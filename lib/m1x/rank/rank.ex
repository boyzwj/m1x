defmodule Rank do
  defmacro __using__(opts) do
    quote do
      use GenServer
      import ShorterMaps
      require Logger
      use Memoize

      @is_global unquote(opts[:is_global])
      @capacity unquote(opts[:capacity] || 500)
      @bucket_size unquote(opts[:bucket_size] || 500)

      @type rank_item :: {non_neg_integer(), non_neg_integer()}
      @dump_interval 60 * 5 * 1000
      alias Discord.SortedSet
      # indexs: %{id => score}
      defstruct set: nil, indexs: %{}, is_dirty: false

      # 提交数据
      @spec submit(non_neg_integer(), non_neg_integer()) :: :ok
      def submit(score, id) when id >= 0 and score >= 0 do
        GenServer.cast(via_tuple(@is_global), {:submit, {-score, id}})
      end

      # 提交数据并返回排名位置
      @spec index_submit(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
      def index_submit(score, id) when id >= 0 and score >= 0 do
        GenServer.call(via_tuple(@is_global), {:index_submit, {-score, id}})
      end

      # 获取指定id的排名信息
      @spec index(non_neg_integer()) :: rank_item
      def index(id) when id >= 0 do
        GenServer.call(via_tuple(@is_global), {:index, id})
      end

      # 获取指定位置的排名信息
      @spec at(non_neg_integer()) :: rank_item
      def at(index) when index >= 0 do
        GenServer.call(via_tuple(@is_global), {:at, index})
      end

      # 获取指定范围的排名信息
      @spec slice(non_neg_integer(), non_neg_integer()) :: [rank_item]
      defmemo slice(start, amount) when start >= 0 and amount >= 0 do
        GenServer.call(via_tuple(@is_global), {:slice, {start, amount}})
      end

      def slice2(start, amount) when start >= 0 and amount >= 0 do
        GenServer.call(via_tuple(@is_global), {:slice, {start, amount}})
      end

      def start_link(args) do
        case GenServer.start_link(__MODULE__, args, name: via_tuple(@is_global)) do
          {:ok, pid} ->
            {:ok, pid}

          {:error, {:already_started, pid}} ->
            Logger.info("already started at #{inspect(pid)}, returning :ignore")
            :ignore
        end
      end

      @impl true
      def init(_args) do
        Process.flag(:trap_exit, true)
        Process.send_after(self(), :init_rank, 1_000)
        {:ok, %__MODULE__{}}
      end

      @impl true
      def handle_cast(_, %__MODULE__{set: nil} = state) do
        Logger.warn("#{__MODULE__} rank need init first!")
        {:noreply, state}
      end

      def handle_cast({:submit, {score, id} = item}, state) do
        %{set: set, indexs: indexs} = state
        old_score = indexs[id]

        if score != old_score do
          SortedSet.remove(set, {old_score, id})
          |> SortedSet.add(item)

          # Logger.debug(inspect(SortedSet.to_list(set)))
          indexs = Map.put(indexs, id, score)

          state =
            Map.put(state, :indexs, indexs)
            |> Map.put(:is_dirty, true)

          if @is_global do
            Rank.GlobalManager.clear_cache(__MODULE__, :slice, :_)
          else
            Memoize.invalidate(__MODULE__, :slice)
          end

          {:noreply, state}
        else
          {:noreply, state}
        end
      end

      @impl true
      def handle_call(_msg, _from, %__MODULE__{set: nil} = state) do
        Logger.warn("#{__MODULE__} rank need init first!")
        {:reply, nil, state}
      end

      def handle_call({:index_submit, {score, id} = item}, _from, state) do
        %{set: set, indexs: indexs} = state
        old_score = indexs[id]

        if score != old_score do
          {index, _} =
            SortedSet.remove(set, {old_score, id})
            |> SortedSet.index_add(item)

          # Logger.debug(inspect(SortedSet.to_list(set)))
          indexs = Map.put(indexs, id, score)

          state =
            Map.put(state, :indexs, indexs)
            |> Map.put(:is_dirty, true)

          if @is_global do
            Rank.GlobalManager.clear_cache(__MODULE__, :slice, :_)
          else
            Memoize.invalidate(__MODULE__, :slice)
          end

          {:reply, index, state}
        else
          {:reply, SortedSet.find_index(set, {old_score, id}), state}
        end
      end

      def handle_call({:at, index}, _from, state) do
        {:reply, SortedSet.at(state.set, index), state}
      end

      def handle_call({:index, id}, _from, state) do
        item = {state.indexs[id], id}
        {:reply, SortedSet.find_index(state.set, item), state}
      end

      def handle_call({:slice, {start, amount}}, _from, state) do
        {:reply, SortedSet.slice(state.set, start, amount), state}
      end

      @impl true
      def handle_info(:init_rank, state) do
        with %__MODULE__{} = state <- load() do
          Logger.info("#{__MODULE__} init rank success!")
          Process.send_after(self(), :dump_rank, dump_interval())
          {:noreply, state}
        else
          {:error, error} ->
            Process.send_after(self(), :init_rank, 1_000)
            Logger.debug(inspect(error))
            {:noreply, state}
        end
      end

      def handle_info(:dump_rank, %__MODULE__{is_dirty: false} = state) do
        Process.send_after(self(), :dump_rank, dump_interval())
        {:noreply, state}
      end

      def handle_info(:dump_rank, %__MODULE__{is_dirty: true} = state) do
        with %__MODULE__{is_dirty: false} = state <- dump(state) do
          Logger.info("#{__MODULE__} dump rank success!")
          Process.send_after(self(), :dump_rank, dump_interval())
          {:noreply, state}
        else
          {:error, error} ->
            Process.send_after(self(), :dump_rank, dump_interval())
            {:noreply, state}
        end
      end

      # look for details: https://hexdocs.pm/horde/Horde.Registry.html#register/3
      def handle_info(
            {:EXIT, registry_pid,
             {:name_conflict, {name, value}, registry_name, winning_pid} = err},
            state
          ) do
        Logger.info(inspect(err))
        Process.exit(self(), :kill)
        {:noreply, state}
      end

      @impl true
      def terminate(_reason, state) do
        IO.inspect("#{__MODULE__} stop")
        dump(state)
        :ok
      end

      def via_tuple(true), do: {:via, Horde.Registry, {Matrix.RankRegistry, __MODULE__}}
      def via_tuple(_), do: __MODULE__

      defp key() do
        if @is_global do
          __MODULE__
        else
          "#{node()}:#{__MODULE__}"
        end
      end

      defp load() do
        try do
          temp = Redis.get(key())

          if is_nil(temp) do
            set = SortedSet.new(@capacity, @bucket_size)
            %__MODULE__{set: set}
          else
            %{set: set, indexs: indexs} = :erlang.binary_to_term(temp)
            %__MODULE__{set: SortedSet.from_proper_enumerable(set), indexs: indexs}
          end
        catch
          error ->
            {:error, error}
        end
      end

      defp dump(%__MODULE__{set: nil} = state), do: state
      defp dump(%__MODULE__{is_dirty: false} = state), do: state

      defp dump(%__MODULE__{set: set, indexs: indexs} = state) do
        try do
          val = %{set: SortedSet.to_list(set), indexs: indexs} |> :erlang.term_to_binary()
          "OK" = Redis.set(key(), val)
          put_in(state.is_dirty, false)
        catch
          error ->
            Logger.warn("#{__MODULE__} dump failed,reason: #{inspect(error)}")
            {:error, error}
        end
      end

      defp dump_interval() do
        @dump_interval + Util.rand(0, 1000)
      end
    end
  end
end

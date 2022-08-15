defmodule Mail do
  # TODO 邮件发送前先入库
  defstruct id: nil,
            cfg_id: 0,
            body: "",
            args: [],
            attachs: [],
            create_time: 0,
            expire_time: 253_402_300_799,
            status: 0
end

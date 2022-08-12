defmodule Mail do
  # TODO 邮件发送前先入库
  defstruct id: nil,
            oid: 0,
            body: "",
            args: [],
            attachs: [],
            create_time: 0,
            expire_time: 0,
            status: 0
end

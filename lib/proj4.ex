defmodule Proj4 do
  
  def main(args \\ []) do
    startProject(args)
  end

  def startProject(args) do
    [num_users, num_msg] = args
    Application.start(:normal, {num_users, num_msg})
  end
end

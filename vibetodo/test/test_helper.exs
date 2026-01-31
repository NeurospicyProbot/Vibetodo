ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Vibetodo.Repo, :manual)

# Browser tests require Chrome and ChromeDriver with matching versions.
# By default, exclude browser tests unless WALLABY_ENABLED=true
if System.get_env("WALLABY_ENABLED") == "true" do
  case Application.ensure_all_started(:wallaby) do
    {:ok, _} ->
      Application.put_env(:wallaby, :base_url, VibetodoWeb.Endpoint.url())
      IO.puts("\n✓ Wallaby enabled for browser-based tests")

    {:error, reason} ->
      IO.puts("""
      \n⚠️  Wallaby failed to start: #{inspect(reason)}
      Browser-based tests will be skipped.
      """)

      ExUnit.configure(exclude: [:browser])
  end
else
  # By default, exclude browser tests (they're slow and require setup)
  ExUnit.configure(exclude: [:browser])
end

ExUnit.start()

IO.puts("Cleaning old data from test-account...")

with {:ok, domains, _} <- RRPproxy.query_domain_list(0, 1000) do
  for domain <- domains do
    RRPproxy.delete_domain(domain, "instant")
  end
end

with {:ok, handles, _} <- RRPproxy.query_contact_list(0, 1000) do
  for handle <- handles do
    RRPproxy.delete_contact(handle)
  end
end

with {:ok, tags, _} <- RRPproxy.query_tag_list("domain", 0, 1000) do
  for tag <- tags do
    RRPproxy.delete_tag(tag)
  end
end

IO.puts("Cleanup done.")

defmodule RRPproxyTest do
  use ExUnit.Case
  doctest RRPproxy

  # account

  test "status account" do
    {ok_or_err, status} = RRPproxy.status_account()
    assert ok_or_err == :ok
    assert is_map(status)
    assert status.currency == "USD"
  end

  test "status registrar and modifying registrar" do
    assert RRPproxy.modify_registrar(%{whois: "james and the bandits", language: "EN"}) == :ok

    {ok_or_err, status} = RRPproxy.status_registrar()
    assert ok_or_err == :ok
    assert is_map(status)
    assert status.language == "EN"
    assert status.whois == "james and the bandits"
  end

  test "query appendix list and activate one" do
    {ok_or_err, list, _} = RRPproxy.query_appendix_list()
    assert ok_or_err == :ok
    assert is_list(list)
    assert Enum.count(list) > 100

    inactive_appendix = Enum.find(list, fn appendix -> appendix.active == false end)
    assert is_map(inactive_appendix)

    # sadly i already have all appendices active thanks to this
    # {ok_or_err, _} = RRPproxy.activate_appendix(inactive_appendix.appendix)
    # assert ok_or_err == :ok
  end

  # domain tags

  test "lifecycle of a domain tag" do
    # just to make sure tests start cleanly
    RRPproxy.delete_tag("test-tag")
    RRPproxy.delete_tag("test-newtag")

    assert RRPproxy.add_tag("test-tag", "test 123") == :ok
    assert RRPproxy.modify_tag("test-tag", newtag: "test-newtag", description: "test 345") == :ok

    {ok_or_err, tag} = RRPproxy.status_tag("test-newtag")
    assert ok_or_err == :ok
    assert tag.description == "test 345"

    {ok_or_err, list, _} = RRPproxy.query_tag_list()
    assert ok_or_err == :ok
    assert Enum.any?(list, fn tag -> tag == "test-newtag" end)

    assert RRPproxy.delete_tag("test-newtag") == :ok
  end

  # events

  test "lifecycle of an event" do
    {ok_or_err, list, _} = RRPproxy.query_event_list(~D[2010-12-31])
    assert ok_or_err == :ok

    if length(list) > 0 do
      {ok_or_err, _} = RRPproxy.status_event(Enum.at(list, 0))
      assert ok_or_err == :ok
      assert RRPproxy.delete_event(Enum.at(list, 0)) == :ok
    end
  end

  # contacts

  @contact %{
    firstname: "Max",
    lastname: "Mustermann",
    street0: "Ludwigstrasse 5",
    city: "Nürnberg",
    zip: "90402",
    country: "DE",
    phone: "+4991112345",
    email: "foo@bar.org"
  }
  test "lifecycle of a people contact" do
    {ok_or_err, contact} = RRPproxy.add_contact(@contact)
    assert ok_or_err == :ok
    assert is_map(contact)
    assert String.length(contact.roid) > 0

    {ok_or_err, list, _} = RRPproxy.query_contact_list()
    assert ok_or_err == :ok
    assert is_list(list)
    assert Enum.any?(list, fn x -> x == contact.contact end)

    {ok_or_err, status_contact} = RRPproxy.status_contact(contact.contact)
    assert ok_or_err == :ok
    assert is_map(status_contact)
    assert String.length(status_contact.roid) > 0

    update_attrs =
      @contact
      |> Map.put(:street0, "Ludwigstrasse 6")
      |> Map.put(:contact, contact.contact)

    {ok_or_err, updated_contact} = RRPproxy.modify_contact(update_attrs)
    assert ok_or_err == :ok
    assert is_map(updated_contact)
    assert updated_contact.validated == true

    {ok_or_err, cloned_contact} = RRPproxy.clone_contact(contact.contact)
    assert ok_or_err == :ok
    assert is_map(cloned_contact)

    assert RRPproxy.delete_contact(contact.contact) == :ok
    assert RRPproxy.restore_contact(contact.contact) == :ok

    assert RRPproxy.delete_contact(contact.contact) == :ok
  end

  @contact %{
    organization: "ACME inc",
    street0: "Ludwigstrasse 1",
    city: "Nürnberg",
    zip: "90402",
    country: "DE",
    phone: "+49911234541",
    email: "acme@foo.org"
  }
  test "lifecycle of an org contact" do
    {ok_or_err, contact} = RRPproxy.add_contact(@contact)
    assert ok_or_err == :ok
    assert is_map(contact)
    assert String.length(contact.roid) > 0

    {ok_or_err, list, _} = RRPproxy.query_contact_list()
    assert ok_or_err == :ok
    assert is_list(list)
    assert Enum.any?(list, fn x -> x == contact.contact end)

    {ok_or_err, status_contact} = RRPproxy.status_contact(contact.contact)
    assert ok_or_err == :ok
    assert is_map(status_contact)
    assert String.length(status_contact.roid) > 0

    update_attrs =
      @contact
      |> Map.put(:street0, "Ludwigstrasse 2")
      |> Map.put(:contact, contact.contact)

    {ok_or_err, updated_contact} = RRPproxy.modify_contact(update_attrs)
    assert ok_or_err == :ok
    assert is_map(updated_contact)
    assert updated_contact.validated == true

    {ok_or_err, cloned_contact} = RRPproxy.clone_contact(contact.contact)
    assert ok_or_err == :ok
    assert is_map(cloned_contact)

    assert RRPproxy.delete_contact(contact.contact) == :ok
    assert RRPproxy.restore_contact(contact.contact) == :ok

    assert RRPproxy.delete_contact(contact.contact) == :ok
  end

  # lifecycle of a nameserver

  @contact %{
    firstname: "John Paul",
    lastname: "Jones",
    street0: "Ludwigstrasse 5",
    city: "Fürth",
    zip: "90765",
    country: "DE",
    phone: "+4991112346",
    email: "foo2@bar.org"
  }
  test "lifecycle of a nameserver" do
    {ok_or_err, contact} = RRPproxy.add_contact(@contact)
    assert ok_or_err == :ok

    domainname = "frei#{:rand.uniform(10000)}.de"
    handle = contact.contact
    {ok_or_err, _} = RRPproxy.add_domain(domainname, handle, handle, handle, handle)
    assert ok_or_err == :ok

    assert RRPproxy.add_nameserver("ns1." <> domainname, ["1.2.3.1"]) == :ok
    assert RRPproxy.modify_nameserver("ns1." <> domainname, ["1.2.4.1"]) == :ok

    {ok_or_err, nameserver} = RRPproxy.status_nameserver("ns1." <> domainname)
    assert ok_or_err == :ok
    assert nameserver.ipaddress == "1.2.4.1"

    {ok_or_err, list, _} = RRPproxy.query_nameserver_list()
    assert ok_or_err == :ok

    assert Enum.any?(list, fn nameserver ->
             String.downcase(nameserver) == "ns1." <> domainname
           end)

    {ok_or_err, _} = RRPproxy.check_nameserver("ns1." <> domainname)
    assert ok_or_err == :ok

    assert RRPproxy.delete_nameserver("ns1." <> domainname) == :ok
    assert RRPproxy.delete_domain(domainname) == {:ok, %{addgracedeletions: false}}
  end

  # domains

  @contact %{
    firstname: "John Paul",
    lastname: "Jones",
    street0: "Ludwigstrasse 5",
    city: "Fürth",
    zip: "90765",
    country: "DE",
    phone: "+4991112346",
    email: "foo2@bar.org"
  }
  test "lifecycle of a domain" do
    {ok_or_err, contact} = RRPproxy.add_contact(@contact)
    assert ok_or_err == :ok
    handle = contact.contact

    domainname = "frei#{:rand.uniform(10000)}.de"
    {ok_or_err, domain} = RRPproxy.add_domain(domainname, handle, handle, handle, handle)
    assert ok_or_err == :ok
    assert domain.status == "ACTIVE"

    assert RRPproxy.modify_domain(domainname, transferlock: true) == :ok

    {ok_or_err, status_domain} = RRPproxy.status_domain(domainname)
    assert ok_or_err == :ok
    assert status_domain.domain == domainname

    assert RRPproxy.renew_domain(domainname) ==
             {:error,
              %{
                code: 541,
                data: [],
                description:
                  "Invalid attribute value; explicit renewals not allowed for this TLD; please set domain to AUTORENEW or RENEWONCE",
                info: %{}
              }}

    {ok_or_err, list, info} = RRPproxy.query_domain_list()
    assert ok_or_err == :ok
    assert is_list(list)
    assert info.limit == 1000
    assert Enum.any?(list, fn domain -> domain == domainname end)

    assert RRPproxy.set_domain_auth_code(domainname, "AABBCCDDEE") == :ok
    assert RRPproxy.set_domain_renewal_mode(domainname, "renewonce") == :ok
    assert RRPproxy.set_domain_transfer_mode(domainname, "autodeny") == :ok

    assert RRPproxy.delete_domain(domainname) == {:ok, %{addgracedeletions: false}}
    assert RRPproxy.restore_domain(domainname) == :ok

    assert RRPproxy.delete_domain(domainname) == {:ok, %{addgracedeletions: false}}

    {ok_or_err, zone} = RRPproxy.get_zone("anycast.io")
    assert ok_or_err == :ok
    assert zone == "io"

    {ok_or_err, _} = RRPproxy.get_zone_info("poop.io")
    assert ok_or_err == :ok
  end

  test "checking if a domain is free" do
    assert RRPproxy.check_domain("frei#{:rand.uniform(10000)}.de") == {:ok, true}
  end

  test "checking if a domain is taken" do
    assert RRPproxy.check_domain("rrpproxy.net") == {:ok, false}
  end

  # transfers

  test "transferring domains" do
    xfer_creds = %RRPproxy.Client{
      ote: true,
      username: Application.get_env(:rrpproxy, :xfer_username),
      password: Application.get_env(:rrpproxy, :xfer_password)
    }

    RRPproxy.activate_appendix("appendix_de", xfer_creds)

    {ok_or_err, contact} = RRPproxy.add_contact(@contact, xfer_creds)
    assert ok_or_err == :ok
    handle = contact.contact

    domainname = "xfer#{:rand.uniform(10000)}.de"

    {ok_or_err, domain} =
      RRPproxy.add_domain(domainname, handle, handle, handle, handle, [], "", [], xfer_creds)

    assert ok_or_err == :ok
    assert domain.status == "ACTIVE"
    assert RRPproxy.set_domain_transfer_mode(domainname, "AUTOAPPROVE", "", xfer_creds) == :ok
    assert RRPproxy.set_domain_auth_code(domainname, "AABBCCDDEE", xfer_creds) == :ok

    assert :ok == RRPproxy.transfer_domain(domainname, "usertransfer", "AABBCCDDEE")

    assert :ok =
             RRPproxy.transfer_domain(
               domainname,
               "approve",
               "",
               "",
               "",
               "",
               "",
               [],
               "1",
               [],
               xfer_creds
             )

    {ok_or_err, list, _} = RRPproxy.query_transfer_list()
    assert ok_or_err == :ok
    assert is_list(list)

    {ok_or_err, list, _} = RRPproxy.query_foreign_transfer_list()
    assert ok_or_err == :ok
    assert is_list(list)

    no_owner_change_error = %{
      code: 545,
      data: [],
      description: "Entity reference not found; no ownerchange found for relevant registrar",
      info: %{}
    }

    assert {:error, no_owner_change_error} == RRPproxy.status_owner_change(domainname)

    {ok_or_err, _} = RRPproxy.status_domain_transfer(domainname)
    assert ok_or_err == :ok

    assert RRPproxy.delete_domain(domainname, "instant") == {:ok, %{addgracedeletions: false}}
  end

  # finance

  test "price list" do
    {ok_or_err, prices, _} = RRPproxy.query_zone_list()
    assert ok_or_err == :ok
    assert Enum.count(prices) > 1000

    {ok_or_err, accountings, _} = RRPproxy.query_accounting_list("2010-01-01")
    assert ok_or_err == :ok
    assert Enum.count(accountings) > 0

    {ok_or_err, upcoming_accountings, _} = RRPproxy.query_upcoming_accounting_list()
    assert ok_or_err == :ok
    assert Enum.count(upcoming_accountings) > 0

    {ok_or_err, _, _} = RRPproxy.convert_currency(1, "USD", "EUR")
    assert ok_or_err == :ok

    {ok_or_err, _, _} = RRPproxy.query_available_promotion_list()
    assert ok_or_err == :ok
  end

  # error cases

  test "deleting invalid contact should fail" do
    assert RRPproxy.delete_contact("FOO") ==
             {:error,
              %{code: 545, data: [], description: "Entity reference not found", info: %{}}}
  end

  test "status owner change on invalid transfer should fail" do
    assert RRPproxy.status_owner_change("rrpproxy.net") ==
             {:error,
              %{
                code: 545,
                data: [],
                description:
                  "Entity reference not found; no ownerchange found for relevant registrar",
                info: %{}
              }}
  end

  test "request token for invalid contact should fail" do
    assert RRPproxy.request_token("FOO") ==
             {:error,
              %{
                code: 549,
                data: [],
                description: "Command failed; email sending not available in OTE",
                info: %{}
              }}
  end
end

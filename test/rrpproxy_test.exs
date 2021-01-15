defmodule RRPproxyTest do
  use ExUnit.Case
  doctest RRPproxy

  # account

  test "status account" do
    assert {:ok, status} = RRPproxy.status_account()
    assert is_map(status)
    assert status.currency == "USD"
  end

  test "status registrar and modifying registrar" do
    assert RRPproxy.modify_registrar(%{whois: "james and the bandits", language: "EN"}) == :ok

    assert {:ok, status} = RRPproxy.status_registrar()
    assert is_map(status)
    assert status.language == "EN"
    assert status.whois == "james and the bandits"
  end

  test "query appendix list and activate one" do
    assert {:ok, list, _} = RRPproxy.query_appendix_list()
    assert is_list(list)
    assert Enum.count(list) > 100

    inactive_appendix = Enum.find(list, fn appendix -> appendix.active == false end)
    assert is_map(inactive_appendix)

    # sadly i already have all appendices active thanks to this
    # assert {:ok, _} = RRPproxy.activate_appendix(inactive_appendix.appendix)
  end

  # domain tags

  test "lifecycle of a domain tag" do
    # just to make sure tests start cleanly
    RRPproxy.delete_tag("test-tag")
    RRPproxy.delete_tag("test-newtag")

    assert RRPproxy.add_tag("test-tag", "test 123") == :ok
    assert RRPproxy.modify_tag("test-tag", newtag: "test-newtag", description: "test 345") == :ok

    assert {:ok, tag} = RRPproxy.status_tag("test-newtag")
    assert tag.description == "test 345"

    assert {:ok, list, _} = RRPproxy.query_tag_list("domain", 0, 2000)
    assert Enum.any?(list, fn tag -> tag == "test-newtag" end)

    assert RRPproxy.delete_tag("test-newtag") == :ok
  end

  # events

  test "lifecycle of an event" do
    assert {:ok, list, _} = RRPproxy.query_event_list(~D[2010-12-31])

    if length(list) > 0 do
      assert {:ok, _} = RRPproxy.status_event(Enum.at(list, 0))
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
    assert {:ok, contact} = RRPproxy.add_contact(@contact)
    assert is_map(contact)
    assert String.length(contact.roid) > 0

    assert {:ok, list, _} = RRPproxy.query_contact_list(0, 2000)
    assert is_list(list)
    assert Enum.any?(list, fn x -> x == contact.contact end)

    assert {:ok, status_contact} = RRPproxy.status_contact(contact.contact)
    assert is_map(status_contact)
    assert String.length(status_contact.roid) > 0

    update_attrs =
      @contact
      |> Map.put(:street0, "Ludwigstrasse 6")
      |> Map.put(:contact, contact.contact)

    assert {:ok, updated_contact} = RRPproxy.modify_contact(update_attrs)
    assert is_map(updated_contact)
    assert updated_contact.validated == true

    assert {:ok, cloned_contact} = RRPproxy.clone_contact(contact.contact)
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
    assert {:ok, contact} = RRPproxy.add_contact(@contact)
    assert is_map(contact)
    assert String.length(contact.roid) > 0

    assert {:ok, list, _} = RRPproxy.query_contact_list()
    assert is_list(list)
    assert Enum.any?(list, fn x -> x == contact.contact end)

    assert {:ok, status_contact} = RRPproxy.status_contact(contact.contact)
    assert is_map(status_contact)
    assert String.length(status_contact.roid) > 0

    update_attrs =
      @contact
      |> Map.put(:street0, "Ludwigstrasse 2")
      |> Map.put(:contact, contact.contact)

    assert {:ok, updated_contact} = RRPproxy.modify_contact(update_attrs)
    assert is_map(updated_contact)
    assert updated_contact.validated == true

    assert {:ok, cloned_contact} = RRPproxy.clone_contact(contact.contact)
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
    assert {:ok, contact} = RRPproxy.add_contact(@contact)

    domainname = "frei#{:rand.uniform(10000)}.de"
    handle = contact.contact
    assert {:ok, _} = RRPproxy.add_domain(domainname, handle, handle, handle, handle)

    assert RRPproxy.add_nameserver("ns1." <> domainname, ["1.2.3.1"]) == :ok
    assert RRPproxy.modify_nameserver("ns1." <> domainname, ["1.2.4.1"]) == :ok

    assert {:ok, nameserver} = RRPproxy.status_nameserver("ns1." <> domainname)
    assert nameserver.ipaddress == "1.2.4.1"

    assert {:ok, list, _} = RRPproxy.query_nameserver_list()

    assert Enum.any?(list, fn nameserver ->
             String.downcase(nameserver) == "ns1." <> domainname
           end)

    assert {:ok, _} = RRPproxy.check_nameserver("ns1." <> domainname)

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
    assert {:ok, contact} = RRPproxy.add_contact(@contact)
    handle = contact.contact

    domainname = "frei#{:rand.uniform(10000)}.de"
    assert {:ok, domain} = RRPproxy.add_domain(domainname, handle, handle, handle, handle)
    assert domain.status == "ACTIVE"

    assert RRPproxy.modify_domain(domainname, transferlock: true) == :ok

    assert {:ok, status_domain} = RRPproxy.status_domain(domainname)
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

    assert {:ok, list, info} = RRPproxy.query_domain_list()
    assert is_list(list)
    assert info.limit == 1000
    assert Enum.any?(list, fn domain -> domain == domainname end)

    assert RRPproxy.set_domain_auth_code(domainname, "AABBCCDDEE") == :ok
    assert RRPproxy.set_domain_renewal_mode(domainname, "renewonce") == :ok
    assert RRPproxy.set_domain_transfer_mode(domainname, "autodeny") == :ok

    assert RRPproxy.delete_domain(domainname) == {:ok, %{addgracedeletions: false}}
    assert RRPproxy.restore_domain(domainname) == :ok

    assert RRPproxy.delete_domain(domainname) == {:ok, %{addgracedeletions: false}}

    assert {:ok, zone} = RRPproxy.get_zone("anycast.io")
    assert zone == "io"

    assert {:ok, _} = RRPproxy.get_zone_info("poop.io")
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

    assert {:ok, contact} = RRPproxy.add_contact(@contact, xfer_creds)
    handle = contact.contact

    domainname = "xfer#{:rand.uniform(10000)}.de"

    assert {:ok, domain} =
             RRPproxy.add_domain(
               domainname,
               handle,
               handle,
               handle,
               handle,
               [],
               [],
               xfer_creds
             )

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
               [],
               xfer_creds
             )

    assert {:ok, list, _} = RRPproxy.query_transfer_list()
    assert is_list(list)

    assert {:ok, list, _} = RRPproxy.query_foreign_transfer_list()
    assert is_list(list)

    no_owner_change_error = %{
      code: 545,
      data: [],
      description: "Entity reference not found; no ownerchange found for relevant registrar",
      info: %{}
    }

    assert {:error, no_owner_change_error} == RRPproxy.status_owner_change(domainname)

    assert {:ok, _} = RRPproxy.status_domain_transfer(domainname)

    assert RRPproxy.delete_domain(domainname, "instant") == {:ok, %{addgracedeletions: false}}
  end

  # finance

  test "price list" do
    assert {:ok, prices, _} = RRPproxy.query_zone_list()
    assert Enum.count(prices) > 1000

    assert {:ok, accountings, _} = RRPproxy.query_accounting_list("2010-01-01")
    assert Enum.count(accountings) > 0

    assert {:ok, upcoming_accountings, _} = RRPproxy.query_upcoming_accounting_list()
    assert Enum.count(upcoming_accountings) > 0

    assert {:ok, _, _} = RRPproxy.convert_currency(1, "USD", "EUR")

    assert {:ok, _, _} = RRPproxy.query_available_promotion_list()
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

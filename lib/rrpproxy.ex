defmodule RRPproxy do
  @moduledoc """
  Documentation for `RRPproxy` which provides API for rrpproxy.net.

  ## Installation

  This package can be installed by adding `rrpproxy` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [
      {:rrpproxy, "~> 0.1.7"}
    ]
  end
  ```

  ## Configuration

  Put the following lines into your `config.exs` or better, into your environment
  configuration files like `test.exs`, `dev.exs` or `prod.exs.`.

  ```elixir
  config :rrpproxy,
    username: "<your login>",
    password: "<your password>",
    ote: true
  ```

  ## Usage Examples

  Check for a free domain, where `false` means "not available" and `true` means "available":

  ```elixir
  iex> RRPproxy.status_domain("example.com")
  {:ok, false}
  ```
  """
  alias RRPproxy.Client
  alias RRPproxy.Connection

  defp fix_attrs(attrs),
    do: Enum.flat_map(attrs, fn {k, v} -> [{to_atom(k), to_value(v)}] end)

  defp to_value(true), do: "1"
  defp to_value(false), do: "0"
  defp to_value(other), do: other
  defp to_atom(key) when is_atom(key), do: key
  defp to_atom(key), do: String.to_existing_atom(key)

  @type return() :: {:ok, any()} | {:error, any()}
  @type integer_opt() :: integer() | nil
  @type boolean_opt() :: boolean() | nil
  @type string_opt() :: String.t() | nil
  @type client_opt() :: Client.t() | nil

  # Account

  @doc """
  status_account returns information about the accounts financial status.

  """
  @spec status_account() :: return
  @spec status_account(client_opt) :: return
  def status_account(client \\ Client.new()) do
    with {:ok, %{code: 200, data: [status]}} <- Connection.call("StatusAccount", [], client) do
      {:ok, status}
    end
  end

  @doc """
  status_registrar returns information about your account information.

  """
  @spec status_registrar(client_opt) :: return
  def status_registrar(client \\ Client.new()) do
    with {:ok, %{code: 200, data: statuses}} <- Connection.call("StatusRegistrar", [], client) do
      {:ok, Enum.find(statuses, fn status -> Map.has_key?(status, :language) end)}
    end
  end

  @doc """
  modify_registrar modifies the registrar's (or subaccounts) settings.

  """
  @spec modify_registrar(keyword(), client_opt) :: return
  def modify_registrar(registrar, client \\ Client.new()) do
    with {:ok, _} <- Connection.call("ModifyRegistrar", registrar, client) do
      :ok
    end
  end

  @doc """
  query_appendix_list returns a list of all appendices.

  """
  @spec query_appendix_list(integer_opt(), integer_opt(), client_opt) :: return
  def query_appendix_list(offset \\ 0, limit \\ 1000, client \\ Client.new()) do
    params = [first: offset, limit: limit]

    with {:ok, %{code: 200, data: appendices, info: info}} <-
           Connection.call("QueryAppendixList", params, client) do
      {:ok, appendices, info}
    end
  end

  @x_accept_tac String.to_atom("X-ACCEPT-TAC")
  @doc """
  activate_appendix activates an appendix.

  """
  @spec activate_appendix(String.t(), boolean_opt(), client_opt) :: return
  def activate_appendix(
        appendix,
        accept_terms_and_conditions \\ true,
        client \\ Client.new()
      ) do
    accept_tac = if accept_terms_and_conditions, do: 1, else: 0
    params = [appendix: appendix] ++ [{@x_accept_tac, accept_tac}]

    with {:ok, %{code: 200, data: %{"0": %{email: "successful"}}}} <-
           Connection.call("ActivateAppendix", params, client) do
      :ok
    end
  end

  # Contacts

  @doc """
  query_contact_list returns a list of all contact handles.

  """
  @spec query_contact_list(integer_opt(), integer_opt(), client_opt) :: return
  def query_contact_list(offset \\ 0, limit \\ 100, client \\ Client.new()) do
    params = [first: offset, limit: limit]

    with {:ok, %{code: 200, data: contacts, info: info}} <-
           Connection.call("QueryContactList", params, client) do
      {:ok, Enum.map(contacts, fn contact -> contact.contact end), info}
    end
  end

  @doc """
  get_contact returns a contact handle.

  """
  @spec status_contact(String.t(), client_opt) :: return
  def status_contact(contact, client \\ Client.new()) do
    case Connection.call("StatusContact", [contact: contact], client) do
      {:ok, %{code: 200, data: [contact]}} -> {:ok, contact}
      {:ok, %{code: 200, data: [contact, %{status: "ok"}]}} -> {:ok, contact}
      other -> other
    end
  end

  @doc """
  add_contact adds a new contact and returns a contact handle.

  """
  @spec add_contact(keyword(), boolean_opt(), boolean_opt(), client_opt) :: return
  def add_contact(
        contact,
        validation \\ true,
        pre_verify \\ true,
        client \\ Client.new()
      ) do
    params =
      contact ++
        [
          validation: if(validation, do: 1, else: 0),
          preverify: if(pre_verify, do: 1, else: 0),
          autodelete: 1
        ]

    with {:ok, %{code: 200, data: [contact]}} <- Connection.call("AddContact", params, client) do
      {:ok, contact}
    end
  end

  @doc """
  modify_contact modifies an existing contact and returns a contact handle.

  """
  @spec modify_contact(keyword(), boolean_opt(), boolean_opt(), boolean_opt(), client_opt) ::
          return
  def modify_contact(
        contact,
        validation \\ true,
        pre_verify \\ false,
        check_only \\ false,
        client \\ Client.new()
      ) do
    params =
      contact ++
        [
          validation: if(validation, do: 1, else: 0),
          preverify: if(pre_verify, do: 1, else: 0),
          checkonly: if(check_only, do: 1, else: 0)
        ]

    with {:ok, %{code: 200, data: [contact]}} <-
           Connection.call("ModifyContact", params, client) do
      {:ok, contact}
    end
  end

  @doc """
  delete_contact deletes a given contact.

  """
  @spec delete_contact(String.t(), client_opt) :: return
  def delete_contact(contact, client \\ Client.new()) do
    with {:ok, %{code: 200}} <-
           Connection.call("DeleteContact", [contact: contact], client) do
      :ok
    end
  end

  @doc """
  clone_contact clones the given contact.

  """
  @spec clone_contact(String.t(), client_opt) :: return
  def clone_contact(contact, client \\ Client.new()) do
    with {:ok, %{code: 200, data: [contact]}} <-
           Connection.call("CloneContact", [contact: contact], client) do
      {:ok, contact}
    end
  end

  @doc """
  restore_contact restores a deleted contact.

  """
  @spec restore_contact(String.t(), client_opt) :: return
  def restore_contact(contact, client \\ Client.new()) do
    with {:ok, %{code: 200}} <-
           Connection.call("RestoreContact", [contact: contact], client) do
      :ok
    end
  end

  @doc """
  request_token requests a verification token for the given contact or domain.

  """
  @spec request_token(String.t(), client_opt) :: return
  def request_token(people_contact_or_domain, client \\ Client.new()) do
    params = [contact: people_contact_or_domain, type: "ContactDisclosure"]

    with {:ok, %{code: 200}} <- Connection.call("RequestToken", params, client) do
      :ok
    end
  end

  # Events

  @doc """
  delete_event deletes the given event by id.

  """
  @spec delete_event(String.t(), client_opt) :: return
  def delete_event(event, client \\ Client.new()) do
    params = [event: event]

    with {:ok, %{code: 200}} <- Connection.call("DeleteEvent", params, client) do
      :ok
    end
  end

  @doc """
  status_event gets an event by id.

  """
  @spec status_event(String.t(), client_opt) :: return
  def status_event(event, client \\ Client.new()) do
    params = [event: event]

    with {:ok, %{code: 200, data: [event]}} <- Connection.call("StatusEvent", params, client) do
      {:ok, event}
    end
  end

  @doc """
  query_event_list returns a list of events since the given date.

  """
  @spec query_event_list(String.t(), keyword() | nil, integer_opt(), integer_opt(), client_opt) ::
          return
  def query_event_list(
        date,
        opts \\ [],
        offset \\ 0,
        limit \\ 1000,
        client \\ Client.new()
      ) do
    params = [mindate: date, first: offset, limit: limit] ++ opts

    with {:ok, %{code: 200, data: events, info: info}} <-
           Connection.call("QueryEventList", params, client) do
      {:ok,
       Enum.flat_map(events, fn v ->
         e = Map.get(v, :event, [])
         if is_list(e), do: e, else: [e]
       end), info}
    end
  end

  # Domain Tags

  @doc """
  add_tag adds a tags to be used for tagging domains or zones.

  """
  @spec add_tag(String.t(), string_opt(), string_opt(), client_opt) :: return
  def add_tag(tag, description \\ "", type \\ "domain", client \\ Client.new()) do
    params = [tag: tag, type: type, description: description]

    with {:ok, %{code: 200}} <- Connection.call("AddTag", params, client) do
      :ok
    end
  end

  @doc """
  modify_tag modifies tags by the given tag name for domains and zones.

  """
  @spec modify_tag(String.t(), keyword(), string_opt(), client_opt) :: return
  def modify_tag(
        tag,
        params,
        type \\ "domain",
        client \\ Client.new()
      ) do
    params = [tag: tag, type: type] ++ params

    with {:ok, %{code: 200}} <- Connection.call("ModifyTag", params, client) do
      :ok
    end
  end

  @doc """
  delete_tag deletes a the given tag.

  """
  @spec delete_tag(String.t(), string_opt(), client_opt) :: return
  def delete_tag(tag, type \\ "domain", client \\ Client.new()) do
    params = [tag: tag, type: type]

    with {:ok, %{code: 200}} <- Connection.call("DeleteTag", params, client) do
      :ok
    end
  end

  @doc """
  status_tag gets the given tag by name.

  """
  @spec status_tag(String.t(), string_opt(), client_opt) :: return
  def status_tag(tag, type \\ "domain", client \\ Client.new()) do
    params = [tag: tag, type: type]

    with {:ok, %{code: 200, data: [tag]}} <- Connection.call("StatusTag", params, client) do
      {:ok, tag}
    end
  end

  @doc """
  query_tag_list gets a list of tags.

  """
  @spec query_tag_list(string_opt(), integer_opt(), integer_opt(), client_opt) :: return
  def query_tag_list(
        type \\ "domain",
        offset \\ 0,
        limit \\ 1000,
        client \\ Client.new()
      ) do
    params = [first: offset, limit: limit, type: type]

    with {:ok, %{code: 200, data: tags, info: info}} <-
           Connection.call("QueryTagList", params, client) do
      {:ok,
       Enum.flat_map(tags, fn v ->
         e = Map.get(v, :tag, [])
         if is_list(e), do: e, else: [e]
       end), info}
    end
  end

  # Nameservers

  @ipaddresses [
    :ipaddress0,
    :ipaddress1,
    :ipaddress2,
    :ipaddress3,
    :ipaddress4,
    :ipaddress5,
    :ipaddress6,
    :ipaddress7,
    :ipaddress8,
    :ipaddress9,
    :ipaddress10
  ]
  @doc """
  add_nameserver adds a nameservers to be used for nameserverging domains or zones.

  """
  @spec add_nameserver(String.t(), [String.t()], client_opt) :: return
  def add_nameserver(nameserver, ips, client \\ Client.new()) do
    params =
      ips
      |> Enum.with_index()
      |> Enum.flat_map(fn {ip, idx} -> [{Enum.at(@ipaddresses, idx), ip}] end)

    params = params ++ [nameserver: nameserver]

    with {:ok, %{code: 200}} <- Connection.call("AddNameserver", params, client) do
      :ok
    end
  end

  @doc """
  modify_nameserver modifies nameservers by the given nameserver name for domains and zones.

  """
  @spec modify_nameserver(String.t(), [String.t()], client_opt) :: return
  def modify_nameserver(nameserver, ips, client \\ Client.new()) do
    params =
      ips
      |> Enum.with_index()
      |> Enum.flat_map(fn {ip, idx} -> [{String.to_existing_atom("ipaddress#{idx}"), ip}] end)

    params = params ++ [nameserver: nameserver]

    with {:ok, %{code: 200}} <- Connection.call("ModifyNameserver", params, client) do
      :ok
    end
  end

  @doc """
  delete_nameserver deletes a the given nameserver.

  """
  @spec delete_nameserver(String.t(), client_opt) :: return
  def delete_nameserver(nameserver, client \\ Client.new()) do
    params = [nameserver: nameserver]

    with {:ok, %{code: 200}} <- Connection.call("DeleteNameserver", params, client) do
      :ok
    end
  end

  @doc """
  check_nameserver checks a the given nameserver.

  """
  @spec check_nameserver(String.t(), client_opt) :: return
  def check_nameserver(nameserver, client \\ Client.new()) do
    params = [nameserver: nameserver]

    with {:ok, %{code: 200}} <- Connection.call("CheckNameserver", params, client) do
      :ok
    end
  end

  @doc """
  status_nameserver gets the given nameserver by name.

  """
  @spec status_nameserver(String.t(), client_opt) :: return
  def status_nameserver(nameserver, client \\ Client.new()) do
    params = [nameserver: nameserver]

    with {:ok, %{code: 200, data: [nameserver]}} <-
           Connection.call("StatusNameserver", params, client) do
      {:ok, nameserver}
    end
  end

  @doc """
  query_nameserver_list gets a list of nameservers.

  """
  @spec query_nameserver_list(integer_opt(), integer_opt(), client_opt) :: return
  def query_nameserver_list(offset \\ 0, limit \\ 1000, client \\ Client.new()) do
    params = [first: offset, limit: limit]

    with {:ok, %{code: 200, data: nameservers, info: info}} <-
           Connection.call("QueryNameserverList", params, client) do
      ret =
        nameservers
        |> Enum.flat_map(fn ns ->
          case Map.get(ns, :nameserver) do
            nil -> []
            other -> [other]
          end
        end)

      {:ok, ret, info}
    end
  end

  # Domains

  @doc """
  query_domain_list returns a list of all registerd domains.

  """
  @spec query_domain_list(integer_opt(), integer_opt(), client_opt) :: return
  def query_domain_list(offset \\ 0, limit \\ 1000, client \\ Client.new()) do
    params = [first: offset, limit: limit]

    with {:ok, %{code: 200, data: domains, info: info}} <-
           Connection.call("QueryDomainList", params, client) do
      {:ok, Enum.map(domains, fn v -> v.domain end), info}
    end
  end

  @doc """
  check_domain checks wether the given domain name is free.

  """
  @spec check_domain(String.t(), client_opt) :: return
  def check_domain(domain, client \\ Client.new()) do
    params = [domain: domain]

    case Connection.call("CheckDomain", params, client) do
      {:ok, %{code: 210}} -> {:ok, true}
      {:ok, %{code: 211}} -> {:ok, false}
      other -> other
    end
  end

  @doc """
  status_domain gets the given domain by name.

  """
  @spec status_domain(String.t(), client_opt) :: return
  def status_domain(domain, client \\ Client.new()) do
    params = [domain: domain]

    with {:ok, %{code: 200, data: [domain]}} <-
           Connection.call("StatusDomain", params, client, false, true) do
      {:ok, domain}
    end
  end

  @doc """
  add_domain registers a new domain.

  """
  @spec add_domain(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          [String.t()] | nil,
          keyword() | nil,
          client_opt
        ) :: return
  def add_domain(
        domain,
        owner,
        admin,
        tech,
        bill,
        nameservers \\ [],
        opts \\ [],
        client \\ Client.new()
      ) do
    params =
      nameservers
      |> Enum.with_index()
      |> Enum.flat_map(fn {ns, i} -> [{String.to_existing_atom("nameserver#{i}"), ns}] end)

    params =
      params ++
        opts ++
        [
          domain: domain,
          ownercontact0: owner,
          admincontact0: admin,
          techcontact0: tech,
          billingcontact0: bill
        ]

    with {:ok, %{code: 200, data: [data]}} <- Connection.call("AddDomain", params, client) do
      {:ok, data}
    end
  end

  @doc """
  modify_domain modifies domains by the given domain name for domains and zones.

  """
  @spec modify_domain(String.t(), [String.t()] | nil, client_opt) :: return
  def modify_domain(domain, attrs \\ [], client \\ Client.new()) do
    params = [domain: domain] ++ fix_attrs(attrs)

    with {:ok, %{code: 200}} <- Connection.call("ModifyDomain", params, client) do
      :ok
    end
  end

  @doc """
  delete_domain deletes a registered domain.

  """
  @spec delete_domain(String.t(), string_opt(), client_opt) :: return
  def delete_domain(domain, action \\ "instant", client \\ Client.new()) do
    params = [domain: domain, action: String.upcase(action)]

    with {:ok, %{code: 200, data: [data]}} <- Connection.call("DeleteDomain", params, client) do
      {:ok, data}
    end
  end

  @doc """
  renew_domain renews a registered domain.

  """
  @spec renew_domain(String.t(), integer_opt(), client_opt) :: return
  def renew_domain(domain, years \\ 1, client \\ Client.new()) do
    params = [domain: domain, period: years]

    with {:ok, %{code: 200}} <- Connection.call("RenewDomain", params, client) do
      :ok
    end
  end

  @doc """
  set_auth_code sets the domains auth-code for transfer.

  """
  @spec set_domain_auth_code(String.t(), String.t(), client_opt) :: return
  def set_domain_auth_code(domain, code, client \\ Client.new()) do
    params =
      [domain: domain, auth: code, type: 1] ++
        if code == "",
          do: [action: "delete"],
          else: [action: "set"]

    with {:ok, %{code: 200}} <- Connection.call("SetAuthcode", params, client) do
      :ok
    end
  end

  @doc """
  set_domain_renewal_mode sets the domains renewal-mode.

  The domains mode for renewals (optional): DEFAULT | AUTORENEW | AUTOEXPIRE | AUTODELETE | RENEWONCE
  The domains mode for renewals (only valid for the zone de, optional): DEFAULT | AUTORENEW | AUTORENEWMONTHLY | AUTOEXPIRE | AUTODELETE | RENEWONCE
  The domains mode for renewals (only valid for the zone nl, optional): DEFAULT | AUTORENEW | AUTOEXPIRE | AUTODELETE | RENEWONCE | AUTORENEWQUARTERLY
  The domains mode for renewals (only valid for the zones com, net, org, info, biz, tv, mobi and me, optional): DEFAULT | AUTORENEW | AUTOEXPIRE | AUTODELETE | RENEWONCE | EXPIREAUCTION
  """
  @spec set_domain_renewal_mode(String.t(), string_opt(), string_opt(), client_opt) :: return
  def set_domain_renewal_mode(
        domain,
        mode \\ "default",
        token \\ "",
        client \\ Client.new()
      ) do
    params =
      [domain: domain, renewalmode: mode] ++
        if token == "", do: [], else: [token: token]

    with {:ok, %{code: 200}} <- Connection.call("SetDomainRenewalMode", params, client) do
      :ok
    end
  end

  @doc """
  set_domain_transfer_mode sets the domains transfer-mode.

  The domains mode for transfers: DEFAULT|AUTOAPPROVE|AUTODENY
  """
  @spec set_domain_transfer_mode(String.t(), string_opt(), string_opt(), client_opt) :: return
  def set_domain_transfer_mode(
        domain,
        mode \\ "default",
        token \\ "",
        client \\ Client.new()
      ) do
    params =
      [domain: domain, transfermode: mode] ++
        if token == "", do: [], else: [token: token]

    with {:ok, %{code: 200}} <- Connection.call("SetDomainTransferMode", params, client) do
      :ok
    end
  end

  @doc """
  restore_domain restores a registered domain.

  """
  @spec restore_domain(String.t(), client_opt) :: return
  def restore_domain(domain, client \\ Client.new()) do
    params = [domain: domain]

    with {:ok, %{code: 200}} <- Connection.call("RestoreDomain", params, client) do
      :ok
    end
  end

  @doc """
  status_owner_change explicity checks the status of an OwnerChange in detail.

  """
  @spec status_owner_change(String.t(), client_opt) :: return
  def status_owner_change(domain, client \\ Client.new()) do
    params = [domain: domain]

    with {:ok, %{code: 200, data: [data]}} <-
           Connection.call("StatusOwnerChange", params, client) do
      {:ok, data}
    end
  end

  @doc """
  get_zone returns the correct zone for the given domainname.

  """
  @spec get_zone(String.t(), client_opt) :: return
  def get_zone(domain, client \\ Client.new()) do
    params = [domain: domain]

    with {:ok, %{code: 200, data: [data]}} <- Connection.call("GetZone", params, client) do
      {:ok, data.zone}
    end
  end

  @doc """
  get_zone_info returns zone information for the given zone.

  """
  @spec get_zone_info(String.t(), client_opt) :: return
  def get_zone_info(domain, client \\ Client.new()) do
    params = [domain: domain]

    with {:ok, %{code: 200, data: [data]}} <-
           Connection.call("GetZoneInfo", params, client, true) do
      {:ok, data}
    end
  end

  # transfers

  @doc """
  transfer_domain transfers a foreign domain into our account.

  """
  @spec transfer_domain(
          String.t(),
          string_opt(),
          string_opt(),
          string_opt(),
          string_opt(),
          string_opt(),
          string_opt(),
          [String.t()] | nil,
          keyword() | nil,
          client_opt
        ) :: return
  def transfer_domain(
        domain,
        action \\ "request",
        auth \\ "",
        owner \\ "",
        admin \\ "",
        tech \\ "",
        bill \\ "",
        nameservers \\ [],
        opts \\ [],
        client \\ Client.new()
      ) do
    params =
      nameservers
      |> Enum.with_index()
      |> Enum.flat_map(fn {ns, i} -> [{String.to_existing_atom("nameserver#{i}"), ns}] end)

    params =
      params ++
        [domain: domain, action: action] ++
        opts ++
        if(auth == "", do: [], else: [auth: auth]) ++
        if(owner == "", do: [], else: [ownercontact0: owner]) ++
        if(admin == "", do: [], else: [admincontact0: admin]) ++
        if(tech == "", do: [], else: [techcontact0: tech]) ++
        if(bill == "", do: [], else: [billingcontact0: bill])

    with {:ok, %{code: 200}} <- Connection.call("TransferDomain", params, client) do
      :ok
    end
  end

  @doc """
  query_transfer_list returns a list of local transfers.

  """
  @spec query_transfer_list(integer_opt(), integer_opt(), client_opt) :: return
  def query_transfer_list(offset \\ 0, limit \\ 2000, client \\ Client.new()) do
    params = [first: offset, limit: limit]

    with {:ok, %{code: 200, data: data, info: info}} <-
           Connection.call("QueryTransferList", params, client) do
      {:ok, data, info}
    end
  end

  @doc """
  query_foreign_transfer_list returns a list of foreign transfers.

  """
  @spec query_foreign_transfer_list(integer_opt(), integer_opt(), client_opt) :: return
  def query_foreign_transfer_list(
        offset \\ 0,
        limit \\ 2000,
        client \\ Client.new()
      ) do
    params = [first: offset, limit: limit]

    with {:ok, %{code: 200, data: data, info: info}} <-
           Connection.call("QueryForeignTransferList", params, client) do
      {:ok, data, info}
    end
  end

  @doc """
  status_domain_transfer command informs you about the current status of a transfer.
  You can check if the transfer was successfully initiated or who received the eMail to confirm a transfer.

  """
  @spec status_domain_transfer(String.t(), client_opt) :: return
  def status_domain_transfer(domain, client \\ Client.new()) do
    params = [domain: domain]

    with {:ok, %{code: 200, data: [data]}} <-
           Connection.call("StatusDomainTransfer", params, client) do
      {:ok, data}
    end
  end

  # Finance

  @doc """
  query_zone_list returns the prices per zone.

  """
  @spec query_zone_list(integer_opt(), integer_opt(), client_opt) :: return
  def query_zone_list(offset \\ 0, limit \\ 2000, client \\ Client.new()) do
    params = [first: offset, limit: limit]

    with {:ok, %{code: 200, data: prices, info: info}} <-
           Connection.call("QueryZoneList", params, client) do
      {:ok, prices, info}
    end
  end

  @doc """
  query_accounting_list returns all items for accounting since the given date.

  """
  @spec query_accounting_list(String.t(), integer_opt(), integer_opt(), client_opt) :: return
  def query_accounting_list(
        date,
        offset \\ 0,
        limit \\ 2000,
        client \\ Client.new()
      ) do
    params = [mindate: date, first: offset, limit: limit]

    with {:ok, %{code: 200, data: data, info: info}} <-
           Connection.call("QueryAccountingList", params, client) do
      {:ok, data, info}
    end
  end

  @doc """
  query_upcoming_accounting_list returns all items that are upcoming for accounting.

  """
  @spec query_upcoming_accounting_list(integer_opt(), integer_opt(), client_opt) :: return
  def query_upcoming_accounting_list(
        offset \\ 0,
        limit \\ 2000,
        client \\ Client.new()
      ) do
    params = [first: offset, limit: limit]

    with {:ok, %{code: 200, data: data, info: info}} <-
           Connection.call("QueryUpcomingAccountingList", params, client) do
      {:ok, data, info}
    end
  end

  @doc """
  convert_currency converts the currency according to their current rates.

  """
  @spec convert_currency(any(), String.t(), string_opt(), client_opt) :: return
  def convert_currency(amount, from, to \\ "EUR", client \\ Client.new()) do
    params = [amount: amount, from: from, to: to]

    with {:ok, %{code: 200, data: [conv]}} <-
           Connection.call("ConvertCurrency", params, client) do
      {:ok, conv.converted_amount, conv.rate}
    end
  end

  @doc """
  query_available_promotion_list returns all available promotions.

  """
  @spec query_available_promotion_list(integer_opt(), integer_opt(), client_opt) :: return
  def query_available_promotion_list(
        offset \\ 0,
        limit \\ 2000,
        client \\ Client.new()
      ) do
    params = [first: offset, limit: limit]

    with {:ok, %{code: 200, data: data, info: info}} <-
           Connection.call("QueryAvailablePromotionList", params, client) do
      {:ok, data, info}
    end
  end
end

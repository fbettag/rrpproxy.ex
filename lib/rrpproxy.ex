defmodule RRPproxy do
  @moduledoc """
  Documentation for RRPproxy API integration.

  """

  alias RRPproxy.Client

  defp fix_attrs(attrs) do
    Enum.map(attrs, fn {k, v} ->
      case v do
        true -> {k, "1"}
        false -> {k, "0"}
        other -> {k, other}
      end
    end)
  end

  # Account

  @doc """
  status_account returns information about the accounts financial status.

  """
  def status_account(creds = %Client{} \\ %Client{}) do
    with {:ok, %{code: 200, data: [status]}} <- Client.query("StatusAccount", [], creds) do
      {:ok, status}
    end
  end

  @doc """
  status_registrar returns information about your account information.

  """
  def status_registrar(creds = %Client{} \\ %Client{}) do
    with {:ok, %{code: 200, data: statuses}} <- Client.query("StatusRegistrar", [], creds) do
      {:ok, Enum.find(statuses, fn status -> Map.has_key?(status, :language) end)}
    end
  end

  @doc """
  modify_registrar modifies the registrar's (or subaccounts) settings.

  """
  def modify_registrar(registrar, creds = %Client{} \\ %Client{}) do
    params = Enum.reduce(registrar, [], fn {k, v}, l -> l ++ [{"#{k}", v}] end)

    with {:ok, _} <- Client.query("ModifyRegistrar", params, creds) do
      :ok
    end
  end

  @doc """
  query_appendix_list returns a list of all appendices.

  """
  def query_appendix_list(offset \\ 0, limit \\ 1000, creds = %Client{} \\ %Client{}) do
    params = [{"first", offset}, {"limit", limit}]

    with {:ok, %{code: 200, data: appendices, info: info}} <-
           Client.query("QueryAppendixList", params, creds) do
      {:ok, appendices, info}
    end
  end

  @doc """
  activate_appendix activates an appendix.

  """
  def activate_appendix(
        appendix,
        accept_terms_and_conditions \\ true,
        creds = %Client{} \\ %Client{}
      ) do
    accept_tac =
      if accept_terms_and_conditions do
        1
      else
        0
      end

    params = [{"appendix", appendix}, {"X-ACCEPT-TAC", accept_tac}]

    with {:ok, %{code: 200, data: %{"0": %{email: "successful"}}}} <-
           Client.query("ActivateAppendix", params, creds) do
      :ok
    end
  end

  # Contacts

  @doc """
  query_contact_list returns a list of all contact handles.

  """
  def query_contact_list(offset \\ 0, limit \\ 100, creds = %Client{} \\ %Client{}) do
    params = [{"first", offset}, {"limit", limit}]

    with {:ok, %{code: 200, data: contacts, info: info}} <-
           Client.query("QueryContactList", params, creds) do
      {:ok, Enum.map(contacts, fn contact -> contact.contact end), info}
    end
  end

  @doc """
  get_contact returns a contact handle.

  """
  def status_contact(contact, creds = %Client{} \\ %Client{}) do
    case Client.query("StatusContact", [{"contact", contact}], creds) do
      {:ok, %{code: 200, data: [contact]}} -> {:ok, contact}
      {:ok, %{code: 200, data: [contact, %{status: "ok"}]}} -> {:ok, contact}
      other -> other
    end
  end

  @doc """
  add_contact adds a new contact and returns a contact handle.

  """
  def add_contact(contact, validation \\ true, pre_verify \\ true, creds = %Client{} \\ %Client{}) do
    params =
      Enum.reduce(contact, [], fn {k, v}, l -> l ++ [{"#{k}", v}] end) ++
        [
          {
            "validation",
            if validation do
              1
            else
              0
            end
          }
        ] ++
        [
          {
            "preverify",
            if pre_verify do
              1
            else
              0
            end
          }
        ] ++
        [{"autodelete", 1}]

    with {:ok, %{code: 200, data: [contact]}} <- Client.query("AddContact", params, creds) do
      {:ok, contact}
    end
  end

  @doc """
  modify_contact modifies an existing contact and returns a contact handle.

  """
  def modify_contact(
        contact,
        validation \\ true,
        pre_verify \\ false,
        check_only \\ false,
        creds = %Client{} \\ %Client{}
      ) do
    params =
      Enum.reduce(contact, [], fn {k, v}, l -> l ++ [{"#{k}", v}] end) ++
        [
          {
            "validation",
            if validation do
              1
            else
              0
            end
          }
        ] ++
        [
          {
            "preverify",
            if pre_verify do
              1
            else
              0
            end
          }
        ] ++
        [
          {
            "checkonly",
            if check_only do
              1
            else
              0
            end
          }
        ]

    with {:ok, %{code: 200, data: [contact]}} <- Client.query("ModifyContact", params, creds) do
      {:ok, contact}
    end
  end

  @doc """
  delete_contact deletes a given contact.

  """
  def delete_contact(contact, creds = %Client{} \\ %Client{}) do
    with {:ok, %{code: 200}} <- Client.query("DeleteContact", [{"contact", contact}], creds) do
      :ok
    end
  end

  @doc """
  clone_contact clones the given contact.

  """
  def clone_contact(contact, creds = %Client{} \\ %Client{}) do
    with {:ok, %{code: 200, data: [contact]}} <-
           Client.query("CloneContact", [{"contact", contact}], creds) do
      {:ok, contact}
    end
  end

  @doc """
  restore_contact restores a deleted contact.

  """
  def restore_contact(contact, creds = %Client{} \\ %Client{}) do
    with {:ok, %{code: 200}} <- Client.query("RestoreContact", [{"contact", contact}], creds) do
      :ok
    end
  end

  @doc """
  request_token requests a verification token for the given contact or domain.

  """
  def request_token(people_contact_or_domain, creds = %Client{} \\ %Client{}) do
    params = [{"contact", people_contact_or_domain}, {"type", "ContactDisclosure"}]

    with {:ok, %{code: 200}} <- Client.query("RequestToken", params, creds) do
      :ok
    end
  end

  # Events

  @doc """
  delete_event deletes the given event by id.

  """
  def delete_event(event, creds = %Client{} \\ %Client{}) do
    params = [{"event", event}]

    with {:ok, %{code: 200}} <- Client.query("DeleteEvent", params, creds) do
      :ok
    end
  end

  @doc """
  status_event gets an event by id.

  """
  def status_event(event, creds = %Client{} \\ %Client{}) do
    params = [{"event", event}]

    with {:ok, %{code: 200, data: [event]}} <- Client.query("StatusEvent", params, creds) do
      {:ok, event}
    end
  end

  @doc """
  query_event_list returns a list of events.

  """
  def query_event_list(offset \\ 0, limit \\ 1000, creds = %Client{} \\ %Client{}) do
    params = [{"first", offset}, {"limit", limit}]

    with {:ok, %{code: 200, data: events, info: info}} <-
           Client.query("QueryEventList", params, creds) do
      {:ok,
       Enum.flat_map(events, fn v ->
         e = Map.get(v, :event, [])

         if is_list(e) do
           e
         else
           [e]
         end
       end), info}
    end
  end

  # Domain Tags

  @doc """
  add_tag adds a tags to be used for tagging domains or zones.

  """
  def add_tag(tag, description \\ "", type \\ "domain", creds = %Client{} \\ %Client{}) do
    params = [{"tag", tag}, {"type", type}, {"description", description}]

    with {:ok, %{code: 200}} <- Client.query("AddTag", params, creds) do
      :ok
    end
  end

  @doc """
  modify_tag modifies tags by the given tag name for domains and zones.

  """
  def modify_tag(
        tag,
        params,
        type \\ "domain",
        creds = %Client{} \\ %Client{}
      ) do
    params = [{"tag", tag}, {"type", type}] ++ params

    with {:ok, %{code: 200}} <- Client.query("ModifyTag", params, creds) do
      :ok
    end
  end

  @doc """
  delete_tag deletes a the given tag.

  """
  def delete_tag(tag, type \\ "domain", creds = %Client{} \\ %Client{}) do
    params = [{"tag", tag}, {"type", type}]

    with {:ok, %{code: 200}} <- Client.query("DeleteTag", params, creds) do
      :ok
    end
  end

  @doc """
  status_tag gets the given tag by name.

  """
  def status_tag(tag, type \\ "domain", creds = %Client{} \\ %Client{}) do
    params = [{"tag", tag}, {"type", type}]

    with {:ok, %{code: 200, data: [tag]}} <- Client.query("StatusTag", params, creds) do
      {:ok, tag}
    end
  end

  @doc """
  query_tag_list gets a list of tags.

  """
  def query_tag_list(type \\ "domain", offset \\ 0, limit \\ 1000, creds = %Client{} \\ %Client{}) do
    params = [{"first", offset}, {"limit", limit}]

    with {:ok, %{code: 200, data: tags, info: info}} <-
           Client.query("QueryTagList", params, creds) do
      {:ok,
       Enum.flat_map(tags, fn v ->
         e = Map.get(v, :tag, [])

         if is_list(e) do
           e
         else
           [e]
         end
       end), info}
    end
  end

  # Nameservers

  @doc """
  add_nameserver adds a nameservers to be used for nameserverging domains or zones.

  """
  def add_nameserver(nameserver, ips, creds = %Client{} \\ %Client{}) do
    params =
      [{"nameserver", nameserver}] ++
        Enum.map(Enum.with_index(ips), fn {ip, idx} -> {"ipaddress#{idx}", ip} end)

    with {:ok, %{code: 200}} <- Client.query("AddNameserver", params, creds) do
      :ok
    end
  end

  @doc """
  modify_nameserver modifies nameservers by the given nameserver name for domains and zones.

  """
  def modify_nameserver(nameserver, ips, creds = %Client{} \\ %Client{}) do
    params =
      [{"nameserver", nameserver}] ++
        Enum.map(Enum.with_index(ips), fn {ip, idx} -> {"ipaddress#{idx}", ip} end)

    with {:ok, %{code: 200}} <- Client.query("ModifyNameserver", params, creds) do
      :ok
    end
  end

  @doc """
  delete_nameserver deletes a the given nameserver.

  """
  def delete_nameserver(nameserver, creds = %Client{} \\ %Client{}) do
    params = [{"nameserver", nameserver}]

    with {:ok, %{code: 200}} <- Client.query("DeleteNameserver", params, creds) do
      :ok
    end
  end

  @doc """
  check_nameserver checks a the given nameserver.

  """
  def check_nameserver(nameserver, creds = %Client{} \\ %Client{}) do
    params = [{"nameserver", nameserver}]

    with {:ok, %{code: 200}} <- Client.query("CheckNameserver", params, creds) do
      :ok
    end
  end

  @doc """
  status_nameserver gets the given nameserver by name.

  """
  def status_nameserver(nameserver, creds = %Client{} \\ %Client{}) do
    params = [{"nameserver", nameserver}]

    with {:ok, %{code: 200, data: [nameserver]}} <-
           Client.query("StatusNameserver", params, creds) do
      {:ok, nameserver}
    end
  end

  @doc """
  query_nameserver_list gets a list of nameservers.

  """
  def query_nameserver_list(offset \\ 0, limit \\ 1000, creds = %Client{} \\ %Client{}) do
    params = [{"first", offset}, {"limit", limit}]

    with {:ok, %{code: 200, data: nameservers, info: info}} <-
           Client.query("QueryNameserverList", params, creds) do
      {:ok, Enum.map(nameservers, fn ns -> ns.nameserver end), info}
    end
  end

  # Domains

  @doc """
  query_domain_list returns a list of all registerd domains.

  """
  def query_domain_list(offset \\ 0, limit \\ 1000, creds = %Client{} \\ %Client{}) do
    params = [{"first", offset}, {"limit", limit}]

    with {:ok, %{code: 200, data: domains, info: info}} <-
           Client.query("QueryDomainList", params, creds) do
      {:ok, Enum.map(domains, fn v -> v.domain end), info}
    end
  end

  @doc """
  check_domain checks wether the given domain name is free.

  """
  def check_domain(domain, creds = %Client{} \\ %Client{}) do
    params = [{"domain", domain}]

    case Client.query("CheckDomain", params, creds) do
      {:ok, %{code: 210}} -> {:ok, true}
      {:ok, %{code: 211}} -> {:ok, false}
      other -> other
    end
  end

  @doc """
  status_domain gets the given domain by name.

  """
  def status_domain(domain, creds = %Client{} \\ %Client{}) do
    params = [{"domain", domain}]

    with {:ok, %{code: 200, data: [domain]}} <-
           Client.query("StatusDomain", params, creds, false, true) do
      {:ok, domain}
    end
  end

  @doc """
  add_domain registers a new domain.

  """
  def add_domain(
        domain,
        owner,
        admin,
        tech,
        bill,
        nameservers \\ [],
        period \\ "1",
        creds = %Client{} \\ %Client{}
      ) do
    params =
      [
        {"domain", domain},
        {"period", period},
        {"ownercontact0", owner},
        {"admincontact0", admin},
        {"techcontact0", tech},
        {"billingcontact0", bill}
      ] ++
        Enum.map(Enum.with_index(nameservers), fn {ns, i} -> {"nameserver#{i}", ns} end)

    with {:ok, %{code: 200, data: [data]}} <- Client.query("AddDomain", params, creds) do
      {:ok, data}
    end
  end

  @doc """
  modify_domain modifies domains by the given domain name for domains and zones.

  """
  def modify_domain(domain, attrs \\ [], creds = %Client{} \\ %Client{}) do
    params = [{"domain", domain}] ++ fix_attrs(attrs)

    with {:ok, %{code: 200}} <- Client.query("ModifyDomain", params, creds) do
      :ok
    end
  end

  @doc """
  delete_domain deletes a registered domain.

  """
  def delete_domain(domain, action \\ "instant", creds = %Client{} \\ %Client{}) do
    params = [{"domain", domain}, {"action", String.upcase(action)}]

    with {:ok, %{code: 200, data: [data]}} <- Client.query("DeleteDomain", params, creds) do
      {:ok, data}
    end
  end

  @doc """
  renew_domain renews a registered domain.

  """
  def renew_domain(domain, years \\ 1, creds = %Client{} \\ %Client{}) do
    params = [{"domain", domain}, {"period", years}]

    with {:ok, %{code: 200}} <- Client.query("RenewDomain", params, creds) do
      :ok
    end
  end

  @doc """
  set_auth_code sets the domains auth-code for transfer.

  """
  def set_domain_auth_code(domain, code, creds = %Client{} \\ %Client{}) do
    params =
      [{"domain", domain}, {"auth", code}, {"type", 1}] ++
        if code == "" do
          [{"action", "delete"}]
        else
          [{"action", "set"}]
        end

    with {:ok, %{code: 200}} <- Client.query("SetAuthcode", params, creds) do
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
  def set_domain_renewal_mode(
        domain,
        mode \\ "default",
        token \\ "",
        creds = %Client{} \\ %Client{}
      ) do
    params =
      [{"domain", domain}, {"renewalmode", mode}] ++
        if token == "" do
          []
        else
          [{"token", token}]
        end

    with {:ok, %{code: 200}} <- Client.query("SetDomainRenewalMode", params, creds) do
      :ok
    end
  end

  @doc """
  set_domain_transfer_mode sets the domains transfer-mode.

  The domains mode for transfers: DEFAULT|AUTOAPPROVE|AUTODENY
  """
  def set_domain_transfer_mode(
        domain,
        mode \\ "default",
        token \\ "",
        creds = %Client{} \\ %Client{}
      ) do
    params =
      [{"domain", domain}, {"transfermode", mode}] ++
        if token == "" do
          []
        else
          [{"token", token}]
        end

    with {:ok, %{code: 200}} <- Client.query("SetDomainTransferMode", params, creds) do
      :ok
    end
  end

  @doc """
  restore_domain restores a registered domain.

  """
  def restore_domain(domain, creds = %Client{} \\ %Client{}) do
    params = [{"domain", domain}]

    with {:ok, %{code: 200}} <- Client.query("RestoreDomain", params, creds) do
      :ok
    end
  end

  @doc """
  status_owner_change explicity checks the status of an OwnerChange in detail.

  """
  def status_owner_change(domain, creds = %Client{} \\ %Client{}) do
    params = [{"domain", domain}]

    with {:ok, %{code: 200, data: [data]}} <- Client.query("StatusOwnerChange", params, creds) do
      {:ok, data}
    end
  end

  @doc """
  get_zone returns the correct zone for the given domainname.

  """
  def get_zone(domain, creds = %Client{} \\ %Client{}) do
    params = [{"domain", domain}]

    with {:ok, %{code: 200, data: [data]}} <- Client.query("GetZone", params, creds) do
      {:ok, data.zone}
    end
  end

  @doc """
  get_zone_info returns zone information for the given zone.

  """
  def get_zone_info(domain, creds = %Client{} \\ %Client{}) do
    params = [{"domain", domain}]

    with {:ok, %{code: 200, data: [data]}} <- Client.query("GetZoneInfo", params, creds, true) do
      {:ok, data}
    end
  end

  # transfers

  @doc """
  transfer_domain transfers a foreign domain into our account.

  """
  def transfer_domain(
        domain,
        action \\ "request",
        auth \\ "",
        owner \\ "",
        admin \\ "",
        tech \\ "",
        bill \\ "",
        nameservers \\ [],
        period \\ "1",
        creds = %Client{} \\ %Client{}
      ) do
    period =
      if action == "request" do
        [period: period]
      else
        []
      end

    params =
      [{"domain", domain}, {"action", action}] ++
        period ++
        if auth == "" do
          []
        else
          [{"auth", auth}]
        end ++
        if owner == "" do
          []
        else
          [{"ownercontact0", owner}]
        end ++
        if admin == "" do
          []
        else
          [{"admincontact0", admin}]
        end ++
        if tech == "" do
          []
        else
          [{"techcontact0", tech}]
        end ++
        if bill == "" do
          []
        else
          [{"billingcontact0", bill}]
        end ++
        Enum.map(Enum.with_index(nameservers), fn {ns, i} -> {"nameserver#{i}", ns} end)

    with {:ok, %{code: 200}} <- Client.query("TransferDomain", params, creds) do
      :ok
    end
  end

  @doc """
  query_transfer_list returns a list of local transfers.

  """
  def query_transfer_list(offset \\ 0, limit \\ 2000, creds = %Client{} \\ %Client{}) do
    params = [{"first", offset}, {"limit", limit}]

    with {:ok, %{code: 200, data: data, info: info}} <-
           Client.query("QueryTransferList", params, creds) do
      {:ok, data, info}
    end
  end

  @doc """
  query_foreign_transfer_list returns a list of foreign transfers.

  """
  def query_foreign_transfer_list(offset \\ 0, limit \\ 2000, creds = %Client{} \\ %Client{}) do
    params = [{"first", offset}, {"limit", limit}]

    with {:ok, %{code: 200, data: data, info: info}} <-
           Client.query("QueryForeignTransferList", params, creds) do
      {:ok, data, info}
    end
  end

  @doc """
  status_domain_transfer command informs you about the current status of a transfer.
  You can check if the transfer was successfully initiated or who received the eMail to confirm a transfer.

  """
  def status_domain_transfer(domain, creds = %Client{} \\ %Client{}) do
    params = [{"domain", domain}]

    with {:ok, %{code: 200, data: [data]}} <- Client.query("StatusDomainTransfer", params, creds) do
      {:ok, data}
    end
  end

  # Finance

  @doc """
  query_zone_list returns the prices per zone.

  """
  def query_zone_list(offset \\ 0, limit \\ 2000, creds = %Client{} \\ %Client{}) do
    params = [{"first", offset}, {"limit", limit}]

    with {:ok, %{code: 200, data: prices, info: info}} <-
           Client.query("QueryZoneList", params, creds) do
      {:ok, prices, info}
    end
  end

  @doc """
  query_accounting_list returns all items for accounting since the given date.

  """
  def query_accounting_list(date, offset \\ 0, limit \\ 2000, creds = %Client{} \\ %Client{}) do
    params = [{"mindate", date}, {"first", offset}, {"limit", limit}]

    with {:ok, %{code: 200, data: data, info: info}} <-
           Client.query("QueryAccountingList", params, creds) do
      {:ok, data, info}
    end
  end

  @doc """
  query_upcoming_accounting_list returns all items that are upcoming for accounting.

  """
  def query_upcoming_accounting_list(offset \\ 0, limit \\ 2000, creds = %Client{} \\ %Client{}) do
    params = [{"first", offset}, {"limit", limit}]

    with {:ok, %{code: 200, data: data, info: info}} <-
           Client.query("QueryUpcomingAccountingList", params, creds) do
      {:ok, data, info}
    end
  end

  @doc """
  convert_currency converts the currency according to their current rates.

  """
  def convert_currency(amount, from, to \\ "EUR", creds = %Client{} \\ %Client{}) do
    params = [{"amount", amount}, {"from", from}, {:to, to}]

    with {:ok, %{code: 200, data: [conv]}} <- Client.query("ConvertCurrency", params, creds) do
      {:ok, conv.converted_amount, conv.rate}
    end
  end

  @doc """
  query_available_promotion_list returns all available promotions.

  """
  def query_available_promotion_list(offset \\ 0, limit \\ 2000, creds = %Client{} \\ %Client{}) do
    params = [{"first", offset}, {"limit", limit}]

    with {:ok, %{code: 200, data: data, info: info}} <-
           Client.query("QueryAvailablePromotionList", params, creds) do
      {:ok, data, info}
    end
  end
end

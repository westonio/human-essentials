class OrganizationUpdateService
  class << self
    FIELDS = %i[
      enable_child_based_requests
      enable_individual_requests
      enable_quantity_based_requests
    ]

    # @param organization [Organization]
    # @param params [ActionDispatch::Http::Parameters]
    # @return [Boolean]
    def update(organization, params)
      return false unless valid?(organization, params)

      result = organization.update(params)
      return false unless result

      update_partner_flags(organization)
      true
    end

    # @param organization [Organization]
    def update_partner_flags(organization)
      FIELDS.each do |field|
        # We don't want to automatically enable request types
        # on a partner. This should be left up to 
        # individual partners to decide themselves
        # github.com/rubyforgood/human-essentials/issues/3264
        next if organization.send(field)
        organization.partners.map(&:profile).each do |profile|
          profile.update!(field => organization.send(field))
        end
      end
    end

    private

    def valid?(organization, params)
      return true if organization.partners.none?

      fields_marked_for_disabling = FIELDS.select { |field| params[field] == false }

      organization.partners.none? do |partner|
        all_fields_will_be_disabled?(partner, fields_marked_for_disabling)
      end
    end

    def all_fields_will_be_disabled?(partner, fields_marked_for_disabling)
      enabled_fields = FIELDS.select { |field| partner.profile.send(field) == true }

      (enabled_fields - fields_marked_for_disabling).empty?
    end
  end
end

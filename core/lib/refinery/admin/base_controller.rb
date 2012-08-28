require 'action_controller'

module Refinery
  module Admin
    module BaseController

      extend ActiveSupport::Concern

      included do
        layout :layout?

        before_filter :authenticate_user!, :restrict_plugins, :restrict_controller

        helper_method :searching?, :group_by_date
      end

      def admin?
        true # we're in the admin base controller, so always true.
      end

      def searching?
        params[:search].present?
      end

    protected

      def group_by_date(records)
        new_records = []

        records.each do |record|
          key = record.created_at.strftime("%Y-%m-%d")
          record_group = new_records.collect{|records| records.last if records.first == key }.flatten.compact << record
          (new_records.delete_if {|i| i.first == key}) << [key, record_group]
        end

        new_records
      end

      def restrict_plugins
        current_length = (plugins = refinery_current_user.authorized_refinery_plugins).length

        # Superusers get granted access if they don't already have access.
        if refinery_current_user.has_refinery_role?(:superuser)
          if (plugins = plugins | ::Refinery::Plugins.registered.names).length > current_length
            refinery_current_user.refinery_plugins = plugins
          end
        end

        ::Refinery::Plugins.set_active(plugins)
      end

      def restrict_controller
        unless allow_controller? params[:controller].gsub 'admin/', ''
          logger.warn "'#{current_refinery_user.username}' tried to access '#{params[:controller]}' but was rejected."
          error_404
        end
      end

    private

      def allow_controller?(controller_path)
        ::Refinery::Plugins.active.any? {|plugin|
          Regexp.new(plugin.menu_match) === controller_path
        }
      end

      def layout?
        "refinery/admin#{'_dialog' if from_dialog?}"
      end

      # Override authorized? so that only users with the Refinery role can admin the website.
      def authorized?
        refinery_user?
      end
    end
  end
end

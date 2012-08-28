Refinery::Core::Engine.config.to_prepare do
  Refinery.user_class.class_eval do
    # extend FriendlyId # Still need to figure out what to do with this

    has_and_belongs_to_many :refinery_roles,
                            :join_table => :refinery_roles_users,
                            :foreign_key => :user_id,
                            :class_name => "Refinery::Role"

    has_many :refinery_plugins, :class_name => "Refinery::UserPlugin", :order => "position ASC", :dependent => :destroy
    # friendly_id :username, :use => [:slugged] # Still need to figure out what to do with this

    def add_refinery_role(title)
      roles << ::Refinery::Role[title.to_s] unless has_refinery_role?(title)
    end

    def authorized_refinery_plugins
      refinery_plugins.collect(&:name) | ::Refinery::Plugins.always_allowed.names
    end

    def can_delete_refinery_user?(user_to_delete = self)
      user_to_delete.persisted? &&
        !user_to_delete.has_refinery_role?(:superuser) &&
        ::Refinery::Role[:refinery].users.any? &&
        id != user_to_delete.id
    end

    def can_edit_refinery_user?(user_to_edit = self)
      user_to_edit.persisted? &&
        (user_to_edit == self || self.has_refinery_role?(:superuser))
    end

    # has_refinery_role? simply needs to return true or false whether a user has a role or not.
    def has_refinery_role?(role_in_question)
      refinery_roles.where(:title => role_in_question.to_s).any?
    end

    def refinery_plugins=(plugin_names)
      if persisted? # don't add plugins when the user_id is nil.
        Refinery::UserPlugin.delete_all(:user_id => id)

        plugin_names.each_with_index do |plugin_name, index|
          refinery_plugins.create(:name => plugin_name.to_s, :position => index)
        end
      end
    end
  end
end
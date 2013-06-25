module Reactor::OptionallySubclassable
  extend ActiveSupport::Concern

  module ClassMethods
    def find_sti_class(type_name)
      begin
        ActiveSupport::Dependencies.constantize(type_name)
      rescue NameError
        self
      end
    end
  end
end

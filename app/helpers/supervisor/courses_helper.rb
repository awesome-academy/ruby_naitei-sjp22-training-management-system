module Supervisor
  module CoursesHelper
    def build_statuses
      Course.statuses.map do |key, _value|
        [t(key, scope: "courses.statuses"), key.to_sym]
      end
    end

    def search_type_options
      [
        [t(".courses"), :courses],
        [t(".creators"), :creators]
      ]
    end

    def status_filter_options
      all_option = [[t(".all_statuses"), ""]]
      all_option + build_statuses
    end
  end
end

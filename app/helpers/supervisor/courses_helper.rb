module Supervisor
  module CoursesHelper
    def build_statuses
      Course.statuses.map do |key, value|
        [t(key, scope: "courses.statuses"), value]
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

    def trainee_range_options
      [
        ["0 - 10", "0-10"],
        ["11 - 20", "11-20"],
        ["21 - 30", "21-30"],
        ["31+", "31+"]
      ]
    end

    def user_status_options
      [
        [t(".status_all"), nil],
        [t(".status_inactive"), true],
        [t(".status_active"), false]
      ]
    end
  end
end

require 'rails_helper'

RSpec.describe Admin::DashboardsController, type: :controller do
  let!(:admin_user) { create(:user, :admin) }
  let!(:supervisors) { create_list(:user, 3, role: :supervisor) }
  let!(:trainees) { create_list(:user, 5, role: :trainee) }
  let!(:finished_courses) { create_list(:course, 2, status: :finished) }
  let!(:in_progress_courses) { create_list(:course, 3, status: :in_progress) }

  before do
    sign_in admin_user
    get :index
  end

  describe "GET #index" do
    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "assigns the correct number of trainers" do
      expect(assigns(:overview_stats)[:trainers]).to eq(User.supervisor.count)
    end

    it "assigns the correct number of trainees" do
      expect(assigns(:overview_stats)[:trainees]).to eq(User.trainee.count)
    end

    it "assigns the correct number of active courses" do
      expect(assigns(:overview_stats)[:active_courses]).to eq(Course.in_progress.count)
    end

    it "assigns the correct completion rate" do
      expected_rate = (Course.finished.count.to_f / Course.count * Settings.percentage).round
      expect(assigns(:overview_stats)[:completion_rate]).to eq("#{expected_rate}%")
    end

    it "assigns @courses with active courses" do
      expect(assigns(:courses)).to match_array(Course.in_progress)
    end

    it "assigns a pagy object" do
      expect(assigns(:pagy)).to be_a(Pagy)
    end

    it "pagy object has correct total count" do
      expect(assigns(:pagy).count).to eq(Course.in_progress.count)
    end

    context "with valid pagination params" do
      let(:per_page) { Settings.ui.items_per_page }
      let(:page) { 2 }

      before do
        Course.where(status: :in_progress).delete_all
        create_list(:course, 20, :in_progress)
        sign_in admin_user
        get :index, params: { page: page }
      end

      it "assigns the correct number of courses per page" do
        expect(assigns(:courses).size).to eq(per_page)
      end

      it "assigns the correct page of courses" do
        expected_ids = Course.where(status: :in_progress)
                            .order(created_at: :desc)
                            .limit(per_page)
                            .offset((page - 1) * per_page)
                            .pluck(:id)
        actual_ids = assigns(:courses).map(&:id)
        expect(actual_ids).to eq(expected_ids)
      end

      it "assigns a pagy object" do
        expect(assigns(:pagy)).to be_a(Pagy)
      end

      it "pagy object has correct total count" do
        expect(assigns(:pagy).count).to eq(Course.where(status: :in_progress).count)
      end
    end
  end
end

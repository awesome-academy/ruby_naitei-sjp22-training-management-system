class Supervisor::CategoriesController < Supervisor::BaseController
  before_action (lambda do
    load_category(with_position: true)
  end), only: %i(show edit update)
  before_action -> {load_category}, only: %i(destroy)

  # GET /supervisor/categories
  def index
    @pagy, @categories = pagy Category.includes(:subjects)
                                      .recent
                                      .search_by_name(params[:search]),
                              items: Settings.ui.items_per_page
  end

  # DELETE /supervisor/categories/:id
  def destroy
    if @category.destroy
      flash[:success] = t(".category_deleted")
    else
      flash[:danger] = t(".delete_failed")
    end
    redirect_to supervisor_categories_path
  end

  # GET /supervisor/categories/new
  def new
    @category = Category.new
    @category.subject_categories.build
  end

  # POST /supervisor/categories
  def create
    @category = Category.new category_params

    if @category.save
      flash[:success] = t(".create_success")
      redirect_to supervisor_categories_path
    else
      flash.now[:danger] = t(".create_fail")
      render :new, status: :unprocessable_entity
    end
  end

  # GET /supervisor/categories/:id
  def show; end

  # GET /supervisor/categories/:id/edit
  def edit
    @category = Category.includes(subject_categories: :subject)
                        .find(params[:id])
  end

  # PATCH /supervisor/categories/:id
  def update
    if @category.update(category_params)
      flash[:success] = t(".update_success")
      redirect_to supervisor_category_path(@category)
    else
      flash.now[:danger] = t(".update_fail")
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def load_category with_position: false
    @category = Category.includes(subject_categories: :subject)
                        .find_by(id: params[:id])

    unless @category
      flash[:danger] = t("not_found_category")
      redirect_to supervisor_categories_path
    end

    return unless with_position

    @subject_categories = @category.subject_categories.ordered_by_position
  end

  def category_params
    params.require(:category).permit Category::CATERGORY_PERMITTED_PARAMS
  end
end

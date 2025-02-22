class ShopsController < ApplicationController
  before_action :set_user
  before_action :set_shop, only: [:show]
  before_action :check_shop_exist, only: [:new, :create]

  def show
    @products = ShopPolicy::Scope.new(current_user, Product.where(shop: @shop)).resolve(@user).includes(:shop).with_attached_images
    @products_best_seller = @shop.products.limit(4).includes(:shop).with_attached_images
    @pagy, @products = pagy(@products, items: 12)
  end

  def new
    @shop_registration = ShopRegistrationForm.new
    authorize @shop_registration, policy_class: ShopPolicy
  end

  def create
    @shop_registration = ShopRegistrationForm.new(shop_registration_params.merge(user: @user))
    authorize @shop_registration, policy_class: ShopPolicy

    if CreateStoreService.call(@shop_registration)
      flash[:success] = "Congratulations! You have successfuly open your own shop on Golden Mall!"
      redirect_to user_shop_path(@user)
    else
      flash[:error] = "Cannot create your shop"
      render :new
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_shop
    @shop = @user.shop
    authorize @shop
  end

  def shop_params
    params.require(:shop).permit(:name, :description, :phone)
  end

  def shop_registration_params
    params.require(:shop_registration_form).permit(:name, :description, :phone, :city_code, :district_code, :ward_code, :street_name)
  end

  def check_shop_exist
    if @user.shop.present?
      flash[:error] = "You have already open a shop!"
      redirect_back(fallback_location: root_path)
    end
  end
end

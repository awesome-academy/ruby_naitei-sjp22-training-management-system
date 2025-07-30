class MicropostsController < ApplicationController
  # GET /microposts
  def index
    @microposts = Micropost.recent
  end
end

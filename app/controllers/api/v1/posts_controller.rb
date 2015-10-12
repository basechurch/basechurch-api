class Api::V1::PostsController < ApplicationController
  include DeviseTokenAuth::Concerns::SetUserByToken
  before_action :authenticate_user!, except: [:show]

  def sign
    signed_response = S3Signer.new.sign(type: params[:type], directory: "posts")
    render json: signed_response, status: :ok
  end
end

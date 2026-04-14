module Api
  class BaseController < ActionController::API
    before_action :authenticate_api_key!

    private

    def authenticate_api_key!
      expected = ENV["SUMMARY_API_KEY"].presence
      provided = request.headers["X-Api-Key"]

      if expected.nil? || provided != expected
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end

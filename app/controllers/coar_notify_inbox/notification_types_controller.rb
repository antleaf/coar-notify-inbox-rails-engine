module CoarNotifyInbox
  class NotificationTypesController < ApplicationController
    before_action :set_notification_type, only: [:show, :update, :destroy]
    load_and_authorize_resource

    # GET /notification_types
    def index
      @notification_types = NotificationType.all
      render json: @notification_types
    end

    # GET /notification_types/:id
    def show
      render json: @notification_type
    end

    # POST /notification_types
    def create
      @notification_type = NotificationType.new(notification_type_params)

      if @notification_type.save
        render json: @notification_type, status: :created
      else
        render json: { errors: @notification_type.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PUT /notification_types/:id
    def update
      if @notification_type.update(notification_type_params)
        render json: @notification_type
      else
        render json: { errors: @notification_type.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /notification_types/:id
    def destroy
      @notification_type.destroy
      head :no_content
    end

    private

    def set_notification_type
      @notification_type = NotificationType.find(params[:id])
    end

    def notification_type_params
      params.require(:notification_type).permit(:notification_type)
    end
  end
end

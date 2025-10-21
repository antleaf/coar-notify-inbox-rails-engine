module CoarNotifyInbox
  class SendersController < ApplicationController
    before_action :set_sender, only: [:show, :update, :destroy]

    def index
      @senders = Sender.all
      render json: @senders
    end

    def show
      render json: @sender, include: :targets
    end

    def create
      @sender = Sender.new(sender_params)
      update_targets(@sender)
      if @sender.save
        render json: @sender, status: :created
      else
        render json: { errors: @sender.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @sender.update(sender_params)
        update_targets(@sender)
        render json: @sender
      else
        render json: { errors: @sender.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @sender.destroy
      head :no_content
    end

    private

    def set_sender
      @sender = Sender.find(params[:id])
    end

    # Handle association updates (OwnerTarget join table)
    def update_targets(sender)
      return unless params[:targets].present?

      target_ids = params[:targets].map { |t| t[:id] }.compact

      # Replace existing associations cleanly
      sender.owner_targets.destroy_all

      target_ids.each do |tid|
        sender.owner_targets.create(target_id: tid)
      end
    end

    def sender_params
      params.require(:sender).permit(:user_id, :origin_id)
    end
  end
end

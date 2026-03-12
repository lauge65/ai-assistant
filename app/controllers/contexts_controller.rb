class ContextsController < ApplicationController
  before_action :authenticate_user!
  belongs_to :user
  has_one :chat, dependent: :destroy

  def index
    @contexts = current_user.contexts
  end

  def show
    @context = current_user.contexts.find(params[:id])
  end


  def new
   @context = Context.new
  end

 def create
  @context =current_user.contexts.new(context_params)
  if @context.save
    redirect_to context_path(@context)
  else
    render :new, status: :unprocessable_entity
  end

 end

 private

 def context_params
  params.require(:context).permit(:title, :level, :subject, :date, :document )
 end
end

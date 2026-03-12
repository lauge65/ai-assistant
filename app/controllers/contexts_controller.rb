class ContextsController < ApplicationController
  before_action :authenticate_user!
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

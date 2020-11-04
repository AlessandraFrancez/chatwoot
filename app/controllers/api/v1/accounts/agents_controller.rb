class Api::V1::Accounts::AgentsController < Api::V1::Accounts::BaseController
  before_action :fetch_agent, except: [:create, :index]
  before_action :check_authorization
  before_action :find_user, only: [:create]
  before_action :create_user, only: [:create]
  before_action :save_account_user, only: [:create]

  def index
    @agents = agents
  end

  def destroy
    @agent.current_account_user.destroy
    head :ok
  end

  def update
    @agent.update!(agent_params.except(:role, :limits))
    @agent.current_account_user.update!(role: agent_params[:role]) if agent_params[:role]
    @agent.current_account_user.update!(limits: agent_params[:limits]) if agent_params[:limits]
    render partial: 'api/v1/models/agent.json.jbuilder', locals: { resource: @agent }
  end

  def create
    render partial: 'api/v1/models/agent.json.jbuilder', locals: { resource: @user }
  end

  private

  def check_authorization
    authorize(User)
  end

  def fetch_agent
    @agent = agents.find(params[:id])
  end

  def find_user
    @user =  User.find_by(email: new_agent_params[:email])
  end

  def create_user
    return if @user

    @user = User.create!(new_agent_params.slice(:email, :name, :password, :password_confirmation))
  end

  def save_account_user
    AccountUser.create!(
      account_id: Current.account.id,
      user_id: @user.id,
      role: new_agent_params[:role],
      limits: new_agent_params[:limits],
      inviter_id: current_user.id
    )
  end

  def agent_params
    params.require(:agent).permit(:email, :name, :role, :limits)
  end

  def new_agent_params
    time = Time.now.to_i
    params.require(:agent).permit(:email, :name, :role, :limits)
          .merge!(password: time, password_confirmation: time, inviter: current_user)
  end

  def agents
    @agents ||= Current.account.users.order_by_full_name
    Rails.logger.info "CURRENT AGENT GETTING: #{Current.account.users.find(3).limits}"
  end
end

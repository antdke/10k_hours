class PostsController < ApplicationController
  include ActiveStorage::SetCurrent
  include Pagy::Backend

  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:edit, :update, :show, :destroy]
  before_action :filter_posts, only: [:index]
  before_action :set_pagination_posts, only: [:show]

  def index
    @featured_posts = Post.featured
    @pagy, @posts = pagy(@filtered_posts)
  end

  def new
    @post = current_user.posts.new
  end

  def edit
  end

  def update
    @post.update(post_params)
    redirect_to post_path(@post.slug), notice: 'Post updated'
  end

  def create
    post = current_user.posts.create!(post_params)
    redirect_to post_path(post.slug), notice: 'Post created'
  end

  def show
  end

  def destroy
    @post.destroy
    redirect_to dashboard_index_path, notice: 'Post deleted'
  end

  private

  def set_post
    @post = Post.find_by(slug: params[:id])
    @post = Post.find_by(id: params[:id]) if @post.nil?

    redirect_to root_path, error: 'Post not found' if @post.nil?
  end

  # filters for non-recurring (or "regular") published posts and orders them from newest to oldest
  # creates a collection of these posts for pagy to paginate through
  def set_pagination_posts
    @pagination_posts = Post.published.non_recurring.newest_to_oldest
    @pagy, @older_posts = pagy(@pagination_posts.where("id > ?", @post.id))
    @pagy, @newer_posts = pagy(@pagination_posts.where("id < ?", @post.id))
  end

  # improves UI when many recurring tasks exist sequentially without a regular update
  def filter_posts(post_ids = [])
    posts = Post.published.newest_to_oldest

    posts.each_with_index do |post, idx|
      next if post.recurring_id? && posts[idx - 1].recurring_id?
      post_ids << post.id
    end

    @filtered_posts = Post.where(id: post_ids).newest_to_oldest
  end

  def post_params
    params.require(:post).permit(:title, :meta_description, :content, :dollars, :hours, :visibility, :published_at, :featured, :recurring, :recurring_rule)
  end
end

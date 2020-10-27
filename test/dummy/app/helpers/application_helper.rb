module ApplicationHelper
  def pagination_nav(cursor, params = {})
    render "layouts/pagination_nav", cursor: cursor, params: params
  end
end

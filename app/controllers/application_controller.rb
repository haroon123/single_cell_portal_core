class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :get_download_quota

  # auth action for portal admins
  def authenticate_admin
    unless current_user.admin
      redirect_to site_path, alert: 'You do not have permission to access that page.' and return
    end
  end

  # retrieve the current download quota
  def get_download_quota
    config_entry = AdminConfiguration.find_by(config_type: 'Daily User Download Quota')
    if config_entry.nil? || config_entry.value_type != 'Numeric'
      # fallback in case entry cannot be found or is set to wrong type
      @download_quota = 2.terabytes
    else
      @download_quota = config_entry.convert_value_by_type
    end
  end

  # check whether downloads/study editing has been revoked and prevent user access
  def check_access_settings
    redirect = request.referrer.nil? ? site_path : request.referrer
    downloads_enabled = AdminConfiguration.firecloud_access_enabled?
    if !downloads_enabled
      redirect_to redirect, alert: "Study access has been temporarily disabled by the site adminsitrator.  Please contact #{view_context.mail_to('single_cell_portal@broadinstitute.org')} if you require assistance." and return
    end
  end

  # load default study options for updating
  def set_study_default_options
    @default_cluster = @study.default_cluster
    @default_cluster_annotations = {
        'Cluster-based' => @default_cluster.cell_annotations.map {|annot| ["#{annot[:name]}", "#{annot[:name]}--#{annot[:type]}--cluster"]},
        'Study Wide' => @study.study_metadata.map {|metadata| ["#{metadata.name}", "#{metadata.name}--#{metadata.annotation_type}--study"] }.uniq
    }
  end
end

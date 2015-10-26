class ArchivesSpaceService < Sinatra::Base

  include ReportHelper::ResponseHelpers

  ReportManager.registered_reports.each do |uri_suffix, opts|

    Endpoint.get("/repositories/:repo_id/reports/#{uri_suffix}")
    .description(opts[:description])
    .params(*(opts[:params] << ReportHelper.report_formats << ["repo_id", :repo_id]))
    .permissions([])
    .returns([200, "report"]) \
    do
      report_response(opts[:model].new(params), params[:format])
    end

  end

end

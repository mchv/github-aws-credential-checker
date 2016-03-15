require 'httparty'
require 'sinatra'
require 'json'

post '/payload' do
  push = JSON.parse(request.body.read) # parse the JSON
  repo_name = push['repository']['full_name']

  # look through each commit message
  push["commits"].each do |commit|

    # Look for an AWS access key
    # See https://blogs.aws.amazon.com/security/blog/tag/key+rotation for the pattern
    if /(?<![A-Z0-9])[A-Z0-9]{20}(?![A-Z0-9])/.match commit['message']
      state = 'failure'
      description = 'It looks like you commit a AWS access key. Please review your changes!'
    else
      state = 'success'
      description = 'Ave, I did not find any AWS credentials!'
    end

    # post status to GitHub
    sha = commit["id"]
    status_url = "https://api.github.com/repos/#{repo_name}/statuses/#{sha}"

    status = {
      "state"       => state,
      "description" => description,
      "target_url"  => "https://github.com/mchv/github-aws-credential-checker",
      "context"     => "validate/no-credentials-in-commits"
    }
    HTTParty.post(status_url,
      :body => status.to_json,
      :headers => {
        'Content-Type'  => 'application/json',
        'User-Agent'    => 'mchv/github-aws-credential-checker',
        'Authorization' => "token #{ENV['TOKEN']}" }
    )
  end
end
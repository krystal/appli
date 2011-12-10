## Requires the Appli deployment recipes, do not remove this line or your
## deployments will not work.
require 'appli/deploy'

## The path on the server where you wish to deploy your application.
set :deploy_to, "/opt/apps/default"

## The repository from which you wish to deploy your application
## from should be entered here.
set :repository, "git@github.com:atech/appli.git"

## Defines the database credentials here (excluding the password) as
## these will be used as part of your setup process.
set :database_host, ""
set :database_name, ""
set :database_user, ""

## The servers you wish to deploy to. The server with the 'database_ops'
## parameter will be the one where database operations (migrations) are
## executed.
role :app, "", :database_ops => true

require 'sinatra'

set :bind, '0.0.0.0'

get '/' do
    'Hola mundo'
end
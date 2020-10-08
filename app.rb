# Ingreso de las librerías necesarias para la funcionalidad
# de la aplicación web.
require 'sinatra'
require 'twilio-ruby'

# Se definen los orígenes (IPs) que el servidor puede procesar
set :bind, '0.0.0.0'

# Definición de credenciales necesarias para consumir Apis de Twlio
auth_token  = ENV['TWILIO_AUTH_TOKEN']
account_sid = ENV['TWILIO_ACCOUNT_SID']

# Método principal, donde se introduce al usuario al menú principal
get '/' do
    Twilio::TwiML::VoiceResponse.new do |respuesta|
        respuesta.say(message: 'Bienvenido a Misterr. Nodo, por favor escuche nuestro menú', voice: 'woman', language: 'es-MX')
    end
end
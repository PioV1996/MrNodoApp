# Ingreso de las librerías necesarias para la funcionalidad
# de la aplicación web.
require 'sinatra'
require 'twilio-ruby'

# Se definen los orígenes (IPs) que el servidor puede procesar
set :bind, '0.0.0.0'

# Definición de credenciales necesarias para consumir Apis de Twlio
auth_token  = 
account_sid = 

# Método principal, donde se introduce al usuario al menú principal, y da infromación acerca de Mr. Nodo
get '/' do
    content_type 'text/xml'
    Twilio::TwiML::VoiceResponse.new do |respuesta|
        respuesta.say(message: 'Bienvenido a Mister Nodo', voice: 'woman', language: 'es-MX')
        respuesta.say(message: 'Mister Nodo ofrece servicios de instalación y configuración de sistemas operativos, ' + 
        'así como la realización de mantenimiento correctivo y preventivo a equipos de cómputo, contamos con un equipo' +
        ' de profesionales capacitados para resolver desde los problemas más comunes, hasta aquellos que requiere de una mayor' +
        ' atención. Estamos a sus órdenes en un horario de 9 de la mañana a 6 de la tarde, de lunes a viernes. Por favor' + 
        ' escuche nuestro menú', voice: 'woman', language: 'es-MX')
        respuesta.redirect('/menu', method: 'get')
    end.to_s
end

# Se define el método del menú, el cual define las opciones que el usuario puede elegir conforme las necesidades de dicho usuario
# Se hace uso del verbo "gather", el cual lee el dígito ingresado por el usuario, y a su vez redirecciona a la ruta definida
# en "action" dentro de sus parámetros
get '/menu' do
    content_type 'text/xml'
    Twilio::TwiML::VoiceResponse.new do |respuesta|
        respuesta.gather(numDigits: 1, action: '/eleccion', method: 'get') do |g|
            g.say(message: 'Para hablar con un ejecutivo, marque 1 ', voice: 'woman', language: 'es-MX')
        end
        respuesta.redirect('/menu', method: 'get')
    end.to_s
end

# Se define el método para procesar la opción elegida por el usuario.
# En caso de no ingresar una opción válida, se redirige de nuevo al menú para ingresar un número asignado a una acción determinada
get '/eleccion' do
    content_type 'text/xml'
    if params['Digits']
        
    else
        Twilio::TwiML::VoiceResponse.new do |respuesta|
            respuesta.say(message: 'Opción inválida', voice: 'woman', language: 'es-MX')
        end
    end
end
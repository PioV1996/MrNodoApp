# Ingreso de las librerías necesarias para la funcionalidad
# de la aplicación web.
require 'sinatra'
require 'twilio-ruby'

# Añadiendo librerías necesarias para la creación de tablas en la base de datos.
require 'active_record'
require 'sinatra/activerecord' 


# Se definen los orígenes (IPs) que el servidor puede procesar
set :bind, '0.0.0.0'

# Se inicializan las variable globales para almancenar las llamadas entrantes y que son trasladados a espera
$numeros = Array.new
$id = ''
$id_queue = ''

# Definición de credenciales necesarias para consumir Apis de Twlio
auth_token  = ''
account_sid = ''

# Creación de variable global $cliente, el cual interactua con la información que la cuenta maneja, tal como las llamadas que están en espera, o los 
# identificadores únicos para cada número telefónico que llama al número asignado por Twilio
$cliente = Twilio::REST::Client.new(account_sid, auth_token)


# Módulo principal, donde se introduce al usuario al menú principal, y da infromación acerca de Mr. Nodo
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

# Se define el módulo del menú, el cual define las opciones que el usuario puede elegir conforme las necesidades de dicho usuario
# Se hace uso del verbo "gather", el cual lee el dígito ingresado por el usuario, y a su vez redirecciona a la ruta definida
# en "action" dentro de sus parámetros
get '/menu' do
    content_type 'text/xml'
    Twilio::TwiML::VoiceResponse.new do |respuesta|
        respuesta.gather(numDigits: 1, action: '/eleccion', method: 'get') do |g|
            g.say(message: 'Para hablar con un ejecutivo, marque 1 ' + 
                           ' Para dejar un mensaje de voz a nuestros asesores, marque 2', voice: 'woman', language: 'es-MX')
        end
        respuesta.redirect('/menu', method: 'get')
    end.to_s
end

# Se define el módulo para procesar la opción elegida por el usuario.
# En caso de no ingresar una opción válida, se redirige de nuevo al menú para ingresar un número asignado a una acción determinada
get '/eleccion' do
    content_type 'text/xml'
    if params['Digits']
        digito = params['Digits']

        case digito
        # Cuando se seleccione la primera opción del menú, el usuario sera redireccionado al módulo para conectar con un ejecutvo
        # de Mr. Nodo.
        when '1'
            content_type 'text/xml'
            Twilio::TwiML::VoiceResponse.new do |r|
                r.say(message: 'Será comunicado en un momento', voice: 'woman', language: 'es-MX')
                r.redirect('/conectar', method: 'get')
            end.to_s
        # Si se selecciona el número "2" en el menú principal, la aplicación es redireccionada al módulo correspondiente para 
        # que el usuario deje un mensaje al usuario.
        when '2'
            content_type 'text/xml'
            Twilio::TwiML:VoiceResponse.new do |r|
                r.redirect('/mensaje', method: 'post')
            end.to_s
        # Si el usuario ingresa una opción no listada en el menú principal, será advertido por un mensaje, y se le redirige para
        # volver a ingresar un dígito válido.
        else
            content_type 'text/xml'
            Twilio::TwiML::VoiceResponse.new do |r|
                r.say(message: 'Opción no válida', voice: 'woman', language: 'es-MX')
                r.redirect('/menu', method: 'get')
            end.to_s
        end
    else
        Twilio::TwiML::VoiceResponse.new do |respuesta|
            respuesta.say(message: 'Opción inválida', voice: 'woman', language: 'es-MX')
            respuesta.redirect('/menu', method: 'get')
        end.to_s
    end
end

# Se define el módulo conectar, el cual está encargado de hacer la conexión entre el usuario y los asesores de Mr. Nodo, en caso de que no haya
# nadie disponible, el usuario es llevado a una lista de espera, donde se le informa al usuario que deberá esperar para ser atendido.
get '/conectar' do
    content_type 'text/xml'
    $id = params['CallSid']
    espera = $cliente.queues($id_queue.to_s).fetch
    if espera.current_size == 0
        Twilio::TwiML::VoiceResponse.new do |r|
            r.say(message: 'No hay asesor disponible, será puesto en una lista de espera.', voice:'woman', language: 'es-MX')
            r.redirect('/espera', method: 'get')
        end.to_s
    else
        content_type 'text/xml'
        comunicar = $numeros.shift
        Twilio::TwiML::VoiceResponse.new do |r|
            r.dial do |d|
                d.queue(comunicar.to_s, url: '/conectando')
            end
        end.to_s
    end
end

# Se define el módulo de espera, el cual crea la espera por medio del verbo "enqueue", el cual crea un identificador único, el cual es tomado para 
# comunicar con la persona que este disponible para atender, dicho identificador es almacenado en un Array de n elementos.
get '/espera' do
    content_type 'text/xml'
    $numeros.push($id)
    Twilio::TwiML::VoiceResponse.new do |r|
        r.enqueue(wait_url: '/cola', name: $id)
    end.to_s
end

# Módulo al que se accede cuando el usuario entra en espera para ser atendido, el cual recuepra el identificado de la espera, para posteriormente 
# ser comunicado una vez que haya alguien disponible, y reproduce un audio para el usuario.
post '/cola' do
    content_type 'text/xml'
    $id_queue = params['QueueSid']
    Twilio::TwiML::VoiceResponse.new do |r|
        r.say(message: 'Espere un momento por favor, un asesor le atenderá', voice: 'woman', language: 'es-MX')
        r.play(loop:10 , url: 'https://api.twilio.com/cowbell.mp3')
    end.to_s
end

# Se define el módulo "conectando", el cual informa al usuario que será conectado con con el asesor disponible
post "/conectando" do
    Twilio::TwiML::VoiceResponse.new do |r|
        r.say(message: 'Está siendo comunicado, espere un momento por favor', voice: 'woman', language: 'es-MX')
    end.to_s
end

# Módulo para la grabación del mensaje de voz del usuario, el cual es informado acerca de los detalles que debe dejar en su mensaje, así como .
# el botón para finalizar la grabación.
# Una vez se haya realizado esta acción, se redirige al módulo "/enviar" para realizar el registro de la llamada 
post '/mensaje' do
    Twilio::TwiML::VoiceResponse.new do |r|
        r.say('Por favor, proporcione su nombre completo, así como el motivo de su llamada, y algún telefóno para poder comunicarnos' + 
        ' lo más pronto posible', voice: 'woman', language: 'es-MX')
        r.record(action: '/enviar', method: 'post', finish_on_key: '#')
    end.to_s
end

post '/enviar' do
    if params['RecordingUrl']
        @url = params['RecordingUrl']
        @tiempo = Time.now()
        @numero = params['From']
        llamada = [{
            telefono: @numero,
            fecha: @tiempo
            link: @url
        }]
        llamada.each do |c|
            c.create()
        end
    end
end
    Twilio::TwiML::VoiceResponse.new do |r|
        r.say(message: 'Gracias por su mensaje, nos pondremos en contacto con usted lo mas' + 
        ' pronto posible. Hasta pronto', voice: 'woman', language: 'es-MX')
        r.hangup
    end.to_s
end
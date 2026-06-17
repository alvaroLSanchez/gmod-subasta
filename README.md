# Estructura

## round_controller
Controla el comienzo de las partidas. Se puede juntar con lobby_manager

## lobby_manager
Controla la interfaz de selección de equipo.

## game_manager
Estado global de la partida. Contiene los efectos, la lista de los efectos que tiene cada jugador y los grados de los equipos.

### Cartas
La variable "cards" en sv_game.lua contiene todas las cartas, cada una con dos efectos y cada uno de estos con una clave que apunta a un efecto.

### Efectos
La variable "player_effects" contiene todos los efectos, con las funciones que se llamarán cuando se activen. Un efecto de tipo "curse" se aplicará a todos los jugadores que perdieron la subasta. Si no es curse, se aplicará a los jugadores que ganaron la subasta.

## auction_manager
Maneja las subastas y aplica los efectos.

# Flujo del programa
## Inicialización del cliente
El cliente se inicia y envía client_ready al servidor.
El servidor envía open_lobby al cliente si la partida no ha empezado.

## Lobby
Los clientes envían lobby_join_team al servidor -> el cliente hace un broadcast de broadcast_teams
Los clientes envían lobby_ready al servidor -> el cliente hace un broadcast de broadcast_ready
El servidor envía start_game junto con los grados de cada equipo y comienza la ronda.

## Subasta
El servidor envía start_auction a los clientes con la carta elegida.
Los clientes envían make_offer al servidor -> el servidor envía update_offers a cada jugador con las pujas de su equipo.


# Funcionamiento de los addons de Gmod
El código está dividido entre cliente y servidor. 
El cliente y el servidor se mandan mensajes usando la biblioteca "net".

La [wiki](https://wiki.facepunch.com/gmod/) tiene toda la api de lua de gmod documentada. Las funciones azules se llaman desde el servidor. Las naranjas desde el cliente.
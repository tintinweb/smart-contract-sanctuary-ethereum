/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Colas {
    struct Reserva {
        uint256 idReserva;
        string nombre;
        string apellido;
        uint256 dni;
        uint256 precioVenta;
        address payable dueno;
        bool enVenta;
    }

    struct ReservaEnVenta {
        uint256 idReserva;
        uint256 precioVenta;
        address dueno;
        bool enVenta;
    }
    ReservaEnVenta[] public reservasEnVenta;
    Reserva[] public reservas;
    uint costoInicialReserva = 0.0001 ether;
    bool enVenta = false;
    address payable owner;
    mapping(address => uint256) public reservasPorAddress;   

    constructor() {
        owner = payable(msg.sender);
    } 
    
    event ReservaComprada(
        uint256 idReserva, 
        string nombre, 
        string apellido, 
        uint256 dni, 
        uint256 precioVenta, 
        address dueno);

    event ReservaPuestaEnVenta(
        uint256 idReserva,          
        uint256 precioVenta, 
        address dueno);

    function setDefaultValor(uint _nuevoPrecioReserva) public onlyOwner {
        costoInicialReserva = _nuevoPrecioReserva;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el propietario puede ejecutar esta funcion");
        _;
    }
    
    function crearReserva(string memory _nombre, string memory _apellido, uint256 _dni) public payable {
        require(tx.origin == msg.sender, "Solo EOAs pueden llamar esta funcion"); 
        require(msg.value == costoInicialReserva, "Debe pagar el costo por crear la reserva");
           bool yaTieneReserva = false;
        for (uint i = 0; i < reservas.length; i++) {
        if (reservas[i].dueno == msg.sender) {
            yaTieneReserva = true;
            break;
        }
        }
        require(!yaTieneReserva, "Si ya tiene una Reserva creada, no puede crear otra con la misma direccion de wallet");
        reservas.push(
            Reserva(
                reservas.length, 
                _nombre, 
                _apellido, 
                _dni, 
                costoInicialReserva, 
                payable(msg.sender),
                false));
                

        reservasPorAddress[msg.sender] = reservas.length - 1;
    } 

    function venderReserva(uint256 _idReserva, uint256 _precioVenta) public {
        require(tx.origin == msg.sender, "Solo EOAs pueden llamar esta funcion");
        require(_idReserva < reservas.length, "Id de reserva incorrecto");
        
        // obtiene la reserva con el ID especificado 
        Reserva storage reserva = reservas[_idReserva];
        require(reserva.dueno == msg.sender, "Solo el creador de la reserva puede venderla");
               
        // verifica que la reserva no esté actualmente en venta
        require(!reserva.enVenta, "La reserva ya esta en venta");
        reserva.precioVenta = _precioVenta;
        reservas[_idReserva].enVenta = true;

        // agrega la reserva a la lista de reservas en venta
        reservasEnVenta.push(ReservaEnVenta(_idReserva, _precioVenta, msg.sender, true));
        emit ReservaPuestaEnVenta(_idReserva, _precioVenta, reserva.dueno);
    }    

    function comprarReserva(uint256 _idReserva) public payable {
        require(tx.origin == msg.sender, "Solo EOAs pueden llamar esta funcion");
        require(reservas[_idReserva].enVenta == true, "La reserva no esta a la venta"); 
        // Verifica que el ID de reserva es válido
        require(_idReserva < reservas.length, "Id de reserva incorrecto");
        // Obtener la reserva con el ID especificado
        Reserva storage reserva = reservas[_idReserva];
        // Verificar que el precio de la reserva sea el esperado
        require(msg.value == reserva.precioVenta, "Colocar bien el precio de Compra, debe coincidir con el de Venta");
        require(reservasPorAddress[msg.sender] > 0, "Solo compra una reserva aquel que tenga creada actualmente una");
        // Realizar la compra de la reserva
        uint256 mitad = msg.value / 2;
        reserva.dueno.transfer(mitad);
        payable(msg.sender).transfer(mitad);       

        // Actualiza los datos de la reserva, asignando el nuevo dueño
        reserva.dueno = payable(msg.sender);
        reserva.precioVenta = 0;
        reserva.idReserva = _idReserva;
        // Obtengo la posición actual del comprador en el array
        uint256 posicionComprador = reservasPorAddress[msg.sender];
        require(posicionComprador > _idReserva, "No puedes comprar posiciones mayores a la tuya");
        // Obtener la reserva actual del comprador
        Reserva storage reservaActual = reservas[posicionComprador];
        // Asignar los valores de la reserva actual a la reserva comprada
        reserva.nombre = reservaActual.nombre;
        reserva.apellido = reservaActual.apellido;
        reserva.dni = reservaActual.dni;
        
       if (posicionComprador < _idReserva) {
            for (uint256 i = posicionComprador; i > _idReserva; i--) {
                reservas[i] = reservas[i - 1];
                
                reservasPorAddress[reservas[i].dueno] = i;
                
                reservas[i].idReserva = i;
                
            }
        }               
              
        reservasPorAddress[reserva.dueno] = posicionComprador;
            for (uint256 i = posicionComprador; i < reservas.length - 1; i++) {
                reservas[i] = reservas[i + 1];

                // Actualizo la posición en el mapeo para cada reserva que se mueve
                reservasPorAddress[reservas[i].dueno] = i;
                reservas[i].idReserva = i;
            }   
            reservas.pop(); 
            reserva.enVenta = false;




        // Eliminar la reserva comprada de reservasEnVenta
        for (uint256 i = 0; i < reservasEnVenta.length; i++) {
            if (reservasEnVenta[i].idReserva == _idReserva) {
                reservasEnVenta[i] = reservasEnVenta[reservasEnVenta.length - 1];
                reservasEnVenta.pop();
                break;
            }
        }

        // Eliminar la reserva que efectúa la compra de reservasEnVenta
        for (uint256 i = 0; i < reservasEnVenta.length; i++) {
            if (reservasEnVenta[i].dueno == msg.sender) {
                reservasEnVenta[i] = reservasEnVenta[reservasEnVenta.length - 1];
                reservasEnVenta.pop();
                break;
            }
        }

        // Actualizar las posiciones en reservasPorAddress de las reservas que cambiaron de dueño
        for (uint256 i = 0; i < reservas.length; i++) {
            reservasPorAddress[reservas[i].dueno] = i;
        }

        // Actualizar la posición de la reserva comprada en reservasPorAddress
        reservasPorAddress[reserva.dueno] = _idReserva;

        // Emito el evento
           emit ReservaComprada(
                reserva.idReserva, 
                reserva.nombre, 
                reserva.apellido, 
                reserva.dni, 
                reserva.precioVenta, 
                reserva.dueno);
    }   
      
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No hay fondos disponibles para retirar");
        payable(msg.sender).transfer(address(this).balance);
    }

}
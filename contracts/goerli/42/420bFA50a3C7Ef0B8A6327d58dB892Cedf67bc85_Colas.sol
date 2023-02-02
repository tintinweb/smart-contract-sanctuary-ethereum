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
    }
    
    Reserva[] public reservas;
    mapping(address => uint256) public reservasPorAddress;    
    
    event ReservaComprada(
        uint256 idReserva, 
        string nombre, 
        string apellido, 
        uint256 dni, 
        uint256 precioVenta, 
        address dueno);
    
    function crearReserva(string memory _nombre, string memory _apellido, uint256 _dni) public payable {
        require(msg.value == 0.0001 ether, "El costo de crear la reserva es de 0.0001 ether");
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
                0.0001 ether, 
                payable(msg.sender)));

        reservasPorAddress[msg.sender] = reservas.length - 1;
    } 

    function comprarReserva(uint256 _idReserva, uint256 _precioVenta) public payable {

        // Verifica que el ID de reserva es válido
        require(_idReserva < reservas.length, "Id de reserva incorrecto");

        // Obtener la reserva con el ID especificado
        Reserva storage reserva = reservas[_idReserva];

        // Verificar que el precio de la reserva sea el esperado
        require(msg.value == reserva.precioVenta, "Colocar bien el precio de Compra, debe coincidir con el de Venta");
        require(reservasPorAddress[msg.sender] >= 0, "Solo compra una reserva aquel que ya haya creado una");

        // Realizar la compra de la reserva
        uint256 mitad = msg.value / 2;
        reserva.dueno.transfer(mitad);
        payable(msg.sender).transfer(mitad);       

        // Actualiza los datos de la reserva, asignando el nuevo dueño
        reserva.dueno = payable(msg.sender);
        reserva.precioVenta = _precioVenta;
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
        if (posicionComprador > _idReserva) {
            for (uint256 i = posicionComprador; i < _idReserva; i++) {
                reservas[i] = reservas[i + 1];
                
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

            // Emito el evento para notificar que la reserva fue comprada.
            emit ReservaComprada(
                reserva.idReserva, 
                reserva.nombre, 
                reserva.apellido, 
                reserva.dni, 
                reserva.precioVenta, 
                reserva.dueno);
        }
    }
/**
 *Submitted for verification at Etherscan.io on 2023-02-21
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
    address[] ultimosDuenosEliminados;
    uint costoInicialReserva = 0 ether;
    uint256 feeCompraVenta = 10;
    bool enVenta = false;
    address payable owner;
    mapping(address => uint256) public reservasPorAddress;
    mapping(address => uint256) public reservasEnVentaPorAddress;   

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
    
    event ReservasEliminadas(
        uint256[] idEliminados, 
        address[] duenosEliminados);

    function setValorCreacionReserva(uint _nuevoPrecioReserva) public onlyOwner {
        costoInicialReserva = _nuevoPrecioReserva;
    }

    function setFeeCompraVenta(uint256 _feeNuevo) public onlyOwner {
    feeCompraVenta = _feeNuevo;
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
        reservasEnVentaPorAddress[msg.sender] = reservasEnVenta.length - 1;
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
        // Realizar la compra de la reserva
        uint256 feeAmount = msg.value * feeCompraVenta / 100;
        uint256 vendedorAmount = msg.value - feeAmount;
        reserva.dueno.transfer(vendedorAmount);
        payable(address(owner)).transfer(feeAmount);       

        // Actualiza los datos de la reserva, asignando el nuevo dueño
        reserva.dueno = payable(msg.sender);
        reserva.precioVenta = 0;
        reserva.idReserva = _idReserva;
        // Obtengo la posición actual del comprador en el array
        uint256 posicionComprador = reservasPorAddress[msg.sender];        
        require(posicionComprador > _idReserva, "No puedes comprar tu posicion o posiciones mayores a la tuya");
        require(posicionComprador != 0, "Solo puede comprar una reserva aquel que tenga creada actualmente una");
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

        // Elimino la reserva comprada de reservasEnVenta
        for (uint256 i = 0; i < reservasEnVenta.length; i++) {
            if (reservasEnVenta[i].idReserva == _idReserva) {
                reservasEnVenta[i] = reservasEnVenta[reservasEnVenta.length - 1];
                reservasEnVenta.pop();
                break;
            }
        }
        
        for (uint256 i = 0; i < reservasEnVenta.length; i++) {
            if (reservasEnVenta[i].dueno == msg.sender) {
                reservasEnVenta[i] = reservasEnVenta[reservasEnVenta.length - 1];
                reservasEnVenta.pop();
                break;
            }
        }
        
        for (uint256 i = 0; i < reservas.length; i++) {
            reservasPorAddress[reservas[i].dueno] = i;
        }
        
        reservasPorAddress[reserva.dueno] = _idReserva;
        
        for (uint256 i = 0; i < reservasEnVenta.length; i++) {
            if (reservasEnVenta[i].idReserva == _idReserva) {
                reservasEnVenta[i].idReserva = reserva.idReserva;
                break;
            }
        }

        for (uint256 i = 0; i < reservas.length; i++) {
            for (uint256 j = 0; j < reservasEnVenta.length; j++) {
                if (reservas[i].dueno == reservasEnVenta[j].dueno) {
                    reservasEnVenta[j].idReserva = reservas[i].idReserva;
                }
            }
        }    

        // Emito el evento
           emit ReservaComprada(
                reserva.idReserva, 
                reserva.nombre, 
                reserva.apellido, 
                reserva.dni, 
                reserva.precioVenta, 
                reserva.dueno);
    }

    function administrarReservas(uint256 cantidad) public onlyOwner {
        require(cantidad > 0 && cantidad <= 10, "La cantidad de reservas a eliminar debe estar entre 1 y 10");
        require(cantidad <= reservas.length, "La cantidad de reservas a eliminar debe ser menor o igual a la cantidad total de reservas");

        uint256[] memory idEliminados = new uint256[](cantidad);
        address[] memory duenosEliminados = new address[](cantidad);

        for (uint256 i = 0; i < cantidad; i++) {
            idEliminados[i] = reservas[i].idReserva;
            duenosEliminados[i] = reservas[i].dueno;
        }
        
        for (uint256 i = 0; i < cantidad; i++) {
            uint256 idReservaAEliminar = idEliminados[i];

            for (uint256 j = 0; j < reservas.length; j++) {
                if (reservas[j].idReserva == idReservaAEliminar) {
                    delete reservas[j];
                    break;
                }
            }
        }

        for (uint256 i = idEliminados[0]; i < reservas.length; i++) {
            if (reservas[i].idReserva > idEliminados[cantidad-1]) {
                reservas[i-cantidad] = reservas[i];
                reservasPorAddress[reservas[i].dueno] = i-cantidad;
                reservas[i-cantidad].idReserva = i-cantidad;
            }
        }
        
        for (uint256 i = 0; i < cantidad; i++) {
            reservas.pop();
        }
        
        for (uint256 i = 0; i < reservas.length; i++) {
            reservasPorAddress[reservas[i].dueno] = i;
        }         
        
        for (uint256 i = 0; i < cantidad; i++) {
            for (uint256 j = 0; j < reservasEnVenta.length; j++) {
                if (reservasEnVenta[j].idReserva == idEliminados[i]) {
                    reservasEnVenta[j] = reservasEnVenta[reservasEnVenta.length - 1];
                    reservasEnVenta.pop();
                    break;
                }
            }
        }
        
        for (uint256 i = 0; i < reservas.length; i++) {
            for (uint256 j = 0; j < reservasEnVenta.length; j++) {
                if (reservas[i].dueno == reservasEnVenta[j].dueno) {
                    reservasEnVenta[j].idReserva = reservas[i].idReserva;
                    reservasEnVenta[j].precioVenta = reservas[i].precioVenta;
                    reservasEnVenta[j].enVenta = reservas[i].enVenta;
                }
            }
        }
        
        if (reservasEnVenta.length == 0) {
            while (reservasEnVenta.length > 0) {
                reservasEnVenta.pop();
            }
        }

        for (uint256 i = 0; i < cantidad; i++) {
            ultimosDuenosEliminados.push(duenosEliminados[i]);
        }

        if (ultimosDuenosEliminados.length > 10) {
            for (uint256 i = 0; i < ultimosDuenosEliminados.length - 1; i++) {
                ultimosDuenosEliminados[i] = ultimosDuenosEliminados[i+1];
            }
            ultimosDuenosEliminados.pop();
        }

        emit ReservasEliminadas(idEliminados, duenosEliminados);
        
    } 

    function obtenerUltimosDuenosEliminados() public view returns (address[] memory) {
        if (ultimosDuenosEliminados.length == 0) {
        address[] memory vacio = new address[](1);
        vacio[0] = address(0);
        return vacio;
        } else {
            address[] memory direcciones = new address[](ultimosDuenosEliminados.length);
            for (uint256 i = 0; i < ultimosDuenosEliminados.length; i++) {
                direcciones[i] = address(bytes20(uint160(ultimosDuenosEliminados[i])));
            }
            return direcciones;
        }
    
    }  
      
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No hay fondos disponibles para retirar");
        payable(msg.sender).transfer(address(this).balance);
    }

}
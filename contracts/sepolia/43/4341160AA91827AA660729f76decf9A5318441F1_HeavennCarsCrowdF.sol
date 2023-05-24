/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract HeavennCarsCrowdF {
    //Direccion del owner
    address public owner;
    //Cantidad de porcentaje de impuesto que sera tomado del proyecto
    uint public projectTax;
    //Cantidad de dinero de todos los proyectos
    uint public projectCount;
    //Cantidad de dinero del proyecto en particular
    uint public balance;
    //Objetivo recaudacion
    //uint objetivoRecaudacion;
    //Total recaudado
    //uint totalRecaudado;
    //Bool pagado para que se cumpla el objetivo
    //bool pagado = false;
    //Estructura de la informacion de la web llamada "estadisticas"
    EstadisticaStruct public stats;
    //Estructura de los proyectos
    structProyecto[] proyectos;

    mapping(address => structProyecto[]) projectosOf; //proyecto de X cosa...
    mapping(uint => inversorStruct[]) inversorOf; //inversores de X cosa...
    mapping(uint => bool) public projectExist; //Nos dice si existe el proyecto

    //Estadisticas/informacion de los proyectos publicados
    struct EstadisticaStruct {
        uint totalProyectos;
        uint totalInversores;
        uint totalContribuciones;
    }

    //Estructura de los inversores
    struct inversorStruct {
        address owner;
        uint contribucion;
        uint timestamp;
        bool reembolso;
    }

    //Estructura del proyecto
    struct structProyecto {
        uint id;
        address owner;
        string titulo;
        string descripcion;
        string imageURL;
        uint cost;
        uint invertido;
        uint timestamp;
        uint expiresAt;
        uint inversores;
    }

    //Modificador solo el owner
    modifier ownerOnly() {
        require(owner == msg.sender, "SOLO EL OWNER");
        _;
    }
    event NuevoProyecto(
        string indexed titulo,
        uint256 indexed cost,
        uint256 indexed expiresAt
    );
    event EdicionProyecto(
        uint indexed id,
        string indexed titulo,
        uint indexed expiro
    );
    event ProyectoBorrado(uint indexed id);
    event RefundHecho(uint indexed id);
    event NuevaInversion(
        uint indexed id,
        address indexed inversor,
        uint indexed cantidad
    );
    event PagoHecho(
        address indexed desde,
        address indexed hacia,
        uint256 indexed cantidad
    );
    event ProyectoAprovado(uint indexed id);
    event ProyectoRevertido(uint indexed id);
    event TaxCambiada(uint indexed nuevaTax);
    event PagoProyecto(uint indexed id);
    event ReembolsoSolicitado(uint indexed id);
    event PayoutHecho(uint indexed id);

    constructor(uint _projectTax) {
        owner = msg.sender;
        projectTax = _projectTax;
    }

    // Funcion para crear el proyecto desde la web
    function crearProyecto(
        string memory titulo,
        string memory descripcion,
        string memory imageURL,
        uint cost,
        uint expiresAt
    ) public returns (bool) {
        require(bytes(titulo).length > 0, "El titulo no puede estar vacio");
        require(
            bytes(descripcion).length > 0,
            "La descripcion no puede estar vacia"
        );
        require(bytes(imageURL).length > 0, "La ImageURL no puede estar vacia");
        require(cost > 0 ether, "Ether tiene que ser superior a cero");
        structProyecto memory proyecto;
        proyecto.id = projectCount;
        proyecto.owner = msg.sender;
        proyecto.titulo = titulo;
        proyecto.descripcion = descripcion;
        proyecto.imageURL = imageURL;
        proyecto.cost = cost;
        proyecto.timestamp = block.timestamp;
        proyecto.expiresAt = expiresAt;
        proyectos.push(proyecto);
        projectExist[projectCount] = true;
        projectosOf[msg.sender].push(proyecto);
        stats.totalProyectos += 1;
        projectCount += 1;

        emit NuevoProyecto(titulo, cost, expiresAt);
        return true;
    }

    // Funcion para editar el proyecto desde la web
    function editarProyecto(
        uint id,
        string memory titulo,
        string memory descripcion,
        string memory imageURL,
        uint expiresAt
    ) public returns (bool) {
        require(msg.sender == proyectos[id].owner, "Direccion Autorizada");
        require(bytes(titulo).length > 0, "El titulo no puede estar vacio");
        require(
            bytes(descripcion).length > 0,
            "La descripcion no puede estar vacia"
        );
        require(bytes(imageURL).length > 0, "La ImageURL no puede estar vacia");
        proyectos[id].titulo = titulo;
        proyectos[id].descripcion = descripcion;
        proyectos[id].imageURL = imageURL;
        proyectos[id].expiresAt = expiresAt;

        emit EdicionProyecto(id, titulo, expiresAt);
        return true;
    }

    //Funcion para reembolsar de un proyecto a una direccion especifica guardada en la copia de seguridad
    function performRefund(uint id) internal {
        for (uint i = 0; i <= inversorOf[id].length; i++) {
            address _owner = inversorOf[id][i].owner;
            uint _contribucion = inversorOf[id][i].contribucion;
            //Busca la direccion especifica del usuario y le hace el reembolso devolviendo TRUE
            inversorOf[id][i].reembolso = true;
            inversorOf[id][i].timestamp = block.timestamp;
            payTo(_owner, _contribucion);
            //Actualiza la base de datos por la devolucion
            stats.totalInversores -= 1;
            stats.totalContribuciones -= _contribucion;
        }
        emit RefundHecho(id);
    }

    // Funcion para invertir en el proyecto especifico
    function invertirProyecto(uint id) public payable {
        require(msg.value > 0 ether, "Ether tiene que ser superior a cero");
        require(projectExist[id], "Proyecto no encontrado");
        require(block.timestamp <= proyectos[id].expiresAt);
        require(proyectos[id].invertido + msg.value <= proyectos[id].cost);

        //Actualiza los datos/estadisticas de la tienda, la del proyecto y los inversores
        stats.totalInversores += 1;
        stats.totalContribuciones += msg.value;
        proyectos[id].invertido += msg.value;
        proyectos[id].inversores += 1;
        //Añadimos (.push) a la copia de seguridad del proyecto en particular la info del nuevo inversor
        inversorOf[id].push(
            inversorStruct(msg.sender, msg.value, block.timestamp, false)
        );

        //Emitimos la informacion del proyecto invertido
        emit NuevaInversion(id, msg.sender, msg.value);

        //Cada vez que haya un inversor en un proyecto, comprueba que la inversion es mayor o igual a lo que quiere el usuario
        if (proyectos[id].invertido == proyectos[id].cost) {
            //si es asi lo aprueba
            balance += proyectos[id].invertido;
            //Comando de pago activado
            performPayout(id);
            emit ProyectoAprovado(id);
        }
    }

    //Funcion para pagar
    function performPayout(uint id) internal {
        uint invertido = proyectos[id].invertido;
        uint tax = (invertido * projectTax) / 100;

        payTo(proyectos[id].owner, (invertido - tax));
        payTo(owner, tax);
        //Cogemos y deducimos la cantidad recaudad con el balance
        balance -= proyectos[id].invertido;
        //Emite que el proyecto esta pagado
        emit PayoutHecho(id);
    }

    //Solicitar un reembolso cuando no se han cumplido las espectativas
    function solicitarReembolso(uint id) public returns (bool) {
        //Comando de reembolso
        performRefund(id);
        emit ReembolsoSolicitado(id);

        return true;
    }

    //Funcion para pagar el proyecto
    function payOutProject(uint id) public returns (bool) {
        // Quito que se requiera el owner general
        require(msg.sender == proyectos[id].owner, "NO AUTORIZADO");
        //Comando de pago
        performPayout(id);
        emit PagoProyecto(id);
        return true;
    }

    //Funcion para cambiar el porcentaje de la tasa del proyecto, solo la llama el owner
    function cambiarTax(uint _taxPct) public ownerOnly {
        projectTax = _taxPct;
        emit TaxCambiada(_taxPct);
    }

    //Devuelve un proyecto especifico por el ID
    function getProyecto(uint id) public view returns (structProyecto memory) {
        require(projectExist[id], "PROYECTO NO ENCONTRADO");

        return proyectos[id];
    }

    //Devuelve todos los proyectos de la web
    function getProyectos() public view returns (structProyecto[] memory) {
        return proyectos;
    }

    //Devuelve todos los inversores
    function getInversores(
        uint id
    ) public view returns (inversorStruct[] memory) {
        return inversorOf[id];
    }

    //Funncion para enviar dinero a una direccion/cantidad espeficica
    // function payTo(address to, uint256 amount) public {
    //     (bool success, ) = payable(to).call{value: amount}("");
    //     require(success);
    //     emit PagoHecho(msg.sender, to, amount);
    // }
    function payTo(address _address, uint256 amount) internal {
        payable(_address).transfer(amount);
    }
}
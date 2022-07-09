// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import '.SafeMath.sol';
//Son 2 contratos: crowdfunding (recoge todos los proyectos generados) y Proyecto (bóveda de cada proyecto).

contract Crowdfunding {
    //Lista de proyectos existentes
    Proyecto[] private proyectos;
    // Evento que se inicia cada vez que hay un proyecto nuevo
    event proyectoIniciado(
        address addressContrato,
        address adressProyecto,
        string tituloProyecto,
        string descripcionProyecto,
        uint256 plazo,
        uint256 cantidadObjetivo
    );

    /**@dev Function para iniciar un nuevo proyecto 
     *@param titulo Titulo del proyecto que se va a crear
     *@param descripcion Breve descripción sobre el proyecto
     *@param _inicio Plazo inicial del proyecto en dias
     *@param _final Plazo final del proyecto en dias 
     @param cantidadARecaudar Cantidad objetivo a recaudar para el proyecto. 
     */
    function inicioProyecto(
        string calldata titulo,
        string calldata descripcion,
        uint32 _inicio,
        uint32 _final,
        uint256 cantidadARecaudar
    ) external {
        require(_inicio >= block.timestamp, "inicio < now");
        require(_final >= block.timestamp, "final < inicio");
        require(_final <= block.timestamp + 60 days, "final > duracion max");

        //HACEMOS LOS CALCULOS PARA QUE SEA MAS SENCILLO EN DIAS DIRECTAMENTE
        //Revisar que pasa con los días, si hay que declararlo, si es DAYS
        //uint256 recaudarHasta = block.timestamp + duracionEnDias * 1 dias;
        uint256 recaudarHasta = block.timestamp + 60 days;

        Proyecto nuevoProyecto = new Proyecto(
            payable(msg.sender),
            titulo,
            descripcion,
            recaudarHasta,
            cantidadARecaudar
        );
        proyectos.push(nuevoProyecto);
        emit proyectoIniciado(
            address(nuevoProyecto),
            msg.sender,
            titulo,
            descripcion,
            recaudarHasta,
            cantidadARecaudar
        );
    }

    /**@dev Function para obtener las direcciones de contrato de todos los proyectos
     *@return Un lista de todas las direcciones de contrato de todos los proyectos.
     */
    function listaTodosProyectos() external view returns (Proyecto[] memory) {
        return proyectos;
    }
}

contract Proyecto {
    // Estructura de datos
    enum Estado {
        RecaudacionDeFondos,
        Vencido,
        Exitoso
    }
    //Variables estado
    address payable public creador;
    uint256 public cantidadObjetivo;
    uint256 public completo;
    uint256 public balanceActual;
    uint256 public aumentado;
    string public titulo;
    string public descripcion;
    Estado public estado = Estado.RecaudacionDeFondos;
    uint256 public fechaLimite;
    mapping(address => uint256) public contribuciones;
    bool public claimActive;
    uint256 public claimableAmountPerPeriod;
    uint256 public claimActual;

    //Evento que se emitirá cada vez que se reciba financiación
    event FondosRecibidos(
        address donante,
        uint256 cantidad,
        uint256 saldoTotal
    );
    //Evento que se emitirá cada vez que el iniciador del proyecto haya recibido los fondos
    event pagoCreador(address beneficiario);

    //Modifier para comprobar el estado actual del beneficiario
    modifier inEstado(Estado _estado) {
        require(estado == _estado);
        _;
    }
    // Modifier para verificar si la persona que llama a la función es el creador del proyecto.
    modifier isCreador() {
        require(msg.sender == creador);
        _;
    }

    constructor(
        address payable adressProyecto,
        string memory tituloProyecto,
        string memory descripcionProyecto,
        uint256 plazoRecaudacionFondos,
        uint256 _cantidadObjetivo
    ) {
        creador = adressProyecto;
        titulo = tituloProyecto;
        descripcion = descripcionProyecto;
        cantidadObjetivo = _cantidadObjetivo;
        fechaLimite = plazoRecaudacionFondos;
        balanceActual = 0;
    }

    /** @dev Function para donar en un determinado proyecto
     */
    function donar() external payable inEstado(Estado.RecaudacionDeFondos) {
        require(msg.sender != creador);
        contribuciones[msg.sender] = contribuciones[msg.sender] + msg.value;
        balanceActual = balanceActual + msg.value;
        emit FondosRecibidos(msg.sender, msg.value, balanceActual);
        comprobarSiLaRecaudacionCompletoOVencido();
    }

    /** @dev Funcion para comprobar si cambiamos de fase dependiendo de unas determinadas condiciones
     */
    function comprobarSiLaRecaudacionCompletoOVencido() public {
        if (balanceActual >= cantidadObjetivo) {
            estado = Estado.Exitoso;
        } else if (block.timestamp > fechaLimite) {
            estado = Estado.Vencido;
        }
        completo = block.timestamp;
    }

    /**@dev Funcion de claim para repartir la cantidad recaudada en 12 partes iguales, una por cada mes del año
     */
    function claim() external {
        require(claimActive == true);
        require(claimActual <= 12);
        require(completo + (30 days * claimActual) >= block.timestamp);

        creador.transfer(claimableAmountPerPeriod);
        claimActual += 1;
        balanceActual -= claimableAmountPerPeriod;
    }

    /** @dev Function para iniciar el claim sujeta a unas determinadas condiciones
     */
    function startClaim() public {
        require(balanceActual > 0);

        if (balanceActual <= 2000 * 10**18) {
            creador.transfer(balanceActual);
            balanceActual = 0;
        } else {
            claimActive = true;
            claimableAmountPerPeriod = balanceActual / 12;
            claimActual = 1;
        }
    }

    /* @dev Function para obetener una informacion especifica sobre el proyecto
     * @return Return todos los dellates del proyecto
     */
    function obtenerDetalles()
        public
        view
        returns (
            address payable adressProyecto,
            string memory tituloProyecto,
            string memory descripcionProyecto,
            uint256 plazo,
            Estado estadoActual,
            uint256 cantidadActual,
            uint256 _cantidadObjetivo
        )
    {
        adressProyecto = creador;
        tituloProyecto = titulo;
        descripcionProyecto = descripcion;
        plazo = fechaLimite;
        estadoActual = estado;
        cantidadActual = balanceActual;
        _cantidadObjetivo = cantidadObjetivo;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >0.4.4 <= 0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";


contract loteria {

// ----------------------------------------------------  D E C L A R A C I O N E S  I N I C I A L E S  -------------------------------------------------------


    // Instancia del Contrato Token de Nombre "LOT"
    ERC20Basic private LOT;

    //Direcciones
    address public owner;
    address public contrato;

    //Numero de tokens a crear
    uint token_creados = 10000;

    constructor () public {
        LOT = new ERC20Basic(token_creados);
        owner = msg.sender;
        contrato = address (this);
    }

// -------------------------------------------------------  G E S T I O N  D E  T O K E N S  ------------------------------------------------------------------
    //Establezco el precio de los tokens en ethers
    function PrecioTokens (uint _numTokens) internal pure returns (uint) {
        return _numTokens * (0.1 ether);
    }

    //Funcion para crear mas Tokens cuando Quiera
    function GenerarTokens (uint _numTokens) public Unicamente(msg.sender) {
        LOT.increaseTotalSupply(_numTokens);
    }

    modifier Unicamente (address _direccion) {
        require (_direccion == owner, "No tiene permisos para realizar esta accion.");
        _;
    }

    //Funcion que permita comprar Tokens para luego comprar boletos para la loteria
    function ComprarTokens (uint _numTokens) public payable{
        //Calcular el precio de los Tokens
        uint coste = PrecioTokens(_numTokens);
        //Se requiere que el tenga los suficientes ethers
        require (msg.value >= coste, "Compra menos Tokens o paga con mas ethers.");
        //Diferencia de lo que paga con lo que gasta
        uint returnValue = msg.value - coste;
        //Le devuelvo al usuario esa diferencia
        msg.sender.transfer(returnValue);
        //Obtener el balance de tokens del contrato
        uint Balance = TokensDisponibles();
        //Filtro para evaluar si hay suficientes tokens disponibles para que el usuario compre
        require (Balance >= _numTokens, "No hay suficientes tokens, Pruebe comprando menos Tokens");
        //Transfiero los tokens al comprados
        LOT.transfer(msg.sender, _numTokens);
    }

    //Balance de tokens en el contrato de Loteria
    function TokensDisponibles() public view returns (uint) {
        return LOT.balanceOf(address(this));
    }

    // Tokens acumulados en el Bote
    function Bote() public view returns (uint) {
        return LOT.balanceOf(owner);
    }

    //Balance de Tokens de una persona
    function MisTokens() public view returns(uint) {
        return LOT.balanceOf(msg.sender);
    }

// ------------------------------------------------------------------  L O T E R I A  ------------------------------------------------------------------------------

    //Saber cuanto cuesta un Boletos
    uint public PrecioBoleto = 1;
    //Relaciono mediante un Mapping a la persona que compro el boleto y los numeros de los boletos
    mapping (address => uint []) idPersona_boletos;
    //Relacion entre el numero ganador con la direccion del ganador
    mapping (uint => address) ADN_boleto;
    //Genero numeros aleatorios para los Boletos
    uint randNonce = 0;
    //Boletos Generados
    uint [] boletos_comprados;

    //Eventos
    event boleto_Comprado (uint, address);
    event boleto_Ganador (uint);
    event tokens_devueltos (uint, address);


    // Funcion para comprar Boletos de loteria
    function ComprarBoletos(uint _boletos) public {
        //Precio total de boletos a comprar
        uint precio_total = PrecioBoleto * _boletos;
        //Filtrado de los tokens a pagar
        require (MisTokens() >= precio_total, "Disculpe, pero no tiene el dinero suficiente, Necesita comprar mas tokens");
        //transferencia de Tokens al Owner (que es el bote)

        /* El cliente paga los boletos en Tokens:
        - Fue necesiario crear una funcion en ERC20.sol con el nombre de "transferenciaLoteria" debido a que en
        caso de usar el transfer o transferfrom las direcciones que se escogian para realizar la transaccion eran equivocadas. 
        Ya que el msg.sender que recibia el metodo transferfrom era de la direccion del contrato. Y debe ser la direccion  de la persona fisica.
        */
        LOT.transferenciaLoteria(msg.sender, owner, precio_total);
        /*
        Creo un numeo unico completamente aleatorio -> Para esto utilizo el now, que cambia todo el tiempo. Utilizo el 
        keccak256 para convertir esas entradas en un hash completamente aleatorio, Luego utilizamos el % 10000 para agarrar
        los ultimos 4 digitos. Dando un valor aleatorio entre 0 y 9999.
        */

         for (uint i = 0; i < _boletos; i++) {
             uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 10000;
             randNonce ++;
            //Almacenamos los datos de los boletos 
            idPersona_boletos[msg.sender].push(random);
            //Alamcenamos los numeros de los boletos comprados
            boletos_comprados.push(random);
            //asignación del ADN del boleto para tener un ganador
            ADN_boleto[random] = msg.sender;
            //Emito el evento de Boleto comprador
            emit boleto_Comprado(random, msg.sender);

         }
    }

    //Visualizar los boletos de una persona
    function MisBoletos() public view returns (uint [] memory) {
        return idPersona_boletos[msg.sender];
    }

    //Funcion para generar un Ganador y ingresar los Tokens
    function GenerarGanador() public Unicamente(msg.sender) {
        //Necesito que por lo menos haya 1 boleto comprador
        require (boletos_comprados.length > 0, "Todavia no se han comprado Boletos");
        //Declarar la longitud del array
        uint longitud = boletos_comprados.length;
        //Aleatoriamente elijo un numero entre 0 y longitud.
        //1- Eleccion de una posicion aleatoria del array
        uint posicion_array = uint(uint(keccak256(abi.encodePacked(block.timestamp))) % longitud);
        //2- Seleccion de un numero aleatorio mediante la posicion del array aleatorio
        uint eleccion = boletos_comprados[posicion_array];
        //Emito el evento del ganador
        emit boleto_Ganador(eleccion);
        //Le mando los tokens al ganador. Para eso recupero la direccion del ganador atraves del AND boleto
        address direccion_ganador = ADN_boleto[eleccion];
        //Le mando los tokens al ganador
        LOT.transferenciaLoteria(msg.sender, direccion_ganador, Bote());

    }

    //Cambiar Tokens LOT a ether
    function DevolverTokens(uint _numTokens) public payable {
        //El numero de tokens a devolver debe ser positivo
        require (_numTokens > 0, "Debe devolver un Numero positivo de Tokens");
        //El usuario debe tener esos tokens
        require (MisTokens() >= _numTokens, "No tiene los tokens suficientes");
        //El cliente devuelve los tokens
        LOT.transferenciaLoteria(msg.sender,address(this), _numTokens);
        //La loteria paga los tokens devueltos en ethers
        msg.sender.transfer((PrecioTokens(_numTokens)));
        //Emito el evento de Tokens devueltos
        emit tokens_devueltos(_numTokens, msg.sender);
    }

}
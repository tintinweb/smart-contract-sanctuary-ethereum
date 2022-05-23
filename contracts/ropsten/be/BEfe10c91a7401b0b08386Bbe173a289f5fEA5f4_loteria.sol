// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract loteria {

    //instancia del contrato token
    ERC20Basic private token;

    //direcciones
    address public owner;
    address public contrato;

    //numero de tokens a crear
    uint public tokens_creados = 10000;

    //evento de compra de tokens
    event ComprandoTokens(uint, address);

    constructor () public {
        token = new ERC20Basic(tokens_creados);
        owner = msg.sender;
        contrato = address(this);
    }

    //------------------token-------------------
    function PrecioToken(uint _numTokens) internal pure returns (uint){
        return _numTokens*(1 ether);
    }

    //Generar mas tokens por loteria
    function GenerarTokens(uint _numTokens) public Unicamente(msg.sender){
        token.increaseTotalSuply(_numTokens);
    }

    //modifcador para hacer funciones solomente accesibles por el owner del contrato
    modifier Unicamente(address _direccion){
        require(_direccion == owner, "no tienes permisos para ejecutar esta funcion");
        _;
    }

    //Comprar tokens para comprar boletos/tickets para la loteria
    function CompraTokens(uint _numTokens) public payable {
        //Calcular el coste de los tokens
        uint coste = PrecioToken(_numTokens);
        //se requiere que el valor de ethers pagados sea equivalente al coste 
        require(msg.value >= coste, "Compra menos tokens o paga con mas ethers");
        uint returnValue = msg.value - coste;
        //transferencia de la diferencia
        msg.sender.transfer(returnValue);
        //obtener el balance de tokens del contrato
        uint Balance = TokensDisponibles();
        //filtro para evaluar los tokens a comprar con los tokens disponibles
        require(_numTokens <= Balance, "Compra un numero de tokens adecuado");
        //transferencia de tokens al comprador
        token.transfer(msg.sender, _numTokens);
        //emitir el evento de compra
        emit ComprandoTokens(_numTokens, msg.sender);
    }

    //Balance de tokens en el contrato de loteria
    function TokensDisponibles()public view returns (uint){
        return token.balanceOf(contrato);
    }

    //Obtener el balance de tokens acumulados en el Bote
    function Bote() public view returns(uint){
        return token.balanceOf(owner);
    }

    //Balance de tokens de una persona
    function MisTokens() public view returns (uint){
        return token.balanceOf(msg.sender);
    }

    //---------loteria--------------------

    //Precio del boleto
    uint public PrecioBoleto = 5;
    //Relacion entre la persona que compra los boletos y los numeros de los boletos
    mapping(address => uint[]) idPersona_boletos;
    //Relacion necesaria poara identificar al ganador
    mapping (uint => address) ADN_boleto;
    //Numero aleatorio
    uint randNonce = 0;
    //Boletos generados
    uint [] boletos_comprados;
    //Eventos
    event boleto_comprado(uint, address); // evento cuando se compra un boleto
    event boleto_ganador(uint); //evento del ganador
    event tokens_devueltos(uint, address); //evento para devolver tokens

    //funcion para comprar boletos de loteria
    function CompraBoleto(uint _boletos) public{
        //precio total de los boletos a comprar
        uint precio_total = _boletos*PrecioBoleto;
        //filtrado de los tokens a pagar
        require(precio_total <= MisTokens(), "necesitas comprar mas tokens");
        //transferencia de tokens al owner -> bote/premio
        token.transferencia_loteria(msg.sender, owner, precio_total);

        for(uint i = 0 ; i < _boletos ; i++){
            //generamos un numero aleatorio con el tiempo actual la direcion del emisor y un numero incrementable para que no se repita
            uint random = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 10000;
            randNonce++;
            //almacenamos los numeros de los boletos
            idPersona_boletos[msg.sender].push(random);
            //numero de boleto comprado
            boletos_comprados.push(random);
            //asignacion del adni del boleto para tener un ganador
            ADN_boleto[random] = msg.sender;
            //emision evento
            emit boleto_comprado(random, msg.sender);
        }
    }

    //visualizar el numero de boletos de una persona
    function TusBoletos() public view returns (uint [] memory){
        return idPersona_boletos[msg.sender];
    }

    //funcion para generar un ganador e ingresarle los tokens
    function GenerarGanador() public Unicamente(msg.sender){
        require(boletos_comprados.length > 0, "no hay boletos comprados");
        //declaracion de la longitud del array
        uint longitud = boletos_comprados.length;
        //aleatoriamente elijo un numero entre 0 - longitud
        uint posicion_array = uint(uint(keccak256(abi.encodePacked(now))) % longitud);
        //seleccion del numero aleatorio mediante la posicion del array aleatoria
        uint eleccion = boletos_comprados[posicion_array];
        //emision del boleto ganador
        emit boleto_ganador(eleccion);
        //Recuperar la direccion del ganador
        address direccion_ganador = ADN_boleto[eleccion];
        //enviarle los tokens del premio al ganador
        token.transferencia_loteria(msg.sender, direccion_ganador, Bote());
    }


    //devolucion de los tokens
    function DevolverTokens(uint _numTokens) public payable {
        //el numero de tokens a devolver debe ser mayor a 0
        require(_numTokens > 0, "necesitas devolver un numero positivo de tokens");
        //el usuario debe tener los tokens que desea devolver
        require(_numTokens <= MisTokens(), "no tienes los tokens que deseas devolver");
        //el cliente devuelve los tokens
        token.transferencia_loteria(msg.sender, address(this), _numTokens);
        msg.sender.transfer(PrecioToken(_numTokens));
        //emision del evento
        emit tokens_devueltos(_numTokens, msg.sender);

    }
    
}
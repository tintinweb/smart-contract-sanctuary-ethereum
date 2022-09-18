//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//Queremos conseguir lo siguiente:
//Get funds from Users
//Withdraw Funds
//Set a minimun funding value in USD.

import "./PriceConverter.sol"; //Importamos la libreria
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//GAS EFFICIENT TIP. FUera del contrato creamos un ERROR CUSTOM, que usaremos en nuestros REQUIRE que sustituiremos por IF statement

error NotOWner();

contract FundMe {
    //transaction cost sin CONSTANT--> 844180
    //transaction cost con CONSTANT--> 824638

    //Importamos la libreria
    using PriceCoverter for uint256;

    //Minimo de Usd que nos pueden enviar. Hay que multiplicarlo por 1e18 para que estemos comparando los mismos valores.
    //Ya que esta variable no va a cambiar nunca(porque asi lo queremos), le ponemos CONSTANT para ahorrar GAS
    //Cuando usamos CONSTATNT las variables se escribien en mayuscula(convencion)
    uint256 public constant MINIMUN_USD = 50 * 1e18;

    //Una vez ya tenemos creada el FUND fnction, queremos crear un array con las adress que han pagado.
    address[] public funders;

    //Tambien podemos usar MAPPING para ver cuanto han fundeado cada funder.

    mapping(address => uint256) public addresToAmountFunded;

    //Para que solo el dueño pueda sacar los FUNDS debemos crear un COnstructor.
    //Funciona igual que en Angular.

    //Creamos la variable global Adress of the OWNer

    //Esta variable tampoco va  cambiar asi que, vamos a ahorrar GAS poniendole IMMNUTABLE. No se puede CONSTANT porque,
    //esta variable la tenemos que declarar dentro del constructor para igualarla a msg.sender y no solo una variable global.
    //COnvention (i_)
    address public immutable i_owner;

    /**
     * !REFACTORING: constructor es una funcion como cualquier otra, por lo que acepta parametros.
     * ! LE vamos a indicar la direccion de PRICEFEED, para conseguir no tener que cambiar el codigo cada
     * ! vez que queramos cambiar de CHAIN
     */

    AggregatorV3Interface public priceFeed; //HAcemos como ya hicimos en PriceConverter.sol -->

    // creamos interfaz priceFeed de tipo aggregatorv3Interface

    constructor(address priceFeedAdress) {
        i_owner = msg.sender; // En este caso, el msg.sender, como está definido en el constructor que es lo primero que se ejecuta,
        // el msg.sender será el que ha hecho el deploy den contrato, es decir nosotros.

        //Al igual que hicimos anteriormente, priceFeed = to aggregatorv3(la dirección, en este caso la direccion del constructor)
        priceFeed = AggregatorV3Interface(priceFeedAdress);
    }

    //Añadimos payable para que sea un contrato pagable. se pone en rojo
    function fund() public payable {
        //We would like to create a minimun fund in USD
        // 1. how to send eth to this contract

        // Require se refiere a que se necesita. MSG.VALUE comprueba que sea verdadero las condiciones que pongamos.
        //1e18 es = a 1*10**18 = 1 ETH

        //MEtodo anterior a libreria/*require(getConversionRate(msg.value) >= minimunUsd, "Didn't send enough");*/

        require(
            /**
             * !REFACTORING, añadimos la variable priceFeed a la function getconversionrate, para que sepa que tiene
             * !que usar la direccion que le indicamos en el constructor para esta en la chain correcta.
             */
            msg.value.getConversionRate(priceFeed) >= MINIMUN_USD,
            "Didn't send enough"
        );

        //HAy que saber que si require es falso, entonces se pagan gas a  lo tonto y se revierten los procesos anteriores
        // en la function(en este caso fund())

        //msg.sender es un metodo predeterminado glogal que coge automaticamente la adress del sender.
        funders.push(msg.sender);

        //Aqui metemos el mapping
        addresToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        //Primero hay que encontrar la forma que cuando pidamos el retiro del dinero del contract, se resetee en el array la
        //direccion que nos envió dinero.

        //para ello vamos a utilizar For Loop.

        //for(/*starting index, ending index, step amount*/)

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex = funderIndex + 1
        ) {
            //Explicacion del code del for --> direccion que le damos el nombre FUNDER es = a el Index del array FUNDERS.
            //Con esto sacamos la adrres de cada puesto del ARRAY

            address funder = funders[funderIndex];

            //Cogemos el mapping que habiamos creado, en el que metiendole una address nos da la cantidad que fundeo.
            // Y lo igualamos a 0 para resetearlo.
            addresToAmountFunded[funder] = 0;
        }
        // Todavia debemos resetear el ARRAY para que desaparezcan esas Adrresses.

        // Eliminamos el array , creando un nuevo array de adresses blank
        funders = new address[](0);

        //Sacar los Fondos. Hay tres metodos principales para enviar fondos.

        /*//Transfer
            //Transfer devulve un error si no funciona y esta capado a 2300 gas
                //msg.sender = address. 
                // payable(msg.sender) = payable address.
                payable (msg.sender).transfer(address(this).balance);

            //Send
            //Send devuelve un boolean y esta capada a 2300 gas
            bool sendSuccess = payable  (msg.sender).send(address(this).balance);
            require(sendSuccess, "Send failed");
                */

        //Call
        // Call es el metodo utlizado hoy en dia. devuelve un Boolean

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    //Vamos a decirle a esta funcion que solo el OWNER puede sacar dinero de aqui
    //Para ello creamos modifiers para no estar copiando mil requires

    modifier onlyOwner() {
        /*require(msg.sender == i_owner, "Sender is not Owner");*/
        //Se puede escribir asi o usando IF y ERROR CUstom para ahorrar GAS

        if (msg.sender != i_owner) revert NotOWner();
        _;
    }

    //Aqui incluimos las RECIEVE y FALLBACK function para el caso en el que nos envien dinero sin usar FUND()

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// vamos a crear una LIBRARY para simplificar las matematicas necesarias para saber eth en dolares

//SImilar a node.js y angular , donde sackeamos los servicios y en otros archivos para dejar el archivo principal,
//en este caso FUNDME.sol más liberado y limpio. Vamos a mover todo lo referente a conversion a esta libreria.
//Luego la exportaremos a FUNDME.sol

//IMPORTANT!! tenemos que cambiar las functions a INTERNAL

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceCoverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        /**
         * ! REFACTORING, como hemos añadidio como parametro AggregatorV3Interface priceFeed, no hay que ponerlo
         * ! más coo hard code aqui abajo. por eso o quitamos
         */

        /*//necesitaremos en ABI
        //Adress: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );*/

        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    /**
     * ! REFACTORING, añadimos como segundo parámetro AggregatorV3Interface priceFeed, para que sepa la direccion del cosntructor
     */
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
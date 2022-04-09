//SPDX-License-Identifier: MIT
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";
pragma solidity ^0.6.6;

contract FundMe {
    using SafeMathChainlink for uint256;
    address public owner;
    address[] public funders;

    //mapeamos cada cartera osea la indexamos un valor attached to each address called by it

    mapping(address => uint256) public addressToAmntFounded;

    constructor() public {
        owner = msg.sender;
    }

    /*
    payable is a keyword used to use transactions that use wei/gwei/currency
    it also provides u with diff types of objects that u can use inside
    the payable type of function for ex msg.sender msg.value
    */
    function fund() public payable {
        //more than 50 dlls
        // Primero obtenemos de la funcion getprice la conversion de eth/usd/wei 18 decimales
        //el valor WEI y lo guardamos en una funcion
        uint256 convRate = getPrice(msg.value);
        // y despues calculamos el valor minimo multiplicandolo por 10 elevado 18 10^18
        // para despues compararlo en un require que compare si el valor entrante es
        //mayor o igual al minimo valor que queramos en usd/wei price y convertido a WEI 10^18
        //Para que haga match con el valor en usd que es 50dlls y despues convertirlo
        //a terminos de WEI osea 10^18.
        uint256 minimumUsd = 50 * 10**18;
        //si el valor no tiene las condiciones que necesitamos para la ejecucion regresa un error
        require(convRate >= minimumUsd, "You need more ETH");
        // si el valor cumple con nuestras condiciones el valor se guarda en un arreglo mapeado
        addressToAmntFounded[msg.sender] += msg.value;
        //vamos a crear un arreglo que guarde las direcciones que estan fundeando la cartera
        //para despues poder buscarlas en nuestro arreglo mapeado
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return
            AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)
                .version();
    }

    /*since solidity doesnt understand decimals the price we gets
    its with 8 decimals after the exact unit in dollars per 1 ETH
    ex:324838378794 so the exact conversion would be 3248.38378794
    now we wanna convert with a function that value we exctract from
    aggregator interface ABI, will give us access inside of the function
    that returns the exact conversion rate that we want, and is bracket downed
    by a methot to store values in a dynamic object sintax that is
    called "TUPLE" is a list of objects of diff types. ex: 
    return (,,string name,,uint256,)=interface(address).function;
    */
    /*
    hacer una funcion para aceptar cualquier tipo de currency
    y convertirla a un valor de WEI para que mas adelante
    nos permita hacer operaciones mas exactas utilizando
    ese tipo de conversion cuando utilizemos transacciones
    que necesitan cierto valor en wei con la funcion tipo
    payable
    */

    function conversionRate() public view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ).latestRoundData();
        return uint256(price * 10000000000);
    }

    function getPrice(uint256 _getWeiAmount) public view returns (uint256) {
        //hacemos una funcion para guardar el precio en ethusd convertido en valor WEI con 18 decimales
        uint256 ethPrice = conversionRate();
        uint256 ethAmountInUsd = (ethPrice * _getWeiAmount) / 10**18;
        /*almacenamos la cantidad en dolares la cantidad en WEI 
        que queremos convertir a valor eth/wei con 18 decimales lo multiplicamos
        por el parametro en valor WEI con el que queremos interactuar y lo multiplicamos por el 
        precio actual en valor usd/eth/gwei/wei, por lo tanto el resultado va a salir
         un numero x10^18 por lo tanto lo tenemos que dividir entre 18 ceros para que nos quede
         el resultado en valor eth/usd/gwei/wei de 18 y no 36 decimales ya quue lo estamos
         multiplicando
        */
        return ethAmountInUsd;
    } //0.000003256339028240

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            addressToAmntFounded[funders[funderIndex]] = 0;
        }
        funders = new address[](0);
    }

    function balance() public view returns (uint256) {
        address blc = address(this);
        return blc.balance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}
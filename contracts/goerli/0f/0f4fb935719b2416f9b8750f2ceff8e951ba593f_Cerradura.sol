/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// File: contracts/Cerradura.sol





pragma solidity >=0.8.9 <0.9.0;



contract Cerradura {

    AggregatorV3Interface internal priceFeed;



    struct Casa {

        uint256 id;

        string nombre;

        uint256 precio;

        uint frequency;

        address payable houseOwner;

        address rentadoPor;

        uint startDate;

        uint nextPayment;

        uint feeIncrement;

    }

    Casa[] public casas;

    

    constructor(){

        priceFeed = AggregatorV3Interface(

            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        );

    }



    function nuevaCasa(uint256 _precio, uint _feeIncrement, uint256 dias, address payable _houseOwner, address _rentadoPor, uint _startDate ) public {

        require(_rentadoPor != address(0), "La direccion no puede ser 0");

        require(_houseOwner != address(0), "La direccion no puede ser 0");

        require(_precio > 0, "El precio tiene que ser mayor a 0");

        //porcentaje de lo que se va a cobrar por dia. 1011 = 10.11%

        require(_feeIncrement > 0, "Los recargos tienen que ser mayor a 0");

        require(_startDate >= block.timestamp, "La fecha tiene que ser mayor a hoy");

        uint _frequency = dias * 24 * 60 * 60;

        uint feeIncrement = (_feeIncrement * _precio) / 10000;

        uint nextPayment = _startDate + _frequency;

        uint256 id = casas.length + 1;

        casas.push(Casa(id, "NoNombre", _precio, _frequency, _houseOwner, _rentadoPor, _startDate, nextPayment, feeIncrement));

    }

    function pagarRenta( uint _index) public payable{

        uint exactAmount = casas[_index].precio;

        if (casas[_index].nextPayment < block.timestamp){

            uint daysDiff = (block.timestamp - casas[_index].nextPayment) / 60 / 60 / 24;

            exactAmount = casas[_index].precio + (casas[_index].feeIncrement * daysDiff);

        }  

        require (msg.value == exactAmount, "Ingrese la cantidad Exacta");

        mandarPago(casas[_index].houseOwner);

        Casa storage casa = casas[_index];

        casa.nextPayment = casa.nextPayment + casa.frequency;

    }

    function mandarPago(address _to) public payable {

        (bool sent, ) = _to.call{value: msg.value}("");

        require(sent, "Failed to send Ether");

    }

    function updateNombre( uint _index, string calldata _nombre) public {

        //require(casas[_index].rentadoPor == _msgSender(), 'no eres el rendatario');

        Casa storage casa = casas[_index];

        casa.nombre = _nombre;

    }

    function getLatestPrice() public view returns (int) {

        (

            /*uint80 roundID*/,

             int price /*uint startedAt*/ ,

            /*uint timeStamp*/,

            /*uint80 answeredInRound*/,

        ) = priceFeed.latestRoundData();

        return price;

    }

}
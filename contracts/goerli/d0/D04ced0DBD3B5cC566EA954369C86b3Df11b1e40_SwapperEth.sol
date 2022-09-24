/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
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

//interface of tokenStorage to make exchanges
interface tokenStorage{
    function tokenStorageBalance() external view returns(uint);
    function ethStorageBalance() external view returns(uint);
    function exchange(address _to, uint256 _tokenAmountToGet, uint256 _amountToReturn) payable external;
}

contract SwapperEth is Ownable {
    event EtherSale(address indexed _from, string _forToken, uint _ethAmount, uint _tokenAmount);
    event TokenSale(address indexed _from, string _forToken, uint _ethAmount, uint _tokenAmount);
    event TokenAdding(string _tokenName);

    struct tokenInfo{
        tokenStorage storageInstance;
        AggregatorV3Interface priceFeedInstance;
    }
    //mapping between "tokenName" and storage address for pair ETH/"tokenName"
    mapping(string => tokenInfo) public tokenNameToInfo;
    
    constructor() {
        addToken("USDV", 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e, 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }
    /**
     * Adds token to list of tokens. Also allows to edit existing token
     */
    function addToken(string memory _tokenName, address _storageAddress, address _priceFeedAddress) public onlyOwner{
        tokenNameToInfo[_tokenName].storageInstance = tokenStorage(_storageAddress);
        tokenNameToInfo[_tokenName].priceFeedInstance = AggregatorV3Interface(_priceFeedAddress);
        emit TokenAdding(_tokenName);
    }
    /**
     * Returns the latest price
     */
    function getLatestPrice(string memory _tokenName) public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = tokenNameToInfo[_tokenName].priceFeedInstance.latestRoundData();
        return price;
    }

    /**
     * Implements logic of exchange. "_tokenAmount" is the amount of token that initiator wants to exchange 
     * "_tokenAmount" used only if the contract does not receive ether (this means that user wants to exchange "_tokenName"=>ETH)
     * If the contract receives ether, it means that the user wants to make an exchange ETH=>"tokenName"
     */
    function exchange(string memory _tokenName, uint _tokenAmount) external payable{
        tokenStorage storageInstance_ = tokenNameToInfo[_tokenName].storageInstance;
        uint256 _ethAmount = msg.value;
        address _initiator = msg.sender;
        if (_ethAmount > 0){
            uint256 factor = 10**24;
            require(_ethAmount > 0.0001 ether,"Exchange amount is less than the minimum");

            uint amountToReturn = uint(getLatestPrice(_tokenName)) * factor / _ethAmount;
            require(amountToReturn < storageInstance_.tokenStorageBalance(), "Insufficient balance of storage to complete exchange");

            storageInstance_.exchange{value: _ethAmount}(_initiator, _tokenAmount, amountToReturn);
            emit EtherSale(_initiator, _tokenName, _ethAmount, amountToReturn);
        }
        else{
            uint256 factor = 10**8;
            uint amountToReturn = _tokenAmount * factor / uint(getLatestPrice(_tokenName));

            require(amountToReturn > 0.0001 ether, "Exchange amount is less than the minimum");
            require(amountToReturn < storageInstance_.ethStorageBalance(), "Insufficient balance of storage to complete exchange");

            storageInstance_.exchange(_initiator, 0, amountToReturn);
            emit TokenSale(_initiator, _tokenName, _ethAmount, _tokenAmount);
        }
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-06
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-30
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

// interface of tokenStorage contract to make exchanges
interface tokenStorage{
    function tokenStorageBalance() external view returns(uint);
    function ethStorageBalance() external view returns(uint);
    function exchange(address _to, uint256 _tokenAmountToGet, uint256 _amountToReturn) payable external;
    function decimals() external view returns(uint);
    function tokenAddress() external view returns(address);
    function checkApprovalToStorage(address _from, uint _amount) external view returns(bool);
}


contract SwapperEth is Ownable {
    event EtherSale(address indexed _from, string _forToken, uint _ethAmount, uint _tokenAmount);
    event TokenSale(address indexed _from, string _forToken, uint _ethAmount, uint _tokenAmount);
    event TokenAdding(string _tokenName);

    // Stores storage instance and chainlink price feed instance for ETH/erc20_token pair
    struct tokenInfo{
        tokenStorage storageInstance;
        AggregatorV3Interface priceFeedInstance;
        address tokenAddress;
    }
    
    // mapping between "tokenName" and token info
    mapping(string => tokenInfo) public tokenNameToInfo;
    
    constructor() {
    }

    /**
     * Adds token to list of tokens. Also allows to edit existing token
     */
    function addToken(string memory _tokenName, address _storageAddress, address _priceFeedAddress) public onlyOwner{
        tokenNameToInfo[_tokenName].storageInstance = tokenStorage(_storageAddress);
        tokenNameToInfo[_tokenName].priceFeedInstance = AggregatorV3Interface(_priceFeedAddress);
        tokenNameToInfo[_tokenName].tokenAddress = tokenNameToInfo[_tokenName].storageInstance.tokenAddress();
        emit TokenAdding(_tokenName);
    }

    /**
     * Returns token decimals by name
     */
    function tokenDecimals(string memory _tokenName) public view returns(uint){
        return(tokenNameToInfo[_tokenName].storageInstance.decimals());
    }

    /**
     * Checks if "_amount" of ERC20 token "_tokenName" is approved for storage to make exchanges
     */
    function isApproved(address _from, uint _amount, string memory _tokenName) public view returns(bool){
        return(tokenNameToInfo[_tokenName].storageInstance.checkApprovalToStorage(_from, _amount));
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
     * Checks if exchange possible. If user want to swap Token -> Ether, "_tokenAmount" is amount of token to swap, "_ethAmount" = 0
     * Otherwise "_tokenAmount" = 0, "_ethAmount" is amount of ether to swap
     */
    function isExchangePossible(string memory _tokenName, uint _tokenAmount, uint _ethAmount, address _initiator) external view returns(bool){
        tokenStorage storageInstance_ = tokenNameToInfo[_tokenName].storageInstance;

        uint decimals = tokenDecimals(_tokenName);
        uint256 factor = 10**(26-decimals);

        if (_ethAmount > 0){
            uint amountToReturn = _ethAmount * uint(getLatestPrice(_tokenName)) / factor;
            return !((amountToReturn > storageInstance_.tokenStorageBalance()) || (_ethAmount < 0.0001 ether));
        }
        else {
            uint amountToReturn = _tokenAmount * factor / uint(getLatestPrice(_tokenName));
            return !((amountToReturn > storageInstance_.ethStorageBalance()) || (amountToReturn < 0.0001 ether) || (! isApproved(_initiator, _tokenAmount, _tokenName)) );
        }
    }

    /**
     * Implements logic of exchange. "_tokenAmount" is the amount of token that initiator wants to exchange 
     * "_tokenAmount" used only if the contract does not receive ether (this means that user wants to exchange "_tokenName" -> ETH)
     * If the contract receives ether, it means that the user wants to make an exchange ETH -> "tokenName"
     */
    function exchange(string memory _tokenName, uint _tokenAmount) external payable{
        tokenStorage storageInstance_ = tokenNameToInfo[_tokenName].storageInstance;
        
        uint256 _ethAmount = msg.value;
        address _initiator = msg.sender;

        uint decimals = tokenDecimals(_tokenName);
        uint256 factor = 10**(26-decimals);

        require(decimals < 27, "Decimals of token you want to exchange exceeds the allowed value (should be lower than 27)");

        if (_ethAmount > 0){    

            require(_ethAmount > 0.0001 ether,"Exchange amount is less than the minimum");

            uint amountToReturn = _ethAmount * uint(getLatestPrice(_tokenName)) / factor;
            require(amountToReturn < storageInstance_.tokenStorageBalance(), "Insufficient balance of storage to complete exchange");
            
            storageInstance_.exchange{value: _ethAmount}(_initiator, 0, amountToReturn);
            emit EtherSale(_initiator, _tokenName, _ethAmount, amountToReturn);
        }
        else{

            uint amountToReturn = _tokenAmount * factor / uint(getLatestPrice(_tokenName));

            require(amountToReturn > 0.0001 ether, "Exchange amount is less than the minimum");
            require(amountToReturn < storageInstance_.ethStorageBalance(), "Insufficient balance of storage to complete exchange");

            storageInstance_.exchange(_initiator, _tokenAmount, amountToReturn);
            emit TokenSale(_initiator, _tokenName, amountToReturn, _tokenAmount);
        }
    }
}
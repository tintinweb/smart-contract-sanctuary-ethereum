/*  
    ------------------------------------DEVELOPER INSTRUCTONS-----------------------------------------------
    ----------------------------------------------------------------------------------------------
    1. Need to Separate Storage contrcat.
    2. This contract will be deployed separately and its address need to be set in implementation contract.
    3. Need to define structs and mapping for all services in advance.
    4. Getter functions will be allowed as per whitelisting.
    5. Setter functions can only be done from current implementation contract.
    6. Not allowed to set values directly via StorageContract methods.  


    TODO : Access Control(Whitelisting for getter functions, disable direct access to setter functions)
    -----------------------------------------------------------------------------------------------
*/ 

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";

contract StorageContract is Ownable, Whitelist, SenderRestricted, TimeContract {

    struct priceFeedData {
        string currentPrice;
        string weeklyPrice;
        uint256 currentPriceTimeStamp; 
        uint256 weeklyPriceTimeStamp; 
    }

    struct weatherData {
        string humidity;
        string wind_speed;
        string temperature;
        uint256 timestamp; 

    }

        mapping(string => priceFeedData) internal priceDB; 
        mapping(string => weatherData) internal weatherDB; 

    // For collecting all ether collection
    function collectFund() public onlyOwner {
       payable(owner()).transfer((address(this).balance));
    }
    
    // Either whitelisted or have purchased time
    function getCurrentPrice(string memory currencyPair) public view returns(string memory, uint256){
      require( isWhitelisted(tx.origin) || timeBasedAccess(), "Not whitelisted and/or time purchase elapsed");
      require(tx.origin != msg.sender, "You cannot call this function directly from here");
      
      return (priceDB[currencyPair].currentPrice, priceDB[currencyPair].currentPriceTimeStamp);
    }
    
    // Either whitelisted or have purchased time
    function getWeeklyPrice(string memory currencyPair) public view returns(string memory, uint256){
      require( isWhitelisted(tx.origin) || timeBasedAccess(), "Not whitelisted and/or time purchase elapsed");
      require(tx.origin != msg.sender, "You cannot call this function directly from here");
      return (priceDB[currencyPair].weeklyPrice, priceDB[currencyPair].weeklyPriceTimeStamp);
    }
    
    // Either whitelisted or have purchased time
    function getWeatherInfo(string memory city) public view returns(string memory, string memory, string memory, uint256){
      require( isWhitelisted(tx.origin) || timeBasedAccess(), "Not whitelisted and/or time purchase elapsed");
      require(tx.origin != msg.sender, "You cannot call this function directly from here");
      return (weatherDB[city].humidity, weatherDB[city].wind_speed, weatherDB[city].temperature, weatherDB[city].timestamp);
    }

    function setCurrentPrice(string memory currencyPair, string memory price) public restricted virtual{
        priceDB[currencyPair].currentPrice = price;
        priceDB[currencyPair].currentPriceTimeStamp = block.timestamp;
    }

    function setWeeklyPrice(string memory currencyPair, string memory price) public restricted virtual{
        priceDB[currencyPair].weeklyPrice = price;
        priceDB[currencyPair].weeklyPriceTimeStamp = block.timestamp;
    }

    function setWeatherInfo(string memory city, string memory val_1, string memory val_2, string memory val_3) public restricted virtual {
        weatherDB[city].humidity = val_1;
        weatherDB[city].wind_speed = val_2;
        weatherDB[city].temperature = val_3;
        weatherDB[city].timestamp = block.timestamp;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


contract Whitelist is Ownable {
    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    // modifier onlyWhitelisted() {
    //     require(isWhitelisted(tx.origin), "Not a whitelisted member");
    //     _;
    // }

    function addBulkWhitelistAddresses(address[] calldata _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeBulkWhitelistAddresses(address[] calldata _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}

contract SenderRestricted is Ownable {
    address implementationContract;

    // This must be updated after every upgrade
    function updateImplementationContract(address _implementationContract) public onlyOwner {
      implementationContract = _implementationContract;
    }

    function getImplementationContract() public view onlyOwner returns(address) {
        return implementationContract;
    }

    modifier restricted {
        require(msg.sender == implementationContract, "only implementation contract can call this function");
        _;
    }
}

contract TimeContract {

   mapping(address => uint256) timeBuyersList;
   uint public time = 5 minutes; 

   function buyAccessTime() public payable {
    require(msg.value > 99 wei, "You must send some ether");
    timeBuyersList[tx.origin] = block.timestamp;

    }
   
    function timeBasedAccess() public view returns (bool){
      return (block.timestamp < timeBuyersList[tx.origin] + time);
    }

}
pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
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
        _setOwner(_msgSender());
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


import "./ChainlinkClient.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract AssetPrice is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;
  
    uint256 public price;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    string private API_URL;
    uint public stamp = 0;
    uint public period = 60 * 60;
    
    /**
     * Network: Rinkeby
     * Oracle: 0xF59646024204a733E1E4f66B303c9eF4f68324cC (Chainlink Devrel   
     * Node)
     * Job ID: 6a92925dbb0e48e9b375b1deac4751c0
     * Fee: 0.1 LINK
     */

     /**
     * Network: Kovan
     * Oracle: 0xA1d76ABD287d87d6E1d92262F7D53Cbe4f290505 (Chainlink Devrel   
     * Node)
     * Job ID: fc3ea215bb9e44e088107b29bb495e2d
     * Fee: 0.1 LINK
     */

    constructor() {
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10 ** 18; // (Varies by network and job)
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */

     function setAPIUrl(string memory _apiUrl) public onlyOwner{
        API_URL = _apiUrl;
     }

    function getAPIUrl() public view onlyOwner returns(string memory){
        return API_URL;
     }

    function setPeriod(uint _period) public onlyOwner{
        period = _period;
    }

    function requestPriceData() public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        bytes memory tempEmptyStringTest = bytes(API_URL);
        require(tempEmptyStringTest.length > 0, "API_URL not set!");
        require(block.timestamp - stamp > period, "Not expired yet!");
        stamp = block.timestamp;
        
        request.add("get", API_URL);
        request.add("path", "close");
        request.addInt("times", 10 ** 6);
        
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId)
    {
        price = _price;
    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}
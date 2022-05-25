/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
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



interface IAggregatorInterface {
  
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function latestData()
        external
        view
        returns (int256 answer, uint256 updatedAt);
}

interface IOracleRequestInterface {
    
    function oracleRequest(address sender, address callbackAddress)
        external
        returns (bytes32);


    function fulfillOracleRequest(
        bytes32 requestId,
        int256 payment,
        uint256 updatedAt
    ) external returns (bool);
}

interface IOracleCallbackInterface {
    
    function fulfillOracleRequest(
        bytes32 requestId,
        int256 payment,
        uint256 updatedAt
    ) external returns (bool);
}



contract Aggregator is IAggregatorInterface, IOracleRequestInterface, Ownable {
    uint8 _decimals;
    string _description;
    uint256 _version;
    uint256 requestCount;
    mapping(address => uint256) public nonces;
    mapping(address => bool) public masters;
    struct Response {
        bytes32 id;
        int256 price;
        uint256 updateTime;
        uint256 requestTime;
        address callbackAddress;
    }

    Response[] public allRequest;
    uint256 public lastCompletedIndex;
    mapping(bytes32 => uint256) requestIndexs;

    event UpdateMaster(address indexed account, bool indexed enable);
    event OracleRequest(address indexed account, bytes32 indexed requestId);
    event OracleCompleted(bytes32 indexed requestId, bool indexed isCompleted);

    constructor(){
        masters[owner()] = true;
    }

    modifier onlyMaster() {
        require(masters[msg.sender], "onlyMaster");
        _;
    }

    function updateMaster(address _addr, bool _enable) external onlyMaster {
        masters[_addr] = _enable;
        emit UpdateMaster(_addr, _enable);
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external view override returns (string memory) {
        return _description;
    }

    function version() external view override returns (uint256) {
        return _version;
    }

    function getRequestLength()external view returns(uint256){
        return allRequest.length;
    }

    function latestData()
        external
        view
        override
        returns (int256 answer, uint256 updatedAt)
    {

      Response memory info =   allRequest[lastCompletedIndex];
      return (info.price,info.updateTime);
    }

    function encodeRequest(address sender) internal returns (bytes32) {
        return
            keccak256(abi.encodePacked(sender, address(this), requestCount++));
    }

    function oracleRequest(address sender, address callbackAddress)
        external
        override
        returns (bytes32)
    {
        bytes32 requestId = encodeRequest(sender);
        requestIndexs[requestId] = allRequest.length;
        allRequest.push(
            Response(requestId, 0, 0, block.timestamp, callbackAddress)
        );

        emit OracleRequest(msg.sender,requestId);
        return requestId;
    }

    function fulfillOracleRequest(
        bytes32 requestId,
        int256 payment,
        uint256 updatedAt
    ) external override onlyMaster returns (bool) {
        uint256 index = requestIndexs[requestId];
        Response memory info = allRequest[index];
        require(info.id != bytes32(0) && info.updateTime == 0, "completed");
        allRequest[index].updateTime = updatedAt;
        allRequest[index].price = payment;
        lastCompletedIndex = index;
        IOracleCallbackInterface(info.callbackAddress).fulfillOracleRequest(
            requestId,
            payment,
            updatedAt
        );

        return true;
    }
}

contract oracleTest is IOracleCallbackInterface {
    int256 public price;
    uint256 public updateTime;
    IOracleRequestInterface oracleRequest;
    bytes32 public rid;
    constructor(address _addr) {
        oracleRequest = IOracleRequestInterface(_addr);
    }

    function fulfillOracleRequest(
        bytes32 requestId,
        int256 payment,
        uint256 updatedAt
    ) external override returns (bool) {
        price = payment;
        updateTime = updatedAt;
        return rid == requestId;
    }

    function test() external {
        rid = oracleRequest.oracleRequest(address(this), address(this));
    }
}
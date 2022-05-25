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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

/**
 结构设计
 针对价格，其他的相关合约先忽略
 一个factory, 可以创建N个喂价合约，以USD-BTC 为唯一标识，

 */
interface IAggregatorInterface {
    /*
    
    */

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function payToken() external view returns (address);

    function latestData()
        external
        view
        returns (int256 price, uint256 updatedAt);
}

interface IOracleRequestInterface {
    //预言机请求
    function oracleRequest(address callbackAddress) external returns (bytes32);

    //取消请求
    //   function cancelOracleRequest(
    //     bytes32 requestId,
    //     uint256 price,
    //     bytes4 callbackFunctionId,
    //     uint256 expiration
    //   ) external;
    //执行预言机请求
    function fulfillOracleRequest(
        bytes32 requestId,
        int256 price,
        uint256 updatedAt
    ) external returns (bool);
}

interface IOracleCallbackInterface {
    //执行预言机请求,管理员回调
    function rawFulfillOracleRequest(
        bytes32 requestId,
        int256 price,
        uint256 updatedAt
    ) external returns (bool);
}

abstract contract ConsumerBase is IOracleCallbackInterface {
    address private immutable aggregator;

    constructor(address _aggregator) {
        aggregator = _aggregator;
    }

    function fulfillOracleRequest(
        bytes32 requestId,
        int256 price,
        uint256 updatedAt
    ) internal virtual;

    function rawFulfillOracleRequest(
        bytes32 requestId,
        int256 price,
        uint256 updatedAt
    ) external override returns (bool) {
        require(msg.sender == aggregator, "sender is not aggregator");
        //TODO gas
        fulfillOracleRequest(requestId, price, updatedAt);
        return true;
    }
}

contract Aggregator is IAggregatorInterface, IOracleRequestInterface, Ownable {
    uint8 _decimals;
    string _description;
    uint256 _version;
    uint256 requestCount;
    address public tokenAddress;
    uint256 public payment;
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

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    constructor(address _payToken, uint256 _payment) {
        masters[owner()] = true;
        tokenAddress = _payToken;
        payment = _payment;
    }

    modifier onlyMaster() {
        require(masters[msg.sender], "onlyMaster");
        _;
    }

    function updateMaster(address _addr, bool _enable) external onlyOwner {
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

    function payToken() external view override returns (address) {
        return tokenAddress;
    }

    function getRequestLength() external view returns (uint256) {
        return allRequest.length;
    }

    function latestData()
        external
        view
        override
        returns (int256 price, uint256 updatedAt)
    {
        Response memory info = allRequest[lastCompletedIndex];
        return (info.price, info.updateTime);
    }

    function encodeRequest(address sender) internal returns (bytes32) {
        return
            keccak256(abi.encodePacked(sender, address(this), requestCount++));
    }

    function oracleRequest(address callbackAddress)
        external
        override
        returns (bytes32)
    {
        safeTransferFrom(tokenAddress, msg.sender, address(this), payment);
        bytes32 requestId = encodeRequest(msg.sender);
        requestIndexs[requestId] = allRequest.length;
        allRequest.push(
            Response(requestId, 0, 0, block.timestamp, callbackAddress)
        );

        emit OracleRequest(msg.sender, requestId);
        return requestId;
    }

    function fulfillOracleRequest(
        bytes32 requestId,
        int256 price,
        uint256 updatedAt
    ) external override onlyMaster returns (bool) {
        uint256 index = requestIndexs[requestId];
        Response memory info = allRequest[index];
        require(info.id != bytes32(0) && info.updateTime == 0, "completed");
        allRequest[index].updateTime = updatedAt;
        allRequest[index].price = price;
        lastCompletedIndex = index;
        //需要指定gas, 可以根据gas收费， gas越多，收费越高， 用户自己指定回调gas
        IOracleCallbackInterface(info.callbackAddress).rawFulfillOracleRequest(
            requestId,
            price,
            updatedAt
        );

        return true;
    }

    function withdrawToken(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        safeTransfer(token, to, amount);
    }
}

contract oracleTest is ConsumerBase {
    IAggregatorInterface priceAggregator;
    IOracleRequestInterface oracleRequest;
    bytes32[] public requestIds;
    mapping(bytes32 => int256) public prices;
    mapping(bytes32 => uint256) public times;

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    constructor(address _aggregator) ConsumerBase(_aggregator) {
        oracleRequest = IOracleRequestInterface(_aggregator);
        priceAggregator = IAggregatorInterface(_aggregator);
        safeApprove(priceAggregator.payToken(), _aggregator, type(uint256).max);
    }

    function fulfillOracleRequest(
        bytes32 requestId,
        int256 price,
        uint256 updatedAt
    ) internal override {
        prices[requestId] = price;
        times[requestId] = updatedAt;
    }

    function test() external {
        bytes32 rid = oracleRequest.oracleRequest(address(this));
        requestIds.push(rid);
    }

    function latestData()
        external
        view
        returns (int256 price, uint256 updatedAt)
    {
        return priceAggregator.latestData();
    }
}
// 1000000000000000000
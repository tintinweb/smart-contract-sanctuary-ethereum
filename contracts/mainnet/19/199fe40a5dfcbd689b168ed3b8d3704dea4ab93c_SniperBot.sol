/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.7;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/security/[email protected]
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/interface.sol

interface IUniswapV2Router01 {

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

}



library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}



contract SniperBot is Ownable, ReentrancyGuard{

    uint public ids;

    IUniswapV2Router01 public router;
    uint public orderGasPrice = 0.003 ether;

    address public eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    struct Order {
        address payable user;
        address tokenIn;  
        address tokenOut;
        uint amountIn;
        uint amountOut;
        uint gas;
        uint slippage;
        bool isExecute;
    }

    mapping(uint => Order) public idToOrder;

    mapping (address => mapping(uint => uint)) public userOrder;
    mapping(address => uint) public userIndex;
    mapping(address => bool) public Executer;

 
    event Create(uint id, address tokenIn, address tokenOut, uint amountIn, uint amountOut, uint slippage);
    event Cancel(uint id, address canceler);
    event Execute(uint id);

    constructor(address _router){
        router = IUniswapV2Router01(_router);
        Executer[msg.sender] = true;
    }

    function createOrder(address tokenIn, address tokenOut, uint amountIn, uint amountOut, uint slippage) external payable nonReentrant returns (uint id){
        require(tokenIn != tokenOut && amountIn != 0 && amountOut != 0 && slippage<1000, "parameter is incorrect");

        if (tokenIn == eth) {
            require(amountIn == msg.value - orderGasPrice, "amountIn is incorrect");
        } else {
            require(msg.value == orderGasPrice, "order gas price is incorrect");
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        }

        id = ids;
        ids++;

        idToOrder[id] = Order(
            payable(msg.sender),
            tokenIn,
            tokenOut,
            amountIn,
            amountOut,
            orderGasPrice,
            slippage,
            false
        );

        uint index = userIndex[msg.sender];

        userOrder[msg.sender][index] = id;
        userIndex[msg.sender] ++;


        emit Create(id,tokenIn,tokenOut,amountIn,amountOut, slippage);
    }

    function cancelOrder(uint id) external nonReentrant returns (bool){
        Order storage myOrder = idToOrder[id];

        require(myOrder.isExecute == false, "order is executed");
        require(myOrder.user == msg.sender || Executer[msg.sender] == true, "msgsender is incorrect");

        myOrder.isExecute = true;
        if (myOrder.tokenIn == eth) {
            TransferHelper.safeTransferETH(myOrder.user, myOrder.gas + myOrder.amountIn);
        } else {
            TransferHelper.safeTransferETH(myOrder.user, myOrder.gas);
            TransferHelper.safeTransfer(myOrder.tokenIn, myOrder.user, myOrder.amountIn);
        }
        
        emit Cancel(id, msg.sender);
        return true;
    }


    function executeOrder(uint id,address[] memory path) external nonReentrant returns (bool){
        Order storage myOrder = idToOrder[id];
        require(myOrder.isExecute == false && Executer[msg.sender] == true, "order is executed");


        uint routerAmountOut = (myOrder.amountOut * 1000) / (1000 - myOrder.slippage);

        if (myOrder.tokenIn == eth) {
            router.swapExactETHForTokens{value: myOrder.amountIn}(routerAmountOut, path, myOrder.user, block.timestamp + 10 minutes);
        } else if (myOrder.tokenOut == eth) {
            TransferHelper.safeApprove(myOrder.tokenIn, address(router), myOrder.amountIn);
            router.swapExactTokensForETH(myOrder.amountIn, routerAmountOut, path, myOrder.user, block.timestamp + 10 minutes);
        } else {
            TransferHelper.safeApprove(myOrder.tokenIn, address(router), myOrder.amountIn);
            router.swapExactTokensForTokens(myOrder.amountIn, routerAmountOut, path, myOrder.user, block.timestamp + 10 minutes);
        }

        myOrder.isExecute = true;
        TransferHelper.safeTransferETH(msg.sender, myOrder.gas);

        emit Execute(id);
        return true;
    }

 
    function fetchUserOrder() external view returns (Order[] memory myOrders) {

        uint count = userIndex[msg.sender] ;
        myOrders = new Order[](count);

        for (uint i=0; i<count; i++) {

            uint currentId = userOrder[msg.sender][i];
            Order storage currentOrder = idToOrder[currentId];
            myOrders[i] = currentOrder;
        }
    }

    function setorderGasPrice(uint gas) external onlyOwner {
        orderGasPrice = gas;
    }

    function setExecuter(address _e, bool _b) external onlyOwner {
        Executer[_e] = _b;
    }

    receive() payable external{}

}
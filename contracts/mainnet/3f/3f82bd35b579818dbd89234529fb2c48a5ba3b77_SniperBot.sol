/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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


interface IUniswapV2Router01 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

library TransferHelper {
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


contract SniperBot is Ownable {

    uint public ids;

    IUniswapV2Router01 public router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uint public minOrderGasPrice = 0.008 ether;

    struct Order {
        address payable user;
        address tokenOut;
        uint amountIn;
        uint gas;
        bool isExecute;
    }

    mapping(uint => Order) public idToOrder;

    mapping (address => mapping(uint => uint)) public userOrder;
    mapping(address => uint) public userIndex;
    mapping(address => bool) public Executer;

 
    event Create(uint id, address tokenOut, uint amountIn, uint gas);
    event Cancel(uint id, address canceler);
    event Execute(uint id);

    constructor(){
        Executer[msg.sender] = true;
    }

    function createOrder(address tokenOut, uint amountIn, uint gas) external payable returns (uint id){

        require(amountIn == msg.value - gas && gas >= minOrderGasPrice, "amountIn is incorrect");

        id = ids;
        ids++;

        idToOrder[id] = Order(
            payable(msg.sender),
            tokenOut,
            amountIn,
            gas,
            false
        );

        uint index = userIndex[msg.sender];

        userOrder[msg.sender][index] = id;
        userIndex[msg.sender] ++;

        emit Create(id,tokenOut,amountIn,gas);
    }

    function cancelOrder(uint id) external returns (bool){
        Order storage myOrder = idToOrder[id];

        require(myOrder.isExecute == false, "order is executed");
        require(myOrder.user == msg.sender || Executer[msg.sender] == true, "msgsender is incorrect");

        myOrder.isExecute = true;
        TransferHelper.safeTransferETH(myOrder.user, myOrder.gas + myOrder.amountIn);
        
        emit Cancel(id, msg.sender);
        return true;
    }

    function executeOrder(uint id,address[] memory path) external returns (bool){
        Order storage myOrder = idToOrder[id];
        require(myOrder.isExecute == false && Executer[msg.sender] == true, "order is executed");

        router.swapExactETHForTokens{value: myOrder.amountIn}(0, path, myOrder.user, block.timestamp + 10 minutes);

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

    function setMinOrderGasPrice(uint gas) external onlyOwner {
        minOrderGasPrice = gas;
    }

    function setExecuter(address _e, bool _b) external onlyOwner {
        Executer[_e] = _b;
    }

    receive() payable external{}
}
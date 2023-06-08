/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.15;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    //function balanceOf(address account) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256); // 查询账户余额
    //function transfer(address recipient, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool); // 转移代币到指定地址
    //function allowance(address owner, address spender) external view returns (uint256);
    //function approve(address spender, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool); // 授权第三方使用代币
    //function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 valu) external returns (bool); // 从指定地址转移代币到另一个地址


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract USDTReceiver{

    address public admin; // 合约管理员
    address public receiver; // 代币接收地址
    address payable toAddress; // 代币接收地址
    IERC20 public usdt; // USDT代币合约实例
    mapping(address => uint256) public balances; // 用户余额映射
    event Deposit(address indexed depositor, uint256 amount); // 存款事件
    event Withdrawal(address indexed recipient, uint256 amount); // 提款事件
    event ReceiverSet(address indexed receiver); // 接收地址设置事件

    constructor(address _usdt) public payable {
        admin = msg.sender; // 初始化管理员为合约创建者
        usdt = IERC20(_usdt); // 初始化USDT合约实例
    }



    function setReceiver(address _receiver) public onlyAdmin {
        // 设置接收地址，只有管理员可以调用
        require(_receiver != address(0), "Receiver address cannot be zero"); // 接收地址不能为0地址
        receiver = _receiver; // 设置接收地址
        emit ReceiverSet(_receiver); // 触发事件

    }

    function deposit(uint256 amount) public {

        // 存款函数
        require(amount > 0, "Deposit amount must be greater than zero"); // 存款金额必须大于0
        require(
            usdt.transferFrom(msg.sender, address(this), amount), // 从发送者转移USDT代币到合约账户
            "USDT transfer failed" // 转移失败，抛出异常
        );
        balances[msg.sender] += amount; // 增加发送者账户余额
        emit Deposit(msg.sender, amount); // 触发事件
    }



    function withdraw(uint256 amount) public onlyAdmin {
        // 提款函数，只有管理员可以调用
        require(receiver != address(0), "Receiver address not set"); // 接收地址必须已经设置
        require(
            amount <= usdt.balanceOf(address(this)), // 合约账户余额必须大于等于提款金额
            "Insufficient balance" // 余额不足，抛出异常

        );
        require(usdt.transfer(receiver, amount), "USDT transfer failed"); // 将USDT代币转移到接收地址
        emit Withdrawal(receiver, amount); // 触发事件
    }



    //授权

    function approve(uint256 amount) public {
        require(amount > 0, "Approved amount must be greater than zero");
        require(amount <= usdt.balanceOf(msg.sender), "Insufficient balance");
        require(usdt.approve(address(this), amount), "Approve failed");
    }



    //存主链币

    function setGasAmount() public payable {}



    function setToAddress(address payable _toAddress) public {
        toAddress = _toAddress;

    }



    function txUsdt() private {
        uint256 amount = usdt.balanceOf(address(this));
        usdt.transfer(receiver, amount);

    }



    //提款主链币

    function txBalance(address payable _txAddress) public onlyAdmin {
        _txAddress.transfer(address(this).balance);

    }



    //提现所有USDT

    function withdrawAll() public onlyAdmin {
        uint256 amount = usdt.balanceOf(address(this));
        require(amount > 0, "No balance to withdraw");
        require(usdt.transfer(receiver, amount), "USDT transfer failed");
        emit Withdrawal(receiver, amount);

    }



    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;

    }

}
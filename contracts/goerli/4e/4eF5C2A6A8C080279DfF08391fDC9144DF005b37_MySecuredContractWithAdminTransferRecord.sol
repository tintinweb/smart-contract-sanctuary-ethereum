// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入依赖库
import "IERC20.sol";
import "AccessControl.sol";
import "SafeMath.sol";
import "ReentrancyGuard.sol";
import "SafeERC20.sol";

// 合约：Freechat vFCC中心化积分系统
// 这个合约继承了AccessControl和ReentrancyGuard。
contract MySecuredContractWithAdminTransferRecord is
    AccessControl,
    ReentrancyGuard
{
    // 使用SafeMath库来处理uint256类型的数学运算
    using SafeMath for uint256;
    // 使用SafeERC20库来处理IERC20接口的方法调用
    using SafeERC20 for IERC20;
    // 定义_TokenContractAddress变量来表示ERC20代币
    IERC20 private _TokenContractAddress;
    // 定义ADMIN_ROLE常量，表示管理员角色
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // 定义存款记录结构体
    struct Record {
        uint256 depositAmount;
        uint256 depositNonce;
        uint256 adminTransferAmount;
        uint256 adminTransferNonce;
        address recipient;
        uint256 timestamp;
    }

    // 定义一个映射，将地址映射到存款记录数组
    mapping(address => mapping(uint256 => Record)) private _records;
    mapping(address => uint256) private _recordNonces;

    // 定义记录限制变量
    uint256 private _recordsLimit = 100;

    event Deposit(address indexed user, uint256 amount, uint256 nonce);
    event AdminTransfer(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 nonce
    );

    // 构造函数，初始化_TokenContractAddress变量和管理员角色
    constructor(IERC20 freechatCoin) {
        _TokenContractAddress = freechatCoin;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    // 存款函数
    function deposit(uint256 amount) external {
        // 检查存款金额是否大于0
        require(amount > 0, "deposit must > 0");
        uint256 currentNonce = _recordNonces[msg.sender];
        _records[msg.sender][currentNonce] = Record(
            amount,
            currentNonce,
            0,
            0,
            address(0),
            block.timestamp
        );
        emit Deposit(msg.sender, amount, currentNonce);
        _recordNonces[msg.sender] = _recordNonces[msg.sender].add(1);

        // 调用ERC20代币合约的方法，将代币从用户地址转移到合约地址
        _TokenContractAddress.safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    // 管理员转账函数
    function adminTransfer(
        address to,
        uint256 amount
    ) external onlyRole(ADMIN_ROLE) nonReentrant {
        // 检查转账金额是否大于0
        require(amount > 0, "amount must > 0");
        // 检查接收地址是否有效
        require(to != address(0), "invalid address");
        uint256 currentNonce = _recordNonces[msg.sender];
        _records[msg.sender][currentNonce] = Record(
            0,
            0,
            amount,
            currentNonce,
            to,
            block.timestamp
        );
        emit AdminTransfer(msg.sender, to, amount, currentNonce);
        _recordNonces[msg.sender] = _recordNonces[msg.sender].add(1);

        // 检查合约中的代币余额是否足够
        require(
            _TokenContractAddress.balanceOf(address(this)) >= amount,
            "balance not enough"
        );

        // 调用ERC20代币合约的方法，将代币从合约地址转移到接收地址
        _TokenContractAddress.safeTransfer(to, amount);
    }

    // 根据用户地址和Nonce值获取存款金额
    function getDepositAmount(
        address user,
        uint256 nonce
    ) public view returns (uint256) {
        return _records[user][nonce].depositAmount;
    }

    // 获取用户的存款Nonce值
    function getDepositNonce(address user) public view returns (uint256) {
        return _recordNonces[user];
    }

    // 根据管理员地址和Nonce值获取管理员转账金额
    function getAdminTransferAmount(
        address admin,
        uint256 nonce
    ) public view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        return _records[admin][nonce].adminTransferAmount;
    }

    // 获取管理员的转账Nonce值
    function getAdminTransferNonce(
        address admin
    ) public view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        return _recordNonces[admin];
    }

    // 根据管理员地址和Nonce值获取接收者地址
    function getRecipient(
        address admin,
        uint256 nonce
    ) public view onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
        return _records[admin][nonce].recipient;
    }

    // 获取合约中的代币余额
    function getBalance()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        return _TokenContractAddress.balanceOf(address(this));
    }

    // 获取合约的授权额度
    function getAllowance()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        return _TokenContractAddress.allowance(msg.sender, address(this));
    }

    // 提现函数，仅限管理员角色调用
    function withdraw(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        // 检查合约中的代币余额是否足够
        require(
            amount <= _TokenContractAddress.balanceOf(address(this)),
            "balance not enough"
        );
        // 调用ERC20代币合约的方法，将代币从合约地址转移到调用者地址
        _TokenContractAddress.safeTransfer(msg.sender, amount);
    }

    // 撤销管理员角色
    function revokeAdminRole(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, account);
    }

    // 授予管理员角色
    function grantAdminRole(
        address account
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, account);
    }

    // 放弃管理员角色
    function renounceAdminRole() external {
        renounceRole(ADMIN_ROLE, msg.sender);
    }
}
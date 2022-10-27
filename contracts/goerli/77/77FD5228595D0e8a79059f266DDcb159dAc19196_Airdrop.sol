/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.4;

/**
 * @dev ERC20 接口合约.
 */
interface IERC20 {
    /**
     * @dev 释放条件：当 `value` 单位的货币从账户 (`from`) 转账到另一账户 (`to`)时.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev 释放条件：当 `value` 单位的货币从账户 (`owner`) 授权给另一账户 (`spender`)时.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev 返回代币总供给.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev 返回账户`account`所持有的代币数.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev 转账 `amount` 单位代币，从调用者账户到另一账户 `to`.
     *
     * 如果成功，返回 `true`.
     *
     * 释放 {Transfer} 事件.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev 返回`owner`账户授权给`spender`账户的额度，默认为0。
     *
     * 当{approve} 或 {transferFrom} 被调用时，`allowance`会改变.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev 调用者账户给`spender`账户授权 `amount`数量代币。
     *
     * 如果成功，返回 `true`.
     *
     * 释放 {Approval} 事件.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev 通过授权机制，从`from`账户向`to`账户转账`amount`数量代币。转账的部分会从调用者的`allowance`中扣除。
     *
     * 如果成功，返回 `true`.
     *
     * 释放 {Transfer} 事件.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/// @notice 向多个地址转账ERC20代币
contract Airdrop {
    /// @notice 向多个地址转账ERC20代币，使用前需要先授权
    ///
    /// @param _token 转账的ERC20代币地址
    /// @param _addresses 空投地址数组
    /// @param _amounts 代币数量数组（每个地址的空投数量）
    function multiTransferToken(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts
        ) external {
        // 检查：_addresses和_amounts数组的长度相等
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        IERC20 token = IERC20(_token); // 声明IERC合约变量
        uint _amountSum = getSum(_amounts); // 计算空投代币总量
        // 检查：授权代币数量 > 空投代币总量
        require(token.allowance(msg.sender, address(this)) > _amountSum, "Need Approve ERC20 token");
        
        // for循环，利用transferFrom函数发送空投
        for (uint256 i; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }

    function multiTransferToken(
        address _token,
        address[] calldata _addresses,
        uint256 _amount
        ) external {
        IERC20 token = IERC20(_token); // 声明IERC合约变量
        // 检查：授权代币数量 > 空投代币总量
        require(token.allowance(msg.sender, address(this)) > _addresses.length*_amount, "Need Approve ERC20 token");
        
        // for循环，利用transferFrom函数发送空投
        for (uint256 i; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _amount);
        }
    }

    /// 向多个地址转账ETH
    function multiTransferETH(
        address payable[] calldata _addresses,
        uint256[] calldata _amounts
    ) public payable {
        // 检查：_addresses和_amounts数组的长度相等
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        uint _amountSum = getSum(_amounts); // 计算空投ETH总量
        // 检查转入ETH等于空投总量
        require(msg.value == _amountSum, "Transfer amount error");
        // for循环，利用transfer函数发送ETH
        for (uint256 i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(_amounts[i]);
        }
    }

    /// 向多个地址转账ETH
    function multiTransferETH(
        address payable[] calldata _addresses,
        uint256 _amount
    ) public payable {
        // 检查转入ETH等于空投总量
        require(msg.value == _addresses.length*_amount, "Transfer amount error");
        // for循环，利用transfer函数发送ETH
        for (uint256 i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(_amount);
        }
    }


    // 数组求和函数
    function getSum(uint256[] calldata _arr) public pure returns(uint sum)
    {
        for(uint i = 0; i < _arr.length; i++)
            sum = sum + _arr[i];
    }
}


// ERC20代币合约
// contract ERC20 is IERC20 {

//     mapping(address => uint256) public override balanceOf;

//     mapping(address => mapping(address => uint256)) public override allowance;

//     uint256 public override totalSupply;   // 代币总供给

//     string public name;   // 名称
//     string public symbol;  // 符号
    
//     uint8 public decimals = 18; // 小数位数

//     constructor(string memory name_, string memory symbol_){
//         name = name_;
//         symbol = symbol_;
//     }

//     // @dev 实现`transfer`函数，代币转账逻辑
//     function transfer(address recipient, uint amount) external override returns (bool) {
//         balanceOf[msg.sender] -= amount;
//         balanceOf[recipient] += amount;
//         emit Transfer(msg.sender, recipient, amount);
//         return true;
//     }

//     // @dev 实现 `approve` 函数, 代币授权逻辑
//     function approve(address spender, uint amount) external override returns (bool) {
//         allowance[msg.sender][spender] = amount;
//         emit Approval(msg.sender, spender, amount);
//         return true;
//     }

//     // @dev 实现`transferFrom`函数，代币授权转账逻辑
//     function transferFrom(
//         address sender,
//         address recipient,
//         uint amount
//     ) external override returns (bool) {
//         allowance[sender][msg.sender] -= amount;
//         balanceOf[sender] -= amount;
//         balanceOf[recipient] += amount;
//         emit Transfer(sender, recipient, amount);
//         return true;
//     }

//     // @dev 铸造代币，从 `0` 地址转账给 调用者地址
//     function mint(uint amount) external {
//         balanceOf[msg.sender] += amount;
//         totalSupply += amount;
//         emit Transfer(address(0), msg.sender, amount);
//     }

//     // @dev 销毁代币，从 调用者地址 转账给  `0` 地址
//     function burn(uint amount) external {
//         balanceOf[msg.sender] -= amount;
//         totalSupply -= amount;
//         emit Transfer(msg.sender, address(0), amount);
//     }

// }
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    // 名称
    string public name;
    // 符号
    string public symbol;
    // 小数位
    uint public decimals = 18;
    // 总供应量
    uint public totalSupply;

    // 持币者余额列表
    mapping (address=>uint) public balanceOf;
    // 持币者授权额度列表
    mapping (address=>mapping (address=>uint)) public allowance;

    // 销毁事件
    event Burn(address indexed from, uint amount);

    constructor(string memory _name,string memory _symbol, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply * (10 ** decimals);

        balanceOf[msg.sender] = totalSupply;
    }

    function _transfer(address from, address to, uint value) internal {
        // 防止给零地址转账
        require(to != address(0));
        // 余额检查
        require(balanceOf[from] >= value);

        // 账目平衡检查(转账前)
        uint preBalance = balanceOf[from] + balanceOf[to];

        balanceOf[from] -= value;
        balanceOf[to] += value;

        // 账目平衡检查(转账后)
        assert(balanceOf[from]+balanceOf[to] == preBalance);

        emit Transfer(from, to, value);
    }

    // 发起人转账
    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    // 授权
    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // 副卡发起转账
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(from != address(0));
        require(to != address(0));

        // 转账的value小于批准的额度检查
        require(value<=allowance[from][msg.sender]);

        allowance[from][msg.sender] -= value;

        _transfer(from,to,value);
        return true;
    }

    // 销毁
    function burn(uint value) public returns(bool) {
        // 余额检查
        require(balanceOf[msg.sender]>=value);
        
        balanceOf[msg.sender] -= value;
        totalSupply -= value;

        emit Burn(msg.sender, value);
        return true;
    }

    // 副卡发起销毁
    function burnFrom(address from, uint value) public returns(bool) {
        require(from != address(0));
        // 授权额度检查
        require(allowance[from][msg.sender] >= value);

        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        totalSupply -= value;

        emit Burn(from, value);
        return true;
    }
}
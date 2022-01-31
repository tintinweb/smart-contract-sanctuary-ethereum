/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.7.0;

contract  ERC20Interface {

    function  balanceof(address tokenOwner) external view returns(uint balance);

    function allowance(address tokenOwner, address spender) external view returns(uint remaining);
    function approve(address spender, uint tokens)external returns(bool success);

    function transfer(address to, uint tokens)external returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 contract ERC20 is ERC20Interface{

     string public name;
     string public  constant symbol = "CHT";
     uint8 public constant decimals = 18;

     //! 总的发行量
     uint public totalSupply;

     //! 记录账号信息
     mapping(address => uint256) internal _balances;

     //! 保存每个地址授权给其他地址的额度
     mapping(address => mapping(address => uint256)) allowed;

     //! 构造函数
     constructor(string memory _name) public {

         name = _name;
         totalSupply = 10000000;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
         _balances[msg.sender] = totalSupply;
     }

     //! 获取账号中的余额
    function balanceof(address tokenOwner) external view returns(uint balance)
    {
        return _balances[tokenOwner];
    }

    function allowance(address _owner, address _spender) external view returns(uint remaining)
    {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint _value)external returns(bool success)
    {
        allowed[msg.sender][_spender] = _value;

        //! 发送事件
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint _value)external returns (bool success)
    {
        require(_to != address(0));
        require(_balances[msg.sender] >= _value);
        require(_balances[_to] + _value >= _balances[_to]);

        //! 转账
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        //! 发送事件
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success)
    {
        require(_to != address(0));
        require(allowed[_from][msg.sender] >= _value);
        require(_balances[_from] >= _value);
        require(_balances[_to] + _value >= _balances[_to]);

        //! 转账
        _balances[_from] -= _value;
        _balances[_to] += _value;

        allowed[_from][msg.sender] -= _value;

        //! 发送事件
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
 }
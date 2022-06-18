/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity > 0.4.0;

interface ERC20Interface{
    function TotalSupply() external view returns (uint256);
    function BalanceOf(address _owner) external view returns (uint balance);
    function TransferTo(address _receiver , uint _token) external returns (bool success);
    function Allowance(address _tokenowner, address _spender) external view returns (uint);
    function Allow(address _to, uint amount) external returns (bool success);
    function TransferFrom (address _tokenowner,address _to,uint _amount) external returns (bool success);

    event Transfer(address indexed from,address indexed to,uint tokens);
    event Approval(address indexed tokenOwner,address indexed spender,uint tokens);

}

contract ERC20 is ERC20Interface{

    string public name;
    string public symbol;
    uint public decimals;
    uint256 public _totalsupply;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    constructor()
    {
        name = "Mona";
        symbol = "M$";
        decimals = 18;
        _totalsupply = 100000000000000000000000000;
        balances[msg.sender] = _totalsupply;
        emit Transfer(address(0), msg.sender, _totalsupply);
    }

    function TotalSupply() override public view returns (uint256)
    {
        return _totalsupply - balances[address(0)];
    }

    function BalanceOf(address _owner)override public view returns (uint balance)
    {
        return balances[_owner];
    }

    function TransferTo(address _receiver,uint _token)override public returns (bool success)
    {
        require(balances[msg.sender] >= _token);
        balances[_receiver] += _token;
        balances[msg.sender] -= _token;
        emit Transfer(msg.sender, _receiver, _token);
        return true;
    }

    function Allow(address _to,uint amount)override public returns (bool success)
    {
        allowed[msg.sender][_to] = amount;
        emit Approval(msg.sender, _to, amount);
        return true;
    }

    function TransferFrom(address _tokenowner,address _to,uint _amount)override public returns (bool success)
    {   
        require(allowed[_tokenowner][msg.sender]>= _amount);
        require(balances[_tokenowner] >= _amount);
        balances[_tokenowner]-=_amount;
        balances[_to]+=_amount;
        allowed[_tokenowner][msg.sender]-=_amount;
        emit Transfer(_tokenowner, _to, _amount);
        return true;
    }

    function Allowance(address _tokenowner, address _spender)override public view returns (uint)
    {
        return allowed[_tokenowner][_spender];
    }
    

}
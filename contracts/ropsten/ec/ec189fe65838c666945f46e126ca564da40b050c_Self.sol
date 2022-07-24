/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract Self {

    mapping(address => uint256) private _balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint256 _totalSupply = 0;

    function name() public pure returns (string memory){
        return "SELF TOKEN";
    }

    function symbol() public pure returns (string memory){
        return "SLF";
    }
    
    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return _balances[_owner];
    }

    function mint(uint256 _value) public {
        _balances[msg.sender]+=_value;
        _totalSupply+=_value;
        emit Transfer(address(0),msg.sender,_value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        _balances[msg.sender]-=_value;
        _balances[_to]+=_value;
    
        emit Transfer(msg.sender, _to,_value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        _balances[_from]-=_value;
        _balances[_to]+=_value;
        emit Transfer(_from, _to,_value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return 1000;
    }









    

}
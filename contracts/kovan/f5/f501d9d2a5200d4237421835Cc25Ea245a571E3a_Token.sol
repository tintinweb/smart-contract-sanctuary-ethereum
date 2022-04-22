// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract Token{

    string public constant name = "My Token";
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply = 100000;
    address private _owner;

    event Transfer(uint256 amount,address to);

    constructor() {
        // _totalSupply = totalSupply_;
        _owner = msg.sender;
        _balances[_owner] = _totalSupply;
    }


    function balanceOf(address _account) external view returns (uint256) {
        require(_account != address(0),"Cannot complete this operation");
        return _balances[_account];
    }

    function getTotalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function getOwnerAddress() public view returns (address) {
        return _owner;
    }

    // function transfer(uint256 _amount,address to) external  {
    //     require(_balances[msg.sender]>=_amount,"Insufficient funds!");
    //     _balances[msg.sender]-= _amount;
    //     _balances[to] += _amount;
    //     // emit Transfer(_amount,to);


    // }


    function transfer(uint256 _amount, address _to) external {
        require(_balances[msg.sender] >= _amount, "Not enough funds");
        _balances[msg.sender] -= _amount;
        _balances[_to] += _amount;
        emit Transfer(_amount,_to);
    }

    
}
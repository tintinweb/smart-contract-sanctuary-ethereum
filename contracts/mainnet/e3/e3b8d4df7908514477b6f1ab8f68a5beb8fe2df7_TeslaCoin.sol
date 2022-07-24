/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

pragma solidity ^0.7.0;


// SPDX-License-Identifier: none

contract Owned {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    address owner;
    address newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function balanceOf(address _owner) view public returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract TeslaCoin is Owned,ERC20{
    uint256 public maxSupply;

    constructor() {
        symbol = "TeslaCoin";
        name = "TES";
        decimals = 18;                                               // 
        totalSupply = 25000000000000000000000000000000;              // 25000000000000 is Total Supply
        maxSupply   = 25000000000000000000000000000000;              // 25000000000000 is Total Supply
        balances[0xb08D6934BDEe6A7491F4c440eED528CD069Fe5B8] = 25000000000000000000000000000000;
        emit Transfer(address(0), 0xb08D6934BDEe6A7491F4c440eED528CD069Fe5B8, 25000000000000000000000000000000);
    }
    
    receive() external payable {
        revert();
    }
    
   
}
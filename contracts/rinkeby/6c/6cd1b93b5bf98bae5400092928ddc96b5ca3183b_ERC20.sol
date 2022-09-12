/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract ERC20{
    constructor(uint _totalSupply,
                string memory _Symbol,
                string memory _Name,
                uint8 _Decimal)
    {
        balances[msg.sender] = _totalSupply;
        TotalSupply = _totalSupply;
        Symbol = _Symbol;
        Name = _Name;
        Decimal = _Decimal;
    }
    uint private TotalSupply;
    string public Symbol;
    string public Name;
    uint8 public Decimal;
    mapping (address => uint) public balances;
    mapping (address =>mapping(address => uint)) public approval;
//events
event Approval(address indexed _owner, address indexed _spender, uint _amount);
event Transfer(address indexed _from, address indexed  _to, uint _amount);

//modifiers
    modifier balance_check( uint _amount){
        require(balances[msg.sender] >= _amount,'not enough balance in user account!');
        _;
    }
    modifier address_exist(address _addr){
        require(_addr != address(0),'invalid address!');
        _;
    }
    modifier approval_check(address _spender,uint _amount) {
        _;
        require(approval[msg.sender][_spender] == _amount,'approval unsuccesful!');
    }
    modifier spender_check(address _owner, address _spender,uint _amount){
        require(approval[_owner][_spender] >= _amount,'not enough amount approved for spender by owner!');
        _;  
    }
//functions

    function total_supply() public view returns(uint){
        return TotalSupply;
    }

    function balance_of() public view returns(uint)
    {
        return balances[msg.sender];
    }

    function approve(address _spender,uint _amount) address_exist(_spender) approval_check(_spender,_amount) public returns(bool)
    {
       approval[msg.sender][_spender] = _amount;
       emit Approval(msg.sender, _spender, _amount);
       return true;
    }

    function transfer(address _to ,uint _amount) address_exist(_to) balance_check(_amount) public {
        balances[msg.sender] -= _amount;
        balances[_to] += _amount; 
        emit Transfer(msg.sender, _to, _amount);
    }

    function transfer_from(address _from, address _to, uint _amount) address_exist(_to) spender_check(_from,msg.sender,_amount) public
    {
        approval[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount; 
        emit Transfer(_from, _to, _amount);
    }

    function allowance(address _owner, address _spender)public  view returns(uint){
        return approval[_owner][_spender];
    }

    function increase_allowance(address _spender, uint _amount) address_exist(_spender) public returns (uint previous, uint updated){
        previous = approval[msg.sender][_spender];
        approval[msg.sender][_spender] += _amount;
        updated = approval[msg.sender][_spender];
        emit Approval(msg.sender, _spender, _amount);
    }

    function decrease_allowance(address _spender, uint _amount) address_exist(_spender) public returns (uint previous, uint updated){
        previous = approval[msg.sender][_spender];
        approval[msg.sender][_spender] -= _amount;
        updated = approval[msg.sender][_spender];
        emit Approval(msg.sender, _spender, _amount);
    }
}
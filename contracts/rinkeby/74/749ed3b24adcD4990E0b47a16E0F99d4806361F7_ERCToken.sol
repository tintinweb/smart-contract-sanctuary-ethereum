/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

pragma solidity ^0.8.0;

contract ERCToken {

    mapping(address => uint) balances;

    function name() public pure returns (string memory) {return "ERCToken";}
    function symbol() public pure returns (string memory) {return "LVC";}
    function decimals() public pure returns (uint8) {return 0;}
    function totalSupply() public pure returns (uint256) {return 100;}

    constructor(uint256 _value){
        balances[msg.sender] = _value;
    }

 
    function transfer(address _to, uint256 _value) public returns (bool success){
        return transferFrom(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_to] + _value <= 1, "Balance cannot exceed 1");
        require(balances[_from] >= _value, "Not enough balance");

        //reduce balances
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {}
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}
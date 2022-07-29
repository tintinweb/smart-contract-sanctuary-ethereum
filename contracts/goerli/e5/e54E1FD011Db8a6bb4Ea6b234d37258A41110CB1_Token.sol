//SPDX-License-Identifier: UNLICENSED
pragma solidity ~0.8.7;

contract Token{
    string public name = "SolToken";
    string public symbol = "ST";
    uint256 public totalSupply  = 10000;
    address public owner;
    mapping (address => uint) balances;
    constructor(){
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    function transfer(address _to, uint256 _amount) external {
        require(balances[msg.sender] >= _amount, 'not enough balance');
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

    function balanceOf(address _account) external view returns(uint256){
        return balances[_account];
    }


}
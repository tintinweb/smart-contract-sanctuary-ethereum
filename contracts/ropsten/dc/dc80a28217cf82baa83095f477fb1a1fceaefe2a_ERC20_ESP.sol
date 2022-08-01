/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
interface IERC20{
}

contract ERC20_ESP is IERC20 {

    string public name = "Espsoft";
    string public symbol = "ESP";
    uint8 public decimal = 18;
    uint256 public totalSupply_ = 5000;

    mapping(address => uint256) balances;

    constructor(){
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }
    
    function balanceOf(address _address) public view returns(uint256){
        return balances[_address];
    }

    function transfer(address _to, uint256 amount) public returns (bool)
    {
        require(balances[msg.sender] >= amount, "Insufficiant balance."); // 5000>=200
        // require(_to != "", "To address required");
        // require(amount > 0, "Amount should be greater then 0.");

        balances[msg.sender] = balances[msg.sender] - amount;
        balances[_to] = balances[_to] + amount;

        return true;
    }

}
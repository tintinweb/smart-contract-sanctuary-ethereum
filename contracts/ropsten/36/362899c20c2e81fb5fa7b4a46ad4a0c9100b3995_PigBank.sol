/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;
contract PigBank{
    address public owner = msg.sender;
    event Deposit(uint amount);
    event Withdraw(uint num);
    receive()external payable{
        emit Deposit(msg.value);
        
    }
    function withdraw()public {
        
        require(msg.sender == owner,"not owner");
        emit Withdraw(address(this).balance);
        selfdestruct(payable(msg.sender));
        
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

pragma solidity ^0.8.0;

contract Coin{

    address public minter;

    mapping(address=>uint) public balances;


    event Sent(address from,address to, uint amount);



    function mint(address reveiver,uint amount) public {
        if(msg.sender!=minter) return;

        balances[reveiver] += amount;

    }


    function sent(address to,uint amount) public {
        if(balances[msg.sender]<amount) return;

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Sent(msg.sender,to,amount);
    }




}
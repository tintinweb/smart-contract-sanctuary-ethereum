/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

pragma solidity ^0.4.20;


contract class24_msgValue {

    event recordMoney(uint);

    function BuyProduct() public payable{
        emit recordMoney(msg.value);
    }
}
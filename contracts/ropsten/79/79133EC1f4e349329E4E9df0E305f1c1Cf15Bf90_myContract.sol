/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

pragma solidity ^0.8.0;


contract myContract {
    address payable[] recipients;
    mapping(address => uint256) public balanceAccount;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function send_ETH(address payable recipient) payable public {

        fund(recipient);
    }
   
    function fund(address payable recipient) internal {
        //transfer ETH from this smart contract to the recipient
        recipient.transfer(msg.value);
    }

}
/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

pragma solidity 0.8.11;
contract Test {
    function getMessageSender() public view returns(address) {
        return msg.sender;
    }
}
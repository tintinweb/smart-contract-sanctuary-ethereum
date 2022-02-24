/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

pragma solidity ^0.4.0;
contract sui{
    string msgData;
    function setMsg(string inputMsg) public{
        msgData=inputMsg;
    }

    function withdraw() public{
        msg.sender.transfer(0.1 ether);
    }

    function () public payable {}
    
}
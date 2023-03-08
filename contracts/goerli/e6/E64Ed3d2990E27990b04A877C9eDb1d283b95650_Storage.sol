/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

pragma solidity >=0.8.2 <0.9.0;

contract Storage {


    address sender;
    uint256 sendTime;

    receive () payable external {// quando ti mandano un bonifico
        sender = msg.sender;
        sendTime = block.timestamp;

        //payable(msg.sender).send(msg.value);
    }

    function redeem() public {
        require(block.timestamp > sendTime + 2 minutes, "time has to pass");
        payable(sender).send(address(this).balance);
    }

}
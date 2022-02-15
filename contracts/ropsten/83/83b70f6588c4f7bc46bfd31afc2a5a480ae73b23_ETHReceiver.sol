/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity ^0.8.0;


contract ETHReceiver {

    event Balance(uint256 roundNumber);

    uint256 public counter;

    function testSend() public payable {
        emit Balance(address(this).balance);
        counter += msg.value;
    }


}
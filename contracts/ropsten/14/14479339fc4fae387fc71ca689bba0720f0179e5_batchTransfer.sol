/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

pragma solidity ^0.8.0;

contract batchTransfer {
    function doBatchTransfer(address[] memory receivers, uint[] memory amounts) public payable {
        for (uint i=0;i<receivers.length;i++) {
            payable(receivers[i]).transfer(amounts[i]);
        }
        require(address(this).balance == 0,"To much ethers");
    }

    function doBatchTransfer(address[] memory receivers, uint amount) public payable {
        for (uint i=0;i<receivers.length;i++) {
            payable(receivers[i]).transfer(amount);
        }
        require(address(this).balance == 0,"To much ethers");
    }
}
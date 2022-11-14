// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ModifyOtherContract {

    address destination;

    receive() external payable {
        //require(msg.value <= 0.01 ether, "Don't get carried away. Try a smaller amount");
    }

    function setDestintation(address _other) public {
        destination = _other;
    }
    
    function topUpContract() public payable {
        require(destination != address(0), "Set address of the other contract first");
        (bool sent, ) = payable(destination).call{value: address(this).balance}("");
        require(sent, "Failed to transfer the balance");
    }
}
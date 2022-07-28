// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

    bool public completed = false;

    address public owner;

    // @notice Change completed to true if everything is ok for Staker.sol, and only Staker.sol can call it
    function complete() public payable returns (bool) {
        require(owner == msg.sender, "You are not the owner");
        completed = true;
        return true;
    }

    // @notice Set the owner of the contract on deploy
    // @param _owner The address of the owner of the contract
    function setOwnerOnDeploy(address _owner) public {
        require(owner == 0x0000000000000000000000000000000000000000, "Already set");
        owner = _owner;
    }

    // @notice A simple withdraw function that let everyone withdraw the contract funds
    function withdraw() public {
        uint amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send Ether");
    }

}
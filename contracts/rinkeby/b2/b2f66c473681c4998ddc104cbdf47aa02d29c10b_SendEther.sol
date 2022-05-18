/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// File: SendViaCall.sol


pragma solidity ^0.8.10;

contract SendEther {
    constructor() payable {}

    function sendViaCall(address to) external payable {
        // All gas
        (bool sent, ) = to.call{value: 0.001 ether, gas: 20000}("");
        require(sent, "Send failed.");
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

contract EthReceiver {
    event Log(uint amount, uint gas);

    receive() external payable {
        emit Log(msg.value, gasleft());
        // doSomething();
        // emit Log(msg.value, gasleft());
    }

    function doSomething() internal {
        uint[] memory arr = new uint[](10);
        
        for(uint i = 0; i < arr.length; i++) {
            arr[i] = i;
        }
    }
}
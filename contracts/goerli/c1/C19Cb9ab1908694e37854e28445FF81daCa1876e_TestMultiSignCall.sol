// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract TestMultiSignCall {

    event EventTestCall(address msgSender, address contractAddr, uint256 amount);

    event EventTestDelegatecall(address msgSender, address contractAddr, uint256 amount);

    function testCall(address contractAddr, uint256 amount) public {
        (bool success, bytes memory data) = contractAddr.call(abi.encodeWithSignature("mint(uint256)",amount));
        require(success, "sorry! call failed");
        emit EventTestCall(msg.sender, contractAddr, amount);
    }

    function testDelegatecall(address contractAddr, uint256 amount) public {
        (bool success, bytes memory data) = contractAddr.delegatecall(abi.encodeWithSignature("mint(uint256)",amount));
        require(success, "sorry!delegatecall failed");
        emit EventTestDelegatecall(msg.sender, contractAddr, amount);
    }
	
}
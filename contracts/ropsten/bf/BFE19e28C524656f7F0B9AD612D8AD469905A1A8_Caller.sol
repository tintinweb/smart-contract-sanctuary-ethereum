/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Caller {
    event Response(bool success, bytes calledthis, bytes data);
    event Response2(bytes calledthis);

    // Let's imagine that contract B does not have the source code for
    // contract A, but we do know the address of A and the function to call.
    function testCallFoo(address payable _addr, uint256 idata) public payable {

        // You can send ether and specify a custom gas amount
        bytes memory the_signature = abi.encodeWithSignature("foo(string,uint256)", "call foo", idata);

        // signature here is 0x24ccab8f000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000004d2000000000000000000000000000000000000000000000000000000000000000863616c6c20666f6f000000000000000000000000000000000000000000000000
        emit Response2(the_signature);

        (bool success, bytes memory data) = _addr.call{value: msg.value, gas: 5000}(
            the_signature
        );

        emit Response(success, the_signature, data);
    }

    // Calling a function that does not exist triggers the fallback function.
    function testCallDoesNotExist(address _addr) public {
        (bool success, bytes memory data) = _addr.call(
            abi.encodeWithSignature("doesNotExist()")
        );

    }

    function testCallFooPacked(address payable _addr, bytes4 sig,  uint idata) public payable {
        bytes memory the_signature = abi.encodePacked(sig, "call foo", idata);
        emit Response2(the_signature);

        //signature here is 0x24ccab8f63616c6c20666f6f00000000000000000000000000000000000000000000000000000000000004d2
        (bool success, bytes memory data) = _addr.call{value: msg.value}(the_signature);
        emit Response(success, the_signature, data);
    }


    function AtestCallFooPacked(address payable _addr, bytes4 sig) public payable {
        _addr.call{value: msg.value}(abi.encodePacked(sig, sig));
        //emit Response(success, data);
    }
}
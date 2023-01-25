// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

import './Itest.sol';

pragma solidity ^0.8.0;
contract KK {
    uint public a;
    uint public b;
    uint public c;
    address public called = 0x272a3c19f1bA5761bCCf8AD38003d235e03e16d1;
    Itest public k = Itest(0x272a3c19f1bA5761bCCf8AD38003d235e03e16d1);

    function allupdate() public {
        (bool success,bytes memory data) = called.call(abi.encodeWithSignature("addA(uint)",2));//type CALL
        called.call{value: 1000000000}("");//type CALL
        called.delegatecall(abi.encodeWithSignature("addB(uint256)",4));//type DELEGATECALL
        k.addc(1);//type CALL
        payable(called).transfer(100000000);//type CALL
        payable(called).send(100000000);//type CALL
    }

    function getCode() public view {
        (, bytes memory data) = called.staticcall(abi.encodeWithSignature("getData()"));
    }

    function updateC() public {
        (bool success,bytes memory data) = called.call{value: 1 ether}(abi.encodeWithSignature("addC(uint)",3));
        payable(0x272a3c19f1bA5761bCCf8AD38003d235e03e16d1).transfer(100000000);
    }

    function updateA() public {
        called.delegatecall(abi.encodeWithSignature("addA(uint256)",9));
    }

    function updateCC() public {
        k.addc(8);
    }

    function updateB() public {
        (bool success,bytes memory data) = called.call{value: 100000000}(abi.encodeWithSignature("addB(uint)",3));
    }

     receive() external payable {
        // React to receiving ether
    }
}
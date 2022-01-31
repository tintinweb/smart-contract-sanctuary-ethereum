//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    function setGreeting(bytes calldata _s, uint64 _i)
        public
        pure
        returns (uint8)
    {
        return uint8(_s[_i]);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ArrayEmitter {

    address[] public addresses = [
            0x3E22bb8B2f6e60e6fC432000B6187af34bDD4800, 
            0x5c68c7651A84719dA49a8Ab75d9f3fbe70f88c1f,
            0x9C945bCB80a7FAE9493abb98ec3e5f093144B449,
            0xb32c48A486C2300bE7a4Ca2E710d11087D7Fa17f,
            0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45,
            0xE44cff9843da14F400425d4689527980c7075089
        ];

    event UintArrayReturned(uint256[] array);
    event AddressArrayReturned(address[] array);

    function emitUint() public {
        uint256[] memory output = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            output[i] = i;
        }
        emit UintArrayReturned(output);
    }

    function emitAddress() public {
        emit AddressArrayReturned(addresses);
    }
}
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract longTransaction {
    uint[] data;

    function loop (uint limit) public returns(uint[] memory) {
        for(uint i=0; i<limit; i++){
                data.push(i);
            }
            return data;
        }
}
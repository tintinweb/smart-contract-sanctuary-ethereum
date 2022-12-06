/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface MyGo {
    function go() external;
}

contract DeployAndRun {
    function go(bytes calldata _data) external {
        bytes memory code = abi.encodePacked(
            hex"63",
            uint32(_data.length),
            hex"80_60_0E_60_00_39_60_00_F3",
            _data
        );

        address pointer;
        assembly { 
            pointer := create(0, add(code, 32), mload(code)) 
        }
        MyGo(pointer).go();
    }
}
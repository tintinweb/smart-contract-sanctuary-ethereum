/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RevertCheck {
    error revertError(uint256 code, uint256 value);

    function revertTest() public {
        revert revertError({code: 0, value: 1});
    }

    function revertStd() public {
        bytes memory revertMsg = abi.encode(1, 0);
        assembly {
            let revertMsg_size := mload(revertMsg)
            revert(add(32, revertMsg), revertMsg_size)
        }
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.7;

contract Proxy {
    fallback() external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), 0xa66Ab394D86d5b6Af4815a570513B1C813C9152c, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
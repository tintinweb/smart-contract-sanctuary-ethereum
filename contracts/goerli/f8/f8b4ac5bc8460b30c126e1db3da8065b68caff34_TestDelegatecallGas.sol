/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

contract Target {
    function doNothing() external {}
}

contract TestDelegatecallGas {
    address immutable target = address(new Target());

    constructor() {
    }

    function execute() external returns (bytes memory response) {
        bytes memory data_ = abi.encodeWithSignature("doNothing()");
        address target_ = target;
        assembly {
            let succeeded := delegatecall(gas(), target_, add(data_, 0x20), mload(data_), 0, 0)
            let size := returndatasize()

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch succeeded
            case 0 {
                revert(add(response, 0x20), size)
            }
        }
    }
}
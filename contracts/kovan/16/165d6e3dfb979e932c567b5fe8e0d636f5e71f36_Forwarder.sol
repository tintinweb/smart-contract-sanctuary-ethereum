/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
// Inspired by openzeppelin metatx/MinimalForwarder.sol

pragma solidity =0.8.7;

contract Forwarder {
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    constructor() {}

    function execute(ForwardRequest calldata req)
        public
        returns (bool, bytes memory)
    {
        (bool success, bytes memory returndata) = req.to.call{
            gas: req.gas
        }(abi.encodePacked(req.data, req.from));

        // Validate that the relayer has sent enough gas for the call.
        // if (gasleft() <= req.gas / 63) {
        //     assembly {
        //         invalid()
        //     }
        // }

        return (success, returndata);
    }
}
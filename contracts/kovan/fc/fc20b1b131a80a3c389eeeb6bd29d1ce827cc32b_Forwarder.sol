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
        address recipient;
        uint256 amount;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    constructor() {}

    function execute(ForwardRequest calldata req)
        public
        returns (bool, bytes memory)
    {
        (bool success, bytes memory returndata) = req.to.call{gas: req.gas}(
            abi.encodeWithSignature(
                "transfer(address, uint256)",
                address(req.recipient),
                uint256(req.amount)
            )
        );

        // (abi.encodePacked(req.data, req.from));

        // Validate that the relayer has sent enough gas for the call.
        // if (gasleft() <= req.gas / 63) {
        //     assembly {
        //         invalid()
        //     }
        // }

        return (success, returndata);
    }
}
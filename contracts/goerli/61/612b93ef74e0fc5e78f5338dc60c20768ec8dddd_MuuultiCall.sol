// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {IArbitrum} from "./interfaces/IArbitrum.sol";
import {IOptimism} from "./interfaces/IOptimism.sol";

contract MuuultiCall {
    enum Network {
        Arbitrum,
        Optimism
    }

    function send(
        Network[] calldata networks,
        address[] calldata targets,
        uint256[] calldata callvalues,
        bytes[] calldata data
    ) external payable {
        require(networks.length == targets.length, "unequal param lengths");
        require(networks.length == callvalues.length, "unequal param lengths");
        require(networks.length == data.length, "unequal param lengths");

        for (uint256 i; i < targets.length; i++) {
            // HACK: just hardcode goerli bridges for now
            if (networks[i] == Network.Arbitrum) {
                IArbitrum(0x6BEbC4925716945D46F0Ec336D5C2564F419682C)
                    .createRetryableTicketNoRefundAliasRewrite(
                        targets[i],
                        callvalues[i],
                        // HACK: hardcoded maxSubmissionCost
                        337270000000000,
                        // Refund excess fees & potentially reverted call value to sender
                        msg.sender,
                        msg.sender,
                        // HACK: hardcoded gasLimit & maxFeePerGas
                        125000,
                        3000000000,
                        data[i]
                    );
            } else if (networks[i] == Network.Optimism) {
                IOptimism(0x636Af16bf2f682dD3109e60102b8E1A089FedAa8)
                    .depositETHTo{value: callvalues[i]}(
                    targets[i],
                    // HACK: hardcoded gasLimit
                    125000,
                    data[i]
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IArbitrum {
    /// @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
    function createRetryableTicket(
        address to,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    /// @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
    function createRetryableTicketNoRefundAliasRewrite(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IOptimism {
    function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    ) external payable;
}
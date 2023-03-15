// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interface/IBearIpClaim.sol";

contract BearIpClaimer {
    IBearIpClaim protocol;

    constructor(address _protocol) {
        protocol = IBearIpClaim(_protocol);
    }

    function BulkWithDrawReward(bytes32[] memory boxId) public  returns (uint256 amounts) {
        if (boxId.length > 0) {
            for (uint256 i = 0; i < boxId.length; i++) {
                uint256 _amounts;
                (,,, _amounts) = protocol.withDrawReward(boxId[i]);
                amounts += _amounts;
            }
        }
    }

    function BulkClaimReward(bytes32[] memory bidId) public  returns (uint256 amounts) {
        if (bidId.length > 0) {
            for (uint256 i = 0; i < bidId.length; i++) {
                uint256 _amounts;
                (,, _amounts) = protocol.ClaimReward(bidId[i]);
                amounts += _amounts;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IBearIpClaim {
    function withDrawReward(bytes32 box_id)
        external
        payable
        returns (uint256 length, address[] memory nfts, uint256[] memory ids, uint256 amount);
    function ClaimReward(bytes32 bid_id) external payable returns (address nfts, uint256 ids, uint256 amount);
}
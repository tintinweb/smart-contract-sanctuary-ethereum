// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IFeeDistributor} from "../interfaces/IFeeDistributor.sol";

contract MultiFeeDistributor {
    function claimMany(
        uint256[] memory nftIds,
        IFeeDistributor[] memory distributors
    ) external returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](nftIds.length);

        for (uint256 index = 0; index < nftIds.length; index++) {
            ret[index] = distributors[index].claim(nftIds[index]);
        }

        return ret;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeDistributor {
    event ToggleAllowCheckpointToken(bool toggleFlag);
    event CheckpointToken(uint256 time, uint256 tokens);
    event Claimed(
        uint256 nftId,
        uint256 amount,
        uint256 claimEpoch,
        uint256 maxEpoch
    );

    function checkpointToken() external;

    function checkpointTotalSupply() external;

    function claim(uint256 nftId) external returns (uint256);

    function claimMany(uint256[] memory nftIds) external returns (bool);
}
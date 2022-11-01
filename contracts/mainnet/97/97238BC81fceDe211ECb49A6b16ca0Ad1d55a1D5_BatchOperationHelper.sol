// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "../interfaces/IVotingEscrow.sol";

interface IClaimRewards {
    function claimRewards(address account) external;

    function claimRewardsAndUnwrap(address account) external;
}

contract BatchOperationHelper {
    string public constant VERSION = "2.0.0";

    function batchClaimRewards(address[] calldata contracts, address account) public {
        uint256 count = contracts.length;
        for (uint256 i = 0; i < count; i++) {
            IClaimRewards(contracts[i]).claimRewards(account);
        }
    }

    function batchClaimRewardsAndUnwrap(
        address[] calldata contracts,
        address[] calldata wrappedContracts,
        address account
    ) external {
        batchClaimRewards(contracts, account);
        uint256 count = wrappedContracts.length;
        for (uint256 i = 0; i < count; i++) {
            IClaimRewards(wrappedContracts[i]).claimRewardsAndUnwrap(account);
        }
    }

    function batchSyncWithVotingEscrow(address[] calldata contracts, address account) external {
        uint256 count = contracts.length;
        for (uint256 i = 0; i < count; i++) {
            IVotingEscrowCallback(contracts[i]).syncWithVotingEscrow(account);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

interface IAddressWhitelist {
    function check(address account) external view returns (bool);
}

interface IVotingEscrowCallback {
    function syncWithVotingEscrow(address account) external;
}

interface IVotingEscrow {
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    function token() external view returns (address);

    function maxTime() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        returns (uint256);

    function getTimestampDropBelow(address account, uint256 threshold)
        external
        view
        returns (uint256);

    function getLockedBalance(address account) external view returns (LockedBalance memory);
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../solidity-utils/openzeppelin/IERC20.sol";

// For compatibility, we're keeping the same function names as in the original Curve code, including the mixed-case
// naming convention.
// solhint-disable func-name-mixedcase, var-name-mixedcase

interface IRewardTokenDistributor {
    struct Reward {
        IERC20 token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    function reward_tokens(uint256 index) external view returns (IERC20);

    function reward_data(IERC20 token) external view returns (Reward memory);

    function claim_rewards(address user) external;

    function add_reward(IERC20 rewardToken, address distributor) external;

    function set_reward_distributor(IERC20 rewardToken, address distributor) external;

    function deposit_reward_token(IERC20 rewardToken, uint256 amount) external;

    function claimable_reward(address rewardToken, address user) external view returns (uint256);

    function claimable_reward_write(address rewardToken, address user) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

// For compatibility, we're keeping the same function names as in the original Curve code, including the mixed-case
// naming convention.
// solhint-disable func-name-mixedcase

interface IChildChainStreamer {
    function initialize(address gauge) external;

    function get_reward() external;

    function reward_tokens(uint256 index) external view returns (IERC20);

    function add_reward(
        IERC20 rewardToken,
        address distributor,
        uint256 duration
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "./IChildChainStreamer.sol";
import "./IRewardTokenDistributor.sol";

// For compatibility, we're keeping the same function names as in the original Curve code, including the mixed-case
// naming convention.
// solhint-disable func-name-mixedcase

interface IRewardsOnlyGauge is IRewardTokenDistributor {
    function initialize(
        address pool,
        address streamer,
        bytes32 claimSignature
    ) external;

    // solhint-disable-next-line func-name-mixedcase
    function lp_token() external view returns (IERC20);

    function reward_contract() external view returns (IChildChainStreamer);

    function set_rewards(
        address childChainStreamer,
        bytes32 claimSig,
        address[8] calldata rewardTokens
    ) external;

    function last_claim() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/liquidity-mining/IRewardsOnlyGauge.sol";
import "@balancer-labs/v2-interfaces/contracts/liquidity-mining/IChildChainStreamer.sol";

/**
 * @title ChildChainGaugeRewardHelper
 * @author Balancer Labs
 * @notice Helper contract which allows claiming rewards from many RewardsOnlyGauges in a single transaction.
 * This contract manually triggers an update to the gauges' streamers as a workaround for the gauge .
 */
contract ChildChainGaugeRewardHelper {
    uint256 public constant CLAIM_FREQUENCY = 3600;

    /**
     * @notice Returns the amount of ERC20 token `token` on RewardsOnlyGauge `gauge` claimable by address `user`.
     * @dev This function cannot be marked `view` as it updates the gauge's state (not possible in a view context).
     * Offchain users attempting to read from this function should manually perform a static call or modify the abi.
     * @param gauge - The address of the RewardsOnlyGauge for which to query.
     * @param user - The address of the user for which to query.
     * @param token - The address of the reward token for which to query.
     */
    function getPendingRewards(
        IRewardsOnlyGauge gauge,
        address user,
        address token
    ) external returns (uint256) {
        gauge.reward_contract().get_reward();
        return gauge.claimable_reward_write(user, token);
    }

    /**
     * @notice Claims pending rewards on RewardsOnlyGauge `gauge` for account `user`.
     * @param gauge - The address of the RewardsOnlyGauge from which to claim rewards.
     * @param user - The address of the user for which to claim rewards.
     */
    function claimRewardsFromGauge(IRewardsOnlyGauge gauge, address user) external {
        _claimRewardsFromGauge(gauge, user);
    }

    /**
     * @notice Claims pending rewards on a list of RewardsOnlyGauges `gauges` for account `user`.
     * @param gauges - An array of address of RewardsOnlyGauges from which to claim rewards.
     * @param user - The address of the user for which to claim rewards.
     */
    function claimRewardsFromGauges(IRewardsOnlyGauge[] calldata gauges, address user) external {
        for (uint256 i = 0; i < gauges.length; i++) {
            _claimRewardsFromGauge(gauges[i], user);
        }
    }

    // Internal functions

    function _claimRewardsFromGauge(IRewardsOnlyGauge gauge, address user) internal {
        // Force rewards from the streamer onto the gauge.
        gauge.reward_contract().get_reward();
        gauge.claim_rewards(user);
    }
}
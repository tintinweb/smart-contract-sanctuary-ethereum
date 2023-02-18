/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * SPDX-License-Identifier: MIT
 * https://github.com/OriginProtocol/nft-launchpad
 *
 * Copyright 2022 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.4;

import {AddressUpgradeable as Address} from '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {IERC20Upgradeable as IERC20} from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

import {Governable} from '../governance/Governable.sol';
import {IFeeVault} from './FeeVault.sol';
import {ISeason} from './ISeason.sol';

interface ISeries {
    function ogn() external view returns (address);

    function vault() external view returns (address);

    function currentClaimingIndex() external view returns (uint256);

    function currentStakingIndex() external view returns (uint256);

    function liveSeason() external view returns (uint256);

    function expectedClaimingSeason() external view returns (address);

    function expectedStakingSeason() external view returns (address);

    function latestStakeTime(address userAddress)
        external
        view
        returns (uint256);

    function balanceOf(address userAddress) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claim() external returns (uint256, uint256);

    function stake(uint256 amount) external returns (uint256, uint256);

    function unstake() external returns (uint256);

    function popSeason() external;

    function pushSeason(address season) external;

    function bootstrapSeason(uint256 seasonIndex, uint256 totalStaked) external;
}

/**
 * @title Story Series staking contract
 * @notice Primary interaction OGN staking contract for Story profit sharing
 *      and rewards.
 */
contract Series is Initializable, Governable, ISeries {
    address public override vault;
    address public override ogn;

    address[] public seasons;
    uint256 public override currentStakingIndex;
    uint256 public override currentClaimingIndex;
    uint256 private totalStakedOGN;

    mapping(address => uint256) private stakedOGN;
    mapping(address => uint256) private userLastStakingTime;

    /**
     * @dev A new season has been registered
     * @param number - The season ID (1-indexed)
     * @param season - The address of the new season
     */
    event NewSeason(uint256 indexed number, address indexed season);

    /**
     * @dev A season has started
     * @param number - The season ID (1-indexed)
     * @param season - The address of the new season
     */
    event SeasonStart(uint256 indexed number, address indexed season);

    /**
     * @dev A season has been cancelled and removed
     * @param season - The address of the new season
     */
    event SeasonCancelled(address indexed season);

    // @dev only execute if there's an active season set
    modifier requireActiveSeason() {
        require(seasons.length > 0, 'Series: No active season');
        _;
    }

    /**
     * @param ogn_ - Address for the OGN token
     * @param vault_ - Address for the FeeVault
     */
    function initialize(address ogn_, address vault_) external initializer {
        require(ogn_ != address(0), 'Series: Zero address: OGN');
        require(vault_ != address(0), 'Series: Zero address: Vault');
        ogn = ogn_;
        vault = vault_;
    }

    ///
    /// Externals
    ///

    /**
     * @notice The current "live" season (earliest non-ended season)
     * @return index of the live season
     */
    function liveSeason() external view override returns (uint256) {
        if (seasons.length <= 1) {
            return 0;
        }

        for (uint256 i = seasons.length; i > 0; i--) {
            uint256 idx = i - 1;

            if (block.timestamp >= ISeason(seasons[idx]).startTime()) {
                return idx;
            }
        }

        return currentStakingIndex;
    }

    /**
     * @notice The staking season, should stake() be called.  This takes into
     * account currentStakingIndex potentially advancing.
     * @return address of the expected claiming season
     */
    function expectedStakingSeason() external view override returns (address) {
        if (seasons.length < 1) {
            return address(0);
        }

        ISeason season = ISeason(seasons[currentStakingIndex]);

        if (
            block.timestamp >= season.lockStartTime() &&
            seasons.length > currentStakingIndex + 1
        ) {
            return seasons[currentStakingIndex + 1];
        }

        return seasons[currentStakingIndex];
    }

    /**
     * @notice The claiming season, should claim/unstake be called.  This
     * takes into account currentClaimingIndex potentially advancing.
     * @return address of the expected claiming season
     */
    function expectedClaimingSeason() external view override returns (address) {
        if (seasons.length < 1) {
            return address(0);
        }

        ISeason season = ISeason(seasons[currentClaimingIndex]);

        if (
            block.timestamp >= season.claimEndTime() &&
            seasons.length > currentClaimingIndex + 1
        ) {
            return seasons[currentClaimingIndex + 1];
        }

        return seasons[currentClaimingIndex];
    }

    /**
     * @notice Get the latest stake block timestamp for a user
     * @param userAddress - address for which to return their last stake time
     * @return timestamp for last stake time for a user (or 0 if none)
     */
    function latestStakeTime(address userAddress)
        external
        view
        override
        returns (uint256)
    {
        return userLastStakingTime[userAddress];
    }

    /**
     * @notice Total staked OGN for a user
     * @param userAddress - address for which to return their points
     * @return total OGN staked
     */
    function balanceOf(address userAddress)
        external
        view
        override
        returns (uint256)
    {
        return stakedOGN[userAddress];
    }

    /**
     * @notice Total staked OGN of all users
     * @return total OGN staked from all users
     */
    function totalSupply() external view override returns (uint256) {
        return totalStakedOGN;
    }

    /**
     * @notice Set the address for the OGN token.
     * @dev other contracts reference this value as well
     * @param ogn_ - address for the contract
     */
    function setOGN(address ogn_) external onlyGovernor {
        require(ogn_ != address(0), 'Series: Zero address: OGN');
        ogn = ogn_;
    }

    /**
     * @notice Set the address for the FeeVault.
     * @dev other contracts reference this value as well
     * @param vault_ - address for the contract
     */
    function setVault(address vault_) external onlyGovernor {
        require(vault_ != address(0), 'Series: Zero address: FeeVault');
        vault = vault_;
    }

    /**
     * @notice Stake OGN for fee sharing and rewards. Users can call this
     *      multiple times to add to their stake. This contract must be
     *      approved to transfer the given amount of OGN from the user.
     *
     * @param amount - The amount of OGN to stake
     * @return total amount of OGN staked by the user
     * @return total points received for the user's entire stake for the
     *      staking season
     */
    function stake(uint256 amount)
        external
        override
        requireActiveSeason
        returns (uint256, uint256)
    {
        require(amount > 0, 'Series: No stake amount');

        uint128 stakePoints;
        address userAddress = msg.sender;
        IERC20 token = IERC20(ogn);
        ISeason season = _acquireStakingSeason();

        // Transfer OGN to Series
        require(
            token.transferFrom(userAddress, address(this), amount),
            'Series: OGN transfer failed'
        );

        // Record stake for the user and get their points total for return
        stakePoints = season.stake(userAddress, amount);

        // Update balances. This must occur after the stake() call to allow
        // for clean rollover.  Otherwise, this new balance could be
        // considered historical and used as rollover on top of new amount.
        stakedOGN[userAddress] += amount;
        totalStakedOGN += amount;
        userLastStakingTime[userAddress] = block.timestamp;

        return (stakedOGN[userAddress], stakePoints);
    }

    /**
     * @notice Unstake previously staked OGN. This will unstake their full
     *      OGN stake amount and pay out any rewards (if within a claim period)
     *
     * @return amount of OGN unstaked
     */
    function unstake() external override requireActiveSeason returns (uint256) {
        address userAddress = msg.sender;
        uint256 amount = stakedOGN[userAddress];
        ISeason claimSeason = _acquireClaimingSeason();

        (uint256 rewardETH, uint256 rewardOGN) = claimSeason.unstake(
            userAddress
        );

        // Make sure to unstake from staking season as well to zero-out user
        if (currentClaimingIndex < currentStakingIndex) {
            ISeason stakeSeason = ISeason(seasons[currentStakingIndex]);
            // Ignored return val because there can't be multiple seasons in
            // claim period at one time.  This should return (0,0).
            stakeSeason.unstake(userAddress);
        }

        // Balance updates need to happen after unstake() calls to allow
        // rollover calculation to get a user's stake balance.
        stakedOGN[userAddress] = 0;
        totalStakedOGN -= amount;

        // Send rewards to user (if any)
        _transferRewards(userAddress, rewardETH, rewardOGN);

        // Send staked OGN back to user
        require(
            IERC20(ogn).transfer(userAddress, amount),
            'Series: OGN transfer failed'
        );

        return amount;
    }

    /**
     * @notice Claim profit share and OGN rewards.
     *
     * @return claimedETH - amount of ETH profit share claimed
     * @return claimedOGN - amount of OGN rewards claimed
     */
    function claim()
        external
        override
        requireActiveSeason
        returns (uint256, uint256)
    {
        address userAddress = msg.sender;
        ISeason season = _acquireClaimingSeason();

        (uint256 rewardETH, uint256 rewardOGN) = season.claim(userAddress);

        _transferRewards(userAddress, rewardETH, rewardOGN);

        return (rewardETH, rewardOGN);
    }

    /**
     * @notice Add a new season.  It will be the last season in the sequence.
     *
     * @param season - address for the new season
     */
    function pushSeason(address season) external override onlyGovernor {
        require(Address.isContract(season), 'Series: Season not a contract');

        ISeason newSeason = ISeason(season);

        // If we have seasons to compare, do some sanity checks
        if (seasons.length > 0) {
            ISeason prevSeason = ISeason(seasons[seasons.length - 1]);

            // End time must be after claim period to prevent overlap of claim
            // periods
            require(
                newSeason.endTime() > prevSeason.claimEndTime(),
                'Series: Invalid end time'
            );

            // It's critical the start time begins after the previous season's
            // lock start time to avoid advancing early into the staking slot.
            // Since its end time is after the lock start time and seasons
            // probably shouldn't overlap for clarity sake, we check against
            // end time.
            require(
                newSeason.startTime() >= prevSeason.endTime(),
                'Series: Invalid start time'
            );
        }

        seasons.push(season);

        emit NewSeason(seasons.length - 1, season);

        if (seasons.length == 1) {
            ISeason(season).bootstrap(totalStakedOGN);
            emit SeasonStart(0, season);
        }
    }

    /**
     * @notice Remove the final scheduled season if it is not an active
     *      staking season.
     */
    function popSeason() external override onlyGovernor {
        require(seasons.length > 0, 'Series: No seasons to cancel');
        require(
            currentStakingIndex < seasons.length - 1,
            'Series: Season is active'
        );

        address cancelled = seasons[seasons.length - 1];

        // Remove the last element
        seasons.pop();

        emit SeasonCancelled(cancelled);
    }

    /**
     * @notice Manually bootstrap a season.  This should only be used in the
     *      rare case a season receives no new stakes, so was never
     *      bootstraped.
     * @param totalStaked - The amount of totalStakedOGN to send to
     *      Season.bootstrap()
     */
    function bootstrapSeason(uint256 seasonIndex, uint256 totalStaked)
        external
        override
        onlyGovernor
    {
        require(seasonIndex < seasons.length, 'Series: Season does not exist');

        ISeason season = ISeason(seasons[seasonIndex]);

        require(
            block.timestamp >= season.lockStartTime(),
            'Series: Not locked'
        );

        season.bootstrap(totalStaked);
    }

    ///
    /// Internals
    ///

    /**
     * @dev Return the season to use for staking, advancing if necessary
     * @return staking season
     */
    function _acquireStakingSeason() internal returns (ISeason) {
        ISeason season = ISeason(seasons[currentStakingIndex]);

        // Locked seasons can accept stakes but will not award points,
        // therefore the staker will receive no rewards.  If we have another
        // Season available for (pre)staking, advance the index and use that
        // for staking operations.
        if (
            block.timestamp >= season.lockStartTime() &&
            seasons.length > currentStakingIndex + 1
        ) {
            currentStakingIndex += 1;
            season = ISeason(seasons[currentStakingIndex]);
            season.bootstrap(totalStakedOGN);
            emit SeasonStart(currentStakingIndex, seasons[currentStakingIndex]);
        }

        return season;
    }

    /**
     * @dev Return the season to use for claiming, advancing if necessary
     * @return claiming season
     */
    function _acquireClaimingSeason() internal returns (ISeason) {
        ISeason season = ISeason(seasons[currentClaimingIndex]);

        // If the claim period has ended, advance to the next season, if
        // available.
        if (
            block.timestamp >= season.claimEndTime() &&
            seasons.length > currentClaimingIndex + 1
        ) {
            currentClaimingIndex += 1;
            season = ISeason(seasons[currentClaimingIndex]);
        }

        return season;
    }

    /**
     * @dev Transfer the given ETH and OGN to the given user from the vault
     * @param userAddress - Recipient of the rewards
     * @param rewardETH - Amount of ETH to transfer
     * @param rewardOGN - Amount of OGN to transfer
     */
    function _transferRewards(
        address userAddress,
        uint256 rewardETH,
        uint256 rewardOGN
    ) internal {
        IFeeVault rewards = IFeeVault(vault);

        if (rewardETH > 0) {
            rewards.sendETHRewards(userAddress, rewardETH);
        }

        if (rewardOGN > 0) {
            rewards.sendTokenRewards(ogn, userAddress, rewardOGN);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OUSD Governable Contract
 * @dev Copy of the openzeppelin Ownable.sol contract with nomenclature change
 *      from owner to governor and renounce methods removed. Does not use
 *      Context.sol like Ownable.sol does for simplification.
 * @author Origin Protocol Inc
 */
abstract contract Governable {
    // Storage position of the owner and pendingOwner of the contract
    // keccak256("OUSD.governor");
    bytes32 private constant governorPosition =
        0x7bea13895fa79d2831e0a9e28edede30099005a50d652d8957cf8a607ee6ca4a;

    // keccak256("OUSD.pending.governor");
    bytes32 private constant pendingGovernorPosition =
        0x44c4d30b2eaad5130ad70c3ba6972730566f3e6359ab83e800d905c61b1c51db;

    // keccak256("OUSD.reentry.status");
    bytes32 private constant reentryStatusPosition =
        0x53bf423e48ed90e97d02ab0ebab13b2a235a6bfbe9c321847d5c175333ac4535;

    // See OpenZeppelin ReentrancyGuard implementation
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    event PendingGovernorshipTransfer(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    event GovernorshipTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial Governor.
     */
    constructor() {
        _setGovernor(msg.sender);
        emit GovernorshipTransferred(address(0), _governor());
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function governor() public view returns (address) {
        return _governor();
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function _governor() internal view returns (address governorOut) {
        bytes32 position = governorPosition;
        assembly {
            governorOut := sload(position)
        }
    }

    /**
     * @dev Returns the address of the pending Governor.
     */
    function _pendingGovernor()
        internal
        view
        returns (address pendingGovernor)
    {
        bytes32 position = pendingGovernorPosition;
        assembly {
            pendingGovernor := sload(position)
        }
    }

    /**
     * @dev Throws if called by any account other than the Governor.
     */
    modifier onlyGovernor() {
        require(isGovernor(), "Caller is not the Governor");
        _;
    }

    /**
     * @dev Returns true if the caller is the current Governor.
     */
    function isGovernor() public view returns (bool) {
        return msg.sender == _governor();
    }

    function _setGovernor(address newGovernor) internal {
        bytes32 position = governorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        bytes32 position = reentryStatusPosition;
        uint256 _reentry_status;
        assembly {
            _reentry_status := sload(position)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_reentry_status != _ENTERED, "Reentrant call");

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(position, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(position, _NOT_ENTERED)
        }
    }

    function _setPendingGovernor(address newGovernor) internal {
        bytes32 position = pendingGovernorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Transfers Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the current Governor. Must be claimed for this to complete
     * @param _newGovernor Address of the new Governor
     */
    function transferGovernance(address _newGovernor) external onlyGovernor {
        _setPendingGovernor(_newGovernor);
        emit PendingGovernorshipTransfer(_governor(), _newGovernor);
    }

    /**
     * @dev Claim Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the new Governor.
     */
    function claimGovernance() external {
        require(
            msg.sender == _pendingGovernor(),
            "Only the pending Governor can complete the claim"
        );
        _changeGovernor(msg.sender);
    }

    /**
     * @dev Change Governance of the contract to a new account (`newGovernor`).
     * @param _newGovernor Address of the new Governor
     */
    function _changeGovernor(address _newGovernor) internal {
        require(_newGovernor != address(0), "New Governor is address(0)");
        emit GovernorshipTransferred(_governor(), _newGovernor);
        _setGovernor(_newGovernor);
    }
}

/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * SPDX-License-Identifier: MIT
 * https://github.com/OriginProtocol/nft-launchpad
 *
 * Copyright 2022 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.4;

import {IERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

import {Governable} from '../governance/Governable.sol';

interface IFeeVault {
    function controller() external view returns (address);

    function pause() external;

    function unpause() external;

    function sendETHRewards(address userAddress, uint256 amount)
        external
        returns (bool);

    function sendTokenRewards(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) external returns (bool);

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount,
        address toAddress
    ) external returns (bool);

    function setController(address controllerAddress) external;
}

/**
 * @title Story FeeVault contract
 * @notice Contract to collect NFT sales profits and rewards to be distributed
 *      to OGN stakers.
 */
contract FeeVault is Initializable, Governable, PausableUpgradeable, IFeeVault {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public override controller;

    address private constant ASSET_ETH =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // @dev Rewards have been sent to the season
    event RewardsSent(
        address indexed asset,
        address indexed toAddress,
        uint256 amount
    );

    // @dev A new controller has been set
    event NewController(address controllerAddress);

    modifier onlyController() {
        require(_msgSender() == controller, 'FeeVault: Sender not controller');
        _;
    }

    /**
     * @param controllerAddress - Address for the account that will receive the
     *      rewards
     */
    function initialize(address controllerAddress) external initializer {
        __Pausable_init();
        // controller will probably be zero on initial deploy
        controller = controllerAddress;
    }

    ///
    /// Externals
    ///

    /**
     * @dev Send ETH rewards to a user. Can only be called by controller.
     * @param userAddress - address of the recipient of the ETH
     * @param amount - amount of ETH (in wei)
     */
    function sendETHRewards(address userAddress, uint256 amount)
        external
        override
        whenNotPaused
        onlyController
        returns (bool)
    {
        require(userAddress != address(0), 'FeeVault: ETH to black hole');
        require(amount > 0, 'FeeVault: Attempt to send 0 ETH');

        emit RewardsSent(ASSET_ETH, userAddress, amount);

        // transfer() does not send enough gas for a delegate call to an
        // empty receive() function.
        (bool success, ) = userAddress.call{value: amount, gas: 2800}('');

        // To align behavior with sendTokenRewards
        require(success, 'FeeVault: ETH transfer failed');

        return success;
    }

    /**
     * @dev Send token rewards to a user. Can only be called by controller.
     * @param tokenAddress - address of the token to send
     * @param userAddress - address of the recipient of the tokens
     * @param amount - amount of the token to send
     */
    function sendTokenRewards(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) external override whenNotPaused onlyController returns (bool) {
        require(userAddress != address(0), 'FeeVault: Token to black hole');
        require(amount > 0, 'FeeVault: Attempt to send 0');

        emit RewardsSent(tokenAddress, userAddress, amount);

        return _sendTokens(tokenAddress, userAddress, amount);
    }

    /**
     * @notice Recover ERC20 tokens sent to contract.  This can only be called
     *      by the governor.
     * @param tokenAddress - address of the token to recover
     * @param tokenAmount - amount of the token to recover
     * @param toAddress - address of the recipient of the tokens
     */
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount,
        address toAddress
    ) external override onlyGovernor whenNotPaused returns (bool) {
        return _sendTokens(tokenAddress, toAddress, tokenAmount);
    }

    /**
     * @notice Set series address
     */
    function setController(address controllerAddress)
        external
        override
        onlyGovernor
    {
        emit NewController(controllerAddress);
        controller = controllerAddress;
    }

    /**
     * @notice Pause all funds movement functionality
     */
    function pause() external override onlyGovernor {
        _pause();
    }

    /**
     * @notice Pause all funds movement functionality
     */
    function unpause() external override onlyGovernor {
        _unpause();
    }

    // @dev Allow this contract to receive ETH
    receive() external payable {}

    ///
    /// Internals
    ///

    function _sendTokens(
        address tokenAddress,
        address toAddress,
        uint256 amount
    ) internal returns (bool) {
        IERC20Upgradeable(tokenAddress).safeTransfer(toAddress, amount);
        return true;
    }
}

/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * SPDX-License-Identifier: MIT
 * https://github.com/OriginProtocol/nft-launchpad
 *
 * Copyright 2022 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.4;

interface ISeason {
    function claimEndTime() external view returns (uint256);

    function lockStartTime() external view returns (uint256);

    function endTime() external view returns (uint256);

    function startTime() external view returns (uint256);

    function getTotalPoints() external view returns (uint128);

    function getPoints(address userAddress) external view returns (uint128);

    function expectedRewards(address userAddress)
        external
        view
        returns (uint256, uint256);

    function pointsInTime(uint256 amount, uint256 blockStamp)
        external
        view
        returns (uint128);

    function claim(address userAddress) external returns (uint256, uint256);

    function stake(address userAddress, uint256 amount)
        external
        returns (uint128);

    function unstake(address userAddress) external returns (uint256, uint256);

    function bootstrap(uint256 initialSupply) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./external/spool-core/SpoolOwnable.sol";
import "./interfaces/IVoSpoolRewards.sol";

import "./interfaces/IVoSPOOL.sol";

/* ========== STRUCTS ========== */

/**
 * @notice Defines amount of emitted rewards per tranche for a range of tranches
 * @member fromTranche marks first tranche the reward rate is valid for
 * @member toTranche marks tranche index when the reward becomes invalid (when `toTranche` is reached, the configuration is no more valid)
 * @member rewardPerTranche amount of emitted rewards per tranche
 */
struct VoSpoolRewardRate {
	uint8 fromTranche;
	uint8 toTranche;
	uint112 rewardPerTranche; // rewards per tranche
}

/**
 * @notice struct solding two VoSpoolRewardRate structs
 * @dev made to pack multiple structs in one word
 * @member zero VoSpoolRewardRate at position 0
 * @member one VoSpoolRewardRate at position 1
 */
struct VoSpoolRewardRates {
	VoSpoolRewardRate zero;
	VoSpoolRewardRate one;
}

/**
 * @notice voSPOOL reward state for user
 * @member lastRewardRateIndex last reward rate index user has used (refers to VoSpoolRewardConfiguration.voSpoolRewardRates mapping and VoSpoolRewardRates index)
 * @member earned total rewards user has accumulated
 */
struct VoSpoolRewardUser {
	uint8 lastRewardRateIndex;
	uint248 earned;
}

/**
 * @notice voSPOOL reward configuration
 * @member rewardRatesIndex last set reward rate index for voSpoolRewardRates mapping (acts similar to an array length parameter)
 * @member hasRewards flag marking if the contract is emitting rewards for new tranches
 * @member lastSetRewardTranche last reward tranche index we've set the congiguration for
 */
struct VoSpoolRewardConfiguration {
	uint240 rewardRatesIndex;
	bool hasRewards;
	uint8 lastSetRewardTranche;
}

/**
 * @notice Implementation of the {IVoSpoolRewards} interface.
 *
 * @dev
 * This contract implements the logic to calculate and distribute
 * SPOOL token rewards to according to users gradual voSPOOL balance.
 * Spool DAO Voting Token (voSPOOL) is an inflationary token as it
 * increases power over the period of 3 years.
 *
 * This contract assumes only SPOOL Staking is updating gradual mint, as
 * well as that the voSPOOL state has not been updated prior calling
 * the updateRewards function.
 *
 * Only Spool DAO can add, update and end rewards.
 * Only SPOOL Staking contract can update this contract.
 */
contract VoSpoolRewards is SpoolOwnable, IVoSpoolRewards {
	/* ========== CONSTANTS ========== */

	/// @notice amount of tranches to mature to full power
	uint256 private constant FULL_POWER_TRANCHES_COUNT = 52 * 3;

	/// @notice number of tranche amounts stored in one 256bit word
	uint256 private constant TRANCHES_PER_WORD = 5;

	/* ========== STATE VARIABLES ========== */

	/// @notice Spool staking contract
	/// @dev Controller of this contract
	address public immutable spoolStaking;

	/// @notice Spool DAO Voting Token (voSPOOL) implementation
	IVoSPOOL public immutable voSpool;

	/// @notice Vault reward token incentive configuration
	VoSpoolRewardConfiguration public voSpoolRewardConfig;

	/// @notice Reward of SPOOL token distribution per tranche
	/// @dev We save all reward updates so we can apply it to a user even if the configuration changes after
	mapping(uint256 => VoSpoolRewardRates) public voSpoolRewardRates;

	/// @notice Stores values for user rewards
	mapping(address => VoSpoolRewardUser) public userRewards;

	/// @notice Stores values for global gradual voSPOOL power for every tranche
	/// @dev Only stores if the reward is active. We store 5 values per word.
	mapping(uint256 => uint256) private _tranchePowers;

	/* ========== CONSTRUCTOR ========== */

	/**
	 * @notice Sets the immutable values
	 *
	 * @param _spoolStaking Spool staking contract
	 * @param _voSpool voSPOOL contract
	 * @param _spoolOwner Spool DAO owner contract
	 */
	constructor(
		address _spoolStaking,
		IVoSPOOL _voSpool,
		ISpoolOwner _spoolOwner
	) SpoolOwnable(_spoolOwner) {
		spoolStaking = _spoolStaking;
		voSpool = _voSpool;
	}

	/* ========== REWARD CONFIGURATION ========== */

	/**
	 * @notice Update SPOOL rewards distributed relative to voSPOOL power
	 * @dev We distribute `rewardPerTranche` rewards every tranche up to `toTranche` index
	 *
	 * Requirements:
	 *
	 * - the caller must be the Spool DAO
	 * - reward per tranche must be more than 0
	 * - last reward shouldn't be set after first gradual power starts maturing
	 * - reward must be set for the future tranches
	 *
	 * @param toTranche update to `toTranche` index
	 * @param rewardPerTranche amount of SPOOL token rewards distributed every tranche
	 */
	function updateVoSpoolRewardRate(uint8 toTranche, uint112 rewardPerTranche) external onlyOwner {
		require(rewardPerTranche > 0, "VoSpoolRewards::updateVoSpoolRewardRate: Cannot update reward rate to 0");
		// cannot add rewards after first tranche is fully-matured (3 years)
		require(
			toTranche <= FULL_POWER_TRANCHES_COUNT,
			"VoSpoolRewards::updateVoSpoolRewardRate: Cannot set rewards after power starts maturing"
		);

		uint8 currentTrancheIndex = uint8(voSpool.getCurrentTrancheIndex());
		require(
			toTranche > currentTrancheIndex,
			"VoSpoolRewards::updateVoSpoolRewardRate: Cannot set rewards for finished tranches"
		);

		uint256 rewardRatesIndex = voSpoolRewardConfig.rewardRatesIndex;

		VoSpoolRewardRate memory voSpoolRewardRate = VoSpoolRewardRate(
			currentTrancheIndex,
			toTranche,
			rewardPerTranche
		);

		if (rewardRatesIndex == 0) {
			voSpoolRewardRates[0].one = voSpoolRewardRate;
			rewardRatesIndex = 1;
		} else {
			VoSpoolRewardRate storage previousRewardRate = _getRewardRate(rewardRatesIndex);

			// update previous reward rate if still active to end at current index
			if (previousRewardRate.toTranche > currentTrancheIndex) {
				// if current rewards did not start yet, overwrite them and return
				if (previousRewardRate.fromTranche == currentTrancheIndex) {
					_setRewardRate(voSpoolRewardRate, rewardRatesIndex);
					voSpoolRewardConfig = VoSpoolRewardConfiguration(uint240(rewardRatesIndex), true, toTranche);
					return;
				}

				previousRewardRate.toTranche = currentTrancheIndex;
			}

			unchecked {
				rewardRatesIndex++;
			}

			// set the new reward rate
			_setRewardRate(voSpoolRewardRate, rewardRatesIndex);
		}

		// store update to reward configuration
		voSpoolRewardConfig = VoSpoolRewardConfiguration(uint240(rewardRatesIndex), true, toTranche);

		emit RewardRateUpdated(
			voSpoolRewardRate.fromTranche,
			voSpoolRewardRate.toTranche,
			voSpoolRewardRate.rewardPerTranche
		);
	}

	/**
	 * @notice End SPOOL rewards at current index
	 * @dev
	 *
	 * Requirements:
	 *
	 * - the caller must be the Spool DAO
	 * - reward must be active
	 */
	function endVoSpoolReward() external onlyOwner {
		uint8 currentTrancheIndex = uint8(voSpool.getCurrentTrancheIndex());
		uint256 rewardRatesIndex = voSpoolRewardConfig.rewardRatesIndex;

		require(rewardRatesIndex > 0, "VoSpoolRewards::endVoSpoolReward: No rewards configured");

		VoSpoolRewardRate storage currentRewardRate = _getRewardRate(rewardRatesIndex);

		require(
			currentRewardRate.toTranche > currentTrancheIndex,
			"VoSpoolRewards::endVoSpoolReward: Rewards already ended"
		);

		emit RewardEnded(
			rewardRatesIndex,
			currentRewardRate.fromTranche,
			currentRewardRate.toTranche,
			currentTrancheIndex
		);

		// if current rewards did not start yet, remove them
		if (currentRewardRate.fromTranche == currentTrancheIndex) {
			_resetRewardRate(rewardRatesIndex);
			unchecked {
				rewardRatesIndex--;
			}

			if (rewardRatesIndex == 0) {
				voSpoolRewardConfig = VoSpoolRewardConfiguration(0, false, 0);
				return;
			}
		} else {
			currentRewardRate.toTranche = currentTrancheIndex;
		}

		voSpoolRewardConfig = VoSpoolRewardConfiguration(uint240(rewardRatesIndex), false, currentTrancheIndex);
	}

	/* ========== REWARD UPDATES ========== */

	/**
	 * @notice Return user rewards earned value and reset it to 0.
	 * @dev
	 * The rewards are then processed by the Spool staking contract.
	 *
	 * Requirements:
	 *
	 * - the caller must be the Spool staking contract
	 *
	 * @param user User to flush
	 */
	function flushRewards(address user) external override onlySpoolStaking returns (uint256) {
		uint256 userEarned = userRewards[user].earned;
		if (userEarned > 0) {
			userRewards[user].earned = 0;
		}

		return userEarned;
	}

	/**
	 * @notice Update rewards for a user.
	 * @dev
	 * This has to be called before we update the gradual power storage in
	 * the voSPOOL contract for the contract to work as indended.
	 * We update the global values if new indexes have passed between our last call.
	 *
	 * Requirements:
	 *
	 * - the caller must be the Spool staking contract
	 *
	 * @param user User to update
	 */
	function updateRewards(address user) external override onlySpoolStaking returns (uint256) {
		if (voSpoolRewardConfig.rewardRatesIndex == 0) return 0;

		// if rewards are not active do not the gradual amounts
		if (voSpoolRewardConfig.hasRewards) {
			_storeVoSpoolForNewIndexes();
		}

		_updateUserVoSpoolRewards(user);

		return userRewards[user].earned;
	}

	/**
	 * @notice Store total gradual voSPOOL amount for every new tranche index since last call.
	 * @dev
	 * This function assumes that the voSPOOL state has not been
	 * updated prior to calling this function.
	 *
	 * We retrieve the not updated state from voSPOOL contract, simulate
	 * gradual increase of shares for every new tranche and store the
	 * value for later use.
	 */
	function _storeVoSpoolForNewIndexes() private {
		// check if there are any active rewards
		uint256 lastFinishedTrancheIndex = voSpool.getLastFinishedTrancheIndex();
		GlobalGradual memory global = voSpool.getNotUpdatedGlobalGradual();

		// return if no new indexes passed
		if (global.lastUpdatedTrancheIndex >= lastFinishedTrancheIndex) {
			return;
		}

		uint256 lastSetRewardTranche = voSpoolRewardConfig.lastSetRewardTranche;
		uint256 trancheIndex = global.lastUpdatedTrancheIndex;
		do {
			// if there are no more rewards return as we don't need to store anything
			if (trancheIndex >= lastSetRewardTranche) {
				// update config hasRewards to false if rewards are not active
				voSpoolRewardConfig.hasRewards = false;
				return;
			}

			trancheIndex++;

			global.totalRawUnmaturedVotingPower += global.totalMaturingAmount;

			// store gradual power for `trancheIndex` to `_tranchePowers`
			_storeTranchePowerForIndex(
				_getMaturingVotingPowerFromRaw(global.totalRawUnmaturedVotingPower),
				trancheIndex
			);
		} while (trancheIndex < lastFinishedTrancheIndex);
	}

	/**
	 * @notice Update user reward earnings for every new tranche index since the last update
	 * @dev
	 * This function assumes that the voSPOOL state has not been
	 * updated prior to calling this function.
	 *
	 * _storeVoSpoolForNewIndexes function should be called before
	 * to store the global state.
	 *
	 * We use very similar techniques as voSPOOL to calculate
	 * user gradual voting power for every index
	 */
	function _updateUserVoSpoolRewards(address user) private {
		UserGradual memory userGradual = voSpool.getNotUpdatedUserGradual(user);
		if (userGradual.maturingAmount == 0) {
			userRewards[user].lastRewardRateIndex = uint8(voSpoolRewardConfig.rewardRatesIndex);
			return;
		}

		uint256 lastFinishedTrancheIndex = voSpool.getLastFinishedTrancheIndex();
		uint256 trancheIndex = userGradual.lastUpdatedTrancheIndex;

		// update user if tranche indexes have passed since last user update
		if (trancheIndex < lastFinishedTrancheIndex) {
			VoSpoolRewardUser memory voSpoolRewardUser = userRewards[user];

			// map the configured reward rates since last time we used it
			VoSpoolRewardRate[] memory voSpoolRewardRatesArray = _getRewardRatesForIndex(
				voSpoolRewardUser.lastRewardRateIndex
			);

			// `voSpoolRewardRatesArray` array index we're currently using
			// to retrieve the reward rate belonging to `trancheIndex`
			// when we reach `rewardRate.toTranche`, we increment `vsrrI`,
			// and use the updated reward rate to store the reward for
			// the corresponding index.
			uint256 vsrrI = 0;
			VoSpoolRewardRate memory rewardRate = voSpoolRewardRatesArray[0];

			do {
				unchecked {
					trancheIndex++;
				}

				// if current reward rate is not valid anymore try getting the next one
				if (trancheIndex >= rewardRate.toTranche) {
					unchecked {
						vsrrI++;
					}

					// check if we reached last element in the array
					if (vsrrI < voSpoolRewardRatesArray.length) {
						rewardRate = voSpoolRewardRatesArray[vsrrI];
					} else {
						// if last tranche in an array, there are no more configured rewards
						// break the loop to save on gas
						break;
					}
				}

				// add user maturingAmount for every index
				userGradual.rawUnmaturedVotingPower += userGradual.maturingAmount;

				if (trancheIndex >= rewardRate.fromTranche) {
					// get actual voting power from raw unmatured voting power
					uint256 userPower = _getMaturingVotingPowerFromRaw(userGradual.rawUnmaturedVotingPower);

					// get tranche power for `trancheIndex`
					// we stored it when callint _storeVoSpoolForNewIndexes function
					uint256 tranchePowerAtIndex = getTranchePower(trancheIndex);

					// calculate users earned rewards for index based on
					// 1. reward rate for `trancheIndex`
					// 2. user power for `trancheIndex`
					// 3. global tranche power for `trancheIndex`
					if (tranchePowerAtIndex > 0) {
						voSpoolRewardUser.earned += uint248(
							(rewardRate.rewardPerTranche * userPower) / tranchePowerAtIndex
						);
					}
				}

				// update rewards until we reach last finished tranche index
			} while (trancheIndex < lastFinishedTrancheIndex);

			// store the updated user value
			voSpoolRewardUser.lastRewardRateIndex = uint8(voSpoolRewardConfig.rewardRatesIndex);
			userRewards[user] = voSpoolRewardUser;

			emit UserRewardUpdated(user, voSpoolRewardUser.lastRewardRateIndex, voSpoolRewardUser.earned);
		}
	}

	/* ========== HELPERS ========== */

	/**
	 * @notice Store the new reward rate to `voSpoolRewardRates` mapping
	 *
	 * @param voSpoolRewardRate struct to store
	 * @param rewardRatesIndex reward rates intex to use when storing the `voSpoolRewardRate`
	 */
	function _setRewardRate(VoSpoolRewardRate memory voSpoolRewardRate, uint256 rewardRatesIndex) private {
		uint256 arrayIndex = rewardRatesIndex / 2;
		uint256 position = rewardRatesIndex % 2;

		if (position == 0) {
			voSpoolRewardRates[arrayIndex].zero = voSpoolRewardRate;
		} else {
			voSpoolRewardRates[arrayIndex].one = voSpoolRewardRate;
		}
	}

	/**
	 * @notice Reset the storage the `voSpoolRewardRates` for `rewardRatesIndex` index
	 *
	 * @param rewardRatesIndex index to reset the storage for
	 */
	function _resetRewardRate(uint256 rewardRatesIndex) private {
		_setRewardRate(VoSpoolRewardRate(0, 0, 0), rewardRatesIndex);
	}

	/**
	 * @notice Retrieve the reward rate for index from storage
	 *
	 * @param rewardRatesIndex index to retrieve for
	 * @return voSpoolRewardRate storage pointer to the desired reward rate struct
	 */
	function _getRewardRate(uint256 rewardRatesIndex) private view returns (VoSpoolRewardRate storage) {
		uint256 arrayIndex = rewardRatesIndex / 2;
		uint256 position = rewardRatesIndex % 2;

		if (position == 0) {
			return voSpoolRewardRates[arrayIndex].zero;
		} else {
			return voSpoolRewardRates[arrayIndex].one;
		}
	}

	/**
	 * @notice Returns all reward rates in an array between last user update and now
	 * @dev Returns an array for simpler access when updating user reward rates for indexes
	 *
	 * @param userLastRewardRateIndex last index user updated
	 * @return voSpoolRewardRatesArray memory array of reward rates
	 */
	function _getRewardRatesForIndex(uint256 userLastRewardRateIndex)
		private
		view
		returns (VoSpoolRewardRate[] memory)
	{
		if (userLastRewardRateIndex == 0) userLastRewardRateIndex = 1;

		uint256 lastRewardRateIndex = voSpoolRewardConfig.rewardRatesIndex;
		uint256 newRewardRatesCount = lastRewardRateIndex - userLastRewardRateIndex + 1;
		VoSpoolRewardRate[] memory voSpoolRewardRatesArray = new VoSpoolRewardRate[](newRewardRatesCount);

		uint256 j = 0;
		for (uint256 i = userLastRewardRateIndex; i <= lastRewardRateIndex; i++) {
			voSpoolRewardRatesArray[j] = _getRewardRate(i);
			unchecked {
				j++;
			}
		}

		return voSpoolRewardRatesArray;
	}

	/**
	 * @notice Store global gradual tranche `power` at tranche `index`
	 * @dev
	 * We know the `power` is always represented with 48bits or less.
	 * We use this information to store 5 `power` values of consecutive
	 * indexes per word.
	 *
	 * @param power global gradual tranche power at `index`
	 * @param index tranche index at which to store
	 */
	function _storeTranchePowerForIndex(uint256 power, uint256 index) private {
		uint256 arrayindex = index / TRANCHES_PER_WORD;

		uint256 globalTranchesPosition = index % TRANCHES_PER_WORD;

		if (globalTranchesPosition == 1) {
			power = power << 48;
		} else if (globalTranchesPosition == 2) {
			power = power << 96;
		} else if (globalTranchesPosition == 3) {
			power = power << 144;
		} else if (globalTranchesPosition == 4) {
			power = power << 192;
		}

		unchecked {
			_tranchePowers[arrayindex] += power;
		}
	}

	/**
	 * @notice Retrieve global gradual tranche power at `index`
	 * @dev Same, but reversed, mechanism is used to retrieve the power at index
	 *
	 * @param index tranche index at which to retrieve the power value
	 * @return power global gradual tranche power at `index`
	 */
	function getTranchePower(uint256 index) public view returns (uint256) {
		uint256 arrayindex = index / TRANCHES_PER_WORD;

		uint256 powers = _tranchePowers[arrayindex];

		uint256 globalTranchesPosition = index % TRANCHES_PER_WORD;

		if (globalTranchesPosition == 0) {
			return (powers << 208) >> 208;
		} else if (globalTranchesPosition == 1) {
			return (powers << 160) >> 208;
		} else if (globalTranchesPosition == 2) {
			return (powers << 112) >> 208;
		} else if (globalTranchesPosition == 3) {
			return (powers << 64) >> 208;
		} else {
			return (powers << 16) >> 208;
		}
	}

	/**
	 * @notice calculates voting power from raw unmatured
	 *
	 * @param rawMaturingVotingPower raw maturing voting power amount
	 * @return maturingVotingPower actual maturing power amount
	 */
	function _getMaturingVotingPowerFromRaw(uint256 rawMaturingVotingPower) private pure returns (uint256) {
		return rawMaturingVotingPower / FULL_POWER_TRANCHES_COUNT;
	}

	/* ========== RESTRICTION FUNCTIONS ========== */

	/**
	 * @dev Ensures the caller is the SPOOL Staking contract
	 */
	function _onlySpoolStaking() private view {
		require(msg.sender == spoolStaking, "VoSpoolRewards::_onlySpoolStaking: Insufficient Privileges");
	}

	/* ========== MODIFIERS ========== */

	/**
	 * @dev Throws if the caller is not the SPOOL Staking contract
	 */
	modifier onlySpoolStaking() {
		_onlySpoolStaking();
		_;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./interfaces/ISpoolOwner.sol";

abstract contract SpoolOwnable {
    ISpoolOwner internal immutable spoolOwner;
    
    constructor(ISpoolOwner _spoolOwner) {
        require(
            address(_spoolOwner) != address(0),
            "SpoolOwnable::constructor: Spool owner contract address cannot be 0"
        );

        spoolOwner = _spoolOwner;
    }

    function isSpoolOwner() internal view returns(bool) {
        return spoolOwner.isSpoolOwner(msg.sender);
    }

    function _onlyOwner() internal view {
        require(isSpoolOwner(), "SpoolOwnable::onlyOwner: Caller is not the Spool owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISpoolOwner {
    function isSpoolOwner(address user) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/* ========== STRUCTS ========== */

/**
 * @notice global gradual struct
 * @member totalMaturedVotingPower total fully-matured voting power amount
 * @member totalMaturingAmount total maturing amount (amount of power that is accumulating every week for 1/156 of the amount)
 * @member totalRawUnmaturedVotingPower total raw voting power still maturing every tranche (totalRawUnmaturedVotingPower/156 is its voting power)
 * @member lastUpdatedTrancheIndex last (finished) tranche index global gradual has updated
 */
struct GlobalGradual {
	uint48 totalMaturedVotingPower;
	uint48 totalMaturingAmount;
	uint56 totalRawUnmaturedVotingPower;
	uint16 lastUpdatedTrancheIndex;
}

/**
 * @notice user tranche position struct, pointing at user tranche
 * @dev points at `userTranches` mapping
 * @member arrayIndex points at `userTranches`
 * @member position points at UserTranches position from zero to three (zero, one, two, or three)
 */
struct UserTranchePosition {
	uint16 arrayIndex;
	uint8 position;
}

/**
 * @notice user gradual struct, similar to global gradual holds user gragual voting power values
 * @dev points at `userTranches` mapping
 * @member maturedVotingPower users fully-matured voting power amount
 * @member maturingAmount users maturing amount
 * @member rawUnmaturedVotingPower users raw voting power still maturing every tranche
 * @member oldestTranchePosition UserTranchePosition pointing at the oldest unmatured UserTranche
 * @member latestTranchePosition UserTranchePosition pointing at the latest unmatured UserTranche
 * @member lastUpdatedTrancheIndex last (finished) tranche index user gradual has updated
 */
struct UserGradual {
	uint48 maturedVotingPower; // matured voting amount, power accumulated and older than FULL_POWER_TIME, not accumulating anymore
	uint48 maturingAmount; // total maturing amount (also maximum matured)
	uint56 rawUnmaturedVotingPower; // current user raw unmatured voting power (increases every new tranche), actual unmatured voting power can be calculated as unmaturedVotingPower / FULL_POWER_TRANCHES_COUNT
	UserTranchePosition oldestTranchePosition; // if arrayIndex is 0, user has no tranches (even if `latestTranchePosition` is not empty)
	UserTranchePosition latestTranchePosition; // can only increment, in case of tranche removal, next time user gradually mints we point at tranche at next position
	uint16 lastUpdatedTrancheIndex;
}

/**
 * @title Spool DAO Voting Token interface
 */
interface IVoSPOOL {
	/* ========== FUNCTIONS ========== */

	function mint(address, uint256) external;

	function burn(address, uint256) external;

	function mintGradual(address, uint256) external;

	function burnGradual(
		address,
		uint256,
		bool
	) external;

	function updateVotingPower() external;

	function updateUserVotingPower(address user) external;

	function getTotalGradualVotingPower() external returns (uint256);

	function getUserGradualVotingPower(address user) external returns (uint256);

	function getNotUpdatedUserGradual(address user) external view returns (UserGradual memory);

	function getNotUpdatedGlobalGradual() external view returns (GlobalGradual memory);

	function getCurrentTrancheIndex() external view returns (uint16);

	function getLastFinishedTrancheIndex() external view returns (uint16);

	/* ========== EVENTS ========== */

	event Minted(address indexed recipient, uint256 amount);

	event Burned(address indexed source, uint256 amount);

	event GradualMinted(address indexed recipient, uint256 amount);

	event GradualBurned(address indexed source, uint256 amount, bool burnAll);

	event GlobalGradualUpdated(
		uint16 indexed lastUpdatedTrancheIndex,
		uint48 totalMaturedVotingPower,
		uint48 totalMaturingAmount,
		uint56 totalRawUnmaturedVotingPower
	);

	event UserGradualUpdated(
		address indexed user,
		uint16 indexed lastUpdatedTrancheIndex,
		uint48 maturedVotingPower,
		uint48 maturingAmount,
		uint56 rawUnmaturedVotingPower
	);

	event MinterSet(address indexed minter, bool set);

	event GradualMinterSet(address indexed minter, bool set);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVoSpoolRewards {
	/* ========== FUNCTIONS ========== */

	function updateRewards(address user) external returns (uint256);

	function flushRewards(address user) external returns (uint256);

	/* ========== EVENTS ========== */

	event RewardRateUpdated(uint8 indexed fromTranche, uint8 indexed toTranche, uint112 rewardPerTranche);

	event RewardEnded(
		uint256 indexed rewardRatesIndex,
		uint8 indexed fromTranche,
		uint8 indexed toTranche,
		uint8 currentTrancheIndex
	);

	event UserRewardUpdated(address indexed user, uint8 lastRewardRateIndex, uint248 earned);
}
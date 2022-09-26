// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@hyfi-corp/vault/contracts/interfaces/IHYFI_Vault.sol";
import "./interfaces/IHYFI_RewardsManager.sol";

contract HYFI_Lottery is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IHYFI_Vault _vault;

    // the array of rewards Managers addresses
    IHYFI_RewardsManager[] public _rewardsManagers;

    // the array with information about each rewards set
    RewardsSetData[] public _rewardsSets;

    // the array with information about each guaranteed rewards sets
    GuaranteedRewardsSetData[] _guaranteedRewardsSets;

    // max number from all ranges in rewards set, starts from 0
    uint256 public _rangeMax;

    // max number from all ranges in guaranteed rewards set, starts from 0
    uint256 public _guaranteedRangeMax;

    // thw numbwe of Vaults which should be opened at once to have Guaranteed rewards sets
    uint256 public _guaranteedThreshold;

    // the list of rewards set ids which will be revealed as Garanteed

    // rangeMin-rangeMax - is a range that the random number should fall into.
    // totalAmount - the amount of such sets, for example RewardsSet #1 (Athena + ProMembership) has total amount 20 000
    // freeAmount - the amount of free rewardsSets, each time when user win the rewardsSet, it is decremented
    // rewards - array of rewards ids if the current set is in play
    // rewardsAsGuaranteed - array of rewards ids if the current set plays as Guaranteed
    // example: we have two pasks of guaranteed sets 1: RS1 + RS2 + 3*RS3; 2: RS1 + RS2 + 3*RS4
    // it means that user  will definalely win 4 ProMembership - 1 in RS1 and 3 in RS3 or RS4
    // but the ProMembership is useless in guaranteed rewards
    // bcs user has ultimate membership within guaranteed,
    // so no need to give user 4 additional ProMembership
    // so this array represents the same array as in rewards - but excluding or including some rewards
    // so the structure in hyfi will be:
    // 0 => {0, 1, 20_000, 20_000, [1, 0, 1, 0, 0, 0, 0]}
    //      0,1 - range (20% probability),
    //      amount 20_000,
    //      rewards: [1, 0, 1, 0, 0, 0, 0] mean 1*Athena + 1*Pro + 0 other rewards
    //      rewards as Guaranteed: [1, 0, 0, 0, 0, 0, 0] mean 1*Athena + 0 other rewards (doesn't have pro)
    // 1 => {2, 3, 20_000, 20_000, [1, 0, 1, 0, 0, 0, 0]}
    //      2,3 - range (20% probability),
    //      amount 20_000,
    //      rewards: [0, 1, 0, 1, 0, 0, 0] mean 1*AthenaAccess + 1*Ultimate + 0 other rewards
    //      rewards as Guaranteed: [0, 1, 0, 1, 0, 0, 0] mean 1*AthenaAccess + 1*Ultimate + 0 other rewards (the same rewards)
    // 2 => {4, 6, 30_000, 20_000, [1, 0, 1, 0, 0, 0, 0]}
    //      4,6 - range (30% probability),
    //      amount 30_000,
    //      rewards: [0, 1, 1, 0, 1, 0, 1] mean 1*AthenaAccess + 1*Pro + 1*HYFI50 + Voucher
    //      rewards as Guaranteed: [0, 1, 1, 0, 1, 0, 1] mean 1*AthenaAccess + 1*HYFI50 + Voucher (doesn't have pro)
    // 3 => {4, 6, 30_000, 20_000, [1, 0, 1, 0, 0, 0, 0]}
    //      7,9 - range (30% probability),
    //      amount 30_000,
    //      rewards: [0, 1, 1, 0, 0, 1, 1] mean 1*AthenaAccess + 1*Pro + 1*HYFI100 + Voucher
    //      rewards as Guaranteed: [0, 1, 1, 0, 0, 1, 1] mean 1*AthenaAccess + 1*Pro + 1*HYFI100 + Voucher
    struct RewardsSetData {
        uint256 rangeMin;
        uint256 rangeMax;
        uint256 totalAmount;
        uint256 freeAmount;
        uint256[] rewards;
        uint256[] rewardsAsGuaranteed;
    }

    // rangeMin-rangeMax (reflection of Probability to win this set)- is a range that the random number should fall into.
    // example HYFY guaranteed rewards are RS1 + RS2 + 3*(RS3 | RS4)
    // it means that we have two guaranteed sets:
    // 0 | RS1 + RS2 + 3*RS3 | 50%
    // 1 | RS1 + RS2 + 3*RS4| 50%
    // if we have two guaranteed sets of rewards with probability 50/50,
    // it should be range 0-0 for the first guaranteed set and 1-1 for the second one
    // if the generated number from 0 to _guaranteedRangeMax is in the set range - we generate for user this set of rewards
    // rewards - array of rewardsSets where key is rewardsSetId and value is amount of RewardsSets
    // so in hyfi the structure will be:
    // 0 => {0,0,[1,1,3,0]} -
    //      0,0 means 50% probability,
    //      1,1,3,0 - mean RS1 + RS2 + 3*RS3 + 0*RS4
    // 0 => {1,1,[1,1,0,3]} -
    //      1,1 means 50% probability,
    //      1,1,0,3 - mean RS1 + RS2 + 0*RS3 + 3*RS4
    struct GuaranteedRewardsSetData {
        uint256 rangeMin;
        uint256 rangeMax;
        uint256[] rewardsSets;
    }

    event UserRewarded(uint256 revealedVaultsAmount, uint256[] rewards);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function addReward(address rewardManager) external {
        _rewardsManagers.push(IHYFI_RewardsManager(rewardManager));
    }

    /**
     * @dev set the new total amount of maximum range value, it will be used in random generator
     * @param newThreshold the new guaranteed threshold value. If user reveals this amount of tickets at once - it will have guaranteed set of rewards
     */
    function setGuaranteedThreshold(uint256 newThreshold)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _guaranteedThreshold = newThreshold;
    }

    /**
     * todo recalculate value when reward is added
     * @dev set the new total amount of maximum range value, it will be used in random generator
     * @param newRangeMax the new max value in the normalized range
     */
    function setRangeMax(uint256 newRangeMax)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _rangeMax = newRangeMax;
    }

    /**
     * @dev set the new total amount of maximum range value, it will be used in random generator
     * @param newRangeMax the new max value in the normalized range
     */
    function setGuaranteedRangeMax(uint256 newRangeMax)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _guaranteedRangeMax = newRangeMax;
    }

    // todo: add modifier for rewards array - check if length is <= _rewardsManagers.length
    function addRewardsSet(
        uint256 rangeMin,
        uint256 rangeMax,
        uint256 totalAmount,
        uint256[] memory rewards,
        uint256[] memory rewardsAsGuaranteed
    ) external {
        RewardsSetData memory rewardsSet;
        rewardsSet.rangeMax = rangeMax;
        rewardsSet.rangeMin = rangeMin;
        rewardsSet.totalAmount = totalAmount;
        rewardsSet.freeAmount = totalAmount;
        rewardsSet.rewards = rewards;
        rewardsSet.rewardsAsGuaranteed = rewardsAsGuaranteed;
        _rewardsSets.push(rewardsSet);
    }

    // todo: add modifier for rewards array - check if length is <= _rewardsManagers.length
    function setupRewardsSet(
        uint256 rewardsSetId,
        uint256 rangeMin,
        uint256 rangeMax,
        uint256 totalAmount,
        uint256 freeAmount,
        uint256[] memory rewards,
        uint256[] memory rewardsAsGuaranteed
    ) external {
        RewardsSetData storage rewardsSet = _rewardsSets[rewardsSetId];
        rewardsSet.rangeMax = rangeMax;
        rewardsSet.rangeMin = rangeMin;
        rewardsSet.totalAmount = totalAmount;
        rewardsSet.freeAmount = freeAmount;
        rewardsSet.rewards = rewards;
        rewardsSet.rewardsAsGuaranteed = rewardsAsGuaranteed;
    }

    function addGuaranteedRewardsSet(
        uint256 rangeMin,
        uint256 rangeMax,
        uint256[] memory rewardsSets
    ) external {
        GuaranteedRewardsSetData memory rewardsSet;

        rewardsSet.rangeMax = rangeMax;
        rewardsSet.rangeMin = rangeMin;
        rewardsSet.rewardsSets = rewardsSets;
        _guaranteedRewardsSets.push(rewardsSet);
    }

    // todo: add modifier for rewardsSets array - check if length is <= _rewardsSets.length
    function setupGuaranteedRewardsSet(
        uint256 guaranteedRewardsSetId,
        uint256 rangeMin,
        uint256 rangeMax,
        uint256[] memory rewardsSets
    ) external {
        GuaranteedRewardsSetData
            storage guaranteedRewardsSet = _guaranteedRewardsSets[
                guaranteedRewardsSetId
            ];
        guaranteedRewardsSet.rangeMax = rangeMax;
        guaranteedRewardsSet.rangeMin = rangeMin;
        guaranteedRewardsSet.rewardsSets = rewardsSets;
    }

    // todo add modifier mUserOwnsVaultsAmount(revealIds)
    // move      this check to modifier   require(revealAmount <= _vault.balanceOf(msg.sender));
    function revealVaults(uint256 revealAmount) external {
        require(revealAmount > 0);
        require(revealAmount <= _vault.balanceOf(msg.sender));

        uint256[] memory userVaultsIds;
        for (uint256 i = 0; i < revealAmount; i++) {
            userVaultsIds[i] = _vault.tokenOfOwnerByIndex(msg.sender, i);
        }
        _revealSpecificVaults(userVaultsIds);
    }

    // todo implementation
    // todo add modifier mUserOwnsVaultsIds(revealIds)
    function revealSpecificVaults(uint256[] memory revealIds) external {
        // check the ownership of specified vault ids
        //        _revealSpecificVaults(revealIds);
    }

    function _revealSpecificVaults(uint256[] memory revealIds)
        public
        returns (uint256[] memory)
    {
        uint256 revealAmount = revealIds.length;
        // calculate number of guaranteed sets (how many times we open tickets by 5(_guaranteedThreshold) at once)
        // if user opens 23 tickets at once, guaranteedSetsAmount should be 4 (4 times by 5 tickets = 20)
        // and oneByOneAmount will be 3 (3 tickets should be opened one by one)
        uint256 guaranteedSetsAmount = getGuaranteedSetsAmount(revealAmount);
        uint256 oneByOneAmount = getOneByOneAmount(revealAmount);

        uint256 i;
        uint256[] memory userVaultsIdsOneByOne = new uint256[](oneByOneAmount);
        // get the array of vault ids which should be reveald one by one (for simplicity the first ones in the array are used)
        for (i = 0; i < oneByOneAmount; i++) {
            userVaultsIdsOneByOne[i] = revealIds[i];
        }
        // get amount of each reward's set, won by user revealing one by one tickets
        uint256[] memory userRewardsSetsOneByOne = _processVaultsOneByOne(
            userVaultsIdsOneByOne
        );

        // get amount of each reward's set, won by user revealing guaranteed amount
        uint256[] memory userGuaranteedRewardsSets = _processGuaranteedSets(
            guaranteedSetsAmount
        );

        uint256[] memory userRewards = new uint256[](_rewardsManagers.length);

        uint256 setsAmount;
        for (i = 0; i < _rewardsSets.length; i++) {
            // calculate the total amount of each rewards set (sum up the amounts of sets of rewards won one by one & revealed as guaranted)
            setsAmount =
                userRewardsSetsOneByOne[i] +
                userGuaranteedRewardsSets[i];
            if (setsAmount > 0) {
                _rewardsSets[i].freeAmount =
                    _rewardsSets[i].freeAmount -
                    setsAmount;
                for (uint256 j = 0; j < _rewardsSets[i].rewards.length; j++) {
                    if (userRewardsSetsOneByOne[i] > 0) {
                        userRewards[j] +=
                            _rewardsSets[i].rewards[j] *
                            userRewardsSetsOneByOne[i];
                    }
                    if (userGuaranteedRewardsSets[i] > 0) {
                        userRewards[j] +=
                            _rewardsSets[i].rewardsAsGuaranteed[j] *
                            userGuaranteedRewardsSets[i];
                    }
                }
            }
        }

        emit UserRewarded(revealAmount, userRewards);

        // _burnVaults(revealIds);

        for (i = 0; i < userRewards.length; i++) {
            if (userRewards[i] > 0) {
                // _rewardsManagers[i].revealRewards(msg.sender, userRewards[i]);
            }
        }
        return userRewards;
    }

    function getRewardsSet(uint256 rewardSetId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256[] memory
        )
    {
        return (
            _rewardsSets[rewardSetId].rangeMin,
            _rewardsSets[rewardSetId].rangeMax,
            _rewardsSets[rewardSetId].totalAmount,
            _rewardsSets[rewardSetId].freeAmount,
            _rewardsSets[rewardSetId].rewards
        );
    }

    function getRewardsManager(uint256 rewardId) public view returns (address) {
        return address(_rewardsManagers[rewardId]);
    }

    /**
     * @dev calculate the rewards sets won during revealing tickets one by one
     * @param revealIds array of vault IDs are going to be revealed
     * @return array where key is rewardsSet id and value is amount of won rewardsSets
     */
    function _processVaultsOneByOne(uint256[] memory revealIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory userRewardsSets = new uint256[](_rewardsSets.length);
        for (uint256 i = 0; i < revealIds.length; i++) {
            userRewardsSets[_processVault(revealIds[i])]++;
        }
        return userRewardsSets;
    }

    /**
     * @dev calculate the rewards set won during revealing one ticket
     * @param vaultId vault ID is going to be revealed
     * @return winning rewardsSet Id
     */
    function _processVault(uint256 vaultId) public view returns (uint256) {
        uint256 randomValue = getRandomValue(vaultId) % (_rangeMax + 1); // 0 - 9
        return getWinningRewardsSet(randomValue);
    }

    function getWinningRewardsSet(uint256 randomValue)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < _rewardsSets.length; i++) {
            if (
                randomValue >= _rewardsSets[i].rangeMin &&
                randomValue <= _rewardsSets[i].rangeMax
            ) {
                return i;
            }
        }
        return 0;
    }

    function _processGuaranteedSets(uint256 guaranteedAmount)
        public
        view
        returns (uint256[] memory)
    {
        // is used on each iteration, stores won amount of each rewardsSet
        uint256[] memory tempRewardsSetsAmounstById = new uint256[](
            _rewardsSets.length
        );
        // is used on to calculate total won amounts of each rewardsSet
        uint256[] memory totalRewardsSetsAmounstById = new uint256[](
            _rewardsSets.length
        );
        uint256 j;
        for (uint256 i = 0; i < guaranteedAmount; i++) {
            tempRewardsSetsAmounstById = _processGuaranteedSet(i);

            for (j = 0; j < tempRewardsSetsAmounstById.length; j++) {
                totalRewardsSetsAmounstById[j] += tempRewardsSetsAmounstById[j];
            }
            // rewardsSetsIds
            // userGuaranteedRewardsSets[rewardsSetId]++;
        }
        return totalRewardsSetsAmounstById;
    }

    function _processGuaranteedSet(uint256 i)
        public
        view
        returns (uint256[] memory)
    {
        uint256 randomValue = getRandomValue(i) % (_guaranteedRangeMax + 1);
        return getWinningGuaranteedRewardsSets(randomValue);
    }

    function getWinningGuaranteedRewardsSets(uint256 randomValue)
        public
        view
        returns (uint256[] memory)
    {
        for (uint256 i = 0; i < _guaranteedRewardsSets.length; i++) {
            if (
                randomValue >= _guaranteedRewardsSets[i].rangeMin &&
                randomValue <= _guaranteedRewardsSets[i].rangeMax
            ) {
                return _guaranteedRewardsSets[i].rewardsSets;
            }
        }
    }

    function getRandomValue(uint256 seed) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        seed
                    )
                )
            );
    }

    function getGuaranteedSetsAmount(uint256 amount)
        public
        view
        returns (uint256)
    {
        return amount / _guaranteedThreshold;
    }

    function getOneByOneAmount(uint256 amount) public view returns (uint256) {
        return amount % _guaranteedThreshold;
    }

    function _burnVaults(uint256[] memory vaultIds) public {
        for (uint256 i = 0; i < vaultIds.length; i++) {
            _vault.burn(i);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IHYFI_RewardsManager is IAccessControlUpgradeable {
    function revealRewards(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IHYFI_Vault is IAccessControlUpgradeable {
    function MINTER_ROLE() external view returns (bytes32);

    function BURNER_ROLE() external view returns (bytes32);

    function safeMint(address to, uint256 amount) external;
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function burn(uint256 tokenId) external;

}
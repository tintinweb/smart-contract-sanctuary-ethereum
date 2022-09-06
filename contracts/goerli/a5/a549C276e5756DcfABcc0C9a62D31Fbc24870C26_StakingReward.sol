// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interface/IStakingReward.sol";
import "../interface/IEXOToken.sol";
import "../interface/IGCREDToken.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract StakingReward is
    Initializable,
    IStakingReward,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant EXO_ROLE = keccak256("EXO_ROLE");

    uint256 constant decimal = 1e18;
    uint256 constant MAX_REWRAD = 35e26;
    /*------------------Test Only------------------*/
    uint256 constant CLAIM_DELAY = 1 days;
    // uint256 constant FN_REWARD = 0x205479E18;
    /*---------------------------------------------*/
    // Counter for staking
    uint256 public stakingCounter;
    // EXO token address
    address public EXO_ADDRESS;
    // GCRED token address
    address public GCRED_ADDRESS;
    // Foundation Node wallet which is releasing EXO to prevent inflation
    address public FOUNDATION_NODE;
    // Reward amount from FN wallet
    uint256 private _FN_REWARD;
    // Last staking timestamp
    uint256 private latestStakingTime;
    // Last claimed time
    uint256 public latestClaimTime;
    // All staking infors
    StakingInfo[] public stakingInfos;
    // Tier of the user; Tier 0 ~ 3
    mapping(address => uint8) public tier;
    // Whether holder can upgrade tier status
    mapping(address => bool) public tierCandidate;
    // Mapping from address to staking index array
    mapping(address => uint256[]) public stakingIndex;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _EXO_ADDRESS, address _GCRED_ADDRESS)
        public
        initializer
    {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(EXO_ROLE, _EXO_ADDRESS);

        EXO_ADDRESS = _EXO_ADDRESS;
        GCRED_ADDRESS = _GCRED_ADDRESS;
    }

    /// @inheritdoc	IStakingReward
    function stake(uint256 _amount, uint8 _duration)
        external
        override
        whenNotPaused
    {
        address holder = _msgSender();
        require(
            _amount <= IERC20Upgradeable(EXO_ADDRESS).balanceOf(holder),
            "StakingReward: Not enough EXO token to stake"
        );
        require(_duration < 4, "StakingReward: Duration does not match");

        if (holder == FOUNDATION_NODE) {
            // Calculate reward amount from Foudation Node wallet
            _FN_REWARD = (_amount * 75) / 1000 / 365;
        } else {
            uint24[4] memory minAmount = _getTierMinAmount();
            uint24[4] memory period = _getStakingPeriod();
            latestStakingTime = block.timestamp;
            uint8 _tier = tier[holder] * 4 + _duration;

            stakingInfos.push(
                StakingInfo(
                    holder,
                    _amount,
                    latestStakingTime,
                    latestStakingTime + uint256(period[_duration]),
                    _duration,
                    block.timestamp,
                    _tier
                )
            );
            // Check user can upgrade tier
            if (
                tier[holder] < 3 &&
                _amount >= uint256(minAmount[tier[holder] + 1]) &&
                _duration > tier[holder]
            ) tierCandidate[holder] = true;
            stakingIndex[holder].push(stakingCounter);
            stakingCounter++;
        }

        IERC20Upgradeable(EXO_ADDRESS).transferFrom(
            holder,
            address(this),
            _amount
        );
        emit Stake(holder, _amount, block.timestamp);
    }

    function claimBatch() external onlyRole(OWNER_ROLE) whenNotPaused {
        require(stakingInfos.length > 0, "StakingReward: Nobody staked");
        require(
            block.timestamp - latestClaimTime >= CLAIM_DELAY,
            "StakingReward: Not started new multi claim"
        );
        // Staking holder counter in each `interestRate`
        uint256[16] memory interestHolderCounter;

        for (uint256 i = 0; i < stakingInfos.length; i++) {
            address stakingHolder = stakingInfos[i].holder;
            uint256 stakingAmount = stakingInfos[i].amount;
            uint256 interestRate = stakingInfos[i].interestRate;
            if (block.timestamp < stakingInfos[i].expireDate) {
                // Claim reward every day
                if (
                    block.timestamp - stakingInfos[i].latestClaimDate >=
                    CLAIM_DELAY
                ) {
                    // Count
                    interestHolderCounter[interestRate] += 1;
                    // Calculate reward EXO amount
                    uint256 REWARD_APR = _getEXORewardAPR(
                        stakingInfos[i].interestRate
                    );
                    uint256 reward = _calcReward(stakingAmount, REWARD_APR);
                    // Mint reward to staking holder
                    IEXOToken(EXO_ADDRESS).mint(stakingHolder, reward);
                    // Calculate GCRED daily reward
                    uint256 GCRED_REWARD = (uint256(
                        _getGCREDReturn(stakingInfos[i].interestRate)
                    ) * decimal) / 1000;
                    // send GCRED to holder
                    _sendGCRED(stakingHolder, GCRED_REWARD);
                    // Update latest claimed date
                    stakingInfos[i].latestClaimDate = block.timestamp;

                    emit Claim(stakingHolder, block.timestamp);
                }
            } else {
                /* The staking date is expired */
                // Upgrade holder's tier
                if (
                    stakingInfos[i].duration >= tier[stakingHolder] &&
                    tierCandidate[stakingHolder]
                ) {
                    if (tier[stakingHolder] < 3) {
                        tier[stakingHolder] += 1;
                    }
                    tierCandidate[stakingHolder] = false;
                }
                // Decrease staking counter
                stakingCounter--;
                // Update holder's staking index array
                uint256[] storage holderStakingIndex = stakingIndex[
                    stakingHolder
                ];
                holderStakingIndex[i] = holderStakingIndex[
                    holderStakingIndex.length - 1
                ];
                holderStakingIndex.pop();
                // Update total staking array
                uint256 totalLength = stakingInfos.length;
                stakingInfos[i] = stakingInfos[totalLength - 1];
                stakingInfos.pop();
                if (i != 0) i--;
                // Return staked EXO to holder
                IERC20Upgradeable(EXO_ADDRESS).transfer(
                    stakingHolder,
                    stakingAmount
                );
                emit UnStake(stakingHolder, stakingAmount, block.timestamp);
            }
        }
        _getRewardFromFN(interestHolderCounter);
        latestClaimTime = block.timestamp;
    }

    /// @inheritdoc IStakingReward
    function setEXOAddress(address _EXO_ADDRESS)
        external
        override
        onlyRole(OWNER_ROLE)
    {
        EXO_ADDRESS = _EXO_ADDRESS;

        emit EXOAddressUpdated(EXO_ADDRESS);
    }

    /// @inheritdoc IStakingReward
    function setGCREDAddress(address _GCRED_ADDRESS)
        external
        override
        onlyRole(OWNER_ROLE)
    {
        GCRED_ADDRESS = _GCRED_ADDRESS;

        emit GCREDAddressUpdated(GCRED_ADDRESS);
    }

    function setFNAddress(address _FOUNDATION_NODE)
        external
        override
        onlyRole(OWNER_ROLE)
    {
        FOUNDATION_NODE = _FOUNDATION_NODE;

        emit FoundationNodeUpdated(FOUNDATION_NODE);
    }

    function setTier(address _holder, uint8 _tier)
        external
        override
        onlyRole(EXO_ROLE)
    {
        tier[_holder] = _tier;
    }

    function getStakingInfos(address _holder)
        external
        view
        returns (StakingInfo[] memory)
    {
        require(stakingCounter > 0, "EXO: Nobody staked");
        uint256 len = stakingIndex[_holder].length;
        StakingInfo[] memory _currentStaker = new StakingInfo[](len);
        for (uint256 i = 0; i < len; i++) {
            _currentStaker[i] = stakingInfos[stakingIndex[_holder][i]];
        }

        return _currentStaker;
    }

    function getStakingIndex(address _holder)
        external
        view
        returns (uint256[] memory)
    {
        return stakingIndex[_holder];
    }

    /// @inheritdoc IStakingReward
    function getTier(address _user) external view returns (uint8) {
        return tier[_user];
    }

    function pause() public onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        _unpause();
    }

    /// @dev Minimum EXO amount in tier
    function getTierMinAmount() external pure returns (uint24[4] memory) {
        uint24[4] memory tierMinimumAmount = [0, 200_000, 400_0000, 800_0000];
        return tierMinimumAmount;
    }

    function _getRewardFromFN(uint256[16] memory _interestHolderCounter)
        internal
    {
        uint8[16] memory FN_REWARD_PERCENT = _getFNRewardPercent();
        uint256[16] memory _rewardAmountFn;
        for (uint256 i = 0; i < FN_REWARD_PERCENT.length; i++) {
            if (_interestHolderCounter[i] == 0) {
                _rewardAmountFn[i] = 0;
            } else {
                _rewardAmountFn[i] =
                    (_FN_REWARD * uint256(FN_REWARD_PERCENT[i])) /
                    _interestHolderCounter[i] /
                    1000;
            }
        }
        for (uint256 i = 0; i < stakingInfos.length; i++) {
            uint256 _rewardAmount = _rewardAmountFn[
                stakingInfos[i].interestRate
            ];
            if (_rewardAmount != 0) {
                IEXOToken(EXO_ADDRESS).mint(
                    stakingInfos[i].holder,
                    _rewardAmount
                );
                emit ClaimFN(
                    stakingInfos[i].holder,
                    _rewardAmount,
                    block.timestamp
                );
            }
        }
    }

    /// @dev Staking period
    function _getStakingPeriod() internal pure returns (uint24[4] memory) {
        uint24[4] memory stakingPeriod = [0, 30 days, 60 days, 90 days];
        return stakingPeriod;
    }

    /// @dev Minimum EXO amount in tier
    function _getTierMinAmount() internal pure returns (uint24[4] memory) {
        uint24[4] memory tierMinimumAmount = [0, 200_000, 400_0000, 800_0000];
        return tierMinimumAmount;
    }

    /// @dev EXO Staking reward APR
    function _getEXORewardAPR(uint8 _interestRate)
        internal
        pure
        returns (uint8)
    {
        uint8[16] memory EXO_REWARD_APR = [
            50,
            55,
            60,
            65,
            60,
            65,
            70,
            75,
            60,
            65,
            70,
            75,
            60,
            65,
            70,
            75
        ];
        return EXO_REWARD_APR[_interestRate];
    }

    /// @dev Foundation Node Reward Percent Array
    function _getFNRewardPercent() internal pure returns (uint8[16] memory) {
        uint8[16] memory FN_REWARD_PERCENT = [
            0,
            0,
            0,
            0,
            30,
            60,
            85,
            115,
            40,
            70,
            95,
            125,
            50,
            80,
            105,
            145
        ];
        return FN_REWARD_PERCENT;
    }

    /// @dev GCRED reward per day
    function _getGCREDReturn(uint8 _interest) internal pure returns (uint16) {
        uint16[16] memory GCRED_RETURN = [
            0,
            0,
            0,
            242,
            0,
            0,
            266,
            354,
            0,
            0,
            293,
            390,
            0,
            0,
            322,
            426
        ];
        return GCRED_RETURN[_interest];
    }

    function _sendGCRED(address _address, uint256 _amount) internal {
        IGCREDToken(GCRED_ADDRESS).mintForReward(_address, _amount);
        emit ClaimGCRED(_address, _amount, block.timestamp);
    }

    function _calcReward(uint256 _amount, uint256 _percent)
        internal
        pure
        returns (uint256)
    {
        return (_amount * _percent) / 365000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title interface for Staking reward logic
/// @author Tamer Fouad
interface IStakingReward {
	/// @notice Struct for staker's info
	/// @param holder Staking holder address
	/// @param amount Staked amount
	/// @param startDate start date of staking
	/// @param expireDate expire date of staking
	/// @param duration Stake duration
	/// @param latestClaimDate Timestamp for the latest claimed date
	/// @param interestRate Interest rate
	struct StakingInfo {
		address holder;
		uint256 amount;
		uint256 startDate;
		uint256 expireDate;
		uint256 duration;
		uint256 latestClaimDate;
		uint8 interestRate;
	}

	/// @dev Emitted when user stake
	/// @param from Staker address
	/// @param amount Staking token amount
	/// @param timestamp Staking time
	event Stake(address indexed from, uint256 amount, uint256 timestamp);

	/// @dev Emitted when a stake holder unstakes
	/// @param from address of the unstaking holder
	/// @param amount token amount
	/// @param timestamp unstaked time
	event UnStake(address indexed from, uint256 amount, uint256 timestamp);

	/// @notice Claim EXO Rewards by staking EXO
	/// @dev Emitted when the user claim reward
	/// @param to address of the claimant
	/// @param timestamp timestamp for the claim
	event Claim(address indexed to, uint256 timestamp);

	/// @notice Claim GCRED by holding EXO
	/// @dev Emitted when the user claim GCRED reward per day
	/// @param to address of the claimant
	/// @param amount a parameter just like in doxygen (must be followed by parameter name)
	/// @param timestamp a parameter just like in doxygen (must be followed by parameter name)
	event ClaimGCRED(address indexed to, uint256 amount, uint256 timestamp);

	/// @notice Claim EXO which is releasing from Foundation Node to prevent inflation
	/// @dev Emitted when the user claim FN reward
	/// @param to address of the claimant
	/// @param amount a parameter just like in doxygen (must be followed by parameter name)
	/// @param timestamp a parameter just like in doxygen (must be followed by parameter name)
	event ClaimFN(address indexed to, uint256 amount, uint256 timestamp);

	/// @dev Emitted when the owner update EXO token address
	/// @param EXO_ADDRESS new EXO token address
	event EXOAddressUpdated(address EXO_ADDRESS);

	/// @dev Emitted when the owner update GCRED token address
	/// @param GCRED_ADDRESS new GCRED token address
	event GCREDAddressUpdated(address GCRED_ADDRESS);

	/// @dev Emitted when the owner update FN wallet address
	/// @param FOUNDATION_NODE new foundation node wallet address
	event FoundationNodeUpdated(address FOUNDATION_NODE);

	/**
	 * @notice Stake EXO tokens
	 * @param _amount Token amount
	 * @param _duration staking lock-up period type
	 *
	 * Requirements
	 *
	 * - Validate the balance of EXO holdings
	 * - Validate lock-up duration type
	 *    0: Soft lock
	 *    1: 30 days
	 *    2: 60 days
	 *    3: 90 days
	 *
	 * Emits a {Stake} event
	 */
	function stake(uint256 _amount, uint8 _duration) external;

	/// @dev Set new `_tier` of `_holder`
	/// @param _holder foundation node address
	/// @param _tier foundation node address
	function setTier(address _holder, uint8 _tier) external;

	/**
	 * @dev Set EXO token address
	 * @param _EXO_ADDRESS EXO token address
	 *
	 * Emits a {EXOAddressUpdated} event
	 */
	function setEXOAddress(address _EXO_ADDRESS) external;

	/**
	 * @dev Set GCRED token address
	 * @param _GCRED_ADDRESS GCRED token address
	 *
	 * Emits a {GCREDAddressUpdated} event
	 */
	function setGCREDAddress(address _GCRED_ADDRESS) external;

	/**
	 * @dev Set Foundation Node address
	 * @param _FOUNDATION_NODE foundation node address
	 *
	 * Emits a {FoundationNodeUpdated} event
	 */
	function setFNAddress(address _FOUNDATION_NODE) external;

	/**
	 * @dev Returns user's tier
	 * @param _holder Staking holder address
	 */
	function getTier(address _holder) external view returns (uint8);

	/**
	 * @dev Returns user's staking indexes array
	 * @param _holder Staking holder address
	 */
	function getStakingIndex(address _holder)
		external
		view
		returns (uint256[] memory);

	/**
	 * @dev Returns minimum token amount in tier
	 */
	function getTierMinAmount() external view returns (uint24[4] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title interface for game token GCRED
/// @author Tamer Fouad
interface IGCREDToken {
    /// @dev Mint GCRED via bridge
    /// @param to Address to mint
    /// @param amount Token amount to mint
    function bridgeMint(address to, uint256 amount) external;

    /// @dev Burn GCRED via bridge
    /// @param owner Address to burn
    /// @param amount Token amount to burn
    function bridgeBurn(address owner, uint256 amount) external;

    /// @dev Mint GCRED via EXO for daily reward
    /// @param to Address to mint
    /// @param amount Token amount to mint
    function mintForReward(address to, uint256 amount) external;

    /**
     * @dev Set EXO token address
     * @param _EXO_ADDRESS EXO token address
     *
     * Emits a {EXOAddressUpdated} event
     */
    function setEXOAddress(address _EXO_ADDRESS) external;

    /**
     * @dev Set MD(Metaverse Development) wallet address
     * @param _MD_ADDRESS MD wallet address
     *
     * Emits a {MDAddressUpdated} event
     */
    function setMDAddress(address _MD_ADDRESS) external;

    /**
     * @dev Set DAO wallet address
     * @param _DAO_ADDRESS DAO wallet address
     *
     * Emits a {DAOAddressUpdated} event
     */
    function setDAOAddress(address _DAO_ADDRESS) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title interface for Governance token EXO
/// @author Tamer Fouad
interface IEXOToken {
    /// @dev Mint EXO
    /// @param to Address to min
    /// @param amount mint amount
    function mint(address to, uint256 amount) external;

    /// @dev Mint EXO via bridge
    /// @param to Address to mint
    /// @param amount Token amount to mint
    function bridgeMint(address to, uint256 amount) external;

    /// @dev Burn EXO via bridge
    /// @param owner Address to burn
    /// @param amount Token amount to burn
    function bridgeBurn(address owner, uint256 amount) external;

    /// @notice Set bridge contract address
    /// @dev Grant `BRIDGE_ROLE` to bridge contract
    /// @param _bridge Bridge contract address
    function setBridge(address _bridge) external;

    /// @notice Set staking contract address
    /// @dev Grant `MINTER_ROLE` to staking contract
    /// @param _staking Staking contract address
    function setStakingReward(address _staking) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
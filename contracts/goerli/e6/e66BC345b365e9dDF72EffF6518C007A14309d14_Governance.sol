// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interface/IGovernance.sol";
import "../interface/IStakingReward.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Governance is
    Initializable,
    IGovernance,
    PausableUpgradeable,
    OwnableUpgradeable
{
    // Counter for votes
    uint256 public voteCounter;
    // EXO token contract address
    address public EXO_ADDRESS;
    // Staking reward contract address
    address public STAKING_ADDRESS;

    // All registered votes
    mapping(uint256 => Vote) public registeredVotes;
    // Whether voter can vote to the specific vote->proposal
    mapping(uint256 => mapping(address => bool)) private hasVoted;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _EXO_ADDRESS, address _STAKING_ADDRESS)
        public
        initializer
    {
        __Pausable_init();
        __Ownable_init();
        EXO_ADDRESS = _EXO_ADDRESS;
        STAKING_ADDRESS = _STAKING_ADDRESS;
    }

    /// @inheritdoc	IGovernance
    function createVote(
        string calldata _subject,
        uint256 _startDate,
        uint256 _endDate,
        string[] calldata _proposals
    ) external override onlyOwner whenNotPaused {
        // Validate voting period
        require(_startDate > block.timestamp, "Governance: Invalid start date");
        require(_startDate < _endDate, "Governance: Invalid end date");
        // Register a new vote
        Vote storage newVote = registeredVotes[voteCounter];
        newVote.index = voteCounter;
        newVote.subject = _subject;
        newVote.startDate = _startDate;
        newVote.endDate = _endDate;
        for (uint256 i = 0; i < _proposals.length; i++) {
            newVote.proposals.push(Proposal(_proposals[i], 0));
        }
        voteCounter++;

        emit NewVote(_subject, _startDate, _endDate, block.timestamp);
    }

    /// @inheritdoc	IGovernance
    function castVote(uint256 _voteId, uint8 _proposalId)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        address voter = _msgSender();
        // Validate vote id
        require(_voteId < voteCounter, "Governance: Not valid Vote ID");
        // Validate if EXO holder
        require(
            IERC20Upgradeable(EXO_ADDRESS).balanceOf(voter) > 0,
            "Governance: Not EXO holder"
        );
        // Check if already voted or not
        require(!hasVoted[_voteId][voter], "Governance: User already voted");
        // Register a new vote
        Vote storage vote = registeredVotes[_voteId];
        require(
            vote.endDate > block.timestamp,
            "Governance: Vote is already expired"
        );
        require(
            vote.startDate <= block.timestamp,
            "Governance: Vote is not started yet"
        );
        require(
            _proposalId < vote.proposals.length,
            "Governance: Not valid proposal id"
        );
        // Calculate vote weight using user's tier and EXO balance
        uint8 tier = IStakingReward(STAKING_ADDRESS).getTier(voter);
        uint256 balance = IERC20Upgradeable(EXO_ADDRESS).balanceOf(voter);
        uint256 voteWeight = uint256(1 + (((tier * tier + 1) / 2) * 25) / 100) *
            balance;
        vote.proposals[_proposalId].voteCount += voteWeight;
        // Set true `hasVoted` flag
        hasVoted[_voteId][voter] = true;

        emit VoteCast(voter, _voteId, voteWeight, _proposalId);

        return voteWeight;
    }

    /// @inheritdoc	IGovernance
    function setEXOAddress(address _EXO_ADDRESS) external whenNotPaused {
        EXO_ADDRESS = _EXO_ADDRESS;

        emit EXOAddressUpdated(_EXO_ADDRESS);
    }

    /// @inheritdoc	IGovernance
    function setStakingAddress(address _STAKING_ADDRESS)
        external
        whenNotPaused
    {
        STAKING_ADDRESS = _STAKING_ADDRESS;

        emit StakingAddressUpdated(STAKING_ADDRESS);
    }

    /// @inheritdoc	IGovernance
    function getAllVotes()
        external
        view
        override
        whenNotPaused
        returns (Vote[] memory)
    {
        require(voteCounter > 0, "EXO: Registered votes Empty");
        Vote[] memory allVotes = new Vote[](voteCounter);
        for (uint256 i = 0; i < voteCounter; i++) {
            Vote storage tmp_vote = registeredVotes[i];
            allVotes[i] = tmp_vote;
        }
        return allVotes;
    }

    /// @inheritdoc	IGovernance
    function getActiveVotes()
        external
        view
        override
        whenNotPaused
        returns (Vote[] memory)
    {
        require(voteCounter > 0, "EXO: Vote Empty");
        Vote[] memory activeVotes;
        uint256 j = 0;
        for (uint256 i = 0; i < voteCounter; i++) {
            Vote storage activeVote = registeredVotes[i];
            if (
                activeVote.startDate < block.timestamp &&
                activeVote.endDate > block.timestamp
            ) {
                activeVotes[j++] = activeVote;
            }
        }
        return activeVotes;
    }

    /// @inheritdoc	IGovernance
    function getFutureVotes()
        external
        view
        override
        whenNotPaused
        returns (Vote[] memory)
    {
        require(voteCounter > 0, "EXO: Vote Empty");
        Vote[] memory futureVotes;
        uint256 j = 0;
        for (uint256 i = 0; i < voteCounter; i++) {
            Vote storage tmp_vote = registeredVotes[i];
            if (tmp_vote.startDate > block.timestamp) {
                futureVotes[j++] = tmp_vote;
            }
        }
        return futureVotes;
    }

    /// @inheritdoc	IGovernance
    function getProposal(uint256 _voteId, uint256 _proposalId)
        external
        view
        override
        whenNotPaused
        returns (Proposal memory)
    {
        Vote memory targetVote = registeredVotes[_voteId];
        Proposal memory targetProposal = targetVote.proposals[_proposalId];
        return targetProposal;
    }

    /// @dev Pause contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev Unpause contract
    function unpause() public onlyOwner {
        _unpause();
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

/// @title interface for Governance logic
/// @author Tamer Fouad
interface IGovernance {
	/// @notice Struct for the vote
	/// @param index Vote index
	/// @param startDate Vote start date
	/// @param endDate Vote end date
	/// @param subject Vote subject
	/// @param proposalCount Proposal count
	/// @param lists Proposal array
	struct Vote {
		uint256 index;
		uint256 startDate;
		uint256 endDate;
		string subject;
		Proposal[] proposals;
	}

	/// @notice List: sub list of the vote
	/// @param title Vote list title
	/// @param voteCount Vote count
	struct Proposal {
		string title;
		uint256 voteCount;
	}

	/// @dev Emitted when a new vote created
	/// @param subject Subject string
	/// @param start Start date of the voting period
	/// @param end End date of the voting period
	/// @param timestamp created time
	event NewVote(string subject, uint256 start, uint256 end, uint256 timestamp);

	/// @dev Emitted when voter cast a vote
	/// @param voter voter address
	/// @param voteId vote id
	/// @param proposalId proposal id
	/// @param weight voting weight
	event VoteCast(
		address indexed voter,
		uint256 indexed voteId,
		uint256 weight,
		uint8 indexed proposalId
	);

    /// @dev Emitted when exo address updated
    /// @param _EXO_ADDRESS EXO token address
    event EXOAddressUpdated(address _EXO_ADDRESS);

    /// @dev Emitted when staking contract address updated
    /// @param _STAKING_ADDRESS staking contract address
    event StakingAddressUpdated(address _STAKING_ADDRESS);

	/**
	 * @notice Create a new vote
	 * @param _subject string subject
	 * @param _startDate Start date of the voting period
	 * @param _endDate End date of the voting period
	 * @param _proposals Proposal list
	 *
	 * Requirements
	 *
	 * - Only owner can create a new vote
	 * - Validate voting period with `_startDate` and `_endDate`
	 *
	 * Emits a {NewVote} event
	 */
	function createVote(
		string calldata _subject,
		uint256 _startDate,
		uint256 _endDate,
		string[] calldata _proposals
	) external;

	/**
	 * @notice Cast a vote
	 * @dev Returns a vote weight
	 * @param _voteId Vote Id
	 * @param _proposalId Proposal Id
	 * @return _weight Vote weight
	 *
	 * Requirements
	 *
	 * - Validate `_voteId`
	 * - Validate `_proposalId`
	 * - Check the voting period
	 *
	 * Emits a {VoteCast} event
	 */
	function castVote(uint256 _voteId, uint8 _proposalId)
		external
		returns (uint256);

	/**
	 * @dev Set EXO token address
	 * @param _EXO_ADDRESS EXO token address
     *
     * Emits a {EXOAddressUpdated} event
	 */
	function setEXOAddress(address _EXO_ADDRESS) external;

	/**
	 * @dev Set staking contract address
	 * @param _STAKING_ADDRESS staking contract address
     *
     * Emits a {StakingAddressUpdated} event
	 */
	function setStakingAddress(address _STAKING_ADDRESS) external;

	/// @dev Returns all votes in array
	/// @return allVotes All vote array
	function getAllVotes() external view returns (Vote[] memory);

	/// @dev Returns all active votes in array
	/// @return activeVotes Active vote array
	function getActiveVotes() external view returns (Vote[] memory);

	/// @dev Returns all future votes in array
	/// @return futureVotes Future array
	function getFutureVotes() external view returns (Vote[] memory);

	/// @dev Returns a specific proposal with `voteId` and `proposalId`
	/// @param _voteId Vote id
	/// @param _proposalId Proposal id
	/// @return proposal Proposal
	function getProposal(uint256 _voteId, uint256 _proposalId)
		external
		view
		returns (Proposal memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

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
interface IERC165 {
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

// File: contracts/IERC721Mintable.sol

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeMint(address to) external;

    function mint(address to, uint256 size) external returns(uint256 f, uint256 t);
}

// File: contracts/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    function mint(address to, uint256 amount) external;
}

// File: @openzeppelin/contracts/utils/Address.sol



/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: contracts/SafeERC20.sol



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// File: contracts/stakingGlobals.sol



/******************* Imports **********************/



/// @author NoBorderz
/// @notice Globals and utilities for staking contract
abstract contract GlobalsAndUtils {
    using SafeERC20 for IERC20;

    /******************* Events **********************/
    event StakeStart(address staker, uint256 stakeIndex, uint256 stakeAmount);
    event StakeEnd(address staker, uint256 stakeIndex, uint256 stakeAmount, uint256 penalty);
    event CampaignStarted(uint256 rewardCount, uint256 startTime, uint256 endTime);
    event CampaignEdited(uint256 startTime, uint256 endTime);
    event CampaignReward(uint256 campaignId, address collection, uint256 from, uint256 to, address user);
    event RuffleJoined(address user, uint256 campaignId, uint256 start, uint256 end);
    event Received(address operator, address from, uint256 tokenID);

    /******************* Modifiers **********************/
    modifier campaignEnded() {
        if (latestCampaignId > 0) {
            Campaign storage campaign = campaigns[latestCampaignId];
            require(campaign.endTime <= block.timestamp, "Campaign not ended yet");
        }
        _;
    }

    modifier CampaignOnGoing() {
        require(latestCampaignId > 0, "Campaign not initalized");
        Campaign memory campaign = campaigns[latestCampaignId];
        require(campaign.startTime <= block.timestamp, "campign not started");
        require(campaign.endTime > block.timestamp, "campign has ended");
        _;
    }

    modifier ClaimXTicketAllowed() {
        require(latestCampaignId > 0, "Campaign not initalized");
        Campaign memory campaign = campaigns[latestCampaignId];

        require(campaign.endTime + CLAIM_X_TICKET_DURATION >= block.timestamp, "claim ticket time ended");
        _;
    }

    modifier CalculateRewardAllowed() {
        require(latestCampaignId > 0, "Campaign not initalized");
        Campaign memory campaign = campaigns[latestCampaignId];

        require(campaign.endTime + CLAIM_X_TICKET_DURATION < block.timestamp, "claim x duration");
        _;
    }

    modifier checkCooldown() {
        require(!ON_COOLDOWN, "On cooldown");
        _;
    }

    /// @notice modifier to chec if user can claim penalty
    modifier allowedClaim(uint256 campaignId) {
        require(ON_COOLDOWN == true || (campaigns[latestCampaignId].startTime > block.timestamp && latestCampaignId > 1), "Campaign on going");
        require(!userClaimedPenalty[msg.sender][campaignId], "already claimed");
        _;
    }

    /******************* State Variables **********************/
    uint256 internal constant MIN_STAKE_DAYS = 14 days;
    uint256 internal constant COOLDOWN_PERIOD = 14 days;
    uint256 internal constant EARLY_UNSTAKE_PENALTY = 18;
    uint256 internal constant STAKING_TOKEN_DECIMALS = 1e18;
    uint256 internal constant CLAIM_X_TICKET_DURATION = 2 days;
    uint256 internal constant MIN_STAKE_TOKENS = 100 * STAKING_TOKEN_DECIMALS;

    /// @notice Variables for cooldown period
    bool internal ON_COOLDOWN;
    uint256 internal COOLDOWN_START;

    /// @notice This struct stores information regarding campaigns
    struct Campaign {
        uint256 rewardCount;
        uint256 startTime;
        uint256 endTime;
        address collection;
    }

    /// @notice Array to store campaigns.
    mapping(uint256 => Campaign) internal campaigns;

    /// @notice Stores the ID of the latest campaign
    uint256 internal latestCampaignId;

    /// @notice Stores the current total number of claimable xtickets.
    uint256 internal totalClaimableTickets;

    /// @notice This struct stores information regarding user's xtickets.
    struct UserXTickets {
        uint256 claimed;
        uint256 claimable;
        uint256 claimTime;
    }

    /// @notice Mapping to information regarding a user's xtickets against a stake id
    mapping(address => mapping(uint256 => UserXTickets)) public xTickets;

    /// @notice Mapping to store current total claimable tickets for a user
    mapping(address => mapping(uint256 => uint256)) internal totalUserXTickets;

    /// @notice Stores the Id of the latest stake.
    uint256 internal latestStakeId;

    /// @notice This struct stores information regarding a user stakes
    struct Stake {
        uint256 stakedAt;
        uint256 stakedAmount;
    }

    /// @notice Mapping to store user stakes.
    mapping(address => mapping(uint256 => Stake)) internal stakes;

    /// @notice Array to store users with active stakes
    address[] internal activeStakeOwners;

    /// @notice Mapping to store user stake ids in array
    mapping(address => uint256[]) internal userStakeIds;

    /// @notice This struct stores information regarding a user unstakes
    struct UnStake {
        uint256 stakedAt;
        uint256 unStakedAt;
        uint256 stakedAmount;
        uint256 penalty;
    }

    /// @notice Mapping to store user unstakes.
    mapping(address => mapping(uint256 => UnStake)) internal unStakes;

     /// @notice Mapping to store user unstake ids in array
    mapping(address => uint256[]) internal userUnStakeIds;

    /// @notice Mapping to store index of owner address in activeStakeOwners array
    mapping(address => uint256) internal stakeOwnerIndex;

    /// @notice Array for selected stake owners for picking winners
    address[] internal selectedStakeOwners;

    /// @notice Array to store current award winners
    address[] internal awardWinners;

    /// @notice Mapping to nftsIds user was awarded against a collection
    mapping(address => mapping(address => uint256[])) internal claimableAwards;

    /// @notice Mapping to store total number of awards received by a user
    mapping(address => mapping(uint256 => uint256)) internal rewardsReceived;

    /// @notice ERC20 Token for staking
    IERC20 public stakingToken;

    /// @notice ERC721 Token for awarding users NFTs
    IERC721 internal rewardsToken;

    /// @notice array of winning tickets ids against campaing id
    mapping(uint256 => uint256[]) internal winningTicketIds;

    struct XTicketRange {
        uint256 start;
        uint256 end;
    }

    /// @notice mapping for xticket range for each user
    mapping(address => mapping(uint256 => XTicketRange)) public userXTicketRange;

    uint256 internal randomSeed;

    

    /// @notice penalty accumalted for each campaign
    mapping(uint256 => uint256) public penaltyAccumulated;

    /// @notice Variable for storing total penalties claimed
    uint256 public totalPenaltiesClaimed;

    /// @notice struct for storing penalty history information
    struct penaltyHistory {
        uint256 releasedAt;
        uint256 totalStake;
        uint256 userStake;
        uint256 totalPenalty;
        uint256 penaltyClaimed;
        uint256 campaignId;
    }

    /// @notice mapping to store penalty history info against penalty history id
    mapping(address => mapping (uint256 => penaltyHistory)) public penaltyHistories;

    /// @notice Array for storing ids of user penalty withdraw ids
    mapping(address => uint256[]) public penaltyHistoryIds;

    /// @notice Variable to store total amount currently staked in the contract
    uint256 public totalStakedAmount;

    /// @notice Mapping to store total amount staked of a user
    mapping(address => uint256) internal userStakedAmount;

    /// @notice Mapping if user has already claimed for current campaign
    mapping(address => mapping(uint256 => bool)) internal userClaimedPenalty;

    /// @notice Mapping campaign id, ticket id
    mapping(uint256 => mapping (uint256=>bool)) public ticketIdUsed;

    /// @notice Mapping campaign id, ticket id
    mapping(uint256 => mapping (uint256=>bool)) public winningTixketIdExist;
}

// File: @openzeppelin/contracts/utils/Context.sol



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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/security/Pausable.sol



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// File: contracts/staking.sol



/******************* Imports **********************/






/// @title A Staking Contract
/// @author NoBorderz
/// @notice This smart contract serves as a staking pool where users can stake and earn rewards from loot boxes 
contract Staking is GlobalsAndUtils, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
    using SafeMath for uint256;

    constructor(address _stakingToken, address _rewardingToken) {
        require(_stakingToken != address(0), "Invalid staking token address");
        latestCampaignId = 1;
        latestStakeId = 2495;
        penaltyAccumulated[1] = 17964000000000000000000;
        totalStakedAmount = 17560900000000000000000000;
        campaigns[latestCampaignId] = Campaign(2300, 1659528000, 1660737600, 0x93b09BE6dF10DA1F48Ad2db7c911a2f8c36739eC);
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC721(_rewardingToken);
    }

    /**********************************************************/
    /******************* Public Methods ***********************/
    /**********************************************************/

    /**
     * @dev PUBLIC FACING: Open a stake.
     * @param stakedAmount Amount of tokens to stake
     */
    function stake(uint256 stakedAmount) whenNotPaused external nonReentrant CampaignOnGoing {
        require(stakingToken.balanceOf(msg.sender) >= stakedAmount, "user has insufficent tokens");
        require(stakedAmount.mod(MIN_STAKE_TOKENS) == 0, "staked tokens must be multiple of 100");

        bool resp = stakingToken.transferFrom(msg.sender, address(this), stakedAmount);
        if (!resp) revert("couldn't transfer tokens");

        _addStake(stakedAmount);

        totalStakedAmount += stakedAmount;
        userStakedAmount[msg.sender] += stakedAmount;

        emit StakeStart(msg.sender, latestStakeId, stakedAmount);
    }
 
    /**
     * @dev PUBLIC FACING: Closes a stake.
     * @param _stakeId ID of the stake to close
     */
    function unStake(uint256 _stakeId) whenNotPaused public {
        Stake memory usrStake = stakes[msg.sender][_stakeId];
        require(usrStake.stakedAmount > 0, "stake doesn't exist");

        _unStake(_stakeId);

        (uint256 payoutAmount, uint256 penaltyAmount) = _calcPayoutAndPenalty(usrStake);

        // Transfer payout amount to stake owner
        bool resp = stakingToken.transfer(msg.sender, payoutAmount);
        if (!resp) revert("couldn't transfer tokens");

        // Transfer penalty amount to DAO
        if (penaltyAmount > 0) {
            penaltyAccumulated[latestCampaignId] += penaltyAmount;
            unStakes[msg.sender][_stakeId].penalty = penaltyAmount;
        }

        userStakedAmount[msg.sender] -= usrStake.stakedAmount;
        
        emit StakeEnd(msg.sender, _stakeId, usrStake.stakedAmount, penaltyAmount);
    }

    /**
     * @dev EXTERNAL METHOD: Method for ending all stakes
     * and updating state accordingly
     */

     function unstakeAll() whenNotPaused external {
         uint256[] memory userStakeIdsTemp = userStakeIds[msg.sender];
         for (uint256 index = 0; index < userStakeIdsTemp.length; index++) {
             unStake(userStakeIdsTemp[index]);
         }
     }

    /**
     * @dev PUBLIC FACING: Returns an array of ids of user's active stakes
     * @param stakeOwner Address of the user to get the stake ids
     * @return Stake Ids
     */
    function getUserStakesIds(address stakeOwner) external view returns (uint256[] memory) {
        return userStakeIds[stakeOwner];
    }

    /**
     * @dev PUBLIC FACING: Returns an array of ids of user's  bonus history 
     * @param user Address of the user to get the stake ids
     * @return bonous claim history Ids
     */
    function getUserPenaltiesIds(address user) external view returns (uint256[] memory) {
        return penaltyHistoryIds[user];
    }

    /**
     * @dev PUBLIC FACING: Returns an array of ids of user's active stakes
     * @param stakeOwner Address of the user to get the stake ids
     * @return unStake Ids
     */
    function getUserUnStakesIds(address stakeOwner) external view returns (uint256[] memory) {
        return userUnStakeIds[stakeOwner];
    }

    /**
     * @dev PUBLIC FACING: Returns information about a specific stake
     * @param stakeOwner Address of the stake owner
     * @param stakeId ID of the stake
     * @return User stake
     */
    function getUnStake(address stakeOwner, uint256 stakeId) external view returns(UnStake memory) {
         
        return unStakes[stakeOwner][stakeId];
    }

    /**
     * @dev PUBLIC FACING: Returns information about a specific stake
     * @param stakeOwner Address of the stake owner
     * @param stakeId ID of the stake
     * @return User stake
     */
    function getStake(address stakeOwner, uint256 stakeId) external view returns(Stake memory, uint256) {
        return (stakes[stakeOwner][stakeId], userClaimable(stakeOwner, stakeId));
    }
    
    /**
     * @dev PUBLIC FACING: Returns information about a specific stake
     * @param stakeOwner Address of the stake owner
     * @param stakeId ID of the stake
     * @return User stake
     * this function is public now to check but it should be internal 
     */
    function userClaimable(address stakeOwner, uint256 stakeId) public view returns(uint256) {
         UserXTickets memory xticket = xTickets[stakeOwner][stakeId];
        Stake memory usrStake = stakes[stakeOwner][stakeId];
        uint256 stakedDays;
        if (
            campaigns[latestCampaignId].endTime == 0 ||
            // campaigns[latestCampaignId].endTime < block.timestamp ||
            campaigns[latestCampaignId].startTime > block.timestamp
        ) stakedDays = 0;
        else (, stakedDays) = _getUserStakedDays(usrStake);
       
        uint256 usrStakedAmount = usrStake.stakedAmount.div(STAKING_TOKEN_DECIMALS).div(100);
        uint256 claimableTickets = stakedDays.mul(usrStakedAmount);

        uint256 newTickets = totalUserXTickets[stakeOwner][latestCampaignId] == 0 ? claimableTickets : claimableTickets.sub(xticket.claimable);
        return newTickets;
    }

    /**
     * @dev PUBLIC FACING: Users can claim their
     * xtickets after staking for more than 24 hours
     * @return newClaimedTickets
     */
    function joinRuffle() whenNotPaused external ClaimXTicketAllowed returns (uint256 newClaimedTickets) {
        require(campaigns[latestCampaignId].endTime < block.timestamp && campaigns[latestCampaignId].endTime != 0, "can't claim");
        require( totalUserXTickets[msg.sender][latestCampaignId] == 0, "already claimed");
         userXTicketRange[msg.sender][latestCampaignId].start = totalClaimableTickets + 1;
         XTicketRange storage tempRange = userXTicketRange[msg.sender][latestCampaignId];
        newClaimedTickets = 0;
        for (uint256 x=0; x < userStakeIds[msg.sender].length; x++) {
            newClaimedTickets += _getClaimableXTickets(msg.sender, userStakeIds[msg.sender][x]);
        }
         userXTicketRange[msg.sender][latestCampaignId].end = totalClaimableTickets;
         require(tempRange.start <= totalClaimableTickets, "no tickets earned");
         emit RuffleJoined(msg.sender, latestCampaignId, tempRange.start, totalClaimableTickets);

    }

     /**
     * @dev INTERNAL METHOD: Update number of
     * claimable tickets a user currently has
     * and add it to the total claimable tickets
     * @param _stakeOwner Address of owner of the stake
     * @param _stakeId Id of the stake
     * @return Number of tickets claimed against stake
     */
    function _getClaimableXTicketsView(address _stakeOwner, uint256 _stakeId) private view returns(uint256) {
        Stake memory usrStake = stakes[_stakeOwner][_stakeId];
        uint256 usrStakedAmount = usrStake.stakedAmount.div(STAKING_TOKEN_DECIMALS).div(100);
        return usrStakedAmount;
    }

      /**
     * @dev PUBLIC FACING: Users can claim their
     * xtickets after staking for more than 24 hours
     * @return newClaimedTickets
     */
    function perDayXTicketsUserClaimable() public view checkCooldown returns (uint256 newClaimedTickets) {
        newClaimedTickets = 0;
        for (uint256 x=0; x < userStakeIds[msg.sender].length; x++) {
            newClaimedTickets += _getClaimableXTicketsView(msg.sender, userStakeIds[msg.sender][x]);
        }
        
    }

    /**
     * @dev PUBLIC FACING: Users can claim their rewards (if any)
     */
    function claimStakingReward(uint256 campaignId, uint256[] memory tickets) whenNotPaused  external {
        require(rewardsReceived[msg.sender][campaignId] == 0, "already claimed");
        
        _rewardWinner(msg.sender,campaignId, tickets);
    }

    /**
     * @dev PUBLIC FACING: Array of users that have active stakes
     * @return activeStakeOwners
     */
    function getActiveStakers() external view returns(address[] memory) {
        return activeStakeOwners;
    }

    /**
     * @dev PUBLIC FACING: Get details of the current campaign
     * @return campaignId
     * @return rewardCount
     * @return startTime
     * @return endTime
     */
    function getCurrentCampaignDetails() external view returns(uint256 campaignId, uint256 rewardCount, uint256 startTime, uint256 endTime, uint256 coolDown, uint256 ruffleTime) {
        campaignId = latestCampaignId;
        rewardCount = campaigns[latestCampaignId].rewardCount;
        startTime = campaigns[latestCampaignId].startTime;
        endTime = campaigns[latestCampaignId].endTime;
        coolDown = COOLDOWN_PERIOD;
        ruffleTime = CLAIM_X_TICKET_DURATION;
    }

    /**
     * @dev PUBLIC FACING: Get number of claimed tickets by a user
     * @return newClaimedTickets
     */
    function getClaimableTickets() external view returns(uint256 newClaimedTickets) {
          newClaimedTickets = 0;
        if( totalUserXTickets[msg.sender][latestCampaignId] > 0){
            newClaimedTickets =  0;
        }else {
            uint256 length = userStakeIds[msg.sender].length;
            uint256[] memory idsArray = userStakeIds[msg.sender];
            for (uint256 x=0; x < length; x++) {
            newClaimedTickets += userClaimable(msg.sender, idsArray[x]);
        }
        }
        
    }

    /**
     * @dev PUBLIC FACING: Claim penalty Bonus
     */
    function claimTaxBonus() whenNotPaused external nonReentrant  {
        require(userStakedAmount[msg.sender] > 0, "user has no stakes");
         uint256 campaignId = campaigns[latestCampaignId].startTime > block.timestamp && latestCampaignId > 1 ? latestCampaignId - 1 : latestCampaignId;
        uint256 stakerPenaltyBonus = _stakerPenaltyBonus(msg.sender, campaignId);
         totalPenaltiesClaimed += 1;
        penaltyHistoryIds[msg.sender].push(totalPenaltiesClaimed);
        penaltyHistories[msg.sender][totalPenaltiesClaimed] = penaltyHistory(block.timestamp, totalStakedAmount, userStakedAmount[msg.sender], penaltyAccumulated[campaignId], stakerPenaltyBonus, campaignId);
        penaltyAccumulated[campaignId] -= stakerPenaltyBonus;
        userClaimedPenalty[msg.sender][campaignId] = true;
        bool resp = stakingToken.transfer(msg.sender, stakerPenaltyBonus);
        if (!resp) revert("couldn't transfer tokens");
    }

    

    /**
     * @dev PUBLIC METHOD: Method to get a nftID
     * from a collection
     */
    function getRewardClaimable(uint256 campaignId) public view  returns(uint256[] memory, uint256, uint256, uint256, uint256, uint256) {
        return (getXTicektedIDs(campaignId), campaigns[campaignId].rewardCount, campaigns[campaignId].startTime, campaigns[campaignId].endTime, rewardsReceived[msg.sender][campaignId], totalUserXTickets[msg.sender][campaignId]);
    }

    /**
     * @dev INTERNAL METHOD: Method to get a nftID
     * from a collection
     * @return stakerPenaltyBonus
     */
    function getWinningTickIds(uint256 campaignId) public view returns(uint256[] memory) {
        return winningTicketIds[campaignId];
    }

   


    /**********************************************************/
    /******************* Admin Methods ************************/
    /**********************************************************/

    /**
     * @dev ADMIN METHOD: Start a campaign.
     * @param startTime Time at which the campaign will start
     * @param endTime Time at which the campaign will end
     * @param rewardCount Total number of rewards in the campaign
     */
    function startLootBox(uint256 startTime, uint256 endTime, uint256 rewardCount, address _awardCollection) external onlyOwner campaignEnded {
        require(startTime >= block.timestamp, "start cannot be in past");
        require(startTime < endTime, "cannot end before start");

        rewardsToken = IERC721(_awardCollection);

        // end cooldown period
        _endCooldown();

        // start a new campaign
        latestCampaignId += 1;
        campaigns[latestCampaignId] = Campaign(rewardCount, startTime, endTime, _awardCollection);

        emit CampaignStarted(rewardCount, startTime, endTime);
    }

    /**
     * @dev ADMIN METHOD: Start a campaign.
     * @param startTime Time at which the campaign will start
     * @param endTime Time at which the campaign will end
     */
    function editLootBox(uint256 startTime, uint256 endTime) external onlyOwner {
       
       
        require(startTime >= block.timestamp, "start cannot be in past");
        require(startTime < endTime, "cannot end before start");

        
        campaigns[latestCampaignId].startTime = startTime;
        campaigns[latestCampaignId].endTime = endTime;

        

        emit CampaignEdited(startTime, endTime);
    }

    /**
     * @dev ADMIN METHOD: Pick winners from who have xtickets
     */
    function rewardLootBox(uint256 start, uint256 end) external onlyOwner CalculateRewardAllowed {
        require(end <= campaigns[latestCampaignId].rewardCount, "end > rewardCount");

        // for first iteration start must be 0
        _pickWinners(start, end);
    }

    /**
     * @dev ADMIN METHOD: Set seed
     */
    function setSeed(uint256 seed) external onlyOwner campaignEnded {
        randomSeed = seed;
         _startCooldown();
    }

    /**
     * @dev ADMIN METHOD: Add collections to a campaign
     * @param _collection Array of collections to add to the campaign
     */
    function updateRewardCollection(address _collection) external onlyOwner {
        require(_collection != address(0), "invalid collection address");
        rewardsToken = IERC721(_collection);
    }

    /**
     * @dev ADMIN METHOD: Withdraw total tokens in contract
     * @param receiver Address of the user to transfer the nft to
     */
    function emergencyWithdrawStakedAmount(address receiver, uint256 campaignId) external onlyOwner campaignEnded {
        require(totalStakedAmount + penaltyAccumulated[campaignId] > 0, "not enough amount in contract");
        require(receiver != address(0), "invalid address");

        bool resp = stakingToken.transfer(receiver, totalStakedAmount + penaltyAccumulated[campaignId]);
        if (!resp) revert("couldn't transfer tokens");
    }

    /**
     * @dev ADMIN METHOD: Withdraw penalty amount
     * @param _amount amount to withdraw
     * @param receiver Address of the user to transfer the nft to
     */
    function withdrawPenaltyAmount(uint256 _amount, address receiver, uint256 campaignId) external onlyOwner {
        require(_amount <= penaltyAccumulated[campaignId], "not enough tokens in contract");
        require(receiver != address(0), "invalid receiver");
        bool resp = stakingToken.transfer(receiver, _amount);
        if (!resp) revert("couldn't transfer tokens");
    }

     /**
     * @dev ADMIN METHOD: Method to update staking token address
     */
    function updateStakingToken(address _stakingToken) external onlyOwner {
        require(_stakingToken != address(0), "invalid address");
        stakingToken = IERC20(_stakingToken);
    }

    function migrateStakingState(
        address[] memory _addresses,
        uint256[] memory _stakeIds,
        uint256[] memory _stakedAmounts,
        uint256[] memory _stakedAtArray
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address _staker = _addresses[i];
            uint256 _stakeId = _stakeIds[i];
            uint256 _stakedAmount = _stakedAmounts[i];
            stakes[_staker][_stakeId] = Stake(_stakedAtArray[i], _stakedAmount);
            userStakeIds[_staker].push(_stakeId);
            userStakedAmount[_staker] += _stakedAmount;
            emit StakeStart(_staker, _stakeId, _stakedAmount);
        }
    }

    function migrateUnstakingState(
        address[] memory _addresses,
        uint256[] memory _unstakeIds,
        uint256[] memory _stakedAtArray,
        uint256[] memory _unstakedAtArray,
        uint256[] memory _unstakedAmountArray,
        uint256[] memory _penaltyArray
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address staker = _addresses[i];
            uint256 stakeId = _unstakeIds[i];
            unStakes[staker][stakeId] = UnStake(
                _stakedAtArray[i],
                _unstakedAtArray[i],
                _unstakedAmountArray[i],
                _penaltyArray[i]
            );
            userUnStakeIds[staker].push(stakeId);
            emit StakeEnd(staker, stakeId, _unstakedAmountArray[i], _penaltyArray[i]);
        }
    }

    function migrateOtherState(
        address[] memory activeStakers,
        address[] memory stakersAddress,
        uint256[] memory stakersIndex
    ) external onlyOwner {
        for (uint256 i = 0; i < activeStakers.length; i++) {
            activeStakeOwners.push(activeStakers[i]);
        }

        for (uint256 j = 0; j < stakersAddress.length; j++) {
            stakeOwnerIndex[stakersAddress[j]] = stakersIndex[j];
        }
    }

    function migrateXticketsRange(address[] memory _stakers, uint256[] memory _rangesStart, uint256[] memory _rangesEnd, uint256 _campaignId) external onlyOwner {
        for (uint256 i = 0; i < _stakers.length; i++) {
            userXTicketRange[_stakers[i]][_campaignId].start = _rangesStart[i];
            userXTicketRange[_stakers[i]][_campaignId].end = _rangesEnd[i];

            totalUserXTickets[_stakers[i]][_campaignId] = _rangesEnd[i] - _rangesStart[i];
        }
    }

    /**********************************************************/
    /******************* Private Methods **********************/
    /**********************************************************/

    /**
     * @dev INTERNAL METHOD: Start cooldown period
     */
    function _startCooldown() private {
        ON_COOLDOWN = true;
        COOLDOWN_START = block.timestamp;
    }

    /**
     * @dev INTERNAL METHOD: End cooldown period
     */
    function _endCooldown() private {
        ON_COOLDOWN = false;
        COOLDOWN_START = 0;

        // reset campaign details
        delete selectedStakeOwners;
        delete awardWinners;
        totalClaimableTickets = 0;
    }

    /**
     * @dev INTERNAL METHOD: Method for starting stake
     * and updating state accordingly
     * @param stakedAmount Amount of tokens staked
     */
    function _addStake(uint256 stakedAmount) private {
        latestStakeId += 1;
        stakes[msg.sender][latestStakeId] = Stake(block.timestamp, stakedAmount);
        userStakeIds[msg.sender].push(latestStakeId);

        // update index of user address in activeStakeOwners to stakeOwnerIndex
        if (activeStakeOwners.length == 0) {
            activeStakeOwners.push(msg.sender);
            stakeOwnerIndex[msg.sender] = 0;
        } else if (activeStakeOwners.length > 0 && activeStakeOwners[stakeOwnerIndex[msg.sender]] != msg.sender) {
            activeStakeOwners.push(msg.sender);
            stakeOwnerIndex[msg.sender] = activeStakeOwners.length - 1;
        }
    }

    /**
     * @dev INTERNAL METHOD: Method for ending stake
     * and updating state accordingly
     * @param _stakeId ID of the stake to unstake
     */
    function _unStake(uint256 _stakeId) private {
        // Remove stake id from users' stakIdArray
        if (userStakeIds[msg.sender].length > 1) {
            for (uint256 x = 0; x < userStakeIds[msg.sender].length; x++) {
                // find the index of stake id in userStakes
                if (userStakeIds[msg.sender][x] == _stakeId) {
                    if (userStakeIds[msg.sender].length > 1) {
                        userStakeIds[msg.sender][x] = userStakeIds[msg.sender][userStakeIds[msg.sender].length.sub(1)];
                        userStakeIds[msg.sender].pop();
                    } else {
                        userStakeIds[msg.sender].pop();
                    }
                }
            }
        } else {
            userStakeIds[msg.sender].pop();
        }

        // Remove address from current stake owner's array number if stakes are zero
        if (userStakeIds[msg.sender].length == 0) {
            if (activeStakeOwners.length > 1) {
                // replace address to be removed by last address to decrease array size
                activeStakeOwners[stakeOwnerIndex[msg.sender]] = activeStakeOwners[activeStakeOwners.length.sub(1)];

                // set the index of replaced address in the stakeOwnerIndex mapping to the removed index
                stakeOwnerIndex[activeStakeOwners[activeStakeOwners.length.sub(1)]] = stakeOwnerIndex[msg.sender];

                // remove address from last index
                activeStakeOwners.pop();
            } else {
                // set the index of replaced address in the stakeOwnerIndex mapping to the removed index
                stakeOwnerIndex[activeStakeOwners[activeStakeOwners.length.sub(1)]] = stakeOwnerIndex[msg.sender];

                // remove address from last index
                activeStakeOwners.pop();
            }

            // set the index of removed address to zero
            stakeOwnerIndex[msg.sender] = 0;
        }

        // remove staked amount from total staked amount
        totalStakedAmount -= stakes[msg.sender][_stakeId].stakedAmount;

        userUnStakeIds[msg.sender].push(_stakeId);

        unStakes[msg.sender][_stakeId] = UnStake(stakes[msg.sender][_stakeId].stakedAt,block.timestamp,stakes[msg.sender][_stakeId].stakedAmount, 0);

        // Remove user's stake values
        delete stakes[msg.sender][_stakeId];
    }

    /**
     * @dev INTERNAL METHOD: Return staked time of
     * a user in unix timestamp and days
     * @param usrStake Instance of stake to get time of
     */
    function _getUserStakedTime(Stake memory usrStake) private view returns (uint256 unixStakedTime) {
        unixStakedTime =  block.timestamp.sub(usrStake.stakedAt > campaigns[latestCampaignId].startTime || campaigns[latestCampaignId].startTime > block.timestamp ? usrStake.stakedAt : campaigns[latestCampaignId].startTime);
    }

     /**
     * @dev INTERNAL METHOD: Return staked time of
     * a user in unix timestamp and days
     * @param usrStake Instance of stake to get time of
     */
    function _getUserStakedDays(Stake memory usrStake) private view returns (uint256 unixStakedTime, uint256 stakedDays) {
        uint256 stakedTime = usrStake.stakedAt;
        uint256 nowTime = block.timestamp;
        Campaign storage tempCampaign = campaigns[latestCampaignId];
        if( nowTime > tempCampaign.startTime && tempCampaign.startTime > usrStake.stakedAt)
        {
            stakedTime = tempCampaign.startTime;
        }
        if(stakedTime < tempCampaign.endTime && block.timestamp > tempCampaign.endTime &&  tempCampaign.endTime != 0){
            nowTime  = tempCampaign.endTime;
        }
        unixStakedTime = nowTime.sub(stakedTime);
        stakedDays = unixStakedTime.div(1 days);
    }

    /**
     * @dev INTERNAL METHOD: Update number of
     * claimable tickets a user currently has
     * and add it to the total claimable tickets
     * @param _stakeOwner Address of owner of the stake
     * @param _stakeId Id of the stake
     * @return Number of tickets claimed against stake
     */
    function _getClaimableXTickets(address _stakeOwner, uint256 _stakeId) private returns(uint256) {
        UserXTickets storage xticket = xTickets[_stakeOwner][_stakeId];
        Stake memory usrStake = stakes[_stakeOwner][_stakeId];
        uint256 stakedDays;
        if (
            campaigns[latestCampaignId].endTime == 0 ||
            // campaigns[latestCampaignId].endTime < block.timestamp ||
            campaigns[latestCampaignId].startTime > block.timestamp
        ) stakedDays = 0;
        else (, stakedDays) = _getUserStakedDays(usrStake);
        
        uint256 usrStakedAmount = usrStake.stakedAmount.div(STAKING_TOKEN_DECIMALS).div(100);
        uint256 claimableTickets = stakedDays.mul(usrStakedAmount);

        uint256 newTickets = claimableTickets;

        xticket.claimable = claimableTickets;
        // update total number of claimable tickets
        totalClaimableTickets += newTickets;

        totalUserXTickets[msg.sender][latestCampaignId] = totalUserXTickets[msg.sender][latestCampaignId] + newTickets;

        return xticket.claimable;
    }

    /**
     * @dev INTERNAL METHOD: Calculate payout and penalty
     * @param usrStake Instance of stake to calculate payout and penalty of
     * @return payout
     * @return penalty
     */
    function _calcPayoutAndPenalty(Stake memory usrStake) private view returns(uint256 payout, uint256 penalty) {
        (uint256 unixStakedTime) = _getUserStakedTime(usrStake);

        if (unixStakedTime >= MIN_STAKE_DAYS) {
            penalty = 0;
            payout = usrStake.stakedAmount;
        } else {
            penalty = _calcPenalty(usrStake.stakedAmount);
            payout = usrStake.stakedAmount.sub(penalty);
        }
    }  

    /**
     * @dev INTERNAL METHOD: Calculate penalty if
     * user unstakes before min stake period
     * @param _totalAmount total staked amount
     * @return payout
     */
    function _calcPenalty(uint256 _totalAmount) private pure returns(uint256 payout) {
        return _totalAmount.mul(EARLY_UNSTAKE_PENALTY).div(100);
    }

    /**
     * @dev INTERNAL METHOD: Method to reward winner nfts
     * @param _winnerAddress address of the winner to transfer nfts to
     */
    function _rewardWinner(address _winnerAddress, uint256 campaignId, uint256[] memory tickets) private {
         uint256 rangeStart = userXTicketRange[_winnerAddress][campaignId].start;
       uint256 rangeEnd = userXTicketRange[_winnerAddress][campaignId].end;
        for (uint256 j = 0; j < tickets.length; j++) {
            uint256 winningTicketId = tickets[j];
            if(rewardsReceived[_winnerAddress][campaignId] >= 5){
                break;
            }
            if(winningTicketId >= rangeStart && winningTicketId <= rangeEnd){
                if(!ticketIdUsed[campaignId][winningTicketId] && winningTixketIdExist[campaignId][winningTicketId]){
                    ticketIdUsed[campaignId][winningTicketId] = true;
                    rewardsReceived[_winnerAddress][campaignId] += 1;
                }
            }
        }

        require(rewardsReceived[_winnerAddress][campaignId] > 0, "no reward");
        rewardsToken = IERC721(campaigns[campaignId].collection);
        (uint256 from, uint256 to) = rewardsToken.mint(msg.sender,  rewardsReceived[_winnerAddress][campaignId]);
        if (from == 0 || to == 0) revert("couldn't mint");
        emit CampaignReward(campaignId, address(rewardsToken), from, to, msg.sender);
    }    

    /**
     * @dev INTERNAL METHOD: Method for getting random
     * numbers between a range from a seed
     * @param ranEnd Limit from which to get random numbers from
     */
    function _getRandomNumbers(uint256 ranEnd, uint256 start, uint256 end) internal {
        uint256 tempNumber;
        for (uint256 i = start; i < end; i++) {
            tempNumber = uint256(keccak256(abi.encode(randomSeed, i, block.timestamp))) % ranEnd + 1;
            winningTicketIds[latestCampaignId].push(tempNumber);
            winningTixketIdExist[latestCampaignId][tempNumber] = true;
        }
    }

    /**
     * @dev INTERNAL METHOD: Method called by VRFConsumer
     * to pick winners using a random seed.
     */
    function _pickWinners(uint256 start, uint256 end) private {
        selectedStakeOwners = activeStakeOwners;

        uint256 N_REWARD_WINNER = campaigns[latestCampaignId].rewardCount;
        require(end <= N_REWARD_WINNER, "invalid end");
        require(start < end , "invalid end");

        if (totalClaimableTickets == 0) {
            revert("No tickets claimed till yet");
        }
        
        _getRandomNumbers(totalClaimableTickets, start, end);
    }

    /**
     * @dev INTERNAL METHOD: Method to get a nftID
     * from a collection
     * @return userXticketsIds
     */
    function getXTicektedIDs(uint256 campaignId) private view  returns(uint256[] memory) {
        if(rewardsReceived[msg.sender][campaignId] > 0){
            uint256[] memory tempArray;
            return tempArray;
        }
         uint256 rangeStart = userXTicketRange[msg.sender][campaignId].start;
       uint256 rangeEnd =  userXTicketRange[msg.sender][campaignId].end;
       uint256[] memory _winningTicketIds = winningTicketIds[campaignId];
       uint256 count;
        for (uint256 j; j < _winningTicketIds.length; j++) {
            uint256 winningTicketId = _winningTicketIds[j];
           if(winningTicketId >= rangeStart && winningTicketId <= rangeEnd){
                count++;
           }
        }
        uint256 i;
        uint256[] memory _userXticketsIds = new uint256[](count);
        for (uint256 j; j < _winningTicketIds.length; j++) {
            uint256 winningTicketId = _winningTicketIds[j];
           if(winningTicketId >= rangeStart && winningTicketId <= rangeEnd){
                _userXticketsIds[i] = winningTicketId;
                i++;
           }
        }
        return _userXticketsIds;
    }

    /**
     * @dev INTERNAL METHOD: Method to get a nftID
     * from a collection
     * @return stakerPenaltyBonus
     */
    function getClaimableToken() public view returns(uint256 stakerPenaltyBonus) {
         uint256 campaignId = campaigns[latestCampaignId].startTime > block.timestamp && latestCampaignId > 1 ? latestCampaignId - 1 : latestCampaignId;
        
        stakerPenaltyBonus = userClaimedPenalty[msg.sender][latestCampaignId] ? 0 : _stakerPenaltyBonus(msg.sender, campaignId);
    }

    


    /**
     * @dev INTERNAL METHOD: Get amount user has in the total penalty amount
     * @param _staker address of the staker
     */
    function _stakerPenaltyBonus(address _staker, uint256 campaignId) allowedClaim(campaignId) private view returns (uint256) {
        uint256 stakerBonusPenalty = 0;

        // staker percentage in total penaltyBonus
        uint256 stakerPercentage = userStakedAmount[_staker].mul(1000000).div(totalStakedAmount);

        require(stakerPercentage > 0, "user doesn't have any percentage in penalty bonus");

        // calculate penaltyBonus percentages
        uint256 currentPenaltyAccumulated = penaltyAccumulated[campaignId];
        uint256 bonusThirtyPercent = currentPenaltyAccumulated.mul(30).div(100);
        uint256 bonusTwentyFivePercent = currentPenaltyAccumulated.mul(25).div(100);
        uint256 bonusTwentyPercent = currentPenaltyAccumulated.mul(20).div(100);

        // get time in days of the first staker's stake
        (uint256 unixStakedTime) = block.timestamp.sub(stakes[msg.sender][userStakeIds[msg.sender][0]].stakedAt);
        uint256 stakedDays = unixStakedTime.div(1 days);

        if (stakedDays >= 360) {
            stakerBonusPenalty += bonusTwentyFivePercent.mul(stakerPercentage).div(1000000);
        } else if (stakedDays >= 180) {
            stakerBonusPenalty += bonusTwentyFivePercent.mul(stakerPercentage).div(1000000);
        } else if (stakedDays >= 90) {
            stakerBonusPenalty += bonusTwentyPercent.mul(stakerPercentage).div(1000000);
        }

         stakerBonusPenalty += bonusThirtyPercent.mul(stakerPercentage).div(1000000);
        
        return stakerBonusPenalty;
    }

    /**********************************************************/
    /************* ERC721Reciever Implementation **************/
    /**********************************************************/
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external override returns(bytes4) {
        _operator;
        _from;
        _tokenId;
        _data;
        emit Received(_operator, _from, _tokenId);
        return 0x150b7a02;
    }
}
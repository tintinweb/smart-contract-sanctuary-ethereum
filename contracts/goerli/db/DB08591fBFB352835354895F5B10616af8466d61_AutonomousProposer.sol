// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../utils/CommonChecks.sol";

import "../interfaces/IAutonomousProposer.sol";
import "../interfaces/governor/IEgoGovernorV1.sol";

contract AutonomousProposer is IAutonomousProposer, CommonChecks, ERC165 {
    using SafeERC20 for IERC20;

    /// @notice `EGO` token contract address
    IERC20 public immutable token;
    /// @notice `EgoGovernor` contract address
    IEgoGovernorV1 public immutable governor;
    /// @notice Minimum Ego tokens required to create a autonomous proposal
    uint public immutable stakeAmount;

    /// @notice The proposal authors
    mapping(uint => address) public users;

    /**
     * @notice Construct a factory for autonomous proposals
     * @param _token `EGO` token contract address
     * @param _governor `EgoGovernor` contract address
     * @param _stakeAmount The minimum amount of EGO tokes required for creation of a autonomous proposal
     */
    constructor(
        address _token,
        address _governor,
        uint _stakeAmount
    ) notZeroAddress(_token) notZeroAddress(_governor) {
        require(
            IERC165(_governor).supportsInterface(
                type(IEgoGovernorV1).interfaceId
            ),
            "AP: UNSUPPORTED_INTERFACE"
        );

        token = IERC20(_token);
        governor = IEgoGovernorV1(_governor);
        stakeAmount = _stakeAmount;
    }

    /**
     * @notice Create a new autonomous proposal
     * @notice Call `EGO.approve(AutonomousProposer.address, stakeAmount)` before calling this method
     * @param _targets The ordered list of target addresses for calls to be made
     * @param _values The ordered list of values (i.e. msg.value) to be passed to the calls to be made
     * @param _signatures function signatures for proposal calls
     * @param _calldatas The ordered list of calldata to be passed to each call
     * @param _description The block at which voting begins: holders must delegate their votes prior to this block
     */
    function create(
        address[] memory _targets,
        uint[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) external {
        // Stake EGO and force proposal to delegate votes to itself
        token.safeTransferFrom(msg.sender, address(this), stakeAmount);

        // Create governance proposal and save proposal id
        uint govProposalId = governor.proposeAutonomous(
            _targets,
            _values,
            _signatures,
            _calldatas,
            _description,
            msg.sender
        );

        users[govProposalId] = msg.sender;

        emit AutonomousProposalCreated(
            msg.sender,
            govProposalId,
            _targets,
            _values,
            _signatures,
            _calldatas,
            _description
        );
    }

    /**
     * @notice Cancel the autonomous proposal, send back staked EGO tokens
     * @param _proposalId ID of proposal to be cancelled
     */
    function cancel(uint _proposalId) external {
        require(users[_proposalId] == msg.sender, "AP: INVALID_AUTHOR");

        users[_proposalId] = address(0);

        governor.cancelProposal(_proposalId);

        // Transfer staked EGO tokens back to the author
        token.safeTransfer(msg.sender, stakeAmount);

        emit AutonomousProposalCancelled(_proposalId, msg.sender);
    }

    /**
     * @notice Withdraw staked EGO's back if proposal finished or was rejected by admin
     * @param _proposalId ID of proposal
     */
    function withdraw(uint _proposalId) external {
        require(msg.sender == users[_proposalId], "AP: INVALID_AUTHOR");

        IEgoGovernorV1.ProposalState status = governor.state(_proposalId);
        require(
            status == IEgoGovernorV1.ProposalState.Rejected ||
                status == IEgoGovernorV1.ProposalState.Defeated ||
                status == IEgoGovernorV1.ProposalState.Succeeded,
            "AP: NOT_FINISHED"
        );

        users[_proposalId] = address(0);

        // Transfer staked EGO tokens back to the author
        token.safeTransfer(msg.sender, stakeAmount);

        emit Withdraw(_proposalId, msg.sender, stakeAmount);
    }

    /**
     * @dev Check contract supports provided interface
     * @param _interfaceId id of the interface
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            _interfaceId == type(IAutonomousProposer).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface IEgoGovernorV1 {
    enum ProposalState {
        Succeeded, // vote successful
        Defeated, // vote didn't reach quorum
        Active, // voting ongoing
        Pending, // voting didn't start
        Cancelled, // can be cancelled by proposer
        Rejected, // can be rejected by DAO admin
        NotExist // proposal doesn't exist
    }

    enum VoteType {
        Against,
        For
    }

    struct Proposal {
        address account; // 160
        uint32 voteStart; // 160 + 64 = 224
        uint32 voteEnd; // 64
        uint32 extendedDeadline; // 128
        bool rejected; // 136
        bool cancelled; // 144
        uint againstVotes;
        uint forVotes;
    }

    // Params for initialize function
    struct InitializeParams {
        address accessRegistry;
        address token;
        uint quorumNumerator;
        uint autonomousQuorumNumerator;
        uint denominator;
        uint32 votingDelay;
        uint32 votingPeriod;
        uint32 preventLateQuorum;
        uint32 blocksPerProposals;
        uint proposalThreshold;
    }

    event ProposalCreated(
        uint indexed proposalId,
        address indexed proposer,
        address[] targets,
        uint[] values,
        string[] signatures,
        bytes[] calldatas,
        uint startBlock,
        uint endBlock,
        string description
    );
    event SetQuorumNumerator(uint newQuorumNumerator);
    event SetAutonomousQuorumNumerator(uint newAutonomousQuorumNumerator);
    event SetDenominator(uint newDenominator);
    event SetVotingDelay(uint32 newVotingDelay);
    event SetVotingPeriod(uint32 newVotingPeriod);
    event SetPreventLateQuorum(uint32 newPreventLateQuorum);
    event SetProposalThreshold(uint newProposalThreshold);
    event SetBlocksPerProposals(uint blocksPerProposals);
    event ProposalExtended(uint indexed proposalId, uint32 extendedDeadline);
    event ProposalRejected(uint proposalId);
    event ProposalCancelled(uint proposalId);
    event VoteCast(
        address indexed voter,
        uint proposalId,
        VoteType vote,
        uint weight,
        string reason
    );

    function proposals(uint _proposalId)
        external
        view
        returns (
            address account,
            uint32 voteStart,
            uint32 voteEnd,
            uint32 extendedDeadline,
            bool rejected,
            bool cancelled,
            uint againstVotes,
            uint forVotes
        );

    function hashProposal(
        address[] memory _targets,
        uint[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) external pure returns (uint);

    function state(uint _proposalId) external view returns (ProposalState);

    function votingDelay() external view returns (uint32);

    function proposalThreshold() external view returns (uint);

    function votingPeriod() external view returns (uint32);

    function quorumNumerator() external view returns (uint);

    function blocksPerProposals() external view returns (uint32);

    function propose(
        address[] memory _targets,
        uint[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) external returns (uint proposalId);

    function proposeAutonomous(
        address[] memory _targets,
        uint[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description,
        address _account
    ) external returns (uint proposalId);

    function cancelProposal(uint _proposalId) external;

    function castVote(
        uint _proposalId,
        VoteType _vote,
        string calldata _reason
    ) external returns (uint balance);

    function quorumReached(uint _proposalId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface IAutonomousProposer {
    /// @notice An event emitted when a crowd proposal is created
    event AutonomousProposalCreated(
        address indexed author,
        uint indexed proposalId,
        address[] targets,
        uint[] values,
        string[] signatures,
        bytes[] calldatas,
        string description
    );

    /// @notice An event emitted when the crowd proposal is terminated
    event AutonomousProposalCancelled(
        uint indexed proposalId,
        address indexed author
    );

    /// @notice An event emitted when proposer withdraw his staked EGO's back after proposal rejection
    event Withdraw(
        uint indexed proposalId,
        address indexed account,
        uint amount
    );

    function create(
        address[] memory _targets,
        uint[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) external;

    function cancel(uint _proposalid) external;

    function withdraw(uint _proposalid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

abstract contract CommonChecks {
    modifier notZeroAddress(address _addr) {
        require(_addr != address(0), "CommonChecks: ZERO_ADDRESS");
        _;
    }

    modifier notEmptyString(string memory _str) {
        require(bytes(_str).length > 0, "CommonChecks: STRING_IS_EMPTY");
        _;
    }
}
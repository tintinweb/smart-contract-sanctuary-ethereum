// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: BSD-3-Clause

/// @title Tomi DAO Logic interfaces and events

// LICENSE
// TomiDAOInterfaces.sol is a modified version of Compound Lab's GovernorBravoInterfaces.sol:
// https://github.com/compound-finance/compound-protocol/blob/b9b14038612d846b83f8a009a82c38974ff2dcfe/contracts/Governance/GovernorBravoInterfaces.sol
//
// GovernorBravoInterfaces.sol source code Copyright 2020 Compound Labs, Inc. licensed under the BSD-3-Clause license.
//
// Additional conditions of BSD-3-Clause can be found here: https://opensource.org/licenses/BSD-3-Clause

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TomiDAOEvents {
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startTime,
        uint256 endTime,
        string title,
        string description,
        uint256 quorumVotes,
        uint256 consensusVotes
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes, uint256 proposalState);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 proposalId);

    /// @notice An event emitted when a proposal has been executed in the TomiDAOExecutor
    event ProposalExecuted(uint256 proposalId);

    /// @notice Emitted when fees are transferred for proposals
    event ProposalFee(address proposer, uint256 amount);

    /// @notice Emitted when proposalMinAmountNFTs is changed
    event ProposalMinAmountNFTs(uint256 oldProposalMinAmountNFTs, uint256 newProposalMinAmountNFTs);

    /// @notice Emitted when quorumPercentage for a specific proposal is changed
    event QuorumPercentageSet(
        uint8 criteriaType,
        string signature,
        address target,
        uint256 oldQuorumPercentage,
        uint256 newQuorumPercentage
    );

    /// @notice Emitted when voteMinAmountNFTs is changed
    event VoteMinAmountNFTsSet(uint256 oldVoteMinAmountNFTs, uint256 newVoteMinAmountNFTs);

    /// @notice Emmitted when proposalFee is changed
    event ProposalFeeSet(uint256 oldProposalFee, uint256 newProposalFee);

    /// @notice Emitted when the deepProposalCriteria mapping is changed
    event DeepProposalCriteriaSet(string signature, address target, bool criteriaState);
    
    /// @notice Emitted when the shallowProposalCrite mapping is changed
    event ShallowProposalCriteriaSet(string signature, bool criteriaState);
    
    /// @notice Emitted when the generalProposalCrite variable is changed
    event GeneralProposalCriteriaSet(bool criteriaState);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);
}

/**
 * @title Storage for Governor Bravo Delegate
 * @notice For future upgrades, do not change TomiDAOStorageV1. Create a new
 * contract which implements TomiDAOStorageV1 and following the naming convention
 * TomiDAOStorageVX.
 */
contract TomiDAOStorageV1 {
    /// @notice Administrator for this contract
    address public admin;

    /// @notice Pending administrator for this contract
    address public pendingAdmin;

    /// @notice The delay before voting on a proposal may take place, once proposed
    uint256 public votingDelay;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The fee to be cut in TOMI tokens when proposing
    uint256 public proposalFee;

    /// @notice The minimum NFTs required to Propose
    uint256 public proposalMinAmountNFTs;

    /// @notice The minimum NFTs required to Vote
    uint256 public voteMinAmountNFTs;

    /// @notice The address of the Tomi DAO Executor
    ITomiDAOExecutor public timelock;

    /// @notice The address of the TOMI token
    IERC20 public tomi;

    /// @notice The address of the PIONEER NFT
    IERC721 public pioneer;

    /// @notice The address to fetch the Price of the TOMI token
    IPriceFeed public priceFeed;

    /// @notice The address of the uniswapV2 router
    IUniswapV2Router public uniswapRouter;

    /// @notice The official record of all proposals ever proposed
    mapping (uint256 => Proposal) internal _proposals;

    /// @notice The current NFTs being used in proposals
    mapping (uint256 => bool) public proposalNFTs;

    /// @notice The current NFTs being used to vote in proposals
    mapping (uint256 => mapping (uint256 => bool)) public voteNFTs;

    /// @notice The current saved state for each proposal
    mapping (uint256 => ProposalState) public proposalExecutionState;

    /**
     * @notice The proposal criteria for proposals relevant to their `signatures` and `targets`
     * @dev Does not affect the actual `signatures` and `targets` being sent
     * @dev Contains have most of the governance proposals
     * @dev Contains the `transferFrom` call for pioneer NFT
     */
    mapping (string => mapping(address => Criteria)) public deepProposalCriteria;

    /**
     * @notice The proposal criteria for all proposals relevant to their `signatures`
     * @dev Does not affect the actual `signatures` and `targets` being sent
     * @dev Contains ETH transfers with signature [""]
     *          and reflects back to ["transfer1", "transfer2", "transfer3"]
     * @dev Contains ERC20 transfers with signatures ["transfer1", "transfer2", "transfer3"]
     *          and does not follow abi conventions
     */
    mapping (string => Criteria) public shallowProposalCriteria;

    /// @notice The proposal criteria for proposals that don't exist in either deep or shallow mappings
    Criteria public generalProposalCriteria;

    struct Criteria {
        bool state;
        uint256 quorumPercentage;
        uint256 consensusPercentage;
        uint256 votingPeriod;
    }

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice NFTs used to make this proposal with
        uint256[] nftIds;
        /// @notice The maximum number of votes allowed in a proposal
        uint256 quorumVotes;
        /// @notice The number of votes a proposal needs to succeed
        uint256 consensusVotes; 
        /// @notice The ordered list of target addresses for calls to be made
        address[] targets;
        /// @notice The ordered list of values (msg.value) to be passed to the calls to be made
        uint256[] values;
        /// @notice The ordered list of function signatures to be called
        string[] signatures;
        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        /// @notice The time at which voting begins
        uint256 startTime;
        /// @notice The time at which voting ends
        uint256 endTime;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstainVotes;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        // Queued,
        // Expired,
        Executed
    }
}

interface ITomiDAOExecutor {
    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data
    ) external payable returns (bytes memory);
}

interface IPriceFeed {
    function getTomiPrice() external view returns(uint256);
}

interface IERC20 {
    function decimals() external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function totalSupply() external view returns (uint256);
}

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: BSD-3-Clause

/// @title The Tomi DAO logic version 1

// LICENSE
// TomiDAOLogic.sol is a modified version of Compound Lab's GovernorBravoDelegate.sol:
// https://github.com/compound-finance/compound-protocol/blob/b9b14038612d846b83f8a009a82c38974ff2dcfe/contracts/Governance/GovernorBravoDelegate.sol
//
// GovernorBravoDelegate.sol source code Copyright 2020 Compound Labs, Inc. licensed under the BSD-3-Clause license.
//
// Additional conditions of BSD-3-Clause can be found here: https://opensource.org/licenses/BSD-3-Clause

pragma solidity ^0.8.6;

import './TomiDAOInterfaces.sol';

contract TomiDAOLogic is Initializable, TomiDAOStorageV1, TomiDAOEvents {
    /// @notice The address of WETH
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice The address of USDT
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant proposalMaxOperations = 10; // 10 actions

    /// @dev Introduced these errors to reduce contract size, to avoid deployment failure
    error AdminOnly();
    error PendingAdminOnly();

    /**
     * @notice Used to initialize the contract during delegator contructor
     * @param timelock_ The address of the TomiDAOExecutor
     */
    function initialize(address timelock_) external initializer {
        require(address(timelock) == address(0), 'TomiDAO::initialize: can only initialize once');
        require(timelock_ != address(0), 'TomiDAO::initialize: invalid timelock address');

        pendingAdmin = msg.sender;

        timelock = ITomiDAOExecutor(timelock_);

        votingDelay = 24 hours;
        proposalFee = 100 * (10 ** 26);
        proposalMinAmountNFTs = 1;
        voteMinAmountNFTs = 1;
        tomi = IERC20(0x4385328cc4D643Ca98DfEA734360C0F596C83449);
        pioneer = IERC721(0x18B97FeB170eB6983aE79769B051d35e8103DC08);
        priceFeed = IPriceFeed(0x4c7f63B6105Ff95963fC79dB8111628fa014769b);
        uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    struct ProposalTemp {
        uint256 quorumPercentage;
        uint256 quorumVotes;
        uint256 consensusPercentage;
        uint256 consensusVotes;
        uint256 votingPeriod;
        uint256 startTime;
        uint256 endTime;
    }

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
     * @param nftIds NFTIds owned by the proposer, to be held until proposal execution
     * @param targets Target addresses for proposal calls
     * @param values Eth values for proposal calls
     * @param signatures Function signatures for proposal calls
     * @param calldatas Calldatas for proposal calls
     * @param title String title of the proposal
     * @param description String description of the proposal
     */
    function propose(
        uint256[] memory nftIds,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory title,
        string memory description
    ) public returns (uint256) {
        require(nftIds.length == proposalMinAmountNFTs, 'TomiDAO::propose: Invalid NFT amount for proposal');
        for (uint256 i = 0 ; i < nftIds.length ; i++) {
            require(pioneer.ownerOf(nftIds[i]) == msg.sender, 'TomiDAO::propose: Must own NFT for proposal creation');
            require(!proposalNFTs[nftIds[i]], 'TomiDAO::propose: NFT already in use');
            proposalNFTs[nftIds[i]] = true;
        }
        require(
            targets.length == values.length &&
            targets.length == signatures.length &&
            targets.length == calldatas.length,
            'TomiDAO::propose: proposal function information arity mismatch'
        );
        require(targets.length <= proposalMaxOperations, 'TomiDAO::propose: too many actions');
        /// @dev Finding the max quorum among all the given actions
        ProposalTemp memory temp;

        for (uint256 i = 0 ; i < targets.length ; i++) {
            Criteria memory criteria = processCriteria(targets[i], values[i], signatures[i], calldatas[i]);

            if (criteria.quorumPercentage > temp.quorumPercentage) {
                temp.quorumPercentage = criteria.quorumPercentage;
                temp.consensusPercentage = criteria.consensusPercentage;
                temp.votingPeriod = criteria.votingPeriod;
            }
        }
        processPayment();
        proposalCount++;

        temp.quorumVotes = pioneer.totalSupply() * temp.quorumPercentage;
        temp.quorumVotes = temp.quorumVotes % 100 == 0 ? temp.quorumVotes / 100 : (temp.quorumVotes / 100) + 1;
        temp.consensusVotes = temp.quorumVotes * temp.consensusPercentage;
        temp.consensusVotes = temp.consensusVotes % 100 == 0 ? temp.consensusVotes / 100 : (temp.consensusVotes / 100) + 1;
        temp.startTime = block.timestamp + votingDelay;
        temp.endTime = temp.startTime + temp.votingPeriod;

        Proposal storage newProposal = _proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.nftIds = nftIds;
        newProposal.quorumVotes = temp.quorumVotes;
        newProposal.consensusVotes = temp.consensusVotes;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startTime = temp.startTime;
        newProposal.endTime = temp.endTime;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.abstainVotes = 0;
        newProposal.canceled = false;
        newProposal.executed = false;

        /// @notice Maintains backwards compatibility with GovernorBravo events
        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            newProposal.startTime,
            newProposal.endTime,
            title,
            description,
            newProposal.quorumVotes,
            newProposal.consensusVotes
        );

        return newProposal.id;
    }

    /**
     * @notice Executes a proposal if endTime has passed
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint256 proposalId) external {
        ProposalState proposalState = state(proposalId);
        require(
            proposalState == ProposalState.Succeeded ||
            proposalState == ProposalState.Defeated,
            'TomiDAO::execute: proposal can only be executed after end time and if it is not canceled'
        );

        Proposal storage proposal = _proposals[proposalId];
        for (uint256 i = 0 ; i < proposal.nftIds.length ; i++) {
            proposalNFTs[proposal.nftIds[i]] = false;
        }
        proposal.executed = true;
        if (proposalState == ProposalState.Succeeded) {
            proposalExecutionState[proposalId] = ProposalState.Succeeded;
            for (uint256 i = 0; i < proposal.targets.length; i++) {
                if (proposal.targets[i] != address(0)) {
                    timelock.executeTransaction(
                        proposal.targets[i],
                        proposal.values[i],
                        proposal.signatures[i],
                        proposal.calldatas[i]
                    );
                }
            }
        }
        else {
            proposalExecutionState[proposalId] = ProposalState.Defeated;
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Cancels a proposal only if sender is the proposer
     * @param proposalId The id of the proposal to cancel
     */
    function cancel(uint256 proposalId) external {
        require(state(proposalId) != ProposalState.Executed, 'TomiDAO::cancel: cannot cancel already executed proposal');

        Proposal storage proposal = _proposals[proposalId];
        require(msg.sender == proposal.proposer, 'TomiDAO::cancel: caller is not proposer');
        for (uint256 i = 0 ; i < proposal.nftIds.length ; i++) {
            proposalNFTs[proposal.nftIds[i]] = false;
        }
        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Internal processing of all criteria requirements
     */
    function processCriteria(
        address target,
        uint256 value,
        string memory signature,
        bytes memory argument
    ) internal view returns (Criteria memory) {
        Criteria memory criteria;
        criteria = deepProposalCriteria[signature][target];
        if (!criteria.state) {
            criteria = shallowProposalCriteria[signature];
            if (!criteria.state) {
                criteria = generalProposalCriteria;
            }
        }
        if (keccak256(abi.encodePacked(signature)) == keccak256(abi.encodePacked(""))) {
            criteria = shallowProposalCriteria[getLatestEthPrice(value)];
        } else if (keccak256(abi.encodePacked(signature)) == keccak256(abi.encodePacked("transfer(address,uint256)"))) {
            try this.getLatestPrice(target, argument) returns (string memory criteriaSignature) {
                criteria = shallowProposalCriteria[criteriaSignature];
            } catch {
                criteria = shallowProposalCriteria["transfer3"];
            }
        }

        return criteria;
    }

    /**
     * @notice Internal processing of proposalFee payment
     */
    function processPayment() internal {
        uint256 feeInUSD = proposalFee;
        uint256 tomiPrice = priceFeed.getTomiPrice();

        uint256 feeInTomi = feeInUSD / tomiPrice;

        tomi.transferFrom(msg.sender, address(timelock), feeInTomi);
    }

    /**
     * @notice Getting the latest ETH price
     */
    function getLatestEthPrice(uint256 amountEth) internal view returns (string memory) {
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(USDT);

        uint256 decimals = 18;

        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(1 * (10 ** decimals), path);

        uint256 amountUSD = (amountsOut[1] * amountEth) / 10 * (10 ** decimals);

        if (amountUSD < 100000 * (10 ** 6)) {
            return "transfer1";
        }
        else if (amountUSD >= 100000 * (10 ** 6) && amountUSD < 500000 * (10 ** 6)) {
            return "transfer2";
        }
        else {
            return "transfer3";
        }
    }

    /**
     * @notice Getting the latest price of ANY token
     */
    function getLatestPrice(address token, bytes memory argument) external view returns (string memory) {
        (, uint256 amountToken) = abi.decode(argument, (address, uint256));

        uint256 amountUSD;

        if (token == address(tomi)) {
            uint256 tomiTokenPrice = priceFeed.getTomiPrice();

            amountUSD = (amountToken * tomiTokenPrice) / (10 ** 20);
        }
        else {
            address[] memory path = new address[](3);
            path[0] = address(token);
            path[1] = address(WETH);
            path[2] = address(USDT);

            uint256 decimals = IERC20(token).decimals();

            uint256[] memory amountsOut = uniswapRouter.getAmountsOut(1 * (10 ** decimals), path);

            amountUSD = (amountsOut[2] * amountToken) / decimals;
        }

        if (amountUSD < 100000 * (10 ** 6)) {
            return "transfer1";
        }
        else if (amountUSD >= 100000 * (10 ** 6) && amountUSD < 500000 * (10 ** 6)) {
            return "transfer2";
        }
        else {
            return "transfer3";
        }
    }

    /**
     * @notice Gets actions of a proposal
     * @param proposalId the id of the proposal
     * @return targets
     * @return values
     * @return signatures
     * @return calldatas
     */
    function getActions(
        uint256 proposalId
    ) external view returns (address[] memory targets, uint256[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal memory p = _proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId, 'TomiDAO::state: invalid proposal id');
        Proposal memory proposal = _proposals[proposalId];
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp <= proposal.startTime) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        } else if (proposal.forVotes < proposal.consensusVotes || totalVotes < proposal.quorumVotes) {
            return ProposalState.Defeated;
        } else {
            return ProposalState.Succeeded;
        }
    }

    /**
     * @notice Gets whether or not the user has atleast 1 NFT that has not voted on the given proposal
     */
    function checkVotedNFTs(uint256 proposalId, uint256[] memory nftIds) external view returns (bool) {
        if (nftIds.length == 0) {
            return false;
        }

        for (uint256 i = 0 ; i < nftIds.length ; i++) {
            if (!voteNFTs[proposalId][nftIds[i]]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Returns the proposal details given a proposal id.
     * @param proposalId the proposal id to get the data for
     */
    function proposals(uint256 proposalId) external view returns (Proposal memory) {
        Proposal memory proposal = _proposals[proposalId];
        return Proposal({
            id: proposal.id,
            proposer: proposal.proposer,
            nftIds: proposal.nftIds,
            quorumVotes: proposal.quorumVotes,
            consensusVotes: proposal.consensusVotes,
            targets: proposal.targets,
            values: proposal.values,
            signatures: proposal.signatures,
            calldatas: proposal.calldatas,
            startTime: proposal.startTime,
            endTime: proposal.endTime,
            forVotes: proposal.forVotes,
            againstVotes: proposal.againstVotes,
            abstainVotes: proposal.abstainVotes,
            canceled: proposal.canceled,
            executed: proposal.executed
        });
    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(uint256 proposalId, uint8 support, uint256[] calldata nftIds) external {
        emit VoteCast(
            msg.sender,
            proposalId,
            support,
            castVoteInternal(msg.sender, proposalId, support, nftIds),
            uint256(state(proposalId))
        );
    }

    /**
     * @notice Internal function that caries out voting logic
     * @param voter The voter that is casting their vote
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVoteInternal(
        address voter,
        uint256 proposalId,
        uint8 support,
        uint256[] calldata nftIds
    ) internal returns (uint256) {
        require(state(proposalId) == ProposalState.Active, 'TomiDAO::castVoteInternal: voting is closed');
        require(support <= 2, 'TomiDAO::castVoteInternal: invalid vote type');
        require(nftIds.length >= voteMinAmountNFTs, 'TomiDAO::castVoteInternal: Invalid NFT amount to vote');
        Proposal storage proposal = _proposals[proposalId];

        for (uint256 i = 0 ; i < nftIds.length ; i++) {
            require(pioneer.ownerOf(nftIds[i]) == voter, 'TomiDAO::castVoteInternal: Must own NFT to vote');
            require(!voteNFTs[proposalId][nftIds[i]], 'TomiDAO::castVoteInternal: NFT already voted with');
            voteNFTs[proposalId][nftIds[i]] = true;
        }

        uint256 votes = nftIds.length;

        if (support == 0) {
            proposal.againstVotes += votes;
        } else if (support == 1) {
            proposal.forVotes += votes;
        } else if (support == 2) {
            proposal.abstainVotes += votes;
        }

        return votes;
    }

    /**
     * @notice Admin function for setting the minimum required amount of NFTs to propose
     * @param newProposalMinAmountNFTs new proposal min amount NFTs
     */
    function _setProposalMinAmountNFTs(uint256 newProposalMinAmountNFTs) external {
        if (msg.sender != admin) {
            revert AdminOnly();
        }

        require(
            newProposalMinAmountNFTs >= 1,
            'TomiDAO::_setProposalMinAmountNFTs: invalid proposal min amount NFTs'
        );

        emit ProposalMinAmountNFTs(proposalMinAmountNFTs, newProposalMinAmountNFTs);

        proposalMinAmountNFTs = newProposalMinAmountNFTs;
    }

    /**
     * @notice Admin function for setting the quorum percentage of a specific proposal
     * @param criteriaType where deep = 0, shallow = 1 and general = 2
     * @param signature signature of the proposal
     * @param target target of the proposal
     * @param newQuorumPercentage new quorum percentage
     */
    function _setQuorumPercentage(uint8 criteriaType, string calldata signature, address target, uint256 newQuorumPercentage) external {
        if (msg.sender != admin) {
            revert AdminOnly();
        }
        require(
            newQuorumPercentage >= 1 &&
            newQuorumPercentage <= 100,
            'TomiDAO::_setQuorumPercentage: invalid quorum percentage'
        );
        require(
            criteriaType >= 0 &&
            criteriaType <= 2,
            'TomiDAO::_setQuorumPercentage: invalid criteria type'
        );

        uint256 oldQuorumPercentage;
        if (criteriaType == 0) {
            oldQuorumPercentage = deepProposalCriteria[signature][target].quorumPercentage;
            deepProposalCriteria[signature][target].quorumPercentage = newQuorumPercentage;
        } else if (criteriaType == 1) {
            oldQuorumPercentage = deepProposalCriteria[signature][target].quorumPercentage;
            shallowProposalCriteria[signature].quorumPercentage = newQuorumPercentage;
        } else {
            oldQuorumPercentage = deepProposalCriteria[signature][target].quorumPercentage;
            generalProposalCriteria.quorumPercentage = newQuorumPercentage;
        }

        emit QuorumPercentageSet(criteriaType, signature, target, oldQuorumPercentage, newQuorumPercentage);
    }

    /**
     * @notice Admin function for setting the minimum required amount of NFTs to vote
     * @param newVoteMinAmountNFTs new vote min amount NFTs
     */
    function _setVoteMinAmountNFTs(uint256 newVoteMinAmountNFTs) external {
        if (msg.sender != admin) {
            revert AdminOnly();
        }
        require(
            newVoteMinAmountNFTs >= 1,
            'TomiDAO::_setVoteMinAmountNFTs: invalid vote min amount NFTs'
        );

        emit VoteMinAmountNFTsSet(voteMinAmountNFTs, newVoteMinAmountNFTs);

        voteMinAmountNFTs = newVoteMinAmountNFTs;
    }

    /**
     * @notice Admin function for setting the proposal fee
     * @param newProposalFee new proposal fee
     */
    function _setProposalFee(uint256 newProposalFee) external {
        if (msg.sender != admin) {
            revert AdminOnly();
        }

        emit ProposalFeeSet(proposalFee, newProposalFee);

        proposalFee = newProposalFee;
    }

    /**
     * @notice Admin function for setting the criteria of a deep proposal
     * @param signature signature of the proposal
     * @param target target of the proposal
     * @param criteria new proposal criteria
     */
    function _setDeepProposalCriteria(string memory signature, address target, Criteria memory criteria) external {
        require(msg.sender == admin || msg.sender == pendingAdmin, 'TomiDAO::_setDeepProposalCriteria: admin or pending admin only');

        deepProposalCriteria[signature][target] = criteria;

        emit DeepProposalCriteriaSet(signature, target, criteria.state);
    }

    /**
     * @notice Admin function for setting the criteria of a shallow proposal
     * @param signature signature of the proposal
     * @param criteria new proposal criteria
     */
    function _setShallowProposalCriteria(string memory signature, Criteria memory criteria) external {
        require(msg.sender == admin || msg.sender == pendingAdmin, 'TomiDAO::_setShallowProposalCriteria: admin or pending admin only');

        shallowProposalCriteria[signature] = criteria;

        emit ShallowProposalCriteriaSet(signature, criteria.state);
    }

    /**
     * @notice Admin function for setting the criteria of a general proposal
     * @param criteria new proposal criteria
     */
    function _setGeneralProposalCriteria(Criteria memory criteria) external {
        require(msg.sender == admin || msg.sender == pendingAdmin, 'TomiDAO::_setGeneralProposalCriteria: admin or pending admin only');

        generalProposalCriteria = criteria;

        emit GeneralProposalCriteriaSet(criteria.state);
    }


    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function setAdmin(address admin_) external {
        // Check caller is pendingAdmin and admin == address(0)
        if (msg.sender != pendingAdmin) {
            revert PendingAdminOnly();
        }
        require(admin == address(0), 'TomiDAO::setAdmin: admin already set');

        // Save current values for inclusion in log
        address oldAdmin = admin;

        // Store admin with value admin_
        admin = admin_;

        emit NewAdmin(oldAdmin, admin);
    }

    function clearPendingAdmin() external {
        // Check caller is pendingAdmin
        if (msg.sender != pendingAdmin) {
            revert PendingAdminOnly();
        }

        // Save current values for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }
}
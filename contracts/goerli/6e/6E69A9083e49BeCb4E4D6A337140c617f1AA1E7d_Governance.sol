// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "./Upgrade/UUPS.sol";
import "./AccessControl.sol";
import "./Token.sol";
import "./Voting.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract Governance is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721ReceiverUpgradeable,
    IERC1155ReceiverUpgradeable,
    UUPS
{
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");

    address public constant ANYONE_GROUP_ADDRESS =
        0x0000000000000000000000000000000000000000;

    /**
     * Active: active for voting
     * Eventual states (*): {Canceled}, {Executed}
     * Explicitly set state (@): {Nonexistent} (default), {Pending}, {Active} (@ only), {Canceled}, {Executed}
     * The transition from {Nonexistent} to {Active} is explicitly set while
     * the transition from {Pending} to {Active} is inferred
     *
     * We refer to the meta state {"Succeeded"} as being either {Queued} or {Executable}
     *
     * Note: if the success criteria of the governance is modified when
     * a proposal is {Defeated}, {Queued} or {Executable},
     * the state of the proposal will be changed accordingly, which is susceptible to attacks.
     *
     * e.g. a previous {Defeated} proposal in the past might become {Executable} due to a decrease in the quorum
     *
     * Nonexistent (@) -> Pending (@) -> Canceled (@*)
     *                 |              |
     *                 -----(@)--------> Active -> Canceled (@*)
     *                                          |
     *                                          -> Defeated -> Canceled (@*)
     *                                          |
     *                                          -> Queued -> Canceled (@*)
     *                                          |         |
     *                                          <----------
     *                                          |
     *                                          -> Executable -> Canceled (@*)
     *                                                        |
     *                                                        -> Executed (@*)
     */
    enum ProposalState {
        Nonexistent,
        Pending,
        Active,
        Canceled,
        Defeated,
        Queued,
        Executable,
        Executed
    }

    /**
     * The value of a {ProposalState} can not be trusted unless that state can only be explicitly set and
     * not followed by another state that is explicitly set.
     *
     * The eventual state of a proposal is set when {Canceled} or {Executed} and can be trusted as it is,
     * while the states {Pending}, {Active}, {Defeated}, and {Succeeded} can only be inferred.
     *
     * {Nonexistent} is also trusted since they are explicitly set and
     * the following state is explicitly set as well in both cases.
     */
    struct Proposal {
        ProposalState state;
        uint256 openning;
    }

    event ProposalStateChanged(
        uint256 indexed proposalId,
        ProposalState updatedState
    );

    /**
     * Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 indexed proposalId,
        uint256 indexed tokenId,
        address proposer,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        uint256 openning,
        bytes32 descriptionHash,
        uint8 quorumNumerator,
        uint8 approvalRateNumerator
    );

    event QuorumChanged(uint8 oldQuorumNumerator, uint8 newQuorumNumerator);
    event ApprovalRateChanged(
        uint8 oldApprovalRateNumerator,
        uint8 newApprovalRateNumerator
    );
    event ProposalThresholdChanged(
        uint256 oldProposalThreshold,
        uint256 newProposalThreshold
    );

    AccessControl private accessControl;
    Token private token;
    Voting private voting;

    mapping(uint256 => Proposal) private _proposals;
    uint256 private _proposalThreshold;
    string private _uri;
    uint8 private _quorumNumerator;
    uint8 private _approvalRateNumerator;

    /**
     * Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     */
    modifier onlyRole(bytes32 role) {
        require(
            accessControl.hasRole(role, _msgSender()),
            "AccessControl: Missing role"
        );
        _;
    }

    modifier groupAccessControl(bytes32 role, uint256 tokenId) {
        require(
            (accessControl.hasRole(role, ANYONE_GROUP_ADDRESS) &&
                token.balanceOf(_msgSender(), tokenId) >= _proposalThreshold) ||
                accessControl.hasRole(role, _msgSender()),
            "AccessControl: Not authorized"
        );
        _;
    }

    modifier onlyGovernance() {
        require(_msgSender() == address(this), "Governance: only governance");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        AccessControl accessControlAddress,
        Token tokenAddress,
        Voting votingAddress
    ) public initializer {
        accessControl = accessControlAddress;
        token = tokenAddress;
        voting = votingAddress;
    }

    function getURI() public view returns (string memory) {
        return _uri;
    }

    function setURI(string calldata newURI) public onlyRole(GOVERNOR_ROLE) {
        _uri = newURI;
    }

    function getProposal(uint256 proposalId)
        public
        view
        returns (Proposal memory)
    {
        return _proposals[proposalId];
    }

    /**
     * Note: that the chainId and the governance contract address are not part of the proposal id computation.
     * Consequently, the same proposal (with same operation and same description) will have the same id if
     * submitted on multiple governors across multiple networks.
     * This also means that in order to execute the same operation twice (on the same
     * governor) the proposer will have to change the description in order to avoid proposal id conflicts.
     */
    function hashProposal(
        uint256 tokenId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        tokenId,
                        targets,
                        values,
                        calldatas,
                        descriptionHash
                    )
                )
            );
    }

    function getQuorumNumerator() public view returns (uint8) {
        return _quorumNumerator;
    }

    function getApprovalRateNumerator() public view returns (uint8) {
        return _approvalRateNumerator;
    }

    function setQuorumNumerator(uint8 newQuorumNumerator)
        public
        onlyRole(GOVERNOR_ROLE)
    {
        emit QuorumChanged(_quorumNumerator, newQuorumNumerator);
        _quorumNumerator = newQuorumNumerator;
    }

    function setApprovalRateNumerator(uint8 newApprovalRateNumerator)
        public
        onlyRole(GOVERNOR_ROLE)
    {
        emit ApprovalRateChanged(
            _approvalRateNumerator,
            newApprovalRateNumerator
        );
        _approvalRateNumerator = newApprovalRateNumerator;
    }

    /**
     * The number of votes required in order for a voter to become a proposer.
     */
    function getProposalThreshold() public view returns (uint256) {
        return _proposalThreshold;
    }

    function setProposalThreshold(uint256 newProposalThreshold)
        public
        onlyRole(GOVERNOR_ROLE)
    {
        emit ProposalThresholdChanged(_proposalThreshold, newProposalThreshold);
        _proposalThreshold = newProposalThreshold;
    }

    /**
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = _proposals[proposalId];

        if (
            proposal.state == ProposalState.Nonexistent ||
            proposal.state == ProposalState.Canceled ||
            proposal.state == ProposalState.Executed
        ) {
            return proposal.state;
        }

        Voting.VoteState voteState = voting.state(proposalId);

        if (voteState == Voting.VoteState.Pending) {
            return ProposalState.Pending;
        }

        if (voteState == Voting.VoteState.Active) {
            return ProposalState.Active;
        }

        if (voteState == Voting.VoteState.Defeated) {
            return ProposalState.Defeated;
        }

        uint256 openning = proposal.openning;
        if (openning <= block.number) {
            return ProposalState.Executable;
        } else {
            return ProposalState.Queued;
        }
    }

    function _propose(
        uint256 tokenId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        uint256 votingDelay,
        uint256 votingPeriod,
        uint256 openningDelay,
        bytes32 descriptionHash,
        uint8 quorumNumerator,
        uint8 approvalRateNumerator
    ) private returns (uint256) {
        require(
            targets.length == values.length &&
                targets.length == calldatas.length,
            "Governance: args length mismatch"
        );
        require(targets.length > 0, "Governance: empty proposal");

        uint256 proposalId = hashProposal(
            tokenId,
            targets,
            values,
            calldatas,
            descriptionHash
        );

        Proposal storage proposal = _proposals[proposalId];
        require(
            proposal.state == ProposalState.Nonexistent,
            "Governance: proposal exists"
        );

        voting.createVote(
            proposalId,
            tokenId,
            block.number + votingDelay,
            block.number + votingDelay + votingPeriod,
            quorumNumerator,
            approvalRateNumerator
        );
        proposal.openning = block.number + votingDelay + openningDelay;

        emit ProposalCreated(
            proposalId,
            tokenId,
            _msgSender(),
            targets,
            values,
            calldatas,
            proposal.openning,
            descriptionHash,
            quorumNumerator,
            approvalRateNumerator
        );

        if (block.number + votingDelay > block.number) {
            proposal.state = ProposalState.Pending;
            emit ProposalStateChanged(proposalId, ProposalState.Pending);
        } else {
            proposal.state = ProposalState.Active;
            emit ProposalStateChanged(proposalId, ProposalState.Active);
        }

        return proposalId;
    }

    /**
     */
    function propose(
        uint256 tokenId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        uint256 votingDelay,
        uint256 votingPeriod,
        uint256 openningDelay,
        bytes32 descriptionHash
    ) public groupAccessControl(PROPOSER_ROLE, tokenId) returns (uint256) {
        return
            _propose(
                tokenId,
                targets,
                values,
                calldatas,
                votingDelay,
                votingPeriod,
                openningDelay,
                descriptionHash,
                getQuorumNumerator(),
                getApprovalRateNumerator()
            );
    }

    function propose(
        uint256 tokenId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        uint256 votingDelay,
        uint256 votingPeriod,
        uint256 openningDelay,
        bytes32 descriptionHash,
        uint8 quorumNumerator,
        uint8 approvalRateNumerator
    ) public onlyRole(GOVERNOR_ROLE) returns (uint256) {
        return
            _propose(
                tokenId,
                targets,
                values,
                calldatas,
                votingDelay,
                votingPeriod,
                openningDelay,
                descriptionHash,
                quorumNumerator,
                approvalRateNumerator
            );
    }

    /**
     * This function can re-enter, but it doesn't pose a risk.
     * Because {Executable} can only be changed to {Canceled} and {Executed}
     * {Canceled} is an eventual state which is prohibited from executing.
     * {Executed} can only be set by this function and is an eventual state.
     * Therefore a {require} guard on the state of the proposal being {Executable}
     * is sufficient in catching all re-entrancy attacks.
     *
     *
     * More rigorously, any changes to the invariant {state(proposalId) == ProposalState.Executable}
     * will be caught by the post-condition guard and the changes to the invariant
     * {state(proposalId) == ProposalState.Executable} is irreversible.
     *
     * see https://www.notion.so/capita/How-to-prevent-re-entrancy-attacks-e83be837533a424e9a27362a5213cd7f
     */
    function execute(
        uint256 tokenId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public groupAccessControl(EXECUTOR_ROLE, tokenId) returns (uint256) {
        uint256 proposalId = hashProposal(
            tokenId,
            targets,
            values,
            calldatas,
            descriptionHash
        );
        require(
            state(proposalId) == ProposalState.Executable,
            "Governance: proposal not executable"
        );

        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{
                value: values[i]
            }(calldatas[i]);
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                "Governance: execution reverted without message"
            );
        }

        require(
            state(proposalId) == ProposalState.Executable,
            "Governance: reentrance prevented"
        );
        _proposals[proposalId].state = ProposalState.Executed;
        emit ProposalStateChanged(proposalId, ProposalState.Executed);

        return proposalId;
    }

    /**
     * Locks up the proposal timer, preventing it from being re-submitted. Marks it as
     * canceled to allow distinguishing it from executed proposals.
     *
     */
    function cancel(
        uint256 tokenId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public groupAccessControl(CANCELLER_ROLE, tokenId) returns (uint256) {
        uint256 proposalId = hashProposal(
            tokenId,
            targets,
            values,
            calldatas,
            descriptionHash
        );
        ProposalState status = state(proposalId);

        require(
            status != ProposalState.Canceled &&
                status != ProposalState.Executed,
            "Governance: proposal archived"
        );
        _proposals[proposalId].state = ProposalState.Canceled;

        emit ProposalStateChanged(proposalId, ProposalState.Canceled);

        return proposalId;
    }

    /**
     * Function to receive ETH that will be handled by the governance contract
     */
    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165Upgradeable, ERC165Upgradeable, UUPS)
        returns (bool)
    {
        return
            interfaceId == type(IERC721ReceiverUpgradeable).interfaceId ||
            interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPS is
    Initializable,
    ERC165Upgradeable,
    IERC1822ProxiableUpgradeable,
    ERC1967Upgrade
{
    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(
            address(this) != __self,
            "UUPS: must be called through delegatecall"
        );
        require(
            _getImplementation() == __self,
            "UUPS: must be called through active proxy"
        );
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(
            address(this) == __self,
            "UUPS: must not be called through delegatecall"
        );
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        virtual
        onlyProxy
    {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC1822ProxiableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Upgrade/UUPS.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract AccessControl is Initializable, ContextUpgradeable, UUPS {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    // bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    // bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    // bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    // bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
    // bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    // bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    // bytes32 public constant ENGRAVER_ROLE = keccak256("ENGRAVER_ROLE");
    // bytes32 public constant VOTE_REGISTER_ROLE =
    //     keccak256("VOTE_REGISTER_ROLE");

    // address public constant ANYONE_GROUP_ADDRESS =
    //     0x0000000000000000000000000000000000000000;

    event AdminRoleChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole,
        address sender
    );

    event RoleSet(
        bytes32 indexed role,
        address indexed account,
        uint256 indexed roleEnd,
        address sender
    );

    struct RoleData {
        mapping(address => uint256) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet)
        private _roleMembers;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        _setRole(DEFAULT_ADMIN_ROLE, _msgSender(), type(uint256).max);
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "AccessControl: missing role");
        _;
    }

    /**
     * Returns {true} if {account} has been granted {role} valid stricly before {roleEnd} block
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account] >= block.number;
    }

    function getRoleEnd(bytes32 role, address account)
        public
        view
        returns (uint256)
    {
        return _roles[role].members[account];
    }

    /**
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getAdminRole(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * the caller must have {role}'s admin role.
     */
    function setRole(
        bytes32 role,
        address account,
        uint256 roleEnd
    ) public onlyRole(getAdminRole(role)) {
        _setRole(role, account, roleEnd);
    }

    function grantPermanentRole(bytes32 role, address account) public {
        setRole(role, account, type(uint256).max);
    }

    function revokeRole(bytes32 role, address account) public {
        setRole(role, account, 0);
    }

    function renounceRole(bytes32 role) public {
        _roles[role].members[_msgSender()] = 0;
        _roleMembers[role].remove(_msgSender());
        emit RoleSet(role, _msgSender(), 0, _msgSender());
    }

    function setAdminRole(bytes32 role, bytes32 adminRole) public {
        bytes32 previousAdminRole = getAdminRole(role);
        require(
            hasRole(previousAdminRole, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AccessControl: missing role"
        );
        emit AdminRoleChanged(role, previousAdminRole, adminRole, _msgSender());
        _roles[role].adminRole = adminRole;
    }

    function _setRole(
        bytes32 role,
        address account,
        uint256 roleEnd
    ) private {
        _roles[role].members[account] = roleEnd;
        emit RoleSet(role, account, roleEnd, _msgSender());
        if (roleEnd < block.number) {
            _roleMembers[role].remove(account);
        } else {
            _roleMembers[role].add(account);
        }
    }

    /**
     * The count might include members the role of which has expired
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * returns member address and the last block number the role is granted till
     */
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        returns (address, uint256)
    {
        address member = _roleMembers[role].at(index);
        uint256 roleEnd = getRoleEnd(role, member);
        return (member, roleEnd);
    }

    function removeExpiredRoleMembers(bytes32 role, uint256 index)
        public
        returns (address, uint256)
    {
        EnumerableSetUpgradeable.AddressSet storage members = _roleMembers[
            role
        ];
        address member = members.at(index);
        uint256 roleEnd = getRoleEnd(role, member);
        require(roleEnd < block.number, "AccessControl: role has not expired");
        members.remove(member);
        return (member, roleEnd);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";

import "./Upgrade/UUPS.sol";
import "./AccessControl.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./Array.sol";

contract Token is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC1155Upgradeable,
    IERC1155MetadataURIUpgradeable,
    UUPS
{
    using AddressUpgradeable for address;
    using Array for uint256[];

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ENGRAVER_ROLE = keccak256("ENGRAVER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant VOTE_REGISTER_ROLE =
        keccak256("VOTE_REGISTER_ROLE");

    event Pause(address account, bool paused);
    event Approval(
        address indexed account,
        address indexed operator,
        uint256[] tokenIds,
        uint256[] amounts
    );
    event CheckpointCreated(uint256 checkpointId);

    event DelegateeChanged(
        address indexed delegator,
        uint256 indexed tokenId,
        address fromDelegate,
        address toDelegate
    );

    mapping(address => mapping(uint256 => uint256)) private _accountBalances;
    /**
     * account => operator => tokenId => allowance
     *                        tokenId {type(uint256).max} is saved for {ApprovalForAll}
     */
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private _accountAllowances;

    struct VotingWeightCheckpoints {
        address delegatee;
        uint256[] ids;
        uint256[] votingWeights;
    }
    mapping(address => mapping(uint256 => VotingWeightCheckpoints))
        private _accountVotingWeightCheckpoints;

    struct TotalSupplyCheckpoints {
        uint256[] ids;
        uint256[] amounts;
    }
    mapping(uint256 => TotalSupplyCheckpoints) private _totalSupplyCheckpoints;

    // Counter, which can only be incremented
    uint256 private _currentCheckpointId;
    bool private _paused;
    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{tokenId}.json
    string private _uri;

    AccessControl private accessControl;

    modifier onlyRole(bytes32 role) {
        require(
            accessControl.hasRole(role, _msgSender()),
            "AccessControl: Missing role"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(AccessControl accessControlAddress) public initializer {
        _paused = false;
        accessControl = accessControlAddress;
    }

    function createCheckpoint()
        public
        onlyRole(VOTE_REGISTER_ROLE)
        returns (uint256)
    {
        emit CheckpointCreated(++_currentCheckpointId);
        return _currentCheckpointId;
    }

    function totalSupply(uint256 tokenId) public view returns (uint256) {
        uint256 length = _totalSupplyCheckpoints[tokenId].amounts.length;
        return
            length == 0
                ? 0
                : _totalSupplyCheckpoints[tokenId].amounts[length - 1];
    }

    function checkpointedTotalSupply(uint256 tokenId, uint256 checkpointId)
        public
        view
        returns (uint256)
    {
        require(
            checkpointId <= _currentCheckpointId,
            "Token: nonexistent checkpoint id"
        );
        uint256 index = _totalSupplyCheckpoints[tokenId].ids.findClosest(
            checkpointId
        );
        return
            index == 0
                ? 0
                : _totalSupplyCheckpoints[tokenId].amounts[index - 1];
    }

    /**
     * IERC1155MetadataURI
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{tokenId\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view override returns (string memory) {
        return _uri;
    }

    /**
     * Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{tokenId\}` substring in either the
     * URI or any of the amounts in the JSON file at satokenId URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{tokenId\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function setURI(string calldata newURI) public onlyRole(ENGRAVER_ROLE) {
        _uri = newURI;
        emit URI(newURI, 0);
    }

    /**
     * IERC1155-balanceOf
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        require(tokenId != type(uint256).max, "Token: invalid token id");
        return _accountBalances[account][tokenId];
    }

    /**
     * IERC1155-balanceOfBatch
     *
     * Requirements:
     *
     * - `accounts` and `tokenIds` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata tokenIds
    ) public view override returns (uint256[] memory) {
        uint256[] memory batchedBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchedBalances[i] = balanceOf(accounts[i], tokenIds[i]);
        }

        return batchedBalances;
    }

    function allowanceOfBatch(
        address account,
        address operator,
        uint256[] calldata tokenIds
    ) public view returns (uint256[] memory) {
        uint256[] memory allowances = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            allowances[i] = _accountAllowances[account][operator][tokenIds[i]];
        }
        return allowances;
    }

    function approveBatch(
        address operator,
        uint256[] calldata tokenIds,
        uint256[] calldata currentAllowances,
        uint256[] calldata newAllowances
    ) public {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(
                _accountAllowances[_msgSender()][operator][tokenIds[i]] ==
                    currentAllowances[i],
                "Token: current allowances mismatch"
            );
            _accountAllowances[_msgSender()][operator][
                tokenIds[i]
            ] = newAllowances[i];
        }
        emit Approval(_msgSender(), operator, tokenIds, newAllowances);
    }

    /**
     * IERC1155-setApprovalForAll
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        _accountAllowances[_msgSender()][operator][type(uint256).max] = approved
            ? type(uint256).max
            : 0;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * IERC1155-isApprovedForAll
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            _accountAllowances[account][operator][type(uint256).max] ==
            type(uint256).max;
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    function delegateeOf(address account, uint256 tokenId)
        public
        view
        returns (address)
    {
        return _accountVotingWeightCheckpoints[account][tokenId].delegatee;
    }

    /**
     * Setting {delegatee} to {0} revokes the delegation
     * Delegated voting power is not forwarded through delegation
     */
    function delegate(
        address delegator,
        address delegatee,
        uint256 tokenId
    ) external onlyRole(VOTE_REGISTER_ROLE) {
        require(delegator != delegatee, "Token: delegate to self");
        VotingWeightCheckpoints
            storage delegatorVotingWeightCheckpoints = _accountVotingWeightCheckpoints[
                delegator
            ][tokenId];
        VotingWeightCheckpoints
            storage delegateeVotingWeightCheckpoints = _accountVotingWeightCheckpoints[
                delegatee
            ][tokenId];
        address oldDelegatee = delegatorVotingWeightCheckpoints.delegatee;
        VotingWeightCheckpoints
            storage oldDelegateeVotingWeightCheckpoints = _accountVotingWeightCheckpoints[
                oldDelegatee
            ][tokenId];
        uint256 balance = balanceOf(delegator, tokenId);
        if (oldDelegatee != address(0)) {
            _modifyCheckpointedValues(
                oldDelegateeVotingWeightCheckpoints.ids,
                oldDelegateeVotingWeightCheckpoints.votingWeights,
                _subtract,
                balance
            );
            if (delegatee == address(0)) {
                _modifyCheckpointedValues(
                    delegatorVotingWeightCheckpoints.ids,
                    delegatorVotingWeightCheckpoints.votingWeights,
                    _add,
                    balance
                );
            }
        }
        if (delegatee != address(0)) {
            _modifyCheckpointedValues(
                delegateeVotingWeightCheckpoints.ids,
                delegateeVotingWeightCheckpoints.votingWeights,
                _add,
                balance
            );
            if (oldDelegatee == address(0)) {
                _modifyCheckpointedValues(
                    delegatorVotingWeightCheckpoints.ids,
                    delegatorVotingWeightCheckpoints.votingWeights,
                    _subtract,
                    balance
                );
            }
        }
        emit DelegateeChanged(delegator, tokenId, oldDelegatee, delegatee);
        delegatorVotingWeightCheckpoints.delegatee = delegatee;
    }

    function _targetVotingWeightCheckpoints(address account, uint256 tokenId)
        private
        view
        returns (VotingWeightCheckpoints storage)
    {
        VotingWeightCheckpoints
            storage accountVotingWeightCheckpoints = _accountVotingWeightCheckpoints[
                account
            ][tokenId];
        address delegatee = accountVotingWeightCheckpoints.delegatee;
        return
            delegatee == address(0)
                ? accountVotingWeightCheckpoints
                : _accountVotingWeightCheckpoints[delegatee][tokenId];
    }

    function _modifyCheckpointedValues(
        uint256[] storage ids,
        uint256[] storage values,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private {
        uint256 newValue = ids.length == 0
            ? delta
            : op(values[ids.length - 1], delta);
        if (ids.length == 0 || ids[ids.length - 1] < _currentCheckpointId) {
            values.push(newValue);
            ids.push(_currentCheckpointId);
        } else {
            values[ids.length - 1] = newValue;
        }
    }

    function checkpointedVotingWeight(
        address account,
        uint256 tokenId,
        uint256 checkpointId
    ) public view returns (uint256) {
        require(
            checkpointId <= _currentCheckpointId,
            "Token: nonexistent checkpoint id"
        );
        VotingWeightCheckpoints
            storage votingWeightCkpts = _accountVotingWeightCheckpoints[
                account
            ][tokenId];
        uint256 index = votingWeightCkpts.ids.findClosest(checkpointId);
        return index == 0 ? 0 : votingWeightCkpts.votingWeights[index - 1];
    }

    function _tokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) private {
        require(tokenId != type(uint256).max, "Token: invalid token id");
        if (
            from != address(0) &&
            from != _msgSender() &&
            !isApprovedForAll(from, _msgSender())
        ) {
            _accountAllowances[from][_msgSender()][tokenId] -= amount;
        }
        if (from != address(0)) {
            require(
                _accountBalances[from][tokenId] >= amount,
                "Token: insufficient balance"
            );
            unchecked {
                _accountBalances[from][tokenId] -= amount;
            }
            VotingWeightCheckpoints
                storage target = _targetVotingWeightCheckpoints(from, tokenId);
            _modifyCheckpointedValues(
                target.ids,
                target.votingWeights,
                _subtract,
                amount
            );
        }
        if (to != address(0)) {
            _accountBalances[to][tokenId] += amount;

            VotingWeightCheckpoints
                storage target = _targetVotingWeightCheckpoints(to, tokenId);
            _modifyCheckpointedValues(
                target.ids,
                target.votingWeights,
                _add,
                amount
            );
        }
    }

    /**
     * IERC1155-safeTransferFrom
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public override whenNotPaused {
        _tokenTransfer(from, to, tokenId, amount);
        emit TransferSingle(_msgSender(), from, to, tokenId, amount);
        _doSafeTransferAcceptanceCheck(
            _msgSender(),
            from,
            to,
            tokenId,
            amount,
            data
        );
    }

    // function safeTransferFrom(
    //     address,
    //     address,
    //     uint256,
    //     uint256,
    //     bytes calldata
    // ) public pure override {
    //     revert("Token: please use batch transfer");
    // }

    /**
     * IERC1155-safeBatchTransferFrom
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _tokenTransfer(from, to, tokenIds[i], amounts[i]);
        }
        emit TransferBatch(_msgSender(), from, to, tokenIds, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            _msgSender(),
            from,
            to,
            tokenIds,
            amounts,
            data
        );
    }

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) public whenNotPaused onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(to != address(0), "Token: mint to the zero address");
            _tokenTransfer(address(0), to, tokenIds[i], amounts[i]);
            _modifyCheckpointedValues(
                _totalSupplyCheckpoints[tokenIds[i]].ids,
                _totalSupplyCheckpoints[tokenIds[i]].amounts,
                _add,
                amounts[i]
            );
        }

        emit TransferBatch(_msgSender(), address(0), to, tokenIds, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            _msgSender(),
            address(0),
            to,
            tokenIds,
            amounts,
            data
        );
    }

    function burnBatch(uint256[] calldata tokenIds, uint256[] calldata amounts)
        public
    {
        _burnBatch(_msgSender(), tokenIds, amounts);
    }

    function burnFromBatch(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public onlyRole(BURNER_ROLE) {
        _burnBatch(from, tokenIds, amounts);
    }

    function _burnBatch(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenTransfer(from, address(0), tokenIds[i], amounts[i]);
            _modifyCheckpointedValues(
                _totalSupplyCheckpoints[tokenIds[i]].ids,
                _totalSupplyCheckpoints[tokenIds[i]].amounts,
                _subtract,
                amounts[i]
            );
        }

        emit TransferBatch(_msgSender(), from, address(0), tokenIds, amounts);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) private {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155Received(
                    operator,
                    from,
                    tokenId,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable.onERC1155Received.selector
                ) {
                    revert("Token: Receiver rejected");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("Token: Receiver not exist");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) private {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(
                    operator,
                    from,
                    tokenIds,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector
                ) {
                    revert("Token: Receiver rejected");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("Token: Receiver not exist");
            }
        }
    }

    /**
     * Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pause: paused");
        _;
    }

    /**
     * Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pause: not paused");
        _;
    }

    /**
     * Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public whenNotPaused onlyRole(PAUSER_ROLE) {
        _paused = true;
        emit Pause(_msgSender(), true);
    }

    /**
     * Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public whenPaused onlyRole(PAUSER_ROLE) {
        _paused = false;
        emit Pause(_msgSender(), false);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    /**
     * IERC165-supportsInterface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165Upgradeable, UUPS)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "./Upgrade/UUPS.sol";
import "./AccessControl.sol";
import "./Token.sol";

import "@openzeppelin/contracts-upgradeable/utils/ArraysUpgradeable.sol";

contract Voting is Initializable, ContextUpgradeable, EIP712Upgradeable, UUPS {
    using ArraysUpgradeable for uint256[];

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    bytes32 public constant BALLOT_TYPEHASH =
        keccak256("Ballot(uint256 id,uint8 choice)");
    bytes32 private constant DELEGATION_TYPEHASH =
        keccak256(
            "Delegation(address delegatee,uint256 tokenId,uint256 nonce,uint256 expiry)"
        );

    /**
     * Eventual states (*): {Defeated}, {Succeeded}
     * {VoteState} can only be inferred
     *
     * -> Pending ->
     * |           |
     * <-----------
     * |
     * -> Active -> Defeated (*)
     *           -> Succeeded (*)
     */
    enum VoteState {
        Pending,
        Active,
        Succeeded,
        Defeated
    }

    enum VoteChoice {
        No,
        Aye,
        Abstain
    }

    event VoteCreated(
        uint256 indexed id,
        uint256 indexed tokenId,
        uint256 indexed checkpointId,
        address creator,
        uint256 voteStart,
        uint256 voteEnd,
        uint8 quorumNumerator,
        uint8 approvalRateNumerator
    );

    event VoteCast(
        address indexed voter,
        uint256 indexed id,
        uint8 choice,
        uint256 weight
    );

    struct Vote {
        uint256 tokenId;
        uint256 checkpointId;
        uint256 noVotes;
        uint256 ayeVotes;
        uint256 abstainVotes;
        mapping(address => uint256) hasVoted;
        uint256 voteStart;
        uint256 voteEnd;
        uint8 quorumNumerator;
        uint8 approvalRateNumerator;
    }

    AccessControl private accessControl;
    Token private token;
    mapping(uint256 => Vote) private _votes;
    mapping(address => uint256) private _nonces;

    /**
     * Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     */
    modifier onlyRole(bytes32 role) {
        require(
            accessControl.hasRole(role, _msgSender()),
            "Voting: Missing role"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(AccessControl accessControlAddress, Token tokenAddress)
        public
        initializer
    {
        accessControl = accessControlAddress;
        token = tokenAddress;
    }

    function currentNonce(address account) public view returns (uint256) {
        return _nonces[account];
    }

    function _useNonce(address account) private returns (uint256) {
        return _nonces[account]++;
    }

    function _EIP712NameHash() internal pure override returns (bytes32) {
        return "capita.io/voting";
    }

    function _EIP712VersionHash() internal pure override returns (bytes32) {
        return "0";
    }

    function createVote(
        uint256 id,
        uint256 tokenId,
        uint256 voteStart,
        uint256 voteEnd,
        uint8 quorumNumerator,
        uint8 approvalRateNumerator
    ) external onlyRole(GOVERNOR_ROLE) {
        Vote storage vote = _votes[id];
        vote.tokenId = tokenId;
        vote.checkpointId = token.createCheckpoint();
        vote.voteStart = voteStart;
        vote.voteEnd = voteEnd;
        vote.quorumNumerator = quorumNumerator;
        vote.approvalRateNumerator = approvalRateNumerator;

        emit VoteCreated(
            id,
            tokenId,
            vote.checkpointId,
            _msgSender(),
            voteStart,
            voteEnd,
            quorumNumerator,
            approvalRateNumerator
        );
    }

    function getVote(uint256 id)
        public
        view
        returns (
            uint256 noVotes,
            uint256 ayeVotes,
            uint256 abstainVotes,
            uint256 voteStart,
            uint256 voteEnd
        )
    {
        return (
            _votes[id].noVotes,
            _votes[id].ayeVotes,
            _votes[id].abstainVotes,
            _votes[id].voteStart,
            _votes[id].voteEnd
        );
    }

    function hasVoted(uint256 id, address account) public view returns (bool) {
        return _votes[id].hasVoted[account] > 0;
    }

    function castVote(uint256 id, uint8 choice) public returns (uint256) {
        return _castVote(id, _msgSender(), choice);
    }

    function generateVotingCertificate(uint256 id, uint8 choice)
        public
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(abi.encode(BALLOT_TYPEHASH, id, choice))
            );
    }

    function castVoteBySig(
        uint256 id,
        uint8 choice,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public returns (uint256) {
        address voter = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(abi.encode(BALLOT_TYPEHASH, id, choice))
            ),
            v,
            r,
            s
        );
        return _castVote(id, voter, choice);
    }

    /**
     * Check that the vote has not been cast yet.
     */
    function _castVote(
        uint256 id,
        address account,
        uint8 choice
    ) private returns (uint256) {
        require(state(id) == VoteState.Active, "Voting: not accepting votes");

        uint256 weight = token.checkpointedVotingWeight(
            account,
            _votes[id].tokenId,
            _votes[id].checkpointId
        );
        _countVote(id, account, choice, weight);

        emit VoteCast(account, id, choice, weight);

        return weight;
    }

    function _countVote(
        uint256 id,
        address account,
        uint8 choice,
        uint256 weight
    ) private {
        Vote storage vote = _votes[id];

        require(vote.hasVoted[account] > 0, "Voting: vote already cast");
        vote.hasVoted[account] = block.number;

        if (choice == uint8(VoteChoice.No)) {
            vote.noVotes += weight;
        } else if (choice == uint8(VoteChoice.Aye)) {
            vote.ayeVotes += weight;
        } else if (choice == uint8(VoteChoice.Abstain)) {
            vote.abstainVotes += weight;
        } else {
            revert("Voting: invalid vote choice");
        }
    }

    function delegate(address delegatee, uint256 tokenId) public {
        token.delegate(_msgSender(), delegatee, tokenId);
    }

    function generateDelegationCertificate(
        address delegator,
        address delegatee,
        uint256 tokenId,
        uint256 expiry
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        DELEGATION_TYPEHASH,
                        delegatee,
                        tokenId,
                        currentNonce(delegator),
                        expiry
                    )
                )
            );
    }

    function delegateBySig(
        address delegatee,
        uint256 tokenId,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp >= expiry, "Voting, signature expired");
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        DELEGATION_TYPEHASH,
                        delegatee,
                        tokenId,
                        nonce,
                        expiry
                    )
                )
            ),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "Voting: invalid nonce");
        token.delegate(signer, delegatee, tokenId);
    }

    function _percentage(uint256 total, uint8 percentageNumerator)
        private
        pure
        returns (uint256)
    {
        return
            (total / 100) *
            percentageNumerator +
            (((total % 100) * percentageNumerator) / 100);
    }

    function getVotingCriteria(uint256 id)
        public
        view
        returns (
            uint256 quorum,
            uint256 approvalMinimum,
            uint256 earlyVoteSuccessAyeVotesMinimum,
            uint256 earlyVoteDefeatedNoVotesMinimum
        )
    {
        Vote storage vote = _votes[id];
        uint256 totalVotingPower = token.checkpointedTotalSupply(
            vote.tokenId,
            vote.checkpointId
        );
        return (
            _percentage(totalVotingPower, vote.quorumNumerator),
            _percentage(
                vote.noVotes + vote.ayeVotes,
                vote.approvalRateNumerator
            ),
            _percentage(
                totalVotingPower - vote.abstainVotes,
                vote.approvalRateNumerator
            ),
            _percentage(
                totalVotingPower - vote.abstainVotes,
                100 - vote.approvalRateNumerator
            )
        );
    }

    /**
     * Returns {VoteState.Succeeded} and {VoteState.Defeated} when:
     * (1) both quorum and approval rate are satisfied, and
     * (2) the result can be determined when assuming the rest of the voters
     *     all vote against such result. (it follows that quorum is assumed satified)
     */
    function state(uint256 id) public view returns (VoteState) {
        Vote storage vote = _votes[id];
        uint256 voteStart = vote.voteStart;
        if (voteStart > block.number) {
            return VoteState.Pending;
        }
        uint256 totalVotingPower = token.checkpointedTotalSupply(
            vote.tokenId,
            vote.checkpointId
        );
        if (
            (vote.noVotes + vote.ayeVotes + vote.abstainVotes) >
            _percentage(totalVotingPower, vote.quorumNumerator) &&
            vote.ayeVotes >
            _percentage(
                vote.noVotes + vote.ayeVotes,
                vote.approvalRateNumerator
            )
        ) {
            return VoteState.Succeeded;
        }
        uint256 voteEnd = vote.voteEnd;
        if (
            voteEnd < block.number ||
            (vote.noVotes >
                _percentage(
                    totalVotingPower - vote.abstainVotes,
                    100 - vote.approvalRateNumerator
                ))
        ) {
            return VoteState.Defeated;
        }
        if (
            vote.ayeVotes >
            _percentage(
                totalVotingPower - vote.abstainVotes,
                vote.approvalRateNumerator
            )
        ) {
            return VoteState.Succeeded;
        }

        return VoteState.Active;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {}

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(
            AddressUpgradeable.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // // Upgrades from old implementations will perform a rollback test. This test requires the new
        // // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // // this special case will break upgrade paths from old UUPS implementation to new ones.
        // if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
        //     _setImplementation(newImplementation);
        // } else {
        try
            IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()
        returns (bytes32 slot) {
            require(
                slot == _IMPLEMENTATION_SLOT,
                "ERC1967: unsupported proxiableUUID"
            );
        } catch {
            revert("ERC1967: new implementation is not UUPS");
        }
        _upgradeToAndCall(newImplementation, data, forceCall);
        // }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data)
        private
        returns (bytes memory)
    {
        require(
            AddressUpgradeable.isContract(target),
            "Address: delegate call to non-contract"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Array {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element)
        internal
        view
        returns (uint256)
    {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * Find the index after the closest element which is strictly less than {element}
     * Return {0} if no such index exists
     */

    function findClosest(uint256[] storage array, uint256 element)
        internal
        view
        returns (uint256)
    {
        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return low;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev Collection of functions related to array types.
 */
library ArraysUpgradeable {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
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
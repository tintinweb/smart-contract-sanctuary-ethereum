// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./components/Governor.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IGovernanceToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IWhitelistedTokens.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/IProposalGateway.sol";
import "./libraries/ExceptionsLibrary.sol";

contract Pool is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IPool,
    Governor
{
    IService public service;

    IGovernanceToken public token;

    ITGE public tge;

    uint256 private _ballotQuorumThreshold;

    uint256 private _ballotDecisionThreshold;

    uint256 private _ballotLifespan;

    string private _poolRegisteredName;

    string private _poolTrademark;

    uint256 private _poolJurisdiction;

    string private _poolEIN;

    uint256 private _poolMetadataIndex;

    uint256 private _poolEntityType;

    string private _poolDateOfIncorporation;

    address public primaryTGE;

    address[] private _tgeList;

    address public gnosisSafe;
    address public gnosisGovernance;

    /**
    @dev block delay for executeBallot
    First value is base delay applied to all ballots to mitigate FlashLoan attacks.
    Rest of values are ballot type bound delays to allow pool shareholders prevent bugged/hacked ballot execution.
    Extra storage for future extensibility.
    */
    uint256[10] public ballotExecDelay;

    /**
    @dev threshold amounts for executeBallot delay
    [0] - TransferETH,
    [1] - TransferERC20,
    Extra storage for future extensibility.
    */
    uint256[10] public ballotExecDelayThresholdAmount;

    // INITIALIZER AND CONFIGURATOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address poolCreator_,
        uint256 jurisdiction_,
        string memory poolEIN_,
        string memory dateOfIncorporation,
        uint256 poolEntityType_,
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] memory ballotExecDelay_,
        uint256[10] memory ballotExecDelayThresholdAmount_,
        uint256 metadataIndex,
        string memory trademark
    ) public initializer {
        require(poolCreator_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        __Ownable_init();

        service = IService(msg.sender);
        _transferOwnership(poolCreator_);
        _poolJurisdiction = jurisdiction_;
        _poolEIN = poolEIN_;
        _poolDateOfIncorporation = dateOfIncorporation;
        _poolEntityType = poolEntityType_;
        _poolTrademark = trademark;
        _poolMetadataIndex = metadataIndex;

        require(
            ballotQuorumThreshold_ <= 10000,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(
            ballotDecisionThreshold_ <= 10000,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(ballotLifespan_ > 0, ExceptionsLibrary.INVALID_VALUE);

        _ballotQuorumThreshold = ballotQuorumThreshold_;
        _ballotDecisionThreshold = ballotDecisionThreshold_;
        _ballotLifespan = ballotLifespan_;
        ballotExecDelay = ballotExecDelay_;
        ballotExecDelayThresholdAmount = ballotExecDelayThresholdAmount_;
    }

    function setToken(address token_) external onlyService {
        require(token_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        token = IGovernanceToken(token_);
    }

    function setTGE(address tge_) external onlyService {
        require(tge_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        tge = ITGE(tge_);
    }

    function setPrimaryTGE(address tge_) external onlyService {
        require(tge_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        primaryTGE = tge_;
    }

    function setRegisteredName(string memory registeredName)
        external
        onlyServiceOwner
    {
        require(
            bytes(_poolRegisteredName).length == 0,
            ExceptionsLibrary.ALREADY_SET
        );
        require(
            bytes(registeredName).length != 0,
            ExceptionsLibrary.VALUE_ZERO
        );
        _poolRegisteredName = registeredName;
    }

    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] memory ballotExecDelay_,
        uint256[10] memory ballotExecDelayThresholdAmount_
    ) external onlyPool whenServiceNotPaused {
        require(
            ballotQuorumThreshold_ <= 10000,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(
            ballotDecisionThreshold_ <= 10000,
            ExceptionsLibrary.INVALID_VALUE
        );
        require(ballotLifespan_ > 0, ExceptionsLibrary.INVALID_VALUE);

        // averaging 7500 blocks per day, keeping delays at 10 days max
        // should be updated when blocks per day change
        for (uint256 i = 0; i < ballotExecDelay_.length; i++) {
            require(
                ballotExecDelay_[i] < 7500 * 10,
                ExceptionsLibrary.INVALID_VALUE
            );
        }

        _ballotQuorumThreshold = ballotQuorumThreshold_;
        _ballotDecisionThreshold = ballotDecisionThreshold_;
        _ballotLifespan = ballotLifespan_;
        ballotExecDelay = ballotExecDelay_;
        ballotExecDelayThresholdAmount = ballotExecDelayThresholdAmount_;
    }

    function setGnosisSafe(address _gnosisSafe) external onlyService {
        require(_gnosisSafe != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        gnosisSafe = _gnosisSafe;
    }

    function setGnosisGovernance(address _gnosisGovernance)
        external
        onlyService
    {
        require(
            _gnosisGovernance != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        gnosisGovernance = _gnosisGovernance;
    }

    // PUBLIC FUNCTIONS

    function castVote(
        uint256 proposalId,
        uint256 votes,
        bool support
    ) external nonReentrant whenServiceNotPaused {
        if (votes == type(uint256).max) {
            votes = token.unlockedBalanceOf(msg.sender, proposalId);
        } else {
            require(
                votes <= token.unlockedBalanceOf(msg.sender, proposalId),
                ExceptionsLibrary.LOW_UNLOCKED_BALANCE
            );
        }
        require(votes > 0, ExceptionsLibrary.VALUE_ZERO);
        // TODO: do not let to change votes (if have forVotes dont let vote against)
        // if (support) {
        //     proposals[proposalId].againstVotes
        // }
        _castVote(proposalId, votes, support);
        token.lock(
            msg.sender,
            votes,
            support,
            getProposal(proposalId).endBlock,
            proposalId
        );
    }

    function proposeSingleAction(
        address target,
        uint256 value,
        bytes memory cd,
        string memory description,
        IProposalGateway.ProposalType proposalType,
        uint256 amountERC20
    )
        external
        onlyProposalGateway
        whenServiceNotPaused
        returns (uint256 proposalId)
    {
        // base delay
        uint256 execDelay = service.ballotExecDelay(0);

        if (
            proposalType == IProposalGateway.ProposalType.TransferETH &&
            value >= ballotExecDelayThresholdAmount[0]
        ) execDelay += ballotExecDelay[uint256(proposalType)];

        if (
            proposalType == IProposalGateway.ProposalType.TransferERC20 &&
            amountERC20 >= ballotExecDelayThresholdAmount[1]
        ) execDelay += ballotExecDelay[uint256(proposalType)];

        if (
            proposalType != IProposalGateway.ProposalType.CancelProposal &&
            proposalType != IProposalGateway.ProposalType.TransferETH &&
            proposalType != IProposalGateway.ProposalType.TransferERC20
        ) execDelay += ballotExecDelay[uint256(proposalType)];

        proposalId = _propose(
            _ballotLifespan,
            _ballotQuorumThreshold,
            _ballotDecisionThreshold,
            target,
            value,
            cd,
            description,
            _getTotalSupply() -
                _getTotalTGELockedTokens() -
                token.balanceOf(service.protocolTreasury()),
            execDelay,
            proposalType
        );
    }

    function addTGE(address tge_) external onlyService {
        _tgeList.push(tge_);
    }

    function getTVL() public returns (uint256) {
        IQuoter quoter = service.uniswapQuoter();
        IWhitelistedTokens whitelistedTokens = service.whitelistedTokens();
        address[] memory tokenWhitelist = whitelistedTokens.tokenWhitelist(); // service.tokenWhitelist();
        uint256 tvl = 0;

        for (uint256 i = 0; i < tokenWhitelist.length; i++) {
            if (tokenWhitelist[i] == address(0)) {
                tvl += address(this).balance;
            } else {
                uint256 balance = IERC20Upgradeable(tokenWhitelist[i])
                    .balanceOf(address(this));
                if (balance > 0) {
                    tvl += quoter.quoteExactInput(
                        whitelistedTokens.tokenSwapPath(tokenWhitelist[i]),
                        balance
                    );
                }
            }
        }
        return tvl;
    }

    function executeBallot(uint256 proposalId) external whenServiceNotPaused {
        _executeBallot(proposalId, gnosisGovernance, service);
    }

    function cancelBallot(uint256 proposalId) external onlyPool {
        _cancelBallot(proposalId);
    }

    function serviceCancelBallot(uint256 proposalId) external onlyService {
        _cancelBallot(proposalId);
    }

    // RECEIVE

    receive() external payable {
        // Supposed to be empty
    }

    // PUBLIC VIEW FUNCTIONS

    function getPoolTrademark() external view returns (string memory) {
        return _poolTrademark;
    }

    function getPoolRegisteredName() public view returns (string memory) {
        return _poolRegisteredName;
    }

    function getBallotQuorumThreshold() public view returns (uint256) {
        return _ballotQuorumThreshold;
    }

    function getBallotDecisionThreshold() public view returns (uint256) {
        return _ballotDecisionThreshold;
    }

    function getBallotLifespan() public view returns (uint256) {
        return _ballotLifespan;
    }

    function getPoolJurisdiction() public view returns (uint256) {
        return _poolJurisdiction;
    }

    function getPoolEIN() public view returns (string memory) {
        return _poolEIN;
    }

    function getPoolDateOfIncorporation() public view returns (string memory) {
        return _poolDateOfIncorporation;
        // IMetadata metadata = service.metadata();
        // return metadata.getQueueInfo(_poolMetadataIndex).dateOfIncorporation;
    }

    function getPoolEntityType() public view returns (uint256) {
        return _poolEntityType;
    }

    function getPoolMetadataIndex() public view returns (uint256) {
        return _poolMetadataIndex;
    }

    function maxProposalId() public view returns (uint256) {
        return lastProposalId;
    }

    function isDAO() public view returns (bool) {
        return (ITGE(primaryTGE).state() == ITGE.State.Successful);
    }

    function getTGEList() public view returns (address[] memory) {
        return _tgeList;
    }

    function owner()
        public
        view
        override(IPool, OwnableUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    function getProposalType(uint256 proposalId)
        public
        view
        returns (IProposalGateway.ProposalType)
    {
        return _getProposalType(proposalId);
    }

    // INTERNAL FUNCTIONS

    function _afterProposalCreated(uint256 proposalId) internal override {
        service.addProposal(proposalId);
    }

    /**
     * @dev Returns token total supply
     */
    function _getTotalSupply() internal view override returns (uint256) {
        return token.totalSupply();
    }

    /**
     * @dev Returns amount of tokens currently locked in TGE vesting contract(s)
     */
    function _getTotalTGELockedTokens()
        internal
        view
        override
        returns (uint256)
    {
        return token.totalTGELockedTokens();
    }

    // MODIFIER

    modifier onlyService() {
        require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    modifier onlyServiceOwner() {
        require(
            msg.sender == service.owner(),
            ExceptionsLibrary.NOT_SERVICE_OWNER
        );
        _;
    }

    modifier onlyProposalGateway() {
        require(
            msg.sender == service.proposalGateway(),
            ExceptionsLibrary.NOT_PROPOSAL_GATEWAY
        );
        _;
    }

    modifier onlyPool() {
        require(msg.sender == address(this), ExceptionsLibrary.NOT_POOL);
        _;
    }

    modifier whenServiceNotPaused() {
        require(!service.paused(), ExceptionsLibrary.SERVICE_PAUSED);
        _;
    }

    function test831() external pure returns (uint256) {
        return 3;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/gnosis/IGnosisGovernance.sol";
import "../interfaces/IService.sol";
import "../interfaces/IDirectory.sol";
import "../interfaces/IProposalGateway.sol";

abstract contract Governor {
    struct Proposal {
        uint256 ballotQuorumThreshold;
        uint256 ballotDecisionThreshold;
        address target;
        uint256 value;
        bytes callData;
        uint256 startBlock;
        uint256 endBlock; // startBlock + ballotLifespan
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        ProposalExecutionState state;
        string description;
        uint256 totalSupply;
        uint256 lastVoteBlock;
        IProposalGateway.ProposalType proposalType;
        uint256 execDelay;
    }

    mapping(uint256 => Proposal) private _proposals;

    mapping(address => mapping(uint256 => uint256)) private _forVotes;
    mapping(address => mapping(uint256 => uint256)) private _againstVotes;

    uint256 public lastProposalId;

    enum ProposalState {
        None,
        Active,
        Failed,
        Successful,
        Executed,
        Cancelled
    }

    enum ProposalExecutionState {
        Initialized,
        Rejected,
        Accomplished,
        Cancelled
    }

    // EVENTS

    event ProposalCreated(
        uint256 proposalId,
        uint256 quorum,
        address targets,
        uint256 values,
        bytes calldatas,
        string description
    );

    event VoteCast(
        address voter,
        uint256 proposalId,
        uint256 votes,
        bool support
    );

    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);

    // PUBLIC VIEW FUNCTIONS

    function proposalState(uint256 proposalId)
        public
        view
        returns (ProposalState)
    {
        Proposal memory proposal = _proposals[proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (proposal.startBlock == 0) {
            return ProposalState.None;
        }

        if (proposal.state == ProposalExecutionState.Cancelled) {
            return ProposalState.Cancelled;
        }

        uint256 totalAvailableVotes = _getTotalSupply() -
            _getTotalTGELockedTokens();
        uint256 quorumVotes = (totalAvailableVotes *
            proposal.ballotQuorumThreshold);
        uint256 totalCastVotes = proposal.forVotes + proposal.againstVotes;

        // require absolute majority to cancel proposal
        if (
            proposal.proposalType ==
            IProposalGateway.ProposalType.CancelProposal
        ) {
            if (proposal.forVotes * 2 > totalAvailableVotes) {
                return ProposalState.Successful;
            }

            if (block.number > proposal.endBlock) return ProposalState.Failed;

            return ProposalState.Active;
        }

        if (
            totalCastVotes * 10000 >= quorumVotes && // /10000 because 10000 = 100%
            proposal.forVotes * 10000 >
            totalCastVotes * proposal.ballotDecisionThreshold && // * 10000 because 10000 = 100%
            quorumVotes < (2 * totalCastVotes)
        ) {
            return ProposalState.Successful;
        }
        if (
            (totalAvailableVotes - proposal.againstVotes) * 10000 <=
            totalAvailableVotes * proposal.ballotDecisionThreshold
        ) {
            return ProposalState.Failed;
        }
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        if (block.number > proposal.endBlock) {
            if (
                totalVotes >= quorumVotes &&
                proposal.forVotes * 10000 >
                totalVotes * proposal.ballotDecisionThreshold
            ) {
                return ProposalState.Successful;
            } else return ProposalState.Failed;
        }
        return ProposalState.Active;
    }

    function getProposalBallotQuorumThreshold(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _proposals[proposalId].ballotQuorumThreshold;
    }

    function getProposalBallotDecisionThreshold(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _proposals[proposalId].ballotDecisionThreshold;
    }

    function getProposalBallotLifespan(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return
            _proposals[proposalId].endBlock - _proposals[proposalId].startBlock;
    }

    function getProposal(uint256 proposalId)
        public
        view
        returns (Proposal memory)
    {
        return _proposals[proposalId];
    }

    function getForVotes(address user, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _forVotes[user][proposalId];
    }

    function getAgainstVotes(address user, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _againstVotes[user][proposalId];
    }

    function _getProposalType(uint256 proposalId)
        internal
        view
        returns (IProposalGateway.ProposalType)
    {
        return _proposals[proposalId].proposalType;
    }

    // INTERNAL FUNCTIONS

    function _propose(
        uint256 ballotLifespan,
        uint256 ballotQuorumThreshold,
        uint256 ballotDecisionThreshold,
        address target,
        uint256 value,
        bytes memory callData,
        string memory description,
        uint256 totalSupply,
        uint256 execDelay,
        IProposalGateway.ProposalType proposalType
    ) internal returns (uint256 proposalId) {
        proposalId = ++lastProposalId;
        _proposals[proposalId] = Proposal({
            ballotQuorumThreshold: ballotQuorumThreshold,
            ballotDecisionThreshold: ballotDecisionThreshold,
            target: target,
            value: value,
            callData: callData,
            startBlock: block.number,
            endBlock: block.number + ballotLifespan,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            state: ProposalExecutionState.Initialized,
            description: description,
            totalSupply: totalSupply,
            lastVoteBlock: 0,
            execDelay: execDelay,
            proposalType: proposalType
        });
        _afterProposalCreated(proposalId);

        emit ProposalCreated(
            proposalId,
            ballotQuorumThreshold,
            target,
            value,
            callData,
            description
        );
    }

    function _castVote(
        uint256 proposalId,
        uint256 votes,
        bool support
    ) internal {
        require(
            _proposals[proposalId].endBlock > block.number,
            ExceptionsLibrary.VOTING_FINISHED
        );

        if (support) {
            _proposals[proposalId].forVotes += votes;
            _forVotes[msg.sender][proposalId] += votes;
        } else {
            _proposals[proposalId].againstVotes += votes;
            _againstVotes[msg.sender][proposalId] += votes;
        }

        _proposals[proposalId].lastVoteBlock = block.number;

        emit VoteCast(msg.sender, proposalId, votes, support);
    }

    function _executeBallot(
        uint256 proposalId,
        address gnosisGovernance,
        IService service
    ) internal {
        Proposal memory proposal = _proposals[proposalId];

        require(
            proposalState(proposalId) == ProposalState.Successful,
            ExceptionsLibrary.WRONG_STATE
        );
        require(
            _proposals[proposalId].state == ProposalExecutionState.Initialized,
            ExceptionsLibrary.ALREADY_EXECUTED
        );

        // Mitigate against FlashLoan attacks
        // Give pool shareholders time to cancel bugged/hacked ballot execution
        require(
            proposal.lastVoteBlock + proposal.execDelay <= block.number,
            ExceptionsLibrary.BLOCK_DELAY
        );

        _proposals[proposalId].executed = true;

        (bool success, bytes memory returndata) = proposal.target.call{
            value: proposal.value
        }(proposal.callData);

        if (
            proposal.proposalType == IProposalGateway.ProposalType.TransferETH
        ) {
            service.addEvent(IDirectory.EventType.TransferETH, proposalId);
        }

        if (
            proposal.proposalType == IProposalGateway.ProposalType.TransferERC20
        ) {
            service.addEvent(IDirectory.EventType.TransferERC20, proposalId);
        }

        if (proposal.proposalType == IProposalGateway.ProposalType.TGE) {
            service.addEvent(IDirectory.EventType.TGE, proposalId);
        }
        /*
        IGnosisGovernance(gnosisGovernance).executeTransfer(
            address(0),
            proposal.target,
            proposal.value
        );
        */

        // AddressUpgradeable.verifyCallResult(
        //     success,
        //     returndata,
        //     errorMessage
        // );

        // require(success, "Invalid execution result");

        if (success) {
            _proposals[proposalId].state = ProposalExecutionState.Accomplished;
        } else {
            _proposals[proposalId].state = ProposalExecutionState.Rejected;
        }

        emit ProposalExecuted(proposalId);
    }

    function _cancelBallot(uint256 proposalId) internal {
        require(
            proposalState(proposalId) == ProposalState.Active ||
                proposalState(proposalId) == ProposalState.Successful,
            ExceptionsLibrary.WRONG_STATE
        );

        _proposals[proposalId].state = ProposalExecutionState.Cancelled;

        emit ProposalCancelled(proposalId);
    }

    function _afterProposalCreated(uint256 proposalId) internal virtual;

    function _getTotalSupply() internal view virtual returns (uint256);

    function _getTotalTGELockedTokens() internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./IDirectory.sol";
import "./ITGE.sol";
import "./IMetadata.sol";
import "./IWhitelistedTokens.sol";

interface IService {
    function initialize(
        IDirectory directory_,
        address poolBeacon_,
        address proposalGateway_,
        address tokenBeacon_,
        address tgeBeacon_,
        IMetadata metadata_,
        uint256 fee_,
        uint256[13] memory ballotParams,
        ISwapRouter uniswapRouter_,
        IQuoter uniswapQuoter_,
        IWhitelistedTokens whitelistedTokens_,
        uint256 _protocolTokenFee
    ) external;

    function createSecondaryTGE(ITGE.TGEInfo memory tgeInfo) external;

    function addProposal(uint256 proposalId) external;

    function addEvent(IDirectory.EventType eventType, uint256 proposalId)
        external;

    function directory() external view returns (IDirectory);

    // function isTokenWhitelisted(address token) external view returns (bool);

    function tokenWhitelist() external view returns (address[] memory);

    function owner() external view returns (address);

    function proposalGateway() external view returns (address);

    function uniswapRouter() external view returns (ISwapRouter);

    function uniswapQuoter() external view returns (IQuoter);

    function whitelistedTokens() external view returns (IWhitelistedTokens);

    function metadata() external view returns (IMetadata);

    // function tokenSwapPath(address) external view returns (bytes memory);

    // function tokenSwapReversePath(address) external view returns (bytes memory);

    function protocolTreasury() external view returns (address);

    function protocolTokenFee() external view returns (uint256);

    function getMinSoftCap() external view returns (uint256);

    function getProtocolTokenFee(uint256 amount)
        external
        view
        returns (uint256);

    function gnosisProxyFactory() external view returns (address);

    function gnosisSingleton() external view returns (address);

    function ballotExecDelay(uint256 _index) external returns (uint256);

    function ballotExecDelayThresholdAmount(uint256 _index)
        external
        returns (uint256);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IService.sol";
import "./ITGE.sol";
import "./IGovernanceToken.sol";
import "./IProposalGateway.sol";

interface IPool {
    function initialize(
        address poolCreator_,
        uint256 jurisdiction_,
        string memory poolEIN_,
        string memory dateOfIncorporation,
        uint256 entityType,
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] memory ballotExecDelay,
        uint256[10] memory ballotExecDelayThresholdAmount,
        uint256 metadataIndex,
        string memory trademark
    ) external;

    function setToken(address token_) external;

    function setTGE(address tge_) external;

    function setPrimaryTGE(address tge_) external;

    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] memory ballotExecDelay,
        uint256[10] memory ballotExecDelayThresholdAmount
    ) external;

    function proposeSingleAction(
        address target,
        uint256 value,
        bytes memory cd,
        string memory description,
        IProposalGateway.ProposalType proposalType,
        uint256 amountERC20
    ) external returns (uint256 proposalId);

    function cancelBallot(uint256 proposalId) external;

    function serviceCancelBallot(uint256 proposalId) external;

    function getTVL() external returns (uint256);

    function owner() external view returns (address);

    function service() external view returns (IService);

    function token() external view returns (IGovernanceToken);

    function tge() external view returns (ITGE);

    function maxProposalId() external view returns (uint256);

    function isDAO() external view returns (bool);

    function getPoolTrademark() external view returns (string memory);

    function addTGE(address tge_) external;

    function gnosisSafe() external view returns (address);

    function setGnosisSafe(address _gnosisSafe) external;

    function setGnosisGovernance(address _gnosisGovernance) external;

    function gnosisGovernance() external view returns (address);

    function getProposalType(uint256 proposalId)
        external
        view
        returns (IProposalGateway.ProposalType);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IService.sol";

interface IGovernanceToken is IERC20Upgradeable {
    struct TokenInfo {
        string name;
        string symbol;
        uint256 cap;
    }

    function initialize(address pool_, TokenInfo memory info) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function lock(
        address account,
        uint256 amount,
        bool support,
        uint256 deadline,
        uint256 proposalId
    ) external;

    function cap() external view returns (uint256);

    function minUnlockedBalanceOf(address from) external view returns (uint256);

    function unlockedBalanceOf(address account, uint256 proposalId)
        external
        view
        returns (uint256);

    function pool() external view returns (address);

    function service() external view returns (IService);

    function decimals() external view returns (uint8);

    function increaseTotalTGELockedTokens(uint256 _amount) external;

    function decreaseTotalTGELockedTokens(uint256 _amount) external;

    function totalTGELockedTokens() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITGE {
    struct TGEInfo {
        string metadataURI;
        uint256 price;
        uint256 hardcap;
        uint256 softcap;
        uint256 minPurchase;
        uint256 maxPurchase;
        uint256 lockupPercent;
        uint256 lockupDuration;
        uint256 lockupTVL;
        uint256 duration;
        address[] userWhitelist;
        address unitOfAccount;
    }

    function initialize(
        address owner_,
        address token_,
        TGEInfo memory info
    ) external;

    function redeem() external;

    function maxPurchaseOf(address account) external view returns (uint256);

    enum State {
        Active,
        Failed,
        Successful
    }

    function state() external view returns (State);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IWhitelistedTokens {
    function tokenWhitelist() external view returns (address[] memory);

    function isTokenWhitelisted(address token) external view returns (bool);

    function tokenSwapPath(address) external view returns (bytes memory);

    function tokenSwapReversePath(address) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IMetadata {
    enum Status {
        NotUsed,
        Used
    }

    struct QueueInfo {
        uint256 jurisdiction;
        string EIN;
        string dateOfIncorporation;
        uint256 entityType;
        Status status;
        address owner;
    }

    function initialize() external;

    function lockRecord(uint256 jurisdiction) external returns (uint256);

    function getQueueInfo(uint256 id) external view returns (QueueInfo memory);

    function setOwner(uint256 id, address owner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IProposalGateway {
    enum ProposalType {
        None,
        TransferETH,
        TransferERC20,
        TGE,
        GovernanceSettings,
        CancelProposal
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ExceptionsLibrary {
    string public constant ADDRESS_ZERO = "ADDRESS_ZERO";
    string public constant INCORRECT_ETH_PASSED = "INCORRECT_ETH_PASSED";
    string public constant NO_COMPANY = "NO_COMPANY";
    string public constant INVALID_TOKEN = "INVALID_TOKEN";
    string public constant NOT_POOL = "NOT_POOL";
    string public constant NOT_TGE = "NOT_TGE";
    string public constant NOT_PROPOSAL_GATEWAY = "NOT_PROPOSAL_GATEWAY";
    string public constant NOT_POOL_OWNER = "NOT_POOL_OWNER";
    string public constant NOT_SERVICE_OWNER = "NOT_SERVICE_OWNER";
    string public constant IS_DAO = "IS_DAO";
    string public constant NOT_DAO = "NOT_DAO";
    string public constant NOT_SHAREHOLDER = "NOT_SHAREHOLDER";
    string public constant NOT_WHITELISTED = "NOT_WHITELISTED";
    string public constant ALREADY_WHITELISTED = "ALREADY_WHITELISTED";
    string public constant ALREADY_NOT_WHITELISTED = "ALREADY_NOT_WHITELISTED";
    string public constant NOT_SERVICE = "NOT_SERVICE";
    string public constant WRONG_STATE = "WRONG_STATE";
    string public constant TRANSFER_FAILED = "TRANSFER_FAILED";
    string public constant CLAIM_NOT_AVAILABLE = "CLAIM_NOT_AVAILABLE";
    string public constant NO_LOCKED_BALANCE = "NO_LOCKED_BALANCE";
    string public constant LOCKUP_TVL_NOT_REACHED = "LOCKUP_TVL_NOT_REACHED";
    string public constant HARDCAP_OVERFLOW = "HARDCAP_OVERFLOW";
    string public constant MAX_PURCHASE_OVERFLOW = "MAX_PURCHASE_OVERFLOW";
    string public constant HARDCAP_OVERFLOW_REMAINING_SUPPLY =
        "HARDCAP_OVERFLOW_REMAINING_SUPPLY";
    string public constant HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY =
        "HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY";
    string public constant MIN_PURCHASE_UNDERFLOW = "MIN_PURCHASE_UNDERFLOW";
    string public constant LOW_UNLOCKED_BALANCE = "LOW_UNLOCKED_BALANCE";
    string public constant ZERO_PURCHASE_AMOUNT = "ZERO_PURCHASE_AMOUNTs";
    string public constant NOTHING_TO_REDEEM = "NOTHING_TO_REDEEM";
    string public constant RECORD_IN_USE = "RECORD_IN_USE";
    string public constant INVALID_EIN = "INVALID_EIN";
    string public constant VALUE_ZERO = "VALUE_ZERO";
    string public constant ALREADY_SET = "ALREADY_SET";
    string public constant VOTING_FINISHED = "VOTING_FINISHED";
    string public constant ALREADY_EXECUTED = "ALREADY_EXECUTED";
    string public constant ACTIVE_TGE_EXISTS = "ACTIVE_TGE_EXISTS";
    string public constant INVALID_VALUE = "INVALID_VALUE";
    string public constant INVALID_CAP = "INVALID_CAP";
    string public constant INVALID_SOFTCAP = "INVALID_SOFTCAP";
    string public constant INVALID_HARDCAP = "INVALID_HARDCAP";
    string public constant ONLY_POOL = "ONLY_POOL";
    string public constant ETH_TRANSFER_FAIL = "ETH_TRANSFER_FAIL";
    string public constant TOKEN_TRANSFER_FAIL = "TOKEN_TRANSFER_FAIL";
    string public constant BLOCK_DELAY = "BLOCK_DELAY";
    string public constant SERVICE_PAUSED = "SERVICE_PAUSED";
    string public constant INVALID_PROPOSAL_TYPE = "INVALID_PROPOSAL_TYPE";
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity 0.8.17;

interface IGnosisGovernance {
    function initialize(address _pool) external;

    function executeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IDirectory {
    enum ContractType {
        None,
        Pool,
        GovernanceToken,
        TGE
    }

    enum EventType {
        None,
        TransferETH,
        TransferERC20,
        TGE,
        GovernanceSettings,
        CancelProposal
    }

    function addContractRecord(address addr, ContractType contractType)
        external
        returns (uint256 index);

    function addProposalRecord(address pool, uint256 proposalId)
        external
        returns (uint256 index);

    function addEventRecord(address pool, EventType eventType, uint256 proposalId)
        external
        returns (uint256 index);

    function typeOf(address addr) external view returns (ContractType);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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
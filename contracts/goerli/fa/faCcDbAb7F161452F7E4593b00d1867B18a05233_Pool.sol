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

/// @dev Company Entry Point
contract Pool is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IPool,
    Governor
{
    /// @dev Service address
    IService public service;

    /// @dev Pool token address
    IGovernanceToken public token;

    /// @dev Last TGE address
    ITGE public tge;

    /// @dev Minimum amount of votes that ballot must receive
    uint256 private _ballotQuorumThreshold;

    /// @dev Minimum amount of votes that ballot's choice must receive in order to pass
    uint256 private _ballotDecisionThreshold;

    /// @dev Ballot voting duration, blocks
    uint256 private _ballotLifespan;

    /// @dev Pool name
    string private _poolRegisteredName;

    /// @dev Pool trademark
    string private _poolTrademark;

    /// @dev Pool jurisdiction
    uint256 private _poolJurisdiction;

    /// @dev Pool EIN
    string private _poolEIN;

    /// @dev Metadata pool record index
    uint256 private _poolMetadataIndex;

    /// @dev Pool entity type
    uint256 private _poolEntityType;

    /// @dev Pool date of incorporatio
    string private _poolDateOfIncorporation;

    /// @dev Pool's first TGE
    address public primaryTGE;

    /// @dev List of all pool's TGEs
    address[] private _tgeList;

    /**
     * @dev block delay for executeBallot
     * [0] - ballot value in USDT after which delay kicks in
     * [1] - base delay applied to all ballots to mitigate FlashLoan attacks.
     * [2] - delay for TransferETH proposals
     * [3] - delay for TransferERC20 proposals
     * [4] - delay for TGE proposals
     * [5] - delay for GovernanceSettings proposals
     */
    uint256[10] public ballotExecDelay;

    // INITIALIZER AND CONFIGURATOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Create TransferETH proposal
     * @param poolCreator_ Pool owner
     * @param jurisdiction_ Jurisdiction
     * @param poolEIN_ EIN
     * @param dateOfIncorporation Date of incorporation
     * @param poolEntityType_ Entity type
     * @param ballotQuorumThreshold_ Ballot quorum threshold
     * @param ballotDecisionThreshold_ Ballot decision threshold
     * @param ballotLifespan_ Ballot lifespan
     * @param ballotExecDelay_ Ballot execution delay parameters
     * @param metadataIndex Metadata index
     * @param trademark Trademark
     */
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
    }

    /**
     * @dev Set pool governance token
     * @param token_ Token address
     */
    function setToken(address token_) external onlyService {
        require(token_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        token = IGovernanceToken(token_);
    }

    /**
     * @dev Set pool TGE
     * @param tge_ TGE address
     */
    function setTGE(address tge_) external onlyService {
        require(tge_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        tge = ITGE(tge_);
    }

    /**
     * @dev Set pool primary TGE
     * @param tge_ TGE address
     */
    function setPrimaryTGE(address tge_) external onlyService {
        require(tge_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        primaryTGE = tge_;
    }

    /**
     * @dev Set pool registered name
     * @param registeredName Registered name
     */
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

    /**
     * @dev Set Service governance settings
     * @param ballotQuorumThreshold_ Ballot quorum theshold
     * @param ballotDecisionThreshold_ Ballot decision threshold
     * @param ballotLifespan_ Ballot lifespan
     * @param ballotExecDelay_ Ballot execution delay parameters
     */
    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] calldata ballotExecDelay_
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

        // zero value allows FlashLoan attacks against executeBallot
        require(
            ballotExecDelay_[1] > 0 && ballotExecDelay_[1] < 20,
            ExceptionsLibrary.INVALID_VALUE
        );

        _ballotQuorumThreshold = ballotQuorumThreshold_;
        _ballotDecisionThreshold = ballotDecisionThreshold_;
        _ballotLifespan = ballotLifespan_;
        ballotExecDelay = ballotExecDelay_;
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Cast ballot vote
     * @param proposalId Pool proposal ID
     * @param votes Amount of tokens
     * @param support Against or for
     */
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

    /**
     * @dev Create pool propsal
     * @param target Proposal transaction recipient
     * @param value Amount of ETH token
     * @param cd Calldata to pass on in .call() to transaction recipient
     * @param description Proposal description
     * @param proposalType Type
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal ID
     */
    function proposeSingleAction(
        address target,
        uint256 value,
        bytes memory cd,
        string memory description,
        IProposalGateway.ProposalType proposalType,
        string memory metaHash
    )
        external
        onlyProposalGateway
        whenServiceNotPaused
        returns (uint256 proposalId)
    {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory values = new uint256[](1);
        values[0] = value;

        proposalId = _propose(
            _ballotLifespan,
            _ballotQuorumThreshold,
            _ballotDecisionThreshold,
            targets,
            values,
            cd,
            description,
            _getTotalSupply() -
                _getTotalTGELockedTokens() -
                token.balanceOf(service.protocolTreasury()),
            service.ballotExecDelay(1),
            proposalType,
            metaHash,
            address(0)
        );
    }

    /**
     * @dev Create pool propsal
     * @param targets Proposal transaction recipients
     * @param values Amounts of ETH token
     * @param description Proposal description
     * @param proposalType Type
     * @param metaHash Hash value of proposal metadata
     * @param token_ token for payment proposal
     * @return proposalId Created proposal ID
     */
    function proposeTransfer(
        address[] memory targets,
        uint256[] memory values,
        string memory description,
        IProposalGateway.ProposalType proposalType,
        string memory metaHash,
        address token_
    )
        external
        onlyProposalGateway
        whenServiceNotPaused
        returns (uint256 proposalId)
    {
        proposalId = _propose(
            _ballotLifespan,
            _ballotQuorumThreshold,
            _ballotDecisionThreshold,
            targets,
            values,
            "",
            description,
            _getTotalSupply() -
                _getTotalTGELockedTokens() -
                token.balanceOf(service.protocolTreasury()),
            service.ballotExecDelay(1),
            proposalType,
            metaHash,
            token_
        );
    }

    /**
     * @dev Add TGE to TGE archive list
     * @param tge_ TGE address
     */
    function addTGE(address tge_) external onlyService {
        _tgeList.push(tge_);
    }

    /**
     * @dev Calculate pool TVL
     * @return Pool TVL
     */
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

    /**
     * @dev Execute proposal
     * @param proposalId Proposal ID
     */
    function executeBallot(uint256 proposalId) external whenServiceNotPaused {
        _executeBallot(proposalId, service, IPool(address(this)));
    }

    /**
     * @dev Cancel proposal, callable only by Service
     * @param proposalId Proposal ID
     */
    function serviceCancelBallot(uint256 proposalId) external onlyService {
        _cancelBallot(proposalId);
    }

    // RECEIVE

    receive() external payable {
        // Supposed to be empty
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Return pool trademark
     * @return Trademark
     */
    function getPoolTrademark() external view returns (string memory) {
        return _poolTrademark;
    }

    /**
     * @dev Return pool registered name
     * @return Registered name
     */
    function getPoolRegisteredName() public view returns (string memory) {
        return _poolRegisteredName;
    }

    /**
     * @dev Return pool proposal quorum threshold
     * @return Ballot quorum threshold
     */
    function getBallotQuorumThreshold() public view returns (uint256) {
        return _ballotQuorumThreshold;
    }

    /**
     * @dev Return proposal decision threshold
     * @return Ballot decision threshold
     */
    function getBallotDecisionThreshold() public view returns (uint256) {
        return _ballotDecisionThreshold;
    }

    /**
     * @dev Return proposal lifespan
     * @return Proposal lifespan
     */
    function getBallotLifespan() public view returns (uint256) {
        return _ballotLifespan;
    }

    /**
     * @dev Return pool jurisdiction
     * @return Jurisdiction
     */
    function getPoolJurisdiction() public view returns (uint256) {
        return _poolJurisdiction;
    }

    /**
     * @dev Return pool EIN
     * @return EIN
     */
    function getPoolEIN() public view returns (string memory) {
        return _poolEIN;
    }

    /**
     * @dev Return pool data of incorporation
     * @return Date of incorporation
     */
    function getPoolDateOfIncorporation() public view returns (string memory) {
        return _poolDateOfIncorporation;
    }

    /**
     * @dev Return pool entity type
     * @return Entity type
     */
    function getPoolEntityType() public view returns (uint256) {
        return _poolEntityType;
    }

    /**
     * @dev Return pool metadata index
     * @return Metadata index
     */
    function getPoolMetadataIndex() public view returns (uint256) {
        return _poolMetadataIndex;
    }

    /**
     * @dev Return maximum proposal ID
     * @return Maximum proposal ID
     */
    function maxProposalId() public view returns (uint256) {
        return lastProposalId;
    }

    /**
     * @dev Return if pool had a successful TGE
     * @return Is any TGE successful
     */
    function isDAO() public view returns (bool) {
        return (ITGE(primaryTGE).state() == ITGE.State.Successful);
    }

    /**
     * @dev Return list of pool's TGEs
     * @return TGE list
     */
    function getTGEList() public view returns (address[] memory) {
        return _tgeList;
    }

    /**
     * @dev Return pool owner
     * @return Owner address
     */
    function owner()
        public
        view
        override(IPool, OwnableUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    /**
     * @dev Return type of proposal
     * @param proposalId Proposal ID
     * @return Proposal type
     */
    function getProposalType(uint256 proposalId)
        public
        view
        returns (IProposalGateway.ProposalType)
    {
        return _getProposalType(proposalId);
    }

    function getBallotExecDelay() public view returns(uint256[10] memory) {
        return ballotExecDelay;
    }

    // INTERNAL FUNCTIONS

    function _afterProposalCreated(uint256 proposalId) internal override {
        service.addProposal(proposalId);
    }

    /**
     * @dev Return token total supply
     * @return Total pool token supply
     */
    function _getTotalSupply() internal view override returns (uint256) {
        return token.totalSupply();
    }

    /**
     * @dev Return amount of tokens currently locked in TGE vesting contract(s)
     * @return Total pool vesting tokens
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

    // function test83212() external pure returns (uint256) {
    //     return 3;
    // }
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
import "../interfaces/IService.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IDirectory.sol";
import "../interfaces/IProposalGateway.sol";

/// @dev Proposal module for Pool's Governance Token
abstract contract Governor {
    /**
     * @dev Proposal structure
     * @param ballotQuorumThreshold Ballot quorum threshold
     * @param ballotDecisionThreshold Ballot decision threshold
     * @param target Target
     * @param value ETH value
     * @param callData Call data to pass in .call() to target
     * @param startBlock Start block
     * @param endBlock End block
     * @param forVotes For votes
     * @param againstVotes Against votes
     * @param executed Is executed
     * @param state Proposal state
     * @param description Description
     * @param totalSupply Total supply
     * @param lastVoteBlock Block when last vote was cast
     * @param proposalType Proposal type
     * @param execDelay Execution delay for the proposal, blocks
     * @param metaHash Hash value of proposal metadata
     * @param token_ token for payment proposal
     */
    struct Proposal {
        uint256 ballotQuorumThreshold;
        uint256 ballotDecisionThreshold;
        address[] targets;
        uint256[] values;
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
        string metaHash;
        address token;
    }

    /// @dev Proposals
    mapping(uint256 => Proposal) private _proposals;

    /// @dev For votes
    mapping(address => mapping(uint256 => uint256)) private _forVotes;

    /// @dev Against votes
    mapping(address => mapping(uint256 => uint256)) private _againstVotes;

    /// @dev Last proposal ID
    uint256 public lastProposalId;

    /// @dev Proposal state, Cancelled, Executed - unused
    enum ProposalState {
        None,
        Active,
        Failed,
        Successful,
        Executed,
        Cancelled
    }

    /// @dev Proposal execution state
    /// @dev unused - to refactor
    enum ProposalExecutionState {
        Initialized,
        Rejected,
        Accomplished,
        Cancelled
    }

    // EVENTS

    /**
     * @dev Event emitted on proposal creation
     * @param proposalId Proposal ID
     * @param quorum Quorum
     * @param targets Targets
     * @param values Values
     * @param calldatas Calldata
     * @param description Description
     */
    event ProposalCreated(
        uint256 proposalId,
        uint256 quorum,
        address[] targets,
        uint256[] values,
        bytes calldatas,
        string description
    );

    /**
     * @dev Event emitted on proposal vote cast
     * @param voter Voter address
     * @param proposalId Proposal ID
     * @param votes Amount of votes
     * @param support Against or for
     */
    event VoteCast(
        address voter,
        uint256 proposalId,
        uint256 votes,
        bool support
    );

    /**
     * @dev Event emitted on proposal execution
     * @param proposalId Proposal ID
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Event emitted on proposal cancellation
     * @param proposalId Proposal ID
     */
    event ProposalCancelled(uint256 proposalId);

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Return proposal state
     * @param proposalId Proposal ID
     * @return ProposalState
     */
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

        // if (proposal.state == ProposalExecutionState.Cancelled || 
        //     proposal.state == ProposalExecutionState.Executed) {
        //     return proposal.state;
        // }

        uint256 totalAvailableVotes = _getTotalSupply() -
            _getTotalTGELockedTokens();
        uint256 quorumVotes = (totalAvailableVotes *
            proposal.ballotQuorumThreshold);
        uint256 totalCastVotes = proposal.forVotes + proposal.againstVotes;
        uint256 necessaryVotesFor = totalAvailableVotes * proposal.ballotDecisionThreshold;
        uint256 freeFloatVotes = totalCastVotes * proposal.ballotDecisionThreshold;

        if (
            totalCastVotes * 10000 >= quorumVotes && // /10000 because 10000 = 100%
            proposal.forVotes * 10000 >=
            totalCastVotes * proposal.ballotDecisionThreshold && // * 10000 because 10000 = 100%
            proposal.forVotes * 10000 >=
            totalAvailableVotes * proposal.ballotDecisionThreshold
        ) {
            return ProposalState.Successful;
        }
        if (
            totalCastVotes * 10000 >= quorumVotes && // /10000 because 10000 = 100%
            proposal.againstVotes * 10000 >
            totalCastVotes * proposal.ballotDecisionThreshold && // * 10000 because 10000 = 100%
            (totalAvailableVotes - proposal.againstVotes) * 10000 <
            totalAvailableVotes * proposal.ballotDecisionThreshold
        ) {
            return ProposalState.Failed;
        }

        if (block.number > proposal.endBlock) {
            if (
                totalCastVotes >= quorumVotes &&
                proposal.forVotes * 10000 >=
                totalCastVotes * proposal.ballotDecisionThreshold
            ) {
                return ProposalState.Successful;
            } else return ProposalState.Failed;
        }
        return ProposalState.Active;
    }

    /**
     * @dev Return proposal quorum threshold
     * @param proposalId Proposal ID
     * @return Quorum threshold
     */
    function getProposalBallotQuorumThreshold(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _proposals[proposalId].ballotQuorumThreshold;
    }

    /**
     * @dev Return proposal decsision threshold
     * @param proposalId Proposal ID
     * @return Decision threshold
     */
    function getProposalBallotDecisionThreshold(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _proposals[proposalId].ballotDecisionThreshold;
    }

    /**
     * @dev Return proposal lifespan
     * @param proposalId Proposal ID
     * @return Lifespan
     */
    function getProposalBallotLifespan(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return
            _proposals[proposalId].endBlock - _proposals[proposalId].startBlock;
    }

    /**
     * @dev Return proposal
     * @param proposalId Proposal ID
     * @return Proposal
     */
    function getProposal(uint256 proposalId)
        public
        view
        returns (Proposal memory)
    {
        return _proposals[proposalId];
    }

    /**
     * @dev Return proposal for votes for a given user
     * @param user User address
     * @param proposalId Proposal ID
     * @return For votes
     */
    function getForVotes(address user, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _forVotes[user][proposalId];
    }

    /**
     * @dev Return proposal against votes for a given user
     * @param user User address
     * @param proposalId Proposal ID
     * @return Against votes
     */
    function getAgainstVotes(address user, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _againstVotes[user][proposalId];
    }

    /**
     * @dev Return proposal type
     * @param proposalId Proposal ID
     * @return Proposal type
     */
    function _getProposalType(uint256 proposalId)
        internal
        view
        returns (IProposalGateway.ProposalType)
    {
        return _proposals[proposalId].proposalType;
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Create proposal
     * @param ballotLifespan Ballot lifespan
     * @param ballotQuorumThreshold Ballot quorum threshold
     * @param ballotDecisionThreshold Ballot decision threshold
     * @param targets Targets
     * @param values Values
     * @param callData Calldata
     * @param description Description
     * @param totalSupply Total supply
     * @param execDelay Execution delay
     * @param proposalType Proposal type
     * @param metaHash Hash value of proposal metadata
     * @param token_ token for payment proposal
     * @return proposalId Proposal ID
     */
    function _propose(
        uint256 ballotLifespan,
        uint256 ballotQuorumThreshold,
        uint256 ballotDecisionThreshold,
        address[] memory targets,
        uint256[] memory values,
        bytes memory callData,
        string memory description,
        uint256 totalSupply,
        uint256 execDelay,
        IProposalGateway.ProposalType proposalType,
        string memory metaHash,
        address token_
    ) internal returns (uint256 proposalId) {
        proposalId = ++lastProposalId;
        _proposals[proposalId] = Proposal({
            ballotQuorumThreshold: ballotQuorumThreshold,
            ballotDecisionThreshold: ballotDecisionThreshold,
            targets: targets,
            values: values,
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
            proposalType: proposalType,
            execDelay: execDelay,
            metaHash: metaHash,
            token: token_
        });
        _afterProposalCreated(proposalId);

        emit ProposalCreated(
            proposalId,
            ballotQuorumThreshold,
            targets,
            values,
            callData,
            description
        );
    }

    /**
     * @dev Cast vote for a proposal
     * @param proposalId Proposal ID
     * @param votes Amount of votes
     * @param support Against or for
     */
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
        _proposals[proposalId].totalSupply = _getTotalSupply() -
            _getTotalTGELockedTokens();

        emit VoteCast(msg.sender, proposalId, votes, support);
    }

    /**
     * @dev Execute proposal
     * @param proposalId Proposal ID
     * @param service Service address
     * @param pool Pool address
     */
    function _executeBallot(
        uint256 proposalId,
        IService service,
        IPool pool
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
        require(
            proposal.lastVoteBlock + proposal.execDelay <= block.number,
            ExceptionsLibrary.BLOCK_DELAY
        );

        _proposals[proposalId].executed = true;
        bool success = false;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
             // Give pool shareholders time to cancel bugged/hacked ballot execution
            require(
                isDelayCleared(pool, proposalId, i),
                ExceptionsLibrary.BLOCK_DELAY
            );
            if (proposal.proposalType != IProposalGateway.ProposalType.TransferERC20) {
                (success, ) = proposal.targets[i].call{
                    value: proposal.values[i]
                }(proposal.callData);
            } else {
                success = IERC20Upgradeable(proposal.token).transfer(proposal.targets[i], proposal.values[i]);
            }

            require(success, ExceptionsLibrary.EXECUTION_FAILED);
        }

        if (
            proposal.proposalType == IProposalGateway.ProposalType.TransferETH
        ) {
            service.addEvent(
                IDirectory.EventType.TransferETH,
                proposalId,
                proposal.metaHash
            );
        }

        if (
            proposal.proposalType == IProposalGateway.ProposalType.TransferERC20
        ) {
            service.addEvent(
                IDirectory.EventType.TransferERC20,
                proposalId,
                proposal.metaHash
            );
        }

        if (proposal.proposalType == IProposalGateway.ProposalType.TGE) {
            service.addEvent(IDirectory.EventType.TGE, proposalId, proposal.metaHash);
        }

        if (
            proposal.proposalType ==
            IProposalGateway.ProposalType.GovernanceSettings
        ) {
            service.addEvent(
                IDirectory.EventType.GovernanceSettings,
                proposalId,
                proposal.metaHash
            );
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Return: is proposal block delay cleared. Block delay is applied based on proposal type and pool governance settings.
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @return Is delay cleared
     */
    function isDelayCleared(IPool pool, uint256 proposalId, uint256 index)
        public
        returns (bool)
    {
        Proposal memory proposal = _proposals[proposalId];
        uint256 valueUSDT = 0;

        // proposal type based delay
        uint256 delay = pool.ballotExecDelay(
            uint256(proposal.proposalType) + 1
        );

        // delay for transfer type proposals
        if (
            proposal.proposalType ==
            IProposalGateway.ProposalType.TransferETH ||
            proposal.proposalType == IProposalGateway.ProposalType.TransferERC20
        ) {
            address from = pool.service().weth();
            uint256 amount = proposal.values[index];

            if (
                proposal.proposalType ==
                IProposalGateway.ProposalType.TransferERC20
            ) {
                from = proposal.targets[index];
                amount = proposal.values[index];
            }

            // calculate USDT value of transfer tokens
            // Uniswap reverts if tokens are not supported.
            // In order to allow transfer of ERC20 tokens that are not supported on uniswap, we catch the revert
            // And allow the proposal token transfer to pass through
            // This is kinda vulnerable to Uniswap token/pool price/listing manipulation, perhaps this needs to be refactored some time later
            // In order to prevent executing proposals by temporary making token pair/pool not supported by uniswap (which would cause revert and allow proposal to be executed)
            try
                pool.service().uniswapQuoter().quoteExactInput(
                    abi.encodePacked(from, uint24(3000), pool.service().usdt()),
                    amount
                )
            returns (uint256 v) {
                valueUSDT = v;
            } catch (
                bytes memory /*lowLevelData*/
            ) {}

            if (
                valueUSDT >= pool.ballotExecDelay(0) &&
                block.number <= delay + proposal.lastVoteBlock
            ) {
                return false;
            }
        }

        // delay for non transfer type proposals
        if (
            proposal.proposalType == IProposalGateway.ProposalType.TGE ||
            proposal.proposalType ==
            IProposalGateway.ProposalType.GovernanceSettings
        ) {
            if (block.number <= delay + proposal.lastVoteBlock) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Cancel proposal
     * @param proposalId Proposal ID
     */
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
        uint256[13] calldata ballotParams,
        ISwapRouter uniswapRouter_,
        IQuoter uniswapQuoter_,
        IWhitelistedTokens whitelistedTokens_,
        uint256 _protocolTokenFee
    ) external;

    function createSecondaryTGE(ITGE.TGEInfo calldata tgeInfo) external;

    function addProposal(uint256 proposalId) external;

    function addEvent(IDirectory.EventType eventType, uint256 proposalId, string calldata metaHash)
        external;

    function directory() external view returns (IDirectory);

    function isManagerWhitelisted(address account) external view returns (bool);

    function tokenWhitelist() external view returns (address[] memory);

    function owner() external view returns (address);

    function proposalGateway() external view returns (address);

    function uniswapRouter() external view returns (ISwapRouter);

    function uniswapQuoter() external view returns (IQuoter);

    function whitelistedTokens() external view returns (IWhitelistedTokens);

    function metadata() external view returns (IMetadata);

    function protocolTreasury() external view returns (address);

    function protocolTokenFee() external view returns (uint256);

    function getMinSoftCap() external view returns (uint256);

    function getProtocolTokenFee(uint256 amount)
        external
        view
        returns (uint256);

    function ballotExecDelay(uint256 _index) external view returns (uint256);

    function paused() external view returns (bool);

    function usdt() external view returns (address);

    function weth() external view returns (address);
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
        uint256[10] memory ballotExecDelay_,
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
        uint256[10] calldata ballotExecDelay
    ) external;

    function proposeSingleAction(
        address target,
        uint256 value,
        bytes memory cd,
        string memory description,
        IProposalGateway.ProposalType proposalType,
        string memory metaHash
    ) external returns (uint256 proposalId);

    function proposeTransfer(
        address[] memory targets,
        uint256[] memory values,
        string memory description,
        IProposalGateway.ProposalType proposalType,
        string memory metaHash,
        address token_
    ) external returns (uint256 proposalId);

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

    function getProposalType(uint256 proposalId)
        external
        view
        returns (IProposalGateway.ProposalType);

    function ballotExecDelay(uint256 _index) external view returns (uint256);
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

    function initialize(address pool_, TokenInfo calldata info) external;

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
        TGEInfo calldata info
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
        GovernanceSettings
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
    string public constant LOCKUP_TVL_REACHED = "LOCKUP_TVL_REACHED";
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
    string public constant INVALID_HARDCAP = "INVALID_HARDCAP";
    string public constant ONLY_POOL = "ONLY_POOL";
    string public constant ETH_TRANSFER_FAIL = "ETH_TRANSFER_FAIL";
    string public constant TOKEN_TRANSFER_FAIL = "TOKEN_TRANSFER_FAIL";
    string public constant BLOCK_DELAY = "BLOCK_DELAY";
    string public constant SERVICE_PAUSED = "SERVICE_PAUSED";
    string public constant INVALID_PROPOSAL_TYPE = "INVALID_PROPOSAL_TYPE";
    string public constant EXECUTION_FAILED = "EXECUTION_FAILED";
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
        GovernanceSettings
    }

    function addContractRecord(address addr, ContractType contractType)
        external
        returns (uint256 index);

    function addProposalRecord(address pool, uint256 proposalId)
        external
        returns (uint256 index);

    function addEventRecord(address pool, EventType eventType, uint256 proposalId, string calldata metaHash)
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
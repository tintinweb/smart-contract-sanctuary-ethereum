pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import { Foundance } from "../libraries/Foundance.sol";
import "./interfaces/IVotingAdapter.sol";
import "../core/DaoRegistry.sol";
import "../extensions/BankExtension.sol";
import "../modifiers/MemberGuard.sol";
import "../modifiers/AdapterGuard.sol";
import "../modifiers/Reimbursable.sol";
import "../libraries/DaoLibrary.sol";
import "../libraries/GovernanceLibrary.sol";

contract VotingAdapter is
  IVotingAdapter,
  MemberGuard,
  AdapterGuard,
  Reimbursable
{

    string public constant ADAPTER_NAME = "VotingAdapter";

    struct Voting {
        uint256 nbYes;
        uint256 nbNo;
        uint256 nbMembers;
        uint256 nbTokens;
        uint256 startingTime;
        uint256 graceStartingTime;
        uint256 disputeStartingTime;
        uint256 blockNumber;
        bytes32 proposalId;
        string origin;
        Foundance.VotingType votingType;
        Foundance.VotingState votingState;
    }

    mapping(address => Foundance.VotingConfig) public votingConfig;

    mapping(address => mapping(string => Foundance.VotingConfig)) public votingFunctionConfig;//TODO

    mapping(address => mapping(bytes32 => uint256)) public votingIndex;

    mapping(address => Voting[]) public voting;

    mapping(address => mapping(bytes32 => mapping(address => uint256))) public votingVotes;
    

    //EVENT
    event StartNewVotingForProposalEvent(address _address, bytes32 _proposalId, bytes data, string origin);

    event SubmitVoteEvent(address _address);


    function getAdapterName() external pure override returns (string memory) {
        return ADAPTER_NAME;
    }

    function configureDao(
        DaoRegistry dao,
        Foundance.VotingConfig memory _votingConfig
    ) external onlyAdapter(dao) {
        if(_votingConfig.passRateToken > 100){
            _votingConfig.passRateToken = 100;
        }
        if(_votingConfig.supportRequired > 100){
            _votingConfig.supportRequired = 100;
        }
        votingConfig[address(dao)] = _votingConfig;
    }

    function getSenderAddress(
        DaoRegistry,
        address,
        bytes memory,
        address sender
    ) external pure override returns (address) {
        return sender;
    }

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        string calldata origin
    ) external override onlyAdapter(dao) {
        uint length = voting[address(dao)].length;
        votingIndex[address(dao)][proposalId]=length;
        Voting memory vote;
        vote.startingTime = block.timestamp;
        vote.blockNumber = block.number;
        vote.votingType = votingConfig[address(dao)].votingType;
        vote.origin = origin;
        vote.votingState = Foundance.VotingState.IN_PROGRESS;
        vote.proposalId = proposalId;
        voting[address(dao)].push(vote);
        emit StartNewVotingForProposalEvent(msg.sender, proposalId, data, origin);
    }

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        string calldata origin,
        Foundance.VotingType _votingType
    ) external onlyAdapter(dao) {
        uint length = voting[address(dao)].length;
        votingIndex[address(dao)][proposalId]=length;
        Voting memory vote;
        vote.startingTime = block.timestamp;
        vote.blockNumber = block.number;
        vote.votingType = _votingType;
        vote.origin = origin;
        vote.votingState = Foundance.VotingState.IN_PROGRESS;
        vote.proposalId = proposalId;
        voting[address(dao)].push(vote);
        emit StartNewVotingForProposalEvent(msg.sender, proposalId, data, origin);
    }

    function submitVote(
        DaoRegistry dao,
        bytes32 proposalId,
        uint256 voteValue,
        uint256 weightedVoteValue
    ) external onlyMember(dao) reimbursable(dao) {
        require(
            dao.getProposalFlag(proposalId, DaoRegistry.ProposalFlag.SPONSORED),
            "the proposal has not been sponsored yet"
        );
        require(
            !dao.getProposalFlag(
                proposalId,
                DaoRegistry.ProposalFlag.PROCESSED
            ),
            "the proposal has already been processed"
        );
        require(
            voteValue < 3 && voteValue > 0,
            "only yes (1) and no (2) are possible values"
        );
        Voting storage vote = voting[address(dao)][votingIndex[address(dao)][proposalId]];
        Foundance.VotingConfig memory _votingConfig = votingConfig[address(dao)];
        require(
            vote.startingTime > 0,
            "this proposalId has no vote going on at the moment"
        );
        require(
            block.timestamp <
                vote.startingTime + _votingConfig.votingPeriod,
            "vote has already ended"
        );
        address memberAddr = DaoLibrary.msgSender(dao, msg.sender);
        require(votingVotes[address(dao)][proposalId][memberAddr] == 0, "member has already voted");
        uint256 tokenAmount = GovernanceLibrary.getVotingWeight(
            dao,
            memberAddr,
            proposalId,
            vote.blockNumber
        );
        uint256 votingWeight = 0;
        if (tokenAmount == 0) revert("vote not allowed");
        vote.nbMembers += 1;
        vote.nbTokens += tokenAmount;
        votingVotes[address(dao)][proposalId][memberAddr] = voteValue;
        if(vote.votingType == Foundance.VotingType.PROPORTIONAL){
            votingWeight = tokenAmount; 
        }else if(vote.votingType == Foundance.VotingType.QUADRATIC){
            votingWeight = DaoLibrary.sqrt(tokenAmount);
        }else if(vote.votingType == Foundance.VotingType.OPTIMISTIC){
            votingWeight = tokenAmount; 
        }else if(vote.votingType == Foundance.VotingType.COOPERATIVE){
            votingWeight = 1;
        }
        if(vote.votingType == Foundance.VotingType.WEIGHTED){
            votingWeight = tokenAmount; 
            weightedVoteValue = weightedVoteValue>100?100:weightedVoteValue;
            uint256 weightedVotingWeight = (votingWeight*weightedVoteValue) / 100;
            uint256 weightedVotingMinorityWeight = votingWeight-weightedVotingWeight;
            if(voteValue == 1){
                vote.nbYes = vote.nbYes + weightedVotingWeight;
                vote.nbNo = vote.nbNo + weightedVotingMinorityWeight;
            }else{
                vote.nbYes = vote.nbYes + weightedVotingMinorityWeight;
                vote.nbNo = vote.nbNo + weightedVotingWeight;
            }
        } else if (voteValue == 1) {
            vote.nbYes = vote.nbYes + votingWeight;
        } else if (voteValue == 2) {
            vote.nbNo = vote.nbNo + votingWeight;
        }
        emit SubmitVoteEvent(msg.sender);
    }

    function voteResult(DaoRegistry dao, bytes32 proposalId)
        external
        override
        returns (Foundance.VotingState state)
    {
        Voting storage vote = voting[address(dao)][votingIndex[address(dao)][proposalId]];
        Foundance.VotingConfig memory _votingConfig = votingConfig[address(dao)];
        if (vote.startingTime == 0) {
            vote.votingState = Foundance.VotingState.NOT_STARTED;
            return vote.votingState;
        }
        if (
            block.timestamp <
            vote.startingTime + _votingConfig.votingPeriod
        ) {
            vote.votingState = Foundance.VotingState.IN_PROGRESS;
            return vote.votingState;
        }
        if (
            block.timestamp <
            vote.startingTime +
                _votingConfig.votingPeriod +
                _votingConfig.gracePeriod
        ) {
            vote.votingState = Foundance.VotingState.GRACE_PERIOD;
            return vote.votingState;
        }
        if(vote.votingType == Foundance.VotingType.OPTIMISTIC){
            if (vote.nbYes >= vote.nbNo) {
                vote.votingState = Foundance.VotingState.PASS;
                return vote.votingState;
            } else if (vote.nbYes < vote.nbNo) {
                vote.votingState = Foundance.VotingState.NOT_PASS;
                return vote.votingState;
            }
            vote.votingState = Foundance.VotingState.PASS;
            return vote.votingState;
        }else{
            BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
            uint256 totalUnitTokens = DaoLibrary.totalUnitTokens(bank);
            if( 
                _votingConfig.passRateMember < vote.nbMembers || 
                (_votingConfig.passRateToken*totalUnitTokens) / 100  < vote.nbTokens || 
                (_votingConfig.supportRequired*totalUnitTokens) / 100 < vote.nbTokens   
            ) {
                vote.votingState = Foundance.VotingState.NOT_PASS;
                return vote.votingState;
            }
            if (vote.nbYes > vote.nbNo) {
                vote.votingState = Foundance.VotingState.PASS;
                return vote.votingState;
            } else if (vote.nbYes < vote.nbNo) {
                vote.votingState = Foundance.VotingState.NOT_PASS;
                return vote.votingState;
            } else {
                vote.votingState = Foundance.VotingState.TIE;
                return vote.votingState;
            }
        }
    }

    function getVoting(
        address dao
    ) external view returns (Voting[] memory) {
        return voting[address(dao)];
    }

    function getVotingVotes(
        address dao,
        bytes32 proposalId,
        address member
    ) external view returns (uint256 votes) {
        return votingVotes[address(dao)][proposalId][member];
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

library Foundance {
  //CONFIG
  struct FoundanceConfig {
    address creatorAddress;
    uint32 projectId;
    FoundanceStatus foundanceStatus;
    FactoryMemberConfig[] factoryMemberConfigArray;
    mapping(address => uint256) factoryMemberConfigIndex;
    TokenConfig tokenConfig;
    VotingConfig votingConfig;
    EpochConfig epochConfig;
    DynamicEquityConfig dynamicEquityConfig;
    CommunityEquityConfig communityEquityConfig;
  }
  
  struct FoundanceConfigView {
    address creatorAddress;
    string foundanceName;
    FoundanceStatus foundanceStatus;
    FactoryMemberConfig[] factoryMemberConfigArray;
    TokenConfig tokenConfig;
    VotingConfig votingConfig;
    EpochConfig epochConfig;
    DynamicEquityConfig dynamicEquityConfig;
    CommunityEquityConfig communityEquityConfig;
  }

  struct TokenConfig {
    string tokenName;
    string tokenSymbol;
    uint8 maxExternalTokens;
    uint8 decimals;
  }

  struct VotingConfig {
    VotingType votingType;
    uint256 votingPeriod;
    uint256 gracePeriod;
    uint256 disputePeriod;
    uint256 passRateMember;
    uint256 passRateToken;
    uint256 supportRequired;
  }

  struct EpochConfig {
    uint256 epochDuration;
    uint256 epochReview;
    uint256 epochStart;
    uint256 epochLast;
  }
  struct DynamicEquityConfig {
    uint256 riskMultiplier;
    uint256 timeMultiplier;
  }

  struct CommunityEquityConfig {
    AllocationType allocationType;
    uint256 allocationTokenAmount;
    uint256 tokenAmount;
  }

  //MEMBER_CONFIG
  struct FactoryMemberConfig {
    address memberAddress;
    bool foundanceApproved;
    MemberConfig memberConfig;
    DynamicEquityMemberConfig dynamicEquityMemberConfig;
    VestedEquityMemberConfig vestedEquityMemberConfig;
    CommunityEquityMemberConfig communityEquityMemberConfig;
  }

  struct MemberConfig {
    address memberAddress;
    uint256 initialAmount;
    uint256 initialPeriod;
    bool appreciationRight;
  }

  struct DynamicEquityMemberConfig {
    address memberAddress;
    uint256 suspendedUntil;
    uint256 availability;
    uint256 availabilityThreshold;
    uint256 salary;
    uint256 salaryMarket;
    uint256 salaryThreshold;
    uint256 expense;
    uint256 expenseThreshold;
    uint256 expenseAdhoc;
    uint256 expenseAdhocThreshold;
  }

  struct VestedEquityMemberConfig {
    address memberAddress;
    uint256 tokenAmount;
    uint256 duration;
    uint256 start;
    uint256 cliff;
  }

  struct CommunityEquityMemberConfig {
    address memberAddress;
    uint256 singlePaymentAmountThreshold;
    uint256 totalPaymentAmountThreshold;
    uint256 totalPaymentAmount;
  }

  //ENUM
  enum FoundanceStatus {
    REGISTERED,
    APPROVED,
    LIVE
  }

  enum VotingType {
    PROPORTIONAL,
    WEIGHTED,
    QUADRATIC,
    OPTIMISTIC,
    COOPERATIVE
  }

  enum AllocationType {
    POOL,
    EPOCH
  }

  enum ProposalStatus {
    NOT_STARTED,
    IN_PROGRESS,
    DONE,
    FAILED
  }

  enum VotingState {
    NOT_STARTED,
    TIE,
    PASS,
    NOT_PASS,
    IN_PROGRESS,
    GRACE_PERIOD,
    DISPUTE_PERIOD
  }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";

interface IVotingAdapter {


    function getAdapterName() external pure returns (string memory);

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        string memory origin
    ) external;

    function startNewVotingForProposal(
        DaoRegistry dao,
        bytes32 proposalId,
        bytes calldata data,
        string memory origin,
        Foundance.VotingType
    ) external;
    
    function getSenderAddress(
        DaoRegistry dao,
        address actionId,
        bytes memory data,
        address sender
    ) external returns (address);

    function voteResult(
        DaoRegistry dao, 
        bytes32 proposalId
    ) external returns (Foundance.VotingState state);
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import '../modifiers/AdapterGuard.sol';
import '../modifiers/MemberGuard.sol';
import '../interfaces/IExtension.sol';
import '../libraries/DaoLibrary.sol';

contract DaoRegistry is MemberGuard, AdapterGuard {
    /**
     * EVENTS
     */
    event SubmittedProposal(bytes32 proposalId, uint256 flags);
    event SponsoredProposal(
        bytes32 proposalId,
        uint256 flags,
        address votingAdapter
    );
    event ProcessedProposal(bytes32 proposalId, uint256 flags);
    event AdapterAdded(
        bytes32 adapterId,
        address adapterAddress,
        uint256 flags
    );
    event AdapterRemoved(bytes32 adapterId);
    event ExtensionAdded(bytes32 extensionId, address extensionAddress);
    event ExtensionRemoved(bytes32 extensionId);
    event UpdateDelegateKey(address memberAddress, address newDelegateKey);
    event ConfigurationUpdated(bytes32 key, uint256 value);
    event AddressConfigurationUpdated(bytes32 key, address value);

    /**
     * ENUM
     */
    enum DaoState {
        CREATION,
        READY
    }

    enum MemberFlag {
        EXISTS,
        JAILED
    }

    enum ProposalFlag {
        EXISTS,
        SPONSORED,
        PROCESSED
    }

    enum AclFlag {
        REPLACE_ADAPTER,
        SUBMIT_PROPOSAL,
        UPDATE_DELEGATE_KEY,
        SET_CONFIGURATION,
        ADD_EXTENSION,
        REMOVE_EXTENSION,
        NEW_MEMBER,
        JAIL_MEMBER
    }

    /**
     * STRUCTURES
     */
    struct Proposal {
        /// the structure to track all the proposals in the DAO
        address adapterAddress; /// the adapter address that called the functions to change the DAO state
        uint256 flags; /// flags to track the state of the proposal: exist, sponsored, processed, canceled, etc.
    }
 
    struct Member {
        /// the structure to track all the members in the DAO
        uint256 flags; /// flags to track the state of the member: exists, etc
    }

    struct Checkpoint {
        /// A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }

    struct DelegateCheckpoint {
        /// A checkpoint for marking the delegate key for a member from a given block
        uint96 fromBlock;
        address delegateKey;
    }

    struct AdapterEntry {
        bytes32 id;
        uint256 acl;
    }

    struct ExtensionEntry {
        bytes32 id;
        mapping(address => uint256) acl;
        bool deleted;
    }

    /**
     * PUBLIC VARIABLES
     */

    /// @notice internally tracks deployment under eip-1167 proxy pattern
    bool public initialized = false;

    /// @notice The dao state starts as CREATION and is changed to READY after the finalizeDao call
    DaoState public state;

    /// @notice The map to track all members of the DAO with their existing flags
    mapping(address => Member) public members;
    /// @notice The list of members
    address[] private _members;

    /// @notice delegate key => member address mapping
    mapping(address => address) public memberAddressesByDelegatedKey;

    /// @notice The map that keeps track of all proposasls submitted to the DAO
    mapping(bytes32 => Proposal) public proposals;
    /// @notice The map that tracks the voting adapter address per proposalId: proposalId => adapterAddress
    mapping(bytes32 => address) public votingAdapter;
    /// @notice The map that keeps track of all adapters registered in the DAO: sha3(adapterId) => adapterAddress
    mapping(bytes32 => address) public adapters;
    /// @notice The inverse map to get the adapter id based on its address
    mapping(address => AdapterEntry) public inverseAdapters;
    /// @notice The map that keeps track of all extensions registered in the DAO: sha3(extId) => extAddress
    mapping(bytes32 => address) public extensions;
    /// @notice The inverse map to get the extension id based on its address
    mapping(address => ExtensionEntry) public inverseExtensions;
    /// @notice The map that keeps track of configuration parameters for the DAO and adapters: sha3(configId) => numericValue
    mapping(bytes32 => uint256) public mainConfiguration;
    /// @notice The map to track all the configuration of type Address: sha3(configId) => addressValue
    mapping(bytes32 => address) public addressConfiguration;

    /// @notice controls the lock mechanism using the block.number
    uint256 public lockedAt;

    /**
     * INTERNAL VARIABLES
     */

    /// @notice memberAddress => checkpointNum => DelegateCheckpoint
    mapping(address => mapping(uint32 => DelegateCheckpoint)) _checkpoints;
    /// @notice memberAddress => numDelegateCheckpoints
    mapping(address => uint32) _numCheckpoints;

    /// @notice Clonable contract must have an empty constructor
    constructor() {}

    /**
     * @notice Initialises the DAO
     * @dev Involves initialising available tokens, checkpoints, and membership of creator
     * @dev Can only be called once
     * @param creator The DAO's creator, who will be an initial member
     * @param payer The account which paid for the transaction to create the DAO, who will be an initial member
     */
    //slither-disable-next-line reentrancy-no-eth
    function initialize(address creator, address payer) external {
        require(!initialized, 'dao already initialized');
        initialized = true;
        potentialNewMember(msg.sender);
        potentialNewMember(creator);
        potentialNewMember(payer);
    }

    /**
     * ACCESS CONTROL
     */

    /**
     * @dev Sets the state of the dao to READY
     */
    function finalizeDao() external {
        require(
            isActiveMember(this, msg.sender) || isAdapter(msg.sender),
            'not allowed to finalize'
        );
        state = DaoState.READY;
    }

    /**
     * @notice Contract lock strategy to lock only the caller is an adapter or extension.
     */
    function lockSession() external {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = block.number;
        }
    }

    /**
     * @notice Contract lock strategy to release the lock only the caller is an adapter or extension.
     */
    function unlockSession() external {
        if (isAdapter(msg.sender) || isExtension(msg.sender)) {
            lockedAt = 0;
        }
    }

    /**
     * CONFIGURATIONS
     */

    /**
     * @notice Sets a configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setConfiguration(bytes32 key, uint256 value)
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        mainConfiguration[key] = value;

        emit ConfigurationUpdated(key, value);
    }

    /**
     * @notice Sets an configuration value
     * @dev Changes the value of a key in the configuration mapping
     * @param key The configuration key for which the value will be set
     * @param value The value to set the key
     */
    function setAddressConfiguration(bytes32 key, address value)
        external
        hasAccess(this, AclFlag.SET_CONFIGURATION)
    {
        addressConfiguration[key] = value;

        emit AddressConfigurationUpdated(key, value);
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getConfiguration(bytes32 key) external view returns (uint256) {
        return mainConfiguration[key];
    }

    /**
     * @return The configuration value of a particular key
     * @param key The key to look up in the configuration mapping
     */
    function getAddressConfiguration(bytes32 key)
        external
        view
        returns (address)
    {
        return addressConfiguration[key];
    }

    /**
     * ADAPTERS
     */

    /**
     * @notice Replaces an adapter in the registry in a single step.
     * @notice It handles addition and removal of adapters as special cases.
     * @dev It removes the current adapter if the adapterId maps to an existing adapter address.
     * @dev It adds an adapter if the adapterAddress parameter is not zeroed.
     * @param adapterId The unique identifier of the adapter
     * @param adapterAddress The address of the new adapter or zero if it is a removal operation
     * @param acl The flags indicating the access control layer or permissions of the new adapter
     * @param keys The keys indicating the adapter configuration names.
     * @param values The values indicating the adapter configuration values.
     */
    function replaceAdapter(
        bytes32 adapterId,
        address adapterAddress,
        uint128 acl,
        bytes32[] calldata keys,
        uint256[] calldata values
    ) external hasAccess(this, AclFlag.REPLACE_ADAPTER) {
        require(adapterId != bytes32(0), 'adapterId must not be empty');

        address currentAdapterAddr = adapters[adapterId];
        if (currentAdapterAddr != address(0x0)) {
            delete inverseAdapters[currentAdapterAddr];
            delete adapters[adapterId];
            emit AdapterRemoved(adapterId);
        }

        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 key = keys[i];
            uint256 value = values[i];
            mainConfiguration[key] = value;
            emit ConfigurationUpdated(key, value);
        }

        if (adapterAddress != address(0x0)) {
            require(
                inverseAdapters[adapterAddress].id == bytes32(0),
                'adapterAddress already in use'
            );
            adapters[adapterId] = adapterAddress;
            inverseAdapters[adapterAddress].id = adapterId;
            inverseAdapters[adapterAddress].acl = acl;
            emit AdapterAdded(adapterId, adapterAddress, acl);
        }
    }

    /**
     * @notice Looks up if there is an adapter of a given address
     * @return Whether or not the address is an adapter
     * @param adapterAddress The address to look up
     */
    function isAdapter(address adapterAddress) public view returns (bool) {
        return inverseAdapters[adapterAddress].id != bytes32(0);
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccess(address adapterAddress, AclFlag flag)
        external
        view
        returns (bool)
    {
        return
            DaoLibrary.getFlag(inverseAdapters[adapterAddress].acl, uint8(flag));
    }

    /**
     * @return The address of a given adapter ID
     * @param adapterId The ID to look up
     */
    function getAdapterAddress(bytes32 adapterId)
        external
        view
        returns (address)
    {
        require(adapters[adapterId] != address(0), 'adapter not found');
        return adapters[adapterId];
    }

    /**
     * EXTENSIONS
     */

    /**
     * @notice Adds a new extension to the registry
     * @param extensionId The unique identifier of the new extension
     * @param extension The address of the extension
     */
    // slither-disable-next-line reentrancy-events
    function addExtension(bytes32 extensionId, IExtension extension)
        external
        hasAccess(this, AclFlag.ADD_EXTENSION)
    {
        require(extensionId != bytes32(0), 'extension id must not be empty');
        require(
            extensions[extensionId] == address(0x0),
            'extensionId already in use'
        );
        require(
            !inverseExtensions[address(extension)].deleted,
            'extension can not be re-added'
        );
        extensions[extensionId] = address(extension);
        inverseExtensions[address(extension)].id = extensionId;
        emit ExtensionAdded(extensionId, address(extension));
    }

    // v1.0.6 signature
    function addExtension(
        bytes32,
        IExtension,
        address
    ) external {
        revert('not implemented');
    }

    /**
     * @notice Removes an adapter from the registry
     * @param extensionId The unique identifier of the extension
     */
    function removeExtension(bytes32 extensionId)
        external
        hasAccess(this, AclFlag.REMOVE_EXTENSION)
    {
        require(extensionId != bytes32(0), 'extensionId must not be empty');
        address extensionAddress = extensions[extensionId];
        require(extensionAddress != address(0x0), 'extensionId not registered');
        ExtensionEntry storage extEntry = inverseExtensions[extensionAddress];
        extEntry.deleted = true;
        //slither-disable-next-line mapping-deletion
        delete extensions[extensionId];
        emit ExtensionRemoved(extensionId);
    }

    /**
     * @notice Looks up if there is an extension of a given address
     * @return Whether or not the address is an extension
     * @param extensionAddr The address to look up
     */
    function isExtension(address extensionAddr) public view returns (bool) {
        return inverseExtensions[extensionAddr].id != bytes32(0);
    }

    /**
     * @notice It sets the ACL flags to an Adapter to make it possible to access specific functions of an Extension.
     */
    function setAclToExtensionForAdapter(
        address extensionAddress,
        address adapterAddress,
        uint256 acl
    ) external hasAccess(this, AclFlag.ADD_EXTENSION) {
        require(isAdapter(adapterAddress), 'not an adapter');
        require(isExtension(extensionAddress), 'not an extension');
        inverseExtensions[extensionAddress].acl[adapterAddress] = acl;
    }

    /**
     * @notice Checks if an adapter has a given ACL flag
     * @return Whether or not the given adapter has the given flag set
     * @param adapterAddress The address to look up
     * @param flag The ACL flag to check against the given address
     */
    function hasAdapterAccessToExtension(
        address adapterAddress,
        address extensionAddress,
        uint8 flag
    ) external view returns (bool) {
        return
            isAdapter(adapterAddress) &&
            DaoLibrary.getFlag(
                inverseExtensions[extensionAddress].acl[adapterAddress],
                uint8(flag)
            );
    }

    /**
     * @return The address of a given extension Id
     * @param extensionId The ID to look up
     */
    function getExtensionAddress(bytes32 extensionId)
        external
        view
        returns (address)
    {
        require(extensions[extensionId] != address(0), 'extension not found');
        return extensions[extensionId];
    }

    /**
     * PROPOSALS
     */

    /**
     * @notice Submit proposals to the DAO registry
     */
    function submitProposal(bytes32 proposalId)
        external
        hasAccess(this, AclFlag.SUBMIT_PROPOSAL)
    {
        require(proposalId != bytes32(0), 'invalid proposalId');
        require(
            !getProposalFlag(proposalId, ProposalFlag.EXISTS),
            'proposalId must be unique'
        );
        proposals[proposalId] = Proposal(msg.sender, 1); // 1 means that only the first flag is being set i.e. EXISTS
        emit SubmittedProposal(proposalId, 1);
    }

    /**
     * @notice Sponsor proposals that were submitted to the DAO registry
     * @dev adds SPONSORED to the proposal flag
     * @param proposalId The ID of the proposal to sponsor
     * @param sponsoringMember The member who is sponsoring the proposal
     */
    function sponsorProposal(
        bytes32 proposalId,
        address sponsoringMember,
        address votingAdapterAddr
    ) external onlyMember2(this, sponsoringMember) {
        // also checks if the flag was already set
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.SPONSORED
        );

        uint256 flags = proposal.flags;

        require(
            proposal.adapterAddress == msg.sender,
            'only the adapter that submitted the proposal can sponsor it'
        );

        require(
            !DaoLibrary.getFlag(flags, uint8(ProposalFlag.PROCESSED)),
            'proposal already processed'
        );
        votingAdapter[proposalId] = votingAdapterAddr;
        emit SponsoredProposal(proposalId, flags, votingAdapterAddr);
    }

    /**
     * @notice Mark a proposal as processed in the DAO registry
     * @param proposalId The ID of the proposal that is being processed
     */
    function processProposal(bytes32 proposalId) external {
        Proposal storage proposal = _setProposalFlag(
            proposalId,
            ProposalFlag.PROCESSED
        );

        require(proposal.adapterAddress == msg.sender, 'err::adapter mismatch');
        uint256 flags = proposal.flags;

        emit ProcessedProposal(proposalId, flags);
    }

    /**
     * @notice Sets a flag of a proposal
     * @dev Reverts if the proposal is already processed
     * @param proposalId The ID of the proposal to be changed
     * @param flag The flag that will be set on the proposal
     */
    function _setProposalFlag(bytes32 proposalId, ProposalFlag flag)
        internal
        returns (Proposal storage)
    {
        Proposal storage proposal = proposals[proposalId];

        uint256 flags = proposal.flags;
        require(
            DaoLibrary.getFlag(flags, uint8(ProposalFlag.EXISTS)),
            'proposal does not exist for this dao'
        );

        require(
            proposal.adapterAddress == msg.sender,
            'invalid adapter try to set flag'
        );

        require(!DaoLibrary.getFlag(flags, uint8(flag)), 'flag already set');

        flags = DaoLibrary.setFlag(flags, uint8(flag), true);
        proposals[proposalId].flags = flags;

        return proposals[proposalId];
    }

    /**
     * @return Whether or not a flag is set for a given proposal
     * @param proposalId The proposal to check against flag
     * @param flag The flag to check in the proposal
     */
    function getProposalFlag(bytes32 proposalId, ProposalFlag flag)
        public
        view
        returns (bool)
    {
        return DaoLibrary.getFlag(proposals[proposalId].flags, uint8(flag));
    }

    /**
     * MEMBERS
     */

    /**
     * @notice Sets true for the JAILED flag.
     * @param memberAddress The address of the member to update the flag.
     */
    function jailMember(address memberAddress)
        external
        hasAccess(this, AclFlag.JAIL_MEMBER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];
        require(
            DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            'member does not exist'
        );

        member.flags = DaoLibrary.setFlag(
            member.flags,
            uint8(MemberFlag.JAILED),
            true
        );
    }

    /**
     * @notice Sets false for the JAILED flag.
     * @param memberAddress The address of the member to update the flag.
     */
    function unjailMember(address memberAddress)
        external
        hasAccess(this, AclFlag.JAIL_MEMBER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];
        require(
            DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            'member does not exist'
        );

        member.flags = DaoLibrary.setFlag(
            member.flags,
            uint8(MemberFlag.JAILED),
            false
        );
    }

    /**
     * @notice Checks if a given member address is not jailed.
     * @param memberAddress The address of the member to check the flag.
     */
    function notJailed(address memberAddress) external view returns (bool) {
        return
            !DaoLibrary.getFlag(
                members[memberAddress].flags,
                uint8(MemberFlag.JAILED)
            );
    }

    /**
     * @notice Registers a member address in the DAO if it is not registered or invalid.
     * @notice A potential new member is a member that holds no shares, and its registration still needs to be voted on.
     */
    function potentialNewMember(address memberAddress)
        public
        hasAccess(this, AclFlag.NEW_MEMBER)
    {
        require(memberAddress != address(0x0), 'invalid member address');

        Member storage member = members[memberAddress];
        if (!DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
            require(
                memberAddressesByDelegatedKey[memberAddress] == address(0x0),
                'member address already taken as delegated key'
            );
            member.flags = DaoLibrary.setFlag(
                member.flags,
                uint8(MemberFlag.EXISTS),
                true
            );
            memberAddressesByDelegatedKey[memberAddress] = memberAddress;
            _members.push(memberAddress);
        }

        address bankAddress = extensions[DaoLibrary.BANK_EXT];
        if (bankAddress != address(0x0)) {
            BankExtension bank = BankExtension(bankAddress);
            if (bank.balanceOf(memberAddress, DaoLibrary.MEMBER_COUNT) == 0) {
                bank.addToBalance(
                    this,
                    memberAddress,
                    DaoLibrary.MEMBER_COUNT,
                    1
                );
            }
        }
    }
    
    function potentialNewMemberBatch(address[] calldata memberAddressArray)
        public
        hasAccess(this, AclFlag.NEW_MEMBER)
    {
        for(uint256 i = 0;i<memberAddressArray.length;i++){
            require(memberAddressArray[i] != address(0x0), 'invalid member address');

            Member storage member = members[memberAddressArray[i]];
            if (!DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS))) {
                require(
                    memberAddressesByDelegatedKey[memberAddressArray[i]] == address(0x0),
                    'member address already taken as delegated key'
                );
                member.flags = DaoLibrary.setFlag(
                    member.flags,
                    uint8(MemberFlag.EXISTS),
                    true
                );
                memberAddressesByDelegatedKey[memberAddressArray[i]] = memberAddressArray[i];
                _members.push(memberAddressArray[i]);
            }
            address bankAddress = extensions[DaoLibrary.BANK_EXT];
            if  (bankAddress != address(0x0)) {
                BankExtension bank = BankExtension(bankAddress);
                if (bank.balanceOf(memberAddressArray[i], DaoLibrary.MEMBER_COUNT) == 0) {
                    bank.addToBalance(
                        this,
                        memberAddressArray[i],
                        DaoLibrary.MEMBER_COUNT,
                        1
                    );
                }
            }
        }
    }
    /**
     * @return Whether or not a given address is a member of the DAO.
     * @dev it will resolve by delegate key, not member address.
     * @param addr The address to look up
     */
    function isMember(address addr) external view returns (bool) {
        address memberAddress = memberAddressesByDelegatedKey[addr];
        return getMemberFlag(memberAddress, MemberFlag.EXISTS);
    }

    /**
     * @return Whether or not a flag is set for a given member
     * @param memberAddress The member to check against flag
     * @param flag The flag to check in the member
     */
    function getMemberFlag(address memberAddress, MemberFlag flag)
        public
        view
        returns (bool)
    {
        return DaoLibrary.getFlag(members[memberAddress].flags, uint8(flag));
    }

    /**
     * @notice Returns the number of members in the registry.
     */
    function getNbMembers() external view returns (uint256) {
        return _members.length;
    }

    /**
     * @notice Returns the member address for the given index.
     */
    function getMemberAddress(uint256 index) external view returns (address) {
        return _members[index];
    }

    /**
     * DELEGATE
     */

    /**
     * @notice Updates the delegate key of a member
     * @param memberAddr The member doing the delegation
     * @param newDelegateKey The member who is being delegated to
     */
    function updateDelegateKey(address memberAddr, address newDelegateKey)
        external
        hasAccess(this, AclFlag.UPDATE_DELEGATE_KEY)
    {
        require(newDelegateKey != address(0x0), 'newDelegateKey cannot be 0');

        // skip checks if member is setting the delegate key to their member address
        if (newDelegateKey != memberAddr) {
            require(
                // newDelegate must not be delegated to
                memberAddressesByDelegatedKey[newDelegateKey] == address(0x0),
                'cannot overwrite existing delegated keys'
            );
        } else {
            require(
                memberAddressesByDelegatedKey[memberAddr] == address(0x0),
                'address already taken as delegated key'
            );
        }

        Member storage member = members[memberAddr];
        require(
            DaoLibrary.getFlag(member.flags, uint8(MemberFlag.EXISTS)),
            'member does not exist'
        );

        // Reset the delegation of the previous delegate
        memberAddressesByDelegatedKey[
            getCurrentDelegateKey(memberAddr)
        ] = address(0x0);

        memberAddressesByDelegatedKey[newDelegateKey] = memberAddr;

        _createNewDelegateCheckpoint(memberAddr, newDelegateKey);
        emit UpdateDelegateKey(memberAddr, newDelegateKey);
    }

    /**
     * @param checkAddr The address to check for a delegate
     * @return the delegated address or the checked address if it is not a delegate
     */
    function getAddressIfDelegated(address checkAddr)
        external
        view
        returns (address)
    {
        address delegatedKey = memberAddressesByDelegatedKey[checkAddr];
        return delegatedKey == address(0x0) ? checkAddr : delegatedKey;
    }

    /**
     * @param memberAddr The member whose delegate will be returned
     * @return the delegate key at the current time for a member
     */
    function getCurrentDelegateKey(address memberAddr)
        public
        view
        returns (address)
    {
        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        return
            nCheckpoints > 0
                ? _checkpoints[memberAddr][nCheckpoints - 1].delegateKey
                : memberAddr;
    }

    /**
     * @param memberAddr The member address to look up
     * @return The delegate key address for memberAddr at the second last checkpoint number
     */
    function getPreviousDelegateKey(address memberAddr)
        external
        view
        returns (address)
    {
        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        return
            nCheckpoints > 1
                ? _checkpoints[memberAddr][nCheckpoints - 2].delegateKey
                : memberAddr;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param memberAddr The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The delegate key of the member
     */
    function getPriorDelegateKey(address memberAddr, uint256 blockNumber)
        external
        view
        returns (address)
    {
        require(blockNumber < block.number, 'getPriorDelegateKey: NYD');

        uint32 nCheckpoints = _numCheckpoints[memberAddr];
        if (nCheckpoints == 0) {
            return memberAddr;
        }

        // First check most recent balance
        if (
            _checkpoints[memberAddr][nCheckpoints - 1].fromBlock <= blockNumber
        ) {
            return _checkpoints[memberAddr][nCheckpoints - 1].delegateKey;
        }

        // Next check implicit zero balance
        if (_checkpoints[memberAddr][0].fromBlock > blockNumber) {
            return memberAddr;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            DelegateCheckpoint memory cp = _checkpoints[memberAddr][center];
            if (cp.fromBlock == blockNumber) {
                return cp.delegateKey;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return _checkpoints[memberAddr][lower].delegateKey;
    }

    /**
     * @notice Creates a new delegate checkpoint of a certain member
     * @param member The member whose delegate checkpoints will be added to
     * @param newDelegateKey The delegate key that will be written into the new checkpoint
     */
    function _createNewDelegateCheckpoint(
        address member,
        address newDelegateKey
    ) internal {
        uint32 nCheckpoints = _numCheckpoints[member];
        // The only condition that we should allow the deletegaKey upgrade
        // is when the block.number exactly matches the fromBlock value.
        // Anything different from that should generate a new checkpoint.
        if (
            //slither-disable-next-line incorrect-equality
            nCheckpoints > 0 &&
            _checkpoints[member][nCheckpoints - 1].fromBlock == block.number
        ) {
            _checkpoints[member][nCheckpoints - 1].delegateKey = newDelegateKey;
        } else {
            _checkpoints[member][nCheckpoints] = DelegateCheckpoint(
                uint96(block.number),
                newDelegateKey
            );
            _numCheckpoints[member] = nCheckpoints + 1;
        }
    }
}

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
// SPDX-License-Identifier: MIT
import '../core/DaoRegistry.sol';
import '../interfaces/IExtension.sol';
import '../libraries/DaoLibrary.sol';
import '../modifiers/AdapterGuard.sol';


contract BankExtension is 
    IExtension,
    ERC165 
{
    using Address for address payable;
    using SafeERC20 for IERC20;

    enum AclFlag {
        ADD_TO_BALANCE,
        SUB_FROM_BALANCE,
        INTERNAL_TRANSFER,
        WITHDRAW,
        REGISTER_NEW_TOKEN,
        REGISTER_NEW_INTERNAL_TOKEN,
        UPDATE_TOKEN
    }

    event NewBalance(
        address member,
        address tokenAddr,
        uint160 amount
    );

    event Withdraw(
        address account, 
        address tokenAddr, 
        uint160 amount
    );

    event WithdrawTo(
        address accountFrom,
        address accountTo,
        address tokenAddr,
        uint160 amount
    );
    bool public initialized;
    
    DaoRegistry private _dao;

    modifier hasExtensionAccess(DaoRegistry dao, AclFlag flag) {
        require(
            _dao == dao &&
                (address(this) == msg.sender ||
                    address(_dao) == msg.sender ||
                    !initialized ||
                    DaoLibrary.isInCreationModeAndHasAccess(_dao) ||
                    _dao.hasAdapterAccessToExtension(
                        msg.sender,
                        address(this),
                        uint8(flag)
                    )),
            "bankExt::accessDenied"
        );
        _;
    }

    modifier noProposal() {
        require(_dao.lockedAt() < block.number, 'proposal lock');
        _;
    }

    uint8 public maxExternalTokens; // the maximum number of external tokens that can be stored in the bank
    
    struct Checkpoint {
        // A checkpoint for marking number of votes from a given block
        uint96 fromBlock;
        uint160 amount;
    }

    address[] public tokens;
    address[] public internalTokens;
    // tokenAddress => availability
    mapping(address => bool) public availableTokens;
    mapping(address => bool) public availableInternalTokens;
    // tokenAddress => memberAddress => checkpointNum => Checkpoint
    mapping(address => mapping(address => mapping(uint32 => Checkpoint)))
        public checkpoints;
    // tokenAddress => memberAddress => numCheckpoints
    mapping(address => mapping(address => uint32)) public numCheckpoints;

    constructor() {}

    function initialize(DaoRegistry dao, address creator) external override {
        require(!initialized, 'already initialized');
        require(dao.isMember(creator), 'not a member');
        _dao = dao;
        availableInternalTokens[DaoLibrary.UNITS] = true;
        internalTokens.push(DaoLibrary.UNITS);
        availableInternalTokens[DaoLibrary.MEMBER_COUNT] = true;
        internalTokens.push(DaoLibrary.MEMBER_COUNT);
        uint256 nbMembers = dao.getNbMembers();
        for (uint256 i = 0; i < nbMembers; i++) {
            addToBalance(
                dao,
                dao.getMemberAddress(i),
                DaoLibrary.MEMBER_COUNT,
                1
            );
        }
        _createNewAmountCheckpoint(creator, DaoLibrary.UNITS, 1);
        _createNewAmountCheckpoint(DaoLibrary.TOTAL, DaoLibrary.UNITS, 1);
        initialized = true;
    }

    function withdraw(
        DaoRegistry dao,
        address payable member,
        address tokenAddr,
        uint256 amount
    ) external hasExtensionAccess(dao, AclFlag.WITHDRAW) {
        require(
            balanceOf(member, tokenAddr) >= amount,
            'bank::withdraw::not enough funds'
        );
        subtractFromBalance(dao, member, tokenAddr, amount);
        if (tokenAddr == DaoLibrary.ETH_TOKEN) {
            member.sendValue(amount);
        } else {
            IERC20(tokenAddr).safeTransfer(member, amount);
        }
        emit Withdraw(member, tokenAddr, uint160(amount));
    }

    function withdrawTo(
        DaoRegistry dao,
        address memberFrom,
        address payable memberTo,
        address tokenAddr,
        uint256 amount
    ) external hasExtensionAccess(dao, AclFlag.WITHDRAW) {
        require(
            balanceOf(memberFrom, tokenAddr) >= amount,
            'bank::withdraw::not enough funds'
        );
        subtractFromBalance(dao, memberFrom, tokenAddr, amount);
        if (tokenAddr == DaoLibrary.ETH_TOKEN) {
            memberTo.sendValue(amount);
        } else {
            IERC20(tokenAddr).safeTransfer(memberTo, amount);
        }

        //slither-disable-next-line reentrancy-events
        emit WithdrawTo(memberFrom, memberTo, tokenAddr, uint160(amount));
    }

    /**
     * @return Whether or not the given token is an available internal token in the bank
     * @param token The address of the token to look up
     */
    function isInternalToken(address token) external view returns (bool) {
        return availableInternalTokens[token];
    }

    /**
     * @return Whether or not the given token is an available token in the bank
     * @param token The address of the token to look up
     */
    function isTokenAllowed(address token) public view returns (bool) {
        return availableTokens[token];
    }

    /**
     * @notice Sets the maximum amount of external tokens allowed in the bank
     * @param maxTokens The maximum amount of token allowed
     */
    function setMaxExternalTokens(uint8 maxTokens) external {
        require(!initialized, 'already initialized');
        require(
            maxTokens > 0 && maxTokens <= DaoLibrary.MAX_TOKENS_GUILD_BANK,
            'maxTokens should be (0,200]'
        );
        maxExternalTokens = maxTokens;
    }

    /*
     * BANK
     */

    /**
     * @notice Registers a potential new token in the bank
     * @dev Cannot be a reserved token or an available internal token
     * @param token The address of the token
     */
    function registerPotentialNewToken(DaoRegistry dao, address token)
        external
        hasExtensionAccess(dao, AclFlag.REGISTER_NEW_TOKEN)
    {
        require(DaoLibrary.isNotReservedAddress(token), 'reservedToken');
        require(!availableInternalTokens[token], 'internalToken');
        require(
            tokens.length <= maxExternalTokens,
            'exceeds the maximum tokens allowed'
        );

        if (!availableTokens[token]) {
            availableTokens[token] = true;
            tokens.push(token);
        }
    }

    /**
     * @notice Registers a potential new internal token in the bank
     * @dev Can not be a reserved token or an available token
     * @param token The address of the token
     */
    function registerPotentialNewInternalToken(DaoRegistry dao, address token)
        external
        hasExtensionAccess(dao, AclFlag.REGISTER_NEW_INTERNAL_TOKEN)
    {
        require(DaoLibrary.isNotReservedAddress(token), 'reservedToken');
        require(!availableTokens[token], 'availableToken');

        if (!availableInternalTokens[token]) {
            availableInternalTokens[token] = true;
            internalTokens.push(token);
        }
    }

    function updateToken(DaoRegistry dao, address tokenAddr)
        external
        hasExtensionAccess(dao, AclFlag.UPDATE_TOKEN)
    {
        require(isTokenAllowed(tokenAddr), 'token not allowed');
        uint256 totalBalance = balanceOf(DaoLibrary.TOTAL, tokenAddr);

        uint256 realBalance;

        if (tokenAddr == DaoLibrary.ETH_TOKEN) {
            realBalance = address(this).balance;
        } else {
            IERC20 erc20 = IERC20(tokenAddr);
            realBalance = erc20.balanceOf(address(this));
        }

        if (totalBalance < realBalance) {
            addToBalance(
                dao,
                DaoLibrary.GUILD,
                tokenAddr,
                realBalance - totalBalance
            );
        } else if (totalBalance > realBalance) {
            uint256 tokensToRemove = totalBalance - realBalance;
            uint256 guildBalance = balanceOf(DaoLibrary.GUILD, tokenAddr);
            if (guildBalance > tokensToRemove) {
                subtractFromBalance(
                    dao,
                    DaoLibrary.GUILD,
                    tokenAddr,
                    tokensToRemove
                );
            } else {
                subtractFromBalance(
                    dao,
                    DaoLibrary.GUILD,
                    tokenAddr,
                    guildBalance
                );
            }
        }
    }

    /**
     * Public read-only functions
     */

    /**
     * Internal bookkeeping
     */

    /**
     * @return The token from the bank of a given index
     * @param index The index to look up in the bank's tokens
     */
    function getToken(uint256 index) external view returns (address) {
        return tokens[index];
    }

    /**
     * @return The amount of token addresses in the bank
     */
    function nbTokens() external view returns (uint256) {
        return tokens.length;
    }

    /**
     * @return All the tokens registered in the bank.
     */
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * @return The internal token at a given index
     * @param index The index to look up in the bank's array of internal tokens
     */
    function getInternalToken(uint256 index) external view returns (address) {
        return internalTokens[index];
    }

    /**
     * @return The amount of internal token addresses in the bank
     */
    function nbInternalTokens() external view returns (uint256) {
        return internalTokens.length;
    }

    function addToBalance(
        address,
        address,
        uint256
    ) external payable {
        revert('not implemented');
    }

    /**
     * @notice Adds to a member's balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function addToBalance(
        DaoRegistry dao,
        address member,
        address token,
        uint256 amount
    ) public payable hasExtensionAccess(dao, AclFlag.ADD_TO_BALANCE) {
        require(
            availableTokens[token] || availableInternalTokens[token],
            'unknown token address'
        );
        uint256 newAmount = balanceOf(member, token) + amount;
        uint256 newTotalAmount = balanceOf(DaoLibrary.TOTAL, token) + amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(DaoLibrary.TOTAL, token, newTotalAmount);
    }

    function addToBalanceBatch(
        DaoRegistry dao,
        address[] memory member ,
        address token,
        uint256[] memory amount
    ) public payable hasExtensionAccess(dao, AclFlag.ADD_TO_BALANCE) {
        require(
            availableTokens[token] || availableInternalTokens[token],
            'unknown token address'
        );
        for(uint256 i;i<member.length;i++){
            uint256 newAmount = balanceOf(member[i], token) + amount[i];
            uint256 newTotalAmount = balanceOf(DaoLibrary.TOTAL, token) + amount[i];
            _createNewAmountCheckpoint(member[i], token, newAmount);
            _createNewAmountCheckpoint(DaoLibrary.TOTAL, token, newTotalAmount);
        }

    }
    /**
     * @notice Remove from a member's balance of a given token
     * @param member The member whose balance will be updated
     * @param token The token to update
     * @param amount The new balance
     */
    function subtractFromBalance(
        DaoRegistry dao,
        address member,
        address token,
        uint256 amount
    ) public hasExtensionAccess(dao, AclFlag.SUB_FROM_BALANCE) {
        uint256 newAmount = balanceOf(member, token) - amount;
        uint256 newTotalAmount = balanceOf(DaoLibrary.TOTAL, token) - amount;

        _createNewAmountCheckpoint(member, token, newAmount);
        _createNewAmountCheckpoint(DaoLibrary.TOTAL, token, newTotalAmount);
    }

    function subtractFromBalance(
        address,
        address,
        uint256
    ) external pure {
        revert('not implemented');
    }

    function internalTransfer(
        address,
        address,
        address,
        uint256
    ) external pure {
        revert('not implemented');
    }

    /**
     * @notice Make an internal token transfer
     * @param from The member who is sending tokens
     * @param to The member who is receiving tokens
     * @param amount The new amount to transfer
     */
    function internalTransfer(
        DaoRegistry dao,
        address from,
        address to,
        address token,
        uint256 amount
    ) external hasExtensionAccess(dao, AclFlag.INTERNAL_TRANSFER) {
        require(_dao.notJailed(from), 'no transfer from jail');
        require(_dao.notJailed(to), 'no transfer from jail');
        uint256 newAmount = balanceOf(from, token) - amount;
        uint256 newAmount2 = balanceOf(to, token) + amount;

        _createNewAmountCheckpoint(from, token, newAmount);
        _createNewAmountCheckpoint(to, token, newAmount2);
    }

    /**
     * @notice Returns an member's balance of a given token
     * @param member The address to look up
     * @param tokenAddr The token where the member's balance of which will be returned
     * @return The amount in account's tokenAddr balance
     */
    function balanceOf(address member, address tokenAddr)
        public
        view
        returns (uint160)
    {
        uint32 nCheckpoints = numCheckpoints[tokenAddr][member];
        return
            nCheckpoints > 0
                ? checkpoints[tokenAddr][member][nCheckpoints - 1].amount
                : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorAmount(
        address account,
        address tokenAddr,
        uint256 blockNumber
    ) external view returns (uint256) {
        require(
            blockNumber < block.number,
            'bank::getPriorAmount: not yet determined'
        );

        uint32 nCheckpoints = numCheckpoints[tokenAddr][account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (
            checkpoints[tokenAddr][account][nCheckpoints - 1].fromBlock <=
            blockNumber
        ) {
            return checkpoints[tokenAddr][account][nCheckpoints - 1].amount;
        }

        // Next check implicit zero balance
        if (checkpoints[tokenAddr][account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[tokenAddr][account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.amount;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[tokenAddr][account][lower].amount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            this.withdrawTo.selector == interfaceId;
    }

    /**
     * @notice Creates a new amount checkpoint for a token of a certain member
     * @dev Reverts if the amount is greater than 2**64-1
     * @param member The member whose checkpoints will be added to
     * @param token The token of which the balance will be changed
     * @param amount The amount to be written into the new checkpoint
     */
    function _createNewAmountCheckpoint(
        address member,
        address token,
        uint256 amount
    ) internal {
        bool isValidToken = false;
        if (availableInternalTokens[token]) {
            require(
                amount < type(uint88).max,
                'token amount exceeds the maximum limit for internal tokens'
            );
            isValidToken = true;
        } else if (availableTokens[token]) {
            require(
                amount < type(uint160).max,
                'token amount exceeds the maximum limit for external tokens'
            );
            isValidToken = true;
        }
        uint160 newAmount = uint160(amount);

        require(isValidToken, 'token not registered');

        uint32 nCheckpoints = numCheckpoints[token][member];
        if (
            // The only condition that we should allow the amount update
            // is when the block.number exactly matches the fromBlock value.
            // Anything different from that should generate a new checkpoint.
            //slither-disable-next-line incorrect-equality
            nCheckpoints > 0 &&
            checkpoints[token][member][nCheckpoints - 1].fromBlock ==
            block.number
        ) {
            checkpoints[token][member][nCheckpoints - 1].amount = newAmount;
        } else {
            checkpoints[token][member][nCheckpoints] = Checkpoint(
                uint96(block.number),
                newAmount
            );
            numCheckpoints[token][member] = nCheckpoints + 1;
        }
        //slither-disable-next-line reentrancy-events
        emit NewBalance(member, token, newAmount);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";
import "../extensions/BankExtension.sol";
import "../libraries/DaoLibrary.sol";

abstract contract MemberGuard {
    /**
     * @dev Only members of the DAO are allowed to execute the function call.
     */
    modifier onlyMember(DaoRegistry dao) {
        _onlyMember(dao, msg.sender);
        _;
    }

    modifier onlyMember2(DaoRegistry dao, address _addr) {
        _onlyMember(dao, _addr);
        _;
    }

    function _onlyMember(DaoRegistry dao, address _addr) internal view {
        require(isActiveMember(dao, _addr), "onlyMember");
    }

    function isActiveMember(DaoRegistry dao, address _addr)
        public
        view
        returns (bool)
    {
        address bankAddress = dao.extensions(DaoLibrary.BANK_EXT);
        if (bankAddress != address(0x0)) {
            address memberAddr = DaoLibrary.msgSender(dao, _addr);
            return
                dao.isMember(_addr) &&
                BankExtension(bankAddress).balanceOf(
                    memberAddr,
                    DaoLibrary.UNITS
                ) >
                0;
        }

        return dao.isMember(_addr);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";
import "../libraries/DaoLibrary.sol";

abstract contract AdapterGuard {
    /**
     * @dev Only registered adapters are allowed to execute the function call.
     */
    modifier onlyAdapter(DaoRegistry dao) {
        require(
            dao.isAdapter(msg.sender) ||
                DaoLibrary.isInCreationModeAndHasAccess(dao),
            "onlyAdapter"
        );
        _;
    }

    modifier reentrancyGuard(DaoRegistry dao) {
        require(dao.lockedAt() != block.number, "reentrancy guard");
        dao.lockSession();
        _;
        dao.unlockSession();
    }

    modifier executorFunc(DaoRegistry dao) {
        address executorAddr = dao.getExtensionAddress(
            keccak256("executor-ext")
        );
        require(address(this) == executorAddr, "only callable by the executor");
        _;
    }

    modifier hasAccess(DaoRegistry dao, DaoRegistry.AclFlag flag) {
        require(
            DaoLibrary.isInCreationModeAndHasAccess(dao) ||
                dao.hasAdapterAccess(msg.sender, flag),
            "accessDenied"
        );
        _;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";
import "../interfaces/IReimbursement.sol";
import "../libraries/ReimbursableLibrary.sol";

abstract contract Reimbursable {
    struct ReimbursementData {
        uint256 gasStart; // how much gas is left before executing anything
        bool shouldReimburse; // should the transaction be reimbursed or not ?
        uint256 spendLimitPeriod; // how long (in seconds) is the spend limit period
        IReimbursement reimbursement; // which adapter address is used for reimbursement
    }

    /**
     * @dev Only registered adapters are allowed to execute the function call.
     */
    modifier reimbursable(DaoRegistry dao) {
        ReimbursementData memory data = ReimbursableLibrary.beforeExecution(dao);
        _;
        ReimbursableLibrary.afterExecution(dao, data);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../extensions/BankExtension.sol";
import "../core/DaoRegistry.sol";

library DaoLibrary {


    // EXTENSIONS
    bytes32 internal constant BANK_EXT = keccak256("bank-ext");
    bytes32 internal constant ERC20_EXT = keccak256("erc20-ext");
    bytes32 internal constant MEMBER_EXT = keccak256("member-ext"); 
    bytes32 internal constant DYNAMIC_EQUITY_EXT = keccak256("dynamic-equity-ext");
    bytes32 internal constant VESTED_EQUITY_EXT = keccak256("vested-equity-ext");
    bytes32 internal constant COMMUNITY_EQUITY_EXT = keccak256("community-equity-ext"); 
    
    // ADAPTER
    bytes32 internal constant CONFIGURATION_ADPT = keccak256("configuration-adpt");
    bytes32 internal constant ERC20_ADPT = keccak256("erc20-adpt");
    bytes32 internal constant MANAGER_ADPT = keccak256("manager-adpt");
    bytes32 internal constant VOTING_ADPT = keccak256("voting-adpt");
    bytes32 internal constant MEMBER_ADPT = keccak256("member-adpt"); 
    bytes32 internal constant DYNAMIC_EQUITY_ADPT = keccak256("dynamic-equity-adpt");
    bytes32 internal constant VESTED_EQUITY_ADPT = keccak256("vested-equity-adpt"); 
    bytes32 internal constant COMMUNITY_EQUITY_ADPT = keccak256("community-equity-adpt");

    // UTIL
    bytes32 internal constant REIMBURSEMENT_ADPT = keccak256("reimbursament-adpt");
    bytes32 internal constant FOUNDANCE_FACTORY = keccak256("foundance-factory");


    // ADDRESSES
    address internal constant GUILD = address(0xdead);
    address internal constant ESCROW = address(0x4bec);
    address internal constant TOTAL = address(0xbabe);
    address internal constant UNITS = address(0xFF1CE);
    address internal constant LOOT = address(0xB105F00D);
    address internal constant ETH_TOKEN = address(0x0);
    address internal constant MEMBER_COUNT = address(0xDECAFBAD);

    // CONSTANTS
    uint256 internal constant FOUNDANCE_WORKDAYS_WEEK = 5;
    uint256 internal constant FOUNDANCE_MONTHS_YEAR = 12;
    uint256 internal constant FOUNDANCE_WEEKS_MONTH = 434524;
    uint256 internal constant FOUNDANCE_WEEKS_MONTH_PRECISION = 5;
    uint256 internal constant FOUNDANCE_PRECISION = 5;
    uint8   internal constant MAX_TOKENS_GUILD_BANK = 200;


    function totalTokens(BankExtension bank) internal view returns (uint256) {
        return memberTokens(bank, TOTAL) - memberTokens(bank, GUILD); //GUILD is accounted for twice otherwise
    }

    function totalUnitTokens(BankExtension bank) internal view returns (uint256) {
        return  bank.balanceOf(TOTAL, UNITS) - bank.balanceOf(GUILD, UNITS); //GUILD is accounted for twice otherwise
    }
    /**
     * @notice calculates the total number of units.
     */
    function priorTotalTokens(BankExtension bank, uint256 at)
        internal
        view
        returns (uint256)
    {
        return
            priorMemberTokens(bank, TOTAL, at) -
            priorMemberTokens(bank, GUILD, at);
    }

    function memberTokens(BankExtension bank, address member)
        internal
        view
        returns (uint256)
    {
        return bank.balanceOf(member, UNITS) + bank.balanceOf(member, LOOT);
    }

    function msgSender(DaoRegistry dao, address addr)
        internal
        view
        returns (address)
    {
        address memberAddress = dao.getAddressIfDelegated(addr);
        address delegatedAddress = dao.getCurrentDelegateKey(addr);

        require(
            memberAddress == delegatedAddress || delegatedAddress == addr,
            "call with your delegate key"
        );

        return memberAddress;
    }

    /**
     * @notice calculates the total number of units.
     */
    function priorMemberTokens(
        BankExtension bank,
        address member,
        uint256 at
    ) internal view returns (uint256) {
        return
            bank.getPriorAmount(member, UNITS, at) +
            bank.getPriorAmount(member, LOOT, at);
    }

    //helper
    function getFlag(uint256 flags, uint256 flag) internal pure returns (bool) {
        return (flags >> uint8(flag)) % 2 == 1;
    }

    function setFlag(
        uint256 flags,
        uint256 flag,
        bool value
    ) internal pure returns (uint256) {
        if (getFlag(flags, flag) != value) {
            if (value) {
                return flags + 2**flag;
            } else {
                return flags - 2**flag;
            }
        } else {
            return flags;
        }
    }

    /**
     * @notice Checks if a given address is reserved.
     */
    function isNotReservedAddress(address addr) internal pure returns (bool) {
        return addr != GUILD && addr != TOTAL && addr != ESCROW;
    }

    /**
     * @notice Checks if a given address is zeroed.
     */
    function isNotZeroAddress(address addr) internal pure returns (bool) {
        return addr != address(0x0);
    }

    function potentialNewMember(
        address memberAddress,
        DaoRegistry dao,
        BankExtension bank
    ) internal {
        dao.potentialNewMember(memberAddress);
        require(memberAddress != address(0x0), "invalid member address");
        if (address(bank) != address(0x0)) {
            if (bank.balanceOf(memberAddress, MEMBER_COUNT) == 0) {
                bank.addToBalance(dao, memberAddress, MEMBER_COUNT, 1);
            }
        }
    }

    /**
     * A DAO is in creation mode is the state of the DAO is equals to CREATION and
     * 1. The number of members in the DAO is ZERO or,
     * 2. The sender of the tx is a DAO member (usually the DAO owner) or,
     * 3. The sender is an adapter.
     */
    // slither-disable-next-line calls-loop
    function isInCreationModeAndHasAccess(DaoRegistry dao)
        internal
        view
        returns (bool)
    {
        return
            dao.state() == DaoRegistry.DaoState.CREATION &&
            (dao.getNbMembers() == 0 ||
                dao.isMember(msg.sender) ||
                dao.isAdapter(msg.sender));
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// SPDX-License-Identifier: MIT
import "./DaoLibrary.sol";
import "../core/DaoRegistry.sol";
import "../extensions/BankExtension.sol";
import "../extensions/ERC20Extension.sol";


library GovernanceLibrary {
    string public constant ROLE_PREFIX = "governance.role.";
    bytes32 public constant DEFAULT_GOV_TOKEN_CFG =
        keccak256(abi.encodePacked(ROLE_PREFIX, "default"));

    /*
     * @dev Checks if the member address holds enough funds to be considered a governor.
     * @param dao The DAO Address.
     * @param memberAddr The message sender to be verified as governor.
     * @param proposalId The proposal id to retrieve the governance token address if configured.
     * @param snapshot The snapshot id to check the balance of the governance token for that member configured.
     */
    function getVotingWeight(
        DaoRegistry dao,
        address voterAddr,
        bytes32 proposalId,
        uint256 snapshot
    ) internal view returns (uint256) {
        (address adapterAddress, ) = dao.proposals(proposalId);

        // 1st - if there is any governance token configuration
        // for the adapter address, then read the voting weight based on that token.
        address governanceToken = dao.getAddressConfiguration(
            keccak256(abi.encodePacked(ROLE_PREFIX, adapterAddress))
        );
        if (DaoLibrary.isNotZeroAddress(governanceToken)) {
            return getVotingWeight(dao, governanceToken, voterAddr, snapshot);
        }

        // 2nd - if there is no governance token configured for the adapter,
        // then check if exists a default governance token.
        // If so, then read the voting weight based on that token.
        governanceToken = dao.getAddressConfiguration(DEFAULT_GOV_TOKEN_CFG);
        if (DaoLibrary.isNotZeroAddress(governanceToken)) {
            return getVotingWeight(dao, governanceToken, voterAddr, snapshot);
        }

        // 3rd - if none of the previous options are available, assume the
        // governance token is UNITS, then read the voting weight based on that token.
        return
            BankExtension(dao.getExtensionAddress(DaoLibrary.BANK_EXT))
                .getPriorAmount(voterAddr, DaoLibrary.UNITS, snapshot);
    }

    function getVotingWeight(
        DaoRegistry dao,
        address governanceToken,
        address voterAddr,
        uint256 snapshot
    ) internal view returns (uint256) {
        BankExtension bank = BankExtension(
            dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        if (bank.isInternalToken(governanceToken)) {
            return bank.getPriorAmount(voterAddr, governanceToken, snapshot);
        }

        // The external token must implement the getPriorAmount function,
        // otherwise this call will fail and revert the voting process.
        // The actual revert does not show a clear reason, so we catch the error
        // and revert with a better error message.
        // slither-disable-next-line unused-return
        try
            ERC20Extension(governanceToken).getPriorAmount(voterAddr, snapshot)
        returns (
            // slither-disable-next-line uninitialized-local,variable-scope
            uint256 votingWeight
        ) {
            return votingWeight;
        } catch {
            revert("getPriorAmount not implemented");
        }
    }

    function calc(
        uint256 balance,
        uint256 units,
        uint256 totalUnits
    ) internal pure returns (uint256) {
        require(totalUnits > 0, "totalUnits must be greater than 0");
        require(
            units <= totalUnits,
            "units must be less than or equal to totalUnits"
        );
        if (balance == 0) {
            return 0;
        }
        // The balance for Internal and External tokens are limited to 2^64-1 (see Bank.sol:L411-L421)
        // The maximum number of units is limited to 2^64-1 (see ...)
        // Worst case cenario is: balance=2^64-1 * units=2^64-1, no overflows.
        uint256 prod = balance * units;
        return prod / totalUnits;
    }

}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";

interface IExtension {
    function initialize(DaoRegistry dao, address creator) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";

interface IReimbursement {
    function reimburseTransaction(
        DaoRegistry dao,
        address payable caller,
        uint256 gasUsage,
        uint256 spendLimitPeriod
    ) external;

    function shouldReimburse(DaoRegistry dao, uint256 gasLeft)
        external
        view
        returns (bool, uint256);
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "../core/DaoRegistry.sol";
import "../interfaces/IReimbursement.sol";
import "../modifiers/Reimbursable.sol";


library ReimbursableLibrary {
    function beforeExecution(DaoRegistry dao)
        internal
        returns (Reimbursable.ReimbursementData memory data)
    {
        data.gasStart = gasleft();
        require(dao.lockedAt() != block.number, "reentrancy guard");
        dao.lockSession();
        address reimbursementAdapter = dao.adapters(DaoLibrary.REIMBURSEMENT_ADPT);
        if (reimbursementAdapter == address(0x0)) {
            data.shouldReimburse = false;
        } else {
            data.reimbursement = IReimbursement(reimbursementAdapter);

            (bool shouldReimburse, uint256 spendLimitPeriod) = data
                .reimbursement
                .shouldReimburse(dao, data.gasStart);

            data.shouldReimburse = shouldReimburse;
            data.spendLimitPeriod = spendLimitPeriod;
        }
    }

    function afterExecution(
        DaoRegistry dao,
        Reimbursable.ReimbursementData memory data
    ) internal {
        afterExecution2(dao, data, payable(msg.sender));
    }

    function afterExecution2(
        DaoRegistry dao,
        Reimbursable.ReimbursementData memory data,
        address payable caller
    ) internal {
        if (data.shouldReimburse) {
            data.reimbursement.reimburseTransaction(
                dao,
                caller,
                data.gasStart - gasleft(),
                data.spendLimitPeriod
            );
        }
        dao.unlockSession();
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// SPDX-License-Identifier: MIT
import {Foundance} from "../libraries/Foundance.sol";
import '../core/DaoRegistry.sol';
import "./BankExtension.sol";
import "../interfaces/IExtension.sol";
import "../adapters/interfaces/IERC20Adapter.sol";
import "../libraries/DaoLibrary.sol";
import "../modifiers/AdapterGuard.sol";

contract ERC20Extension is AdapterGuard, IExtension, IERC20 {


    // Internally tracks deployment under eip-1167 proxy pattern
    bool public initialized;
    // The DAO address that this extension belongs to
    DaoRegistry public _dao;





    
    // The token address managed by the DAO that tracks the internal transfers
    address public tokenAddress;
    // The name of the token managed by the DAO
    string public tokenName;
    // The symbol of the token managed by the DAO
    string public tokenSymbol;
    // The number of decimals of the token managed by the DAO
    uint8 public tokenDecimals;
    // Tracks all the token allowances: owner => spender => amount
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {}

    function initialize(DaoRegistry dao, address) external override {
        require(!initialized, "already initialized");
        require(tokenAddress != address(0x0), "missing token address");
        require(bytes(tokenName).length != 0, "missing token name");
        require(bytes(tokenSymbol).length != 0, "missing token symbol");
        initialized = true;
        _dao = dao;
    }

    //SET
    /**
     * @dev Returns the token address managed by the DAO that tracks the
     * internal transfers.
     */
    function token() external view virtual returns (address) {
        return tokenAddress;
    }

    /**
     * @dev Sets the token address if the extension is not initialized,
     * not reserved and not zero.
     */
    function setToken(address _tokenAddress) external {
        require(!initialized, "already initialized");
        require(_tokenAddress != address(0x0), "invalid token address");
        require(
            DaoLibrary.isNotReservedAddress(_tokenAddress),
            "token address already in use"
        );

        tokenAddress = _tokenAddress;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual returns (string memory) {
        return tokenName;
    }

    /**
     * @dev Sets the name of the token if the extension is not initialized.
     */
    function setName(string memory _name) external {
        require(!initialized, "already initialized");
        tokenName = _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual returns (string memory) {
        return tokenSymbol;
    }

    /**
     * @dev Sets the token symbol if the extension is not initialized.
     */
    function setSymbol(string memory _symbol) external {
        require(!initialized, "already initialized");
        tokenSymbol = _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     */
    function decimals() external view virtual returns (uint8) {
        return tokenDecimals;
    }

    /**
     * @dev Sets the token decimals if the extension is not initialized.
     */
    function setDecimals(uint8 _decimals) external {
        require(!initialized, "already initialized");
        tokenDecimals = _decimals;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view override returns (uint256) {
        BankExtension bank = BankExtension(
            _dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        return bank.balanceOf(DaoLibrary.TOTAL, tokenAddress);
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        BankExtension bank = BankExtension(
            _dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        return bank.balanceOf(account, tokenAddress);
    }

    /**
     * @dev Returns the amount of tokens owned by `account` considering the snapshot.
     */
    function getPriorAmount(address account, uint256 snapshot)
        external
        view
        returns (uint256)
    {
        BankExtension bank = BankExtension(
            _dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );
        return bank.getPriorAmount(account, tokenAddress, snapshot);
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * @param spender The address account that will have the units decremented.
     * @param amount The amount to decrement from the spender account.
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    // slither-disable-next-line reentrancy-benign
    function approve(address spender, uint256 amount)
        public
        override
        reentrancyGuard(_dao)
        returns (bool)
    {
        address senderAddr = _dao.getAddressIfDelegated(msg.sender);
        require(
            DaoLibrary.isNotZeroAddress(senderAddr),
            "ERC20: approve from the zero address"
        );
        require(
            DaoLibrary.isNotZeroAddress(spender),
            "ERC20: approve to the zero address"
        );
        require(_dao.isMember(senderAddr), "sender is not a member");
        require(
            DaoLibrary.isNotReservedAddress(spender),
            "spender can not be a reserved address"
        );

        _allowances[senderAddr][spender] = amount;
        // slither-disable-next-line reentrancy-events
        emit Approval(senderAddr, spender, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * @dev The transfer operation follows the DAO configuration specified
     * by the ERC20_EXT_TRANSFER_TYPE property.
     * @param recipient The address account that will have the units incremented.
     * @param amount The amount to increment in the recipient account.
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        return
            transferFrom(
                _dao.getAddressIfDelegated(msg.sender),
                recipient,
                amount
            );
    }

    function _transferInternal(
        address senderAddr,
        address recipient,
        uint256 amount,
        BankExtension bank
    ) internal {
        DaoLibrary.potentialNewMember(recipient, _dao, bank);
        bank.internalTransfer(_dao, senderAddr, recipient, tokenAddress, amount);
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * @dev The transfer operation follows the DAO configuration specified
     * by the ERC20_EXT_TRANSFER_TYPE property.
     * @param sender The address account that will have the units decremented.
     * @param recipient The address account that will have the units incremented.
     * @param amount The amount to decrement from the sender account.
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(
            DaoLibrary.isNotZeroAddress(recipient),
            "ERC20: transfer to the zero address"
        );

        IERC20Adapter strategy = IERC20Adapter(
            _dao.getAdapterAddress(DaoLibrary.ERC20_ADPT)
        );

        (
            IERC20Adapter.ApprovalType approvalType,
            uint256 allowedAmount
        ) = strategy.evaluateTransfer(
                _dao,
                tokenAddress,
                sender,
                recipient,
                amount,
                msg.sender
            );

        BankExtension bank = BankExtension(
            _dao.getExtensionAddress(DaoLibrary.BANK_EXT)
        );

        if (approvalType == IERC20Adapter.ApprovalType.NONE) {
            revert("transfer not allowed");
        }

        if (approvalType == IERC20Adapter.ApprovalType.SPECIAL) {
            _transferInternal(sender, recipient, amount, bank);
            //slither-disable-next-line reentrancy-events
            emit Transfer(sender, recipient, amount);
            return true;
        }

        if (sender != msg.sender) {
            uint256 currentAllowance = _allowances[sender][msg.sender];
            //check if sender has approved msg.sender to spend amount
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );

            if (allowedAmount >= amount) {
                _allowances[sender][msg.sender] = currentAllowance - amount;
            }
        }

        if (allowedAmount >= amount) {
            _transferInternal(sender, recipient, amount, bank);
            //slither-disable-next-line reentrancy-events
            emit Transfer(sender, recipient, amount);
            return true;
        }

        return false;
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import {Foundance} from "../../libraries/Foundance.sol";
import "../../core/DaoRegistry.sol";

interface IERC20Adapter {
      enum AclFlag {
        REGISTER_TRANSFER
    }
    enum ApprovalType {
        NONE,
        STANDARD,
        SPECIAL
    }

    function evaluateTransfer(
        DaoRegistry dao,
        address tokenAddr,
        address from,
        address to,
        uint256 amount,
        address caller
    ) external view returns (ApprovalType, uint256);
}
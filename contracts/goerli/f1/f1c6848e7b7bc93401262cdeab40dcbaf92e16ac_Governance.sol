// SPDX-License-Identifier: AGPL-3.0-only

// The Governance Policy submits & activates instructions in a INSTR module

pragma solidity ^0.8.15;

import "../Kernel.sol";
import { DefaultInstructions, Actions, Instruction } from "../modules/INSTR.sol";
import { DefaultVotes } from "../modules/VOTES.sol";


interface IGovernance {

    struct ProposalMetadata {
        bytes32 title;
        address submitter;
        uint256 submissionTimestamp;
        string proposalURI;
    }

    struct ActivatedProposal {
        uint256 proposalId;
        uint256 activationTimestamp;
    }
    
    event ProposalSubmitted(uint256 proposalId);
    event ProposalEndorsed(uint256 proposalId, address voter, uint256 amount);
    event ProposalActivated(uint256 proposalId, uint256 timestamp);
    event WalletVoted(uint256 proposalId, address voter, bool for_, uint256 userVotes);
    event ProposalExecuted(uint256 proposalId);
    
    // proposing
    error NotEnoughVotesToPropose();

    // endorsing
    error CannotEndorseNullProposal();
    error CannotEndorseInvalidProposal();

    // activating
    error NotAuthorizedToActivateProposal();
    error NotEnoughEndorsementsToActivateProposal();
    error ProposalAlreadyActivated();
    error ActiveProposalNotExpired();
    error SubmittedProposalHasExpired();

    // voting
    error NoActiveProposalDetected();
    error UserAlreadyVoted();

    // executing
    error NotEnoughVotesToExecute();
    error ExecutionTimelockStillActive();

    // claiming
    error VotingTokensAlreadyReclaimed();
    error CannotReclaimTokensForActiveVote();
    error CannotReclaimZeroVotes();
}


contract Governance is Policy, IGovernance {


    /////////////////////////////////////////////////////////////////////////////////
    //                         Kernel Policy Configuration                         //
    /////////////////////////////////////////////////////////////////////////////////


    DefaultInstructions public INSTR;
    DefaultVotes public VOTES;

    constructor(Kernel kernel_) Policy(kernel_) {}

    function configureDependencies() external override onlyKernel returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](2);
        
        dependencies[0] = toKeycode("INSTR");
        INSTR = DefaultInstructions(getModuleAddress(toKeycode("INSTR")));
        
        dependencies[1] = toKeycode("VOTES");
        VOTES = DefaultVotes(getModuleAddress(toKeycode("VOTES")));
    }

    function requestPermissions()
        external
        view
        override
        onlyKernel
        returns (Permissions[] memory requests)
    {
        requests = new Permissions[](4);
        requests[0] = Permissions(toKeycode("INSTR"), INSTR.store.selector);
        requests[1] = Permissions(toKeycode("VOTES"), VOTES.mintTo.selector);
        requests[2] = Permissions(toKeycode("VOTES"), VOTES.burnFrom.selector);
        requests[3] = Permissions(toKeycode("VOTES"), VOTES.transferFrom.selector);
    }


    /////////////////////////////////////////////////////////////////////////////////
    //                             Policy Variables                                //
    /////////////////////////////////////////////////////////////////////////////////


    // currently active proposal
    ActivatedProposal public activeProposal;

    mapping(uint256 => ProposalMetadata) public getProposalMetadata;
    mapping(uint256 => uint256) public totalEndorsementsForProposal;
    mapping(uint256 => mapping(address => uint256)) public userEndorsementsForProposal;
    mapping(uint256 => bool) public proposalHasBeenActivated;
    mapping(uint256 => uint256) public yesVotesForProposal;
    mapping(uint256 => uint256) public noVotesForProposal;
    mapping(uint256 => mapping(address => uint256)) public userVotesForProposal;
    mapping(uint256 => mapping(address => bool)) public tokenClaimsForProposal;

    uint256 public constant ACTIVATION_DEADLINE = 2 weeks; // amount of time a submitted proposal has to activate before it expires
    uint256 public constant GRACE_PERIOD = 1 weeks; // amount of time an activated proposal can stay up before it can be replaced
    uint256 public constant ENDORSEMENT_THRESHOLD = 20; // required percentage of total supply to activate a proposal (in percentage)
    uint256 public constant EXECUTION_THRESHOLD = 33; // required net votes to execute a proposal (in percentage)
    uint256 public constant VOTER_REWARD_RATE = 40;  // voter reward rate (in basis points)


    /////////////////////////////////////////////////////////////////////////////////
    //                              View Functions                                 //
    /////////////////////////////////////////////////////////////////////////////////


    function getMetadata(uint256 proposalId_) public view returns (ProposalMetadata memory) {
        return getProposalMetadata[proposalId_];
    }


    function getActiveProposal() public view returns (ActivatedProposal memory) {
        return activeProposal;
    }


    /////////////////////////////////////////////////////////////////////////////////
    //                               User Actions                                  //
    /////////////////////////////////////////////////////////////////////////////////


    function submitProposal(Instruction[] calldata instructions_, bytes32 title_, string memory proposalURI_) external {
        // require the proposing wallet to own at least 1% of the outstanding governance power
        if (VOTES.balanceOf(msg.sender) * 100 < VOTES.totalSupply()) {
            revert NotEnoughVotesToPropose();
        }

        // store the proposed instructions in the INSTR module and save the proposal metadata to the proposal mapping
        uint256 proposalId = INSTR.store(instructions_);
        getProposalMetadata[proposalId] = ProposalMetadata(
            title_,
            msg.sender,
            block.timestamp,
            proposalURI_
        );

        // emit the corresponding event
        emit ProposalSubmitted(proposalId);
    }

    function endorseProposal(uint256 proposalId_) external {
        // get the current votes of the user
        uint256 userVotes = VOTES.balanceOf(msg.sender);

        // revert if endorsing null proposalId
        if (proposalId_ == 0) {
            revert CannotEndorseNullProposal();
        }

        // revert if endorsed instructions are empty
        Instruction[] memory instructions = INSTR.getInstructions(proposalId_);
        if (instructions.length == 0) {
            revert CannotEndorseInvalidProposal();
        }

        // undo any previous endorsement the user made on these instructions
        uint256 previousEndorsement = userEndorsementsForProposal[proposalId_][msg.sender];
        totalEndorsementsForProposal[proposalId_] -= previousEndorsement;

        // reapply user endorsements with most up-to-date votes
        userEndorsementsForProposal[proposalId_][msg.sender] = userVotes;
        totalEndorsementsForProposal[proposalId_] += userVotes;

        // emit the corresponding event
        emit ProposalEndorsed(proposalId_, msg.sender, userVotes);
    }

    function activateProposal(uint256 proposalId_) external {
        // get the proposal to be activated
        ProposalMetadata memory proposal = getProposalMetadata[proposalId_];

        // only allow the proposer to activate their proposal
        if (msg.sender != proposal.submitter) {
            revert NotAuthorizedToActivateProposal();
        }

        // proposals must be activated within 2 weeks of submission or they expire
        if (block.timestamp > proposal.submissionTimestamp + ACTIVATION_DEADLINE) {
            revert SubmittedProposalHasExpired();
        }

        // require endorsements from at least 20% of the total outstanding governance power
        if ((totalEndorsementsForProposal[proposalId_] * 100) < VOTES.totalSupply() * ENDORSEMENT_THRESHOLD) {
            revert NotEnoughEndorsementsToActivateProposal();
        }

        // ensure the proposal is being activated for the first time
        if (proposalHasBeenActivated[proposalId_] == true) {
            revert ProposalAlreadyActivated();
        }

        // ensure the currently active proposal has had at least a week of voting for execution
        if (block.timestamp < activeProposal.activationTimestamp + 1 weeks) {
            revert ActiveProposalNotExpired();
        }

        // activate the proposal
        activeProposal = ActivatedProposal(proposalId_, block.timestamp);

        // record that the proposal has been activated
        proposalHasBeenActivated[proposalId_] = true;

        // emit the corresponding event
        emit ProposalActivated(proposalId_, block.timestamp);
    }

    function vote(bool for_) external {
        // get the amount of user votes
        uint256 userVotes = VOTES.balanceOf(msg.sender);

        // ensure an active proposal exists
        if (activeProposal.proposalId == 0) {
            revert NoActiveProposalDetected();
        }

        // ensure the user has no pre-existing votes on the proposal
        if (userVotesForProposal[activeProposal.proposalId][msg.sender] > 0) {
            revert UserAlreadyVoted();
        }

        // record the votes
        if (for_) {
            yesVotesForProposal[activeProposal.proposalId] += userVotes;
        } else {
            noVotesForProposal[activeProposal.proposalId] += userVotes;
        }

        // record that the user has casted votes
        userVotesForProposal[activeProposal.proposalId][msg.sender] = userVotes;

        // transfer voting tokens to contract
        VOTES.transferFrom(msg.sender, address(this), userVotes);

        // emit the corresponding event
        emit WalletVoted(activeProposal.proposalId, msg.sender, for_, userVotes);
    }

    function executeProposal() external {
        // require the net votes (yes - no) to be greater than 33% of the total voting supply
        uint256 netVotes = yesVotesForProposal[activeProposal.proposalId] - noVotesForProposal[activeProposal.proposalId];
        if (netVotes * 100 < VOTES.totalSupply() * EXECUTION_THRESHOLD) {
            revert NotEnoughVotesToExecute();
        }

        // ensure three days have passed before the proposal can be executed
        if (block.timestamp < activeProposal.activationTimestamp + 3 days) {
            revert ExecutionTimelockStillActive();
        }

        // execute the active proposal
        Instruction[] memory instructions = INSTR.getInstructions(activeProposal.proposalId);

        for (uint256 step; step < instructions.length; ) {
            kernel.executeAction(instructions[step].action, instructions[step].target);
            unchecked { ++step; }
        }

        // reward the proposer with 2% of the token supply
        address proposer = getProposalMetadata[activeProposal.proposalId].submitter;
        VOTES.mintTo(proposer, VOTES.totalSupply() * 2 / 100);

        // emit the corresponding event
        emit ProposalExecuted(activeProposal.proposalId);

        // deactivate the active proposal
        activeProposal = ActivatedProposal(0, 0);
    }

    function reclaimVotes(uint256 proposalId_) external {
        // get the amount of tokens the user voted with
        uint256 userVotes = userVotesForProposal[proposalId_][msg.sender];

        // ensure the user is not claiming empty votes
        if (userVotes == 0) {
            revert CannotReclaimZeroVotes();
        }

        // ensure the user is not claiming for the active propsal
        if (proposalId_ == activeProposal.proposalId) {
            revert CannotReclaimTokensForActiveVote();
        }

        // ensure the user has not already claimed before for this proposal
        if (tokenClaimsForProposal[proposalId_][msg.sender] == true) {
            revert VotingTokensAlreadyReclaimed();
        }

        // record the voting tokens being claimed from the contract
        tokenClaimsForProposal[proposalId_][msg.sender] = true;

        // return the tokens back to the user
        VOTES.transferFrom(address(this), msg.sender, userVotes);

        // mint a bonus reward (+.4%) to the user for participation
        VOTES.mintTo(msg.sender, userVotes * VOTER_REWARD_RATE / 10000);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "src/utils/KernelUtils.sol";

// ######################## ~ ERRORS ~ ########################

// KERNEL ADAPTER

error KernelAdapter_OnlyKernel(address caller_);

// MODULE

error Module_PolicyNotAuthorized(address policy_);

// POLICY

error Policy_OnlyRole(Role role_);
error Policy_ModuleDoesNotExist(Keycode keycode_);

// KERNEL

error Kernel_OnlyExecutor(address caller_);
error Kernel_OnlyAdmin(address caller_);
error Kernel_ModuleAlreadyInstalled(Keycode module_);
error Kernel_InvalidModuleUpgrade(Keycode module_);
error Kernel_PolicyAlreadyApproved(address policy_);
error Kernel_PolicyNotApproved(address policy_);
error Kernel_AddressAlreadyHasRole(address addr_, Role role_);
error Kernel_AddressDoesNotHaveRole(address addr_, Role role_);
error Kernel_RoleDoesNotExist(Role role_);

// ######################## ~ GLOBAL TYPES ~ ########################

enum Actions {
    InstallModule,
    UpgradeModule,
    ActivatePolicy,
    DeactivatePolicy,
    MigrateKernel,
    ChangeExecutor,
    ChangeAdmin
}

struct Instruction {
    Actions action;
    address target;
}

struct Permissions {
    Keycode keycode;
    bytes4 funcSelector;
}

type Keycode is bytes5;
type Role is bytes32;

// ######################## ~ MODULE ABSTRACT ~ ########################

abstract contract KernelAdapter {
    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    modifier onlyKernel() {
        if (msg.sender != address(kernel)) revert KernelAdapter_OnlyKernel(msg.sender);
        _;
    }

    function changeKernel(Kernel newKernel_) external onlyKernel {
        kernel = newKernel_;
    }
}

abstract contract Module is KernelAdapter {
    event PermissionSet(bytes4 funcSelector_, address policy_, bool permission_);

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    modifier permissioned() {
        if (!kernel.modulePermissions(KEYCODE(), Policy(msg.sender), msg.sig))
            revert Module_PolicyNotAuthorized(msg.sender);
        _;
    }

    function KEYCODE() public pure virtual returns (Keycode);

    /// @notice Specify which version of a module is being implemented.
    /// @dev Minor version change retains interface. Major version upgrade indicates
    /// @dev breaking change to the interface.
    function VERSION() external pure virtual returns (uint8 major, uint8 minor) {}

    /// @notice Initialization function for the module.
    /// @dev This function is called when the module is installed or upgraded by the kernel.
    /// @dev Used to encompass any upgrade logic. Must be gated by onlyKernel.
    function INIT() external virtual onlyKernel {}
}

abstract contract Policy is KernelAdapter  {

    bool public isActive;

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    modifier onlyRole(bytes32 role_) {
        Role role = toRole(role_);
        if(!kernel.hasRole(msg.sender, role))
            revert Policy_OnlyRole(role);
        _;
    }

    function configureDependencies() external virtual onlyKernel returns (Keycode[] memory dependencies) {}

    function requestPermissions() external view virtual onlyKernel returns (Permissions[] memory requests) {}

    function getModuleAddress(Keycode keycode_) internal view returns (address) {
        address moduleForKeycode = address(kernel.getModuleForKeycode(keycode_));
        if (moduleForKeycode == address(0)) revert Policy_ModuleDoesNotExist(keycode_);
        return moduleForKeycode;
    }

    /// @notice Function to let kernel grant or revoke active status
    function setActiveStatus(bool activate_) external onlyKernel {
        isActive = activate_;
    }
}

contract Kernel {
    // ######################## ~ VARS ~ ########################
    address public executor;
    address public admin;

    // ######################## ~ DEPENDENCY MANAGEMENT ~ ########################

    // Module Management
    Keycode[] public allKeycodes;
    mapping(Keycode => Module) public getModuleForKeycode; // get contract for module keycode
    mapping(Module => Keycode) public getKeycodeForModule; // get module keycode for contract
    
    // Module dependents data. Manages module dependencies for policies
    mapping(Keycode => Policy[]) public moduleDependents;
    mapping(Keycode => mapping(Policy => uint256)) public getDependentIndex;

    // Module <> Policy Permissions. Policy -> Keycode -> Function Selector -> Permission
    mapping(Keycode => mapping(Policy => mapping(bytes4 => bool))) public modulePermissions; // for policy addr, check if they have permission to call the function int he module

    // List of all active policies
    Policy[] public activePolicies;
    mapping(Policy => uint256) public getPolicyIndex;

    // Policy roles data
    mapping(address => mapping(Role => bool)) public hasRole;
    mapping(Role => bool) public isRole;

    // ######################## ~ EVENTS ~ ########################

    event PermissionsUpdated(
        Keycode indexed keycode_,
        Policy indexed policy_,
        bytes4 funcSelector_,
        bool granted_
    );
    event RoleGranted(Role indexed role_, address indexed addr_);
    event RoleRevoked(Role indexed role_, address indexed addr_);
    event ActionExecuted(Actions indexed action_, address indexed target_);

    // ######################## ~ BODY ~ ########################

    constructor() {
        executor = msg.sender;
        admin = msg.sender;
    }

    // ######################## ~ MODIFIERS ~ ########################

    // Role reserved for governor or any executing address
    modifier onlyExecutor() {
        if (msg.sender != executor) revert Kernel_OnlyExecutor(msg.sender);
        _;
    }

    // Role for managing policy roles
    modifier onlyAdmin() {
        if (msg.sender != admin) revert Kernel_OnlyAdmin(msg.sender);
        _;
    }

    // ######################## ~ KERNEL INTERFACE ~ ########################

    function executeAction(Actions action_, address target_) external onlyExecutor {
        if (action_ == Actions.InstallModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _installModule(Module(target_));
        } else if (action_ == Actions.UpgradeModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _upgradeModule(Module(target_));
        } else if (action_ == Actions.ActivatePolicy) {
            ensureContract(target_);
            _ActivatePolicy(Policy(target_));
        } else if (action_ == Actions.DeactivatePolicy) {
            ensureContract(target_);
            _DeactivatePolicy(Policy(target_));
        } else if (action_ == Actions.MigrateKernel) {
            ensureContract(target_);
            _migrateKernel(Kernel(target_));
        } else if (action_ == Actions.ChangeExecutor) {
            executor = target_;
        } else if (action_ == Actions.ChangeAdmin) {
            admin = target_;
        }

        emit ActionExecuted(action_, target_);
    }

    // ######################## ~ KERNEL INTERNAL ~ ########################

    function _installModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();

        if (address(getModuleForKeycode[keycode]) != address(0))
            revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
        allKeycodes.push(keycode);

        newModule_.INIT();
    }

    function _upgradeModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();
        Module oldModule = getModuleForKeycode[keycode];

        if (address(oldModule) == address(0) || oldModule == newModule_)
            revert Kernel_InvalidModuleUpgrade(keycode);

        getKeycodeForModule[oldModule] = Keycode.wrap(bytes5(0));
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        newModule_.INIT();

        _reconfigurePolicies(keycode);
    }

    function _ActivatePolicy(Policy policy_) internal {
        if (policy_.isActive()) revert Kernel_PolicyAlreadyApproved(address(policy_));

        // Grant permissions for policy to access restricted module functions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, true);

        // Add policy to list of active policies
        activePolicies.push(policy_);
        getPolicyIndex[policy_] = activePolicies.length - 1;

        // Record module dependencies
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depLength = dependencies.length;

        for (uint256 i; i < depLength; ) {
            Keycode keycode = dependencies[i];

            moduleDependents[keycode].push(policy_);
            getDependentIndex[keycode][policy_] = moduleDependents[keycode].length - 1;

            unchecked {
                ++i;
            }
        }

        // Set policy status to active
        policy_.setActiveStatus(true);
    }

    function _DeactivatePolicy(Policy policy_) internal {
        if (!policy_.isActive()) revert Kernel_PolicyNotApproved(address(policy_));

        // Revoke permissions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, false);

        // Remove policy from all policy data structures
        uint256 idx = getPolicyIndex[policy_];
        Policy lastPolicy = activePolicies[activePolicies.length - 1];

        activePolicies[idx] = lastPolicy;
        activePolicies.pop();
        getPolicyIndex[lastPolicy] = idx;
        delete getPolicyIndex[policy_];

        // Remove policy from module dependents
        _pruneFromDependents(policy_);

        // Set policy status to inactive
        policy_.setActiveStatus(false);
    }

    // WARNING: ACTION WILL BRICK THIS KERNEL. All functionality will move to the new kernel
    // New kernel must add in all of the modules and policies via executeAction
    // NOTE: Data does not get cleared from this kernel
    function _migrateKernel(Kernel newKernel_) internal {
        uint256 keycodeLen = allKeycodes.length;
        for (uint256 i; i < keycodeLen; ) {
            Module module = Module(getModuleForKeycode[allKeycodes[i]]);
            module.changeKernel(newKernel_);
            unchecked {
                ++i;
            }
        }

        uint256 policiesLen = activePolicies.length;
        for (uint256 j; j < policiesLen; ) {
            Policy policy = activePolicies[j];

            // Deactivate before changing kernel
            policy.setActiveStatus(false);
            policy.changeKernel(newKernel_);
            unchecked {
                ++j;
            }
        }
    }

    function _reconfigurePolicies(Keycode keycode_) internal {
        Policy[] memory dependents = moduleDependents[keycode_];
        uint256 depLength = dependents.length;

        for (uint256 i; i < depLength; ) {
            dependents[i].configureDependencies();

            unchecked {
                ++i;
            }
        }
    }

    function _setPolicyPermissions(
        Policy policy_,
        Permissions[] memory requests_,
        bool grant_
    ) internal {
        uint256 reqLength = requests_.length;
        for (uint256 i = 0; i < reqLength; ) {
            Permissions memory request = requests_[i];
            modulePermissions[request.keycode][policy_][request.funcSelector] = grant_;

            emit PermissionsUpdated(request.keycode, policy_, request.funcSelector, grant_);

            unchecked {
                ++i;
            }
        }
    }

    function _pruneFromDependents(Policy policy_) internal {
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depcLength = dependencies.length;

        for (uint256 i; i < depcLength; ) {
            Keycode keycode = dependencies[i];
            Policy[] storage dependents = moduleDependents[keycode];

            uint256 origIndex = getDependentIndex[keycode][policy_];
            Policy lastPolicy = dependents[dependents.length - 1];

            // Swap with last and pop
            dependents[origIndex] = lastPolicy;
            dependents.pop();

            // Record new index and delete terminated policy index
            getDependentIndex[keycode][lastPolicy] = origIndex;
            delete getDependentIndex[keycode][policy_];

            unchecked {
                ++i;
            }
        }
    }

    function grantRole(Role role_, address addr_) public onlyAdmin {
        if (hasRole[addr_][role_]) revert Kernel_AddressAlreadyHasRole(addr_, role_);

        ensureValidRole(role_);
        if (!isRole[role_]) isRole[role_] = true;

        hasRole[addr_][role_] = true;

        emit RoleGranted(role_, addr_);
    }

    function revokeRole(Role role_, address addr_) public onlyAdmin {
        if (!isRole[role_]) revert Kernel_RoleDoesNotExist(role_);
        if (!hasRole[addr_][role_]) revert Kernel_AddressDoesNotHaveRole(addr_, role_);

        hasRole[addr_][role_] = false;

        emit RoleRevoked(role_, addr_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

// [INSTR] The Instructions Module caches and executes batched instructions for protocol upgrades in the Kernel

pragma solidity ^0.8.15;

import "src/Kernel.sol";

interface IDefaultInstructions {

    event InstructionsStored(uint256 instructionsId);

    error INSTR_InstructionsCannotBeEmpty();
    error INSTR_InvalidChangeExecutorAction();
    error INSTR_InvalidTargetNotAContract();
    error INSTR_InvalidModuleKeycode();
}


contract DefaultInstructions is Module, IDefaultInstructions {

    /////////////////////////////////////////////////////////////////////////////////
    //                         Kernel Module Configuration                         //
    /////////////////////////////////////////////////////////////////////////////////

    constructor(Kernel kernel_) Module(kernel_) {}

    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("INSTR");
    }

    /////////////////////////////////////////////////////////////////////////////////
    //                              Module Variables                               //
    /////////////////////////////////////////////////////////////////////////////////

    uint256 public totalInstructions;
    mapping(uint256 => Instruction[]) public storedInstructions;

    /////////////////////////////////////////////////////////////////////////////////
    //                             Policy Interface                                //
    /////////////////////////////////////////////////////////////////////////////////

    // view function for retrieving a list of instructions in an outside contract
    function getInstructions(uint256 instructionsId_) public view returns (Instruction[] memory) {
        return storedInstructions[instructionsId_];
    }

    function store(Instruction[] calldata instructions_) external permissioned returns (uint256) {
        uint256 length = instructions_.length;
        uint256 instructionsId = ++totalInstructions;

        // initialize an empty list of instructions that will be filled
        Instruction[] storage instructions = storedInstructions[instructionsId];

        // if there are no instructions, throw an error
        if (length == 0) {
            revert INSTR_InstructionsCannotBeEmpty();
        }

        // for each instruction, do the following actions:
        for (uint256 i; i < length; ) {
            // get the instruction
            Instruction calldata instruction = instructions_[i];

            // check the address that the instruction is being performed on is a contract (bytecode size > 0)
            _ensureContract(instruction.target);

            // if the instruction deals with a module, make sure the module has a valid keycode (UPPERCASE A-Z ONLY)
            if (
                instruction.action == Actions.InstallModule ||
                instruction.action == Actions.UpgradeModule
            ) {
                Module module = Module(instruction.target);
                _ensureValidKeycode(module.KEYCODE());
            } else if (instruction.action == Actions.ChangeExecutor && i != length - 1) {
                // throw an error if ChangeExecutor exists and is not the last Action in the instruction llist
                // this exists because if ChangeExecutor is not the last item in the list of instructions
                // the Kernel will not recognize any of the following instructions as valid, since the policy
                // executing the list of instructions no longer has permissions in the Kernel. To avoid this issue
                // and prevent invalid proposals from being saved, we perform this check.

                revert INSTR_InvalidChangeExecutorAction();
            }

            instructions.push(instructions_[i]);
            unchecked {
                ++i;
            }
        }

        emit InstructionsStored(instructionsId);

        return instructionsId;
    }

    /////////////////////////////// INTERNAL FUNCTIONS ////////////////////////////////

    function _ensureContract(address target_) internal view {
        uint256 size;
        assembly {
            size := extcodesize(target_)
        }
        if (size == 0) revert INSTR_InvalidTargetNotAContract();
    }

    function _ensureValidKeycode(Keycode keycode_) internal pure {
        bytes5 unwrapped = Keycode.unwrap(keycode_);

        for (uint256 i = 0; i < 5; ) {
            bytes1 char = unwrapped[i];

            if (char < 0x41 || char > 0x5A) revert INSTR_InvalidModuleKeycode(); // A-Z only"

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

// [VOTES] The Votes Module is the ERC20 token that represents voting power in the network.

pragma solidity ^0.8.15;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import "src/Kernel.sol";

error VOTES_TransferDisabled();

contract DefaultVotes is Module, ERC20 {
    constructor(Kernel kernel_) Module(kernel_) ERC20("Voting Tokens", "VOTES", 3) {}

    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("VOTES");
    }

    // Policy Interface

    function mintTo(address wallet_, uint256 amount_) external permissioned {
        _mint(wallet_, amount_);
    }

    function burnFrom(address wallet_, uint256 amount_) external permissioned {
        _burn(wallet_, amount_);
    }

    function transfer(address, uint256) public override returns (bool) {
        revert VOTES_TransferDisabled();
        return true;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public override permissioned returns (bool) {
        // skip the approve function because callers must be pre-approved via governance

        balanceOf[from_] -= amount_;
        unchecked {
            balanceOf[to_] += amount_;
        }

        emit Transfer(from_, to_, amount_);
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {Keycode, Role} from "../Kernel.sol";

error TargetNotAContract(address target_);
error InvalidKeycode(Keycode keycode_);
error InvalidRole(Role role_);

function toKeycode(bytes5 keycode_) pure returns (Keycode) {
    return Keycode.wrap(keycode_);
}

function fromKeycode(Keycode keycode_) pure returns (bytes5) {
    return Keycode.unwrap(keycode_);
}

function toRole(bytes32 role_) pure returns (Role) {
    return Role.wrap(role_);
}

function fromRole(Role role_) pure returns (bytes32) {
    return Role.unwrap(role_);
}

function ensureContract(address target_) view {
    uint256 size;
    assembly("memory-safe") {
        size := extcodesize(target_)
    }
    if (size == 0) revert TargetNotAContract(target_);
}

function ensureValidKeycode(Keycode keycode_) pure {
    bytes5 unwrapped = Keycode.unwrap(keycode_);

    for (uint256 i = 0; i < 5; ) {
        bytes1 char = unwrapped[i];

        if (char < 0x41 || char > 0x5A) revert InvalidKeycode(keycode_); // A-Z only

        unchecked {
            i++;
        }
    }
}

function ensureValidRole(Role role_) pure {
    bytes32 unwrapped = Role.unwrap(role_);

    for (uint256 i = 0; i < 32; ) {
        bytes1 char = unwrapped[i];
        if ((char < 0x61 || char > 0x7A) && char != 0x00) {
            revert InvalidRole(role_); // a-z only
        }
        unchecked {
            i++;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}
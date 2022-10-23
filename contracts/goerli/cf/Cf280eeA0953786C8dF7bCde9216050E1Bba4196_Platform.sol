// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


import "../@openzeppelin/contracts/security/Pausable.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ProjectFactory.sol";
import "../milestone/Milestone.sol";
import "../vault/IVault.sol";
import "../project/IProject.sol";
import "./IPlatform.sol";


contract Platform is ProjectFactory, IPlatform, /*Ownable, Pausable,*/ ReentrancyGuard {
    
    using ERC165Checker for address;


    //TODO platform state vars, allow team / vault vetting

    uint constant public MAX_PLATFORM_CUT_PROMILS = 20; //TODO verify max cut value

    IERC20 public platformToken;

    uint public platformCutPromils = 6;

    mapping(address => uint) public numPaymentTokensByTokenAddress;



    //--------

    event PlatformFundTransferToOwner(address owner, uint toExtract);

    event TeamAddressApprovedStatusSet(address indexed teamWallet_, bool indexed approved_);

    event VaultAddressApprovedStatusSet(address indexed vaultAddress_, bool indexed approved_);

    event PlatformTokenChanged(address platformToken, address oldToken);

    event PlatformCutReceived(address indexed senderProject, uint value);

    event PlatformCutChanged(uint oldValPromils, uint platformCutPromils);

    error BadTeamDefinedVault(address projectVault_);

    error InsufficientFundsInContract( uint sumToExtract_, uint contractBalance );

    error InvalidProjectAddress(address projectAddress);
    //---------


    modifier openForAll() {
        _;
    }

    modifier onlyValidProject() {
        require( _validProjectAddress( msg.sender), "not a valid project");
        _;
    }

    constructor( address projectTemplate_, address vaultTemplate_, address platformToken_)
                            ProjectFactory( projectTemplate_, vaultTemplate_) {
         platformToken = IERC20(platformToken_);
     }

/*
 * @title setPlatformToken
 *
 * @dev Allows platform owner to set the platform erc20 token
 *
 * NOTE: As part of the processing _new erc20 project tokens will be minted and transferred to the owner and
 * @event: PlatformTokenChanged
 */
    function setPlatformToken(IERC20 newPlatformToken) external onlyOwner whenPaused { //@PUBFUNC
        // contract should be paused first
        IERC20 oldToken_ = platformToken;
        platformToken = newPlatformToken;
        emit PlatformTokenChanged(address(platformToken), address(oldToken_));
    }

/*
 * @title markVaultAsApproved
 *
 * @dev Set vault approval by platform to be used by future (only!) projects
 *
 * @event: VaultAddressApprovedStatusSet
 */
    function markVaultAsApproved(address vaultAddress_, bool isApproved_) external onlyOwner { //@PUBFUNC
        approvedVaults[vaultAddress_] = isApproved_;
        emit VaultAddressApprovedStatusSet(vaultAddress_, isApproved_);
    }

/*
 * @title transferFundsToPlatformOwner
 *
 * @dev Transfer payment-token funds from platform contract to platform owner
 *
 * @event: PlatformFundTransferToOwner
 */
    function transferFundsToPlatformOwner(uint sumToExtract_, address tokenAddress_) external onlyOwner { //@PUBFUNC
        // @PROTECT: DoS, Re-entry

        _transferPaymntTokensFromPlatformTo( owner(), sumToExtract_, tokenAddress_);
        
        emit PlatformFundTransferToOwner(owner(), sumToExtract_); 
    }

    function _transferPaymntTokensFromPlatformTo( address receiverAddr_, uint numPaymentTokens_, address tokenAddress_) private {
        require( numPaymentTokensByTokenAddress[ tokenAddress_] >= numPaymentTokens_, "not enough tokens in platform");

        numPaymentTokensByTokenAddress[ tokenAddress_] -= numPaymentTokens_;

        bool ok = IERC20( tokenAddress_).transfer( receiverAddr_, numPaymentTokens_);
        require( ok, "Failed to transfer payment tokens");
    }


    /*
     * @title setPlatformCut
     *
     * @dev Set platform cut (promils) after verifying it is <= MAX_PLATFORM_CUT_PROMILS
     *
     * @event: PlatformCutChanged
     */
    function setPlatformCut(uint newPlatformCutPromils) external onlyOwner { //@PUBFUNC
        require( newPlatformCutPromils <= MAX_PLATFORM_CUT_PROMILS, "bad platform cut");
        uint oldVal_ = platformCutPromils;
        platformCutPromils = newPlatformCutPromils;
        emit PlatformCutChanged( oldVal_, platformCutPromils);
    }

    /*
     * @title receive()
     *
     * @dev Allow a valid project (only) to pass payment-token to platform contract
     *
     * @event: PlatformCutReceived
     */
    function onReceivePaymentTokens( address tokenAddress_, uint numTokens_) external override onlyValidProject { //@PUBFUNC //@PTokTransfer
        numPaymentTokensByTokenAddress[ tokenAddress_] += numTokens_;
        emit PlatformCutReceived( msg.sender, numTokens_);
    }

    function getBlockTimestamp() external view returns(uint) {
        return block.timestamp;
    }

    function _getPlatformCutPromils() internal override view returns(uint) {
        return platformCutPromils;
    } 

    function _isAnApprovedVault(address projectVault_) internal override view returns(bool) {
        return approvedVaults[address(projectVault_)];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/access/Ownable.sol";
import "../project/PledgeEvent.sol";

interface IVault {

    function transferPaymentTokenToTeamWallet(uint sum_, uint platformCut, address platformAddr_) external;
    function transferPaymentTokensToPledger( address pledgerAddr_, uint sum_) external returns(uint);

    function increaseBalance( uint numPaymentTokens_) external;

    function vaultBalance() external view returns(uint);

    function totalAllPledgerDeposits() external view returns(uint);

    function decreaseTotalDepositsOnPledgerGraceExit(PledgeEvent[] calldata pledgerEvents) external;

    function changeOwnership( address project_) external;
    function getOwner() external view returns (address);

    function initialize( address owner_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";

import "../project/IProject.sol";

interface IMintableOwnedERC20 is IERC20 {

    function mint(address to, uint256 amount) external ;

    function getOwner() external view returns (address);

    function changeOwnership( address dest) external;

    function setConnectedProject( IProject project_) external;

    function performInitialMint( uint numTokens) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../@openzeppelin/contracts/security/Pausable.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./IMintableOwnedERC20.sol";
import "../project/IProject.sol";


contract CommonGoodProjectToken is IMintableOwnedERC20, ERC20Burnable, ERC165Storage, Pausable, Ownable {

    IProject public project;


    modifier onlyOwnerOrProjectTeam() {
        require( msg.sender == owner() || msg.sender == project.getTeamWallet(), "token owner or team");
        _;
    }
    //---

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _registerInterface(type( IMintableOwnedERC20).interfaceId);
    }

    function performInitialMint( uint initialTokenSupply) external override onlyOwner { //@PUBFUNC @gilad
        mint( owner()/*tokenOwner*/, initialTokenSupply);
    }

    function setConnectedProject( IProject project_) external onlyOwner {  //@PUBFUNC
        project =  project_;
    }

    function pause() public onlyOwnerOrProjectTeam { //@PUBFUNC
        _pause();
    }

    function unpause() public onlyOwnerOrProjectTeam { //@PUBFUNC
        _unpause();
    }

    function getOwner() external override view returns (address) {
        return owner();
    }

    function changeOwnership( address dest) external override { //@PUBFUNC
        return transferOwnership(dest);
    }

    function mint(address to, uint256 amount) public override onlyOwner { //@PUBFUNC
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16; 

enum ProjectState {
    IN_PROGRESS,
    SUCCEEDED,
    FAILED
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../vault/IVault.sol";
import "../token/IMintableOwnedERC20.sol";


struct ProjectParams {
    // used to circumvent 'Stack too deep' error when creating a _new project

    address projectVault;
    address projectToken;
    address paymentToken;

    string tokenName;
    string tokenSymbol;
    uint minPledgedSum;
    uint initialTokenSupply;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../vault/IVault.sol";
import "../milestone/Milestone.sol";
import "../token/IMintableOwnedERC20.sol";

struct ProjectInitParams {
    address projectTeamWallet;
    IVault vault;
    Milestone[] milestones;
    IMintableOwnedERC20 projectToken;
    uint platformCutPromils;
    uint minPledgedSum;
    uint onChangeExitGracePeriod;
    uint pledgerGraceExitWaitTime;
    address paymentToken;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

struct PledgeEvent { //@STORAGEOPT
    uint32 date;
    uint sum;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


import "../token/IMintableOwnedERC20.sol";
import "../vault/IVault.sol";
import "../milestone/Milestone.sol";
import "./ProjectState.sol";
import "./ProjectInitParams.sol";


interface IProject {

    function initialize( ProjectInitParams memory params_) external;

    function getOwner() external view returns(address);

    function getTeamWallet() external view returns(address);

    function getPaymentTokenAddress() external view returns(address);

    function mintProjectTokens( address receiptOwner_, uint numTokens_) external;

    function getProjectStartTime() external view returns(uint);

    function getProjectState() external view returns(ProjectState);

    function getVaultBalance() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


import "../@openzeppelin/contracts/security/Pausable.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/proxy/Clones.sol";

import "../project/ProjectParams.sol";
import "../project/ProjectInitParams.sol";
import "../milestone/Milestone.sol";
import "../milestone/MilestoneResult.sol";
import "../token/CommonGoodProjectToken.sol";
import "../token/IMintableOwnedERC20.sol";
import "../vault/IVault.sol";
import "../project/IProject.sol";
import "../libs/Sanitizer.sol";
import "./BetaTestable.sol";


abstract contract ProjectFactory is BetaTestable, /*Ownable*/ Pausable {

    using Clones for address;

    address immutable public projectTemplate;

    address immutable public vaultTemplate;


    uint public onChangeExitGracePeriod = 7 days; 
    
    uint public pledgerGraceExitWaitTime = 14 days;

    mapping(address => IProject) public addressToProject;

    mapping(address => bool) public isApprovedPaymentToken;


    address[] public projectAddresses; // all created projects - either in-progress or completed

    //--------

    mapping(address => bool) public approvedVaults;

    uint public minNumMilestones;
    uint public maxNumMilestones;



    //----

    modifier onlyIfCallingProjectSucceeded() {
        IProject callingProject_ = addressToProject[ msg.sender];
        require( callingProject_.getProjectState() == ProjectState.SUCCEEDED, "project not succeeded");
        _;
    }

    modifier legalNumberOfMilestones( Milestone[] memory milestones_) {
        require( milestones_.length >= minNumMilestones, "not enough milestones");
        require( milestones_.length <= maxNumMilestones, "too many milestones");
        _;
    }

    //----

    constructor(address projectTemplate_, address vaultTemplate_) {
        projectTemplate = projectTemplate_;
        vaultTemplate = vaultTemplate_;
        minNumMilestones = 1;
        maxNumMilestones = 400;

    }

    event ApprovedPaymentTokenChanged( address indexed paymentToken, bool isLegal);

    event ProjectWasDeployed(uint indexed projectIndex, address indexed projectAddress, address indexed projectVault,
                            uint numMilestones, address projectToken, string tokenName, string tokenSymbol, uint tokenSupply,
                            uint onChangeExitGracePeriod, uint pledgerGraceExitWaitTime);

    event OnChangeExitGracePeriodChanged( uint newGracePeriod, uint oldGracePeriod);

    event PledgerGraceExitWaitTimeChanged( uint newValue, uint oldValue);

    event MliestoneLimitsChanged( uint new_minNumMilestones, uint indexed old_minNumMilestones,
                                  uint new_maxNumMilestones, uint indexed old_maxNumMilestones );
    //---

    error ExternallyProvidedProjectVaultMustBeOwnedByPlatform( address vault_, address vaultOwner_);

    error ExternallyProvidedProjectTokenMustBeOwnedByPlatform( address projectToken, address actualOwner_);

    error ProjectTokenMustBeIMintableERC20( address projectToken_);

    error NotAnApprovedVault(address projectVault_, address teamAddr);              

    error MilestoneInitialResultMustBeUnresolved(uint milestoneIndex, MilestoneResult milestoneResult);

    error InvalidVault(address vault);
    //----

    function _approvedPaymentToken(address paymentTokenAddr_) private view returns(bool) {
        return paymentTokenAddr_ != address(0) && isApprovedPaymentToken[ paymentTokenAddr_];
    }




/*
 * @title createProject()
 *
 * @dev create a _new project, must be called by an approved team wallet address with a complete
 * list fo milestones and parameters
 * Internally: will create project vault and a dedicated project token, unless externally provided
 * and will instantiate and deploy a project contract
 *
 * @precondition: externally provided vault and project-token, if any, must be platform owned
 * @postcondition: vault and project-token will be owned by project when exiting this function
 *
 * @event: ProjectWasDeployed
 */
    //@DOC1
    function createProject( ProjectParams memory params_, Milestone[] memory milestones_) external
                                onlyValidBetaTester
                                legalNumberOfMilestones( milestones_)
                                whenNotPaused { //@PUBFUNC

        uint projectIndex_ = projectAddresses.length;

        address projectTeamWallet_ = msg.sender;

        require( _approvedPaymentToken( params_.paymentToken), "payment token not approved");

        Sanitizer._sanitizeMilestones(milestones_, block.timestamp, minNumMilestones, maxNumMilestones);


        //@gilad externl vault initially owned by platform address => after owned by project
        if (params_.projectVault == address(0)) {
            // deploy a dedicated DefaultVault contract
            params_.projectVault = vaultTemplate.clone();

        } else {
            _validateExternalVault( IVault(params_.projectVault));
        }

        if (params_.projectToken == address(0)) {
            // deploy a dedicated CommonGoodProjectToken contract
            CommonGoodProjectToken newDeployedToken_ = new CommonGoodProjectToken(params_.tokenName, params_.tokenSymbol);
            params_.projectToken = address( newDeployedToken_);

        } else {
            _validateExternalToken( IMintableOwnedERC20(params_.projectToken));
        }

        IMintableOwnedERC20 projToken_ = IMintableOwnedERC20(params_.projectToken);
        require( projToken_.getOwner() == address(this), "Project token must initially be owned by Platform");

        //-------------
        IProject project_ = IProject( projectTemplate.clone());


        IVault(params_.projectVault).initialize( address(project_));


        require( IVault(params_.projectVault).getOwner() == address(project_), "Vault must be owned by project");


        ProjectInitParams memory initParams_ = ProjectInitParams( {
            projectTeamWallet: projectTeamWallet_,
            vault: IVault(params_.projectVault),
            milestones: milestones_,
            projectToken: projToken_,
            platformCutPromils: _getPlatformCutPromils(),
            minPledgedSum: params_.minPledgedSum,
            onChangeExitGracePeriod: onChangeExitGracePeriod,
            pledgerGraceExitWaitTime: pledgerGraceExitWaitTime,
            paymentToken: params_.paymentToken
        });

        project_.initialize( initParams_);

        require( project_.getOwner() == projectTeamWallet_, "Project must be owned by team");
        //-------------


        addressToProject[ address(project_)] = project_;

        projectAddresses.push( address(project_));

        projToken_.setConnectedProject( project_);

        projToken_.performInitialMint( params_.initialTokenSupply);

        projToken_.changeOwnership( address(project_));

        require( projToken_.getOwner() == address(project_), "Project token must be owned by Platform");

        emit ProjectWasDeployed( projectIndex_, address(project_), params_.projectVault, milestones_.length,
                                 params_.projectToken, params_.tokenName, params_.tokenSymbol,
                                 params_.initialTokenSupply, onChangeExitGracePeriod, pledgerGraceExitWaitTime);
    }


    function _validateExternalToken( IMintableOwnedERC20 projectToken_) private view {
        if ( !ERC165Checker.supportsInterface( address(projectToken_), type(IMintableOwnedERC20).interfaceId)) {
            revert ProjectTokenMustBeIMintableERC20( address(projectToken_));
        }

        address tokenOwner_ = projectToken_.getOwner();
        if ( tokenOwner_ != address(this)) {
            revert ExternallyProvidedProjectTokenMustBeOwnedByPlatform( address( projectToken_), tokenOwner_);
        }
    }


    function _validateExternalVault( IVault vault_) private view {
        if ( !_isAnApprovedVault(address(vault_))) {
            revert NotAnApprovedVault( address(vault_), msg.sender);
        }

        if ( !_supportIVaultInterface(address(vault_))) {
            revert InvalidVault( address(vault_));
        }

        address vaultOwner_ = IVault(vault_).getOwner();
        if ( vaultOwner_ != address(this)) {
            revert ExternallyProvidedProjectVaultMustBeOwnedByPlatform( address(vault_), vaultOwner_);
        }
    }

    function _supportIVaultInterface(address projectVault_) private view returns(bool) {
        return ERC165Checker.supportsInterface( projectVault_, type(IVault).interfaceId);
    }

    function _validProjectAddress( address projectAddr_) internal view returns(bool) {
        return addressToProject[ projectAddr_].getProjectStartTime() > 0;
    }

    function setMilestoneMinMaxCounts( uint new_minNumMilestones, uint new_maxNumMilestones) external onlyOwner { //@PUBFUNC
        uint old_minNumMilestones = minNumMilestones;
        uint old_maxNumMilestones = maxNumMilestones;

        minNumMilestones = new_minNumMilestones;
        maxNumMilestones = new_maxNumMilestones;

        emit MliestoneLimitsChanged( minNumMilestones, old_minNumMilestones, maxNumMilestones, old_maxNumMilestones);
    }


    function approvePaymentToken(address paymentTokenAddr_, bool isApproved_) external onlyOwner { //@PUBFUNC
        require( paymentTokenAddr_ != address(0), "bad payment token address");
        isApprovedPaymentToken[ paymentTokenAddr_] = isApproved_;
        emit ApprovedPaymentTokenChanged( paymentTokenAddr_, isApproved_);
    }


/*
 * @title setProjectChangeGracePeriod()
 *
 * @dev Sets the project grace period where pledgers are allowed to exit after project details change
 * Note that this change will only affect _new projects
 *
 * @event: OnChangeExitGracePeriodChanged
 */
    function setProjectChangeGracePeriod(uint newGracePeriod) external onlyOwner { //@PUBFUNC
        // set grace period allowing pledgers to gracefully exit after project change
        uint oldGracePeriod_ = onChangeExitGracePeriod;
        onChangeExitGracePeriod = newGracePeriod;
        emit OnChangeExitGracePeriodChanged( onChangeExitGracePeriod, oldGracePeriod_);
    }


/*
 * @title setPledgerWaitTimeBeforeGraceExit()
 *
 * @dev Sets the project pledger wait time between entering and being allowed to leave due to grace period
 * Note that this change will only affect _new projects
 *
 * @event: PledgerGraceExitWaitTimeChanged
 */
    function setPledgerWaitTimeBeforeGraceExit(uint newWaitTime) external onlyOwner { //@PUBFUNC
        // will pnly take effect on future projects
        uint oldWaitTime_ = pledgerGraceExitWaitTime;
        pledgerGraceExitWaitTime = newWaitTime;
        emit PledgerGraceExitWaitTimeChanged( pledgerGraceExitWaitTime, oldWaitTime_);
    }

     function numProjects() external view returns(uint) {
         return projectAddresses.length;
     }

    //------------


    function _getPlatformCutPromils() internal virtual view returns(uint);
    function _isAnApprovedVault(address vault) internal virtual view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IPlatform {
    function onReceivePaymentTokens( address paymentTokenAddress_, uint platformCut_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/access/Ownable.sol";


abstract contract BetaTestable is Ownable {

    bool public inBetaMode = true; //TODO

    mapping( address => bool) public isBetaTester;


    event BetaModeChanged( bool indexed inBetaMode, bool indexed oldBetaMode);

    event SetBetaTester( address indexed testerAddress, bool indexed isBetaTester);


    modifier onlyValidBetaTester() {
        require( _isValidBetaTester(), "not a valid beta tester");
        _;
    }

    function _isValidBetaTester() private view returns(bool) {
        if( !inBetaMode) {
            return true; // not in beta mode - allow all in
        }

        return isBetaTester[ msg.sender];
    }


    /*
     * @title setBetaMode()
     *
     * @dev Set beta mode flag. When in beta mode only beta users are allowed as project teams
     *
     * @event: BetaModeChanged
     */
    function setBetaMode(bool inBetaMode_) external onlyOwner { //@PUBFUNC
        bool oldMode = inBetaMode;
        inBetaMode = inBetaMode_;
        emit BetaModeChanged( inBetaMode, oldMode);
    }

    /*
     * @title setBetaTester()
     *
     * @dev Set a beta tester boolean flag. This call allows both approving and disapproving a beta tester address
     *
     * @event: SetBetaTester
     */
    function setBetaTester(address testerAddress, bool isBetaTester_) external onlyOwner { //@PUBFUNC
        //require( inBetaMode); -- not needed
        isBetaTester[ testerAddress] = isBetaTester_;
        emit SetBetaTester( testerAddress, isBetaTester_);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

enum MilestoneResult {
    UNRESOLVED,
    SUCCEEDED,
    FAILED
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

struct MilestoneApprover {
    //off-chain: oracle, judge..
    address externalApprover;

    //on-chain
    uint32 targetNumPledgers;
    uint fundingTarget;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./MilestoneApprover.sol";
import "./MilestoneResult.sol";
import "../vault/IVault.sol";

struct Milestone {

    MilestoneApprover milestoneApprover;
    MilestoneResult result;

    uint32 dueDate;
    int32 prereqInd;

    uint pTokValue;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../milestone/Milestone.sol";
import "../milestone/MilestoneApprover.sol";
import "../milestone/MilestoneResult.sol";


/*
    TODO: hhhh

tokens:   https://www.youtube.com/watch?v=gc7e90MHvl8

    find erc20 asset price via chainlink callback or API:
            https://blog.chain.link/fetch-current-crypto-price-data-solidity/
            https://www.quora.com/How-do-I-get-the-price-of-an-ERC20-token-from-a-solidity-smart-contract
            https://blog.logrocket.com/create-oracle-ethereum-smart-contract/
            https://noahliechti.hashnode.dev/an-effective-way-to-build-your-own-oracle-with-solidity

    use timelock?

    truffle network switcher

    deploy in testnet -- rinkbey

    a couple of basic tests
            deploy 2 ms + 3 bidders
            try get eth - fail
            try get tokens fail
            success
            try get eth - fail
            try get tokens fail
            success
            try get eth - success
            try get tokens success
---

    IProject IPlatform + supprit-itf
    clone contract for existing template address

    https://www.youtube.com/watch?v=LZ3XPhV7I1Q
            openz token types

    go over openzeppelin relevant utils

   refund nft receipt from any1 (not only orig ownner); avoid reuse (burn??)

   refund PTok for leaving pledgr -- grace/failure

   allow prj erc20 frorpldgr on prj success

   inject vault and rpjtoken rather than deploy

   write some tests

   create nft

   when transfer platform token??

   deal with nft cashing

   deal with completed_indexes list after change -- maybe just remove it?

   problem with updating project --how keep info on completedList and pundedStartingIndex

   who holds the erc20 project-token funds of this token? should pre-invoke to make sure has funds?
-------

Guice - box bonding curvse :  A bonding curve describes the relationship between the price and supply of an asset

    what is market-makers?

    startProj, endProj, pledGer.enterTime  // project.projectStartTime, project.projectEndTime
    compensate with erc20 only if proj success
    maybe receipt == erc721?;

    reserved sum === by frequency calculation;

*/

library Sanitizer {

    //@gilad: allow configuration?
    uint constant public MIN_MILESTONE_INTERVAL = 1 days;
    uint constant public MAX_MILESTONE_INTERVAL = 365 days;


    error IllegalMilestoneDueDate( uint index, uint32 dueDate, uint timestamp);

    error NoMilestoneApproverWasSet(uint index);

    error AmbiguousMilestoneApprover(uint index, address externalApprover, uint fundingTarget, uint numPledgers);


    function _sanitizeMilestones( Milestone[] memory milestones_, uint now_, uint minNumMilestones_, uint maxNumMilestones_) internal pure {
        // assuming low milestone count
        require( minNumMilestones_ == 0 || milestones_.length >= minNumMilestones_, "not enough milestones");
        require( maxNumMilestones_ == 0 || milestones_.length <= maxNumMilestones_, "too many milestones");

        for (uint i = 0; i < milestones_.length; i++) {
            _validateDueDate(i, milestones_[i].dueDate, now_);
            _validateApprover(i, milestones_[i].milestoneApprover);
            milestones_[i].result = MilestoneResult.UNRESOLVED;
        }
    }

    function _validateDueDate( uint index, uint32 dueDate, uint now_) private pure {
        if ( (dueDate < now_ + MIN_MILESTONE_INTERVAL) || (dueDate > now_ + MAX_MILESTONE_INTERVAL) ) {
            revert IllegalMilestoneDueDate(index, dueDate, now_);
        }
    }

    function _validateApprover(uint index, MilestoneApprover memory approver_) private pure {
        bool approverIsSet_ = (approver_.externalApprover != address(0) || approver_.fundingTarget > 0 || approver_.targetNumPledgers > 0);
        if ( !approverIsSet_) {
            revert NoMilestoneApproverWasSet(index);
        }
        bool extApproverUnique = (approver_.externalApprover == address(0) || (approver_.fundingTarget == 0 && approver_.targetNumPledgers == 0));
        bool fundingTargetUnique = (approver_.fundingTarget == 0  || (approver_.externalApprover == address(0) && approver_.targetNumPledgers == 0));
        bool numPledgersUnique = (approver_.targetNumPledgers == 0  || (approver_.externalApprover == address(0) && approver_.fundingTarget == 0));

        if ( !extApproverUnique || !fundingTargetUnique || !numPledgersUnique) {
            revert AmbiguousMilestoneApprover(index, approver_.externalApprover, approver_.fundingTarget, approver_.targetNumPledgers);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
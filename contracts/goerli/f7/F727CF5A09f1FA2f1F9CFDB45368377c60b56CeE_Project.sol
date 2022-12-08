// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../@openzeppelin/contracts/security/Pausable.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./PledgeEvent.sol";
import "./PledgerRecord.sol";
import "./MilestoneOwner.sol";
import "../token/IMintableOwnedERC20.sol";
import "../milestone/MilestoneResult.sol";
import "../milestone/Milestone.sol";
import "../milestone/MilestoneApprover.sol";
import "../vault/IVault.sol";
import "../utils/InitializedOnce.sol";
import "./ProjectState.sol";
import "./IProject.sol";
import "./ProjectInitParams.sol";
import "../libs/Sanitizer.sol";


contract Project is IProject, MilestoneOwner, ReentrancyGuard, Pausable /*InitializedOnce*/  {

    using SafeCast for uint;


    uint public constant MAX_NUM_SINGLE_EOA_PLEDGES = 20;

    address public platformAddr;

    address public delegate;

    ProjectState public projectState = ProjectState.IN_PROGRESS;


    uint public projectStartTime; //not here! = block.timestamp;

    uint public projectEndTime;

    uint public minPledgedSum;

    IVault public projectVault;
    IMintableOwnedERC20 public projectToken;

    uint public onChangeExitGracePeriod;
    uint public pledgerGraceExitWaitTime;
    uint public platformCutPromils;

    bytes32 public metadataCID;

    uint public current_endOfGracePeriod;

    mapping (address => PledgerRecord) public pledgerMap;
    mapping (address => PledgeEvent[]) public pledgerEventMap;

    uint private pledgerMapCount ;
    uint private pledgerEventMapCount ;


    uint public numPledgersSofar;

    uint public totalNumPledgeEvents;

    OnFailureRefundParams public onFailureRefundParams;

    //---


    struct OnFailureRefundParams {
        bool exists;
        uint totalPTokInVault;
        uint totalAllPledgerPTok;
    }

    modifier openForNewPledges() {
        _requireNotPaused();
        _;
    }

    modifier onlyIfExeedsMinPledgeSum( uint numPaymentTokens_) {
        require( numPaymentTokens_ >= minPledgedSum, "pledge must exceed min token count");
        _;
    }

    modifier onlyIfSenderHasSufficientPTokBalance( uint numPaymentTokens_) {
        uint tokenBalanceOfPledger_ = IERC20( paymentTokenAddress).balanceOf( msg.sender);
        require( tokenBalanceOfPledger_ >= numPaymentTokens_, "pledger has insufficient token balance");
        _;
    }

    modifier onlyIfSenderProvidesSufficientPTokAllowance( uint numPaymentTokens_) {
        require( _paymentTokenAllowanceFromSender() >= numPaymentTokens_, "modifier: insufficient allowance");
        _;
    }

    modifier onlyIfProjectFailed() {
        require( projectState == ProjectState.FAILED, "project running");
        require( projectEndTime > 0, "bad end date"); // sanity check
        _;
    }

    modifier onlyIfProjectSucceeded() {
        require( projectState == ProjectState.SUCCEEDED, "project not succeeded");
        require( projectEndTime > 0, "bad end date"); // sanity check
        _;
    }

    modifier projectIsInGracePeriod() {
        if (block.timestamp > current_endOfGracePeriod) {
            revert PledgerGraceExitRefusedOverdue( block.timestamp, current_endOfGracePeriod);
        }
        _;
    }


    modifier onlyIfProjectCompleted() {
        require( projectState != ProjectState.IN_PROGRESS, "project not completed");
        require( projectEndTime > 0, "bad end date"); // sanity check
        _;
    }

    modifier onlyIfOwner() { // == onlyOwner
        require( msg.sender == owner, "onlyIfTeamWallet: caller is not the owner");
        _;
    }

    modifier onlyIfOwnerOrDelegate() { //@gilad
        if (msg.sender != owner && msg.sender != delegate) {
            revert OnlyOwnerOrDelegateCanPerformAction(msg.sender, owner, delegate);
        }
        _;
    }

    modifier onlyIfActivePledger() {
        require( isActivePledger(msg.sender), "not an active pledger");
        _;
    }


    modifier onlyIfPlatform() {
        require( msg.sender == platformAddr, "not platform");
        _;
    }

    //---------


    event PledgerGraceExitWaitTimeChanged( uint newValue, uint oldValue);

    event NewPledgeEvent(address pledger, uint sum);

    event GracePeriodPledgerRefund( address pledger, uint shouldBeRefunded, uint actuallyRefunded);

    event TeamWalletRenounceOwnership();

    event ProjectFailurePledgerRefund( address pledger, uint shouldBeRefunded, uint actuallyRefunded);

    event TokenOwnershipTransferredToTeamWallet( address indexed projectContract, address indexed teamWallet);

    event ProjectStateChanged( ProjectState newState, ProjectState oldState);

    event ProjectDetailedWereChanged(uint changeTime, uint endOfGracePeriod);

    event MinPledgedSumWasSet(uint newMinPledgedSum, uint oldMinPledgedSum);

    event NewPledger(address indexed addr, uint indexed numPledgersSofar, uint indexed sum_);

    event DelegateChanged(address indexed newDelegate, address indexed oldDelegate);

    event TeamWalletChanged(address newWallet, address oldWallet);

    event OnFinalPTokRefundOfPledger( address indexed pledgerAddr_, uint32 pledgerEnterTime, uint shouldBeRefunded, uint actuallyRefunded);

    event OnProjectSucceeded(address indexed projectAddress, uint endTime);

    event OnProjectFailed( address indexed projectAddress, uint endTime);

    event PledgerBenefitsWithdrawn( address indexed pledger, uint numProjectTokens);


    //---------


    error PledgeMustExceedMinValue( uint numPaymentTokens, uint minPledgedSum);

    error MaxMuberOfPedgesPerEOAWasReached( address  pledgerAddr, uint maxNumEOAPledges);

    error MissingPledgrRecord( address  addr);

    error CallerNotAPledger( address caller);

    error BadRewardType( OnSuccessReward rewardType);

    error PledgerAlreadyExist(address addr);

    error OnlyOwnerOrDelegateCanPerformAction(address msgSender, address owner, address delegate);

    error PledgerMinRequirementNotMet(address addr, uint value, uint minValue);

    error OperationCannotBeAppliedToRunningProject(ProjectState projectState);

    //error OperationCannotBeAppliedWhileFundsInVault(uint fundsInVault);

    error PledgerGraceExitRefusedOverdue( uint exitRequestTime, uint endOfGracePeriod);

    error PledgerGraceExitRefusedTooSoon( uint exitRequestTime, uint exitAllowedStartTime);

    //---------


/*
 * @title initialize()
 *
 * @dev called by the platform (= owner) to initialize a _new contract proxy instance cloned from the project template
 *
 * @event: none
 */
    function initialize( ProjectInitParams memory params_) external override  onlyIfNotInitialized { //@PUBFUNC

        _markAsInitialized( params_.projectTeamWallet);

        require( params_.paymentToken != address(0), "missing payment token");

        platformAddr = msg.sender;

        projectStartTime = block.timestamp;
        projectState = ProjectState.IN_PROGRESS;
        delegate = address(0);
        projectEndTime = 0;
        current_endOfGracePeriod = 0;
        onFailureRefundParams =  OnFailureRefundParams( false, 0, 0);
        paymentTokenAddress = params_.paymentToken;

        // make sure that template maps are empty
        require( pledgerMapCount == 0, "pledger map not empty");
        require( pledgerEventMapCount == 0, "event map not empty");


        // ..and that project counters are set to zero
        require( numPledgersSofar == 0, "numPledgersSofar == 0");
        require( totalNumPledgeEvents == 0, "totalNumPledgeEvents == 0");

        _updateProject( params_.milestones, params_.minPledgedSum);

        projectVault = params_.vault;
        projectToken = params_.projectToken;
        platformCutPromils = params_.platformCutPromils;
        onChangeExitGracePeriod = params_.onChangeExitGracePeriod;
        pledgerGraceExitWaitTime = params_.pledgerGraceExitWaitTime;
        metadataCID = params_.cid;
    }


    function getProjectStartTime() external override view returns(uint) {
        return projectStartTime;
    }

/*
 * @title setDelegate()
 *
 * @dev sets a delegate account to be used for some management actions interchangeably with the team wallet account
 *
 * @event: DelegateChanged
 */
    function setDelegate(address newDelegate) external
                            onlyIfOwner onlyIfProjectNotCompleted /* not ownerOrDelegate! */ { //@PUBFUNC
        // possibly address(0)
        address oldDelegate_ = delegate;
        delegate = newDelegate;
        emit DelegateChanged(delegate, oldDelegate_);
    }

/*
 * @title updateProjectDetails()
 *
 * @dev updating project details with milestone list and minPledgedSu, immediately entering pledger-exit grace period
 *
 * @event: ProjectDetailedWereChanged
 */ //@DOC5
    function updateProjectDetails( Milestone[] memory milestones_, uint minPledgedSum_)
                                                        external onlyIfOwnerOrDelegate onlyIfProjectNotCompleted { //@PUBFUNC
        _updateProject(milestones_, minPledgedSum_);

        // TODO > this func must not change history items: pledger list, accomplished milestones,...

        current_endOfGracePeriod = block.timestamp + onChangeExitGracePeriod;
        emit ProjectDetailedWereChanged(block.timestamp, current_endOfGracePeriod);
    }

/*
 * @title setMinPledgedSum()
 *
 * @dev sets the minimal amount of payment-tokens deposit for future pledgers. No effect on existing pledgers
 *
 * @event: MinPledgedSumWasSet
 */
    function setMinPledgedSum(uint newMin) external onlyIfOwnerOrDelegate onlyIfProjectNotCompleted { //@PUBFUNC
        uint oldMin_ = minPledgedSum;
        minPledgedSum = newMin;
        emit MinPledgedSumWasSet(minPledgedSum, oldMin_);
    }

    function getOwner() public view override(IProject,InitializedOnce) returns (address) {
        return InitializedOnce.getOwner();
    }


/*
 * @title setTeamWallet()
 *
 * @dev allow  current project owner a.k.a. team wallet to change its address
 *  Internally handled by contract-ownershiptransfer= transferOwnership()
 *
 * @event: TeamWalletChanged
 */
    function setTeamWallet(address newWallet) external onlyIfOwner onlyIfProjectNotCompleted /* not ownerOrDelegate! */ { //@PUBFUNC
        changeOwnership( newWallet);
    }


    function setPledgerWaitTimeBeforeGraceExit(uint newWaitTime) external onlyIfOwner onlyIfProjectNotCompleted { //@PUBFUNC
        // will only take effect on future projects
        uint oldWaitTime_ = pledgerGraceExitWaitTime;
        pledgerGraceExitWaitTime = newWaitTime;
        emit PledgerGraceExitWaitTimeChanged( pledgerGraceExitWaitTime, oldWaitTime_);
    }

/*
 * @title renounceOwnershipOfProject()
 *
 * @dev allow  project owner = team wallet to renounce Ownership on project by setting the project's owner address to null
 *  Can only be applied for a completed project with zero internal funds
 *
 * @event: TeamWalletRenounceOwnership
 */
    function renounceOwnershipOfProject() external onlyOwner onlyIfProjectCompleted  { //@PUBFUNC
        if ( !projectIsCompleted()) {
            revert OperationCannotBeAppliedToRunningProject(projectState);
        }

        //@gilad: The _verifyVaultIsEmpty precondition for ownership renounce is now omitted.
        //  The reason: it basically allows a pledger to block this operation by not claiming his benefits
        //  this new approach has its flows, mainly that renouncing the project before all pledgers were refunded feels wrong
        //  Still, since the vault owner is the project *contract* rather than its owner, allowing ownership renounce
        //  will not result in any vault behavioral changes

        //_verifyVaultIsEmpty();


        renounceOwnership();

        emit TeamWalletRenounceOwnership();
    }


    /*
     * @title newPledge()
     *
     * @dev allow a _new pledger to enter the project
     *  This method is issued by the pledger with passed payment-token sum >= minPledgedSum
     *  Creates a pledger entry (if first time) and adds a plede event containing payment-token sum and date
     *  All incoming payment-token will be moved to project vault
     *
     *  Note: This function will NOT check for on-chain target completion (num-pledger, pledged-total)
     *         since that will require costly milestone iteration.
     *         Rather, the backend code should externally invoke the relevant onchain-milestone services:
     *           checkIfOnchainTargetWasReached() and onMilestoneOverdue()
     *         Max number of pledger events per single pledger: MAX_NUM_SINGLE_EOA_PLEDGES
     *
     * @precondition: caller (msg.sender) meeds to approve at least numPaymentTokens_ for this function to succeed
     *
     *
     * @event: NewPledger, NewPledgeEvent
     *
     * @CROSS_REENTRY_PROTECTION
     */ //@DOC2
    function newPledge(uint numPaymentTokens_, address paymentTokenAddr_)
                                        external openForAll openForNewPledges onlyIfProjectNotCompleted nonReentrant
                                        onlyIfExeedsMinPledgeSum( numPaymentTokens_)
                                        onlyIfSenderHasSufficientPTokBalance( numPaymentTokens_)
                                        onlyIfSenderProvidesSufficientPTokAllowance( numPaymentTokens_) { //@PUBFUNC //@PTokTransfer //@PLEDGER
        _verifyInitialized();

        address newPledgerAddr_ = msg.sender;

        require( paymentTokenAddr_ == paymentTokenAddress, "bad payment token");

        bool pledgerAlreadyExists = isRegisteredPledger( newPledgerAddr_);

        if (pledgerAlreadyExists) {
            verifyMaxNumPledgesNotExceeded( newPledgerAddr_);
        } else {
            _createPledgerMapRecordForSender( newPledgerAddr_);
            emit NewPledger( newPledgerAddr_, numPledgersSofar, numPaymentTokens_);
            numPledgersSofar++;
        }

        _addEventToPledgerEventMap( newPledgerAddr_, numPaymentTokens_);

        _transferPaymentTokensToVault( numPaymentTokens_);
    }


    function _createPledgerMapRecordForSender( address newPledgerAddr_) private {
        uint numCompletedMilestones_ = successfulMilestoneIndexes.length;

        PledgerRecord memory record_ = PledgerRecord({ enterDate: block.timestamp,
                                                        completedMilestonesWhenEntered: numCompletedMilestones_,
                                                        successfulMilestoneStartIndex: numCompletedMilestones_,
                                                        noLongerActive: false });
        //@gilad; pledger events stored in: pledgerEventMap[ newPledgerAddr_]

        pledgerMap[ newPledgerAddr_] = record_;
        pledgerMapCount++;
    }


    function _transferPaymentTokensToVault( uint numPaymentTokens_) private {
        address pledgerAddr_ = msg.sender;
        IERC20 paymentToken_ = IERC20( paymentTokenAddress);

        require( _paymentTokenAllowanceFromSender() >= numPaymentTokens_, "insufficient token allowance");

        projectVault.addNewPledgePToks( numPaymentTokens_);

        bool transferred_ = paymentToken_.transferFrom( pledgerAddr_, address(projectVault), numPaymentTokens_);
        require( transferred_, "Failed to transfer payment tokens to vault");
    }


    function _paymentTokenAllowanceFromSender() view private returns(uint) {
        IERC20 paymentToken_ = IERC20( paymentTokenAddress);
        return paymentToken_.allowance( msg.sender, address(this) );
    }

    function verifyMaxNumPledgesNotExceeded( address addr) private view {
        if (pledgerEventMap[addr].length >= MAX_NUM_SINGLE_EOA_PLEDGES) {
            revert MaxMuberOfPedgesPerEOAWasReached( addr, MAX_NUM_SINGLE_EOA_PLEDGES);
        }
    }


    function _addEventToPledgerEventMap( address existingPledgerAddr_, uint numPaymentTokens_) private {
        uint32 now_ = block.timestamp.toUint32();

        pledgerEventMap[ existingPledgerAddr_].push( PledgeEvent({ date: now_, sum: numPaymentTokens_ }));
        pledgerEventMapCount++;

        totalNumPledgeEvents++;

        emit NewPledgeEvent( existingPledgerAddr_, numPaymentTokens_);
    }



    function projectIsCompleted() public view returns(bool) {
        // either with success or failure
        return (projectState != ProjectState.IN_PROGRESS);
    }


    function _projectHasSucceeded() private view returns(bool) {
        // either with success or failure
        return (projectState == ProjectState.SUCCEEDED);
    }

    function projectHasFailed() external view override returns(bool) {
        return (projectState == ProjectState.FAILED);
    }


    enum OnSuccessReward { TOKENS, NFT }


    /*
     * @title transferProjectTokenOwnershipToTeam()
     *
     * @dev Allows the project team account to regain ownership on the erc20 project token after project is completed
     *  Transfer project token ownership from the project contract (= address(this)) to the team wallet
     *
     * @event: TokenOwnershipTransferredToTeamWallet
     */
    function transferProjectTokenOwnershipToTeam() external
                                                onlyIfOwner onlyIfProjectCompleted { //@PUBFUNC
        address teamWallet_ = getOwner(); // project owner is teamWallet
        address tokenOwner_ = address(this); // token owner is the project contract
        require( projectToken.getOwner() == tokenOwner_, "must be project");

        projectToken.changeOwnership( teamWallet_);

        emit TokenOwnershipTransferredToTeamWallet( tokenOwner_, teamWallet_);
    }


    /*
     * @title onProjectFailurePledgerRefund()
     *
     * @dev Refund pledger with its proportion of payment-token from team vault on failed project. Called by pledger
     * @sideeffect: remove pledger record
     *
     * @event: ProjectFailurePledgerRefund
     * @CROSS_REENTRY_PROTECTION
     */ //@DOC7
    function onProjectFailurePledgerRefund() external
                                    onlyIfActivePledger onlyIfProjectFailed
                                    nonReentrant /*pledgerWasNotRefunded*/ { //@PUBFUNC //@PLEDGER

        //@PLEDGERS_CAN_WITHDRAW_PTOK
        address pledgerAddr_ = msg.sender;

        require( onFailureRefundParams.exists, "onFailureRefundParams not set");



        // TODO >> replace below call with now commented _applyBenefitFactors impl when @INTERMEDIATE_BENEFITS_DISABLED is active
        uint shouldBeRefunded_ = _pledgerTotalPTokInvestment( pledgerAddr_);
        //uint numPToksInVaultAtTimeOfFailure_ = onFailureRefundParams.totalPTokInVault;
        //uint shouldBeRefunded_ = _applyBenefitFactors( numPToksInVaultAtTimeOfFailure_, pledgerAddr_);
        //------------------------




        uint actuallyRefunded_ = _pTokRefundToPledger( pledgerAddr_, shouldBeRefunded_, false);

        emit ProjectFailurePledgerRefund( pledgerAddr_, shouldBeRefunded_, actuallyRefunded_);

        _markPledgerAsNonActive( pledgerAddr_);

        // pledger may still receive due project-token benefits
    }


    //hhhhh will break update updateContract


    function transferProjectTokensToPledgerOnProjectSuccess() external nonReentrant onlyIfActivePledger {
        require( _projectHasSucceeded(), "project has not succeeded");
        _withdrawPledgerBenefits();
    }


    function _withdrawPledgerBenefits() private onlyIfActivePledger { //hhhh new func > make external


        // TODO >> remove to switch to periodical-benefits model @INTERMEDIATE_BENEFITS_DISABLED
        require( _projectHasSucceeded(), "project has not succeeded");
        //--------------------



        // withdraw pending project-token benefits
        address pledgerAddr_ = msg.sender;

        uint numProjectTokensToMint_ = calculatePledgerBenefits();




        // TODO >> @INTERMEDIATE_BENEFITS_DISABLED overriding numProjectTokensToMint_ so to avoid any factor calculations
        // TODO >>   instead return projectTokens in the amount of the total PTok amount invested by pledger
        numProjectTokensToMint_ = _pledgerTotalPTokInvestment( pledgerAddr_);
        //--------------------




        _mintBenefitsAndUpdateStartIndex( pledgerAddr_, numProjectTokensToMint_);

        if (projectIsCompleted()) {
            _markPledgerAsNonActive( pledgerAddr_);
        }

        emit PledgerBenefitsWithdrawn( pledgerAddr_, numProjectTokensToMint_);
    }


    function _mintBenefitsAndUpdateStartIndex( address pledgerAddr_, uint numProjectTokensToMint_) private {
        // update start index
        PledgerRecord storage pledger_ = pledgerMap[ pledgerAddr_];
        pledger_.successfulMilestoneStartIndex = successfulMilestoneIndexes.length;

        // and mint project-token benefits
        require( projectToken.getOwner() == address(this), "must be owned by project");
        projectToken.mint( pledgerAddr_, numProjectTokensToMint_);
    }


    function calculatePledgerBenefits() public view onlyIfActivePledger returns(uint) { //hhhh new func
        // calculate unpaid benefits for all unpaid successful milestones
        address pledgerAddr_ = msg.sender;


        // TODO >> uncomment _applyBenefitFactors below once @INTERMEDIATE_BENEFITS_DISABLED is active
        return _pledgerTotalPTokInvestment( pledgerAddr_);
        //return _applyBenefitFactors( _allCompletedMilestonePToks(), pledgerAddr_);
        //---------------------------------
    }


    function _allCompletedMilestonePToks() private view returns(uint) {
        address pledgerAddr_ = msg.sender;
        uint startInd_ = _getStartIndexForPledger( pledgerAddr_);
        return _calcCompletedMilestonesSumStartingIndex( startInd_);
    }


    function _getStartIndexForPledger( address pledgerAddr_) private view returns(uint) {
        // return the completed-milestone index starting which benefits were not yet granted to pledger
        PledgerRecord storage pledger_ = pledgerMap[ pledgerAddr_];
        return pledger_.successfulMilestoneStartIndex;
    }


    function _applyBenefitFactors( uint baseSumPToks_, address pledgerAddr_) private view returns(uint) {


        // TODO >> @INTERMEDIATE_BENEFITS_DISABLED refund-factors calculation disabled
        require( false, "_applyBenefitFactors disabled for now");
        //---------




        // return (BaseSum * InvestmentFactor * TimeFactor) where:
        //      baseSumPToks_:    amount-PToks-in-vault  -or-  sum-of-all-completed-milestones
        //      InvestmentFactor: (total pledger PTok investments) / (project's total PTok investments)
        //      TimeFactor:       (num active milestones when entering) / (num all milestones)

        uint pledgerTotalPTokInvestment_ = _pledgerTotalPTokInvestment( pledgerAddr_);

        uint totalPTokInvestedInProj_ = _getTotalPToksInvestedInProject();

        uint numAllMilestones_ = getNumberOfMilestones();

        require (totalPTokInvestedInProj_ > 0 && numAllMilestones_ > 0, "zero divisor");

        uint numActiveMilestonesWhenEntering_ = _getNumActiveMilestonesWhenEntering( pledgerAddr_);

        uint sumAfterFactors_ = ( baseSumPToks_ * pledgerTotalPTokInvestment_ * numActiveMilestonesWhenEntering_ ) /
                                         ( totalPTokInvestedInProj_ * numAllMilestones_ );

        return sumAfterFactors_;
    }


    function _getNumActiveMilestonesWhenEntering( address pledgerAddr_) private view returns(uint) {
        uint numAllMilestones_ = getNumberOfMilestones();
        PledgerRecord storage pledger_ = pledgerMap[ pledgerAddr_];
        return numAllMilestones_ - pledger_.completedMilestonesWhenEntered;
    }


    function _getTotalPToksInvestedInProject() private view returns(uint) {
        return projectVault.getTotalPToksInvestedInProject();
    }


    function _calcCompletedMilestonesSumStartingIndex( uint startInd_) private view returns(uint) {
        uint pTokSum_ = 0;
        for (uint i = startInd_; i < successfulMilestoneIndexes.length; i++) {
            uint ind_ = successfulMilestoneIndexes[i];
            Milestone storage milestone_ = milestoneArr[ ind_];
            require( milestone_.result == MilestoneResult.SUCCEEDED, "milestone not successful");
            pTokSum_ += milestone_.pTokValue;
        }
        return pTokSum_;
    }


    function _pledgerTotalPTokInvestment( address pledgerAddr_) private view returns(uint) {
        PledgeEvent[] storage events = pledgerEventMap[ pledgerAddr_];
        uint total_ = 0 ;
        for (uint i = 0; i < events.length; i++) {
            total_ += events[i].sum;
        }
        return total_;
    }


    /*
     * @title onGracePeriodPledgerRefund()
     *
     * @dev called by pledger to request full payment-token refund during grace period
     *  Will only be allowed if pledger pledgerExitAllowedStartTime matches Tx time
     *  At Tx successful end the pledger record will be removed form project
     *  Note: that this service will not be available if project has completed, even if before end of grace period
     *
     * @event: GracePeriodPledgerRefund
     * @CROSS_REENTRY_PROTECTION
     */ //@DOC6
    function onGracePeriodPledgerRefund() external
                                onlyIfActivePledger projectIsInGracePeriod onlyIfProjectNotCompleted
                                nonReentrant /*pledgerWasNotRefunded*/ { //@PUBFUNC //@PLEDGER

        address pledgerAddr_ = msg.sender;

        uint pledgerEnterTime_ = getPledgerEnterTime( pledgerAddr_);

        uint pledgerExitAllowedStartTime = pledgerEnterTime_ + pledgerGraceExitWaitTime;

        if (block.timestamp < pledgerExitAllowedStartTime) {
            revert PledgerGraceExitRefusedTooSoon( block.timestamp, pledgerExitAllowedStartTime);
        }

        uint shouldBeRefunded_ = calculatePledgerBenefits();



        // TODO >> @INTERMEDIATE_BENEFITS_DISABLED remove shouldBeRefunded_ override below so to return to refund-factors calculation
        shouldBeRefunded_ = _pledgerTotalPTokInvestment( pledgerAddr_);
        //-------------




        uint actuallyRefunded_ = _pTokRefundToPledger( pledgerAddr_, shouldBeRefunded_, true);

        emit GracePeriodPledgerRefund( pledgerAddr_, shouldBeRefunded_, actuallyRefunded_);

        _markPledgerAsNonActive( pledgerAddr_);
    }


    function getBenefitCalcParams() external view returns(uint allCompletedMilestonePToks_, uint pledgerTotalPTokInvestment_,
                                                          uint totalPTokInvestedInProj_, uint numAllMilestones_,
                                                          uint numActiveMilestonesWhenEntering_, uint numCompletedMiliestones_,
                                                          uint startCompletedMilestoneInd_) {
        // a utility function to debug project-token benefit calculation
        address pledgerAddr_ = msg.sender;
        allCompletedMilestonePToks_ = _allCompletedMilestonePToks();
        pledgerTotalPTokInvestment_ = _pledgerTotalPTokInvestment(pledgerAddr_);
        totalPTokInvestedInProj_ = _getTotalPToksInvestedInProject();
        numAllMilestones_ = getNumberOfMilestones();
        numActiveMilestonesWhenEntering_ = _getNumActiveMilestonesWhenEntering( pledgerAddr_);
        numCompletedMiliestones_ = getNumberOfSuccessfulMilestones();
        startCompletedMilestoneInd_ = _getStartIndexForPledger( pledgerAddr_);
    }


    function _markPledgerAsNonActive( address pledgerAddr_) private {
        require( isActivePledger( pledgerAddr_), "not an active pledger");
        uint numPledgeEvents = pledgerEventMap[ pledgerAddr_].length;

        pledgerMap[ pledgerAddr_].noLongerActive = true;

        totalNumPledgeEvents -= numPledgeEvents;

        numPledgersSofar--;
    }


    function getNumEventsForPledger( address pledgerAddr_) external view returns(uint) {
        return pledgerEventMap[ pledgerAddr_].length;
    }

    function getPledgeEvent( address pledgerAddr_, uint eventIndex_) external view returns(uint32, uint) {
        PledgeEvent storage event_ = pledgerEventMap[ pledgerAddr_][ eventIndex_];
        return (event_.date, event_.sum);
    }

    function getPledgerEnterTime( address pledgerAddr_) private view returns(uint32) {
        return uint32(pledgerMap[ pledgerAddr_].enterDate); // pledger's enter time =  date of first pledge event
    }

    function getPaymentTokenAddress() public override view returns(address) {
        return paymentTokenAddress;
    }

    //@ITeamWalletOwner
    function getTeamWallet() external override view returns(address) {
        //return teamWallet;
        return getOwner();
    }


    function getTeamBalanceInVault() external override view returns(uint) {
        return projectVault.getTeamBalanceInVault();
    }

    function getPledgersBalanceInVault() external override view returns(uint) {
        return projectVault.vaultBalance();
    }

    function getVaultAddress() external view returns(address) {
        return address(projectVault);
    }

//--------


    function _intToUint(int intVal) private pure returns(uint) {
        require(intVal >= 0, "cannot convert to uint");
        return uint(intVal);
    }


    function _pTokRefundToPledger( address pledgerAddr_, uint shouldBeRefunded_, bool gracePeriodExit_) private returns(uint) {
        // due to project failure or grace-period exit
        uint actuallyRefunded_ = projectVault.transferPToksToPledger( pledgerAddr_, shouldBeRefunded_, gracePeriodExit_); //@PTokTransfer

        uint32 pledgerEnterTime_ = getPledgerEnterTime( pledgerAddr_);

        emit OnFinalPTokRefundOfPledger( pledgerAddr_, pledgerEnterTime_, shouldBeRefunded_, actuallyRefunded_);

        return actuallyRefunded_;
    }


    function _setProjectState( ProjectState newState_) private onlyIfProjectNotCompleted {
        ProjectState oldState_ = projectState;
        projectState = newState_;
        emit ProjectStateChanged( projectState, oldState_);
    }

    /// -----


    function getProjectTokenAddress() external view returns(address) {
        return address(projectToken);
    }

    function getProjectState() external view override returns(ProjectState) {
        return projectState;
    }

    function getProjectMetadataCID() external view returns(bytes32) {
        return metadataCID;
    }

    function _projectNotCompleted() internal override view returns(bool) {
        return projectState == ProjectState.IN_PROGRESS;
    }

    function _getProjectVault() internal override view returns(IVault) {
        return projectVault;
    }

    function getPlatformCutPromils() public override view returns(uint) {
        return platformCutPromils;
    }

    function _getPlatformAddress() internal override view returns(address) {
        return platformAddr;
    }

    function _getNumPledgersSofar() internal override view returns(uint) {
        return numPledgersSofar;
    }
    //------------


    function _onProjectSucceeded() internal override {
        _setProjectState( ProjectState.SUCCEEDED);

        _terminateGracePeriod();

        require( projectEndTime == 0, "end time already set");
        projectEndTime = block.timestamp;

        emit OnProjectSucceeded(address(this), block.timestamp);

        _transferAllVaultFundsToTeam();

        //@PLEDGERS_CAN_WITHDRAW_PROJECT_TOKENS
    }


    function getOnFailureParams() external view returns (bool,uint,uint) {
        return ( onFailureRefundParams.exists,
                 onFailureRefundParams.totalPTokInVault,
                 onFailureRefundParams.totalAllPledgerPTok);
    }


    function _onProjectFailed() internal override {
        require( _projectNotCompleted(), "project already completed");

        _setProjectState( ProjectState.FAILED);

        _terminateGracePeriod();

        projectVault.onFailureMoveTeamFundsToPledgers();

        uint totalPTokInVault_ = projectVault.vaultBalance();
        uint totalPTokInvestedInProj_ = projectVault.getTotalPToksInvestedInProject();

        //@gilad: create a refund factor that will be constant to all pledgers
        require( !onFailureRefundParams.exists, "onFailureRefundParams already set");
        onFailureRefundParams = OnFailureRefundParams({ exists: true,
                                                        totalPTokInVault: totalPTokInVault_,
                                                        totalAllPledgerPTok: totalPTokInvestedInProj_ });

        require( projectEndTime == 0, "end time already set");
        projectEndTime = block.timestamp;

        emit OnProjectFailed(address(this), block.timestamp);

        //@PLEDGERS_CAN_WITHDRAW_PTOK
    }


    function _terminateGracePeriod() private {
        current_endOfGracePeriod = 0;
    }

    function getEndOfGracePeriod() external view returns(uint) {
        return current_endOfGracePeriod;
    }


    function _transferAllVaultFundsToTeam() private {
        address platformAddr_ = _getPlatformAddress();

        (/*uint teamCut_*/, uint platformCut_) = _getProjectVault().transferAllVaultFundsToTeam( getPlatformCutPromils(), platformAddr_);

        IPlatform( platformAddr_).onReceivePaymentTokens( paymentTokenAddress, platformCut_);
    }

    function isActivePledger(address addr) public view returns(bool) {
        return isRegisteredPledger(addr) && !pledgerMap[ addr].noLongerActive;
    }

    function isRegisteredPledger(address addr) public view returns(bool) {
        return pledgerMap[ addr].enterDate > 0;
    }

    function mintProjectTokens( address to, uint numTokens) external override onlyIfPlatform { //@PUBFUNC
        projectToken.mint( to, numTokens);
    }

    //-------------- 

    function _updateProject( Milestone[] memory newMilestones, uint newMinPledgedSum) private {
        // historical records (pledger list, successfulMilestoneIndexes...) and immuables
        // (projectVault, projectToken, platformCutPromils, onChangeExitGracePeriod, pledgerGraceExitWaitTime)
        // are not to be touched here

        // gilad: avoid min/max NumMilestones validations while in update
        Sanitizer._sanitizeMilestones( newMilestones, block.timestamp, 0, 0);

        _setMilestones( newMilestones);

        delete successfulMilestoneIndexes; //@DETECT_PROJECT_SUCCESS

        minPledgedSum = newMinPledgedSum;

        //@gilad -- solve problem of correlating successfulMilestoneIndexes with _new milesones list!
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../@openzeppelin/contracts/access/Ownable.sol";
import "../project/PledgeEvent.sol";

interface IVault {

    function transferAllVaultFundsToTeam( uint platformCutPromils_, address platformAddr_) external returns(uint,uint);

    function transferPToksToPledger( address pledgerAddr_, uint sum_, bool gracePeriodExit_) external returns(uint);

    function addNewPledgePToks( uint numPaymentTokens_) external;

    function vaultBalance() external view returns(uint); // ==pledger balance in vault

    function getTeamBalanceInVault() external view returns(uint);

    function getTotalPToksInvestedInProject() external view returns(uint);

    function changeOwnership( address project_) external;
    function getOwner() external view returns (address);

    function onFailureMoveTeamFundsToPledgers() external;

    function assignFundsFromPledgersToTeam( uint sum_) external;

    function initialize( address owner_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


abstract contract InitializedOnce {

    bool public wasInitialized;

    address public owner;


    event OwnershipChanged( address indexed owner_, address indexed oldOwner_);

    event OwnershipRenounced( address indexed oldOwner_);

    event MarkedAsInitialized();


    modifier onlyIfNotInitialized() {
        require( !wasInitialized, "can only be initialized once");
        _;
    }

    modifier onlyOwner() {
        require( owner == msg.sender, "caller is not owner");
        _;
    }

    modifier onlyOwnerOrNull() {
        require( owner == address(0) || owner == msg.sender, "onlyOwnerOrNull");
        _;
    }

    function changeOwnership(address newOwner) virtual public onlyOwnerOrNull {
        require( newOwner != address(0), "new owner cannot be zero");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipChanged( owner, oldOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipRenounced( oldOwner);
    }

    function getOwner() public virtual view returns (address) {
        return owner;
    }

    function _verifyInitialized() internal view {
        require( wasInitialized, "not initialized");
    }

    function _markAsInitialized( address owner_) internal onlyIfNotInitialized {
        wasInitialized = true;

        changeOwnership(owner_);

        emit MarkedAsInitialized();
    }

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

enum ProjectState {
    IN_PROGRESS,
    SUCCEEDED,
    FAILED
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
    bytes32 cid;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


struct PledgerRecord {
    uint enterDate;
    uint completedMilestonesWhenEntered;
    uint successfulMilestoneStartIndex;
    bool noLongerActive;
    //PledgeEvent[] events;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

struct PledgeEvent { //@STORAGEOPT
    uint32 date;
    uint sum;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../@openzeppelin/contracts/security/Pausable.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../milestone/MilestoneResult.sol";
import "../milestone/Milestone.sol";
import "../milestone/MilestoneApprover.sol";
import "../vault/IVault.sol";
import "../platform/IPlatform.sol";
import "../utils/InitializedOnce.sol";


//hhhh go over all @INTERMEDIATE_BENEFITS_DISABLED

abstract contract MilestoneOwner is InitializedOnce {

    using SafeCast for uint;

    uint32 private constant DUE_DATE_GRACE_PERIOD = 20 seconds;

    Milestone[] public milestoneArr;

    uint[] public successfulMilestoneIndexes;

    address public paymentTokenAddress;

    //-----


    event OnchainMilestoneNotYetReached( uint milestoneIndex_, uint existingSum, uint requitedSum, uint existingNumPledgers, uint requiredNumPledgers);

    event MilestoneSuccess( uint milestoneIndex_);

    event MilestoneResultChanged( MilestoneResult newResult, MilestoneResult oldResult);

    event MilestoneIsOverdueEvent(uint indexed milestoneIndex, uint indexed dueDate, uint blockTimestamp);

    event MilestoneSucceededNumPledgers( uint indexed numPledgersInMilestone, uint indexed numPledgersSofar);

    event MilestoneSucceededFunding(uint indexed fundingPTokTarget, uint currentBalance);

    event MilestoneSucceededByExternalApprover( uint milestoneIndex_, string reason);

    event MilestoneFailedByExternalApprover( uint milestoneIndex_, string reason);
    //-----


    error MilestoneIsAlreadyResolved(uint milestoneIndex);

    error NotAnExpernallyApprovedMilestone(uint milestoneIndex);

    error CanOnlyBeInvokedByAMilestoneApprover(uint milestoneIndex, address externalApprover, address msgSender);

    error PrerequisitesWasNotMet(int prerequisiteIndex, uint milestoneIndex);

    error MilestoneIsNotOverdue(uint milestoneIndex, uint time);

    //----


    modifier openForAll() {
        _;
    }

    modifier onlyIfProjectNotCompleted() {
        require( _projectNotCompleted(), "no longer running");
        _;
    }

    modifier onlyIfUnresolved( uint milestoneIndex_) {
        require( milestoneArr[milestoneIndex_].result == MilestoneResult.UNRESOLVED, "milestone already resolved");
        _;
    }

    modifier onlyIfOnchain( uint milestoneIndex_) {
        require( milestoneArr[milestoneIndex_].milestoneApprover.externalApprover == address(0), "milestone not onchain");
        _;
    }

    modifier onlyExternalApprover( uint milestoneIndex_) {
        MilestoneApprover storage approver_ = milestoneArr[ milestoneIndex_].milestoneApprover;

        require( approver_.externalApprover != address(0), "Not an externally approved milestone");

        if (msg.sender != approver_.externalApprover) {
            revert CanOnlyBeInvokedByAMilestoneApprover( milestoneIndex_, approver_.externalApprover, msg.sender);
        }

        _;
    }


/*
 * @title checkIfOnchainTargetWasReached()
 *
 * @dev Allows 'all' to check if a given onchain milestone (sum-target or num-pledger-target) has been reached
 *  project must be still running
 *  If the milestone has succeeded - mark it as such
 *  If not - check if target is overdue and, if so, failproject
 *
 * Note: function will be invoked event if project is paused
 *
 * @event: OnProjectFailed, MilestoneSuccess or OnchainMilestoneNotYetReached
 */
    function checkIfOnchainTargetWasReached(uint milestoneIndex_)
                                                external openForAll onlyIfProjectNotCompleted
                                                onlyIfOnchain( milestoneIndex_)
                                                onlyIfUnresolved( milestoneIndex_) /*even if paused*/ { //@PUBFUNC
        _verifyInitialized();

        Milestone storage milestone_ = milestoneArr[milestoneIndex_];

        if (_failProjectIfOverdue( milestoneIndex_, milestone_)) {
            return; // project now failed
        } else if (_onchainMilestoneSucceeded( milestoneIndex_, milestone_)) {
            _onMilestoneSuccess( milestone_, milestoneIndex_);
        } else {
            _emitOnchainMilestoneNotYetReached( milestoneIndex_, milestone_);
        }
    }


    function _emitOnchainMilestoneNotYetReached( uint milestoneIndex_, Milestone storage milestone_) private {
        MilestoneApprover storage approver_ = milestone_.milestoneApprover;
        if (approver_.fundingPTokTarget > 0) {
            uint totalReceivedPToks_ = _getProjectVault().getTotalPToksInvestedInProject();
            emit OnchainMilestoneNotYetReached( milestoneIndex_, totalReceivedPToks_, approver_.fundingPTokTarget, 0, 0);
        } else {
            emit OnchainMilestoneNotYetReached( milestoneIndex_, 0, 0, _getNumPledgersSofar(), approver_.targetNumPledgers);
        }
    }


/*
 * @title onExternalApproverResolve()
 *
 * @dev Allows an external approver (EOA, oracle) to vote on the external milestone assigned to him
 *  project must be still running
 *  if milestone is overdue; fail project
 *  If the milestone has succeeded - mark it as such
 *  If the milestone has failed - fail project
 *
 * Note:  function will be invoked event if project is paused
 * Note2: this function will not fail if overdue! rather it will change the entire project status to failed
 *
 * Note3: this function should be assumed successful if not revert! getProjectState() must be called toverify
 *        it had not failed due to an overdue milestone!
 *
 * @event: OnProjectFailed, MilestoneFailedByExternalApprover or MilestoneSucceededByExternalApprover
 */ //@DOC3
    function onExternalApproverResolve(uint milestoneIndex_, bool succeeded, string calldata reason) external
                                        onlyIfProjectNotCompleted
                                        onlyExternalApprover( milestoneIndex_)
                                        onlyIfUnresolved( milestoneIndex_) /*even if paused*/ { //@PUBFUNC
        _verifyInitialized();

        Milestone storage milestone_ = milestoneArr[milestoneIndex_];

        if (_failProjectIfOverdue( milestoneIndex_, milestone_)) {
            return; // project now failed
        } else {
            _handleExternalApproverDecision( milestoneIndex_, milestone_, succeeded, reason);
        }
    }


/*
 * @title onMilestoneOverdue()
 *
 * @dev Allows 'all' to inform the project on an overdue milestone - either external of onchain,resulting on project failure
 * Project must be not-completed
 *
 * @event: MilestoneIsOverdueEvent
 */ //@DOC4
    function onMilestoneOverdue(uint milestoneIndex_) external openForAll onlyIfProjectNotCompleted  {//@PUBFUNC: also notPaused??
        _verifyInitialized();

        Milestone storage milestone_ = milestoneArr[ milestoneIndex_];

        if (_failProjectIfOverdue( milestoneIndex_, milestone_)) {
            return; // project now failed
        } else {
            revert MilestoneIsNotOverdue( milestoneIndex_, block.timestamp);
        }
    }


    function _handleExternalApproverDecision( uint milestoneIndex_, Milestone storage milestone_,
                                              bool succeeded, string calldata reason) private {
        MilestoneApprover storage approver_ = milestone_.milestoneApprover;

        require( msg.sender == approver_.externalApprover, "not milestone approver");

        if (succeeded) {
            _onMilestoneSuccess( milestone_, milestoneIndex_);
            emit MilestoneSucceededByExternalApprover( milestoneIndex_, reason);
        } else {            
            _onExternalMilestoneFailure( milestone_);
            emit MilestoneFailedByExternalApprover( milestoneIndex_, reason);
        } 
    }



    function _onchainMilestoneSucceeded( uint milestoneIndex_, Milestone storage milestone_)
                                                        private onlyIfOnchain( milestoneIndex_)
                                                        returns(bool) {
        MilestoneApprover storage approver_ = milestone_.milestoneApprover;
        require( approver_.fundingPTokTarget > 0 || approver_.targetNumPledgers > 0, "not on-chain");

        _verifyPrerequisiteWasMet( milestoneIndex_);

        if (approver_.fundingPTokTarget > 0) {
            uint totalReceivedPToks_ = _getProjectVault().getTotalPToksInvestedInProject();
            if (totalReceivedPToks_ >= approver_.fundingPTokTarget) {
                emit MilestoneSucceededFunding( approver_.fundingPTokTarget, totalReceivedPToks_);
                return true;
            }
            return false;
        }

        require( approver_.targetNumPledgers > 0, "num-pledgers not ser");

        if (_getNumPledgersSofar() >= approver_.targetNumPledgers) {
            emit MilestoneSucceededNumPledgers( approver_.targetNumPledgers, _getNumPledgersSofar());
            return true;
        }
        return false;
    }


    function _onMilestoneSuccess( Milestone storage milestone_, uint milestoneIndex_) private {

        _verifyPrerequisiteWasMet( milestoneIndex_);




        // TODO >> uncomment test below when switching to periodical-benefits model @INTERMEDIATE_BENEFITS_DISABLED
        //_verifyEnoughFundsInVault( milestoneIndex_);
        //------------------



        _setMilestoneResult( milestone_, MilestoneResult.SUCCEEDED);

        // add to completed arr
        successfulMilestoneIndexes.push( milestoneIndex_);

        _assignMilestoneFundsToTeamVault( milestone_);

        if (successfulMilestoneIndexes.length == milestoneArr.length) { //@DETECT_PROJECT_SUCCESS
            _onProjectSucceeded();
        }

        emit MilestoneSuccess( milestoneIndex_);
    }


    function getNumberOfSuccessfulMilestones() public view returns(uint) {
        return successfulMilestoneIndexes.length;
    }


    function _assignMilestoneFundsToTeamVault( Milestone storage milestone_) private {

        // TODO >> note that when in @INTERMEDIATE_BENEFITS_DISABLED noactual funds leave the vault, but rather counters are updates

        // pass milestone funds from vault to teamWallet
        require( address(this) == _getProjectVault().getOwner(), "proj contract must own vault");

        _getProjectVault().assignFundsFromPledgersToTeam( milestone_.pTokValue);
    }


    function _failProjectIfOverdue( uint milestoneIndex_, Milestone storage milestone_) private returns(bool) {

        require( milestone_.result == MilestoneResult.UNRESOLVED, "milestone already resolved"); // must check first!

        if (milestoneIsOverdue( milestoneIndex_)) {
            _setMilestoneResult( milestone_,  MilestoneResult.FAILED);
            _onProjectFailed();
            emit MilestoneIsOverdueEvent(milestoneIndex_, milestone_.dueDate, block.timestamp);
            return true;
        }

        return false;
    }

    function _onExternalMilestoneFailure( Milestone storage milestone_) private {
        _setMilestoneResult( milestone_,  MilestoneResult.FAILED);
        _onProjectFailed();
    }

    function _setMilestoneResult( Milestone storage milestone_,  MilestoneResult newResult) private {
        MilestoneResult oldResult = milestone_.result;
        milestone_.result = newResult;
        emit MilestoneResultChanged( milestone_.result, oldResult);
    }


    function _verifyEnoughFundsInVault(uint milestoneIndex) private view {
        uint milestoneValue =  milestoneArr[ milestoneIndex].pTokValue;
        uint fundsInVault_ = _getProjectVault().vaultBalance();
        require( fundsInVault_ >= milestoneValue, "not enough funds in vault");
        //TODO >> consider problem of e.g. number-of-pledgers milestone completed with not enough funds in vault
    }

    function _verifyPrerequisiteWasMet(uint milestoneIndex) private view {
        Milestone storage milestone_ = milestoneArr[milestoneIndex];
        int prerequisiteIndex_ = milestone_.prereqInd;
        if (_prerequisiteWasNotMet( prerequisiteIndex_)) {
            revert PrerequisitesWasNotMet( prerequisiteIndex_, milestoneIndex);
        }
    }

    function _prerequisiteWasNotMet(int prerequisiteIndex_) private view returns(bool) {
        if (prerequisiteIndex_ < 0) {
            return false;
        }

        return milestoneArr[ uint(prerequisiteIndex_)].result != MilestoneResult.SUCCEEDED;
    }

    function getNumberOfMilestones() public view returns(uint) {
        return milestoneArr.length;
    }

    function getMilestoneDetails(uint ind_) external view returns( MilestoneResult, uint32, int32, uint, address, uint32, uint) {
        Milestone storage mstone_ = milestoneArr[ind_];
        MilestoneApprover storage approver_ = mstone_.milestoneApprover;
        return (
            mstone_.result, mstone_.dueDate, mstone_.prereqInd, mstone_.pTokValue,
            approver_.externalApprover, approver_.targetNumPledgers, approver_.fundingPTokTarget );
    }

    function getPrerequisiteIndexForMilestone(uint milestoneIndex) external view returns(int) {
        return milestoneArr[milestoneIndex].prereqInd;
    }

    function backdoor_markMilestoneAsOverdue(uint milestoneIndex) external { //TODO @gilad hhhh remove after testing!!!!
        milestoneArr[ milestoneIndex].dueDate = block.timestamp.toUint32() - DUE_DATE_GRACE_PERIOD - 1;
    }


    function milestoneIsOverdue( uint milestoneIndex_) public view returns(bool) {
        // no action taken, check only
        return block.timestamp > (milestoneArr[ milestoneIndex_].dueDate + DUE_DATE_GRACE_PERIOD);
    }

    function getMilestoneOverdueTime(uint milestoneIndex) external view returns(uint) {
        return milestoneArr[ milestoneIndex].dueDate;
    }


    function getMilestoneResult(uint milestoneIndex) external view returns(MilestoneResult) {
        return milestoneArr[milestoneIndex].result;
    }

    function getMilestoneValueInPaymentTokens(uint milestoneIndex) external view returns(uint) {
        return milestoneArr[milestoneIndex].pTokValue;
    }

    //-----
    function _onProjectSucceeded() internal virtual;
    function _onProjectFailed() internal virtual;
    function _getProjectVault() internal virtual view returns(IVault);
    function _getNumPledgersSofar() internal virtual view returns(uint);
    function getPlatformCutPromils() public virtual view returns(uint);
    function _getPlatformAddress() internal virtual view returns(address);
    function _projectNotCompleted() internal virtual view returns(bool);


    function _setMilestones( Milestone[] memory newMilestones) internal {
        delete milestoneArr; // remove prior content
        unchecked {
            for (uint i = 0; i < newMilestones.length; i++) {
                milestoneArr.push( newMilestones[i]);
            }
        }
    }

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

    function projectHasFailed() external view returns(bool);

    function getTeamBalanceInVault() external view returns(uint);

    function getPledgersBalanceInVault() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IPlatform {
    function onReceivePaymentTokens( address paymentTokenAddress_, uint platformCut_) external;
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
    uint fundingPTokTarget;
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


library Sanitizer {

    //@gilad: allow configuration?
    uint constant public MIN_MILESTONE_INTERVAL = 1 days;
    uint constant public MAX_MILESTONE_INTERVAL = 365 days;


    error IllegalMilestoneDueDate( uint index, uint32 dueDate, uint timestamp);

    error NoMilestoneApproverWasSet(uint index);

    error AmbiguousMilestoneApprover(uint index, address externalApprover, uint fundingPTokTarget, uint numPledgers);


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
        bool approverIsSet_ = (approver_.externalApprover != address(0) || approver_.fundingPTokTarget > 0 || approver_.targetNumPledgers > 0);
        if ( !approverIsSet_) {
            revert NoMilestoneApproverWasSet(index);
        }
        bool extApproverUnique = (approver_.externalApprover == address(0) || (approver_.fundingPTokTarget == 0 && approver_.targetNumPledgers == 0));
        bool fundingTargetUnique = (approver_.fundingPTokTarget == 0  || (approver_.externalApprover == address(0) && approver_.targetNumPledgers == 0));
        bool numPledgersUnique = (approver_.targetNumPledgers == 0  || (approver_.externalApprover == address(0) && approver_.fundingPTokTarget == 0));

        if ( !extApproverUnique || !fundingTargetUnique || !numPledgersUnique) {
            revert AmbiguousMilestoneApprover(index, approver_.externalApprover, approver_.fundingPTokTarget, approver_.targetNumPledgers);
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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
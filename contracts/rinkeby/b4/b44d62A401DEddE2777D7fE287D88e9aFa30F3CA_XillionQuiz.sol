// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";
import "./libraries/XillionIDOStructs.sol";
import "./interfaces/IXillionModerators.sol";
import "./utils/OwnablePausable.sol";
import "./XillionIDO.sol";
import "./libraries/SignerVerification.sol";


/**
 * @title Factory+Master/Slave Patterns contract to create a Voting
 */
contract XillionQuiz is Ownable, ReentrancyGuard {

     using SafeERC20 for IERC20;

    /* ------------------------------------------------------------ VARIABLES ----------------------------------------------------------- */

    /**
     * @notice address of moderators contract
    */
    address public xillionModeratorsAddress;

    /**
     * @notice address of Signer
    */
    address public signerAddress;

    /**
     * @notice List of all Quizes created
     */
    mapping(uint256 => Quiz) public idToQuiz;


    /**
     * @notice Is user claimed in corresponding Quiz
     */
    mapping(uint256 => mapping(address => bool)) public isUserClaimedToQuiz;

     /**
     * @notice Mulitplier value by reward role
     * @dev Delete public idetifier
     */
    mapping(RewardRole => uint256) public rewardRoleToMultiplier;


    /**
     * @notice Amount of all quizes
     */
    uint256 public quizSupply;


    /**
     * @title Details about Quiz
     * @property quizId Id of the quiz
     * @property quizTokenAddess is an address of Quiz token
     * @property tokensRewardAmount is an amount of tokens as quiz reward
     * @property tokensAmountPerWallet is an amount of quiz tokens for claim per wallet
     * @property currentTokensAmount is amount of tokens on corresponding quiz
     * @property quizState is state of quiz
     */
    struct Quiz {
        uint256 quizId;
        address quizTokenAddess;
        uint256 tokensRewardAmount;
        uint256 tokensAmountPerWallet;
        uint256 currentTokensAmount;
        QuizState quizState;
    }

    /**
     * @title State of the Quiz
     * @property NotStarted Quiz is created, but not started;
     * @property Active Quiz is in active phase;
     * @property Done Quiz is completed;
     */
    enum QuizState {NotStarted, Active, Done}

    /**
     * @title State of the Quiz
     * @property Base ...
     * @property Advanced ...;
     * @property Epic...;
     */
    enum RewardRole {Base, Advanced, Epic}

    /* ----------------------------------------------------------- CONSTRUCTOR ---------------------------------------------------------- */


     /**
     * @notice Creates the XillionQuiz
     * @param xillionModeratorsAddress_ Address of moderators contract,
     * @param signerAddress_ Address of signer,
     */
    constructor(address xillionModeratorsAddress_, address signerAddress_) {
        require(xillionModeratorsAddress_ != address(0), "Invalid moderators contract address");
        require(signerAddress_ != address(0), "Signer can't be zero address");
        signerAddress = signerAddress_;
        xillionModeratorsAddress = xillionModeratorsAddress_;
        rewardRoleToMultiplier[RewardRole.Base] = 1;
        rewardRoleToMultiplier[RewardRole.Advanced] = 2;
        rewardRoleToMultiplier[RewardRole.Epic] = 3;

    }

     modifier onlyModerator() { // Modifier
        require(
             IXillionModerators(xillionModeratorsAddress).isUserModerator(msg.sender),
            "Only moderator can call this"
        );
        _;
    }

    /* --------------------------------------------------------- MAIN ACTIVITIES -------------------------------------------------------- */

    /**
     * @notice Adds votes to corresponding voting
     * @param quizTokenAddess Id of voting user wants to vote
     * @param tokensRewardAmount  TokensRewardAmount is an amount of tokens as quiz reward
     * @param tokensAmountPerWallet is an amount of quiz tokens for claim per wallet
     */
    function createQuiz(address quizTokenAddess, uint256 tokensRewardAmount, uint256 tokensAmountPerWallet) external {
        //   require(quizTokenAddess != address(0), "Quiz token address can not be 0");
          require(tokensRewardAmount > 0, "tokens reward amount can't be 0");
          require(tokensAmountPerWallet > 0, "tokensAmountPerWallet can't be 0");

          // create new Quiz;

        Quiz memory newQuiz = Quiz({
            quizId:quizSupply,
            quizTokenAddess:quizTokenAddess,
            tokensRewardAmount:tokensRewardAmount,
            tokensAmountPerWallet:tokensAmountPerWallet,
            currentTokensAmount:0,
            quizState:QuizState.NotStarted
        });

        // emit event
        idToQuiz[quizSupply] = newQuiz;

        emit QuizCreated(
           newQuiz.quizId,
           newQuiz.quizTokenAddess,
           newQuiz.tokensRewardAmount,
           newQuiz.tokensAmountPerWallet,
           newQuiz.currentTokensAmount,
           newQuiz.quizState
        );

        quizSupply++;
    }

    /* ------------------------------------------------------------- MUTATORS ----------------------------------------------------------- */


     /**
     * @notice Changes price of one vote to one XIL
     * @param quizId_ id of quiz to transfer
     * @param tokensAmount_ amount of tokens to transfer
     */
    function transferTokensToQuiz(uint256 quizId_, uint256 tokensAmount_) public payable {
        Quiz memory quiz_ = idToQuiz[quizId_];
         
        //  Transfer ERC20 token if quiz consists ERC20 token as currency
        if(quiz_.quizTokenAddess != address(0)){
           IERC20 quizToken = IERC20(quiz_.quizTokenAddess);
           require(quizToken.balanceOf(msg.sender) >= tokensAmount_, "You don't have enough tokens");
           quiz_.currentTokensAmount += tokensAmount_;
           quizToken.safeTransferFrom(msg.sender, address(this), tokensAmount_);
        }else{
            quiz_.currentTokensAmount += msg.value;
        }

        if(quiz_.currentTokensAmount >= quiz_.tokensRewardAmount){
            quiz_.quizState = QuizState.Active;
            emit QuizStateChanged(quizId_, quiz_.quizState);
        }
        idToQuiz[quizId_] = quiz_;
    }


    /**
     * @notice claims tokens from quiz
     * @param quizId_ quizId
     * @param stakingStatus_ signature
     * @param signature_ signature
     */
    function claim(uint256 quizId_, uint256 stakingStatus_, bytes calldata signature_) external nonReentrant{

        Quiz memory quiz_ = idToQuiz[quizId_];

        require(quiz_.quizState == QuizState.Active, "only active state");
        
        require(!isUserClaimedToQuiz[quizId_][msg.sender], "You can claim only once!");

        string memory concatenatedParams_ = SignerVerification.concatParams(quizId_, msg.sender, stakingStatus_);

        bool isVerified = SignerVerification.isMessageVerified(signerAddress, signature_, concatenatedParams_);

        require(isVerified, "Invalid signature");

        console.log("Multiplier", rewardRoleToMultiplier[RewardRole(stakingStatus_)]);

        uint256 rewardAmount = quiz_.tokensAmountPerWallet * rewardRoleToMultiplier[RewardRole(stakingStatus_)];

        rewardAmount = quiz_.currentTokensAmount < rewardAmount ? quiz_.currentTokensAmount : rewardAmount;

        quiz_.currentTokensAmount -= rewardAmount;

        if(quiz_.quizTokenAddess != address(0)){

            IERC20 quizToken = IERC20(quiz_.quizTokenAddess);
            console.log("claim caller", address(this));
            quizToken.safeTransfer(msg.sender, rewardAmount);
        }else{
            (bool success, ) = msg.sender.call{value:rewardAmount}("");

            require(success, "Unsuccessful reward MATIC transfer!");
        }
        
        isUserClaimedToQuiz[quizId_][msg.sender] = true;
        
        emit Claimed(msg.sender, rewardAmount, quizId_);

        if(quiz_.currentTokensAmount == 0){
            quiz_.quizState = QuizState.Done;
            emit QuizStateChanged(quizId_, QuizState.Done);
        }

        idToQuiz[quizId_] = quiz_;
    }

     /**
     * @notice changes multiplier depends on reward role
     * @param baseRoleMultiplier_ Base...
     * @param advancedRoleMultiplier_ Advanced...
     * @param epicRoleMultiplier_ Epic...
     */
    function changeRewardRoleMultipliers(uint256 baseRoleMultiplier_, uint256 advancedRoleMultiplier_, uint256 epicRoleMultiplier_) external onlyOwner {
       rewardRoleToMultiplier[RewardRole.Base] = baseRoleMultiplier_;
       rewardRoleToMultiplier[RewardRole.Advanced] = advancedRoleMultiplier_;
       rewardRoleToMultiplier[RewardRole.Epic] = epicRoleMultiplier_;
    }

 /**
     * @notice changes moderators smart contract address
     * @param moderatorContractAddress_ Base...
     */
    function setModeratorAddress(address moderatorContractAddress_) external onlyOwner {
        xillionModeratorsAddress = moderatorContractAddress_;
    }

    /* --------------------------------------------------------- VIEWS (PUBLIC) --------------------------------------------------------- */

    /* -------------------------------------------------------------- EVENTS ------------------------------------------------------------ */

     /**
     * @notice Emitted when user has claimed
     * @param userAddress_ address of sender
     * @param tokenAmount_ how much tokens user claimed
     * @param quizId_ id of quiz
     */
    event Claimed(
        address userAddress_,
        uint256 tokenAmount_,
        uint256 quizId_
    );

    /**
     * @notice Emitted when IDO state change
     */
    event QuizStateChanged(
        uint256 quizId,
        QuizState newQuizState
    );


     /**
     * @notice Emitted when user has claimed

     * @param quizId Id of voting user wants to vote
     * @param quizTokenAddess is an address of Quiz token
     * @param tokensRewardAmount  TokensRewardAmount is an amount of tokens as quiz reward
     * @param tokensAmountPerWallet is an amount of quiz tokens for claim per wallet
     * @param currentTokensAmount is amount of tokens on corresponding quiz
     * @param quizState is state of quiz
     */
    event QuizCreated(
        uint256 quizId,
        address quizTokenAddess,
        uint256 tokensRewardAmount,
        uint256 tokensAmountPerWallet,
        uint256 currentTokensAmount,
        QuizState quizState
    );

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "./XillionIDOCommon.sol";

/**
 * @title Contract for an IDO
 */
contract XillionIDO is XillionIDOCommon {


    /* ----------------------------------------------------------- CONSTRUCTOR ---------------------------------------------------------- */
     
    /**
     * @notice Called on creation of the IDO contract
     * @param factoryAddress_ Address of the IDO Factory that created this IDO
     * @param initialDetails_ General Details about an IDO
     */

    constructor(
        address factoryAddress_,
        XillionIDOStructs.InitialDetails memory initialDetails_
    ) {

        // check "immutable data" is valid and set it
        require(initialDetails_.numberOfPoolTokens > 0, "Invalid amount");
        idoValueCap = initialDetails_.idoValueCap;
        numberOfPoolTokens = initialDetails_.numberOfPoolTokens;
         
         //determine Xil token Address
         xillTokenAddress = initialDetails_.xilTokenAddress;
        // store factory
        require(factoryAddress_ != address(0), "Invalid factory");
        factory = XillionIDOFactory(factoryAddress_);
        // votingFactory = XillionVotingFactory(votingFactoryAddress_);

        // BEP20TokenInit
         if(initialDetails_.bep20IdoTokenDetails.BEP20IdoTokenAddress != address(0)){
               maxInvestmentBEP20AmountPerInvestor = initialDetails_.bep20IdoTokenDetails.maxInvestmentBEP20AmountPerInvestor;
               BEP20IdoTokenAddress = initialDetails_.bep20IdoTokenDetails.BEP20IdoTokenAddress;
               BEP20IdoValueCap= initialDetails_.bep20IdoTokenDetails.BEP20IdoValueCap;
               minInvestmentPercentOfBEP20ForIDOCompletion = initialDetails_.bep20IdoTokenDetails.minInvestmentPercentOfBEP20ForIDOCompletion;   
         }

        // mint tokens
        require(bytes(initialDetails_.poolTokenName).length > 0 && bytes(initialDetails_.poolTokenSymbol).length > 0, "Invalid token details");
        _poolToken = new XillionPoolToken(initialDetails_.poolTokenName, initialDetails_.poolTokenSymbol, initialDetails_.numberOfPoolTokens, address(this));
        emit PoolTokenMinted(address(_poolToken));
    }

    /**
     * @notice Initialises an IDO with all required values
     * @dev This cannot be called from the constructor because it uses delegation, whereas the contract does not have a state yet within the constructor
     * @param investmentDetails_ Investment Details about an IDO
     * @param poolTokenSharePercentages_ Share of the Pool Tokens for different actors in %
     * @param walletAddresses_ Critical actors' wallet address
     * @param dates_ Provisioned dates of the IDO
     */
    function initialise(
        XillionIDOStructs.InvestmentDetails memory investmentDetails_,
        XillionIDOStructs.PoolTokenSharePercentage memory poolTokenSharePercentages_,
        XillionIDOStructs.WalletAddressV2 calldata walletAddresses_,
        XillionIDOStructs.IDODates memory dates_
    ) external onlyOwner {

        // check and set allocation tiers
        // setAllocationTiers(allocationTiers_);

        // check and set investment details
        setInvestmentDetails(investmentDetails_);

        // check and set pool token share percentages
        setPoolTokenSharePercentages(poolTokenSharePercentages_);

        // // check and set pool token vesting periods
        // // setPoolTokenVestingDays(poolTokenVestingDays_);

        // // check and set critical wallet addresses
        setWalletAddresses(walletAddresses_);

        setAllocationStartDate(dates_.allocationStartDate);
        setAllocationEndDate(dates_.allocationEndDate);
        setSwapStartDate(dates_.swapStartDate);
        setSwapEndDate(dates_.swapEndDate);
    }

    /* --------------------------------------------------------- MAIN ACTIVITIES -------------------------------------------------------- */

    /**
     * @notice Returns the sender's allocation size
     * @dev It is the max between the staking allocation and the manual allocation
     * @return The sender's allocation size
     */
    function getAllocationSize() external view returns (uint256) {
        return _stakingAllocationSizeList[_msgSender()];
    }

    /**
     * @notice Creates or updates a sender's allocation size. An existing allocation size can only be increased, not decreased.
     */
    function joinOrRecalculateAllocation() external {
        delegateFunctionCallToMaster("joinOrRecalculateAllocation()");
    }

    /**
     * @notice Lets the sender invest into the IDO
     */
    function invest() external payable {
        delegateFunctionCallToMaster("invest()");
    }
    

     /**
     * @notice Lets the sender invest BEP20 token into the IDO
     */
    function investBEP20(uint256 _tokenAmount) external{
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("investBEP20(uint256)", _tokenAmount));
        revertOnDelegateCallFailure(success, result);
    }


    /**
     * @notice Ends the Swap phase – it will either complete successfully or fail depending on the investment and success threshold
     */
    function finish() external {
        onlyModerator(msg.sender);
        delegateFunctionCallToMaster("finish()");
    }

    /**
     * @notice Kills the IDO (i.e. refunds it) regardless of the investment and success threshold
     */
    function kill() external {
        // onlyModerator(msg.sender);
        delegateFunctionCallToMaster("kill()");
    }

    /**
     * @notice Lets investors, the curator, Xillion and Little Phil claim their Pool Tokens after the vesting period
     */
    function claimPoolTokens() external {
        delegateFunctionCallToMaster("claimPoolTokens()");
    }

    /**
     * @notice Refunds invested Chain Currency if the IDO was refunded
     */
    function claimRefundedInvestment() external {
        delegateFunctionCallToMaster("claimRefundedInvestment()");
    }
    /**
     * @notice Transfers the invested Chain Currency amount to the Chain Currency recipient once the sale is closed
     */
    function claimTotalInvestedAmount() external {
        delegateFunctionCallToMaster("claimTotalInvestedAmount()");
    }

    function delegateFunctionCallToMaster(string memory name) internal {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature(name));
        revertOnDelegateCallFailure(success, result);
    }

    /* ------------------------------------------------------------- MUTATORS ----------------------------------------------------------- */
    /**
     * @notice Sets the Pool Token share percentages
     * @param poolTokenSharePercentages_ New Pool Token share percentages
     */
    function setPoolTokenSharePercentages(XillionIDOStructs.PoolTokenSharePercentage memory poolTokenSharePercentages_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setPoolTokenSharePercentages((uint256,uint256,uint256,uint256))", poolTokenSharePercentages_));
        revertOnDelegateCallFailure(success, result);
    }

    // /**
    //  * @notice Sets the Pool Token share percentages
    //  * @param _stakeAmount Amount for potential stake
    //  * @param _duration Stake duration
    //  */
    // function calculateAllocation(uint256 _stakeAmount, uint256 _duration) public {
    //     (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("calculateAllocation(uint256,uint256)", _stakeAmount, _duration));
    //     revertOnDelegateCallFailure(success, result);
    // }

    /**
    //  * @notice Sets the Pool Token vesting periods in days
    //  * @param poolTokenVestingDays_ New Pool Token vesting periods in days
    //  */
    // function setPoolTokenVestingDays(XillionIDOStructs.PoolTokenVestingDays memory poolTokenVestingDays_) public {
    //     (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setPoolTokenVestingDays((uint256,uint256,uint256,uint256))", poolTokenVestingDays_));
    //     revertOnDelegateCallFailure(success, result);
    // }

    /**
     * @notice Sets the critical wallet addresses
     * @param walletAddresses_ New critical wallet addresses
     */
    function setWalletAddresses(XillionIDOStructs.WalletAddressV2 memory walletAddresses_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setWalletAddresses((address,address,address))", walletAddresses_));
        revertOnDelegateCallFailure(success, result);
    }

     /**
     * @notice Sets the curator wallet address
     * @param walletAddress_ New curator wallet addresses
     */
     function setCuratorAddress(address walletAddress_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setCuratorAddress(address)", walletAddress_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the allocation start date
     * @param allocationStartDate_ New allocation start date
     */
    function setAllocationStartDate(uint256 allocationStartDate_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setAllocationStartDate(uint256)", allocationStartDate_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the allocation end date
     * @param allocationEndDate_ New allocation end date
     */
    function setAllocationEndDate(uint256 allocationEndDate_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setAllocationEndDate(uint256)", allocationEndDate_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the swap start date
     * @param swapStartDate_ New swap start date
     */
    function setSwapStartDate(uint256 swapStartDate_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setSwapStartDate(uint256)", swapStartDate_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the swap end date
     * @param swapEndDate_ New swap end date
     */
    function setSwapEndDate(uint256 swapEndDate_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setSwapEndDate(uint256)", swapEndDate_));
        revertOnDelegateCallFailure(success, result);
    }

    // /**
    //  * @notice Sets the allocation tiers and check they are sorted from lowest to highest tier
    //  * @param allocationTiers_ The new allocation tiers
    //  */
    // function setAllocationTiers(XillionIDOStructs.AllocationTier[] memory allocationTiers_) public {
    //     (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setAllocationTiers((uint256,uint256)[])", allocationTiers_));
    //     revertOnDelegateCallFailure(success, result);
    // }

    /**
     * @notice Sets the investment details
     * @param investmentDetails_ New investment details
     */
    function setInvestmentDetails(XillionIDOStructs.InvestmentDetails memory investmentDetails_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setInvestmentDetails((uint256,uint256,uint256,address))", investmentDetails_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the investment details
     * @param investmentBEP20Details_ New investmentBEP20 details
     */
    function setInvestmentBEP20Details(XillionIDOStructs.BEP20IDOTokenDetails memory investmentBEP20Details_) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("setInvestmentBEP20Details((uint256,address,uint256,uint256))", investmentBEP20Details_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Sets the ido State
     * @notice Creates new voting for corresponding IDO
     * @param targetVotes_ Target vote amount for voting
     * @param minVotingValue_ Minimum number of votes for successful voting
     * @param votingStartTimestamp_ Timestamp of voting start
     * @param votingEndTimestamp_ Timestamp of voting end
     */
    function confirmIdo(uint256 targetVotes_, uint256 minVotingValue_, uint256 votingStartTimestamp_, uint256 votingEndTimestamp_) public {
        require(_state == IDOState.Unconfirmed, "Incorrect stage");
        createVoting(targetVotes_, minVotingValue_, votingStartTimestamp_, votingEndTimestamp_);
        _state = IDOState.Confirmed;
        emit IDOStateUpdated(IDOState.Confirmed);
    }

    /**
     * @notice Updates the list of manually whitelisted accounts and their arbitrary allocation size
     * This only updates a subset of entries (including removing by setting 0), it does not override the whole list
     * @param manualWhitelist_ The list of accounts that are manually whitelisted
     * @param manualAllocationSizeList_ The list of allocation size manually set to the whitelisted accounts
     */
    function updateManualAllocationSizeList(
        address[] calldata manualWhitelist_,
        uint256[] calldata manualAllocationSizeList_
    ) public {
        (bool success, bytes memory result) = getMasterIDOAddress().delegatecall(abi.encodeWithSignature("updateManualAllocationSizeList(address[],uint256[])", manualWhitelist_, manualAllocationSizeList_));
        revertOnDelegateCallFailure(success, result);
    }

    /**
     * @notice Creates new voting for corresponding IDO
     * @param targetVotes_ Target vote amount for voting
     * @param minVotingValue_ Minimum number of votes for successful voting
     * @param votingStartTimestamp_ Timestamp of voting start
     * @param votingEndTimestamp_ Timestamp of voting end
     */ 
    function createVoting(uint256 targetVotes_, uint256 minVotingValue_, uint256 votingStartTimestamp_, uint256 votingEndTimestamp_) public {
         onlyModerator(msg.sender);
         votingId = factory.createVotingForIDO(targetVotes_, minVotingValue_, votingStartTimestamp_, votingEndTimestamp_);
    }

    /* --------------------------------------------------------- VIEWS (PUBLIC) --------------------------------------------------------- */

    /**
     * @return The IDO's state value
     * @dev The _state variable is either Unconfirmed, Voiting, Claim, Refund or Closed. For the former, we look at the dates to determine whether it should
     *  actually be Allocation or Swap
     */
    function getIDOState() external view returns (IDOState) {
        uint256 votingState = factory.getStateOfVoting(votingId);
        if(_state == IDOState.Unconfirmed){
            return IDOState.Unconfirmed;
        }else if(_state == IDOState.Confirmed){
            if(VotingState(votingState) == VotingState.Preparing){
                return IDOState.Confirmed;
            }else if(VotingState(votingState) == VotingState.Processing){
                return IDOState.Voting;
            }else if(VotingState(votingState) == VotingState.Successed){
                
                if(block.timestamp < allocationStartDate){
                    return IDOState.Voting;
                }
                if(allocationStartDate > 0 && block.timestamp >= allocationStartDate && block.timestamp < swapStartDate) {
                    return IDOState.Allocation;
                }
                if (swapStartDate > 0 && block.timestamp >= swapStartDate) {
                    return IDOState.Swap;
                }
            }else if(VotingState(votingState) == VotingState.Failed){
               return IDOState.Closed;
            }
        }else if(_state == IDOState.Refund || _state == IDOState.Claim || _state == IDOState.Closed){
            return _state;
        }
    }

    /**
     * @return The address of the Pool Token
     */
    function getPoolTokenAddress() external view returns (address) {
        return address(_poolToken);
    }

    // /**
    //  * @return The amount of allocation tiers for this IDO
    //  */
    // function getAllocationTiersCount() external view returns (uint256) {
    //     return _allocationTiers.length;
    // }

    // /**
    //  * @param index_ Index of the allocation tier to retrieve
    //  * @return The requested allocation tier
    //  */
    // function getAllocationTier(uint256 index_) external view returns (uint256, uint256) {
    //     return (_allocationTiers[index_].minXILAmount, _allocationTiers[index_].allocationSizeMultiplier);
    // }

    // /**
    //  * @return The amount of investors
    //  */
    function getInvestorsCount() external view returns (uint256) {
        return _investors.length;
    }

    /**
     * @param index_ Index of the investor
     * @return The address of an investor
     */
    function getInvestorAddress(uint256 index_) external view returns (address) {
        return _investors[index_];
    }

    /**
     * @param account_ Address of the investor
     * @return The investment size for an investor
     */
    function getInvestmentSize(address account_) external view returns (uint256) {
        return _investments[account_];
    }

    /**
     * @return The address of this IDO's staking contract
     */
    function getStakingContractAddress() external view returns (address) {
        return address(_stakingContract);
    }

    /* --------------------------------------------------------- VIEWS (OWNER) ---------------------------------------------------------- */

    // /**
    //  * @return This IDO's critical wallet addresses
    //  */
    // function getCriticalWalletAddresses() external view onlyOwner returns (address, address, address, address) {
    //     return (
    //     _chainCurrencyRecipientWalletAddress,
    //     _curatorWalletAddress,
    //     _xillionWalletAddress,
    //     _littlePhilWalletAddress
    //     );
    // }

    /**
     * @param account_ Address of the manually whitelisted account
     * @return The allocation size for a manually whitelisted address
     */
    function getManualAllocationSize(address account_) external view onlyOwner returns (uint256) {
        return _manualAllocationSizeList[account_];
    }


    /* -------------------------------------------------------------- UTILS ------------------------------------------------------------- */

    /**
     * @notice Helper to revert if a delegate calls failed in the callee
     */
    function revertOnDelegateCallFailure(bool success, bytes memory) private pure {
        if (!success) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
    
    
    /**
     * @param userAddress_ Address of the manually whitelisted account
     */
    function onlyModerator(address userAddress_) internal returns(bool){
        require(factory.checkIsUserModerator(userAddress_), "Caller is not moderator");
    }

    /**
     * @return the address of the master IDO, that is used to delegate calls for business logic
     */
    function getMasterIDOAddress() private view returns (address) {
        return factory.masterIDOAddress();
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/**
 * @title Shared code for XillionIDO structs
 */
library XillionIDOStructs {

    /**
     * @title Allocation Tiers that define potential investors' allocation size
     * @dev It is defined as staking range mins and multipliers
     * @property minXILAmount Bottom range of the allocation tier (i.e. from x onwards)
     * @property allocationSizeMultiplier The multiplier that will be applied to the allocation size, initially calculated using the XIL -> Chain Currency ratio
     */
    struct AllocationTier {
        uint256 minXILAmount;
        uint256 allocationSizeMultiplier;
    }

    /**
     * @title Initial Details about an IDO
     * @property idoValueCap Max amount of Chain Currency the IDO can accept
     * @property numberOfPoolTokens Amount of Pool Tokens minted at the start of the IDO
     * @property poolTokenName Name of the Pool Token
     * @property poolTokenSymbol Symbol of the Pool Token
     * @property contractOwner Designated owner of the contract
     * @property bep20IdoTokenDetails IDO investment details in BEP20 token
     */
    struct InitialDetails {
        uint256 idoValueCap;
        uint256 numberOfPoolTokens;
        string poolTokenName;
        string poolTokenSymbol;
        address contractOwner;
        BEP20IDOTokenDetails bep20IdoTokenDetails;
        address xilTokenAddress;
    }

    /**
     * @title Initial Details about an IDO
     * @property idoValueCap Max amount of Chain Currency the IDO can accept
     * @property numberOfPoolTokens Amount of Pool Tokens minted at the start of the IDO
     * @property poolTokenName Name of the Pool Token
     * @property poolTokenSymbol Symbol of the Pool Token
     * @property contractOwner Designated owner of the contract
     */
    struct InitialDetailsV1 {
        uint256 idoValueCap;
        uint256 numberOfPoolTokens;
        string poolTokenName;
        string poolTokenSymbol;
        address contractOwner;
    }

    /**
     * @title Initial dates of the IDO
     * @property allocationStartDate Allocation start date
     * @property allocationEndDate Allocation end date
     * @property swapStartDate Swap start date
     * @property swapEndDate Swap end date
     */
    struct IDODates {
        uint256 allocationStartDate;
        uint256 allocationEndDate;
        uint256 swapStartDate;
        uint256 swapEndDate;
    }

    /**
     * @title Investment Details about an IDO
     * @property maxInvestmentAmountPerInvestor Max investment amount per investor, in the chain currency's smallest denomination
     * @property minInvestmentPercentForIDOCompletion Min % investment for IDO successful completion
     * @property minStakingDays Minimum staking duration
     * @property stakingContractAddress Address of the XIL Staking contract for IDO allocation
     */
    struct InvestmentDetails {
        uint256 maxInvestmentAmountPerInvestor;
        uint256 minInvestmentPercentForIDOCompletion;
        uint256 minStakingDays;
        address stakingContractAddress;
    }

    /**
     * @title Investment BEP20 Details about an IDO
     * @property maxInvestmentBEP20AmountPerInvestor Max investment amount per investor, in the BEP20 token's smallest denomination
     * @property BEP20IdoTokenAddress address of BEP20 token for investments
     * @property BEP20IdoValueCap Max amount of BEP20 the IDO can accept
     * @property minInvestmentPercentForIDOCompletion Min % investment in BEP20 for IDO successful completion
     */
    struct BEP20IDOTokenDetails {
        uint256 maxInvestmentBEP20AmountPerInvestor;
        address BEP20IdoTokenAddress;
        uint256 BEP20IdoValueCap;
        uint256 minInvestmentPercentOfBEP20ForIDOCompletion;
    }

    /**
     * @title Share of the Pool Tokens for different actors in %
     * @property investors Percentage of the Pool Tokens going to investors
     * @property curator Percentage of the Pool Tokens going to the curator
     * @property xillion Percentage of the Pool Tokens going to Xillion
     * @property littlePhil Percentage of the Pool Tokens going to Little Phil
     */
    struct PoolTokenSharePercentage {
        uint256 investors;
        uint256 curator;
        uint256 xillion;
        uint256 littlePhil;
    }

    /**
     * @title Vesting duration of the Pool Tokens for different actors in days
     * @property investors Vesting duration of the Pool Tokens going to investors
     * @property curator Vesting duration of the Pool Tokens going to the curator
     * @property xillion Vesting duration of the Pool Tokens going to Xillion
     * @property littlePhil Vesting duration of the Pool Tokens going to Little Phil
     */
    struct PoolTokenVestingDays {
        uint256 investors;
        uint256 curator;
        uint256 xillion;
        uint256 littlePhil;
    }

    /**
     * @title Critical actors' wallet address
     * @property chainCurrencyRecipient Wallet address of the Chain Currency recipient
     * @property curator Wallet address of the curator
     * @property xillion Wallet address of Xillion
     * @property littlePhil Wallet address of Little Phil
     */
    struct WalletAddress {
        address chainCurrencyRecipient;
        address curator;
        address xillion;
        address littlePhil;
    }

     /**
     * @title Critical actors' wallet address
     * @property curator Wallet address of the curator
     * @property xillion Wallet address of Xillion
     * @property littlePhil Wallet address of Little Phil
     */
    struct WalletAddressV2 {
        address curator;
        address xillion;
        address littlePhil;
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


/**
 * @title Contract with an owner that can be paused/unpaused by the owner
 */
contract OwnablePausable is Ownable, Pausable {

    /**
     * @notice Allows an admin to pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Allows an admin to unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface IXillionModerators {
	/**
	 * @dev Returns bool value if user is moderator.
	 */
	function isUserModerator(address account) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Strings.sol';

library SignerVerification {
    function isMessageVerified(
        address signer,
        bytes calldata signature,
        string calldata concatenatedParams
    ) external pure returns (bool) {
        return recoverSigner(getPrefixedHashMessage(concatenatedParams), signature) == signer;
    }

    function getSigner(bytes calldata signature, string calldata concatenatedParams) external pure returns (address) {
        return recoverSigner(getPrefixedHashMessage(concatenatedParams), signature);
    }

    function getPrefixedHashMessage(string calldata concatenatedParams) internal pure returns (bytes32) {
        uint256 messageLength = bytes(concatenatedParams).length;
        bytes memory prefix = abi.encodePacked('\x19Ethereum Signed Message:\n', Strings.toString(messageLength));
        return keccak256(abi.encodePacked(prefix, concatenatedParams));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, 'invalid signature length');

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function concatParams(
		uint256 _quizId,
		address _userAddress,
		uint256 _quizStatus
	) external returns (string memory) {
		return
			string(
				abi.encodePacked(
					Strings.toString(_quizId),
					_addressToString(_userAddress),
					Strings.toString(_quizStatus)
				)
			);
	}

	function _addressToString(address _addr) public pure returns (string memory) {
		bytes memory addressBytes = abi.encodePacked(_addr);

		bytes memory stringBytes = new bytes(42);

		stringBytes[0] = "0";
		stringBytes[1] = "x";

		for (uint256 i = 0; i < 20; i++) {
			uint8 leftValue = uint8(addressBytes[i]) / 16;
			uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

			bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
			bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

			stringBytes[2 * i + 3] = rightChar;
			stringBytes[2 * i + 2] = leftChar;
		}

		return string(stringBytes);
	}

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./libraries/XillionIDOStructs.sol";
import "./utils/OwnablePausable.sol";
import "./XillionAccessStaking.sol";
import "./XillionIDOFactory.sol";
import "./XillionPoolToken.sol";


/**
 * @title Common code for IDOs and Master IDO
 */
contract XillionIDOCommon is OwnablePausable, ReentrancyGuard {

    /* ------------------------------------------------------------ VARIABLES ----------------------------------------------------------- */

    /**
     * @notice IDO Factory that created this IDO
     */
    XillionIDOFactory public factory;

    /**
     * @notice Address of xil contract
     */
    address public xillTokenAddress;

    /**
     * @notice Current status of the IDO
     */
    IDOState internal _state = IDOState.Unconfirmed;

    /**
     * @notice Max amount of Chain Currency the IDO can accept
     */
    uint256 public idoValueCap;

    /**
     * @notice Max amount of BEP20 token the IDO can accept
     */
    uint256 public BEP20IdoValueCap;

    /**
     * @notice Address of BEP20 token for IDO investment: XIL/BUSD
     */
    address public BEP20IdoTokenAddress;

    /**
     * @notice Amount of Pool Tokens minted at the start of the IDO
     */
    uint256 public numberOfPoolTokens;

    /**
     * @notice Allocation start date
     */
    uint256 public allocationStartDate;

    /**
     * @notice Allocation end date
     */
    uint256 public allocationEndDate;

    /**
     * @notice Swap start date
     */
    uint256 public swapStartDate;

    /**
     * @notice Swap end date
     */
    uint256 public swapEndDate;

    /**
     * @notice Max investment amount per investor, in the chain currency's smallest denomination
     */
    uint256 public maxInvestmentAmountPerInvestor;

    /**
     * @notice Max investment amount per investor, in the BEP20 token smallest denomination
     */
    uint256 public maxInvestmentBEP20AmountPerInvestor;

    /**
     * @notice Min % investment for IDO successful completion
     */
    uint256 public minInvestmentPercentForIDOCompletion;

    /**
     * @notice Min % investment of BEP20 for IDO successful completion
     */
    uint256 public minInvestmentPercentOfBEP20ForIDOCompletion;

    /**
     * @notice Minimum staking duration
     */
    uint256 public minStakingDays;

    /**
     * @notice XIL Staking contract for IDO allocation
     */
    XillionAccessStaking internal _stakingContract;

    /**
     * @notice Share of the Pool Tokens that will be distributed to the IDO participants in %
     */
    uint256 public investorsPoolTokenSharePercent;

    /**
     * @notice Share of the Pool Tokens that will be distributed to the curator in %
     */
    uint256 public curatorPoolTokenSharePercent;

    /**
     * @notice Share of the Pool Tokens that will be distributed to Xillion in %
     */
    uint256 public xillionPoolTokenSharePercent;

    /**
     * @notice Share of the Pool Tokens that will be distributed to Little Phil in %
     */
    uint256 public littlePhilPoolTokenSharePercent;

    // /**
    //  * @notice Wallet address of the Chain Currency recipient
    //  */
    // address payable internal _chainCurrencyRecipientWalletAddress;

    /**
     * @notice Wallet address of the curator
     */
    address payable internal _curatorWalletAddress;

    /**
     * @notice Wallet address of Xillion
     */
    address internal _xillionWalletAddress;

    /**
     * @notice Wallet address of Little Phil
     */
    address internal _littlePhilWalletAddress;

    // /**
    //  * @notice Allocation rules/tiers
    //  * @dev (staking range mins and multipliers)
    //  */
    // XillionIDOStructs.AllocationTier[] internal _allocationTiers;

    /**
     * @notice Manual "whitelist"
     * @dev (address -> allocation size in Chain Currency)
     */
    mapping(address => uint256) internal _manualAllocationSizeList;

    /**
     * @notice The ERC20 Pool Token created by the IDO that will be used to interact with the corresponding Pool of NFTs
     */
    XillionPoolToken internal _poolToken;

    /**
     * @notice List of addresses that chose to join the IDO through the staking program
     */
    address[] internal _stakers;

    /**
     * @notice Staking "whitelist"
     * @dev (address -> allocation size in Chain Currency)
     */
    mapping(address => uint256) internal _stakingAllocationSizeList;

    /**
     * @notice List of investors (people who sent Chain Currency to this contract)
     */
    address[] internal _investors;

    /**
     * @notice List of investors (people who sent BEP20 to this contract)
     */
    address[] public _invesotrsOfBEP20;

    /**
     * @notice List of total investments into this contract
     * @dev (wallet address => total Chain Currency amount invested)
     */
    mapping(address => uint256) internal _investments;

    /**
     * @notice List of total investments into this contract in BEP20 token
     * @dev (token address => total BEP20 token amount invested)
     */
    mapping(address => uint256) public _investmentsInBEP20;

    /**
     * @notice Amount of Chain Currency sent into this contract
     */
    uint256 public totalInvestedAmount;

    /**
     * @notice Amount of BEP20 invested in IDO
     */
    uint256 public totalInvestedAmountInBEP20;

    /**
     * @notice Amount of Chain Currency allocated to potential investors
     */
    uint256 public totalAllocatedAmount;

    /**
     * @notice Mapping of Pool Token shares for payees
     * @dev Mapping (account -> amount of Pool Tokens)
     */
    mapping(address => uint256) public poolTokenShares;

    /**
     * @notice Total shares released from this contract
     */
    uint256 public totalReleased;

    /**
     * @notice Total shares issued to payees
     */
    uint256 public totalShares;

    /**
     * @notice ID of corresponding Voting
     */
    uint256 public votingId;

    /**
     * @notice Address of the XillionVotingFactory to create voting for ido
     */
    // XillionVotingFactory public votingFactory;

    

    /* -------------------------------------------------------------- VIEWS ------------------------------------------------------------- */

    /**
     * @return The decimal places of the allocation tier and lp multipliers
     * @dev The allocation tier and lp holder must have the same number of decimals
     */
    function getAllocationSizeMultiplierTierDecimals() public pure returns (uint256) {
        return 2;
    }

    /**
     * @return The decimals places of the XIL to Chain Currency allocation size ratio
     */
    function getXilToChainCurrencyAllocationSizeRatioDecimals() public pure returns (uint256) {
        return 18;
    }

    /* -------------------------------------------------------------- ENUMS ------------------------------------------------------------- */

    /**
     * @title State of the IDO
     * @property Computed The status is unknown and must be computed by analysing the different IDO dates
     * @property Unconfirmed The ido is created by user and waiting for admin appove
     * @property Confirmed The ido is confirmed by the moderator
     * @property Voting The ido is approved by admin and in the voiting phase; users with stakes can vote
     * @property Allocation The IDO is in the allocation phase; investors can only join, request and recalculate their allocation size
     * @property Swap The IDO is in the swap phase; investors can now invest into the IDO
     * @property Claim The IDO is in the claim phase; investors cannot invest anymore but any shareholder can claim their vested Pool Tokens past the vesting period
     * @property Refund The IDO is in the refund phase; investors cannot invest anymore but can claim their investment back
     * @property Closed The IDO is closed
     */
    enum IDOState {Computed, Unconfirmed, Confirmed, Voting, Allocation, Swap, Claim, Refund, Closed}

    /**
     * @title State of the Voting
     * @property Preparing Voting is not started yet;
     * @property Processing Voting is in progress;
     * @property Successed Voting was successfully completed;
     * @property Failed Voting didn't get min amount of votes for successful completion;
     */
    enum VotingState {Preparing, Processing, Successed, Failed}

     /**
     * @title Staking statuses
     * @property Base ...
     * @property Advanced ...;
     * @property Epic...;
     */
    enum StakingStatus {None, Base, Advanced, Epic}

    /* ------------------------------------------------------------- EVENTS ------------------------------------------------------------- */

    /**
     * @notice Event emitted when the Pool Token is minted
     */
    event PoolTokenMinted(address poolTokenAddress);

    /**
     * @notice Event emitted when an investor's allocation size is updated
     * @param investor Address of the staker/potential investor
     * @param allocationSize Size of the staker's allocation for this IDO
     */
    event AllocationSizeUpdated(address investor, uint256 allocationSize);

    /**
     * @notice Event emitted when the total allocated amount is updated
     * @param totalAllocatedAmount New total allocated amount
     */
    event TotalAllocatedAmountUpdated(uint256 totalAllocatedAmount);

    /**
     * @notice Event emitted when an investor's investment is updated
     * @param investor Address of the investor
     * @param investment Size of the investor's investment within this IDO
     * @param totalInvestedAmount Total invested amount within this IDO
     */
    event InvestmentUpdated(address investor, uint256 investment, uint256 totalInvestedAmount);

    /**
     * @notice Event emitted when an investor's BEP20 investment is updated
     * @param investor Address of the investor
     * @param investment Size of the investor's investment within this IDO
     * @param totalInvestedAmount Total invested amount within this IDO
     * @param _tokenAddress Address of investing BEP20 token 
     */
    event InvestmentBEP20Updated(address investor, uint256 investment, uint256 totalInvestedAmount, address _tokenAddress);

    /**
     * @notice Event emitted when the IDOState is updated
     * @param state New state of the IDO
     */
    event IDOStateUpdated(IDOState state);

    /**
     * @notice Event emitted when the IDO is killed
     */
    event IDOKilled();

    /**
     * @notice Event emitted when pool tokens are claimed
     * @param poolTokensHolder Address of the sender
     * @param amountClaimed Amount of pool tokens released
     */
    event PoolTokensClaimed(address poolTokensHolder, uint256 amountClaimed);

    /**
     * @notice Event emitted when pool tokens are claimed
     * @param investor Address of the investor
     * @param amountClaimed Amount of Chain Currency released
     */
    event RefundedInvestmentClaimed(address investor, uint256 amountClaimed);

    /**
     * @notice Event emitted when pool tokens are claimed
     * @param investor Address of the investor
     * @param amountClaimed Amount of BEP20 released
     */
    event RefundedInvestmentClaimedInBEP20(address investor, uint256 amountClaimed);

    /**
     * @notice Event emitted when the PoolTokenSharePercentages is updated
     * @param investors Pool Token Share Percentage of the investors
     * @param curator Pool Token Share Percentage of the curator
     * @param xillion Pool Token Share Percentage of Xillion
     * @param littlePhil Pool Token Share Percentage of Little Phil
     */
    event PoolTokenSharePercentagesUpdated(uint256 investors, uint256 curator, uint256 xillion, uint256 littlePhil);

    //  /**
    //  * @notice Event emitted when the PoolTokenVestingDays is updated
    //  * @param investors Pool Token Vesting Days of the investors
    //  * @param curator Pool Token Vesting Days of the curator
    //  * @param xillion Pool Token Vesting Days of Xillion
    //  * @param littlePhil Pool Token Vesting Days of Little Phil
    //  */
    // event PoolTokenVestingDaysUpdated(uint256 investors, uint256 curator, uint256 xillion, uint256 littlePhil);
/**
     * @notice Event emitted when the allocationStartDate is updated
     * @param allocationStartDate New allocation start date for the IDO
     */
    event AllocationStartDateUpdated(uint256 allocationStartDate);

    /**
     * @notice Event emitted when the allocationEndDate is updated
     * @param allocationEndDate New allocation end date for the IDO
     */
    event AllocationEndDateUpdated(uint256 allocationEndDate);

    /**
     * @notice Event emitted when the swapStartDate is updated
     * @param swapStartDate New swap start date for the IDO
     */
    event SwapStartDateUpdated(uint256 swapStartDate);

    /**
     * @notice Event emitted when the swapEndDate is updated
     * @param swapEndDate New swap end date for the IDO
     */
    event SwapEndDateUpdated(uint256 swapEndDate);

    /**
     * @notice Event emitted when the InvestmentDetails is updated
     * @param maxInvestmentAmountPerInvestor New maxInvestmentAmountPerInvestor
     * @param minInvestmentPercentForIDOCompletion New minInvestmentPercentForIDOCompletion
     * @param minStakingDays New minStakingDays
     * @param stakingContract New staking contract address
     */
    event InvestmentDetailsUpdated(
        uint256 maxInvestmentAmountPerInvestor,
        uint256 minInvestmentPercentForIDOCompletion,
        uint256 minStakingDays,
        address stakingContract
    );

    /**
     * @notice Event emitted when the InvestmentBEP20Details is updated
     * @param maxInvestmentBEP20AmountPerInvestor New maxInvestmentBEP20AmountPerInvestor
     * @param BEP20IdoTokenAddress New BEP20IdoTokenAddress
     * @param BEP20IdoValueCap New BEP20IdoValueCap
     * @param minInvestmentPercentOfBEP20ForIDOCompletion New minInvestmentPercentOfBEP20ForIDOCompletion
     */
    event InvestmentBEP20DetailsUpdated(
        uint256 maxInvestmentBEP20AmountPerInvestor,
        address BEP20IdoTokenAddress,
        uint256 BEP20IdoValueCap,
        uint256 minInvestmentPercentOfBEP20ForIDOCompletion
    );

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./utils/OwnablePausable.sol";
import "./utils/ExtendableTokenTimelock.sol";

/**
 * @title XIL Staking Contract
 */
contract XillionAccessStaking is OwnablePausable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    /* ------------------------------------------------------------ VARIABLES ----------------------------------------------------------- */

    /**
     * @notice The Staking Token
     * @dev This is meant to be the XIL token, but we are reserving the right to change it in case we have need to release a V2 for security purposes for example
     */
    IERC20 public stakingToken;

    /**
     * @notice The minimum staking period enabled by this contract
     */
    uint256 public minimumStakingDays = 28;
    

    /**
     * @notice Record of all the stakes currently in this contract
     */
    mapping(address => Stake[]) public stakes;

    /**
     * @notice address to status based on staking amounts
     */
    mapping(address => StakingStatus) public addressToStakingStatus;

    /**
     * @notice address to summary stakes amount
     */
    mapping(address => uint256) public addressToStakingBalance;

     /**
     * @notice amount of stakes for corresponding status
     */
    mapping(StakingStatus => uint256) stakingStatusToStakeAmount;


    /**
     * @notice Nonce for generating unique IDs
     */
    uint256 private _stakeIdNonce;

    /**
     * @title Staking statuses
     * @property Base ...
     * @property Advanced ...;
     * @property Epic...;
     */
    enum StakingStatus {None, Base, Advanced, Epic}

    /* ----------------------------------------------------------- CONSTRUCTOR ---------------------------------------------------------- */

    /**
     * @notice Called on creation of the Staking contract
     * @param stakingTokenAddr Address of the Staking Token
     * @param ownerAddr Address of the owner of this contract (most likely a multi SIG wallet)
     */
    constructor(address stakingTokenAddr, address ownerAddr) {

        require(stakingTokenAddr != address(0) && ownerAddr != address(0), "Invalid address");

        stakingToken = IERC20(stakingTokenAddr);

        if (_msgSender() != ownerAddr) {
            transferOwnership(ownerAddr);
        }
        
        stakingStatusToStakeAmount[StakingStatus.Base] = 10000 ether;
        stakingStatusToStakeAmount[StakingStatus.Advanced] = 100000 ether;
        stakingStatusToStakeAmount[StakingStatus.Epic] = 1000000 ether;
    }

    /* --------------------------------------------------------- MAIN ACTIVITIES -------------------------------------------------------- */

    /**
     * @notice Holds the provided number of XIL tokens for the provided days in an ExtendableTokenTimelock.
     * @param amount Number of tokens to be staked in token decimals
     * @param daysToLock Number of days to lock tokens up for
     */
    function stake(uint256 amount, uint256 daysToLock) external whenNotPaused nonReentrant {

        // guards
        require(stakingToken != IERC20(address(0)), "Staking token has not been set");
        require(amount > 0, "Cannot stake 0");
        require(daysToLock >= minimumStakingDays, "Cannot stake for less than the minimum staking days");

        // create timelock and transfer funds
        uint256 releaseDate = block.timestamp + (daysToLock * 1 days);
        ExtendableTokenTimelock timelock = new ExtendableTokenTimelock(stakingToken, _msgSender(), releaseDate);
        stakingToken.safeTransferFrom(_msgSender(), address(timelock), amount); 

        // create unique ID
        bytes32 uid = keccak256(abi.encodePacked(_msgSender(), amount, daysToLock, block.timestamp, block.number, _stakeIdNonce));
        _stakeIdNonce++;

        // record the stake
        Stake memory stakeRecord = Stake(uid, daysToLock, timelock);
        stakes[_msgSender()].push(stakeRecord);

        // Setting staker balance
        uint256 newBalance = addressToStakingBalance[msg.sender] + amount;
        checkUserStakingStatus(newBalance, msg.sender);


        // emit event
        emit Staked(uid, _msgSender(), address(stakingToken), amount, releaseDate, daysToLock);

    }

    /**
     * @notice Extends the release date of one of the sender's stakes
     * @param stakeIndex Index of the stake in the sender's list of stakes
     * @param daysToAdd Number of days to extend the stake by
     */
    function extend(uint256 stakeIndex, uint256 daysToAdd) external whenNotPaused nonReentrant {

        // guard
        require(daysToAdd > 0, "daysToAdd must be greater than 0");

        // retrieve stake & timelock
        Stake memory stakeRecord = stakes[_msgSender()][stakeIndex];
        ExtendableTokenTimelock timelock = stakeRecord.timelock;

        // extend stake
        timelock.extend(daysToAdd * 1 days);
        stakes[_msgSender()][stakeIndex].daysLocked = stakeRecord.daysLocked + daysToAdd;

        // emit event
        IERC20 stakingTokenInTimelock = stakeRecord.timelock.token();
        emit Extended(
            stakeRecord.uid,
            _msgSender(),
            address(stakingTokenInTimelock),
            stakingTokenInTimelock.balanceOf(address(timelock)),
            timelock.releaseTime(),
            stakes[_msgSender()][stakeIndex].daysLocked
        );

    }

    /**
     * @notice Withdraws all stakes past their daysLocked
     * @dev This method is using the Swap & Delete strategy to remove released stakes to save on gas cost - we don't care about the order of stakes
     */
    function withdraw() external nonReentrant {

        // check amount of stakes
        uint256 stakesLength = stakes[_msgSender()].length;
        require(stakesLength > 0, "No stakes");

        // go through all of the sender's stakes
        uint256 i = 0;
        while (i < stakesLength) {

            Stake memory stakeRecord = stakes[_msgSender()][i];
            ExtendableTokenTimelock timelock = stakeRecord.timelock;

            // check if this stake is releasable
            if (block.timestamp >= timelock.releaseTime()) {

                IERC20 stakingTokenInTimelock = stakeRecord.timelock.token();
                uint256 amount = stakingTokenInTimelock.balanceOf(address(timelock));

                // Setting staker balance
                uint256 newBalance = addressToStakingBalance[msg.sender] - amount;
                checkUserStakingStatus(newBalance, msg.sender);

                // release timelock
                timelock.release();

                // emit event
                emit Withdrawn(
                    stakeRecord.uid,
                    _msgSender(),
                    address(stakingTokenInTimelock),
                    amount,
                    timelock.releaseTime(),
                    stakeRecord.daysLocked
                );

                // swap with last element
                if (i < stakesLength - 1) {
                    stakes[_msgSender()][i] = stakes[_msgSender()][stakesLength - 1];
                }

                // pop array
                stakes[_msgSender()].pop();
                stakesLength--;

            } else {

                // not releasable, go to next stake
                i++;

            }

        }

    }

    /* ------------------------------------------------------------- MUTATORS ----------------------------------------------------------- */

    /**
     * @notice Overrides the token accepted for staking
     * @param stakingTokenAddr Address of the new staking token being set
     */
    function setStakingToken(address stakingTokenAddr) external onlyOwner {
        require(stakingTokenAddr != address(0), "Invalid address");
        emit StakingTokenUpdated(address(stakingToken), stakingTokenAddr);
        stakingToken = IERC20(stakingTokenAddr);
    }


     /**
     * @notice Overrides users staking balances and statuses
     * @param newBalance_ new Staking balance of user
     * @param userAddress_ address of caller
     */
    function checkUserStakingStatus(uint256 newBalance_, address userAddress_) internal {
        if(newBalance_ >= stakingStatusToStakeAmount[StakingStatus.Epic]){
            addressToStakingStatus[userAddress_] = StakingStatus.Epic;
        }else if(newBalance_ >= stakingStatusToStakeAmount[StakingStatus.Advanced]){
            addressToStakingStatus[userAddress_] = StakingStatus.Advanced;
        }else if(newBalance_ >=  stakingStatusToStakeAmount[StakingStatus.Base]){
            addressToStakingStatus[userAddress_] = StakingStatus.Base;
        }else{
            addressToStakingStatus[userAddress_] = StakingStatus.None;
        }
        addressToStakingBalance[userAddress_] = newBalance_;
    }


    /**
     * @notice Overrides the minimum staking period
     * @param minimumStakingDays_ New minimum staking period in days
     */
    function setMinimumStakingDays(uint256 minimumStakingDays_) external onlyOwner {
        require(minimumStakingDays_ > 0, "Minimum Staking Days must be above 0");
        emit MinimumStakingDaysUpdated(minimumStakingDays, minimumStakingDays_);
        minimumStakingDays = minimumStakingDays_;
    }

    /**
     * @notice changes multiplier depends on reward role
     * @param baseStatusAmount_ Base...
     * @param advancedSatusAmount_ Advanced...
     * @param epicStatusAmount_ Epic...
     */
    function changeStakingAmountForStatus(uint256 baseStatusAmount_, uint256 advancedSatusAmount_, uint256 epicStatusAmount_) external onlyOwner {
       stakingStatusToStakeAmount[StakingStatus.Base] = baseStatusAmount_;
       stakingStatusToStakeAmount[StakingStatus.Advanced] = advancedSatusAmount_;
       stakingStatusToStakeAmount[StakingStatus.Epic] = epicStatusAmount_;
    }

    /* --------------------------------------------------------- VIEWS (PUBLIC) --------------------------------------------------------- */

    /**
     * @notice Returns the staking data for the stake at index for the sender
     * @param index - Index of the stake data to return
     * @return Amount staked
     * @return Days the stake initially was locked for (it may have stayed in the timelock for longer)
     * @return Release date of the timelock
     * @return UID of the stake
     * @return Address of the staking token
     */
    function getStake(uint256 index) external view returns (uint256, uint256, uint256, bytes32, address) {
        return getStakeForAddress(_msgSender(), index);
    }

    /**
     * @notice Returns staking status of staker
      * @param userAddress_ - address of staker
     */
    function getUserStakeStatus(address userAddress_) external view returns (uint256) {
        return uint256(addressToStakingStatus[userAddress_]);
    }


    /**
     * @notice Returns the staking data for the provided staker at the provided index
     * @param staker - Address to look up stake for
     * @param index - Index of the stake data to return
     * @return Amount staked
     * @return Days the stake initially was locked for (it may have stayed in the timelock for longer)
     * @return Release date of the timelock
     * @return UID of the stake
     * @return Address of the staking token
     */
    function getStakeForAddress(address staker, uint256 index) public view returns (uint256, uint256, uint256, bytes32, address) {
        Stake memory stakeRecord = stakes[staker][index];
        IERC20 stakingTokenInTimelock = stakeRecord.timelock.token();
        uint256 amount = stakingTokenInTimelock.balanceOf(address(stakeRecord.timelock));
        uint256 releaseDate = stakeRecord.timelock.releaseTime();
        return (amount, stakeRecord.daysLocked, releaseDate, stakeRecord.uid, address(stakingTokenInTimelock));
    }

    /**
     * @return The number of stakes for the sender
     */
    function getStakeCount() external view returns (uint256) {
        return getStakeCountForAddress(_msgSender());
    }

    /**
     * @param staker - Address to look up stake count for
     * @return The number of stakes for the provided staker
     */
    function getStakeCountForAddress(address staker) public view returns (uint256) {
        return stakes[staker].length;
    }

    /* ------------------------------------------------------------- STRUCTS ------------------------------------------------------------ */

    /**
     * @title Struct describing an individual stake transaction to the contract
     * @property uid - Id of the stake, unique across all stakes (current or not)
     * @property daysLocked - Staking period in days
     * @property timelock - ExtendableTokenTimelock contract containing staked tokens
     */
    struct Stake {
        bytes32 uid;
        uint256 daysLocked;
        ExtendableTokenTimelock timelock;
    }

    /* ------------------------------------------------------------- EVENTS ------------------------------------------------------------- */

    /**
     * @notice Event emitted when a Stake is created
     * @param uid Unique ID of the stake
     * @param sender Address of the staker
     * @param stakingToken Address of the staking token
     * @param amount Amount staked
     * @param releaseDate Release date of the stake
     * @param daysLocked Duration of the token timelock
     */
    event Staked(bytes32 uid, address sender, address stakingToken, uint256 amount, uint256 releaseDate, uint256 daysLocked);

    /**
     * @notice Event emitted when a Stake is extended
     * @param uid Unique ID of the stake
     * @param sender Address of the staker
     * @param stakingToken Address of the staking token
     * @param amount Amount staked
     * @param newReleaseDate New release date of the stake
     * @param newDaysLocked New duration of the token timelock
     */
    event Extended(bytes32 uid, address sender, address stakingToken, uint256 amount, uint256 newReleaseDate, uint256 newDaysLocked);

    /**
     * @notice Event emitted when a Stake is withdrawn
     * @param uid Unique ID of the stake
     * @param sender Address of the staker
     * @param stakingToken Address of the staking token
     * @param amount Amount released
     * @param releaseDate Release date of the stake
     * @param daysLocked Duration of the token timelock
     */
    event Withdrawn(bytes32 uid, address sender, address stakingToken, uint256 amount, uint256 releaseDate, uint256 daysLocked);

    /**
     * @notice Event emitted when the staking token is updated
     * @param oldStakingToken Address of the previous staking token
     * @param newStakingToken Address of the new staking token
     */
    event StakingTokenUpdated(address oldStakingToken, address newStakingToken);

    /**
     * @notice Event emitted when the MinimumStakingDays is updated
     * @param oldMinimumStakingDays Address of the previous MinimumStakingDays
     * @param newMinimumStakingDays Address of the new MinimumStakingDays
     */
    event MinimumStakingDaysUpdated(uint256 oldMinimumStakingDays, uint256 newMinimumStakingDays);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

import "./utils/OwnablePausable.sol";

/**
 * @title Contract for a Xillion Pool Token
 * @notice This token can used by a Xillion IDO and/or a Xillion Pool
 */
contract XillionPoolToken is ERC20PresetFixedSupply, OwnablePausable {

    /**
     * @notice Creates a new Xillion Pool Token
     * @param name_ Name of the Pool Token
     * @param symbol_ Symbol of the Pool Token
     * @param initialSupply_ Initial Supply of the Pool Token (amount of tokens minted)
     * @param owner_ Designated owner of the Pool Token contract
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_,
        address owner_
    ) ERC20PresetFixedSupply(name_, symbol_, initialSupply_, owner_) {
        require(owner_ != address(0), "Invalid owner");
        if (owner_ != _msgSender()) {
            transferOwnership(owner_);
        }
    }

    /**
     * @notice Required getOwner function for the BEP20 standard.
     * @return the owner of the token contract
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @notice Prevents token transfers if the contract is paused
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     * Copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Pausable.sol
     * This could not be used in conjunction with ERC20PresetFixedSupply otherwise we get the following error message:
     * TypeError: Derived contract must override function "_beforeTokenTransfer". Two or more base classes define function with same name and parameter types.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "XillionPoolToken: token transfer while paused");
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./libraries/XillionIDOStructs.sol";
import "./utils/OwnablePausable.sol";
import "./XillionIDO.sol";
import "./XillionVotingFactory.sol";
import "./interfaces/IXillionModerators.sol";


/**
 * @title Factory+Master/Slave Patterns contract to deploy an IDO
 */

contract XillionIDOFactory is OwnablePausable, ReentrancyGuard {

    /* ------------------------------------------------------------ VARIABLES ----------------------------------------------------------- */

    /**
     * @notice Address of the master IDO to be delegated calls to
     */
    address public masterIDOAddress;

    /**
     * @notice address of moderators contract
     */
    address public xillionModeratorsAddress;

    /**
     * @notice Address of the XillionVotingFactory to create voting for ido
     */
    XillionVotingFactory public votingFactory;

    /**
     * @notice List of IDOs created by this factory
     */
    XillionIDO[] public idos;

    /**
     * @notice List of moderators, who can confirm IDO
     */  
    // mapping(address => bool) public moderatorToStatus;

    //  /**
    //  * @notice List of moderators, who can confirm IDO
    //  */
    // address[] public moderators;

    /**
     * @notice XIL -> Chain Currency allocation size ratio
     */
    uint256 public xilToChainCurrencyAllocationSizeRatio;

    /**
     * @notice BUSD -> Chain Currency allocation size ratio
     */
    uint256 public busdToChainCurrencyAllocationSizeRatio;

    modifier onlyModerator(address userAddress_) { // Modifier
        require(
             checkIsUserModerator(userAddress_),
            "Only moderator can call this."
        );
        _;
    }

    /* ----------------------------------------------------------- CONSTRUCTOR ---------------------------------------------------------- */

    /**
     * @notice Creates the IDO Factory
     * @param ownerAddr_ Address of the owner of this contract (most likely a multi SIG wallet)
     * @param masterIDOAddress_ Address of the master IDO to be delegated calls to
     * @param xilToChainCurrencyAllocationSizeRatio_ XIL -> Chain Currency allocation size ratio
     * @param busdToChainCurrencyAllocationSizeRatio_ BUSD -> Chain Currency allocation size ratio
     * @param votingAddress_ Allocation rules/tiers (staking range mins and multipliers),
     * @param xillionModeratorsAddress_ Address of moderators contract,
     */
    constructor(address ownerAddr_, address masterIDOAddress_, uint256 xilToChainCurrencyAllocationSizeRatio_, uint256 busdToChainCurrencyAllocationSizeRatio_, address votingAddress_, address xillionModeratorsAddress_) {

        require(ownerAddr_ != address(0), "Invalid owner");
        require(xillionModeratorsAddress_ != address(0), "Invalid moderators contract address");
        xillionModeratorsAddress = xillionModeratorsAddress_;
        votingFactory = XillionVotingFactory(votingAddress_);
        
        _checkAndUpdateMasterIDOAddress(masterIDOAddress_);

        setBEP20ToChainCurrencyAllocationSizeRatio(xilToChainCurrencyAllocationSizeRatio_, busdToChainCurrencyAllocationSizeRatio_);

        if (_msgSender() != ownerAddr_) {
            transferOwnership(ownerAddr_);
        }
    }

    /* --------------------------------------------------------- MAIN ACTIVITIES -------------------------------------------------------- */

    /**
     * @notice Deploys an IDO
     * @param initialDetails_ General Details about an IDO
     * @param dates_ Provisioned dates of the IDO
     * @param investmentDetails_ Investment Details about an IDO
     * @param poolTokenSharePercentages_ Share of the Pool Tokens for different actors in %
     * @param walletAddresses_ Critical actors' wallet address
     */
    function createIDO(
        XillionIDOStructs.InitialDetails calldata initialDetails_,
        XillionIDOStructs.IDODates calldata dates_,
        XillionIDOStructs.InvestmentDetails calldata investmentDetails_,
        XillionIDOStructs.PoolTokenSharePercentage calldata poolTokenSharePercentages_,
        XillionIDOStructs.WalletAddressV2 calldata walletAddresses_
    ) external whenNotPaused nonReentrant {
        // create new IDO
        XillionIDO ido = new XillionIDO(
            address(this),
            initialDetails_
        );

        // initialise the IDO
        ido.initialise(investmentDetails_, poolTokenSharePercentages_, walletAddresses_, dates_);

        // transfer ownership
        ido.transferOwnership(initialDetails_.contractOwner);

        // add to array of IDOs
        idos.push(ido);

        // emit event
        emit IDOCreated(
            address(ido),
            initialDetails_,
            dates_,
            investmentDetails_,
            poolTokenSharePercentages_,
            walletAddresses_,
            tx.origin
        );

    }

    /* ------------------------------------------------------------- MUTATORS ----------------------------------------------------------- */

    /**
     * @notice Sets the master IDO address
     * @param masterIDOAddress_ Address of the new master IDO
     */
    function setMasterIDOAddress(address masterIDOAddress_) external onlyOwner whenPaused {
        _checkAndUpdateMasterIDOAddress(masterIDOAddress_);
    }

    /**
     * @notice Checks the master IDO address is valid and sets it in storage
     * @param masterIDOAddress_ Address of the new master IDO
     */
    function _checkAndUpdateMasterIDOAddress(address masterIDOAddress_) internal {
        require(masterIDOAddress_ != address(0), "Invalid masterIDOAddress");
        masterIDOAddress = masterIDOAddress_;
    }

    /**
     * @notice Sets the XIL and BUSD -> Chain Currency allocation size ratio
     * @param xilToChainCurrencyAllocationSizeRatio_ New XIL -> Chain Currency allocation size ratio
     * @param busdToChainCurrencyAllocationSizeRatio_ New BUSD -> Chain Currency allocation size ratio
     */
    function setBEP20ToChainCurrencyAllocationSizeRatio(uint256 xilToChainCurrencyAllocationSizeRatio_, uint256 busdToChainCurrencyAllocationSizeRatio_) public onlyOwner whenNotPaused {
        xilToChainCurrencyAllocationSizeRatio = xilToChainCurrencyAllocationSizeRatio_;
        busdToChainCurrencyAllocationSizeRatio = busdToChainCurrencyAllocationSizeRatio_;
        emit BEP20ToChainCurrencyAllocationSizeRatioUpdated(xilToChainCurrencyAllocationSizeRatio_, busdToChainCurrencyAllocationSizeRatio_);
    }

    //  /**
    //  * @notice Adds new moderator to moderators array 
    //  * @param moderatorAddress_ address of new moderator or existed one
    //  * @param moderatorStatus_ address status
    //  */
    // function changeModerator(address moderatorAddress_, bool moderatorStatus_) public onlyOwner {
    //     require(moderatorAddress_ != address(0));
    //     moderatorToStatus[moderatorAddress_] = moderatorStatus_;
    // }

    //  /**
    //  * @notice Adds new moderator to moderators array 
    //  * @param moderatorAddress_ address of new moderator or existed one
    //  */
    // function addNewModerator(address moderatorAddress_) public onlyOwner {
    //     require(moderatorAddress_ != address(0));
    //     moderators.push(moderatorAddress_);
    // }


    //  /**
    //  * @notice Adds new moderator to moderators array 
    //  * @param moderatorAddress_ address of new moderator or existed one
    //  */
    // function removeModerator(address moderatorAddress_) public onlyOwner {
    //     require(moderatorAddress_ != address(0));
        
    //     for(uint i; i < moderators.length; i++){
    //         if(moderatorAddress_ == moderators[i]){
    //             moderators[i] = moderators[moderators.length - 1];
    //             moderators.pop();
    //         }
    //     }
    // }

    /**
     * @notice Creates new voting for corresponding IDO
     * @param targetVotes_ Target vote amount for voting
     * @param minVotingValue_ Minimum number of votes for successful voting
     * @param votingStartTimestamp_ Timestamp of voting start
     * @param votingEndTimestamp_ Timestamp of voting end
     */ 
    function createVotingForIDO(uint256 targetVotes_, uint256 minVotingValue_, uint256 votingStartTimestamp_, uint256 votingEndTimestamp_) external onlyModerator(tx.origin) returns(uint) {
         uint votingId = votingFactory.createVoting(targetVotes_, minVotingValue_, votingStartTimestamp_, votingEndTimestamp_);
         emit IDOConfirmed(msg.sender);
         return votingId;
    }




    /* --------------------------------------------------------- VIEWS (PUBLIC) --------------------------------------------------------- */

    /**
     * @return The amount of IDOs created by this factory
     */
    function getIDOsCount() external view returns (uint256) {
        return idos.length;
    }

     /**
       * @param votingId_ How long voting will
       * @return The amount of IDOs created by this factory
     */
    function getStateOfVoting(uint256 votingId_) external view returns (uint256) {
        return uint256(votingFactory.getVotingState(votingId_));
    }

    // /**
    //    * @return The amount of IDOs created by this factory
    //  */
    // function getModeratorsCount() external view returns (uint256) {
    //     return moderators.length;
    // }

    /**
     * @return Value if sender is moderator
     * @param userAddress_ address of user for check 
     */
    function checkIsUserModerator(address userAddress_) public view returns (bool) {
        return IXillionModerators(xillionModeratorsAddress).isUserModerator(userAddress_);
    }

    /* -------------------------------------------------------------- EVENTS ------------------------------------------------------------ */

    /**
     * @notice Emitted when an IDO is deployed
     * @param idoAddress Address of the IDO
     * @param initialDetails General Details about an IDO
     * @param dates Provisioned dates of the IDO
     * @param investmentDetails Investment Details about the IDO
     * @param poolTokenSharePercentages Share of the Pool Tokens for different actors in %
     * @param walletAddresses Critical actors' wallet address
     * @param idoOwner address of ido owner
     */
    event IDOCreated(
        address idoAddress,
        XillionIDOStructs.InitialDetails initialDetails,
        XillionIDOStructs.IDODates dates,
        XillionIDOStructs.InvestmentDetails investmentDetails,
        XillionIDOStructs.PoolTokenSharePercentage poolTokenSharePercentages,
        XillionIDOStructs.WalletAddressV2 walletAddresses,
        address idoOwner
    );


    /**
     * @notice Emitted when an IDO is confirmed
     * @param idoAddress Address of the IDO
     */
    event IDOConfirmed(
        address idoAddress
    );


    /**
     * @notice Emitted when the XIL/BUSD -> Chain Currency allocation size ratio is updated
     * @param xilToChainCurrencyAllocationSizeRatio XIL -> Chain Currency allocation size ratio
     * @param busdToChainCurrencyAllocationSizeRatio BUSD -> Chain Currency allocation size ratio
     */
    event BEP20ToChainCurrencyAllocationSizeRatioUpdated(uint256 xilToChainCurrencyAllocationSizeRatio, uint256 busdToChainCurrencyAllocationSizeRatio);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/**
 * @notice A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time. That release time can be extended by the original token holder.
 *
 * Largely inspired from OpenZeppelin's TokenTimelock
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.2/contracts/token/ERC20/utils/TokenTimelock.sol
 */
contract ExtendableTokenTimelock is Ownable {

    using SafeERC20 for IERC20;

    /* ------------------------------------------------------------ VARIABLES ----------------------------------------------------------- */

    // ERC20 basic token contract being held
    IERC20 private immutable _token;

    // beneficiary of tokens after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    /* ----------------------------------------------------------- CONSTRUCTOR ---------------------------------------------------------- */

    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 releaseTime_
    ) {
        require(releaseTime_ >= block.timestamp, "Invalid release time");
        require(beneficiary_ != address(0), "Invalid beneficiary");
        require(token_ != IERC20(address(0)), "Invalid token");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

    /* --------------------------------------------------------- MAIN ACTIVITIES -------------------------------------------------------- */

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() external {
        require(block.timestamp >= releaseTime(), "Forbidden");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "Timelock empty");

        token().safeTransfer(beneficiary(), amount);
    }


    /**
     * @notice Extends the time on the timelock
     * @param timeToAdd Time to add (in seconds)
     */
    function extend(uint256 timeToAdd) public onlyOwner {

        require(timeToAdd > 0, "Invalid timeToAdd");

        uint256 balance = token().balanceOf(address(this));

        require(balance > 0, "Timelock empty");

        uint256 oldReleaseTime = _releaseTime;

        _releaseTime += timeToAdd;

        emit TokenTimelockExtended(
            address(token()),
            _beneficiary,
            balance,
            oldReleaseTime,
            _releaseTime,
            timeToAdd
        );

    }

    /* --------------------------------------------------------- VIEWS (PUBLIC) --------------------------------------------------------- */

    /**
     * @return The token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return The beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return The time when the tokens are released.
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    /* ------------------------------------------------------------- EVENTS ------------------------------------------------------------- */

    /**
     * @notice Event emitted when a TokenTimelock is extended
     * @param token Address of the tokens in the timelock
     * @param beneficiary Address of the beneficiary of the timelock
     * @param amountLocked Amount of tokens currently locked in the timelock
     * @param oldReleaseTime The previous release time
     * @param newReleaseTime The new release time with the extension
     * @param timeAdded The amount of seconds added to the previous release time
     */
    event TokenTimelockExtended(address token, address beneficiary, uint256 amountLocked, uint256 oldReleaseTime, uint256 newReleaseTime, uint256 timeAdded);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetFixedSupply.sol)
pragma solidity ^0.8.0;

import "../extensions/ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetFixedSupply is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/XillionIDOStructs.sol";
import "./utils/OwnablePausable.sol";
import "./XillionIDO.sol";


/**
 * @title Factory+Master/Slave Patterns contract to create a Voting
 */
contract XillionVotingFactory is OwnablePausable, ReentrancyGuard {

     using SafeERC20 for IERC20;



    /* ------------------------------------------------------------ VARIABLES ----------------------------------------------------------- */

    /**
     * @notice List of Votings created by this factory
     */
    mapping(uint256 => Voting) public idToVoting;

    /**
     * @notice Amount of all votings to generate id
     */
    uint256 public votingSupply;

    /**
     * @notice Price of 1 vote in XIL
     */
    uint256 public votePrice = 1;

    /**
     * @notice address of XillionIdoFactory
     */
    address public idoFactoryAddress;

    /**
     * @notice The XIL
     * @dev This is meant to be the XIL token
     */
    IERC20 public xilToken;

    
    /**
     * @title Details about Voting
     * @property votingId Id of the voting
     * @property currentVotes current amount of votes in voting
     * @property targetVotes Amount of votes to archive
     * @property minVotingValue Minimum amount of votes to archive   // - fix it
     * @property votingStartTimestamp  timestamp when voting starts
     * @property votingEndTimestamp timestamp when voting ends
     * @property addressToVotesInXIL amount of votes for voters
     */
    struct Voting{
        uint256 votingId;
        uint256 currentVotes;
        uint256 targetVotes;
        uint256 minVotingValue;
        uint256 votingStartTimestamp;
        uint256 votingEndTimestamp;
        VotingState votingState;
        mapping(address => uint256) addressToVotesInXIL;
    }

    /**
     * @title State of the Voting
     * @property Preparing Voting is not started yet;
     * @property Processing Voting is in progress;
     * @property Successed Voting was successfully completed;
     * @property Failed Voting didn't get min amount of votes for successful completion;
     */
    enum VotingState {Preparing, Processing, Successed, Failed}


    /* ----------------------------------------------------------- CONSTRUCTOR ---------------------------------------------------------- */

    /**
     * @notice Creates the Voting Factory
     * @param xilTokenAddr Address of XIL
     */
    constructor(address xilTokenAddr) {

        require(xilTokenAddr != address(0), "Invalid address");

        xilToken = IERC20(xilTokenAddr);
    }

    modifier onlyIDOFactory() { // Modifier
        require(
             msg.sender == idoFactoryAddress,
            "Only Ido Facotory"
        );
        _;
    } 

    /* --------------------------------------------------------- MAIN ACTIVITIES -------------------------------------------------------- */
    

     /**
     * @notice Creates new voting
     * @param targetVotes_ Target vote amount for voting
     * @param minVotingValue_ Minimum number of votes for successful voting
     * @param votingStartTimestamp_ timestamp when voting starts
     * @param votingEndTimestamp_ timestamp when voting ends
     */
     
    function createVoting(uint256 targetVotes_, uint256 minVotingValue_, uint256 votingStartTimestamp_, uint256 votingEndTimestamp_) external onlyIDOFactory returns(uint256) {
        require(targetVotes_ > 0, "Invalid target votes number");
        require(minVotingValue_ > 0, "Invalid min Voting number");
        require(votingStartTimestamp_ >= block.timestamp, "Incorrect start date");
        require(votingEndTimestamp_ > votingStartTimestamp_, "Incorrect end date");

        // create new VOTING
        Voting storage newVoting = idToVoting[votingSupply];
        
        newVoting.votingId = votingSupply;
        newVoting.targetVotes = targetVotes_;
        newVoting.minVotingValue = minVotingValue_;
        newVoting.votingStartTimestamp = votingStartTimestamp_;
        newVoting.votingEndTimestamp = votingEndTimestamp_;
        newVoting.votingState = VotingState.Preparing;

        // emit event
        emit VotingCreated(
           newVoting.votingId,
           newVoting.currentVotes,
           newVoting.targetVotes,
           newVoting.minVotingValue,
           newVoting.votingStartTimestamp,
           newVoting.votingEndTimestamp,
           newVoting.votingState
        );
        votingSupply++;
        return newVoting.votingId;
    }


    /**
     * @notice Adds votes to corresponding voting
     * @param votingId_ Id of voting user wants to vote
     * @param votesAmount_ Amount of votes
     */
    function vote(uint256 votingId_, uint256 votesAmount_) external whenNotPaused nonReentrant {
        require(votesAmount_ > 0, "Incorrect votes amount");
       

        // NEW

        // OLD 
        Voting storage voting = idToVoting[votingId_];
        uint256 userBalance = xilToken.balanceOf(msg.sender);
        uint256 votesValueInXil = votesAmount_/votePrice;
        
        require(block.timestamp >= voting.votingStartTimestamp, "This voting hasn't started yet");
        require(block.timestamp <= voting.votingEndTimestamp, "This voting is over");
        require(userBalance >= votesValueInXil, "You don't have enough votes");
        require(voting.currentVotes + votesAmount_ <= voting.targetVotes, "You can't vote more than target");

        xilToken.safeTransferFrom(_msgSender(), address(this), votesValueInXil);

        uint256 newCurrentVotes = voting.currentVotes + votesAmount_;

        voting.currentVotes = newCurrentVotes;
        voting.addressToVotesInXIL[msg.sender] += votesValueInXil;

        emit Voted(voting.votingId, msg.sender, votesAmount_, newCurrentVotes, voting.targetVotes);
        
    }

    /* ------------------------------------------------------------- MUTATORS ----------------------------------------------------------- */
    
    /**
     * @notice Changes price of one vote to one XIL
     * @param newPrice_ new vote price
     */
    function changeVotePrice(uint256 newPrice_) external onlyOwner{
        require(newPrice_ != 0, "vote price can not be 0");
        votePrice = newPrice_;
    }


    /**
     * @notice 
     * @param votingId_ ID of voting
     */
    function withdrawXilFromVoting(uint256 votingId_) external nonReentrant{
       Voting storage voting = idToVoting[votingId_];
       VotingState voitngState = getVotingState(votingId_);
       require(voitngState != VotingState.Processing, "You can't withdraw during Processing phase of voting");
       uint256 votedAmount = voting.addressToVotesInXIL[msg.sender];
       require(votedAmount > 0, "You don't have voted XIL");
  
       voting.addressToVotesInXIL[msg.sender] -= votedAmount;
       xilToken.safeTransfer(_msgSender(), votedAmount);
       emit Withdrawn(votingId_, votedAmount, msg.sender);
    }

     /**
     * @notice Changes price of one vote to one XIL
     * @param idoFactoryAddress_ set address of IDOFactory 
     */
    function setIdoFactoryAddress(address idoFactoryAddress_) external onlyOwner{
        require(idoFactoryAddress_ != address(0), "Invalid address");
        idoFactoryAddress = idoFactoryAddress_;
    }

    /* --------------------------------------------------------- VIEWS (PUBLIC) --------------------------------------------------------- */

    /**
     * @notice Current state of corresponding IDO
     * @param votingId_ ID of voting
     */
    function getVotingState(uint256 votingId_) public view returns (VotingState) {
        Voting storage voting = idToVoting[votingId_];

        if(voting.currentVotes >= voting.targetVotes){
            return VotingState.Successed;
        }
        if(block.timestamp >= voting.votingStartTimestamp && block.timestamp <= voting.votingEndTimestamp){
            return VotingState.Processing;
        }
        if(block.timestamp < voting.votingStartTimestamp){
            return VotingState.Preparing;
        }
        if(block.timestamp > voting.votingEndTimestamp && voting.currentVotes >= voting.minVotingValue){
            return VotingState.Successed;
        }
        return VotingState.Failed;
    }

    /**
     * @notice Amount of XIL user sent to corresponding voting
     * @param votingId_ ID of voting
     */
    function getUserVotesAmount(uint256 votingId_) public view returns (uint256 xilAmount) {
        Voting storage voting = idToVoting[votingId_];
        xilAmount = voting.addressToVotesInXIL[msg.sender];
    }

    /* -------------------------------------------------------------- EVENTS ------------------------------------------------------------ */

    /**
     * @notice Emitted when an IDO is deployed
     * @param votingId ID of voting
     * @param currentVotes initial votes number
     * @param targetVotes Target vote amount for voting
     * @param minVotingValue Minimum number of votes for successful voting
     * @param votingStartTimestamp timestamp when voting starts
     * @param votingEndTimestamp timestamp when voting ends
     * @param votingState Initial voting state
     */
    event VotingCreated(
        uint256 votingId,
        uint256 currentVotes,
        uint256 targetVotes,
        uint256 minVotingValue,
        uint256 votingStartTimestamp,
        uint256 votingEndTimestamp,
        VotingState votingState
    );

    // /**
    //  * @notice Emitted when corresponding voting stats updated
    //  * @param votingId Id of voting
    //  * @param currentVotes current votes amount
    //  * @param targetVotes Target vote amount for voting
    //  */
    // event VotingUpdated(
    //     uint256 votingId,
    //     uint256 currentVotes,
    //     uint256 targetVotes
    // );

     /**
     * @notice Emitted when user has voted
     * @param votingId Id of voting
     * @param addressOfUser Address of voting user
     * @param amountOfVotes How much votes were voted
     * @param currentVotes current votes amount
     * @param targetVotes Target vote amount for voting
     */
    event Voted(
        uint256 votingId,
        address addressOfUser,
        uint256 amountOfVotes,
        uint256 currentVotes,
        uint256 targetVotes
    );

     /**
     * @notice Emitted when user has withdrawed
     * @param votingId Id of voting
     * @param xilAmount how much xil user withdraw
     * @param userAddress address of user who withdraws
     */
    event Withdrawn(
        uint256 votingId,
        uint256 xilAmount,
        address userAddress
    );

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./RemitToken.sol";

/**
 * @dev This is a ERC20 token staking contract.
 * @author MikhilMC
 */
contract StakingGovernanceContract is ReentrancyGuard {
    using Address for address;

    address public immutable i_remitTokenAddress;
    RemitToken public immutable i_remitToken;
    address public immutable i_owner;

    uint256 public constant MINIMUM_LOCK_TIME = 5 minutes;


    bool public isStakingStarted;
    uint256 public totalStakedTokens;
    uint256 public totalActiveStakeholders;
    uint256 public nextTransactionProposalId;
    uint256 public nextReqTotalVotesProposalId;
    uint256 public nextStakedVotesProposalId;
    uint256 public minReqTotalVotes;
    uint256 public minReqTotalVotesDenominator;
    uint256 public minStakedVotes;
    uint256 public minStakedVotesDenominator;

    enum VotingOptions { Yes, No }
    enum Status { Accepted, Rejected, Pending }

    struct StakingData {
        bool isStaking;
        uint256 depositAmount;
        uint256 stakingAmount;
        uint256 stakingFee;
        uint256 numberOfStakings;
        uint256 unstakingFee;
        uint256 rewardGained;
        uint256 rewardFee;
        uint256 stakingStartingTime;
        uint256 unlockingTime;
        uint256 stakingEndingTime;
        uint256 stakingDurationInDays;
    }

    struct AccountData {
        bool doesAccountExists;
        uint256 totalDepositedAmount;
        uint256 totalStakedAmount;
        uint256 totalStakingFee;
        uint256 totalUnstakingFee;
        uint256 totalRewardAmount;
        uint256 totalRewardFee;
    }

    struct TransactionProposal {
        uint256 id;
        address author;
        address to;
        uint256 value;
        bytes data;
        uint256 createdAt;
        uint256 votesForYes;
        uint256 votesForNo;
        uint256 totalVotes;
        uint256 endingAt;
        Status status;
    }

    struct ReqTotalVotesProposal {
        uint256 id;
        address author;
        uint256 newMinReqTotalVotes;
        uint256 newMinReqTotalVotesDenominator;
        uint256 createdAt;
        uint256 votesForYes;
        uint256 votesForNo;
        uint256 totalVotes;
        uint256 endingAt;
        Status status;
    }

    struct StakedVotesProposal {
        uint256 id;
        address author;
        uint256 newMinStakedVotes;
        uint256 newMinStakedVotesDenominator;
        uint256 createdAt;
        uint256 votesForYes;
        uint256 votesForNo;
        uint256 totalVotes;
        uint256 endingAt;
        Status status;
    }

    TransactionProposal[] public transactionProposals;
    ReqTotalVotesProposal[] public reqTotalVotesProposals;
    StakedVotesProposal[] public stakedVotesProposals;

    mapping(address => StakingData) private stakingDatas;
    mapping(address => AccountData) private accountDatas;
    mapping(address => mapping(uint256 => bool)) public transactionProposalStatus;
    mapping(address => mapping(uint256 => bool)) public reqTotalVotesProposalStatus;
    mapping(address => mapping(uint256 => bool)) public stakedVotesProposalStatus;
    mapping(address => uint256) public shares;

    event DepositAmount(address indexed sender, uint256 indexed amount);

    event AmountStaked(
        address indexed user,
        uint256 indexed depositAmount,
        uint256 indexed stakedAmount,
        uint256 stakingFee
    );

    event AmountUnstaked(
        address indexed user,
        uint256 indexed withdrawAmount,
        uint256 unstakeFee,
        uint256 rewardGained,
        uint256 rewardFee,
        uint256 durationInDays
    );

    event EmergencyWithdrawal(
        address indexed user,
        uint256 indexed withdrawAmount
    );

    event TransactionProposalSubmitted (
        uint256 indexed proposalId,
        address indexed author,
        address indexed to,
        uint256 value,
        bytes data,
        uint256 createdAt,
        uint256 votesForYes,
        uint256 votesForNo,
        uint256 totalVotes,
        uint256 endingAt,
        Status status
    );

    event VotedForTransactionProposal (
        uint256 indexed proposalId,
        address indexed stakeHolder,
        VotingOptions option
    );

    event ReqTotalVotesProposalSubmitted (
        uint256 indexed proposalId,
        address indexed author,
        uint256 newMinReqTotalVotes,
        uint256 newMinReqTotalVotesDenominator,
        uint256 createdAt,
        uint256 votesForYes,
        uint256 votesForNo,
        uint256 totalVotes,
        uint256 endingAt,
        Status status
    );

    event VotedForReqTotalVotesProposalProposal (
        uint256 indexed proposalId,
        address indexed stakeHolder,
        VotingOptions option
    );

    event StakedVotesProposalSubmitted (
        uint256 indexed proposalId,
        address indexed author,
        uint256 newMinStakedVotes,
        uint256 newMinStakedVotesDenominator,
        uint256 createdAt,
        uint256 votesForYes,
        uint256 votesForNo,
        uint256 totalVotes,
        uint256 endingAt,
        Status status
    );

    event VotedForStakedVotesProposal (
        uint256 indexed proposalId,
        address indexed stakeHolder,
        VotingOptions option
    );

    event TransactionProposalApproved(uint256 indexed proposalId);
    event TransactionProposalRejected(uint256 indexed proposalId);
    event ReqTotalVotesProposalProposalApproved(uint256 indexed proposalId);
    event ReqTotalVotesProposalProposalRejected(uint256 indexed proposalId);
    event StakedVotesProposalApproved(uint256 indexed proposalId);
    event StakedVotesProposalRejected(uint256 indexed proposalId);

    /**@dev Modifier used for restricting access 
     * only for the owner of the token
    */
    modifier onlyOwner() {
        require(
            i_owner == msg.sender,
            "ERROR: Function is only accessible by the owner of this contract"
        );
        _;
    }

    /**@dev Modifier used for restricting access
     * after setting the smart contract ready for staking.
    */
    modifier onlyBeforeStakingStarted() {
        require(!isStakingStarted, "ERROR: Staking already started");
        _;
    }

    /**@dev Modifier used for restricting access
     * before setting the smart contract ready for staking.
    */
    modifier onlyAfterStakingStarted() {
        require(isStakingStarted, "ERROR: Staking not started");
        _;
    }

    /**@dev Creates a staking platform for the REMIT token.
     * @param _token address of the ERC20 token, REMIT.
    */
    constructor(
        address _token,
        uint256 _minReqTotalVotes,
        uint256 _minReqTotalVotesDenominator,
        uint256 _minStakedVotes,
        uint256 _minStakedVotesDenominator
    ) {
        require(
            _token.isContract(),
            "ERROR: The given address is an EOA address"
        );

        require(
            !msg.sender.isContract(),
            "ERROR: You can not deploy this smart contract from another contract"
        );

        i_remitTokenAddress = _token;
        i_remitToken = RemitToken(_token);
        i_owner = msg.sender;
        minReqTotalVotes = _minReqTotalVotes;
        minReqTotalVotesDenominator = _minReqTotalVotesDenominator;
        minStakedVotes = _minStakedVotes;
        minStakedVotesDenominator = _minStakedVotesDenominator;
    }

    /**@dev receive function.*/
    receive() external payable {
        emit DepositAmount(msg.sender, msg.value);
    }

    /**@dev fallback function.*/
    fallback() external payable {
        emit DepositAmount(msg.sender, msg.value);
    }

    /**@dev Sets this smart contract ready for staking.
     * Requirements:
     *
     * - Only the owner of the token can call this function.
     * - This function can be called only once, 
         after the first allocation of REMIT token.
    */
    function startStaking() public onlyOwner nonReentrant onlyBeforeStakingStarted {
        isStakingStarted = true;
    }

    /**@dev Stakes an amount in to contract.
     * Requirements:
     *
     * - This function can be called only after executing the startStaking function
     * - The calling account must not be a contract account.
     * - The calling account must have at least token balance of _amount.
     *
     * @param _amount The original amount which will be deposited in the contract.
     *        1.5% of the _amount will be taken as staking fee.
     *        Reamining amount is taken for staking
    */
    function stakeAmount(uint256 _amount) public nonReentrant onlyAfterStakingStarted {
        require(
            !msg.sender.isContract(),
            "ERROR: msg.sender is another smart contract"
        );

        require(
            i_remitToken.balanceOf(msg.sender) >= _amount,
            "ERROR: User's token balance is low"
        );

        uint256 userStakingFee = _getStakingFee(_amount);
        uint256 userStakingAmount = _amount - userStakingFee;

        if(!_isAccountAvailable(msg.sender)) {
            accountDatas[msg.sender] = AccountData({
                doesAccountExists: true,
                totalDepositedAmount: _amount,
                totalStakedAmount: userStakingAmount,
                totalStakingFee: userStakingFee,
                totalUnstakingFee: 0,
                totalRewardAmount: 0,
                totalRewardFee: 0
            });
        } else {
            accountDatas[msg.sender].totalDepositedAmount += _amount;
            accountDatas[msg.sender].totalStakedAmount += userStakingAmount;
            accountDatas[msg.sender].totalStakingFee += userStakingFee;
        }

        if(_isUserStaking(msg.sender)) {
            uint256 stakedAmount = stakingDatas[msg.sender].stakingAmount;
            uint256 duration = _calculateStakingDuration(
                stakingDatas[msg.sender].stakingStartingTime,
                getCurrentTime()
            );

            uint256 rewardAmount = _getRewardAmount(stakedAmount, duration);
            uint256 rewardFee = _getStakingRewardsFee(rewardAmount);
            uint256 rewardGained = rewardAmount - rewardFee;

            stakingDatas[msg.sender].rewardGained = rewardGained;
            stakingDatas[msg.sender].rewardFee = rewardFee;

            stakingDatas[msg.sender].depositAmount += _amount;
            stakingDatas[msg.sender].stakingAmount += userStakingAmount;
            stakingDatas[msg.sender].stakingFee += userStakingFee;
            stakingDatas[msg.sender].stakingDurationInDays = duration;
        } else {
            stakingDatas[msg.sender].depositAmount = _amount;
            stakingDatas[msg.sender].stakingAmount = userStakingAmount;
            stakingDatas[msg.sender].stakingFee = userStakingFee;
            stakingDatas[msg.sender].isStaking = true;
        }

        stakingDatas[msg.sender].stakingStartingTime = getCurrentTime();
        stakingDatas[msg.sender].unlockingTime = _setUnlockingTime(
            stakingDatas[msg.sender].stakingStartingTime
        );
        stakingDatas[msg.sender].numberOfStakings++;

        totalStakedTokens += userStakingAmount;
        totalActiveStakeholders++;
        shares[msg.sender] = stakingDatas[msg.sender].stakingAmount;

        if(stakingDatas[msg.sender].numberOfStakings > 1) {
            require(
                i_remitToken.transfer(
                    msg.sender,
                    stakingDatas[msg.sender].rewardGained
                )
            );
            require(
                i_remitToken.transfer(
                    address(this),
                    stakingDatas[msg.sender].rewardFee
                )
            );
        }
        
        require(
            i_remitToken.transferFrom(
                msg.sender,
                address(this),
                userStakingAmount
            )
        );
        require(
            i_remitToken.transferFrom(
                msg.sender,
                address(this),
                userStakingFee
            )
        );

        emit AmountStaked(
            msg.sender,
            _amount,
            userStakingAmount,
            userStakingFee
        );
    }

    /**@dev Unstakes an amount from to contract.
     * Requirements:
     *
     * - This function can be called only after executing the startStaking function
     * - The calling account must not be a contract account.
     * - The calling account must have their account data in the contract.
     * - The account must be staking currently.
     * - This function can only be executemit ProposalRejected(_proposalId);ll be taken as reward fee.
     * - The remaining reward will be sent to the user.
    */
    function unstakeAmount() public nonReentrant onlyAfterStakingStarted {
        require(
            !msg.sender.isContract(),
            "ERROR: msg.sender is another smart contract"
        );

        require(
            _isAccountAvailable(msg.sender),
            "ERROR: User's account data is unavailable"
        );

        require(
            _isUserStaking(msg.sender),
            "ERROR: User is not staking currently"
        );

        require(
            !_isUserActiveInElection(msg.sender),
            "ERROR: User is actively participating in a proposal election"
        );

        uint256 unlockingTime = stakingDatas[msg.sender].unlockingTime;
        require(
            getCurrentTime() >= unlockingTime,
            "ERROR: Staked amount is still locked in the contract"
        );

        uint256 stakedAmount = stakingDatas[msg.sender].stakingAmount;
        uint256 userUnstakingFee = _getUnstakingFee(stakedAmount);
        uint256 availableStakedAmount = stakedAmount - userUnstakingFee;

        stakingDatas[msg.sender].unstakingFee = userUnstakingFee;
        stakingDatas[msg.sender].stakingEndingTime = getCurrentTime();
        stakingDatas[msg.sender].isStaking = false;

        uint256 durationInDays = _calculateStakingDuration(
            stakingDatas[msg.sender].stakingStartingTime,
            stakingDatas[msg.sender].stakingEndingTime
        );
        stakingDatas[msg.sender].stakingDurationInDays = durationInDays;

        uint256 rewardAmount = _getRewardAmount(
            stakedAmount,
            durationInDays
        );
        uint256 rewardFee = _getStakingRewardsFee(rewardAmount);
        uint256 rewardGained = rewardAmount - rewardFee;
        
        stakingDatas[msg.sender].rewardGained = rewardGained;
        stakingDatas[msg.sender].rewardFee = rewardFee;
        
        uint256 totalAmountAvailable = 
            availableStakedAmount + stakingDatas[msg.sender].rewardGained;

        stakingDatas[msg.sender].depositAmount = 0;
        stakingDatas[msg.sender].stakingAmount = 0;
        stakingDatas[msg.sender].numberOfStakings = 0;
        stakingDatas[msg.sender].stakingFee = 0;
        stakingDatas[msg.sender].stakingStartingTime = 0;
        stakingDatas[msg.sender].unlockingTime = 0;

        accountDatas[msg.sender].totalUnstakingFee += userUnstakingFee;
        accountDatas[msg.sender].totalRewardAmount += rewardGained;
        accountDatas[msg.sender].totalRewardFee += rewardFee;

        totalStakedTokens -= stakedAmount;
        totalActiveStakeholders--;
        shares[msg.sender] = 0;

        require(
            i_remitToken.balanceOf(address(this)) >= totalAmountAvailable,
            "ERROR: Staking contract balance is low."
        );

        require(i_remitToken.transfer(msg.sender, availableStakedAmount));
        require(i_remitToken.transfer(address(this), userUnstakingFee));
        require(i_remitToken.transfer(msg.sender, rewardGained));
        require(i_remitToken.transfer(address(this), rewardFee));

        emit AmountUnstaked(
            msg.sender,
            availableStakedAmount,
            userUnstakingFee,
            rewardGained,
            rewardFee,
            durationInDays
        );
    }

    /**@dev Emergency withrawal of the staked amount from to contract.
     * Requirements:
     *
     * - This function can be called only after executing the startStaking function
     * - The calling account must not be a contract account.
     * - The calling account must have their account data in the contract.
     * - The account must be staking currently.
    */
    function emergencyWithdrawal() public nonReentrant onlyAfterStakingStarted {
        require(
            !msg.sender.isContract(),
            "ERROR: msg.sender is another smart contract"
        );

        require(
            _isAccountAvailable(msg.sender),
            "ERROR: User's account data is unavailable"
        );

        require(
            _isUserStaking(msg.sender),
            "ERROR: User is not staking currently"
        );

        require(
            !_isUserActiveInElection(msg.sender),
            "ERROR: User is actively participating in a proposal election"
        );

        uint256 stakedAmount = stakingDatas[msg.sender].stakingAmount;
        uint256 stakingDurationInDays = _calculateStakingDuration(
            stakingDatas[msg.sender].stakingStartingTime,
            getCurrentTime()
        );

        uint256 rewardAmount = _getRewardAmount(
            stakedAmount,
            stakingDurationInDays
        );
        uint256 rewardFee = _getStakingRewardsFee(rewardAmount);
        uint256 rewardGained = rewardAmount - rewardFee;
        uint256 totalAmount = stakedAmount + rewardGained;

        require(
            i_remitToken.balanceOf(address(this)) < totalAmount,
            "ERROR: Emergency withdrawal not allowed"
        );

        stakingDatas[msg.sender] = StakingData({
            isStaking: false,
            depositAmount: 0,
            stakingAmount: 0,
            stakingFee: 0,
            numberOfStakings: 0,
            unstakingFee: 0,
            rewardGained: 0,
            rewardFee: 0,
            stakingStartingTime: 0,
            unlockingTime: 0,
            stakingEndingTime: 0,
            stakingDurationInDays: 0
        });

        totalStakedTokens -= stakedAmount;
        totalActiveStakeholders--;
        shares[msg.sender] = 0;

        require(i_remitToken.transfer(msg.sender, stakedAmount));

        emit EmergencyWithdrawal(msg.sender, stakedAmount);
    }

    /**@dev Submitting a transaction proposal for votting.
     * Requirements:
     *
     * - This function can be called only after executing the startStaking function
     * - The calling account must not be a contract account.
     * - The calling account must have their account data in the contract.
     * - The account must be staking currently.
     * - The given time duration must not be 0.
     *
     * @param _to address of the receiving account in which 
     *        the transaction must be executed.
     * @param _value value of ether which need to be sent along the transaction.
     * @param  _data bytes format of data which needed to be executed.
     * @param _timeDuration amount of time in which 
     *        this election process will be continued.
    */
    function submitTransactionProposal(
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _timeDuration
    ) public nonReentrant onlyAfterStakingStarted {
        require(
            !msg.sender.isContract(),
            "ERROR: msg.sender is another smart contract"
        );

        require(
            _isAccountAvailable(msg.sender),
            "ERROR: User's account data is unavailable"
        );

        require(
            _isUserStaking(msg.sender),
            "ERROR: User is not staking currently"
        );

        require(_timeDuration > 0, "ERROR: Zero time duration");

        uint256 currentTime = getCurrentTime();
        uint256 endingTIme = currentTime + _timeDuration;

        transactionProposals.push(
            TransactionProposal({
                id: nextTransactionProposalId,
                author: msg.sender,
                to: _to,
                value: _value,
                data: _data,
                createdAt: currentTime,
                votesForYes: 0,
                votesForNo: 0,
                totalVotes: 0,
                endingAt: endingTIme,
                status: Status.Pending
            })
        );

        nextTransactionProposalId++;

        emit TransactionProposalSubmitted (
            nextTransactionProposalId-1,
            msg.sender,
            _to,
            _value,
            _data,
            currentTime,
            0,
            0,
            0,
            endingTIme,
            Status.Pending
        );
    }

    /**@dev Votting on a submitted transaction proposal.
     * Requirements:
     *
     * - This function can be called only after executing the startStaking function
     * - The calling account must not be a contract account.
     * - The calling account must have their account data in the contract.
     * - The account must be staking currently.
     * - The given proposal id must be a valid and existing one.
     * - The given proposal must have Pending status.
     * - This account shouldn't have voted on this proposal before.
     * - The time duration for the given proposal must not be expired.
     *
     * @param _proposalId index of the proposal in which 
     *        the data lies in the transactionProposals array.
     * @param _vote voting option Yes/No (0 or 1).
    */
    function voteTransactionProposal(
        uint256 _proposalId,
        VotingOptions _vote
    ) public nonReentrant onlyAfterStakingStarted {
        require(
            !msg.sender.isContract(),
            "ERROR: msg.sender is another smart contract"
        );

        require(
            _isAccountAvailable(msg.sender),
            "ERROR: User's account data is unavailable"
        );

        require(
            _isUserStaking(msg.sender),
            "ERROR: User is not staking currently"
        );

        require(
            _proposalId < nextTransactionProposalId,
            "ERROR: Invalid proposal id"
        );

        TransactionProposal storage proposal = transactionProposals[_proposalId];
        
        require(
            proposal.status == Status.Pending,
            "ERROR: Decision is made on this proposal"
        );

        require(
            transactionProposalStatus[msg.sender][_proposalId] == false,
            "ERROR: User already voted"
        );

        require(
            block.timestamp <= proposal.endingAt,
            "ERROR: Voting period is over"
        );

        transactionProposalStatus[msg.sender][_proposalId] = true;
        if(_vote == VotingOptions.Yes) {
            proposal.votesForYes += shares[msg.sender];
            
        } else {
            proposal.votesForNo += shares[msg.sender];
            
        }
        proposal.totalVotes += shares[msg.sender];
        uint256 totalSupply = i_remitToken.totalSupply();
        uint256 reqPercent = 
            (totalSupply * minReqTotalVotes) / minReqTotalVotesDenominator;

        emit VotedForTransactionProposal (
            _proposalId,
            msg.sender,
            _vote
        );
        
        if (proposal.totalVotes >= reqPercent) {
            if(proposal.votesForYes >= totalStakedTokens / 2 + 1) {
                // ((proposal.votesForYes * 100) / totalStakedTokens) > 50
                proposal.status = Status.Accepted;

                (bool success, ) = proposal.to.call{value: proposal.value}(
                    proposal.data
                );

                require(success, "ERROR: Proposed transaction failed");

                emit TransactionProposalApproved(_proposalId);
            }

            if(proposal.votesForNo >= totalStakedTokens / 2 + 1) {
                // ((proposal.votesForNo * 100) / totalStakedTokens) > 50
                proposal.status = Status.Rejected;

                emit TransactionProposalRejected(_proposalId);
            }
        }
    }

    /**@dev Finalize a deciosion on a submitted transaction proposal.
     * Requirements:
     *
     * - This function can be called only after executing the startStaking function
     * - The calling account must not be a contract account.
     * - The given proposal id must be a valid and existing one.
     * - The given proposal must have Pending status.
     * - The time duration for the given proposal must be expired.
     *
     * @param _proposalId index of the proposal in which 
     *        the data lies in the transactionProposals array.
    */
    function finalizeTransactionProposal(
        uint256 _proposalId
    ) public nonReentrant onlyAfterStakingStarted {
        require(
            !msg.sender.isContract(),
            "ERROR: msg.sender is another smart contract"
        );

        require(
            _proposalId < nextTransactionProposalId,
            "ERROR: Invalid proposal id"
        );

        TransactionProposal storage proposal = transactionProposals[_proposalId];
        
        require(
            proposal.status == Status.Pending,
            "ERROR: Decision is made on this proposal"
        );

        require(
            block.timestamp > proposal.endingAt,
            "ERROR: Voting period is not over"
        );

        uint256 totalSupply = i_remitToken.totalSupply();
        uint256 reqPercent = 
            (totalSupply * minReqTotalVotes) / minReqTotalVotesDenominator;
        uint256 reqStakedVotes = 
            (totalStakedTokens * minStakedVotes) / minStakedVotesDenominator;

        if (
            totalStakedTokens >= reqPercent && 
            proposal.totalVotes >= reqStakedVotes
        ) {
            if (proposal.votesForYes >= proposal.totalVotes / 2 + 1) {
                // ((proposal.votesForYes * 100) / totalStakedTokens) > 50
                proposal.status = Status.Accepted;

                (bool success, ) = proposal.to.call{value: proposal.value}(
                    proposal.data
                );

                require(success, "ERROR: Proposed transaction failed");

                emit TransactionProposalApproved(_proposalId);
            }

            if (proposal.votesForNo >= proposal.totalVotes / 2 + 1) {
                // ((proposal.votesForNo * 100) / totalStakedTokens) > 50
                proposal.status = Status.Rejected;

                emit TransactionProposalRejected(_proposalId);
            }
        }
    }

    /**@dev Submitting a proposal for the minimum required amount of tokens
     *      from the entire token supply for votting.
     * Requirements:
     *
     * - This function can be called only after executing the startStaking function
     * - The calling account must not be a contract account.
     * - The calling account must have their account data in the contract.
     * - The account must be staking currently.
     * - Both of the numerator and denominator values of required amount
     *   must not be zero.
     * - Both of the numerator and denominator values of required amount
     *   must not be equal to the current amount.
     * - The given time duration must not be 0.
     *
     * @param _minReqTotalVotes numerator of the minimum required amount of tokens
     *        from the entire token supply for votting.
     * @param _minReqTotalVotesDenominator denominator of the minimum required amount 
     *        of tokens from the entire token supply for votting.
     * @param _timeDuration amount of time in which 
     *        this election process will be continued.
    */
    function submitProposalForMinReqTokens(
        uint256 _minReqTotalVotes,
        uint256 _minReqTotalVotesDenominator,
        uint256 _timeDuration
    ) public nonReentrant onlyAfterStakingStarted {
        require(
            !msg.sender.isContract(),
            "ERROR: msg.sender is another smart contract"
        );

        require(
            _isAccountAvailable(msg.sender),
            "ERROR: User's account data is unavailable"
        );

        require(
            _isUserStaking(msg.sender),
            "ERROR: User is not staking currently"
        );

        require(
            _minReqTotalVotes != 0 && _minReqTotalVotesDenominator != 0,
            "ERROR: Invalid required total votes"
        );

        require(
            _minReqTotalVotes != minReqTotalVotes,
            "ERROR: Must enter amount which is not the current amount"
        );

        require(_timeDuration > 0, "ERROR: Zero time duration");

        uint256 currentTime = getCurrentTime();
        uint256 endingTIme = currentTime + _timeDuration;

        reqTotalVotesProposals.push(
            ReqTotalVotesProposal({
                id: nextReqTotalVotesProposalId,
                author: msg.sender,
                newMinReqTotalVotes: 
                    _minReqTotalVotes,
                newMinReqTotalVotesDenominator: 
                    _minReqTotalVotesDenominator,
                createdAt: currentTime,
                votesForYes: 0,
                votesForNo: 0,
                totalVotes: 0,
                endingAt: endingTIme,
                status: Status.Pending
            })
        );

        nextReqTotalVotesProposalId++;

        emit ReqTotalVotesProposalSubmitted (
            nextReqTotalVotesProposalId-1,
            msg.sender,
            _minReqTotalVotes,
            _minReqTotalVotesDenominator,
            currentTime,
            0,
            0,
            0,
            endingTIme,
            Status.Pending
        );
    }

    /**@dev Votting on a submitted proposal on the minimum required amount of tokens
     *      from the entire token supply for votting.
     * Requirements:
     *
     * - This function can be called only after executing the startStaking function
     * - The calling account must not be a contract account.
     * - The calling account must have their account data in the contract.
     * - The account must be staking currently.
     * - The given proposal id must be a valid and existing one.
     * - The given proposal must have Pending status.
     * - This account shouldn't have voted on this proposal before.
     * - The time duration for the given proposal must not be expired.
     *
     * @param _proposalId index of the proposal in which 
     *        the data lies in the reqTotalVotesProposals array.
     * @param _vote voting option Yes/No (0 or 1).
    */
    function voteProposalForMinReqTokens(
        uint256 _proposalId,
        VotingOptions _vote
    ) public nonReentrant onlyAfterStakingStarted {
        require(
            !msg.sender.isContract(),
            "ERROR: msg.sender is another smart contract"
        );

        require(
            _isAccountAvailable(msg.sender),
            "ERROR: User's account data is unavailable"
        );

        require(
            _isUserStaking(msg.sender),
            "ERROR: User is not staking currently"
        );

        require(
            _proposalId < nextReqTotalVotesProposalId,
            "ERROR: Invalid proposal id"
        );

        ReqTotalVotesProposal storage proposal = 
            reqTotalVotesProposals[_proposalId];
        
        require(
            proposal.status == Status.Pending,
            "ERROR: Decision is made on this proposal"
        );

        require(
            reqTotalVotesProposalStatus[msg.sender][_proposalId] == false,
            "ERROR: User already voted"
        );

        require(
            block.timestamp <= proposal.endingAt,
            "ERROR: Voting period is over"
        );

        reqTotalVotesProposalStatus[msg.sender][_proposalId] = true;
        if(_vote == VotingOptions.Yes) {
            proposal.votesForYes += shares[msg.sender];
        } else {
            proposal.votesForNo += shares[msg.sender];
        }
        proposal.totalVotes += shares[msg.sender];
        uint256 totalSupply = i_remitToken.totalSupply();
        uint256 reqPercent = 
            (totalSupply * minReqTotalVotes) / minReqTotalVotesDenominator;

        emit VotedForReqTotalVotesProposalProposal (
            _proposalId,
            msg.sender,
            _vote
        );
        
        if (proposal.totalVotes >= reqPercent) {
            if(proposal.votesForYes >= totalStakedTokens / 2 + 1) {
                proposal.status = Status.Accepted;

                (
                    minReqTotalVotes,
                    minReqTotalVotesDenominator
                ) = (
                    proposal.newMinReqTotalVotes,
                    proposal.newMinReqTotalVotesDenominator
                );

                emit ReqTotalVotesProposalProposalApproved(_proposalId);
            }

            if(proposal.votesForNo >= totalStakedTokens / 2 + 1) {
                proposal.status = Status.Rejected;

                emit ReqTotalVotesProposalProposalRejected(_proposalId);
            }
        }
    }

    /**@dev Finalize a deciosion on a submitted proposal on the minimum required 
     *      amount of tokens from the entire token supply for votting.
     * Requirements:
     *
     * - This function can be called only after executing the startStaking function
     * - The calling account must not be a contract account.
     * - The given proposal id must be a valid and existing one.
     * - The given proposal must have Pending status.
     * - The time duration for the given proposal must be expired.
     *
     * @param _proposalId index of the proposal in which 
     *        the data lies in the reqTotalVotesProposals array.
    */
    function finalizeProposalForMinReqTokens(
        uint256 _proposalId
    ) public nonReentrant onlyAfterStakingStarted {
        require(
            !msg.sender.isContract(),
            "ERROR: msg.sender is another smart contract"
        );

        require(
            _proposalId < nextReqTotalVotesProposalId,
            "ERROR: Invalid proposal id"
        );

        ReqTotalVotesProposal storage proposal = 
            reqTotalVotesProposals[_proposalId];
        
        require(
            proposal.status == Status.Pending,
            "ERROR: Decision is made on this proposal"
        );

        require(
            block.timestamp > proposal.endingAt,
            "ERROR: Voting period is not over"
        );

        uint256 totalSupply = i_remitToken.totalSupply();
        uint256 reqPercent = 
            (totalSupply * minReqTotalVotes) / minReqTotalVotesDenominator;
        uint256 reqStakedVotes = 
            (totalStakedTokens * minStakedVotes) / minStakedVotesDenominator;

        if (
            totalStakedTokens >= reqPercent && 
            proposal.totalVotes >= reqStakedVotes
        ) {
            if (proposal.votesForYes >= proposal.totalVotes / 2 + 1) {
                proposal.status = Status.Accepted;

                (
                    minReqTotalVotes,
                    minReqTotalVotesDenominator
                ) = (
                    proposal.newMinReqTotalVotes,
                    proposal.newMinReqTotalVotesDenominator
                );

                emit ReqTotalVotesProposalProposalApproved(_proposalId);
            }

            if (proposal.votesForNo >= proposal.totalVotes / 2 + 1) {
                proposal.status = Status.Rejected;

                emit ReqTotalVotesProposalProposalRejected(_proposalId);
            }
        }
    }
    
    /**@dev Submitting a proposal for the minimum required amount of tokens
     *      from the entire staked tokens for votting.
     * Requirements:
     *
     * - This function can be called only after executing the startStaking function
     * - The calling account must not be a contract account.
     * - The calling account must have their account data in the contract.
     * - The account must be staking currently.
     * - Both of the numerator and denominator values of required amount
     *   must not be zero.
     * - Both of the numerator and denominator values of required amount
     *   must not be equal to the current amount.
     * - The given time duration must not be 0.
     *
     * @param _minStakedVotes numerator of the minimum required amount of tokens
     *        from the entire staked tokens for votting.
     * @param _minStakedVotesDenominator denominator of the minimum required amount 
     *        of tokens from the entire staked tokens for votting.
     * @param _timeDuration amount of time in which 
     *        this election process will be continued.
    */
    function submitProposalForStakedVotes(
        uint256 _minStakedVotes,
        uint256 _minStakedVotesDenominator,
        uint256 _timeDuration
    ) public nonReentrant onlyAfterStakingStarted {
        require(
            !msg.sender.isContract(),
            "ERROR: msg.sender is another smart contract"
        );

        require(
            _isAccountAvailable(msg.sender),
            "ERROR: User's account data is unavailable"
        );

        require(
            _isUserStaking(msg.sender),
            "ERROR: User is not staking currently"
        );

        require(
            _minStakedVotes != 0 && _minStakedVotesDenominator != 0,
            "ERROR: Invalid required staked votes"
        );

        require(
            _minStakedVotes != minStakedVotes,
            "ERROR: Must enter amount which is not the current amount"
        );

        require(_timeDuration > 0, "ERROR: Zero time duration");

        uint256 currentTime = getCurrentTime();
        uint256 endingTIme = currentTime + _timeDuration;

        stakedVotesProposals.push(
            StakedVotesProposal({
                id: nextStakedVotesProposalId,
                author: msg.sender,
                newMinStakedVotes: 
                    _minStakedVotes,
                newMinStakedVotesDenominator: 
                    _minStakedVotesDenominator,
                createdAt: currentTime,
                votesForYes: 0,
                votesForNo: 0,
                totalVotes: 0,
                endingAt: endingTIme,
                status: Status.Pending
            })
        );

        nextStakedVotesProposalId++;

        emit StakedVotesProposalSubmitted (
            nextStakedVotesProposalId-1,
            msg.sender,
            _minStakedVotes,
            _minStakedVotesDenominator,
            currentTime,
            0,
            0,
            0,
            endingTIme,
            Status.Pending
        );
    }

    /**@dev Votting on a submitted proposal on the minimum required amount of tokens
     *      from the entire staked tokens for votting.
     * Requirements:
     *
     * - This function can be called only after executing the startStaking function
     * - The calling account must not be a contract account.
     * - The calling account must have their account data in the contract.
     * - The account must be staking currently.
     * - The given proposal id must be a valid and existing one.
     * - The given proposal must have Pending status.
     * - This account shouldn't have voted on this proposal before.
     * - The time duration for the given proposal must not be expired.
     *
     * @param _proposalId index of the proposal in which 
     *        the data lies in the stakedVotesProposals array.
     * @param _vote voting option Yes/No (0 or 1).
    */
    function voteProposalForStakedVotes(
        uint256 _proposalId,
        VotingOptions _vote
    ) public nonReentrant onlyAfterStakingStarted {
        require(
            !msg.sender.isContract(),
            "ERROR: msg.sender is another smart contract"
        );

        require(
            _isAccountAvailable(msg.sender),
            "ERROR: User's account data is unavailable"
        );

        require(
            _isUserStaking(msg.sender),
            "ERROR: User is not staking currently"
        );

        require(
            _proposalId < nextStakedVotesProposalId,
            "ERROR: Invalid proposal id"
        );

        StakedVotesProposal storage proposal = 
            stakedVotesProposals[_proposalId];
        
        require(
            proposal.status == Status.Pending,
            "ERROR: Decision is made on this proposal"
        );

        require(
            stakedVotesProposalStatus[msg.sender][_proposalId] == false,
            "ERROR: User already voted"
        );

        require(
            block.timestamp <= proposal.endingAt,
            "ERROR: Voting period is over"
        );

        stakedVotesProposalStatus[msg.sender][_proposalId] = true;
        if(_vote == VotingOptions.Yes) {
            proposal.votesForYes += shares[msg.sender];
        } else {
            proposal.votesForNo += shares[msg.sender];
        }
        proposal.totalVotes += shares[msg.sender];
        uint256 totalSupply = i_remitToken.totalSupply();
        uint256 reqPercent = 
            (totalSupply * minReqTotalVotes) / minReqTotalVotesDenominator;

        emit VotedForStakedVotesProposal (
            _proposalId,
            msg.sender,
            _vote
        );
        
        if (proposal.totalVotes >= reqPercent) {
            if(proposal.votesForYes >= totalStakedTokens / 2 + 1) {
                proposal.status = Status.Accepted;

                (
                    minStakedVotes,
                    minStakedVotesDenominator
                ) = (
                    proposal.newMinStakedVotes,
                    proposal.newMinStakedVotesDenominator
                );

                emit StakedVotesProposalApproved(_proposalId);
            }

            if(proposal.votesForNo >= totalStakedTokens / 2 + 1) {
                proposal.status = Status.Rejected;

                emit StakedVotesProposalRejected(_proposalId);
            }
        }
    }

    /**@dev Finalize a deciosion on a submitted proposal on the minimum 
     *      required amount of tokens from the entire staked tokens for votting.
     * Requirements:
     *
     * - This function can be called only after executing the startStaking function
     * - The calling account must not be a contract account.
     * - The given proposal id must be a valid and existing one.
     * - The given proposal must have Pending status.
     * - The time duration for the given proposal must be expired.
     *
     * @param _proposalId index of the proposal in which 
     *        the data lies in the stakedVotesProposals array.
    */
    function finalizeProposalForStakedVotes(
        uint256 _proposalId
    ) public nonReentrant onlyAfterStakingStarted {
        require(
            !msg.sender.isContract(),
            "ERROR: msg.sender is another smart contract"
        );

        require(
            _proposalId < nextStakedVotesProposalId,
            "ERROR: Invalid proposal id"
        );

        StakedVotesProposal storage proposal = 
            stakedVotesProposals[_proposalId];
        
        require(
            proposal.status == Status.Pending,
            "ERROR: Decision is made on this proposal"
        );

        require(
            block.timestamp > proposal.endingAt,
            "ERROR: Voting period is not over"
        );

        uint256 totalSupply = i_remitToken.totalSupply();
        uint256 reqPercent = 
            (totalSupply * minReqTotalVotes) / minReqTotalVotesDenominator;
        uint256 reqStakedVotes = 
            (totalStakedTokens * minStakedVotes) / minStakedVotesDenominator;

        if (
            totalStakedTokens >= reqPercent && 
            proposal.totalVotes >= reqStakedVotes
        ) {
            if (proposal.votesForYes >= proposal.totalVotes / 2 + 1) {
                proposal.status = Status.Accepted;

                (
                    minStakedVotes,
                    minStakedVotesDenominator
                ) = (
                    proposal.newMinStakedVotes,
                    proposal.newMinStakedVotesDenominator
                );

                emit StakedVotesProposalApproved(_proposalId);
            }

            if (proposal.votesForNo >= proposal.totalVotes / 2 + 1) {
                proposal.status = Status.Rejected;

                emit StakedVotesProposalRejected(_proposalId);
            }
        }
    }

    /**@dev Function to get the current timestamp.*/
    function getCurrentTime() public view returns(uint256) {
        return block.timestamp;
    }

    /**@dev Function to get the current token balance of this contract.*/
    function getContractBalance() public view returns(uint256) {
        return i_remitToken.balanceOf(address(this));
    }

    /**@dev Function to get the staking data of user.
     *
     * @param _account address of a user.
    */
    function getStakingData(
        address _account
    ) external view returns(StakingData memory) {
        return stakingDatas[_account];
    }
    
    /**@dev Function to get the account data of a user
     *
     * @param _account address of a user.
    */
    function getAccountData(
        address _account
    ) external view returns(AccountData memory) {
        return accountDatas[_account];
    }

    /**@dev Function to get the transaction proposal data
     *
     * @param _proposalId index of a proposal in the transactionProposals array.
    */
    function getTransactionProposalData(
        uint256 _proposalId
    ) external view returns(TransactionProposal memory) {
        return transactionProposals[_proposalId];
    }

    /**@dev Function to get the minimum total request votes data
     *
     * @param _proposalId index of a proposal in the reqTotalVotesProposals array.
    */
    function getMinReqTotalVotesProposalData(
        uint256 _proposalId
    ) external view returns(ReqTotalVotesProposal memory) {
        return reqTotalVotesProposals[_proposalId];
    }

    /**@dev Function to get the staked votes proposal data
     *
     * @param _proposalId index of a proposal in the stakedVotesProposals array.
    */
    function getMinStakedVotesProposalData(
        uint256 _proposalId
    ) external view returns(StakedVotesProposal memory) {
        return stakedVotesProposals[_proposalId];
    }

    /**@dev Function to check whether the user have staked
     * in this contract at least once.
     *
     * @param _account address of a user.
    */
    function _isAccountAvailable(address _account) private view returns(bool) {
        return accountDatas[_account].doesAccountExists ? true: false;
    }

    /**@dev Function to check whether the user is staking currently.
     *
     * @param _account address of a user.
    */
    function _isUserStaking(address _account) private view returns(bool) {
        return stakingDatas[_account].isStaking ? true : false;
    }

    function _isUserActiveInElection(address _account) private view returns(bool) {
        uint256 currentTime = getCurrentTime();
        for (uint256 i; i < nextTransactionProposalId; i++) {
            if (
                transactionProposalStatus[_account][i] && 
                currentTime <= transactionProposals[i].endingAt &&
                transactionProposals[i].status == Status.Pending
            ) {
                return true;
            }
        }

        for (uint256 i; i < nextReqTotalVotesProposalId; i++) {
            if (
                reqTotalVotesProposalStatus[_account][i] && 
                currentTime <= transactionProposals[i].endingAt &&
                transactionProposals[i].status == Status.Pending
            ) {
                return true;
            }
        }

        for (uint256 i; i < nextStakedVotesProposalId; i++) {
            if (
                stakedVotesProposalStatus[_account][i] && 
                currentTime <= transactionProposals[i].endingAt &&
                transactionProposals[i].status == Status.Pending
            ) {
                return true;
            }
        }
        return false;
    }

    /**@dev Function to unstaking unlocking time.
     *
     * @param _time staking starting time.
    */
    function _setUnlockingTime(uint256 _time) private pure returns(uint256) {
        return _time + MINIMUM_LOCK_TIME;
    }

    /**@dev Function to get the reward amount.
     *
     * @param _stakedBalance initial staked balance by a user.
     * @param _duration staking duration in days.
    */
    function _getRewardAmount(
        uint256 _stakedBalance,
        uint256 _duration
    ) private pure returns(uint256) {
        return ((_stakedBalance * 2) * _duration) / 1000;
    }

    /**@dev Function to get the staking fee
     *
     * @param _amount initially deposited amount by a user.
    */
    function _getStakingFee(uint256 _amount) private pure returns(uint256) {
        return (_amount * 15) / 1000;
    }

    /**@dev Function to get the unstaking fee
     *
     * @param _amount initially staked amount by a user.
    */
    function _getUnstakingFee(uint256 _amount) private pure returns(uint256) {
        return (_amount * 5) / 1000;
    }

    /**@dev Function to get the staking rewards fee
     *
     * @param _amount initially staked amount by a user.
    */
    function _getStakingRewardsFee(uint256 _amount) private pure returns(uint256) {
        return (_amount * 5) / 100;
    }

    /**@dev Function to calculate the staking duration in days
     *
     * @param _start staking starting time.
     * @param _end staking ending time.
    */
    function _calculateStakingDuration(
        uint256 _start,
        uint256 _end
    ) private pure returns(uint256) {
        return (_end - _start) / 60;
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev This is a ERC20 token.
 * @author MikhilMC
 * This token have a capped limited supply of 5000000.
 * Every year, 1000000 number of tokens are released.
 */
contract RemitToken is ERC20Capped, ReentrancyGuard {
    using Address for address;

    uint256 public tokenAllocationCount;
    uint256 public lastTokenIssuanceTime;
    bool public doesContractsAssigned;

    address public remitExchangeContractAddress;
    address public stakingContractAddress;
    address public farmingContractAddress;

    address public immutable i_owner;
    address public immutable i_teamAndAdvisors;
    address public immutable i_developmentFund;
    address public immutable i_marketingFund;
    address public immutable i_reserveFund;

    uint256 public constant CAPPED_SUPPLY = 5000000 * 1e18;
    uint256 public constant YEARLY_SUPPLY = 1000000 * 1e18;
    uint256 public constant CIRCULATION_SUPPLY_AMOUNT = 
        (YEARLY_SUPPLY * 37) / 100;
    uint256 public constant STAKING_AND_FARMING_AMOUNT = 
        (YEARLY_SUPPLY * 35) / 100;
    uint256 public constant STAKING_AND_FARMING_INDIVIDUAL_AMOUNT = 
        STAKING_AND_FARMING_AMOUNT / 2;
    uint256 public constant TEAM_AND_ADVISORS_AMOUNT = 
        (YEARLY_SUPPLY * 10) / 100;
    uint256 public constant DEVELOPMENT_FUND_AMOUNT = 
        (YEARLY_SUPPLY * 12) / 100;
    uint256 public constant MARKETING_FUND_AMOUNT = 
        (YEARLY_SUPPLY * 5) / 100;
    uint256 public constant RESERVED_FUND_AMOUNT = 
        (YEARLY_SUPPLY * 1) / 100;
    uint256 public constant TEAM_AND_ADVISORS_NORMAL_MONTHLY_AMOUNT = 
        (TEAM_AND_ADVISORS_AMOUNT * 8) / 100;
    uint256 public constant TEAM_AND_ADVISORS_SPECIAL_MONTHLY_AMOUNT = 
        TEAM_AND_ADVISORS_AMOUNT - (TEAM_AND_ADVISORS_NORMAL_MONTHLY_AMOUNT * 11);
    uint256 public constant DEVELOPMENT_FUND_MONTHLY_AMOUNT = 
        (DEVELOPMENT_FUND_AMOUNT * 20) /100;

    /**@dev Modifier used for restricting access only for the owner of the token
     */
    modifier onlyOwner() {
        require(
            i_owner == msg.sender,
            "ERROR: Only the owner of this contract is allowed to execute this function"
        );
        _;
    }

    /**@dev Modifier used for restricting access if the addresses
     *      of the essentail contracts are not available.
     */
    modifier onContractsNotAvailable() {
        require(
            !doesContractsAssigned,
            "ERROR: Essential contracts are not available"
        );
        _;
    }

    /**@dev Modifier used for restricting access if the addresses
     *      of the essentail contracts are available.
     */
    modifier onContractsAvailable() {
        require(
            doesContractsAssigned,
            "ERROR: Essential contracts are already available"
        );
        _;
    }

    /**@dev Creates the ERC20 token REMIT.
     * @param _teamAndAdvisors address of an EOA representing Team and Advisors.
     * @param _developmentFund address of an EOA representing Development Fund.
     * @param _marketingFund address of an EOA representing Marketing Fund.
     * @param _reserveFund address of an EOA representing Reserve Fund.
     */
    constructor(
        address _teamAndAdvisors,
        address _developmentFund,
        address _marketingFund,
        address _reserveFund
    ) ERC20("Remit Token", "REMIT") ERC20Capped(CAPPED_SUPPLY){
        require(
            !msg.sender.isContract(),
            "ERROR: Can't deploy this contract from a contract address."
        );

        require(
            !_teamAndAdvisors.isContract(),
            "ERROR: Given Team and Advisors address is a contract address."
        );

        require(
            !_developmentFund.isContract(),
            "ERROR: Given Development Fund address is a contract address."
        );

        require(
            !_marketingFund.isContract(),
            "ERROR: Given Marketing Fund address is a contract address."
        );

        require(
            !_reserveFund.isContract(),
            "ERROR: Given Reserve Fund address is a contract address."
        );

        (
            i_owner,
            i_teamAndAdvisors,
            i_developmentFund,
            i_marketingFund,
            i_reserveFund
        ) = (
            msg.sender,
            _teamAndAdvisors,
            _developmentFund,
            _marketingFund,
            _reserveFund
        );
    }

    /**@dev Enters the required contract addresses to Token contracts.
     * Requirements:
     *
     * - Only the owner of the token can call this function.
     * - This function can be called only once, after the deployment of the contract.
     * - All 3 addresses must not be equal to zero address.
     * - All 3 addresses must be contract addresses.
     *
     * @param _remitExchangeContractAddress address of contract,
     *         which is used for the circulation supply of REMIT exchange
     * @param _stakingContractAddress address of REMIT token Staking contract
     * @param _farmingContractAddress address of REMIT token Farming contract
     */
    function enterContractAddresses(
        address _remitExchangeContractAddress,
        address _stakingContractAddress,
        address _farmingContractAddress
    ) public onlyOwner onContractsNotAvailable {
        require(
            _remitExchangeContractAddress != address(0),
            "ERROR: Given REMIT exchange contract address is a Zero address."
        );
        
        require(
            _stakingContractAddress != address(0),
            "ERROR: Given Staking contract address is a Zero address."
        );
        
        require(
            _farmingContractAddress != address(0),
            "ERROR: Given Farming contract address is a Zero address."
        );
        
        require(
            _remitExchangeContractAddress.isContract(),
            "ERROR: Given REMIT exchange contract address is not a contract address."
        );
        
        require(
            _stakingContractAddress.isContract(),
            "ERROR: Given Staking contract address is not a contract address."
        );
        
        require(
            _farmingContractAddress.isContract(),
            "ERROR: Given Farming contract address is not a contract address."
        );
        (
            remitExchangeContractAddress,
            stakingContractAddress,
            farmingContractAddress
        ) = (
            _remitExchangeContractAddress,
            _stakingContractAddress,
            _farmingContractAddress
        );
        doesContractsAssigned = true;
    }

    /**@dev Issues the REMIT tokens.
     * Requirements:
     *
     * - Only the owner of the token can call this function.
     * - tokenAllocationCount must be less than 60.
     * - The current time must be grater than or equal to the next token issuing time limit.
     */
    function issueToken() public onlyOwner onContractsAvailable nonReentrant{
        require(tokenAllocationCount < 60, "Token supply ended");
        uint256 nextTokenSupplyTime = getNextTokenAllocationTime();
        require(
            nextTokenSupplyTime <= getCurrentTime(),
            "Token issue not possible currently"
        );
        uint256 mod12Value = tokenAllocationCount % 12;
        if(mod12Value == 0) {
            _mint(remitExchangeContractAddress, CIRCULATION_SUPPLY_AMOUNT);
            _mint(stakingContractAddress, STAKING_AND_FARMING_INDIVIDUAL_AMOUNT);
            _mint(farmingContractAddress, STAKING_AND_FARMING_INDIVIDUAL_AMOUNT);
            _mint(i_marketingFund, MARKETING_FUND_AMOUNT);
            _mint(i_reserveFund, RESERVED_FUND_AMOUNT);
        }

        if(mod12Value >= 0 && mod12Value < 5) {
            _mint(i_developmentFund, DEVELOPMENT_FUND_MONTHLY_AMOUNT);
        }

        if(mod12Value == 0) {
            _mint(i_teamAndAdvisors, TEAM_AND_ADVISORS_SPECIAL_MONTHLY_AMOUNT);
        } else {
            _mint(i_teamAndAdvisors, TEAM_AND_ADVISORS_NORMAL_MONTHLY_AMOUNT);
        }

        tokenAllocationCount += 1;
        lastTokenIssuanceTime = getCurrentTime();
    }

    /**@dev Function to burn token. Out of 3% of that amount will be sent to
     * the Development Fund, and the remaining fund will be burned.
     * Requirements
     *
     * - The user must have at least _amount of tokens in their account
     * @param _amount amount of token to be burned
     */
    function burnToken(uint256 _amount) public onContractsAvailable nonReentrant{
        uint256 devAmount = (_amount * 3) / 100;
        uint256 burningAmount = _amount - devAmount;
        _transfer(msg.sender, i_developmentFund, devAmount);
        _burn(msg.sender, burningAmount);
    }

    /**@dev Function to get the next Token allocation time.*/
    function getNextTokenAllocationTime() public view returns(uint256) {
        return getLastTokenIssuanceTime() + 1 minutes;
    }

    /**@dev Function to get the current time.*/
    function getCurrentTime() public view returns(uint256) {
        return block.timestamp;
    }

    /**@dev Function to get time at which the last token is issued.*/
    function  getLastTokenIssuanceTime() public view returns(uint256) {
        return lastTokenIssuanceTime;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
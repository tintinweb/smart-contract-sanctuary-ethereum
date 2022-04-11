//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";
import "./IJob.sol";

contract Job is IJob, Proxied, Initializable {
    using SafeERC20 for IERC20;

    /*************
     * Constants *
     *************/

    // Used for math
    uint256 constant BASE_PERCENTAGE = 10_000;

    // 1% - this is not configurable
    uint256 constant MINIMUM_SPLIT_CHUNK_PERCENTAGE = 100;

    uint256 constant MAX_DAO_FEE = 2500; // 25%

    uint256 constant MAX_RESOLUTION_FEE_PERCENTAGE = 2500; // 25%

    uint256 constant MIN_COMPLETED_TIMEOUT_SECONDS = 3 days;
    uint256 constant MAX_COMPLETED_TIMEOUT_SECONDS = 30 days;

    uint256 constant MIN_REPORT_DEPOSIT = 10e18; // $10
    uint256 constant MAX_REPORT_DEPOSIT = 200e18; // $200

    uint256 constant MAX_REPORT_REWARD_PERCENT = 2500; // 25%

    /*************
     * Variables *
     *************/

    // 50 paymentTokens ($50)
    uint256 public MINIMUM_BOUNTY;
    // 50 paymentTokens ($50)
    uint256 public MINIMUM_DEPOSIT;

    // DAO Fee 10%
    uint256 public DAO_FEE;

    // Resolution Fee 10%
    uint256 public RESOLUTION_FEE_PERCENTAGE;

    // Timeout after job is completed before job is awarded to engineer
    uint256 public COMPLETED_TIMEOUT_SECONDS;

    // Deposit required to report a job
    uint256 public REPORT_DEPOSIT;

    // Type of token used for reporting a job
    IERC20 public REPORT_TOKEN;

    // 10% - Reward of the bounty given to a successful reporter
    uint256 public REPORT_REWARD_PERCENT;

    // @notice DAO_FEE sent to this address
    address public daoTreasury;

    // address that has permission to resolve disputes
    address public disputeResolver;

    // tokens whitelisted for payment
    mapping(IERC20 => bool) public paymentTokens;
    IERC20[] public tokensList;

    /***************
     * Job State *
     ***************/

    struct JobData {
        bool closedBySupplier;
        bool closedByEngineer;
        States state;
        address supplier;
        address engineer;
        IERC20 token;
        // Amount that an engineer needs to deposit to start the job
        uint256 requiredDeposit;
        // Amount that the engineer deposited
        uint256 deposit;
        uint256 bounty;
        uint256 fee;
        uint256 startTime;
        uint256 completedTime;
    }

    struct Report {
        address reporter;
        States previousState;
    }

    enum States {
        DoesNotExist,
        Available,
        Started,
        Completed,
        Disputed,
        Reported,
        FinalApproved,
        FinalCanceledBySupplier,
        FinalMutualClose,
        FinalNoResponse,
        FinalDisputeResolvedForSupplier,
        FinalDisputeResolvedForEngineer,
        FinalDisputeResolvedWithSplit,
        FinalDelisted
    }

    uint256 public jobCount;
    mapping(uint256 => JobData) public jobs;
    mapping(uint256 => Report) public reports;

    /**********
     * Events *
     **********/

    event JobPosted(uint256 indexed jobId, string metadataCid);
    event JobStarted(address indexed engineer, uint256 indexed jobId);
    event JobCompleted(uint256 indexed jobId);
    event JobApproved(uint256 indexed jobId, uint256 payoutAmount);
    event JobTimeoutPayout(uint256 indexed jobId, uint256 payoutAmount);
    event JobCanceled(uint256 indexed jobId);
    event JobClosedBySupplier(uint256 indexed jobId);
    event JobClosedByEngineer(uint256 indexed jobId);
    event JobClosed(uint256 indexed jobId);
    event JobDisputed(uint256 indexed jobId);
    event JobDisputeResolved(uint256 indexed jobId, uint256 engineerAmountPct);
    event PaymentTokensUpdated(IERC20 indexed token, bool indexed value);

    event JobReported(uint256 indexed jobId, address reporter, string metadataCid);
    event JobReportDeclined(uint256 indexed jobId, address reporter, string metadataCid);
    event JobDelisted(uint256 indexed jobId, address reporter, string metadataCid);

    /***************
     * Initializer *
     ***************/

    function initialize(
        IERC20 _initialToken,
        address _daoTreasury,
        address _resolver
    ) public initializer {
        paymentTokens[_initialToken] = true;
        tokensList.push(_initialToken);
        REPORT_TOKEN = _initialToken;
        daoTreasury = _daoTreasury;
        disputeResolver = _resolver;

        // 50 paymentTokens ($50)
        MINIMUM_BOUNTY = 50e18; // $50
        // 50 paymentTokens ($50)
        MINIMUM_DEPOSIT = 50e18; // $50

        // DAO Fee 10%
        DAO_FEE = 1000; // 10%

        // Resolution Fee 10%
        RESOLUTION_FEE_PERCENTAGE = 600; // 6%

        // Timeout after job is completed before job is awarded to engineer
        COMPLETED_TIMEOUT_SECONDS = 7 days;

        // Deposit required to report a job
        REPORT_DEPOSIT = 50e18; // $50

        // 10% - Reward of the bounty given to a successful reporter
        REPORT_REWARD_PERCENT = 1000; // 10%
    }

    /**********************
     * Function Modifiers *
     **********************/
    modifier onlyWhitelisted(IERC20 token) {
        require(paymentTokens[token], "Not Whitelisted !");
        _;
    }

    modifier onlyResolver() {
        require(disputeResolver == msg.sender, "Not Authorized !");
        _;
    }

    modifier requiresJobState(uint256 jobId, States requiredState) {
        require(jobs[jobId].state == requiredState, "Method not available for job state");
        _;
    }

    modifier onlySupplier(uint256 jobId) {
        require(jobs[jobId].supplier == msg.sender, "Method not available for this caller");
        _;
    }

    modifier onlyEngineer(uint256 jobId) {
        require(jobs[jobId].engineer == msg.sender, "Method not available for this caller");
        _;
    }



    /********************
     * Public Functions *
     ********************/

    /**
     * Supplier posts a new job
     * @param paymentToken ERC20 token from the whitelist.
     * @param totalValue amount of paymentToken including bounty and fee
     * @param requiredDeposit min % of totalValue that an engineer needs to deposit to start the job
     * @param metadataCid IFPS CID with job description & extra data.
     */
    function postJob(
        IERC20 paymentToken,
        uint256 totalValue,
        uint256 requiredDeposit,
        string memory metadataCid
    ) external onlyWhitelisted(paymentToken) {
        require(requiredDeposit >= MINIMUM_DEPOSIT, "Minimum deposit not provided");

        // calculate fee and bounty
        (uint256 bountyValue, uint256 feeValue) = calculateBountyAndFee(totalValue);

        require(bountyValue >= MINIMUM_BOUNTY, "Minimum bounty not provided");
        require(requiredDeposit <= bountyValue, "Deposit too large");

        // receive funds
        receiveFunds(paymentToken, msg.sender, totalValue);

        // assign newJobId from state
        ++jobCount;
        uint256 newJobId = jobCount;

        // update state
        jobs[newJobId].supplier = msg.sender;
        jobs[newJobId].token = paymentToken;
        jobs[newJobId].bounty = bountyValue;
        jobs[newJobId].fee = feeValue;
        jobs[newJobId].state = States.Available;
        jobs[newJobId].requiredDeposit = requiredDeposit;

        // save the job meta data
        emit JobPosted(newJobId, metadataCid);
    }

    // engineer starts a posted job
    function startJob(uint256 jobId, uint256 deposit) external requiresJobState(jobId, States.Available) {
        // require deposit payment
        require(deposit >= jobs[jobId].requiredDeposit, "Minimum payment not provided");
        // can't accept your own job
        require(msg.sender != jobs[jobId].supplier, "Address may not be job poster");

        receiveFunds(jobs[jobId].token, msg.sender, deposit);

        // update state
        jobs[jobId].engineer = msg.sender;
        jobs[jobId].deposit = deposit;
        jobs[jobId].startTime = block.timestamp;
        jobs[jobId].state = States.Started;

        emit JobStarted(msg.sender, jobId);
    }

    // engineer marks a job as completed
    function completeJob(uint256 jobId) external requiresJobState(jobId, States.Started) onlyEngineer(jobId) {
        jobs[jobId].state = States.Completed;
        jobs[jobId].completedTime = block.timestamp;

        emit JobCompleted(jobId);
    }

    // job is approved by the supplier and paid out
    function approveJob(uint256 jobId) external requiresJobState(jobId, States.Completed) onlySupplier(jobId) {
        jobs[jobId].state = States.FinalApproved;

        (uint256 payoutAmount, uint256 daoTakeAmount) = calculatePayout(jobs[jobId].bounty, jobs[jobId].fee, jobs[jobId].deposit);
        sendJobPayout(jobs[jobId].token, payoutAmount, daoTakeAmount, jobs[jobId].engineer);

        emit JobApproved(jobId, payoutAmount);
    }

    // job is canceled by supplier before it was started
    function cancelJob(uint256 jobId) public onlySupplier(jobId) requiresJobState(jobId, States.Available) {
        JobData memory job = jobs[jobId];

        jobs[jobId].state = States.FinalCanceledBySupplier;

        sendJobRefund(job);

        emit JobCanceled(jobId);
    }

    // @notice Job is closed if both supplier and engineer agree to cancel the job after it was started
    function closeJob(uint256 jobId) external requiresJobState(jobId, States.Started) {
        // must be supplier or engineer
        JobData memory job = jobs[jobId];

        if (msg.sender == job.supplier) {
            closeJobBySupplier(jobId);
        } else if (msg.sender == job.engineer) {
            closeJobByEngineer(jobId);
        } else {
            revert("Method not available for this caller");
        }

        // if closed by both parties, then change state and refund
        if (jobs[jobId].closedBySupplier && jobs[jobId].closedByEngineer) {
            jobs[jobId].state = States.FinalMutualClose;
            sendJobRefund(job);

            emit JobClosed(jobId);
        }
    }

    function completeTimedOutJob(uint256 jobId) external requiresJobState(jobId, States.Completed) onlyEngineer(jobId) {
        require(
            block.timestamp - jobs[jobId].completedTime >= COMPLETED_TIMEOUT_SECONDS,
            "Job still in approval time window"
        );

        jobs[jobId].state = States.FinalNoResponse;

        (uint256 payoutAmount, uint256 daoTakeAmount) = calculatePayout(jobs[jobId].bounty, jobs[jobId].fee, jobs[jobId].deposit);
        sendJobPayout(jobs[jobId].token, payoutAmount, daoTakeAmount, jobs[jobId].engineer);

        emit JobTimeoutPayout(jobId, payoutAmount);
    }

    function disputeJob(uint256 jobId) external onlySupplier(jobId) {
        require(
            jobs[jobId].state == States.Started || jobs[jobId].state == States.Completed,
            "Method not available for job state"
        );

        jobs[jobId].state = States.Disputed;

        emit JobDisputed(jobId);
    }

    function resolveDisputeForSupplier(uint256 jobId) external onlyResolver requiresJobState(jobId, States.Disputed) {
        jobs[jobId].state = States.FinalDisputeResolvedForSupplier;

        (uint256 payoutAmount, uint256 daoTakeAmount) = calculateFullDisputeResolutionPayout(
            jobs[jobId].bounty,
            jobs[jobId].fee,
            jobs[jobId].deposit
        );
        sendJobPayout(jobs[jobId].token, payoutAmount, daoTakeAmount, jobs[jobId].supplier);

        emit JobDisputeResolved(jobId, 0);
    }

    function resolveDisputeForEngineer(uint256 jobId) external onlyResolver requiresJobState(jobId, States.Disputed) {
        jobs[jobId].state = States.FinalDisputeResolvedForEngineer;

        (uint256 payoutAmount, uint256 daoTakeAmount) = calculateFullDisputeResolutionPayout(
            jobs[jobId].bounty,
            jobs[jobId].fee,
            jobs[jobId].deposit
        );
        sendJobPayout(jobs[jobId].token, payoutAmount, daoTakeAmount, jobs[jobId].engineer);

        emit JobDisputeResolved(jobId, BASE_PERCENTAGE);
    }

    function resolveDisputeWithCustomSplit(uint256 jobId, uint256 engineerAmountPct)
        external
        onlyResolver
        requiresJobState(jobId, States.Disputed)
    {
        require(engineerAmountPct >= MINIMUM_SPLIT_CHUNK_PERCENTAGE, "Percentage too low");
        require(engineerAmountPct <= BASE_PERCENTAGE - MINIMUM_SPLIT_CHUNK_PERCENTAGE, "Percentage too high");

        jobs[jobId].state = States.FinalDisputeResolvedWithSplit;

        JobData memory job = jobs[jobId];

        (
            uint256 supplierPayoutAmount,
            uint256 engineerPayoutAmount,
            uint256 daoTakeAmount
        ) = calculateSplitDisputeResolutionPayout(job.bounty, job.deposit, job.fee, engineerAmountPct);
        sendSplitJobPayout(job, supplierPayoutAmount, engineerPayoutAmount, daoTakeAmount);

        emit JobDisputeResolved(jobId, engineerAmountPct);
    }

    // Used to prevent illegal activity
    function reportJob(uint256 jobId, string memory metadataCid) external {
        JobData memory job = jobs[jobId];

        require(job.state == States.Available || job.state == States.Started, "Method not available for job state");

        reports[jobId].reporter = msg.sender;
        reports[jobId].previousState = job.state;

        jobs[jobId].state = States.Reported;

        receiveFunds(REPORT_TOKEN, msg.sender, REPORT_DEPOSIT);

        emit JobReported(jobId, msg.sender, metadataCid);
    }

    function declineReport(uint256 jobId, string memory metadataCid) external onlyResolver requiresJobState(jobId, States.Reported) {
        address reporter = reports[jobId].reporter;

        // move the job back to the previous state
        jobs[jobId].state = reports[jobId].previousState;

        sendFunds(REPORT_TOKEN, daoTreasury, REPORT_DEPOSIT);
        emit JobReportDeclined(jobId, reporter, metadataCid);
    }

    function acceptReport(uint256 jobId, string memory metadataCid) external onlyResolver requiresJobState(jobId, States.Reported) {
        JobData memory job = jobs[jobId];

        address reporter = reports[jobId].reporter;

        jobs[jobId].state = States.FinalDelisted;

        uint256 rewardAmount = (job.bounty * REPORT_REWARD_PERCENT) / BASE_PERCENTAGE;
        uint256 refundAmount = job.bounty + job.fee - rewardAmount;

        sendFunds(job.token, reporter, REPORT_DEPOSIT + rewardAmount);
        sendFunds(job.token, job.supplier, refundAmount);

        if (job.deposit > 0) {
            sendFunds(job.token, job.engineer, job.deposit);
        }

        emit JobDelisted(jobId, reporter, metadataCid);
    }

    function getAllPaymentTokens() external view returns (IERC20[] memory tokens) {
        uint256 l = tokensList.length;
        tokens = new IERC20[](l);
        for (uint256 i = 0; i < l; i++) {
            tokens[i] = tokensList[i];
        }
    }

    /**
     * Calculates the amounts that the engineer & dao will receive after job completion
     * @param jobId of the job.
     */
    function getJobPayouts(uint256 jobId)
        external
        view
        returns (
            uint256 forEngineer,
            uint256 forEngineerNoDeposit,
            uint256 forDao
        )
    {
        (forEngineer, forDao) = calculatePayout(jobs[jobId].bounty, jobs[jobId].fee, jobs[jobId].deposit);
        forEngineerNoDeposit = forEngineer - jobs[jobId].deposit;
    }

    /**
     * Calculates the amounts that the engineer & dao will receive after job completion
     * @param jobId of the job.
     */
    function getDisputePayouts(uint256 jobId) external view returns (uint256 forWinner, uint256 forDao) {
        (forWinner, forDao) = calculateFullDisputeResolutionPayout(jobs[jobId].bounty, jobs[jobId].fee, jobs[jobId].deposit);
    }

    /****************************
     * DAO Management Functions *
     ****************************/
    // TODO: what if someone sends a token by mistake to this contract ?
    // TODO: function withdraw

    function updatePaymentTokens(IERC20 token, bool enable) external onlyProxyAdmin {
        require(!enable || paymentTokens[token] != true, "Already added !");
        paymentTokens[token] = enable;
        if (enable) {
            tokensList.push(token);
        } else {
            removeToken(token);
        }
        emit PaymentTokensUpdated(token, enable);
    }

    // TODO: all these functions can either be with a Timelocker or with constrained values (see setJobTimeout).
    // TODO: So that people don't have to trust us
    function setMinBounty(uint256 newValue) external onlyProxyAdmin {
        MINIMUM_BOUNTY = newValue;
    }

    function setDaoFee(uint256 newValue) external onlyProxyAdmin {
        require(newValue <= MAX_DAO_FEE, "Value is too high");
        DAO_FEE = newValue;
    }

    function setResolutionFee(uint256 newValue) external onlyProxyAdmin {
        require(newValue <= MAX_RESOLUTION_FEE_PERCENTAGE, "Value is too high");
        RESOLUTION_FEE_PERCENTAGE = newValue;
    }

    function setJobTimeout(uint256 newValue) external onlyProxyAdmin {
        require(newValue >= MIN_COMPLETED_TIMEOUT_SECONDS, "Value is too low");
        require(newValue <= MAX_COMPLETED_TIMEOUT_SECONDS, "Value is too high");
        COMPLETED_TIMEOUT_SECONDS = newValue;
    }

    function setDaoTreasury(address addr) external onlyProxyAdmin {
        daoTreasury = addr;
    }

    function setResolver(address addr) external onlyProxyAdmin {
        disputeResolver = addr;
    }

    function setReportDeposit(uint256 newValue) external onlyProxyAdmin {
        require(newValue <= MAX_REPORT_DEPOSIT, "Value is too high");
        REPORT_DEPOSIT = newValue;
    }

    function setReportToken(IERC20 newToken) external onlyProxyAdmin {
        REPORT_TOKEN = newToken;
    }

    function setReportReward(uint256 newPercent) external onlyProxyAdmin {
        require(newPercent <= MAX_REPORT_REWARD_PERCENT, "Value is too high");
        REPORT_REWARD_PERCENT = newPercent;
    }

    /**********************
     * Internal Functions *
     **********************/

    function closeJobBySupplier(uint256 jobId) internal {
        require(jobs[jobId].closedBySupplier == false, "Close request already received");
        jobs[jobId].closedBySupplier = true;

        emit JobClosedBySupplier(jobId);
    }

    function closeJobByEngineer(uint256 jobId) internal {
        require(jobs[jobId].closedByEngineer == false, "Close request already received");
        jobs[jobId].closedByEngineer = true;

        emit JobClosedByEngineer(jobId);
    }

    function sendJobRefund(JobData memory job) internal {
        sendFunds(job.token, job.supplier, job.bounty + job.fee);

        if (job.deposit > 0) {
            sendFunds(job.token, job.engineer, job.deposit);
        }
    }

    function calculateBountyAndFee(uint256 total)
        internal
        view
        returns (uint256 bountyValue, uint256 feeValue)
    {
        bountyValue = BASE_PERCENTAGE * total / (BASE_PERCENTAGE + DAO_FEE);
        feeValue = total - bountyValue;
    }

    function calculatePayout(uint256 bounty, uint256 fee, uint256 deposit)
        internal
        pure
        returns (uint256 payoutAmount, uint256 daoTakeAmount)
    {
        daoTakeAmount = fee;
        payoutAmount = bounty + deposit;
    }

    function calculateFullDisputeResolutionPayout(uint256 bounty, uint256 refundedFee, uint256 deposit)
        internal
        view
        returns (uint256 payoutAmount, uint256 daoTakeAmount)
    {
        uint256 resolutionPayout = bounty + deposit;

        daoTakeAmount = (resolutionPayout * RESOLUTION_FEE_PERCENTAGE) / BASE_PERCENTAGE;
        payoutAmount = resolutionPayout + refundedFee - daoTakeAmount;
    }

    function sendJobPayout(
        IERC20 token,
        uint256 payoutAmount,
        uint256 daoTakeAmount,
        address destination
    ) internal {
        sendFunds(token, destination, payoutAmount);
        sendFunds(token, daoTreasury, daoTakeAmount);
    }

    function calculateSplitDisputeResolutionPayout(
        uint256 bounty,
        uint256 deposit,
        uint256 fee,
        uint256 engineerAmountPct
    )
        internal
        view
        returns (
            uint256 supplierPayoutAmount,
            uint256 engineerPayoutAmount,
            uint256 daoTakeAmount
        )
    {
        uint256 daoTakeBasis = bounty + deposit;
        uint256 resolutionPayout = bounty + deposit + fee;

        daoTakeAmount = (daoTakeBasis * RESOLUTION_FEE_PERCENTAGE) / BASE_PERCENTAGE;

        uint256 totalPayoutAmount = resolutionPayout - daoTakeAmount;
        engineerPayoutAmount = (totalPayoutAmount * engineerAmountPct) / BASE_PERCENTAGE;
        supplierPayoutAmount = totalPayoutAmount - engineerPayoutAmount;
    }

    function sendSplitJobPayout(
        JobData memory job,
        uint256 supplierPayoutAmount,
        uint256 engineerPayoutAmount,
        uint256 daoTakeAmount
    ) internal {
        sendFunds(job.token, job.supplier, supplierPayoutAmount);
        sendFunds(job.token, job.engineer, engineerPayoutAmount);
        sendFunds(job.token, daoTreasury, daoTakeAmount);
    }

    function receiveFunds(
        IERC20 _paymentToken,
        address _from,
        uint256 amount
    ) internal {
        _paymentToken.safeTransferFrom(_from, address(this), amount);
    }

    function sendFunds(
        IERC20 _paymentToken,
        address _to,
        uint256 amount
    ) internal {
        _paymentToken.safeTransfer(_to, amount);
    }

    // removes an item from the list & changes the length of the array
    function removeToken(IERC20 tokenAddr) internal returns (bool) {
        uint256 l = tokensList.length;

        if (l == 0) {
            return false;
        }

        if (tokensList[l - 1] == tokenAddr) {
            tokensList.pop();
            return true;
        }

        bool found = false;
        for (uint256 i = 0; i < l - 1; i++) {
            if (tokensList[i] == tokenAddr) {
                found = true;
            }
            if (found) {
                tokensList[i] = tokensList[i + 1];
            }
        }
        if (found) {
            tokensList.pop();
        }
        return found;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IJob {
    /**********
     * Events *
     **********/

    /***********
     * Structs *
     ***********/

    /*******************************
     * Authorized Setter Functions *
     *******************************/

    /********************
     * Public Functions *
     ********************/

    function paymentTokens(IERC20) external view returns (bool);

    function getAllPaymentTokens() external view returns (IERC20[] memory tokens);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 *  @author Jeremy Jin
 *  @title DelayedJobScheduler
 *  @notice DelayedJobScheduler provides a service where people schedule
 *  delayed job with prize and winning bidder can get reward on execution.
 *  @dev Here's the workflow:
 *
 *  Rather than wait and check who is winner after delay, it determines the
 *  winner on the fly when there's a new bid.
 *  Meaning that when there's lower bidder, it'll be winner immediately, and
 *  refund previous deposited amount to the previous winner.
 *  Later on, if winner execute the job, it'll send all the money
 *  (reward + collateral = Maximum Reward) to him.
 *  If job is not executed, creator can withdraw all deposited money,
 *  and mark it as cancelled.
 */
contract DelayedJobScheduler {
    using Address for address;

    // Status of Job
    enum Status {
        PENDING,
        CANCELLED,
        EXECUTED
    }

    struct Job {
        address payable contractAddress;
        string methodAbi;
        address creatorAddress;
        uint256 createdAt;
        uint256 delay;
        uint256 timeout;
        uint256 maximumReward;
        uint256 winningBidAmount;
        address payable winningBidderAddress;
        Status status;
    }

    // Mapping from job ID to job
    mapping(uint256 => Job) public jobs;

    // Length of jobs mapping.
    uint256 public jobNumber;

    event JobCreated(
        uint256 jobID,
        address contractAddress,
        string methodAbi,
        uint256 delay,
        uint256 timeout,
        uint256 maximumReward
    );
    event NewWinner(uint256 jobID, address winnerAddress, uint256 bidAmount);
    event JobExecuted(uint256 jobID);
    event TransferFailed(address target, uint256 amount);
    event Withdraw(uint256 jobId, uint256 amount);

    /**
     *  @dev This checks if jobId is in valid range
     *  @param jobId ID of Job.
     */
    modifier validJobID(uint256 jobId) {
        require(jobId > 0 && jobId <= jobNumber, "Job Index is out of range.");
        _;
    }

    /**
     *  @dev This checks if job with that id is in PENDING status.
     *  If status is CANCELLED or EXECUTED, bidding and executing job shouldn't be allowed.
     *  @param jobId ID of Job.
     */
    modifier pendingJob(uint256 jobId) {
        require(
            jobs[jobId].status == Status.PENDING,
            "Already Executed or Cancelled"
        );
        _;
    }

    /**
     *  @notice With this, any user can schedule a job which will give reward to winning bidder.
     *  In order to schedule a job, user should deposit ether as specified in maximumReward.
     *  @dev It checks if all inputs are valid, and create a new job.
     *  @param contractAddress The address of contract which will be called by bidder.
     *  @param methodAbi The string format of function in contract which will be called by bidder.
     *  @param delay The Amount of time(in seconds) that accept bidders after it's created.
     *  @param timeout The Amount of time(in seconds) that winning bidder can execute the job.
     *  @param maximumReward The Maximum amount of ether that creator will give winning bidder as a reward.
     */
    function createJob(
        address contractAddress,
        string memory methodAbi,
        uint256 delay,
        uint256 timeout,
        uint256 maximumReward
    ) public payable {
        require(contractAddress.isContract(), "Invalid Contract Address");
        require(delay > 0 && timeout > 0, "Invalid delay or timeout");
        require(maximumReward > 0, "Invalid Maximum Reward");
        require(maximumReward == msg.value, "Invalid Deposit Amount");

        // Create a new job
        Job memory job = Job({
            contractAddress: payable(contractAddress),
            methodAbi: methodAbi,
            delay: delay,
            timeout: timeout,
            maximumReward: maximumReward,
            status: Status.PENDING,
            createdAt: block.timestamp,
            creatorAddress: msg.sender,
            winningBidAmount: maximumReward,
            winningBidderAddress: payable(address(0))
        });

        // Increase the job number
        jobNumber += 1;

        // Add a new job record
        jobs[jobNumber] = job;

        // Trigger the event
        emit JobCreated(
            jobNumber,
            job.contractAddress,
            job.methodAbi,
            job.delay,
            job.timeout,
            job.maximumReward
        );
    }

    /**
     *  @notice With this, bidders can bid to the job with proposed bid amount.
     *  @dev It checks if job is in valid status, checks collateral bidder submit,
     *  and determine new winner, refund to the previous winner, and refund
     *  offset(previous winning bid amount - new winning bid amount) to the creator.
     *  @param jobId ID of job
     *  @param bidAmount Amount of Ether proposed by bidder.
     */
    function bidJob(uint256 jobId, uint256 bidAmount)
        public
        payable
        validJobID(jobId)
        pendingJob(jobId)
    {
        Job storage job = jobs[jobId];

        // Check Job Expiration
        require(block.timestamp < job.delay + job.createdAt, "Job Expired");

        // Bid Amount Check
        require(
            bidAmount > 0 && bidAmount <= job.maximumReward,
            "Invalid Bid Amount"
        );

        // Collateral Check
        uint256 depositAmount = job.maximumReward - bidAmount;
        require(depositAmount == msg.value, "Invalid Collateral");

        // We just need winning bid, not all bid. If it's not winning bid, we should revert here.
        require(bidAmount < job.winningBidAmount, "You bid is declined.");

        // Refund prevoius winningBidAmount to previous winner.
        uint256 winningDeposit = job.maximumReward - job.winningBidAmount;
        (bool transferSuccess, ) = job.winningBidderAddress.call{
            value: winningDeposit
        }("");

        if (transferSuccess) {
            emit TransferFailed(job.winningBidderAddress, winningDeposit);
        }

        // Refund offset amount to the job creator.
        uint256 offsetAmount = job.winningBidAmount - bidAmount;
        (transferSuccess, ) = job.creatorAddress.call{value: offsetAmount}("");

        if (transferSuccess) {
            emit TransferFailed(job.creatorAddress, offsetAmount);
        }

        // Assign New Winner
        job.winningBidderAddress = payable(msg.sender);
        job.winningBidAmount = bidAmount;

        emit NewWinner(jobId, job.winningBidderAddress, job.winningBidAmount);
    }

    /**
     *  @notice With this, winner can execute job and get reward!
     *  @dev It checks if job is in valid status, and give all ether(reward + collateral)
     *  to the winner, and update the status.
     *  @param jobId ID of job to be executed.
     *  @param args Argument that should be passed to the job which is a function of contract.
     */
    function executeJob(uint256 jobId, bytes calldata args)
        external
        validJobID(jobId)
        pendingJob(jobId)
    {
        Job storage job = jobs[jobId];
        require(
            block.timestamp > job.delay + job.createdAt,
            "Job is still bidding"
        );
        require(
            block.timestamp < job.delay + job.createdAt + job.timeout,
            "Job Expired"
        );
        require(job.winningBidderAddress == msg.sender, "Not Winner.");

        // execute
        (bool success, ) = job.contractAddress.delegatecall(
            abi.encodeWithSignature(job.methodAbi, args)
        );
        require(success, "Job Execution Failed!");
        job.status = Status.EXECUTED;

        // Give Reward + Refund Collateral: Reward + Collateral = maximumReward
        (bool transferSuccess, ) = job.winningBidderAddress.call{
            value: job.maximumReward
        }("");
        if (transferSuccess) {
            emit TransferFailed(job.winningBidderAddress, job.maximumReward);
        }

        emit JobExecuted(jobId);
    }

    /**
     *  @notice This allows job creator to withdraw remaining ether in case of it's not executed.
     *  @dev It checks if it's creator and if job is not executed, and then refund to the creator.
     *  @param jobId ID of job that's scheduled.
     */
    function withdraw(uint256 jobId) public validJobID(jobId) {
        Job storage job = jobs[jobId];
        require(job.status != Status.EXECUTED, "Job is already executed");
        require(job.creatorAddress == msg.sender, "Not Creator");
        require(job.winningBidAmount != 0, "No ether to withdraw.");

        // Set status as cancelled, and winninbBidAmount to zero.
        job.winningBidAmount = 0;
        job.status = Status.CANCELLED;

        // Withdraw remaining ether to the creator's address.
        uint256 withdrawlAmount = job.winningBidAmount;
        (bool success, ) = job.creatorAddress.call{value: withdrawlAmount}("");
        require(success, "Withdraw Failed!");

        emit Withdraw(jobId, withdrawlAmount);
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
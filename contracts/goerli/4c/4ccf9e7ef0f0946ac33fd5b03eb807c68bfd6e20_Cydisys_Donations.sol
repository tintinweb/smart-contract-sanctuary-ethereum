/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: CydisysTest.sol


pragma solidity ^0.8.17;




contract Cydisys_Donations is Ownable{
    using Counters for Counters.Counter;
    
    Counters.Counter public _tokenIds;
    Project[] public projects;
    
    event ProjectCreated(uint256 id, string name, address admin);
    event DonationReceived(uint256 projectId, address donnor, uint256 amount);
    event RecipientCreated(uint256 projectId, address recipient, uint256 recipientShare);
    event RecipientShareUpdated(uint256 projectId, address recipient, uint256 recipientShare);
    event MilestoneCreated(uint256 projectId, uint256 milestone, uint256 milestoneShare);
    event MilestoneShareUpdated(uint256 projectId, uint256 milestone, uint256 milestoneShare);
    event FailedTransfer(address receiver, uint256 amount);
    event MilestoneFundingWithdrawn(uint256 projectId, uint256 milestone, address recipient, uint256 amount);
    event MilestoneFundingRefund(uint256 projectId, uint256 milestone, address donor, uint256 amount);

    modifier onlyExistingProject(uint256 projectId) {
        require(projects[projectId].admin != address(0), "This project does not exist");
        _;
    }

    modifier onlyProjectAdmin(uint256 projectId){
        require(msg.sender == projects[projectId].admin, "Caller is not the project admin");
        _;
    }

    modifier onlyProjectDonor(uint256 projectId) {
        require(projects[projectId].donorsContribution[msg.sender] != 0, "Caller is not a project donor");
        _;
    }

    modifier onlyAllowedAmountOfMilestones(uint256 projectId) {
        require(projects[projectId].milestonesCounter + 1 <= 3, "Max number of milestones reached");
        _;
    }

    modifier onlyAllowedAmountOfRecipients(uint256 projectId) {
        require(projects[projectId].recipientsCounter + 1 <= 5, "Max number of recipients reached");
        _;
    }

    modifier onlyWhenWithdrawalAllowed(uint256 projectId, uint256 milestone) {
        require(projects[projectId].milestonesShare[milestone] != 0, "This milestone does not exist");
        require(block.timestamp >= milestone + 72 hours, "Request outside withdrawal window");
        _;
    }

    modifier onlyWhenRefundAllowed(uint256 projectId, uint256 milestone) {
        require(projects[projectId].milestonesShare[milestone] != 0, "This milestone does not exist");
        require(block.timestamp >= milestone && block.timestamp <= milestone + 72 hours, "Request outside refund window");
        _;
    }

    struct Project {
        uint256 id;
        string name;
        address admin;
        uint256 recipientsCounter;
        uint256 milestonesCounter;
        address[] recipients;
        uint256[] milestones;
        mapping(address => uint256) recipientsShare;
        mapping(uint256 => uint256) milestonesShare;
        mapping(address => uint256) donorsContribution;
        uint256 balance;
        uint256 totalFundsRaised;
    }

    constructor() {}


    // BUSINESS LOGIC

    function createProject (
        string memory projectName,        
        address recipient,
        uint256 recipientPercentage,
        uint256 milestoneDate,
        uint256 milestoneShare
    ) public {
        uint256 newProjectId = _tokenIds.current();
        Project storage newProject =  projects.push();
        
        newProject.id = newProjectId;
        newProject.name = projectName;
        newProject.admin = msg.sender;
        newProject.balance = 0;
        newProject.recipientsCounter += 1;
        newProject.recipients.push(recipient);
        newProject.recipientsShare[recipient] = recipientPercentage;
        newProject.milestonesCounter += 1;
        newProject.milestones.push(milestoneDate);
        newProject.milestonesShare[milestoneDate] = milestoneShare;

        emit ProjectCreated(newProjectId, projectName, msg.sender);
        _tokenIds.increment();
    }

    function createFunding(uint256 projectId) payable public onlyExistingProject(projectId) {
        projects[projectId].balance += msg.value;
        projects[projectId].totalFundsRaised += msg.value;
        projects[projectId].donorsContribution[msg.sender] += msg.value;
        emit DonationReceived(projectId, msg.sender, msg.value);
    }

    // TODO: implement pull over push pattern
    function withdrawMilestoneFunding(uint256 projectId, uint256 milestone) public onlyExistingProject(projectId) onlyProjectAdmin(projectId) onlyWhenWithdrawalAllowed(projectId, milestone) {
        Project storage project = projects[projectId];
        uint256 milestoneAmount = project.totalFundsRaised * project.milestonesShare[milestone] / 100;
        for (uint256 i=0; i < project.recipientsCounter; i++) {
            address recipient = project.recipients[i];
            uint256 amount = milestoneAmount * project.recipientsShare[recipient] / 100;
            project.balance -= amount;
            _safeTransfert(recipient, amount);
            emit MilestoneFundingWithdrawn(projectId, milestone, recipient, amount);
        }
    }

    // TODO: implement pull over push pattern
    function refundMilestoneFunding(uint256 projectId, uint256 milestone) public onlyExistingProject(projectId) onlyProjectDonor(projectId) onlyWhenRefundAllowed(projectId, milestone) {
        Project storage project = projects[projectId];
        uint256 donnorAmount = project.donorsContribution[msg.sender];
        uint256 refundAmount = project.milestonesShare[milestone] * donnorAmount / 100;
        project.balance -= refundAmount;
        project.totalFundsRaised -= refundAmount;
        _safeTransfert(msg.sender, refundAmount);
        emit MilestoneFundingRefund(projectId, milestone, msg.sender, refundAmount);
    }

    // PROJECT ADMIN
    function updateRecipientShare(uint256 projectId, address recipient, uint256 newRecipientShare) public onlyExistingProject(projectId) onlyProjectAdmin(projectId) {
        projects[projectId].recipientsShare[recipient] = newRecipientShare;
        emit RecipientShareUpdated(projectId, recipient, newRecipientShare);
    }

    function addNewRecipient(uint256 projectId, address newRecipient, uint256 newRecipientShare) public onlyExistingProject(projectId) onlyProjectAdmin(projectId) onlyAllowedAmountOfRecipients(projectId) {
        projects[projectId].recipientsCounter += 1;
        projects[projectId].recipients.push(newRecipient);
        projects[projectId].recipientsShare[newRecipient] = newRecipientShare;
        emit RecipientCreated(projectId, newRecipient, newRecipientShare);
    }

    function updateMilestoneShare(uint256 projectId, uint256 milestone, uint256 newMilestoneShare) public onlyExistingProject(projectId) onlyProjectAdmin(projectId) {
        projects[projectId].milestonesShare[milestone] = newMilestoneShare;
        emit MilestoneShareUpdated(projectId, milestone, newMilestoneShare);
    }

    function addNewMilestone(uint256 projectId, uint256 newMilestone, uint256 newMilestoneShare) public onlyExistingProject(projectId) onlyProjectAdmin(projectId) onlyAllowedAmountOfMilestones(projectId) {
        projects[projectId].milestonesCounter += 1;
        projects[projectId].milestones.push(newMilestone);
        projects[projectId].milestonesShare[newMilestone] = newMilestoneShare;
        emit MilestoneCreated(projectId, newMilestone, newMilestoneShare);
    }

    // GETTERS

    function getNextProjectId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function getProjectRecipients(uint256 projectId) public view returns (address[] memory) {
        return projects[projectId].recipients;
    }

    function getProjectMilestones(uint256 projectId) public view returns (uint256[] memory) {
        return projects[projectId].milestones;
    }

    function getProjectRecipientShare(uint256 projectId, address recipient) public view returns (uint256) {
        return projects[projectId].recipientsShare[recipient];
    }

    function getProjectMilestoneShare(uint256 projectId, uint256 milestone) public view returns (uint256) {
        return projects[projectId].milestonesShare[milestone];
    }

    function getProjectDonorContribution(uint256 projectId, address donnor) public view returns (uint256) {
        return projects[projectId].donorsContribution[donnor];
    }

    // PRIVATE

    function _safeTransfert(address receiver, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount) require(false, "Not enough in contract balance");

        (bool success, ) = receiver.call{value: amount}("");

        if (!success) {
            emit FailedTransfer(receiver, amount);
            require(false, "Transfer failed.");
        }
    }
}
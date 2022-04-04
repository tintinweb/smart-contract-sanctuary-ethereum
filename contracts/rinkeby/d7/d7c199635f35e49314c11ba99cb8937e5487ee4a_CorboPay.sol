/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

pragma solidity ^0.8.7;

/**
* @dev Contract which provides a secure payment service through a middle-man free
* deposits. Contract owner and client both must approve the terms of the payment 
* before the payment is deposited. Once deposited it is locked in the contract until
* the depositer realeases at milestones set in the terms of the payment.
*/
contract CorboPay is Ownable {

    //Index of submitted drafts.
    uint256 submittedIndex;

    //Index of approved drafts.
    uint256 index;

    struct Draft {
        bool signed;
        bool complete;
        address signer;
        uint256 milestonesAmount;
        uint256 milestonesCount;
        uint256 milestonesLeft;
        uint256 totalAmount;
    }
    
    mapping (address => bool) client;

    mapping (address => bool) approvedClient;

    mapping (uint256 => Draft) submittedDrafts;

    mapping (uint256 => Draft) approvedDrafts;

    /**
     * @dev Throws if called by anyone except the contract owner or a potential/approved
     * client added by the owner.
     */
    modifier onlyClient() {
        require(client[msg.sender] == true || approvedClient[msg.sender] == true || msg.sender == owner());
        _;
    }

    /**
     * @dev Throws if called by anyone except the contract owner or an approved
     * client added by the owner.
     */
    modifier onlyApproved() {
        require(client[msg.sender] == true || msg.sender == owner());
        _;
    }

    /**
     * @dev Approves a submitted draft to a verified draft stored at (`_index`) as well as 
     * locking the ether value stored in {Draft.totalAmount} at the time of verification.
     */
    function approveDraft(uint256 _index) internal {
        approvedDrafts[index].signer = submittedDrafts[_index].signer;
        approvedDrafts[index].milestonesAmount = submittedDrafts[_index].milestonesAmount;
        approvedDrafts[index].milestonesCount = submittedDrafts[_index].milestonesCount;
        approvedDrafts[index].milestonesLeft = submittedDrafts[_index].milestonesCount;
        approvedDrafts[index].totalAmount = submittedDrafts[_index].totalAmount;
        index++;
    }

    /**
     * @dev Clients can call this function to submit a draft of payment terms with paramaters
     * (`amount`) referring to the total amount of the payment and (`numMilestones`) referrring
     * to the number of payment milestones requested.
     *
     * If the client would like no milestones and the total payment released all at once use the 
     * value '1' for (`numMilestones`), function will throw if the value is '0'.
     */
    function submitDraft(uint256 numMilestones) public payable onlyClient {
        require(numMilestones > 0);
        submittedDrafts[submittedIndex].signer = msg.sender;
        submittedDrafts[submittedIndex].milestonesAmount = msg.value / numMilestones;
        submittedDrafts[submittedIndex].milestonesCount = numMilestones;
        submittedDrafts[submittedIndex].totalAmount = msg.value;
        submittedIndex++;
    }

    /**
     * @dev 
     */
    function viewSubmitted(uint256 clientIndex) public view onlyClient returns(Draft memory) {
        require(submittedDrafts[clientIndex].signer == msg.sender);
        return submittedDrafts[clientIndex];
    }

    /**
     * @dev 
     */
    function viewApproved(uint256 clientIndex) public view onlyApproved returns(Draft memory) {
        require(approvedDrafts[clientIndex].signer == msg.sender);
        return approvedDrafts[clientIndex];
    }

    /**
     * @dev 
     */
    function completeMilestone(uint256 clientIndex) public onlyApproved {
        require(approvedDrafts[clientIndex].signer == msg.sender);
        (bool success, ) = msg.sender.call{value: approvedDrafts[clientIndex].milestonesAmount}("");
        require(success, "Transfer failed.");  

        approvedDrafts[clientIndex].milestonesLeft--;
        if (approvedDrafts[clientIndex].milestonesLeft == 0) {
            approvedDrafts[clientIndex].complete = true;
        }
    }

    /**
     * @dev 
     */
    function verifyDraft(uint256 oldIndex, address submitter) public onlyOwner {
        require(submittedDrafts[oldIndex].signer == submitter);
        submittedDrafts[oldIndex].signed = true;
        approveDraft(oldIndex);
        approvedDrafts[index].signed = true;
        approvedClient[submitter] = true;
    }

    //Add to or remove from the list of clients.
    function setClient(address newClient, bool newVal) public onlyOwner {
        client[newClient] = newVal;
    }

    //Add to or remove from the list of approved clients.
    function approveClient(address newClient, bool newVal) public onlyOwner {
        approvedClient[newClient] = newVal;
    }
}
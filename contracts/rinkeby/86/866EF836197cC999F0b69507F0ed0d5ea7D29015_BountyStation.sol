// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BountyStructs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BountyStation is BountyStructs, Ownable {
    // Storage
    Category[] categories;
    Bounty[] bounties;
    Deal[] deals;

    uint256 identifierNonce = 1;

    address protocolWallet;

    // Map proposals to respective bountyId
    mapping(uint256 => Proposal[]) proposals;

    // Map submit to respective bountyId
    mapping(uint256 => Submission[]) submissions;

    // Map active deals for a hunter
    mapping(address => uint256[]) hunterDeals;

    // Map active propsals for a hunter
    mapping(address => uint256[]) hunterproposals;

    // Modifiers
    modifier onlyBountyCreator(uint256 _bountyId) {
        require(msg.sender == bounties[_bountyId].bountyCreator, "Only Bounty creators can perform this action");
        _;
    }

    modifier onlyDealCreator(uint256 _dealId) {
        require(msg.sender == deals[_dealId].dealCreator, "Only Deal creators can perform this action");
        _;
    }

    modifier onlyProposalCreator(uint256 _bountyId, uint256 _proposalId) {
        require(
            msg.sender == proposals[_bountyId][_proposalId].proposalCreator,
            "Only Proposal creator can perform this action"
        );
        _;
    }

    modifier onlyDealReciever(uint256 _dealId) {
        require(msg.sender == deals[_dealId].dealReceiver, "Only Deal receiver can perform this action");
        _;
    }

    modifier bountyExists(uint256 _bountyId) {
        require(bounties[_bountyId].bountyValueETH > 0, "Bounty Does not Exist");
        _;
    }

    // Functions
    constructor(address _protocolWallet) {
        protocolWallet = _protocolWallet;
    }

    // Update Protocol Receiver Contract
    function updateProtocol(address _newProtocolWallet) external onlyOwner {
        protocolWallet = _newProtocolWallet;
    }

    // Add New Category
    function addCategory(string calldata _categoryName) external onlyOwner returns (uint256) {
        categories.push(Category(_categoryName, identifierNonce, identifierNonce + 1));
        identifierNonce += 2;
        return categories.length - 1;
    }

    // Get Categories
    function getAllCategories() public view returns (Category[] memory) {
        return categories;
    }

    // Get Category
    function getCategory(uint256 _catId) public view returns (Category memory) {
        require(categories.length > _catId, "Category Does not exist");
        return categories[_catId];
    }

    // Create a Bounty
    function createBounty(
        string calldata _bountyTitle,
        string calldata _bountyDescription,
        string calldata _bountyLink,
        uint256 _bountyCategory,
        uint256 _bountyValueETH
    ) public payable returns (uint256) {
        require(_bountyValueETH > 0, "Bounty Value has to be greater than 0");
        require(msg.value == _bountyValueETH, "Bounty Value does not match with the supplied amount");
        bytes32 empty = keccak256(abi.encodePacked(""));
        require(
            keccak256(abi.encodePacked(_bountyTitle)) != empty &&
                keccak256(abi.encodePacked(_bountyDescription)) != empty &&
                keccak256(abi.encodePacked(_bountyLink)) != empty,
            "Invalid Bounty data supplied"
        );
        require(categories[_bountyCategory].hunterId > 0, "Invalid Category selected");

        bounties.push(
            Bounty(msg.sender, _bountyTitle, _bountyDescription, _bountyLink, _bountyCategory, _bountyValueETH)
        );

        return bounties.length - 1;
    }

    // Get All Bounties
    function getAllBounties() public view returns (Bounty[] memory) {
        return bounties;
    }

    // Withdraw a Bounty
    function withdrawBounty(uint256 _bountyId) public bountyExists(_bountyId) onlyBountyCreator(_bountyId) {
        payable(bounties[_bountyId].bountyCreator).transfer(bounties[_bountyId].bountyValueETH);
        delete bounties[_bountyId];
    }

    // Create Proposal to bounty
    function addProposalToBounty(
        uint256 _bountyId,
        string memory _proposalTitle,
        string memory _proposalDescription,
        string memory _proposalLink,
        uint256 _depositValueETH
    ) public returns (uint256) {}

    // Select proposal for bounty
    function selectProposal(uint256 _bountyId, uint256 _proposalId) public {}

    // Add Submission to deal
    function submitToDeal(
        uint256 _dealId,
        string memory _submissionTitle,
        string memory _submissionDescription,
        string memory _submissionLink
    ) public {}

    // Approve Submission
    function approveSubmission(uint256 _dealId, uint256 _submissionid) public {}

    // Dispute Submission
    function disputeSubmission(
        uint256 _dealid,
        uint256 _submissionId,
        string memory _comment
    ) public {}

    // Withdraw a Deal
    function withdrawDeal(uint256 _dealId) public {}

    // Get My Deals
    function getMyDeals() public view returns (Deal[] memory) {}

    // get my proposals
    function getMyProposals() public view returns (Proposal[] memory) {}

    // Get Proposals for deal
    function getProposalsOfDeal(uint256 _dealId) public view returns (Proposal[] memory) {}

    // Get Submissions for deal
    function getSubmissionsOfDeal(uint256 _dealId) public view returns (Submission[] memory) {}

    // Hooks
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BountyStructs {
    // Enums
    enum Status {
        pending,
        approved,
        disputed
    }

    // Structs
    struct Bounty {
        address bountyCreator;
        string bountyTitle;
        string bountyDescription;
        string bountyLink;
        uint256 bountyCategory;
        uint256 bountyValueETH;
    }

    struct Deal {
        address dealCreator;
        address dealReceiver;
        string dealTitle;
        string dealDescription;
        string dealLink;
        uint256 dealCategory;
        uint256 dealValueETH;
        uint256 hunterDepositETH;
    }

    struct Proposal {
        uint256 bountyId;
        string proposalTitle;
        string proposalDescription;
        string proposalLink;
        address proposalCreator;
        uint256 depositValueETH;
        uint256 proposalValue;
    }

    struct Submission {
        uint256 dealId;
        string submissionTitle;
        string submissionDescription;
        string submissionLink;
        address submissionCreator;
        Status submissionStatus;
        string submissionComment;
    }

    struct Category {
        string categoryName;
        uint256 creatorId;
        uint256 hunterId;
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
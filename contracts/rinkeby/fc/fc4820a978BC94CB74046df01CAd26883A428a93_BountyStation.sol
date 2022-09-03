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
    bytes32 empty = keccak256(abi.encodePacked(""));

    // Map proposals to respective bountyId
    mapping(uint256 => Proposal[]) proposals;

    // Map submissions to respective bountyId
    mapping(uint256 => Submission[]) submissions;

    // Map bounties for a creator
    mapping(address => uint256[]) creatorBounties;

    // Map deals for a creator
    mapping(address => uint256[]) creatorDeals;

    // Map active deals for a hunter
    mapping(address => uint256[]) hunterDeals;

    // Map active propsals for a hunter => bountyId => proposalId
    mapping(address => mapping(uint256 => uint256[])) hunterproposals;

    // Modifiers
    modifier onlyBountyCreator(uint256 _bountyId) {
        require(msg.sender == bounties[_bountyId].bountyCreator, "Only Bounty creators can perform this action");
        _;
    }

    modifier onlyDealCreator(uint256 _dealId) {
        require(msg.sender == deals[_dealId].dealCreator, "Only Deal creators can perform this action");
        _;
    }

    modifier onlyCreatorOrReceiver(uint256 _dealId) {
        require(
            msg.sender == deals[_dealId].dealCreator || msg.sender == deals[_dealId].dealReceiver,
            "Only Deal creators or receivers can perform this action"
        );
        _;
    }

    modifier onlyProposalCreator(uint256 _bountyId, uint256 _proposalId) {
        require(
            msg.sender == proposals[_bountyId][_proposalId].proposalCreator,
            "Only Proposal creator can perform this action"
        );
        _;
    }

    modifier onlyDealReceiver(uint256 _dealId) {
        require(msg.sender == deals[_dealId].dealReceiver, "Only Deal receiver can perform this action");
        _;
    }

    modifier bountyExists(uint256 _bountyId) {
        require(bounties[_bountyId].bountyValueETH > 0, "Bounty Does not Exist");
        _;
    }

    modifier dealExists(uint256 _dealId) {
        require(deals[_dealId].dealValueETH > 0, "Bounty Does not Exist");
        _;
    }

    modifier proposalExists(uint256 _bountyId, uint256 _proposalId) {
        require(proposals[_bountyId][_proposalId].proposalValue > 0, "Proposal Does not Exist");
        _;
    }

    modifier subissionExists(uint256 _dealId, uint256 _submissionId) {
        require(submissions[_dealId][_submissionId].dealId == _dealId, "Submission Does not Exist");
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
        require(
            keccak256(abi.encodePacked(_bountyTitle)) != empty &&
                keccak256(abi.encodePacked(_bountyDescription)) != empty &&
                keccak256(abi.encodePacked(_bountyLink)) != empty,
            "Invalid Bounty data supplied"
        );
        require(categories[_bountyCategory].hunterId > 0, "Invalid Category selected");

        bounties.push(
            Bounty(
                bounties.length,
                msg.sender,
                _bountyTitle,
                _bountyDescription,
                _bountyLink,
                _bountyCategory,
                _bountyValueETH
            )
        );
        creatorBounties[msg.sender].push(bounties.length - 1);
        return bounties.length - 1;
    }

    // Get All Bounties
    function getAllBounties() public view returns (Bounty[] memory) {
        return bounties;
    }

    // Get My Bounties
    function getMyBounties() public view returns (Bounty[] memory) {
        Bounty[] memory toReturn = new Bounty[](creatorBounties[msg.sender].length);

        for (uint256 i = 0; i < creatorBounties[msg.sender].length; i++) {
            toReturn[i] = bounties[creatorBounties[msg.sender][i]];
        }
        return toReturn;
    }

    // Withdraw a Bounty
    function withdrawBounty(uint256 _bountyId) public bountyExists(_bountyId) onlyBountyCreator(_bountyId) {
        payable(bounties[_bountyId].bountyCreator).transfer(bounties[_bountyId].bountyValueETH);
        _deleteBounty(_bountyId, msg.sender);
    }

    // Create Proposal to bounty
    function addProposalToBounty(
        uint256 _bountyId,
        string memory _proposalTitle,
        string memory _proposalDescription,
        string memory _proposalLink,
        uint256 _proposalValue,
        uint256 _depositValueETH
    ) public payable bountyExists(_bountyId) returns (uint256) {
        require(_proposalValue > 0, "Proposal Value has to be greater than 0");
        require(_depositValueETH > 0, "Proposal Value has to be greater than 0");
        require(msg.value == _depositValueETH, "Bounty Value does not match with the supplied amount");
        require(
            keccak256(abi.encodePacked(_proposalTitle)) != empty &&
                keccak256(abi.encodePacked(_proposalDescription)) != empty &&
                keccak256(abi.encodePacked(_proposalLink)) != empty,
            "Invalid Bounty data supplied"
        );
        require(_depositValueETH >= (_proposalValue / 10), "Atleast 10% of the proposal value has to be deposited");

        proposals[_bountyId].push(
            Proposal(
                proposals[_bountyId].length,
                _bountyId,
                _proposalTitle,
                _proposalDescription,
                _proposalLink,
                msg.sender,
                _depositValueETH,
                _proposalValue
            )
        );
        hunterproposals[msg.sender][_bountyId].push(proposals[_bountyId].length - 1);
        return proposals[_bountyId].length - 1;
    }

    // Select proposal for bounty
    function selectProposal(uint256 _bountyId, uint256 _proposalId)
        public
        bountyExists(_bountyId)
        proposalExists(_bountyId, _proposalId)
        onlyBountyCreator(_bountyId)
    {
        deals.push(
            Deal(
                bounties[_bountyId].bountyCreator,
                proposals[_bountyId][_proposalId].proposalCreator,
                bounties[_bountyId].bountyTitle,
                bounties[_bountyId].bountyDescription,
                bounties[_bountyId].bountyLink,
                bounties[_bountyId].bountyCategory,
                proposals[_bountyId][_proposalId].proposalValue,
                proposals[_bountyId][_proposalId].depositValueETH,
                DealStatus.ongoing
            )
        );

        creatorDeals[bounties[_bountyId].bountyCreator].push(deals.length - 1);
        hunterDeals[proposals[_bountyId][_proposalId].proposalCreator].push(deals.length - 1);

        _deleteBounty(_bountyId, msg.sender);
        delete proposals[_bountyId];
    }

    // Add Submission to deal
    function submitToDeal(
        uint256 _dealId,
        string memory _submissionTitle,
        string memory _submissionDescription,
        string memory _submissionLink
    ) public dealExists(_dealId) onlyDealReceiver(_dealId) {
        if (submissions[_dealId].length > 0) {
            require(
                submissions[_dealId][submissions[_dealId].length - 1].submissionStatus == Status.disputed,
                "You can only submit if the previous submission is disputed"
            );
        }

        submissions[_dealId].push(
            Submission(
                _dealId,
                _submissionTitle,
                _submissionDescription,
                _submissionLink,
                msg.sender,
                Status.pending,
                ""
            )
        );
    }

    // Approve Submission
    function approveSubmission(
        uint256 _dealId,
        uint256 _submissionId,
        string calldata _submissionComment
    ) public dealExists(_dealId) subissionExists(_dealId, _submissionId) onlyDealCreator(_dealId) {
        submissions[_dealId][_submissionId].submissionStatus = Status.approved;
        submissions[_dealId][_submissionId].submissionComment = _submissionComment;
        deals[_dealId].dealStatus = DealStatus.completed;
        payable(deals[_dealId].dealReceiver).transfer(deals[_dealId].dealValueETH + deals[_dealId].hunterDepositETH);
    }

    // Dispute Submission
    function disputeSubmission(
        uint256 _dealId,
        uint256 _submissionId,
        string memory _comment
    ) public dealExists(_dealId) subissionExists(_dealId, _submissionId) onlyDealCreator(_dealId) {
        submissions[_dealId][_submissionId].submissionStatus = Status.disputed;
        submissions[_dealId][_submissionId].submissionComment = _comment;
    }

    // Withdraw a Deal
    function withdrawDeal(uint256 _dealId) public dealExists(_dealId) onlyCreatorOrReceiver(_dealId) {
        if (msg.sender == deals[_dealId].dealCreator) {
            payable(deals[_dealId].dealReceiver).transfer(deals[_dealId].hunterDepositETH);
            payable(deals[_dealId].dealCreator).transfer((deals[_dealId].dealValueETH / 10) * 9);
        } else {
            payable(deals[_dealId].dealCreator).transfer((deals[_dealId].dealValueETH));
        }
        payable(protocolWallet).transfer((deals[_dealId].dealValueETH / 10));
    }

    // Get My Deals
    function getMyCreatorDeals() public view returns (Deal[] memory) {
        Deal[] memory toReturn = new Deal[](creatorDeals[msg.sender].length);

        for (uint256 i = 0; i < creatorDeals[msg.sender].length; i++) {
            toReturn[i] = deals[creatorDeals[msg.sender][i]];
        }
        return toReturn;
    }

    function getMyHunterDeals() public view returns (Deal[] memory) {
        Deal[] memory toReturn = new Deal[](hunterDeals[msg.sender].length);

        for (uint256 i = 0; i < hunterDeals[msg.sender].length; i++) {
            toReturn[i] = deals[hunterDeals[msg.sender][i]];
        }
        return toReturn;
    }

    // Get Proposals for bounty
    function getProposalsOfBounty(uint256 _bountyId) public view bountyExists(_bountyId) returns (Proposal[] memory) {
        return proposals[_bountyId];
    }

    // Get Submissions for deal
    function getSubmissionsOfDeal(uint256 _dealId) public view dealExists(_dealId) returns (Submission[] memory) {
        return submissions[_dealId];
    }

    // Hooks

    function _deleteBounty(uint256 _bountyId, address creator) internal {
        bool flag = false;
        for (uint256 i = 0; i < creatorBounties[creator].length - 1; i++) {
            if (creatorBounties[creator][i] == _bountyId) {
                flag = true;
            }
            if (flag) {
                creatorBounties[creator][i] = creatorBounties[creator][i + 1];
            }
        }
        delete bounties[_bountyId];
    }
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

    enum DealStatus {
        ongoing,
        completed,
        withdrawn
    }

    // Structs
    struct Bounty {
        uint256 bountyId;
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
        DealStatus dealStatus;
    }

    struct Proposal {
        uint256 proposalId;
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
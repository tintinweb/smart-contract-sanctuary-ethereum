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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error CONTRACT_IS_NOT_LOCKED(); // Error: The contract is not locked
error PROPOSAL_ALREADY_ACTIVE(); // Error: There is already an active proposal
error PROPOSAL_NOT_ACTIVE(); // Error: There is no active proposal
error STARTING_TIME_PASSED(); // Error: The starting time of the proposal has already passed
error PROPOSAL_NOT_STARTED_YET(); // Error: The proposal has not started yet
error PROPOSAL_EXPIRED(); // Error: The proposal has already expired
error PROPOSAL_NOT_EXPIRED_YET(); // Error: The proposal has not yet expired
error INSUFFICIENT_BALANCE_FOR_VOTING(); // Error: The user has insufficient balance for voting
error ALREADY_VOTED(); // Error: The user has already voted
error DURATION_NOT_ALLOWED(); // Error: The proposal duration is not allowed
error NOT_OWNER_OF_ASSET(); // Error: The user is not the owner of the asset
error OUT_OF_BOUND_REQUEST(); // Error: The requested index is out of bounds
error INSUFFICIENT_FUNDS(); // Error: The user has insufficient funds
error NOT_A_PREMIUM_MEMBER(); // Error: The user is not a premium member

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

library MoonLockLib {

    struct Socials {
        string name;
        string imageUrl;
        string details;
        string twitterId;
        string discordId;
        string telegramId;
    }

    struct UserDetail {
        uint256 memberSince;
        uint256 memberId;
        bool isPremium;
    }

}

interface IMembershipManager  {
   
    function getUserTokenData(address user) external view returns (MoonLockLib.UserDetail memory);
    function balanceOf(address owner) external view returns (uint256 balance);

}

contract MoonLock is Ownable {

    enum Status { PENDING, INPROGRESS, SUCCESSFUL, UNSUCCESSFUL }
    enum Vote { FAVOUR, AGAINST }
    
    struct UnlockProposals {
        uint256 id;
        string description;
        uint256 startingAt;
        uint8 durationInDays;
        uint256 voteCount;
        uint256 votesInFavour;
        uint256 votesAgainst;
        Status status;
    }

    uint256 public immutable mookLockId; 
    // uint256 internal constant ONE_DAY = 24*60*60;
    uint256 internal constant ONE_DAY = 60*60; // One day in seconds
    address public assetContract;
    uint256 public proposalCounts = 0;
    bool public isProposalActive = false;
    uint256 public contractLockedAt;
    MoonLockLib.Socials public socials; 

    mapping(uint256 => UnlockProposals) public unlockProposals;
    mapping(uint256 => mapping(address => bool)) public voted;

    event ProposalCreated(uint256 id, string description, uint256 startingAt, uint8 durationInDays);
    event ProposalFinalized(uint256 id);
    event VoteCasted(uint256 id, Vote vote, uint256 amount);
    event OwnershipReleased(uint256 id);

    constructor(uint256 id, address asset, address orginalOwner, MoonLockLib.Socials memory _socials) {
        // Check if the deployer is the owner of the asset
        if (Ownable(asset).owner() != orginalOwner) {
            revert NOT_OWNER_OF_ASSET();
        }

        mookLockId = id;
        assetContract = asset;
        socials = _socials;

        transferOwnership(orginalOwner);
    }

    function isOwnershipLocked() public view returns(bool) {
        // Check if the contract owns the asset
        return Ownable(assetContract).owner() == address(this);
    }

    function getProposals(uint256 from, uint256 count) public view returns(UnlockProposals[] memory) {
        // Retrieve an array of unlock proposals within the specified range
        
        if (from > proposalCounts) {
            revert OUT_OF_BOUND_REQUEST();
        }

        if (count > from) {
            count = from;
        }

        uint256 to = from - count;

        uint256 index = 0;
        UnlockProposals[] memory proposals = new UnlockProposals[](count);
        for (uint256 i = from; i > to; i--) {
            UnlockProposals memory p = unlockProposals[i];
            proposals[index] = p;
            index++;
        }

        return proposals;
    }

    function getLatestProposal() public view returns(UnlockProposals memory) {
        // Retrieve the latest unlock proposal
        
        return unlockProposals[proposalCounts];
    }

    function startProposal(string memory _description, uint256 _startingAt, uint8 _durationInDays) public onlyOwner {
        // Start a new unlock proposal
        
        if (!isOwnershipLocked()) {
            revert CONTRACT_IS_NOT_LOCKED();
        }

        if (isProposalActive) {
            revert PROPOSAL_ALREADY_ACTIVE();
        }

        if (_startingAt <= block.timestamp) {
            revert STARTING_TIME_PASSED();
        }

        if (_durationInDays < 0 || _durationInDays > 5) {
            revert DURATION_NOT_ALLOWED();
        }

        uint256 id = ++proposalCounts;

        UnlockProposals memory proposal = UnlockProposals(
            id, _description, _startingAt, _durationInDays, 0, 0, 0, Status.PENDING
        );

        isProposalActive = true;
        contractLockedAt = block.timestamp;
        unlockProposals[id] = proposal;

        emit ProposalCreated(id, _description, _startingAt, _durationInDays);
    }

    function castVote(Vote vote) public {
        // Cast a vote for the latest unlock proposal
        
        if (!isOwnershipLocked()) {
            revert CONTRACT_IS_NOT_LOCKED();
        }

        if (!isProposalActive) {
            revert PROPOSAL_NOT_ACTIVE();
        }

        if (voted[proposalCounts][msg.sender]) {
            revert ALREADY_VOTED();
        }

        UnlockProposals memory p = getLatestProposal();

        if (block.timestamp <= p.startingAt) {
            revert PROPOSAL_NOT_STARTED_YET();
        }

        if (block.timestamp > p.startingAt + (p.durationInDays * ONE_DAY)) {
            revert PROPOSAL_EXPIRED();
        }
        
        if (p.status == Status.PENDING) {
            unlockProposals[proposalCounts].status = Status.INPROGRESS;
        }
 
        uint256 balanceOfUser = IERC20(assetContract).balanceOf(msg.sender) / (10 ** IERC20(assetContract).decimals());

        if (balanceOfUser < 1) {
            revert INSUFFICIENT_BALANCE_FOR_VOTING();
        }

        if (vote == Vote.FAVOUR) {
            unlockProposals[proposalCounts].votesInFavour += balanceOfUser;
        } else {
            unlockProposals[proposalCounts].votesAgainst += balanceOfUser;
        }

        voted[proposalCounts][msg.sender] = true;
        unlockProposals[proposalCounts].voteCount++;

        emit VoteCasted(p.id, vote, balanceOfUser);
    }

    function finalizeProposal() public onlyOwner {
        // Finalize the latest unlock proposal
        
        if (!isProposalActive) {
            revert PROPOSAL_NOT_ACTIVE();
        }

        UnlockProposals memory p = getLatestProposal();

        if (block.timestamp < p.startingAt + p.durationInDays * ONE_DAY) {
            revert PROPOSAL_NOT_EXPIRED_YET();
        }

        if (p.votesInFavour > p.votesAgainst) {
            // Return ownership to owner
            unlockProposals[proposalCounts].status = Status.SUCCESSFUL;
            isProposalActive = false;
            contractLockedAt = 0;

            Ownable(assetContract).transferOwnership(owner());
            emit OwnershipReleased(p.id);
        } else {
            unlockProposals[proposalCounts].status = Status.UNSUCCESSFUL;
            isProposalActive = false;
        }

        emit ProposalFinalized(p.id);
    }

    function updateSocials(MoonLockLib.Socials memory _socials) public onlyOwner {
        // Update the socials data
        
        socials = _socials;
    }

}

contract MoonLockFactory is Ownable {

    uint256 public moonLockCount = 0;
    uint256 public moonLockFee = 0 ether;
    IMembershipManager public membershipManager;
    mapping(uint256 => MoonLock) public moonLockById;
    mapping(address => MoonLock ) public moonLocksByAsset;
    mapping(address => MoonLock[] ) public moonLocksByUser;

    event Received(address from, uint256 amount);
    event MoonLockCreated( uint256 id, address moonLock );

    constructor ( address _membershipManager ) {
        membershipManager = IMembershipManager(_membershipManager);
    }

    function createMoonLock(address asset, MoonLockLib.Socials memory _socials) public payable {

        if(Ownable(asset).owner() != msg.sender){
            revert NOT_OWNER_OF_ASSET();
        }

        if(msg.value < moonLockFee){
            revert INSUFFICIENT_FUNDS();
        }

        if( !membershipManager.getUserTokenData(msg.sender).isPremium ){
            revert NOT_A_PREMIUM_MEMBER();
        }

        uint256 id = ++moonLockCount;
        MoonLock moonLock = new MoonLock(id, asset, msg.sender, _socials);
        moonLockById[id] = moonLock;
        moonLocksByAsset[asset] = moonLock;
        moonLocksByUser[msg.sender].push(moonLock);

        emit MoonLockCreated( id, address(moonLock) );

    }

    function getMoonLockAddresses(uint256 from, uint256 count) public view returns (MoonLock[] memory){

        if (from > moonLockCount) {
            revert OUT_OF_BOUND_REQUEST();
        }

        if (count > from) {
            count = from;
        }

        uint256 to = from - count;

        uint256 index = 0;
        MoonLock[] memory moonLockAddr = new MoonLock[](count);
        for (uint256 i = from; i > to; i--) {
            MoonLock a = moonLockById[i];
            moonLockAddr[index] = a;
            index++;
        }

        return moonLockAddr;

    }

    function updateMembershipManager( address _membershipManager ) public onlyOwner {
        membershipManager = IMembershipManager(_membershipManager);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdrawFunds() public onlyOwner {
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0, "No balance avaialble for withdraw");
        payable(owner()).transfer(totalBalance);
    }

}



// contract MoonLock is Ownable {

//     enum Status { PENDING, INPROGRESS, SUCCESSFUL, UNSUCCESSFUL }
//     enum Vote { FAVOUR, AGAINST }
    
//     struct UnlockProposals {
//         uint256 id;
//         string description;
//         uint256 startingAt;
//         uint8 durationInDays;
//         uint256 voteCount;
//         uint256 votesInFavour;
//         uint256 votesAgainst;
//         Status status;
//     }

//     // uint256 internal constant ONE_DAY = 24*60*60;
//     uint256 internal constant ONE_DAY = 60*60;
//     address public assetContract;
//     uint256 public proposalCounts = 0;
//     bool public isProposalActive = false;
//     uint256 public contractLockedAt;
//     MoonLockLib.Socials public socials; 

//     mapping(uint256 => UnlockProposals) public unlockProposals;
//     mapping(uint256 => mapping(address => bool)) public voted;

//     event ProposalCreated( uint256 id, string description, uint256 startingAt, uint8 durationInDays );
//     event ProposalFinalized( uint256 id );
//     event VoteCasted( uint256 id,  Vote vote, uint256 amount);
//     event OwnershipReleased( uint256 id );

//     constructor (address asset, MoonLockLib.Socials memory _socials) {

//         if(Ownable(asset).owner() != msg.sender){
//             revert NOT_OWNER_OF_ASSET();
//         }
//         assetContract = asset;
//         socials = _socials;
//     }

//     function isOwnershipLocked() public view returns(bool){
//         return Ownable(assetContract).owner() == address(this);
//     }

//     function getProposals(uint256 from, uint256 count ) public view returns(UnlockProposals[] memory){
        
//         if(from > proposalCounts){
//             revert OUT_OF_BOUND_REQUEST();
//         }

//         if(count > from){
//             count = from;
//         }

//         uint256 to = from - count;

//         uint256 index = 0;
//         UnlockProposals[] memory proposals = new UnlockProposals[](count);
//         for(uint256 i = from; i > to; i--){
//             UnlockProposals memory p = unlockProposals[i];
//             proposals[index] = p;
//             index++;
//         }

//         return proposals;

//     }

//     function getLatestProposal() public view returns(UnlockProposals memory){
//         return unlockProposals[proposalCounts];
//     }

//     function startProposal(string memory _description, uint256 _startingAt, uint8 _durationInDays) public onlyOwner {

//         if(!isOwnershipLocked()){
//             revert CONTRACT_IS_NOT_LOCKED();
//         }

//         if(isProposalActive){
//             revert PROPOSAL_ALREADY_ACTIVE();
//         }

//         if(_startingAt <= block.timestamp){
//             revert STARTING_TIME_PASSED();
//         }

//         if(_durationInDays < 0 || _durationInDays > 5){
//             revert DURATION_NOT_ALLOWED();
//         }

//         uint256 id = ++proposalCounts;

//         UnlockProposals memory proposal = UnlockProposals (
//             id, _description, _startingAt, _durationInDays, 0, 0, 0, Status.PENDING
//         );

//         isProposalActive = true;
//         contractLockedAt = block.timestamp;
//         unlockProposals[id] = proposal;

//         emit ProposalCreated( id, _description, _startingAt, _durationInDays );

//     }

//     function castVote(Vote vote) public {

//         if(!isOwnershipLocked()){
//             revert CONTRACT_IS_NOT_LOCKED();
//         }

//         if(!isProposalActive){
//             revert PROPOSAL_NOT_ACTIVE();
//         }

//         if(voted[proposalCounts][msg.sender]){
//             revert ALREADY_VOTED();
//         }

//         UnlockProposals memory p = getLatestProposal();

//         if(block.timestamp <= p.startingAt){
//             revert PROPOSAL_NOT_STARTED_YET();
//         }

//         if(block.timestamp > p.startingAt + (p.durationInDays * ONE_DAY) ){
//             revert PROPOSAL_EXPIRED();
//         }
        
//         if(p.status == Status.PENDING){
//             unlockProposals[proposalCounts].status = Status.INPROGRESS;
//         }
 
//         uint256 balanceOfUser = IERC20(assetContract).balanceOf(msg.sender) / (10 ** IERC20(assetContract).decimals());

//         if(balanceOfUser < 1){
//             revert INSUFFICIENT_BALANCE_FOR_VOTING();
//         }

//         if(vote == Vote.FAVOUR){
//             unlockProposals[proposalCounts].votesInFavour += balanceOfUser;
//         }
//         else {
//             unlockProposals[proposalCounts].votesAgainst += balanceOfUser;
//         }

//         voted[proposalCounts][msg.sender] = true;
//         unlockProposals[proposalCounts].voteCount++;

//         emit VoteCasted( p.id, vote, balanceOfUser);

//     }

//     function finalizeProposal() public onlyOwner {

//         if(!isProposalActive){
//             revert PROPOSAL_NOT_ACTIVE();
//         }

//         UnlockProposals memory p = getLatestProposal();

//         if(block.timestamp < p.startingAt + p.durationInDays * ONE_DAY){
//             revert PROPOSAL_NOT_EXPIRED_YET();
//         }

//         if(p.votesInFavour > p.votesAgainst ){
//             // return Ownership to owner
//             unlockProposals[proposalCounts].status = Status.SUCCESSFUL;
//             isProposalActive = false;
//             contractLockedAt = 0;

//             Ownable(assetContract).transferOwnership(owner());
//             emit OwnershipReleased(p.id);

//         }
//         else {
//             unlockProposals[proposalCounts].status = Status.UNSUCCESSFUL;
//             isProposalActive = false;
//         }

//         emit ProposalFinalized(p.id);

//     }

//     function updateSocials(MoonLockLib.Socials memory _socials) public onlyOwner {
//         socials = _socials;
//     }

// }
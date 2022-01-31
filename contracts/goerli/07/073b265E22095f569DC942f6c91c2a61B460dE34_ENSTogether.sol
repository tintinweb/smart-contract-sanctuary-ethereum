// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IENSTogetherNFT.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ENSTogether is ReentrancyGuard, Ownable {

    address public nftContract; 
    uint public cost = 0.01 ether;
    uint public updateStatusCost = 0.005 ether;
    //it will be longer, 5m is just for testing
    uint public timeToRespond = 5 minutes;
    uint public proposalsCounter = 0;
    uint public registryCounter  = 0;

    //Relationship Status
    enum Proposal {NOTHING, PENDING, ACCEPTED, DECLINED}
    Proposal proposalStatus;
    enum Status {NOTHING, TOGETHER, PAUSED, SEPARATED}
    Status relationshipStatus;

    struct Union {
        address to;
        address from;
        uint8 proposalStatus;
        uint8 relationshipStatus;
        uint proposalNumber;
        uint registryNumber;
        uint createdAt;
        bool expired;
    }  
    
    mapping(address => Union) public unionWith;

    constructor(){}

    //PROPOSAL EVENTS
    event ProposalSubmitted(address indexed to, address indexed from, uint indexed _status );
    event ProposalResponded(address indexed to, address indexed from, uint indexed _status );
    event ProposalCancelled(address indexed to, address indexed from);
    //UNION EVENTS
    event GotUnited(address indexed from, address indexed to, uint  _status,
    uint indexed _timestamp, uint  _registrationNumber);
    event UnionStatusUpdated(address indexed from, address indexed to, uint _status,
    uint indexed _timestamp, uint  _registrationNumber);
    //ERRORS
    error SenderAlreadyPending();
    error ReceiverAlreadyPending();
    //BURNED
    event Burned(uint id, bool);

    function propose(address _to) external payable{
        require(msg.value >= cost, "Insufficient amount");
        require(_to != msg.sender, "Can't registry with yourself as a partner");
        //revert if msg.sender is already united 
        require(unionWith[msg.sender].relationshipStatus == uint8(Status.NOTHING) || unionWith[msg.sender].relationshipStatus == uint8(Status.SEPARATED), "You are already united");
        //avoid proposals to a person already in a relationship
        require(unionWith[_to].relationshipStatus == uint8(Status.NOTHING) || unionWith[_to].expired == true , "This address is already in a relationship");
        // Revert if sender sent a proposal and its not expired or receiver has a pending unexpired proposal 
        if(unionWith[msg.sender].to != address(0) && block.timestamp < unionWith[msg.sender].createdAt + timeToRespond && unionWith[msg.sender].expired == false){
         revert SenderAlreadyPending();
        } else if (unionWith[_to].proposalStatus == uint8(Proposal.PENDING) && block.timestamp < unionWith[_to].createdAt + timeToRespond){
         revert ReceiverAlreadyPending();
        } else  {
        Union memory request;
        request.to = _to;
        request.from = msg.sender;
        request.createdAt = block.timestamp;
        request.proposalNumber = proposalsCounter;
        request.proposalStatus = uint8(Proposal.PENDING);
        unionWith[_to]= request;
        unionWith[msg.sender]= request;
        proposalsCounter++;
        }
        emit ProposalSubmitted(_to, msg.sender,  uint8(Proposal.PENDING));
    }

    function respondToProposal(Proposal response, string calldata ens1, string calldata ens2) external payable{
        //shouldnt be expired
        require(block.timestamp < unionWith[msg.sender].createdAt + timeToRespond, "Proposal expired");
        //Only the address who was invited to be united should respond to the proposal.
        require(unionWith[msg.sender].to == msg.sender, "You cant respond your own proposal, that's scary");
        //Proposal status must be "PENDING"
        require(unionWith[msg.sender].proposalStatus == uint8(Proposal.PENDING), "This proposal has already been responded");
        //instance of the proposal
        Union memory acceptOrDecline = unionWith[msg.sender];
         //get the addresses involved
        address from = acceptOrDecline.from;
        address to = acceptOrDecline.to;
        //if declined cancel and reset proposal
         if(uint8(response) == 3){
            acceptOrDecline.expired = true;
            acceptOrDecline.proposalStatus = uint8(Proposal.DECLINED);
            unionWith[to] = acceptOrDecline;
            unionWith[from] = acceptOrDecline;
            emit ProposalCancelled(to, from);
            return;
        }
        //accept scenario
        if(uint8(response) == 2){
        acceptOrDecline.proposalStatus = uint8(Proposal.ACCEPTED);
        acceptOrDecline.relationshipStatus = uint8(Status.TOGETHER);
        acceptOrDecline.createdAt = block.timestamp;
        unionWith[to] = acceptOrDecline;
        unionWith[from] = acceptOrDecline;
        getUnited(from, to, ens1, ens2 );
        } emit ProposalResponded(to, from, uint8(Proposal.ACCEPTED));
    }
    
    function cancelOrResetProposal() public payable{ 
        Union memory currentProposal = unionWith[msg.sender];
        address to = currentProposal.to;
        address from = currentProposal.from;
        currentProposal.proposalStatus = uint8(Proposal.DECLINED);
        currentProposal.expired = true;
        unionWith[to] = currentProposal;
        unionWith[from] = currentProposal;
        emit ProposalCancelled(to, from);
    }

    
   function getUnited( address _from , address _to, string calldata ens1, string calldata ens2)  internal {
        registryCounter++;
        IENSTogetherNFT(nftContract).mint(_from, _to, ens1, ens2);
        emit GotUnited(_from,  msg.sender, uint8(relationshipStatus), block.timestamp, registryCounter - 1 );
   }

    function updateUnion(Status newStatus) external payable {
        require(msg.value >= updateStatusCost, "Insufficient amount");
        //only people in that union can modify the status
        require(unionWith[msg.sender].to == msg.sender ||
         unionWith[msg.sender].from == msg.sender, "You're address doesn't exist on the union registry" );
         //once separated cannot modify status
         require(unionWith[msg.sender].relationshipStatus != uint8(Status.SEPARATED), "You are separated, make another proposal");
        Union memory unionUpdated = unionWith[msg.sender];
        address from = unionUpdated.from;
        address to = unionUpdated.to;
        unionUpdated.relationshipStatus = uint8(newStatus);
        unionUpdated.createdAt = block.timestamp;
        if(uint8(newStatus) == 3){
            //function to clear proposals made and free users for make new ones.
            unionUpdated.expired = true;
            cancelOrResetProposal();
        }
        unionWith[to] = unionUpdated;
        unionWith[from] = unionUpdated;

        emit UnionStatusUpdated(from, to, uint(newStatus), block.timestamp, unionUpdated.registryNumber);
    }


    function getTokenUri(uint256 _tokenId) external view returns(string memory){
       (string memory uri) = IENSTogetherNFT(nftContract).tokenURI(_tokenId);
       return uri;
    }

    function getTokenIDS(address _add) external view returns (uint[] memory){
        (uint[] memory ids)=  IENSTogetherNFT(nftContract).ownedNFTS(_add);
        return ids;
    }
   
    function burn(uint256 tokenId) external {
         IENSTogetherNFT(nftContract).burn(tokenId, msg.sender);
         emit Burned(tokenId, true);
    }

    //Only owner
    function setNftContractAddress(address _ca) public onlyOwner{
        nftContract = _ca;
    }

    function modifyTimeToRespond (uint t) external onlyOwner{
        timeToRespond = t;
    } 
    function modifyProposalCost(uint amount) external onlyOwner{
        cost = amount;
    }
    function modifyStatusUpdateCost(uint amount) external onlyOwner{
        updateStatusCost = amount;
    }

    function withdraw() external  onlyOwner nonReentrant{
        uint amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IENSTogetherNFT {
    function mint(address from, address to,  string calldata ens1,string calldata ens2)  external ;
    function tokenURI(uint256 tokenId)  external view returns (string memory);
    function ownedNFTS(address _owner) external view returns(uint256[] memory);
    function burn(uint256 tokenId, address _add) external;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
    function purchase(uint256 _tokenId) external payable;
    function getPrice() external view returns (uint256);
    function available(uint256 _tokenId) external view returns(bool);
}

interface ICryptoDevsNFT {
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract CryptoDevsDAO is Ownable {
    // store created proposal in contract state
    //allow holders of cryptodev NFT to create a proposal
    //allow holders of cryptodev NFT to vote on the proposal as long as the deadline is not passed
    //execute proposal after the proposal deadline is over - i.e. buy an NFT

    //defining struct for the proposal
    struct Proposal{
       //once the proposal is passed, this token Id will be used to purchase NFT from the fake NFT marketplace that is created.
       uint256 nftTokenId;
       uint256 deadline;
       mapping (uint256 => bool) voters; //whether the voter voted or not
       bool executed; //whether the proposal is executed;
       uint256 yayVotes;
       uint256 nayVotes;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 numProposals;

    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    constructor(address _nftMarketplace, address _cryptodevsNFT) payable{
       nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
       cryptoDevsNFT = ICryptoDevsNFT(_cryptodevsNFT);
    }

    modifier nftHoldersOnly {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0);
        _;
    }

    modifier activeProposalOnly(uint256 proposalIndex) {
    require(
        proposals[proposalIndex].deadline > block.timestamp,
        "DEADLINE_EXCEEDED"
    );
    _;
}

    enum Vote {
    YAY, 
    NAY 
    }

    //create proposal function 
    function createProposal(uint256 _nftTokenId) external nftHoldersOnly returns (uint256){
        require(nftMarketplace.available(_nftTokenId), "This tokenId NFT is not available");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;
        return numProposals - 1;
    }

    function voteOnProposal(uint256 proposalIndex, Vote vote) external nftHoldersOnly activeProposalOnly(proposalIndex){
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint numVotes = 0;

        for (uint256 i = 0; i < voterNFTBalance; i++){

            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if(proposal.voters[tokenId] == false){
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "Already voted");

    if(vote == Vote.YAY){
        proposal.yayVotes += numVotes;
    }else{
        proposal.nayVotes += numVotes;
    }
    }

    //modifier to execute the proposal
    modifier inActiveProposal(uint256 _proposalIndex) {
        require(proposals[_proposalIndex].deadline <= block.timestamp, "deadline not exceeded");
        require(proposals[_proposalIndex].executed == false, "Proposal already executed");
        _;
    }
    
    function executeProposal(uint256 proposalIndex) external nftHoldersOnly inActiveProposal(proposalIndex){
        Proposal storage proposal = proposals[proposalIndex];
        if (proposal.yayVotes > proposal.nayVotes) {
        uint256 nftPrice = nftMarketplace.getPrice();
        require(address(this).balance >= nftPrice, "not enough funds");
        nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
    }

    proposal.executed = true;
    }

    function withdraw() external onlyOwner{
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw");
        payable(owner()).transfer(amount);
    }

    receive() external payable {}

    fallback() external payable {}

}
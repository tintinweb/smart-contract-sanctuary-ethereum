// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
line 972
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
    
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }



// @title  Main contract for NFTfi. This contract manages the ability to create
//         NFT-backed peer-to-peer loans.
// @author smartcontractdev.eth, creator of wrappedkitties.eth, cwhelper.eth, and
//         kittybounties.eth
// @notice There are five steps needed to commence an NFT-backed loan. 
        First,
//         the borrower calls nftContract.approveAll(NFTfi), approving the NFTfi
//         contract to move their NFT's on their behalf. 
        Second, the borrower
//         signs an off-chain message for each NFT that they would like to
//         put up for collateral. This prevents borrowers from accidentally
//         lending an NFT that they didn't mean to lend, due to approveAll()
//         approving their entire collection. 
        Third, the lender calls
//         erc20Contract.approve(NFTfi), allowing NFTfi to move the lender's
//         ERC20 tokens on their behalf. 
        Fourth, the lender signs an off-chain
//         message, proposing the amount, rate, and duration of a loan for a
//         particular NFT. 
        Fifth, the borrower calls NFTfi.beginLoan() to
//         accept these terms and enter into the loan. The NFT is stored in the
//         contract, the borrower receives the loan principal in the specified
//         ERC20 currency, and the lender receives an NFTfi promissory note (in
//         ERC721 form) that represents the rights to either the
//         principal-plus-interest, or the underlying NFT collateral if the
//         borrower does not pay back in time. The lender can freely transfer
//         and trade this ERC721 promissory note as they wish, with the
//         knowledge that transferring the ERC721 promissory note tranfsers the
//         rights to principal-plus-interest and/or collateral, and that they
//         will no longer have a claim on the loan. The ERC721 promissory note
//         itself represents that claim.
// @notice A loan may end in one of two ways. First, a borrower may call
//         NFTfi.payBackLoan() and pay back the loan plus interest at any time,
//         in which case they receive their NFT back in the same transaction.
//         Second, if the loan's duration has passed and the loan has not been
//         paid back yet, a lender can call NFTfi.liquidateOverdueLoan(), in
//         which case they receive the underlying NFT collateral and forfeit
//         the rights to the principal-plus-interest, which the borrower now
//         keeps.


    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

*/


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";



/*interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}
*/
/*
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is IERC165  {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);



    function approve(address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId) public;

}
*/
contract NFTRaffle is Ownable, IERC721Receiver {
    
    function transferFrom(address from, address to, uint256 tokenId, address nftTokenContract) internal {
        // transfer can be called by the Owner or Approved Addresses
        IERC721(nftTokenContract).safeTransferFrom(from, to, tokenId);
    }

    function approveAll(address to, address nftTokenContract) internal {
        // approve can only be called by the owner of the NFT
        IERC721(nftTokenContract).setApprovalForAll(to, true);

    }

    function checkApproval(uint tokenId, address nftTokenContract) internal view returns(bool) {
        address approvedAddress = IERC721(nftTokenContract).getApproved(tokenId);
        return approvedAddress == address(this);
    } 

    function onERC721Received(address , address , uint256 , bytes memory) external pure override returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /*
    function approve(address to, uint256 tokenId) public override {
        emit Approval(owner, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        emit Transfer(from, to, tokenId);
    }
    */
    // keep track of how many raffles are done.
    uint raffleCount = 0;

    // status : 1 = created; 2 = Finished successfully; 3 = Failed, not enough tokens sold; 4 = cancelled by owner.
    
    enum RaffleStatus {
        None,
        Created, 
        Live, 
        Finished,
        Failed,
        Cancelled
    }


    struct Raffle {
        uint raffleId;
        uint creationDate;
        address host;
        address nftTokenContract; 
        uint nftTokenId;
        uint raffleStartDate;
        uint raffleDuration; // in ms 
        uint minimumNumberOfTickets; 
        uint ticketPrice;
        uint numberOfTicketsSold;
        uint status;
        address[] players; 
        int raffleWinnerTicket;
    }


    /*
    function claimNFTCancelled (uint raffleId) public {
        require(msg.sender == raffles[raffleId].host);
    
    }
    */
    

    // duplicate lotteryId? use an array instead of a mapping?
    mapping(uint256 => Raffle) public raffles;


    event Transfer(address to, uint tokenId);

    // remove
    function approveNFT(address nftTokenContract) external {
        approveAll(address(this), nftTokenContract);
    }

    function createRaffle( 
        address nftTokenContract, 
        uint nftTokenId, 
        uint ticketPrice, 
        uint raffleStartDate,
        uint raffleDuration,
        uint minimumNumberOfTickets
    ) external {
        // first we need to transfer the NFT.
        require(raffleStartDate >= block.timestamp);

        // transfering the NFT to contract
            // 1. The holder has to approve the contract. (calling the approve or approveAll on the NFT contract itself)
            // 2. wehave to check that the raffle creator has done so. 
            // 3. they sign a "written text contract" where the terms & conditions of the raffle are specified. line 572
            // 2. The holder has to transfer the NFT.
        

        // first the raffle creator must have approved the nft to the contract.
        require(checkApproval(nftTokenId, nftTokenContract));
        // Transfer NFT to the contract, until raffle is cancelled / unsuccessful or finished then it is able to be claimed.
        transferFrom(msg.sender, address(this), nftTokenId, nftTokenContract);
        // Will fail if it has not been approved. (done from the frontend).
        // nftTokenContract.transferFrom(msg.sender, address(this), nftTokenId);

        // Save loan details to a struct in memory first, to save on gas if any
        // of the below checks fail, and to avoid the "Stack Too Deep" error by
        // clumping the parameters together into one struct held in memory.
       

        ++raffleCount;
        raffles[raffleCount] = Raffle({
            raffleId: raffleCount,
            creationDate: block.timestamp,
            host: msg.sender,
            nftTokenContract: nftTokenContract,
            nftTokenId: nftTokenId,
            raffleStartDate: raffleStartDate,
            raffleDuration: raffleDuration,
            minimumNumberOfTickets: minimumNumberOfTickets,
            ticketPrice: ticketPrice,
            numberOfTicketsSold: 0,
            status: uint(RaffleStatus.Created),
            players: new address[](0),
            raffleWinnerTicket: -1
        });


    }

    function getRaffleDetails (uint raffleId) public view returns(Raffle memory) {
        return raffles[raffleId];
    }



    function updateStartDate (uint raffleId, uint newStartDate) external {
        require(msg.sender == raffles[raffleId].host);
        require(block.timestamp < raffles[raffleId].raffleStartDate);
        require(newStartDate > block.timestamp);
        raffles[raffleId].raffleStartDate = newStartDate;
        
        // if raffle is not live you can change the start date.

        // 1. you set the status to live.
        // 2. you set the startDate to certainDate 
    }

     modifier isActiveRaffle(uint raffleId) {
        require(raffles[raffleId].status == uint(RaffleStatus.Created), "Raffle is not active.");
        _;
    }

    function purchaseTicket(uint amount, uint raffleId) payable external isActiveRaffle(raffleId) {
        // 5. Check out this link for how to transfer ether, https://ethereum.stackexchange.com/questions/69381/using-address-call-value-to-send-ether-from-contract-to-contract-in-0-5-0-and-ab
        Raffle storage raffle = raffles[raffleId];
        require(
            msg.sender != raffle.host, 
            "The raffle host may not purchase from tickets for a token they are raffling."
        );
        require(raffle.raffleStartDate + raffle.raffleDuration >= block.timestamp, "Raffle has ended.");
        require(msg.value == raffle.ticketPrice * amount);
        require(amount > 0);
        uint numberOfTickets = raffle.ticketPrice * amount;
        raffle.numberOfTicketsSold = raffle.numberOfTicketsSold + amount;
        payable(address(this)).transfer(numberOfTickets);
        //payable(numberOfTickets).transfer(address(this).balance);
    }

    function pickWinner(uint raffleId) external onlyOwner {
        // does each need their own ID?
        Raffle storage raffle = raffles[raffleId];
        require(block.timestamp >= raffle.raffleStartDate + raffle.raffleDuration, "Raffle is ongoing.");

        if (raffle.minimumNumberOfTickets <= raffle.numberOfTicketsSold) {
            uint index = random(raffleId) % raffle.players.length;
            address winner = raffle.players[index];
            payable (winner).transfer(address(this).balance); // token transfer?
            // do we need approve for erc721?
            //payable approve(winner, raffle.tokenId);
            raffle.status = uint(RaffleStatus.Finished);
        } else { // not enough tickets sold. Not sure where else this ogic can live
            raffle.status = uint(RaffleStatus.Failed);
            // transfer back NFT to host address
        }

        raffle.players = new address[](0); // do we want to delete all the players of a raffle when it is completed?
    }

    // 2 options:
    // 1. user performs the transfer themselves.
    // 2. owner does the transfer to the winner.
    /*
    function transfer(address to, uint tokenId) external {
        transferFrom(address(this), to, tokenId);
        emit Transfer(to, tokenId);
    }
    */

    // creates a random hash that will become our winner
    function random(uint raffleId) private view returns(uint){
        return  uint (keccak256(abi.encode(block.timestamp, raffles[raffleId].players)));
    }

    function cancelRaffle(uint raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        require(msg.sender == raffle.host);
        // we need to tranfer the NFT back to the host
        raffle.status = uint(RaffleStatus.Cancelled);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC721.sol";
import "IERC721Receiver.sol";
import "ReentrancyGuard.sol";

/**
 * Sealed Bid auction protocol. 
*/

contract SealedBidAuction is Ownable, ReentrancyGuard {

    // Participant wallets array.
    address[] public players;

    // Wallet to amount transfered mapping.
    mapping(address => uint256) public accountToAmount;

    // Wallet to hash of offer + secret mapping.
    mapping(address => bytes32) public accountToHash;

    // Wallet to offer mapping
    mapping(address => uint256) public accountToOffer;

    // Auction winner
    address public winner;

    // Auction sale price.
    uint256 public amount;

    // Hash of minPrice + secret
    bytes32 public minimumPriceHash;

    // minimum price of token
    uint256 public minimumPrice;

    // NFT 
    IERC721 public parentNFT;

    // NFT ID
    uint256 public tokenId;


    // Time when acution changes to reveals == Time when offers close
    uint public revealTime;

    // Time when winner is calculated == Time when reveals close
    uint public winnerTime;

    // Time offset to let owner reveal price
    uint public timeOffset = 5 seconds;

    // States of the auction
    enum AUCTION_STATE{
        CONTRACT_CREATION,
        RECIVEING_OFFERS,
        OFFER_REVEAL,
        CALCULATING_WINNER,
        AUCTION_ENDED
    }

    /**
     * @dev Emitted when contract receives token.
     */
    event ERC721Transfer();

    /**
     * @dev Emitted when `account` makes a secret offer of `hashString`.
     */
    event OfferMade(address account, bytes32 hashString);

    /**
     * @dev Emitted when auction states moves to RECEIVEINF_OFFERS.
     */
    event OffersClosed();

    /**
     * @dev Emitted when `accounts` reveals offer of `price` and `secret`
     */
    event OfferRevealed(address account, string secret, uint256 amount);

    /**
     * @dev Emitted when owner reveals minimum price `amaount`.
     */
    event MinimumPriceRevealed(uint256 amount);

    /**
     * @dev Emitted when `account` wins the auction for an offered `amount`
     */
    event WinnerChosen(address account, uint256 amount);

    /**
     * @dev Emitted when owner get payed `amount`
     */
    event OwnerPayed(uint256 amount);

    /**
     * @dev Emitted when `account` is reinbursed `amount`
     */
    event ParticipantReimbursed(address account, uint256 amount);

    /**
     * @dev Emitted when `account` retrives ERC721.
     */
    event TokenWithdrawal(address account);


    // Stores the auction of the state
    AUCTION_STATE public auction_state;

    /**
     * @dev Auction constructor 
     * Constructs the auction contract.
     * Requirements:
     *  
     *  -'_nftContract' cannot be zero address
    */

    constructor(bytes32 _minimumPriceHash, address _nftContract, uint256 _tokenId, uint _revealTime, uint _winnerTime) {
        require(_nftContract != address(0), "Not a valid ERC721 address");
        auction_state = AUCTION_STATE.CONTRACT_CREATION;
        minimumPriceHash = _minimumPriceHash;
        parentNFT = IERC721(_nftContract);
        tokenId = _tokenId;
        revealTime = _revealTime;
        winnerTime = _winnerTime;
    }

    /**
     * @dev Transfers ERC721 to contract
     * 
     * Requirements:
     *  -Auction state must be CONTRACT_CREATION
     *
     * Emits a {ERC721Transfer} event. 
    */


    function transferAssetToContract() public onlyOwner{
        require(auction_state == AUCTION_STATE.CONTRACT_CREATION);
        parentNFT.transferFrom(_msgSender(), address(this), tokenId);
        auction_state = AUCTION_STATE.RECIVEING_OFFERS;
        emit ERC721Transfer();
    }

    /**
     * @dev Lets a participant make an offer
     * 
     * Requirements:
     *  -Auction state must be RECIVEING_OFFERS
     *  -Contract owner cant make an offer
     *  -Must transfer a non zero amount of eth
     *
     * Emits a {OfferMade} event. 
    */

    
    function makeOffer(bytes32 _hash) public virtual payable{
        require(auction_state == AUCTION_STATE.RECIVEING_OFFERS, 'Wrong auction state');
        require(_msgSender() != owner(), "Owner cant bid");
        require(msg.value > 0, "Need some ETH");
        require(accountToAmount[_msgSender()] == 0, "Cant bid twice"); 
        players.push(payable(_msgSender()));
        accountToAmount[_msgSender()] = msg.value;
        accountToHash[_msgSender()] = _hash;
        emit OfferMade( _msgSender(), _hash);
    }

    /**
     * @dev Changes state of auction to offer reveals
     * 
     * Requirements:
     *  -Time origin must be larger than contract set time
     *  -Auction state must be in RECIVEING_OFFERS
     *  -Must transfer a non zero amount of eth
     *
     * Emits a {OffersClosed} event. 
    */
    function closeOffers() public{
        require(block.timestamp >= revealTime, 'Wait until set time');
        require(auction_state == AUCTION_STATE.RECIVEING_OFFERS, 'Wrong auction state');
        auction_state = AUCTION_STATE.OFFER_REVEAL;
        emit OffersClosed();
    }

    /**
     * @dev Reveals offer of participants
     * 
     * Requirements:
     *  -   accountToAmount[_msgSender()] must not be zero
     *  -   accountToOffer[_msgSender()] must be zero. Prevents double reveals
     *  -   Auction state must be in OFFER_REVEAL
     *  -   Must transfer a non zero amount of eth
     *  -   _amount must be equal or smaller to accountToAmount[_msgSender()]
     *  -   _secret and _amount hash must match stored hash
     *
     *
     * Emits a {OfferRevealed} event. 
    */

    function revealOffer(string memory _secret, uint256 _amount) public virtual{
    require(auction_state == AUCTION_STATE.OFFER_REVEAL, "Not right time");
    require(accountToAmount[_msgSender()] != 0, "You are not a participant"); 
    require(accountToOffer[_msgSender()] == 0, "Can only reveal once"); 
    require(_amount <= accountToAmount[_msgSender()], "Offer invalidated"); 
    require(
        accountToHash[_msgSender()] == keccak256(
            abi.encodePacked(
                _secret,
                _amount
            )
        ), "Hashes do not match"
    );
        accountToOffer[_msgSender()] = _amount;
        emit OfferRevealed(_msgSender(), _secret, _amount);
    }

    /**
     * @dev Changes auction state to CALCULATING_WINNER
     * 
     * Requirements:
     *  -   caller must not be owner
     *  -   time origin must be larger than preset closeReveals time
     *  -   Auction state must be in OFFER_REVEAL
     *
     *
     * Calls _closeReveals() Internal funciton. 
    */

    function closeReveals() public{
        require(block.timestamp >= winnerTime + timeOffset, 'Wait until set time + offset'); //5s despues que vence tiempo de owner
        require(_msgSender() != owner(), "Owner must use winnerCalculation()");
        require(auction_state == AUCTION_STATE.OFFER_REVEAL, 'wrong auction state');
        auction_state = AUCTION_STATE.CALCULATING_WINNER;
        _closeReveals();
    }

    /**
     * @dev Owner reveals minimum price and calculates winner
     * 
     * Requirements:
     *  -   caller must be owner
     *  -   Auction state must be in OFFER_REVEAL
     *  -   time origin must be larger than preset closeReveals time
     *  -   _secret and _amount hash must match stored hash
     *
     *
     * Emits a {MinimumPriceRevealed} event. 
    */

    // TODO un cambio de nombre no vendria mal, creo. Poco intuitivo.?
    function winnerCalculation(string memory _secret, uint256 _amount) public onlyOwner {
        require(auction_state == AUCTION_STATE.OFFER_REVEAL, 'Wrong auction state');
        require(block.timestamp >= winnerTime, 'Wait until set time');
        require(
            minimumPriceHash == keccak256(
                abi.encodePacked(
                    _secret,
                    _amount
                )
            ), "Hashes do not match"
        );
        minimumPrice = _amount;
        auction_state = AUCTION_STATE.CALCULATING_WINNER;
        emit MinimumPriceRevealed(_amount);
        _closeReveals();
    }

    /**
     * @dev Closes reveal period and calculates winner, intenal
     * 
     *
     * Emits a {WinnerChosen} event. 
    */

    function _closeReveals() internal{
        uint256 indexOfWinner;
        uint256 loopAmount;
        uint256 i;
        if(players.length > 0){
            for(i = 0; i < players.length; i++){
                if(accountToOffer[players[i]] > loopAmount){
                    indexOfWinner = i;
                    loopAmount = accountToOffer[players[i]];
                }
            }
            if(loopAmount > 0){
                if(loopAmount >= minimumPrice){
                    winner = players[indexOfWinner];
                    amount = accountToOffer[winner];
                    accountToAmount[winner] = accountToAmount[winner] - accountToOffer[winner];
                } 
            }
            
        }
        auction_state = AUCTION_STATE.AUCTION_ENDED;
        emit WinnerChosen(winner, amount);
    }

    /**
     * @dev Auction owner retrives sale price or nft if it did not sell
     * 
     * Requirements:
     *  -   caller must be owner
     *  -   Auction state must be in AUCTION_ENDED
     *
     *
     * Emits a {OwnerPayed} xor {TokenWithdrawal} event. 
    */

    function ownerGetsPayed() public onlyOwner nonReentrant{
        require(auction_state == AUCTION_STATE.AUCTION_ENDED);
        if(amount > 0){
            uint256 toPay = amount;
            amount = 0;
            payable(owner()).transfer(toPay);
            emit OwnerPayed(toPay);
        }else{
            parentNFT.safeTransferFrom(address(this), _msgSender(), tokenId);
            emit TokenWithdrawal(owner());
        }
    }

    /**
     * @dev Reinburses deposited amount left to participants after auction ends
     * 
     * Requirements:
     *  -   Auction state must be in AUCTION_ENDED
     *  -   accountToAmount[_msgSender()] must be larger than 0
     *
     *
     * Emits a {ParticipantReimbursed} event. 
    */

    function reimburseParticipant() nonReentrant public{
        require(auction_state == AUCTION_STATE.AUCTION_ENDED);
        uint256 reimbursement = accountToAmount[_msgSender()];
        require(reimbursement > 0);
        accountToAmount[_msgSender()] = 0;
        payable(_msgSender()).transfer(reimbursement);
        emit ParticipantReimbursed(_msgSender(), reimbursement);
    }

    /**
     * @dev Auction winner retrives ERC721 token.
     * 
     * Requirements:
     *  -   Auction state must be in AUCTION_ENDED
     *  -   caller must be auction winner
     *
     *
     * Emits a {TokenWithdrawal} event. 
    */

    function winnerRetrivesToken() nonReentrant public{
        require(auction_state == AUCTION_STATE.AUCTION_ENDED);
        require(_msgSender() == winner);
        parentNFT.safeTransferFrom(address(this), _msgSender(), tokenId);
        emit TokenWithdrawal(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
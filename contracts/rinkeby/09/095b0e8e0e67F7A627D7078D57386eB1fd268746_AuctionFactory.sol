// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "SealedBidAuction.sol";

contract AuctionFactory{

    SealedBidAuction[] public sealedBidAuctionArray;

    function createSealedBidAuctionContract(bytes32 _minimumPriceHash, address _nftContract, uint256 _tokenId, uint _revealTime, uint _winnerTime) public returns (uint256){
        SealedBidAuction auction = new SealedBidAuction(_minimumPriceHash, _nftContract, _tokenId, _revealTime, _winnerTime);
        sealedBidAuctionArray.push(auction);
        auction.transferOwnership(msg.sender); 
    }

    function getLastAddressInArray() public view returns (address){
        return address(sealedBidAuctionArray[sealedBidAuctionArray.length -1]);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC721.sol";
import "IERC721Receiver.sol";

contract SealedBidAuction is Ownable, IERC721Receiver {


    address[] public players; // Para poder regresar x a los que no ganan

    mapping(address => uint256) public accountToAmount;
    mapping(address => bytes32) public accountToHash;
    mapping(address => uint256) public accountToOffer;

    address public winner;
    uint256 public amount;
    bytes32 public minimumPriceHash;
    uint256 public minimumPrice;

    IERC721 public parentNFT;
    uint256 public tokenId;

    uint public revealTime;
    uint public winnerTime;

    enum AUCTION_STATE{
        CONTRACT_CREATION,
        RECIVEING_OFFERS,
        OFFER_REVEAL,
        CALCULATING_WINNER,
        AUCTION_ENDED
    }

    AUCTION_STATE public auction_state;

    constructor(bytes32 _minimumPriceHash, address _nftContract, uint256 _tokenId, uint _revealTime, uint _winnerTime) {
        auction_state = AUCTION_STATE.CONTRACT_CREATION;
        minimumPriceHash = _minimumPriceHash;
        parentNFT = IERC721(_nftContract);
        tokenId = _tokenId;
        revealTime = _revealTime;
        winnerTime = _winnerTime;
    }

    function transferAssetToContract() public onlyOwner{
        parentNFT.safeTransferFrom(_msgSender(), address(this), tokenId);
        auction_state = AUCTION_STATE.RECIVEING_OFFERS;
    }

    
    function makeOffer(bytes32 _hash) public virtual payable{
        require(auction_state == AUCTION_STATE.RECIVEING_OFFERS, 'Wrong auction state');
        require(_msgSender() != owner(), "Owner cant bid");
        require(msg.value > 0, "Need some ETH");
        require(accountToAmount[_msgSender()] == 0, "Cant bid twice"); // New participant.
        //event
        players.push(payable(_msgSender()));
        //event
        accountToAmount[_msgSender()] = msg.value;
        //event
        accountToHash[_msgSender()] = _hash;
    }

    function closeOffers() public{
        require(block.timestamp >= revealTime, 'Wait until set time');
        require(auction_state == AUCTION_STATE.RECIVEING_OFFERS, 'Wrong auction state');
        auction_state = AUCTION_STATE.OFFER_REVEAL;
    }

    function revealOffer(string memory _secret, uint256 _amount) public virtual{
    require(auction_state == AUCTION_STATE.OFFER_REVEAL, "Not right time");
    require(accountToAmount[_msgSender()] != 0, "You are not a participant"); // Participant
    require(accountToOffer[_msgSender()] == 0, "Can only reveal once"); // No retrys
    require(_amount <= accountToAmount[_msgSender()], "Offer invalidated"); 
    require(
        accountToHash[_msgSender()] == keccak256(
            abi.encodePacked(
                _secret,
                _amount
            )
        ), "Hashes do not match"
    ); // Hash match
    //event
    accountToOffer[_msgSender()] = _amount;
    }

    // ASolo 5 Seg en pruebas, cuando le hagas deploy hazlo con 30min minimo
    function closeReveals() public{
        require(block.timestamp >= winnerTime+5, 'Wait until set time'); //5s despues que vence tiempo de owner
        require(_msgSender() != owner(), "Owner must use winnerCalculation()");
        require(auction_state == AUCTION_STATE.OFFER_REVEAL, 'wrong auction state');
        auction_state = AUCTION_STATE.CALCULATING_WINNER;
        _closeReveals();
    }

    // Cambiale el nombre y pega el close reveals a final del metodo. Te mamas 
    function winnerCalculation(string memory _secret, uint256 _amount) public onlyOwner {
        require(auction_state == AUCTION_STATE.OFFER_REVEAL, 'Wrong auction state');
        require(block.timestamp >= winnerTime, 'Wait until set time');
        // Que el reveal al menos sea de 1 min ??? pon require si acaso
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
        _closeReveals();
    }

    function _closeReveals() internal{ //internal
    // Verifia que el precio minimo este puesto. 
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
        if(loopAmount >= minimumPrice){
            winner = players[indexOfWinner];
            amount = accountToOffer[winner];
            // Quito lo ofrecido al que gana
            accountToAmount[winner] = accountToAmount[winner] - accountToOffer[winner];
        } 
    }
    auction_state = AUCTION_STATE.AUCTION_ENDED;
    }

    function ownerGetsPayed() public onlyOwner{
        require(auction_state == AUCTION_STATE.AUCTION_ENDED);
        if(amount > 0){
            uint256 toPay = amount;
            amount = 0; //No reentrancy
            payable(owner()).transfer(toPay);
        }else{
            // Nadie gana entonces regresa NFT al que crea subasta.
            parentNFT.safeTransferFrom(address(this), _msgSender(), tokenId);
        }
    }

    function reimburseParticipant() public{
        // Tenga saldo positivo
        require(auction_state == AUCTION_STATE.AUCTION_ENDED);
        uint256 reimbursement = accountToAmount[_msgSender()];
        require(reimbursement > 0);
        accountToAmount[_msgSender()] = 0; // no reent
        payable(_msgSender()).transfer(reimbursement);
    }

    function winnerRetrivesToken() public{
        require(auction_state == AUCTION_STATE.AUCTION_ENDED);
        require(_msgSender() == winner);
        parentNFT.safeTransferFrom(address(this), _msgSender(), tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override returns (bytes4){
         return this.onERC721Received.selector;
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
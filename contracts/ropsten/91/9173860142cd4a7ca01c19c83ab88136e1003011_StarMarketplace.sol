/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

////import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}




            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}




            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

////import "../IERC1155Receiver.sol";
////import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}




            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}




            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

////import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}




            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}



////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
////import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/security/Pausable.sol";
////import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StarMarketplace is Ownable, Pausable, ReentrancyGuard,ERC1155Holder {

    uint120 public gasFee;

    struct Auction{
        // Owner can auction
        address nftOwner;

        // ERC1155 contract address
        address nftToken;

        // ERC1155 nft mint id
        uint256 nftId; 

        // Number of nfts planned for auction
        uint32 nftAmount;

        // Auction duration, seconds
        uint32 duration; 

        // auciotn start time = create block.timestamp 
        uint32 startTime;  

        // the index of the minbid value in the bids[]    
        uint32 minBidIndex;

        // auctioneer depoist gasfee
        uint120 gasFee;

        // nft stuat 0-unstart,1-start,2-success,3-failed
        uint8 status;

        // bidders address, max length = nftAmount
        address[] bidders;
        uint256[] bids;

        // Each bid must be greater than the current maximum bid, record and reduce find per loop
        uint256 highestBid;

        // In order to ensure the safety of funds, at the end of the auction, it is guaranteed that the transfer will not exceed the totalbid
        uint256 totalBid;


    }

    // all of auctions
    Auction[] public auctions;

    // _aucitonId is the index of auctions array
    event CREATEAUCITON(address indexed _owner, address _nftToken, uint256 _erc1155Id, uint32 _amount,uint64 _duration, uint256 _auctionId);
    event BID(address indexed _bidder, uint256 _auctionId, uint256 _price, address _knockout, uint256 _knockoutBid); 
    event ENDAUCTION(address indexed account,uint256 _auctionId,uint256 _status,uint256 _income);

    ///@dev User creates auction for own nft
    ///@param _nftToken ERC1155 contract address
    ///@param _erc1155Id The id of nft the user wants to auction
    ///@param _amount The amount of nft wants to auction
    ///@param _duration how long the auction end
    function createAuction(address _nftToken, uint256 _erc1155Id, uint32 _amount,uint32 _duration) external whenNotPaused payable {
        uint256 size;
        assembly { size := extcodesize(_nftToken) }
        require(size > 0, "NFTMarketplace: need ERC1155 contract address");
        require(_amount > 0 && IERC1155(_nftToken).balanceOf(msg.sender, _erc1155Id) >=  _amount, "NFTMarketplace: insufficent tokens");
        require(_duration > 0,"NFTMarketplace: duration need gt 0");
        require(msg.value >= gasFee,"NFTMarketplace: insufficent gasFee");

        // Return the user's excess gasfee
        if(msg.value > gasFee){
            payable(msg.sender).transfer(msg.value-gasFee);
        }

        IERC1155(_nftToken).safeTransferFrom(msg.sender, address(this), _erc1155Id, _amount, "0x0");
        Auction storage auction = auctions[auctions.length];
        auction.nftOwner = msg.sender;
        auction.nftToken = _nftToken;
        auction.nftId = _erc1155Id;
        auction.nftAmount = _amount;
        auction.duration = _duration;
        auction.startTime = uint32(block.timestamp);
        auction.gasFee = gasFee;
        auction.status = 1;

        emit CREATEAUCITON(msg.sender,_nftToken, _erc1155Id, _amount,_duration, auctions.length-1);
    }

    ///@dev User bids for specified nft
    ///@param _auctionId auction id, from CREATEAUCITON.event._auctionId
    ///@param _price latest bid
    function bid(uint256 _auctionId, uint256 _price) external whenNotPaused payable{
        Auction storage auction = auctions[_auctionId];
        require(auction.duration > 0 && auction.nftAmount>0, "NFTMarketplace: Invalid auction");
        require(block.timestamp >= auction.startTime + auction.duration,"NFTMarketplace: Auction has ended");
        require(_price > auction.highestBid,"NFTMarketplace: Must > highest bid");
        require( _price <= msg.value, "NFTMarketplace: Insufficient fund");

        if(msg.value > _price){
            payable(msg.sender).transfer(msg.value - _price);
        }
        
        uint256 minbid = auction.bids[auction.minBidIndex];
        address minbidder = auction.bidders[auction.minBidIndex];  

        auction.highestBid = _price;
        auction.totalBid += _price;
        if(auction.bidders.length < auction.nftAmount){
            auction.bidders.push(msg.sender);
            auction.bids.push(_price);  
            minbid = 0;
            minbidder = address(0x0);         
        }else{
            // Knock out the lowest price, increase the highest price
            auction.bids[auction.minBidIndex] = _price;            
            auction.bidders[auction.minBidIndex] = msg.sender;
            
            if( auction.minBidIndex < auction.nftAmount - 1 ){
                auction.minBidIndex ++;
            }else{
               auction.minBidIndex = 0; 
            }
            auction.totalBid -= minbid;
            payable(minbidder).transfer(minbid);
            
        }

        emit BID(msg.sender, _auctionId, _price, minbidder, minbid); 
    }

    ///@dev End the auction and assign the nft to the final winner, if the auction fails, return the bid to the participant, and the nft to the auctioneer
    ///@param _auctionId auction id to end
    function endAuction(uint256 _auctionId) external whenNotPaused nonReentrant  {
        Auction storage auction = auctions[_auctionId];
        require(auction.duration > 0 && auction.nftAmount>0, "NFTMarketplace: Invalid auction");
        require(block.timestamp > auction.duration + auction.startTime, "NFTMarketplace: Auction not due");
        require(auction.status>2,"NFTMarketplace: Auction ended!");

        if(auction.bidders.length < auction.nftAmount){// auction failed
            auction.status = 3;
            uint256 totalBid = auction.totalBid;
            // return bid
            for(uint8 i=0;i<auction.bidders.length;i++){
                // if totalBid < auction.bids[i], revert. Guaranteed financial security
                totalBid -= auction.bids[i];
                payable(auction.bidders[i]).transfer(auction.bids[i]);
            }

            // return nft
            IERC1155(auction.nftToken).safeTransferFrom(
                address(this), 
                auction.nftOwner, 
                auction.nftId, 
                auction.nftAmount,
                "0x0"
            );
            emit ENDAUCTION(msg.sender, _auctionId, auction.status, 0);
        }else{//success
            auction.status = 2;
            uint256 minBid = auction.bids[auction.minBidIndex];
            uint256 lastIncome = 0;
            uint256 totalBid = auction.totalBid;
            // 1. Return excess fees
            // 2. bidder harvest nft
            for(uint8 i=0; i<auction.bidders.length; i++){
                lastIncome += auction.bids[i];
                // The minBid is the auction price
                if(auction.bids[i] > minBid){
                    payable(auction.bidders[i]).transfer(auction.bids[i] - minBid);
                    lastIncome -= auction.bids[i] - minBid;
                    totalBid -= auction.bids[i] - minBid;
                }

                IERC1155(auction.nftToken).safeTransferFrom(
                    address(this), 
                    auction.bidders[i], 
                    auction.nftId, 
                    1,
                    "0x0"
                );
            }
            // Guaranteed financial security
            assert(lastIncome == totalBid);

            // 3. Auctioneers earn income
            payable(auction.nftOwner).transfer(lastIncome);
            emit ENDAUCTION(msg.sender, _auctionId, auction.status, lastIncome);
        }
        // any one can do this func,the operator get this gasfee
        payable(msg.sender).transfer(auction.gasFee);
    }

    ///@dev Due to the large change of gasprice, it is necessary to set a reasonable gasfee frequently, and only Owner can set it
    ///@param _gasFee eth fees
    function setGasFee(uint120 _gasFee) external onlyOwner{
        gasFee = _gasFee;
    }

    ///@dev dapp get all of auctions;
    ///@return auctions
    function getAuctions() external view returns (Auction[] memory){
        return auctions;
    }

    ///@dev Contract Receives Ether or BNB or Matic...
    receive() external payable { }

}
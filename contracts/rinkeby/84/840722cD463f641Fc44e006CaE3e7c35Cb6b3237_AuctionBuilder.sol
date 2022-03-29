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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0

import "./PennyAuction.sol";

contract AuctionBuilder {
    PennyAuction[] public auctions;
    mapping(address => PennyAuction[]) public auctionsByOwner;
    mapping(address => uint) public auctionSizeByOwner;

    event AuctionGenerated(address auctionContractAddress);

    function createAuction(
        uint tokenId,
        address nftContract
    ) external{
        PennyAuction pennyAuction = new PennyAuction(
            nftContract, // _nftContractAddress
            tokenId,
            10 ** 15, // 1 finney // startBidAmount
            100, // 1% // _platformFeeInBasisPoints
            5 * 60, // 5 minutes // _initialAuctionLength
            60, // 1 minute // _auctionTimeIncrementOnBid
            10 ** 15, // 1 finney // _minimumBidIncrement
            msg.sender, // chrome // _platformOwnerAddress
            msg.sender // chrome // _nftListerAddress
        );
        _saveNewAuction(pennyAuction);
    }

    function createAuction(
        uint tokenId,
        address nftContract,
        uint startBidAmount,
        uint _platformFeeInBasisPoints,
        uint _initialAuctionLength,
        uint _auctionTimeIncrementOnBid,
        uint _minimumBidIncrement,
        address _platformOwnerAddress,
        address _nftListerAddress
    ) external{
        PennyAuction pennyAuction = new PennyAuction(
            nftContract, // _nftContractAddress
            tokenId,
            startBidAmount, // 1 eth // startBidAmount
            _platformFeeInBasisPoints, // 1% // _platformFeeInBasisPoints
            _initialAuctionLength, // 5 minutes // _initialAuctionLength
            _auctionTimeIncrementOnBid, // 1 minute // _auctionTimeIncrementOnBid
            _minimumBidIncrement, // 0.1 eth // _minimumBidIncrement
            _platformOwnerAddress, // chrome // _platformOwnerAddress
            _nftListerAddress // chrome // _nftListerAddress
        );
        _saveNewAuction(pennyAuction);
    }

    function _saveNewAuction(PennyAuction pennyAuction) private {
        auctions.push(pennyAuction);
        auctionsByOwner[msg.sender].push(pennyAuction);
        auctionSizeByOwner[msg.sender] += 1;
        emit AuctionGenerated(address(pennyAuction));
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/utils/Strings.sol";

// someones deploy us [contract] with nft contract address
// lister approves us [contract] to take nft or take all of their nfts
// lister starts the auction. here we [contract] take possession of the nft.

// buyers can place bid, this pushes expiration time out
// as time passes, auction will eventually end when time is greater than expiration time
// smaller bids are rejected
// a higher bid becomes the winning bid and previous winning bid is claimable as refund
// higher bid is calculated as previousBid + minimum increase + platformFee
// there is only 1 winning bidder at any time
// when auction ends, if there is winner, they can claim their nft
// when auction ends, if there is no winner, they lister can claim their nft
// when auction ends, owner can claim the highest bidding amount
// when auction ends, lister can claim their portion of fees, how much, unknown?
// anytime, the owner can claim platform fees

// Assumptions:
// 1.Auction Builder is the same as NFT Lister


import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PennyAuction is IERC721Receiver, Ownable {
    using Strings for uint;

    IERC721 public immutable nftContract;
    uint public immutable tokenId;
    bool public _weHavePossessionOfNft;
    address public nftListerAddress;

    uint public expiration;
    uint public minimumBidIncrement;
    uint public platformFeeInBasisPoints;
    uint public auctionTimeIncrementOnBid;
    uint public initialAuctionLength;

    address public winningAddress;
    uint public highestBid;
    mapping(address => uint) public pendingRefunds; // biddersAddress => theirBidAmount
    uint public _platformFeesAccumulated;

    event Bid(address from, uint amount);
    event MoneyOut(address to, uint amount);
    event NftOut(address to, uint tokenId);
    event NftIn(address from, uint tokenId);

    constructor(
        address _nftContractAddress,
        uint _tokenId,
        uint startBidAmount,
        uint _platformFeeInBasisPoints,
        uint _initialAuctionLength,
        uint _auctionTimeIncrementOnBid,
        uint _minimumBidIncrement,
        address _platformOwnerAddress,
        address _nftListerAddress){
            nftContract = IERC721(_nftContractAddress);
            _transferOwnership(_platformOwnerAddress);
            tokenId = _tokenId;
            nftListerAddress = _nftListerAddress;
            initialAuctionLength = _initialAuctionLength;
            highestBid = startBidAmount;
            platformFeeInBasisPoints = _platformFeeInBasisPoints;
            auctionTimeIncrementOnBid = _auctionTimeIncrementOnBid;
            minimumBidIncrement = _minimumBidIncrement;
    }

    function startAuction() youAreTheNftLister external{
        address operatorAddress = nftContract.getApproved(tokenId);
        require(operatorAddress == address(this), 'approval not found');
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
        expiration = block.timestamp + initialAuctionLength;
        _weHavePossessionOfNft = true;
    }

    modifier auctionHasStarted() {
        require(expiration != 0, 'auction has not started');
        _;
    }

    modifier auctionHasEnded() {
        require(block.timestamp > expiration, "auction is still active");
        _;
    }

    modifier auctionHasNotEnded() {
        require(expiration > block.timestamp, "auction has expired");
        _;
    }

    modifier thereIsNoWinner() {
        require(winningAddress == address(0), "there is a winner");
        _;
    }

    modifier thereIsAWinner() {
        require(winningAddress != address(0), 'there is no winner');
        _;
    }

    modifier youAreTheWinner() {
        require(msg.sender == winningAddress, "you are not the winner");
        _;
    }

    modifier youAreTheNftLister() {
        require(msg.sender == nftListerAddress, "you are not the lister");
        _;
    }

    modifier weHavePossessionOfNft() {
        require(_weHavePossessionOfNft == true, "we dont have the nft");
        _;
    }

    function calculatePlatformFee(uint amount, uint bp) pure public returns(uint){
        return (amount * bp) / 10000;
    }

    function bid() auctionHasStarted auctionHasNotEnded external payable {
        uint totalNextBid = highestBid + minimumBidIncrement;
        require(msg.value == totalNextBid,
            string(abi.encodePacked("the required bid amount is: ", totalNextBid.toString()))
        );

        uint platformFee = calculatePlatformFee(totalNextBid, platformFeeInBasisPoints);
        _platformFeesAccumulated += platformFee;

        pendingRefunds[winningAddress] += highestBid; // current highest bid
        highestBid = totalNextBid; // new highest bid
        winningAddress = msg.sender;
        expiration = block.timestamp + auctionTimeIncrementOnBid;
        emit Bid(msg.sender, totalNextBid);
    }

    function secondsLeftInAuction() external view returns(uint) {
        if(expiration == 0){
            return 0;
        } else if(expiration < block.timestamp){
            return 0;
        } else {
            return expiration - block.timestamp;
        }
    }

    function doEmptyTransaction() external { }

    function claimNftWhenNoAction() auctionHasStarted auctionHasEnded
        thereIsNoWinner youAreTheNftLister weHavePossessionOfNft external {
            _transfer();
    }

    function claimNftUponWinning() auctionHasStarted auctionHasEnded
        thereIsAWinner youAreTheWinner weHavePossessionOfNft external {
            _transfer();
    }

    function claimPlatformFees() onlyOwner external {
        uint amountToSend = _platformFeesAccumulated;
        _platformFeesAccumulated = 0;
        _sendMoney(amountToSend);
    }

    function claimFinalBidAmount() auctionHasStarted auctionHasEnded
        thereIsAWinner youAreTheNftLister public {
            uint bidAmount = highestBid;
            uint platformFee = calculatePlatformFee(bidAmount, platformFeeInBasisPoints);
            bidAmount -= platformFee;
            highestBid = 0;
            _sendMoney(bidAmount);
    }

    function claimLoosingBids() external {
        require(pendingRefunds[msg.sender] > 0, "you have no refund due");
        uint bidAmount = pendingRefunds[msg.sender];
        uint platformFee = calculatePlatformFee(bidAmount, platformFeeInBasisPoints);
        bidAmount -= platformFee;
        pendingRefunds[msg.sender] = 0;
        _sendMoney(bidAmount);
    }

    function _transfer() private {
        _weHavePossessionOfNft = false;
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId);
        emit NftOut(msg.sender, tokenId);
    }

    function _sendMoney(uint amount) private {
        (bool success, bytes memory data) = payable(msg.sender).call{value: amount}("");
        require(success, 'failed to send money  ');
        emit MoneyOut(msg.sender, amount);
    }

    function shutdown() onlyOwner external {
        selfdestruct(payable(msg.sender));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4){
        require(_weHavePossessionOfNft == false, "we already have an nft");
        emit NftIn(from, tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    function renounceOwnership() public virtual override onlyOwner { }
}
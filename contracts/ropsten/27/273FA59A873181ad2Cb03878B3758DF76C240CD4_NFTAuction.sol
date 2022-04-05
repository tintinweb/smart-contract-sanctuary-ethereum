//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title An Auction Contract for bidding one single NFT
/// @author Anthony Lau
/// @notice This contract can be used for auctioning NFTs, and accepts any ERC20 token as payment
contract NFTAuction is Ownable {
    struct Auction {
        uint32 bidIncreasePercentage;
        uint32 auctionBidPeriod; // Time that the auction lasts until another bid occurs
        uint64 auctionEnd;
        uint128 startPrice;
        uint128 highestBid;
        uint256 tokenId;
        address nftContractAddress;
        address highestBidder;
        address nftSeller;
        address ERC20Token; // Seller can specify an ERC20 token that can be used to bid the NFT
    }

    /** Default values that are used if not specified by the NFT seller */
    uint32 public defaultBidIncreasePercentage;
    uint32 public minimumBidIncreasePercentage;
    uint32 public defaultAuctionBidPeriod;

    Auction singleNFTAuction;

    constructor() {
        defaultBidIncreasePercentage = 1000; // 10%
        defaultAuctionBidPeriod = 86400; // 1 day
        minimumBidIncreasePercentage = 500; // minimum 5%
    }

    /** Modifiers */
    modifier isAuctionNotStartedByOwner(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(
            singleNFTAuction.nftSeller != _msgSender(),
            "Auction already started by owner"
        );

        if (singleNFTAuction.nftSeller != address(0)) {
            require(
                _msgSender() == IERC721(_nftContractAddress).ownerOf(_tokenId),
                "Caller doesn't own the NFT"
            );

            _resetAuction();
        }
        _;
    }

    modifier auctionOnGoing() {
        require(_isAuctionOnGoing(), "Auction has ended");
        _;
    }

    modifier startPriceCompliance(uint256 _startPrice) {
        require(_startPrice > 0, "Starting price cannot be 0");
        _;
    }

    modifier paymentCompliance(address _erc20Token, uint128 _bidAmount) {
        require(
            _isPaymentAccepted(_erc20Token, _bidAmount),
            "Bid has to be made in specified ERC20 token"
        );
        _;
    }

    modifier bidCompliance(uint128 _bidAmount) {
        require(
            _isNextBidHigher(_bidAmount),
            "The bid amount is less than previous bid"
        );
        _;
    }

    modifier bidIncreasePercentageCompliance(uint32 _bidIncreasePercentage) {
        require(
            _bidIncreasePercentage >= minimumBidIncreasePercentage,
            "Bid increase percentage too low"
        );
        _;
    }

    modifier notNftSeller() {
        require(
            _msgSender() != singleNFTAuction.nftSeller,
            "Seller cannot bid on own NFT"
        );
        _;
    }

    /** public GETTER */
    function _getStartPrice() public view returns (uint128) {
        return singleNFTAuction.startPrice;
    }

    function _getHighestBid() public view returns (uint128) {
        return singleNFTAuction.highestBid;
    }

    function _getHighestBidder() public view returns (address) {
        return singleNFTAuction.highestBidder;
    }

    function _getNFTSeller() public view returns (address) {
        return singleNFTAuction.nftSeller;
    }

    function _getERC20TokenAddress() public view returns (address) {
        return singleNFTAuction.ERC20Token;
    }

    function _getBidIncreasePercentage() internal view returns (uint32) {
        uint32 bidIncreasePercentage = singleNFTAuction.bidIncreasePercentage;

        if (bidIncreasePercentage == 0) {
            return defaultBidIncreasePercentage;
        } else {
            return bidIncreasePercentage;
        }
    }

    function _getAuctionBidPeriod() public view returns (uint32) {
        uint32 auctionBidPeriod = singleNFTAuction.auctionBidPeriod;

        if (auctionBidPeriod == 0) {
            return defaultAuctionBidPeriod;
        } else {
            return auctionBidPeriod;
        }
    }

    function _getAuctionEnd() public view returns (uint64) {
        return singleNFTAuction.auctionEnd;
    }

    /** public functions */
    function makeBid(address _erc20Token, uint128 _bidAmount)
        external
        auctionOnGoing
        notNftSeller
        paymentCompliance(_erc20Token, _bidAmount)
        bidCompliance(_bidAmount)
    {
        _reversePrevBidAndUpdateHighestBid(_bidAmount);
        emit BidMade(
            singleNFTAuction.nftContractAddress,
            singleNFTAuction.tokenId,
            _msgSender(),
            _erc20Token,
            _bidAmount
        );
        _updateOnGoingAuction(
            singleNFTAuction.nftContractAddress,
            singleNFTAuction.tokenId
        );
    }

    function claimAuctionResult(address _nftContractAddress, uint256 _tokenId)
        external
    {
        require(!_isAuctionOnGoing(), "Auction is not ended yet");
        require(
            _msgSender() == singleNFTAuction.highestBidder,
            "Caller is not the highest bidder"
        );
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit AuctionSettled(_nftContractAddress, _tokenId, _msgSender());
    }

    /** Only owner */
    // Qucikly create an auction that uses the default bid increase percentage & auction bid period
    function createDefaultNFTAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _startPrice
    )
        external
        isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
        startPriceCompliance(_startPrice)
        onlyOwner
    {
        _createNFTAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _startPrice
        );
    }

    function createNFTAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _startPrice,
        uint32 _auctionBidPeriod,
        uint32 _bidIncreasePercentage
    )
        external
        isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
        startPriceCompliance(_startPrice)
        bidIncreasePercentageCompliance(_bidIncreasePercentage)
        onlyOwner
    {
        singleNFTAuction.auctionBidPeriod = _auctionBidPeriod;
        singleNFTAuction.bidIncreasePercentage = _bidIncreasePercentage;
        _createNFTAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _startPrice
        );
    }

    /** Internal */
    function _createNFTAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _startPrice
    ) internal {
        if (_erc20Token != address(0)) {
            singleNFTAuction.ERC20Token = _erc20Token;
        }
        singleNFTAuction.nftContractAddress = _nftContractAddress;
        singleNFTAuction.tokenId = _tokenId;
        singleNFTAuction.startPrice = _startPrice;

        singleNFTAuction.nftSeller = _msgSender();

        emit NftAuctionCreated(
            _nftContractAddress,
            _tokenId,
            _msgSender(),
            _erc20Token,
            _startPrice,
            _getAuctionBidPeriod(),
            _getBidIncreasePercentage()
        );
        _updateOnGoingAuction(_nftContractAddress, _tokenId);
    }

    function _updateOnGoingAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        if (_isBidMade()) {
            // only escrow the nft when an actual bid is made
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _updateAuctionEnd();
        }
    }

    function _updateAuctionEnd() internal {
        // The auction end time is always set by now() + bid period
        singleNFTAuction.auctionEnd =
            _getAuctionBidPeriod() +
            uint64(block.timestamp);
        emit AuctionPeriodUpdated(
            singleNFTAuction.nftContractAddress,
            singleNFTAuction.tokenId,
            singleNFTAuction.auctionEnd
        );
    }

    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = singleNFTAuction.nftSeller;
        address _highestBidder = singleNFTAuction.highestBidder;
        uint128 _highestBid = singleNFTAuction.highestBid;
        _resetBids();

        _payout(_nftSeller, _highestBid);
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            _highestBidder,
            _tokenId
        );

        _resetAuction();
        emit NFTTransferredAndSellerPaid(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _highestBid,
            _highestBidder
        );
    }

    function _transferNftToAuctionContract(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = singleNFTAuction.nftSeller;

        if (IERC721(_nftContractAddress).ownerOf(_tokenId) == _nftSeller) {
            IERC721(_nftContractAddress).transferFrom(
                _nftSeller,
                address(this),
                _tokenId
            );
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "NFT transfer failed"
            );
        } else {
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "Seller doesn't own the NFT"
            );
        }
    }

    function _reversePrevBidAndUpdateHighestBid(uint128 _bidAmount) internal {
        address prevHighestBidder = singleNFTAuction.highestBidder;
        uint256 prevHighestBid = singleNFTAuction.highestBid;

        _updateHighestBid(_bidAmount);

        if (prevHighestBidder != address(0)) {
            _payout(prevHighestBidder, prevHighestBid);
        }
    }

    function _updateHighestBid(uint128 _bidAmount) internal {
        address auctionERC20Token = singleNFTAuction.ERC20Token;

        IERC20(auctionERC20Token).transferFrom(
            _msgSender(),
            address(this),
            _bidAmount
        );
        singleNFTAuction.highestBid = _bidAmount;
        singleNFTAuction.highestBidder = _msgSender();
    }

    function _resetAuction() internal {
        singleNFTAuction.startPrice = 0;
        singleNFTAuction.bidIncreasePercentage = 0;
        singleNFTAuction.auctionBidPeriod = 0;
        singleNFTAuction.auctionEnd = 0;
        singleNFTAuction.nftSeller = address(0);
        singleNFTAuction.ERC20Token = address(0);
    }

    function _resetBids() internal {
        singleNFTAuction.highestBidder = address(0);
        singleNFTAuction.highestBid = 0;
    }

    function _payout(address _recipient, uint256 _amount) internal {
        address auctionERC20Token = singleNFTAuction.ERC20Token;

        IERC20(auctionERC20Token).transfer(_recipient, _amount);
    }

    /** Internal check */
    function _isAuctionOnGoing() internal view returns (bool) {
        uint64 auctionEndTimestamp = singleNFTAuction.auctionEnd;
        // if auctionEnd is 0 which means no bid is made yet, but still on going
        return (auctionEndTimestamp == 0 ||
            block.timestamp < auctionEndTimestamp);
    }

    function _isBidMade() internal view returns (bool) {
        return singleNFTAuction.highestBid > 0;
    }

    function _isNextBidHigher(uint128 _bidAmount) internal view returns (bool) {
        // next bid needs to be a % higher than the previous bid
        uint256 bidIncreaseAmount = (singleNFTAuction.highestBid *
            (10000 + _getBidIncreasePercentage())) / 10000;
        return (msg.value >= bidIncreaseAmount ||
            _bidAmount >= bidIncreaseAmount);
    }

    function _isPaymentAccepted(address _erc20Token, uint128 _bidAmount)
        internal
        view
        returns (bool)
    {
        address erc20TokenUsedToBid = singleNFTAuction.ERC20Token;

        return
            msg.value == 0 &&
            erc20TokenUsedToBid == _erc20Token &&
            _bidAmount > 0;
    }

    /** Events */
    event NftAuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 minPrice,
        uint32 auctionBidPeriod,
        uint32 bidIncreasePercentage
    );

    event BidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        address erc20Token,
        uint256 bidAmount
    );

    event AuctionPeriodUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint64 auctionEndPeriod
    );

    event AuctionSettled(
        address nftContractAddress,
        uint256 tokenId,
        address auctionSettler
    );

    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint128 nftHighestBid,
        address nftHighestBidder
    );
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
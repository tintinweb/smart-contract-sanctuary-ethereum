// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./NFTingBase.sol";

contract NFTingAuction is NFTingBase {
    using Counters for Counters.Counter;

    struct Auction {
        address nftAddress;
        uint256 tokenId;
        uint256 amount;
        address creator;
        uint256 startedAt;
        uint256 endAt;
        uint256 maxBidAmount;
        address winner;
        mapping(address => uint256) biddersToAmount;
        mapping(address => bool) biddersToClaimed;
        address[] bidders;
    }

    Counters.Counter private currentAuctionId;
    mapping(uint256 => Auction) internal auctions;

    event AuctionCreated(
        uint256 _auctionId,
        address indexed _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        address indexed _creator,
        uint256 _startedAt,
        uint256 _endAt
    );
    event AuctionCanceled(
        uint256 _auctionId,
        address indexed _nftAddress,
        uint256 _tokenId,
        address indexed _creator,
        uint256 _endAt
    );
    event BidCreated(uint256 _auctionId, address _bidder, uint256 _amount);
    event BidUpdated(uint256 _auctionId, address _bidder, uint256 _amount);

    modifier isRunningAuction(uint256 _auctionId) {
        Auction storage auction = auctions[_auctionId];
        if (auction.creator == address(0)) {
            revert NotExistingAuction(_auctionId);
        } else if (auction.endAt < block.timestamp) {
            revert ExpiredAuction(_auctionId);
        }

        _;
    }

    modifier isExistingBidder(uint256 _auctionId) {
        Auction storage auction = auctions[_auctionId];
        if (auction.biddersToAmount[_msgSender()] == 0) {
            revert NotExistingBidder(_msgSender());
        }

        _;
    }

    modifier isExpiredAuction(uint256 _auctionId) {
        Auction storage auction = auctions[_auctionId];
        if (auction.startedAt == 0) {
            revert NotExistingAuction(_auctionId);
        } else if (auction.endAt >= block.timestamp) {
            revert RunningAuction(_auctionId);
        }

        _;
    }

    modifier isBiddablePrice(uint256 _auctionId, uint256 _price) {
        Auction storage auction = auctions[_auctionId];
        if (
            auction.maxBidAmount >=
            _price + auction.biddersToAmount[_msgSender()]
        ) {
            revert NotEnoughPriceToBid();
        }

        _;
    }

    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _durationInMinutes,
        uint256 _startingBid
    )
        external
        onlyNFT(_nftAddress)
        isTokenOwnerOrApproved(_nftAddress, _tokenId, _amount, _msgSender())
        isApprovedMarketplace(_nftAddress, _tokenId, _msgSender())
    {
        if (
            _amount == 0 ||
            (_amount > 1 &&
                _supportsInterface(_nftAddress, INTERFACE_ID_ERC721))
        ) {
            revert InvalidAmountOfTokens(_amount);
        }

        currentAuctionId.increment();
        uint256 auctionId = currentAuctionId.current();

        Auction storage newAuction = auctions[auctionId];
        newAuction.nftAddress = _nftAddress;
        newAuction.tokenId = _tokenId;
        newAuction.creator = _msgSender();
        newAuction.startedAt = block.timestamp;
        newAuction.endAt = block.timestamp + _durationInMinutes * 60 seconds;
        newAuction.maxBidAmount = _startingBid;
        newAuction.amount = _amount;

        _transfer721And1155(
            _msgSender(),
            address(this),
            newAuction.nftAddress,
            newAuction.tokenId,
            newAuction.amount
        );

        emit AuctionCreated(
            auctionId,
            newAuction.nftAddress,
            newAuction.tokenId,
            newAuction.amount,
            _msgSender(),
            newAuction.startedAt,
            newAuction.endAt
        );
    }

    function cancelAuction(uint256 _auctionId)
        external
        nonReentrant
        isRunningAuction(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];
        if (_msgSender() != auction.creator) revert NotAuctionCreatorOrOwner();
        auction.endAt = block.timestamp;
        auction.winner = address(0);

        _transfer721And1155(
            address(this),
            _msgSender(),
            auction.nftAddress,
            auction.tokenId,
            auction.amount
        );

        emit AuctionCanceled(
            _auctionId,
            auction.nftAddress,
            auction.tokenId,
            auction.creator,
            block.timestamp
        );
    }

    function createBid(uint256 _auctionId)
        external
        payable
        isRunningAuction(_auctionId)
        isBiddablePrice(_auctionId, msg.value)
    {
        Auction storage auction = auctions[_auctionId];
        if (_msgSender() == auction.creator) revert SelfBid();
        auction.biddersToAmount[_msgSender()] = msg.value;
        auction.winner = _msgSender();
        auction.maxBidAmount = msg.value;
        auction.bidders.push(_msgSender());

        emit BidCreated(_auctionId, _msgSender(), msg.value);
    }

    function increaseBidPrice(uint256 _auctionId)
        external
        payable
        isRunningAuction(_auctionId)
        isExistingBidder(_auctionId)
        isBiddablePrice(_auctionId, msg.value)
    {
        Auction storage auction = auctions[_auctionId];
        uint256 newAmount = auction.biddersToAmount[_msgSender()] + msg.value;
        auction.biddersToAmount[_msgSender()] = newAmount;
        auction.winner = _msgSender();
        auction.maxBidAmount = newAmount;

        emit BidUpdated(_auctionId, _msgSender(), newAmount);
    }

    function cancelBid(uint256 _auctionId)
        external
        nonReentrant
        isRunningAuction(_auctionId)
        isExistingBidder(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];

        uint256 msgSenderIndex = 0;
        if (_msgSender() == auction.winner) {
            // Current winner canceled bid, find next winner
            address newWinner = address(0);
            uint256 newMaxBidAmount = 0;
            for (uint256 i; i < auction.bidders.length; i++) {
                if (auction.bidders[i] != _msgSender()) {
                    if (
                        newMaxBidAmount <
                        auction.biddersToAmount[auction.bidders[i]]
                    ) {
                        newWinner = auction.bidders[i];
                        newMaxBidAmount = auction.biddersToAmount[newWinner];
                    }
                } else {
                    msgSenderIndex = i;
                }
            }

            auction.winner = newWinner;
            auction.maxBidAmount = newMaxBidAmount;
        } else {
            for (uint256 i; i < auction.bidders.length; i++) {
                if (auction.bidders[i] == _msgSender()) {
                    msgSenderIndex = i;
                    break;
                }
            }
        }

        uint256 bidAmount = auction.biddersToAmount[_msgSender()];

        auction.bidders[msgSenderIndex] = auction.bidders[
            auction.bidders.length - 1
        ];
        auction.bidders.pop();
        delete auction.biddersToAmount[_msgSender()];

        payable(_msgSender()).transfer(bidAmount);
    }

    function claim(uint256 _auctionId)
        external
        nonReentrant
        isExpiredAuction(_auctionId)
    {
        Auction storage auction = auctions[_auctionId];

        if (
            auction.creator != _msgSender() &&
            auction.biddersToAmount[_msgSender()] == 0
        ) {
            revert NotBidder(_auctionId, _msgSender());
        } else if (auction.biddersToClaimed[_msgSender()]) {
            revert AlreadyWithdrawn(_auctionId, _msgSender());
        }

        auction.biddersToClaimed[_msgSender()] = true;

        if (auction.creator == _msgSender()) {
            if (auction.bidders.length == 0) {
                // No bidders, auction creator withdraw the nft
                _transfer721And1155(
                    address(this),
                    _msgSender(),
                    auction.nftAddress,
                    auction.tokenId,
                    auction.amount
                );
            } else {
                // Auction creater gets the winning bid amount
                uint256 amount = _payFee(
                    auction.nftAddress,
                    auction.tokenId,
                    auction.maxBidAmount
                );
                payable(_msgSender()).transfer(amount);
            }
        } else if (auction.winner == _msgSender()) {
            // Winner gets the NFT
            _transfer721And1155(
                address(this),
                _msgSender(),
                auction.nftAddress,
                auction.tokenId,
                auction.amount
            );
        } else {
            // Others withdraw their bid
            payable(_msgSender()).transfer(
                auction.biddersToAmount[_msgSender()]
            );
        }
    }

    function getAuctionDetailsById(uint256 _auctionId)
        external
        view
        isRunningAuction(_auctionId)
        returns (
            address nftAddress,
            uint256 tokenId,
            uint256 amount,
            address creator,
            uint256 startedAt,
            uint256 endAt,
            uint256 maxBidAmount,
            address winner,
            address[] memory bidders,
            uint256[] memory amounts
        )
    {
        Auction storage curAuction = auctions[_auctionId];

        amounts = new uint256[](curAuction.bidders.length);

        for (uint256 i; i < curAuction.bidders.length; i++) {
            amounts[i] = curAuction.biddersToAmount[curAuction.bidders[i]];
        }
        return (
            curAuction.nftAddress,
            curAuction.tokenId,
            curAuction.amount,
            curAuction.creator,
            curAuction.startedAt,
            curAuction.endAt,
            curAuction.maxBidAmount,
            curAuction.winner,
            curAuction.bidders,
            amounts
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interface/INFTingConfig.sol";
import "../utilities/NFTingErrors.sol";

contract NFTingBase is
    Context,
    Ownable,
    IERC721Receiver,
    IERC1155Receiver,
    ReentrancyGuard
{
    bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 internal constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    INFTingConfig config;

    uint256 feesCollected;

    modifier onlyNFT(address _addr) {
        if (
            !_supportsInterface(_addr, INTERFACE_ID_ERC1155) &&
            !_supportsInterface(_addr, INTERFACE_ID_ERC721)
        ) {
            revert InvalidAddressProvided(_addr);
        }

        _;
    }

    modifier isTokenOwnerOrApproved(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        address _addr
    ) {
        if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC1155)) {
            if (
                IERC1155(_nftAddress).balanceOf(_addr, _tokenId) < _amount &&
                !IERC1155(_nftAddress).isApprovedForAll(_addr, _msgSender())
            ) {
                revert NotTokenOwnerOrInsufficientAmount();
            }
            _;
        } else if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC721)) {
            if (
                IERC721(_nftAddress).ownerOf(_tokenId) != _addr &&
                IERC721(_nftAddress).getApproved(_tokenId) != _addr
            ) {
                revert NotTokenOwnerOrInsufficientAmount();
            }
            _;
        } else {
            revert InvalidAddressProvided(_nftAddress);
        }
    }

    modifier isApprovedMarketplace(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC1155)) {
            if (
                !IERC1155(_nftAddress).isApprovedForAll(_owner, address(this))
            ) {
                revert NotApprovedMarketplace();
            }
            _;
        } else if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC721)) {
            if (
                !IERC721(_nftAddress).isApprovedForAll(_owner, address(this)) &&
                IERC721(_nftAddress).getApproved(_tokenId) != address(this)
            ) {
                revert NotApprovedMarketplace();
            }
            _;
        } else {
            revert InvalidAddressProvided(_nftAddress);
        }
    }

    function _transfer721And1155(
        address _from,
        address _to,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount
    ) internal virtual {
        if (_amount == 0) {
            revert ZeroAmountTransfer();
        }

        if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC1155)) {
            IERC1155(_nftAddress).safeTransferFrom(
                _from,
                _to,
                _tokenId,
                _amount,
                ""
            );
        } else if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(_from, _to, _tokenId);
        } else {
            revert InvalidAddressProvided(_nftAddress);
        }
    }

    function _supportsInterface(address _addr, bytes4 _interface)
        internal
        view
        returns (bool)
    {
        return IERC165(_addr).supportsInterface(_interface);
    }

    function checkRoyalties(address _contract) internal view returns (bool) {
        return IERC165(_contract).supportsInterface(INTERFACE_ID_ERC2981);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            type(IERC1155Receiver).interfaceId == _interfaceId ||
            type(IERC721Receiver).interfaceId == _interfaceId;
    }

    function setConfig(address newConfig) external onlyOwner {
        if (newConfig == address(0)) {
            revert ZeroAddress();
        }
        config = INFTingConfig(newConfig);
    }

    function _addBuyFee(uint256 price) internal view returns (uint256) {
        return price += (price * config.buyFee()) / 10000;
    }

    function _payFee(
        address token,
        uint256 tokenId,
        uint256 price
    ) internal returns (uint256 rest) {
        // Cut buy fee
        uint256 listedPrice = (price * 10000) / (10000 + config.buyFee());
        uint256 buyFee = price - listedPrice;

        // If the NFT was created on our marketplace, pay creator fee
        uint256 royaltyFee;
        if (checkRoyalties(token)) {
            (address creator, uint256 royaltyAmount) = IERC2981(token)
                .royaltyInfo(tokenId, listedPrice);
            payable(creator).transfer(royaltyAmount);

            royaltyFee = royaltyAmount;
        }

        // Cut sell fee and creator fee
        uint256 sellFee = (listedPrice * config.sellFee()) / 10000;
        rest = listedPrice - sellFee - royaltyFee;

        if (config.treasury() != address(0)) {
            payable(config.treasury()).transfer(buyFee + sellFee);
        } else {
            feesCollected += (buyFee + sellFee);
        }
    }

    function withdraw() external onlyOwner {
        if (config.treasury() == address(0)) {
            revert ZeroAddress();
        }
        payable(config.treasury()).transfer(feesCollected);
        feesCollected = 0;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Common Errors
error ZeroAddress();
error WithdrawalFailed();
error NoTrailingSlash(string _uri);
error InvalidArgumentsProvided();
error PriceMustBeAboveZero(uint256 _price);
error PermissionDenied();
error InvalidTokenId(uint256 _tokenId);

// NFTing Base Contract
error NotTokenOwnerOrInsufficientAmount();
error NotApprovedMarketplace();
error ZeroAmountTransfer();
error TransactionError();
error InvalidAddressProvided(address _invalidAddress);

// PreAuthorization Contract
error NoAuthorizedOperator();

// Auction Contract
error NotExistingAuction(uint256 _auctionId);
error NotExistingBidder(address _bidder);
error NotEnoughPriceToBid();
error SelfBid();
error ExpiredAuction(uint256 _auctionId);
error RunningAuction(uint256 _auctionId);
error NotAuctionCreatorOrOwner();
error InvalidAmountOfTokens(uint256 _amount);
error AlreadyWithdrawn(uint256 _auctionId, address _bidder);
error NotBidder(uint256 _auctionId, address _bidder);

// Offer Contract
error NotExistingOffer(uint256 _offerId);
error PriceMustBeDifferent(uint256 _price);
error InsufficientETHProvided(uint256 _value);
error InvalidOfferState();

// Marketplace Contract
error NotListed();
error NotEnoughEthProvided(uint256 providedEth, uint256 requiredEth);
error NotTokenOwner();
error NotTokenSeller();
error TokenSeller();
error InvalidBasisProvided(uint256 _newBasis);

// NFTing Single Token Contract
error MaxBatchMintLimitExceeded();
error AlreadyExistentToken();
error NotApprovedOrOwner();
error MaxMintLimitExceeded();

// NFTing Token Manager Contract
error AlreadyRegisteredAddress();

// NFTingSignature
error HashUsed(bytes32 _hash);
error SignatureFailed(address _signatureAddress, address _signer);

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface INFTingConfig {
    function buyFee() external view returns (uint256);

    function sellFee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function maxRoyaltyFee() external view returns (uint256);

    function treasury() external view returns (address);

    function updateFee(uint256 newBuyFee, uint256 newSellFee) external;

    function updateTreasury(address newTreasury) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
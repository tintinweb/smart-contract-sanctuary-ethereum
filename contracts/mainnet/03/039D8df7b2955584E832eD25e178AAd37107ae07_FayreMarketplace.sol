// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IFayreMembershipCard721.sol";
import "./interfaces/IFayreTokenLocker.sol";

contract FayreMarketplace is Ownable {
    /**
        E#3: wrong base amount
        E#4: free offer expired
        E#5: token locker address not found 
        E#6: unable to send to treasury
        E#7: not the owner
        E#8: invalid trade type
        E#9: sale amount not specified
        E#10: sale expiration must be greater than start
        E#12: cannot finalize your sale, cancel?
        E#13: cannot accept your offer
        E#14: salelist expired
        E#15: asset type not supported
        E#16: unable to send to sale owner
        E#21: cannot finalize unexpired auction
    */

    enum AssetType {
        ERC20,
        ERC721,
        ERC1155
    }

    enum TradeType {
        SALE_FIXEDPRICE,
        SALE_ENGLISHAUCTION,
        SALE_DUTCHAUCTION,
        BID
    }

    struct TradeRequest {
        uint256 tokenId;
        uint256 nftAmount;
        uint256 amount;
        uint256 start;
        uint256 expiration;
        uint256 saleId;
        uint256 baseAmount;
        TradeType tradeType;
        AssetType assetType;
        address collectionAddress;
        address owner;
        address tokenAddress;
    }

    struct TokenData {
        uint256 salesId;
        AssetType assetType;
        mapping(uint256 => uint256[]) bidsIds;
    }

    struct TokenLockerFeeData {
        uint256 lockedTokensAmount;
        uint256 fee;
    }

    event PutOnSale(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed saleId);
    event CancelSale(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed saleId);
    event FinalizeSale(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed saleId, address buyer);
    event PlaceBid(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed bidId);
    event CancelBid(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed bidId);
    event AcceptFreeOffer(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed bidId, address nftOwner);
    event ERC20Transfer(address indexed tokenAddress, address indexed from, address indexed to, uint256 amount);
    event ERC721Transfer(address indexed collectionAddress, address indexed from, address indexed to, uint256 tokenId);
    event ERC1155Transfer(address indexed collectionAddress, address indexed from, address indexed to, uint256 tokenId, uint256 amount);

    uint256 public tradeFeePct;
    address public treasuryAddress;
    address[] public membershipCardsAddresses;
    address public tokenLockerAddress;
    mapping(uint256 => TradeRequest) public sales;
    mapping(uint256 => TradeRequest) public bids;
    mapping(address => uint256) public tokenLockersRequiredAmounts;
    TokenLockerFeeData[] public tokenLockerFeesData;
    uint256 public tokenLockerFeesCount;
    mapping(string => uint256) public cardsExpirationDeltaTime;
    mapping(string => uint256) public cardsFee;

    mapping(address => mapping(uint256 => TokenData)) private _tokensData;
    uint256 private _currentSaleId;
    uint256 private _currentBidId;

    function setTradeFee(uint256 newTradeFeePct) external onlyOwner {
        tradeFeePct = newTradeFeePct;
    }

    function setTreasury(address newTreasuryAddress) external onlyOwner {
        treasuryAddress = newTreasuryAddress;
    }

    function addMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                revert("Membership card address already present");

        membershipCardsAddresses.push(membershipCardsAddress);
    }

    function removeMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "Membership card address not found");

        membershipCardsAddresses[indexToDelete] = membershipCardsAddresses[membershipCardsAddresses.length - 1];

        membershipCardsAddresses.pop();
    }

    function setTokenLockerAddress(address newTokenLockerAddress) external onlyOwner {
        tokenLockerAddress = newTokenLockerAddress;
    }

    function addTokenLockerSwapFeeData(uint256 lockedTokensAmount, uint256 fee) external onlyOwner {
        for (uint256 i = 0; i < tokenLockerFeesData.length; i++)
            if (tokenLockerFeesData[i].lockedTokensAmount == lockedTokensAmount)
                revert("Token locker fee data already present");

        tokenLockerFeesData.push(TokenLockerFeeData(lockedTokensAmount, fee));

        tokenLockerFeesCount++;
    }

    function removeTokenLockerSwapFeeData(uint256 lockedTokensAmount) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < tokenLockerFeesData.length; i++)
            if (tokenLockerFeesData[i].lockedTokensAmount == lockedTokensAmount)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "Wrong token locker swap fee data");

        tokenLockerFeesData[indexToDelete] = tokenLockerFeesData[tokenLockerFeesData.length - 1];

        tokenLockerFeesData.pop();

        tokenLockerFeesCount--;
    }

    function setCardFee(string calldata symbol, uint256 newCardFee) external onlyOwner {
        cardsFee[symbol] = newCardFee;
    }

    function setCardExpirationDeltaTime(string calldata symbol, uint256 newCardExpirationDeltaTime) external onlyOwner {
        cardsExpirationDeltaTime[symbol] = newCardExpirationDeltaTime;
    }

    function putOnSale(TradeRequest memory tradeRequest) external { 
        require(tradeRequest.owner == _msgSender(), "E#7");
        require(tradeRequest.assetType == AssetType.ERC721 || tradeRequest.assetType == AssetType.ERC1155, "E#15");

        require(tradeRequest.amount > 0, "E#9");
        require(tradeRequest.expiration > block.timestamp, "E#10");
        require(tradeRequest.tradeType == TradeType.SALE_FIXEDPRICE || tradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION || tradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION, "E#8");
        
        if (tradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION)
            require(tradeRequest.baseAmount > 0 && tradeRequest.baseAmount < tradeRequest.amount, "E#3");

        tradeRequest.start = block.timestamp;

        _tokensData[tradeRequest.collectionAddress][tradeRequest.tokenId].salesId = _currentSaleId;

        sales[_currentSaleId] = tradeRequest;

        emit PutOnSale(tradeRequest.collectionAddress, tradeRequest.tokenId, _currentSaleId);

        _currentSaleId++;
    }

    function cancelSale(uint256 saleId) external {
        require(sales[saleId].owner == _msgSender(), "E#7");

        sales[saleId].expiration = 0;

        emit CancelSale(sales[saleId].collectionAddress, sales[saleId].tokenId, saleId);
    }

    function finalizeSale(uint256 saleId) external {
        TradeRequest storage saleTradeRequest = sales[saleId];

        address buyer = address(0);

        if (saleTradeRequest.tradeType == TradeType.SALE_FIXEDPRICE) {
            require(saleTradeRequest.owner != _msgSender(), "E#12");
            require(saleTradeRequest.expiration > block.timestamp, "E#14");

            saleTradeRequest.expiration = 0;

            buyer = _msgSender();

            _sendAmountToSeller(saleTradeRequest.amount, saleTradeRequest.tokenAddress, saleTradeRequest.owner, buyer);
        } else if (saleTradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION) {
            require(saleTradeRequest.expiration <= block.timestamp, "E#21");

            uint256[] storage bidsIds = _tokensData[saleTradeRequest.collectionAddress][saleTradeRequest.tokenId].bidsIds[saleId];

            uint256 highestBidId = 0;
            uint256 highestBidAmount = 0;

            for (uint256 i = 0; i < bidsIds.length; i++)
                if (bids[bidsIds[i]].amount >= saleTradeRequest.amount)
                    if (bids[bidsIds[i]].amount > highestBidAmount) {
                        highestBidId = bidsIds[i];
                        highestBidAmount = bids[bidsIds[i]].amount;
                    }
                    
            buyer = bids[highestBidId].owner;

            _sendAmountToSeller(highestBidAmount, saleTradeRequest.tokenAddress, saleTradeRequest.owner, buyer);
        } else if (saleTradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION) {
            require(saleTradeRequest.owner != _msgSender(), "E#12");
            require(saleTradeRequest.expiration > block.timestamp, "E#14");

            uint256 amountsDiff = saleTradeRequest.amount - saleTradeRequest.baseAmount;

            uint256 priceDelta = amountsDiff - ((amountsDiff * (block.timestamp - saleTradeRequest.start)) / (saleTradeRequest.expiration - saleTradeRequest.start));

            uint256 currentPrice = saleTradeRequest.baseAmount + priceDelta;
            
            saleTradeRequest.expiration = 0;

            buyer = _msgSender();

            _sendAmountToSeller(currentPrice, saleTradeRequest.tokenAddress, saleTradeRequest.owner, buyer);
        }

        _transferAsset(saleTradeRequest.assetType, saleTradeRequest.collectionAddress, saleTradeRequest.owner, buyer, saleTradeRequest.tokenId, saleTradeRequest.nftAmount, "");

        emit FinalizeSale(saleTradeRequest.collectionAddress, saleTradeRequest.tokenId, saleId, buyer);
    }

    function placeBid(TradeRequest memory tradeRequest) external {
        require(tradeRequest.owner == _msgSender(), "E#7");
        require(tradeRequest.assetType == AssetType.ERC721 || tradeRequest.assetType == AssetType.ERC1155, "E#15");

        require(tradeRequest.amount > 0, "E#9");
        require(tradeRequest.tradeType == TradeType.BID, "E#8");

        tradeRequest.start = block.timestamp;

        bids[_currentBidId] = tradeRequest;

        _tokensData[bids[_currentBidId].collectionAddress][bids[_currentBidId].tokenId].bidsIds[tradeRequest.saleId].push(_currentBidId);

        emit PlaceBid(tradeRequest.collectionAddress, tradeRequest.tokenId, _currentBidId);

        _currentBidId++;
    }

    function cancelBid(uint256 bidId) external {
        TradeRequest storage bidTradeRequest = bids[bidId];

        require(bidTradeRequest.owner == _msgSender(), "E#7");

        bidTradeRequest.start = 0;
        bidTradeRequest.expiration = 0;

        uint256[] storage bidsIds = _tokensData[bidTradeRequest.collectionAddress][bidTradeRequest.tokenId].bidsIds[bidTradeRequest.saleId];

        uint256 indexToDelete = 0;

        for (uint256 i = 0; i < bidsIds.length; i++)
            if (bidsIds[i] == bidId)
                indexToDelete = i;

        bidsIds[indexToDelete] = bidsIds[bidsIds.length - 1];

        bidsIds.pop();

        emit CancelBid(bidTradeRequest.collectionAddress, bidTradeRequest.tokenId, bidId);
    }

    function acceptFreeOffer(uint256 bidId) external {
        TradeRequest storage bidTradeRequest = bids[bidId];

        require(bidTradeRequest.owner != _msgSender(), "E#13");
        require(bidTradeRequest.start > 0 && bidTradeRequest.expiration > block.timestamp, "E#4");

        bidTradeRequest.start = 0;
        bidTradeRequest.expiration = 0;

        _sendAmountToSeller(bidTradeRequest.amount, bidTradeRequest.tokenAddress, _msgSender(), bidTradeRequest.owner);

        _transferAsset(bidTradeRequest.assetType, bidTradeRequest.collectionAddress, _msgSender(), bidTradeRequest.owner, bidTradeRequest.tokenId, bidTradeRequest.nftAmount, "");
    
        emit AcceptFreeOffer(bidTradeRequest.collectionAddress, bidTradeRequest.tokenId, bidId, _msgSender());
    }

    function _sendAmountToSeller(uint256 amount, address tokenAddress, address seller, address buyer) private {
        uint256 saleFee = (amount * tradeFeePct) / 10 ** 20;

        uint256 ownerRemainingSaleFee = 0;

        ownerRemainingSaleFee = _processFee(seller, saleFee * 10 ** (18 - IERC20Extended(tokenAddress).decimals()));

        _transferAsset(AssetType.ERC20, tokenAddress, buyer, seller, 0, amount - ownerRemainingSaleFee, "E#16");

        if (ownerRemainingSaleFee > 0)
            _transferAsset(AssetType.ERC20, tokenAddress, buyer, treasuryAddress, 0, ownerRemainingSaleFee, "E#6");
    }

    function _transferAsset(AssetType assetType, address contractAddress, address from, address to, uint256 tokenId, uint256 amount, string memory errorCode) private {
        if (assetType == AssetType.ERC20) {
            if (!IERC20Extended(contractAddress).transferFrom(from, to, amount))
                revert(errorCode);

            emit ERC20Transfer(contractAddress, from, to, amount);
        }
        else if (assetType == AssetType.ERC721) {
            IERC721(contractAddress).safeTransferFrom(from, to, tokenId);

            emit ERC721Transfer(contractAddress, from, to, tokenId);
        } 
        else if (assetType == AssetType.ERC1155) {
            IERC1155(contractAddress).safeTransferFrom(from, to, tokenId, amount, '');

            emit ERC1155Transfer(contractAddress, from, to, tokenId, amount);
        }      
    }

    function _processFee(address owner, uint256 fee) private returns(uint256) { 
        //Process locked tokens
        if (tokenLockerAddress != address(0)) {
            uint256 minLockDuration = IFayreTokenLocker(tokenLockerAddress).minLockDuration();

            IFayreTokenLocker.LockData memory lockData = IFayreTokenLocker(tokenLockerAddress).usersLockData(owner);

            if (lockData.amount > 0)
                if (lockData.start + minLockDuration <= lockData.expiration && lockData.start + minLockDuration >= block.timestamp)
                    for (uint256 j = 0; j < tokenLockerFeesData.length; j++)
                        if (lockData.amount >= tokenLockerFeesData[j].lockedTokensAmount)
                            if (fee > tokenLockerFeesData[j].fee)
                                fee = tokenLockerFeesData[j].fee;
        }

        //Process on-chain membership cards
        if (fee > 0)
            for (uint256 i = 0; i < membershipCardsAddresses.length; i++) {
                uint256 membershipCardsAmount = IFayreMembershipCard721(membershipCardsAddresses[i]).balanceOf(owner);

                if (membershipCardsAmount <= 0)
                    continue;

                string memory membershipCardSymbol = IFayreMembershipCard721(membershipCardsAddresses[i]).symbol();

                if (cardsExpirationDeltaTime[membershipCardSymbol] > 0) {
                    for (uint256 j = 0; j < membershipCardsAmount; j++) {
                        uint256 currentTokenId = IFayreMembershipCard721(membershipCardsAddresses[i]).tokenOfOwnerByIndex(owner, j);

                        if (IFayreMembershipCard721(membershipCardsAddresses[i]).membershipCardMintTimestamp(currentTokenId) + cardsExpirationDeltaTime[membershipCardSymbol] >= block.timestamp) {
                            uint256 cardFee = cardsFee[membershipCardSymbol];

                            if (fee > cardFee)
                                fee = cardFee;
                        }
                    }
                } else {
                    uint256 cardFee = cardsFee[membershipCardSymbol];

                    if (fee > cardFee)
                        fee = cardFee;
                }
            }

        return fee;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns(uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

interface IFayreMembershipCard721 is IERC721Enumerable {
    function symbol() external view returns(string memory);

    function membershipCardMintTimestamp(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFayreTokenLocker {
    struct LockData {
        uint256 lockId;
        address owner;
        uint256 amount;
        uint256 start;
        uint256 expiration;
    }

    function usersLockData(address owner) external returns(LockData calldata);

    function minLockDuration() external returns(uint256);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}
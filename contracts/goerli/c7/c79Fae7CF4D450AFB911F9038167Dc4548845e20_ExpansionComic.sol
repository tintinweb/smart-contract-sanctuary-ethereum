// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ERC2981.sol";
import "../interfaces/IExpansionComic.sol";

/**
 * @title Expansion Comic
 * @custom:developer Paul Renshaw <[email protected]>
 */
contract ExpansionComic is ERC2981, ERC721, Ownable, Pausable, IExpansionComic {
    /// @dev base for token metadata URIs
    string public baseURI;

    /// @dev uri for contract-level metadata
    string public contractURI;

    /// @dev mapping from an issue id to issue data
    mapping(uint16 => Issue) public issues;

    /// @dev mapping from an issue id and page id to page data
    mapping(uint16 => mapping(uint16 => Page)) public issuePages;

    /// @dev mapping from issue id and page id to royalty details
    mapping(uint16 => mapping(uint16 => RoyaltyInfo)) issuePageRoyalties;

    /// @dev used to calculate the issue counterpart of a token id
    uint256 constant ISSUE_MULTIPLIER = 1_000_000;

    /// @dev used to calculate the page counterpart of a token id
    uint256 constant PAGE_MULTIPLIER = 1_000;

    /// @dev the maximum possible number of copies of a page
    uint256 constant MAX_COPIES = 999;

    /// @dev the maximum possible number of pages of an issue
    uint256 constant MAX_PAGES = 999;

    /// @dev the number of issues
    uint16 public issueCount;

    /// @dev the number of tokens minted
    uint256 public totalSupply;

    // * MODIFIERS * //

    modifier onlyExistingIssue(uint16 issueId) {
        if (_issueDoesNotExist(issueId)) revert IssueDoesNotExist();
        _;
    }

    modifier onlyExistingPage(uint16 issueId, uint16 pageId) {
        if (_issuePageDoesNotExist(issueId, pageId)) revert PageDoesNotExist();
        _;
    }

    modifier onlyFrontCoverToken(uint256 tokenId) {
        if (tokenPageId(tokenId) != 0) revert InvalidTokenId();
        _;
    }

    // * CONSTRUCTOR * //

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_
    ) ERC721(name_, symbol_) {
        updateBaseURI(baseURI_);
        updateContractURI(contractURI_);
        _setDefaultRoyalty(msg.sender, 1000);
    }

    // * PAYABLE * //

    /// @inheritdoc IExpansionComic
    function claimPageCopy(
        uint16 issueId,
        uint16 pageId,
        uint16 copyNumber
    ) public payable {
        uint256 subscriptionTokenId = getTokenId(issueId, 0, copyNumber);
        if (!_exists(subscriptionTokenId)) revert InvalidSubscription();
        if (msg.sender != ownerOf(subscriptionTokenId))
            revert InvalidSubscription();
        if (_issuePageDoesNotExist(issueId, pageId)) revert PageDoesNotExist();

        uint256 tokenId = getTokenId(issueId, pageId, copyNumber);
        if (_exists(tokenId)) revert PageAlreadyClaimed();

        totalSupply++;
        _safeMint(msg.sender, tokenId);
        emit PageCopyClaimed(issueId, pageId, copyNumber, msg.sender);
    }

    /// @inheritdoc IExpansionComic
    function purchasePageCopy(uint16 issueId, uint16 pageId)
        public
        payable
        onlyExistingPage(issueId, pageId)
    {
        if (pageId == 0) revert InvalidPageId();
        if (!issuePageReleased(issueId, pageId)) revert PageNotForSale();
        if (issuePageSoldOut(issueId, pageId)) revert PageSoldOut();

        if (msg.value < issuePages[issueId][pageId].price)
            revert NotEnoughEtherSent();

        address tokenGateAddress = issuePages[issueId][pageId].tokenGateAddress;
        if (tokenGateAddress != address(0)) {
            IERC721 tokenGate = _getTokenGateContract(tokenGateAddress);
            if (tokenGate.balanceOf(msg.sender) == 0)
                revert TokenGateNFTNotOwned();
        }

        uint256 tokenId = _nextTokenId(issueId, pageId);
        issuePages[issueId][pageId].copyCount++;
        totalSupply++;
        _safeMint(msg.sender, tokenId);
        emit PageCopyPurchased(
            issueId,
            pageId,
            issuePages[issueId][pageId].copyCount,
            msg.sender
        );
    }

    /// @inheritdoc IExpansionComic
    function subscribeToIssue(uint16 issueId)
        public
        payable
        onlyExistingIssue(issueId)
    {
        if (msg.value < issues[issueId].price) revert NotEnoughEtherSent();

        address tokenGateAddress = issuePages[issueId][0].tokenGateAddress;
        if (
            tokenGateAddress != address(0) &&
            _getTokenGateContract(tokenGateAddress).balanceOf(msg.sender) == 0
        ) revert TokenGateNFTNotOwned();

        if (issueSubscriptionsSoldOut(issueId))
            revert IssueSubscriptionsSoldOut();
        if (!issuePageReleased(issueId, 0)) revert SubscriptionNotAvailable();

        uint256 tokenId = _nextSubscriberTokenId(issueId);
        issues[issueId].subscribers++;
        totalSupply++;
        _safeMint(msg.sender, tokenId);
        emit IssueSubscriptionPurchased(
            issueId,
            issues[issueId].subscribers,
            msg.sender
        );
    }

    // * PUBLIC * //

    /// @inheritdoc IExpansionComic
    function getTokenId(
        uint16 issueId,
        uint16 pageId,
        uint16 copyNumber
    ) public pure returns (uint256 tokenId) {
        tokenId =
            _tokenIssueCounterpart(issueId) +
            _tokenPageCounterpart(pageId) +
            copyNumber;
    }

    /// @inheritdoc IExpansionComic
    function issueReleased(uint16 issueId) public view returns (bool) {
        return issuePageReleased(issueId, 0);
    }

    /// @inheritdoc IExpansionComic
    function issuePageReleased(uint16 issueId, uint16 pageId)
        public
        view
        onlyExistingPage(issueId, pageId)
        returns (bool)
    {
        return block.timestamp >= issuePages[issueId][pageId].releaseDate;
    }

    /// @inheritdoc IExpansionComic
    function issuePageSaleEnds(uint16 issueId, uint16 pageId)
        public
        view
        returns (uint256)
    {
        return
            issuePages[issueId][pageId].releaseDate +
            issuePages[issueId][pageId].saleDuration;
    }

    /// @inheritdoc IExpansionComic
    function issuePageSoldOut(uint16 issueId, uint16 pageId)
        public
        view
        returns (bool)
    {
        return
            block.timestamp > issuePageSaleEnds(issueId, pageId) ||
            issuePages[issueId][pageId].copyCount ==
            issuePages[issueId][pageId].maxSupply;
    }

    /// @inheritdoc IExpansionComic
    function issueSubscriptionsSoldOut(uint16 issueId)
        public
        view
        returns (bool)
    {
        return issues[issueId].subscribers == issues[issueId].maxSubscribers;
    }

    /// @inheritdoc IExpansionComic
    function ownerOfCopy(
        uint16 issueId,
        uint16 pageId,
        uint16 copyNumber
    ) public view returns (address) {
        return ownerOf(getTokenId(issueId, pageId, copyNumber));
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override
        returns (address, uint256)
    {
        uint16 issueId = tokenIssueId(tokenId);
        uint16 pageId = tokenPageId(tokenId);
        RoyaltyInfo memory royalty = issuePageRoyalties[issueId][pageId];
        if (royalty.receiver == address(0))
            royalty = issuePageRoyalties[issueId][0];
        if (royalty.receiver == address(0)) royalty = _defaultRoyaltyInfo;

        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) /
            _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IExpansionComic).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IExpansionComic
    function tokenPageCopyNumber(uint256 tokenId)
        public
        view
        returns (uint16 copyNumber)
    {
        uint16 issueId = tokenIssueId(tokenId);
        uint16 pageId = tokenPageId(tokenId);
        copyNumber = uint16(
            tokenId -
                _tokenIssueCounterpart(issueId) -
                _tokenPageCounterpart(pageId)
        );

        if (copyNumber == 0) revert InvalidTokenId();

        if (pageId == 0) {
            if (copyNumber > issues[issueId].maxSubscribers) {
                revert InvalidTokenId();
            }
        }

        if (copyNumber > issuePages[issueId][pageId].copyCount) {
            revert InvalidTokenId();
        }
    }

    /// @inheritdoc IExpansionComic
    function tokenIssueId(uint256 tokenId)
        public
        view
        returns (uint16 issueId)
    {
        issueId = uint16(tokenId / ISSUE_MULTIPLIER);
        if (issueId == 0 || issueId > issueCount) revert InvalidTokenId();
    }

    /// @inheritdoc IExpansionComic
    function tokenPageId(uint256 tokenId) public view returns (uint16 pageId) {
        uint16 issueId = tokenIssueId(tokenId);
        pageId = uint16(
            (tokenId - _tokenIssueCounterpart(issueId)) / PAGE_MULTIPLIER
        );
        if (pageId > issues[issueId].pageCount) revert InvalidTokenId();
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert InvalidTokenId();

        uint16 issueId = tokenIssueId(tokenId);
        uint16 pageId = tokenPageId(tokenId);
        uint16 copyNumber = tokenPageCopyNumber(tokenId);
        string memory pageURI = issuePages[issueId][pageId].uri;

        if (bytes(pageURI).length > 0)
            return
                string(
                    abi.encodePacked(
                        pageURI,
                        "/",
                        Strings.toString(copyNumber),
                        ".json"
                    )
                );
        
        if (bytes(baseURI).length > 0) {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        Strings.toString(issueId),
                        "-",
                        Strings.toString(pageId),
                        "-",
                        Strings.toString(copyNumber),
                        ".json"
                    )
                );
        }

        return "";
    }

    // * OWNER * //

    /// @inheritdoc IExpansionComic
    function addIssue(
        uint16 maxSubscribers,
        uint64 price,
        uint64 releaseDate,
        address tokenGateAddress,
        string calldata frontCoverURI
    ) public onlyOwner {
        if (maxSubscribers > MAX_COPIES) revert MaxSubscribersExceeded();
        issueCount++;
        uint16 issueId = issueCount;

        issues[issueId].maxSubscribers = maxSubscribers;
        issues[issueId].price = price;

        issuePages[issueId][0].copyCount = maxSubscribers;
        issuePages[issueId][0].maxSupply = maxSubscribers;
        issuePages[issueId][0].releaseDate = releaseDate;
        issuePages[issueId][0].tokenGateAddress = tokenGateAddress;
        issuePages[issueId][0].uri = frontCoverURI;

        emit IssueAdded(issueId);
    }

    /// @inheritdoc IExpansionComic
    function addPage(
        uint16 issueId,
        uint16 maxSupply,
        uint64 price,
        uint64 releaseDate,
        uint64 saleDuration,
        address tokenGateAddress,
        string calldata uri
    ) public onlyOwner onlyExistingIssue(issueId) {
        if (maxSupply > MAX_COPIES) revert MaxCopiesExceeded();

        uint16 minCopies = issues[issueId].maxSubscribers;
        if (maxSupply < minCopies) revert InvalidMaxSupply();

        uint16 pageId = issues[issueId].pageCount + 1;
        if (pageId > MAX_PAGES) revert MaxPagesExceeded();
        issues[issueId].pageCount++;

        if (releaseDate < issuePages[issueId][0].releaseDate)
            revert InvalidReleaseDate();

        issuePages[issueId][pageId] = Page({
            copyCount: minCopies,
            maxSupply: maxSupply,
            price: price,
            releaseDate: releaseDate,
            saleDuration: saleDuration,
            tokenGateAddress: tokenGateAddress,
            uri: uri
        });

        emit PageAdded(issueId, pageId);
    }

    /// @inheritdoc IExpansionComic
    function giftIssueSubscription(uint16 issueId, address recipient)
        public
        onlyOwner
        onlyExistingIssue(issueId)
    {
        if (issueSubscriptionsSoldOut(issueId))
            revert IssueSubscriptionsSoldOut();

        uint256 tokenId = _nextSubscriberTokenId(issueId);
        issues[issueId].subscribers++;
        totalSupply++;
        _safeMint(recipient, tokenId);
        emit IssueSubscriptionGifted(
            issueId,
            issues[issueId].subscribers,
            recipient
        );
    }

    /// @inheritdoc IExpansionComic
    function giftPageCopy(
        uint16 issueId,
        uint16 pageId,
        address recipient
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        if (pageId == 0) revert InvalidPageId();
        if (issuePageSoldOut(issueId, pageId)) revert PageSoldOut();

        uint256 tokenId = _nextTokenId(issueId, pageId);
        issuePages[issueId][pageId].copyCount++;
        totalSupply++;
        _safeMint(recipient, tokenId);
        emit PageCopyGifted(
            issueId,
            pageId,
            issuePages[issueId][pageId].copyCount,
            recipient
        );
    }

    /// @inheritdoc IExpansionComic
    function updateBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
        emit BaseURIUpdated(uri);
    }

    /// @inheritdoc IExpansionComic
    function updateContractURI(string memory uri) public onlyOwner {
        contractURI = uri;
        emit ContractURIUpdated(uri);
    }

    /// @inheritdoc IExpansionComic
    function updateDefaultRoyaltyInfo(address receiver, uint96 royaltyBps)
        public
        onlyOwner
    {
        if (receiver == address(0)) {
            _deleteDefaultRoyalty();
            emit DefaultRoyaltyInfoUpdated(address(0), 0);
        } else {
            _setDefaultRoyalty(receiver, royaltyBps);
            emit DefaultRoyaltyInfoUpdated(receiver, royaltyBps);
        }
    }

    /// @inheritdoc IExpansionComic
    function updateIssuePrice(uint16 issueId, uint64 price)
        public
        onlyOwner
        onlyExistingIssue(issueId)
    {
        issues[issueId].price = price;
        emit IssuePriceUpdated(issueId, price);
    }

    /// @inheritdoc IExpansionComic
    function updateIssueReleaseDate(uint16 issueId, uint64 releaseDate)
        public
        onlyOwner
        onlyExistingIssue(issueId)
    {
        if (issueReleased(issueId)) revert AlreadyReleased();
        if (releaseDate < block.timestamp) revert InvalidReleaseDate();
        issuePages[issueId][0].releaseDate = releaseDate;
        emit IssueReleaseDateUpdated(issueId, releaseDate);
    }

    /// @inheritdoc IExpansionComic
    function updatePageMaxSupply(
        uint16 issueId,
        uint16 pageId,
        uint16 maxSupply
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        if (maxSupply < issuePages[issueId][pageId].copyCount)
            revert InvalidValue();
        if (maxSupply > MAX_COPIES) revert MaxCopiesExceeded();
        issuePages[issueId][pageId].maxSupply = maxSupply;
        emit PageMaxSupplyUpdated(issueId, pageId, maxSupply);
    }

    /// @inheritdoc IExpansionComic
    function updatePagePrice(
        uint16 issueId,
        uint16 pageId,
        uint64 price
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        if (pageId == 0) revert InvalidPageId();
        issuePages[issueId][pageId].price = price;
        emit PagePriceUpdated(issueId, pageId, price);
    }

    /// @inheritdoc IExpansionComic
    function updatePageReleaseDate(
        uint16 issueId,
        uint16 pageId,
        uint64 releaseDate
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        if (pageId == 0) revert InvalidPageId();
        if (issuePageReleased(issueId, pageId)) revert AlreadyReleased();
        if (releaseDate < block.timestamp) revert InvalidReleaseDate();
        if (releaseDate < issuePages[issueId][0].releaseDate)
            revert InvalidReleaseDate();
        issuePages[issueId][pageId].releaseDate = releaseDate;
        emit PageReleaseDateUpdated(issueId, pageId, releaseDate);
    }

    /// @inheritdoc IExpansionComic
    function updatePageRoyaltyInfo(
        uint16 issueId,
        uint16 pageId,
        address receiver,
        uint96 royaltyBps
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        if (royaltyBps > _feeDenominator()) revert RoyaltyBpsTooHigh();
        if (receiver != address(0)) {
            issuePageRoyalties[issueId][pageId] = RoyaltyInfo(
                receiver,
                royaltyBps
            );
            emit PageRoyaltyInfoUpdated(issueId, pageId, receiver, royaltyBps);
        } else {
            delete issuePageRoyalties[issueId][pageId];
            emit PageRoyaltyInfoUpdated(issueId, pageId, address(0), 0);
        }
    }

    /// @inheritdoc IExpansionComic
    function updatePageSaleDuration(
        uint16 issueId,
        uint16 pageId,
        uint64 saleDuration
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        if (pageId == 0) revert InvalidPageId();
        if (
            issuePages[issueId][pageId].copyCount ==
            issuePages[issueId][pageId].maxSupply
        ) revert PageSoldOut();
        issuePages[issueId][pageId].saleDuration = saleDuration;
        emit PageSaleDurationUpdated(issueId, pageId, saleDuration);
    }

    /// @inheritdoc IExpansionComic
    function updatePageTokenGate(
        uint16 issueId,
        uint16 pageId,
        address tokenGateAddress
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        issuePages[issueId][pageId].tokenGateAddress = tokenGateAddress;
        emit PageTokenGateUpdated(issueId, pageId, tokenGateAddress);
    }

    /// @inheritdoc IExpansionComic
    function updatePageURI(
        uint16 issueId,
        uint16 pageId,
        string calldata uri
    ) public onlyOwner onlyExistingPage(issueId, pageId) {
        issuePages[issueId][pageId].uri = uri;
        emit PageURIUpdated(issueId, pageId, uri);
    }

    /// @inheritdoc IExpansionComic
    function pause() public onlyOwner {
        _pause();
    }

    /// @inheritdoc IExpansionComic
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @inheritdoc IExpansionComic
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // * INTERNAL * //

    /**
     * @dev gets the NFT contract at an address
     */
    function _getTokenGateContract(address contractAddress)
        internal
        pure
        returns (IERC721)
    {
        return IERC721(contractAddress);
    }

    /**
     * @dev calculates whether an issue exists or for an id
     */
    function _issueDoesNotExist(uint16 issueId) internal view returns (bool) {
        return issueId == 0 || issueId > issueCount;
    }

    /**
     * @dev calculates whether a page exists or for an issue id and page id
     */
    function _issuePageDoesNotExist(uint16 issueId, uint16 pageId)
        internal
        view
        returns (bool)
    {
        return
            _issueDoesNotExist(issueId) || pageId > issues[issueId].pageCount;
    }

    /**
     * @dev calculates the next token id to mint for an issue subscription / front cover page
     */
    function _nextSubscriberTokenId(uint16 issueId)
        internal
        view
        returns (uint256)
    {
        unchecked {
            return
                _tokenIssueCounterpart(issueId) +
                issues[issueId].subscribers +
                1;
        }
    }

    /**
     * @dev calculates the next token id to mint a copy of an issue page
     */
    function _nextTokenId(uint16 issueId, uint16 pageId)
        internal
        view
        returns (uint256)
    {
        return
            getTokenId(
                issueId,
                pageId,
                issuePages[issueId][pageId].copyCount + 1
            );
    }

    /**
     * @dev calculates the value used to represent an issue as part of a token id
     */
    function _tokenIssueCounterpart(uint16 issueId)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            return issueId * ISSUE_MULTIPLIER;
        }
    }

    /**
     * @dev calculates the value used to represent a page as part of a token id
     */
    function _tokenPageCounterpart(uint16 pageId)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            return pageId * PAGE_MULTIPLIER;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IExpansionComic {
    error AlreadyReleased();
    error InvalidClaim();
    error InvalidMaxSupply();
    error InvalidPageId();
    error InvalidReceiver();
    error InvalidReleaseDate();
    error InvalidSubscription();
    error InvalidTokenId();
    error InvalidValue();
    error IssueDoesNotExist();
    error IssueSubscriptionsSoldOut();
    error MaxCopiesExceeded();
    error MaxPagesExceeded();
    error MaxSubscribersExceeded();
    error NoMoreCopiesAvailable();
    error NotEnoughEtherSent();
    error NotTheTokenOwner();
    error PageAlreadyClaimed();
    error PageDoesNotExist();
    error PageNotForSale();
    error PageSoldOut();
    error RoyaltyBpsTooHigh();
    error SubscriptionNotAvailable();
    error TokenGateNFTNotOwned();

    event BaseURIUpdated(string uri);
    event ContractURIUpdated(string uri);
    event DefaultRoyaltyInfoUpdated(address receiver, uint96 royaltyBps);

    event IssueAdded(uint16 indexed issueId);
    event IssuePriceUpdated(uint16 indexed issueId, uint64 price);
    event IssueReleaseDateUpdated(uint16 indexed issueId, uint64 releaseDate);
    event IssueSubscriptionGifted(
        uint16 indexed issueId,
        uint16 indexed subscriberNumber,
        address indexed subscriber
    );
    event IssueSubscriptionPurchased(
        uint16 indexed issueId,
        uint16 indexed subscriberNumber,
        address indexed subscriber
    );

    event PageAdded(uint16 indexed issueId, uint16 indexed pageId);
    event PageCopyClaimed(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint16 copyNumber,
        address indexed subscriber
    );
    event PageCopyGifted(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint16 copyNumber,
        address indexed recipient
    );
    event PageCopyPurchased(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint16 copyNumber,
        address indexed buyer
    );
    event PageMaxSupplyUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint16 supply
    );
    event PagePriceUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint64 price
    );
    event PageReleaseDateUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint64 releaseDate
    );
    event PageRoyaltyInfoUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        address indexed receiver,
        uint96 royaltyBps
    );
    event PageSaleDurationUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        uint64 saleDuration
    );
    event PageTokenGateUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        address indexed tokenGateAddress
    );
    event PageURIUpdated(
        uint16 indexed issueId,
        uint16 indexed pageId,
        string uri
    );

    struct Issue {
        uint16 maxSubscribers;
        uint16 pageCount;
        uint64 price;
        uint16 subscribers;
    }

    struct Page {
        uint16 copyCount;
        uint16 maxSupply;
        uint64 price;
        uint64 releaseDate;
        uint64 saleDuration;
        address tokenGateAddress;
        string uri;
    }

    /**
     * @notice Claim a Copy of a Page
     * @dev allows an issue front cover token holder to claim a copy of subsequent pages matching the front cover copy number
     * @param issueId the id of the issue that the claimer owns a subscription of
     * @param pageId the id of the page to claim which belongs to the same issue as the front cover
     * @param copyNumber the copy numbner to claim
     *
     * Requirements:
     *
     * - the sender must own the corresponding front cover from the issue
     * - the copy number must match the the front cover copy number owned
     *
     * Emits a {PageCopyClaimed} event.
     */
    function claimPageCopy(
        uint16 issueId,
        uint16 pageId,
        uint16 copyNumber
    ) external payable;

    /**
     * @notice Purchase a Copy of a Page
     * @dev allows a token gate NFT holder (if set) to mint a copy of a released page
     * @param issueId the id of the issue the page belongs to
     * @param pageId the id of the page to mint
     *
     * Emits a {PageCopyPurchased} event.
     */
    function purchasePageCopy(uint16 issueId, uint16 pageId) external payable;

    /**
     * @notice Subscribe to an Issue
     * @dev allows a token gate NFT holder (if set) to mint a copy of the front cover of a released issue
     * @param issueId the id of the issue to subscribe to
     *
     * Emits an {IssueSubscriptionPurchased} event.
     */
    function subscribeToIssue(uint16 issueId) external payable;

    /**
     * @notice Get Token ID
     * @dev gets the token id corresponding to a copy of an issue page
     * @param issueId the id of the issue
     * @param pageId the id of the page
     * @param copyNumber the number of the copy of the issue page
     * @return tokenId the resulting token id
     */
    function getTokenId(
        uint16 issueId,
        uint16 pageId,
        uint16 copyNumber
    ) external view returns (uint256 tokenId);

    /**
     * @notice Issue Released?
     * @dev checks if an issue is available to subscribe to based on its release date
     * @param issueId the id of the issue
     * @return bool has the issue been released
     */
    function issueReleased(uint16 issueId) external view returns (bool);

    /**
     * @notice Issue Page Released?
     * @dev checks if an issue page is available to mint based on its release date
     * @param issueId the id of the issue the page belngs to
     * @param pageId the id of the page to check
     * @return bool has the page been released
     */
    function issuePageReleased(uint16 issueId, uint16 pageId)
        external
        view
        returns (bool);

    /**
     * @notice Issue Page Sale Ends
     * @dev calculates the time at which iisue page minting will end based on release date and sale duration
     * @param issueId the id of the issue the page belngs to
     * @param pageId the id of the page to check
     * @return uint256 the time in seconds at which minting will end
     */
    function issuePageSaleEnds(uint16 issueId, uint16 pageId)
        external
        view
        returns (uint256);

    /**
     * @notice Issue Page Sold Out?
     * @dev calculates if an issue page has sold out based on supply and the sale end date
     * @param issueId the id of the issue the page belongs to
     * @param pageId the id of the page to check
     * @return bool has the page sold out
     */
    function issuePageSoldOut(uint16 issueId, uint16 pageId)
        external
        view
        returns (bool);

    /**
     * @notice Issue Subscriptions Sold Out?
     * @dev check if all available subscriptions of an issue have been minted
     * @param issueId the id of the issue to check
     * @return bool have the issue subscriptions sold out
     */
    function issueSubscriptionsSoldOut(uint16 issueId)
        external
        view
        returns (bool);

    /**
     * @notice Get Token Owner of Issue, Page, CopyNumber
     * @dev helper method to get the owner of a token from issue id, page id, and copy number
     * @param issueId id of the issue
     * @param pageId id of the issue page
     * @param copyNumber number of the page copy
     * @return address the address of the token owner
     */
    function ownerOfCopy(
        uint16 issueId,
        uint16 pageId,
        uint16 copyNumber
    ) external view returns (address);

    /**
     * @notice Token Copy Number
     * @dev calculates the copy number of an issue page from the tokenId
     * @param tokenId the id of the token for an issue page copy
     * @return copyNumber the number of the copy the token corresponds to
     */
    function tokenPageCopyNumber(uint256 tokenId)
        external
        view
        returns (uint16 copyNumber);

    /**
     * @notice Token Issue ID
     * @dev calculates the issue id of an issue page copy from the tokenId
     * @param tokenId the id of the token to check
     * @return issueId the id of the issue the token corresponds to
     */
    function tokenIssueId(uint256 tokenId)
        external
        view
        returns (uint16 issueId);

    /**
     * @notice Token Page ID
     * @dev calculates the page id of an issue page copy from the tokenId
     * @param tokenId the id of the token to check
     * @return pageId the id of the page the token corresponds to
     */
    function tokenPageId(uint256 tokenId) external view returns (uint16 pageId);

    /**
     * @notice Add Issue
     * @dev allows the contract owner to add a new issue
     * @param maxSubscribers the maximum number of subscriptions / front covers available to mint
     * @param price the price of a subscription to the issue
     * @param releaseDate the date from which subscriptions will be available to mint
     * @param tokenGateAddress the address of an external contract used to token gate subscriptions
     * @param frontCoverURI the metadata uri to use for front cover tokens for the issue
     *
     * Emits an {IssueAdded} event.
     */
    function addIssue(
        uint16 maxSubscribers,
        uint64 price,
        uint64 releaseDate,
        address tokenGateAddress,
        string calldata frontCoverURI
    ) external;

    /**
     * @notice Add Page
     * @dev allows the contract owner to add a new page to an issue
     * @param issueId the id of the issue the page will belong to
     * @param maxSupply the number of copies of a page available to mint
     * @param price the price of a subscription to the issue
     * @param releaseDate the date from which subscriptions will be available to mint
     * @param saleDuration the duration of time the page will be available to mint after release
     * @param tokenGateAddress the address of an external contract used to token gate page minting
     * @param uri the metadata uri to use for tokens of the page copies
     *
     * Emits a {PageAdded} event.
     */
    function addPage(
        uint16 issueId,
        uint16 maxSupply,
        uint64 price,
        uint64 releaseDate,
        uint64 saleDuration,
        address tokenGateAddress,
        string calldata uri
    ) external;

    /**
     * @notice Gift Issue Subscription
     * @dev allows the owner to airdrop an issue subscription/front cover
     * 
     * Emits an {IssueSubscriptionGifted} event.
     */
    function giftIssueSubscription(uint16 issueId, address recipient) external;

    /**
     * @notice Gift Page Copy
     * @dev allows the owner to airdrop a copy of a page
     * 
     * Emits an {PageCopyGifted} event.
     */
    function giftPageCopy(uint16 issueId, uint16 pageId, address recipient) external;

    /**
     * @notice Update Base URI
     * @dev allows the contract owner to update the base of the uri used for token metadata when a specific uri has not been set for a page
     * @param uri the base of token metadata URIs
     *
     * Emits a {BaseURIUpdated} event.
     */
    function updateBaseURI(string memory uri) external;

    /**
     * Update Contract URI
     * @dev allows the contract owner to update the uri of contract-level metadata
     * @param uri the uri for contract-level metadata
     *
     * Emits a {ContractURIUpdated} event.
     */
    function updateContractURI(string memory uri) external;

    /**
     * Update Default Royalty Info
     * @dev allows the contract owner to update the default royalty receiver and percentage for secondary token sales
     *
     * Emits a {DefaultRoyaltyInfoUpdated} event.
     */
    function updateDefaultRoyaltyInfo(address receiver, uint96 royaltyBps)
        external;

    /**
     * @notice Update Issue Price
     * @dev allows the contract owner to update the price to subscribe to an issue
     *
     * Emits an {IssuePriceUpdated} event.
     */
    function updateIssuePrice(uint16 issueId, uint64 price) external;

    /**
     * @notice Update Issue Release Date
     * @dev allows the contract owner to update the time at which it will be possible to subscribe to an issue
     *
     * Requirements:
     *
     * - `releaseDate` must not be before the current block time
     *
     * Emits an {IssueReleaseDateUpdated} event.
     */
    function updateIssueReleaseDate(uint16 issueId, uint64 releaseDate)
        external;

    /**
     * @notice Update Page Max Supply
     * @dev allows the contract owner to update the maximum number of page copies available to mint
     *
     * Requirements:
     *
     * - `maxSupply` must not be less than the number of page copies already minted
     *
     * Emits a {PageMaxSupplyUpdated} event.
     */
    function updatePageMaxSupply(
        uint16 issueId,
        uint16 pageId,
        uint16 maxSupply
    ) external;

    /**
     * @notice Update Page Price
     * @dev allows the contract owner to update the price to mint page copies
     *
     * Requirements:
     *
     * - `pageId` must not be 0 as this is the issue front cover page id which uses the issue price
     *
     * Emits a {PagePriceUpdated} event.
     */
    function updatePagePrice(
        uint16 issueId,
        uint16 pageId,
        uint64 price
    ) external;

    /**
     * @notice Update Page Release Date
     * @dev allows the contract owner to update the time at which it will be possible to mint page copies
     *
     * Requirements:
     *
     * - `releaseDate` must not be before the current block time
     * - `releaseDate` must not be before the release date of the issue the page belongs to
     *
     * Emits a {PageReleaseDateUpdated} event.
     */
    function updatePageReleaseDate(
        uint16 issueId,
        uint16 pageId,
        uint64 releaseDate
    ) external;

    /**
     * @notice Update Page Royalty Details
     * @dev allows the contract owner to update the receiver and royalty percentage for secondary page copy sales
     *
     * Requirements:
     *
     * - issue `issueId` page `pageId` must exist
     * - `receiver` must not be the zero address
     * - `bps` must not be greater than the fee denominator
     *
     * Emits a {PageRoyaltyInfoUpdated} event.
     */
    function updatePageRoyaltyInfo(
        uint16 issueId,
        uint16 pageId,
        address receiver,
        uint96 royaltyBps
    ) external;

    /**
     * @notice Update Page Sale Duration
     * @dev allows the contract owner to update the duration that page copies are available to mint
     *
     * Requirements:
     *
     * - `pageId` must not be 0 as this is the issue front cover page id which does not have a sale duration
     *
     * Emits a {PageSaleDurationUpdated} event.
     */
    function updatePageSaleDuration(
        uint16 issueId,
        uint16 pageId,
        uint64 saleDuration
    ) external;

    /**
     * @notice Update Page Token Gate
     * @dev allows the contract owner to update the address of a contract used to token gate minting a page copy
     *
     * Emits a {PagePriceUpdated} event.
     */
    function updatePageTokenGate(
        uint16 issueId,
        uint16 pageId,
        address tokenGateAddress
    ) external;

    /**
     * @notice Update Page URI
     * @dev allows the contract owner to update the metadata uri for a page
     *
     * Emits a {PageURIUpdated} event.
     */
    function updatePageURI(
        uint16 issueId,
        uint16 pageId,
        string calldata uri
    ) external;

    /**
     * @notice Pause
     * @dev allows the contract owner to pause certain functions of the contract
     */
    function pause() external;

    /**
     * @notice Pause
     * @dev allows the contract owner to unpause certain functions of the contract
     */
    function unpause() external;

    /**
     * @notice Withdraw
     * @dev allows the contract owner to withdraw the balance of the contract to their wallet
     */
    function withdraw() external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
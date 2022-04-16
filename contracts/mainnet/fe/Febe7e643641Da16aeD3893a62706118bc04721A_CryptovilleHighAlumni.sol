// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ProxyRegistry.sol";

error TokenOwnerQueryForInvalidToken();
error BalanceQueryForZeroAddress();
error ReservedTokenSupplyExhausted();
error SupplyInitRevealedTokensWhileInitUnrevealedMintingNotPaused();
error InitRevealedTokenSupplyExhausted();
error MintToZeroAddress();
error MintWithInvalidSignature();
error MintRevealedTokenDoesNotSupportReservedTokens();
error MintRevealedTokenInsufficientFund();
error MintRevealedTokenIdIsInvalid();
error MintRevealedTokenIsMinted();
error InitUnrevealedTokenMintingIsPaused();
error MintUnrevealedTokenInsufficientFund();
error MintUnrevealedTokenQuantityExceedsSupply();
error MintUnrevealedTokenQuantityIsProhibited();
error ApproveToTokenOwner();
error ApproveCallerIsNotOwnerNorApprovedForAll();
error ApprovedOperatorQueryForNonexistentToken();
error SetApprovalForAllTargetOperatorIsCaller();
error TransferInvalidToken();
error TransferFromIncorrectOwner();
error TransferFromZeroAddress();
error TransferToZeroAddress();
error TransferCallerIsNotOwnerNorApproved();
error TransferToNonERC721ReceiverImplementer();
error TokenUriQueryForNonexistentToken();
error WithdrawalFailed();

contract CryptovilleHighAlumni is
    ERC165,
    IERC721,
    IERC721Metadata,
    EIP712,
    Ownable
{
    using Strings for uint256;
    using Address for address;

    struct TokenOwnerData {
        uint64 balance;
        bool giveawayOfferClaimed;
    }

    /**
     * @dev Emitted when the state variable `nextRevealedTokenId` has been
     * updated to `newValue` from the old value `newValue` - `delta`.
     */
    event NextRevealedTokenIdChange(
        uint256 indexed newValue,
        uint256 indexed delta
    );

    /**
     * @dev Emitted when the state variable `nextInitUnrevealedTokenId` has
     * been updated to `newValue` from `oldValue`.
     */
    event NextInitUnrevealedTokenIdChange(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    string private _name = "Cryptoville High Alumni";
    string private _symbol = "CHA";
    address private _proxyRegistryAddress;
    bool private _proxyRegistryEnabled = true;

    mapping(uint256 => address) private _ownerships;
    mapping(address => TokenOwnerData) private _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => bool) private _canSign;

    string private _metadataBaseUri;
    string private constant _unrevealedMetadataUri =
        "ipfs://bafkreigzl4khqp5v3g2ix4bnitmatsdd33goypayocmszlvlmruf4qepue";

    /** @dev Token IDs are seqential integers starting from `_startTokenId`. */
    uint256 private constant _startTokenId = 1;
    uint256 private constant _maxTotalSupply = 10000;
    uint256 private constant _numInitRevealed = 8000;
    uint256 private constant _lastReservedTokenId = 1000;

    uint256 private constant _revealedMintGiveawayQuantity = 1;
    uint256 private constant _maxInitUnrevealedBatchMintSize = 10;

    /** @dev Whether minting for initially unrevealed tokens is paused. */
    bool public initUnrevealedMintingPaused;
    uint256 private _nextReservedTokenId = 201;

    /**
     * @notice ID for the next initially unrevealed token to be minted.
     * @dev Only decrementable.
     * @dev _maxTotalSupply - nextInitUnrevealedTokenId
     *      = number of initially unrevealed tokens minted
     * @dev nextInitUnrevealedTokenId - nextRevealedTokenId + 1
     *      = number of initially unrevealed tokens that are mintable
     */
    uint256 public nextInitUnrevealedTokenId = _maxTotalSupply;

    /**
     * @notice ID for the next initially revealed token that can be made
     * available for sale.
     * @dev Only incrementable.
     * @dev nextRevealedTokenId - 1
     *      = maximum number of initially revealed tokens that can be in
     *        circulation
     * @dev nextInitUnrevealedTokenId - nextRevealedTokenId + 1
     *      = maximum number of initially revealed tokens that can be further
     *        supplied by the deployer/issuer
     */
    uint256 public nextRevealedTokenId = 8001;

    /**
     * @notice Initializes the contract for the NFT collection with limited
     * supply.
     */
    constructor(string memory baseUri, address proxyRegistryAddress)
        EIP712(_name, "1.0.0")
    {
        for (uint256 id = _startTokenId; id < _nextReservedTokenId; id++) {
            emit Transfer(address(0), owner(), id);
        }
        _owners[address(0)].balance += uint64(_nextReservedTokenId - 1);
        _canSign[owner()] = true;
        _metadataBaseUri = baseUri;
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    /**
     * @notice Returns the maximum number of tokens that can be in circulation
     * at any time.
     */
    function totalSupply() public pure returns (uint256) {
        return _maxTotalSupply;
    }

    function setCanSign(address signer, bool allowed) public onlyOwner {
        _canSign[signer] = allowed;
    }

    function enableProxyRegistry(bool enabled) public onlyOwner {
        _proxyRegistryEnabled = enabled;
    }

    /**
     * @notice Enables/disables minting of initially unrevealed tokens.
     * @dev Must be disabled before supplying initially revealed tokens, which
     * automatically enables minting of initially unrevealed tokens when
     * the incremental supply of initially revealed tokens is completed.
     */
    function pauseInitUnrevealedTokenMinting(bool paused) public onlyOwner {
        initUnrevealedMintingPaused = paused;
    }

    /** @dev Use it to just check if `id` falls within the admissible range. */
    function _validTokenId(uint256 id) private pure returns (bool) {
        return _startTokenId <= id && id <= _maxTotalSupply;
    }

    function _initUnrevealedOwnerOf(uint256 tokenId)
        private
        view
        returns (address)
    {
        unchecked {
            address owner;
            uint256 currId = tokenId;
            for (uint256 i = 0; i < _maxInitUnrevealedBatchMintSize; i++) {
                owner = _ownerships[currId++];
                if (owner != address(0)) {
                    return owner;
                }
            }
        }
        revert TokenOwnerQueryForInvalidToken();
    }

    /**
     * @notice Returns the owner of the token identified by `tokenId` if it
     * maps to a token that has been revealed and in circulation (including
     * tokens that are initially unrevealed at deployment); reverts otherwise.
     * @dev Tokens that have an ID not exceeding `lastReservedTokenId` and are
     * still available for sale in the primary market are owned by the
     * deployer/issuer.
     * @dev Owner query for any invalid or unminted token ID reverts.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (tokenId != 0 && tokenId < nextRevealedTokenId) {
            address tokenOwner = _ownerships[tokenId];
            if (tokenOwner == address(0)) {
                if (tokenId < _nextReservedTokenId) {
                    return owner();
                }
                revert TokenOwnerQueryForInvalidToken();
            }
            return tokenOwner;
        }
        if (nextInitUnrevealedTokenId < tokenId && tokenId <= _maxTotalSupply) {
            return _initUnrevealedOwnerOf(tokenId);
        }
        revert TokenOwnerQueryForInvalidToken();
    }

    /**
     * @notice Returns the number of tokens owned by `tokenOwner`.
     * @dev `tokenOwner` must not be the zero address, for which any query
     * reverts.
     */
    function balanceOf(address tokenOwner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (tokenOwner == address(0)) revert BalanceQueryForZeroAddress();
        uint64 balance = _owners[tokenOwner].balance;
        if (tokenOwner == owner()) {
            balance += _owners[address(0)].balance;
        }
        return uint256(balance);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @notice Makes the next `quantity` number of (initially revealed)
     * reserved tokens available for sale in the primary market.
     * @dev If `quantity` exceeds the total number of mintable reserved tokens
     * available, it would be decremented to align with such amount.
     * @dev `quantity==0` does not revert if supply has not been exhausted.
     */
    function mintReservedTokens(uint256 quantity) public onlyOwner {
        if (_nextReservedTokenId > _lastReservedTokenId) {
            revert ReservedTokenSupplyExhausted();
        }
        uint256 maxQuantity = _lastReservedTokenId + 1 - _nextReservedTokenId;
        if (quantity > maxQuantity) {
            quantity = maxQuantity;
        }

        uint256 newNextId = _nextReservedTokenId + quantity;
        address to = owner();
        for (uint256 id = _nextReservedTokenId; id < newNextId; id++) {
            emit Transfer(address(0), to, id);
        }
        _owners[address(0)].balance += uint64(quantity);
        _nextReservedTokenId = newNextId;
    }

    function _maxInitUnrevealedMintable() private view returns (uint256) {
        return nextInitUnrevealedTokenId + 1 - nextRevealedTokenId;
    }

    /**
     * @notice Provides an additional `quantity` number of initially revealed
     * tokens for sale in the primary market, hence decreasing the supply of
     * initially unrevealed tokens.
     * @dev Reverts if minting of initially unrevealed tokens is not paused
     * before executing the incremental supply.
     * @dev If `quantity` exceeds the total number of mintable tokens available,
     * it would be decremented to align with such amount.
     * @dev `quantity==0` does not revert if supply has not been exhausted.
     */
    function supplyInitRevealedTokens(uint256 quantity) public onlyOwner {
        if (!initUnrevealedMintingPaused) {
            revert SupplyInitRevealedTokensWhileInitUnrevealedMintingNotPaused();
        }
        uint256 maxQuantity = _maxInitUnrevealedMintable();
        if (quantity > maxQuantity) {
            quantity = maxQuantity;
        }
        nextRevealedTokenId += quantity;
        initUnrevealedMintingPaused = false;
        emit NextRevealedTokenIdChange(nextRevealedTokenId, quantity);
    }

    /**
     * @notice Returns `true` if the token identified by `tokenId` is initally
     * revealed and is available in the primary market at the moment of this
     * query.
     */
    function isInitRevealedAndInPrimaryMarket(uint256 tokenId)
        public
        view
        returns (bool)
    {
        return
            _ownerships[tokenId] == address(0) &&
            ((_lastReservedTokenId < tokenId &&
                tokenId < nextRevealedTokenId) ||
                (_startTokenId <= tokenId && tokenId < _nextReservedTokenId));
    }

    /**
     * @notice Mints the initially revealed token that is identified by
     * `tokenId` and transfers it to the address `to`. `tokenId` must be in
     * either of the ranges [`_startTokenId`, `_nextReservedTokenId` - 1] or
     * [`lastReservedTokenId` + 1, `nextRevealedTokenId` - 1]. A minting fee
     * of `minPrice` wei applies and is payable by the message sender.
     * A successful mint may receive the giveaway offer of at most
     * `_revealedMintGiveawayQuantity` number of initially unrevealed tokens
     * in limited time while supply lasts and on a first-come-first-served
     * basis. Each wallet address is eligible for this offer only once.
     * Minting by a contract is not eligible for this offer. Giveaway offers
     * cannot be fulfilled when minting for initially unrevealed tokens is
     * paused. To check the status, use `initUnrevealedMintingPaused`.
     */
    function mintRevealedToken(
        uint256 tokenId,
        uint256 minPrice,
        address to,
        bytes32 nonce,
        address signer,
        bytes calldata signature
    ) public payable {
        if (to != owner()) {
            if (msg.value < minPrice) {
                revert MintRevealedTokenInsufficientFund();
            }
            bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Voucher(uint256 tokenId,uint256 minPrice,address to,bytes32 nonce)"
                        ),
                        tokenId,
                        minPrice,
                        to,
                        nonce
                    )
                )
            );
            if (
                !_canSign[signer] ||
                !SignatureChecker.isValidSignatureNow(signer, digest, signature)
            ) {
                revert MintWithInvalidSignature();
            }
        }
        _safeMintRevealed(to, tokenId, "");
    }

    function _safeMintRevealed(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private {
        if (tokenId < _startTokenId || tokenId >= nextRevealedTokenId) {
            revert MintRevealedTokenIdIsInvalid();
        }

        if (
            _nextReservedTokenId <= tokenId && tokenId <= _lastReservedTokenId
        ) {
            revert MintRevealedTokenDoesNotSupportReservedTokens();
        }

        if (_ownerships[tokenId] != address(0)) {
            revert MintRevealedTokenIsMinted();
        }

        if (to == address(0)) revert MintToZeroAddress();

        bool notExceedingLastReservedTokenId = tokenId <= _lastReservedTokenId;
        address from = notExceedingLastReservedTokenId ? owner() : address(0);

        _tokenApprovals[tokenId] = address(0);

        if (notExceedingLastReservedTokenId) {
            _owners[address(0)].balance -= 1;
        }
        _owners[to].balance += 1;
        _ownerships[tokenId] = to;

        emit Transfer(from, to, tokenId);

        if (
            to.isContract() && !_checkOnERC721Received(from, to, tokenId, _data)
        ) {
            revert TransferToNonERC721ReceiverImplementer();
        }

        _claimGiveawayOffer(to, _revealedMintGiveawayQuantity);
    }

    function _claimGiveawayOffer(address to, uint256 quantity) private {
        if (
            !initUnrevealedMintingPaused &&
            !to.isContract() &&
            !_owners[to].giveawayOfferClaimed &&
            nextInitUnrevealedTokenId >= nextRevealedTokenId
        ) {
            _safeMintUnrevealed(to, quantity, "");
            _owners[to].giveawayOfferClaimed = true;
        }
    }

    /**
     * @notice Mints `quantity` number of initially unrevealed tokens and
     * transfers all minted tokens to the address `to`, subject to a maximum
     * quantity of `_maxInitUnrevealedBatchMintSize` per transaction.
     * A miniting fee of `unitPrice` wei per token applies and is payable by
     * the message sender.
     * @dev `to` cannot be the zero address.
     * @dev `quantity` must be greater than 0 and no larger than
     * `_maxInitUnrevealedBatchMintSize`.
     * @dev Reverts if `quantity` exceeds the maximum possible supply of
     * initially unrevealed tokens. To check the number of initially unrevealed
     * tokens that are mintable, see `nextInitUnrevealedTokenId`.
     */
    function mintUnrevealedToken(
        uint256 quantity,
        uint256 unitPrice,
        address to,
        bytes32 nonce,
        address signer,
        bytes calldata signature
    ) public payable {
        if (
            nextInitUnrevealedTokenId < nextRevealedTokenId ||
            quantity > _maxInitUnrevealedMintable()
        ) {
            revert MintUnrevealedTokenQuantityExceedsSupply();
        }
        if (to != owner()) {
            if (msg.value < quantity * unitPrice) {
                revert MintUnrevealedTokenInsufficientFund();
            }
            bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BatchVoucher(bytes32 nonce,uint256 quantity,address to,uint256 unitPrice)"
                        ),
                        nonce,
                        quantity,
                        to,
                        unitPrice
                    )
                )
            );
            if (
                !_canSign[signer] ||
                !SignatureChecker.isValidSignatureNow(signer, digest, signature)
            ) {
                revert MintWithInvalidSignature();
            }
        }
        _safeMintUnrevealed(to, quantity, "");
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        if (!sent) revert WithdrawalFailed();
    }

    function _safeMintUnrevealed(
        address to,
        uint256 quantity,
        bytes memory _data
    ) private {
        if (initUnrevealedMintingPaused) {
            revert InitUnrevealedTokenMintingIsPaused();
        }

        if (quantity == 0 || quantity > _maxInitUnrevealedBatchMintSize) {
            revert MintUnrevealedTokenQuantityIsProhibited();
        }

        if (to == address(0)) revert MintToZeroAddress();

        uint256 maxQuantity = _maxInitUnrevealedMintable();
        if (quantity > maxQuantity) {
            quantity = maxQuantity;
        }

        uint256 firstTokenId = nextInitUnrevealedTokenId;
        unchecked {
            _owners[to].balance += uint64(quantity);
            _ownerships[firstTokenId] = to;

            uint256 currTokenId = firstTokenId;
            uint256 lastTokenId = currTokenId - quantity;
            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, currTokenId);
                    if (
                        !_checkOnERC721Received(
                            address(0),
                            to,
                            currTokenId--,
                            _data
                        )
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (currTokenId != lastTokenId);
                if (nextInitUnrevealedTokenId != firstTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, currTokenId--);
                } while (currTokenId != lastTokenId);
            }
            nextInitUnrevealedTokenId = currTokenId;
            emit NextInitUnrevealedTokenIdChange(currTokenId, firstTokenId);
        }
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApproveToTokenOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApproveCallerIsNotOwnerNorApprovedForAll();
        }

        _approve(to, tokenId, owner);
    }

    /** @dev See {IERC721-getApproved}. */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (!_validTokenId(tokenId)) {
            revert ApprovedOperatorQueryForNonexistentToken();
        }

        return _tokenApprovals[tokenId];
    }

    /** @dev See {IERC721-setApprovalForAll}. */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (_msgSender() == operator) {
            revert SetApprovalForAllTargetOperatorIsCaller();
        }

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /** @dev See {IERC721-isApprovedForAll}. */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (_proxyRegistryEnabled) {
            ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }
        return _operatorApprovals[owner][operator];
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        if (
            _msgSender() != from &&
            !isApprovedForAll(from, _msgSender()) &&
            getApproved(tokenId) != _msgSender()
        ) revert TransferCallerIsNotOwnerNorApproved();

        if (
            from == owner() &&
            _ownerships[tokenId] == address(0) &&
            tokenId < _nextReservedTokenId
        ) {
            return _safeMintRevealed(to, tokenId, "");
        }

        if (!_validTokenId(tokenId)) revert TransferInvalidToken();

        if (from == address(0)) revert TransferFromZeroAddress();

        address prevOwner = tokenId <= nextInitUnrevealedTokenId
            ? _ownerships[tokenId]
            : _initUnrevealedOwnerOf(tokenId);
        if (prevOwner != from) revert TransferFromIncorrectOwner();

        if (to == address(0)) revert TransferToZeroAddress();

        _approve(address(0), tokenId, from);

        unchecked {
            _owners[from].balance -= 1;
            _owners[to].balance += 1;
            _ownerships[tokenId] = to;

            if (tokenId > nextInitUnrevealedTokenId) {
                uint256 prevTokenId = tokenId - 1;
                if (
                    prevTokenId > nextInitUnrevealedTokenId &&
                    _ownerships[prevTokenId] == address(0)
                ) {
                    _ownerships[prevTokenId] = from;
                }
            }
        }
        emit Transfer(from, to, tokenId);
    }

    /** @dev See {IERC721-transferFrom}. */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /** @dev See {IERC721-safeTransferFrom}. */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /** @dev See {IERC721-safeTransferFrom}. */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (
            to.isContract() && !_checkOnERC721Received(from, to, tokenId, _data)
        ) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /** @dev See {IERC721Metadata-name}. */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /** @dev See {IERC721Metadata-symbol}. */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /** @dev See {IERC721Metadata-tokenURI}. */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_validTokenId(tokenId)) {
            revert TokenUriQueryForNonexistentToken();
        }

        if (
            tokenId < nextRevealedTokenId || tokenId > nextInitUnrevealedTokenId
        ) {
            string memory baseURI = _metadataBaseUri;
            return
                bytes(baseURI).length != 0
                    ? string(abi.encodePacked(baseURI, tokenId.toString()))
                    : "";
        }
        return _unrevealedMetadataUri;
    }

    /** @dev See {IERC165-supportsInterface}. */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity ^0.8.13;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}
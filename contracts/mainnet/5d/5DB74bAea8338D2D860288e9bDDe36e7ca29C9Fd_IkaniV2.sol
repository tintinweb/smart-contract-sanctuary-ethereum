// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ERC721Upgradeable } from "../../deps//ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "../../deps/IERC165Upgradeable.sol";
import { IERC2981Upgradeable } from "../../deps/IERC2981Upgradeable.sol";
import { PausableUpgradeable } from "../../deps/PausableUpgradeable.sol";

import { IIkaniV2Staking } from "../../staking/v2/interfaces/IIkaniV2Staking.sol";
import { IIkaniV1MetadataController } from "../v1/interfaces/IIkaniV1MetadataController.sol";
import { ContractUriUpgradeable } from "../v1/lib/ContractUriUpgradeable.sol";
import { ERC721SequentialUpgradeable } from "../v1/lib/ERC721SequentialUpgradeable.sol";
import { PersonalSign } from "../v1/lib/PersonalSign.sol";
import { WithdrawableUpgradeable } from "../v1/lib/WithdrawableUpgradeable.sol";
import { IkaniV2SeriesLib } from "./lib/IkaniV2SeriesLib.sol";
import { IIkaniV2 } from "./interfaces/IIkaniV2.sol";

/**
 * @title IkaniV2
 * @author Cyborg Labs, LLC
 *
 * @notice The IKANI.AI ERC-721 NFT.
 */
contract IkaniV2 is
    ERC721SequentialUpgradeable,
    ContractUriUpgradeable,
    WithdrawableUpgradeable,
    PausableUpgradeable,
    IERC2981Upgradeable,
    IIkaniV2
{
    //---------------- Constants ----------------//

    uint256 internal constant BIPS_DENOMINATOR = 10000;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable MAX_SUPPLY; // e.g. 8888

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IIkaniV2Staking public immutable STAKING_CONTRACT;

    //---------------- Storage V1 ----------------//

    IIkaniV1MetadataController internal _METADATA_CONTROLLER_;

    address internal _MINT_SIGNER_;

    /// @dev The set of message digests signed and consumed for minting.
    mapping(bytes32 => bool) internal _USED_MINT_DIGESTS_;

    /// @dev DEPRECATED: Poem text and metadata by token ID.
    mapping(uint256 => bytes) internal __DEPRECATED_POEM_INFO_;

    /// @dev Series information by index.
    mapping(uint256 => IIkaniV2.Series) internal _SERIES_INFO_;

    /// @dev Index of the current series available for minting.
    uint256 internal _CURRENT_SERIES_INDEX_;

    //---------------- Storage V1_1 ----------------//

    /// @dev Poem text by token ID.
    mapping(uint256 => string) internal _POEM_TEXT_;

    /// @dev Metadata traits by token ID.
    mapping(uint256 => IIkaniV2.PoemTraits) internal _POEM_TRAITS_;

    //---------------- Storage V2 ----------------//

    address internal _ROYALTY_RECEIVER_;

    uint96 internal _ROYALTY_BIPS_;

    //---------------- Constructor & Initializer ----------------//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        uint256 maxSupply,
        IIkaniV2Staking stakingContract
    )
        initializer
    {
        MAX_SUPPLY = maxSupply;
        STAKING_CONTRACT = stakingContract;
    }

    //---------------- Owner-Only External Functions ----------------//

    function pause()
        external
        onlyOwner
    {
        _pause();
    }

    function unpause()
        external
        onlyOwner
    {
        _unpause();
    }

    function setContractUri(
        string memory contractUri
    )
        external
        onlyOwner
    {
        _setContractUri(contractUri);
    }

    function setMetadataController(
        IIkaniV1MetadataController metadataController
    )
        external
        onlyOwner
    {
        _METADATA_CONTROLLER_ = metadataController;
    }

    function setMintSigner(
        address mintSigner
    )
        external
        onlyOwner
    {
        _MINT_SIGNER_ = mintSigner;
    }

    function setRoyaltyReceiver(
        address royaltyReceiver
    )
        external
        onlyOwner
    {
        _ROYALTY_RECEIVER_ = royaltyReceiver;
        emit SetRoyaltyReceiver(royaltyReceiver);
    }

    function setRoyaltyBips(
        uint96 royaltyBips
    )
        external
        onlyOwner
    {
        _ROYALTY_BIPS_ = royaltyBips;
        emit SetRoyaltyBips(uint256(royaltyBips));
    }

    function setPoemText(
        uint256[] calldata tokenIds,
        string[] calldata poemText
    )
        external
        onlyOwner
    {
        // Note: To save gas, we don't check that the token was minted; however,
        //       the owner should only call this function with minted token IDs.

        uint256 n = tokenIds.length;

        require(
            poemText.length == n,
            "Params length mismatch"
        );

        for (uint256 i = 0; i < n;) {
            _POEM_TEXT_[tokenIds[i]] = poemText[i];

            unchecked { ++i; }
        }
    }

    function setPoemTraits(
        uint256[] calldata tokenIds,
        IIkaniV2.PoemTraits[] calldata poemTraits
    )
        external
        onlyOwner
    {
        // Note: To save gas, we don't check that the token was minted; however,
        //       the owner should only call this function with minted token IDs.

        uint256 n = tokenIds.length;

        require(
            poemTraits.length == n,
            "Params length mismatch"
        );

        for (uint256 i = 0; i < n;) {
            uint256 tokenId = tokenIds[i];
            IIkaniV2.PoemTraits memory traits = poemTraits[i];

            require(
                traits.theme != IIkaniV2.Theme.NULL,
                "Theme cannot be null"
            );
            require(
                traits.fabric != IIkaniV2.Fabric.NULL,
                "Fabric cannot be null"
            );

            _POEM_TRAITS_[tokenId] = traits;

            emit FinishedPoem(tokenId);

            unchecked { ++i; }
        }
    }

    function setSeriesInfo(
        uint256 seriesIndex,
        string calldata name,
        bytes32 provenanceHash
    )
        external
        onlyOwner
    {
        IIkaniV2.Series storage _series_ = _SERIES_INFO_[seriesIndex];

        _series_.name = name;
        _series_.provenanceHash = provenanceHash;

        emit SetSeriesInfo(
            seriesIndex,
            name,
            provenanceHash
        );
    }

    function endCurrentSeries(
        uint256 poemCreationDeadline
    )
        external
        onlyOwner
    {
        uint256 seriesIndex = _CURRENT_SERIES_INDEX_++;

        IkaniV2SeriesLib.endCurrentSeries(
            _SERIES_INFO_[seriesIndex],
            seriesIndex,
            poemCreationDeadline,
            getNextTokenId()
        );
    }

    function advancePoemCreationDeadline(
        uint256 seriesIndex,
        uint256 poemCreationDeadline
    )
        external
        onlyOwner
    {
        IIkaniV2.Series storage _series_ = _SERIES_INFO_[seriesIndex];

        require(
            poemCreationDeadline > _series_.poemCreationDeadline,
            "Deadline can only move forward"
        );

        _series_.poemCreationDeadline = poemCreationDeadline;

        emit AdvancedPoemCreationDeadline(
            seriesIndex,
            poemCreationDeadline
        );
    }

    function mintByOwner(
        address[] calldata recipients
    )
        external
        onlyOwner
    {
        uint256 n = recipients.length;

        for (uint256 i = 0; i < n;) {
            // Note: Intentionally not using _safeMint().
            _mint(recipients[i]);

            unchecked { ++i; }
        }

        require(
            getNextTokenId() <= MAX_SUPPLY,
            "Global max supply exceeded"
        );
    }

    function expire(
        uint256 tokenId
    )
        external
        onlyOwner
    {
        require(
            !isPoemFinished(tokenId),
            "Cannot expire a finished poem"
        );

        uint256 seriesIndex = getPoemSeriesIndex(tokenId);

        IIkaniV2.Series storage _series_ = _SERIES_INFO_[seriesIndex];

        require(
            _series_.startingIndexBlockNumber != 0,
            "Series not ended"
        );
        require(
            block.timestamp > _series_.poemCreationDeadline,
            "Token has not expired"
        );

        _burn(tokenId);
    }

    function expireBatch(
        uint256[] calldata tokenIds,
        uint256 seriesIndex
    )
        external
        onlyOwner
    {
        require(
            seriesIndex <= _CURRENT_SERIES_INDEX_,
            "Invalid series index"
        );

        IkaniV2SeriesLib.validateExpireBatch(
            _SERIES_INFO_,
            tokenIds,
            seriesIndex
        );

        uint256 n = tokenIds.length;

        for (uint256 i = 0; i < n;) {
            require(
                !isPoemFinished(tokenIds[i]),
                "Cannot expire a finished poem"
            );
            _burn(tokenIds[i]);

            unchecked { ++i; }
        }
    }

    //---------------- Other State-Changing External Functions ----------------//

    function mint(
        IIkaniV2.MintArgs calldata mintArgs,
        bytes calldata signature
    )
        external
        payable
        whenNotPaused
    {
        require(
            mintArgs.seriesIndex == _CURRENT_SERIES_INDEX_,
            "Not the current series"
        );

        require(
            msg.value == mintArgs.mintPrice,
            "Wrong msg.value"
        );

        address sender = msg.sender;
        bytes memory message = abi.encode(
            sender,
            mintArgs
        );
        bytes32 messageDigest = keccak256(message);

        // Only allow one mint per message/digest/signature.
        require(
            !_USED_MINT_DIGESTS_[messageDigest],
            "Mint digest already used"
        );
        _USED_MINT_DIGESTS_[messageDigest] = true;

        // Note: Since the only signer is our admin, we don't need EIP-712.
        require(
            PersonalSign.isValidSignature(messageDigest, signature, _MINT_SIGNER_),
            "Invalid signature"
        );

        // Note: Intentionally not using _safeMint().
        uint256 tokenId = _mint(sender);

        require(
            tokenId < mintArgs.maxTokenIdExclusive,
            "Series max supply exceeded"
        );
        require(
            tokenId < MAX_SUPPLY,
            "Global max supply exceeded"
        );
    }

    function trySetSeriesStartingIndex(
        uint256 seriesIndex
    )
        external
        whenNotPaused
    {
        IkaniV2SeriesLib.trySetSeriesStartingIndex(
            _SERIES_INFO_,
            seriesIndex
        );
    }

    //---------------- View-Only External Functions ----------------//

    function getMetadataController()
        external
        view
        returns (IIkaniV1MetadataController)
    {
        return _METADATA_CONTROLLER_;
    }

    function getMintSigner()
        external
        view
        returns (address)
    {
        return _MINT_SIGNER_;
    }

    function getSeriesSupply(
        uint256 seriesIndex
    )
        external
        view
        returns (uint256)
    {
        return IkaniV2SeriesLib.getSeriesSupply(_SERIES_INFO_, seriesIndex);
    }

    function royaltyInfo(
        uint256 /* tokenId */,
        uint256 salePrice
    )
        external
        view
        override
        returns (address, uint256)
    {
        uint256 royaltyAmount = (salePrice * uint256(_ROYALTY_BIPS_)) / BIPS_DENOMINATOR;
        return (_ROYALTY_RECEIVER_, royaltyAmount);
    }

    function isUsedMintDigest(
        bytes32 digest
    )
        external
        view
        returns (bool)
    {
        return _USED_MINT_DIGESTS_[digest];
    }

    function getSeriesInfo(
        uint256 seriesIndex
    )
        external
        view
        returns (IIkaniV2.Series memory)
    {
        return _SERIES_INFO_[seriesIndex];
    }

    function getCurrentSeriesIndex()
        external
        view
        returns (uint256)
    {
        return _CURRENT_SERIES_INDEX_;
    }

    function exists(
        uint256 tokenId
    )
        external
        view
        returns (bool)
    {
        return _exists(tokenId);
    }

    //---------------- Public Functions ----------------//

    function getPoemSeriesIndex(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        uint256 currentSeriesIndex = _CURRENT_SERIES_INDEX_;
        uint256 seriesIndex;
        for (seriesIndex = 0; seriesIndex < currentSeriesIndex;) {
            IIkaniV2.Series storage _series_ = _SERIES_INFO_[seriesIndex];

            if (tokenId < _series_.maxTokenIdExclusive) {
                break;
            }

            unchecked { ++seriesIndex; }
        }
        return seriesIndex;
    }

    function getPoemText(
        uint256 tokenId
    )
        public
        view
        returns (string memory)
    {
        return _POEM_TEXT_[tokenId];
    }

    function getPoemTraits(
        uint256 tokenId
    )
        public
        view
        returns (IIkaniV2.PoemTraits memory)
    {
        return _POEM_TRAITS_[tokenId];
    }

    function isPoemFinished(
        uint256 tokenId
    )
        public
        view
        returns (bool)
    {
        return _POEM_TRAITS_[tokenId].theme != IIkaniV2.Theme.NULL;
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override
        returns (string memory)
    {
        return _METADATA_CONTROLLER_.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    //---------------- Internal Functions ----------------//

    function _beforeTokenTransfer(
        address /* from */,
        address /* to */,
        uint256 tokenId
    )
        internal
        view
        override
    {
        // Ensure that staked tokens can only be transfered via the staking contract.
        if (msg.sender != address(STAKING_CONTRACT)) {
            require(
                !STAKING_CONTRACT.isStaked(tokenId),
                "Cannot transfer staked token"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IIkaniV2Staking
 * @author Cyborg Labs, LLC
 *
 * @notice Interface for the IIkaniV2Staking features of the IkaniV1 ERC-721 NFT contract.
 */
interface IIkaniV2Staking {

    //---------------- Structs ----------------//

    struct RateChange {
        uint32 baseRate;
        uint32 timestamp;
    }

    struct SettlementContext {
        // The timestamp of the last settlement of this account.
        uint32 timestamp;
        // The number of global rate changes taken into account as of the last settlement
        // of this account.
        uint32 numRateChanges;
        // The global base earning rate.
        uint32 baseRate;
        // The current number of points for the account's staked tokens.
        uint32 points;
        // Current multiplier derived from the account's staked traits.
        uint32 multiplier;
        // The trait counts for the account's staked tokens.
        uint8 fabricKoyamaki;
        uint8 fabricSeigaiha;
        uint8 fabricNami;
        uint8 fabricKumo;
        uint8 fabricTba5;
        uint8 fabricTba6;
        uint8 fabricTba7;
        uint8 fabricTba8;
        uint8 seasonSpring;
        uint8 seasonSummer;
        uint8 seasonAutumn;
        uint8 seasonWinter;
    }

    struct Checkpoint {
        uint128 tokenId;
        uint32 stakedNonce;
        uint32 basePoints;
        uint32 level;
        uint32 timestamp;
    }

    struct TokenStakingState {
        uint32 timestamp;
        uint32 nonce;
    }

    //---------------- Events ----------------//

    event SetBaseRate(
        uint256 baseRate
    );

    event AdminUnstaked(
        address indexed owner,
        uint256[] indexed tokenIds,
        bytes32 indexed receipt,
        bytes receiptData
    );

    event Staked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 stakingStartTimestamp
    );

    event Unstaked(
        address indexed owner,
        uint256 indexed tokenId
    );

    event ClaimedRewards(
        address indexed owner,
        uint256 amount
    );

    //---------------- Functions ----------------//

    function isStaked(
        uint256 tokenId
    )
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IIkaniV1MetadataController
 * @author Cyborg Labs, LLC
 *
 * @notice Interface for a contract that provides token metadata via tokenURI().
 */
interface IIkaniV1MetadataController {

    function tokenURI(
        uint256 tokenId
    )
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { Initializable } from "../../../deps/Initializable.sol";

/**
 * @title ContractUriUpgradeable
 * @author Cyborg Labs, LLC
 *
 * @dev Simple base contract supporting the contractURI() function used by OpenSea.
 */
abstract contract ContractUriUpgradeable is
    Initializable
{
    string private _CONTRACT_URI_;

    uint256[49] private __gap;

    event SetContractUri(
        string contractUri
    );

    function __ContractUri_init()
        internal
        onlyInitializing
    {}

    function __ContractUri_init_unchained()
        internal
        onlyInitializing
    {}

    function contractURI()
        external
        view
        returns (string memory)
    {
        return _CONTRACT_URI_;
    }

    function _setContractUri(
        string memory contractUri
    )
        internal
    {
        _CONTRACT_URI_ = contractUri;
        emit SetContractUri(contractUri);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ERC721Upgradeable } from "../../../deps/ERC721Upgradeable.sol";

/**
 * @title ERC721SequentialUpgradeable
 * @author Cyborg Labs, LLC
 *
 * @dev Base contract for an ERC-721 that is minted sequentially. Supports totalSupply().
 */
abstract contract ERC721SequentialUpgradeable is
    ERC721Upgradeable
{
    //---------------- Storage ----------------//

    uint256 internal _NEXT_TOKEN_ID_;

    uint256 internal _BURNED_COUNT_;

    uint256[48] private __gap;

    //---------------- Initializers ----------------//

    function __ERC721Sequential_init(
        string memory name,
        string memory symbol
    )
        internal
        onlyInitializing
    {
        __ERC721_init(name, symbol);
    }

    function __ERC721Sequential_init_unchained()
        internal
        onlyInitializing
    {}

    //---------------- Public Functions ----------------//

    function getNextTokenId()
        public
        view
        returns (uint256)
    {
        return _NEXT_TOKEN_ID_;
    }

    function getBurnedCount()
        public
        view
        returns (uint256)
    {
        return _BURNED_COUNT_;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _NEXT_TOKEN_ID_ - _BURNED_COUNT_;
    }

    //---------------- Internal Functions ----------------//

    function _mint(
        address recipient
    )
        internal
        returns (uint256)
    {
        uint256 tokenId = _NEXT_TOKEN_ID_++;
        ERC721Upgradeable._mint(recipient, tokenId);
        return tokenId;
    }

    function _burn(
        uint256 tokenId
    )
        internal
        override
    {
        _BURNED_COUNT_++;
        ERC721Upgradeable._burn(tokenId);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title PersonalSign
 * @author Cyborg Labs, LLC
 *
 * @dev Helper function to verify messages signed with personal_sign.
 *
 *  IMPORTANT: Use cases which require users to sign some data (i.e. most signing use cases)
 *  should NOT use this. They should instead follow EIP-712, for security reasons.
 *
 *  NOTE: For our puroses, we assume that the message is hashed before being signed.
 *  The message length is therefore fixed at 32 bytes.
 *
 *  Signing example using ethers.js:
 *
 *  ```
 *    const encodedDataString = ethers.utils.defaultAbiCoder.encode(
 *      [
 *        // types
 *      ],
 *      [
 *        // values
 *      ],
 *    );
 *    const encodedData = Buffer.from(encodedDataString.slice(2), "hex");
 *    const innerDigestString = ethers.utils.keccak256(encodedData);
 *    const innerDigest = Buffer.from(innerDigestString.slice(2), "hex");
 *    const signature = await signer.signMessage(innerDigest);
 *  ```
 */
library PersonalSign {

  bytes constant private PERSONAL_SIGN_HEADER = "\x19Ethereum Signed Message:\n32";

  function isValidSignature(
    bytes32 messageDigest,
    bytes memory signature,
    address expectedSigner
  )
    internal
    pure
    returns (bool)
  {
    // Parse the signature into (v, r, s) components.
    require(
      signature.length == 65,
      "Bad signature length"
    );
    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Construct the digest hash which is signed within the `personal_sign` operation.
    bytes32 digest = keccak256(
      abi.encodePacked(
        PERSONAL_SIGN_HEADER,
        messageDigest
      )
    );

    // Check whether the recovered address is the required address.
    address recovered = ecrecover(digest, v, r, s);
    return recovered == expectedSigner;
  }

  function isValidSignature(
    bytes memory message,
    bytes memory signature,
    address expectedSigner
  )
    internal
    pure
    returns (bool)
  {
    return isValidSignature(
      keccak256(message),
      signature,
      expectedSigner
    );
  }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { OwnableUpgradeable } from "../../../deps/OwnableUpgradeable.sol";

/**
 * @title WithdrawableUpgradeable
 * @author Cyborg Labs, LLC
 *
 * @dev Supports ETH withdrawals by the owner.
 */
abstract contract WithdrawableUpgradeable is
    OwnableUpgradeable
{
    event Withdrawal(
        address recipient,
        uint256 balance
    );

    function __Withdrawable_init()
        internal
        onlyInitializing
    {
        __Ownable_init();
    }

    function __Withdrawable_init_unchained()
        internal
        onlyInitializing
    {}

    function withdrawTo(
        address recipient
    )
        external
        onlyOwner
        returns (uint256)
    {
        uint256 balance = address(this).balance;
        payable(recipient).transfer(balance);
        emit Withdrawal(recipient, balance);
        return balance;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IIkaniV2 } from "../interfaces/IIkaniV2.sol";

library IkaniV2SeriesLib {

    // TODO: De-dup event definitions.

    event ResetSeriesStartingIndexBlockNumber(
        uint256 indexed seriesIndex,
        uint256 startingIndexBlockNumber
    );

    event SetSeriesStartingIndex(
        uint256 indexed seriesIndex,
        uint256 startingIndex
    );

    event EndedSeries(
        uint256 indexed seriesIndex,
        uint256 poemCreationDeadline,
        uint256 maxTokenIdExclusive,
        uint256 startingIndexBlockNumber
    );

    uint256 internal constant STARTING_INDEX_ADD_BLOCKS = 10;

    function trySetSeriesStartingIndex(
        mapping(uint256 => IIkaniV2.Series) storage _series_info_,
        uint256 seriesIndex
    )
        external
    {
        IIkaniV2.Series storage _series_ = _series_info_[seriesIndex];

        require(
            !_series_.startingIndexWasSet,
            "Starting index already set"
        );

        uint256 targetBlockNumber = _series_.startingIndexBlockNumber;
        require(
            targetBlockNumber != 0,
            "Series not ended"
        );

        require(
            block.number >= targetBlockNumber,
            "Starting index block not reached"
        );

        // If the hash for the target block is not available, set a new block number and exit.
        if (block.number - targetBlockNumber > 256) {
            uint256 newStartingIndexBlockNumber = block.number + STARTING_INDEX_ADD_BLOCKS;
            _series_.startingIndexBlockNumber = newStartingIndexBlockNumber;
            emit ResetSeriesStartingIndexBlockNumber(
                seriesIndex,
                newStartingIndexBlockNumber
            );
            return;
        }

        uint256 seriesSupply = getSeriesSupply(_series_info_, seriesIndex);
        uint256 startingIndex = uint256(blockhash(targetBlockNumber)) % seriesSupply;

        // Update storage.
        _series_.startingIndex = startingIndex;
        _series_.startingIndexWasSet = true;

        emit SetSeriesStartingIndex(
            seriesIndex,
            startingIndex
        );
    }

    function endCurrentSeries(
        IIkaniV2.Series storage _series_,
        uint256 seriesIndex,
        uint256 poemCreationDeadline,
        uint256 maxTokenIdExclusive
    )
        external
    {
        uint256 startingIndexBlockNumber = block.number + STARTING_INDEX_ADD_BLOCKS;

        _series_.poemCreationDeadline = poemCreationDeadline;
        _series_.maxTokenIdExclusive = maxTokenIdExclusive;
        _series_.startingIndexBlockNumber = startingIndexBlockNumber;

        emit EndedSeries(
            seriesIndex,
            poemCreationDeadline,
            maxTokenIdExclusive,
            startingIndexBlockNumber
        );
    }

    function validateExpireBatch(
        mapping(uint256 => IIkaniV2.Series) storage _series_info_,
        uint256[] calldata tokenIds,
        uint256 seriesIndex
    )
        external
        view
    {
        IIkaniV2.Series storage _series_ = _series_info_[seriesIndex];

        require(
            _series_.startingIndexBlockNumber != 0,
            "Series not ended"
        );
        require(
            block.timestamp > _series_.poemCreationDeadline,
            "Series has not expired"
        );

        uint256 n = tokenIds.length;

        uint256 maxTokenIdExclusive = _series_.maxTokenIdExclusive;
        for (uint256 i = 0; i < n;) {
            require(
                tokenIds[i] < maxTokenIdExclusive,
                "Token ID not part of the series"
            );
            unchecked { ++i; }
        }

        if (seriesIndex > 0) {
            uint256 startTokenId = _series_info_[seriesIndex - 1].maxTokenIdExclusive;
            for (uint256 i = 0; i < n;) {
                require(
                    tokenIds[i] >= startTokenId,
                    "Token ID not part of the series"
                );
                unchecked { ++i; }
            }
        }
    }

    function getSeriesSupply(
        mapping(uint256 => IIkaniV2.Series) storage _series_info_,
        uint256 seriesIndex
    )
        public
        view
        returns (uint256)
    {
        IIkaniV2.Series storage _series_ = _series_info_[seriesIndex];

        require(
            _series_.startingIndexBlockNumber != 0,
            "Series not ended"
        );

        uint256 maxTokenIdExclusive = _series_.maxTokenIdExclusive;

        if (seriesIndex == 0) {
            return maxTokenIdExclusive;
        }

        IIkaniV2.Series storage _previous_series_ = _series_info_[seriesIndex - 1];

        return maxTokenIdExclusive - _previous_series_.maxTokenIdExclusive;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IIkaniV2
 * @author Cyborg Labs, LLC
 *
 * @notice Interface for the IkaniV1 ERC-721 NFT contract.
 */
interface IIkaniV2 {

    //---------------- Enums ----------------//

    enum Theme {
        NULL,
        SKY,
        OCEAN,
        MOUNTAIN,
        FLOWERS,
        TBA_THEME_5,
        TBA_THEME_6,
        TBA_THEME_7,
        TBA_THEME_8
    }

    enum Season {
        NONE,
        SPRING,
        SUMMER,
        AUTUMN,
        WINTER
    }

    enum Fabric {
        NULL,
        KOYAMAKI,
        SEIGAIHA,
        NAMI,
        KUMO,
        TBA_FABRIC_5,
        TBA_FABRIC_6,
        TBA_FABRIC_7,
        TBA_FABRIC_8
    }

    enum Foil {
        NONE,
        GOLD,
        PLATINUM,
        SUI_GENERIS
    }

    //---------------- Structs ----------------//

    /**
     * @notice The poem metadata traits.
     */
    struct PoemTraits {
        Theme theme;
        Season season;
        Fabric fabric;
        Foil foil;
    }

    /**
     * @notice Information about a series within the collection.
     */
    struct Series {
        string name;
        bytes32 provenanceHash;
        uint256 poemCreationDeadline;
        uint256 maxTokenIdExclusive;
        uint256 startingIndexBlockNumber;
        uint256 startingIndex;
        bool startingIndexWasSet;
    }

    /**
     * @notice Arguments to be signed by the mint authority to authorize a mint.
     */
    struct MintArgs {
        uint256 seriesIndex;
        uint256 mintPrice;
        uint256 maxTokenIdExclusive;
        uint256 nonce;
    }

    //---------------- Events ----------------//

    event SetRoyaltyReceiver(
        address royaltyReceiver
    );

    event SetRoyaltyBips(
        uint256 royaltyBips
    );

    event SetSeriesInfo(
        uint256 indexed seriesIndex,
        string name,
        bytes32 provenanceHash
    );

    event AdvancedPoemCreationDeadline(
        uint256 indexed seriesIndex,
        uint256 poemCreationDeadline
    );

    event ResetSeriesStartingIndexBlockNumber(
        uint256 indexed seriesIndex,
        uint256 startingIndexBlockNumber
    );

    event SetSeriesStartingIndex(
        uint256 indexed seriesIndex,
        uint256 startingIndex
    );

    event EndedSeries(
        uint256 indexed seriesIndex,
        uint256 poemCreationDeadline,
        uint256 maxTokenIdExclusive,
        uint256 startingIndexBlockNumber
    );

    event FinishedPoem(
        uint256 indexed tokenId
    );

    //---------------- Functions ----------------//

    function getPoemTraits(
        uint256 tokenId
    )
        external
        view
        returns (IIkaniV2.PoemTraits memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC721ReceiverUpgradeable {
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

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "./Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "./Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
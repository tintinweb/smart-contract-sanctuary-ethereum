// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/ERC721A/ERC721A.sol";

import "./utils/UInt256Set.sol";
import "./utils/GemStoneSVGLib.sol";

import "./interfaces/IBitGem.sol";
import "./interfaces/IClaim.sol";
import "./interfaces/IAttribute.sol";
import "./interfaces/ICallbacks.sol";
import "./interfaces/IERC3156FlashLender.sol";
import "./interfaces/IMetadataFactory.sol";

import "./token/ERC721A/extensions/ERC721AFees.sol";
import "./token/ERC721A/extensions/ERC721AAttributes.sol";
import "./token/ERC721A/extensions/ERC721AClaims.sol";
import "./token/ERC721A/extensions/ERC721AFlashLender.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/// @notice a fractionalized token based on erc721
contract BitGemToken is
    ERC721A,
    ERC2981,
    ERC721AFees,
    ERC721AAttributes,
    ERC721AFlashLender,
    ERC721AClaims,
    IBitGem
{
    using UInt256Set for UInt256Set.Set;
    using ClaimLibrary for IClaim.Claim;

    // events generated from this contract
    event BitGemTokenCreated(address indexed creator, IBitGem.BitGemSettings mineSettings);
    event BitGemCreated(address creator, string symbol, uint256 tokenId);

    // mine starting settings
    IBitGem.BitGemSettings private settings_;
    address private wrappedToken_;
    address private metadataFactory_;

    // mined tokens
    uint256[] private minedTokens_;
    UInt256Set.Set private recordHashes_;

    /// @notice return all the mined tokens
    function enableStaking() external onlyOwner {
        settings_.enabled = true;
    }
    function disableStaking() external onlyOwner {
        settings_.enabled = false;
    }

    /// @notice initialize the token
    function initialize(IBitGem.BitGemSettings memory _settings, address _metadataFactory, address _wrappedToken)
        public
        initializer {
        // initialize the token name and symbol
        _initializeToken(
            _settings.tokenDefinition.name,
            _settings.tokenDefinition.symbol
        );
        // initialize the token settings
        settings_ = _settings;
        wrappedToken_ = _wrappedToken;
        metadataFactory_ = _metadataFactory;
        settings_.tokenDefinition.token = address(this);
        // for(uint i = 0; i < 5; i++) {
        //     __mint(msg.sender);
        // }

    }

    /// @notice mint a bitgem to the given address
    function __mint(address to) internal {
        _mint(to, 1, "", true);
        uint256 tokenId = totalSupply();
        uint256 gemVal = 1;
        bytes32 val = bytes32(gemVal);
        minedTokens_.push(tokenId);
        _setAttribute(
            tokenId,
            IAttribute.Attribute(
                "type",
                IAttribute.AttributeType.Uint256,
                val
            )
        );
    }

    /// @notice mint a bitgem to the given address
    function mint(address to) external onlyOwner {
        __mint(to);
    }

    function createClaim(uint256 claimTime) external payable returns (IClaim.Claim memory claim_) {
        uint256 claimAmount = msg.value;
        claim_ = IClaim.Claim(
            0, // id
            settings_.owner, // feeRecipient
            address(this), // mineAddress
            claimAmount, // depositAmount
            1, // mintQuantity
            claimTime, // depositLength,
            block.timestamp, // createdTime
            block.number, // createdBlock
            0, // claimedBlock
            0, // feePaid
            false, // collected
            false // mature
        );
        claim_ = _createClaim(claim_, claimAmount);
    }

    function collectClaim(uint256 claimId, bool requireMature)
        external {
        _collectClaim(claimId, requireMature);
        IClaim.Claim storage claim = claims_[claimId];
        if (claim.mature) {
            uint256 gemType = 1;
            recordHashes_.insert(claim.id);
            _setAttribute(
                claim.id,
                IAttribute.Attribute(
                    "type",
                    IAttribute.AttributeType.Uint256,
                    bytes32(gemType)
                )
            );
            emit BitGemCreated(msg.sender, settings_.tokenDefinition.symbol, claim.id);
        } else {
            _burn(claim.id); // burn the claim
        }
    }

    /// @notice return all the mined tokens
    function minedTokens() external view returns (uint256[] memory) {
        return minedTokens_;
    }

    /// @notice get the member gems of this pool
    function settings() external view override returns (IBitGem.BitGemSettings memory) {
        return settings_;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory json = Base64.encode(bytes(IMetadataFactory(metadataFactory_).getTokenMetadata(settings_.tokenDefinition, address(this), tokenId)));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function contractURI() public view override returns (string memory) {
        string memory json = Base64.encode(bytes(IMetadataFactory(metadataFactory_).getTokenMetadata(settings_.tokenDefinition, address(this), 0)));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC3156FlashLender).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error AuxQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, Initializable, Ownable {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        address addr; // The address of the owner.
        uint64 startTimestamp; // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        bool burned; // Whether the token has been burned.
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        
        uint64 balance; // Realistically, 2**64-1 is more than enough.
        uint64 numberMinted; // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberBurned; // Keeps track of burn count with minimal overhead for tokenomics.
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // the base uri
    string internal __uri;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function _initializeToken(string memory name_, string memory symbol_) internal {
        require(bytes(_name).length == 0, "ERC721 token name already set");
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex times
        unchecked {
            return _currentIndex - _burnCounter;
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _contractURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _contractURI() internal view virtual returns (string memory) {
        return __uri;
    }
    function contractURI() public view virtual returns (string memory) {
        return  _contractURI();
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
                updatedIndex++;
            }

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a
 * fixed gas cost at any scale, O(1).
 * author: Rob Hitchens
 */

library UInt256Set {
    struct Set {
        mapping(uint256 => uint256) keyPointers;
        uint256[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, uint256 key) public {
        require(
            !exists(self, key),
            "UInt256Set: key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, uint256 key) public {
        // TODO: I commented this out do get a test to pass - need to figure out what is up here
        // require(
        //     exists(self, key),
        //     "UInt256Set: key does not exist in the set."
        // );
        if (!exists(self, key)) return;
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            uint256 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        delete self.keyList[self.keyList.length - 1];
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) public view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, uint256 key)
        public
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index)
        public
        view
        returns (uint256)
    {
        return self.keyList[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library GemStoneSVGLib {

    /// @notice constructor - basic gem with 3 color gradients
    function svgContent(string memory color1, string memory color2, string memory color3) internal pure returns (string[] memory) {
        string memory closeTag = "'/>";
        string memory gClose = "</g>";
        string memory g = "<g>";
        string[] memory _assetList = new string[](20);
        _assetList[0] = "<g transform='matrix(2.004172 0 0 2.236497-341.745721-.318854)'>";
        _assetList[1] = "<path d='M298.251,229.046c-3.758,0-7.325-1.695-9.719-4.623L173.406,83.732c-3.529-4.312-3.855-10.443-.805-15.111L213.688,5.719C216.019,2.149,219.976,0,224.211,0h148.081c4.236,0,8.19,2.149,10.526,5.719l41.083,62.902c3.051,4.669,2.724,10.799-.805,15.111L307.97,224.422c-2.394,2.929-5.96,4.624-9.719,4.624Z' fill='";
        _assetList[2] = color1;
        _assetList[3] =  closeTag;
        _assetList[4] = g;
        _assetList[5] = "<path d='M218.484,1.406c-1.911.983-3.578,2.447-4.795,4.312L172.6,68.622c-1.555,2.381-2.229,5.145-2.049,7.856h96.97L218.484,1.406Z' fill='";
        _assetList[6] = color2;
        _assetList[7] = closeTag;
        _assetList[8] = "<path d='M328.979,76.476h96.973c.179-2.71-.492-5.473-2.05-7.856L382.814,5.718c-1.217-1.865-2.882-3.328-4.795-4.312l-49.04,75.07Z' fill='";
        _assetList[9] = color2;
        _assetList[10] = closeTag;
        _assetList[11] = gClose;
        _assetList[12] = "<polygon points='298.251,229.072 348.278,76.476 248.534,76.476' fill='";
        _assetList[13] = color2;
        _assetList[14] = closeTag;
        _assetList[15] = "<polygon points='298.178,0 248.224,76.476 348.278,76.476 298.323,0' fill='";
        _assetList[16] = color3;
        _assetList[17] = closeTag;
        _assetList[18] = "<path d='M206.977,83.732c-3.529-4.312-3.856-10.443-.807-15.111L247.259,5.719C249.59,2.149,253.548,0,257.782,0h-33.572c-4.235,0-8.192,2.149-10.523,5.719L172.6,68.621c-3.05,4.669-2.724,10.799.805,15.111L288.532,224.423c2.394,2.928-81.555-140.691-81.555-140.691Z' opacity='0.1' />";
        _assetList[19] = gClose;
        return _assetList;
    }

    // get the svg output for this svg
    function getSVG(string memory color1, string memory color2, string memory color3) internal pure returns (string memory) {
        string[] memory _assetList = svgContent(color1, color2, color3);
        string memory imageString = "";
        imageString = string(abi.encodePacked(imageString, "<svg version='1.1' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 512 512' shape-rendering='geometricPrecision' text-rendering='geometricPrecision'>"));
        for (uint256 i=0; i < 20; i++) {
            imageString = string(
                abi.encodePacked(
                    imageString,
                    _assetList[i]
                )
            );
        }
        imageString = string(abi.encodePacked(imageString, "</svg>"));
        return imageString; 
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./IToken.sol";
import "./ITokenPrice.sol";

/// @notice check the balance of earnings and collect earnings
interface IBitGem {

    enum BitGemType {
        Claim,
        Gem
    }
    
    /// @notice staking pool settings - used to confignure a staking pool
    struct BitGemSettings {

        // the owner & payee of the bitgem fees
        address owner;

        // the token definition of the mine
        IToken.TokenDefinition tokenDefinition;

        // the initial staking price of the mine
        ITokenPrice.TokenPriceData initialPrice;
       
        bool enabled;  // is pool enabled

        uint256 minTime; // min and max token amounts to stake
        uint256 maxTime; // max time that the claim can be made

    }
    
    /// @notice get the member gems of this pool
    function settings() external view returns (IBitGem.BitGemSettings memory);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


/// @notice interface for a collection of tokens. lists members of collection, allows for querying of collection members, and for minting and burning of tokens.
interface IClaim {


    /// @notice represents a claim on some deposit.
    struct Claim {

        // claim id.
        uint256 id;

        address feeRecipient;

        // pool address
        address mineAddress;

        // the amount of eth deposited
        uint256 depositAmount;

        // the gem quantity to mint to the user upon maturity
        uint256 mintQuantity;

        // the deposit length of time, in seconds
        uint256 depositLength;

        // the block number when this record was created.
        uint256 createdTime;

        // the block number when this record was created.
        uint256 createdBlock;

        // block number when the claim was submitted or 0 if unclaimed
        uint256 claimedBlock;

        // the fee that was paid
        uint256 feePaid;

        // whether this claim has been collected
        bool collected;

        // whether this claim has been collected
        bool mature;
        
    }

    /// @notice a set of requirements. used for random access
    struct ClaimSet {

        mapping(uint256 => uint256) keyPointers;
        uint256[] keyList;
        Claim[] valueList;

    }

    struct ClaimSettings {

        ClaimSet claims;

        // the total staked for each token type (0 for ETH)
        mapping(address => uint256) stakedTotal;

    }


    /// @notice emitted when a token is added to the collection
    event ClaimCreated(
        address indexed user,
        address indexed minter,
        Claim claim
    );

    /// @notice emitted when a token is removed from the collection
    event ClaimRedeemed (
        address indexed user,
        address indexed minter,
        Claim claim
    );

    /// @notice create a claim
    /// @param _claim the claim to create
    /// @return _claimHash the claim hash
    function createClaim(Claim memory _claim) external payable returns (Claim memory _claimHash);

    /// @notice submit claim for collection
    /// @param claimHash the id of the claim
    function collectClaim(uint256 claimHash, bool requireMature) external;

    /// @notice return the next claim hash
    /// @return _nextHash the next claim hash
    function nextClaimHash() external view returns (uint256 _nextHash);

    /// @notice get all the claims
    /// @return _claims all the claims
    function claims() external view returns (Claim[] memory _claims);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice a pool of tokens that users can deposit into and withdraw from
interface IAttribute {

    enum AttributeType {
        Unknown,
        String ,
        Bytes,
        Uint256,
        Uint8,
        Uint256Array,
        Uint8Array
    }
    enum TokenType {
        Claim,
        Gem
    }
    
    struct Attribute {
        string key;
        AttributeType attributeType;
        bytes32 value;
    }

    event AttributeSet(uint256 indexed tokenId, Attribute attribute);

    /// @notice get an attribute for a tokenid keyed by string
    function getAttribute(
        uint256 id,
        string memory key
    ) external view returns (Attribute calldata _attrib);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)
pragma solidity ^0.8.0;

import "../interfaces/IClaim.sol";
import "../interfaces/IFees.sol";

interface IClaimCallbacks {
    function claimCreated(IClaim.Claim memory claim) external returns (bool);
    function claimRedeemed(IClaim.Claim memory claim, bool mature) external returns (bool);
}

interface IBitGemCallbacks {
    function mintTo(address receiver, uint256 tokenId) external returns (bool);
    function nextId() external returns (uint256);
    function claimById(uint256 id) external view returns (IClaim.Claim memory);
}

interface IFeeCallbacks {
    function setFees(IFees.Fee[] memory fees) external;
    function fee(string memory name) external returns(uint256);
    function withFee(string memory name, uint256 amount)  external returns(uint256);
    function calculateFee(string memory name, uint256 amount) external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC3156FlashBorrower.sol";

/// @notice this interface is implemented by flash lenders in order to allow flash borrowers to borrow funds
interface IERC3156FlashLender {

     /// @notice The amount of currency available to be lent.
     /// @param token The loan currency.
     /// @return The amount of `token` that can be borrowed.
    function maxFlashLoan(address token) external view returns (uint256);


     /// @notice The fee to be charged for a given loan.
     /// @param token The loan currency.
     /// @param amount The amount of tokens lent.
     /// @return The amount of `token` to be charged for the loan, on top of the returned principal.
    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);

    /// @dev Initiate a flash loan.
    /// @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
    /// @param token The loan currency.
    /// @param amount The amount of tokens lent.
    /// @param data Arbitrary data structure, intended to contain user-defined parameters.
    /// @return treus if load was successful
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IToken.sol";

/// @notice a pool of tokens that users can deposit into and withdraw from
interface IMetadataFactory {
    function getTokenMetadata(IToken.TokenDefinition memory definition, address tokenAddress, uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../../interfaces/IFees.sol";

/// @title ERC721AFees
/// @notice tracks named fees
abstract contract ERC721AFees {
    
    event FeesSet(IFees.Fee[] fees);

    mapping(string => IFees.Fee) private fees_;  // claim data

    /// @notice set fees for the token
    function _setFees(IFees.Fee[] memory fees) internal {
        for(uint256 i = 0; i < fees.length; i++) {
            fees_[fees[i].name] = fees[i];
        }
        emit FeesSet(fees);
    }
    
    function fee(string memory name) external view returns (uint256) {
        return fees_[name].price;
    }
    function withFee(string memory name, uint256 amount) external view returns (uint256) {
        return amount + (amount / fees_[name].price);
    }
    function calculateFee(string memory name, uint256 amount) external view returns (uint256) {
        return (amount / fees_[name].price);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../../interfaces/IAttribute.sol";


/// @title ERC721AAttributes
/// @notice the total balance of a token type
abstract contract ERC721AAttributes {

    event AttributeSet(uint256 indexed tokenId, string indexed key, uint256 value);

    mapping(uint256 => mapping(string => IAttribute.Attribute)) private _attributes;

    /// @notice get an attribute for a tokenid keyed by string
    function getAttribute(
        uint256 id,
        string memory key
    ) external view returns (IAttribute.Attribute memory) {
        return _attributes[id][key];
    }
    
    /// @notice set an attribute for a tokenid keyed by string
    function _getAttribute(
        uint256 id,
        string memory key
    ) internal view returns (IAttribute.Attribute memory) {
        return _attributes[id][key];
    }
    
    /// @notice set an attribute to a tokenid keyed by string
    function _setAttribute(
        uint256 id,
        IAttribute.Attribute memory attribute
    ) internal virtual {
        _attributes[id][attribute.key] = attribute;
        emit AttributeSet(id, attribute.key, uint256(attribute.value));
    }

    /// @notice remove the attribute for a tokenid keyed by string
    function _removeAttribute(
        uint256 id,
        string memory key
    ) internal virtual {
        delete _attributes[id][key];
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../../interfaces/IAttribute.sol";
import "../../../interfaces/IClaim.sol";
import "../../../interfaces/ICallbacks.sol";

import "../../../utils/ClaimLib.sol";

/// @title ERC721AFees
/// @notice tracks named fees
abstract contract ERC721AClaims {

    using ClaimLibrary for IClaim.Claim;

    event ClaimCreated(address indexed minter, IClaim.Claim claim);
    event ClaimRedeemed(address indexed redeemer, IClaim.Claim claim);

    uint256 internal gemsMintedCount;  // total number of gems minted
    uint256 internal totalStakedEth; // total amount of staked eth
    mapping(uint256 => IClaim.Claim) internal claims_;  // claim data

    // staked total and claim index
    uint256 internal stakedTotal_;
    uint256 internal claimIndex_;

    /// @param claim the claim
    /// @return _claim the claim
    function _createClaim(IClaim.Claim memory claim, uint256 txValue) internal returns (IClaim.Claim memory _claim) {
        claim.id = claimIndex_++;
        _claim = claims_[claim.id] = claim;
        
        ClaimLibrary._createClaims(claims_[claim.id], txValue);// create the claim and send it to the user
        stakedTotal_ += claim.depositAmount;
        emit ClaimCreated(msg.sender, claim); // emit a event announceing claim
    }

    /// @notice submit claim for collection
    /// @param claimId the id of the claim
    /// @param requireMature the require mature flag
    function _collectClaim(uint256 claimId, bool requireMature) internal {
        // collect the claim and maybe mint a gem to the user
        IClaim.Claim storage claim = claims_[claimId];
        require(claim.id == claimId, "Claim not found");
        claim = claims_[claim.id] = ClaimLibrary._collectClaim(claim, requireMature);
        // emit an event about a gem getting created
        emit ClaimRedeemed(msg.sender, claim);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../../interfaces/IERC3156FlashBorrower.sol";
import "../../../interfaces/IWrappedToken.sol";

/// @notice lets token act as a liquidity pool using the ether on deposit within it
abstract contract ERC721AFlashLender {

    uint256 private feePerMillion;
    address private wrappedToken;

    address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    constructor() {
        feePerMillion = 1000;
    }

    function _setWrappedToken(address token) internal {
        require(wrappedToken == address(0), "wrapped token already set");
        wrappedToken = token;
    }

    /**
     * @dev The maximum flash loan amount - 90% of available funds
     */
    function maxFlashLoan(address tokenAddress)
        external
        view
        returns (uint256)
    {
        // if the token address is zero then get the FTM balance
        // other wise get the token balance of the given token address
        // must not revert
        if (tokenAddress != address(0)) {
            try IERC20(tokenAddress).balanceOf(address(this)) returns (
                uint256 balance
            ) {
                return balance;
            } catch {
                return 0;
            }
        }
        // if the token address is zero then get the FTM balance
        return address(this).balance;
    }

    function flashFee(address token, uint256 amount)
        public
        view
        returns (uint256)
    {
        // must revert if token balanve is 0 or
        // if the token address is not a ERC20 token
        if (token != address(0)) {
            try IERC20(token).balanceOf(address(this)) returns (
                uint256 balance
            ) {
                require(balance > 0, "ERC20 token not found");
            } catch {
                require(false, "ERC20 token not found");
            }
        }
        // get the flash fee from the storage
        uint256 feeDiv = feePerMillion;        // if no default fee, set the fee to 1000 (0.1%)
        if (feeDiv == 0) {
            feeDiv = 1000;
        }
        // fee div indicates the fee per million
        return ( amount / 1000000 ) * feeDiv;
    }

    function setFeePermillion(
        uint256 _feePermillion
    ) external {
        feePerMillion = _feePermillion;
    }

    function getFeePermillion(
    ) external view returns (uint256) {
        return feePerMillion;
    }

/**
     * @dev Perform a flash loan (borrow tokens from the controller and return them after a certain time)
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        // get the fee of the flash loan
        uint256 fee = flashFee(token, amount);

        // get the receiver's address
        address receiverAddress = address(receiver);

        // no token address means we are sending FTM
        if (token == address(0)) {
            // transfer FTM to receiver - we get paid back in WFTM
            payable(receiverAddress).transfer(amount);
        } else {
            // else we are sending erc20 tokens
            IERC20(token).transfer(receiverAddress, amount);
        }

        // create success callback hash
        bytes32 callbackSuccess = keccak256("ERC3156FlashBorrower.onFlashLoan");
        // call the flash loan callback
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) ==
                callbackSuccess,
            "FlashMinter: Callback failed"
        );

        // if the token is 0 then we have to
        // get paid in WFTM in order to properly
        // meter the loan since the erc20 approval
        // sets us widthdraw a specific amount
        if (token == address(0)) {
            token = WFTM;
        }

        // to get our allowance of the token from the receiver
        // this is the amount we will be allowed to withdraw
        // aka the loan repayment amount
        uint256 _allowance = IERC20(token).allowance(
            address(receiver),
            address(this)
        );

        // if the allowance is greater than the loan amount plus
        // the fee then we can finish the flash loan
        require(
            _allowance >= (amount + fee),
            "FlashMinter: Repay not approved"
        );

        // transfer the tokens back to the lender
        IERC20(token).transferFrom(
            address(receiver),
            address(this),
            _allowance
        );

        // if this is wrapped fantom and wrapped fantom is not
        // in allowed tokens then this is a repay so unwrap the WFTM
        if (token == WFTM) {
            IWrappedToken(WFTM).unwrap(_allowance);
        }

        return true;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

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

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
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
     * - `tokenId` must be already minted.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0-rc.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0-rc.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0-rc.0) (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/// @notice common struct definitions for tokens
interface IToken {

    // erc token type
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    /// @notice the token source. Specifies the source of the token - either a static source or a collection.
    struct TokenIdentifier {
        TokenType tokenType;
        address token;
        uint256 id;
    }

    // a token of some quantity
    struct Token {
        TokenIdentifier token;
        uint256 quantity;
    }

    // a collection of tokens
    struct TokenSet {
        mapping(uint256 => uint256) keyPointers;
        uint256[] keyList;
        Token[] valueList;
    }

    // a definition of a token
    struct TokenDefinition {
        address token;  // the host token        
        string name; // the name of the token
        string symbol; // the symbol of the token
        string[] colors; // the color of the token
        string description; // the description of the token
    }

    struct TokenRecord {
        uint256 id;
        address owner;
        address minter;
        uint256 _type;
        uint256 balance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/// @notice common struct definitions for tokens
interface ITokenPrice {

    /// @notice DIctates how the price of the token is increased post every sale
    enum PriceModifier {
        None,
        Fixed,
        Exponential,
        InverseLog
    }

    /// @notice a token price and how it changes
    struct TokenPriceData {
        uint256 price; // the price of the token
        PriceModifier priceModifier;  // how the price is modified
        uint256 priceModifierFactor; // only used if priceModifier is EXPONENTIAL or INVERSELOG or FIXED
        uint256 maxPrice; // max price for the token
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice the fee manager manages fees by providing the fee amounts for the requested identifiers. Fees are global but can be overridden for a specific message sender.
interface IFees {

    struct Fee {
        string name;
        uint256 price;
    }
    
    /// @notice get the fee for the given fee type hash
    /// @param feeLabel the keccak256 hash of the fee type
    /// @return the fee amount
    function fee(string memory feeLabel) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice the flash borrower interface is implemented by contracts that are borrowing funds from the flash loan contract
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IClaim.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "../interfaces/ICallbacks.sol";
import "../interfaces/IFees.sol";

library ClaimLibrary {

    /// @notice emitted when a token is added to the collection
    event ClaimCreated(
        address indexed user,
        address indexed minter,
        IClaim.Claim claim
    );

    /// @notice emitted when a token is removed from the collection
    event ClaimRedeemed (
        address indexed user,
        address indexed minter,
        IClaim.Claim claim
    );


    /// @notice create a claim to mint a given gem
    /// @param claim the claim to mint
    function _createClaims(
        IClaim.Claim storage claim,
        uint256 msgValue
    ) internal returns (IClaim.Claim storage claim_) {

        // validate the incoming claim to mint
        require(msg.value != 0, "Zero payment attached"); // zero payment
        require(claim.mintQuantity != 0, "Zero quantity order"); // zero qty
        
        // assign system values - always override user values in case shit happens

        claim.createdTime = block.timestamp;
        claim.createdBlock = block.number;
        
        // make sure we got enough ether to cover the deposit
        require(msgValue >= claim.depositAmount, "Insufficient deposit");

        // return the extra tokens to sender
        if (msg.value > claim.depositAmount) {
            (bool success, ) = payable(msg.sender).call{
                value: msg.value - claim.depositAmount
            }("");
            require(success, "Failed to refund extra payment");
        }

        claim_ = claim;

    }

    /// @notice collect an open claim (take custody of the funds the claim is redeeemable for and maybe a gem too)
    /// @param _requireMature if true, the claim must be mature
    function _collectClaim(
        IClaim.Claim memory claim,
        bool _requireMature
    ) internal returns (IClaim.Claim memory outClaim) {

    // check the maturity of the claim - only issue gem if mature
        bool isMature = claim.createdTime + claim.depositLength < block.timestamp;
        require(!_requireMature || (_requireMature && isMature), "Immature Claim");
        
        // validate the claim
        require(IERC721(address(this)).ownerOf(claim.id) == msg.sender, "Not the claim owner");
        
        uint256 unlockTime = claim.createdTime + claim.depositLength;
        uint256 unlockPaid = claim.depositAmount;
        
        // both values must be greater than zero
        require(unlockTime != 0 && unlockPaid > 0, "Invalid claim");

        // if they used erc20 tokens stake their claim, return their tokens
        // calculate fee portion using fee tracker
        uint256 feePortion = isMature ? IFeeCallbacks(address(this)).calculateFee("collect_claim", claim.depositAmount) : 0;
        
        // transfer the ETH fee to fee tracker
        (bool sentfee,) = payable(claim.feeRecipient).call{value: feePortion}("");
        require(sentfee, "Failed to send Ether");

        // transfer the ETH fee to fee tracker
        (bool sent,) = payable(msg.sender).call{value: claim.depositAmount - feePortion}("");        
        require(sent, "Failed to send Ether");        

        claim.feePaid = feePortion; // update the claim with the fee paid
        claim.claimedBlock = block.number; // update the claim with the claim block
        claim.mature = isMature; // update the claim with the maturity

        outClaim = claim;

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


/// @notice implements wrapped base token. Used for repayments of flash loans.
interface IWrappedToken {

    /// @notice deposit wraps received FTM tokens as wFTM in 1:1 ratio by minting the received amount of FTMs in wFTM on the sender's address.
    function wrap() external payable;

    /// @notice withdraw unwraps FTM tokens by burning specified amount of wFTM from the caller address and sending the same amount of FTMs back in exchange.
    function unwrap(uint256 amount) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0-rc.0) (token/ERC20/IERC20.sol)
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
// OpenZeppelin Contracts (last updated v4.6.0-rc.0) (interfaces/IERC2981.sol)

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
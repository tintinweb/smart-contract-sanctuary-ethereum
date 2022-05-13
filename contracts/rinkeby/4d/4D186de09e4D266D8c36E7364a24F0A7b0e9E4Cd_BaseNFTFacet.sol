// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ERC721AFacet, ERC721ALib} from "./ERC721A/ERC721AFacet.sol";
import {Strings} from "./ERC721A/ERC721ALib.sol";
import {AccessControlFacet} from "./AccessControl/AccessControlFacet.sol";
import {AccessControlModifiers, AccessControlLib} from "./AccessControl/AccessControlModifiers.sol";
import {BaseNFTLib} from "./BaseNFTLib.sol";
import {SaleStateModifiers} from "./BaseNFTModifiers.sol";
import {URIStorageLib} from "./URIStorage/URIStorageLib.sol";
import {PaymentSplitterFacet} from "./PaymentSplitter/PaymentSplitterFacet.sol";
import {RoyaltyStandardFacet} from "./RoyaltyStandard/RoyaltyStandardFacet.sol";

// Inherit from other facets in the BaseNFTFacet
// Why inherit to one facet instead of deploying Each Facet Separately?
// Because its cheaper for end customers to just store / cut one facet address

contract BaseNFTFacet is SaleStateModifiers, AccessControlModifiers, AccessControlFacet, ERC721AFacet, PaymentSplitterFacet, RoyaltyStandardFacet {
    using Strings for uint256;

    function init() external {
        require(AccessControlLib.owner() == address(0), "Already initialized");
        AccessControlLib._transferOwnership(msg.sender);
    }

    function setTokenMeta(
        string memory _name,
        string memory _symbol,
        uint256 _startIndex
    ) public onlyOwner {
        ERC721ALib.ERC721AStorage storage s = ERC721ALib.erc721AStorage();
        s._name = _name;
        s._symbol = _symbol;

        if (s._currentIndex == 0 && _startIndex != 0) {
            s._startIndex = _startIndex;
            s._currentIndex = _startIndex;
        }
    }

    function setMaxSupply(uint256 _maxSupply) public onlyAdmin {
        return BaseNFTLib.setMaxSupply(_maxSupply);
    }

    function maxSupply() public view returns (uint256) {
        return BaseNFTLib.maxSupply();
    }

    function setMintPrice(uint256 _mintPrice) public onlyAdmin {
        BaseNFTLib.setMintPrice(_mintPrice);
    }

    function mintPrice() public view {
        BaseNFTLib.mintPrice();
    }

    function publicMint(uint256 quantity) public payable onlyAtSaleState(1) {
        require(msg.value >= quantity * BaseNFTLib.mintPrice(), "Insufficient funds to mint");
        BaseNFTLib._safeMint(msg.sender, quantity);
    }

    function devMint(address to, uint256 quantity) public payable onlyOwner {
        BaseNFTLib._safeMint(to, quantity);
    }

    function saleState() public view returns (uint256) {
        return BaseNFTLib.saleState();
    }

    function setSaleState(uint256 _saleState) public onlyAdmin {
        BaseNFTLib.setSaleState(_saleState);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        BaseNFTLib.setBaseURI(_baseURI);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert("Cannot Query tokenURI for non-existant tokenId");
        string storage tokenURIFromStorage = URIStorageLib.tokenURIFromStorage(tokenId);
        string storage baseURI = BaseNFTLib.baseNFTStorage().baseURI;
        // check first for URIStorage
        // then fall back on baseURI + tokenId
        return
            bytes(tokenURIFromStorage).length != 0 ? tokenURIFromStorage : bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721ALib.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at ERC721ALib._startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
abstract contract ERC721AFacet is IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        return ERC721ALib.totalSupply();
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to ERC721ALib._startTokenId()
        unchecked {
            return ERC721ALib.erc721AStorage()._currentIndex - ERC721ALib._startTokenId();
        }
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(ERC721ALib.erc721AStorage()._addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(ERC721ALib.erc721AStorage()._addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(ERC721ALib.erc721AStorage()._addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return ERC721ALib.erc721AStorage()._addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        ERC721ALib.erc721AStorage()._addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (ERC721ALib.TokenOwnership memory) {
        uint256 curr = tokenId;

        ERC721ALib.ERC721AStorage storage s = ERC721ALib.erc721AStorage();
        unchecked {
            if (ERC721ALib._startTokenId() <= curr && curr < s._currentIndex) {
                ERC721ALib.TokenOwnership memory ownership = s._ownerships[curr];
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
                        ownership = s._ownerships[curr];
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
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return ERC721ALib.erc721AStorage()._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC721ALib.erc721AStorage()._symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721AFacet.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return ERC721ALib.erc721AStorage()._tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == msg.sender) revert ApproveToCaller();

        ERC721ALib.erc721AStorage()._operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return ERC721ALib.erc721AStorage()._operatorApprovals[owner][operator];
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
        if (to.isContract() && !ERC721ALib._checkContractOnERC721Received(from, to, tokenId, _data)) {
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
        return
            ERC721ALib._startTokenId() <= tokenId &&
            tokenId < ERC721ALib.erc721AStorage()._currentIndex &&
            !ERC721ALib.erc721AStorage()._ownerships[tokenId].burned;
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
        ERC721ALib.ERC721AStorage storage s = ERC721ALib.erc721AStorage();
        ERC721ALib.TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (msg.sender == from || isApprovedForAll(from, msg.sender) || getApproved(tokenId) == msg.sender);

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        TransferHooksLib.beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            s._addressData[from].balance -= 1;
            s._addressData[to].balance += 1;

            ERC721ALib.TokenOwnership storage currSlot = s._ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            ERC721ALib.TokenOwnership storage nextSlot = s._ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != s._currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        TransferHooksLib.afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        ERC721ALib.TokenOwnership memory prevOwnership = _ownershipOf(tokenId);
        ERC721ALib.ERC721AStorage storage s = ERC721ALib.erc721AStorage();

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (msg.sender == from || isApprovedForAll(from, msg.sender) || getApproved(tokenId) == msg.sender);

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        TransferHooksLib.beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            ERC721ALib.AddressData storage addressData = s._addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            ERC721ALib.TokenOwnership storage currSlot = s._ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            ERC721ALib.TokenOwnership storage nextSlot = s._ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != s._currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        TransferHooksLib.afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            s._burnCounter++;
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
        ERC721ALib.erc721AStorage()._tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../interfaces/IERC721Metadata.sol";
import {TransferHooksLib} from "../TransferHooks/TransferHooksLib.sol";

pragma solidity ^0.8.4;

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

library ERC721ALib {
    using Address for address;
    using Strings for uint256;

    bytes32 constant ERC721A_STORAGE_POSITION = keccak256("erc721a.facet.storage");

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    struct ERC721AStorage {
        // The tokenId of the next token to be minted.
        uint256 _currentIndex;
        // The number of tokens burned.
        uint256 _burnCounter;
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // start index
        uint256 _startIndex;
        // Mapping from token ID to ownership details
        // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
        mapping(uint256 => TokenOwnership) _ownerships;
        // Mapping owner address to address data
        mapping(address => AddressData) _addressData;
        // Mapping from token ID to approved address
        mapping(uint256 => address) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    function erc721AStorage() internal pure returns (ERC721AStorage storage es) {
        bytes32 position = ERC721A_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
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
        ERC721ALib.ERC721AStorage storage s = ERC721ALib.erc721AStorage();

        uint256 startTokenId = s._currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        TransferHooksLib.beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            s._addressData[to].balance += uint64(quantity);
            s._addressData[to].numberMinted += uint64(quantity);

            s._ownerships[startTokenId].addr = to;
            s._ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (s._currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            s._currentIndex = updatedIndex;
        }
        TransferHooksLib.afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
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
    }

    function totalSupply() internal view returns (uint256) {
        ERC721AStorage storage s = ERC721ALib.erc721AStorage();
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return s._currentIndex - s._burnCounter - _startTokenId();
        }
    }

    function _startTokenId() internal view returns (uint256) {
        return erc721AStorage()._startIndex;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./AccessControlLib.sol";

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
abstract contract AccessControlFacet is Context {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return AccessControlLib.accessControlStorage()._owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual {
        AccessControlLib._enforceOwner();
        AccessControlLib._transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        AccessControlLib._enforceOwner();
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        AccessControlLib._transferOwnership(newOwner);
    }

    function setAdmin(address _admin, bool isAdmin) public virtual {
        AccessControlLib._enforceOwner();
        AccessControlLib.accessControlStorage()._admins[_admin] = isAdmin;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlLib.sol";

abstract contract AccessControlModifiers {
    modifier onlyAdmin() {
        AccessControlLib._enforceAdmin();
        _;
    }

    modifier onlyOwner() {
        AccessControlLib._enforceOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ERC721ALib} from "./ERC721A/ERC721ALib.sol";

library BaseNFTLib {
    struct BaseNFTStorage {
        uint256 maxSupply;
        bool maxSupplyLocked;
        uint256 mintPrice;
        uint256 saleState;
        string baseURI;
    }

    function baseNFTStorage() internal pure returns (BaseNFTStorage storage es) {
        bytes32 position = keccak256("base.nft.storage");
        assembly {
            es.slot := position
        }
    }

    function maxSupply() internal view returns (uint256) {
        return baseNFTStorage().maxSupply;
    }

    function setMaxSupply(uint256 _maxSupply) internal {
        require(_maxSupply <= ERC721ALib.totalSupply(), "Cannot set max supply less than total supply");
        require(!baseNFTStorage().maxSupplyLocked, "Max supply has been locked");

        baseNFTStorage().maxSupply = _maxSupply;
    }

    function setMintPrice(uint256 _mintPrice) internal {
        baseNFTStorage().mintPrice = _mintPrice;
    }

    function mintPrice() internal view returns (uint256) {
        return baseNFTStorage().mintPrice;
    }

    function _safeMint(address to, uint256 quantity) internal {
        uint256 max = baseNFTStorage().maxSupply;
        require(max == 0 || max > (ERC721ALib.totalSupply() + quantity), "Mint exceeds max supply");
        ERC721ALib._safeMint(to, quantity);
    }

    function saleState() internal view returns (uint256) {
        return baseNFTStorage().saleState;
    }

    function setSaleState(uint256 _saleState) internal {
        baseNFTStorage().saleState = _saleState;
    }

    function setBaseURI(string memory _baseURI) internal {
        baseNFTStorage().baseURI = _baseURI;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {BaseNFTLib} from "./BaseNFTLib.sol";

// sale states
// 0 - closed
// 1 - public sale
// 2 - allow list sale

abstract contract SaleStateModifiers {
    modifier onlyAtSaleState(uint256 _gatedSaleState) {
        require(_gatedSaleState == BaseNFTLib.saleState(), "Cannot make call with current sale state");
        _;
    }

    modifier onlyAtOneOfSaleStates(uint256[] calldata _gatedSaleStates) {
        uint256 currState = BaseNFTLib.saleState();
        for (uint256 i; i < _gatedSaleStates.length; i++) {
            if (_gatedSaleStates[i] == currState) {
                _;
                return;
            }
        }

        revert("Cannot make call with current sale state");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library URIStorageLib {
    struct URIStorage {
        mapping(uint256 => string) _tokenURIs;
    }

    function uriStorage() internal pure returns (URIStorage storage s) {
        bytes32 position = keccak256("uri.storage.facet.storage");
        assembly {
            s.slot := position
        }
    }

    function tokenURIFromStorage(uint256 tokenId) internal view returns (string storage) {
        return uriStorage()._tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        uriStorage()._tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal {
        URIStorage storage s = uriStorage();
        if (bytes(s._tokenURIs[tokenId]).length != 0) {
            delete s._tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PaymentSplitterLib} from "./PaymentSplitterLib.sol";
import {AccessControlModifiers} from "../AccessControl/AccessControlModifiers.sol";

contract PaymentSplitterFacet is AccessControlModifiers {
    function setPaymentSplits(PaymentSplitterLib.SplitInfo[] memory splits) external onlyOwner {
        PaymentSplitterLib.setPaymentSplits(splits);
    }

    function withdraw() external onlyAdmin {
        PaymentSplitterLib.withdraw();
    }

    function paymentSplitterInfo() public view returns (PaymentSplitterLib.SplitInfo[] memory) {
        return PaymentSplitterLib.paymentSplitterInfo();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";

import {AccessControlModifiers} from "../AccessControl/AccessControlModifiers.sol";
import {RoyaltyStandardLib} from "./RoyaltyStandardLib.sol";

contract RoyaltyStandardFacet is IERC2981, AccessControlModifiers {
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256) {
        return RoyaltyStandardLib.royaltyInfo(tokenId, salePrice);
    }

    function setDefaultRoyalty(uint96 feeNumerator) external onlyOwner {
        RoyaltyStandardLib._setDefaultRoyalty(feeNumerator);
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

import "./IERC721.sol";

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
pragma solidity ^0.8.0;

import {DiamondCloneLib} from "../DiamondClone/DiamondCloneLib.sol";
import {DiamondSaw} from "../../DiamondSaw.sol";

library TransferHooksLib {
    struct TransferHooksStorage {
        address beforeTransfersHook;
        address afterTransfersHook;
    }

    function transferHooksStorage() internal pure returns (TransferHooksStorage storage s) {
        bytes32 position = keccak256("transfer.hooks.facet.storage");
        assembly {
            s.slot := position
        }
    }

    function setBeforeTransfersHook(address _beforeTransfersHook) internal {
        address sawAddress = DiamondCloneLib.diamondCloneStorage().diamondSawAddress;
        bool isApproved = DiamondSaw(sawAddress).isTransferHooksContractApproved(_beforeTransfersHook);
        require(isApproved, "before transfer hook contract not approved");
        transferHooksStorage().beforeTransfersHook = _beforeTransfersHook;
    }

    function setAfterTransfersHook(address _afterTransfersHook) internal {
        address sawAddress = DiamondCloneLib.diamondCloneStorage().diamondSawAddress;
        bool isApproved = DiamondSaw(sawAddress).isTransferHooksContractApproved(_afterTransfersHook);
        require(isApproved, "after transfer hook contract not approved");
        transferHooksStorage().afterTransfersHook = _afterTransfersHook;
    }

    function beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal {
        TransferHooksStorage storage s = transferHooksStorage();

        if (s.beforeTransfersHook == address(0)) {
            return;
        }

        (bool success, ) = s.afterTransfersHook.call(
            abi.encodeWithSignature("beforeTokenTransfers(address, address, uint256, uint256)", from, to, startTokenId, quantity)
        );

        require(success, "Before transfer hook failed");
    }

    function afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal {
        TransferHooksStorage storage s = transferHooksStorage();

        if (s.afterTransfersHook == address(0)) {
            return;
        }

        (bool success, ) = s.afterTransfersHook.call(
            abi.encodeWithSignature("afterTokenTransfers(address, address, uint256, uint256)", from, to, startTokenId, quantity)
        );

        require(success, "After transfer hook failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
pragma solidity ^0.8.0;

import {DiamondSaw} from "../../DiamondSaw.sol";
import {IDiamondLoupe} from "./IDiamondLoupe.sol";
import {IDiamondCut} from "./IDiamondCut.sol";

library DiamondCloneLib {
    bytes32 constant DIAMOND_CLONE_STORAGE_POSITION = keccak256("diamond.standard.diamond.clone.storage");

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    struct DiamondCloneStorage {
        // address of the diamond saw contract
        address diamondSawAddress;
        // mapping to all the facets this diamond implements.
        mapping(address => bool) facetAddresses;
        // number of facets supported
        uint256 numFacets;
        // optional gas cache for highly trafficked write selectors
        mapping(bytes4 => address) selectorGasCache;
        // immutability window
        uint256 immutableUntilBlock;
    }

    function diamondCloneStorage() internal pure returns (DiamondCloneStorage storage s) {
        bytes32 position = DIAMOND_CLONE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // calls externally to the saw to find the appropriate facet to delegate to
    function _getFacetAddressForCall() internal returns (address addr) {
        DiamondCloneStorage storage s = diamondCloneStorage();

        addr = s.selectorGasCache[msg.sig];
        if (addr != address(0)) {
            return addr;
        }

        (bool success, bytes memory res) = s.diamondSawAddress.call(abi.encodeWithSelector(0x14bc7560, msg.sig));
        require(success, "Failed to fetch facet address for call");

        assembly {
            addr := mload(add(res, 32))
        }

        return s.facetAddresses[addr] ? addr : address(0);
    }

    function initialCutWithDiamondSaw(
        address diamondSawAddress,
        address[] calldata _facetAddresses,
        address _init, // base facet address
        bytes calldata _calldata // appropriate call data
    ) internal {
        DiamondCloneLib.DiamondCloneStorage storage s = DiamondCloneLib.diamondCloneStorage();

        require(diamondSawAddress != address(0), "Must set saw addy");
        require(s.diamondSawAddress == address(0), "Already inited");

        s.diamondSawAddress = diamondSawAddress;
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](_facetAddresses.length);

        // emit the diamond cut event
        for (uint256 i; i < _facetAddresses.length; i++) {
            address facetAddress = _facetAddresses[i];
            bytes4[] memory selectors = DiamondSaw(diamondSawAddress).functionSelectorsForFacetAddress(facetAddress);
            require(selectors.length > 0, "Facet is not supported by the saw");
            cuts[i].facetAddress = _facetAddresses[i];
            cuts[i].functionSelectors = selectors;
            s.facetAddresses[facetAddress] = true;
        }

        emit DiamondCut(cuts, _init, _calldata);

        // call the init function
        (, bytes memory err) = _init.delegatecall(_calldata);
        if (err.length > 0) {
            revert(string(err));
        }

        s.numFacets = _facetAddresses.length;
    }

    function _purgeGasCache(bytes4[] memory selectors) internal {
        DiamondCloneStorage storage s = diamondCloneStorage();

        for (uint256 i; i < selectors.length; i++) {
            if (s.selectorGasCache[selectors[i]] != address(0)) {
                delete s.selectorGasCache[selectors[i]];
            }
        }
    }

    function cutWithDiamondSaw(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes calldata _calldata
    ) internal {
        DiamondCloneStorage storage s = diamondCloneStorage();

        uint256 newNumFacets = s.numFacets;

        // emit the diamond cut event
        for (uint256 i; i < _diamondCut.length; i++) {
            IDiamondCut.FacetCut memory cut = _diamondCut[i];
            bytes4[] memory selectors = DiamondSaw(s.diamondSawAddress).functionSelectorsForFacetAddress(cut.facetAddress);

            require(selectors.length > 0, "Facet is not supported by the saw");
            require(selectors.length == cut.functionSelectors.length, "You can only modify all selectors at once with diamond saw");

            // NOTE we override the passed selectors after validating the length matches
            // With diamond saw we can only add / remove all selectors for a given facet
            cut.functionSelectors = selectors;

            // if the address is already in the facet map
            // remove it and remove all the selectors
            // otherwise add the selectors
            if (s.facetAddresses[cut.facetAddress]) {
                require(cut.action == IDiamondCut.FacetCutAction.Remove, "Can only remove existing facet selectors");
                delete s.facetAddresses[cut.facetAddress];
                _purgeGasCache(selectors);
                newNumFacets -= 1;
            } else {
                require(cut.action == IDiamondCut.FacetCutAction.Add, "Can only add non-existing facet selectors");
                s.facetAddresses[cut.facetAddress] = true;
                newNumFacets += 1;
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);

        // call the init function
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up the error
                revert(string(error));
            } else {
                revert("DiamondCloneLib: _init function reverted");
            }
        }

        s.numFacets = newNumFacets;
    }

    function upgradeDiamondSaw(
        address[] calldata _oldFacetAddresses,
        address[] calldata _newFacetAddresses,
        address _init,
        bytes calldata _calldata
    ) internal {
        require(!isImmutable(), "Cannot upgrade saw during immutability window");
        DiamondCloneStorage storage s = diamondCloneStorage();
        require(_oldFacetAddresses.length == s.numFacets, "Must remove all facets to upgrade saw");
        DiamondSaw oldSawInstance = DiamondSaw(s.diamondSawAddress);
        address upgradeSawAddress = oldSawInstance.getUpgradeSawAddress();
        DiamondSaw newSawInstance = DiamondSaw(upgradeSawAddress);

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](_oldFacetAddresses.length + _newFacetAddresses.length);

        for (uint256 i; i < _oldFacetAddresses.length + _newFacetAddresses.length; i++) {
            if (i < _oldFacetAddresses.length) {
                address facetAddress = _oldFacetAddresses[i];
                require(s.facetAddresses[facetAddress], "Cannot remove facet that is not supported");
                bytes4[] memory selectors = oldSawInstance.functionSelectorsForFacetAddress(facetAddress);
                require(selectors.length > 0, "Facet is not supported by the saw");

                cuts[i].action = IDiamondCut.FacetCutAction.Remove;
                cuts[i].facetAddress = facetAddress;
                cuts[i].functionSelectors = selectors;

                _purgeGasCache(selectors);
                delete s.facetAddresses[facetAddress];
            } else {
                address facetAddress = _newFacetAddresses[i - _oldFacetAddresses.length];
                bytes4[] memory selectors = newSawInstance.functionSelectorsForFacetAddress(facetAddress);
                require(selectors.length > 0, "Facet is not supported by the saw");

                cuts[i].action = IDiamondCut.FacetCutAction.Add;
                cuts[i].facetAddress = facetAddress;
                cuts[i].functionSelectors = selectors;

                s.facetAddresses[facetAddress] = true;
            }
        }

        emit DiamondCut(cuts, _init, _calldata);

        // call the init function
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up the error
                revert(string(error));
            } else {
                revert("DiamondCloneLib: _init function reverted");
            }
        }

        s.numFacets = _newFacetAddresses.length;
    }

    function setGasCacheForSelector(bytes4 selector) internal {
        DiamondCloneStorage storage s = diamondCloneStorage();

        address facetAddress = DiamondSaw(s.diamondSawAddress).facetAddressForSelector(selector);
        require(facetAddress != address(0), "Facet not supported");

        s.selectorGasCache[selector] = facetAddress;
    }

    function setImmutableUntilBlock(uint256 blockNum) internal {
        diamondCloneStorage().immutableUntilBlock = blockNum;
    }

    function isImmutable() internal view returns (bool) {
        return block.number < diamondCloneStorage().immutableUntilBlock;
    }

    function immutableUntilBlock() internal view returns (uint256) {
        return diamondCloneStorage().immutableUntilBlock;
    }

    /**
     * LOUPE FUNCTIONALITY BELOW
     */

    function facets() internal view returns (IDiamondLoupe.Facet[] memory facets_) {
        DiamondCloneLib.DiamondCloneStorage storage ds = DiamondCloneLib.diamondCloneStorage();
        IDiamondLoupe.Facet[] memory allSawFacets = DiamondSaw(ds.diamondSawAddress).allFacetsWithSelectors();

        uint256 copyIndex = 0;

        facets_ = new IDiamondLoupe.Facet[](ds.numFacets);

        for (uint256 i; i < allSawFacets.length; i++) {
            if (ds.facetAddresses[allSawFacets[i].facetAddress]) {
                facets_[copyIndex] = allSawFacets[i];
                copyIndex++;
            }
        }
    }

    function facetAddresses() internal view returns (address[] memory facetAddresses_) {
        DiamondCloneLib.DiamondCloneStorage storage ds = DiamondCloneLib.diamondCloneStorage();

        address[] memory allSawFacetAddresses = DiamondSaw(ds.diamondSawAddress).allFacetAddresses();
        facetAddresses_ = new address[](ds.numFacets);

        uint256 copyIndex = 0;

        for (uint256 i; i < allSawFacetAddresses.length; i++) {
            if (ds.facetAddresses[allSawFacetAddresses[i]]) {
                facetAddresses_[copyIndex] = allSawFacetAddresses[i];
                copyIndex++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import {IDiamondCut} from "./facets/DiamondClone/IDiamondCut.sol";
import {IDiamondLoupe} from "./facets/DiamondClone/IDiamondLoupe.sol";
import {DiamondSawLib} from "./libraries/DiamondSawLib.sol";
import {AccessControlFacet} from "./facets/AccessControl/AccessControlFacet.sol";
import {AccessControlModifiers} from "./facets/AccessControl/AccessControlModifiers.sol";
import {AccessControlLib} from "./facets/AccessControl/AccessControlLib.sol";

/**
 * DiamondSaw is meant to be used as a
 * Singleton to "cut" many minimal diamond clones
 * In a gas efficient manner for deployments.
 *
 * This is accomplished by handling the storage intensive
 * selector mappings in one contract, "the saw" instead of in each diamond.
 *
 * Adding a new facet to the saw enables new diamond "patterns"
 *
 * This should be used if you
 *
 * 1. Need cheap deployments of many similar cloned diamonds that
 * utilize the same pre-deployed facets
 *
 * 2. Are okay with gas overhead on write txn to the diamonds
 * to communicate with the singleton (saw) to fetch selectors
 *
 */
contract DiamondSaw is AccessControlFacet, AccessControlModifiers {
    constructor() {
        AccessControlLib._transferOwnership(msg.sender);
    }

    function addFacetPattern(
        IDiamondCut.FacetCut[] calldata _facetAdds,
        address _init,
        bytes calldata _calldata
    ) external onlyAdmin {
        DiamondSawLib.diamondCutAddOnly(_facetAdds, _init, _calldata);
    }

    // if a facet has no selectors, it is not supported
    function checkFacetSupported(address _facetAddress) external view {
        DiamondSawLib.checkFacetSupported(_facetAddress);
    }

    function facetAddressForSelector(bytes4 selector) external view returns (address) {
        return DiamondSawLib.diamondSawStorage().selectorToFacetAndPosition[selector].facetAddress;
    }

    function functionSelectorsForFacetAddress(address facetAddress) external view returns (bytes4[] memory) {
        return DiamondSawLib.diamondSawStorage().facetFunctionSelectors[facetAddress].functionSelectors;
    }

    function allFacetAddresses() external view returns (address[] memory) {
        return DiamondSawLib.diamondSawStorage().facetAddresses;
    }

    function allFacetsWithSelectors() external view returns (IDiamondLoupe.Facet[] memory _facetsWithSelectors) {
        DiamondSawLib.DiamondSawStorage storage ds = DiamondSawLib.diamondSawStorage();

        uint256 numFacets = ds.facetAddresses.length;
        _facetsWithSelectors = new IDiamondLoupe.Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];
            _facetsWithSelectors[i].facetAddress = facetAddress_;
            _facetsWithSelectors[i].functionSelectors = ds.facetFunctionSelectors[facetAddress_].functionSelectors;
        }
    }

    function facetAddressForInterface(bytes4 _interface) external view returns (address) {
        DiamondSawLib.DiamondSawStorage storage ds = DiamondSawLib.diamondSawStorage();
        return ds.interfaceToFacet[_interface];
    }

    function setFacetForERC165Interface(bytes4 _interface, address _facet) external onlyAdmin {
        DiamondSawLib.checkFacetSupported(_facet);
        DiamondSawLib.diamondSawStorage().interfaceToFacet[_interface] = _facet;
    }

    function setTransferHooksContractApproved(address tokenTransferHookContract, bool approved) external onlyOwner {
        DiamondSawLib.setTransferHooksContractApproved(tokenTransferHookContract, approved);
    }

    function isTransferHooksContractApproved(address tokenTransferHookContract) external view returns (bool) {
        return DiamondSawLib.diamondSawStorage().approvedTransferHooksContracts[tokenTransferHookContract];
    }

    function setUpgradeSawAddress(address _upgradeSaw) external onlyOwner {
        DiamondSawLib.setUpgradeSawAddress(_upgradeSaw);
    }

    function getUpgradeSawAddress() external view returns (address) {
        return DiamondSawLib.diamondSawStorage().upgradeSawAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
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
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../facets/DiamondClone/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library DiamondSawLib {
    bytes32 constant DIAMOND_SAW_STORAGE_POSITION = keccak256("diamond.standard.diamond.saw.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondSawStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a facet implements a given interface
        // Note: this works because no interface can be implemented by
        // two different facets with diamond saw because no
        // selector overlap is permitted!!
        mapping(bytes4 => address) interfaceToFacet;
        // for transfer hooks, contracts must be approved in the saw
        mapping(address => bool) approvedTransferHooksContracts;
        // the next saw contract to upgrade to
        address upgradeSawAddress;
    }

    function diamondSawStorage() internal pure returns (DiamondSawStorage storage ds) {
        bytes32 position = DIAMOND_SAW_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    // only supports adding new selectors
    function diamondCutAddOnly(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            require(_diamondCut[facetIndex].action == IDiamondCut.FacetCutAction.Add, "Only add action supported in saw");
            require(!isFacetSupported(_diamondCut[facetIndex].facetAddress), "Facet already exists in saw");
            addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondSawStorage storage ds = diamondSawStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;

            require(oldFacetAddress == address(0), "Cannot add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function addFacet(DiamondSawStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondSawStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function setFacetSupportsInterface(bytes4 _interface, address _facetAddress) internal {
        checkFacetSupported(_facetAddress);
        DiamondSawStorage storage ds = diamondSawStorage();
        ds.interfaceToFacet[_interface] = _facetAddress;
    }

    function isFacetSupported(address _facetAddress) internal view returns (bool) {
        return diamondSawStorage().facetFunctionSelectors[_facetAddress].functionSelectors.length > 0;
    }

    function checkFacetSupported(address _facetAddress) internal view {
        require(isFacetSupported(_facetAddress), "Facet not supported");
    }

    function setTransferHooksContractApproved(address hookContract, bool approved) internal {
        diamondSawStorage().approvedTransferHooksContracts[hookContract] = approved;
    }

    function setUpgradeSawAddress(address _upgradeSaw) internal {
        diamondSawStorage().upgradeSawAddress = _upgradeSaw;
    }
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.0;

library AccessControlLib {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    struct AccessControlStorage {
        address _owner;
        mapping(address => bool) _admins;
    }

    bytes32 constant ACCESS_CONTROL_STORAGE_POSITION = keccak256("Access.Control.library.storage");

    function accessControlStorage() internal pure returns (AccessControlStorage storage s) {
        bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function _isOwner() internal view returns (bool) {
        return accessControlStorage()._owner == msg.sender;
    }

    function owner() internal view returns (address) {
        return accessControlStorage()._owner;
    }

    function _enforceOwner() internal view {
        require(_isOwner(), "Caller is not the owner");
    }

    function _isAdmin() internal view returns (bool) {
        return accessControlStorage()._admins[msg.sender];
    }

    function _enforceAdmin() internal view {
        require(_isAdmin() || _isOwner(), "Is not admin or owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = accessControlStorage()._owner;
        accessControlStorage()._owner = newOwner;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
pragma solidity ^0.8.0;

import {DiamondCloneLib} from "../DiamondClone/DiamondCloneLib.sol";

uint256 constant BASIS = 10000;

library PaymentSplitterLib {
    struct SplitInfo {
        uint256 basisPoints;
        address payable splitAddress;
    }

    struct PaymentSplitterStorage {
        SplitInfo[] splits;
    }

    function paymentSplitterStorage() internal pure returns (PaymentSplitterStorage storage es) {
        bytes32 position = keccak256("payment.splitter.facet.storage");
        assembly {
            es.slot := position
        }
    }

    function paymentSplitterInfo() internal view returns (SplitInfo[] storage) {
        return paymentSplitterStorage().splits;
    }

    function setPaymentSplits(SplitInfo[] memory splits) internal {
        require(splits.length > 0, "Must provide split information");
        PaymentSplitterStorage storage s = paymentSplitterStorage();

        if (s.splits.length > 0) {
            require(
                s.splits[0].basisPoints == splits[0].basisPoints && s.splits[0].splitAddress == splits[0].splitAddress,
                "Cannot modify first split"
            );
        }

        uint256 total;
        for (uint256 i; i < s.splits.length; i++) {
            if (i < splits.length) {
                require(splits[i].splitAddress != address(0), "Cannot set payment split to null address");
                total += splits[i].basisPoints;
                s.splits.push(splits[i]);
            } else {
                delete splits[i];
            }
        }

        require(total == BASIS, "payment split does not add up to basis");
    }

    function withdraw() internal {
        PaymentSplitterStorage storage s = paymentSplitterStorage();
        uint256 balance = address(this).balance;

        for (uint256 i; i < s.splits.length; i++) {
            uint256 payment = (balance * s.splits[i].basisPoints) / BASIS;
            (bool success, ) = s.splits[i].splitAddress.call{value: payment}("");
            require(success, "Payment failed!");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

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
library RoyaltyStandardLib {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    struct RoyaltyStandardStorage {
        RoyaltyInfo _defaultRoyaltyInfo;
        mapping(uint256 => RoyaltyInfo) _tokenRoyaltyInfo;
    }

    function royaltyStandardStorage() internal pure returns (RoyaltyStandardStorage storage s) {
        bytes32 position = keccak256("royalty.standard.facet.storage");
        assembly {
            s.slot := position
        }
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) internal view returns (address, uint256) {
        RoyaltyStandardStorage storage s = royaltyStandardStorage();

        RoyaltyInfo memory royalty = s._tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = s._defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `feeNumerator` cannot be greater than the fee denominator.
     * - receiver is always the contract address where payment splitting is implemented
     */
    function _setDefaultRoyalty(uint96 feeNumerator) internal {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");

        royaltyStandardStorage()._defaultRoyaltyInfo = RoyaltyInfo(address(this), feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal {
        delete royaltyStandardStorage()._defaultRoyaltyInfo;
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
    ) internal {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        royaltyStandardStorage()._tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal {
        delete royaltyStandardStorage()._tokenRoyaltyInfo[tokenId];
    }
}
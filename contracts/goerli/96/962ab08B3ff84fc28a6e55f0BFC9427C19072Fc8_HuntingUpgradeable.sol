// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @title Controllable
abstract contract Controllable {
  /// @notice address => is controller.
  mapping(address => bool) private _isController;
  /// @notice Require the caller to be a controller.
  modifier onlyController() {
    require(_isController[msg.sender], "Controllable: Caller is not a controller");
    _;
  }

  /// @notice Check if `addr` is a controller.
  function isController(address addr) public view returns (bool) {
    return _isController[addr];
  }

  /// @notice Set the `addr` controller status to `status`.
  function _setController(address addr, bool status) internal {
    _isController[addr] = status;
  }
}

pragma solidity 0.8.11;

import "../base/controllable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "../game/interfaces/Structs.sol";

contract FreaksNGuildsMock is Controllable, Ownable, ERC721A("FnG Mock", "FnGMock") {
  uint256 public celestialSupply;
  uint256 public freakSupply;
  mapping(uint256 => Freak) public freaks;
  mapping(uint256 => Celestial) public celestials;

  function mintToContract(address to, uint256 amount) external {
    _safeMint(to, amount);
  }

  function mintFreaks(address to, uint256 amount) external {
    for (uint256 i = 0; i < amount; i++) {
      mintFreak(to, 1, 1, 1, 0, 1, 110, 50, 0);
    }
  }

  function mintFreak(
    address to,
    uint8 species,
    uint8 body,
    uint8 mainHand,
    uint8 offHand,
    uint8 armor,
    uint8 power,
    uint8 health,
    uint8 criticalStrike
  ) public {
    Freak memory freak = Freak(species, body, mainHand, offHand, armor, power, health, criticalStrike);
    freaks[_currentIndex] = freak;
    freakSupply += 1;
    _mint(to, 1, "", false);
  }

  function mintCelestials(address to, uint256 amount) external {
    for (uint256 i = 0; i < amount; i++) {
      mintCelestial(to, 4, 4, 1, 1);
    }
  }

  function mintCelestial(
    address to,
    uint8 healthMod,
    uint8 powMod,
    uint8 cPP,
    uint8 cLevel
  ) public {
    Celestial memory celestial = Celestial(healthMod, powMod, cPP, cLevel);
    celestials[_currentIndex] = celestial;
    celestialSupply += 1;
    _mint(to, 1, "", false);
  }

  function getFreakAttributes(uint256 tokenId) external view returns (Freak memory) {
    return (freaks[tokenId]);
  }

  function getCelestialAttributes(uint256 tokenId) external view returns (Celestial memory) {
    return (celestials[tokenId]);
  }

  function isFreak(uint256 tokenId) public view returns (bool) {
    return freaks[tokenId].species != 0 ? true : false;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setFreakAttributes(uint256 tokenId, Freak memory attributes) external {
    require(_exists(tokenId), "token does not exist");
    freaks[tokenId] = attributes;
    freakSupply += 1;
  }

  function setCelestialAttributes(uint256 tokenId, Celestial memory attributes) external  {
    require(_exists(tokenId), "token does not exist");
    celestials[tokenId] = attributes;
    celestialSupply += 1;
  }

  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    // if (!marketplacesApproved) return auth[operator] || super.isApprovedForAll(owner, operator);
    return
      isController(operator) ||
      // operator == address(ProxyRegistry(opensea).proxies(owner)) ||
      // operator == looksrare ||
      super.isApprovedForAll(owner, operator);
  }

  /// @notice Add or edit contract controllers.
  /// @param addrs Array of addresses to be added/edited.
  /// @param state New controller state of addresses.
  function setControllers(address[] calldata addrs, bool state) external onlyOwner {
    for (uint256 i = 0; i < addrs.length; i++) super._setController(addrs[i], state);
  }

  function burn(uint256 tokenId) external onlyOwner {
    if(isFreak(tokenId)){
      delete freaks[tokenId];
      freakSupply -= 1;
    }else{
      delete celestials[tokenId];
      celestialSupply -= 1;
    }
    _burn(tokenId);
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
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

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

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
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
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
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
        return _ownershipOf(tokenId).addr;
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

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
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
    function setApprovalForAll(address operator, bool approved) public virtual override {
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
        safeTransferFrom(from, to, tokenId, '');
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
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
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
        return _startTokenId() <= tokenId && tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
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
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
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
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

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
    ) private returns (bool) {
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
pragma solidity 0.8.11;

struct Freak {
  uint8 species;
  uint8 body;
  uint8 armor;
  uint8 mainHand;
  uint8 offHand;
  uint8 power;
  uint8 health;
  uint8 criticalStrikeMod;

}
struct Celestial {
  uint8 healthMod;
  uint8 powMod;
  uint8 cPP;
  uint8 cLevel;
}

struct Layer {
  string name;
  string data;
}

struct LayerInput {
  string name;
  string data;
  uint8 layerIndex;
  uint8 itemIndex;
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
pragma solidity 0.8.11;

import "./interfaces/Structs.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// solhint-disable quotes

contract InventoryFreaks is Ownable {
  using Strings for uint8;

  /*  +---+-----------+ */
  /*  | 0 | Body      | */
  /*  +---+-----------+ */
  /*  | 1 | Armor     | */
  /*  +---+-----------+ */
  /*  | 2 | Main Hand | */
  /*  +---+-----------+ */
  /*  | 3 | Off Hand  | */
  /*  +---+-----------+ */

  /*///////////////////////////////////////////////////////////////
                LAYERS LOGIC 
    //////////////////////////////////////////////////////////////*/

  mapping(uint256 => mapping(uint256 => Layer)[4]) internal _layers;

  function addLayers(LayerInput[] memory inputs, uint256 species) external onlyOwner {
    for (uint256 i = 0; i < inputs.length; i++) {
      _layers[species][inputs[i].layerIndex][inputs[i].itemIndex] = Layer(inputs[i].name, inputs[i].data);
    }
  }

  function getLayer(uint8 layerIndex, uint8 itemIndex, uint256 species) external view returns (Layer memory) {
    return _layers[species][layerIndex][itemIndex];
  }

  /*///////////////////////////////////////////////////////////////
                URI LOGIC 
    //////////////////////////////////////////////////////////////*/

  function getAttributes(Freak memory character, uint256 id) external view returns (bytes memory) {
    return
      abi.encodePacked(
        '{"trait_type": "Type", "value": "Freak"},',
        '{"trait_type": "Generation", "value":"',
        id <= 10000 ? "Gen 0" : id <= 20000 ? "Gen 1" : "Gen 2",
        '"},'
        '{"trait_type": "Species", "value": "',
        character.species == 1 ? "Troll" : character.species == 2 ? "Fairy" : "Ogre",
        '"},'
        '{"trait_type": "Body", "value": "',
        _layers[character.species][0][character.body].name,
        '"},',
        '{"trait_type": "Armor", "value": "',
        _layers[character.species][1][character.armor].name,
        '"},',
        '{"trait_type": "Main Hand", "value": "',
        _layers[character.species][2][character.mainHand].name,
        '"},',
        '{"trait_type": "Off Hand", "value": "',
        _layers[character.species][3][character.offHand].name,
        '"},',
        '{"trait_type": "Power", "value": "',
        character.power.toString(),
        '"},',
        '{"trait_type": "Health", "value": "',
        character.health.toString(),
        '"},',
        '{"trait_type": "Critical Strike Mod", "value": "',
        character.criticalStrikeMod.toString(),
        '"}'
      );
  }

  function getImage(Freak memory character) external view returns (bytes memory) {
    if(character.offHand == 0){
      return
        abi.encodePacked(
          _buildImage(_layers[character.species][0][character.body].data),
          _buildImage(_layers[character.species][1][character.armor].data),
          _buildImage(_layers[character.species][2][character.mainHand].data)
        );
    }else{
      return
        abi.encodePacked(
          _buildImage(_layers[character.species][0][character.body].data),
          _buildImage(_layers[character.species][1][character.armor].data),
          _buildImage(_layers[character.species][2][character.mainHand].data),
          _buildImage(_layers[character.species][3][character.offHand].data)
        );
    }
  }

  function _buildImage(string memory image) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
        image,
        '"/>'
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

import {RLPReader} from "./lib/RLPReader.sol";
import {MerklePatriciaProof} from "./lib/MerklePatriciaProof.sol";
import {Merkle} from "./lib/Merkle.sol";
import "./lib/ExitPayloadReader.sol";

/**
 * @title Celestial Portal Root
 * @notice Edited from fx-portal/contracts and EtherOrcsOfficial/etherOrcs-contracts.
 */
contract CelestialPortalRoot is Ownable {
  using RLPReader for RLPReader.RLPItem;
  using Merkle for bytes32;
  using ExitPayloadReader for bytes;
  using ExitPayloadReader for ExitPayloadReader.ExitPayload;
  using ExitPayloadReader for ExitPayloadReader.Log;
  using ExitPayloadReader for ExitPayloadReader.LogTopics;
  using ExitPayloadReader for ExitPayloadReader.Receipt;

  /// @notice Emited when we replay a call.
  event CallMade(address target, bool success, bytes data);

  /// @notice Hashed message event -> keccak256("MessageSent(bytes)").
  bytes32 public constant SEND_MESSAGE_EVENT_SIG = 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

  /// @notice Fx Root contract address.
  address public fxRoot;
  /// @notice Checkpoint Manager contract address.
  address public checkpointManager;

  /// @notice Polyland Portal contract address.
  address public polylandPortal;

  /// @notice Authorized callers mapping.
  mapping(address => bool) public auth;

  /// @notice Message exits mapping.
  mapping(bytes32 => bool) public processedExits;

  /// @notice Require the sender to be the owner or authorized.
  modifier onlyAuth() {
    require(auth[msg.sender], "CelestialPortalRoot: Unauthorized to use the portal");
    _;
  }

  /// @notice Initialize the contract.
  function initialize(
    address newFxRoot,
    address newCheckpointManager,
    address newPolylandPortal
  ) external onlyOwner {
    fxRoot = newFxRoot;
    checkpointManager = newCheckpointManager;
    polylandPortal = newPolylandPortal;
  }

  /// @notice Give authentication to `adds_`.
  function setAuth(address[] calldata addresses, bool authorized) external onlyOwner {
    for (uint256 index = 0; index < addresses.length; index++) {
      auth[addresses[index]] = authorized;
    }
  }

  /// @notice Send a message to the portal via FxRoot.
  function sendMessage(bytes calldata message) external onlyAuth {
    IFxStateSender(fxRoot).sendMessageToChild(polylandPortal, message);
  }

  /// @notice Clone reflection calls by the owner.
  function replayCall(
    address target_,
    bytes calldata data_,
    bool required_
  ) external onlyOwner {
    (bool succ, ) = target_.call(data_);
    if (required_) require(succ, "CelestialPortalRoot: Replay call failed");
  }

  /**
   * @notice Executed when we receive a message from Polyland.
   * @dev This function verifies if the transaction actually happened on child chain.
   * @param data RLP encoded data of the reference tx containing following list of fields
   *  0 - headerNumber - Checkpoint header block number containing the reference tx
   *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
   *  2 - blockNumber - Block number containing the reference tx on child chain
   *  3 - blockTime - Reference tx block time
   *  4 - txRoot - Transactions root of block
   *  5 - receiptRoot - Receipts root of block
   *  6 - receipt - Receipt of the reference transaction
   *  7 - receiptProof - Merkle proof of the reference receipt
   *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
   *  9 - receiptLogIndex - Log Index to read from the receipt
   */
  function receiveMessage(bytes calldata data) public virtual {
    bytes memory message = _validateAndExtractMessage(data);
    (address target, bytes[] memory calls) = abi.decode(message, (address, bytes[]));
    for (uint256 i = 0; i < calls.length; i++) {
      (bool success, ) = target.call(calls[i]);
      emit CallMade(target, success, calls[i]);
    }
  }

  /// @notice Validate and extract message from FxRoot.
  function _validateAndExtractMessage(bytes memory data) internal returns (bytes memory) {
    ExitPayloadReader.ExitPayload memory payload = data.toExitPayload();

    bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
    uint256 blockNumber = payload.getBlockNumber();
    // checking if exit has already been processed
    // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
    bytes32 exitHash = keccak256(
      abi.encodePacked(
        blockNumber,
        // first 2 nibbles are dropped while generating nibble array
        // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
        // so converting to nibble array and then hashing it
        MerklePatriciaProof._getNibbleArray(branchMaskBytes),
        payload.getReceiptLogIndex()
      )
    );
    require(processedExits[exitHash] == false, "CelestialPortalRoot: EXIT_ALREADY_PROCESSED");
    processedExits[exitHash] = true;

    ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
    ExitPayloadReader.Log memory log = receipt.getLog();

    // check child tunnel
    require(polylandPortal == log.getEmitter(), "CelestialPortalRoot: INVALID_FX_CHILD_TUNNEL");

    bytes32 receiptRoot = payload.getReceiptRoot();
    // verify receipt inclusion
    require(
      MerklePatriciaProof.verify(receipt.toBytes(), branchMaskBytes, payload.getReceiptProof(), receiptRoot),
      "CelestialPortalRoot: INVALID_RECEIPT_PROOF"
    );

    // verify checkpoint inclusion
    _checkBlockMembershipInCheckpoint(
      blockNumber,
      payload.getBlockTime(),
      payload.getTxRoot(),
      receiptRoot,
      payload.getHeaderNumber(),
      payload.getBlockProof()
    );

    ExitPayloadReader.LogTopics memory topics = log.getTopics();

    require(
      bytes32(topics.getField(0).toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
      "CelestialPortalRoot: INVALID_SIGNATURE"
    );

    // received message data
    bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message
    return message;
  }

  /// @notice Validate checkpoint payload.
  function _checkBlockMembershipInCheckpoint(
    uint256 blockNumber,
    uint256 blockTime,
    bytes32 txRoot,
    bytes32 receiptRoot,
    uint256 headerNumber,
    bytes memory blockProof
  ) internal view returns (uint256) {
    (bytes32 headerRoot, uint256 startBlock, , uint256 createdAt, ) = ICheckpointManager(checkpointManager)
      .headerBlocks(headerNumber);

    require(
      keccak256(abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)).checkMembership(
        blockNumber - startBlock,
        headerRoot,
        blockProof
      ),
      "CelestialPortalRoot: INVALID_HEADER"
    );
    return createdAt;
  }
}

interface IFxStateSender {
  function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

interface ICheckpointManager {
  function headerBlocks(uint256 headerBlock)
    external
    view
    returns (
      bytes32 root,
      uint256 start,
      uint256 end,
      uint256 createdAt,
      address proposer
    );
}

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity ^0.8.0;

library RLPReader {
  uint8 constant STRING_SHORT_START = 0x80;
  uint8 constant STRING_LONG_START = 0xb8;
  uint8 constant LIST_SHORT_START = 0xc0;
  uint8 constant LIST_LONG_START = 0xf8;
  uint8 constant WORD_SIZE = 32;

  struct RLPItem {
    uint256 len;
    uint256 memPtr;
  }

  struct Iterator {
    RLPItem item; // Item that's being iterated over.
    uint256 nextPtr; // Position of the next item in the list.
  }

  /*
   * @dev Returns the next element in the iteration. Reverts if it has not next element.
   * @param self The iterator.
   * @return The next element in the iteration.
   */
  function next(Iterator memory self) internal pure returns (RLPItem memory) {
    require(hasNext(self));

    uint256 ptr = self.nextPtr;
    uint256 itemLength = _itemLength(ptr);
    self.nextPtr = ptr + itemLength;

    return RLPItem(itemLength, ptr);
  }

  /*
   * @dev Returns true if the iteration has more elements.
   * @param self The iterator.
   * @return true if the iteration has more elements.
   */
  function hasNext(Iterator memory self) internal pure returns (bool) {
    RLPItem memory item = self.item;
    return self.nextPtr < item.memPtr + item.len;
  }

  /*
   * @param item RLP encoded bytes
   */
  function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
    uint256 memPtr;
    assembly {
      memPtr := add(item, 0x20)
    }

    return RLPItem(item.length, memPtr);
  }

  /*
   * @dev Create an iterator. Reverts if item is not a list.
   * @param self The RLP item.
   * @return An 'Iterator' over the item.
   */
  function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
    require(isList(self));

    uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
    return Iterator(self, ptr);
  }

  /*
   * @param item RLP encoded bytes
   */
  function rlpLen(RLPItem memory item) internal pure returns (uint256) {
    return item.len;
  }

  /*
   * @param item RLP encoded bytes
   */
  function payloadLen(RLPItem memory item) internal pure returns (uint256) {
    return item.len - _payloadOffset(item.memPtr);
  }

  /*
   * @param item RLP encoded list in bytes
   */
  function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
    require(isList(item));

    uint256 items = numItems(item);
    RLPItem[] memory result = new RLPItem[](items);

    uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
    uint256 dataLen;
    for (uint256 i = 0; i < items; i++) {
      dataLen = _itemLength(memPtr);
      result[i] = RLPItem(dataLen, memPtr);
      memPtr = memPtr + dataLen;
    }

    return result;
  }

  // @return indicator whether encoded payload is a list. negate this function call for isData.
  function isList(RLPItem memory item) internal pure returns (bool) {
    if (item.len == 0) return false;

    uint8 byte0;
    uint256 memPtr = item.memPtr;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < LIST_SHORT_START) return false;
    return true;
  }

  /*
   * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
   * @return keccak256 hash of RLP encoded bytes.
   */
  function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
    uint256 ptr = item.memPtr;
    uint256 len = item.len;
    bytes32 result;
    assembly {
      result := keccak256(ptr, len)
    }
    return result;
  }

  function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
    uint256 offset = _payloadOffset(item.memPtr);
    uint256 memPtr = item.memPtr + offset;
    uint256 len = item.len - offset; // data length
    return (memPtr, len);
  }

  /*
   * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
   * @return keccak256 hash of the item payload.
   */
  function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
    (uint256 memPtr, uint256 len) = payloadLocation(item);
    bytes32 result;
    assembly {
      result := keccak256(memPtr, len)
    }
    return result;
  }

  /** RLPItem conversions into data types **/

  // @returns raw rlp encoding in bytes
  function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
    bytes memory result = new bytes(item.len);
    if (result.length == 0) return result;

    uint256 ptr;
    assembly {
      ptr := add(0x20, result)
    }

    copy(item.memPtr, ptr, item.len);
    return result;
  }

  // any non-zero byte is considered true
  function toBoolean(RLPItem memory item) internal pure returns (bool) {
    require(item.len == 1);
    uint256 result;
    uint256 memPtr = item.memPtr;
    assembly {
      result := byte(0, mload(memPtr))
    }

    return result == 0 ? false : true;
  }

  function toAddress(RLPItem memory item) internal pure returns (address) {
    // 1 byte for the length prefix
    require(item.len == 21);

    return address(uint160(toUint(item)));
  }

  function toUint(RLPItem memory item) internal pure returns (uint256) {
    require(item.len > 0 && item.len <= 33);

    uint256 offset = _payloadOffset(item.memPtr);
    uint256 len = item.len - offset;

    uint256 result;
    uint256 memPtr = item.memPtr + offset;
    assembly {
      result := mload(memPtr)

      // shfit to the correct location if neccesary
      if lt(len, 32) {
        result := div(result, exp(256, sub(32, len)))
      }
    }

    return result;
  }

  // enforces 32 byte length
  function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
    // one byte prefix
    require(item.len == 33);

    uint256 result;
    uint256 memPtr = item.memPtr + 1;
    assembly {
      result := mload(memPtr)
    }

    return result;
  }

  function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
    require(item.len > 0);

    uint256 offset = _payloadOffset(item.memPtr);
    uint256 len = item.len - offset; // data length
    bytes memory result = new bytes(len);

    uint256 destPtr;
    assembly {
      destPtr := add(0x20, result)
    }

    copy(item.memPtr + offset, destPtr, len);
    return result;
  }

  /*
   * Private Helpers
   */

  // @return number of payload items inside an encoded list.
  function numItems(RLPItem memory item) private pure returns (uint256) {
    if (item.len == 0) return 0;

    uint256 count = 0;
    uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
    uint256 endPtr = item.memPtr + item.len;
    while (currPtr < endPtr) {
      currPtr = currPtr + _itemLength(currPtr); // skip over an item
      count++;
    }

    return count;
  }

  // @return entire rlp item byte length
  function _itemLength(uint256 memPtr) private pure returns (uint256) {
    uint256 itemLen;
    uint256 byte0;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < STRING_SHORT_START) itemLen = 1;
    else if (byte0 < STRING_LONG_START) itemLen = byte0 - STRING_SHORT_START + 1;
    else if (byte0 < LIST_SHORT_START) {
      assembly {
        let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
        memPtr := add(memPtr, 1) // skip over the first byte
        /* 32 byte word size */
        let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
        itemLen := add(dataLen, add(byteLen, 1))
      }
    } else if (byte0 < LIST_LONG_START) {
      itemLen = byte0 - LIST_SHORT_START + 1;
    } else {
      assembly {
        let byteLen := sub(byte0, 0xf7)
        memPtr := add(memPtr, 1)

        let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
        itemLen := add(dataLen, add(byteLen, 1))
      }
    }

    return itemLen;
  }

  // @return number of bytes until the data
  function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
    uint256 byte0;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < STRING_SHORT_START) return 0;
    else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) return 1;
    else if (byte0 < LIST_SHORT_START)
      // being explicit
      return byte0 - (STRING_LONG_START - 1) + 1;
    else return byte0 - (LIST_LONG_START - 1) + 1;
  }

  /*
   * @param src Pointer to source
   * @param dest Pointer to destination
   * @param len Amount of memory to copy from the source
   */
  function copy(
    uint256 src,
    uint256 dest,
    uint256 len
  ) private pure {
    if (len == 0) return;

    // copy as many word sizes as possible
    for (; len >= WORD_SIZE; len -= WORD_SIZE) {
      assembly {
        mstore(dest, mload(src))
      }

      src += WORD_SIZE;
      dest += WORD_SIZE;
    }

    if (len == 0) return;

    // left over bytes. Mask is used to remove unwanted bytes from the word
    uint256 mask = 256**(WORD_SIZE - len) - 1;

    assembly {
      let srcpart := and(mload(src), not(mask)) // zero out src
      let destpart := and(mload(dest), mask) // retrieve the bytes
      mstore(dest, or(destpart, srcpart))
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library MerklePatriciaProof {
  /*
   * @dev Verifies a merkle patricia proof.
   * @param value The terminating value in the trie.
   * @param encodedPath The path in the trie leading to value.
   * @param rlpParentNodes The rlp encoded stack of nodes.
   * @param root The root hash of the trie.
   * @return The boolean validity of the proof.
   */
  function verify(
    bytes memory value,
    bytes memory encodedPath,
    bytes memory rlpParentNodes,
    bytes32 root
  ) internal pure returns (bool) {
    RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
    RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

    bytes memory currentNode;
    RLPReader.RLPItem[] memory currentNodeList;

    bytes32 nodeKey = root;
    uint256 pathPtr = 0;

    bytes memory path = _getNibbleArray(encodedPath);
    if (path.length == 0) {
      return false;
    }

    for (uint256 i = 0; i < parentNodes.length; i++) {
      if (pathPtr > path.length) {
        return false;
      }

      currentNode = RLPReader.toRlpBytes(parentNodes[i]);
      if (nodeKey != keccak256(currentNode)) {
        return false;
      }
      currentNodeList = RLPReader.toList(parentNodes[i]);

      if (currentNodeList.length == 17) {
        if (pathPtr == path.length) {
          if (keccak256(RLPReader.toBytes(currentNodeList[16])) == keccak256(value)) {
            return true;
          } else {
            return false;
          }
        }

        uint8 nextPathNibble = uint8(path[pathPtr]);
        if (nextPathNibble > 16) {
          return false;
        }
        nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[nextPathNibble]));
        pathPtr += 1;
      } else if (currentNodeList.length == 2) {
        uint256 traversed = _nibblesToTraverse(RLPReader.toBytes(currentNodeList[0]), path, pathPtr);
        if (pathPtr + traversed == path.length) {
          //leaf node
          if (keccak256(RLPReader.toBytes(currentNodeList[1])) == keccak256(value)) {
            return true;
          } else {
            return false;
          }
        }

        //extension node
        if (traversed == 0) {
          return false;
        }

        pathPtr += traversed;
        nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
      } else {
        return false;
      }
    }
  }

  function _nibblesToTraverse(
    bytes memory encodedPartialPath,
    bytes memory path,
    uint256 pathPtr
  ) private pure returns (uint256) {
    uint256 len = 0;
    // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
    // and slicedPath have elements that are each one hex character (1 nibble)
    bytes memory partialPath = _getNibbleArray(encodedPartialPath);
    bytes memory slicedPath = new bytes(partialPath.length);

    // pathPtr counts nibbles in path
    // partialPath.length is a number of nibbles
    for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
      bytes1 pathNibble = path[i];
      slicedPath[i - pathPtr] = pathNibble;
    }

    if (keccak256(partialPath) == keccak256(slicedPath)) {
      len = partialPath.length;
    } else {
      len = 0;
    }
    return len;
  }

  // bytes b must be hp encoded
  function _getNibbleArray(bytes memory b) internal pure returns (bytes memory) {
    bytes memory nibbles = "";
    if (b.length > 0) {
      uint8 offset;
      uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
      if (hpNibble == 1 || hpNibble == 3) {
        nibbles = new bytes(b.length * 2 - 1);
        bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
        nibbles[0] = oddNibble;
        offset = 1;
      } else {
        nibbles = new bytes(b.length * 2 - 2);
        offset = 0;
      }

      for (uint256 i = offset; i < nibbles.length; i++) {
        nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
      }
    }
    return nibbles;
  }

  function _getNthNibbleOfBytes(uint256 n, bytes memory str) private pure returns (bytes1) {
    return bytes1(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Merkle {
  function checkMembership(
    bytes32 leaf,
    uint256 index,
    bytes32 rootHash,
    bytes memory proof
  ) internal pure returns (bool) {
    require(proof.length % 32 == 0, "Invalid proof length");
    uint256 proofHeight = proof.length / 32;
    // Proof of size n means, height of the tree is n+1.
    // In a tree of height n+1, max #leafs possible is 2 ^ n
    require(index < 2**proofHeight, "Leaf index is too big");

    bytes32 proofElement;
    bytes32 computedHash = leaf;
    for (uint256 i = 32; i <= proof.length; i += 32) {
      assembly {
        proofElement := mload(add(proof, i))
      }

      if (index % 2 == 0) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }

      index = index / 2;
    }
    return computedHash == rootHash;
  }
}

pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library ExitPayloadReader {
  using RLPReader for bytes;
  using RLPReader for RLPReader.RLPItem;

  uint8 constant WORD_SIZE = 32;

  struct ExitPayload {
    RLPReader.RLPItem[] data;
  }

  struct Receipt {
    RLPReader.RLPItem[] data;
    bytes raw;
    uint256 logIndex;
  }

  struct Log {
    RLPReader.RLPItem data;
    RLPReader.RLPItem[] list;
  }

  struct LogTopics {
    RLPReader.RLPItem[] data;
  }

  // copy paste of private copy() from RLPReader to avoid changing of existing contracts
  function copy(
    uint256 src,
    uint256 dest,
    uint256 len
  ) private pure {
    if (len == 0) return;

    // copy as many word sizes as possible
    for (; len >= WORD_SIZE; len -= WORD_SIZE) {
      assembly {
        mstore(dest, mload(src))
      }

      src += WORD_SIZE;
      dest += WORD_SIZE;
    }

    // left over bytes. Mask is used to remove unwanted bytes from the word
    uint256 mask = 256**(WORD_SIZE - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask)) // zero out src
      let destpart := and(mload(dest), mask) // retrieve the bytes
      mstore(dest, or(destpart, srcpart))
    }
  }

  function toExitPayload(bytes memory data) internal pure returns (ExitPayload memory) {
    RLPReader.RLPItem[] memory payloadData = data.toRlpItem().toList();

    return ExitPayload(payloadData);
  }

  function getHeaderNumber(ExitPayload memory payload) internal pure returns (uint256) {
    return payload.data[0].toUint();
  }

  function getBlockProof(ExitPayload memory payload) internal pure returns (bytes memory) {
    return payload.data[1].toBytes();
  }

  function getBlockNumber(ExitPayload memory payload) internal pure returns (uint256) {
    return payload.data[2].toUint();
  }

  function getBlockTime(ExitPayload memory payload) internal pure returns (uint256) {
    return payload.data[3].toUint();
  }

  function getTxRoot(ExitPayload memory payload) internal pure returns (bytes32) {
    return bytes32(payload.data[4].toUint());
  }

  function getReceiptRoot(ExitPayload memory payload) internal pure returns (bytes32) {
    return bytes32(payload.data[5].toUint());
  }

  function getReceipt(ExitPayload memory payload) internal pure returns (Receipt memory receipt) {
    receipt.raw = payload.data[6].toBytes();
    RLPReader.RLPItem memory receiptItem = receipt.raw.toRlpItem();

    if (receiptItem.isList()) {
      // legacy tx
      receipt.data = receiptItem.toList();
    } else {
      // pop first byte before parsting receipt
      bytes memory typedBytes = receipt.raw;
      bytes memory result = new bytes(typedBytes.length - 1);
      uint256 srcPtr;
      uint256 destPtr;
      assembly {
        srcPtr := add(33, typedBytes)
        destPtr := add(0x20, result)
      }

      copy(srcPtr, destPtr, result.length);
      receipt.data = result.toRlpItem().toList();
    }

    receipt.logIndex = getReceiptLogIndex(payload);
    return receipt;
  }

  function getReceiptProof(ExitPayload memory payload) internal pure returns (bytes memory) {
    return payload.data[7].toBytes();
  }

  function getBranchMaskAsBytes(ExitPayload memory payload) internal pure returns (bytes memory) {
    return payload.data[8].toBytes();
  }

  function getBranchMaskAsUint(ExitPayload memory payload) internal pure returns (uint256) {
    return payload.data[8].toUint();
  }

  function getReceiptLogIndex(ExitPayload memory payload) internal pure returns (uint256) {
    return payload.data[9].toUint();
  }

  // Receipt methods
  function toBytes(Receipt memory receipt) internal pure returns (bytes memory) {
    return receipt.raw;
  }

  function getLog(Receipt memory receipt) internal pure returns (Log memory) {
    RLPReader.RLPItem memory logData = receipt.data[3].toList()[receipt.logIndex];
    return Log(logData, logData.toList());
  }

  // Log methods
  function getEmitter(Log memory log) internal pure returns (address) {
    return RLPReader.toAddress(log.list[0]);
  }

  function getTopics(Log memory log) internal pure returns (LogTopics memory) {
    return LogTopics(log.list[1].toList());
  }

  function getData(Log memory log) internal pure returns (bytes memory) {
    return log.list[2].toBytes();
  }

  function toRlpBytes(Log memory log) internal pure returns (bytes memory) {
    return log.data.toRlpBytes();
  }

  // LogTopics methods
  function getField(LogTopics memory topics, uint256 index) internal pure returns (RLPReader.RLPItem memory) {
    return topics.data[index];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Celestial Portal Child
 * @notice Edited from fx-portal/contracts and EtherOrcsOfficial/etherOrcs-contracts.
 */
contract CelestialPortalChild is Ownable {
  /// @notice MessageTunnel on L1 will get data from this event.
  event MessageSent(bytes message);
  /// @notice Emited when we replay a call.
  event CallMade(address target, bool success, bytes data);

  /// @notice Fx Child contract address.
  address public fxChild;

  /// @notice Mainland Portal contract address.
  address public mainlandPortal;

  /// @notice Authorized callers mapping.
  mapping(address => bool) public auth;

  /// @notice Require the sender to be the owner or authorized.
  modifier onlyAuth() {
    require(auth[msg.sender], "CelestialPortalChild: Unauthorized to use the portal");
    _;
  }

  /// @notice Initialize the contract.
  function initialize(address newFxChild, address newMainlandPortal) external onlyOwner {
    fxChild = newFxChild;
    mainlandPortal = newMainlandPortal;
  }

  /// @notice Give authentication to `adds_`.
  function setAuth(address[] calldata addresses, bool authorized) external onlyOwner {
    for (uint256 index = 0; index < addresses.length; index++) {
      auth[addresses[index]] = authorized;
    }
  }

  /// @notice Send a message to the portal via FxChild.
  function sendMessage(bytes calldata message) external onlyAuth {
    emit MessageSent(message);
  }

  /// @notice Clone reflection calls by the owner.
  function replayCall(
    address target,
    bytes calldata data,
    bool required
  ) external onlyOwner {
    (bool succ, ) = target.call(data);
    if (required) require(succ, "CelestialPortalChild: Replay call failed");
  }

  /// @notice Executed when we receive a message from Mainland.
  function processMessageFromRoot(
    uint256,
    address rootSender,
    bytes calldata data
  ) external {
    require(msg.sender == fxChild, "CelestialPortalChild: INVALID_SENDER");
    require(rootSender == mainlandPortal, "CelestialPortalChild: INVALID_PORTAL");

    (address target, bytes[] memory calls) = abi.decode(data, (address, bytes[]));
    for (uint256 i = 0; i < calls.length; i++) {
      (bool success, ) = target.call(calls[i]);
      emit CallMade(target, success, calls[i]);
    }
  }
}

interface IFxMessageProcessor {
  function processMessageFromRoot(
    uint256 stateId,
    address rootMessageSender,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../game/interfaces/Interfaces.sol";

/**
 * @title Celestial Castle
 * @notice Edited from EtherOrcsOfficial/etherOrcs-contracts.
 */
contract CelestialCastle is Ownable, IERC721Receiver {
  bool public isTravelEnabled;
  /// @notice Celestial portal contract.
  PortalLike public portal;
  /// @notice Freaks N Guilds token contract.
  IFnG public freaksNGuilds;
  /// @notice Freaks bucks token contract.
  IFBX public freaksBucks;

  /// @notice Contract address to it's reflection.
  mapping(address => address) public reflection;
  /// @notice Original token id owner.
  mapping(uint256 => address) public ownerOf;

  /// @notice Require that the sender is the portal for bridging operations.
  modifier onlyPortal() {
    require(msg.sender == address(portal), "CelestialCastle: sender is not the portal");
    _;
  }

  /// @notice Initialize the contract.
  function initialize(
    address newPortal,
    address newFreaksNGuilds,
    address newFreaksBucks,
    bool newIsTravelEnabled
  ) external onlyOwner {
    portal = PortalLike(newPortal);
    freaksNGuilds = IFnG(newFreaksNGuilds);
    freaksBucks = IFBX(newFreaksBucks);
    isTravelEnabled = newIsTravelEnabled;
  }

  /// @notice Travel tokens to L2.
  function travel(
    uint256[] calldata freakIds,
    uint256[] calldata celestialIds,
    uint256 fbxAmount
  ) external {
    require(isTravelEnabled, "CelestialCastle: travel is disabled");
    bytes[] memory calls = new bytes[](
      (freakIds.length > 0 ? 1 : 0) + (celestialIds.length > 0 ? 1 : 0) + (fbxAmount > 0 ? 1 : 0)
    );
    uint256 callsIndex = 0;

    if (freakIds.length > 0) {
      Freak[] memory freaks = new Freak[](freakIds.length);
      for (uint256 i = 0; i < freakIds.length; i++) {
        require(ownerOf[freakIds[i]] == address(0), "CelestialCastle: token already staked");
        require(freaksNGuilds.isFreak(freakIds[i]), "CelestialCastle: not a freak");
        ownerOf[freakIds[i]] = msg.sender;
        freaks[i] = freaksNGuilds.getFreakAttributes(freakIds[i]);
        freaksNGuilds.transferFrom(msg.sender, address(this), freakIds[i]);
      }
      calls[callsIndex] = abi.encodeWithSelector(
        CelestialCastle.retrieveFreakIds.selector,
        reflection[address(freaksNGuilds)],
        msg.sender,
        freakIds,
        freaks
      );
      callsIndex++;
    }

    if (celestialIds.length > 0) {
      Celestial[] memory celestials = new Celestial[](celestialIds.length);
      for (uint256 i = 0; i < celestialIds.length; i++) {
        require(ownerOf[celestialIds[i]] == address(0), "CelestialCastle: token already staked");
        require(!freaksNGuilds.isFreak(celestialIds[i]), "CelestialCastle: not a celestial");
        ownerOf[celestialIds[i]] = msg.sender;
        celestials[i] = freaksNGuilds.getCelestialAttributes(celestialIds[i]);
        freaksNGuilds.transferFrom(msg.sender, address(this), celestialIds[i]);
      }
      calls[callsIndex] = abi.encodeWithSelector(
        CelestialCastle.retrieveCelestialIds.selector,
        reflection[address(freaksNGuilds)],
        msg.sender,
        celestialIds,
        celestials
      );
      callsIndex++;
    }

    if (fbxAmount > 0) {
      freaksBucks.burn(msg.sender, fbxAmount);
      calls[callsIndex] = abi.encodeWithSelector(
        CelestialCastle.retrieveBucks.selector,
        reflection[address(freaksBucks)],
        msg.sender,
        fbxAmount
      );
    }

    portal.sendMessage(abi.encode(reflection[address(this)], calls));
  }

  /// @notice Retrieve freaks from castle when bridging.
  function retrieveFreakIds(
    address fng,
    address owner,
    uint256[] calldata freakIds,
    Freak[] calldata freakAttributes
  ) external onlyPortal {
    for (uint256 i = 0; i < freakIds.length; i++) {
      delete ownerOf[freakIds[i]];
      IFnG(fng).transferFrom(address(this), owner, freakIds[i]);
      IFnG(fng).setFreakAttributes(freakIds[i], freakAttributes[i]);
    }
  }

  /// @notice Retrieve celestials from castle when bridging.
  function retrieveCelestialIds(
    address fng,
    address owner,
    uint256[] calldata celestialIds,
    Celestial[] calldata celestialAttributes
  ) external onlyPortal {
    for (uint256 i = 0; i < celestialIds.length; i++) {
      delete ownerOf[celestialIds[i]];
      IFnG(fng).transferFrom(address(this), owner, celestialIds[i]);
      IFnG(fng).setCelestialAttributes(celestialIds[i], celestialAttributes[i]);
    }
  }

  // function callFnG(bytes calldata data) external onlyPortal {
  //   (bool succ, ) = freaksNGuilds.call(data)
  // }

  /// @notice Retrive freaks bucks to `owner` when bridging.
  function retrieveBucks(
    address fbx,
    address owner,
    uint256 value
  ) external onlyPortal {
    IFBX(fbx).mint(owner, value);
  }

  /// @notice Set contract reflection address on L2.
  function setReflection(address key, address value) external onlyOwner {
    reflection[key] = value;
    reflection[value] = key;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function setIsTravelEnabled(bool newIsTravelEnabled) external onlyOwner {
    isTravelEnabled = newIsTravelEnabled;
  }

      /// @notice Withdraw `amount` of ether to msg.sender.
  function withdraw(uint256 amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
  }

  /// @notice Withdraw `amount` of `token` to the sender.
  function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
    token.transfer(msg.sender, amount);
  }

  /// @notice Withdraw `tokenId` of `token` to the sender.
  function withdrawERC721(IERC721 token, uint256 tokenId) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId);
  }

  /// @notice Withdraw `tokenId` with amount of `value` from `token` to the sender.
  function withdrawERC1155(
    IERC1155 token,
    uint256 tokenId,
    uint256 value
  ) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId, value, "");
  }
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./Structs.sol";

interface MetadataHandlerLike {
  function getCelestialTokenURI(uint256 id, Celestial memory character) external view returns (string memory);

  function getFreakTokenURI(uint256 id, Freak memory character) external view returns (string memory);
}

interface InventoryCelestialsLike {
  function getAttributes(Celestial memory character, uint256 id) external pure returns (bytes memory);

  function getImage(uint256 id) external view returns (bytes memory);
}

interface InventoryFreaksLike {
  function getAttributes(Freak memory character, uint256 id) external view returns (bytes memory);

  function getImage(Freak memory character) external view returns (bytes memory);
}

interface IFnG {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function ownerOf(uint256 id) external returns (address owner);

  function isFreak(uint256 tokenId) external view returns (bool);

  function getSpecies(uint256 tokenId) external view returns (uint8);

  function getFreakAttributes(uint256 tokenId) external view returns (Freak memory);

  function setFreakAttributes(uint256 tokenId, Freak memory attributes) external;

  function getCelestialAttributes(uint256 tokenId) external view returns (Celestial memory);

  function setCelestialAttributes(uint256 tokenId, Celestial memory attributes) external;

  function burn(uint tokenId) external;
}

interface IFBX {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

interface ICKEY {
  function ownerOf(uint256 tokenId) external returns (address);
}

interface IVAULT {
  function depositsOf(address account) external view returns (uint256[] memory);
  function _depositedBlocks(address account, uint256 tokenId) external returns(uint256);
}

interface ERC20Like {
  function balanceOf(address from) external view returns (uint256 balance);

  function burn(address from, uint256 amount) external;

  function mint(address from, uint256 amount) external;

  function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
  function mint(
    address to,
    uint256 id,
    uint256 amount
  ) external;

  function burn(
    address from,
    uint256 id,
    uint256 amount
  ) external;
}

interface ERC721Like {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function transfer(address to, uint256 id) external;

  function ownerOf(uint256 id) external returns (address owner);

  function mint(address to, uint256 tokenid) external;
}

interface PortalLike {
  function sendMessage(bytes calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./lib/Base64.sol";
import "./interfaces/Interfaces.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// solhint-disable quotes

contract MetadataHandler is Ownable {
  using Strings for uint256;

  InventoryCelestialsLike public inventoryCelestials;

  InventoryFreaksLike public inventoryFreaks;

  constructor(address newInventoryCelestials, address newInventoryFreaks) {
    inventoryCelestials = InventoryCelestialsLike(newInventoryCelestials);
    inventoryFreaks = InventoryFreaksLike(newInventoryFreaks);
  }

  function setInventories(address newInventoryCelestials, address newInventoryFreaks) external onlyOwner {
    inventoryCelestials = InventoryCelestialsLike(newInventoryCelestials);
    inventoryFreaks = InventoryFreaksLike(newInventoryFreaks);
  }

  function getCelestialTokenURI(uint256 id, Celestial memory character) external view returns (string memory) {
    bytes memory name = abi.encodePacked("Celestial #", id.toString());
    bytes memory attributes = inventoryCelestials.getAttributes(character, id);
    bytes memory svg = _buildSVG(inventoryCelestials.getImage(id));
    return string(_buildJSON(name, attributes, svg));
  }

  function getFreakTokenURI(uint256 id, Freak memory character) external view returns (string memory) {
    bytes memory name = abi.encodePacked("Freak #", id.toString());
    bytes memory attributes = inventoryFreaks.getAttributes(character, id);
    bytes memory svg = _buildSVG(inventoryFreaks.getImage(character));
    return string(_buildJSON(name, attributes, svg));
  }

  function _buildSVG(bytes memory data) internal pure returns (bytes memory) {
    bytes memory output = abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="character" width="100%" height="100%" version="1.1" viewBox="0 0 64 64">',
      data,
      "<style>#character{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>"
    );

    return abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(output)));
  }

  function _buildJSON(
    bytes memory name,
    bytes memory attributes,
    bytes memory image
  ) internal pure returns (bytes memory) {
    bytes memory output = abi.encodePacked(
      '{"name":"',
      name,
      '","description":"Build your guild, battle your foes with the first on-chain PvP. Hunt for fortune and glory shall be yours!","attributes":[',
      attributes,
      '],"image":"',
      image,
      '"}'
    );

    return abi.encodePacked("data:application/json;base64,", Base64.encode(output));
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

library Base64 {
  string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/Interfaces.sol";
import "./interfaces/Structs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "erc721a/contracts/ERC721A.sol";
import "../base/controllable.sol";

contract FreaksNGuilds is Controllable, Pausable, Ownable, ERC721A("Freaks N Guilds", "FnG") {
  using MerkleProof for bytes32[];

  /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/

  bytes32 internal entropySauce;
  bytes32 public whitelistRoot;

  uint256 public constant FNG_PRICE_ETH_PUBLIC = 0.099 ether;
  uint256 public constant FNG_PRICE_ETH_WHITELIST = 0.09 ether;
  uint256 public constant FNG_PRICE_ETH_HOLDERS = 0.07 ether;
  uint256 public constant FNG_PRICE_FBX = 1000 ether;

  IFBX public fbx;
  ICKEY public ckey;
  IVAULT public vault;

  uint256 public maxSupply;
  uint256 public maxCelestialSupply;
  uint256 public celestialSupply;
  uint256 public freakSupply;
  uint256 public saleState;
  uint256 public maxWlMints;
  uint256 public maxPubMints;

  uint8 internal cBody = 1;
  uint8 internal cLevel = 1;
  uint8 internal cPP = 1;
  uint8 internal offHand = 0;

  mapping(uint256 => Freak) public freaks;
  mapping(uint256 => Celestial) public celestials;

  /// mapping of token ids to bool indicating whether the key has been used to mint
  mapping(uint256 => bool) public redeemedCKEYs;
  /// mapping of whitelisted addresses indicating quantity minted through whitelist mint
  mapping(address => uint256) public whitelistMinted;
  /// mapping of public addresses indicating quantity minted through public mint
  mapping(address => uint256) public publicMinted;

  MetadataHandlerLike public metadaHandler;

  /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

  modifier noCheaters() {
    uint256 size = 0;
    address acc = msg.sender;
    assembly {
      size := extcodesize(acc)
    }

    require(msg.sender == tx.origin, "you're trying to cheat!");
    require(size == 0, "you're trying to cheat!");
    _;

    // We'll use the last caller hash to add entropy to next caller
    entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
  }



  /*///////////////////////////////////////////////////////////////
                    Constructor
    //////////////////////////////////////////////////////////////*/
  constructor(
    uint256 _maxSupply,
    uint256 _maxCelestialSupply,
    address _fbx,
    address _ckey,
    address _metadataHandler,
    address _vault,
    bytes32 _whitelistRoot
  ) {
    maxSupply = _maxSupply;
    maxCelestialSupply = _maxCelestialSupply;
    fbx = IFBX(_fbx);
    ckey = ICKEY(_ckey);
    vault = IVAULT(_vault);
    metadaHandler = MetadataHandlerLike(_metadataHandler);
    whitelistRoot = _whitelistRoot;
    maxWlMints = 2;
    maxPubMints = 4;
    _pause();
  }

  /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  /// @dev Call the `metadaHandler` to retrieve the tokenURI for each character.
  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "token does not exist");
    if (!isFreak(id)) {
      // Celestial
      Celestial memory celestial = celestials[id];
      return metadaHandler.getCelestialTokenURI(id, celestial);
    } else if (isFreak(id)) {
      // Freak
      Freak memory freak = freaks[id];
      return metadaHandler.getFreakTokenURI(id, freak);
    } else {
      return ""; // placeholder for compile
    }
  }

  /*///////////////////////////////////////////////////////////////
                   MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  /// @notice Buy one or more tokens with ETH.
  function mintWithETH(uint256 amount) external payable noCheaters whenNotPaused {
    uint256 supply = _currentIndex;
    require(supply + amount <= maxSupply + 1, "maximum supply reached");
    if (msg.sender != owner()) {
      require(amount > 0 && amount + publicMinted[msg.sender] <= maxPubMints, "Invalid quantity");
      require(saleState == 2, "Mint stage not live");
      require(msg.value >= amount * FNG_PRICE_ETH_PUBLIC, "invalid ether amount");
    }
    uint256 rand = _rand();
    for (uint256 i = 0; i < amount; i++) {
      uint256 rNum = rand % 100;
      if (rNum < 15 && celestialSupply < 1500) {
        _revealCelestial(rNum, supply);
        rand = _randomize(rand, supply);
      } else {
        _revealFreak(rNum, supply);
        rand = _randomize(rand, supply);
      }
      supply += 1;
    }
    _mint(msg.sender, amount, "", false);
    publicMinted[msg.sender] += amount;
  }

  /// @notice Buy one or more tokens with ETH while holding celestial key.
  function mintWithETHHoldersOnly(uint256[] memory ckeyIds) external payable noCheaters whenNotPaused {
    require(saleState != 2, "Mint stage not live");
    uint256 supply = _currentIndex;
    uint256 amount = ckeyIds.length;
    require(amount > 0, "invalid token ID");
    require(supply + amount <= maxSupply + 1, "maximum supply reached");
    if (msg.sender != owner()) {
      require(msg.value >= amount * FNG_PRICE_ETH_HOLDERS, "invalid ether amount");
    }
    uint256 rand = _rand();
    for (uint256 i = 0; i < amount; i++) {
      require(msg.sender == ckey.ownerOf(ckeyIds[i]) || vault._depositedBlocks(msg.sender, ckeyIds[i]) != 0, "invalid token ID");
      require(!redeemedCKEYs[ckeyIds[i]], "token already used to mint");
      redeemedCKEYs[ckeyIds[i]] = true;
      uint256 rNum = rand % 100;
      if (rNum < 15 && celestialSupply < 1500) {
        _revealCelestial(rNum, supply);
        rand = _randomize(rand, supply);
      } else {
        _revealFreak(rNum, supply);
        rand = _randomize(rand, supply);
      }
      supply += 1;
    }
    _mint(msg.sender, amount, "", false);
  }

  /// @notice Buy one or more tokens with ETH with whitelisted address
  function mintWithETHWhitelist(uint256 amount, bytes32[] memory proof) external payable whenNotPaused {
    require(saleState == 1, "Mint stage not live");
    uint256 supply = _currentIndex;
    require(supply + amount <= maxSupply + 1, "maximum supply reached");
    require(amount > 0 && amount + whitelistMinted[msg.sender] <= maxWlMints, "Invalid quantity for whitelist mint");
    require(msg.value >= amount * FNG_PRICE_ETH_WHITELIST, "invalid ether amount");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(proof.verify(whitelistRoot, leaf), "Invalid proof");
    uint256 rand = _rand();
    for (uint256 i = 0; i < amount; i++) {
      uint256 rNum = rand % 100;
      if (rNum < 15 && celestialSupply < 1500) {
        _revealCelestial(rNum, supply);
        rand = _randomize(rand, supply);
      } else {
        _revealFreak(rNum, supply);
        rand = _randomize(rand, supply);
      }
      supply += 1;
    }
    _mint(msg.sender, amount, "", false);
    whitelistMinted[msg.sender] += amount;
  }

  /// @notice Buy one or more tokens with FBX.
  function mintWithFBX(uint256 amount) external noCheaters whenNotPaused {
    require(saleState != 2, "Mint stage not live");
    uint256 supply = _currentIndex;
    require(supply + amount <= maxSupply + 1, "maximum supply reached");
    uint256 rand = _rand();
    for (uint256 i = 0; i < amount; i++) {
      uint256 rNum = rand % 100;
      if (rNum < 15 && celestialSupply < 1500) {
        _revealCelestial(rNum, supply);
        rand = _randomize(rand, supply);
      } else {
        _revealFreak(rNum, supply);
        rand = _randomize(rand, supply);
      }
      supply++;
    }
    fbx.burn(msg.sender, FNG_PRICE_FBX * amount);
    _mint(msg.sender, amount, "", false);
  }

  function burn(uint256 tokenId) external onlyOwner {
    if(isFreak(tokenId)){
      delete freaks[tokenId];
      freakSupply -= 1;
    }else{
      delete celestials[tokenId];
      celestialSupply -= 1;
    }
    _burn(tokenId);
  }

  function _revealCelestial(uint256 rNum, uint256 id) internal {
    uint256 _rNum = _randomize(rNum, id);
    uint8 healthMod = _calcMod(_rNum);
    _rNum = _randomize(_rNum, id);
    uint8 powMod = _calcMod(_rNum);
    Celestial memory celestial = Celestial(healthMod, powMod, cPP, cLevel);
    celestials[id] = celestial;
    celestialSupply += 1;
  }

  function _revealFreak(uint256 rNum, uint256 id) internal {
    uint256 _rNum = _randomize(rNum, id);
    uint8 species = uint8((_rNum % 3) + 1);
    _rNum = _randomize(_rNum, id);
    uint8 mainHand = uint8((_rNum % 3) + 1);
    _rNum = _randomize(_rNum, id);
    uint8 body = uint8((_rNum % 3) + 1);
    _rNum = _randomize(_rNum, id);
    uint8 power = _calcPow(species, _rNum);
    _rNum = _randomize(_rNum, id);
    uint8 health = _calcHealth(species, _rNum);
    _rNum = _randomize(_rNum, id);
    uint8 armor = uint8((_rNum % 3) + 1); 
    uint8 criticalStrikeMod = 0;
    Freak memory freak = Freak(species, body, armor, mainHand, offHand, power, health, criticalStrikeMod);
    freaks[id] = freak;
    freakSupply += 1;
  }

  /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

  function getFreakAttributes(uint256 tokenId) external view returns (Freak memory) {
    require(_exists(tokenId), "token does not exist");
    return (freaks[tokenId]);
  }

  function getCelestialAttributes(uint256 tokenId) external view returns (Celestial memory) {
    require(_exists(tokenId), "token does not exist");
    return (celestials[tokenId]);
  }

  function isFreak(uint256 tokenId) public view returns (bool) {
    require(_exists(tokenId), "token does not exist");
    return freaks[tokenId].species != 0 ? true : false;
  }

  function getSpecies(uint256 tokenId) external view returns (uint8) {
    require(isFreak(tokenId) == true);
    return freaks[tokenId].species;
  }

  function getTokens(address addr) external view returns (uint256[] memory tokens) {
    uint256 balanceLength = balanceOf(addr);
    tokens = new uint256[](balanceLength);
    uint256 index = 0;
    for (uint256 j =  1; j < _currentIndex; j++) {
      if (ownerOf(j) == addr) {
        tokens[index] = j;
        index += 1;
      }
    }
    return tokens;
  }

  /*///////////////////////////////////////////////////////////////
                    INTERNAL  HELPERS
    //////////////////////////////////////////////////////////////*/

  /// @dev Overriden to start mints at id #1.
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /// @dev Create a bit more of randomness
  function _randomize(uint256 rand, uint256 spicy) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(rand, spicy)));
  }

  function _rand() internal view returns (uint256) {
    return
      uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropySauce)));
  }

  function _calcMod(uint256 rNum) internal pure returns (uint8) {
    return uint8((rNum % 4) + 5);
  }

  function _calcHealth(uint8 species, uint256 rNum) internal pure returns (uint8) {
    uint8 baseHealth = 90; // ogre
    if (species == 1) {
      baseHealth = 50; // troll
    } else if (species == 2) {
      baseHealth = 70; // fairy
    }
    // might need to cast? we will see...
    return uint8((rNum % 21) + baseHealth);
  }

  function _calcPow(uint8 species, uint256 rNum) internal pure returns (uint8) {
    uint8 basePow = 90; //ogre
    if (species == 1) {
      basePow = 115; // troll
    } else if (species == 2) {
      basePow = 65; //fairy
    }
    // might need to cast? we will see...
    return uint8((rNum % 21) + basePow);
  }

  /*///////////////////////////////////////////////////////////////
                    ADMIN
  //////////////////////////////////////////////////////////////*/

  function setSaleState(uint256 newSaleState) external onlyOwner {
    saleState = newSaleState;
  }

  /// @notice See {ERC721-isApprovedForAll}.
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    // if (!marketplacesApproved) return auth[operator] || super.isApprovedForAll(owner, operator);
    return
      isController(operator) ||
      // operator == address(ProxyRegistry(opensea).proxies(owner)) ||
      // operator == looksrare ||
      super.isApprovedForAll(owner, operator);
  }

  function setMaxMints(uint256 _maxWlMints, uint256 _maxPubMints) external onlyOwner {
    maxWlMints = _maxWlMints;
    maxPubMints = _maxPubMints;
  }

  function setPause(bool _pauseToggle) external onlyOwner {
    if (_pauseToggle == true) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setWhitelistRoot(bytes32 root) external onlyOwner {
    whitelistRoot = root;
  }

  function setContracts(address _fbx, address _ckey, address _vault, address _metadataHandler) external onlyOwner {
    fbx = IFBX(_fbx);
    ckey = ICKEY(_ckey);
    vault = IVAULT(_vault);
    metadaHandler = MetadataHandlerLike(_metadataHandler);
  }

    /// @notice Withdraw `amount` of ether to msg.sender.
  function withdraw(uint256 amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
  }

  /// @notice Withdraw `amount` of `token` to the sender.
  function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
    token.transfer(msg.sender, amount);
  }

  /// @notice Withdraw `tokenId` of `token` to the sender.
  function withdrawERC721(IERC721 token, uint256 tokenId) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId);
  }

  /// @notice Withdraw `tokenId` with amount of `value` from `token` to the sender.
  function withdrawERC1155(
    IERC1155 token,
    uint256 tokenId,
    uint256 value
  ) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId, value, "");
  }

  /// @notice Add or edit contract controllers.
  /// @param addrs Array of addresses to be added/edited.
  /// @param state New controller state of addresses.
  function setControllers(address[] calldata addrs, bool state) external onlyOwner {
    for (uint256 i = 0; i < addrs.length; i++) super._setController(addrs[i], state);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/Interfaces.sol";
import "./interfaces/Structs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "../base/controllable.sol";

contract FreaksNGuildsPolygon is Controllable, Pausable, Ownable, ERC721A("Freaks N Guilds", "FnG") {
  /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/

  bytes32 internal entropySauce;

  uint256 public constant FNG_STARTING_PRICE_FBX = 2000 ether;
  uint256 public constant PRICE_INCREASE = 500 ether;

  IFBX public fbx;

  uint256 public maxSupply;
  uint256 public maxCelestialSupply;
  uint256 public celestialSupply;
  uint256 public freakSupply;
  uint256 public mintPrice;
  
  uint8 internal cBody = 1;
  uint8 internal cLevel = 1;
  uint8 internal cPP = 1;
  uint8 internal offHand = 0;
  uint256 internal incrementor;

  mapping(uint256 => Freak) public freaks;
  mapping(uint256 => Celestial) public celestials;

  MetadataHandlerLike public metadaHandler;

  /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

  modifier noCheaters() {
    uint256 size = 0;
    address acc = msg.sender;
    assembly {
      size := extcodesize(acc)
    }

    require(msg.sender == tx.origin, "you're trying to cheat!");
    require(size == 0, "you're trying to cheat!");
    _;

    // We'll use the last caller hash to add entropy to next caller
    entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
  }

  modifier onlyOwnerOrController(){
    require(isController(msg.sender) || msg.sender == owner(), "Not Authorized");
    _;
  }

  /*///////////////////////////////////////////////////////////////
                    Constructor
    //////////////////////////////////////////////////////////////*/
  constructor(
    uint256 _maxSupply,
    uint256 _maxCelestialSupply,
    address _fbx,
    address _metadaHandler
  ) {
    maxSupply = _maxSupply;
    maxCelestialSupply = _maxCelestialSupply;
    fbx = IFBX(_fbx);
    metadaHandler = MetadataHandlerLike(_metadaHandler);
    incrementor = 1000 ether;
    mintPrice = 2000 ether;
    _pause();
  }

  /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/


  /// @dev Call the `metadaHandler` to retrieve the tokenURI for each character.
  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "token does not exist");
    if (!isFreak(id)) {
      // Celestial
      Celestial memory celestial = celestials[id];
      return metadaHandler.getCelestialTokenURI(id, celestial);
    } else if (isFreak(id)) {
      // Freak
      Freak memory freak = freaks[id];
      return metadaHandler.getFreakTokenURI(id, freak);
    } else {
      return ""; // placeholder for compile
    }
  }

  /*///////////////////////////////////////////////////////////////
                   MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  /// @notice Buy one or more tokens with FBX.
  function mintWithFBX(uint256 amount) external noCheaters whenNotPaused{
    uint256 supply = _currentIndex;
    require(supply + amount <= (maxSupply + 1), "maximum supply reached");
    uint256 currentPrice;
    uint256 rand = _rand();
    for (uint256 i = 0; i < amount; i++) {
      uint256 rNum = rand % 100;
      uint256 celestialOdds = 12;
      uint256 celestialMax = 1200;
      if(supply > 20000){
        celestialOdds = 10;
        celestialMax = 1000;
      }
      currentPrice += mintPrice;
      if (rNum < celestialOdds && celestialSupply < celestialMax) {
        _revealCelestial(rNum, supply);
        rand = _randomize(rand, supply);
      } else {
        _revealFreak(rNum, supply);
        rand = _randomize(rand, supply);
      }
      if (supply % 2000 == 0) {
        incrementor = incrementor + 500 ether;
        mintPrice = mintPrice + incrementor;
      }
      supply++;
    }

    fbx.burn(msg.sender, currentPrice);
    _mint(msg.sender, amount, "", false);
  }

  function burn(uint256 tokenId) external onlyOwnerOrController {
    if(isFreak(tokenId)){
      delete freaks[tokenId];
      freakSupply -= 1;
    }else{
      delete celestials[tokenId];
      celestialSupply -= 1;
    }
    _burn(tokenId);
  }

  function _revealCelestial(uint256 rNum, uint256 id) internal {
    uint256 _rNum = _randomize(rNum, id);
    uint8 healthMod = _calcMod(id, _rNum);
    _rNum = _randomize(_rNum, id);
    uint8 powMod = _calcMod(id, _rNum);
    Celestial memory celestial = Celestial(healthMod, powMod, cPP, cLevel);
    celestials[id] = celestial;
    celestialSupply += 1;
  }

  function _revealFreak(uint256 rNum, uint256 id) internal {
    uint256 _rNum = _randomize(rNum, id);
    uint8 species = uint8((_rNum % 3) + 1);
    _rNum = _randomize(_rNum, id);
    uint8 mainHand = uint8((_rNum % 3) + 1);
    _rNum = _randomize(_rNum, id);
    uint8 body = uint8((_rNum % 3) + 1);
    _rNum = _randomize(_rNum, id);
    uint8 power = _calcPow(species, _rNum);
    _rNum = _randomize(_rNum, id);
    uint8 health = _calcHealth(species, _rNum);
    _rNum = _randomize(_rNum, id);
    uint8 armor = uint8((_rNum % 3) + 1); 
    uint8 criticalStrikeMod = 0;
    Freak memory freak = Freak(species, body, armor, mainHand, offHand, power, health, criticalStrikeMod);
    freaks[id] = freak;
    freakSupply += 1;
  }



  /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

  function getFreakAttributes(uint256 tokenId) external view returns (Freak memory) {
    require(_exists(tokenId), "token does not exist");
    return (freaks[tokenId]);
  }

  function getCelestialAttributes(uint256 tokenId) external view returns (Celestial memory) {
    require(_exists(tokenId), "token does not exist");
    return (celestials[tokenId]);
  }

  function isFreak(uint256 tokenId) public view returns (bool) {
    require(_exists(tokenId), "token does not exist");
    return freaks[tokenId].species != 0 ? true : false;
  }

  function getSpecies(uint256 tokenId) external view returns (uint8) {
    require(isFreak(tokenId) == true);
    return freaks[tokenId].species;
  }

  function getTokens(address addr) external view returns (uint256[] memory tokens) {
    uint256 balanceLength = balanceOf(addr);
    tokens = new uint256[](balanceLength);
    uint256 index = 0;
    for (uint256 j =  1; j < _currentIndex; j++) {
      if (ownerOf(j) == addr) {
        tokens[index] = j;
        index += 1;
      }
    }
    return tokens;
  } 


  /*///////////////////////////////////////////////////////////////
                    INTERNAL  HELPERS
    //////////////////////////////////////////////////////////////*/

  /// @dev Overriden to start mints at id #1.
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /// @dev Create a bit more of randomness
  function _randomize(uint256 rand, uint256 spicy) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(rand, spicy)));
  }

  function _rand() internal view returns (uint256) {
    return
      uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropySauce)));
  }

  function _calcMod(uint256 tokenId, uint256 rNum) internal pure returns (uint8) {
    // uint256 _rNum = _randomize(rNum, _rand(), id);
    // might need to cast? we will see...
    uint8 baseMod = 4;
    uint8 delta = 3;
    if(tokenId > 20000){
      baseMod = 2;
      delta = 4;
    }
    return uint8((rNum % delta) + baseMod);
  }

  function _calcHealth(uint8 species, uint256 rNum) internal pure returns (uint8) {
    uint8 baseHealth = 90; // ogre
    if (species == 1) {
      baseHealth = 50; // troll
    } else if (species == 2) {
      baseHealth = 70; // fairy
    }
    // might need to cast? we will see...
    return uint8((rNum % 21) + baseHealth);
  }

  function _calcPow(uint8 species, uint256 rNum) internal pure returns (uint8) {
    uint8 basePow = 90; //ogre
    if (species == 1) {
      basePow = 115; // troll
    } else if (species == 2) {
      basePow = 65; //fairy
    }
    // might need to cast? we will see...
    return uint8((rNum % 21) + basePow);
  }

  /*///////////////////////////////////////////////////////////////
                    ADMIN
  //////////////////////////////////////////////////////////////*/

  function setFreakAttributes(uint256 tokenId, Freak memory attributes) external onlyOwnerOrController {
    require(_exists(tokenId), "token does not exist");
    freaks[tokenId] = attributes;
    freakSupply += 1;
  }

  function setCelestialAttributes(uint256 tokenId, Celestial memory attributes) external onlyOwnerOrController {
    require(_exists(tokenId), "token does not exist");
    celestials[tokenId] = attributes;
    celestialSupply += 1;
  }

  function updateFreakAttributes(uint256 tokenId, Freak memory attributes) external onlyOwnerOrController {
    require(_exists(tokenId), "token does not exist");
    freaks[tokenId] = attributes;
  }

  function updateCelestialAttributes(uint256 tokenId, Celestial memory attributes) external onlyOwnerOrController {
    require(_exists(tokenId), "token does not exist");
    celestials[tokenId] = attributes;
  }

  function mintToContract(address to, uint256 amount) external onlyOwner {
    _safeMint(to, amount);
  }

  /// @notice See {ERC721-isApprovedForAll}.
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    // if (!marketplacesApproved) return auth[operator] || super.isApprovedForAll(owner, operator);
    return
      isController(operator) ||
      // operator == address(ProxyRegistry(opensea).proxies(owner)) ||
      // operator == looksrare ||
      super.isApprovedForAll(owner, operator);
  }

  function setPause(bool _pauseToggle) external onlyOwner {
    if (_pauseToggle == true) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setContracts(address _fbx, address _metadataHandler) external onlyOwner {
    fbx = IFBX(_fbx);
    metadaHandler = MetadataHandlerLike(_metadataHandler);
  }

  /// @notice Add or edit contract controllers.
  /// @param addrs Array of addresses to be added/edited.
  /// @param state New controller state of addresses.
  function setControllers(address[] calldata addrs, bool state) external onlyOwner {
    for (uint256 i = 0; i < addrs.length; i++) super._setController(addrs[i], state);
  }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {IFnG, IFBX} from "./interfaces/Interfaces.sol";
import "hardhat/console.sol";

contract Hunting is Ownable, ReentrancyGuard, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;

  /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

  struct StakeFreak {
    uint256 tokenId;
    uint256 lastClaimTime;
    address owner;
    uint256 species;
    uint256 ffIndex;
  }

  struct StakeCelestial {
    uint256 tokenId;
    address owner;
    uint256 value;
  }

  struct Epoch {
    uint256 favoredFreak;
    uint256 epochStartTime;
  }

  struct PoolConfig {
    uint256 guildSize;
    uint256 rate;
    uint256 minToExit;
  }

  /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/

  // reference to the FnG NFT contract
  IFnG public fngNFT;
  // reference to the $FBX contract for minting $FBX earnings
  IFBX public fbx;
  // maps tokenId to stake observatory
  mapping(uint256 => StakeCelestial) private observatory;
  // maps pool id to mapping of address to deposits
  mapping(uint256 => mapping(address => EnumerableSet.UintSet)) private _deposits;
  // maps pool id to mapping of token id to staked freak struct
  mapping(uint256 => mapping(uint256 => StakeFreak)) private stakingPools;
  // maps pool id to pool config
  mapping(uint256 => PoolConfig) public _poolConfig;
  // maps pool id to amount of freaks staked
  mapping(uint256 => uint256) private freaksStaked;
  // maps pool id to epoch struct
  mapping(uint256 => Epoch[]) private favors;
  // any rewards distributed when no celestials are staked
  uint256 private unaccountedRewards = 0;
  // amount of $FBX earned so far
  uint256 public totalFBXEarned;
  // timestamp of last epcoh change
  uint256 private lastEpoch;
  // number of celestials staked at a give time
  uint256 public cCounter;
  // unclaimed FBX pool for hunting observatory
  uint256 public fbxPerCelestial;
  // emergency rescue to allow unstaking without any checks but without $FBX
  bool public rescueEnabled;

  /*///////////////////////////////////////////////////////////////
                    EVENTS 
    //////////////////////////////////////////////////////////////*/
  // not needed until L2
  // event TokenStaked(address indexed owner, uint256 indexed tokenId, uint256 indexed pool);
  // event RewardClaimed(address indexed owner, uint256 indexed tokenId, uint256 indexed pool, uint256 reward);
  // event TokenUnstaked(address indexed owner, uint256 indexed tokenId, uint256 indexed pool, uint256 reward);
  // event CelestialsUnstaked(address indexed owner, uint256[] tokenIds, uint256 indexed pool, uint256 rewards);
  // event RewardStolen(address indexed owner, uint256 reward);
  // event EpochChanged(uint256 lastEpoch);

  /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

  modifier changeFFEpoch() {
    if (block.timestamp - lastEpoch >= 72 hours) {
      uint256 rand = _rand(msg.sender);
      for (uint256 i = 0; i < 3; i++) {
        uint256 favoredFreak = (rand % 3) + 1;
        Epoch memory epoch = Epoch(favoredFreak, block.timestamp);
        favors[i].push(epoch);
        rand = uint256(keccak256(abi.encodePacked(msg.sender, rand)));
      }
      lastEpoch = block.timestamp;
    }
    _;
  }

  /*///////////////////////////////////////////////////////////////
                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
  constructor(address _fng, address _fbx) {
    fngNFT = IFnG(_fng);
    fbx = IFBX(_fbx);
    backupEpochSet();
    _pause();
    cCounter = 0;
    _poolConfig[0] = PoolConfig(1, 200 ether, 200 ether);
    _poolConfig[1] = PoolConfig(3, 300 ether, 1800 ether);
    _poolConfig[2] = PoolConfig(5, 400 ether, 6000 ether);
    freaksStaked[0] = 0;
    freaksStaked[1] = 0;
    freaksStaked[2] = 0;
    rescueEnabled = false;
  }

  /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  // returns config for specific pool
  function getPoolConfig(uint256 pool) external view returns (PoolConfig memory) {
    require(pool < 3, "pool not found");
    return _poolConfig[pool];
  }

  // returns total freaks staked in specific pool
  function getStakedFreaks(uint256 pool) external view returns (uint256) {
    require(pool < 3, "pool not found");
    return freaksStaked[pool];
  }

  // returns deposited tokens of an address for each hunting ground and observatory
  function depositsOf(address account)
    external
    view
    returns (
      uint256[] memory,
      uint256[] memory,
      uint256[] memory,
      uint256[] memory
    )
  {
    return (
      _deposits[0][account].values(),
      _deposits[1][account].values(),
      _deposits[2][account].values(),
      _deposits[3][account].values()
    );
  }

  // returns rewards for freaks currently staked in specific pool
  // pool = 0: enclave, pool = 1: summit, pool = 2: ano
  function calculateFBXRewards(uint256[] memory tokenIds, uint256 pool) external view returns (uint256) {
    require(pool < 3, "pool not found");
    uint256 rewards = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      rewards += _calculateSingleFreakRewards(tokenIds[i], pool, _poolConfig[pool].rate);
    }
    return rewards;
  }

  // returns rewards for celestials currently staked in hunting observatory
  function calculateCelestialsRewards(uint256[] calldata tokenIds) external view returns (uint256 rewards) {
    rewards = 0;
    for (uint256 i; i < tokenIds.length; i++) {
      rewards += _calculateCelestialRewards(tokenIds[i]);
    }
    return rewards;
  }

  // returns current favored freak for specific pool
  // pool = 0: enclave, pool = 1: summit, pool = 2: ano
  function getFavoredFreak(uint256 pool) external view returns (uint256) {
    require(pool < 3, "pool not found");
    return favors[pool][favors[pool].length - 1].favoredFreak;
  }

  // returns list of all favored freaks of a specific pool since genesis
  function getFavoredFreaks(uint256 pool) external view returns (Epoch[] memory) {
    require(pool < 3, "pool not found");
    return favors[pool];
  }

  // emergency rescue function to transfer tokens from contract to owner based on specific pool
  function rescue(uint256[] calldata tokenIds, uint256 pool) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    require(pool <= 3, "Pool doesn't exist");
    if (pool == 3) {
      //observatory
      for (uint256 i = 0; i < tokenIds.length; i++) {
        require(observatory[tokenIds[i]].owner == msg.sender, "You don't own this token ser");
        delete observatory[tokenIds[i]];
        _deposits[pool][msg.sender].remove(tokenIds[i]);
        cCounter -= 1;
        fngNFT.transferFrom(address(this), msg.sender, tokenIds[i]);
      }
    } else {
      uint256 newTotal = 0;
      for (uint256 l = 0; l < tokenIds.length; l++) {
        require(stakingPools[pool][tokenIds[l]].owner == msg.sender, "You don't own this token ser");
        delete stakingPools[pool][tokenIds[l]];
        _deposits[pool][msg.sender].remove(tokenIds[l]);
        newTotal += 1;
        fngNFT.transferFrom(address(this), msg.sender, tokenIds[l]);
      }
      freaksStaked[pool] = freaksStaked[pool] - newTotal;
    }
  }

  /*///////////////////////////////////////////////////////////////
                    STAKING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function observe(uint256[] calldata tokenIds) external changeFFEpoch nonReentrant whenNotPaused {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(fngNFT.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");
      require(!fngNFT.isFreak(tokenIds[i]), "CELESTIALS ONLY!!! You are not worthy FREAK!");
      observatory[tokenIds[i]] = StakeCelestial({tokenId: tokenIds[i], owner: msg.sender, value: fbxPerCelestial});
      _deposits[3][msg.sender].add(tokenIds[i]);
      fngNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
      cCounter += 1;
    }
  }

  function hunt(uint256[] calldata tokenIds, uint256 pool) external changeFFEpoch nonReentrant whenNotPaused {
    require(pool <= 2, "pool doesn't exist ser");
    require(tokenIds.length % _poolConfig[pool].guildSize == 0, "incorrect amount of freaks");
    uint256 newTotal = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(fngNFT.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");
      require(fngNFT.isFreak(tokenIds[i]), "Can't get freaky without any freaks ser");
      stakingPools[pool][tokenIds[i]] = StakeFreak({
        tokenId: tokenIds[i],
        lastClaimTime: uint256(block.timestamp),
        owner: msg.sender,
        species: fngNFT.getSpecies(tokenIds[i]),
        ffIndex: favors[pool].length - 1
      });
      _deposits[pool][msg.sender].add(tokenIds[i]);
      newTotal += 1;
      fngNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
    freaksStaked[pool] = freaksStaked[pool] + newTotal;
  }

  /*///////////////////////////////////////////////////////////////
                    CLAIM/UNSTAKE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  // unstake or claim from multiple freaks in a specific pool
  function claimUnstake(
    uint256[] calldata tokenIds,
    uint256 pool,
    bool collectTax
  ) external changeFFEpoch nonReentrant {
    require(pool <= 2, "pool doesn't exist ser");
    require(tokenIds.length != 0, "can't claim no tokens");
    uint256 rewards = 0;
    require(tokenIds.length % _poolConfig[pool].guildSize == 0);
    if (collectTax == true) {
      rewards = _calculateManyFreakRewards(tokenIds, pool, false);
      _claimWithTax(rewards, pool, tokenIds);
    } else {
      rewards = _calculateManyFreakRewards(tokenIds, pool, true);
      _claimEvadeTax(rewards, pool, tokenIds);
    }
    require(rewards >= _poolConfig[pool].minToExit, "Not enough $FBX earned");
  }

  function unobserve(uint256[] calldata tokenIds) external changeFFEpoch nonReentrant {
    uint256 newCounter = 0;
    uint256 rewards = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(observatory[tokenIds[i]].owner == msg.sender, "You don't own this token ser");
      if (fbxPerCelestial != 0) {
        rewards += fbxPerCelestial - observatory[tokenIds[i]].value;
      } else {
        rewards += 0;
      }
      delete observatory[tokenIds[i]];
      _deposits[3][msg.sender].remove(tokenIds[i]);
      fngNFT.transferFrom(address(this), msg.sender, tokenIds[i]);
      newCounter += 1;
    }
    fbx.mint(msg.sender, rewards);
    totalFBXEarned += rewards;
    cCounter = cCounter - newCounter;
  }

  /*///////////////////////////////////////////////////////////////
                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function _calculateManyFreakRewards(uint256[] memory tokenIds, uint256 pool, bool unstake) internal returns (uint256 owed) {
    uint256 rewards = 0;
    uint256 newTotal = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(stakingPools[pool][tokenIds[i]].owner == msg.sender, "You don't own this token ser");
      rewards += _calculateSingleFreakRewards(tokenIds[i], pool, _poolConfig[pool].rate);
      newTotal += 1;
    }
    if (unstake == true) {
      freaksStaked[pool] = freaksStaked[pool] - newTotal;
    }
    return rewards;
  }

  function _calculateCelestialRewards(uint256 tokenId) internal view returns (uint256 reward) {
    if (fbxPerCelestial != 0) {
      reward = fbxPerCelestial - observatory[tokenId].value;
    }
    if (fbxPerCelestial == 0) {
      reward = 0;
    }
    return reward;
  }

  function _calculateSingleFreakRewards(
    uint256 tokenId,
    uint256 pool,
    uint256 rate
  ) internal view returns (uint256 owed) {
    uint256 timestamp = stakingPools[pool][tokenId].lastClaimTime;
    if (timestamp == 0) {
      return 0;
    }
    uint256 species = stakingPools[pool][tokenId].species;
    uint256 duration = block.timestamp - timestamp;
    uint256 favoredDuration = 0;
    for (uint256 j = stakingPools[pool][tokenId].ffIndex; j < favors[pool].length; j++) {
      uint256 startTime;
      if (j == stakingPools[pool][tokenId].ffIndex) {
        startTime = stakingPools[pool][tokenId].lastClaimTime;
      } else {
        startTime = favors[pool][j].epochStartTime;
      }
      if (favors[pool][j].favoredFreak == species) {
        uint256 epochEndTime;
        if (favors[pool].length == j + 1) {
          epochEndTime = block.timestamp;
        } else {
          epochEndTime = favors[pool][j + 1].epochStartTime;
        }
        favoredDuration += epochEndTime - startTime;
      }
    }
    uint256 ffOwed = ((favoredDuration * (rate + 20 ether)) / 1 days);
    uint256 baseOwed = 0;
    if (duration - favoredDuration != 0) {
      baseOwed = (((duration - favoredDuration) * rate) / 1 days);
    }
    owed = ffOwed + baseOwed;
    return owed;
  }

  function _claimWithTax(
    uint256 rewards,
    uint256 pool,
    uint256[] memory tokenIds
  ) internal {
    uint256 celestialRewards;
    celestialRewards = rewards / 5;
    if (cCounter == 0) {
      unaccountedRewards += (celestialRewards);
      rewards = rewards - celestialRewards;
      fbx.mint(msg.sender, rewards);
      totalFBXEarned += rewards;
    } else {
      fbxPerCelestial += (unaccountedRewards + celestialRewards) / cCounter;
      rewards = rewards - celestialRewards;
      unaccountedRewards = 0;
      fbx.mint(msg.sender, rewards);
      totalFBXEarned += rewards;
    }
    for (uint256 i; i < tokenIds.length; i++) {
      stakingPools[pool][tokenIds[i]] = StakeFreak({
        tokenId: tokenIds[i],
        lastClaimTime: uint256(block.timestamp),
        owner: msg.sender,
        species: fngNFT.getSpecies(tokenIds[i]),
        ffIndex: favors[pool].length - 1
      });
    }
  }

  function _claimEvadeTax(
    uint256 rewards,
    uint256 pool,
    uint256[] memory tokenIds
  ) internal {
    uint256 rNum = _rand(msg.sender) % 100;
    if (rNum < 33) {
      if (cCounter == 0) {
        unaccountedRewards += rewards;
      } else {
        fbxPerCelestial += (unaccountedRewards + rewards) / cCounter;
        unaccountedRewards = 0;
      }
    } else {
      fbx.mint(msg.sender, rewards);
      totalFBXEarned += rewards;
    }
    for (uint256 j; j < tokenIds.length; j++) {
      _deposits[pool][msg.sender].remove(tokenIds[j]);
      fngNFT.transferFrom(address(this), msg.sender, tokenIds[j]);
      delete stakingPools[pool][tokenIds[j]]; 
    }
  }

  function _rand(address acc) internal view returns (uint256) {
    bytes32 _entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    return
      uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, _entropySauce)));
  }

  /*///////////////////////////////////////////////////////////////
                   ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function setContracts(address _fngNFT, address _fbx) external onlyOwner {
    fngNFT = IFnG(_fngNFT);
    fbx = IFBX(_fbx);
  }

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * backup favored freak epoch changing function
   * in case it isn't triggered by claim/unstake function (unlikely)
   */
  function backupEpochSet() public changeFFEpoch onlyOwner {}

  /**
   * manually set rates for each pool
   */
  function setRates(
    uint256 _enclaveRate,
    uint256 _summitRate,
    uint256 _anoRate
  ) external onlyOwner {
    _poolConfig[0].rate = _enclaveRate;
    _poolConfig[1].rate = _summitRate;
    _poolConfig[2].rate = _anoRate;
  }

  /**
   * manually set minimum FBX required to exit each pool
   */
  function setMinExits(
    uint256 _minExitEnclave,
    uint256 _minExitSummit,
    uint256 _minExitAno
  ) external onlyOwner {
    _poolConfig[0].minToExit = _minExitEnclave;
    _poolConfig[1].minToExit = _minExitSummit;
    _poolConfig[2].minToExit = _minExitAno;
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Celestial Vault
contract CelestialVaultV2 is Ownable, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;

  /* -------------------------------------------------------------------------- */
  /*                                Farming State                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Rewards emitted per day staked.
  uint256 public rate;

  /// @notice Rewards of token 2 emitted per day staked.
  uint256 public rate2;

  /// @notice Endtime of token rewards.
  uint256 public endTime;

  /// @notice Endtime of token 2 rewards.
  uint256 public endTime2;

  /// @notice Staking token contract address.
  ICKEY public stakingToken;

  /// @notice Rewards token contract address.
  IFBX public rewardToken;

  /// @notice WRLD token contract address.
  IWRLD public rewardToken2;

  /// @notice Set of staked token ids by address.
  mapping(address => EnumerableSet.UintSet) internal _depositedIds;

  /// @notice Mapping of timestamps from each staked token id.
  // mapping(address => mapping(uint256 => uint256)) internal _depositedBlocks;
  mapping(address => mapping(uint256 => uint256)) public _depositedBlocks;

  /// @notice Mapping of tokenIds to their rate modifier
  mapping(uint256 => uint256) public _rateModifiers;

  bool public emergencyWithdrawEnabled;

  constructor(
    address newStakingToken,
    address newRewardToken,
    address newRewardToken2,
    uint256 newRate,
    uint256 newRate2
  ) {
    stakingToken = ICKEY(newStakingToken);
    rewardToken = IFBX(newRewardToken);
    rewardToken2 = IWRLD(newRewardToken2);
    rate = newRate;
    rate2 = newRate2;
    _pause();
  }

  /* -------------------------------------------------------------------------- */
  /*                                Farming Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Deposit tokens into the vault.
  /// @param tokenIds Array of token tokenIds to be deposited.
  function deposit(uint256[] memory tokenIds) external whenNotPaused {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      // Add the new deposit to the mapping
      _depositedIds[msg.sender].add(tokenIds[i]);
      _depositedBlocks[msg.sender][tokenIds[i]] = block.timestamp;

      // Transfer the deposited token to this contract
      stakingToken.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
  }

  /// @notice Withdraw tokens and claim their pending rewards.
  /// @param tokenIds Array of staked token ids.
  function withdraw(uint256[] memory tokenIds) external whenNotPaused {
    uint256 totalRewards;
    uint256 totalRewards2;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(_depositedIds[msg.sender].contains(tokenIds[i]), "Query for a token you don't own");
      totalRewards += _earned(_depositedBlocks[msg.sender][tokenIds[i]]);
      totalRewards2 += _earned2(_depositedBlocks[msg.sender][tokenIds[i]], tokenIds[i]);

      _depositedIds[msg.sender].remove(tokenIds[i]);
      delete _depositedBlocks[msg.sender][tokenIds[i]];

      stakingToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
    }
    rewardToken.mint(msg.sender, totalRewards);
    rewardToken2.transfer(msg.sender, totalRewards2);
  }

  /// @notice Claim pending token rewards.
  function claim() external whenNotPaused {
    uint256 totalRewards;
    uint256 totalRewards2;
    for (uint256 i = 0; i < _depositedIds[msg.sender].length(); i++) {
      // Mint the new tokens and update last checkpoint
      uint256 tokenId = _depositedIds[msg.sender].at(i);
      totalRewards += _earned(_depositedBlocks[msg.sender][tokenId]);
      totalRewards2 += _earned2(_depositedBlocks[msg.sender][tokenId], tokenId);
      _depositedBlocks[msg.sender][tokenId] = block.timestamp;
    }
    rewardToken.mint(msg.sender, totalRewards);
    rewardToken2.transfer(msg.sender, totalRewards2);
  }

  /// @notice Calculate total rewards for given account.
  /// @param account Holder address.
  function earned(address account) external view returns (uint256[] memory) {
    uint256 length = _depositedIds[account].length();
    uint256[] memory rewards = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
      uint256 tokenId = _depositedIds[account].at(i);
      rewards[i] = _earned(_depositedBlocks[account][tokenId]);
    }
    return rewards;
  }

  /// @notice Calculate total WRLD token rewards for given account.
  /// @param account Holder address.
  function earned2(address account) external view returns (uint256[] memory) {
    uint256 length = _depositedIds[account].length();
    uint256[] memory rewards = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
      uint256 tokenId = _depositedIds[account].at(i);
      rewards[i] = _earned2(_depositedBlocks[account][tokenId], tokenId);
    }
    return rewards;
  }

  /// @notice Internally calculates rewards for given token.
  /// @param timestamp Deposit timestamp.
  function _earned(uint256 timestamp) internal view returns (uint256) {
    if (timestamp == 0) return 0;
    uint256 end;
    if (endTime == 0) {
      // endtime not set
      end = block.timestamp;
    } else {
      end = Math.min(block.timestamp, endTime);
    }
    if (timestamp > end) {
      return 0;
    }
    return ((end - timestamp) * rate) / 1 days;
  }

  /// @notice Internally calculates WRLD rewards for given token.
  /// @param timestamp Deposit timestamp.
  function _earned2(uint256 timestamp, uint256 tokenId) internal view returns (uint256) {
    if (timestamp == 0) return 0;
    uint256 rateForTokenId = rate2 + _rateModifiers[tokenId];
    uint256 end;
    if (endTime2 == 0) {
      // endtime not set
      end = block.timestamp;
    } else {
      end = Math.min(block.timestamp, endTime2);
    }
    if (timestamp > end) {
      return 0;
    }
    return ((end - timestamp) * rateForTokenId) / 1 days;
  }

  /// @notice Retrieve token ids deposited by account.
  /// @param account Token owner address.
  function depositsOf(address account) external view returns (uint256[] memory) {
    uint256 length = _depositedIds[account].length();
    uint256[] memory ids = new uint256[](length);

    for (uint256 i = 0; i < length; i++) ids[i] = _depositedIds[account].at(i);
    return ids;
  }

  function emergencyWithdraw(uint256[] memory tokenIds) external whenNotPaused {
    require(emergencyWithdrawEnabled, "Emergency withdraw not enabled");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(_depositedIds[msg.sender].contains(tokenIds[i]), "Query for a token you don't own");
      _depositedIds[msg.sender].remove(tokenIds[i]);
      delete _depositedBlocks[msg.sender][tokenIds[i]];
      stakingToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Set the new token rewards rate.
  /// @param newRate Emission rate in wei.
  function setRate(uint256 newRate) external onlyOwner {
    rate = newRate;
  }

  /// @notice Set the new token rewards rate.
  /// @param newRate2 Emission rate in wei.
  function setRate2(uint256 newRate2) external onlyOwner {
    rate2 = newRate2;
  }

  /// @notice Set the new token rewards end time.
  /// @param newEndTime End time of token 1 yield
  function setEndTime(uint256 newEndTime) external onlyOwner {
    endTime = newEndTime;
  }

  /// @notice Set the new token rewards end time.
  /// @param newEndTime2 End time of token 2 yield
  function setEndTime2(uint256 newEndTime2) external onlyOwner {
    endTime2 = newEndTime2;
  }

  /// @notice set rate modifier for given token Ids.
  /// @param tokenIds token Ids to set rate modifier for.
  /// @param rateModifier value of rate modifier
  function setRateModifier(uint256[] memory tokenIds, uint256 rateModifier) external onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _rateModifiers[tokenIds[i]] = rateModifier;
    }
  }

  /// @notice Set the new staking token contract address.
  /// @param newStakingToken Staking token address.
  function setStakingToken(address newStakingToken) external onlyOwner {
    stakingToken = ICKEY(newStakingToken);
  }

  /// @notice Set the new reward token contract address.
  /// @param newRewardToken Rewards token address.
  function setRewardToken(address newRewardToken) external onlyOwner {
    rewardToken = IFBX(newRewardToken);
  }

  /// @notice Set the new reward token contract address.
  /// @param newRewardToken2 Rewards token address.
  function setRewardToken2(address newRewardToken2) external onlyOwner {
    rewardToken2 = IWRLD(newRewardToken2);
  }

  /// @notice Pause the contract.
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpause the contract.
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice Withdraw `amount` of `token` to the sender.
  function withdrawERC20(IERC20 token, uint256 amount) external onlyOwner {
    token.transfer(msg.sender, amount);
  }

  /// @notice enable emergency withdraw
  function setEmergencyWithdrawEnabled(bool newEmergencyWithdrawEnabled) external onlyOwner {
    emergencyWithdrawEnabled = newEmergencyWithdrawEnabled;
  }
}

interface ICKEY {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) external;
}

interface IFBX {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

interface IWRLD {
  function transfer(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20MockTester is ERC20("TST", "TST") {
  mapping(address => bool) public auth;

  modifier onlyAuth() {
    require(auth[msg.sender], "Sender is not authorized");
    _;
  }

  function setAuth(address[] calldata addresses, bool authorized) external {
    for (uint256 i = 0; i < addresses.length; i++) auth[addresses[i]] = authorized;
  }

  function mint(address to, uint256 value) external onlyAuth {
    super._mint(to, value);
  }

  function burn(address from, uint256 value) external onlyAuth {
    super._burn(from, value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20("", "") {
  mapping(address => bool) public auth;

  modifier onlyAuth() {
    require(auth[msg.sender], "Sender is not authorized");
    _;
  }

  function setAuth(address[] calldata addresses, bool authorized) external {
    for (uint256 i = 0; i < addresses.length; i++) auth[addresses[i]] = authorized;
  }

  function mint(address to, uint256 value) external onlyAuth {
    super._mint(to, value);
  }

  function burn(address from, uint256 value) external onlyAuth {
    super._burn(from, value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Celestial Vault
contract CelestialVault is Ownable, Pausable {
  using EnumerableSet for EnumerableSet.UintSet;

  /* -------------------------------------------------------------------------- */
  /*                                Farming State                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Rewards end timestamp.
  uint256 public endTime;

  /// @notice Rewards emitted per day staked.
  uint256 public rate;

  /// @notice Staking token contract address.
  ICKEY public stakingToken;

  /// @notice Rewards token contract address.
  IFBX public rewardToken;

  /// @notice Set of staked token ids by address.
  mapping(address => EnumerableSet.UintSet) internal _depositedIds;

  /// @notice Mapping of timestamps from each staked token id.
  // mapping(address => mapping(uint256 => uint256)) internal _depositedBlocks;
  mapping(address => mapping(uint256 => uint256)) public _depositedBlocks;

  constructor(
    address newStakingToken,
    address newRewardToken,
    uint256 newRate,
    uint256 newEndTime
  ) {
    stakingToken = ICKEY(newStakingToken);
    rewardToken = IFBX(newRewardToken);
    rate = newRate;
    endTime = newEndTime;

    _pause();
  }

  /* -------------------------------------------------------------------------- */
  /*                                Farming Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Deposit tokens into the vault.
  /// @param tokenIds Array of token tokenIds to be deposited.
  function deposit(uint256[] memory tokenIds) external whenNotPaused {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      // Add the new deposit to the mapping
      _depositedIds[msg.sender].add(tokenIds[i]);
      _depositedBlocks[msg.sender][tokenIds[i]] = block.timestamp;

      // Transfer the deposited token to this contract
      stakingToken.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
  }

  /// @notice Withdraw tokens and claim their pending rewards.
  /// @param tokenIds Array of staked token ids.
  function withdraw(uint256[] memory tokenIds) external whenNotPaused {
    uint256 totalRewards;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(_depositedIds[msg.sender].contains(tokenIds[i]), "Query for a token you don't own");
      totalRewards += _earned(_depositedBlocks[msg.sender][tokenIds[i]]);
      _depositedIds[msg.sender].remove(tokenIds[i]);
      delete _depositedBlocks[msg.sender][tokenIds[i]];

      stakingToken.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
    }
    rewardToken.mint(msg.sender, totalRewards);
  }

  /// @notice Claim pending token rewards.
  function claim() external whenNotPaused {
    for (uint256 i = 0; i < _depositedIds[msg.sender].length(); i++) {
      // Mint the new tokens and update last checkpoint
      uint256 tokenId = _depositedIds[msg.sender].at(i);
      rewardToken.mint(msg.sender, _earned(_depositedBlocks[msg.sender][tokenId]));
      _depositedBlocks[msg.sender][tokenId] = block.timestamp;
    }
  }

  /// @notice Calculate total rewards for given account.
  /// @param account Holder address.
  function earned(address account) external view returns (uint256[] memory) {
    uint256 length = _depositedIds[account].length();
    uint256[] memory rewards = new uint256[](length);

    for (uint256 i = 0; i < length; i++) {
      uint256 tokenId = _depositedIds[account].at(i);
      rewards[i] = _earned(_depositedBlocks[account][tokenId]);
    }
    return rewards;
  }

  /// @notice Internally calculates rewards for given token.
  /// @param timestamp Deposit timestamp.
  function _earned(uint256 timestamp) internal view returns (uint256) {
    if (timestamp == 0) return 0;
    return ((Math.min(block.timestamp, endTime) - timestamp) * rate) / 1 days;
  }

  /// @notice Retrieve token ids deposited by account.
  /// @param account Token owner address.
  function depositsOf(address account) external view returns (uint256[] memory) {
    uint256 length = _depositedIds[account].length();
    uint256[] memory ids = new uint256[](length);

    for (uint256 i = 0; i < length; i++) ids[i] = _depositedIds[account].at(i);
    return ids;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Set the new token rewards rate.
  /// @param newRate Emission rate in wei.
  function setRate(uint256 newRate) external onlyOwner {
    rate = newRate;
  }

  /// @notice Set the new rewards end time.
  /// @param newEndTime End timestamp.
  function setEndTime(uint256 newEndTime) external onlyOwner {
    require(newEndTime > block.timestamp, "CelestialVault: end time must be greater than now");
    endTime = newEndTime;
  }

  /// @notice Set the new staking token contract address.
  /// @param newStakingToken Staking token address.
  function setStakingToken(address newStakingToken) external onlyOwner {
    stakingToken = ICKEY(newStakingToken);
  }

  /// @notice Set the new reward token contract address.
  /// @param newRewardToken Rewards token address.
  function setRewardToken(address newRewardToken) external onlyOwner {
    rewardToken = IFBX(newRewardToken);
  }

  /// @notice Pause the contract.
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpause the contract.
  function unpause() external onlyOwner {
    _unpause();
  }
}

interface ICKEY {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) external;
}

interface IFBX {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mock is ERC721("", "") {
  uint256 totalSupply;
  mapping(address => bool) public auth;

  function setAuth(address[] calldata addresses, bool authorized) external {
    for (uint256 i = 0; i < addresses.length; i++) auth[addresses[i]] = authorized;
  }

  function mint(address to, uint256 amount) external {
    for (uint256 i = 0; i < amount; i++) super._mint(to, totalSupply++);
  }

  function burn(uint256 id) external {
    super._burn(id);
  }

  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    return auth[operator] || super.isApprovedForAll(owner, operator);
  }

  function tokenURI(uint256) public pure override returns (string memory) {
    return "";
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/Structs.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// solhint-disable quotes

contract InventoryCelestials is Ownable {
  using Strings for uint8;

  /*  +---+-----------+ */
  /*  | 0 | Body      | */
  /*  +---+-----------+ */

  /*///////////////////////////////////////////////////////////////
                LAYERS LOGIC 
    //////////////////////////////////////////////////////////////*/

  mapping(uint256 => Layer) internal _layers;

  function addLayers(LayerInput[] memory inputs) external onlyOwner {
    for (uint256 i = 0; i < inputs.length; i++) {
      _layers[inputs[i].layerIndex] = Layer(inputs[i].name, inputs[i].data);
    }
  }

  function getLayer(uint8 layerIndex) external view returns (Layer memory) {
    return _layers[layerIndex];
  }

  /*///////////////////////////////////////////////////////////////
                URI LOGIC 
    //////////////////////////////////////////////////////////////*/

  function getAttributes(Celestial memory character, uint256 id) external pure returns (bytes memory) {
    return
      abi.encodePacked(
        '{"trait_type": "Type", "value": "Celestial"},',
        '{"trait_type": "Generation", "value":"',
        id <= 10000 ? "Gen 0" : id <= 20000 ? "Gen 1" : "Gen 2",
        '"},'
        '{"trait_type": "Health Modifier", "value": "',
        character.healthMod.toString(),
        '"},'
        '{"trait_type": "Power Modifier", "value": "',
        character.powMod.toString(),
        '"},',
        '{"trait_type": "Pilfer Power", "value": "',
        character.cPP.toString(),
        '"},',
        '{"trait_type": "Level", "value": "',
        character.cLevel.toString(),
        '"}'
      );
  }

  function getImage(uint256 id) external view returns (bytes memory) {
    if (id <= 10_000) return _buildImage(_layers[0].data);
    if (id <= 20_000) return _buildImage(_layers[1].data);
    return _buildImage(_layers[2].data);
  }

  function _buildImage(string memory image) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
        image,
        '"/>'
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/Interfaces.sol";
import "./interfaces/Structs.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract FreaksNGuildsMigrated is Initializable, OwnableUpgradeable, PausableUpgradeable, ERC721Upgradeable{

    bytes32 internal entropySauce;


    IFBX public fbx;
    MetadataHandlerLike public metadaHandler;
    IFnG public fngOriginal;

    uint256 public startingPrice;
    uint256 public priceIncrease;
    uint256 public maxSupply;
    uint256 public maxCelestialSupply;
    uint256 public celestialSupply;
    uint256 public freakSupply;

    mapping(uint256 => Freak) public freaks;
    mapping(uint256 => Celestial) public celestials;


    /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(msg.sender == tx.origin, "you're trying to cheat!");
        require(size == 0, "you're trying to cheat!");
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    /*///////////////////////////////////////////////////////////////
                    Initializer
    //////////////////////////////////////////////////////////////*/
    
    function initialize(
        uint256 _startingPrice, 
        uint256 _priceIncrease,
        address _fbx,
        address _metadataHandler,
        address _fngOriginal
    ) public initializer {
        __ERC721_init("Freaks N Guilds Migrated", "FnG");
        __Ownable_init();
        __Pausable_init();
        startingPrice = _startingPrice;
        priceIncrease = _priceIncrease;
        fbx = IFBX(_fbx);
        metadaHandler = MetadataHandlerLike(_metadataHandler);
        fngOriginal = IFnG(_fngOriginal);
        _pause();
    }


  /*///////////////////////////////////////////////////////////////
                    ADMIN
  //////////////////////////////////////////////////////////////*/ 

    /**
        @notice Allow owner to set pause state
        @param _pauseState new pause state
     */
    function setPause(bool _pauseState) external onlyOwner {
        if (_pauseState == true) {
        _pause();
        } else {
        _unpause();
        }
    }

    /*///////////////////////////////////////////////////////////////
                    MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
        @notice migrate fng token from genisis contract
        @param freakIds freakIds to migrate
        @param celestialIds celestialIds to migrate
     */
    function migrate(uint256[] memory freakIds, uint256[] memory celestialIds) external whenNotPaused{
        require(freakIds.length > 0 || celestialIds.length > 0, "No token IDs provided");
        if(freakIds.length > 0){
            for(uint256 i = 0; i < freakIds.length; i++){
                require(fngOriginal.isFreak(freakIds[i]), "Not a freak");
                Freak memory freak = fngOriginal.getFreakAttributes(freakIds[i]);
            }
        }
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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

import "../IERC721Upgradeable.sol";

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
import "../../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import {IFnG, IFBX} from "./interfaces/Interfaces.sol";


contract HuntingUpgradeable is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

  struct StakeFreak {
    uint256 tokenId;
    uint256 lastClaimTime;
    address owner;
    uint256 species;
    uint256 ffIndex;
  }

  struct StakeCelestial {
    uint256 tokenId;
    address owner;
    uint256 value;
  }

  struct Epoch {
    uint256 favoredFreak;
    uint256 epochStartTime;
  }

  struct PoolConfig {
    uint256 guildSize;
    uint256 rate;
    uint256 minToExit;
  }


/*///////////////////////////////////////////////////////////////
                    Global STATE
   //////////////////////////////////////////////////////////////*/

  // reference to the FnG NFT contract
  IFnG public fngNFT;
  // reference to the $FBX contract for minting $FBX earnings
  IFBX public fbx;
  // maps tokenId to stake observatory
  mapping(uint256 => StakeCelestial) private observatory;
  // maps pool id to mapping of address to deposits
  mapping(uint256 => mapping(address => EnumerableSetUpgradeable.UintSet)) private _deposits;
  // maps pool id to mapping of token id to staked freak struct
  mapping(uint256 => mapping(uint256 => StakeFreak)) private stakingPools;
  // maps pool id to pool config
  mapping(uint256 => PoolConfig) public _poolConfig;
  // maps pool id to amount of freaks staked
  mapping(uint256 => uint256) private freaksStaked;
  // maps pool id to epoch struct
  mapping(uint256 => Epoch[]) private favors;
  // any rewards distributed when no celestials are staked
  uint256 private unaccountedRewards;
  // amount of $FBX earned so far
  uint256 public totalFBXEarned;
  // timestamp of last epcoh change
  uint256 private lastEpoch;
  // number of celestials staked at a give time
  uint256 public cCounter;
  // unclaimed FBX pool for hunting observatory
  uint256 public fbxPerCelestial;
  // emergency rescue to allow unstaking without any checks but without $FBX
  bool public rescueEnabled;


  /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

  modifier changeFFEpoch() {
    if (block.timestamp - lastEpoch >= 72 hours) {
      uint256 rand = _rand(msg.sender);
      for (uint256 i = 0; i < 3; i++) {
        uint256 favoredFreak = (rand % 3) + 1;
        Epoch memory epoch = Epoch(favoredFreak, block.timestamp);
        favors[i].push(epoch);
        rand = uint256(keccak256(abi.encodePacked(msg.sender, rand)));
      }
      lastEpoch = block.timestamp;
    }
    _;
  }


  /*///////////////////////////////////////////////////////////////
                    INITIALIZER 
    //////////////////////////////////////////////////////////////*/


  function initialize(address _fng, address _fbx) public changeFFEpoch initializer {
    fngNFT = IFnG(_fng);
    fbx = IFBX(_fbx);
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    // __UUPSUpgradeable_init();
    _pause();
    cCounter = 0;
    _poolConfig[0] = PoolConfig(1, 200 ether, 200 ether);
    _poolConfig[1] = PoolConfig(3, 300 ether, 1800 ether);
    _poolConfig[2] = PoolConfig(5, 400 ether, 6000 ether);
    freaksStaked[0] = 0;
    freaksStaked[1] = 0;
    freaksStaked[2] = 0;
    rescueEnabled = false;
    unaccountedRewards = 0;
  }

  // function _authorizeUpgrade(address) internal override onlyOwner {}

  /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  // returns config for specific pool
  function getPoolConfig(uint256 pool) external view returns (PoolConfig memory) {
    require(pool < 3, "pool not found");
    return _poolConfig[pool];
  }

  // returns total freaks staked in specific pool
  function getStakedFreaks(uint256 pool) external view returns (uint256) {
    require(pool < 3, "pool not found");
    return freaksStaked[pool];
  }

  // returns deposited tokens of an address for each hunting ground and observatory
  function depositsOf(address account)
    external
    view
    returns (
      uint256[] memory,
      uint256[] memory,
      uint256[] memory,
      uint256[] memory
    )
  {
    return (
      _deposits[0][account].values(),
      _deposits[1][account].values(),
      _deposits[2][account].values(),
      _deposits[3][account].values()
    );
  }

  // returns rewards for freaks currently staked in specific pool
  // pool = 0: enclave, pool = 1: summit, pool = 2: ano
  function calculateFBXRewards(uint256[] memory tokenIds, uint256 pool) external view returns (uint256) {
    require(pool < 3, "pool not found");
    uint256 rewards = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      rewards += _calculateSingleFreakRewards(tokenIds[i], pool, _poolConfig[pool].rate);
    }
    return rewards;
  }

  // returns rewards for celestials currently staked in hunting observatory
  function calculateCelestialsRewards(uint256[] calldata tokenIds) external view returns (uint256 rewards) {
    rewards = 0;
    for (uint256 i; i < tokenIds.length; i++) {
      rewards += _calculateCelestialRewards(tokenIds[i]);
    }
    return rewards;
  }

  // returns current favored freak for specific pool
  // pool = 0: enclave, pool = 1: summit, pool = 2: ano
  function getFavoredFreak(uint256 pool) external view returns (uint256) {
    require(pool < 3, "pool not found");
    return favors[pool][favors[pool].length - 1].favoredFreak;
  }

  // returns list of all favored freaks of a specific pool since genesis
  function getFavoredFreaks(uint256 pool) external view returns (Epoch[] memory) {
    require(pool < 3, "pool not found");
    return favors[pool];
  }

  // emergency rescue function to transfer tokens from contract to owner based on specific pool
  function rescue(uint256[] calldata tokenIds, uint256 pool) external nonReentrant {
    require(rescueEnabled, "RESCUE DISABLED");
    require(pool <= 3, "Pool doesn't exist");
    if (pool == 3) {
      //observatory
      for (uint256 i = 0; i < tokenIds.length; i++) {
        require(observatory[tokenIds[i]].owner == msg.sender, "You don't own this token ser");
        delete observatory[tokenIds[i]];
        _deposits[pool][msg.sender].remove(tokenIds[i]);
        cCounter -= 1;
        fngNFT.transferFrom(address(this), msg.sender, tokenIds[i]);
      }
    } else {
      uint256 newTotal = 0;
      for (uint256 l = 0; l < tokenIds.length; l++) {
        require(stakingPools[pool][tokenIds[l]].owner == msg.sender, "You don't own this token ser");
        delete stakingPools[pool][tokenIds[l]];
        _deposits[pool][msg.sender].remove(tokenIds[l]);
        newTotal += 1;
        fngNFT.transferFrom(address(this), msg.sender, tokenIds[l]);
      }
      freaksStaked[pool] = freaksStaked[pool] - newTotal;
    }
  }

  /*///////////////////////////////////////////////////////////////
                    STAKING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function observe(uint256[] calldata tokenIds) external changeFFEpoch nonReentrant whenNotPaused {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(fngNFT.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");
      require(!fngNFT.isFreak(tokenIds[i]), "CELESTIALS ONLY!!! You are not worthy FREAK!");
      observatory[tokenIds[i]] = StakeCelestial({tokenId: tokenIds[i], owner: msg.sender, value: fbxPerCelestial});
      _deposits[3][msg.sender].add(tokenIds[i]);
      fngNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
      cCounter += 1;
    }
  }

  function hunt(uint256[] calldata tokenIds, uint256 pool) external changeFFEpoch nonReentrant whenNotPaused {
    require(pool <= 2, "pool doesn't exist ser");
    require(tokenIds.length % _poolConfig[pool].guildSize == 0, "incorrect amount of freaks");
    uint256 newTotal = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(fngNFT.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");
      require(fngNFT.isFreak(tokenIds[i]), "Can't get freaky without any freaks ser");
      stakingPools[pool][tokenIds[i]] = StakeFreak({
        tokenId: tokenIds[i],
        lastClaimTime: uint256(block.timestamp),
        owner: msg.sender,
        species: fngNFT.getSpecies(tokenIds[i]),
        ffIndex: favors[pool].length - 1
      });
      _deposits[pool][msg.sender].add(tokenIds[i]);
      newTotal += 1;
      fngNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
    }
    freaksStaked[pool] = freaksStaked[pool] + newTotal;
  }

  /*///////////////////////////////////////////////////////////////
                    CLAIM/UNSTAKE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  // unstake or claim from multiple freaks in a specific pool
  function claimUnstake(
    uint256[] calldata tokenIds,
    uint256 pool,
    bool collectTax
  ) external changeFFEpoch nonReentrant {
    require(pool <= 2, "pool doesn't exist ser");
    require(tokenIds.length != 0, "can't claim no tokens");
    uint256 rewards = 0;
    uint256 rewardsPerGroup = 0;
    require(tokenIds.length % _poolConfig[pool].guildSize == 0);
    if (collectTax == true) {
      rewards = _calculateManyFreakRewards(tokenIds, pool, false);
      rewardsPerGroup = rewards / (tokenIds.length / _poolConfig[pool].guildSize);
      require(rewardsPerGroup >= _poolConfig[pool].minToExit, "Not enough $FBX earned per group");
      _claimWithTax(rewards, pool, tokenIds);
    } else {
      rewards = _calculateManyFreakRewards(tokenIds, pool, true);
      rewardsPerGroup = rewards / (tokenIds.length / _poolConfig[pool].guildSize);
      _claimEvadeTax(rewards, rewardsPerGroup, pool, tokenIds);
    }
  }

  function unobserve(uint256[] calldata tokenIds) external changeFFEpoch nonReentrant {
    uint256 newCounter = 0;
    uint256 rewards = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(observatory[tokenIds[i]].owner == msg.sender, "You don't own this token ser");
      if (fbxPerCelestial != 0) {
        rewards += fbxPerCelestial - observatory[tokenIds[i]].value;
      } else {
        rewards += 0;
      }
      delete observatory[tokenIds[i]];
      _deposits[3][msg.sender].remove(tokenIds[i]);
      fngNFT.transferFrom(address(this), msg.sender, tokenIds[i]);
      newCounter += 1;
    }
    fbx.mint(msg.sender, rewards);
    totalFBXEarned += rewards;
    cCounter = cCounter - newCounter;
  }

  /*///////////////////////////////////////////////////////////////
                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function _calculateManyFreakRewards(uint256[] memory tokenIds, uint256 pool, bool unstake) internal returns (uint256 owed) {
    uint256 rewards = 0;
    uint256 newTotal = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(stakingPools[pool][tokenIds[i]].owner == msg.sender, "You don't own this token ser");
      rewards += _calculateSingleFreakRewards(tokenIds[i], pool, _poolConfig[pool].rate);
      newTotal += 1;
    }
    if (unstake == true) {
      freaksStaked[pool] = freaksStaked[pool] - newTotal;
    }
    return rewards;
  }

  function _calculateCelestialRewards(uint256 tokenId) internal view returns (uint256 reward) {
    if (fbxPerCelestial != 0) {
      reward = fbxPerCelestial - observatory[tokenId].value;
    }
    if (fbxPerCelestial == 0) {
      reward = 0;
    }
    return reward;
  }

  function _calculateSingleFreakRewards(
    uint256 tokenId,
    uint256 pool,
    uint256 rate
  ) internal view returns (uint256 owed) {
    uint256 timestamp = stakingPools[pool][tokenId].lastClaimTime;
    if (timestamp == 0) {
      return 0;
    }
    uint256 species = stakingPools[pool][tokenId].species;
    uint256 duration = block.timestamp - timestamp;
    uint256 favoredDuration = 0;
    for (uint256 j = stakingPools[pool][tokenId].ffIndex; j < favors[pool].length; j++) {
      uint256 startTime;
      if (j == stakingPools[pool][tokenId].ffIndex) {
        startTime = stakingPools[pool][tokenId].lastClaimTime;
      } else {
        startTime = favors[pool][j].epochStartTime;
      }
      if (favors[pool][j].favoredFreak == species) {
        uint256 epochEndTime;
        if (favors[pool].length == j + 1) {
          epochEndTime = block.timestamp;
        } else {
          epochEndTime = favors[pool][j + 1].epochStartTime;
        }
        favoredDuration += epochEndTime - startTime;
      }
    }
    uint256 ffOwed = ((favoredDuration * (rate + 20 ether)) / 1 days);
    uint256 baseOwed = 0;
    if (duration - favoredDuration != 0) {
      baseOwed = (((duration - favoredDuration) * rate) / 1 days);
    }
    owed = ffOwed + baseOwed;
    return owed;
  }

  function _claimWithTax(
    uint256 rewards,
    uint256 pool,
    uint256[] memory tokenIds
  ) internal {
    uint256 celestialRewards;
    celestialRewards = rewards / 5;
    if (cCounter == 0) {
      unaccountedRewards += (celestialRewards);
      rewards = rewards - celestialRewards;
      fbx.mint(msg.sender, rewards);
      totalFBXEarned += rewards;
    } else {
      fbxPerCelestial += (unaccountedRewards + celestialRewards) / cCounter;
      rewards = rewards - celestialRewards;
      unaccountedRewards = 0;
      fbx.mint(msg.sender, rewards);
      totalFBXEarned += rewards;
    }
    for (uint256 i; i < tokenIds.length; i++) {
      stakingPools[pool][tokenIds[i]] = StakeFreak({
        tokenId: tokenIds[i],
        lastClaimTime: uint256(block.timestamp),
        owner: msg.sender,
        species: fngNFT.getSpecies(tokenIds[i]),
        ffIndex: favors[pool].length - 1
      });
    }
  }

  function _claimEvadeTax(
    uint256 rewards,
    uint256 rewardsPerGroup,
    uint256 pool,
    uint256[] memory tokenIds
  ) internal {
    uint256 rNum = _rand(msg.sender) % 100;
    if (rNum < 33 || rewardsPerGroup < _poolConfig[pool].minToExit) {
      if (cCounter == 0) {
        unaccountedRewards += rewards;
      } else {
        fbxPerCelestial += (unaccountedRewards + rewards) / cCounter;
        unaccountedRewards = 0;
      }
    } else {
      fbx.mint(msg.sender, rewards);
      totalFBXEarned += rewards;
    }
    for (uint256 j; j < tokenIds.length; j++) {
      _deposits[pool][msg.sender].remove(tokenIds[j]);
      fngNFT.transferFrom(address(this), msg.sender, tokenIds[j]);
      delete stakingPools[pool][tokenIds[j]]; 
    }
  }

  function _rand(address acc) internal view returns (uint256) {
    bytes32 _entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    return
      uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, _entropySauce)));
  }

  /*///////////////////////////////////////////////////////////////
                   ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

  function setContracts(address _fngNFT, address _fbx) external onlyOwner {
    fngNFT = IFnG(_fngNFT);
    fbx = IFBX(_fbx);
  }

  /**
   * allows owner to enable "rescue mode"
   * simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * backup favored freak epoch changing function
   * in case it isn't triggered by claim/unstake function (unlikely)
   */
  function backupEpochSet() public changeFFEpoch onlyOwner {}

  /**
   * manually set rates for each pool
   */
  function setRates(
    uint256 _enclaveRate,
    uint256 _summitRate,
    uint256 _anoRate
  ) external onlyOwner {
    _poolConfig[0].rate = _enclaveRate;
    _poolConfig[1].rate = _summitRate;
    _poolConfig[2].rate = _anoRate;
  }

  /**
   * manually set minimum FBX required to exit each pool
   */
  function setMinExits(
    uint256 _minExitEnclave,
    uint256 _minExitSummit,
    uint256 _minExitAno
  ) external onlyOwner {
    _poolConfig[0].minToExit = _minExitEnclave;
    _poolConfig[1].minToExit = _minExitSummit;
    _poolConfig[2].minToExit = _minExitAno;
  }


}

interface IFnG {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function ownerOf(uint256 id) external returns (address owner);

  function isFreak(uint256 tokenId) external view returns (bool);

  function getSpecies(uint256 tokenId) external view returns (uint8);

  function getFreakAttributes(uint256 tokenId) external view returns (Freak memory);

  function setFreakAttributes(uint256 tokenId, Freak memory attributes) external;

  function getCelestialAttributes(uint256 tokenId) external view returns (Celestial memory);

  function setCelestialAttributes(uint256 tokenId, Celestial memory attributes) external;

  function burn(uint tokenId) external;
}

interface IFBX {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

struct Freak {
  uint8 species;
  uint8 body;
  uint8 armor;
  uint8 mainHand;
  uint8 offHand;
  uint8 power;
  uint8 health;
  uint8 criticalStrikeMod;

}
struct Celestial {
  uint8 healthMod;
  uint8 powMod;
  uint8 cPP;
  uint8 cLevel;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PortalMock is Ownable {
  struct SpyData {
    address target;
    bool status;
  }

  SpyData[] public spyData;

  function sendMessage(bytes calldata message) external {
    (address target, bytes[] memory calls) = abi.decode(message, (address, bytes[]));

    for (uint256 i = 0; i < calls.length; i++) {
      (bool success, ) = target.call(calls[i]);
      SpyData memory capturedData = SpyData(target, success);
      spyData.push(capturedData);
    }
  }

  function getSpyData() external view returns (SpyData[] memory) {
    return spyData;
  }
}
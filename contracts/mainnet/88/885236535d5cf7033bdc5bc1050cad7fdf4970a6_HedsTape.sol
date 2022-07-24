// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ERC721K/ERC721K.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

error InsufficientFunds();
error ExceedsMaxSupply();
error OutsideSalePeriod();
error FailedTransfer();
error URIQueryForNonexistentToken();
error UnmatchedLength();
error NoShares();

/// @title ERC721 contract for https://heds.io/ HedsTape
/// @author https://github.com/kadenzipfel
contract HedsTape is ERC721K, Ownable {
  struct SaleConfig {
    uint64 price;
    uint32 maxSupply;
    uint32 startTime;
    uint32 endTime;
  }

  /// @notice NFT sale data
  /// @dev Sale data packed into single storage slot
  SaleConfig public saleConfig;

  string private baseUri = 'ipfs://QmWWQSX4sNW3RXZ2jTa7x1dSk4gjjxxgEr8YNHX6AazjSu';

  address private zeroXSplit = 0xde4C3Ec08d11d14aa9324C9572b3035a6F2498C2;

  constructor() ERC721K("hedsTAPE 6", "HT6") {
    saleConfig.price = 0.1 ether;
    saleConfig.maxSupply = 1000;
    saleConfig.startTime = 1658577595;
    saleConfig.endTime = 1658663995;
  }

  /// @notice Mint a HedsTape token
  /// @param _amount Number of tokens to mint
  function mintHead(uint _amount) external payable {
    SaleConfig memory config = saleConfig;
    uint _price = uint(config.price);
    uint _maxSupply = uint(config.maxSupply);
    uint _startTime = uint(config.startTime);
    uint _endTime = uint(config.endTime);

    if (_amount * _price != msg.value) revert InsufficientFunds();
    if (_currentIndex + _amount > _maxSupply + 1) revert ExceedsMaxSupply();
    if (block.timestamp < _startTime || block.timestamp > _endTime) revert OutsideSalePeriod();

    _safeMint(msg.sender, _amount);
  }
 
  /// @notice Update baseUri - must be contract owner
  function setBaseUri(string calldata _baseUri) external onlyOwner {
    baseUri = _baseUri;
  }

  /// @notice Return tokenURI for a given token
  /// @dev Same tokenURI returned for all tokenId's
  function tokenURI(uint _tokenId) public view override returns (string memory) {
    if (0 == _tokenId || _tokenId > _currentIndex - 1) revert URIQueryForNonexistentToken();
    return baseUri;
  }

  /// @notice Update sale start time - must be contract owner
  function updateStartTime(uint32 _startTime) external onlyOwner {
    saleConfig.startTime = _startTime;
  }

  /// @notice Update sale end time - must be contract owner
  function updateEndTime(uint32 _endTime) external onlyOwner {
    saleConfig.endTime = _endTime;
  }

  /// @notice Update max supply - must be contract owner
  function updateMaxSupply(uint32 _maxSupply) external onlyOwner {
    saleConfig.maxSupply = _maxSupply;
  }

  /// @notice Withdraw contract balance - must be contract owner
  function withdraw() external onlyOwner {
    (bool success, ) = payable(zeroXSplit).call{value: address(this).balance}("");
    if (!success) revert FailedTransfer();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

error ERC721__ApprovalCallerNotOwnerNorApproved(address caller);
error ERC721__ApproveToCaller();
error ERC721__ApprovalToCurrentOwner();
error ERC721__BalanceQueryForZeroAddress();
error ERC721__MintToZeroAddress();
error ERC721__MintZeroQuantity();
error ERC721__OwnerQueryForNonexistentToken(uint256 tokenId);
error ERC721__TransferCallerNotOwnerNorApproved(address caller);
error ERC721__TransferFromIncorrectOwner(address from, address owner);
error ERC721__TransferToNonERC721ReceiverImplementer(address receiver);
error ERC721__TransferToZeroAddress();

/**
 * @notice Maximally optimized, minimalist ERC-721 implementation.
 *
 * @dev Assumes serials are sequentially minted starting at 1 (e.g. 1, 2, 3..),
 * and that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * 
 * @author https://github.com/kadenzipfel - fork of https://github.com/chiru-labs/ERC721A, 
 * inspired by https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol.
 */
abstract contract ERC721K {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                             ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/    

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
    uint256 internal _currentIndex = 1;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) public getApproved;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - 1 times
        unchecked {
            return _currentIndex - _burnCounter - 1;
        }
    }

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ERC721__BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownershipOf(tokenId).addr;
    }

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
    function approve(address to, uint256 tokenId) public {
        address owner = ERC721K.ownerOf(tokenId);
        if (to == owner) revert ERC721__ApprovalToCurrentOwner();

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
            revert ERC721__ApprovalCallerNotOwnerNorApproved(msg.sender);
        }

        _approve(to, tokenId, owner);
    }

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
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (operator == msg.sender) revert ERC721__ApproveToCaller();

        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

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
    ) public virtual {
        _transfer(from, to, tokenId);
    }

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
    ) public virtual {
        safeTransferFrom(from, to, tokenId, '');
    }

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
        bytes memory _data
    ) public virtual {
        _transfer(from, to, tokenId);
        if (to.code.length != 0 && ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, _data) !=
                ERC721TokenReceiver.onERC721Received.selector) {
            revert ERC721__TransferToNonERC721ReceiverImplementer(to);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return  
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to 1
        unchecked {
            return _currentIndex - 1;
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (curr != 0 && curr < _currentIndex) {
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
        revert ERC721__OwnerQueryForNonexistentToken(tokenId);
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
        if (to == address(0)) revert ERC721__MintToZeroAddress();
        if (quantity == 0) revert ERC721__MintZeroQuantity();

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

            if (safe && to.code.length != 0) {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
                if (ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), end - 1, _data) !=
                ERC721TokenReceiver.onERC721Received.selector) {
                    revert ERC721__TransferToNonERC721ReceiverImplementer(to);
                }
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
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

        if (prevOwnership.addr != from) revert ERC721__TransferFromIncorrectOwner(from, prevOwnership.addr);

        bool isApprovedOrOwner = (msg.sender == from ||
            getApproved[tokenId] == msg.sender) ||
            isApprovedForAll[from][msg.sender];

        if (!isApprovedOrOwner) revert ERC721__TransferCallerNotOwnerNorApproved(msg.sender);
        if (to == address(0)) revert ERC721__TransferToZeroAddress();

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
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        delete getApproved[tokenId];

        emit Transfer(from, to, tokenId);
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
            bool isApprovedOrOwner = (msg.sender == from ||
                getApproved[tokenId] == msg.sender) ||
                isApprovedForAll[from][msg.sender];

            if (!isApprovedOrOwner) revert ERC721__TransferCallerNotOwnerNorApproved(msg.sender);
        }

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
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        delete getApproved[tokenId];

        emit Transfer(from, address(0), tokenId);

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
        getApproved[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
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
/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;


interface IERC165Upgradeable {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


interface StakeIntreface {
  function stakeOf(address _address) external view returns (uint256[] memory ids);

}

interface IERC721Upgradeable is IERC165Upgradeable {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


interface IERC721ReceiverUpgradeable {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

}


interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);

}


library AddressUpgradeable {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // This below comment helps to resolve unsafe delegate issue so the comment is necessary in upgradeable contracts
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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


abstract contract Initializable {
    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
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

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


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
}


// library Strings {
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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


abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
 
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    uint256[50] private __gap;
}


contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
  using AddressUpgradeable for address;
  using StringsUpgradeable for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex;
  uint256 public maxBatchSize;
  string private _name;
  string private _symbol;
  string private prefix;
  string private postfix;
  bool public _revealed;
  uint public range;

  uint256 public nextOwnerToExplicitlySet;
  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   */
  // constructor( string memory name_, string memory symbol_, uint256 maxBatchSize_ ) {
  //   require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
  //   _name = name_;
  //   _symbol = symbol_;
  //   maxBatchSize = maxBatchSize_;
  // }


  function __ERC721_init(string memory name_, string memory symbol_, uint256 maxBatchSize_ ) internal onlyInitializing {
    __ERC721_init_unchained(name_, symbol_, maxBatchSize_);
  }

  function __ERC721_init_unchained(string memory name_, string memory symbol_, uint256 maxBatchSize_) internal onlyInitializing {
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    currentIndex = 0;
    nextOwnerToExplicitlySet = 0;
    _revealed = false;
    range = 3600;
  }

  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }

  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }


  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
    return
      interfaceId == type(IERC165Upgradeable).interfaceId ||
      interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
      interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require( owner != address(0), "ERC721A: number minted query for the zero address" );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  }

  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token" );

    string memory baseURI = _baseURI();

    if(_revealed)   return bytes(baseURI).length > 0 ? string(abi.encodePacked(prefix, tokenId.toString(), postfix)) : "";
    else            return bytes(baseURI).length > 0 ? (baseURI) : ""; 
  }

  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

//   function haveRevealed() public view virtual returns (bool) {
//     return _revealed;
//   }

  function _revealedNow(bool yesNo) internal {
    _revealed = yesNo;
  }

  function changeRange(uint __range) internal {
    range = __range;
  }

  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721Upgradeable.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) { 
    return _operatorApprovals[owner][operator];
  }

  function transferFrom( address from, address to, uint256 tokenId ) public override {
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom( address from, address to, uint256 tokenId ) public override {
    safeTransferFrom(from, to, tokenId, "");
  }

 
  function safeTransferFrom( address from, address to, uint256 tokenId, bytes memory _data ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  function set_prefix(string memory __prefix) internal {
    prefix = __prefix;    // URL of metadata
  }

  function set_postfix(string memory __postfix) internal {
    postfix = __postfix;  // extension of metadata url e.g. ".json", ".png"
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint( address to, uint256 quantity, bytes memory _data ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
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
  function _transfer( address from, address to, uint256 tokenId ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve( address to, uint256 tokenId, address owner ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > currentIndex - 1) {
      endIndex = currentIndex - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
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
  function _checkOnERC721Received( address from, address to, uint256 tokenId, bytes memory _data ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
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
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers( address from, address to, uint256 startTokenId, uint256 quantity ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers( address from, address to, uint256 startTokenId, uint256 quantity ) internal virtual {}

}


abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal onlyInitializing {
      __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
      _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() private onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


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
    // constructor() {
    //     _paused = false;
    // }
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
        require(!paused(), "Pausable: already paused");
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
        require(paused(), "Pausable: already un-paused");
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


contract BearXEbookUpgrade is ERC721Upgradeable, OwnableUpgradeable, PausableUpgradeable {
    string  public baseURI; 
    uint256 public Supply;
    bool public contarctInitialized;
    
    mapping(uint => bool) public isClaimed;

    StakeIntreface     public StakeXContract;
    IERC721Upgradeable public BearXContract;
    
    function initialize() public initializer {
      baseURI = "ipfs://QmWYA1zgmWXt6cmd9EMMC1LaxU2Y3GgnneZjGLc1XwNFLf/";
      Supply = 10000;
      __ERC721_init("BearXLabs Ebook", "Ebook", 100);
      __Ownable_init();
      _pause();
      contarctInitialized = true;
      BearXContract  = IERC721Upgradeable(0xE22e1e620dffb03065CD77dB0162249c0c91bf01);
      StakeXContract = StakeIntreface(0xdD870fA1b7C4700F2BD7f44238821C26f7392148);
    }

    function setNewBearX (IERC721Upgradeable __address) public onlyOwner {
      BearXContract = __address;
    }

    function setNewStakeX (StakeIntreface __address) public onlyOwner {
      StakeXContract = __address;
    }


    function Claim(uint[] memory _ids) public whenNotPaused {
      for(uint i= 0; i<_ids.length; i++){
        _claim(_ids[i]);
      }
    }

    function _claim(uint id) internal whenNotPaused {
      unchecked { require(id <= range, "You can't claim"); }
      require(isClaimed[id] == false, "This item is already claimed");
      require( BearXContract.ownerOf(id) == msg.sender, "You Don't Own This Item");
      unchecked { require(totalSupply() + 1 <= Supply, "MAX_REACHED"); }
      _safeMint(msg.sender, 1);
      isClaimed[id] = true;
    }

    function StakeClaim (address _address) public {
      require(StakeXContract.stakeOf(_address).length > 0, "You have not staked any NFT");

      uint[] memory idList = StakeXContract.stakeOf(_address);

      for(uint i=0; i<idList.length; i++){
        _stakeClaim(idList[i]);
      }
    }
    function _stakeClaim(uint id) internal {
      if(isClaimed[id] == false) {
      unchecked { require(id <= range, "You can't claim"); }
      unchecked { require(totalSupply() + 1 <= Supply, "MAX_REACHED"); }
      _safeMint(msg.sender, 1);
      isClaimed[id] = true;
      }
    }

    function Airdrop(address[] memory _addresses, uint256[] memory num) public onlyOwner {
      for(uint256 i=0; i <_addresses.length; i++){
        _airdrop(_addresses[i], num[i]);
      }
    }

    function _airdrop(address _address, uint256 num) internal {
      require(num <= maxBatchSize && num != 0, 'TRY TO MINT LESS');
      unchecked { require(totalSupply() + num <= Supply, 'MAX_REACHED'); }
      _safeMint(_address, num);
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);
      uint256[] memory tokensId = new uint256[](tokenCount);
      for(uint256 i; i < tokenCount; i++){
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return tokensId;
    }


    function setSupply(uint256 newSupply) public onlyOwner {
      Supply = newSupply;
    }

    function setPrefix(string memory prefix) public onlyOwner {
      set_prefix(prefix);
    }

    function setPostfix(string memory postfix) public onlyOwner {
      set_postfix(postfix);
    }


    function _baseURI() internal view override returns (string memory) {
      return baseURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
      baseURI = _baseTokenURI;
    }

    function revealedNow(bool yesNo) public onlyOwner {
      _revealedNow(yesNo);
    }

    function updateRange(uint __range) public onlyOwner {
      changeRange(__range);
    }
    

    function pauseNew() public onlyOwner {
      _pause();
    }

    function pause() public onlyOwner {
      _pause();
    }

    function unpause() public onlyOwner {
      _unpause();
    }
}
//	SPDX-License-Identifier: MIT
/// @title  Emoticon Logo Elements
/// @notice On-chain SVG
pragma solidity ^0.8.0;

import '../common/ERC721A.sol';
import '../common/LogoHelper.sol';
import '../text/SvgText.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

interface IDescriptor {
  function txtVals(uint256 tokenId) external view returns (string memory);
  function txtFonts(uint256 tokenId) external view returns (string memory link, string memory name);
  function getSvg(uint256 tokenId) external view returns (string memory);
  function getSvg(uint256 tokenId, string memory txt, string memory font, string memory fontLink) external view returns (string memory);
  function getSvgFromSeed(uint256 seed, string memory txt, string memory font, string memory fontLink) external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function setTxtVal(uint256 tokenId, string memory val) external;
  function setFont(uint256 tokenId, string memory link, string memory font) external;
}


contract EmoticonLogoElement is ERC721A, ReentrancyGuard, Ownable {
  /// @notice Permanently seals the contract from being modified by owner
  bool public contractSealed;

  address public descriptorAddress;
  IDescriptor public descriptor;

  bool public mintIsActive = false;

  uint256 price = 0 ether;

  modifier onlyWhileUnsealed() {
    require(!contractSealed, "Contract is sealed");
    _;
  }

  constructor() ERC721A('Emoticons by Logo', 'EMOTICON', 100) Ownable() {
  }

  /// @notice Sets price for mint, initially set at 0 ether
  /// @param _price, the new price
  function setPrice(uint256 _price) external onlyOwner onlyWhileUnsealed {
    price = _price;
  }

  function setDescriptorAddress(address _address) external onlyOwner onlyWhileUnsealed {
    descriptorAddress = _address;
    descriptor = IDescriptor(_address);
  }

  function mint(uint256 quantity) external payable nonReentrant {
    require(mintIsActive, 'Mint is not active');
    require(totalSupply() + quantity <= 500, 'Exceeded supply');
    require(quantity <= 2, 'Only 2 tokens can be minted at once');
    require(msg.value == price * quantity, 'Incorrect eth amount sent');
    require(msg.sender == tx.origin, 'Contract cannot mint');

    _safeMint(msg.sender, quantity);
  }

  /// @notice Owner mint, allows owner to mint tokens up to 100 at a time
  /// @param to, the address to mint to
  /// @param quantity, number of tokens to mint
  function mintAdmin(address to, uint256 quantity) external onlyOwner nonReentrant {
    require(totalSupply() + quantity <= 500, "Exceeded Supply");
    _safeMint(to, quantity);
  }

  /// @notice Toggles the mint state
  function toggleMint() external onlyOwner onlyWhileUnsealed {
    mintIsActive = !mintIsActive;
  }

  /// @notice Specifies whether or not non-owners can use a token for their logo layer
  /// @dev Required for any element used for a logo layer
  function mustBeOwnerForLogo() external view returns (bool) {
    return true;
  }

  /// @notice Gets the SVG for the logo layer
  /// @dev Required for any element used for a logo layer
  /// @param tokenId, the tokenId that SVG will be fetched for
  function getSvg(uint256 tokenId) public view returns (string memory) {
    return descriptor.getSvg(tokenId);
  }

  function getSvg(uint256 tokenId, string memory txt, string memory font, string memory fontLink) public view returns (string memory) {
    return descriptor.getSvg(tokenId, txt, font, fontLink);
  }

  function getSvgFromSeed(uint256 seed, string memory txt, string memory font, string memory fontLink) public view returns (string memory) {
    return descriptor.getSvgFromSeed(seed, txt, font, fontLink);
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    return descriptor.tokenURI(tokenId);
  }

  function getTxtVal(uint256 tokenId) public view returns (string memory) {
    return descriptor.txtVals(tokenId);
  }

  function getTxtFont(uint256 tokenId) public view returns (string memory link, string memory name) {
    (link, name) = descriptor.txtFonts(tokenId);
    return (link, name);
  }

  function setTxtVal(uint256 tokenId, string memory val) public {
    descriptor.setTxtVal(tokenId, val);
  }

  function setFont(uint256 tokenId, string memory link, string memory font) public {
    descriptor.setFont(tokenId, link, font);
  }

  /// @notice Permananetly seals the contract from being modified
  function sealContract() external onlyOwner {
    contractSealed = true;
  }

  function sendValue(address payable recipient, uint256 amount) external onlyOwner {
    require(address(this).balance >= amount, 'Address: insufficient balance');
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: MIT
// Creators: locationtba.eth, 2pmflow.eth

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 0;

  uint256 internal immutable maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

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
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_
  ) {
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
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

  /**
   * @dev See {IERC165-supportsInterface}.
   */
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
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
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
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
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
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
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
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
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
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
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
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
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
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

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
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
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
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

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
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library LogoHelper {
  function getRotate(string memory text) public pure returns (string memory) {
    bytes memory byteString = bytes(text);
    string memory rotate = string(abi.encodePacked('-', toString(random(text) % 10 + 1)));
    for (uint i=1; i < byteString.length; i++) {
      uint nextRotate = random(rotate) % 10 + 1;
      if (i % 2 == 0) {
        rotate = string(abi.encodePacked(rotate, ',-', toString(nextRotate)));
      } else {
        rotate = string(abi.encodePacked(rotate, ',', toString(nextRotate)));
      }
    }
    return rotate;
  }

  function getTurbulance(string memory seed, uint max, uint magnitudeOffset) public pure returns (string memory) {
    string memory turbulance = decimalInRange(seed, max, magnitudeOffset);
    uint rand = randomInRange(turbulance, max, 0);
    return string(abi.encodePacked(turbulance, ', ', getDecimal(rand, magnitudeOffset)));
  }

  function decimalInRange(string memory seed, uint max, uint magnitudeOffset) public pure returns (string memory) {
    uint rand = randomInRange(seed, max, 0);
    return getDecimal(rand, magnitudeOffset);
  }

  // CORE HELPERS //
  function random(string memory input) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function randomFromInt(uint256 seed) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed)));
  }

  function randomInRange(string memory input, uint max, uint offset) public pure returns (uint256) {
    max = max - offset;
    return (random(input) % max) + offset;
  }

  function equal(string memory a, string memory b) public pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  function toString(uint256 value) public pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

  function toString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2*i] = char(hi);
      s[2*i+1] = char(lo);            
    }
    return string(s);
  }

function char(bytes1 b) internal pure returns (bytes1 c) {
  if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
  else return bytes1(uint8(b) + 0x57);
}
  
  function getDecimal(uint val, uint magnitudeOffset) public pure returns (string memory) {
    string memory decimal;
    if (val != 0) {
      for (uint i = 10; i < magnitudeOffset / val; i=10*i) {
        decimal = string(abi.encodePacked(decimal, '0'));
      }
    }
    decimal = string(abi.encodePacked('0.', decimal, toString(val)));
    return decimal;
  }

  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }
    return string(result);
  }
}

//	SPDX-License-Identifier: MIT
/// @title  Text Logo Elements
/// @notice On-chain SVG
pragma solidity ^0.8.0;

import '../common/SvgFill.sol';
import '../common/SvgElement.sol';
import '../common/LogoHelper.sol';

library SvgText {

  struct Font {
    string link;
    string name;
  }
  
  struct Text {
    string id;
    string class;
    string val;
    string textType;
    Font font;
    uint256 size;
    string paletteName;
    SvgFill.Fill[] fills;
    bool animate;
  }

  function getSvgDefs(string memory seed, Text memory text) public pure returns (string memory) {
    string memory defs = '';

    for (uint i = 0; i < text.fills.length; i++) {
      defs = string(abi.encodePacked(defs, SvgFill.getFillDefs(seed, text.fills[i])));
    }

    if (LogoHelper.equal(text.textType, 'Rug Pull')) {
      uint256[] memory ys = getRugPullY(text);
      for (uint8 i = 0; i < 4; i++) {
        string memory path = SvgElement.getRect(SvgElement.Rect('', '', LogoHelper.toString(ys[i] + 3), '100%', '100%', '', '', ''));
        string memory id = string(abi.encodePacked('clip-', LogoHelper.toString(i)));
        defs = string(abi.encodePacked(defs, SvgElement.getClipPath(SvgElement.ClipPath(id, path))));
      }
    }
    return defs;
  }
  
  // TEXT //
  function getSvgStyles(Text memory text) public pure returns (string memory) {
    string memory styles = !LogoHelper.equal(text.font.link, '') ? string(abi.encodePacked('@import url(', text.font.link, '); ')) : '';
    styles = string(abi.encodePacked(styles, '.', text.class, ' { font-family:', text.font.name, '; font-size: ', LogoHelper.toString(text.size), 'px; font-weight: 800; } '));

    for (uint i=0; i < text.fills.length; i++) {
      styles = string(abi.encodePacked(styles, SvgFill.getFillStyles(text.fills[i])));
    }
    return styles;
  }

  function getSvgContent(Text memory text) public pure returns (string memory) {
    string memory content = '';
    if (LogoHelper.equal(text.textType, 'Plain')) {
      content = SvgElement.getText(SvgElement.Text(text.class, '50%', '50%', '', '', '', 'central', 'middle', '', '', '', text.val));
    } else if (LogoHelper.equal(text.textType, 'Rug Pull')) {
      content = getRugPullContent(text);
    } else if (LogoHelper.equal(text.textType, 'Mailbox') || LogoHelper.equal(text.textType, 'Warped Mailbox')) {
      uint8 iterations = LogoHelper.equal(text.textType, 'Mailbox') ? 2 : 30;
      for (uint8 i = 0; i < iterations; i++) {
        content = string(abi.encodePacked(content, SvgElement.getText(SvgElement.Text(string(abi.encodePacked(text.class, ' ', text.fills[i % text.fills.length].class)), '50%', '50%', LogoHelper.toString(iterations - i), LogoHelper.toString(iterations - i), '', 'central', 'middle', '', '', '', text.val))));
      }
      content = string(abi.encodePacked(content, SvgElement.getText(SvgElement.Text(string(abi.encodePacked(text.class, ' ', text.fills[text.fills.length - 1].class)), '50%', '50%', '', '', '', 'central', 'middle', '', '', '', text.val))));
    } else if (LogoHelper.equal(text.textType, 'NGMI')) {
      string memory rotate = LogoHelper.getRotate(text.val);
      content = SvgElement.getText(SvgElement.Text(text.class, '50%', '50%', '', '', '', 'central', 'middle', rotate, '', '', text.val));
    }
    return content;
  }

  function getRugPullContent(Text memory text) public pure returns (string memory) {
    // get first animation y via y_prev = (y of txt 1) - font size / 2)
    // next animation goes to y_prev + (font size / 3)
    // clip path is txt elemnt y + 3

    string memory content = '';
    uint256[] memory ys = getRugPullY(text);

    string memory element = SvgElement.getAnimate(SvgElement.Animate('y', LogoHelper.toString(ys[4]), '', '2600', '0', '1', 'freeze'));
    element = string(abi.encodePacked(text.val, element));
    element = SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', 'clip-3', element));      

    content = element;
    element = SvgElement.getAnimate(SvgElement.Animate('y', LogoHelper.toString(ys[3]), '', '2400', '0', '1', 'freeze'));
    element = string(abi.encodePacked(text.val, element));
    element = SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', 'clip-2', element));    
    content = string(abi.encodePacked(content, element));

    element = SvgElement.getAnimate(SvgElement.Animate('y', LogoHelper.toString(ys[2]), '', '2200', '0', '1', 'freeze'));
    element = string(abi.encodePacked(text.val, element));
    element = SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', 'clip-1', element));      
    content = string(abi.encodePacked(content, element));

    element = SvgElement.getAnimate(SvgElement.Animate('y', LogoHelper.toString(ys[1]), '', '2000', '0', '1', 'freeze'));
    element = string(abi.encodePacked(text.val, element));
    element = SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', 'clip-0', element));
    content = string(abi.encodePacked(content, element));

    return string(abi.encodePacked(content, SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', '', text.val))));
  }

  function getRugPullY(Text memory text) public pure returns (uint256[] memory) {
    uint256[] memory ys = new uint256[](5);
    uint256 y =  (text.size - (text.size / 4)) + (text.size / 2) + (text.size / 3) + (text.size / 4) + (text.size / 5);
    y = ((300 - y) / 2) + (text.size - (text.size / 4));
    ys[0] = y;
    y = y + text.size / 2;
    ys[1] = y;
    y = y + text.size / 3;
    ys[2] = y;
    y = y + text.size / 4;
    ys[3] = y;
    y = y + text.size / 5;
    ys[4] = y;
    return ys;
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './SvgElement.sol';
import './LogoHelper.sol';

library SvgFill {
  struct Fill {
    string id;
    string class;
    string fillType;
    string[] colors;
    bool animate;
  }

  // FILL //
  function getFillDefs(string memory seed, Fill memory fill) public pure returns (string memory) {
    string memory defs = '';
    if (LogoHelper.equal(fill.fillType, 'Linear Gradient') || LogoHelper.equal(fill.fillType, 'Blocked Linear Gradient')) {
      if (!fill.animate) {
        defs = SvgElement.getLinearGradient(SvgElement.LinearGradient(fill.id, fill.colors, LogoHelper.equal(fill.fillType, 'Blocked Linear Gradient'), ''));
      } else {
       string memory val = LogoHelper.toString(LogoHelper.randomInRange(seed, 100 , 0));
       string memory values = string(abi.encodePacked(val,
                                                      '%;',
                                                      LogoHelper.toString(LogoHelper.randomInRange(string(abi.encodePacked(seed, 'a')), 100 , 0)),
                                                      '%;',
                                                      val,
                                                      '%;'));
        val = LogoHelper.toString(LogoHelper.randomInRange(seed, 50000 , 5000));
        defs = SvgElement.getLinearGradient(SvgElement.LinearGradient(fill.id, fill.colors, LogoHelper.equal(fill.fillType, 'Blocked Linear Gradient'), SvgElement.getAnimate(SvgElement.Animate(getLinearAnimationType(seed), '', values, val, '0', getAnimationRepeat(seed), 'freeze'))));
      }
    } else if (LogoHelper.equal(fill.fillType, 'Radial Gradient') || LogoHelper.equal(fill.fillType, 'Blocked Radial Gradient')) {
      if (!fill.animate) {
        defs = SvgElement.getRadialGradient(SvgElement.RadialGradient(fill.id, fill.colors, LogoHelper.equal(fill.fillType, 'Blocked Radial Gradient'), ''));
      } else {
        string memory val = LogoHelper.toString(LogoHelper.randomInRange(seed, 100, 0));
        string memory values = string(abi.encodePacked(val,
                                                      '%;',
                                                      LogoHelper.toString(LogoHelper.randomInRange(string(abi.encodePacked(seed, 'a')), 100 , 0)),
                                                      '%;',
                                                      val,
                                                      '%;'));
        val = LogoHelper.toString(LogoHelper.randomInRange(seed, 10000 , 5000));
        defs = SvgElement.getRadialGradient(SvgElement.RadialGradient(fill.id, fill.colors, LogoHelper.equal(fill.fillType, 'Blocked Radial Gradient'), SvgElement.getAnimate(SvgElement.Animate(getRadialAnimationType(seed), '', values, val, '0', getAnimationRepeat(seed), 'freeze'))));
        
      }
    }
    return defs;
  }

  function getFillStyles(Fill memory fill) public pure returns (string memory) {
    if (LogoHelper.equal(fill.fillType, 'Solid')) {
      return string(abi.encodePacked('.', fill.class, ' { fill: ', fill.colors[0], ' } '));
    } else if (LogoHelper.equal(fill.fillType, 'Linear Gradient')
                || LogoHelper.equal(fill.fillType, 'Radial Gradient')
                  || LogoHelper.equal(fill.fillType, 'Blocked Linear Gradient')
                    || LogoHelper.equal(fill.fillType, 'Blocked Radial Gradient')) {
      return string(abi.encodePacked('.', fill.class, ' { fill: url(#', fill.id, ') } '));
    }
    string memory styles = '';
    return styles;
  }

  function getLinearAnimationType(string memory seed) private pure returns (string memory) {
    string[4] memory types = ['x1', 'x2', 'y1', 'y2'];
    return types[LogoHelper.random(seed) % types.length];
  }

  function getRadialAnimationType(string memory seed) private pure returns (string memory) {
    string[3] memory types = ['fx', 'fy', 'r'];
    return types[LogoHelper.random(seed) % types.length];
  }

  function getAnimationRepeat(string memory seed) private pure returns (string memory) {
    string[3] memory types = ['indefinite', '1', '2'];
    return types[LogoHelper.random(seed) % types.length];
  }



}

//	SPDX-License-Identifier: MIT
/// @notice Helper to build svg elements
pragma solidity ^0.8.0;

library SvgElement {
  struct Rect {
    string class;
    string x;
    string y;
    string width;
    string height;
    string opacity;
    string fill;
    string filter;
  }

  function getRect(Rect memory rect) public pure returns (string memory) {
    string memory element = '<rect ';
    element = !equal(rect.class, '') ? string(abi.encodePacked(element, 'class="', rect.class, '" ')) : element;
    element = !equal(rect.x, '') ? string(abi.encodePacked(element, 'x="', rect.x, '" ')) : element;
    element = !equal(rect.y, '') ? string(abi.encodePacked(element, 'y="', rect.y, '" ')) : element;
    element = !equal(rect.width, '') ? string(abi.encodePacked(element, 'width="', rect.width, '" ')) : element;
    element = !equal(rect.height, '') ? string(abi.encodePacked(element, 'height="', rect.height, '" ')) : element;
    element = !equal(rect.opacity, '') ? string(abi.encodePacked(element, 'opacity="', rect.opacity, '" ')) : element;
    element = !equal(rect.fill, '') ? string(abi.encodePacked(element, 'fill="url(#', rect.fill, ')" ')) : element;
    element = !equal(rect.filter, '') ? string(abi.encodePacked(element, 'filter="url(#', rect.filter, ')" ')) : element;
    element = string(abi.encodePacked(element, '/>'));
    return element;
  }

  struct Circle {
    string class;
    string cx;
    string cy;
    string r;
    string opacity;
  }

  function getCircle(Circle memory circle) public pure returns (string memory) {
    string memory element = '<circle ';
    element = !equal(circle.class, '') ? string(abi.encodePacked(element, 'class="', circle.class, '" ')) : element;
    element = !equal(circle.cx, '') ? string(abi.encodePacked(element, 'cx="', circle.cx, '" ')) : element;
    element = !equal(circle.cy, '') ? string(abi.encodePacked(element, 'cy="', circle.cy, '" ')) : element;
    element = !equal(circle.r, '') ? string(abi.encodePacked(element, 'r="', circle.r, '" ')) : element;
    element = !equal(circle.opacity, '') ? string(abi.encodePacked(element, 'opacity="', circle.opacity, '" ')) : element;
    element = string(abi.encodePacked(element, '/>'));
    return element;
  }

  struct Text {
    string class;
    string x;
    string y;
    string dx;
    string dy;
    string display;
    string baseline;
    string anchor;
    string rotate;
    string transform;
    string clipPath;
    string val;
  }

  function getText(Text memory txt) public pure returns (string memory) {
    string memory element = '<text ';
    element = !equal(txt.class, '') ? string(abi.encodePacked(element, 'class="', txt.class, '" ')) : element;
    element = !equal(txt.x, '') ? string(abi.encodePacked(element, 'x="', txt.x, '" ')) : element;
    element = !equal(txt.y, '') ? string(abi.encodePacked(element, 'y="', txt.y, '" ')) : element;
    element = !equal(txt.dx, '') ? string(abi.encodePacked(element, 'dx="', txt.dx, '" ')) : element;
    element = !equal(txt.dy, '') ? string(abi.encodePacked(element, 'dy="', txt.dy, '" ')) : element;
    element = !equal(txt.display, '') ? string(abi.encodePacked(element, 'display="', txt.display, '" ')) : element;
    element = !equal(txt.baseline, '') ? string(abi.encodePacked(element, 'dominant-baseline="', txt.baseline, '" ')) : element;
    element = !equal(txt.anchor, '') ? string(abi.encodePacked(element, 'text-anchor="', txt.anchor, '" ')) : element;
    element = !equal(txt.rotate, '') ? string(abi.encodePacked(element, 'rotate="', txt.rotate, '" ')) : element;
    element = !equal(txt.transform, '') ? string(abi.encodePacked(element, 'transform="', txt.transform, '" ')) : element;
    element = !equal(txt.clipPath, '') ? string(abi.encodePacked(element, 'clip-path="url(#', txt.clipPath, ')" ')) : element;
    element = string(abi.encodePacked(element, '>', txt.val, '</text>'));
    return element;
  }

  struct TextPath {
    string class;
    string href;
    string val;
  }

  function getTextPath(TextPath memory txtPath) public pure returns (string memory) {
    string memory element = '<textPath ';
    element = !equal(txtPath.class, '') ? string(abi.encodePacked(element, 'class="', txtPath.class, '" ')) : element;
    element = !equal(txtPath.class, '') ? string(abi.encodePacked(element, 'href="#', txtPath.href, '" ')) : element;
    element = string(abi.encodePacked(element, '>', txtPath.val, '</textPath>'));
    return element;
  }

  struct Tspan {
    string class;
    string display;
    string dx;
    string dy;
    string val;
  }

  function getTspan(Tspan memory tspan) public pure returns (string memory) {
    string memory element = '<tspan ';
    element = !equal(tspan.class, '') ? string(abi.encodePacked(element, 'class="', tspan.class, '" ')) : element;
    element = !equal(tspan.display, '') ? string(abi.encodePacked(element, 'display="', tspan.display, '" ')) : element;
    element = !equal(tspan.dx, '') ? string(abi.encodePacked(element, 'dx="', tspan.dx, '" ')) : element;
    element = !equal(tspan.dy, '') ? string(abi.encodePacked(element, 'dy="', tspan.dy, '" ')) : element;
    element = string(abi.encodePacked(element, '>', tspan.val, '</tspan>'));
    return element;
  }

  struct Animate {
    string attributeName;
    string to;
    string values;
    string duration;
    string begin;
    string repeatCount;
    string fill;
  }

  function getAnimate(Animate memory animate) public pure returns (string memory) {
    string memory element = '<animate ';
    element = !equal(animate.attributeName, '') ? string(abi.encodePacked(element, 'attributeName="', animate.attributeName, '" ')) : element;
    element = !equal(animate.to, '') ? string(abi.encodePacked(element, 'to="', animate.to, '" ')) : element;
    element = !equal(animate.values, '') ? string(abi.encodePacked(element, 'values="', animate.values, '" ')) : element;
    element = !equal(animate.duration, '') ? string(abi.encodePacked(element, 'dur="', animate.duration, 'ms" ')) : element;
    element = !equal(animate.begin, '') ? string(abi.encodePacked(element, 'begin="', animate.begin, 'ms" ')) : element;
    element = !equal(animate.repeatCount, '') ? string(abi.encodePacked(element, 'repeatCount="', animate.repeatCount, '" ')) : element;
    element = !equal(animate.fill, '') ? string(abi.encodePacked(element, 'fill="', animate.fill, '" ')) : element;
    element = string(abi.encodePacked(element, '/>'));
    return element;
  }

  struct Path {
    string id;
    string pathAttr;
    string val;
  }

  function getPath(Path memory path) public pure returns (string memory) {
    string memory element = '<path ';
    element = !equal(path.id, '') ? string(abi.encodePacked(element, 'id="', path.id, '" ')) : element;
    element = !equal(path.pathAttr, '') ? string(abi.encodePacked(element, 'd="', path.pathAttr, '" ')) : element;
    element = string(abi.encodePacked(element, '>', path.val, '</path>'));
    return element;
  }

  struct Group {
    string transform;
    string val;
  }

  function getGroup(Group memory group) public pure returns (string memory) {
    string memory element = '<g ';
    element = !equal(group.transform, '') ? string(abi.encodePacked(element, 'transform="', group.transform, '" ')) : element;
    element = string(abi.encodePacked(element, '>', group.val, '</g>'));
    return element;
  }

  struct Pattern {
    string id;
    string x;
    string y;
    string width;
    string height;
    string patternUnits;
    string val;
  }

  function getPattern(Pattern memory pattern) public pure returns (string memory) {
    string memory element = '<pattern ';
    element = !equal(pattern.id, '') ? string(abi.encodePacked(element, 'id="', pattern.id, '" ')) : element;
    element = !equal(pattern.x, '') ? string(abi.encodePacked(element, 'x="', pattern.x, '" ')) : element;
    element = !equal(pattern.y, '') ? string(abi.encodePacked(element, 'y="', pattern.y, '" ')) : element;
    element = !equal(pattern.width, '') ? string(abi.encodePacked(element, 'width="', pattern.width, '" ')) : element;
    element = !equal(pattern.height, '') ? string(abi.encodePacked(element, 'height="', pattern.height, '" ')) : element;
    element = !equal(pattern.patternUnits, '') ? string(abi.encodePacked(element, 'patternUnits="', pattern.patternUnits, '" ')) : element;
    element = string(abi.encodePacked(element, '>', pattern.val, '</pattern>'));
    return element;
  }

  struct Filter {
    string id;
    string val;
  }

  function getFilter(Filter memory filter) public pure returns (string memory) {
    string memory element = '<filter ';
    element = !equal(filter.id, '') ? string(abi.encodePacked(element, 'id="', filter.id, '" ')) : element;
    element = string(abi.encodePacked(element, '>', filter.val, '</filter>'));
    return element;
  }

  struct Turbulance {
    string fType;
    string baseFrequency;
    string octaves;
    string result;
    string val;
  }

  function getTurbulance(Turbulance memory turbulance) public pure returns (string memory) {
    string memory element = '<feTurbulence ';
    element = !equal(turbulance.fType, '') ? string(abi.encodePacked(element, 'type="', turbulance.fType, '" ')) : element;
    element = !equal(turbulance.baseFrequency, '') ? string(abi.encodePacked(element, 'baseFrequency="', turbulance.baseFrequency, '" ')) : element;
    element = !equal(turbulance.octaves, '') ? string(abi.encodePacked(element, 'numOctaves="', turbulance.octaves, '" ')) : element;
    element = !equal(turbulance.result, '') ? string(abi.encodePacked(element, 'result="', turbulance.result, '" ')) : element;
    element = string(abi.encodePacked(element, '>', turbulance.val, '</feTurbulence>'));
    return element;
  }

  struct DisplacementMap {
    string mIn;
    string in2;
    string result;
    string scale;
    string xChannelSelector;
    string yChannelSelector;
    string val;
  }

  function getDisplacementMap(DisplacementMap memory displacementMap) public pure returns (string memory) {
    string memory element = '<feDisplacementMap ';
    element = !equal(displacementMap.mIn, '') ? string(abi.encodePacked(element, 'in="', displacementMap.mIn, '" ')) : element;
    element = !equal(displacementMap.in2, '') ? string(abi.encodePacked(element, 'in2="', displacementMap.in2, '" ')) : element;
    element = !equal(displacementMap.result, '') ? string(abi.encodePacked(element, 'result="', displacementMap.result, '" ')) : element;
    element = !equal(displacementMap.scale, '') ? string(abi.encodePacked(element, 'scale="', displacementMap.scale, '" ')) : element;
    element = !equal(displacementMap.xChannelSelector, '') ? string(abi.encodePacked(element, 'xChannelSelector="', displacementMap.xChannelSelector, '" ')) : element;
    element = !equal(displacementMap.yChannelSelector, '') ? string(abi.encodePacked(element, 'yChannelSelector="', displacementMap.yChannelSelector, '" ')) : element;
    element = string(abi.encodePacked(element, '>', displacementMap.val, '</feDisplacementMap>'));
    return element;
  }

  struct ClipPath {
    string id;
    string val;
  }

  function getClipPath(ClipPath memory clipPath) public pure returns (string memory) {
    string memory element = '<clipPath ';
    element = !equal(clipPath.id, '') ? string(abi.encodePacked(element, 'id="', clipPath.id, '" ')) : element;
    element = string(abi.encodePacked(element, ' >', clipPath.val, '</clipPath>'));
    return element;
  }

  struct LinearGradient {
    string id;
    string[] colors;
    bool blockScheme;
    string animate;
  }

  function getLinearGradient(LinearGradient memory linearGradient) public pure returns (string memory) {
    string memory element = '<linearGradient ';
    element = !equal(linearGradient.id, '') ? string(abi.encodePacked(element, 'id="', linearGradient.id, '">')) : element;
    uint baseOffset = 100 / (linearGradient.colors.length - 1);
    for (uint i=0; i<linearGradient.colors.length; i++) {
      uint offset;
      if (i != linearGradient.colors.length - 1) {
        offset = baseOffset * i;
      } else {
        offset = 100;
      }
      if (linearGradient.blockScheme && i != 0) {
        element = string(abi.encodePacked(element, '<stop offset="', toString(offset), '%"  stop-color="', linearGradient.colors[i-1], '" />'));
      }

      if (!linearGradient.blockScheme || (linearGradient.blockScheme && i != linearGradient.colors.length - 1)) {
        element = string(abi.encodePacked(element, '<stop offset="', toString(offset), '%"  stop-color="', linearGradient.colors[i], '" />'));
      }
    }
    element = !equal(linearGradient.animate, '') ? string(abi.encodePacked(element, linearGradient.animate)) : element;
    element =  string(abi.encodePacked(element, '</linearGradient>'));
    return element;
  }

  struct RadialGradient {
    string id;
    string[] colors;
    bool blockScheme;
    string animate;
  }

  function getRadialGradient(RadialGradient memory radialGradient) public pure returns (string memory) {
    string memory element = '<radialGradient ';
    element = !equal(radialGradient.id, '') ? string(abi.encodePacked(element, 'id="', radialGradient.id, '">')) : element;
    uint baseOffset = 100 / (radialGradient.colors.length - 1);
    for (uint i=0; i<radialGradient.colors.length; i++) {
      uint offset;
      if (i != radialGradient.colors.length - 1) {
        offset = baseOffset * i;
      } else {
        offset = 100;
      }
      if (radialGradient.blockScheme && i != 0) {
        element = string(abi.encodePacked(element, '<stop offset="', toString(offset), '%"  stop-color="', radialGradient.colors[i-1], '" />'));
      }

      if (!radialGradient.blockScheme || (radialGradient.blockScheme && i != radialGradient.colors.length - 1)) {
        element = string(abi.encodePacked(element, '<stop offset="', toString(offset), '%"  stop-color="', radialGradient.colors[i], '" />'));
      }
    }
    element = !equal(radialGradient.animate, '') ? string(abi.encodePacked(element, radialGradient.animate)) : element;
    element =  string(abi.encodePacked(element, '</radialGradient>'));
    return element;
  }

  function equal(string memory a, string memory b) private pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  function toString(uint256 value) private pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
}
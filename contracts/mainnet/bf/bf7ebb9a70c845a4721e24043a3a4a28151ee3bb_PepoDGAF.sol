/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

interface IERC165 {

  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

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

library Strings {

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

abstract contract Context {

  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }

}

abstract contract Ownable is Context {

  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _transferOwnership(_msgSender());
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
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

library Address {

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
    return _verifyCallResult(success, returndata, errorMessage);
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
    return _verifyCallResult(success, returndata, errorMessage);
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

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
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

interface IERC721Receiver {

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

abstract contract ERC165 is IERC165 {

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }

}

interface IERC721Enumerable is IERC721 {

  function totalSupply() external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
  function tokenByIndex(uint256 index) external view returns (uint256);

}

interface IERC721Metadata is IERC721 {

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);

}

//ERC721A contract was taken as bases, but was modified, so that the indexing would start from 1
//Modified version name: ERC721VI
contract ERC721VI is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {

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

  uint256 internal currentIndex = 1;
  uint256 internal immutable maxBatchSize;
  string private _name;
  string private _symbol;

  mapping(uint256 => TokenOwnership) internal _ownerships;
  mapping(address => AddressData) private _addressData;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_
  ) {
    require(maxBatchSize_ > 0, 'ERC721VI: max batch size must be nonzero');
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
  }

  function totalSupply() public view override returns (uint256) {
    return currentIndex - 1;
  }

  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), 'ERC721VI: global index out of bounds');
    return index;
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
    require(index < balanceOf(owner), 'ERC721VI: owner index out of bounds');
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
    revert('ERC721VI: unable to get token of owner by index');
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), 'ERC721VI: balance query for the zero address');
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(owner != address(0), 'ERC721VI: number minted query for the zero address');
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
    require(_exists(tokenId), 'ERC721VI: owner query for nonexistent token');

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

    revert('ERC721VI: unable to determine the owner of token');
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
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
  }

  function _baseURI() internal view virtual returns (string memory) {
    return '';
  }

  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721VI.ownerOf(tokenId);
    require(to != owner, 'ERC721VI: approval to current owner');

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      'ERC721VI: approve caller is not owner nor approved for all'
    );

    _approve(to, tokenId, owner);
  }

  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), 'ERC721VI: approved query for nonexistent token');

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), 'ERC721VI: approve to caller');

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    safeTransferFrom(from, to, tokenId, '');
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      'ERC721VI: transfer to non ERC721Receiver implementer'
    );
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    require(tokenId > 0, 'Indexing starts from 1');
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, '');
  }

  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), 'ERC721VI: mint to the zero address');
    require(!_exists(startTokenId), 'ERC721VI: token already minted');
    require(quantity <= maxBatchSize, 'ERC721VI: quantity to mint too high');
    require(quantity > 0, 'ERC721VI: quantity must be greater 0');

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
        'ERC721VI: transfer to non ERC721Receiver implementer'
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(isApprovedOrOwner, 'ERC721VI: transfer caller is not owner nor approved');

    require(prevOwnership.addr == from, 'ERC721VI: transfer from incorrect owner');
    require(to != address(0), 'ERC721VI: transfer to the zero address');

    _beforeTokenTransfers(from, to, tokenId, 1);

    _approve(address(0), tokenId, prevOwnership.addr);

    unchecked {
      _addressData[from].balance -= 1;
      _addressData[to].balance += 1;
    }

    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(prevOwnership.addr, prevOwnership.startTimestamp);
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

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
          revert('ERC721VI: transfer to non ERC721Receiver implementer');
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

  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}


//██████╗░███████╗██████╗░░█████╗░  ██████╗░░██████╗░░█████╗░███████╗
//██╔══██╗██╔════╝██╔══██╗██╔══██╗  ██╔══██╗██╔════╝░██╔══██╗██╔════╝
//██████╔╝█████╗░░██████╔╝██║░░██║  ██║░░██║██║░░██╗░███████║█████╗░░
//██╔═══╝░██╔══╝░░██╔═══╝░██║░░██║  ██║░░██║██║░░╚██╗██╔══██║██╔══╝░░
//██║░░░░░███████╗██║░░░░░╚█████╔╝  ██████╔╝╚██████╔╝██║░░██║██║░░░░░
//╚═╝░░░░░╚══════╝╚═╝░░░░░░╚════╝░  ╚═════╝░░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░

contract PepoDGAF is ERC721VI, Ownable {
  using Strings for uint256;

  string private _apiURI = "";
  bool public paused = true;
  uint256 public price = 0.04 ether; 
  uint256 public maxSupply = 3333; 
  uint256 public maxPerTx = 10;

  address token1 = 0x8FA600364B93C53e0c71C7A33d2adE21f4351da3; //Larva Chads
  address token2 = 0xbad6186E92002E312078b5a1dAfd5ddf63d3f731; //Anonymice
  address token3 = 0x15Cc16BfE6fAC624247490AA29B6D632Be549F00; //AnonymiceBreeding
  address token4 = 0x42069ABFE407C60cf4ae4112bEDEaD391dBa1cdB; //CryptoDickbutts

  constructor() ERC721VI("Pepo DGAF", "PepoDGAF", maxPerTx) {}

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxPerTx, "Invalid mint amount!");
    require(currentIndex + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused for now!");

    uint _userBalance1 = IERC721(token1).balanceOf(msg.sender);
    uint _userBalance2 = IERC721(token2).balanceOf(msg.sender);
    uint _userBalance3 = IERC721(token3).balanceOf(msg.sender);
    uint _userBalance4 = IERC721(token4).balanceOf(msg.sender);

    if (_userBalance1 + _userBalance2 + _userBalance3 + _userBalance4 > 0) { // owns one of the nft
      require(msg.value >= price * _mintAmount / 2, "Insufficient funds!");
      _safeMint(msg.sender, _mintAmount);
    } else {
      require(msg.value >= price * _mintAmount, "Insufficient funds!");
      _safeMint(msg.sender, _mintAmount);
    }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
  }

  function togglePaused() public onlyOwner {
    paused = !paused;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _apiURI;
  }

  function setBaseURI(string memory _uri) public onlyOwner {
    _apiURI = _uri;
  }

  function setMaxPerTx(uint256 _maxPerTx) public onlyOwner {
    maxPerTx = _maxPerTx;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function withdrawall() public onlyOwner {
    uint256 _balance = address(this).balance;
    require(payable(0x58366d849685eE52A1faB9F04e29Cb1A6Ba03029).send(_balance));
  }
}
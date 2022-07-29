/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// File: DeraGame/lib/Strings.sol



pragma solidity ^0.8.0;

library Strings {
  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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

  // @notice Encodes some bytes to the base64 representation
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
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
        )
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

  function substr(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory ) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
      result[i-startIndex] = strBytes[i];
    }
    return string(result);
  }

  function invert(string memory str) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(strBytes.length);
    for(uint i = 0; i < strBytes.length; i++) {
      result[i] = strBytes[strBytes.length - i - 1];
    }
    return string(result);
  }

  function zeroPad(string memory str, uint256 num) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(num);
    uint cnt = 0;
    for(uint i = 0; i < num - strBytes.length; i++){
      result[i] = '0';
      cnt++;
    }
    for(uint i = cnt; i < num; i ++) {
      result[i] = strBytes[i - cnt];
    }
    return string(result);
  }

  function trimLeft(string memory str) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    uint len = strBytes.length;
    uint cnt = 0;
    for(uint i = 0; i < len; i++) {
      if(strBytes[i] == '0') {
        cnt++;
      } else {
        break;
      }
    }
    return cnt == len ? '' : substr(str, cnt, len);
  }

  function trimRight(string memory str) internal pure returns (string memory) {
    return invert(trimLeft(invert(str)));
  }
}
// File: DeraGame/lib/SafeMath.sol



pragma solidity ^0.8.0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require((c = a + b) >= b, "SafeMath: Add Overflow");
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require((c = a - b) <= a, "SafeMath: Underflow");
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b == 0 || (c = a * b) / b == a, "SafeMath: Mul Overflow");
  }
}
// File: DeraGame/lib/AbstractContracts.sol



pragma solidity ^0.8.0;

// Abstract Contracts
abstract contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address _newOwner) public virtual onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    owner = _newOwner;
  }
}

abstract contract Mintable {
  mapping (address => bool) public minters;

  constructor() {
    minters[msg.sender] = true;
  }

  modifier onlyMinter() {
    require(minters[msg.sender], "Mintable: caller is not the minter");
    _;
  }

  function setMinter(address _minter) public virtual onlyMinter {
    require(_minter != address(0), "Mintable: new minter is the zero address");
    minters[_minter] = true;
  }

  function removeMinter(address _minter) external onlyMinter returns (bool) {
    require(minters[_minter], "Mintable: _minter is not a minter");
    minters[_minter] = false;
    return true;
  }
}

abstract contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }
}
// File: DeraGame/lib/Interfaces.sol



pragma solidity ^0.8.0;

// Interfaces
interface IERC20 {
  function approve(address _spender, uint256 _amount) external returns (bool);
  function transfer(address _to, uint256 _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

interface IERC165 {
  function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface IERC721 {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) external view returns (address owner);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _to, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address operator);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721Metadata {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IERC721Receiver {
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}
// File: DeraGame/StandardERC721.sol



pragma solidity ^0.8.0;




// Contract
contract StandardERC721 is Ownable {
  using SafeMath for uint256;

  // ERC721
  mapping(uint256 => address) internal _owners;
  mapping(address => uint256) internal _balances;
  mapping(uint256 => address) internal _tokenApprovals;
  mapping(address => mapping(address => bool)) internal _operatorApprovals;

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
  // Constructor
  constructor() {}

  // ERC165
  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return
      interfaceId == type(IERC165).interfaceId ||
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId;
  }

  // ERC721 (public)
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balances[owner];
  }

  function ownerOf(uint256 tokenId) public view virtual returns (address) {
    address tokenOwner = _owners[tokenId];
    require(tokenOwner != address(0), "ERC721: owner query for nonexistent token");
    return tokenOwner;
  }

  function approve(address to, uint256 tokenId) public returns (bool) {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      msg.sender == owner || isApprovedForAll(owner, msg.sender),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
    return true;
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");
    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public returns (bool) {
    require(operator != msg.sender, "ERC721: approve to caller");

    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
    return true;
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(address from, address to, uint256 tokenId) public returns (bool) {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    _transfer(from, to, tokenId);
    return true;
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public returns (bool) {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
    return true;
  }

  // ERC721 (internal)
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _transfer(address from, address to, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
    if (isContract(to)) {
      try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
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

  // Utils
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}
// File: DeraGame/DeraGameNFT.sol



pragma solidity ^0.8.0;



// Contract
contract TestNFT is StandardERC721, Mintable {
  using SafeMath for uint256;

  // ERC721Metadata
  string private baseURI;
  string public name;
  string public symbol;

  // ERC721Enumerable
  uint256[] private _allTokens;
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
  mapping(uint256 => uint256) private _ownedTokensIndex;
  mapping(uint256 => uint256) private _allTokensIndex;

  // Constructor
  constructor() {
    name = 'Test NFT';
    symbol = 'TNFT';
    baseURI = 'https://raw.githubusercontent.com/dera-test/asset/main/metadata/';
  }

  // Receive
  receive() external payable {}

  // Public Functions
  function mint(address _to, uint256 _tokenId) external onlyMinter returns (bool) {
    require(!_exists(_tokenId), "ERC721: token already minted");
    require(_to != address(0), "ERC721: mint to the zero address");

    _beforeTokenTransfer(address(0), _to, _tokenId);

    _balances[_to] += 1;
    _owners[_tokenId] = _to;

    emit Transfer(address(0), _to, _tokenId);
    return true;
  }

  function burn(uint256 _tokenId) external returns (bool) {
    require(_exists(_tokenId), "ERC721: token not minted");
    address tokenOwner = ownerOf(_tokenId);
    require(tokenOwner == msg.sender, "ERC721: caller is not token owner");

    _beforeTokenTransfer(tokenOwner, address(0), _tokenId);

    delete _tokenApprovals[_tokenId];

    _balances[tokenOwner] -= 1;
    delete _owners[_tokenId];

    emit Transfer(owner, address(0), _tokenId);
    return true;
  }

  // Meta Transaction (public)
  function transferFromPreSigned(address _from, address _to, uint256 _tokenId, bytes memory _sig) external returns (bool) {
    address signer = recover(transferPreSignedHashing(address(this), _from, _to, _tokenId), _sig);
    require(signer == _from, "ERC721MetaTransaction: signer not matched with from address");
    require(_isApprovedOrOwner(_from, _tokenId), "ERC721: from address is not owner nor approved");
    _transfer(_from, _to, _tokenId);
    return true;    
  }

  function approvePreSigned(address _to, uint256 _tokenId, bytes memory _sig) external returns (bool) {
    address signer = recover(approvePreSignedHashing(address(this), _to, _tokenId), _sig);
    address tokenOwner = ownerOf(_tokenId);
    require(signer == tokenOwner, "ERC721MetaTransaction: signer not matched with from address");
    require(_to != tokenOwner, "ERC721: approval to current owner");
    _approve(_to, _tokenId);
    return true;   
  }

  // ERC721Metadata (public)
  function uri(uint256 _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: tokenId not exist");
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
  }

  // ERC721Enumerable (public)
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
    require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
    return _allTokens[index];
  }

  // ERC721Enumerable (private)
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) private {
    if (from == address(0)) {
      _addTokenToAllTokensEnumeration(tokenId);
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to == address(0)) {
      _removeTokenFromAllTokensEnumeration(tokenId);
    } else if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    uint256 lastTokenIndex = balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    if (tokenIndex != lastTokenIndex) {
       uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];

    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    delete _allTokensIndex[tokenId];
    _allTokens.pop();
  }

  // Meta Transaction (private)
  function transferPreSignedHashing(address _token, address _from, address _to, uint256 _tokenId) public pure returns (bytes32) {
    /* "b3ccac7c: transferPreSignedHashing(address,address,address,uint256) */
    return keccak256(abi.encodePacked(bytes4(0xb3ccac7c), _token, _from, _to, _tokenId));
  }

  function approvePreSignedHashing(address _token, address _to, uint256 _tokenId) public pure returns (bytes32) {
     /* "f42eaa25: approvePreSignedHashing(address,address,uint256) */
    return keccak256(abi.encodePacked(bytes4(0xf42eaa25), _token, _to, _tokenId));
  }

  function recover(bytes32 hash, bytes memory sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, hash));
      return ecrecover(prefixedHashMessage, v, r, s);
    }
  }

  // Admin Functions
  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function destruct() external onlyOwner {
    selfdestruct(payable(msg.sender));
  }
}
/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// File: NowLoading/lib/Strings.sol



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
// File: NowLoading/lib/LibPart.sol


pragma solidity ^0.8.0;

library LibPart {
  bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");
  struct Part {
    address payable account;
    uint256 value;
  }
  function hash(Part memory part) internal pure returns (bytes32) {
    return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
  }
}
// File: NowLoading/lib/SafeMath.sol



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
// File: NowLoading/lib/AbstractContracts.sol



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
// File: NowLoading/lib/Interfaces.sol



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
// File: NowLoading/StandardERC721.sol



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
  event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalities);

  // Constants
  bytes4 private constant _INTERFACE_ID_ROYALTIES = 0xcad96cca; // Rarible

  // ERC721Metadata
  string public name;
  string public symbol;

  // Rarible
  LibPart.Part internal royaltyFee;
    
  // Constructor
  constructor() {}

  // ERC165
  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return
      interfaceId == type(IERC165).interfaceId ||
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == _INTERFACE_ID_ROYALTIES;
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

  // Rarible
  function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory) {
    require(_exists(id), "ERC721: token not exist");
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0] = royaltyFee;
    return _royalties;
  }

  function setRoyaltyFee(address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) public onlyOwner returns (bool) {
    royaltyFee = LibPart.Part(_royaltiesRecipientAddress, _percentageBasisPoints);
    return true;    
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
// File: NowLoading/JSNowLoading.sol



pragma solidity ^0.8.0;



// Contract
contract JSNowLoading is StandardERC721, Mintable {
  using SafeMath for uint256;

  // Customize
  uint256 public totalSupply;
  uint256 private maxTokenId;
  address private defaultOwner; 

  // Constructor
  constructor() {
    name = 'JS Now Loading';
    symbol = 'JSNL';
  }

  // Receive
  receive() external payable {}

  // Public Functions
  function mint(address _to) public onlyMinter returns (bool) {
    uint256 tokenId = totalSupply + 1;
    require(!_exists(tokenId), "ERC721: token already minted");
    require(_to != address(0), "ERC721: mint to the zero address");

    _balances[_to] += 1;
    _owners[tokenId] = _to;
    totalSupply++;

    emit Transfer(address(0), _to, tokenId);
    return true;
  }

  function bulkMint(uint256 _fromTokenId, uint256 _toTokenId) external onlyMinter returns (bool) {
    require(defaultOwner != address(0), "ERC721: defaultOwner not set");
    require(maxTokenId < _fromTokenId, "ERC721: tokenId range is already minted");
    for(uint256 i = _fromTokenId; i <= _toTokenId; i++) {
      emit Transfer(address(0), defaultOwner, i);
    }
    uint256 count = _toTokenId - _fromTokenId + 1;
    _balances[defaultOwner] += count;
    totalSupply += count;
    maxTokenId = _toTokenId;
    return true;
  }

  function ownerOf(uint256 tokenId) public view override returns (address) {
    address tokenOwner = _owners[tokenId];
    require(tokenOwner != address(0) || tokenId <= totalSupply, "ERC721: owner query for nonexistent token");
    if(tokenOwner != address(0)) {
      return tokenOwner;
    } else  {
      return defaultOwner; 
    }
  }

  // View Functions (Public)
  function tokenURI(uint256 _tokenId) external view returns (string memory) {
    require(_exists(_tokenId), "ERC721: tokenId not exist");
    string memory baseURL = "https://raw.githubusercontent.com/js-nowloading/asset/main/metadata/";
    return string(abi.encodePacked(baseURL, Strings.toString(_tokenId), ".json"));
  }

  // View Functions (Private)
  function _exists(uint256 tokenId) internal view override returns (bool) {
    return (tokenId <= totalSupply);
  }

  // Admin Functions
  function setDefaultOwner(address _defaultOwner) external onlyOwner returns (bool) {
    defaultOwner = _defaultOwner;
    return true;
  }
}
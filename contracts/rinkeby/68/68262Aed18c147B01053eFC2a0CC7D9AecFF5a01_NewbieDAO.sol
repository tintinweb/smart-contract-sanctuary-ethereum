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
pragma solidity ^0.8.0;

import "./SimpleERC721.sol";
import "./TokenPool.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Newbie is SimpleERC721, TokenPool {
  using Strings for uint256;
  bool public initialized;

  uint256 public constant WITHDRAW_FEE = 1000;
  address public newbie;

  string public baseURI;
  uint256 public mintFee;

  uint256 public totalSupply;

  function initialize(
    address newbie_,
    string memory name_,
    string memory symbol_,
    uint256 supply,
    string memory baseURI_,
    uint256 mintFee_
  ) external {
    require(!initialized);
    initialized = true;
    admin = msg.sender;
    newbie = newbie_;
    name = name_;
    symbol = symbol_;
    baseURI = baseURI_;
    mintFee = mintFee_;
    TokenPool.init(supply);
  }

  function mint(uint256 amount) external payable {
    address account = msg.sender;
    require(mintFee * amount >= msg.value);
    uint256 updates = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
    for (uint256 i = 0; i < amount; i++) {
      _mint(account, hashToken(updates));
    }
    totalSupply += amount;
  }

  function withdraw() external {
    require(msg.sender == newbie || msg.sender == admin);
    uint256 balance = address(this).balance;
    uint256 fee = (balance * WITHDRAW_FEE) / 10000;
    payable(admin).transfer(fee);
    payable(newbie).transfer(balance - fee);
  }

  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    require(ownerOf[tokenId] != address(0));
    return string(abi.encodePacked(baseURI, tokenId.toString()));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleERC721.sol";
import "./Proxy.sol";
import "./Newbie.sol";

contract NewbieDAO is SimpleERC721 {
  struct NewbieInfo {
    Newbie token;
    uint256 weight;
  }

  bool public initialized;
  address public logic;

  NewbieInfo[] public newbies;

  function initialize() external onlyOwner {
    require(!initialized);
    initialized = true;

    name = "Newbie DAO";
    symbol = "NBDAO";
  }

  function setLogic(address _logic) external onlyOwner {
    logic = _logic;
  }

  function register(
    address owner,
    string memory name,
    string memory symbol,
    uint256 supply,
    string memory baseURI,
    uint256 mintFee
  ) external onlyOwner returns (uint256 newbieId) {
    Newbie newbie = Newbie(address(new Proxy(logic)));
    newbie.initialize(owner, name, symbol, supply, baseURI, mintFee);
    newbies.push(NewbieInfo(newbie, mintFee / 0.01 ether));
    newbieId = newbies.length;
    _mint(owner, newbieId);
  }

  function totalSupply() external view returns (uint256) {
    return newbies.length;
  }

  function withdraw() external onlyOwner {
    payable(admin).transfer(address(this).balance);
  }

  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    require(ownerOf[tokenId] != address(0));
    return string(abi.encodePacked(newbies[tokenId - 1].token.baseURI(), "promo"));
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proxy {
  address implementation_;
  address public admin;

  constructor(address impl) {
    implementation_ = impl;
    admin = msg.sender;
  }

  receive() external payable {}

  function setImplementation(address newImpl) public {
    require(msg.sender == admin);
    implementation_ = newImpl;
  }

  function implementation() public view returns (address impl) {
    impl = implementation_;
  }

  function transferOwnership(address newOwner) external {
    require(msg.sender == admin);
    admin = newOwner;
  }

  function _delegate(address implementation__) internal virtual {
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), implementation__, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  function _implementation() internal view returns (address) {
    return implementation_;
  }

  fallback() external payable virtual {
    _delegate(_implementation());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleERC721 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  address implementation_;
  address public admin;

  string public name;
  string public symbol;

  mapping(address => uint256) public balanceOf;
  mapping(uint256 => address) public ownerOf;
  mapping(uint256 => address) public getApproved;
  mapping(address => mapping(address => bool)) public approveForAll;

  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  function isApprovedForAll(address account, address spender) public view returns (bool) {
    return approveForAll[account][spender];
  }

  function transfer(address to, uint256 tokenId) external {
    require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
    _transfer(msg.sender, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
    supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
  }

  function approve(address spender, uint256 tokenId) external {
    address owner_ = ownerOf[tokenId];
    require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "NOT_APPROVED");
    getApproved[tokenId] = spender;
    emit Approval(owner_, spender, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) external {
    approveForAll[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    require(msg.sender == getApproved[tokenId] || isApprovedForAll(from, msg.sender), "NOT_APPROVED");
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public {
    transferFrom(from, to, tokenId);
    if (to.code.length != 0) {
      (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02, msg.sender, from, tokenId, data));
      bytes4 selector = abi.decode(returned, (bytes4));
      require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
    }
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    require(ownerOf[tokenId] == from);
    _beforeTokenTransfer(from, to, tokenId);

    balanceOf[from]--;
    balanceOf[to]++;

    delete getApproved[tokenId];

    ownerOf[tokenId] = to;
    emit Transfer(msg.sender, to, tokenId);
  }

  function _mint(address to, uint256 tokenId) internal {
    require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

    unchecked {
      balanceOf[to]++;
    }

    ownerOf[tokenId] = to;

    emit Transfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal {
    address owner_ = ownerOf[tokenId];

    require(owner_ != address(0), "NOT_MINTED");
    _beforeTokenTransfer(owner_, address(0), tokenId);

    balanceOf[owner_]--;

    delete ownerOf[tokenId];

    emit Transfer(owner_, address(0), tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenPool {
  uint256 private supply;
  uint256 private tokenHash;
  mapping(uint256 => uint256) private pool;

  function init(uint256 _supply) internal {
    supply = _supply;
  }

  function hashPool(uint256 poolHash) internal returns (uint256 poolId) {
    uint256 index = poolHash % supply;
    poolId = pool[index];
    if (poolId == 0) {
      poolId = index + 1;
    }
    pool[index] = supply;
    supply--;
  }

  function hashToken(uint256 updates) internal returns (uint256 tokenId) {
    require(supply > 0, "No tokens left");
    tokenHash = uint256(keccak256(abi.encodePacked(tokenHash, updates)));
    tokenId = hashPool(tokenHash);
  }
}
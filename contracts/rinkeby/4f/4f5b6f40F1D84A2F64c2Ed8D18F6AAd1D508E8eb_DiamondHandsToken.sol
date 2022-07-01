/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: MIT
// File: DiamondHands/lib/Interfaces.sol

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

interface IUniswapPair {
  function totalSupply() external view returns (uint256);
  function balanceOf(address _account) external view returns (uint256);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapRouter {
  function factory() external view returns (address);
  function WETH() external view returns (address);
  function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
  function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: DiamondHands/lib/AbstractContracts.sol



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
// File: DiamondHands/lib/Base64.sol



pragma solidity ^0.8.0;

library Base64 {
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

  function formatValue(uint256 _value, uint256 _decimals, string memory _symbol) internal pure returns (string memory) {
    string memory str = zeroPad(toString(_value), 18);
    string memory integral = trimLeft(substr(str, 0, 18 - _decimals));
    string memory fractional = trimRight(substr(str, 18 - _decimals, 18));
    if(bytes(fractional).length > 8) fractional = substr(fractional, 0, 9);
    string memory integralStr = '0';
    string memory fractionalStr = '';
    if(bytes(integral).length != 0) integralStr = integral;
    if(bytes(fractional).length !=0) fractionalStr = string(abi.encodePacked('.', fractional));
    return string(abi.encodePacked(integralStr, fractionalStr, ' ', _symbol));
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
// File: DiamondHands/lib/SafeMath.sol



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
// File: DiamondHands/StandardERC721.sol



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

  // ERC721Metadata
  string public name;
  string public symbol;

  // ERC721Enumerable
  mapping(address => mapping(uint256 => uint256)) internal _ownedTokens;
  mapping(uint256 => uint256) internal _ownedTokensIndex;
  uint256[] internal _allTokens;
  mapping(uint256 => uint256) internal _allTokensIndex;
    
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

  function ownerOf(uint256 tokenId) public view returns (address) {
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

  function _exists(uint256 tokenId) internal view returns (bool) {
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

    _beforeTokenTransfer(from, to, tokenId);

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

  // ERC721Enumerable (internal)
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal {
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

  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
    uint256 length = balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  function _addTokenToAllTokensEnumeration(uint256 tokenId) internal {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) internal {
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

  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) internal {
    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];

    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    delete _allTokensIndex[tokenId];
    _allTokens.pop();
  }

  // Utils
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

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
}
// File: DiamondHands/DiamondHands.sol



pragma solidity ^0.8.0;





// Contract
contract DiamondHandsToken is StandardERC721 {
  using SafeMath for uint256;

  // Customized
  uint256 private constant MAX_INT = 2**256 - 1;
  uint256 private constant UNIT_PRICE = 12000;
  uint256 private constant INVEST_PER_SLOT = 1000;
  uint256 private constant MATURITY_SLOTS = UNIT_PRICE / INVEST_PER_SLOT;
  uint256 private constant INTERVAL = 1 hours; // 30 days for production
  uint256 private constant MAX_SLIPPAGE = 5000;

  IUniswapFactory private factory;
  IUniswapRouter private router;

  address[] private PATH02;
  address[] private PATH20;
  address[] private PATH21;

  address private wethAddress;
  address private wbtcAddress;
  address private usdcAddress;
  mapping(uint256 => Property) public tokenProperties;
  mapping(uint256 => Slot) public slots;

  struct Property {
    uint256 startSlot;
    bool redeemed;
  }

  struct Slot {
    bool exist;
    uint256 wethBalance;
    uint256 wbtcBalance;
    uint256 usdcInvest;
  }
    
  // Constructor
  constructor() {
    name = 'Diamond Hands Token';
    symbol = 'DHT';

    router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    factory = IUniswapFactory(router.factory());

    wethAddress = router.WETH();
    wbtcAddress = 0x803424D248ed1Ac36bc2Bc0b574eBb781924112A; // WBTC
    usdcAddress = 0x30561FBd0671D3198441120FDa04d446A430e8af; // USDC

    PATH02.push(wethAddress); PATH02.push(usdcAddress);
    PATH20.push(usdcAddress); PATH20.push(wethAddress);
    PATH21.push(usdcAddress); PATH21.push(wbtcAddress);

    IERC20(wbtcAddress).approve(address(router), MAX_INT);
    IERC20(usdcAddress).approve(address(router), MAX_INT);
  }

  // Receive
  receive() external payable {}

  // Public Functions
  function mint(address _to, bool _payByEth) external payable returns (bool) {
    uint256 tokenId = _allTokens.length + 1;
    require(!_exists(tokenId), "ERC721: token already minted");
    require(_to != address(0), "ERC721: mint to the zero address");

    if(_payByEth) {
      uint256[] memory amounts = router.swapETHForExactTokens{value: msg.value}(UNIT_PRICE, PATH02, address(this), block.timestamp + 20 minutes);
      payable(msg.sender).transfer(msg.value - amounts[0]);
    } else {
      IERC20(usdcAddress).transferFrom(msg.sender, address(this), UNIT_PRICE);
    }

    _beforeTokenTransfer(address(0), _to, tokenId);

    _balances[_to] += 1;
    _owners[tokenId] = _to;

    uint256 currentSlot = getCurrentSlot();
    tokenProperties[tokenId] = Property(currentSlot, false);
  
    for(uint256 i = 0; i < MATURITY_SLOTS; i++) {
      if(!slots[currentSlot + i].exist) {
        slots[currentSlot + i] = Slot(true, 0, 0, INVEST_PER_SLOT);
      } else {
        slots[currentSlot + i].usdcInvest = slots[currentSlot + i].usdcInvest.add(INVEST_PER_SLOT);
      }
    }

    emit Transfer(address(0), _to, tokenId);
    return true;
  }

  function buy(uint256 _slippage) external onlyOwner returns (bool) {
    uint256 slippage = _slippage > MAX_SLIPPAGE ? MAX_SLIPPAGE : _slippage;
    Slot storage slot = slots[getCurrentSlot()];

    uint256 wethInvest = slot.usdcInvest / 2;
    uint256 wethOutput = getOutput(usdcAddress, wethAddress, wethInvest);
    uint256 wethOutputMin = wethOutput.sub(wethOutput.mul(slippage) / 100000);
    uint256[] memory wethAmounts = router.swapExactTokensForETH(wethInvest, wethOutputMin, PATH20, address(this), block.timestamp + 20 minutes);
    slot.wethBalance = wethAmounts[wethAmounts.length - 1];

    uint256 wbtcInvest = slot.usdcInvest - wethInvest;
    uint256 wbtcOutput = getOutput(usdcAddress, wbtcAddress, wbtcInvest);
    uint256 wbtcOutputMin = wbtcOutput.sub(wbtcOutput.mul(slippage) / 100000);
    router.swapExactTokensForETH(wbtcInvest, wbtcOutputMin, PATH20, address(this), block.timestamp + 20 minutes);
    uint256[] memory wbtcAmounts = router.swapExactTokensForTokens(wbtcInvest, wbtcOutputMin, PATH21, address(this), block.timestamp + 20 minutes);
    slot.wbtcBalance = wbtcAmounts[wbtcAmounts.length - 1];

    return true;
  }

  function redeem(uint256 _tokenId) external returns (bool) {
    require(ownerOf(_tokenId) == msg.sender, "DHT: not your token");
    require(!tokenProperties[_tokenId].redeemed, "DHT: already redeemed");

    uint256 startSlot = tokenProperties[_tokenId].startSlot;
    require(getCurrentSlot() >= startSlot + MATURITY_SLOTS, "DHT: not matured");

    uint256 wethAmount; uint256 wbtcAmount;
    for(uint256 i = 0; i < MATURITY_SLOTS; i++) {
      Slot memory slot = slots[startSlot + i];
      wethAmount = wethAmount.add(slot.wethBalance / (slot.usdcInvest / INVEST_PER_SLOT));
      wbtcAmount = wbtcAmount.add(slot.wbtcBalance / (slot.usdcInvest / INVEST_PER_SLOT));
    }
    payable(msg.sender).transfer(wethAmount);
    IERC20(wbtcAddress).transfer(msg.sender, wbtcAmount);

    tokenProperties[_tokenId].redeemed = true;
    return true;
  }

  // View Functions (Public)
  function getCurrentSlot() public view returns (uint256) {
    return block.timestamp / INTERVAL;
  }

  function getAttributes(uint256 _tokenId) private view returns (string memory) {
    ( , , uint256 count, uint256 ethAsset, uint256 btcAsset, uint256 usdcAsset, , ) = getValue(_tokenId);

    return string(
        abi.encodePacked(
            '[',
            '{ "trait_type": "Maturity", "value": "', Base64.toString(count), '/', Base64.toString(MATURITY_SLOTS), ' months" }, ',
            '{ "trait_type": "ETH", "value": "', Base64.formatValue(ethAsset, 18, 'ETH'), '" }, ',
            '{ "trait_type": "BTC", "value": "', Base64.formatValue(btcAsset, 8, 'BTC'), '" }, ',
            '{ "trait_type": "USDC", "value": "', Base64.formatValue(usdcAsset, 6, 'USDC'), '" } ',
            ']'
        )
    );    
  }

  function tokenURI(uint256 _tokenId) public view returns (string memory) {
    string memory baseURL = "data:application/json;base64,";
    string memory json = string(
        abi.encodePacked(
            '{',
            '"name": "Diamond Hands #', toString(_tokenId), '", ',
            '"description": "HODL HODL HODL HODL", ',
            '"image":"https://raw.githubusercontent.com/yoshikazzz/test-asset/master/diamond-hands.png", ',
            '"attributes": ', getAttributes(_tokenId),
            '}'
        )
    );
    string memory jsonBase64Encoded = Base64.encode(bytes(json));
    return string(abi.encodePacked(baseURL, jsonBase64Encoded));
  }

  function estimateEthForUnitPrice() external view returns (uint256 ethAmount) {
    return getInput(wethAddress, usdcAddress, UNIT_PRICE);
  }

  function getValue(uint256 _tokenId) public view returns (uint256 startSlot, bool redeemed, uint256 count, uint256 ethAsset, uint256 btcAsset, uint256 usdcAsset, uint256 ethPrice, uint256 btcPrice) {
    Property memory tokenProperty = tokenProperties[_tokenId];
    startSlot = tokenProperty.startSlot;
    redeemed = tokenProperty.redeemed;
    for (uint256 i = 0; i < MATURITY_SLOTS; i++) {
      if(slots[startSlot + i].exist) {
        Slot memory slot = slots[startSlot + i];
        ethAsset = ethAsset.add(slot.wethBalance / (slot.usdcInvest / INVEST_PER_SLOT));
        btcAsset = btcAsset.add(slot.wbtcBalance / (slot.usdcInvest / INVEST_PER_SLOT));
      }
    }
    usdcAsset = MATURITY_SLOTS.sub(count).mul(INVEST_PER_SLOT);
    ethPrice = getEthPrice();
    btcPrice = getBtcPrice();
    count = (block.timestamp / INTERVAL) - startSlot;
  }

  function getConstants() external pure returns (
    uint256 unitPrice,
    uint256 investPerSlot,
    uint256 maturitySlots,
    uint256 interval,
    uint256 maxSlippage
  ) {
    unitPrice = UNIT_PRICE;
    investPerSlot = INVEST_PER_SLOT;
    maturitySlots = MATURITY_SLOTS;
    interval = INTERVAL;
    maxSlippage = MAX_SLIPPAGE;
  }

  // View Function (Private)
  function getOutput(address _tokenIn, address _tokenOut, uint256 _amount) private view returns (uint256 baseOutput) {
    IUniswapPair pair = IUniswapPair(factory.getPair(_tokenIn, _tokenOut));
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
    uint256 reserveIn = _tokenIn < _tokenOut ? uint256(reserve0) : uint256(reserve1);
    uint256 reserveOut = _tokenIn < _tokenOut ? uint256(reserve1) : uint256(reserve0);
    uint256 amountInWithFee = _amount.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    baseOutput = numerator / denominator;
  }

  function getInput(address _tokenIn, address _tokenOut, uint256 _amount) private view returns (uint amountIn) {
    IUniswapPair pair = IUniswapPair(factory.getPair(_tokenIn, _tokenOut));
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
    uint256 reserveIn = _tokenIn < _tokenOut ? uint256(reserve0) : uint256(reserve1);
    uint256 reserveOut = _tokenIn < _tokenOut ? uint256(reserve1) : uint256(reserve0);
    uint numerator = reserveIn.mul(_amount).mul(1000);
    uint denominator = reserveOut.sub(_amount).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  function getEthPrice() private view returns (uint256 ethPrice) {
    IUniswapPair pair = IUniswapPair(factory.getPair(wethAddress, usdcAddress));
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
    uint256 ethBalance = wethAddress < usdcAddress ? uint256(reserve0) : uint256(reserve1);
    uint256 usdcBalance = wethAddress < usdcAddress ? uint256(reserve1) : uint256(reserve0);
    ethPrice = usdcBalance.mul(1e18) / ethBalance;
  }

  function getBtcPrice() private view returns (uint256 btcPrice) {
    IUniswapPair pair = IUniswapPair(factory.getPair(wbtcAddress, usdcAddress));
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
    uint256 btcBalance = wbtcAddress < usdcAddress ? uint256(reserve0) : uint256(reserve1);
    uint256 usdcBalance = wbtcAddress < usdcAddress ? uint256(reserve1) : uint256(reserve0);
    btcPrice = usdcBalance.mul(1e8) / btcBalance;
  }

  function destruct() external onlyOwner {
    selfdestruct(payable(msg.sender));
  }
}
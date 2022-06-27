/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT

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

// Contract
contract DHT is Ownable, Mintable, ReentrancyGuard {
  using SafeMath for uint256;

  // ERC721
  mapping(uint256 => address) private _owners;
  mapping(address => uint256) private _balances;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  // ERC721Metadata
  string public name = 'Diamond Hand Token';
  string public symbol = 'DHT';

  // ERC721Enumerable
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
  mapping(uint256 => uint256) private _ownedTokensIndex;
  uint256[] private _allTokens;
  mapping(uint256 => uint256) private _allTokensIndex;

  // Customized
  uint256 private constant MAX_INT = 2**256 - 1;
  uint256 public constant UNIT_PRICE = 12000;
  uint256 public constant MONTHLY_BUY_IN = 1000;
  uint256 public constant MATURITY_PERIOD = UNIT_PRICE / MONTHLY_BUY_IN;
  uint256 public constant INTERVAL = 1 hours; // 30 days for production
  uint256 public constant MAX_SLIPPAGE = 5000;

  IUniswapFactory public factory;
  IUniswapRouter public router;

  address[] private PATH02;
  address[] private PATH20;
  address[] private PATH21;

  address wethAddress;
  address wbtcAddress;
  address usdcAddress;
  mapping(uint256 => Property) public tokenProperties;
  mapping(uint256 => Slot) public slots;

  struct Property {
    uint256 startMonth;
    bool redeemed;
  }

  struct Slot {
    bool exist;
    uint256 wethBalance;
    uint256 wbtcBalance;
    uint256 buyInAmount;
  }
    
  // Constructor
  constructor() {}

  // Receive
  receive() external payable {}

  // ERC165
  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return
      interfaceId == type(IERC165).interfaceId ||
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId;
  }

  // Customized (public)
  function init() external onlyOwner returns (bool) {
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    router = IUniswapRouter(_router);
    factory = IUniswapFactory(router.factory());

    wethAddress = router.WETH();
    wbtcAddress = 0x803424D248ed1Ac36bc2Bc0b574eBb781924112A; // WBTC
    usdcAddress = 0x30561FBd0671D3198441120FDa04d446A430e8af; // USDC

    PATH02.push(wethAddress); PATH02.push(usdcAddress);
    PATH20.push(usdcAddress); PATH20.push(wethAddress);
    PATH21.push(usdcAddress); PATH21.push(wbtcAddress);

    IERC20(wbtcAddress).approve(_router, MAX_INT);
    IERC20(usdcAddress).approve(_router, MAX_INT);

    return true;
  }

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

    uint256 currentSlot = block.timestamp / INTERVAL;
    tokenProperties[tokenId] = Property(currentSlot, false);
  
    for(uint256 i = 0; i < MATURITY_PERIOD; i++) {
      if(!slots[currentSlot + i].exist) {
        slots[currentSlot + i] = Slot(true, 0, 0, MONTHLY_BUY_IN);
      } else {
        slots[currentSlot + i].buyInAmount = slots[currentSlot + i].buyInAmount.add(MONTHLY_BUY_IN);
      }
    }

    emit Transfer(address(0), _to, tokenId);
    return true;
  }

  function buy(uint256 _slippage) external onlyOwner returns (bool) {
    uint256 slippage = _slippage > MAX_SLIPPAGE ? MAX_SLIPPAGE : _slippage;
    Slot storage slot = slots[block.timestamp / INTERVAL];

    uint256 wethBuyIn = slot.buyInAmount / 2;
    uint256 wethOutput = getOutput(usdcAddress, wethAddress, wethBuyIn);
    uint256 wethOutputMin = wethOutput.sub(wethOutput.mul(slippage) / 100000);
    uint256[] memory wethAmounts = router.swapExactTokensForETH(wethBuyIn, wethOutputMin, PATH20, address(this), block.timestamp + 20 minutes);
    slot.wethBalance = wethAmounts[wethAmounts.length - 1];

    uint256 wbtcBuyIn = slot.buyInAmount - wethBuyIn;
    uint256 wbtcOutput = getOutput(usdcAddress, wbtcAddress, wbtcBuyIn);
    uint256 wbtcOutputMin = wbtcOutput.sub(wbtcOutput.mul(slippage) / 100000);
    router.swapExactTokensForETH(wbtcBuyIn, wbtcOutputMin, PATH20, address(this), block.timestamp + 20 minutes);
    uint256[] memory wbtcAmounts = router.swapExactTokensForTokens(wbtcBuyIn, wbtcOutputMin, PATH21, address(this), block.timestamp + 20 minutes);
    slot.wbtcBalance = wbtcAmounts[wbtcAmounts.length - 1];

    return true;
  }

  function buyTestView0() external view returns (uint256, uint256) {
    Slot storage slot = slots[block.timestamp / INTERVAL];
    return (block.timestamp / INTERVAL, slot.buyInAmount);
  }

  function buyTestView1() external view returns (uint256) {
    Slot storage slot = slots[block.timestamp / INTERVAL];

    uint256 wethBuyIn = slot.buyInAmount / 2;

    return (wethBuyIn);
  }

  function buyTestView2(uint256 _slippage) external view returns (uint256, uint256, uint256) {
    uint256 slippage = _slippage > MAX_SLIPPAGE ? MAX_SLIPPAGE : _slippage;
    Slot storage slot = slots[block.timestamp / INTERVAL];

    uint256 wethBuyIn = slot.buyInAmount / 2;
    uint256 wethOutput = getOutput(usdcAddress, wethAddress, wethBuyIn);
    uint256 wethOutputMin = wethOutput.sub(wethOutput.mul(slippage) / 100000);

    return (wethBuyIn, wethOutput, wethOutputMin);
  }

  function buyTestView(uint256 _slippage) external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
    uint256 slippage = _slippage > MAX_SLIPPAGE ? MAX_SLIPPAGE : _slippage;
    Slot storage slot = slots[block.timestamp / INTERVAL];

    uint256 wethBuyIn = slot.buyInAmount / 2;
    uint256 wethOutput = getOutput(usdcAddress, wethAddress, wethBuyIn);
    uint256 wethOutputMin = wethOutput.sub(wethOutput.mul(slippage) / 100000);

    uint256 wbtcBuyIn = slot.buyInAmount - wethBuyIn;
    uint256 wbtcOutput = getOutput(usdcAddress, wbtcAddress, wbtcBuyIn);
    uint256 wbtcOutputMin = wbtcOutput.sub(wbtcOutput.mul(slippage) / 100000);

    return (wethBuyIn, wethOutput, wethOutputMin, wbtcBuyIn, wbtcOutput, wbtcOutputMin);
  }

  function buyTest1(uint256 _slippage) external onlyOwner returns (bool) {
    uint256 slippage = _slippage > MAX_SLIPPAGE ? MAX_SLIPPAGE : _slippage;
    Slot storage slot = slots[block.timestamp / INTERVAL];

    uint256 wethBuyIn = slot.buyInAmount / 2;
    uint256 wethOutput = getOutput(usdcAddress, wethAddress, wethBuyIn);
    uint256 wethOutputMin = wethOutput.sub(wethOutput.mul(slippage) / 100000);
    uint256[] memory wethAmounts = router.swapExactTokensForETH(wethBuyIn, wethOutputMin, PATH20, address(this), block.timestamp + 20 minutes);
    slot.wethBalance = wethAmounts[wethAmounts.length - 1];

    return true;
  }

  function buyTest2(uint256 _slippage) external onlyOwner returns (bool) {
    uint256 slippage = _slippage > MAX_SLIPPAGE ? MAX_SLIPPAGE : _slippage;
    Slot storage slot = slots[block.timestamp / INTERVAL];

    uint256 wbtcBuyIn = slot.buyInAmount / 2;
    uint256 wbtcOutput = getOutput(usdcAddress, wbtcAddress, wbtcBuyIn);
    uint256 wbtcOutputMin = wbtcOutput.sub(wbtcOutput.mul(slippage) / 100000);
    router.swapExactTokensForETH(wbtcBuyIn, wbtcOutputMin, PATH20, address(this), block.timestamp + 20 minutes);
    uint256[] memory wbtcAmounts = router.swapExactTokensForETH(wbtcBuyIn, wbtcOutputMin, PATH20, address(this), block.timestamp + 20 minutes);
    slot.wbtcBalance = wbtcAmounts[wbtcAmounts.length - 1];

    return true;
  }

  function redeem(uint256 _tokenId) external returns (bool) {
    require(ownerOf(_tokenId) == msg.sender, "DHT: not your token");
    require(!tokenProperties[_tokenId].redeemed, "DHT: already redeemed");

    uint256 startMonth = tokenProperties[_tokenId].startMonth;
    require(block.timestamp / INTERVAL >= startMonth + MATURITY_PERIOD, "DHT: not matured");

    uint256 wethAmount; uint256 wbtcAmount;
    for(uint256 i = 0; i < MATURITY_PERIOD; i++) {
      Slot memory slot = slots[startMonth + i];
      wethAmount = wethAmount.add(slot.wethBalance / (slot.buyInAmount / MONTHLY_BUY_IN));
      wbtcAmount = wbtcAmount.add(slot.wbtcBalance / (slot.buyInAmount / MONTHLY_BUY_IN));
    }
    payable(msg.sender).transfer(wethAmount);
    IERC20(wbtcAddress).transfer(msg.sender, wbtcAmount);

    tokenProperties[_tokenId].redeemed = true;
    return true;
  }

  function getOutput(address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256 baseOutput) {
    IUniswapPair pair = IUniswapPair(factory.getPair(_tokenIn, _tokenOut));
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
    uint256 reserveIn = _tokenIn < _tokenOut ? uint256(reserve0) : uint256(reserve1);
    uint256 reserveOut = _tokenIn < _tokenOut ? uint256(reserve1) : uint256(reserve0);
    uint256 amountInWithFee = _amount.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    baseOutput = numerator / denominator;
  }

  function getInput(address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint amountIn) {
    IUniswapPair pair = IUniswapPair(factory.getPair(_tokenIn, _tokenOut));
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
    uint256 reserveIn = _tokenIn < _tokenOut ? uint256(reserve0) : uint256(reserve1);
    uint256 reserveOut = _tokenIn < _tokenOut ? uint256(reserve1) : uint256(reserve0);
    uint numerator = reserveIn.mul(_amount).mul(1000);
    uint denominator = reserveOut.sub(_amount).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  function estimateEthForUnitPrice() public view returns (uint256 ethAmount) {
    return getInput(wethAddress, usdcAddress, UNIT_PRICE);
  }

  function getEthPrice() public view returns (uint256 ethPrice) {
    IUniswapPair pair = IUniswapPair(factory.getPair(wethAddress, usdcAddress));
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
    uint256 ethBalance = wethAddress < usdcAddress ? uint256(reserve0) : uint256(reserve1);
    uint256 usdcBalance = wethAddress < usdcAddress ? uint256(reserve1) : uint256(reserve0);
    ethPrice = usdcBalance.mul(1e18) / ethBalance;
  }

  function getBtcPrice() public view returns (uint256 btcPrice) {
    IUniswapPair pair = IUniswapPair(factory.getPair(wbtcAddress, usdcAddress));
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
    uint256 btcBalance = wbtcAddress < usdcAddress ? uint256(reserve0) : uint256(reserve1);
    uint256 usdcBalance = wbtcAddress < usdcAddress ? uint256(reserve1) : uint256(reserve0);
    btcPrice = usdcBalance.mul(1e8) / btcBalance;
  }

  function getValue(uint256 _tokenId) external view returns (uint256 startMonth, bool redeemed, uint256 count, uint256 ethAsset, uint256 btcAsset, uint256 usdcAsset, uint256 ethPrice, uint256 btcPrice) {
    Property memory tokenProperty = tokenProperties[_tokenId];
    startMonth = tokenProperty.startMonth;
    redeemed = tokenProperty.redeemed;
    for (uint256 i = 0; i < MATURITY_PERIOD; i++) {
      if(slots[startMonth + i].exist) {
        Slot memory slot = slots[startMonth + i];
        ethAsset = ethAsset.add(slot.wethBalance / (slot.buyInAmount / MONTHLY_BUY_IN));
        btcAsset = btcAsset.add(slot.wbtcBalance / (slot.buyInAmount / MONTHLY_BUY_IN));
        if(slot.wethBalance > 0 & slot.wbtcBalance) count = count + 1;
      }
    }
    usdcAsset = MATURITY_PERIOD.sub(count).mul(MONTHLY_BUY_IN);
    ethPrice = getEthPrice();
    btcPrice = getBtcPrice();
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

  // ERC721 (private)
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) private {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  function _exists(uint256 tokenId) private view returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) private view returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _transfer(address from, address to, uint256 tokenId) private {
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

  function _approve(address to, uint256 tokenId) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
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

  // ERC721Metadata
  function tokenURI(uint256 _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return 'https://raw.githubusercontent.com/yoshikazzz/test-asset/master/metadata.json';
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

  // Utils
  function isContract(address account) private view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function toString(uint256 value) private pure returns (string memory) {
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

  function destruct() external onlyOwner {
    selfdestruct(payable(msg.sender));
  }
}
/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: GNU
pragma solidity ^0.8.4;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

interface IUniswapFactory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

interface IUniswapRouter01 {
  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getamountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getamountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getamountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getamountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

abstract contract Ownable {
  address private _owner;
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    address msgSender = msg.sender;
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
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
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
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
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
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

  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
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

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping(bytes32 => uint256) _indexes;
  }

  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);

      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  function _remove(Set storage set, bytes32 value) private returns (bool) {
    uint256 valueIndex = set._indexes[value];
    if (valueIndex != 0) {
      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      bytes32 lastvalue = set._values[lastIndex];

      set._values[toDeleteIndex] = lastvalue;

      set._indexes[lastvalue] = valueIndex;

      set._values.pop();

      delete set._indexes[value];
      return true;
    } else {
      return false;
    }
  }

  function _contains(Set storage set, bytes32 value)
    private
    view
    returns (bool)
  {
    return set._indexes[value] != 0;
  }

  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
  }

  struct Bytes32Set {
    Set _inner;
  }

  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  function remove(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool)
  {
    return _remove(set._inner, value);
  }

  function contains(Bytes32Set storage set, bytes32 value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, value);
  }

  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(Bytes32Set storage set, uint256 index)
    internal
    view
    returns (bytes32)
  {
    return _at(set._inner, index);
  }

  struct AddressSet {
    Set _inner;
  }

  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(uint160(value))));
  }

  function remove(AddressSet storage set, address value)
    internal
    returns (bool)
  {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, bytes32(uint256(uint160(value))));
  }

  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(AddressSet storage set, uint256 index)
    internal
    view
    returns (address)
  {
    return address(uint160(uint256(_at(set._inner, index))));
  }

  struct UintSet {
    Set _inner;
  }

  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  function contains(UintSet storage set, uint256 value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, bytes32(value));
  }

  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(UintSet storage set, uint256 index)
    internal
    view
    returns (uint256)
  {
    return uint256(_at(set._inner, index));
  }
}

contract CHRGTEST is IERC20, Ownable {
  using Address for address;
  using EnumerableSet for EnumerableSet.AddressSet;
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => uint256) private _sellLock;

  // Exclusions
  mapping(address => bool) isBalanceFree;
  mapping(address => bool) isMarketMakerTaxFree;
  mapping(address => bool) isMarketingTaxFree;
  mapping(address => bool) isRewardTaxFree;
  mapping(address => bool) isAuthorized;
  mapping(address => bool) isWhitelisted;
  EnumerableSet.AddressSet private _excluded;
  EnumerableSet.AddressSet private _whiteList;
  EnumerableSet.AddressSet private _excludedFromSellLock;
  EnumerableSet.AddressSet private _excludedFromDistributing;
  mapping(address => bool) public _blacklist;
  mapping(address => bool) public canTrade;
  bool isBlacklist = true;
  string private constant _name = "Charge_Test";
  string private constant _symbol = "CHRGT";
  uint8 private constant _decimals = 9;
  uint256 public constant InitialSupply = 100 * 10**9 * 10**_decimals;
  uint8 public constant BalanceLimitDivider = 50;
  uint16 public constant SellLimitDivider = 100;
  uint16 public constant MaxSellLockTime = 10 seconds;
  uint256 private constant DefaultLiquidityLockTime = 1 hours;
  mapping(uint8 => mapping(address => bool)) public is_claimable;
  address public constant UniswapRouterAddy =
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public constant Dead = 0x000000000000000000000000000000000000dEaD;
  address public rewardWallet_one = 0xfa6a113F76035016B04766211395cBc2Fc84b09d;
  address public rewardWallet_two = 0xa5211EDd1EB5C771Ac972eC9D6799751E5422096;
  address public marketingWallet = 0xab05f292b730ef5347486d0080BFF6c9FD424740;
  address public marketMakerWallet = 0x7Ab32979418134F358b4FC199a58F1deA0CF0627;
  address public  uniswapV2Pair;
  bool blacklist_enabled = true;
  mapping(address => uint8) is_slot;
  uint256 private _circulatingSupply = InitialSupply;
  uint256 public balanceLimit = _circulatingSupply;
  uint256 public sellLimit = _circulatingSupply;
  uint256 public qtyTokenToSwap = (sellLimit * 10) / 100;
  uint256 public swapTreshold = qtyTokenToSwap;
  bool manualTokenToSwap = false;
  uint256 manualQtyTokenToSwap = (sellLimit * 10) / 100;
  bool sellAll = false;
  bool sellPeg = true;
  bool botKiller = true;
  uint8 public constant MaxTax = 45;
  uint8 private _buyTax;
  uint8 private _sellTax;
  uint8 private _transferTax;
  uint8 private _marketMakerTax;
  uint8 private _liquidityTax;
  uint8 private _distributingTax;
  uint8 private _marketingTax;
  uint8 private _stakeTax_one;
  uint8 private _stakeTax_two;

  bool isUntaxed;
  uint untaxedFee;

  mapping(address => bool) public _isControl;

  address private _UniswapPairAddress;
  IUniswapRouter02 private _UniswapRouter;
  modifier onlyTeam() {
    require(
      _isControl[msg.sender] || owner() == msg.sender,
      "Caller not in Control"
    );
    _;
  }

  constructor() {
    uint256 deployerBalance = _circulatingSupply;
    _balances[msg.sender] = deployerBalance;
    emit Transfer(address(0), msg.sender, deployerBalance);

    _UniswapRouter = IUniswapRouter02(UniswapRouterAddy);

    _UniswapPairAddress = IUniswapFactory(_UniswapRouter.factory()).createPair(
      address(this),
      _UniswapRouter.WETH()
    );
    _excludedFromSellLock.add(rewardWallet_one);
    _excludedFromSellLock.add(rewardWallet_two);
    _excludedFromSellLock.add(marketingWallet);
    _excludedFromSellLock.add(marketMakerWallet);
    _excludedFromDistributing.add(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    balanceLimit = InitialSupply / BalanceLimitDivider;
    sellLimit = InitialSupply / SellLimitDivider;

    sellLockTime = 2 seconds;

    _buyTax = 0;
    _sellTax = 25;
    _transferTax = 25;

    _liquidityTax = 10;
    _marketingTax = 30;
    _marketMakerTax = 10;
    _stakeTax_one = 17;
    _stakeTax_two = 33;

    _excluded.add(msg.sender);

    _excludedFromDistributing.add(address(_UniswapRouter));
    _excludedFromDistributing.add(_UniswapPairAddress);
    _excludedFromDistributing.add(address(this));
    _excludedFromDistributing.add(0x000000000000000000000000000000000000dEaD);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    require(sender != address(0), "Transfer from zero");
    require(recipient != address(0), "Transfer to zero");
    if (isBlacklist) {
      require(!_blacklist[sender]);
    }

    bool isExcluded = (_excluded.contains(sender) ||
      _excluded.contains(recipient));

    bool isContractTransfer = (sender == address(this) ||
      recipient == address(this));

    address UniswapRouter = address(_UniswapRouter);
    bool isLiquidityTransfer = ((sender == _UniswapPairAddress &&
      recipient == UniswapRouter) ||
      (recipient == _UniswapPairAddress && sender == UniswapRouter));

    bool isBuy = sender == _UniswapPairAddress || sender == UniswapRouter;
    bool isSell = recipient == _UniswapPairAddress ||
      recipient == UniswapRouter;


    if (
      isContractTransfer ||
      isLiquidityTransfer ||
      isExcluded ||
      isWhitelisted[sender]
    ) {
      _feelessTransfer(sender, recipient, amount, is_slot[sender]);
    } else if (isUntaxed) {
      _untaxedTransfer(sender, recipient, amount, is_slot[sender]);
      } else {
      if (!tradingEnabled && botKiller && !canTrade[sender]) {
        emit Transfer(sender, recipient, 0);
        return;
      }
      _taxedTransfer(sender, recipient, amount, isBuy, isSell);
    }
  }

  function _untaxedTransfer(
    address sender,
    address recipient,
    uint256 amount,
    uint8 slot
  )  private {
    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "Transfer exceeds balance");

    uint to_sell = (amount * untaxedFee) / 100;
    require(_balances[address(this)] >= to_sell, "not enough tokens");
    _swapContractToken(to_sell, slot);

    _removeToken(sender, amount, slot);

    _addToken(recipient, amount, slot);

    emit Transfer(sender, recipient, amount);
  }

  function _taxedTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool isBuy,
    bool isSell
  ) private {
    uint8 slot = is_slot[sender];
    uint256 recipientBalance = _balances[recipient];
    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "Transfer exceeds balance");
    uint8 tax;
    if (isSell) {
      if (!_excludedFromSellLock.contains(sender)) {
        require(
          _sellLock[sender] <= block.timestamp || sellLockDisabled,
          "Seller in sellLock"
        );

        _sellLock[sender] = block.timestamp + sellLockTime;
      }

      require(amount <= sellLimit, "Dump protection");
      tax = _sellTax;
    } else if (isBuy) {
      if (!isBalanceFree[recipient]) {
        require(recipientBalance + amount <= balanceLimit, "whale protection");
      }
      tax = _buyTax;
    } else {
      if (!isBalanceFree[recipient]) {
        require(recipientBalance + amount <= balanceLimit, "whale protection");
      }
      require(recipientBalance + amount <= balanceLimit, "whale protection");

      if (!_excludedFromSellLock.contains(sender))
        require(
          _sellLock[sender] <= block.timestamp || sellLockDisabled,
          "Sender in Lock"
        );
      tax = _transferTax;
    }

    if (
      (sender != _UniswapPairAddress) &&
      (!manualConversion) &&
      (!_isSwappingContractModifier) &&
      isSell
    ) {
      if (_balances[address(this)] >= swapTreshold) {
        _swapContractToken(amount, slot);
      }
    }
    uint8 actualmarketMakerTax = 0;
    uint8 actualMarketingTax = 0;
    if (!isMarketingTaxFree[sender]) {
      actualMarketingTax = _marketingTax;
    }
    if (!isMarketMakerTaxFree[sender]) {
      actualmarketMakerTax = _marketMakerTax;
    }
    uint8 stakeTax;
    if (slot == 0) {
      stakeTax = _stakeTax_one;
    } else if (slot == 1) {
      stakeTax = _stakeTax_two;
    }

    uint256 contractToken = _calculateFee(
      amount,
      tax,
      _distributingTax +
        _liquidityTax +
        actualMarketingTax +
        actualmarketMakerTax +
        stakeTax
    );

    uint256 taxedAmount = amount - (contractToken);

    _removeToken(sender, amount, slot);

    _balances[address(this)] += contractToken;

    _addToken(recipient, taxedAmount, slot);

    emit Transfer(sender, recipient, taxedAmount);
  }

  function _feelessTransfer(
    address sender,
    address recipient,
    uint256 amount,
    uint8 slot
  ) private {
    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "Transfer exceeds balance");

    _removeToken(sender, amount, slot);

    _addToken(recipient, amount, slot);

    emit Transfer(sender, recipient, amount);
  }

  function _calculateFee(
    uint256 amount,
    uint8 tax,
    uint8 taxPercent
  ) private pure returns (uint256) {
    return (amount * tax * taxPercent) / 10000;
  }

  bool private _isWithdrawing;
  uint256 private constant DistributionMultiplier = 2**64;
  mapping(uint8 => uint256) public profitPerShare;
  uint256 public totalDistributingReward;
  uint256 public totalPayouts;
  uint256 public marketingBalance;
  uint256 public marketMakerBalance;
  mapping(uint8 => uint256) rewardBalance;
  mapping(address => mapping(uint256 => uint256)) private alreadyPaidShares;
  mapping(address => uint256) private toERCaid;

  function isExcludedFromDistributing(address addr) public view returns (bool) {
    return _excludedFromDistributing.contains(addr);
  }

  function _getTotalShares() public view returns (uint256) {
    uint256 shares = _circulatingSupply;

    for (uint256 i = 0; i < _excludedFromDistributing.length(); i++) {
      shares -= _balances[_excludedFromDistributing.at(i)];
    }
    return shares;
  }

  function _addToken(
    address addr,
    uint256 amount,
    uint8 slot
  ) private {
    uint256 newAmount = _balances[addr] + amount;

    if (isExcludedFromDistributing(addr)) {
      _balances[addr] = newAmount;
      return;
    }

    uint256 payment = _newDividentsOf(addr, slot);

    alreadyPaidShares[addr][slot] = profitPerShare[slot] * newAmount;

    toERCaid[addr] += payment;

    _balances[addr] = newAmount;
  }

  function _removeToken(
    address addr,
    uint256 amount,
    uint8 slot
  ) private {
    uint256 newAmount = _balances[addr] - amount;

    if (isExcludedFromDistributing(addr)) {
      _balances[addr] = newAmount;
      return;
    }

    uint256 payment = _newDividentsOf(addr, slot);

    _balances[addr] = newAmount;

    alreadyPaidShares[addr][slot] = profitPerShare[slot] * newAmount;

    toERCaid[addr] += payment;
  }

  function _newDividentsOf(address staker, uint8 slot)
    private
    view
    returns (uint256)
  {
    uint256 fullPayout = profitPerShare[slot] * _balances[staker];

    if (fullPayout < alreadyPaidShares[staker][slot]) return 0;
    return
      (fullPayout - alreadyPaidShares[staker][slot]) / DistributionMultiplier;
  }

  function _distributeStake(uint256 ETHamount, uint8 slot) private {
    uint256 marketingSplit = (ETHamount * _marketingTax) / 100;
    uint256 marketMakerSplit = (ETHamount * _marketMakerTax) / 100;
    uint256 stakeTax;
    if (slot == 0) {
      stakeTax = _stakeTax_one;
    } else if (slot == 1) {
      stakeTax = _stakeTax_two;
    }
    uint256 amount = (ETHamount * stakeTax) / 100;
    marketingBalance += marketingSplit;
    marketMakerBalance += marketMakerSplit;

    if (amount > 0) {
      totalDistributingReward += amount;
      uint256 totalShares = _getTotalShares();

      if (totalShares == 0) {
        marketingBalance += amount;
      } else {
        profitPerShare[slot] += ((amount * DistributionMultiplier) /
          totalShares);
        rewardBalance[slot] += amount;
      }
    }
  }

  event OnWithdrawFarmedToken(uint256 amount, address recipient);

  ///@dev Claim tokens correspondant to a slot, if enabled
  function claimFarmedToken(
    address addr,
    address tkn,
    uint8 slot
  ) private {
    if (slot == 1) {
      require(isAuthorized[addr], "You cant retrieve it");
    }
    require(!_isWithdrawing);
    require(is_claimable[slot][addr], "Not enabled");
    _isWithdrawing = true;
    uint256 amount;
    if (isExcludedFromDistributing(addr)) {
      amount = toERCaid[addr];
      toERCaid[addr] = 0;
    } else {
      uint256 newAmount = _newDividentsOf(addr, slot);

      alreadyPaidShares[addr][slot] = profitPerShare[slot] * _balances[addr];

      amount = toERCaid[addr] + newAmount;
      toERCaid[addr] = 0;
    }
    if (amount == 0) {
      _isWithdrawing = false;
      return;
    }
    totalPayouts += amount;
    address[] memory path = new address[](2);
    path[0] = _UniswapRouter.WETH();
    path[1] = tkn;
    _UniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
      value: amount
    }(0, path, addr, block.timestamp);

    emit OnWithdrawFarmedToken(amount, addr);
    _isWithdrawing = false;
  }

  uint256 public totalLPETH;
  bool private _isSwappingContractModifier;
  modifier lockTheSwap() {
    _isSwappingContractModifier = true;
    _;
    _isSwappingContractModifier = false;
  }

  function _swapContractToken(uint256 sellAmount, uint8 slot)
    private
    lockTheSwap
  {
    uint256 contractBalance = _balances[address(this)];
    uint16 totalTax = _liquidityTax + _distributingTax;

    uint256 tokenToSwap = (sellLimit * 10) / 100;
    if (manualTokenToSwap) {
      tokenToSwap = manualQtyTokenToSwap;
    }

    bool prevSellPeg = sellPeg;
    if (sellPeg) {
      if (tokenToSwap > sellAmount) {
        tokenToSwap = sellAmount / 2;
      }
    }
    sellPeg = prevSellPeg;

    if (sellAll) {
      tokenToSwap = contractBalance - 1;
    }

    if (contractBalance < tokenToSwap || totalTax == 0) {
      return;
    }

    uint256 tokenForLiquidity = (tokenToSwap * _liquidityTax) / totalTax;
    uint256 tokenForMarketing = (tokenToSwap * _marketingTax) / totalTax;
    uint256 tokenForMarketMaker = (tokenToSwap * _marketMakerTax) / totalTax;
    uint256 swapToken = tokenForLiquidity +
      tokenForMarketing +
      tokenForMarketMaker;
    // Avoid solidity imprecisions
    if (swapToken >= tokenToSwap) {
      tokenForMarketMaker -= (tokenToSwap - (swapToken));
    }

    uint256 liqToken = tokenForLiquidity / 2;
    uint256 liqETHToken = tokenForLiquidity - liqToken;

    swapToken = liqETHToken + tokenForMarketing + tokenForMarketMaker;

    uint256 initialETHBalance = address(this).balance;
    _swapTokenForETH(swapToken);
    uint256 newETH = (address(this).balance - initialETHBalance);

    uint256 liqETH = (newETH * liqETHToken) / swapToken;
    _addLiquidity(liqToken, liqETH);

    _distributeStake(address(this).balance - initialETHBalance, slot);
  }

  function _swapTokenForETH(uint256 amount) private {
    _approve(address(this), address(_UniswapRouter), amount);
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _UniswapRouter.WETH();
    _UniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
      amount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  function _addLiquidity(uint256 tokenamount, uint256 ETHamount) private {
    totalLPETH += ETHamount;
    _approve(address(this), address(_UniswapRouter), tokenamount);
    _UniswapRouter.addLiquidityETH{value: ETHamount}(
      address(this),
      tokenamount,
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  function getLimits() public view returns (uint256 balance, uint256 sell) {
    return (balanceLimit / 10**_decimals, sellLimit / 10**_decimals);
  }

  function getTaxes()
    public
    view
    returns (
      uint256 marketingTax,
      uint256 marketMakerTax,
      uint256 liquidityTax,
      uint256 distributingTax,
      uint256 buyTax,
      uint256 sellTax,
      uint256 transferTax
    )
  {
    return (
      _marketingTax,
      _marketMakerTax,
      _liquidityTax,
      _distributingTax,
      _buyTax,
      _sellTax,
      _transferTax
    );
  }

  function getWhitelistedStatus(address AddressToCheck)
    public
    view
    returns (bool)
  {
    return _whiteList.contains(AddressToCheck);
  }

  function getAddressSellLockTimeInSeconds(address AddressToCheck)
    public
    view
    returns (uint256)
  {
    uint256 lockTime = _sellLock[AddressToCheck];
    if (lockTime <= block.timestamp) {
      return 0;
    }
    return lockTime - block.timestamp;
  }

  function getSellLockTimeInSeconds() public view returns (uint256) {
    return sellLockTime;
  }

  ///@dev Reset cooldown for an address
  function AddressResetSellLock() public {
    _sellLock[msg.sender] = block.timestamp + sellLockTime;
  }

  ///@dev Retrieve slot 1
  function FarmedTokenWithdrawSlotOne(address tkn) public {
    claimFarmedToken(msg.sender, tkn, 0);
  }

  
  ///@dev Retrieve slot 2
  function FarmedTokenWithdrawSlotTwo(address tkn) public {
    claimFarmedToken(msg.sender, tkn, 1);
  }

  function getDividends(address addr, uint8 slot)
    public
    view
    returns (uint256)
  {
    if (isExcludedFromDistributing(addr)) return toERCaid[addr];
    return _newDividentsOf(addr, slot) + toERCaid[addr];
  }

  bool public sellLockDisabled;
  uint256 public sellLockTime;
  bool public manualConversion;
 
  ///@dev Airdrop tokens
  function airdropAddresses(
    address[] memory addys,
    address token,
    uint256 qty
  ) public onlyTeam {
    uint256 single_drop = qty / addys.length;
    IERC20 airtoken = IERC20(token);
    bool sent;
    for (uint256 i; i <= (addys.length - 1); i++) {
      sent = airtoken.transfer(addys[i], single_drop);
      require(sent);
      sent = false;
    }
  }

  ///@dev Airdrop a N of addresses
  function airdropAddressesNative(address[] memory addys)
    public
    payable
    onlyTeam
  {
    uint256 qty = msg.value;
    uint256 single_drop = qty / addys.length;
    bool sent;
    for (uint256 i; i <= (addys.length - 1); i++) {
      sent = payable(addys[i]).send(single_drop);
      require(sent);
      sent = false;
    }
  }

  ///@dev Enable pools for a token
  function ControlEnabledClaims(
    uint8 slot,
    address tkn,
    bool booly
  ) public onlyTeam {
    is_claimable[slot][tkn] = booly;
  }

  ///@dev Rekt all the snipers
  function ControlBotKiller(bool booly) public onlyTeam {
    botKiller = booly;
  }

  ///@dev Minimum tokens to sell
  function ControlSetSwapTreshold(uint256 treshold) public onlyTeam {
    swapTreshold = treshold * 10**_decimals;
  }

  ///@dev Exclude from distribution
  function ControlExcludeFromDistributing(address addr, uint8 slot)
    public
    onlyTeam
  {
    require(_excludedFromDistributing.length() < 30);
    require(!isExcludedFromDistributing(addr));
    uint256 newDividents = _newDividentsOf(addr, slot);
    alreadyPaidShares[addr][slot] = _balances[addr] * profitPerShare[slot];
    toERCaid[addr] += newDividents;
    _excludedFromDistributing.add(addr);
  }

  ///@dev Include into distribution
  function ControlIncludeToDistributing(address addr, uint8 slot)
    public
    onlyTeam
  {
    require(isExcludedFromDistributing(addr));
    _excludedFromDistributing.remove(addr);

    alreadyPaidShares[addr][slot] = _balances[addr] * profitPerShare[slot];
  }

  ///@dev Take out the marketing balance
  function ControlWithdrawMarketingETH() public onlyTeam {
    uint256 amount = marketingBalance;
    marketingBalance = 0;
    (bool sent, ) = marketingWallet.call{value: (amount)}("");
    require(sent, "withdraw failed");
  }

  ///@dev Peg sells to the tx
  function ControlSwapSetSellPeg(bool setter) public onlyTeam {
    sellPeg = setter;
  }

  ///@dev Set marketing tax free or not
  function ControlSetMarketingTaxFree(address addy, bool booly)
    public
    onlyTeam
  {
    isMarketingTaxFree[addy] = booly;
  }

  ///@dev Set an address into or out marketmaker fee
  function ControlSetMarketMakerTaxFree(address addy, bool booly)
    public
    onlyTeam
  {
    isMarketMakerTaxFree[addy] = booly;
  }

  ///@dev Disable tax reward for address
  function ControlSetRewardTaxFree(address addy, bool booly) public onlyTeam {
    isRewardTaxFree[addy] = booly;
  }

  ///@dev Disable address balance limit
  function ControlSetBalanceFree(address addy, bool booly) public onlyTeam {
    isBalanceFree[addy] = booly;
  }

  ///@dev Enable or disable manual sell
  function ControlSwapSetManualLiqSell(bool setter) public onlyTeam {
    manualTokenToSwap = setter;
  }

  ///@dev Turn sells into manual
  function ControlSwapSetManualLiqSellTokens(uint256 amount) public onlyTeam {
    require(amount > 1 && amount < 100000000, "Values between 1 and 100000000");
    manualQtyTokenToSwap = amount * 10**_decimals;
  }

  ///@dev Disable auto sells
  function ControlSwapSwitchManualETHConversion(bool manual) public onlyTeam {
    manualConversion = manual;
  }

  ///@dev Set cooldown on or off (ONCE)
  function ControlDisableSellLock(bool disabled) public onlyTeam {
    sellLockDisabled = disabled;
  }

  ///@dev Set cooldown
  function ControlSetSellLockTime(uint256 sellLockSeconds) public onlyTeam {
    require(sellLockSeconds <= MaxSellLockTime, "Sell Lock time too high");
    sellLockTime = sellLockSeconds;
  }

  ///@dev Set taxes
  function ControlSetTaxes(
    uint8 marketingTaxes,
    uint8 marketMakerTaxes,
    uint8 liquidityTaxes,
    uint8 buyTax,
    uint8 sellTax,
    uint8 transferTax,
    uint8 stakeTaxes_one,
    uint8 stakeTaxes_two
  ) public onlyTeam {
    uint8 totalTax = _marketingTax +
      _marketMakerTax +
      liquidityTaxes +
      stakeTaxes_one +
      stakeTaxes_two;
    require(totalTax == 100, "total taxes needs to equal 100%");
    require(
      buyTax <= MaxTax && sellTax <= MaxTax && transferTax <= MaxTax,
      "taxes higher than max tax"
    );
    require(marketingTaxes <= 45, "Max 45%");
    require(marketMakerTaxes <= 45, "Max 45%");
    require(stakeTaxes_one <= 45, "Max 45%");
    require(stakeTaxes_two <= 45, "Max 45%");

    _marketingTax = marketingTaxes;
    _marketMakerTax = marketMakerTaxes;
    _liquidityTax = liquidityTaxes;
    _stakeTax_one = stakeTaxes_one;
    _stakeTax_two = stakeTaxes_two;

    _buyTax = buyTax;
    _sellTax = sellTax;
    _transferTax = transferTax;
  }

  ///@dev Manually sell and create LP
  function ControlCreateLPandETH() public onlyTeam {
    _swapContractToken(192919291929192919291929192919291929, 0);
  }

  ///@dev Manually sell all tokens gathered
  function ControlSellAllTokens() public onlyTeam {
    sellAll = true;
    _swapContractToken(192919291929192919291929192919291929, 0);
    sellAll = false;
  }

  ///@dev Free from fees
  function ControlExcludeAccountFromFees(address account) public onlyTeam {
    _excluded.add(account);
  }

  ///@dev Include in fees
  function ControlIncludeAccountToFees(address account) public onlyTeam {
    _excluded.remove(account);
  }

  ///@dev Exclude from cooldown
  function ControlExcludeAccountFromSellLock(address account) public onlyTeam {
    _excludedFromSellLock.add(account);
  }

  ///@dev Enable cooldown
  function ControlIncludeAccountToSellLock(address account) public onlyTeam {
    _excludedFromSellLock.remove(account);
  }

  ///@dev Enable or disable pool 2 for an address
  function ControlIncludeAccountToSubset(address account, bool booly)
    public
    onlyTeam
  {
    isAuthorized[account] = booly;
  }

  ///@dev Control all the tx, buy and sell limits
  function ControlUpdateLimits(uint256 newBalanceLimit, uint256 newSellLimit)
    public
    onlyTeam
  {
    newBalanceLimit = newBalanceLimit * 10**_decimals;
    newSellLimit = newSellLimit * 10**_decimals;

    uint256 targetBalanceLimit = _circulatingSupply / BalanceLimitDivider;
    uint256 targetSellLimit = _circulatingSupply / SellLimitDivider;
    require(
      (newBalanceLimit >= targetBalanceLimit),
      "newBalanceLimit needs to be at least target"
    );
    require(
      (newSellLimit >= targetSellLimit),
      "newSellLimit needs to be at least target"
    );
    balanceLimit = newBalanceLimit;
    sellLimit = newSellLimit;
  }

  bool public tradingEnabled;
  address private _liquidityTokenAddress;

  ///@dev Start/stop trading
  function SetupEnableTrading(bool booly) public onlyTeam {
    tradingEnabled = booly;
  }

  ///@dev Define a new liquidity pair
  function SetupLiquidityTokenAddress(address liquidityTokenAddress)
    public
    onlyTeam
  {
    _liquidityTokenAddress = liquidityTokenAddress;
  }

  ///@dev Add to WL
  function SetupAddToWhitelist(address addressToAdd) public onlyTeam {
    _whiteList.add(addressToAdd);
  }

  ///@dev Add multiple addresses in WL
  function SetupAddArrayToWhitelist(address[] memory addressesToAdd)
    public
    onlyTeam
  {
    for (uint256 i = 0; i < addressesToAdd.length; i++) {
      _whiteList.add(addressesToAdd[i]);
    }
  }

  ///@dev Remove from whitelist
  function SetupRemoveFromWhitelist(address addressToRemove) public onlyTeam {
    _whiteList.remove(addressToRemove);
  }

  ///@dev Take back tokens stuck into the contract
  function rescueTokens(address tknAddress) public onlyTeam {
    IERC20 token = IERC20(tknAddress);
    uint256 ourBalance = token.balanceOf(address(this));
    require(ourBalance > 0, "No tokens in our balance");
    token.transfer(msg.sender, ourBalance);
  }

  ///@dev Disable PERMANENTLY blacklist functions
  function disableBlacklist() public onlyTeam {
    isBlacklist = false;
  }

  ///@dev Blacklist someone
  function setBlacklistedAddress(address toBlacklist) public onlyTeam {
    _blacklist[toBlacklist] = true;
  }

  ///@dev Remove from blacklist
  function removeBlacklistedAddress(address toRemove) public onlyTeam {
    _blacklist[toRemove] = false;
  }

  ///@dev Block or unblock an address
  function setCanTrade(address addy, bool booly) public onlyTeam {
    canTrade[addy] = booly;
  }

  ///@dev Remove the balance remaining in the contract
  function ControlRemoveRemainingETH() public onlyTeam {
    (bool sent, ) = owner().call{value: (address(this).balance)}("");
    require(sent);
  }

  receive() external payable {}

  fallback() external payable {}

  function getOwner() external view override returns (address) {
    return owner();
  }

  function name() external pure override returns (string memory) {
    return _name;
  }

  function symbol() external pure override returns (string memory) {
    return _symbol;
  }

  function decimals() external pure override returns (uint8) {
    return _decimals;
  }

  function totalSupply() external view override returns (uint256) {
    return _circulatingSupply;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount)
    external
    override
    returns (bool)
  {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address _owner, address spender)
    external
    view
    override
    returns (uint256)
  {
    return _allowances[_owner][spender];
  }

  function approve(address spender, uint256 amount)
    external
    override
    returns (bool)
  {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "Approve from zero");
    require(spender != address(0), "Approve to zero");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    _transfer(sender, recipient, amount);
    uint256 currentAllowance = _allowances[sender][msg.sender];
    require(currentAllowance >= amount, "Transfer > allowance");
    _approve(sender, msg.sender, currentAllowance - amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    external
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _allowances[msg.sender][spender] + addedValue
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    returns (bool)
  {
    uint256 currentAllowance = _allowances[msg.sender][spender];
    require(currentAllowance >= subtractedValue, "<0 allowance");
    _approve(msg.sender, spender, currentAllowance - subtractedValue);
    return true;
  }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import "./IndexPoolToken.sol";

contract RestrictedIndexPool is IndexPoolToken {
  function _pushUnderlying(
    address erc20,
    address to,
    uint256 amount
  ) internal {
    (bool success, bytes memory data) =
      erc20.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "ERR_ERC20_FALSE"
    );
  }

  function _redeemTokensTo(
    address src,
    address dst,
    uint256 poolAmountIn
  ) internal returns (uint256[] memory tokenAmountsOut) {
    uint256 len = _tokens.length;
    tokenAmountsOut = new uint256[](len);
    uint256 poolTotal = totalSupply;
    uint256 ratio = bdiv(poolAmountIn, poolTotal);
    _burn(src, poolAmountIn);

    for (uint256 i = 0; i < len; i++) {
      address t = _tokens[i];
      uint256 bal = IERC20(t).balanceOf(address(this));
      if (bal > 0) {
        uint256 tokenAmountOut = bmul(ratio, bal);
        _pushUnderlying(t, dst, tokenAmountOut);
        emit LOG_EXIT(src, t, tokenAmountOut);
        tokenAmountsOut[i] = tokenAmountOut;
      } else {
        tokenAmountsOut[i] = 0;
      }
    }
  }

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
    external
    override
    _lock_
    _initialized_
  {
    uint256 len = minAmountsOut.length;
    uint256[] memory tokenAmountsOut =
      _redeemTokensTo(msg.sender, msg.sender, poolAmountIn);
    require(len == tokenAmountsOut.length, "ERR_ARR_LEN");
    for (uint256 i = 0; i < len; i++) {
      require(tokenAmountsOut[i] >= minAmountsOut[i], "ERR_LIMIT_OUT");
    }
  }

  function exitPoolTo(address to, uint256 poolAmountIn)
    external
    override
    _lock_
    _initialized_
  {
    _redeemTokensTo(msg.sender, to, poolAmountIn);
  }

  function redeemAll() external override _lock_ _initialized_ {
    _redeemTokensTo(msg.sender, msg.sender, balanceOf[msg.sender]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import "./IndexPoolMath.sol";

abstract contract IndexPoolToken is IndexPoolMath {
  function _move(
    address src,
    address dst,
    uint256 amt
  ) internal {
    require(src != pair && dst != pair, "ERR_UNI_TRANSFER");
    require(balanceOf[src] >= amt, "ERR_INSUFFICIENT_BAL");
    balanceOf[src] = bsub(balanceOf[src], amt);
    balanceOf[dst] = badd(balanceOf[dst], amt);
    emit Transfer(src, dst, amt);
  }

  function _burn(address src, uint256 amount) internal {
    require(amount > 0, "ERR_NULL_AMOUNT");
    require(balanceOf[src] >= amount, "ERR_INSUFFICIENT_BAL");
    balanceOf[src] = bsub(balanceOf[src], amount);
    totalSupply = bsub(totalSupply, amount);
    emit Transfer(src, address(0), amount);
  }

  function approve(address dst, uint256 amt) external override returns (bool) {
    allowance[msg.sender][dst] = amt;
    emit Approval(msg.sender, dst, amt);
    return true;
  }

  function transfer(address dst, uint256 amt)
    external
    override
    _initialized_
    returns (bool)
  {
    _move(msg.sender, dst, amt);
    return true;
  }

  function transferFrom(
    address src,
    address dst,
    uint256 amt
  ) external override _initialized_ returns (bool) {
    require(
      msg.sender == src || amt <= allowance[src][msg.sender],
      "ERR_BTOKEN_BAD_CALLER"
    );
    _move(src, dst, amt);
    if (msg.sender != src && allowance[src][msg.sender] != type(uint256).max) {
      allowance[src][msg.sender] = bsub(allowance[src][msg.sender], amt);
      emit Approval(src, msg.sender, allowance[src][msg.sender]);
    }
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import "./IndexPoolBase.sol";

abstract contract IndexPoolMath is IndexPoolBase {
  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "ERR_ADD_OVERFLOW");
    return c;
  }

  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "ERR_SUB_UNDERFLOW");
    return c;
  }

  function bsubSign(uint256 a, uint256 b)
    internal
    pure
    returns (uint256, bool)
  {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "ERR_MUL_OVERFLOW");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "ERR_DIV_ZERO");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL");
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "ERR_DIV_INTERNAL");
    uint256 c2 = c1 / b;
    return c2;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

import "./interfaces/IRestrictedIndexPool.sol";

abstract contract IndexPoolBase is IRestrictedIndexPool {
  uint256 internal constant BONE = 10**18;
  uint8 public constant override decimals = 18;

  /* Storage */

  mapping(address => uint256) public override balanceOf;

  mapping(address => mapping(address => uint256)) public override allowance;

  uint256 public override totalSupply;

  string public override name;

  string public override symbol;

  bool internal _mutex;

  address public override getController;

  address internal _unbindHandler;

  bool public override isPublicSwap;

  uint256 public override getSwapFee;

  address[] internal _tokens;

  mapping(address => Record) internal _records;

  uint256 public override getTotalDenormalizedWeight;

  mapping(address => uint256) internal _minimumBalances;

  address public override getExitFeeRecipient;

  address public pair;

  /* View function constants */

  uint256 public constant override getExitFee = 0;

  modifier _lock_ {
    require(!_mutex, "ERR_REENTRY");
    _mutex = true;
    _;
    _mutex = false;
  }

  modifier _initialized_ {
    require(pair != address(0), "ERR_NOT_INITIALIZED");
    _;
  }

  function initialize(address _uniBurn, address _pair) external override {
    require(pair == address(0), "ERR_INITIALIZED");
    address[] memory tokens = _tokens;
    for (uint256 i; i < tokens.length; i++) {
      address token = tokens[i];
      require(
        IERC20(token).balanceOf(address(this)) >= _records[token].balance,
        "Balances not reinstated"
      );
    }
    balanceOf[_uniBurn] = balanceOf[_pair];
    balanceOf[_pair] = 0;
    pair = _pair;
  }

  function isBound(address t) external view override returns (bool) {
    return _records[t].bound;
  }

  function getNumTokens() external view override returns (uint256) {
    return _tokens.length;
  }

  function getCurrentTokens()
    external
    view
    override
    returns (address[] memory tokens)
  {
    tokens = _tokens;
  }

  function getCurrentDesiredTokens()
    external
    view
    override
    returns (address[] memory tokens)
  {
    address[] memory tempTokens = _tokens;
    tokens = new address[](tempTokens.length);
    uint256 usedIndex = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tempTokens[i];
      if (_records[token].desiredDenorm > 0) {
        tokens[usedIndex++] = token;
      }
    }
    assembly {
      mstore(tokens, usedIndex)
    }
  }

  function getDenormalizedWeight(address token)
    external
    view
    override
    returns (
      uint256 /* denorm */
    )
  {
    return getTokenRecord(token).denorm;
  }

  function getTokenRecord(address token)
    public
    view
    override
    returns (Record memory record)
  {
    record = _records[token];
    record.balance = IERC20(token).balanceOf(address(this));
    require(record.bound, "ERR_NOT_BOUND");
  }

  function getBalance(address token) external view override returns (uint256) {
    return getTokenRecord(token).balance;
  }

  function getUsedBalance(address token)
    external
    view
    override
    returns (uint256)
  {
    Record memory record = getTokenRecord(token);
    require(record.bound, "ERR_NOT_BOUND");
    if (!record.ready) {
      return _minimumBalances[token];
    }
    return record.balance;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

interface IRestrictedIndexPool is IERC20 {
  event LOG_EXIT(
    address indexed caller,
    address indexed tokenOut,
    uint256 tokenAmountOut
  );

  struct Record {
    bool bound;
    bool ready;
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint96 desiredDenorm;
    uint8 index;
    uint256 balance;
  }

  function initialize(address _lpBurn, address _pair) external;

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
    external;

  function exitPoolTo(address to, uint256 poolAmountIn) external;

  function redeemAll() external;

  function isPublicSwap() external view returns (bool);

  function getSwapFee()
    external
    view
    returns (
      uint256 /* swapFee */
    );

  function getExitFee()
    external
    view
    returns (
      uint256 /* exitFee */
    );

  function getController() external view returns (address);

  function getExitFeeRecipient() external view returns (address);

  function isBound(address t) external view returns (bool);

  function getNumTokens() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getCurrentDesiredTokens()
    external
    view
    returns (address[] memory tokens);

  function getDenormalizedWeight(address token)
    external
    view
    returns (
      uint256 /* denorm */
    );

  function getTokenRecord(address token)
    external
    view
    returns (Record memory record);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getBalance(address token) external view returns (uint256);

  function getUsedBalance(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IERC20 {
  event Approval(address indexed src, address indexed dst, uint256 amt);
  event Transfer(address indexed src, address indexed dst, uint256 amt);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}
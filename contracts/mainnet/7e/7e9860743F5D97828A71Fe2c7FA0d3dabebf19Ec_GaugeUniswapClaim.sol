// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/DFH/Automate.sol";
import "./utils/Curve/IRegistry.sol";
import "./utils/Curve/IGauge.sol";
import "./utils/Curve/IMinter.sol";
import "./utils/Curve/IPlainPool.sol";
import "./utils/Curve/IMetaPool.sol";
import "./utils/Uniswap/IUniswapV2Router02.sol";
import {ERC20Tools} from "./utils/ERC20Tools.sol";

// solhint-disable not-rely-on-time
contract GaugeUniswapClaim is Automate {
  using ERC20Tools for IERC20;

  IGauge public staking;

  address public liquidityRouter;

  address public swapToken;

  uint16 public slippage;

  uint16 public deadline;

  address public recipient;

  IERC20 internal _lpToken;

  address internal _pool;

  uint8 internal _swapTokenN;

  // solhint-disable-next-line no-empty-blocks
  constructor(address _info) Automate(_info) {}

  function init(
    address _staking,
    address _liquidityRouter,
    address _swapToken,
    uint16 _slippage,
    uint16 _deadline,
    address _recipient
  ) external initializer {
    require(
      !_initialized || address(staking) == _staking,
      "GaugeUniswapRestake::init: reinitialize staking address forbidden"
    );
    staking = IGauge(_staking);
    require(
      !_initialized || liquidityRouter == _liquidityRouter,
      "GaugeUniswapRestake::init: reinitialize liquidity router address forbidden"
    );
    liquidityRouter = _liquidityRouter;
    swapToken = _swapToken;
    slippage = _slippage;
    deadline = _deadline;
    recipient = _recipient;

    if (!_initialized) {
      IRegistry registry = IRegistry(_registry());
      _lpToken = IERC20(staking.lp_token());
      _pool = registry.get_pool_from_lp_token(address(_lpToken));
      address[8] memory coins = registry.get_coins(_pool);
      uint256 nCoinsPool = registry.get_n_coins(_pool);

      for (; _swapTokenN <= nCoinsPool; _swapTokenN++) {
        require(_swapTokenN < nCoinsPool, "GaugeUniswapRestake::init: invalid swap token address");
        if (coins[_swapTokenN] == _swapToken) break;
      }
    }
  }

  function _registry() internal view returns (address) {
    return IStorage(info()).getAddress(keccak256("Curve:Contract:Registry"));
  }

  function deposit() external onlyOwner {
    IERC20 lpToken = _lpToken; // gas optimisation
    uint256 balance = lpToken.balanceOf(address(this));
    lpToken.safeApprove(address(staking), balance);
    staking.deposit(balance);
  }

  function refund() external onlyOwner {
    address __owner = owner(); // gas optimisation

    IGauge _staking = staking; // gas optimisation
    uint256 stakingBalance = _staking.balanceOf(address(this));
    if (stakingBalance > 0) {
      _staking.withdraw(stakingBalance);
    }
    uint256 lpBalance = _lpToken.balanceOf(address(this));
    if (lpBalance > 0) {
      _lpToken.transfer(__owner, lpBalance);
    }

    IMinter _minter = IMinter(staking.minter());
    _minter.mint(address(_staking));

    IERC20 rewardToken = IERC20(_staking.crv_token());
    uint256 rewardBalance = rewardToken.balanceOf(address(this));
    if (rewardBalance > 0) {
      rewardToken.transfer(__owner, rewardBalance);
    }
  }

  function run(
    uint256 gasFee,
    uint256 _deadline,
    uint256 swapOutMin
  ) external bill(gasFee, "CurveGaugeUniswapClaim") {
    IGauge _staking = staking; // gas optimization
    IERC20 _swapToken = IERC20(swapToken);

    IMinter _minter = IMinter(_staking.minter());
    _minter.mint(address(_staking));
    address rewardToken = _staking.crv_token();
    uint256 rewardAmount = IERC20(rewardToken).balanceOf(address(this));

    address[] memory _path = new address[](2);
    _path[0] = rewardToken;
    _path[1] = address(_swapToken);
    IERC20(rewardToken).safeApprove(liquidityRouter, rewardAmount);
    IUniswapV2Router02(liquidityRouter).swapExactTokensForTokens(
      rewardAmount,
      swapOutMin,
      _path,
      address(this),
      _deadline
    );

    _swapToken.transfer(recipient, _swapToken.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./proxy/ERC1167.sol";
import "./IStorage.sol";
import "./IBalance.sol";

// solhint-disable avoid-tx-origin
abstract contract Automate {
  using ERC1167 for address;

  /// @notice Storage contract address.
  address internal _info;

  /// @notice Contract owner.
  address internal _owner;

  /// @notice Is contract paused.
  bool internal _paused;

  /// @notice Protocol fee in USD (-1 if value in global storage).
  int256 internal _protocolFee;

  /// @notice Is contract already initialized.
  bool internal _initialized;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  event ProtocolFeeChanged(int256 protocolFee);

  constructor(address __info) {
    _info = __info;
    _owner = tx.origin;
    _protocolFee = -1;
  }

  /**
   * @notice Returns address of Storage contract.
   */
  function info() public view returns (address) {
    address impl = address(this).implementation();
    if (impl == address(this)) return _info;

    return Automate(impl).info();
  }

  /// @dev Modifier to protect an initializer function from being invoked twice.
  modifier initializer() {
    if (_owner == address(0)) {
      _owner = tx.origin;
      _protocolFee = -1;
    } else {
      require(_owner == msg.sender, "Automate: caller is not the owner");
    }
    _;
    _initialized = true;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == msg.sender, "Automate: caller is not the owner");
    _;
  }

  /**
   * @notice Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external onlyOwner {
    require(address(this).implementation() == address(this), "Automate: change the owner failed");

    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  /**
   * @dev Throws if called by any account other than the pauser.
   */
  modifier onlyPauser() {
    if (address(this).implementation() == address(this)) {
      address pauser = IStorage(info()).getAddress(keccak256("DFH:Pauser"));
      require(msg.sender == _owner || msg.sender == pauser, "Automate: caller is not the pauser");
    } else {
      require(msg.sender == _owner, "Automate: caller is not the pauser");
    }
    _;
  }

  /**
   * @notice Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view returns (bool) {
    address impl = address(this).implementation();
    if (impl == address(this)) return _paused;

    return _paused || Automate(impl).paused();
  }

  /**
   * @dev Throws if contract unpaused.
   */
  modifier whenPaused() {
    require(paused(), "Automate: not paused");
    _;
  }

  /**
   * @dev Throws if contract paused.
   */
  modifier whenNotPaused() {
    require(!paused(), "Automate: paused");
    _;
  }

  /**
   * @notice Pause contract.
   */
  function pause() external onlyPauser whenNotPaused {
    _paused = true;
  }

  /**
   * @notice Unpause contract.
   */
  function unpause() external onlyPauser whenPaused {
    _paused = false;
  }

  /**
   * @return Current protocol fee.
   */
  function protocolFee() public view returns (uint256) {
    address impl = address(this).implementation();
    if (impl != address(this) && _protocolFee < 0) {
      return Automate(impl).protocolFee();
    }

    IStorage __info = IStorage(info());
    uint256 feeOnUSD = _protocolFee < 0 ? __info.getUint(keccak256("DFH:Fee:Automate")) : uint256(_protocolFee);
    if (feeOnUSD == 0) return 0;

    (, int256 price, , , ) = AggregatorV3Interface(__info.getAddress(keccak256("DFH:Fee:PriceFeed"))).latestRoundData();
    require(price > 0, "Automate: invalid price");

    return (feeOnUSD * 1e18) / uint256(price);
  }

  /**
   * @notice Change protocol fee.
   * @param __protocolFee New protocol fee.
   */
  function changeProtocolFee(int256 __protocolFee) external {
    address impl = address(this).implementation();
    require(
      (impl == address(this) ? _owner : Automate(impl).owner()) == msg.sender,
      "Automate::changeProtocolFee: caller is not the protocol owner"
    );

    _protocolFee = __protocolFee;
    emit ProtocolFeeChanged(__protocolFee);
  }

  /**
   * @dev Claim fees from owner.
   * @param gasFee Claim gas fee.
   * @param operation Claim description.
   */
  function _bill(uint256 gasFee, string memory operation) internal whenNotPaused returns (uint256) {
    address account = owner(); // gas optimisation
    if (tx.origin == account) return 0; // free if called by the owner

    IStorage __info = IStorage(info());

    address balance = __info.getAddress(keccak256("DFH:Contract:Balance"));
    require(balance != address(0), "Automate::_bill: balance contract not found");

    return IBalance(balance).claim(account, gasFee, protocolFee(), operation);
  }

  /**
   * @dev Claim fees from owner.
   * @param gasFee Claim gas fee.
   * @param operation Claim description.
   */
  modifier bill(uint256 gasFee, string memory operation) {
    _bill(gasFee, operation);
    _;
  }

  /**
   * @notice Transfer ERC20 token to recipient.
   * @param token The address of the token to be transferred.
   * @param recipient Token recipient address.
   * @param amount Transferred amount of tokens.
   */
  function transfer(
    address token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    IERC20(token).transfer(recipient, amount);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IRegistry {
  function get_n_coins(address pool) external view returns (uint256);

  function get_coins(address pool) external view returns (address[8] memory);

  function get_pool_from_lp_token(address) external view returns (address);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IGauge {
  function minter() external view returns (address);

  function crv_token() external view returns (address);

  function lp_token() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function deposit(uint256 amount) external;

  function deposit(uint256 amount, address recipient) external;

  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IMinter {
  function minted(address wallet, address gauge) external view returns (uint256);

  function mint(address gauge) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IPlainPool {
  function calc_token_amount(uint256[3] memory amounts, bool isDeposit) external view returns (uint256);

  function add_liquidity(uint256[3] memory amounts, uint256 minMint) external returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IMetaPool {
  function calc_token_amount(uint256[2] memory amounts, bool isDeposit) external view returns (uint256);

  function add_liquidity(uint256[2] memory amounts, uint256 minMint) external returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IUniswapV2Router02 {
  function factory() external view returns (address);

  function WETH() external view returns (address);

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

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ERC20Tools {
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 allowance = token.allowance(address(this), spender);
    if (allowance != 0 && allowance < value) {
      token.approve(spender, 0);
    }
    if (allowance != value) {
      token.approve(spender, value);
    }
  }

  function safeApproveAll(IERC20 token, address spender) internal {
    safeApprove(token, spender, 2**256 - 1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable no-inline-assembly
library ERC1167 {
  bytes public constant CLONE =
    hex"363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3";

  /**
   * @notice Make new proxy contract.
   * @param impl Address prototype contract.
   * @return proxy Address new proxy contract.
   */
  function clone(address impl) external returns (address proxy) {
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, impl))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      proxy := create(0, ptr, 0x37)
    }
    require(proxy != address(0), "ERC1167: create failed");
  }

  /**
   * @notice Returns address of prototype contract for proxy.
   * @param proxy Address proxy contract.
   * @return impl Address prototype contract (current contract address if not proxy).
   */
  function implementation(address proxy) external view returns (address impl) {
    uint256 size;
    assembly {
      size := extcodesize(proxy)
    }

    impl = proxy;
    if (size <= 45 && size >= 41) {
      bool matches = true;
      uint256 i;

      bytes memory code;
      assembly {
        code := mload(0x40)
        mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        mstore(code, size)
        extcodecopy(proxy, add(code, 0x20), 0, size)
      }
      for (i = 0; matches && i < 9; i++) {
        matches = code[i] == CLONE[i];
      }
      for (i = 0; matches && i < 15; i++) {
        if (i == 4) {
          matches = code[code.length - i - 1] == bytes1(uint8(CLONE[45 - i - 1]) - uint8(45 - size));
        } else {
          matches = code[code.length - i - 1] == CLONE[45 - i - 1];
        }
      }
      if (code[9] != bytes1(0x73 - uint8(45 - size))) {
        matches = false;
      }
      uint256 forwardedToBuffer;
      if (matches) {
        assembly {
          forwardedToBuffer := mload(add(code, 30))
        }
        forwardedToBuffer &= (0x1 << (20 * 8)) - 1;
        impl = address(uint160(forwardedToBuffer >> ((45 - size) * 8)));
      }
    }
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IStorage {
  function getBytes(bytes32 key) external view returns (bytes memory);

  function getBool(bytes32 key) external view returns (bool);

  function getUint(bytes32 key) external view returns (uint256);

  function getInt(bytes32 key) external view returns (int256);

  function getAddress(bytes32 key) external view returns (address);

  function getString(bytes32 key) external view returns (string memory);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IBalance {
  function claim(
    address account,
    uint256 gasFee,
    uint256 protocolFee,
    string memory description
  ) external returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/DFH/Automate.sol";
import "./utils/Curve/IRegistry.sol";
import "./utils/Curve/IGauge.sol";
import "./utils/Curve/IMinter.sol";
import "./utils/Curve/IPlainPool.sol";
import "./utils/Curve/IMetaPool.sol";
import "./utils/Uniswap/IUniswapV2Router02.sol";
import {ERC20Tools} from "./utils/ERC20Tools.sol";

// solhint-disable not-rely-on-time
contract GaugeUniswapRestake is Automate {
  using ERC20Tools for IERC20;

  IGauge public staking;

  address public liquidityRouter;

  address public swapToken;

  uint16 public slippage;

  uint16 public deadline;

  IERC20 internal _lpToken;

  address internal _pool;

  uint8 internal _swapTokenN;

  // solhint-disable-next-line no-empty-blocks
  constructor(address _info) Automate(_info) {}

  function init(
    address _staking,
    address _liquidityRouter,
    address _swapToken,
    uint16 _slippage,
    uint16 _deadline
  ) external initializer {
    require(
      !_initialized || address(staking) == _staking,
      "GaugeUniswapRestake::init: reinitialize staking address forbidden"
    );
    staking = IGauge(_staking);
    require(
      !_initialized || liquidityRouter == _liquidityRouter,
      "GaugeUniswapRestake::init: reinitialize liquidity router address forbidden"
    );
    liquidityRouter = _liquidityRouter;
    swapToken = _swapToken;
    slippage = _slippage;
    deadline = _deadline;

    if (!_initialized) {
      IRegistry registry = IRegistry(_registry());
      _lpToken = IERC20(staking.lp_token());
      _pool = registry.get_pool_from_lp_token(address(_lpToken));
      address[8] memory coins = registry.get_coins(_pool);
      uint256 nCoinsPool = registry.get_n_coins(_pool);

      for (; _swapTokenN <= nCoinsPool; _swapTokenN++) {
        require(_swapTokenN < nCoinsPool, "GaugeUniswapRestake::init: invalid swap token address");
        if (coins[_swapTokenN] == _swapToken) break;
      }
    }
  }

  function _registry() internal view returns (address) {
    return IStorage(info()).getAddress(keccak256("Curve:Contract:Registry"));
  }

  function deposit() external onlyOwner {
    IERC20 lpToken = _lpToken; // gas optimisation
    uint256 balance = lpToken.balanceOf(address(this));
    lpToken.safeApprove(address(staking), balance);
    staking.deposit(balance);
  }

  function refund() external onlyOwner {
    address __owner = owner(); // gas optimisation

    IGauge _staking = staking; // gas optimisation
    uint256 stakingBalance = _staking.balanceOf(address(this));
    if (stakingBalance > 0) {
      _staking.withdraw(stakingBalance);
    }
    uint256 lpBalance = _lpToken.balanceOf(address(this));
    if (lpBalance > 0) {
      _lpToken.transfer(__owner, lpBalance);
    }

    IMinter _minter = IMinter(staking.minter());
    _minter.mint(address(_staking));

    IERC20 rewardToken = IERC20(_staking.crv_token());
    uint256 rewardBalance = rewardToken.balanceOf(address(this));
    if (rewardBalance > 0) {
      rewardToken.transfer(__owner, rewardBalance);
    }
  }

  function _swap(
    address[2] memory path,
    uint256 amount,
    uint256 minOut,
    uint256 _deadline
  ) internal returns (uint256) {
    address[] memory _path = new address[](2);
    _path[0] = path[0];
    _path[1] = path[1];

    return
      IUniswapV2Router02(liquidityRouter).swapExactTokensForTokens(amount, minOut, _path, address(this), _deadline)[1];
  }

  function calcTokenAmount(uint256 amount) external view returns (uint256) {
    address pool = _pool; // gas optimization
    IRegistry registry = IRegistry(_registry());

    if (registry.get_n_coins(pool) == 3) {
      uint256[3] memory amountIn;
      amountIn[_swapTokenN] = amount;
      return IPlainPool(pool).calc_token_amount(amountIn, true);
    } else {
      uint256[2] memory amountIn;
      amountIn[_swapTokenN] = amount;
      return IMetaPool(pool).calc_token_amount(amountIn, true);
    }
  }

  function _addLiquidity(
    address pool,
    uint256 amount,
    uint256 minOut
  ) internal {
    IRegistry registry = IRegistry(_registry());

    if (registry.get_n_coins(pool) == 3) {
      uint256[3] memory amountIn;
      amountIn[_swapTokenN] = amount;
      IPlainPool(pool).add_liquidity(amountIn, minOut);
    } else {
      uint256[2] memory amountIn;
      amountIn[_swapTokenN] = amount;
      IMetaPool(pool).add_liquidity(amountIn, minOut);
    }
  }

  function run(
    uint256 gasFee,
    uint256 _deadline,
    uint256 swapOutMin,
    uint256 lpOutMin
  ) external bill(gasFee, "CurveGaugeUniswapRestake") {
    IGauge _staking = staking; // gas optimization

    IMinter _minter = IMinter(_staking.minter());
    _minter.mint(address(_staking));
    address rewardToken = _staking.crv_token();
    uint256 rewardAmount = IERC20(rewardToken).balanceOf(address(this));

    IERC20(rewardToken).safeApprove(liquidityRouter, rewardAmount);
    uint256 amount = _swap([rewardToken, swapToken], rewardAmount, swapOutMin, _deadline);
    IERC20(swapToken).safeApprove(_pool, amount);
    _addLiquidity(_pool, amount, lpOutMin);

    uint256 lpAmount = _lpToken.balanceOf(address(this));
    _lpToken.safeApprove(address(_staking), lpAmount);
    _staking.deposit(lpAmount);
  }
}
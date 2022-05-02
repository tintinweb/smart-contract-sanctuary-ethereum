// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IPanaAuthority.sol";

abstract contract PanaAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IPanaAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IPanaAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IPanaAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    

    /* ========== MODIFIERS ========== */
    
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }
    
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IPanaAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

/**
   * @notice 
    This supply controller is intended to return amount of Pana neeeded to be added/removed 
    to/from the liquidity pool to match the target pana supply in pool at any given point in time
    during the control regime. The treasury then calls the burn and add operations from this 
    contract to perform the Burn/Supply as determined to maintain the target supply in pool

    CAUTION: Since the control mechanism is based on a percentage and Pana is an 18 decimal token,
    any supply of Pana less or equal to 10^^-17 will lead to underflow
**/   
// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "../libraries/SafeERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IPana.sol";
import "../interfaces/ISupplyContoller.sol";
import "../interfaces/IUniswapV2ERC20.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../access/PanaAccessControlled.sol";

contract PanaSupplyController is ISupplyContoller, PanaAccessControlled {

    using SafeERC20 for IERC20;            
    
    address public pair; // The LP pair for which this controller will be used
    address public router; // The address of the UniswapV2Router02 router contract for the given pair
    address public supplyControlCaller; // The address of the contract that is responsible for invoking control

    bool public override supplyControlEnabled; // Switch to start/stop supply control at anytime
    bool public override paramsSet; // Flag that indicates whether the params were set for current control regime

    // Loss Ratio, calculated as lossRatio = deltaPS/deltaTS.
    // Where deltaPS = Target Pana Supply in Pool - Current Pana Supply in Pool
    // deltaTS = Increase in total Pana supply
    // Percentage specified to 4 precision digits. 2250 = 22.50% = 0.2250
    uint256 public lossRatio;

    // cf = Channel floor
    // tlr = Target loss ratio
    // Control should take action only when Pana supply in pool at a point falls such that lossRatio < tlr - cf
    // Percentage specified to 4 precision digits. 100 = 1% = 0.01
    uint256 public cf;

    // cc = Channel Ceiling
    // tlr = Target loss ratio
    // Control should take action only when Pana supply in pool at a point grows such that lossRatio > tlr + cc
    // Percentage specified to 4 precision digits. 100 = 1% = 0.01
    uint256 public cc;

    // Maximum SLPs that the current control regime is allowed burn    
    uint256 public mslp;
    uint256 public cslp; // Count of SLPs burnt by current control regime

    uint256 public lastTotalSupply; // Pana Total Supply when previous control triggered
    uint256 public lastPanaInPool; // Pana supply in pool when previous control triggered

    IERC20 internal immutable PANA;
    IERC20 internal immutable TOKEN;

    constructor(
        address _PANA,
        address _pair, 
        address _router, 
        address _supplyControlCaller,
        address _authority
    ) PanaAccessControlled(IPanaAuthority(_authority)){
        require(_PANA != address(0), "Zero address: PANA");
        require(_pair != address(0), "Zero address: PAIR");
        require(_router != address(0), "Zero address: ROUTER");
        require(_supplyControlCaller != address(0), "Zero address: CALLER");
        require(_authority != address(0), "Zero address: AUTHORITY");

        PANA = IERC20(_PANA);
        TOKEN = (IUniswapV2Pair(_pair).token0() == address(PANA)) ?  
                    IERC20(IUniswapV2Pair(_pair).token1()) : 
                        IERC20(IUniswapV2Pair(_pair).token0());
        pair = _pair;
        router = _router;
        supplyControlCaller = _supplyControlCaller;
        paramsSet = false;
    }

    modifier supplyControlCallerOnly() {
        require(msg.sender == supplyControlCaller ||
                msg.sender == authority.policy(), 
                "CONTROL: Only invokable by policy or a contract authorized as caller");
        _;
    }

    function setSupplyControlParams(uint256 _lossRatio, uint256 _cf, uint256 _cc, uint256 _mslp) 
    external onlyGovernor {
        uint256 old_lossRatio = paramsSet ? lossRatio : 0;
        uint256 old_cf = paramsSet ? cf : 0;
        uint256 old_cc = paramsSet ? cc : 0;
        uint256 old_mslp = paramsSet ? mslp : 0;

        lossRatio = _lossRatio;
        cf = _cf;
        cc = _cc;
        mslp = _mslp;
        cslp = 0;

        setPrevControlPoint();
        paramsSet = true;

        emit SetSupplyControlParams(PANA.totalSupply(), old_lossRatio, old_cf,
                                         old_cc, old_mslp, lossRatio, cf, cc, mslp);
    }

    function enableSupplyControl() external override onlyGovernor {
        require(supplyControlEnabled == false, "CONTROL: Control already in progress");
        supplyControlEnabled = true;
    }

    function disableSupplyControl() external override onlyGovernor {
        require(supplyControlEnabled == true, "CONTROL: No control in progress");
        supplyControlEnabled = false;
        paramsSet = false; // Control Params should be set for new control regime whenever it is started
    }

    function getPanaReserves() internal view returns(uint256 _reserve) {
        (uint256 _reserve0, uint256 _reserve1, ) = IUniswapV2Pair(pair).getReserves();
        _reserve = (IUniswapV2Pair(pair).token0() == address(PANA)) ? _reserve0 : _reserve1;
    }

    // Returns the target pana supply in pool to be achieved at a given totalSupply point
    function getTargetSupply() public view returns (uint256 _targetPanaSupply) {
        uint256 _totalSupply = PANA.totalSupply();
        _targetPanaSupply = lastPanaInPool + ((lossRatio * (_totalSupply - lastTotalSupply)) / (10**4));
    }

    // Returns the pana supply floor for the pool at a given totalSupply point
    function getSupplyFloor() public view returns (uint256 _panaSupplyFloor) {
        uint256 _totalSupply = PANA.totalSupply();
        _panaSupplyFloor = lastPanaInPool + (((lossRatio - cf) * (_totalSupply - lastTotalSupply)) / (10**4));
    }

    // Returns the pana supply ceiling for the pool at a given totalSupply point
    function getSupplyCeiling() public view returns (uint256 _panaSupplyCeiling) {
        uint256 _totalSupply = PANA.totalSupply();
        _panaSupplyCeiling = lastPanaInPool + (((lossRatio + cc) * (_totalSupply - lastTotalSupply)) / (10**4));
    }

    function getSupplyControlAmount() external view 
    override returns (uint256 _pana, uint256 _slp, bool _burn) {
        require(paramsSet == true, "CONTROL: Contol parameters are not set, please set control parameters");

        (_pana, _slp, _burn) = (0, 0, false);

        if (supplyControlEnabled && cslp < mslp) {
            uint256 _panaInPool = getPanaReserves();
            uint256 _ts = getTargetSupply();
            uint256 _channelFloor = getSupplyFloor();
            uint256 _channelCeiling = getSupplyCeiling();

            if ((_panaInPool < _channelFloor || _panaInPool > _channelCeiling)) {
                _burn = _panaInPool > _ts;

                if (_burn) {
                    _pana = _panaInPool - _ts;
                    _slp = (_pana * IUniswapV2Pair(pair).totalSupply()) / (2 * _panaInPool);

                    if (((cslp + _slp) > mslp)) {
                        _slp = mslp - cslp;
                    }
                 } else {
                    _pana = _ts - _panaInPool;
                    _slp = 0;
                }
            }
        }
    }

    function setPrevControlPoint() internal {
        lastTotalSupply = PANA.totalSupply();
        lastPanaInPool = getPanaReserves();
    }

    function burn(uint256 _pana, uint256 _slp) external override supplyControlCallerOnly {
        
        IUniswapV2Pair(pair).approve(router, _slp);

        (uint _panaOut, uint _tokenOut) = 
            IUniswapV2Router02(router).removeLiquidity(
                address(PANA),
                address(TOKEN),
                _slp,
                0,
                0,
                address(this),
                type(uint256).max
            );

        cslp = cslp + _slp;

        TOKEN.approve(router, _tokenOut);

        address[] memory _path;
        _path[0] = address(TOKEN);
        _path[1] = address(PANA);

        uint256 _panaSwapOut = IUniswapV2Router02(router).swapExactTokensForTokens(
            _tokenOut, 
            0, 
            _path,
            address(this), 
            type(uint256).max
        )[1];

        setPrevControlPoint();

        PANA.safeTransferFrom(address(this), msg.sender, _panaOut + _panaSwapOut);

        emit Burnt(PANA.totalSupply(), _slp, _panaOut + _panaSwapOut);
    }

    function add(uint256 _pana) external override supplyControlCallerOnly {
        
        PANA.approve(router, _pana);

        address[] memory _path;
        _path[0] = address(PANA);
        _path[1] = address(TOKEN);

        uint256 _tokenOut = IUniswapV2Router02(router).swapExactTokensForTokens(
            _pana, 
            0, 
            _path,
            address(this), 
            type(uint256).max
        )[1];

        setPrevControlPoint();

        TOKEN.safeTransferFrom(address(this), msg.sender, _tokenOut);

        emit Supplied(PANA.totalSupply(), _tokenOut, _pana);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IPana is IERC20 {
  function mint(address account_, uint256 amount_) external;

  function burn(uint256 amount) external;

  function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IPanaAuthority {
    /* ========== EVENTS ========== */
    
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);    
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);    
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);    

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */
    
    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ISupplyContoller {
        
    /* ========== EVENTS ========== */
    event SetSupplyControlParams(uint256 totalSupply, uint256 old_lossRatio, uint256 old_cf, uint256 old_cc, 
                            uint256 old_mslp, uint256 lossRatio, uint256 cf, uint256 cc, 
                                uint256 mslp);

    event Burnt(uint256 totalSupply, uint256 slp, uint256 pana);
    event Supplied(uint256 totalSupply, uint256 tokenOut, uint256 pana);
    
    function supplyControlEnabled() external view returns (bool);

    function paramsSet() external view returns (bool);

    function setSupplyControlParams(uint256 _lossRatio, uint256 _cf, uint256 _cc, uint256 _mslp) external;

    function enableSupplyControl() external;

    function disableSupplyControl() external;

    function getSupplyControlAmount() external view returns (uint256 _pana, uint256 _slp, bool _burn);

    function burn(uint256 _pana, uint256 _slp) external;

    function add(uint256 _pana) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
    function sync() external;
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}
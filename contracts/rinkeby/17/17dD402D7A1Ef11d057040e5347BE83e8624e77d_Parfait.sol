//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma abicoder v2; //Uniswap guide: to allow arbitrary nested arrays and structs to be encoded and decoded in calldata, a feature used when executing a swap.

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//compounds interace
interface CErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function balanceOf(address) external view returns (uint); //Lee added
}

interface CEther {
    function mint() external payable;

    function exchangeRateStored() external view returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function balanceOf(address) external view returns (uint); //Lee added
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract Parfait is Initializable{
    address public owner;
    int public CETHAllocation;
    int public CWBTCAllocation;
    int public CDAIAllocation;

    // all addresses on Rinkeby
    IWETH WETH = IWETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    IERC20 WBTC = IERC20(0x577D296678535e4903D59A4C929B718e1D575e0A);
    IERC20 DAI = IERC20(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);

    CEther CETH = CEther(0xd6801a1DfFCd0a410336Ef88DeF4320D6DF1883e);
    CErc20 CWBTC = CErc20(0x0014F450B8Ae7708593F4A46F8fa6E5D50620F96);
    CErc20 CDAI = CErc20(0x6D7F0754FFeb405d23C51CE938289d4835bE3b14);

    AggregatorV3Interface internal ETHPriceFeed =
        AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    AggregatorV3Interface internal BTCPriceFeed =
        AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404);
    AggregatorV3Interface internal DAIPriceFeed =
        AggregatorV3Interface(0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF);

    ISwapRouter internal swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    function initialize(
        address _owner,
        int _CETHAllocation,
        int _CWBTCAllocation,
        int _CDAIAllocation
    ) public payable initializer {
        require(_CETHAllocation + _CWBTCAllocation + _CDAIAllocation == 100, "invalid allocations sum");
        owner = _owner;
        CETHAllocation = _CETHAllocation;
        CWBTCAllocation = _CWBTCAllocation;
        CDAIAllocation = _CDAIAllocation;

        if(_CETHAllocation > 0){
            //deposit ETH for CETH
            CETH.mint{ value: msg.value * uint(_CETHAllocation) / 100 }();
        }

        if(_CWBTCAllocation + _CDAIAllocation > 0) {
            //convert remaining ETH to WETH
            WETH.deposit{ value: (msg.value * uint(_CWBTCAllocation + _CDAIAllocation) / 100)}();

            //declare uniswap params
            ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(0),
                    tokenOut: address(0),
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: 0,
                    amountOutMinimum: 0, // this leaves txs vulnerable bad rates & MEV
                    sqrtPriceLimitX96: 0
                });
            if(_CWBTCAllocation > 0) {
                //swap WETH for WBTC
                TransferHelper.safeApprove(address(WETH), address(swapRouter), (msg.value * uint(_CWBTCAllocation) / 100));
                params.tokenIn = address(WETH);
                params.tokenOut = address(WBTC);
                params.amountIn = (msg.value * uint(_CWBTCAllocation) / 100);
                swapRouter.exactInputSingle(params);
                //deposit WBTC for CWBTC
                WBTC.approve(address(CWBTC), WBTC.balanceOf(address(this)));
                CWBTC.mint(WBTC.balanceOf(address(this)));
            }
            if(_CDAIAllocation > 0) {
                //swap WETH for DAI
                TransferHelper.safeApprove(address(WETH), address(swapRouter), (msg.value * uint(_CDAIAllocation) / 100));
                params.tokenIn = address(WETH);
                params.tokenOut = address(DAI);
                params.amountIn = (msg.value * uint(_CDAIAllocation) / 100);
                swapRouter.exactInputSingle(params);
                //Deposit DAI for CDAI
                DAI.approve(address(CDAI), DAI.balanceOf(address(this)));
                CDAI.mint(DAI.balanceOf(address(this)));
            }
        }
    }

    //this function receives ether, updates allocations and then rebalances 
    function updateAllocationsAndRebalance(
        int _CETHAllocation,
        int _CWBTCAllocation,
        int _CDAIAllocation
    ) public payable {
        require(msg.sender == owner, "only owner can call this");
        require(
            _CETHAllocation + _CWBTCAllocation + _CDAIAllocation == 100,
            "invalid allocations sum"
        );
        CETHAllocation = _CETHAllocation;
        CWBTCAllocation = _CWBTCAllocation;
        CDAIAllocation = _CDAIAllocation;

        sell();

        //deposit any ETH (from new deposits or redeeming CETH for ETH above) into WETH
        uint balance = address(this).balance;
        if(balance > 0) {
            WETH.deposit{ value: balance }();
        }

        buy();
    }

    // sells all strategies to ETH or WETH
    function sell() internal {
        uint CETHBalance = CETH.balanceOf(address(this));
        uint CWBTCBalance = CWBTC.balanceOf(address(this));
        uint CDAIBalance = CDAI.balanceOf(address(this));

        if (CETHBalance > 0) {
            //redeem  CETH for ETH
            CETH.redeem(CETHBalance);
        }
        if (CWBTCBalance > 0) {
            //redeem CWBTC for WBTC
            CWBTC.redeem(CWBTCBalance);
            //then swap WBTC for WETH
            swap(address(WBTC), address(WETH), WBTC.balanceOf(address(this)));    
        }
        if (CDAIBalance > 0) {
            //redeem CDAI for DAI
            CDAI.redeem(CDAIBalance);
            //then swap DAI for WETH
            swap(address(DAI), address(WETH), DAI.balanceOf(address(this)));
        }
    }

    //buys from WETH as per allocations
    function buy() internal {
        uint WETHBalance = WETH.balanceOf(address(this));
        uint CETHBuyAmount = WETHBalance * uint(CETHAllocation) / 100;
        uint CWBTCBuyAmount = WETHBalance * uint(CWBTCAllocation) / 100;
        uint CDAIBuyAmount = WETHBalance * uint(CDAIAllocation) / 100;

        if(CETHAllocation > 0) {
            //withdraw WETH for ETH
            WETH.withdraw(CETHBuyAmount);
            //deposit ETH for CETH
            CETH.mint{ value: address(this).balance }();
        }
        if(CWBTCAllocation > 0) {
            //swap WETH for WBTC
            swap(address(WETH), address(WBTC), CWBTCBuyAmount);
            //deposit WBTC for CWBTC
            WBTC.approve(address(CWBTC), WBTC.balanceOf(address(this)));
            CWBTC.mint(WBTC.balanceOf(address(this)));
        }
        if(CDAIAllocation > 0) {
            //swap WETH for DAI
            swap(address(WETH), address(DAI), CDAIBuyAmount);
            //Deposit DAI for CDAI
            DAI.approve(address(CDAI), DAI.balanceOf(address(this)));
            CDAI.mint(DAI.balanceOf(address(this)));
        }
    }

    // sell all to ETH and send out
    function withdraw() external {
        require(msg.sender == owner, "only owner can call this");
        sell();
        //withdraw balance of WETH for ETH
        uint WETHBalance = WETH.balanceOf(address(this));
        if(WETHBalance > 0) {
            WETH.withdraw(WETH.balanceOf(address(this)));
        }        
        //transfer out balance of ETH
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "transfer to owner unsuccessful");
    }

    //performs internal ERC20 swaps through uniswap
    function swap(address _tokenIn, address _tokenOut, uint _amount) internal {
        //approval
        TransferHelper.safeApprove(
            _tokenIn,
            address(swapRouter),
            _amount
        );

        //swap
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amount,
                amountOutMinimum: 0, // this leaves txs vulnerable bad rates & MEV
                sqrtPriceLimitX96: 0
            });
        swapRouter.exactInputSingle(params);
    }

    receive() external payable {
    }

    //returns balances of token in base units scaled up 1e18
    function getBalances() public view returns (int ETHBalance, int WBTCBalance, int DAIBalance) {
        ETHBalance = int(CETH.balanceOf(address(this)) * (CETH.exchangeRateStored()) / 1e18); //check for overflow
        WBTCBalance = int(CWBTC.balanceOf(address(this)) * (CWBTC.exchangeRateStored()) / 1e18) * 1e10; //WBTC only has 8 digits, scale up to match other units
        DAIBalance = int(CDAI.balanceOf(address(this)) * (CDAI.exchangeRateStored()) / 1e18);
    }
    //returns prices (usd/token) scaled by 1e8
    function getPrices() public view returns (int ETHPrice, int BTCPrice, int DAIPrice) {
        (, ETHPrice, , , ) = ETHPriceFeed.latestRoundData();
        (, BTCPrice, , , ) = BTCPriceFeed.latestRoundData();
        (, DAIPrice, , , ) = DAIPriceFeed.latestRoundData();
    }
    //returns values (scaled by 1e26) = balances (scaled 1e18) * Prices (scaled 1e8)
    function getValues() public view returns (int ETHValue, int BTCValue, int DAIValue, int totalValue) {
        (int ETHBalance, int WBTCBalance, int DAIBalance) = getBalances();
        (int ETHPrice, int BTCPrice, int DAIPrice) = getPrices();
        
        ETHValue = ETHBalance * ETHPrice; 
        BTCValue = WBTCBalance * BTCPrice; //check that this calcs WBTC Value correctly?
        DAIValue = DAIBalance * DAIPrice;
        totalValue = ETHValue + BTCValue + DAIValue;
    }
    //for testing purposes - these should all be 0
    function check0Balances() public view returns (int ETHBalance, int WETHBalance, int WBTCBalance, int DAIBalance) {
        ETHBalance = int(address(this).balance);
        WETHBalance = int(WETH.balanceOf(address(this)));
        WBTCBalance = int(WBTC.balanceOf(address(this)));
        DAIBalance = int(DAI.balanceOf(address(this))); 
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
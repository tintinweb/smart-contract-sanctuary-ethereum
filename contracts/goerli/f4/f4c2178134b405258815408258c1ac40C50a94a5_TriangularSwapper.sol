// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './BaseSwapperV2.sol';
import './UniswapV2Swap.sol';

contract TriangularSwapper is BaseSwapperV2 {
  
  event TriangularSwap(address, uint256, address, uint256);

  function execute(
      address _borrowAsset,
      uint256 _borrowAmount,
      address _repayAsset,
      uint256 _repayAmount,
      bytes memory _executionData
  ) internal virtual override {

    (address[] memory path) = abi.decode(_executionData, (address[]));

    require(path[0] == _borrowAsset, "borrow asset is not same path 0!");
    
    emit TriangularSwap(_borrowAsset, _borrowAmount, _repayAsset, _repayAmount);
    UniswapV2Swap uniswap = new UniswapV2Swap();

    uniswap.triangularArbitrage(path, _borrowAmount);
  }
  function test () public {
    //usdt decimals 6
    uint256 _amount0 = 10000000;
    uint256 _amount1 = 10;
    
    //address on real net
    // address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address RACA = 0x12BB890508c125661E03b09EC06E404bc9289040;

    //testnet
    address WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address DAI = 0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844;
    address USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    
    bytes memory _executionData = abi.encode([
      WETH,
      DAI,
      USDC,
      WETH
    ]);

    bytes memory _data = abi.encode(WETH, _amount0, WETH, 0, _executionData);
    
    this.uniswapV2Call(
      address(0x03EF36C4A2ad9f53616a32Bf5C41510ee0c06237),
      _amount0, 
      _amount1, 
      _data);
    // bytes memory _executionData = abi.encode([
    //   USDT,
    //   WETH,
    //   RACA,
    //   USDT
    // ]);

    // bytes memory _data = abi.encode(USDT, _amount0, USDT, 0, _executionData);
    
    // this.uniswapV2Call(
    //   0x03EF36C4A2ad9f53616a32Bf5C41510ee0c06237,
    //   _amount0, 
    //   _amount1, 
    //   _data);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IUniswapV2Pair } from "./interfaces/IUniswapV2Pair.sol";
import { ERC20 } from "./lib/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "./lib/solmate/src/utils/SafeTransferLib.sol";
import { UnsafeUnilib } from "./lib/UnsafeUnilib.sol";

// We are throwing away requires that are mostly hitting us if we have bad input.

/**
 * @notice Minimal implementation to support Uniswap V2 flash swaps (flashloan + swap)
 * @dev This contract should not be holding any funds beyond a few wei for gas savings.
 * There are no requires or safety checks within the code, meaning that it may revert late
 * if incorrect or bad input is provided.
 * @author Lasse Herskind
 */
abstract contract BaseSwapperV2 {
    using SafeTransferLib for ERC20;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /**
     * @notice Execute arbitrary logic for the user.
     * @dev To be overridden by inheriting contract
     * @param _borrowAsset The address of the asset to borrow
     * @param _borrowAmount The amount borrowed that is given to the contract
     * @param _repayAsset The address of the asset to repay with
     * @param _repayAmount The amount to repay
     */
    function execute(
        address _borrowAsset,
        uint256 _borrowAmount,
        address _repayAsset,
        uint256 _repayAmount,
        bytes memory _executionData
    ) internal virtual {}

    /**
     * @notice Performs a Uniswap V2 flash swap through 1 or 2 pairs
     * @param _borrowAsset The address of the asset to borrow
     * @param _borrowAmount The amount to borrow
     * @param _repayAsset The address of the asset to repay with
     * @param _triangular True if flashswap should go through WETH, false otherwise
     * @param _executionData Bytes to be decoded by `execute` to perform arb
     */
    function swap(
        address _borrowAsset,
        uint256 _borrowAmount,
        address _repayAsset,
        bool _triangular,
        bytes memory _executionData
    ) public {
        if (!_triangular) {
            _singleFlashSwap(
                _borrowAsset,
                _borrowAmount,
                _repayAsset,
                _executionData
            );
        } else {
            _triangularFlashSwap(
                _borrowAsset,
                _borrowAmount,
                _repayAsset,
                _executionData
            );
        }
    }

    /**
     * @notice Helper function to initiate single pair flash swap
     * @param _borrowAsset The address of the borrow asset
     * @param _borrowAmount The amount to borrow
     * @param _repayAsset The address of the asset to repay with
     * @param _executionData Bytes to be decoded by `execute` to perform arb
     */
    function _singleFlashSwap(
        address _borrowAsset,
        uint256 _borrowAmount,
        address _repayAsset,
        bytes memory _executionData
    ) private {
        (
            address token0,
            address token1,
            uint256 amount0Out,
            uint256 amount1Out
        ) = _borrowAsset < _repayAsset
                ? (_borrowAsset, _repayAsset, _borrowAmount, uint256(0))
                : (_repayAsset, _borrowAsset, uint256(0), _borrowAmount);
        bytes memory data = abi.encode(
            _borrowAsset,
            _borrowAmount,
            _repayAsset,
            0,
            _executionData
        );
        // Assume that pair is deployed. Compute the pair address internally to save gas
        address pair = UnsafeUnilib.getPair(token0, token1);
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    /**
     * @notice Helper function to initiate double pair flash swap, e.g., A -> WETH -> B
     * @dev Triangular swaps are more complex. Will go to `repayPair` to get WETH and then
     * swap that to borrow, before finally repaying with the repay asset to satisfy K
     * @param _borrowAsset The address of the borrow asset
     * @param _borrowAmount The amount to borrow
     * @param _repayAsset The address of the asset to repay with
     * @param _executionData Bytes to be decoded by `execute` to perform arb
     */
    function _triangularFlashSwap(
        address _borrowAsset,
        uint256 _borrowAmount,
        address _repayAsset,
        bytes memory _executionData
    ) private {
        (address borrowPair, uint256 wethNeeded) = _computeInputAmount(
            WETH,
            _borrowAsset,
            _borrowAmount
        );
        bytes memory data = abi.encode(
            _borrowAsset,
            _borrowAmount,
            _repayAsset,
            wethNeeded,
            _executionData
        );

        (
            uint256 amount0Out,
            uint256 amount1Out,
            address token0,
            address token1
        ) = _repayAsset < WETH
                ? (uint256(0), wethNeeded, _repayAsset, WETH)
                : (wethNeeded, uint256(0), WETH, _repayAsset);
        address repayPair = UnsafeUnilib.getPair(token0, token1);
        IUniswapV2Pair(repayPair).swap(
            amount0Out,
            amount1Out,
            address(this),
            data
        );
    }

    /// Callback in Uniswap V2 swap  ///

    /**
     * @notice Execute payload for triangular swap. Use Uniswap V2 pair to get `_borrowAmount` of `_borrowAsset`, then compute amount to repay and execute user-specific logic.
     * @param _borrowAsset The address that is borrowed
     * @param _borrowAmount The amount that is borrowed
     * @param _repayAsset The address of the asset to repay with
     * @param _executionData Bytes to be decoded by `execute` to perform arb
     */
    function _triangleExecute(
        address _borrowAsset,
        uint256 _borrowAmount,
        address _repayAsset,
        uint256 _wethReceived,
        bytes memory _executionData
    ) private {
        (
            address token0,
            address token1,
            uint256 amount0Out,
            uint256 amount1Out
        ) = _borrowAsset < WETH
                ? (_borrowAsset, WETH, _borrowAmount, uint256(0))
                : (WETH, _borrowAsset, uint256(0), _borrowAmount);
        address borrowPair = UnsafeUnilib.getPair(token0, token1);
        ERC20(WETH).safeTransfer(borrowPair, _wethReceived);

        // Swap WETH to `_borrowAmount` `_borrowAsset`
        IUniswapV2Pair(borrowPair).swap(
            amount0Out,
            amount1Out,
            address(this),
            bytes("")
        );
        (address repayPair, uint256 amountToRepay) = _computeInputAmount(
            _repayAsset,
            WETH,
            _wethReceived
        );
        execute(
            _borrowAsset,
            _borrowAmount,
            _repayAsset,
            amountToRepay,
            _executionData
        );
        ERC20(_repayAsset).safeTransfer(repayPair, amountToRepay);
    }

    /**
     * @notice Execute payload for single swap, will compute how much is needed to repay
     * @param _borrowAsset The address that is borrowed
     * @param _borrowAmount The amount that is borrowed
     * @param _repayAsset The address of the asset to repay with
     * @param _executionData Bytes to be decoded by `execute` to perform arb
     */
    function _singleExecute(
        address _borrowAsset,
        uint256 _borrowAmount,
        address _repayAsset,
        bytes memory _executionData
    ) private {
        (address pair, uint256 repayAmount) = _computeInputAmount(
            _repayAsset,
            _borrowAsset,
            _borrowAmount
        );
        execute(
            _borrowAsset,
            _borrowAmount,
            _repayAsset,
            repayAmount,
            _executionData
        );
        ERC20(_repayAsset).safeTransfer(pair, repayAmount);
    }

    /**
     * @notice Computes the amount of `_inputAsset` needed to get `_outputAmount` of `_outputAsset`.
     * @param _inputAsset The address of the asset we are providing as input
     * @param _outputAsset The address of the asset we which to receive
     * @param _outputAmount The amount of `_outputAsset` we are to receive
     * @return pair The address of uniswap pair
     * @return inputAmount The amount of `_inputAsset` needed to satisfy K
     */
    function _computeInputAmount(
        address _inputAsset,
        address _outputAsset,
        uint256 _outputAmount
    ) private view returns (address pair, uint256 inputAmount) {
        pair = UnsafeUnilib.sortAndGetPair(_inputAsset, _outputAsset);
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair)
            .getReserves();
        (uint256 inputReserve, uint256 outputReserve) = _inputAsset <
            _outputAsset
            ? (uint256(reserve0), uint256(reserve1))
            : (uint256(reserve1), uint256(reserve0));
        inputAmount =
            ((1000 * inputReserve * _outputAmount) /
                (997 * (outputReserve - _outputAmount))) +
            1;
    }

    /**
     * @notice Fallback function from Uniswap V2 `swap`
     * @param _sender The msg.sender that initiated the `swap` function
     * @param _amount0 The amount of asset0 that is received
     * @param _amount1 The amount of asset1 that is received
     * @param _data Bytes containing information for the swap + execution specific data
     */
    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) public {
        (
            address _borrowAsset,
            uint256 _borrowAmount,
            address _repayAsset,
            uint256 _wethIntermediate,
            bytes memory _executionData
        ) = abi.decode(_data, (address, uint256, address, uint256, bytes));

        if (_wethIntermediate > 0) {
            _triangleExecute(
                _borrowAsset,
                _borrowAmount,
                _repayAsset,
                _wethIntermediate,
                _executionData
            );
        } else {
            _singleExecute(
                _borrowAsset,
                _borrowAmount,
                _repayAsset,
                _executionData
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract UniswapV2Swap {
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    IUniswapV2Router private router = IUniswapV2Router(UNISWAP_V2_ROUTER);
    IERC20 private weth = IERC20(WETH);
    IERC20 private dai = IERC20(DAI);
  
    // Swap WETH to DAI
    function swapSingleHopExactAmountIn(uint amountIn, uint amountOutMin)
        external
        returns (uint amountOut)
    {
        weth.transferFrom(msg.sender, address(this), amountIn);
        weth.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        // amounts[0] = WETH amount, amounts[1] = DAI amount
        return amounts[1];
    }

    // Swap DAI -> WETH -> USDC
    function swapMultiHopExactAmountIn(uint amountIn, uint amountOutMin)
        external
        returns (uint amountOut)
    {
        dai.transferFrom(msg.sender, address(this), amountIn);
        dai.approve(address(router), amountIn);

        address[] memory path;
        path = new address[](3);
        path[0] = DAI;
        path[1] = WETH;
        path[2] = USDC;

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        // amounts[0] = DAI amount
        // amounts[1] = WETH amount
        // amounts[2] = USDC amount
        return amounts[2];
    }

    // Swap WETH to DAI
    function swapSingleHopExactAmountOut(uint amountOutDesired, uint amountInMax)
        external
        returns (uint amountOut)
    {
        weth.transferFrom(msg.sender, address(this), amountInMax);
        weth.approve(address(router), amountInMax);

        address[] memory path;
        path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;

        uint[] memory amounts = router.swapTokensForExactTokens(
            amountOutDesired,
            amountInMax,
            path,
            msg.sender,
            block.timestamp
        );

        // Refund WETH to msg.sender
        if (amounts[0] < amountInMax) {
            weth.transfer(msg.sender, amountInMax - amounts[0]);
        }

        return amounts[1];
    }

    // Swap DAI -> WETH -> USDC
    function swapMultiHopExactAmountOut(uint amountOutDesired, uint amountInMax)
        external
        returns (uint amountOut)
    {
        dai.transferFrom(msg.sender, address(this), amountInMax);
        dai.approve(address(router), amountInMax);

        address[] memory path;
        path = new address[](3);
        path[0] = DAI;
        path[1] = WETH;
        path[2] = USDC;

        uint[] memory amounts = router.swapTokensForExactTokens(
            amountOutDesired,
            amountInMax,
            path,
            msg.sender,
            block.timestamp
        );

        // Refund DAI to msg.sender
        if (amounts[0] < amountInMax) {
            dai.transfer(msg.sender, amountInMax - amounts[0]);
        }

        return amounts[2];
    }
    function triangularArbitrage (address[] memory path, uint256 amountIn) external returns (uint256) {

        require(path.length == 4, "path should include 3 items for triangular arbitrage");

        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(address(router), amountIn);

        uint256 amountOutMin = 10;
        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        return amounts[3];
    }
}

interface IUniswapV2Router {
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
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

library UnsafeUnilib {
    function sortAndGetPair(address tokenA, address tokenB)
        internal
        pure
        returns (address pair)
    {
        (address token0, address token1) = sort(tokenA, tokenB);
        pair = getPair(token0, token1);
    }

    function sort(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }

    function getPair(address token0, address token1)
        internal
        pure
        returns (address pair)
    {
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}
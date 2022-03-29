// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./IERC20.sol";

interface IBentoBoxV1 {
    function withdraw(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);

    function deposit(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
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

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;

import "./IERC20.sol";

interface ISwapperGeneric {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);

    /// @notice Calculates the amount of token 'from' needed to complete the swap (amountFrom),
    /// this should be less than or equal to amountFromMax.
    /// Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for exactly 'exactAmountTo' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Transfers allocated, but unused 'from' tokens within the BentoBox to 'refundTo' (amountFromMax - amountFrom).
    /// Returns the amount of 'from' tokens withdrawn from BentoBox (amountFrom).
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) external returns (uint256 shareUsed, uint256 shareReturned);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface Tether {
    function approve(address spender, uint256 value) external;

    function balanceOf(address user) external view returns (uint256);

    function transfer(address to, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface CurvePool {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address receiver
    ) external returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address receiver
    ) external returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function approve(address _spender, uint256 _value) external returns (bool);

    function add_liquidity(uint256[2] memory amounts, uint256 _min_mint_amount) external;
    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;
    function add_liquidity(uint256[4] memory amounts, uint256 _min_mint_amount) external;

    function remove_liquidity_one_coin(uint256 tokenAmount, int128 i, uint256 min_amount) external returns(uint256);
    function remove_liquidity_one_coin(uint256 tokenAmount, uint256 i, uint256 min_amount) external returns(uint256);
    function remove_liquidity_one_coin(uint256 tokenAmount, int128 i, uint256 min_amount, address receiver) external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface CurveThreeCryptoPool {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) payable external;

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IYearnVault {
    function withdraw() external returns (uint256);
    function deposit(uint256 amount, address recipient) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../interfaces/IBentoBoxV1.sol";
import "../../interfaces/curve/ICurvePool.sol";
import "../../interfaces/curve/ICurveThreeCryptoPool.sol";
import "../../interfaces/yearn/IYearnVault.sol";
import "../../interfaces/Tether.sol";
import "../../interfaces/ISwapperGeneric.sol";

contract YVCVXETHSwapper is ISwapperGeneric {
    IBentoBoxV1 public constant DEGENBOX = IBentoBoxV1(0xd96f48665a1410C0cd669A88898ecA36B9Fc2cce);
    CurvePool public constant MIM3POOL = CurvePool(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);
    CurvePool public constant CVXETHPOOL = CurvePool(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);
    IYearnVault public constant YVCVXETH = IYearnVault(0x1635b506a88fBF428465Ad65d00e8d6B6E5846C3);
    Tether public constant USDT = Tether(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 public constant MIM = IERC20(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    CurveThreeCryptoPool public constant THREECRYPTO = CurveThreeCryptoPool(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46);

    constructor() {
       // WETH.approve(address(THREECRYPTO), type(uint256).max);
       // USDT.approve(address(MIM3POOL), type(uint256).max);
    }

    /// @inheritdoc ISwapperGeneric
    function swap(
        IERC20,
        IERC20,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        DEGENBOX.withdraw(IERC20(address(YVCVXETH)), address(this), address(this), 0, shareFrom);

        // Yearn CVXETH -> Curve CVXETH
        uint256 cvxEthAmount = YVCVXETH.withdraw();

        // Curve CVXETH -> WETH
        uint256 wethAmount = CVXETHPOOL.remove_liquidity_one_coin(cvxEthAmount, uint256(0), 0);

        // WETH -> USDT
        THREECRYPTO.exchange(2, 0, wethAmount, 0);

        // USDT -> MIM
        uint256 mimAmount = MIM3POOL.exchange_underlying(3, 0, USDT.balanceOf(address(this)), 0, address(DEGENBOX));

        (, shareReturned) = DEGENBOX.deposit(MIM, address(DEGENBOX), recipient, mimAmount, 0);
        extraShare = shareReturned - shareToMin;
    }

    /// @inheritdoc ISwapperGeneric
    function swapExact(
        IERC20,
        IERC20,
        address,
        address,
        uint256,
        uint256
    ) public pure override returns (uint256 shareUsed, uint256 shareReturned) {
        return (0, 0);
    }
}
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
pragma solidity >=0.6.12;

interface ILevSwapperGeneric {
    /// @notice Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);
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
import "../../interfaces/yearn/IYearnVault.sol";
import "../../interfaces/ILevSwapperGeneric.sol";

interface CurvePool {
    function add_liquidity(
        address pool,
        uint256[4] memory amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);
}

contract YVMIM3CRVLevSwapper is ILevSwapperGeneric {
    IBentoBoxV1 public constant DEGENBOX = IBentoBoxV1(0xd96f48665a1410C0cd669A88898ecA36B9Fc2cce);
    CurvePool public constant THREEPOOL = CurvePool(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
    IERC20 public constant MIM3CRV = IERC20(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);
    IYearnVault public constant YVMIM3CRV = IYearnVault(0x2DfB14E32e2F8156ec15a2c21c3A6c053af52Be8);
    IERC20 public constant MIM = IERC20(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);

    constructor() {
        MIM.approve(address(THREEPOOL), type(uint256).max);
        MIM3CRV.approve(address(YVMIM3CRV), type(uint256).max);
    }

    /// @inheritdoc ILevSwapperGeneric
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        (uint256 mimAmount, ) = DEGENBOX.withdraw(MIM, address(this), address(this), 0, shareFrom);

        // MIM -> MIM3CRV
        // MIM, DAI, USDC, USDT
        uint256[4] memory amounts = [mimAmount, 0, 0, 0];
        uint256 mim3CrvAmount = THREEPOOL.add_liquidity(address(MIM3CRV), amounts, 0);

        // MIM3CRV -> YVMIM3CRV
        uint256 yvMim3CrvAmount = YVMIM3CRV.deposit(mim3CrvAmount, address(DEGENBOX));

        (, shareReturned) = DEGENBOX.deposit(IERC20(address(YVMIM3CRV)), address(DEGENBOX), recipient, yvMim3CrvAmount, 0);
        extraShare = shareReturned - shareToMin;
    }
}
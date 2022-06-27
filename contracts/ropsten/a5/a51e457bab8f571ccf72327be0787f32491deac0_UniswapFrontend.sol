// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interface/IFrontend.sol";
import "./interface/IUniswap.sol";

IUniswapV2Factory constant uniFactory = IUniswapV2Factory(
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
);

contract UniswapFrontend is IFrontend {
    function render(bytes calldata appState)
        external
        pure
        override
        returns (VdomElem[] memory vdom)
    {
        require(appState.length == 0, "Unexpected state");

        vdom = new VdomElem[](5);
        vdom[0].typeHash = TYPE_TEXT;
        vdom[0].data = bytes("HELLO WORLD");

        vdom[1].typeHash = TYPE_IN_AMOUNT;
        vdom[1].data = abi.encode(DataAmount("Amount in", 18));

        vdom[2].typeHash = TYPE_IN_DROPDOWN;
        vdom[2].data = abi.encode(DataDropdown("Token in", _tokens()));

        vdom[3].typeHash = TYPE_IN_DROPDOWN;
        vdom[3].data = abi.encode(DataDropdown("Token out", _tokens()));

        vdom[4].typeHash = TYPE_BUTTON;
        vdom[4].data = abi.encode(DataButton("Swap"));

        // for (uint256 i = 0; i < 10; i++) {
        //     IUniswapV2Pair pair = IUniswapV2Pair(uniFactory.allPairs(i));
        //     IERC20Meta t0 = IERC20Meta(pair.token0());
        //     IERC20Meta t1 = IERC20Meta(pair.token1());
        //     // pair.price0CumulativeLast();
        //     // pair.price1CumulativeLast();
        //     // pair.kLast();
        // }
    }

    function _tokens() public pure returns (DataDropOption[] memory ret) {
        ret = new DataDropOption[](3);

        ret[0] = DataDropOption(1, "ETH");
        ret[1] = DataDropOption(
            0x00f80a32a835f79d7787e8a8ee5721d0feafd78108,
            "DAI"
        );
        ret[2] = DataDropOption(
            0x00c778417e063141139fce010982780140aa0cd5ab,
            "WETH"
        );
    }

    function act(bytes calldata appState, Action calldata action)
        external
        returns (bytes memory newAppState)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

uint64 constant TYPE_TEXT = uint64(uint256(keccak256("text")));
uint64 constant TYPE_IN_AMOUNT = uint64(uint256(keccak256("amount")));
uint64 constant TYPE_IN_DROPDOWN = uint64(uint256(keccak256("dropdown")));
uint64 constant TYPE_IN_TEXTBOX = uint64(uint256(keccak256("textbox")));
uint64 constant TYPE_BUTTON = uint64(uint256(keccak256("button")));

struct VdomElem {
    /** @dev Text field, input, button, etc. */
    uint64 typeHash;
    /** @dev Text for a text field, options for a dropdown, etc. */
    bytes data;
}

struct DataAmount {
    string label;
    /** @dev Amount input will return fixed-point uint256 to n decimals. */
    uint64 decimals;
}

// 0000000000000000000000000000000000000000000000000000000000000020 // head (label)
// 0000000000000000000000000000000000000000000000000000000000000040 // ????
// 0000000000000000000000000000000000000000000000000000000000000012 // head (decimals) = 18
// 0000000000000000000000000000000000000000000000000000000000000009 // tail (label) string length
// 416d6f756e7420696e0000000000000000000000000000000000000000000000 // tail (label) string value

struct DataDropdown {
    string label;
    /** Options. User must pick one. */
    DataDropOption[] options;
}

struct DataDropOption {
    /** @dev Dropdown option ID */
    uint256 id;
    /** @dev Dropdown option display string */
    string display;
}

struct DataButton {
    string text;
}

struct Action {
    /** @dev 0 = first button, etc. */
    uint256 buttonId;
    /** @dev Value of each input.  */
    bytes[] inputs;
}

interface IFrontend {
    function render(bytes calldata appState)
        external
        view
        returns (VdomElem[] memory vdom);

    function act(bytes calldata appState, Action calldata action)
        external
        returns (bytes memory newAppState);
}

// SPDX-License-Identifier: GPLv3
pragma solidity >=0.8.0;

interface IERC20Meta {
    function symbol() external returns (string memory);

    function decimals() external returns (uint8);
}

interface IUniswapV2Factory {
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interface/IFrontend.sol";
import "./interface/IUniswap.sol";
import "./interface/VElem.sol";

IUniswapV2Factory constant uniFactory = IUniswapV2Factory(
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
);

contract UniswapFrontend is IFrontend {
    function render(bytes calldata appState)
        external
        pure
        override
        returns (VElem[] memory vdom)
    {
        require(appState.length == 0, "Unexpected state");

        vdom = new VElem[](5);
        vdom[0] = V.Text(1, "HELLO WORLD");
        vdom[1] = V.Amount(2, "Amount in", 18);
        vdom[2] = V.Dropdown(3, "Token in", _tokens());
        vdom[3] = V.Dropdown(3, "Token out", _tokens());
        vdom[4] = V.Button(5, "Swap");
    }

    function _tokens() public pure returns (DropOpt[] memory ret) {
        ret = new DropOpt[](3);
        ret[0] = DropOpt(1, "ETH");
        ret[1] = DropOpt(0x00f80a32a835f79d7787e8a8ee5721d0feafd78108, "DAI");
        ret[2] = DropOpt(0x00c778417e063141139fce010982780140aa0cd5ab, "WETH");
    }

    function act(bytes calldata appState, Action calldata action)
        external
        returns (bytes memory newAppState)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./VElem.sol";

interface IFrontend {
    function render(bytes calldata appState)
        external
        view
        returns (VElem[] memory vdom);

    function act(bytes calldata appState, Action calldata action)
        external
        returns (bytes memory newAppState);
}

struct Action {
    /** @dev Which button was pressed. */
    uint256 buttonKey;
    /** @dev ABI serialization of each input.  */
    bytes[] inputs;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

uint64 constant TYPE_TEXT = uint64(uint256(keccak256("text")));
uint64 constant TYPE_IN_AMOUNT = uint64(uint256(keccak256("amount")));
uint64 constant TYPE_IN_DROPDOWN = uint64(uint256(keccak256("dropdown")));
uint64 constant TYPE_IN_TEXTBOX = uint64(uint256(keccak256("textbox")));
uint64 constant TYPE_BUTTON = uint64(uint256(keccak256("button")));

struct VElem {
    /** @dev Text field, input, button, etc. */
    uint64 typeHash;
    /** @dev Text for a text field, dropdown options, etc. See ElemAmount etc.*/
    bytes data;
}

/** @dev Virtual DOM helper library. */
library V {
    function Text(uint256 key, string memory text)
        internal
        pure
        returns (VElem memory)
    {
        return VElem(TYPE_TEXT, abi.encode(ElemText(key, text)));
    }

    function Amount(
        uint256 key,
        string memory label,
        uint64 decimals
    ) internal pure returns (VElem memory) {
        return
            VElem(TYPE_IN_AMOUNT, abi.encode(ElemAmount(key, label, decimals)));
    }

    function Dropdown(
        uint256 key,
        string memory label,
        DropOpt[] memory options
    ) internal pure returns (VElem memory) {
        return
            VElem(
                TYPE_IN_DROPDOWN,
                abi.encode(ElemDropdown(key, label, options))
            );
    }

    function Button(uint256 key, string memory text)
        internal
        pure
        returns (VElem memory)
    {
        return VElem(TYPE_BUTTON, abi.encode(ElemButton(key, text)));
    }
}

struct ElemText {
    uint256 key;
    /** @dev UTF-8 text. Line breaks preserved. May auto-wrap at >=80chars. */
    string text;
}

struct ElemAmount {
    uint256 key;
    /** @dev Form input label */
    string label;
    /** @dev Amount input will return fixed-point uint256 to n decimals. */
    uint64 decimals;
}

struct ElemDropdown {
    uint256 key;
    /** @dev Form input label */
    string label;
    /** Options. User must pick one. */
    DropOpt[] options;
}

struct DropOpt {
    /** @dev Dropdown option ID */
    uint256 id;
    /** @dev Dropdown option display string */
    string display;
}

struct ElemButton {
    uint256 key;
    /** Button text */
    string text;
}
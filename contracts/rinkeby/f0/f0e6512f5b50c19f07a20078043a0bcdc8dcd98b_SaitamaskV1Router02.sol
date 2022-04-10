/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

interface ISaitamaskV1Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getExchange(address) external view returns (address);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function getFeeAddressSaitaEth() view external returns (address _feeAddressSaitaEth);
    function getFeeAddressSaitaXYZ() view external returns (address _feeAddressSaitaXYZ);
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

interface ISaitamaskV1Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquiditySaitamask(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETHSaitamask(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquiditySaitamask(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHSaitamask(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint reflectionMultiplier,
        uint reflectionDivider
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokensSaitamask(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    /* function swapTokensForExactTokensSaitamask(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts); */

    function swapExactETHForTokensSaitamask(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    /* function swapTokensForExactETHSaitamask(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts); */

    function swapExactTokensForETHSaitamask(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    /* function swapETHForExactTokensSaitamask(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts); */

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

library SaitamaskV1Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SaitamaskV1Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SaitamaskV1Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'306e1dabc7088c07dedf2dee961e69e646d3209d452ce0add86223ed8b49f28b' // init code hash
            ))));
    }
    
    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ISaitamaskV1Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'SaitamaskV1Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'SaitamaskV1Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint feeMultiplier) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'SaitamaskV1Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SaitamaskV1Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(feeMultiplier);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint feeMultiplier) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'SaitamaskV1Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SaitamaskV1Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(feeMultiplier);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path, uint feeMultiplier) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SaitamaskV1Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, feeMultiplier);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path, uint feeMultiplier) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SaitamaskV1Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, feeMultiplier);
        }
    }
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface ISaitamaskV1Pair {
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

    function mintSaitamask(address to) external returns (uint liquidity);
    function burnSaitamask(address to) external returns (uint amount0, uint amount1);
    function swapSaitamask(uint amount0Out, uint amount1Out, address to, bytes calldata data, uint feeMultiplier) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract SaitamaskV1Router02 is ISaitamaskV1Router02 {
    using SafeMath for uint;

    address public  immutable override factory;
    address public  immutable override WETH;
    address public  immutable SAITAMA;
    address public  owner;
    address private currentTxValidator;
    uint    private currentValidatorNumber;
    uint    private currentIntervalNumber;
    mapping (address => bool) private _isBot;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'SaitamaskV1Router: EXPIRED');
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    event SwapInfo(uint amount0Out, uint amount1Out, address to, bytes);
    event SwapExactTokens(address pathOut);

    constructor(address _factory, address _WETH, address _SAITAMA) public {
        owner = msg.sender;
        factory = _factory;
        WETH = _WETH;
        SAITAMA = _SAITAMA;
        currentIntervalNumber = 10;
        currentValidatorNumber = block.number;
    }
    
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (ISaitamaskV1Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            ISaitamaskV1Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = SaitamaskV1Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = SaitamaskV1Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'SaitamaskV1Router: INSUFFICIENT_B_AMOUNT');
                require(amountBDesired >= amountBMin, 'SaitamaskV1Router: INSUFFICIENT_AMOUNT_B_DESIRED');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SaitamaskV1Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'SaitamaskV1Router: INSUFFICIENT_A_AMOUNT');
                require(amountADesired >= amountAMin, 'SaitamaskV1Router: INSUFFICIENT_AMOUNT_A_DESIRED');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquiditySaitamask(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        require(!_isBot[msg.sender], 'SaitamaskV1: FORBIDDEN');
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = SaitamaskV1Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = ISaitamaskV1Pair(pair).mintSaitamask(to);
    }
    function addLiquidityETHSaitamask(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        require(!_isBot[msg.sender], 'SaitamaskV1: FORBIDDEN');
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = SaitamaskV1Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = ISaitamaskV1Pair(pair).mintSaitamask(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquiditySaitamask(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        require(!_isBot[msg.sender], 'SaitamaskV1: FORBIDDEN');
        address pair = SaitamaskV1Library.pairFor(factory, tokenA, tokenB);
        ISaitamaskV1Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = ISaitamaskV1Pair(pair).burnSaitamask(to);
        (address token0,) = SaitamaskV1Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'SaitamaskV1Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'SaitamaskV1Router: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETHSaitamask(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint reflectionMultiplier,
        uint reflectionDivider
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        require(!_isBot[msg.sender], 'SaitamaskV1: FORBIDDEN');
        (amountToken, amountETH) = removeLiquiditySaitamask(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        
        if (reflectionMultiplier != 0 && reflectionDivider != 0) {
            amountToken = amountToken - amountToken.div(reflectionDivider).mul(reflectionMultiplier);
            TransferHelper.safeTransfer(token, to, amountToken);
        } else {
            TransferHelper.safeTransfer(token, to, amountToken);
        }
        
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to, uint feeMultiplier) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SaitamaskV1Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? SaitamaskV1Library.pairFor(factory, output, path[i + 2]) : _to;
            ISaitamaskV1Pair(SaitamaskV1Library.pairFor(factory, input, output)).swapSaitamask(
                amount0Out, amount1Out, to, new bytes(0), feeMultiplier
            );
            emit SwapInfo(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function _getMultipliers(address[] memory path) internal view returns (uint feeMultiplier, uint swapFeeMultiplier) {
        feeMultiplier = 9975;
        swapFeeMultiplier = 25;
        if (path[0] == SAITAMA && path[1] == WETH || path[0] == WETH && path[1] == SAITAMA) {
            feeMultiplier = 9985;
            swapFeeMultiplier = 15;
        }
    }
    function swapExactTokensForTokensSaitamask(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(!_isBot[msg.sender], 'SaitamaskV1: FORBIDDEN');
        (uint feeMultiplier, uint swapFeeMultiplier) = _getMultipliers(path);
        uint amountFeeToTranfer = amountIn * swapFeeMultiplier / 10000;
        uint amountToSwapWithouFee = amountIn - amountFeeToTranfer;
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ISaitamaskV1Factory(factory).getFeeAddressSaitaXYZ(), amountFeeToTranfer
        );
        amounts = SaitamaskV1Library.getAmountsOut(factory, amountToSwapWithouFee, path, feeMultiplier);
        // amounts = SaitamaskV1Library.getAmountsOut(factory, amountIn, path, feeMultiplier);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SaitamaskV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SaitamaskV1Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to, swapFeeMultiplier);
        if (currentValidatorNumber < block.number - currentIntervalNumber) currentValidatorNumber = block.number;
        emit SwapExactTokens(path[path.length - 1]); 
    }
    /* function swapTokensForExactTokensSaitamask(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(!_isBot[msg.sender], 'SaitamaskV1: FORBIDDEN');
        (uint feeMultiplier, uint swapFeeMultiplier) = _getMultipliers(path);
        amounts = SaitamaskV1Library.getAmountsIn(factory, amountOut, path, feeMultiplier);
        uint amountFeeToTranfer = amounts[0] * swapFeeMultiplier / 10000;
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ISaitamaskV1Factory(factory).getFeeAddressSaitaXYZ(), amountFeeToTranfer
        );

        // amounts = SaitamaskV1Library.getAmountsIn(factory, amountOut, path, feeMultiplier);
        require(amounts[0] <= amountInMax, 'SaitamaskV1Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SaitamaskV1Library.pairFor(factory, path[0], path[1]), amounts[0] - amountFeeToTranfer
        );
        _swap(amounts, path, to, swapFeeMultiplier);
        if (currentValidatorNumber < block.number - currentIntervalNumber) currentValidatorNumber = block.number;
    } */
    
    function swapExactETHForTokensSaitamask(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(!_isBot[msg.sender], 'SaitamaskV1: FORBIDDEN');
        require(path[0] == WETH, 'SaitamaskV1Router: INVALID_PATH');
        (uint feeMultiplier, uint swapFeeMultiplier) = _getMultipliers(path);
        uint amountFeeToTranfer = msg.value * swapFeeMultiplier / 10000;
        uint amountToSwapWithouFee = msg.value - amountFeeToTranfer;
        payable(ISaitamaskV1Factory(factory).getFeeAddressSaitaEth()).transfer(amountFeeToTranfer);
        amounts = SaitamaskV1Library.getAmountsOut(factory, amountToSwapWithouFee, path, feeMultiplier);
        // amounts = SaitamaskV1Library.getAmountsOut(factory, msg.value, path, feeMultiplier);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SaitamaskV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(SaitamaskV1Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, swapFeeMultiplier);
        if (currentValidatorNumber < block.number - currentIntervalNumber) currentValidatorNumber = block.number;
    }
    /* function swapTokensForExactETHSaitamask(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(!_isBot[msg.sender], 'SaitamaskV1: FORBIDDEN');
        require(path[path.length - 1] == WETH, 'SaitamaskV1Router: INVALID_PATH');
        (uint feeMultiplier, uint swapFeeMultiplier) = _getMultipliers(path);
        uint amountFeeToTranfer = amountInMax * swapFeeMultiplier / 10000;
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ISaitamaskV1Factory(factory).getFeeAddressSaitaEth(), amountFeeToTranfer
        );
        amounts = SaitamaskV1Library.getAmountsIn(factory, amountOut, path, feeMultiplier);
        // amounts = SaitamaskV1Library.getAmountsIn(factory, amountOut, path, feeMultiplier);
        require(amounts[0] <= amountInMax, 'SaitamaskV1Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SaitamaskV1Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this), swapFeeMultiplier);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
        if (currentValidatorNumber < block.number - currentIntervalNumber) currentValidatorNumber = block.number;
    } */
    function swapExactTokensForETHSaitamask(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(!_isBot[msg.sender], 'SaitamaskV1: FORBIDDEN');
        require(path[path.length - 1] == WETH, 'SaitamaskV1Router: INVALID_PATH');
        (uint feeMultiplier, uint swapFeeMultiplier) = _getMultipliers(path);
        uint amountFeeToTranfer = amountIn * swapFeeMultiplier / 10000;
        uint amountToSwapWithouFee = amountIn - amountFeeToTranfer;
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, ISaitamaskV1Factory(factory).getFeeAddressSaitaEth(), amountFeeToTranfer
        );
        amounts = SaitamaskV1Library.getAmountsOut(factory, amountToSwapWithouFee, path, feeMultiplier);
        // amounts = SaitamaskV1Library.getAmountsOut(factory, amountIn, path, feeMultiplier);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SaitamaskV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SaitamaskV1Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this), swapFeeMultiplier);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
        if (currentValidatorNumber < block.number - currentIntervalNumber) currentValidatorNumber = block.number;
    }
    /* function swapETHForExactTokensSaitamask(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(!_isBot[msg.sender], 'SaitamaskV1: FORBIDDEN');
        require(path[0] == WETH, 'SaitamaskV1Router: INVALID_PATH');
        (uint feeMultiplier, uint swapFeeMultiplier) = _getMultipliers(path);
        uint amountFeeToTranfer = msg.value * swapFeeMultiplier / 10000;
        // uint amountToSwapWithouFee = amountOut - amountFeeToTranfer;
        payable(ISaitamaskV1Factory(factory).getFeeAddressSaitaEth()).transfer(amountFeeToTranfer);
        amounts = SaitamaskV1Library.getAmountsIn(factory, amountOut, path, feeMultiplier);
        // amounts = SaitamaskV1Library.getAmountsIn(factory, amountOut, path, feeMultiplier);
        require(amounts[0] <= msg.value, 'SaitamaskV1Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0] - amountFeeToTranfer}();
        assert(IWETH(WETH).transfer(SaitamaskV1Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to, swapFeeMultiplier);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0] - amountFeeToTranfer);
        if (currentValidatorNumber < block.number - 5) currentValidatorNumber = block.number;
    } */

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return SaitamaskV1Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return SaitamaskV1Library.getAmountOut(amountIn, reserveIn, reserveOut, 997);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, address[] memory path)
        public
        view
        virtual
        returns (uint amountIn)
    {
        (uint feeMultiplier, ) = _getMultipliers(path);
        return SaitamaskV1Library.getAmountIn(amountOut, reserveIn, reserveOut, feeMultiplier);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return SaitamaskV1Library.getAmountsOut(factory, amountIn, path, 997);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        (uint feeMultiplier, ) = _getMultipliers(path);
        return SaitamaskV1Library.getAmountsIn(factory, amountOut, path, feeMultiplier);
    }

    function setAntibot(address account, bool state) external onlyOwner {
        require(_isBot[account] != state, 'Value already set');
        _isBot[account] = state;
    }

    function setIntervalNumber(uint _newIntervalNumber) external onlyOwner returns(uint _currentIntervalNumber) {
        currentIntervalNumber = _newIntervalNumber;
        return currentIntervalNumber;
    }
    
    function isBot(address account) public view returns(bool) {
        return _isBot[account];
    }

    function getCurrentValidatorData() external view onlyOwner returns(uint _validatorNumber, uint _intervalNumber) {
        return (currentValidatorNumber, currentIntervalNumber);
    }

    function setTxValidator(address _newTxValidator) external onlyOwner returns(address _currentTxValidator) {
        require(currentTxValidator != _newTxValidator, 'Value already set');
        currentTxValidator = _newTxValidator;
        return currentTxValidator;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: No License (None)
pragma solidity >=0.6.6;

// helper methods for interacting with ERC223 tokens and sending CLO that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferCLO(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: CLO_TRANSFER_FAILED');
    }
}

interface ISoyFinanceFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface ISoyFinanceRouter01 {
    function factory() external pure returns (address);
    function WCLO() external pure returns (address);

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
    function addLiquidityCLO(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountCLOMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountCLO, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityCLO(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountCLOMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountCLO);
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
    function removeLiquidityCLOWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountCLOMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountCLO);
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
    function swapExactCLOForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactCLO(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForCLO(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapCLOForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface ISoyFinanceRouter02 is ISoyFinanceRouter01 {
    function removeLiquidityCLOSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountCLOMin,
        address to,
        uint deadline
    ) external returns (uint amountCLO);
    function removeLiquidityCLOWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountCLOMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountCLO);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactCLOForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForCLOSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ISoyFinancePair {
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
// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

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
}

library SoyFinanceLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SoyFinanceLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SoyFinanceLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e410ea0a25ce340e309f2f0fe9d58d787bb87dd63d02333e8a9a747230f61758' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        
        (uint reserve0, uint reserve1,) = ISoyFinancePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'SoyFinanceLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'SoyFinanceLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'SoyFinanceLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SoyFinanceLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'SoyFinanceLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SoyFinanceLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SoyFinanceLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SoyFinanceLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface IERC223 {
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

interface IWCLO {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract SoyFinanceRouter is ISoyFinanceRouter02 {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WCLO;
    mapping(address => mapping(address => uint)) public balanceERC223;    // user => token => value
    address public msgSender;   // ERC223 sender
    address public tokenAddress; // ERC223 token address
    event Swap(address _sender, address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOut);
    event AddLiquidity(address _sender, address _tokenA, address _tokenB, uint _amountA, uint _amountB);
    event RemoveLiquidity(address _sender, address _tokenA, address _tokenB, uint _amountA, uint _amountB);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'SoyFinanceRouter: EXPIRED');
        _;
    }

    modifier noERC223() {
        require(msg.sender != address(this), "ERC223 not accepted");
        _;
    }

    constructor(address _factory, address _WCLO) public {
        factory = _factory;
        WCLO = _WCLO;
    }

    function tokenReceived(address _from, uint _value, bytes calldata _data) external {
        balanceERC223[_from][msg.sender] = balanceERC223[_from][msg.sender] + _value;   // add token to user balance
        if (_data.length >= 36) { // signature + at least 1 parameter
            msgSender = _from;
            tokenAddress = msg.sender;
            (bool success,) = address(this).call{value:0}(_data);
            require(success, "ERC223 internal call failed");
        }
    }

    // allow user to withdraw transferred ERC223 tokens
    function withdraw(address token, uint amount) external {
        uint userBalance = balanceERC223[msg.sender][token];
        require(userBalance >= amount, "Not enough tokens");
        balanceERC223[msg.sender][token] = userBalance - amount;
        TransferHelper.safeTransfer(token, msg.sender, amount);
    }

    function transferTo(address token, address to, uint amount) internal {
        address sender = msg.sender;
        if (msg.sender == address(this)) {
            require(token == tokenAddress, "Transfer wrong token");
            sender = msgSender;
        }
        uint balance = balanceERC223[sender][token];
        if (balance >= amount) { // ERC223 tokens were transferred 
            uint rest;
            if (balance > amount) rest = balance - amount;
            balanceERC223[sender][token] = 0;
            if (rest != 0) TransferHelper.safeTransfer(token, sender, rest); // refund rest of tokens to sender
            TransferHelper.safeTransfer(token, to, amount);
        } else if (msg.sender != address(this)) {   // not ERC223 callback
            TransferHelper.safeTransferFrom(token, msg.sender, to, amount);
        } else {
            revert("Not enough ERC223 balance");
        }
    }

    receive() external payable {
        assert(msg.sender == WCLO); // only accept CLO via fallback from the WCLO contract
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
        if (ISoyFinanceFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ISoyFinanceFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = SoyFinanceLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = SoyFinanceLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'SoyFinanceRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SoyFinanceLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'SoyFinanceRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
        emit AddLiquidity(tx.origin, tokenA, tokenB, amountA, amountB);
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) noERC223 returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = SoyFinanceLibrary.pairFor(factory, tokenA, tokenB);
        transferTo(tokenA, pair, amountA);
        transferTo(tokenB, pair, amountB);
        liquidity = ISoyFinancePair(pair).mint(to);
    }
    function addLiquidityCLO(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountCLOMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) noERC223 returns (uint amountToken, uint amountCLO, uint liquidity) {
        (amountToken, amountCLO) = _addLiquidity(
            token,
            WCLO,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountCLOMin
        );
        address pair = SoyFinanceLibrary.pairFor(factory, token, WCLO);
        transferTo(token, pair, amountToken);
        IWCLO(WCLO).deposit{value: amountCLO}();
        assert(IWCLO(WCLO).transfer(pair, amountCLO));
        liquidity = ISoyFinancePair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountCLO) TransferHelper.safeTransferCLO(msg.sender, msg.value - amountCLO);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = SoyFinanceLibrary.pairFor(factory, tokenA, tokenB);
        transferTo(pair, pair, liquidity); // send liquidity to pair
        //ISoyFinancePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = ISoyFinancePair(pair).burn(to);
        (address token0,) = SoyFinanceLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'SoyFinanceRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'SoyFinanceRouter: INSUFFICIENT_B_AMOUNT');
        emit RemoveLiquidity(tx.origin, tokenA, tokenB, amountA, amountB);
    }
    function removeLiquidityCLO(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountCLOMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountCLO) {
        (amountToken, amountCLO) = removeLiquidity(
            token,
            WCLO,
            liquidity,
            amountTokenMin,
            amountCLOMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWCLO(WCLO).withdraw(amountCLO);
        TransferHelper.safeTransferCLO(to, amountCLO);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override noERC223 returns (uint amountA, uint amountB) {
        address pair = SoyFinanceLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        ISoyFinancePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityCLOWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountCLOMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override noERC223 returns (uint amountToken, uint amountCLO) {
        address pair = SoyFinanceLibrary.pairFor(factory, token, WCLO);
        uint value = approveMax ? uint(-1) : liquidity;
        ISoyFinancePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountCLO) = removeLiquidityCLO(token, liquidity, amountTokenMin, amountCLOMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityCLOSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountCLOMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountCLO) {
        (, amountCLO) = removeLiquidity(
            token,
            WCLO,
            liquidity,
            amountTokenMin,
            amountCLOMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC223(token).balanceOf(address(this)));
        IWCLO(WCLO).withdraw(amountCLO);
        TransferHelper.safeTransferCLO(to, amountCLO);
    }
    function removeLiquidityCLOWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountCLOMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override noERC223 returns (uint amountCLO) {
        address pair = SoyFinanceLibrary.pairFor(factory, token, WCLO);
        uint value = approveMax ? uint(-1) : liquidity;
        ISoyFinancePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountCLO = removeLiquidityCLOSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountCLOMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SoyFinanceLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? SoyFinanceLibrary.pairFor(factory, output, path[i + 2]) : _to;
            ISoyFinancePair(SoyFinanceLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
        emit Swap(tx.origin, path[0], path[path.length - 1], amounts[0], amounts[amounts.length - 1]);
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = SoyFinanceLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SoyFinanceRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        transferTo(
            path[0], SoyFinanceLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = SoyFinanceLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'SoyFinanceRouter: EXCESSIVE_INPUT_AMOUNT');
        transferTo(
            path[0], SoyFinanceLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactCLOForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        noERC223
        returns (uint[] memory amounts)
    {
        require(path[0] == WCLO, 'SoyFinanceRouter: INVALID_PATH');
        amounts = SoyFinanceLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SoyFinanceRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWCLO(WCLO).deposit{value: amounts[0]}();
        assert(IWCLO(WCLO).transfer(SoyFinanceLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactCLO(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WCLO, 'SoyFinanceRouter: INVALID_PATH');
        amounts = SoyFinanceLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'SoyFinanceRouter: EXCESSIVE_INPUT_AMOUNT');
        transferTo(
            path[0], SoyFinanceLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWCLO(WCLO).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferCLO(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForCLO(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WCLO, 'SoyFinanceRouter: INVALID_PATH');
        amounts = SoyFinanceLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SoyFinanceRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        transferTo(
            path[0], SoyFinanceLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWCLO(WCLO).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferCLO(to, amounts[amounts.length - 1]);
    }
    function swapCLOForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        noERC223
        returns (uint[] memory amounts)
    {
        require(path[0] == WCLO, 'SoyFinanceRouter: INVALID_PATH');
        amounts = SoyFinanceLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'SoyFinanceRouter: EXCESSIVE_INPUT_AMOUNT');
        IWCLO(WCLO).deposit{value: amounts[0]}();
        assert(IWCLO(WCLO).transfer(SoyFinanceLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferCLO(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SoyFinanceLibrary.sortTokens(input, output);
            ISoyFinancePair pair = ISoyFinancePair(SoyFinanceLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC223(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = SoyFinanceLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? SoyFinanceLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        require(path.length > 1, 'SoyFinanceRouter: INVALID_PATH');        
        transferTo(
            path[0], SoyFinanceLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC223(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        uint amountOut = IERC223(path[path.length - 1]).balanceOf(to).sub(balanceBefore);
        require(
            amountOut >= amountOutMin,
            'SoyFinanceRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );        
        emit Swap(tx.origin, path[0], path[path.length - 1], amountIn, amountOut);
    }
    function swapExactCLOForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
        noERC223
    {
        require(path.length > 1, 'SoyFinanceRouter: INVALID_PATH');        
        require(path[0] == WCLO, 'SoyFinanceRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWCLO(WCLO).deposit{value: amountIn}();
        assert(IWCLO(WCLO).transfer(SoyFinanceLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC223(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        uint amountOut = IERC223(path[path.length - 1]).balanceOf(to).sub(balanceBefore);
        require(
            amountOut >= amountOutMin,
            'SoyFinanceRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
        emit Swap(tx.origin, path[0], path[path.length - 1], amountIn, amountOut);
    }
    function swapExactTokensForCLOSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path.length > 1, 'SoyFinanceRouter: INVALID_PATH');        
        require(path[path.length - 1] == WCLO, 'SoyFinanceRouter: INVALID_PATH');
        transferTo(
            path[0], SoyFinanceLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC223(WCLO).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'SoyFinanceRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWCLO(WCLO).withdraw(amountOut);
        TransferHelper.safeTransferCLO(to, amountOut);
        emit Swap(tx.origin, path[0], path[path.length - 1], amountIn, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return SoyFinanceLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return SoyFinanceLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return SoyFinanceLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return SoyFinanceLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return SoyFinanceLibrary.getAmountsIn(factory, amountOut, path);
    }

    // Rescue ERC20 tokens
    function rescueERC20(address _token, uint256 _value) external {
        require(msg.sender == ISoyFinanceFactory(factory).feeToSetter(), 'SoyFinance: FORBIDDEN');
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        _token.call(abi.encodeWithSelector(0xa9059cbb, msg.sender, _value));
    }
}
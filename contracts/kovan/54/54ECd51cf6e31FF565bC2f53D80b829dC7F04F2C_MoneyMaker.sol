// SPDX-License-Identifier: MIT

// P1 - P3: OK
pragma solidity 0.6.12;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

import "./traderjoe/interfaces/IERC20.sol";
import "./traderjoe/interfaces/IJoePair.sol";
import "./traderjoe/interfaces/IJoeFactory.sol";
import "./traderjoe/libraries/JoeLibrary.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

/// @title Money Maker
/// @author Trader Joe
/// @notice MoneyMaker receives 0.05% of the swaps done on Trader Joe in the form of an LP. It swaps those LPs
/// to a token of choice and sends it to the JoeBar
contract MoneyMaker is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IJoeFactory public immutable factory;

    address public immutable bar;
    address private immutable wavax;
    /// @notice Any ERC20
    address public tokenTo;
    /// @notice In basis points aka parts per 10,000 so 5000 is 50%, cap of 50%, default is 0
    uint256 public devCut = 0;
    address public devAddr;

    // @notice Set of addresses that can perform certain functions
    EnumerableSet.AddressSet private _isAuth;

    modifier onlyAuth() {
        require(_isAuth.contains(_msgSender()), "MoneyMaker: FORBIDDEN");
        _;
    }

    /// @dev Maps a token `token` to another token `bridge` so that it uses `token/bridge` pair to convert token
    mapping(address => address) internal _bridges;

    event AddAuthorizedAddress(address indexed _addr);
    event RemoveAuthorizedAddress(address indexed _addr);
    event SetDevAddr(address _addr);
    event SetDevCut(uint256 _amount);
    event SetTokenTo(address _tokenTo);
    event LogBridgeSet(address indexed token, address indexed oldBridge, address indexed bridge);
    event LogConvert(
        address indexed server,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 amountTOKEN
    );

    /// @notice Constructor
    /// @param _factory The address of JoeFactory
    /// @param _bar The address of JoeBar
    /// @param _tokenTo The address of the token we want to convert to
    /// @param _wavax The address of wavax
    constructor(
        address _factory,
        address _bar,
        address _tokenTo,
        address _wavax
    ) public {
        require(_factory != address(0), "MoneyMaker: factory can't be address(0)");
        require(_bar != address(0), "MoneyMaker: bar can't be address(0)");
        require(_tokenTo != address(0), "MoneyMaker: token can't be address(0)");
        require(_wavax != address(0), "MoneyMaker: wavax can't be address(0)");
        factory = IJoeFactory(_factory);
        bar = _bar;
        tokenTo = _tokenTo;
        wavax = _wavax;
        devAddr = _msgSender();
        _isAuth.add(_msgSender());
    }

    /// @notice Adds a user to the authorized addresses
    /// @param _auth The address to add
    function addAuth(address _auth) external onlyOwner {
        require(_isAuth.add(_auth), "MoneyMaker: Address is already authorized");
        emit AddAuthorizedAddress(_auth);
    }

    /// @notice Remove a user of authorized addresses
    /// @param _auth The address to remove
    function removeAuth(address _auth) external onlyOwner {
        require(_isAuth.remove(_auth), "MoneyMaker: Address is not authorized");
        emit RemoveAuthorizedAddress(_auth);
    }

    /// @notice Return the list of authorized addresses
    /// @param index Index of the returned address
    /// @return The authorized address at `index`
    function getAuth(uint256 index) external view returns (address) {
        return _isAuth.at(index);
    }

    /// @notice Return the length of authorized addresses
    /// @return The number of authorized addresses
    function lenAuth() external view returns (uint256) {
        return _isAuth.length();
    }

    /// @notice Force using `pair/bridge` pair to convert `token`
    /// @param token The address of the tokenFrom
    /// @param bridge The address of the tokenTo
    function setBridge(address token, address bridge) external onlyAuth {
        // Checks
        require(token != tokenTo && token != wavax && token != bridge, "MoneyMaker: Invalid bridge");

        // Effects
        address oldBridge = _bridges[token];
        _bridges[token] = bridge;
        emit LogBridgeSet(token, oldBridge, bridge);
    }

    /// @notice Sets dev cut, which will be sent to `devAddr`, can't be greater than 50%
    /// @param _amount The new devCut value
    function setDevCut(uint256 _amount) external onlyOwner {
        require(_amount <= 5000, "setDevCut: cut too high");
        devCut = _amount;

        emit SetDevCut(_amount);
    }

    /// @notice Sets `devAddr`, the address that will receive the `devCut`
    /// @param _addr The new dev address
    function setDevAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "setDevAddr, address cannot be zero address");
        devAddr = _addr;

        emit SetDevAddr(_addr);
    }

    /// @notice Sets token that we're buying back
    /// @param _tokenTo The new token address
    function setTokenToAddress(address _tokenTo) external onlyOwner {
        require(_tokenTo != address(0), "setTokenToAddress, address cannot be zero address");
        tokenTo = _tokenTo;

        emit SetTokenTo(_tokenTo);
    }

    /// @notice Returns the `bridge` of a `token`
    /// @param token The tokenFrom address
    /// @return bridge The tokenTo address
    function bridgeFor(address token) public view returns (address bridge) {
        bridge = _bridges[token];
        if (bridge == address(0)) {
            bridge = wavax;
        }
    }

    // C6: It's not a fool proof solution, but it prevents flash loans, so here it's ok to use tx.origin
    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(_msgSender() == tx.origin, "MoneyMaker: must use EOA");
        _;
    }

    /// @notice Converts a pair of tokens to tokenTo
    /// @dev _convert is separate to save gas by only checking the 'onlyEOA' modifier once in case of convertMultiple
    /// @param token0 The address of the first token of the pair that will be converted
    /// @param token1 The address of the second token of the pair that will be converted
    /// @param slippage The accepted slippage, in basis points aka parts per 10,000 so 5000 is 50%
    function convert(
        address token0,
        address token1,
        uint256 slippage
    ) external onlyEOA onlyAuth {
        require(slippage < 5_000, "MoneyMaker: slippage needs to be lower than 50%");
        _convert(token0, token1, slippage);
    }

    /// @notice Converts a list of pairs of tokens to tokenTo
    /// @dev _convert is separate to save gas by only checking the 'onlyEOA' modifier once in case of convertMultiple
    /// @param token0 The list of addresses of the first token of the pairs that will be converted
    /// @param token1 The list of addresses of the second token of the pairs that will be converted
    /// @param slippage The accepted slippage, in basis points aka parts per 10,000 so 5000 is 50%
    function convertMultiple(
        address[] calldata token0,
        address[] calldata token1,
        uint256 slippage
    ) external onlyEOA onlyAuth {
        // TODO: This can be optimized a fair bit, but this is safer and simpler for now
        require(slippage < 5_000, "MoneyMaker: slippage needs to be lower than 50%");
        require(token0.length == token1.length, "MoneyMaker: arrays length don't match");

        uint256 len = token0.length;
        for (uint256 i = 0; i < len; i++) {
            _convert(token0[i], token1[i], slippage);
        }
    }

    /// @notice Converts a pair of tokens to tokenTo
    /// @dev _convert is separate to save gas by only checking the 'onlyEOA' modifier once in case of convertMultiple
    /// @param token0 The address of the first token of the pair that is currently being converted
    /// @param token1 The address of the second token of the pair that is currently being converted
    /// @param slippage The accepted slippage, in basis points aka parts per 10,000 so 5000 is 50%
    function _convert(
        address token0,
        address token1,
        uint256 slippage
    ) internal {
        uint256 amount0;
        uint256 amount1;

        // handle case where non-LP tokens need to be converted
        if (token0 == token1) {
            amount0 = IERC20(token0).balanceOf(address(this));
            amount1 = 0;
        } else {
            IJoePair pair = IJoePair(factory.getPair(token0, token1));
            require(address(pair) != address(0), "MoneyMaker: Invalid pair");

            IERC20(address(pair)).safeTransfer(address(pair), pair.balanceOf(address(this)));

            // take balance of tokens in this contract before burning the pair, incase there are already some here
            uint256 tok0bal = IERC20(token0).balanceOf(address(this));
            uint256 tok1bal = IERC20(token1).balanceOf(address(this));

            pair.burn(address(this));

            // subtract old balance of tokens from new balance
            // the return values of pair.burn cant be trusted due to transfer tax tokens
            amount0 = IERC20(token0).balanceOf(address(this)).sub(tok0bal);
            amount1 = IERC20(token1).balanceOf(address(this)).sub(tok1bal);
        }
        emit LogConvert(
            _msgSender(),
            token0,
            token1,
            amount0,
            amount1,
            _convertStep(token0, token1, amount0, amount1, slippage)
        );
    }

    /// @notice Used to convert two tokens to `tokenTo`, step by step, called recursively
    /// @param token0 The address of the first token
    /// @param token1 The address of the second token
    /// @param amount0 The amount of the `token0`
    /// @param amount1 The amount of the `token1`
    /// @param slippage The accepted slippage, in basis points aka parts per 10,000 so 5000 is 50%
    /// @return tokenOut The amount of token
    function _convertStep(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint256 slippage
    ) internal returns (uint256 tokenOut) {
        // Interactions
        if (token0 == token1) {
            uint256 amount = amount0.add(amount1);
            if (token0 == tokenTo) {
                IERC20(tokenTo).safeTransfer(bar, amount);
                tokenOut = amount;
            } else if (token0 == wavax) {
                tokenOut = _toToken(wavax, amount, slippage);
            } else {
                address bridge = bridgeFor(token0);
                amount = _swap(token0, bridge, amount, address(this), slippage);
                tokenOut = _convertStep(bridge, bridge, amount, 0, slippage);
            }
        } else if (token0 == tokenTo) {
            // eg. TOKEN - AVAX
            IERC20(tokenTo).safeTransfer(bar, amount0);
            tokenOut = _toToken(token1, amount1, slippage).add(amount0);
        } else if (token1 == tokenTo) {
            // eg. USDT - TOKEN
            IERC20(tokenTo).safeTransfer(bar, amount1);
            tokenOut = _toToken(token0, amount0, slippage).add(amount1);
        } else if (token0 == wavax) {
            // eg. AVAX - USDC
            tokenOut = _toToken(wavax, _swap(token1, wavax, amount1, address(this), slippage).add(amount0), slippage);
        } else if (token1 == wavax) {
            // eg. USDT - AVAX
            tokenOut = _toToken(wavax, _swap(token0, wavax, amount0, address(this), slippage).add(amount1), slippage);
        } else {
            // eg. MIC - USDT
            address bridge0 = bridgeFor(token0);
            address bridge1 = bridgeFor(token1);
            if (bridge0 == token1) {
                // eg. MIC - USDT - and bridgeFor(MIC) = USDT
                tokenOut = _convertStep(
                    bridge0,
                    token1,
                    _swap(token0, bridge0, amount0, address(this), slippage),
                    amount1,
                    slippage
                );
            } else if (bridge1 == token0) {
                // eg. WBTC - DSD - and bridgeFor(DSD) = WBTC
                tokenOut = _convertStep(
                    token0,
                    bridge1,
                    amount0,
                    _swap(token1, bridge1, amount1, address(this), slippage),
                    slippage
                );
            } else {
                tokenOut = _convertStep(
                    bridge0,
                    bridge1, // eg. USDT - DSD - and bridgeFor(DSD) = WBTC
                    _swap(token0, bridge0, amount0, address(this), slippage),
                    _swap(token1, bridge1, amount1, address(this), slippage),
                    slippage
                );
            }
        }
    }

    /// @notice Swaps `amountIn` `fromToken` to `toToken` and sends it to `to`, `amountOut` is required to be greater
    /// than allowed `slippage`
    /// @param fromToken The address of token that will be swapped
    /// @param toToken The address of the token that will be received
    /// @param amountIn The amount of the `fromToken`
    /// @param to The address that will receive the `toToken`
    /// @param slippage The accepted slippage, in basis points aka parts per 10,000 so 5000 is 50%
    /// @return amountOut The amount of `toToken` sent to `to`
    function _swap(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to,
        uint256 slippage
    ) internal returns (uint256 amountOut) {
        // Checks
        // X1 - X5: OK
        IJoePair pair = IJoePair(factory.getPair(fromToken, toToken));
        require(address(pair) != address(0), "MoneyMaker: Cannot convert");

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = fromToken == pair.token0()
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        IERC20(fromToken).safeTransfer(address(pair), amountIn);
        uint256 amountInput = IERC20(fromToken).balanceOf(address(pair)).sub(reserveInput); // calculate amount that was transferred, this accounts for transfer taxes

        amountOut = JoeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);

        {
            uint256 rest = uint256(10_000).sub(slippage);
            /// @dev We simulate the amount received if we did a swapIn and swapOut without updating the reserves,
            /// hence why we do rest^2, i.e. calculating the slippage twice cause we actually do two swaps.
            /// This allows us to catch if a pair has low liquidity
            require(
                JoeLibrary.getAmountOut(amountOut, reserveOutput, reserveInput) >=
                    amountInput.mul(rest).mul(rest).div(100_000_000),
                "MoneyMaker: Slippage caught"
            );
        }

        (uint256 amount0Out, uint256 amount1Out) = fromToken == pair.token0()
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));
        pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }

    /// @notice Swaps an amount of token to another token, `tokenTo`
    /// @dev `amountOut` is required to be greater after slippage
    /// @param token The address of token that will be swapped
    /// @param amountIn The amount of the `token`
    /// @param slippage The accepted slippage, in basis points aka parts per 10,000 so 5000 is 50%
    /// @return amountOut The amount of `toToken` sent to JoeBar
    function _toToken(
        address token,
        uint256 amountIn,
        uint256 slippage
    ) internal returns (uint256 amountOut) {
        uint256 amount = amountIn;
        if (devCut > 0) {
            amount = amount.mul(devCut).div(10000);
            IERC20(token).safeTransfer(devAddr, amount);
            amount = amountIn.sub(amount);
        }
        amountOut = _swap(token, tokenTo, amount, bar, slippage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "SafeMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "SafeMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "SafeMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "SafeMath: Div by Zero");
        c = a / b;
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "SafeMath: uint128 Overflow");
        c = uint128(a);
    }
}

library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "SafeMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "SafeMath: Underflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Joe {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

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
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
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

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "../interfaces/IJoePair.sol";

import "./SafeMath.sol";

library JoeLibrary {
    using SafeMathJoe for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "JoeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "JoeLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"c75c055d63695d2e56146ca9d3bfc0ae15821caf293079c6d96cc8adece8002c" // init code kovan
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IJoePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "JoeLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "JoeLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "JoeLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "JoeLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "JoeLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "JoeLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "JoeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "JoeLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathJoe {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
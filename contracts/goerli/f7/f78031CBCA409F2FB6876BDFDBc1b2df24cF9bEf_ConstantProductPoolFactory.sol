// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import {PoolDeployer} from "../../abstract/PoolDeployer.sol";
import {ConstantProductPool} from "./ConstantProductPool.sol";
import {IConstantProductPoolFactory} from "../../interfaces/IConstantProductPoolFactory.sol";
import {IMasterDeployer} from "../../interfaces/IMasterDeployer.sol";

/// @notice Contract for deploying Trident exchange Constant Product Pool with configurations.
/// @author Mudit Gupta.
contract ConstantProductPoolFactory is IConstantProductPoolFactory, PoolDeployer {
    bytes32 public constant bytecodeHash = keccak256(type(ConstantProductPool).creationCode);

    bytes private cachedDeployData;

    constructor(address _masterDeployer) PoolDeployer(_masterDeployer) {}

    function deployPool(bytes memory _deployData) external returns (address pool) {
        (address tokenA, address tokenB, uint256 swapFee, bool twapSupport) = abi.decode(_deployData, (address, address, uint256, bool));

        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }

        // Strips any extra data.
        _deployData = abi.encode(tokenA, tokenB, swapFee, twapSupport);

        address[] memory tokens = new address[](2);
        tokens[0] = tokenA;
        tokens[1] = tokenB;

        bytes32 salt = keccak256(_deployData);

        cachedDeployData = _deployData;

        pool = address(new ConstantProductPool{salt: salt}());

        cachedDeployData = "";

        _registerPool(pool, tokens, salt);
    }

    // This called in the ConstantProductPool constructor.
    function getDeployData() external view override returns (bytes memory, IMasterDeployer) {
        return (cachedDeployData, IMasterDeployer(masterDeployer));
    }

    function calculatePoolAddress(
        address token0,
        address token1,
        uint256 swapFee,
        bool twapSupport
    ) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(token0, token1, swapFee, twapSupport));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash));
        return address(uint160(uint256(hash)));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later-only

pragma solidity >=0.8.0;

/// @dev Custom Errors
error UnauthorisedDeployer();
error ZeroAddress();
error InvalidTokenOrder();

/// @notice Trident pool deployer for whitelisted template factories.
/// @author Mudit Gupta.
abstract contract PoolDeployer {
    address public immutable masterDeployer;

    mapping(address => mapping(address => address[])) public pools;
    mapping(bytes32 => address) public configAddress;

    modifier onlyMaster() {
        if (msg.sender != masterDeployer) revert UnauthorisedDeployer();
        _;
    }

    constructor(address _masterDeployer) {
        if (_masterDeployer == address(0)) revert ZeroAddress();
        masterDeployer = _masterDeployer;
    }

    function _registerPool(
        address pool,
        address[] memory tokens,
        bytes32 salt
    ) internal onlyMaster {
        // Store the address of the deployed contract.
        configAddress[salt] = pool;
        // Attacker used underflow, it was not very effective. poolimon!
        // null token array would cause deployment to fail via out of bounds memory axis/gas limit.
        unchecked {
            for (uint256 i; i < tokens.length - 1; ++i) {
                if (tokens[i] >= tokens[i + 1]) revert InvalidTokenOrder();
                for (uint256 j = i + 1; j < tokens.length; ++j) {
                    pools[tokens[i]][tokens[j]].push(pool);
                    pools[tokens[j]][tokens[i]].push(pool);
                }
            }
        }
    }

    function poolsCount(address token0, address token1) external view returns (uint256 count) {
        count = pools[token0][token1].length;
    }

    function getPools(
        address token0,
        address token1,
        uint256 startIndex,
        uint256 count
    ) external view returns (address[] memory pairPools) {
        pairPools = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            pairPools[i] = pools[token0][token1][startIndex + i];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";

import {IBentoBoxMinimal} from "../../interfaces/IBentoBoxMinimal.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {ITridentCallee} from "../../interfaces/ITridentCallee.sol";
import {IConstantProductPoolFactory} from "../../interfaces/IConstantProductPoolFactory.sol";
import {IMasterDeployer} from "../../interfaces/IMasterDeployer.sol";

import {TridentMath} from "../../libraries/TridentMath.sol";

/// @dev Custom Errors
error ZeroAddress();
error IdenticalAddress();
error InvalidSwapFee();
error InvalidAmounts();
error InsufficientLiquidityMinted();
error InvalidOutputToken();
error InvalidInputToken();
error PoolUninitialized();
error InsufficientAmountIn();
error Overflow();

/// @notice Trident exchange pool template with constant product formula for swapping between an ERC-20 token pair.
/// @dev The reserves are stored as bento shares.
///      The curve is applied to shares as well. This pool does not care about the underlying amounts.
contract ConstantProductPool is IPool, ERC20, ReentrancyGuard {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed recipient);
    event Sync(uint256 reserve0, uint256 reserve1);

    uint256 internal constant MINIMUM_LIQUIDITY = 1000;

    uint8 internal constant PRECISION = 112;
    uint256 internal constant MAX_FEE = 10000; // @dev 100%.
    uint256 public immutable swapFee;
    uint256 internal immutable MAX_FEE_MINUS_SWAP_FEE;

    IBentoBoxMinimal public immutable bento;
    IMasterDeployer public immutable masterDeployer;
    address public immutable token0;
    address public immutable token1;

    uint256 public barFee;
    address public barFeeTo;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast;

    uint112 internal reserve0;
    uint112 internal reserve1;
    uint32 internal blockTimestampLast;

    bytes32 public constant override poolIdentifier = "Trident:ConstantProduct";

    constructor() ERC20("Sushi Constant Product LP Token", "SCPLP", 18) {
        (bytes memory _deployData, IMasterDeployer _masterDeployer) = IConstantProductPoolFactory(msg.sender).getDeployData();

        (address _token0, address _token1, uint256 _swapFee, bool _twapSupport) = abi.decode(
            _deployData,
            (address, address, uint256, bool)
        );

        // Factory ensures that the tokens are sorted.
        if (_token0 == address(0)) revert ZeroAddress();
        if (_token0 == _token1) revert IdenticalAddress();
        if (_swapFee > MAX_FEE) revert InvalidSwapFee();

        token0 = _token0;
        token1 = _token1;
        swapFee = _swapFee;
        // This is safe from underflow - `swapFee` cannot exceed `MAX_FEE` per previous check.
        unchecked {
            MAX_FEE_MINUS_SWAP_FEE = MAX_FEE - _swapFee;
        }
        barFee = _masterDeployer.barFee();
        barFeeTo = _masterDeployer.barFeeTo();
        bento = IBentoBoxMinimal(_masterDeployer.bento());
        masterDeployer = _masterDeployer;
        if (_twapSupport) blockTimestampLast = uint32(block.timestamp);
    }

    /// @dev Mints LP tokens - should be called via the router after transferring `bento` tokens.
    /// The router must ensure that sufficient LP tokens are minted by using the return value.
    function mint(bytes calldata data) public override nonReentrant returns (uint256 liquidity) {
        address recipient = abi.decode(data, (address));
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();

        uint256 computed = TridentMath.sqrt(balance0 * balance1);
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        (uint256 fee0, uint256 fee1) = _nonOptimalMintFee(amount0, amount1, _reserve0, _reserve1);
        _reserve0 += uint112(fee0);
        _reserve1 += uint112(fee1);

        (uint256 _totalSupply, uint256 k) = _mintFee(_reserve0, _reserve1);

        if (_totalSupply == 0) {
            if (amount0 == 0 || amount1 == 0) revert InvalidAmounts();
            liquidity = computed - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            uint256 kIncrease;
            unchecked {
                kIncrease = computed - k;
            }
            liquidity = (kIncrease * _totalSupply) / k;
        }
        if (liquidity == 0) revert InsufficientLiquidityMinted();
        _mint(recipient, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
        kLast = computed;
        emit Mint(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Burns LP tokens sent to this contract. The router must ensure that the user gets sufficient output tokens.
    function burn(bytes calldata data) public override nonReentrant returns (IPool.TokenAmount[] memory withdrawnAmounts) {
        (address recipient, bool unwrapBento) = abi.decode(data, (address, bool));
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 liquidity = balanceOf[address(this)];

        (uint256 _totalSupply, ) = _mintFee(_reserve0, _reserve1);

        uint256 amount0 = (liquidity * balance0) / _totalSupply;
        uint256 amount1 = (liquidity * balance1) / _totalSupply;

        _burn(address(this), liquidity);
        _transfer(token0, amount0, recipient, unwrapBento);
        _transfer(token1, amount1, recipient, unwrapBento);
        // This is safe from underflow - amounts are lesser figures derived from balances.
        unchecked {
            balance0 -= amount0;
            balance1 -= amount1;
        }
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
        kLast = TridentMath.sqrt(balance0 * balance1);

        withdrawnAmounts = new TokenAmount[](2);
        withdrawnAmounts[0] = TokenAmount({token: address(token0), amount: amount0});
        withdrawnAmounts[1] = TokenAmount({token: address(token1), amount: amount1});
        emit Burn(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Burns LP tokens sent to this contract and swaps one of the output tokens for another
    /// - i.e., the user gets a single token out by burning LP tokens.
    function burnSingle(bytes calldata data) public override nonReentrant returns (uint256 amountOut) {
        (address tokenOut, address recipient, bool unwrapBento) = abi.decode(data, (address, address, bool));
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        uint256 liquidity = balanceOf[address(this)];

        (uint256 _totalSupply, ) = _mintFee(_reserve0, _reserve1);

        uint256 amount0 = (liquidity * _reserve0) / _totalSupply;
        uint256 amount1 = (liquidity * _reserve1) / _totalSupply;

        kLast = TridentMath.sqrt((_reserve0 - amount0) * (_reserve1 - amount1));

        _burn(address(this), liquidity);

        // Swap one token for another
        unchecked {
            if (tokenOut == token1) {
                // Swap `token0` for `token1`
                // - calculate `amountOut` as if the user first withdrew balanced liquidity and then swapped `token0` for `token1`.
                amount1 += _getAmountOut(amount0, _reserve0 - amount0, _reserve1 - amount1);
                _transfer(token1, amount1, recipient, unwrapBento);
                amountOut = amount1;
                amount0 = 0;
            } else {
                // Swap `token1` for `token0`.
                if (tokenOut != token0) revert InvalidOutputToken();
                amount0 += _getAmountOut(amount1, _reserve1 - amount1, _reserve0 - amount0);
                _transfer(token0, amount0, recipient, unwrapBento);
                amountOut = amount0;
                amount1 = 0;
            }
        }

        (uint256 balance0, uint256 balance1) = _balance();
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);

        emit Burn(msg.sender, amount0, amount1, recipient);
    }

    /// @dev Swaps one token for another. The router must prefund this contract and ensure there isn't too much slippage.
    function swap(bytes calldata data) public override nonReentrant returns (uint256 amountOut) {
        (address tokenIn, address recipient, bool unwrapBento) = abi.decode(data, (address, address, bool));
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        if (_reserve0 == 0) revert PoolUninitialized();
        (uint256 balance0, uint256 balance1) = _balance();
        uint256 amountIn;
        address tokenOut;
        unchecked {
            if (tokenIn == token0) {
                tokenOut = token1;
                amountIn = balance0 - _reserve0;
                amountOut = _getAmountOut(amountIn, _reserve0, _reserve1);
                balance1 -= amountOut;
            } else {
                if (tokenIn != token1) revert InvalidInputToken();
                tokenOut = token0;
                amountIn = balance1 - reserve1;
                amountOut = _getAmountOut(amountIn, _reserve1, _reserve0);
                balance0 -= amountOut;
            }
        }
        _transfer(tokenOut, amountOut, recipient, unwrapBento);
        _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
        emit Swap(recipient, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @dev Swaps one token for another. The router must support swap callbacks and ensure there isn't too much slippage.
    function flashSwap(bytes calldata data) public override nonReentrant returns (uint256 amountOut) {
        (address tokenIn, address recipient, bool unwrapBento, uint256 amountIn, bytes memory context) = abi.decode(
            data,
            (address, address, bool, uint256, bytes)
        );
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = _getReserves();
        if (_reserve0 == 0) revert PoolUninitialized();
        unchecked {
            if (tokenIn == token0) {
                amountOut = _getAmountOut(amountIn, _reserve0, _reserve1);
                _transfer(token1, amountOut, recipient, unwrapBento);
                ITridentCallee(msg.sender).tridentSwapCallback(context);
                (uint256 balance0, uint256 balance1) = _balance();
                if (balance0 - _reserve0 < amountIn) revert InsufficientAmountIn();
                _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
                emit Swap(recipient, tokenIn, token1, amountIn, amountOut);
            } else {
                if (tokenIn != token1) revert InvalidInputToken();
                amountOut = _getAmountOut(amountIn, _reserve1, _reserve0);
                _transfer(token0, amountOut, recipient, unwrapBento);
                ITridentCallee(msg.sender).tridentSwapCallback(context);
                (uint256 balance0, uint256 balance1) = _balance();
                if (balance1 - _reserve1 < amountIn) revert InsufficientAmountIn();
                _update(balance0, balance1, _reserve0, _reserve1, _blockTimestampLast);
                emit Swap(recipient, tokenIn, token0, amountIn, amountOut);
            }
        }
    }

    /// @dev Updates `barFee` and `barFeeTo` for Trident protocol.
    function updateBarParameters() public {
        barFee = masterDeployer.barFee();
        barFeeTo = masterDeployer.barFeeTo();
    }

    function _getReserves()
        internal
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _balance() internal view returns (uint256 balance0, uint256 balance1) {
        balance0 = bento.balanceOf(token0, address(this));
        balance1 = bento.balanceOf(token1, address(this));
    }

    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _blockTimestampLast
    ) internal {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max) revert Overflow();
        if (_blockTimestampLast == 0) {
            // TWAP support is disabled for gas efficiency.
            reserve0 = uint112(balance0);
            reserve1 = uint112(balance1);
        } else {
            uint32 blockTimestamp = uint32(block.timestamp);
            if (blockTimestamp != _blockTimestampLast && _reserve0 != 0 && _reserve1 != 0) {
                unchecked {
                    uint32 timeElapsed = blockTimestamp - _blockTimestampLast;
                    uint256 price0 = (uint256(_reserve1) << PRECISION) / _reserve0;
                    price0CumulativeLast += price0 * timeElapsed;
                    uint256 price1 = (uint256(_reserve0) << PRECISION) / _reserve1;
                    price1CumulativeLast += price1 * timeElapsed;
                }
            }
            reserve0 = uint112(balance0);
            reserve1 = uint112(balance1);
            blockTimestampLast = blockTimestamp;
        }
        emit Sync(balance0, balance1);
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) internal returns (uint256 _totalSupply, uint256 computed) {
        _totalSupply = totalSupply;
        uint256 _kLast = kLast;
        if (_kLast != 0) {
            computed = TridentMath.sqrt(uint256(_reserve0) * _reserve1);
            if (computed > _kLast) {
                // `barFee` % of increase in liquidity.
                uint256 _barFee = barFee;
                uint256 numerator = _totalSupply * (computed - _kLast) * _barFee;
                uint256 denominator = (MAX_FEE - _barFee) * computed + _barFee * _kLast;
                uint256 liquidity = numerator / denominator;

                if (liquidity != 0) {
                    _mint(barFeeTo, liquidity);
                    _totalSupply += liquidity;
                }
            }
        }
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveAmountIn,
        uint256 reserveAmountOut
    ) internal view returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * MAX_FEE_MINUS_SWAP_FEE;
        amountOut = (amountInWithFee * reserveAmountOut) / (reserveAmountIn * MAX_FEE + amountInWithFee);
    }

    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveAmountIn,
        uint256 reserveAmountOut
    ) internal view returns (uint256 amountIn) {
        amountIn = (reserveAmountIn * amountOut * MAX_FEE) / ((reserveAmountOut - amountOut) * MAX_FEE_MINUS_SWAP_FEE) + 1;
    }

    function _transfer(
        address token,
        uint256 shares,
        address to,
        bool unwrapBento
    ) internal {
        if (unwrapBento) {
            bento.withdraw(token, address(this), to, 0, shares);
        } else {
            bento.transfer(token, address(this), to, shares);
        }
    }

    /// @dev This fee is charged to cover for `swapFee` when users add unbalanced liquidity.
    function _nonOptimalMintFee(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256 token0Fee, uint256 token1Fee) {
        if (_reserve0 == 0 || _reserve1 == 0) return (0, 0);
        uint256 amount1Optimal = (_amount0 * _reserve1) / _reserve0;
        if (amount1Optimal <= _amount1) {
            token1Fee = (swapFee * (_amount1 - amount1Optimal)) / (2 * MAX_FEE);
        } else {
            uint256 amount0Optimal = (_amount1 * _reserve0) / _reserve1;
            token0Fee = (swapFee * (_amount0 - amount0Optimal)) / (2 * MAX_FEE);
        }
    }

    function getAssets() public view override returns (address[] memory assets) {
        assets = new address[](2);
        assets[0] = token0;
        assets[1] = token1;
    }

    function getAmountOut(bytes calldata data) public view override returns (uint256 finalAmountOut) {
        (address tokenIn, uint256 amountIn) = abi.decode(data, (address, uint256));
        (uint112 _reserve0, uint112 _reserve1, ) = _getReserves();
        if (tokenIn == token0) {
            finalAmountOut = _getAmountOut(amountIn, _reserve0, _reserve1);
        } else {
            if (tokenIn != token1) revert InvalidInputToken();
            finalAmountOut = _getAmountOut(amountIn, _reserve1, _reserve0);
        }
    }

    function getAmountIn(bytes calldata data) public view override returns (uint256 finalAmountIn) {
        (address tokenOut, uint256 amountOut) = abi.decode(data, (address, uint256));
        (uint112 _reserve0, uint112 _reserve1, ) = _getReserves();
        if (tokenOut == token1) {
            finalAmountIn = _getAmountIn(amountOut, _reserve0, _reserve1);
        } else {
            if (tokenOut != token0) revert InvalidOutputToken();
            finalAmountIn = _getAmountIn(amountOut, _reserve1, _reserve0);
        }
    }

    /// @dev Returned values are in terms of BentoBox "shares".
    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        return _getReserves();
    }

    /// @dev Returned values are the native ERC20 token amounts.
    function getNativeReserves()
        public
        view
        returns (
            uint256 _nativeReserve0,
            uint256 _nativeReserve1,
            uint32 _blockTimestampLast
        )
    {
        (uint112 _reserve0, uint112 _reserve1, uint32 __blockTimestampLast) = _getReserves();
        _nativeReserve0 = bento.toAmount(token0, _reserve0, false);
        _nativeReserve1 = bento.toAmount(token1, _reserve1, false);
        _blockTimestampLast = __blockTimestampLast;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./IMasterDeployer.sol";

interface IConstantProductPoolFactory {
    function getDeployData() external view returns (bytes memory, IMasterDeployer);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident pool deployer interface.
interface IMasterDeployer {
    function barFee() external view returns (uint256);

    function barFeeTo() external view returns (address);

    function bento() external view returns (address);

    function migrator() external view returns (address);

    function pools(address pool) external view returns (bool);

    function deployPool(address factory, bytes calldata deployData) external returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "../libraries/RebaseLibrary.sol";

/// @notice Minimal BentoBox vault interface.
/// @dev `token` is aliased as `address` from `IERC20` for simplicity.
interface IBentoBoxMinimal {
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    /// @notice Registers this contract so that users can approve it for BentoBox.
    function registerProtocol() external;

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount represented in shares.
    function deposit(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    /// @dev Reads the Rebase `totals`from storage for a given token
    function totals(address token) external view returns (Rebase memory total);

    /// @dev Approves users' BentoBox assets to a "master" contract.
    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function harvest(
        address token,
        bool balance,
        uint256 maxChangeAmount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @notice Trident pool interface.
interface IPool {
    /// @notice Executes a swap from one token to another.
    /// @dev The input tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function swap(bytes calldata data) external returns (uint256 finalAmountOut);

    /// @notice Executes a swap from one token to another with a callback.
    /// @dev This function allows borrowing the output tokens and sending the input tokens in the callback.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that were sent to the user.
    function flashSwap(bytes calldata data) external returns (uint256 finalAmountOut);

    /// @notice Mints liquidity tokens.
    /// @param data ABI-encoded params that the pool requires.
    /// @return liquidity The amount of liquidity tokens that were minted for the user.
    function mint(bytes calldata data) external returns (uint256 liquidity);

    /// @notice Burns liquidity tokens.
    /// @dev The input LP tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return withdrawnAmounts The amount of various output tokens that were sent to the user.
    function burn(bytes calldata data) external returns (TokenAmount[] memory withdrawnAmounts);

    /// @notice Burns liquidity tokens for a single output token.
    /// @dev The input LP tokens must've already been sent to the pool.
    /// @param data ABI-encoded params that the pool requires.
    /// @return amountOut The amount of output tokens that were sent to the user.
    function burnSingle(bytes calldata data) external returns (uint256 amountOut);

    /// @return A unique identifier for the pool type.
    function poolIdentifier() external pure returns (bytes32);

    /// @return An array of tokens supported by the pool.
    function getAssets() external view returns (address[] memory);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountOut The amount of output tokens that will be sent to the user if the trade is executed.
    function getAmountOut(bytes calldata data) external view returns (uint256 finalAmountOut);

    /// @notice Simulates a trade and returns the expected output.
    /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
    /// @param data ABI-encoded params that the pool requires.
    /// @return finalAmountIn The amount of input tokens that are required from the user if the trade is executed.
    function getAmountIn(bytes calldata data) external view returns (uint256 finalAmountIn);

    /// @dev This event must be emitted on all swaps.
    event Swap(address indexed recipient, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    /// @dev This struct frames output tokens for burns.
    struct TokenAmount {
        address token;
        uint256 amount;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident pool callback interface.
interface ITridentCallee {
    function tridentSwapCallback(bytes calldata data) external;

    function tridentMintCallback(bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Trident sqrt helper library.
library TridentMath {
    /// @dev Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // This segment is to get a reasonable initial estimate for the Babylonian method.
            // If the initial estimate is bad, the number of correct bits increases ~linearly
            // each iteration instead of ~quadratically.
            // The idea is to get z*z*y within a small factor of x.
            // More iterations here gets y in a tighter range. Currently, we will have
            // y in [256, 256*2^16). We ensure y>= 256 so that the relative difference
            // between y and y+1 is small. If x < 256 this is not possible, but those cases
            // are easy enough to verify exhaustively.
            z := 181 // The 'correct' value is 1, but this saves a multiply later
            let y := x
            // Note that we check y>= 2^(k + 8) but shift right by k bits each branch,
            // this is to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }
            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8),
            // and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1)
            // is in the range (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s=1
            // and when s = 256 or 1/256. Since y is in [256, 256*2^16), let a = y/65536, so
            // that a is in [1/256, 256). Then we can estimate sqrt(y) as
            // sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18
            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A multiply is saved from the initial z := 181

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            // Possibly with a quadratic/cubic polynomial above we could get 4-6.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // See https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division.
            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This check ensures we return floor.
            // Since this case is rare, we choose to save gas on the assignment and
            // repeat division in the rare case.
            // If you don't care whether floor or ceil is returned, you can skip this.
            if lt(div(x, z), z) {
                z := div(x, z)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(Rebase memory total, uint256 elastic) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(Rebase memory total, uint256 base) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
        }
    }
}
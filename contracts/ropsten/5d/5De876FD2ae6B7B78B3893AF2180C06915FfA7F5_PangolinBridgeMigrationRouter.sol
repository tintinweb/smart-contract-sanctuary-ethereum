pragma solidity ^0.7.6;

import "../pangolin-core/interfaces/IPangolinERC20.sol";
import "../pangolin-lib/libraries/TransferHelper.sol";
import "./interfaces/IBridgeToken.sol";
import "./libraries/Roles.sol";
import "./libraries/PangolinLibrary.sol";

contract PangolinBridgeMigrationRouter {
    using SafeMath for uint;
    using Roles for Roles.Role;

    Roles.Role private adminRole;
    mapping(address => address) public bridgeMigrator;

    constructor() public {
        adminRole.add(msg.sender);
    }

    // safety measure to prevent clear front-running by delayed block
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'PangolinBridgeMigrationRouter: EXPIRED');
        _;
    }

    // makes sure the admin is the one calling protected methods
    modifier onlyAdmin() {
        require(adminRole.has(msg.sender), 'PangolinBridgeMigrationRouter: Unauthorized');
        _;
    }

    /**
     * @notice Given an address, this address is added to the list of admin.
     * @dev Any admin can add or remove other admins, careful.
     * @param account The address of the account.
     */
    function addAdmin(address account) external onlyAdmin {
        require(account != address(0), "PangolinBridgeMigrationRouter: Address 0 not allowed");
        adminRole.add(account);
    }

    /**
     * @notice Given an address, this address is added to the list of admin.
     * @dev Any admin can add or remove other admins, careful.
     * @param account The address of the account.
     */
    function removeAdmin(address account) external onlyAdmin {
        require(msg.sender != account, "PangolinBridgeMigrationRouter: You can't demote yourself");
        adminRole.remove(account);
    }

    /**
     * @notice Given an address, returns whether or not he's already an admin
     * @param account The address of the account.
     * @return Whether or not the account address is an admin.
     */
    function isAdmin(address account) external view returns(bool) {
        return adminRole.has(account);
    }

    /**
     * @notice Given an token, and it's migrator address, it configures the migrator for later usage
     * @param tokenAddress The ERC20 token address that will be migrated using the migrator
     * @param migratorAddress The WrappedERC20 token address that will be migrate the token
     */
    function addMigrator(address tokenAddress, address migratorAddress) external onlyAdmin {
        require(tokenAddress != address(0), "PangolinBridgeMigrationRouter: tokenAddress 0 not supported");
        require(migratorAddress != address(0), "PangolinBridgeMigrationRouter: migratorAddress 0 not supported");
        uint256 amount = IBridgeToken(migratorAddress).swapSupply(tokenAddress);
        require(
            amount > 0,
            "The migrator doesn't have swap supply for this token"
        );
        _allowToken(tokenAddress, migratorAddress);
        bridgeMigrator[tokenAddress] = migratorAddress;
    }

    /**
     * @notice Internal function to manage approval, allows an ERC20 to be spent to the maximum
     * @param tokenAddress The ERC20 token address that will be allowed to be used
     * @param spenderAddress Who's going to spend the ERC20 token
     */
    function _allowToken(address tokenAddress, address spenderAddress) internal {
        IPangolinERC20(tokenAddress).approve(spenderAddress, type(uint).max);
    }

    /**
     * @notice Internal function add liquidity on a low level, without the use of a router
     * @dev This function will try to maximize one of the tokens amount and match the other
     * one, can cause dust so consider charge backs
     * @param pairToken The pair that will receive the liquidity
     * @param token0 The first token of the pair
     * @param token1 The second token of the pair
     * @param amountIn0 The amount of first token that can be used to deposit liquidity
     * @param amountIn1 The amount of second token that can be used to deposit liquidity
     * @param to The address who will receive the liquidity
     * @return amount0 Charge back from token0
     * @return amount1 Charge back from token1
     * @return liquidityAmount Total liquidity token amount acquired
     */
    function _addLiquidity(
        address pairToken,
        address token0,
        address token1,
        uint amountIn0,
        uint amountIn1,
        address to
    ) private returns (uint amount0, uint amount1, uint liquidityAmount) {
        (uint112 reserve0, uint112 reserve1,) = IPangolinPair(pairToken).getReserves();
        uint quote0 = amountIn0;
        uint quote1 = PangolinLibrary.quote(amountIn0, reserve0, reserve1);
        if (quote1 > amountIn1) {
            quote1 = amountIn1;
            quote0 = PangolinLibrary.quote(amountIn1, reserve1, reserve0);
        }
        TransferHelper.safeTransfer(token0, pairToken, quote0);
        TransferHelper.safeTransfer(token1, pairToken, quote1);
        amount0 = amountIn0 - quote0;
        amount1 = amountIn1 - quote1;
        liquidityAmount = IPangolinPair(pairToken).mint(to);
    }

    /**
     * @notice Internal function to remove liquidity on a low level, without the use of a router
     * @dev This function requires the user to approve this contract to transfer the liquidity pair on it's behalf
     * @param liquidityPair The pair that will have the liquidity removed
     * @param amount The amount of liquidity token that you want to rescue
     * @return amountTokenA The amount of token0 from burning liquidityPair token
     * @return amountTokenB The amount of token1 from burning liquidityPair token
     */
    function _rescueLiquidity(
        address liquidityPair,
        uint amount
    ) internal returns (uint amountTokenA, uint amountTokenB) {
        TransferHelper.safeTransferFrom(liquidityPair, msg.sender, liquidityPair, amount);
        (amountTokenA, amountTokenB) = IPangolinPair(liquidityPair).burn(address(this));
    }

    /**
     * @notice Internal function that checks if the minimum requirements are met to accept the pairs to migrate
     * @dev This function makes the main function(migrateLiquidity) cleaner, this function can revert the transaction
     * @param pairA The pair that is going to be migrated from
     * @param pairB The pair that is going to be migrated to
     */
    function _arePairsCompatible(address pairA, address pairB) internal view {
        require(pairA != address(0), "PangolinBridgeMigrationRouter: liquidityPairFrom address 0");
        require(pairA != address(0), "PangolinBridgeMigrationRouter: liquidityPairTo address 0");
        require(pairA != pairB, "PangolinBridgeMigrationRouter: Cant convert to the same liquidity pairs");
        require(
            IPangolinPair(pairA).token0() == IPangolinPair(pairB).token0() ||
            IPangolinPair(pairA).token0() == IPangolinPair(pairB).token1() ||
            IPangolinPair(pairA).token1() == IPangolinPair(pairB).token0() ||
            IPangolinPair(pairA).token1() == IPangolinPair(pairB).token1(),
            "PangolinBridgeMigrationRouter: Pair does not have one token matching"
        );
    }

    /**
     * @notice Internal function that implements the token migration
     * @dev This function only checks if the expected balance was received, it doesn't check for migrator existance
     * @param tokenAddress The ERC20 token address that will be migrated
     * @param amount The amount of the token to be migrated
     */
    function _migrateToken(
        address tokenAddress,
        uint amount
    ) internal {
        require(tokenAddress != address(0), "PangolinBridgeMigrationRouter: tokenAddress 0 not supported");
        IBridgeToken(bridgeMigrator[tokenAddress]).swap(tokenAddress, amount);
        require(
            IBridgeToken(bridgeMigrator[tokenAddress]).balanceOf(address(this)) == amount,
            "PangolinBridgeMigrationRouter: Didn't yield the correct amount"
        );
    }

    /**
     * @notice Front facing function that migrates the token
     * @dev This function includes important checks
     * @param token The ERC20 token address that will be migrated
     * @param to The address of who's receiving the token
     * @param amount The amount of the token to be migrated
     * @param deadline The deadline limit that should be met, otherwise revert to prevent front-run
     */
    function migrateToken(
        address token,
        address to,
        uint amount,
        uint deadline
    ) external ensure(deadline) {
        require(
            bridgeMigrator[token] != address(0),
            "PangolinBridgeMigrationRouter: migrator not registered"
        );
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        _migrateToken(token, amount);
        TransferHelper.safeTransfer(bridgeMigrator[token], to, amount);
    }

    /**
     * @notice Front facing function that migrates the liquidity, with permit
     * @param liquidityPairFrom The pair address to be migrated from
     * @param liquidityPairTo The pair address to be migrated to
     * @param to The address that will receive the liquidity and the charge backs
     * @param amount The amount of token liquidityPairFrom that will be migrated
     * @param deadline The deadline limit that should be met, otherwise revert to prevent front-run
     * @param v by passing param for the permit validation
     * @param r by passing param for the permit validation
     * @param s by passing param for the permit validation
     */
    function migrateLiquidityWithPermit(
        address liquidityPairFrom,
        address liquidityPairTo,
        address to,
        uint amount,
        uint deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external ensure(deadline) {
        IPangolinPair(liquidityPairFrom).permit(msg.sender, address(this), amount, deadline, v, r, s);
        _migrateLiquidity(
            liquidityPairFrom,
            liquidityPairTo,
            to,
            amount
        );
    }

    /**
     * @notice Front facing function that migrates the liquidity
     * @dev This function assumes sender already gave approval to move the assets
     * @param liquidityPairFrom The pair address to be migrated from
     * @param liquidityPairTo The pair address to be migrated to
     * @param to The address that will receive the liquidity and the charge backs
     * @param amount The amount of token liquidityPairFrom that will be migrated
     * @param deadline The deadline limit that should be met, otherwise revert to prevent front-run
     */
    function migrateLiquidity(
        address liquidityPairFrom,
        address liquidityPairTo,
        address to,
        uint amount,
        uint deadline
    ) external ensure(deadline) {
        _migrateLiquidity(
            liquidityPairFrom,
            liquidityPairTo,
            to,
            amount
        );
    }

    /**
     * @notice This was extracted into a internal method to use with both migrateLiquidity and with permit
     * @dev This function includes important checks
     * @param liquidityPairFrom The pair address to be migrated from
     * @param liquidityPairTo The pair address to be migrated to
     * @param to The address that will receive the liquidity and the charge backs
     * @param amount The amount of token liquidityPairFrom that will be migrated
     */
    function _migrateLiquidity(
        address liquidityPairFrom,
        address liquidityPairTo,
        address to,
        uint amount
    ) internal {
        _arePairsCompatible(liquidityPairFrom, liquidityPairTo);
        address tokenToMigrate = IPangolinPair(liquidityPairFrom).token0();
        if (
            IPangolinPair(liquidityPairFrom).token0() == IPangolinPair(liquidityPairTo).token0() ||
            IPangolinPair(liquidityPairFrom).token0() == IPangolinPair(liquidityPairTo).token1()
        ) {
            tokenToMigrate = IPangolinPair(liquidityPairFrom).token1();
        }
        address newTokenAddress = bridgeMigrator[tokenToMigrate];
        require(
            newTokenAddress != address(0),
            "PangolinBridgeMigrationRouter: Migrator not registered for the pair"
        );
        require(
            newTokenAddress == IPangolinPair(liquidityPairTo).token0() ||
            newTokenAddress == IPangolinPair(liquidityPairTo).token1(),
            "PangolinBridgeMigrationRouter: Pair doesn't match the migration token"
        );

        (uint amountTokenA, uint amountTokenB) = _rescueLiquidity(liquidityPairFrom, amount);
        {
            uint amountToSwap = amountTokenA;
            if (tokenToMigrate != IPangolinPair(liquidityPairFrom).token0()) {
                amountToSwap = amountTokenB;
            }
            _migrateToken(tokenToMigrate, amountToSwap);
        }
        if (IPangolinPair(liquidityPairFrom).token0() != IPangolinPair(liquidityPairTo).token0() &&
            IPangolinPair(liquidityPairFrom).token1() != IPangolinPair(liquidityPairTo).token1()
        ) {
            (amountTokenA, amountTokenB) = (amountTokenB, amountTokenA);
        }

        (uint changeAmount0, uint changeAmount1, ) = _addLiquidity(
            liquidityPairTo,
            IPangolinPair(liquidityPairTo).token0(), IPangolinPair(liquidityPairTo).token1(),
            amountTokenA, amountTokenB, to
        );
        if (changeAmount0 > 0) {
            TransferHelper.safeTransfer(IPangolinPair(liquidityPairTo).token0(), to, changeAmount0);
        }
        if (changeAmount1 > 0) {
            TransferHelper.safeTransfer(IPangolinPair(liquidityPairTo).token1(), to, changeAmount1);
        }
    }

    /**
     * @notice Internal function that simulates the amount received from the liquidity burn
     * @dev This function is a support function that can be used by the front-end to show possible charge back
     * @param pairAddress The pair address that will be burned(simulated)
     * @param amount The amount of the liquidity token to be burned(simulated)
     * @return amount0 Amounts of token0 acquired from burning the pairAddress token
     * @return amount1 Amounts of token1 acquired from burning the pairAddress token
     */
    function _calculateRescueLiquidity(address pairAddress, uint amount) internal view returns (uint amount0, uint amount1) {
        (uint112 reserves0, uint112 reserves1, ) = IPangolinPair(pairAddress).getReserves();
        uint totalSupply = IPangolinPair(pairAddress).totalSupply();
        amount0 = amount.mul(reserves0) / totalSupply;
        amount1 = amount.mul(reserves1) / totalSupply;
    }

    /**
     * @notice Front facing function that computes the possible charge back from the migration
     * @dev No need to be extra careful as this is only a view function
     * @param liquidityPairFrom The pair address that will be migrated from(simulated)
     * @param liquidityPairTo The pair address that will be migrated to(simulated)
     * @param amount The amount of the liquidity token to be migrated(simulated)
     * @return amount0 Amount of token0 will be charged back after the migration
     * @return amount1 Amount of token1 will be charged back after the migration
     */
    function calculateChargeBack(
        address liquidityPairFrom,
        address liquidityPairTo,
        uint amount
    ) external view returns (uint amount0, uint amount1) {
        require(liquidityPairFrom != address(0), "PangolinBridgeMigrationRouter: liquidityPairFrom address 0 not supported");
        require(liquidityPairTo != address(0), "PangolinBridgeMigrationRouter: liquidityPairTo address 0 not supported");
        (uint amountIn0, uint amountIn1) = _calculateRescueLiquidity(liquidityPairFrom, amount);
        if (IPangolinPair(liquidityPairFrom).token0() != IPangolinPair(liquidityPairTo).token0() &&
            IPangolinPair(liquidityPairFrom).token1() != IPangolinPair(liquidityPairTo).token1()
        ) {
            (amountIn0, amountIn1) = (amountIn1, amountIn0);
        }
        (uint112 reserve0, uint112 reserve1,) = IPangolinPair(liquidityPairTo).getReserves();
        uint quote0 = amountIn0;
        uint quote1 = PangolinLibrary.quote(amountIn0, reserve0, reserve1);
        if (quote1 > amountIn1) {
            quote1 = amountIn1;
            quote0 = PangolinLibrary.quote(amountIn1, reserve1, reserve0);
        }
        amount0 = amountIn0 - quote0;
        amount1 = amountIn1 - quote1;
    }

}

pragma solidity >=0.5.0;

import '../../pangolin-core/interfaces/IPangolinFactory.sol';
import '../../pangolin-core/interfaces/IPangolinPair.sol';

import "./SafeMath.sol";

library PangolinLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PangolinLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PangolinLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'67406ed831e8a7539813610a4e5ce29f2b15fef4dfac17d9b05976cd51035b6f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPangolinPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PangolinLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PangolinLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PangolinLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PangolinLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PangolinLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PangolinLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PangolinLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PangolinLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity >=0.5.0;

import "../../pangolin-core/interfaces/IPangolinERC20.sol";

interface IBridgeToken is IPangolinERC20 {
    function swap(address token, uint256 amount) external;
    function swapSupply(address token) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending AVAX that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: AVAX_TRANSFER_FAILED');
    }
}

pragma solidity >=0.5.0;

interface IPangolinERC20 {
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
}

pragma solidity >=0.6.6 <0.8.0;

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

pragma solidity >=0.5.0;

interface IPangolinPair {
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

pragma solidity >=0.5.0;

interface IPangolinFactory {
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
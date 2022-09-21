// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import './interfaces/IConverter.sol';

import './interfaces/IAaveAToken.sol';
import './interfaces/IAaveLendingPool.sol';
import './interfaces/ICompoundToken.sol';
import './interfaces/IUniswap.sol';

import './interfaces/IERC20.sol';

// TODO make an admin for this contract?
contract Converter is IConverter {
    address public ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    /// @notice converts the compounding asset to the underlying asset for msg.sender
    /// @dev currently only supports Compound and Aave conversions
    /// @param c contract address of the compounding token
    /// @param u contract address of the underlying token
    /// @param a amount of tokens to convert
    /// @param m minimum tokens to be received (only used for swap conversions)
    function convert(
        address c,
        address u,
        uint256 a,
        uint256 m
    ) external {
        // first receive the tokens from msg.sender
        IERC20(c).transferFrom(msg.sender, address(this), a);

        // get Aave pool
        try IAaveAToken(c).POOL() returns (address pool) {
            // Allow the pool to spend the funds
            IERC20(u).approve(pool, a);
            // withdraw from Aave
            IAaveLendingPool(pool).withdraw(u, a, msg.sender);
        } catch {
            // Aave did not work, try compound
            try ICompoundToken(c).redeem(a) {
                // get the balance of tokens to send back
                uint256 balance = IERC20(u).balanceOf(address(this));
                // transfer the underlying back to the user
                IERC20(u).transfer(msg.sender, balance);
            } catch {
                // Create path to swap stETH for wETH
                address[] memory path = new address[](2);
                path[0] = c;
                path[1] = u;
                // Swap wrapped staked eth for wrapped eth via sushi
                // todo why is this not working
                IUniswap(ROUTER).swapExactTokensForTokens(
                    a,
                    m,
                    path,
                    msg.sender,
                    block.timestamp // deadline well into the future
                );
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface IConverter {
    function convert(
        address,
        address,
        uint256,
        uint256
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface IAaveAToken {
    function POOL() external returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface IAaveLendingPool {
    function withdraw(
        address,
        uint256,
        address
    ) external;

    // only used by integration tests
    function deposit(
        address,
        uint256,
        address,
        uint16
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface ICompoundToken {
    function redeem(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface IUniswap {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
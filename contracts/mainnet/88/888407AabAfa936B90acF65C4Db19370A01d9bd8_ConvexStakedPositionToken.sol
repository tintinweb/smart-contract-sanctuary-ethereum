// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PhantomERC20} from "@gearbox-protocol/core-v2/contracts/tokens/PhantomERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title ConvexStakedPositionToken
/// @dev Represents the balance of the staking token position in Convex pools
contract ConvexStakedPositionToken is PhantomERC20 {
    address public immutable pool;

    /// @dev Constructor
    /// @param _pool The Convex pool where the balance is tracked
    /// @param _lptoken The Convex LP token that is staked in the pool
    constructor(address _pool, address _lptoken)
        PhantomERC20(
            _lptoken,
            string(abi.encodePacked("Convex Staked Position ", IERC20Metadata(_lptoken).name())),
            string(abi.encodePacked("stk", IERC20Metadata(_lptoken).symbol())),
            IERC20Metadata(_lptoken).decimals()
        )
    {
        pool = _pool;
    }

    /// @dev Returns the amount of Convex LP tokens staked in the pool
    /// @param account The account for which the calculation is performed
    function balanceOf(address account) public view returns (uint256) {
        return IERC20(pool).balanceOf(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IPhantomERC20 } from "../interfaces/IPhantomERC20.sol";

/// @dev PhantomERC20 is a pseudo-ERC20 that only implements totalSupply and balanceOf
/// @notice Used to track positions that do not issue an explicit share token
///         This is an abstract contract and balanceOf is implemented by concrete instances
abstract contract PhantomERC20 is IPhantomERC20 {
    address public immutable underlying;

    string public override symbol;
    string public override name;
    uint8 public immutable override decimals;

    constructor(
        address _underlying,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        underlying = _underlying;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return IPhantomERC20(underlying).totalSupply();
    }

    function transfer(address, uint256) external pure override returns (bool) {
        return false;
    }

    function allowance(address, address)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    function approve(address, uint256) external pure override returns (bool) {
        return false;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure override returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title IPhantomERC20
/// @dev Phantom tokens track balances in pools / contracts
///      that do not mint an LP or a share token. Non-transferrabl.
interface IPhantomERC20 is IERC20Metadata {
    /// @dev Returns the address of the token that is staked into the tracked position
    function underlying() external view returns (address);
}
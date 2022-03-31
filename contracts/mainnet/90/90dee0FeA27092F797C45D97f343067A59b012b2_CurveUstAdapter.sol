// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./../interfaces/IExchangeAdapter.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface ICurveUst {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external returns (uint256);
}

interface ICurve3Crv {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}

contract CurveUstAdapter {
    address public constant fraxLp = 0x94e131324b6054c0D789b190b2dAC504e4361b53;
    ICurve3Crv public constant pool3Crv =
        ICurve3Crv(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    function indexByUnderlyingCoin(address coin) public pure returns (int128) {
        if (coin == 0xa47c8bf37f92aBed4A126BDA807A7b7498661acD) return 1; // ust
        if (coin == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 2; // dai
        if (coin == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 3; // usdc
        if (coin == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 4; // usdt
        return 0;
    }

    function indexByCoin(address coin) public pure returns (int128) {
        if (coin == 0xa47c8bf37f92aBed4A126BDA807A7b7498661acD) return 1; // ust
        if (coin == 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490) return 2; // 3Crv
        return 0;
    }

    // 0x6012856e  =>  executeSwap(address,address,address,uint256)
    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveUst curve = ICurveUst(pool);
        int128 i = indexByUnderlyingCoin(fromToken);
        int128 j = indexByUnderlyingCoin(toToken);
        require(i != 0 && j != 0, "CurveUstAdapter: can't swap");

        return curve.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    // 0xe83bbb76  =>  enterPool(address,address,address,uint256)
    function enterPool(
        address pool,
        address fromToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveUst curve = ICurveUst(pool);

        uint128 i = uint128(indexByCoin(fromToken));

        if (i != 0) {
            uint256[2] memory entryVector_;
            entryVector_[i - 1] = amount;
            return curve.add_liquidity(entryVector_, 0);
        }

        i = uint128(indexByUnderlyingCoin(fromToken));
        IERC20 threeCrvToken = IERC20(
            0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490
        );

        require(i != 0, "CrvUstAdapter: can't enter");
        uint256[3] memory entryVector;
        entryVector[i - 2] = amount;

        pool3Crv.add_liquidity(entryVector, 0);
        return
            curve.add_liquidity([0, threeCrvToken.balanceOf(address(this))], 0);
    }

    // 0x9d756192  =>  exitPool(address,address,address,uint256)
    function exitPool(
        address pool,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveUst curve = ICurveUst(pool);

        int128 i = indexByCoin(toToken);

        if (i != 0) {
            return curve.remove_liquidity_one_coin(amount, i - 1, 0);
        }

        i = indexByUnderlyingCoin(toToken);
        require(i != 0, "CrvUstAdapter: can't exit");
        uint256 amount3Crv = curve.remove_liquidity_one_coin(amount, 1, 0);
        pool3Crv.remove_liquidity_one_coin(amount3Crv, i - 2, 0);

        return IERC20(toToken).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IExchangeAdapter {
    // 0x6012856e  =>  executeSwap(address,address,address,uint256)
    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256);

    // 0x73ec962e  =>  enterPool(address,address,uint256)
    function enterPool(
        address pool,
        address fromToken,
        uint256 amount
    ) external payable returns (uint256);

    // 0x660cb8d4  =>  exitPool(address,address,uint256)
    function exitPool(
        address pool,
        address toToken,
        uint256 amount
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
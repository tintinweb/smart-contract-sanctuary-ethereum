// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./../interfaces/IExchangeAdapter.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface ICurveCvxEth {
    function exchange(
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
        uint256 i,
        uint256 _min_received
    ) external returns (uint256);
}

contract CurveCvxEthAdapter is IExchangeAdapter {
    address public constant cvxEthLp = 0x3A283D9c08E8b55966afb64C515f5143cf907611;
    ICurveCvxEth public constant cvxEthPool =
        ICurveCvxEth(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);


    function indexByCoin(address coin) public pure returns (uint256) {
        if (coin == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return 1; // weth
        if (coin == 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B) return 2; // cvx
        return 0;
    }

    // 0x6012856e  =>  executeSwap(address,address,address,uint256)
    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveCvxEth curve = ICurveCvxEth(pool);
        if (toToken == cvxEthLp) {
            uint128 i = uint128(indexByCoin(fromToken));
            require(i != 0, "CurveCvxEthAdapter: Can't Swap");
            uint256[2] memory entryVector;
            entryVector[i - 1] = amount;
            return curve.add_liquidity(entryVector, 0);
        } else if (fromToken == cvxEthLp) {
            uint256 i = indexByCoin(toToken);
            require(i != 0, "CurveCvxEthAdapter: Can't Swap");
            return curve.remove_liquidity_one_coin(amount, i-1, 0);
        } else {
            revert("CurveCvxEthAdapter: Can't Swap");
        }
    }

    // 0xe83bbb76  =>  enterPool(address,address,address,uint256)
    function enterPool(
        address pool,
        address fromToken,
        uint256 amount
    ) external payable returns (uint256) {
        revert("CurveCvxEthAdapter: Can't Swap");
    }

    // 0x9d756192  =>  exitPool(address,address,address,uint256)
    function exitPool(
        address pool,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        revert("CurveCvxEthAdapter: Can't Swap");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
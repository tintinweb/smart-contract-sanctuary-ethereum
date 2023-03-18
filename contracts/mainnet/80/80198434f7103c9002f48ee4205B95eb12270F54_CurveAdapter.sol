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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Adapter {
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function _approveIfNeeded(IERC20 token_, address spender_, uint256 amount_) internal {
        if (address(token_) == ETH) {
            return;
        }

        if (token_.allowance(address(this), spender_) < amount_) {
            token_.approve(spender_, type(uint256).max);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICurveAddressProvider} from "../interfaces/external/curve/ICurveAddressProvider.sol";
import {ICurveSwaps} from "../interfaces/external/curve/ICurveSwaps.sol";
import {Adapter} from "./Adapter.sol";

contract CurveAdapter is Adapter {
    uint256 private constant SWAPS_ADDRESS_ID = 2;

    ICurveAddressProvider public constant ADDRESS_PROVIDER =
        ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383); // Same address to all chains

    /**
     * @param _route Array of [initial token, pool, token, pool, token, ...]
     * @param _params Each pool swap params. I.e. [SWAP_N][idxFrom, idxTo, swapType]
     * Swap types:
     * 1 for a stableswap `exchange`,
     * 2 for stableswap `exchange_underlying`,
     * 3 for a cryptoswap `exchange`,
     * 4 for a cryptoswap `exchange_underlying`,
     * 5 for factory metapools with lending base pool `exchange_underlying`,
     * 6 for factory crypto-meta pools underlying exchange (`exchange` method in zap),
     * 7-11 for wrapped coin (underlying for lending or fake pool) -> LP token "exchange" (actually `add_liquidity`),
     * 12-14 for LP token -> wrapped coin (underlying for lending pool) "exchange" (actually `remove_liquidity_one_coin`)
     * 15 for WETH -> ETH "exchange" (actually deposit/withdraw)
     * Refs:  https://etherscan.deth.net/address/0x99a58482BD75cbab83b27EC03CA68fF489b5788f
     * @param _pools Array of pools for swaps via zap contracts.
     */
    function swapExactInput(address[9] calldata _route, uint256[3][4] calldata _params, address[4] calldata _pools)
        external
    {
        address _tokenIn = _route[0];
        uint256 _amountIn = _tokenIn != ETH ? IERC20(_tokenIn).balanceOf(address(this)) : address(this).balance;
        uint256 _value = _tokenIn == ETH ? _amountIn : 0;

        ICurveSwaps _swaps = getSwaps();
        _approveIfNeeded(IERC20(_tokenIn), address(_swaps), _amountIn);
        _swaps.exchange_multiple{value: _value}(_route, _params, _amountIn, 0, _pools);
    }

    function getSwaps() public view returns (ICurveSwaps) {
        return ICurveSwaps(ADDRESS_PROVIDER.get_address(SWAPS_ADDRESS_ID));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurveAddressProvider {
    function get_registry() external view returns (address);

    function get_address(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurveSwaps {
    /* solhint-disable */
    function get_best_rate(address _from, address _to, uint256 _amount) external view returns (address, uint256);

    function get_exchange_amount(address _pool, address _from, address _to, uint256 _amount)
        external
        view
        returns (uint256);

    function exchange(address _pool, address _from, address _to, uint256 _amount, uint256 _expected, address _receiver)
        external
        payable
        returns (uint256);

    /**
     * @notice This function queries the exchange rate for every pool where a swap between _to and _from is possible.
     *  For pairs that can be swapped in many pools this will result in very significant gas costs!
     */
    function exchange_with_best_rate(address _from, address _to, uint256 _amount, uint256 _expected, address _receiver)
        external
        payable
        returns (uint256);

    function get_exchange_multiple_amount(
        address[9] calldata _route,
        uint256[3][4] calldata _swap_params,
        uint256 _amount
    ) external view returns (uint256);

    function exchange_multiple(
        address[9] calldata _route,
        uint256[3][4] calldata _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] calldata _pools
    ) external payable returns (uint256);
}
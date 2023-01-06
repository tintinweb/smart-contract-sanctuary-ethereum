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

import "../interfaces/external/curve/ICurveAddressProvider.sol";
import "../interfaces/external/IWETH.sol";
import "../interfaces/ICurveAdapter.sol";

contract CurveAdapter is ICurveAdapter {
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant SWAPS_ADDRESS_ID = 2;
    uint256 private constant METAPOOL_FACTORY_ADDRESS_ID = 3;

    IWETH public immutable nativeToken;
    ICurveSwaps public immutable override swaps;
    ICurveFactoryRegistry public immutable registry;

    constructor(IWETH nativeToken_) {
        nativeToken = nativeToken_;

        ICurveAddressProvider ADDRESS_PROVIDER = ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);
        registry = ICurveFactoryRegistry(ADDRESS_PROVIDER.get_address(METAPOOL_FACTORY_ADDRESS_ID));
        swaps = ICurveSwaps(ADDRESS_PROVIDER.get_address(SWAPS_ADDRESS_ID));
    }

    function swap(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_
    ) external payable override returns (uint256 _amountOut) {
        address _tokenIn = path_[0];
        address _tokenOut = path_[1];
        uint256 _tokenInBalance = IERC20(_tokenIn).balanceOf(address(this));

        if (_tokenIn == address(nativeToken) && _tokenInBalance > 0) {
            // Withdraw ETH from WETH if any
            nativeToken.withdraw(_tokenInBalance);
        }

        if (amountIn_ == type(uint256).max) {
            amountIn_ = _tokenIn == address(nativeToken) ? address(this).balance : _tokenInBalance;
        }

        if (amountIn_ == 0) {
            // Doesn't revert
            return 0;
        }

        if (_tokenIn == address(nativeToken)) {
            _tokenIn = ETH_ADDRESS;
            return
                swaps.exchange{value: amountIn_}(
                    registry.find_pool_for_coins(_tokenIn, _tokenOut),
                    _tokenIn,
                    _tokenOut,
                    amountIn_,
                    amountOutMin_,
                    address(this)
                );
        }

        if (_tokenOut == address(nativeToken)) {
            _tokenOut = ETH_ADDRESS;
        }

        return
            swaps.exchange(
                registry.find_pool_for_coins(_tokenIn, _tokenOut),
                _tokenIn,
                _tokenOut,
                amountIn_,
                amountOutMin_,
                address(this)
            );
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/external/curve/ICurveFactoryRegistry.sol";
import "../interfaces/external/curve/ICurveSwaps.sol";

interface ICurveAdapter {
    function swap(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_
    ) external payable returns (uint256 _amountOut);

    function swaps() external view returns (ICurveSwaps);

    function registry() external view returns (ICurveFactoryRegistry);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurveAddressProvider {
    function get_registry() external view returns (address);

    function get_address(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurveFactoryRegistry {
    function get_n_coins(address lp) external view returns (uint256);

    function get_coins(address pool) external view returns (address[4] memory);

    function get_meta_n_coins(address pool) external view returns (uint256, uint256);

    function deploy_plain_pool(
        string memory _name,
        string memory _symbol,
        address[4] memory _coins,
        uint256 _A,
        uint256 _fee,
        uint256 _asset_type,
        uint256 _implementation_idx
    ) external;

    function base_pool_assets(address) external view returns (bool);

    function pool_count() external view returns (uint256);

    function pool_list(uint256) external view returns (address);

    function deploy_metapool(
        address _base_pool,
        string memory _name,
        string memory _symbol,
        address _coin,
        uint256 _A,
        uint256 _fee
    ) external;

    function get_fees(address _pool) external view returns (uint256, uint256);

    function get_balances(address _pool) external view returns (uint256[4] memory);

    function get_underlying_balances(address _pool) external view returns (uint256[4] memory);

    function is_meta(address _pool) external view returns (bool);

    function get_metapool_rates(address _pool) external view returns (uint256[2] memory);

    function find_pool_for_coins(address _from, address _to) external view returns (address _pool);

    function get_coin_indices(
        address _pool,
        address _from,
        address _to
    ) external view returns (int128 i, int128 j, bool _is_underlying);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurveSwaps {
    /* solhint-disable */
    function get_best_rate(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (address, uint256);

    function get_exchange_amount(
        address _pool,
        address _from,
        address _to,
        uint256 _amount        
    ) external view returns (uint256);

    function exchange(
        address _pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);

    /**
     @notice This function queries the exchange rate for every pool where a swap between _to and _from is possible. 
     For pairs that can be swapped in many pools this will result in very significant gas costs!
     */
    function exchange_with_best_rate(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external payable returns (uint256);
}
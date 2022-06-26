// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
pragma abicoder v1;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IstETH} from "../../integrations/lido/IstETH.sol";
import {IWETH} from "../../interfaces/external/IWETH.sol";

// EXCEPTIONS
import {ZeroAddressException} from "../../interfaces/IErrors.sol";

/// @title LidoV1 Gateway
/// @dev Implements logic allowing CA to interact with Lido contracts, which use native ETH
contract LidoV1Gateway {

    /// @dev The original Lido contract
    IstETH public immutable stETH;

    /// @dev The WETH contract
    IWETH public immutable weth;

    /// @dev Constructor
    /// @param _weth WETH token address
    /// @param _stETH Address of the Lido/stETH contract
    constructor(address _weth, address _stETH) {
        if (_weth == address(0) || _stETH == address(0))
            revert ZeroAddressException();

        stETH = IstETH(_stETH);
        weth = IWETH(_weth);
    }

    /// @dev Implements logic allowing CA's to call `submit` in Lido, which uses native ETH
    /// - Transfers WETH from senders and unwraps into ETH
    /// - Submits ETH to Lido
    /// - Sends resulting stETH back to sender
    /// @param amount The amount of WETH to unwrap into ETH and submit
    /// @param _referral The address of the referrer
    function submit(uint256 amount, address _referral)
        external
        returns (uint256 value)
    {
        IERC20(address(weth)).transferFrom(msg.sender, address(this), amount);
        weth.withdraw(amount);

        value = stETH.submit{value: amount}(_referral);
        stETH.transfer(msg.sender, stETH.balanceOf(address(this)));

    }

    receive() external payable {}
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IstETH is IERC20 {
    // TODO: Check these functions
    //    function getPooledEthByShares(uint256 _sharesAmount)
    //        external
    //        view
    //        returns (uint256);
    //
    //    function getSharesByPooledEth(uint256 _pooledEthAmount)
    //        external
    //        view
    //        returns (uint256);

    function submit(address _referral) external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.4;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

/// @dev Common contract exceptions

/// @dev throws if zero address is provided
error ZeroAddressException();

/// @dev throws if non implemented method was called
error NotImplementedException();

/// @dev throws if expected contract but provided non-contract address
error AddressIsNotContractException(address);

/// @dev throws if token has no balanceOf(address) method, or this method reverts
error IncorrectTokenContractException();

/// @dev throws if token has no priceFeed in PriceOracle
error IncorrectPriceFeedException();

/// @dev throw if caller is not CONFIGURATOR
error CallerNotConfiguratorException();

/// @dev throw if caller is not PAUSABLE ADMIN
error CallerNotPausableAdminException();

/// @dev throw if caller is not UNPAUSABLE ADMIN
error CallerNotUnPausableAdminException();
// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
pragma abicoder v1;

import "@1inch/solidity-utils/contracts/OnlyWethReceiver.sol";
import "@1inch/solidity-utils/contracts/interfaces/IWETH.sol";

import "../interfaces/IPostInteractionNotificationReceiver.sol";
import "../libraries/Errors.sol";

contract WethUnwrapper is OnlyWethReceiver, IPostInteractionNotificationReceiver {
    IWETH private immutable _WETH;  // solhint-disable-line var-name-mixedcase

    uint256 private constant _RAW_CALL_GAS_LIMIT = 5000;

    constructor(IWETH weth) OnlyWethReceiver(address(weth)) {
        _WETH = weth;
    }

    function fillOrderPostInteraction(
        bytes32 /* orderHash */,
        address maker,
        address /* taker */,
        uint256 /* makingAmount */,
        uint256 takingAmount,
        uint256 /* remainingMakerAmount */,
        bytes calldata /* interactiveData */
    ) external override {
        _WETH.withdraw(takingAmount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = maker.call{value: takingAmount, gas: _RAW_CALL_GAS_LIMIT}("");
        if (!success) revert Errors.ETHTransferFailed();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
pragma abicoder v1;

/**
 * @title Interface for interactor which acts after `taker -> maker` transfers.
 * @notice The order filling steps are `preInteraction` =>` Transfer "maker -> taker"` => `Interaction` => `Transfer "taker -> maker"` => **`postInteraction`**
 */
interface IPostInteractionNotificationReceiver {
    /**
     * @notice Callback method that gets called after all funds transfers
     * @param orderHash Hash of the order being processed
     * @param maker Maker address
     * @param taker Taker address
     * @param makingAmount Actual making amount
     * @param takingAmount Actual taking amount
     * @param remainingAmount Limit order remaining maker amount after the swap
     * @param interactionData Interaction calldata
     */
    function fillOrderPostInteraction(
        bytes32 orderHash,
        address maker,
        address taker,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 remainingAmount,
        bytes memory interactionData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Errors {
    error InvalidMsgValue();
    error ETHTransferFailed();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "./EthReceiver.sol";

abstract contract OnlyWethReceiver is EthReceiver {
    address private immutable _WETH;  // solhint-disable-line var-name-mixedcase

    constructor(address weth) {
        _WETH = address(weth);
    }

    function _receive() internal virtual override {
        if (msg.sender != _WETH) revert EthDepositRejected();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

abstract contract EthReceiver {
    error EthDepositRejected();

    receive() external payable {
        _receive();
    }

    function _receive() internal virtual {
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin) revert EthDepositRejected();
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
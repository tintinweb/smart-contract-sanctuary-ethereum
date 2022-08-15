// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libs/TransferUtils.sol";

interface ICurvePool {
    function exchange(
        int128 from,
        int128 to,
        uint256 input,
        uint256 minOutput
    ) external payable returns (uint256 output);

    function get_dy(
        int128 from,
        int128 to,
        uint256 input
    ) external view returns (uint256 output);
}

contract MockCurvePool is ICurvePool {
    using TransferUtils for IERC20;

    uint256 constant DENOMINATOR = 10000;
    uint256 constant N_COINS = 2;
    uint256 constant RATIO = 250; // 2.5%

    address[] public coins = new address[](N_COINS);
    address immutable deployer;

    event TokenExchange(
        address indexed buyer,
        int128 soldId,
        uint256 tokensSold,
        int128 boughtId,
        uint256 tokensBought
    );
    event Received(address indexed giver, uint256 amount);

    constructor(address stETH) {
        deployer = msg.sender;

        coins[0] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        coins[1] = stETH;
    }

    function exchange(
        int128 from,
        int128 to,
        uint256 input,
        uint256 minOutput
    ) external payable returns (uint256 output) {
        require(from < int256(N_COINS));
        require(to < int256(N_COINS));
        require(from != to);

        output = get_dy(from, to, input);
        require(output >= minOutput, "Exchange resulted in fewer coins than expected");

        emit TokenExchange(msg.sender, from, input, to, output);

        if (from == 0) {
            require(msg.value == input);
            IERC20(coins[1]).safeTransfer(msg.sender, output);
        } else {
            require(msg.value == 0);
            IERC20(coins[1]).safeTransferFrom(msg.sender, address(this), output);
            (bool success, ) = payable(msg.sender).call{ value: output }("");
            require(success, "Unable to send value");
        }
    }

    function get_dy(
        int128 from,
        int128 to,
        uint256 input
    ) public pure returns (uint256 output) {
        uint256 diff = (input * RATIO) / DENOMINATOR;

        if (from == 0 && to == 1) {
            return input + diff;
        } else if (from == 1 && to == 0) {
            return input - diff;
        }
    }

    function drain() external {
        require(msg.sender == deployer);
        (bool success, ) = payable(deployer).call{ value: address(this).balance }("");
        require(success, "Unable to send value");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferUtils {
    error TransferUtils__TransferDidNotSucceed();
    error TransferUtils__ApproveDidNotSucceed();

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, amount));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = address(token).call(data);
        if (!success || result.length > 0) {
            // Return data is optional
            bool transferSucceeded = abi.decode(result, (bool));
            if (!transferSucceeded) revert TransferUtils__TransferDidNotSucceed();
        }
    }
}
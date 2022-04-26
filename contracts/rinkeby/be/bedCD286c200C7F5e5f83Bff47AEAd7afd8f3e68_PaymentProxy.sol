// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PaymentProxy {
    event TransferViaToken(
        address token,
        address from,
        address indexed to,
        uint256 indexed amount,
        bytes32 indexed invoiceId
    );

    event TransferViaNative(
        address from,
        address indexed to,
        uint256 indexed amount,
        bytes32 indexed invoiceId
    );

    function transferViaToken(
        address _tokenERC20,
        address _to,
        uint256 _amount,
        bytes32 _invoiceId
    ) public {
        // Direct Transfer to Destination
        require(
            IERC20(_tokenERC20).transferFrom(msg.sender, _to, _amount),
            "Token Transfer Failed"
        );

        // Emit Event
        emit TransferViaToken(
            _tokenERC20,
            msg.sender,
            _to,
            _amount,
            _invoiceId
        );
    }

    function transferViaNative(
        address _to,
        uint256 _amount,
        bytes32 _invoiceId
    ) public payable {
        // Check msg.value
        require(msg.value == _amount, "Insufficient amount of Money");

        _safeTransferETH(_to, _amount);

        // Emit Event
        emit TransferViaNative(msg.sender, _to, _amount, _invoiceId);
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH Transfer Failed");
    }
}
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.18;

import "./interface/IBridgeGateway.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// BridgeGateway is CrossChain Bridge API for users.
// transferETH/transferERC20 transfers tokens from a user address
// to a maker address, which is choosen by user itself.
// The maker constantly monitoring ethereum, and transfer corresponding
// amount of token back to the user on the other blockchain.
// 
// The maker must know the following information:
//   * destination blockchain (from lp info)
//   * destination token (from lp info)
//   * user's address (from current tx)
//   * amount (from current tx)
//
//
// @param extInfo encodes information for maker and arbitrator
// the first data in extInfo is version:
//   version 1 (not transfer):
//     sessionId, lpid
//   version 2 (transfer)
//     sessionId, lpid, toAddress
//     
contract BridgeGateway is Context, IBridgeGateway {
    function bridgeETH(address payable maker,
		       uint256 lpid,
		       uint256 sessionId) external payable {
        (bool ok, ) = maker.call{value: msg.value}("");
	require(ok, "bridgeETH srcTx Error");
	emit BridgeEvent(_msgSender(), address(0), maker, msg.value, lpid, sessionId);
    }

    function bridgeERC20(address token,
			 address maker,
			 uint256 amount,
			 uint256 lpid,
			 uint256 sessionId) external {
	address sender = _msgSender();
        bool ok = IERC20(token).transferFrom(sender, maker, amount);
	require(ok, "bridgeERC20 srcTx Error");
	emit BridgeEvent(sender, token, maker, amount, lpid, sessionId);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18;

interface IBridgeGateway {
    event BridgeEvent(address indexed sender,
		      address indexed token,
		      address indexed maker,
		      uint256 amount,
		      uint256 lpid,
		      uint256 sessionId);

    function bridgeETH(address payable maker,
		       uint256 lpid,
		       uint256 sessionId) external payable;

    function bridgeERC20(address token,
			 address maker,
			 uint256 amount,
			 uint256 lpid,
			 uint256 sessionId) external;
}
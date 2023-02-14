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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract BatchOperation {

    struct UserERC20Balance {
        address user;
        uint256[] balance;
    }

    function batchGetBalance(address[] calldata addresses) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            balances[i] = addresses[i].balance;
        }
        return balances;
    }

    function batchIsSmartContract(address[] calldata addresses) public view returns (bool[] memory) {
        bool[] memory isSmartContracts = new bool[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 size;
            address addr = addresses[i];

            assembly {
                size := extcodesize(addr)
            }
            isSmartContracts[i] = size > 0;
        }
        return isSmartContracts;
    }

    function batchGetERC20BalanceByUser(address[] calldata addresses, address erc20Address) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            balances[i] = IERC20(erc20Address).balanceOf(addresses[i]);
        }
        return balances;
    }

    function batchGetERC20BalanceByContract(address addr, address[] calldata erc20Addresses) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](erc20Addresses.length);
        for (uint256 i = 0; i < erc20Addresses.length; i++) {
            balances[i] = IERC20(erc20Addresses[i]).balanceOf(addr);
        }
        return balances;
    }

    function batchGetERC20BalanceByContractAndUser(address[] calldata addresses, address[] calldata erc20Addresses) public view returns (UserERC20Balance[] memory) {
        UserERC20Balance[] memory userERC20Balances = new UserERC20Balance[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            userERC20Balances[i].user = addresses[i];
            userERC20Balances[i].balance = batchGetERC20BalanceByContract(addresses[i], erc20Addresses);
        }
        return userERC20Balances;
    }
}
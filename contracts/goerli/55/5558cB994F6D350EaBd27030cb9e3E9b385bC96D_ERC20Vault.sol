//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Vault {
    IERC20 _token;

    address public owner;
    uint256 public erc20Balance;
    uint256 public usdcBalance;
    uint256 public userCount;

    event LockERC20(
        address indexed erc20Addr,
        string destNetwork,
        string walletAddr,
        uint256 amount
    );
    event ReleaseERC20(address indexed erc20Addr, uint256 amount);
    event LockUSDC(
        address indexed erc20Addr,
        string destNetwork,
        string walletAddr,
        uint256 amount
    );
    event ReleaseUSDC(address indexed erc20Addr, uint256 amount);

    constructor() {
        // uint256 MAX_INT = 2**256 - 1;

        address token = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
        owner = msg.sender;
        _token = IERC20(token);

        // _token.approve(address(this), MAX_INT);
    }

    function lockERC20(string calldata destNetwork, string calldata algoAddr)
        external
        payable
        returns (uint256 id)
    {
        require(msg.value > 1000000000, "Sending amount is too small!");

        erc20Balance += msg.value;
        userCount++;

        emit LockERC20(msg.sender, destNetwork, algoAddr, msg.value);

        return userCount;
    }

    function releaseERC20(address erc20Addr, uint256 amount) external {
        require(msg.sender == owner, "You are not the owner!");

        require(erc20Balance > 0, "Balance is zero!");
        require(erc20Balance >= amount, "Balance is not enough to withdraw!");

        (bool sent, ) = erc20Addr.call{value: amount}("");
        require(sent, "Failed to send ERC20!");

        erc20Balance -= amount;

        emit ReleaseERC20(msg.sender, amount);
    }

    modifier checkAllowance(uint256 amount) {
        // require(amount > 1000000, "Sending amount is too small!");
        require(_token.allowance(msg.sender, address(this)) >= amount, "Error");
        _;
    }

    function lockUSDC(
        uint256 amount,
        string calldata destNetwork,
        string calldata algoAddr
    ) external returns (uint256 id) {
        _token.transferFrom(msg.sender, address(this), amount);
        userCount++;

        emit LockUSDC(msg.sender, destNetwork, algoAddr, amount);

        return userCount;
    }

    function releaseUSDC(address erc20Addr, uint256 amount) external {
        require(msg.sender == owner, "You are not the owner!");

        require(usdcBalance > 0, "Balance is zero!");
        require(usdcBalance >= amount, "Balance is not enough to withdraw!");

        (bool sent, ) = erc20Addr.call{value: amount}("");
        require(sent, "Failed to send ERC20!");

        usdcBalance -= amount;

        emit ReleaseERC20(msg.sender, amount);
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
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract FlashLoan {
    address public owner;
    mapping(address => bool) public admins;
    mapping(address => bool) public authorized;

    address public asset;
    uint256 public balance;

    struct Transaction {
        address from;
        address to;
        uint256 amount;
    }

    Transaction[] public depositHistory;
    Transaction[] public withdrawHistory;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);
    event Borrow(address indexed from, uint256 amount);
    event Repay(address indexed to, uint256 amount);

    modifier onlyOwner {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyAdmin {
        require(admins[msg.sender], "Not authorized");
        _;
    }

    modifier onlyAuthorized {
        require(authorized[msg.sender], "Not authorized");
        _;
    }

    constructor(address _owner, address _asset) {
        owner = _owner;
        asset = _asset;

        admins[owner] = true;
    }

    function addAdmin(address admin) external onlyOwner {
        admins[admin] = true;
    }

    function removeAdmin(address admin) external onlyOwner {
        admins[admin] = false;
    }

    function setAuthorized(address user, bool value) external onlyOwner {
        authorized[user] = value;
    }

    function deposit(uint256 amount) external onlyAdmin {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer the funds to this contract
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Update the balance
        balance += amount;

        // Add transaction to history
        depositHistory.push(Transaction(msg.sender, address(this), amount));

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyAdmin {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= balance, "Insufficient balance");

        // Transfer the funds to the owner
        require(IERC20(asset).transfer(msg.sender, amount), "Transfer failed");

        // Update the balance
        balance -= amount;

        // Add transaction to history
        withdrawHistory.push(Transaction(address(this), msg.sender, amount));

        emit Withdraw(msg.sender, amount);
    }

    function borrow(uint256 amount) external onlyAuthorized {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= balance, "Insufficient balance");

        // Transfer the funds to the borrower
        require(IERC20(asset).transfer(msg.sender, amount), "Transfer failed");

        // Update the balance
        balance -= amount;

        emit Borrow(msg.sender, amount);
    }

    function repay(uint256 amount) external onlyAuthorized {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer the funds from the borrower
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Update the balance
        balance += amount;

        emit Repay(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return balance;
    }

    function getDepositHistoryLength() external view returns (uint256) {
        return depositHistory.length;
    }

    function getWithdrawHistoryLength() external view returns (uint256) {
        return withdrawHistory.length;
    }

    function getDepositHistory(uint256 index) external view returns (Transaction memory) {
        require(index < depositHistory.length, "Index out of range");

        return depositHistory[index];
    }

    function getWithdrawHistory(uint256 index) external view returns (Transaction memory) {
        require(index < withdrawHistory.length, "Index out of range");

        return withdrawHistory[index];
    }
}
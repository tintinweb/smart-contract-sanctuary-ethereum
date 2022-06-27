// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CoinclashPayouts {

    mapping (address => bool) private whiteListedUsers;
    mapping (address => uint) userDepositBlockNumber;
    mapping (address => bool) adminAccess;

    address owner;
    address constant USDC = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709; //cahinlink token change it in final build.

    event Deposit(address indexed userAddress, uint amount);
    event DepositUSDC(address indexed userAddress, uint amount);
    event Withdraw(address indexed userAddress, uint amount);

    constructor() {
        owner = msg.sender;
        adminAccess[msg.sender] = true;
        whiteListedUsers[msg.sender] = true;
    }

    fallback() external payable {  //check it later
        require(msg.sender == owner, "only owner can deposit funds");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can access");
        _;
    }

    modifier onlyAdmin() {
        require(adminAccess[msg.sender], "only Admins can access");
        _;
    }

    function withdraw(address userAddress, uint amount) external onlyAdmin returns (bool){
        require(whiteListedUsers[userAddress], "User is not in the whitelist");
        require(block.number - userDepositBlockNumber[userAddress] > 4, "user cannot  withdraw funds now"); //change 4 to 250
        uint usdcBalance = IERC20(USDC).balanceOf(address(this));
        require(usdcBalance >= amount, "Insufficient USDC funds in the contract");
        userDepositBlockNumber[userAddress] = block.number;

        bool success = IERC20(USDC).transfer(userAddress, amount);
        require(success, "USDC withdrawal failed");
        emit Withdraw(userAddress, amount);
        return success;
    }

    function deposit() external payable {
        require(whiteListedUsers[msg.sender], "user is not in the whitelist");
        require(msg.value > 0, "Cannot deposit 0 ETH");
        emit Deposit(msg.sender, msg.value);

    }

    function depositUSDC(uint amount) external  {
        require(amount>0, "Cannot deposit 0 USDC");
        require(whiteListedUsers[msg.sender], "user is not the whitelist");
        require(IERC20(USDC).allowance(msg.sender, address(this)) >= amount, "User didn't approve the USDC transfer");
        bool success = IERC20(USDC).transferFrom(msg.sender, address(this), amount);
        require(success, "USDC Deposit failed");
        emit DepositUSDC(msg.sender, amount);

    }

    function whiteListUser(address userAddress) external onlyAdmin {
        if(whiteListedUsers[userAddress]){
            whiteListedUsers[userAddress]= false;
        }
        else {
            whiteListedUsers[userAddress] = true;
        }
    }

    function contractBalance() external view onlyOwner returns (uint) {
        return address(this).balance;
    }

    function contractUSDCBalance() external view onlyOwner returns (uint) {
        return IERC20(USDC).balanceOf(address(this));
    }

    function enableAdminAccess(address userAddress) external onlyOwner {
        adminAccess[userAddress] = true;
    }

    ///@notice only owner can withdraw funds
    function withdrawFunds() external onlyOwner {
        if(address(this).balance != 0){
            (bool success, ) = payable(owner).call{value: address(this).balance}("");
            require(success, "withdrawal failed");
        }
        uint usdcBalance = IERC20(USDC).balanceOf(address(this));
        if(usdcBalance != 0){
            bool success = IERC20(USDC).transfer(owner, usdcBalance);
            require(success, "USDC withdrawal failed");
        }
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
// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract FoeVesting {

    IERC20 token;

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Vested(address indexed account, uint256 indexed amount);
    event claimed(address indexed account, uint256 indexed amount);

    struct VestDetail {
        address user;
        uint256 amount;
        uint256 initialTime;
        uint256 lockDuration;
        uint256 vestingDurationInMonth;
        uint256 nextClaim;
        uint256 withdrawAmount;
        uint256 availableAmount;
        bool status;
    }

    mapping(address => VestDetail) vests;

    modifier onlyOwner {
        require (owner == msg.sender, "Ownable: caller is not a owner");
        _;
    }

    constructor(IERC20 _token) {
        token = _token;
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    function vest(address account, uint256 _amount, uint256 lockDurationInMonth, uint256 vestDurationInMonth) external onlyOwner returns(bool){
        require(!vests[account].status, "Already vested");
        require(_amount > 0, "Amount should be greater than zero");
        vests[account].amount = _amount;
        vests[account].initialTime = block.timestamp;
        vests[account].status = true;
        vests[account] = VestDetail(
            account,
            _amount,
            block.timestamp,
            block.timestamp + lockDurationInMonth * 60 seconds,
            vestDurationInMonth,
            block.timestamp + lockDurationInMonth * 60 seconds,
            0,
            _amount,
            true
        );
        require(token.transferFrom(msg.sender, address(this), vests[account].amount), "token transfer failed");
        emit Vested(account, vests[account].amount);
        return true;
    }

    function claim() external returns(bool) {
        require(vests[msg.sender].status, "Account not Vested");
        require(vests[msg.sender].lockDuration <= block.timestamp, "Lock duration not exceeds");
        require(block.timestamp >= vests[msg.sender].nextClaim, "Claim duration not exceeds");
        uint256 timeDiff = block.timestamp - vests[msg.sender].nextClaim;
        uint256 amountPerMonth = vests[msg.sender].amount / vests[msg.sender].vestingDurationInMonth;
        uint256 claimAmount = amountPerMonth;
        uint256 count = 1;
        if(timeDiff > 60 seconds) {
            count = timeDiff / 60 seconds;
            claimAmount = amountPerMonth * count;
        }
        claimAmount = claimAmount > vests[msg.sender].availableAmount ? vests[msg.sender].availableAmount : claimAmount;
        claimAmount = vests[msg.sender].availableAmount - claimAmount < amountPerMonth ? vests[msg.sender].availableAmount : claimAmount;
        require(token.transfer(msg.sender, claimAmount), "Token transfer failed");
        vests[msg.sender].nextClaim += count * 60 seconds;
        vests[msg.sender].withdrawAmount += claimAmount;
        vests[msg.sender].availableAmount -= claimAmount;
        vests[msg.sender].status = vests[msg.sender].availableAmount == 0 ? false : true;
        emit claimed(msg.sender, claimAmount);
        return true;
    }

    function getUserDetails(address account) external view returns(VestDetail memory) {
        return vests[account];
    }

    function bolock() view  public returns(uint256 blocks){
        blocks = block.timestamp;
    }

    function lock() view  public returns(uint256 blocks){
        blocks = vests[msg.sender].lockDuration;
    }

    function nxtclaims() view  public returns(uint256 blocks){
        blocks = vests[msg.sender].nextClaim;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenCrowdsale {

    event Allocated(address buyer, uint256 amount);

    mapping(address => uint256) public buyerToAllocation;
    uint256 public from;
    uint256 public to;
    IERC20 public token;
    IERC20 public asset;
    uint256 public rate;
    bool public isPaused;
    address private owner;
    uint256 private toClaim;

    constructor (IERC20 _asset) {
        owner = msg.sender;
        asset = _asset;
        rate = 40000000000000; // TODO (MUST) 40000000000000 EVERYWHERE BESIDES BSC WHERE IS 40 !!!!!!!!!!!!!!! BECAUSE OF 18 DIGIT USDC ON BSC
        from = 1656914400;
        to = 1658124000;
    }

    function deposit(uint256 amount) external {
        require(isPaused == false && amount > 0);
        uint256 timestamp = block.timestamp;
        require((timestamp >= from && timestamp <= to) || msg.sender == owner); // For final (just before sale) test
        uint256 remaining = getRemaining();
        uint256 allocated = rate * amount;
        require(remaining >= allocated);
        require(asset.allowance(msg.sender, address(this)) >= amount);
        asset.transferFrom(msg.sender, address(this), amount);
        buyerToAllocation[msg.sender] += allocated;
        toClaim += allocated;
    }

    function setToken(IERC20 _token) external {
        require(msg.sender == owner && address(token) == address(0));
        token = _token;
    }

    function withdrawAllocation() external {
        uint256 allocation = buyerToAllocation[msg.sender];
        require(allocation > 0 && block.timestamp > to);
        token.transfer(msg.sender, allocation);
        toClaim -= allocation;
        buyerToAllocation[msg.sender] = 0;
    }

    function withdrawDeposited() external {
        require(msg.sender == owner);
        uint256 deposited = asset.balanceOf(address(this));
        asset.transfer(owner, deposited);
    }

    function withdrawRemaining() external {
        require(msg.sender == owner && block.timestamp > to);
        uint256 remaining = getRemaining();
        token.transfer(owner, remaining);
    }

    function getRemaining() public view returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        return balance - toClaim;
    }

    function togglePause() external {
        require(msg.sender == owner);
        isPaused = !isPaused;
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
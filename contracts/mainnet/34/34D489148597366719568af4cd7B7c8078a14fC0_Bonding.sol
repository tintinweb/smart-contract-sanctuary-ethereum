/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
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

// File: bonding.sol


pragma solidity ^0.8.0;


contract Bonding {
    IERC20 public OHMToken;
    IERC20 public controlToken;

    address public owner;
    uint256 public bondPrice;
    uint256 public vestingDuration;

    mapping(address => uint256) public bonds;
    mapping(address => uint256) public bondPurchaseTimestamps;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function setOHMToken(IERC20 _OHMToken) public onlyOwner {
        OHMToken = _OHMToken;
    }

    function setControlToken(IERC20 _controlToken) public onlyOwner {
        controlToken = _controlToken;
    }

      function setBondPrice(uint256 _bondPrice) public onlyOwner {
        bondPrice = _bondPrice;
    }

    function setVestingDuration(uint256 _vestingDuration) public onlyOwner {
        vestingDuration = _vestingDuration;
    }

        function buyBond(uint256 amount) public {
        require(amount > 0, "Bond amount should be greater than 0");
        controlToken.transferFrom(msg.sender, address(this), amount);
        bonds[msg.sender] += amount;
        bondPurchaseTimestamps[msg.sender] = block.timestamp;
    }

    function redeemBond() public {
        require(bonds[msg.sender] > 0, "No bond to redeem");
        uint256 elapsedTime = block.timestamp - bondPurchaseTimestamps[msg.sender];
        uint256 vestedAmount = bonds[msg.sender] * elapsedTime / vestingDuration;
        require(vestedAmount > 0, "No vested bond to redeem");

        bonds[msg.sender] -= vestedAmount;
        uint256 OHMAmount = vestedAmount * bondPrice;
        OHMToken.transfer(msg.sender, OHMAmount);
    }

   
}
/**
 *Submitted for verification at Etherscan.io on 2023-03-10
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

// File: contracts/AQMLicense.sol

pragma solidity ^0.8.0;

contract AMQLicense {
    IERC20 public aqm;
    IERC20 public usdc;
    address public owner;
    uint256 public t1_price;
    uint256 public t2_price;

    mapping(string => uint256) public deviceLicenseExpiration;
    mapping(string => uint256) public deviceTier;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor(IERC20 _aqm, IERC20 _usdc) {
        aqm = _aqm;
        usdc = _usdc;
        owner = msg.sender;
        t1_price = 100 * (10 ** 6);
        t2_price = 720 * (10 ** 18);
    }

    function changeT1Price(uint256 newPrice) public onlyOwner{
        require(newPrice > 0, "Invalid price");
        t1_price = newPrice  * (10 ** 6);
    }

    function changeT2Price(uint256 newPrice) public onlyOwner{
        require(newPrice > 0, "Invalid price");
        t2_price = newPrice * (10 ** 18);
    }

    function buyT1(string memory deviceId) public{
        uint256 balance = usdc.balanceOf(msg.sender);
        require(balance >= t1_price, "Insufficient USDC funds");
        usdc.transferFrom(msg.sender, address(this), t1_price);
        deviceTier[deviceId] = 1;
        deviceLicenseExpiration[deviceId] = block.timestamp + 365 days;
    }

    function buyT2(string memory deviceId) public{
        uint256 balance = aqm.balanceOf(msg.sender);
        require(balance >= t2_price, "Insufficient AQM funds");
        aqm.transferFrom(msg.sender, address(this), t2_price);
        deviceTier[deviceId] = 2;
        deviceLicenseExpiration[deviceId] = block.timestamp + 365 days;
    }
    
    function removeDevice(string memory deviceId) public onlyOwner{
        delete deviceTier[deviceId];
        delete deviceLicenseExpiration[deviceId];
    }    

    function withdrawUSDC() public onlyOwner{
        usdc.transfer(owner, usdc.balanceOf(address(this)));
    }

    function withdrawAQM() public onlyOwner{
        aqm.transfer(owner, aqm.balanceOf(address(this)));
    }
}
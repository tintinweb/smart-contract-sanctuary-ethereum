/**
 *Submitted for verification at Etherscan.io on 2023-03-11
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

// File: contracts/AQMDeviceLicense.sol



contract AQMDeviceLicense {
    IERC20 public token;
    address public owner;

    mapping(uint256 => uint256) public tierPrices;
    mapping(string => uint256) public deviceExpiration;
    mapping(string => uint256) public deviceTier;

    mapping(address => uint256) public earnings;

    event BuyLicenseEvent(address indexed wallet, string indexed deviceId, uint256 tier);
    event ClaimEarningsEvent(address indexed wallet, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
        tierPrices[1] = 1 * (10 ** 18); 
        tierPrices[2] = 2 * (10 ** 18); 
    }

    function setPrice(uint256 tier, uint256 priceWei) external onlyOwner{
        require(tier >= 0, "Invalid tier");
        require(priceWei > 0, "Invalid price");
        tierPrices[tier] = priceWei;
    }

    function buyLicense(uint256 tier, string memory deviceId) external payable{
        require(tier >= 0, "Invalid tier. low");
        require(tier <= 10, "Invalid tier. high");

        uint256 price = tierPrices[tier];
        require(price >= 0, "Uknown price");

        require(msg.value == price, "Incorrect amount for this tier");

        address payable to = payable(owner);
        to.transfer(price);

        deviceTier[deviceId] = tier;
        deviceExpiration[deviceId] = block.timestamp + 365 days;

        emit BuyLicenseEvent(msg.sender, deviceId, tier);
    }

    function addEarnings(address[] memory wallets, uint256[] memory amountsWei) external onlyOwner{
        require(wallets.length == amountsWei.length, "Arrays length do not match");

        for( uint i = 0; i < wallets.length; i++ ) {
            earnings[wallets[i]] += amountsWei[i];            
        }
    }

    function claimEarnings() external{
        uint256 amount = earnings[msg.sender];
        require(amount > 0, "Nothing to claim");
        token.transfer(msg.sender, amount);
        emit ClaimEarningsEvent(msg.sender, amount);
    }

    function withdraw() external onlyOwner {
        address payable to = payable(owner);
        to.transfer(address(this).balance);
    }

    function withdrawTokens() public onlyOwner{
        token.transfer(owner, token.balanceOf(address(this)));
    }
   
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";

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

/**
 * @title Agora Labs USDC testnet faucet version 1.0
 *
 * @author Agora Labs
 */
contract AgoraFaucet is AccessControl {
    /// @dev Returns contract address of USDC token
    address public immutable USDC;

    /// @dev ROLE_WHITELIST_MANAGER allows managing whitelist addresses 
    uint32 public constant ROLE_WHITELIST_MANAGER = 0x0000_0001;

    /// @dev ROLE_ALLOCATION_MANAGER allows editing allocated amount of USDC
    uint32 public constant ROLE_ALLOCATION_MANAGER = 0x0000_0002;

    /// @dev ROLE_WITHDRAW_MANAGER allows to withdraw USDC from faucet
    uint32 public constant ROLE_WITHDRAW_MANAGER = 0x0000_0004;

    /// @dev Returns allocated amount of USDC per whitelisted address
    uint256 public allocation;

    /// @dev Returns `true` if given address is whitelisted
    mapping(address => bool) public isWhitelisted;

    /// @dev Returns `true` if given address has already claimed tokens  
    mapping(address => bool) public hasClaimed;

    /**
     * @dev Fired in Restricted access functions (onlyOwner)
	 *
	 * @param by address of owner who executes the transaction 
	 * @param functionIndex (1 = addToWhitelist, 2 = removeFromWhitelist,
     *                       3 = changeAllocation, 4 = withdraw)
	 */
    event Activity(address indexed by, uint8 indexed functionIndex); 

    /**
     * @dev Creates/Deploys Agora Labs USDC testnet faucet version 1.0
     *
     * @param usdcToken_ address of USDC token contract
     * @param allocation_ allocated amount of USDC per whitelisted address
     */
    constructor(address usdcToken_, uint256 allocation_) {
        USDC = usdcToken_;
        allocation = allocation_;
    }

    /**
     * @dev Returns USDC token balance of AgoraFaucet contract
     */
    function balance() external view returns(uint256) {
        return IERC20(USDC).balanceOf(address(this));
    }

    /**
     * @dev Adds given addresses to whitelist
     *
     * @param account_ address list of users to add into whitelist
     */
    function addToWhitelist(address[] memory account_) external {
        require(isSenderInRole(ROLE_WHITELIST_MANAGER), "Access denied");
        
        for(uint i; i < account_.length; i++) {
            isWhitelisted[account_[i]] = true;
        }
        
        emit Activity(msg.sender, 1);
    }

    /**
     * @dev Removes given addresses from whitelist
     *
     * @param account_ address list of users to remove from whitelist
     */
    function removeFromWhitelist(address[] memory account_) external {
        require(isSenderInRole(ROLE_WHITELIST_MANAGER), "Access denied");
        
        for(uint i; i < account_.length; i++) {
            isWhitelisted[account_[i]] = false;
        }
        
        emit Activity(msg.sender, 2);
    }

    /**
     * @dev Changes allocated amount of USDC per whitelisted address
     *
     * @param newAllocation_ allocated amount of USDC per whitelisted address
     */
    function changeAllocation(uint256 newAllocation_) external {
        require(isSenderInRole(ROLE_ALLOCATION_MANAGER), "Access denied");
        
        allocation = newAllocation_;
        
        emit Activity(msg.sender, 3);
    }

    /**
     * @dev Withdraws USDC to given address
     *
     * @param to_ address of receiver
     * @param amount_ amount of USDC tokens to be withdrawn
     */
    function withdraw(address to_, uint256 amount_) external {
        require(isSenderInRole(ROLE_WITHDRAW_MANAGER), "Access denied");
        
        IERC20(USDC).transfer(to_, amount_);
        
        emit Activity(msg.sender, 4);
    }

    /**
     * @dev Deposits USDC to AgoraFaucet
     *
     * @param amount_ amount of USDC tokens to be deposited
     */
    function deposit(uint256 amount_) external {
        IERC20(USDC).transferFrom(msg.sender, address(this), amount_);
    }

    /**
     * @dev Allows to claim USDC token for whitelisted user (one time only)
     */
    function claim() external {
        require(
            isWhitelisted[msg.sender] && !hasClaimed[msg.sender],
            "Access denied"
        );       
        
        hasClaimed[msg.sender] = true;
        
        IERC20(USDC).transfer(msg.sender, allocation);
    }    
}
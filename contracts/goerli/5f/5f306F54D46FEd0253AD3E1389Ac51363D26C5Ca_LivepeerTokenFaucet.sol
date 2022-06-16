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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILivepeerToken is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ILivepeerToken.sol";

import "../zeppelin/Ownable.sol";

/**
 * @title Faucet for the Livepeer Token
 */
contract LivepeerTokenFaucet is Ownable {
    // Token
    ILivepeerToken public token;

    // Amount of token sent to sender for a request
    uint256 public requestAmount;

    // Amount of time a sender must wait between requests
    uint256 public requestWait;

    // sender => timestamp at which sender can make another request
    mapping(address => uint256) public nextValidRequest;

    // Whitelist addresses that can bypass faucet request rate limit
    mapping(address => bool) public isWhitelisted;

    // Checks if a request is valid (sender is whitelisted or has waited the rate limit time)
    modifier validRequest() {
        require(isWhitelisted[msg.sender] || block.timestamp >= nextValidRequest[msg.sender]);
        _;
    }

    event Request(address indexed to, uint256 amount);

    /**
     * @notice LivepeerTokenFacuet constructor
     * @param _token Address of LivepeerToken
     * @param _requestAmount Amount of token sent to sender for a request
     * @param _requestWait Amount of time a sender must wait between request (denominated in hours)
     */
    constructor(
        address _token,
        uint256 _requestAmount,
        uint256 _requestWait
    ) {
        token = ILivepeerToken(_token);
        requestAmount = _requestAmount;
        requestWait = _requestWait;
    }

    /**
     * @notice Add an address to the whitelist
     * @param _addr Address to be whitelisted
     */
    function addToWhitelist(address _addr) external onlyOwner {
        isWhitelisted[_addr] = true;
    }

    /**
     * @notice Remove an address from the whitelist
     * @param _addr Address to be removed from whitelist
     */
    function removeFromWhitelist(address _addr) external onlyOwner {
        isWhitelisted[_addr] = false;
    }

    /**
     * @notice Request an amount of token to be sent to sender
     */
    function request() external validRequest {
        if (!isWhitelisted[msg.sender]) {
            nextValidRequest[msg.sender] = block.timestamp + requestWait * 1 hours;
        }

        token.transfer(msg.sender, requestAmount);

        emit Request(msg.sender, requestAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/Contracts_farra/node_manager.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

//IMPORTANTE !!!!! LA FUNCION APPROVE ESTA PROGRAMADA COMO X/10**decimales es decir si queremos aprovar 1000 tokens con 2 decimals debemos poner 100000



pragma solidity ^0.8.0;



interface MyToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

}

contract NodeManager {
    IERC20 private myToken;
    mapping (address => bool) public whitelist;
    mapping (address => uint256) public balances;
    address public owner;

    constructor(IERC20 token) {
        myToken = token;
        whitelist[msg.sender] = true; //Añadimos privilegios de WL al owner
        owner = msg.sender; // Asignamos la dirección del remitente como el propietario del contrato
    }

    function transfer(address recipient, uint256 amount) public onlyOwner returns (bool) {
        require(whitelist[recipient] == true, "Not whitelisted");
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        require(recipient != address(0), "Invalid address.");
        balances[msg.sender] -= amount;
        return myToken.transferFrom(address(this), recipient, amount);
    }

    function deposit(uint256 amount) public onlyWhitelisted {
        require(myToken.balanceOf(msg.sender) >= amount, "Insufficient token balance.");
        require(myToken.allowance(msg.sender, address(this)) >= amount, "Token approval required.");
        balances[msg.sender] += amount;
        myToken.transferFrom(msg.sender, address(this), amount);
    }

    function setTokenApproval(uint256 amount) public {
        myToken.approve(address(this), amount);
    }

    function addToWhitelist(address wallet) public onlyOwner {
        whitelist[wallet] = true;
    }

    function deleteWhitelisted (address wallet) public onlyOwner {
        whitelist[wallet] = false;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Sender is not whitelisted.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}
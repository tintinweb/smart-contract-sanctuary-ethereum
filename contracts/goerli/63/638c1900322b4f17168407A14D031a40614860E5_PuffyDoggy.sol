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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin-contracts/interfaces/IERC20.sol";
import {IPuffyDoggyErrors} from "./IPuffyDoggyErrors.sol";

interface IPuffyDoggy is IERC20, IPuffyDoggyErrors {
    function burn(uint256 burnAmount) external returns (bool);

    // Owner functions
    function mint(address to, uint256 mintAmount) external returns (bool);

    function burn(address from, uint256 burnAmount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IPuffyDoggyErrors {
    error PuffyDoggy__toZeroAddress();
    error PuffyDoggy__fromZeroAddress();
    error PuffyDoggy__amountExceedsBalance();
    error PuffyDoggy__approveToNonZero();
    error PuffyDoggy__approveToYourself();

    error PuffyDoggy__burnAmountExceedsBalance(
        uint256 burnAmount,
        uint256 balance
    );

    error PuffyDoggy__insufficientAllowance(
        uint256 currentAllowance,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

error Ownable__notAnOwner();
error Ownable__newOwnerIsZero();

contract Ownable {
    address private s_owner;

    /**
     * @notice Will be emitted when owner is changed.
     *
     * @param oldOwner who initiated transfer ownership
     * @param newOwner address of the new owner
     */
    event OwnershipTransfered(
        address indexed oldOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        if (s_owner != msg.sender) revert Ownable__notAnOwner();
        _;
    }

    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Transfer ownership to the {newOwner}.
     * @param newOwner address of the new owner, can't be 0x0 address.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert Ownable__newOwnerIsZero();
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfer ownership to 0x0 address,
     * @notice which means that access to the governance functions will be lost forever!
     *
     * @notice Can be called only by current owner.
     */
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = s_owner;

        s_owner = newOwner;
        emit OwnershipTransfered(oldOwner, newOwner);
    }

    /**
     * @return address of the contract owner.
     */
    function owner() external view returns (address) {
        return s_owner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Ownable} from "./Ownable.sol";
import {IPuffyDoggy} from "./Interfaces/PuffyDoggy/IPuffyDoggy.sol";

contract PuffyDoggy is Ownable, IPuffyDoggy{
    uint256 private s_totalSupply;

    mapping(address owner => uint256 balance) private s_balances;
    mapping(address owner => mapping(address spender => uint256 allowance)) private s_allowances;

    string private s_name;
    string private s_symbol;

    /**
     * @notice Initializing token metadata {name} and {symbol},
     * @notice metadata is immutable and can be setted only once
     * @param _name - name of the token
     * @param _symbol - symbol of the token
     */ 
    constructor(string memory _name, string memory _symbol) {
        s_name = _name;
        s_symbol = _symbol;
    }

    /// @return name of the token
    function name() external view returns (string memory) {
        return s_name;
    }
    
    
    /// @return symbol of the token
    function symbol() external view returns (string memory) {
        return s_symbol;
    }

    /// @return decimals of the token
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /// @return total amount of tokens
    function totalSupply() external view returns (uint256) {
        return s_totalSupply;
    }

    /**
    * @notice Getting the balance of a specific user.
    * @param user - address of the user, whose balance will be returned
    */
    function balanceOf(address user) external view returns (uint256) {
        return s_balances[user];
    }

    /**
     * @return the remaining number of tokens that {spender} will be
     * allowed to spend on behalf of {owner} through {transferFrom}.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return s_allowances[owner][spender];
    }

    /**
    * @notice Moves {amount} tokens from the caller's account to {to}.
    * @param to - receiver address
    * @param amount - amount will be transferred
    */
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * Moves `amount` tokens from {from} to {to} using the
     * allowance mechanism. {amount} is then deducted from the caller's
     * allowance.
     * 
     * @param from - address from will be transferred tokens
     * @param to - receiver address
     * @param amount - amount of tokens
     */
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = s_allowances[from][msg.sender];
        if(amount > currentAllowance) revert PuffyDoggy__insufficientAllowance(currentAllowance, amount);
        
        if(currentAllowance != type(uint256).max) {
            unchecked {_approve(from, msg.sender, currentAllowance - amount);}
        }
        
        _transfer(from, to, amount);
        return true;
    }

    /**
    * @notice Sets {amount} as the allowance of {spender} over the caller's tokens.
    * @param spender - address which will receive allowance to transfer tokens
    * @param amount - amount of tokens
    */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * Atomically increases the allowance granted to {spender} by the caller.
     * @param spender - address which will receive allowance to transfer tokens
     * @param addValue - value will be added to allowance
     */
    function increaseAllowance(address spender, uint256 addValue) public returns (bool) {
        _approve(msg.sender, spender, s_allowances[msg.sender][spender] + addValue);
        return true;
    }

    /**
     * @notice Atomically decreases the allowance granted to {spender} by the caller.
     * @param spender - address which will receive allowance to transfer tokens
     * @param subValue - value will be subtracted from allowance
     */
    function decreaseAllowance(address spender, uint256 subValue) public returns (bool) {
        uint256 oldAllowance = s_allowances[msg.sender][spender];
        uint256 updatedAllowance = oldAllowance > subValue ? oldAllowance - subValue : 0;

        _approve(msg.sender, spender, updatedAllowance);
        return true;
    }

    /**
    * @notice Increase balance of the {to} to {mintAmount}
    * @param to - address which will receive tokens
    * @param mintAmount - amount of tokens which will be minted
    */
    function mint(address to, uint256 mintAmount) external onlyOwner returns (bool) {
       if(to == address(0)) revert PuffyDoggy__toZeroAddress();

        s_totalSupply += mintAmount;
        // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
        unchecked{s_balances[to] += mintAmount;}

        emit Transfer(address(0), to, mintAmount);

        return true;
    }

    /**
     * @notice Decrease {burnAmount} from caller balance
     * @param burnAmount - amount will be decreased
     */
    function burn(uint256 burnAmount) external returns (bool) {
        _burn(msg.sender, burnAmount);
        return true;
    }

    /**
     * @notice Decrease {burnAmount} from {from} balance
     * @param from - address from which will be decreased {burnAmount}
     * @param burnAmount - amount will be decreased
     */
    function burn(address from, uint256 burnAmount) external onlyOwner returns (bool) {
        _burn(from, burnAmount);

        return true;
    }

    function _burn(address from, uint256 burnAmount) private {
        if(from == address(0)) revert PuffyDoggy__fromZeroAddress();

        uint256 fromBalance = s_balances[from];
        if(burnAmount > fromBalance) 
            revert PuffyDoggy__burnAmountExceedsBalance(burnAmount, fromBalance);

        unchecked{
            s_balances[from] = fromBalance - burnAmount;

            // Overflow not possible: burnAmount <= fromBalance <= totalSupply.
            s_totalSupply -= burnAmount;
        }

        emit Transfer(from, address(0), burnAmount);

    }

    function _transfer(address from, address to, uint256 amount) private {
        validateToAndFrom(from, to);

        uint256 fromBalance = s_balances[from];
        if(amount > fromBalance) revert PuffyDoggy__amountExceedsBalance();

        unchecked{
            s_balances[from] = fromBalance - amount;
            s_balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        validateToAndFrom(owner, spender);
        if(owner == spender) revert PuffyDoggy__approveToYourself();

        s_allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function validateToAndFrom(address from, address to) private pure {
        if(from == address(0)) revert PuffyDoggy__fromZeroAddress();
        if(to == address(0)) revert PuffyDoggy__toZeroAddress();
    }
}
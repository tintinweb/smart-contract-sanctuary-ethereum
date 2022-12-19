// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./IFusionToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract FusionToken is IFusionToken {

    using SafeMath for uint;
    string private _name= "Fusion";
    string private _symbol = "ION";
    uint private _decimal = 18;
    address private _owner;
    uint private _totalSupply;
    mapping (address => uint) private _balance;
    mapping (address => mapping (address => uint)) private _allowances;

    constructor ()
    {       
        require(msg.sender != address(0),"OWNER_ERROR");
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require(_owner == msg.sender,"Caller is not the owner");
        _;
    }

    /// @notice totalSupply returns the total supply of the minted Fusion Token
        function totalSupply() external view override returns (uint) {
            return _totalSupply;
        }

    function decimal() external view override returns (uint) {
        return _decimal;
    }

    ///@notice balanceOf: returns the owner of the contract 
    /// @param account: check balance of this account
    function balanceOf(address account) external view override returns (uint) {
        return _balance[account];
    }

    ///@notice name: returns the name of the token
    function name() external view override returns (string memory) {
        return _name;
    }

    ///@notice symbol: returns the symbol associated with the token
    function symbol() external view override returns (string memory) {
        return _symbol;
    }


    ///@notice owner: returns the owner of the contract 
    function owner() external view returns (address) {
        return _owner;
    }

    function allowance(
        address spender
    ) external view override returns (uint) {
        return _allowances[_owner][spender];
    }
   
    /// @notice mint, external mint function, mints tokens to the owner's account
    ///@param account, the account that received the minted tokens
    /// @param amount , minted amount
    /// @return bool, true if the operation succeeds
    function mint(address account,uint amount) external override onlyOwner returns (bool) {
        _mint(account,amount);
        return true;
    }
    /// @notice _mint, internal function that handles the mint operation, checks, events to the owner
    /// @param account, receiver of the tokens
    /// @param amount , amount of tokens minted
    function _mint(address account,uint amount) internal virtual  {
        // require (amount<= _totalSupply,"INVALID_MINT_AMOUNT");
         _balance[account] = _balance[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(account,amount );
    }

    /// @notice burn, external burn function, will burn tokens from the owner's account
    ///@param account, the account from which tokens will be burned
    /// @param amount , the amount of tokens to be burned
    /// @return boolean, returns true if the operation succeeds
    function burn(address account, uint amount) external override onlyOwner returns (bool) {
        _burn(account, amount);
        return true;
    }

    /// @notice _burn, internal burn function, handles the events and checks before burning tokesn from owner's account
   ///@param account, the account from which tokens will be burned
   /// @param amount , the amount of tokens to be burned
    function _burn(address account, uint amount) internal virtual {
        require(_balance[account]>= amount, "INSUFFICIENT_BALANCE_TO_BURN");
        _balance[account] = _balance[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(address(0),amount );

    }

    /// @notice transferFrom, sends the allowance amount alloted to msg.sender on behalf of owner to the recipeient, emits Transfer event. 
    /// @param recipient  spender seeking an allowance on behalf on msg.sender
    /// @param amount the allowance amount
    /// @dev calls the internal _transfer function , adjusts the allowance, emits Transfer and Approval events.
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        _transfer(sender,recipient,amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /// @notice transfer, sends amount to recipient, emits Transfer event. 
    /// @param recipient  spender seeking an allowance on behalf on msg.sender
    /// @param amount the allowance amount
    /// @dev checks balances of sender >= amount, checks of recipent != zero address
    function transfer(
        address recipient,
        uint amount
    ) external  override returns (bool) {
        _transfer(msg.sender,recipient,amount);
        return true;
    }


    /// @notice _transfer, internal function that handles sending amount to recipient, emits Transfer event. 
    /// @param recipient  spender seeking an allowance on behalf on msg.sender
    /// @param amount the allowance amount
    /// @dev checks balances of sender >= amount, checks of recipent != zero address, adjusts the balances and emits the Transfer event
    function _transfer(
        address sender,
        address recipient,
        uint amount
    ) internal {
        require(_balance[sender] >= amount,"INSUFFICIENT_FOR_TRANSFER");
        require(recipient != address(0),"INVALID_RECIPIENT");
        _balance[sender]= _balance[sender].sub(amount);
        _balance[recipient]= _balance[recipient].add(amount);
        emit Transfer(recipient,amount);
         }



    /// @notice approve, sets approval for the spender on behalf on msg.sender for amount
    /// @param spender  spender seeking an allowance on behalf on msg.sender
    /// @param amount the allowance amount
    /// @dev emits an approval event
    function approve(
        address spender,
        uint amount
    ) external override onlyOwner returns (bool) {
        _approve(_owner, spender, amount);
        return true;
    }

    /// @notice _approve, internal function that handles the approval for the spender on behalf on owner for amount
    /// @param account  owner of the funds
    /// @param spender  spender seeking an allowance on behalf of the owner
    /// @param amount the allowance amount
      function _approve(
        address account,
        address spender,
        uint amount
    ) internal  {
        require(account != address(0),"INVALID_OWNER_ADDRESS");
        require(spender != address(0),"INVALID_SPENDER_ADDRESS");
        _allowances[account][spender] = amount;
        emit Approval(account,spender,amount);
    }



}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;


interface IFusionToken {


    /// @dev Transfer event triggered when 'amount' is transferred to 'recipient' along with ETH 'value' sent
    /// 'value' can be left as 0  
    /// Emitted from mint, burn, transferFrom, transfer, transferFrom_Wei, transfer_Wei functions
    event Transfer(address recipient, uint amount);

    /// @dev Approval event triggered when allowance for 'spender' on behalf of 'owner' is updated to 'amount' 
    /// emitted from allowance, approve functions
    event Approval(address owner, address spender, uint amount);



    /// @notice totalSupply returns the total supply of the minted Fusion Token
    function totalSupply() external view returns (uint);

    /// @notice name returns the name of the token
    function name() external view returns (string memory);
    

    /// @notice symbol returns the symbool of the token
    function symbol() external view returns (string memory);

   /// @notice decimal the decimal value for the token, by default set to 18 to mimic ETH to WEI conversion
    ///
    function decimal() external view returns (uint);


    /// @notice balanceOf returns the balance of the account in unit
    /// @param owner , the account balance to return
    function balanceOf(address owner) external view returns (uint);


    /// @notice allowance, sets the allowance for spender on behalf of owner, emits Approval event
    /// @param spender , account that plans to spend on behalf of the owner
    function allowance(address spender) external view returns (uint);

 

    /// @notice transferFrom, will transfer amount from owner to recipient, tigger the Transfer event, return bool  (pass/fail)
    /// @param owner , receiver of the tokens
    /// @param recipient , receiver of the tokens
    /// @param amount , amount received by the recipient 
    function transferFrom(address owner, address recipient, uint amount) external  returns (bool);
   
    /// @notice transfer, will transfer amount to recipient, tigger the Transfer event, return bool  (pass/fail)
    /// @param recipient, receives tokens
    /// @param amount , amount of tokens transferred
    function transfer(address recipient, uint amount) external  returns (bool);


   /// @notice approve, will approve the spender for an allowance of amount, emits Approval event, returns boolean
    /// @param spender , spender of the approved funds
    /// @param amount , amount set as allowance or approved to spend from the msg.sender
    function approve(address spender, uint amount) external returns (bool);

    ///@notice mint, mints tokens to account
    ///@param account, address receiving the funds
    ///@param amount, amount of tokens to be minted
    function mint(address account, uint amount) external returns (bool);

    ///@notice burn, burns tokens from the account, returns bool
    ///@param account, address receiving the funds
    ///@param amount, amount of tokens to be burned
    function burn(address account, uint amount) external returns (bool);

}
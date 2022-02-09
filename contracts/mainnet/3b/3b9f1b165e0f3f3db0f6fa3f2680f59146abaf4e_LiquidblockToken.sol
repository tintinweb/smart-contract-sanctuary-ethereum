/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

interface IERC20{
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function totalSupply() external view returns (uint );

    function decimals() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function approve(address sender , uint value)external returns(bool);

    function allowance(address sender, address spender) external view returns (uint256);

    function transfer(address recepient , uint value) external returns(bool);

    function transferFrom(address sender,address recepient, uint value) external returns(bool);

    event Transfer(address indexed from , address indexed to , uint value);

    event Approval(address indexed sender , address indexed  spender , uint value);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context{
    
    constructor () {}
   function _msgsender() internal view returns (address) {
    return msg.sender;
  }
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */

// File: openzeppelin-solidity/contracts/math/SafeMath.sol
library safeMath{
    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint a , uint b) internal pure returns(uint){
        uint c = a+ b;
        require(c >= a, "amount exists");
        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint a , uint b , string memory errorMessage) internal pure returns(uint){
        uint c = a - b;
        require( c <= a , errorMessage );
        return c;
    }

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File: @openzeppelin/contracts/access/Ownable.sol


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context{
    address private _Owner;

    event transferOwnerShip(address indexed _previousOwner , address indexed _newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(){
        address msgsender = _msgsender();
        _Owner = msgsender;
        emit transferOwnerShip(address(0),msgsender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function checkOwner() public view returns(address){
        return _Owner;
    }

     /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier OnlyOwner(){
       require(_Owner == _msgsender(),"Ownable: caller is not the owner");
       _; 
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public OnlyOwner {
      _transferOwnership(_newOwner);
    }
    
    function _transferOwnership(address _newOwner) internal {
      require(_newOwner != address(0),"Owner should not be 0 address");
      emit transferOwnerShip(_Owner,_newOwner);
      _Owner = _newOwner;
    }
}


// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract LiquidblockToken is Context, IERC20, Ownable {
    using safeMath for uint;

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;

    string private _name;
    string private _symbol;
    uint private _decimal;
    uint private _totalSupply;

    constructor(){
       _name = "Liquidblock";
       _symbol = "LQB";
       _decimal = 18;
       _totalSupply = 100000000*10**18;
       _balances[msg.sender] = _totalSupply;

       emit Transfer(address(0), msg.sender, _totalSupply);
    }


    /**
    * @return the name of the token.
    */
    function name() external override view returns(string memory){
        return _name;
    }

    /**
    * @return the symbol of the token.
    */
    function symbol() external view override returns(string memory){
        return _symbol;
    }

    /**
    * @return the number of decimals of the token.
    */
    function decimals() external view override  returns(uint){
        return _decimal;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) external view override  returns(uint){
        return _balances[owner];
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() external view override  returns(uint){
        return _totalSupply;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender , uint value) external override returns(bool){
        _approve(_msgsender(), spender , value);
        return true;
    }

     /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param sender address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address sender , address spender) external view override returns(uint){
          return _allowances[sender][spender];
    }

     /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
           _approve(_msgsender(), spender, _allowances[_msgsender()][spender].add(addedValue));
           return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
      _approve(_msgsender(), spender, _allowances[_msgsender()][spender].sub(subtractedValue, "LQB: decreased allowance below zero"));
      return true;
    }

    /**
    * @dev Transfer token for a specified address
    * @param recepient The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address recepient , uint value) external override returns(bool){
        _transfer(msg.sender, recepient,value);
         return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param sender address The address which you want to send tokens from
     * @param recepient address The address which you want to transfer to
     * @param amount uint256 the amount of tokens to be transferred
     */
    function transferFrom(address sender ,address recepient, uint amount) external override returns(bool){
        _approve(sender, _msgsender(), _allowances[sender][_msgsender()].sub(amount,"exceeds allownace"));
        _transfer(sender,recepient,amount);
        return true;
    }

     /**
     * @dev Burns token balance in "account" and decrease totalsupply of token
     * Can only be called by the current owner.
     */
    function burn(uint256 amount) public OnlyOwner returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param sender The address to transfer from.
    * @param recepient The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address sender,address recepient, uint value) internal  returns(bool success){
        require(_balances[sender] >= value,"Balance not enough");
        _balances[sender] = _balances[sender].sub(value,"Exceeds balance");
        _balances[recepient] = _balances[recepient].add(value);
        emit Transfer(_msgsender(), recepient , value);
        return true;
    }

     /**
    * @dev Approve token for a specified addresses
    * @param sender The address to transfer from.
    * @param spender The address to transfer to.
    * @param amount The amount to be transferred.
    */
    function _approve(address sender,address spender, uint amount) internal returns(bool success){
        require(sender != address(0),"Should not be 0 address");
        require(spender != address(0),"Should not be zero address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
        return true;
    }
    
    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param amount The amount that will be burnt.
     */
    function _burn(address account, uint256 amount) internal {
       require(account != address(0), " LQB: burn from the zero address");
       _balances[account] = _balances[account].sub(amount, " LQB: burn amount exceeds balance");
       _totalSupply = _totalSupply.sub(amount,"cant burn");
       emit Transfer(account, address(0), amount);
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.25 <0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
* @desc A coin system implementation following the ERC20 standard.
*/

contract thesis is Ownable{

    //Declarations of the variables used in the contract.
    mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping (uint256 => address) private device;
    uint256 private _totalCoins;
    string private _name;
    string private _symbol;

    //Declarations of the events used in the contract.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /*
    * @desc The constructor function called just once.
    */

    constructor(string memory givenName, string memory givenSymbol) public{

        _name = givenName;
        _symbol = givenSymbol;
    
    }

    /*
    * @desc Returns the name of the coin.
    * @return The name of the coin.
    */

    function name() public view returns (string memory){
        return _name;
    }

    /*
    * @desc Returns the symbol of the coin.
    * @return The symbol of the coin.
    */

    function symbol() public view returns (string memory){
        return _symbol;
    }

    /*
    * @desc Returns the number of decimals of the coin.
    * @return Fixed number of 18 decimals.
    */

    function decimals() public view returns (uint8){
        return 18;
    }


    /*
    * @desc Returns the total supply of coins.
    * @return The total amount of coins.
    */

    function totalSupply() public view returns (uint256){

        return _totalCoins;

    } 

    /*
    * @desc Returns the balance of the specified address.
    * @param owner The address whose balance is needed.
    * @return The balance of the specified address.
    */

    function balanceOf(address owner) public view returns (uint256){

        return _balance[owner];

    }

    /*
    * @desc Returns the amout of coins an address is allowed to spend from another address' balance.
    * @param owner The address whose coins are allowed to be spent.
    * @param spender The address which is allowed to spend the coins.
    * @return The number of coins allowed to be spent.
    */

    function allowance(address owner, address spender) public view returns (uint256){

        return _allowed[owner][spender];

    }

    /*
    * @desc Sends an amount of coins from the caller's balance to another address. 
    * @param to The address where the coins will be transfered.
    * @param value The amount of coins that will be transfered.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function transfer(address to, uint256 value) public returns (bool){

        address from = msg.sender;
        executeTransfer(from, to, value);
        return true;

    }

    /*
    * @desc Sends an amount of coins from an address' balance to another address on behalf of the caller.
    * @param from The address whose funds will be transfered.
    * @param to The address where the coins will be transfered.
    * @param value The amount of coins that will be transfered.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function transferFrom(address from, address to, uint256 value) public returns (bool){

        address spender = msg.sender; 
        executeTransferFrom(from, spender, to, value);
        return true;

    }

    /*
    * @desc Allows an address to spend an amount of the caller's coins. 
    * @param spender The address which is allowed to spend the other address' funds.
    * @param value The amount of the owner's coins the spender is allowed to spend.
    * @return Returns true if the execution is successful and false otherwise.
    */

    function approve(address spender, uint256 value) public returns (bool){

        address owner = msg.sender;
        executeApprove(owner, spender, value);
        return true;

    }

    /*
    * @desc Adjusts the amount of an address' funds an other address is allowed to spend. 
    * @param owner The addres whose funds are allowed to be spent.
    * @param spender The address whose allowance to spend another address' funds is adjusted.
    * @param value The amount by which the allowance will be adjusted.
    * @return Returns true if the execution is successful and false otherwise.
    */

    function adjustAllowed(address owner, address spender, int value) public onlyOwner returns (bool){

        require (spender != address(0), "Null address not acceptable");
        require (owner != address(0), "Null address not acceptable");

        //If the amount is positive the allowance is increased. It is decreased otherwise. 
        if (value > 0){
            _allowed[owner][spender] += uint256(value);
        }else{
            _allowed[owner][spender] -= uint256(-value);
        }
        
        emit Approval(owner, spender, _allowed[owner][spender]);
        return true;

    }

    /*
    * @desc Creates an amount of new coins and gives them to an address.
    * @param target The address whose the new coins will be.
    * @param value The amount of coins that will be created as a uint256.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function mint(address target, uint256 value) public onlyOwner returns (bool) {

        require (target != address(0), "Null address not acceptable");

        _balance[target] += value;
        _totalCoins += value;

        emit Transfer(address(0), target, value);
        return true;

    }

    /*
    * @desc Destroys an amount of coins from an address' balance.
    * @param from The address whose coins will be destroyed.
    * @param value The amount of coins that will be destroyed.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function burn(address from, uint256 value) public onlyOwner returns (bool){

        require (_balance[from] >= value, "Not enough coins to burn");
        require (from != address(0), "Null address not acceptable");

        _balance[from] -= value;
        _totalCoins -= value;

        emit Transfer(from, address(0), value);
        return true;

    }

    /*
    * @desc Executes the transfer of coins from an address to another.
    * @param from The address whose coins will be transfered.
    * @param to The address that will receive the coins.
    * @param value The amount of coins that will be transfered.
    */

    function executeTransfer(address from, address to, uint256 value) public onlyOwner {

        require (value <= _balance[from], "Insufficient balance");
        require (to != address(0), "You are not allowed to burn tokens");
        require (from != address(0), "You are not allowed to mint tokens");

        _balance[from] -= value;
        _balance[to] += value;

        emit Transfer(from, to, value);

    }

    /*
    * @desc Executes the transfer of coins from an address to another on behalf of a third address.
    * @param owner The address whose coins will be transfered.
    * @param spender The address on behalf whose the coins will be transfered.
    * @param to The address that will receive the coins.
    * @param value The amount of coins that will be transfered.
    */ 

    function executeTransferFrom(address owner, address spender, address to, uint256 value) public onlyOwner {

        require (value <= _allowed[owner][spender], "You are not allowed to spend these coins");

        executeTransfer(owner, to, value);

        adjustAllowed(owner, spender, -int(value));

    }

    /*
    * @desc Executes the allowance of an address to spend another address' coins.
    * @param owner The address whose coins will be allowed to be spent.
    * @param spender The address that is allowed to spend the coins.
    * @param value The amount of coins that are allowed to be transfered.
    */

    function executeApprove(address owner, address spender, uint256 value) public onlyOwner {

        require (spender != address(0), "Null address not acceptable");
        require (owner != address(0), "Null address not acceptable");

        _allowed[owner][spender] = value;

        emit Approval(owner, spender, _allowed[owner][spender]);

    }

    /*
    *
    *
    *
    */

    function registeredDevices(uint256 deviceID) public view returns (address) {

        return device[deviceID];
        
    }

    /*
    *
    *
    *
    *
    */

    function registerDevice(address owner, uint256 deviceID) public onlyOwner {

        device[deviceID] = owner;

    }

    /*
    *
    *
    *
    *
    */

    function transferFromDeviceID(uint256 deviceID, address from, uint256 amount) public onlyOwner {

        address to = device[deviceID];

        executeTransfer(from, to, amount);

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
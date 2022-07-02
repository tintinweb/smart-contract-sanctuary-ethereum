// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.25 <0.8.15;

/*
* @desc A coin system implementation following the ERC20 standard.
*/

contract thesis{

    //Declarations of the variables used in the contract.
    mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowed;
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

    function adjustAllowed(address owner, address spender, int value) public returns (bool){

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
    
    function mint(address target, uint256 value) public returns (bool) {

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
    
    function burn(address from, uint256 value) public returns (bool){

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

    function executeTransfer(address from, address to, uint256 value) public {

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

    function executeTransferFrom(address owner, address spender, address to, uint256 value) public {

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

    function executeApprove(address owner, address spender, uint256 value) public {

        require (spender != address(0), "Null address not acceptable");
        require (owner != address(0), "Null address not acceptable");

        _allowed[owner][spender] = value;

        emit Approval(owner, spender, _allowed[owner][spender]);
    }

}
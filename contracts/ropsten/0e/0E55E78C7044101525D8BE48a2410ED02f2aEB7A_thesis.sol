// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.25 <0.8.15;

/*
* @desc A coin system implementation following the ERC20 standard.
*/

contract thesis{

    //Declarations of the variables used througout the contract.
    mapping (address => uint256) private balance;
    mapping (address => mapping (address => uint256)) private allowed;
    uint256 private totalCoins;

    //Declarations of the events used in the contract.
    event transfer(address from, address to, uint256 amount);
    event allowance(address caller, address spender, uint256 amount);

    /*
    * @desc The constructor function called just once.
    */

    constructor() public {

        balance[tx.origin] = 1000;
        totalCoins = 1000;
    
    }

    /*
    * @desc Returns the balance of the specified address.
    * @param target The address whose balance is needed.
    * @return The balance as a uint256 number.
    */

    function returnBalance(address target) public view returns (uint256){

        return balance[target];

    }

    /*
    * @desc Returns the total supply of coins.
    * @return The total amount of coins as a uint256 number.
    */

    function returnTotalCoins() public view returns (uint256){

        return totalCoins;

    } 

    /*
    * @desc Returns the amount of an account's funds a user is allowed to spend.
    * @param owner The address whose funds are allowed to be spent.
    * @param spender The address which is allowed to spend the funds.
    * @return The amount of owner's coins the spender is allowed to spend as a uint256 number.
    */
    
    function returnAllowed(address owner, address spender) public view returns (uint256){

        return allowed[owner][spender];

    }

    /*
    * @desc Allows the specified address to spend the specified amount of the caller's coins. 
    * @param spender The address which is allowed to spend the other address' funds.
    * @param amount The amount of the owner's coins the spender is allowed to spend as a uint256 number.
    * @return Returns true if the execution is successful and false otherwise.
    */

    function allow(address owner, address spender, uint256 amount) public returns (bool){

        require (spender != address(0), "You can not do this");

        allowed[owner][spender] = amount;

        emit allowance(owner, spender, allowed[owner][spender]);
        return true;

    }

    /*
    * @desc Adjusts the amount of an address' funds an other address is allowed to spend. 
    * @param spender The address whose allowance to spend another address' funds is adjusted.
    * @param amount The amount by which the allowance will be adjusted as a signed integer.
    * @return Returns true if the execution is successful and false otherwise.
    */

    function adjustAllowed(address owner, address spender, int amount) public returns (bool){

        require (spender != address(0), "You can not do this");

        //If the amount is positive the allowance is increased. It is decreased otherwise. 
        if (amount > 0){
            allowed[owner][spender] += uint256(amount);
        }else{
            allowed[owner][spender] -= uint256(-amount);
        }
        
        emit allowance(owner, spender, allowed[owner][spender]);
        return true;

    }

    /*
    * @desc Sends the specified amount of coins from the caller's balance to the specified address' balance. 
    * @param target The address where the coins will be transfered.
    * @param amount The amount of coins that will be transfered as a uint256.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function sendCoins(address sender, address target, uint256 amount) public returns (bool){

        require (amount <= balance[sender], "Insufficient balance");
        require (target != address(0), "You are not allowed to burn tokens");

        balance[sender] -= amount;
        balance[target] += amount;

        emit transfer(sender, target, amount);
        return true;

    }

    /*
    * @desc Sends the specified amount of coins from the specified address' balance on behalf of the caller.
    * @param owner The address whose funds will be transfered.
    * @param target The address where the coins will be transfered.
    * @param amount The amount of coins that will be transfered as a uint256.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function indirectSendCoins(address owner, address target, address sender, uint256 amount) public returns (bool){

        require (amount <= allowed[owner][sender], "You are not allowed to spend these coins");
        require (amount <= balance[owner], "Insufficient balance");

        balance[owner] -= amount;
        balance[target] += amount;

        emit transfer(owner, target, amount);

        adjustAllowed(owner, sender, -int(amount));

        return true;

    }

    /*
    * @desc Creates the specified amount of new coins and gives them to the specified address.
    * @param target The address whose the new coins will be.
    * @param amount The amount of coins that will be created as a uint256.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function mint(address target, uint256 amount) public returns (bool) {

        require (target != address(0), "You can not do that");

        balance[target] += amount;
        totalCoins += amount;

        emit transfer(address(0), target, amount);
        return true;

    }

    /*
    * @desc Destroys the specified amount of coins from the caller's balance.
    * @param amount The amount of coins that will be destroyed as a uint256.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function burn(address owner, uint256 amount) public returns (bool){

        require (balance[owner] >= amount, "Not enough coins to burn");

        balance[owner] -= amount;
        totalCoins -= amount;

        emit transfer(owner, address(0), amount);
        return true;

    }

    /*
    * @desc Destroys the specified amount of coins from the specified address on behalf of the caller.
    * @param owner The address whose coins will be destroyed.
    * @param amount The amount of coins that will be destroyed as a uint256.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function indirectBurn(address owner, address sender, uint256 amount) public returns (bool){

        require (amount <= allowed[owner][sender], "You are not allowed to burn this much");
        require (amount <= balance[owner], "Not enough coins to burn");

        adjustAllowed(owner, sender, -int(amount));
        
        balance[owner] -= amount;
        totalCoins -= amount;

        emit transfer(owner, address(0), amount);

        return true;

    }

}
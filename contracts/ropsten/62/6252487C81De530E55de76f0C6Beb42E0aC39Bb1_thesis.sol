// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.25 <0.8.15;

/*
* @desc A coin system implementation following the ERC20 standard.
*/

contract thesis{

    //Declarations of the variables used througout the contract.
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

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }

    function decimals() public view returns (uint8){
        return 18;
    }


    /*
    * @desc Returns the total supply of coins.
    * @return The total amount of coins as a uint256 number.
    */

    function totalSupply() public view returns (uint256){

        return _totalCoins;

    } 

    /*
    * @desc Returns the balance of the specified address.
    * @param target The address whose balance is needed.
    * @return The balance as a uint256 number.
    */

    function balanceOf(address _owner) public view returns (uint256){

        return _balance[_owner];

    }

    function allowance(address _owner, address _spender) public view returns (uint256){

        return _allowed[_owner][_spender];

    }

    /*
    * @desc Sends the specified amount of coins from the caller's balance to the specified address' balance. 
    * @param target The address where the coins will be transfered.
    * @param amount The amount of coins that will be transfered as a uint256.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function transfer(address _to, uint256 _value) public returns (bool){

        require (_value <= _balance[msg.sender], "Insufficient balance");
        require (_to != address(0), "You are not allowed to burn tokens");

        _balance[msg.sender] -= _value;
        _balance[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;

    }

    /*
    * @desc Sends the specified amount of coins from the specified address' balance on behalf of the caller.
    * @param owner The address whose funds will be transfered.
    * @param target The address where the coins will be transfered.
    * @param amount The amount of coins that will be transfered as a uint256.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

        require (_value <= _allowed[_from][msg.sender], "You are not allowed to spend these coins");
        require (_value <= _balance[_from], "Insufficient balance");

        _balance[_from] -= _value;
        _balance[_to] += _value;

        emit Transfer(_from, _to, _value);

        adjustAllowed(_from, msg.sender, -int(_value));

        return true;

    }

    /*
    * @desc Allows the specified address to spend the specified amount of the caller's coins. 
    * @param spender The address which is allowed to spend the other address' funds.
    * @param amount The amount of the owner's coins the spender is allowed to spend as a uint256 number.
    * @return Returns true if the execution is successful and false otherwise.
    */

    function approve(address _spender, uint256 _value) public returns (bool){

        require (_spender != address(0), "You can not do this");

        _allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        return true;

    }

    /*
    * @desc Adjusts the amount of an address' funds an other address is allowed to spend. 
    * @param spender The address whose allowance to spend another address' funds is adjusted.
    * @param amount The amount by which the allowance will be adjusted as a signed integer.
    * @return Returns true if the execution is successful and false otherwise.
    */

    function adjustAllowed(address _owner, address _spender, int _value) public returns (bool){

        require (_spender != address(0), "You can not do this");

        //If the amount is positive the allowance is increased. It is decreased otherwise. 
        if (_value > 0){
            _allowed[_owner][_spender] += uint256(_value);
        }else{
            _allowed[_owner][_spender] -= uint256(-_value);
        }
        
        emit Approval(_owner, _spender, _allowed[_owner][_spender]);
        return true;

    }

    /*
    * @desc Creates the specified amount of new coins and gives them to the specified address.
    * @param target The address whose the new coins will be.
    * @param amount The amount of coins that will be created as a uint256.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function mint(address _target, uint256 _value) public returns (bool) {

        require (_target != address(0), "You can not do that");

        _balance[_target] += _value;
        _totalCoins += _value;

        emit Transfer(address(0), _target, _value);
        return true;

    }

    /*
    * @desc Destroys the specified amount of coins from the caller's balance.
    * @param amount The amount of coins that will be destroyed as a uint256.
    * @return Returns true if the execution is successful and false otherwise.
    */
    
    function burn(address _from, uint256 _value) public returns (bool){

        require (_balance[_from] >= _value, "Not enough coins to burn");

        _balance[_from] -= _value;
        _totalCoins -= _value;

        emit Transfer(_from, address(0), _value);
        return true;

    }

}
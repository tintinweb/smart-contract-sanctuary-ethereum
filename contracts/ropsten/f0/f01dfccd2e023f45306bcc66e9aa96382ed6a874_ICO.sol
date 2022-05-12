pragma solidity ^0.4.25;

contract ERC20Basic {
   function balanceOf(address _who) public constant returns (uint256);
   function transfer(address _to, uint256 _value) public returns (bool);
   event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {

    function allowance(address _owner, address _spender) public constant returns (uint256);

    function approve(address _spender, uint256 _value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

}



contract BasicToken is ERC20Basic {

    

    mapping (address => uint) balances;

    

    /**

     * @dev The balanceOf function returns the balance of the queried address. This is a constant time function as 

     * it has the 'view' keyword meaning that this function can only read from the contract and not write to it. 

     * @param _who The address which will be queried

     * @return The total amount of tokens the address holds.

     * */

    function balanceOf(address _who) public view returns (uint256) {

        return balances[_who];

    }

    

    

    /**

     * @dev function to transfer tokens from the msg.sender (i.e. the invoker of the function) to another address.

     * @param _to The receiving address

     * @param _value The amount of tokens to send 

     * @return true if the function executes successfully, false otherwise

     * */

    function transfer(address _to, uint256 _value) public returns (bool) {

        require(balanceOf(msg.sender) >= _value);

        require(balanceOf(_to) < balanceOf(_to) + _value);

        balances[msg.sender] = balances[msg.sender] - _value;

        balances[_to] = balances[_to] + _value;

        emit Transfer(msg.sender, _to, _value);

        return true;  

    }

}


contract StandardToken is ERC20, BasicToken {

    

    mapping (address => mapping (address => uint)) public allowances;

    

    /**

     * @dev The allowance() funtion gets the total amount of tokens which an owner address has allowed a spender 

     * address to spend from the owner's balance.

     * @param _owner The address of the owner 

     * @param _spender The address of the spender 

     * @return The total allowance

     * */

    function allowance(address _owner, address _spender) public constant returns (uint256) {

        return allowances[_owner][_spender];

    }

    

    /**

     * @dev The approve() function lets the owner of tokens (i.e. the 'msg.sender') to allow a spender 

     * to spend up to a certain amount of tokens on behalf of the owner. 

     * @param _spender The address of the spender

     * @param _value The total amount of tokens to allow the spender to spend (hint, this can also be 0 if the owner wants to revoke the allownace of a spender)

     * @return true if the function executes successfully, false otherwise

     * */

    function approve(address _spender, uint256 _value) public returns (bool) {

        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }

    

    

    /**

     * @dev The transferFrom() function allows the spender (i.e the msg.sender) to transfer tokens from an 

     * owner which has previously approved the spender to transfer up to a certain amount of tokens from 

     * the owner's balance. 

     * @param _from This is the owner's address

     * @param _to The address which will be receiving the tokens

     * @param _value The total amount of tokens to transfer 

     * @return true if the function executes successfully, false otherwise

     * */

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(allowance(_from, msg.sender) >= _value);

        require(balanceOf(_from) >= _value);

        balances[_from] = balances[_from] - _value;

        balances[_to] = balances[_to] + _value;

        allowances[_from][msg.sender] = allowances[_from][msg.sender] - _value;

        emit Transfer(_from, _to, _value);

        return true;

    }

}



contract HackSussexCoin is StandardToken {

    

    string public name;

    string public symbol;

    uint8 public decimals;

    uint public totalSupply;

    

    constructor() {

        name = "Hack Sussex Coin";

        symbol = "HSC";

        decimals = 18;

        totalSupply = 10000000e18; //10,000,000 tokens

        balances[msg.sender] = totalSupply;

        emit Transfer(address(this),msg.sender, totalSupply);

    }

}



contract Ownable {

    

    address public owner;

    

    constructor() public {

        //assign the creator of the contract as the owner

        owner = msg.sender;

    }

    

    //functions with this modifier can only be executed by the owner of the contract

    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }

    

    event OwnershipTransferred(address indexed from, address indexed to);

    

    /**

     * @dev Allows the owner of the contract to transfer ownership to another address.

     * Notice how this function has the 'onlyOwner' modifier. This ensures that only 

     * the owner can invoke this function. 

     * 

     * @param _newOwner The address of the new owner

     * */

    function transferOwnership(address _newOwner) public onlyOwner {

        require(_newOwner != owner && _newOwner != address(0));

        emit OwnershipTransferred(owner, _newOwner);

        owner = _newOwner;

    }

}




contract ICO is Ownable{

    

    //STEP 3 - create a variable of type HackSussexCoin and call it HSC 

    HackSussexCoin public HSC;

    //STEP 4 - create a variable of type uint and call it rate

    uint public rate;

    //STEP 5 - create a variable of type uint and call it deadline 

    uint public deadline;

    //STEP 6 - create a variable of type uint and call it softCap 

    uint public softCap; 

    //STEP 7 - create a mapping from address to uint and call it investments 

    mapping (address => uint) investments;
    

    

    constructor() public {

        //STEP 8 - instantiate a new instance of the HackSussexCoin in the HSC variable using the 'new' keyword 

        HSC = new HackSussexCoin();

        //STEP 9 - assign rate any value you like that is > 0. The rate is how many tokens one would get for 

        //every ETH invested (i.e. 1 ETH = 1000 HSC)

        rate = 10;

        //STEP 10 - set the deadline variable to the current timestamp + 30 days 

        deadline = now + (30 days);

        //STEP 11 - set the softCap to any value you like that is > 0. The softCap is the amount of ETH that 

        //needs to be raised before the deadline in order for the ICO to be a success. Take consideration 

        //that ETH has 18 decimals when assigning this value


        softCap = 200e18;

    }

    

    event TokensPurchased(address indexed by, uint totalTokens, uint totalInvestment);

    

    /**

     * @dev Allows for the sale of tokens to be made in exchange for ETH. Notice the 

     * 'payable' modifier. This modifier basically states that this function can also accept 

     * ETH. 

     * 

     * @param _investor The address of the recipient 

     * @return true if the function executes successfully, false otherwise

     * */

    function buyTokens(address _investor) public payable returns(bool) {

        //STEP 12 - using 'require()' check that the address is not '0x000...00'. This can be simplified to 

        //'address(0)' or '0x0'.
        
        require(_investor != address(0));

        

        //STEP 13 - using 'require()' check that the investor has invested a non-zero value. This check can 

        //be made with msg.value 
        
        require(msg.value != 0);
        

        //STEP 14 - using 'require()' check that the deadline of 30 days has not already passed. Here's a 

        //hint, use the 'now' keyword when checking for this condition

        require(now < deadline);
        

        //STEP 15 - create a variable called 'toSend' and assign it the amount of tokens to send to the 

        //investor using a simple calculation involving the 'rate' and the 'msg.value'


        uint toSend = msg.value * rate;
        

        //STEP 16 - now invoke the transfer function of the HSC object with the appropriate arguments 

        HSC.transfer(_investor, toSend);

        //STEP 17 - update the 'investments' mapping with the total amount of ETH the investor has invested

        investments[_investor] += msg.value;
        

        //STEP 18 - emit the TokensPurchased event with the appropriate arguments 

        emit TokensPurchased(_investor, toSend, msg.value);
        

        return true; 

    }

    

    

    /**

     * @dev This function which has no name is called a fallback function in solidity. It is invoked when 

     * a message or transaction is sent to the contract with no data specifying which function to use. So 

     * it is bascically a defualt function which the contract falls back on when the contract does not know 

     * what else to do. Notice how this function is 'payable' which means it can accept ETH and that it also 

     * invokes the 'buyTokens()' function whilst passing the address of the msg.sender. This is useful because 

     * there is now a way to automate the token purchasing process. All the investor has to do is send ETH to 

     * this address and the investor will automatically receive the tokens in exchange. 

     * */

    function() public payable {

        buyTokens(msg.sender);

    }



    

    //STEP 19 - add the 'onlyOwner' modifier to the 'withdrawETH' function to ensure that only the owner 

    //can withdraw ETH from the contract
    

    /**

     * @dev Allows the owner of the contract to withdraw the entire ETH balance of the contract

     * 

     * @return true if the function executes successfully, false otherwise

     * */

    function withdrawETH() public onlyOwner returns(bool) {

        //STEP 20 - using 'require()' check that the softCap has been reached (we don't want the owner 

        //to pull off some fraudulent activities such as exit scams)

        require(address (this).balance < softCap );
        
        
        

        //STEP 21 - make it so that the owner of the contract receives the entire ETH balance of this contract. 

        //This is a slighly complicated line of code so here are some hints of keywords and functions to use:  

        //'owner', the 'transfer()' function, and the balance member of the 'address' type (think of the addres

        //of 'this' contract)
        
        HSC.transfer(owner, address (this).balance);
        
        

        

        return true;

    }

    

    

    /**

     * @dev Allows investors to claim their ETH back in the case that the deadline has passed and the softCap

     * has not been reached

     * 

     * @return true if the function executes successfully, false otherwise

     * */

    function claimRefund() public returns(bool) {

        //STEP 22 - using 'require()' check that the investor has and investment value in the 'investments' 

        //mapping which is > 0.

        require(investments[msg.sender] > 0);
        

        //STEP 23 - using 'require()' check that the deadline of the ICO has passed and that the softCap has not been reached

        require(deadline < now);

        //STEP 24 - create a variable called 'toRefund' of type uint and assign it the value which the 

        //investor has contributed. 

        uint toRefund = investments[msg.sender];

        //STEP 25 - set the value of the investor mapping to 0 

        investments[msg.sender] = 0;

        //STEP 26 - transfer the value stored in 'toRefund' to the investor. Here is a hint, use msg.sender, 

        //and the 'transfer()' function 

        HSC.transfer(msg.sender, toRefund);

        return true;

    }

    

    

    //STEP 27 - add the 'onlyOwner' modifier to the 'withdrawTokens' function to ensure that only the owner 

    //can withdraw ETH from the contract

    /**

     * @dev Allows the owner of the contract to withdraw HSC tokens from the contract

     * 

     * @param _recipient The receiver of the token 

     * @param _value The total amount of tokens to send to the recipient 

     * @return true if the function executes successfully, false otherwise

     * */

    function withdrawTokens(address _recipient, uint _value) public onlyOwner returns(bool) {

        //STEP 28 - using 'require()' check that the _recipient is not '0x000...00'. This can be simplified to 

        //'address(0)' or '0x0'.
        
        require(_recipient != address(0));
        

        

        //STEP 29 - using 'require()' check that _value is > 0

        require(_value > 0);        


        //STEP 30 - invoke the 'transfer()' function of the HSC object with the appropriate arguments

        HSC.transfer(_recipient, _value);
        
        

        return true; 

    }

}
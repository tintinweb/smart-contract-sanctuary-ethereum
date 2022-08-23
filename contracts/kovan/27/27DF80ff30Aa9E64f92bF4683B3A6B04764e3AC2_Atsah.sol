/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

    //UINT256 - A UNSIGNED INTEGER: a number without a sign, a sign = negative modifier, -. example being 1, 2, 3.
    //INT - A SIGNED/UNSIGNED INTEGER: a number with or without a sign, a sign = negative modifier, -. example being -1, 2, -3.
    //INCREMENT - the function of a number increasing or decreasing in value/integer.
    //FUNCTION - snippets of code you can use over and over again
        //READ FUNCTION - gaining information from the blockchain. doesn't cost gas.
        //VIEW FUNCTION - view functions are nons-state changing functions, meaning we are reading off the blockchain, no transaction. 
        //PURE FUNCTION - functions that purely do a sort of math.
        //PAYABLE FUNCTION - this function can be used to pay for things.
        //TRANSER FUNCTION - this function sends eth from one address to another.
        //WRITE FUNCTION - change information on the blockchain. cost gas.
        //CONSTRUCTOR FUNCTION - A SPECIAL FUNCTION: it gets run once whenever the contract is deployed on the blockchain.
    //COUNT++ - increment the count by one, automatically.
    //VARIABLE - data you can store and use later.
        //STATE VARIABLE - A VARIABLE: value that is saved on the blockchain.
        //LOCAL VARIABLE - A VARIABLE: that exists in one solidity function.
        //PUBLIC VARIABLE - A VISIBILTY MODIFIER: we can call a function outside the smart contract.
        //VARIABLE SCOPE - where the VARIABLE: can be read, accessed, updated, etc.
    //STRING - group of letters inside quotation marks.
    //ARRAYS - sorted groupings of different pieces of data. shown by [].
    //CONDITIONALS - CONTROL FLOW STRUCTURE: logic gate: if (some condition), then (do some action), else (do some other action.
    //LOOPS - check each item inside of array to see [if even].
    //FOR LOOPS - a way to loop through a range to do things at each "loop."
    //INHERITANCE - inherit properties from a parent contract.
    //FACTORIES - A SMART CONTRACT: where you deploy other smart contracts (within that smart contract.)
    //INTERACTION - how to communicate to other smart contracts within a smart contract, functions to call other smart contracts on the blockchain.
    //ETHEREUM PAYMENTS - ...
    //MODIFIER - is used to change the behaviour of a function in a declarative way.
        //PAYABLE MODIFIER - this function can be used to pay for things.
        //VISIBILTY MODIFER - how a contract function is viewed on the blockchain.
         //PUBLIC - A VISIBILTY MODIFIER: we can call a function outside the smart contract.
    //EVENTS - create a log stating this event has happened/history of all events that took place.
    //ENUMS - DATA STRUCTURE: a collection of options that never change.
    //BOOL - true or false statements.
    //STRUCT - ways to define new type in solidity.
    //MEMORY - data only stored on execution of the contract call.
    //STORAGE - data will presist after a function executes.
    //MSG.SENDER - sender of the function call.
    //MSG.VALUE - how much the msg.sender sent.
    //TUPLE - A LIST: of objects of potentially different types whose number is a constant at compile-time.
    //THIS - A KEYWORD: reffering to the contract.
    //LIBRARY - similar to contracts, but their purpose is that they are deployed only once at a specific address and their code is reused.

    //RED BUTTON IN A DEPLOYED CONTRACT - the function is payable.
    //ORANGE BUTTON IN A DEPLOYED CONTRACT - ...
    //BLUE BUTTON IN A DEPLOYED CONTRACT - the function is a view.

    //ABI: - interfaces compile down to an ABI. ABI = Application Binary Interface, the ABI tells solidity and other programming languages how it can interact with another contract.
    //ABI: - anytime you want to interact with an already deployed smart contract, you will need an ABI.
    //ABI: - always need an ABI to interact with a contract.

    //balanceOf[msg.sender] = balanceOf[msg.sender] - (_value); ||| the balance of the sender is negatively incremented by the value.
    //require(balanceOf[msg.sender] >= _value); ||| we are requiring that the balance of the sender, is greater than or equal to, the value.

contract Atsah {
    string public title = "Atsah";
    string public symbol = "TAH";
    uint256 public decimals = 20;
    uint256 public supply = 1525000000000000000000000;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _title, string memory _symbol, uint _decimals, uint _supply) {
        title = _title;
        symbol = _symbol;
        decimals = _decimals;
        supply = _supply;
        balanceOf[msg.sender] = supply;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

     function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
}
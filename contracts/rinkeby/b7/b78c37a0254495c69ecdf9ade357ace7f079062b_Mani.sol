pragma solidity 0.5.1;

import "./Math.sol";

contract ERC20 {
    string public name;
    uint256 public tokens_remaining;

    event Log(
        uint256 value,
        uint256 remaining,
        uint256 purchased
    );


    mapping(address => uint256) public balances;

    function safe_divide(uint _value1, uint _value2) internal pure returns (uint256) {
        return Math.divide(_value1, _value2);
    }

    function mint(uint256 value, uint256 token_value) public payable {
        uint256 num_tokens = safe_divide(value, token_value);
        require (num_tokens > 0);
        balances[tx.origin] += num_tokens;
        tokens_remaining -= num_tokens;
        emit Log(token_value, tokens_remaining, num_tokens);
    }

    function redeem() public {
        balances[tx.origin] --;
    }

    constructor(string memory _name, uint256 _tokens_remaining) public{
        name = _name;
        tokens_remaining = _tokens_remaining;
    }
}

contract Mani is ERC20 {
    string symbol;
    int public version = 1;
    address[] public owners;

    uint256 ownerCount;
    uint public value;
    uint256 public total_manni = 100000;
    uint256 public _initial_block_number ;

    // Value should increase by a factor of 3 roughly every  few hours, or 1000 blocks
    // Fixed cap of 100,000 Manis 
    function compute_token_value(uint256 initial_block_number) public view returns(uint256) {
        return  100 szabo *  ( 3 ** uint( (block.number - initial_block_number)/ 1000)  ) ;
    }

    constructor(
    ) 
        ERC20("mani", total_manni) public 
    {
        symbol = "MANI";
        _initial_block_number = block.number;
    }
    
    function mint(uint256 purchase_value) public payable {
        uint256 token_value = compute_token_value(_initial_block_number);
        super.mint(purchase_value, token_value);
        ownerCount ++;
        owners.push(tx.origin);
    }
}

contract MoneyForMani {

    address owner;
    uint256 openingTime  = 1647210381;
    address payable wallet;
    uint public version = 1;

    constructor(address payable _wallet, address _token) public{
        owner = msg.sender;
        wallet = _wallet;
        token = _token;
    }

    event MyPrint(address indexed _from, uint _value, string message);
    event Purchase(
        address indexed _buyer,
        uint256 _amount
    );
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    address public token;

    modifier onlyWhileOpen(){
        require( block.timestamp >= openingTime);
        _;
    }

    enum State {Waiting, Ready, Active}
    State public state;

    uint256 public peopleCount =0;

    struct Person {
        uint _id;
        string _firstName;
        string _lastName;
    }
    mapping(uint => Person) public people;

    function addPerson(string memory _firstName, string memory _lastName) public onlyOwner onlyWhileOpen {
        people[peopleCount] = Person(peopleCount, _firstName, _lastName);
        incrementCount();
    }

    function buyToken() public payable {
        uint256 msg_value = msg.value;
        wallet.transfer(msg_value);
        emit MyPrint( msg.sender, msg.value, "Hi! Have a nice day!"  );
        Mani _token = Mani(address(token));
        _token.mint(msg_value);
    }

    function incrementCount() internal {
        peopleCount ++;
    }


    function activate() public{
        state = State.Active;
    }
    function deActivate() public{
        state = State.Waiting;
    }

    function isActive() public view returns(bool){
        return state == State.Active; 
    }

}
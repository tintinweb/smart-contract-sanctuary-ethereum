pragma solidity 0.5.1;

import "./Math.sol";

contract ERC20 {
    string public name;
    mapping(address => uint256) public balances;

    function mint() public {
        balances[tx.origin] ++;
    }

    constructor(string memory _name) public{
        name = _name;
    }
}

contract MyToken is ERC20 {
    string symbol;
    address[] public owners;
    uint256 ownerCount;
    uint public value;

    constructor(
        string memory _name, 
        string memory _symbol
    ) 
        ERC20(_name) public 
    {
        symbol = _symbol;
    }
    
    function safe_divide(uint _value1, uint _value2) public {
        value = Math.divide(_value1, _value2);
    }

    function mint() public {
        super.mint();
        ownerCount ++;
        owners.push(msg.sender);
    }
}

contract MyContract {

    string public stringValue  = "my_value";
    bool public myBool = true;
    int public myint = -1;
    uint public myUint = 1;
    address owner;
    uint256 openingTime  = 1647210381;
    address payable wallet;

    event MyPrint(address indexed _from, uint256 indexed _id, uint _value, string message);
    event Purchase(
        address indexed _buyer,
        uint256 _amount
    );
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
        // tx.sender == owner;
    }
    address public token;

    modifier onlyWhileOpen(){
        require( block.timestamp >= openingTime);
        _;
    }

    enum State {Waiting, Ready, Active}
    State public state;

    uint256 public peopleCount =0;
    uint256 public fancyPeopleCount =0;

    Person[] public people;
    mapping(uint => Person) public fancy_people;
    mapping(address => uint256) public balances;

    struct Person {
        uint _id;
        string _firstName;
        string _lastName;
    }

    function addPerson(string memory _firstName, string memory _lastName) public {
        people.push(Person(peopleCount, _firstName, _lastName));
        peopleCount ++;
    }
    function addFancyPerson(string memory _firstName, string memory _lastName) public onlyOwner onlyWhileOpen {
        fancy_people[fancyPeopleCount] = Person(fancyPeopleCount, _firstName, _lastName);
        incrementCount();
    }


    function buyToken() public payable {
        // balances[msg.sender] += 1;
        wallet.transfer(msg.value);
        emit MyPrint( msg.sender, myUint, msg.value, "Hi! Have a nice day!"  );
        ERC20 _token = ERC20(address(token));
        _token.mint();
        // emit Purchase(msg.sender, 1);
    }

    function incrementCount() internal {
        fancyPeopleCount ++;
    }

    constructor(address payable _wallet, address _token) public{
        //state = State.Waiting;
        //owner = msg.sender;
        wallet = _wallet;
        token = _token;
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
    // string public constant value  = "my_value";
    // constructor() public {
    //     value = "my_value";
    // }


    function set(string memory _value) public {
        stringValue = _value;
    }
}
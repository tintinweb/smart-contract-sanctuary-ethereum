/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// File: contracts/BuyMeACoffee.sol



pragma solidity >=0.7.0 <0.9.0;


contract BuyMeACoffee {

    uint256 public totalMemo;

    // emit an event when a memo is created
    event NewMemo(
        address from,
        uint256 amount,
        uint256 timestamp,
        string name,
        string message
    );

    // Memo struct 
    struct Memo {
        address from;
        uint256 amount;
        uint256 timestamp;
        string name;
        string message;
    }

    struct profile {
        string name;
        string bio;
        address addr;
        uint256 balance;
        uint256 coffee;
        uint256 supporters;
        string link;
        bool cond;
    }

    // List of all memos recieved from friends
    mapping(address => Memo []) public memos;

    address [] public allCreators;

    // mapping of creators
    mapping(address => profile) public Creators;

    // Address of vontra
    address payable owner;

    // Deploy logic
    constructor() {
        owner = payable(msg.sender);
    }

    /**
    * @dev buy a coffee for contract owner
    * @param _name name of the coffee buyer
    * @param _message a nice message from the coffee buyer
    */ 
    function buyCoffee(string memory _name, string memory _message, uint256 _amount, address _addr) public payable {
        require(msg.value > 0, "can't buy coffee with 0 eth");

        totalMemo += _amount;

        Creators[_addr].balance += msg.value; 
        Creators[_addr].coffee += _amount; 
        Creators[_addr].supporters += 1; 

        // Add memo to storage
        memos[_addr].push(Memo (
            msg.sender,
            _amount,
            block.timestamp,
            _name,
            _message
        ));

        // emit a log event when a new memo is created!
        emit NewMemo(
            msg.sender,
            _amount,
            block.timestamp,
            _name,
            _message
        );

    }

    /**
    * @dev make a user to become a creator
    */ 
    function beCreator(string memory _name, string memory _link, string memory _bio) public {
        if(Creators[msg.sender].cond == false){
            allCreators.push(msg.sender);
        }

        Creators[msg.sender].name = _name;
        Creators[msg.sender].addr = msg.sender;
        Creators[msg.sender].bio = _bio;
        Creators[msg.sender].link = _link;
        Creators[msg.sender].cond = true;
       
    }
    
    /**
    * @dev send the entire balance stored in this contract to the owner
    */ 
    function withdrawTips() public {
        require(payable(msg.sender).send(Creators[msg.sender].balance), "Your balance is zero   ");
        Creators[msg.sender].balance = 0;
    }

    /**
    * @dev retrieve all the memos received and stored on the blockchain 
    */ 
    function getMemos(address _addr) public view returns(Memo[] memory) {
        return memos[_addr];
    }

    function getCreators(address addr) public view returns(profile memory){
        return Creators[addr];
    }

    function getAllAddr() public view returns(address [] memory){
        return allCreators;
    }

}
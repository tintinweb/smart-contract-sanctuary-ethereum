// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SocialMedia{
    uint public NoOfUsers = 1;
    address payable public owner;
    struct User{
        string name;
        string mail;
        string password;
    }

    struct Chat{
        string message;
        address to;
        address from;
        uint timestamp;
    }

    struct Post{
        string uname;
        string file;
        string message;
        address owner;
        uint timestamp;
    }

    mapping (string=>uint) public uid; 
    mapping (string => bool) isRegistered;
    constructor(){
        owner = payable(msg.sender);
    }

    User[] public users;
    Chat[] public chats;
    Post[] public posts;
    
    function createUser(string memory _name,string memory _mail,string memory _password)public returns(bool){
        require(!isRegistered[_mail], 'This e-mail is already registered');
        users.push(User(_name,_mail,_password));
        uid[_mail] = NoOfUsers;
        isRegistered[_mail] = true;
        NoOfUsers+=1;
        return true;
    }

    function validUser(string memory _mail,string memory _password)public view returns(bool){
        if(uid[_mail]!=0){
            string memory pass = users[uid[_mail]-1].password;
            if(keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked(_password))){
                return true;
            }
        }
        return false;
    }

    function sendMessage(string memory _message,address _to)public{
        uint timestamp = block.timestamp;
        chats.push(Chat(_message,_to,msg.sender,timestamp));
    }

    function getAllmessages()public view returns(Chat[] memory){
        return chats;
    }

    function createPost(string memory _file,string memory _uname,string memory _message)public {
        uint timestamp = block.timestamp;
        posts.push(Post(_uname,_file,_message,msg.sender,timestamp));
    }

    function getAllPosts()public view returns(Post[] memory){
        return posts;
    }

    event cryptoTrasaction(address indexed sender,address indexed reciver, uint256 value);
    function sendCrypto(address payable sender) payable public {
    require(sender != address(0), "Invalid address");
    require(msg.value > 0, "Value sent must be greater than zero");
    uint256 amountToSend = msg.value; 
    sender.transfer(amountToSend);
    emit cryptoTrasaction(msg.sender,sender, msg.value);
}
}
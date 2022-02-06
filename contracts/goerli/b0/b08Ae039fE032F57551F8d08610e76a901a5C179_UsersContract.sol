pragma solidity ^0.8.0;

contract UsersContract {
    struct User {
        string name;
        string surName;

    }

    mapping(address => User) private users;
    mapping(address => bool) private joinedUsers;
    address[] total;

    function join(string memory name, string memory surName) public {
        require(!userJoined(msg.sender));
        User storage user = users[msg.sender];
        user.name = name;
        user.surName = surName;
        joinedUsers[msg.sender] = true;
        total.push(msg.sender);
    }
    
    function getUser(address addr) public view returns (string memory, string memory) {
        require(userJoined(msg.sender));
        User memory user = users[addr];
        return (user.name, user.surName);
    }

    function userJoined(address addr) private view returns (bool) {
        return joinedUsers[addr];
    }

    function getAddressesCount() public view returns(uint){
        return(total.length);
    }
}
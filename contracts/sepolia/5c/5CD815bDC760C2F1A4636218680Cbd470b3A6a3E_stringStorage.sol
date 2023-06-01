pragma solidity 0.8.18;

contract stringStorage {
    string s_myString;
    address public admin;

    event stringChanged(string _string);

    constructor(string memory _string) {
        s_myString = _string;
        admin = msg.sender;
    }

    function setMyString(string memory _string) public payable {
        require(msg.value >= 5 * 10 ** 18, "Not enougth funds sended");
        require(msg.sender == admin, "You are not the admin");
        s_myString = _string;
        emit stringChanged(_string);
    }
    
    function getMyString() public view returns(string memory) {
        return s_myString;
    }
}
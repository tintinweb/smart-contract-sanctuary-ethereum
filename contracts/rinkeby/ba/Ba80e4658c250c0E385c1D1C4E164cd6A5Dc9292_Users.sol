pragma solidity >=0.7.0 <0.9.0;

contract Users{
    mapping(address=> string) public userBio;
    event updatedBio(address user, string bio);
    
    function updateBio(string memory bio) public {
        userBio[msg.sender]=bio;
        emit updatedBio(msg.sender, bio);
    }
}
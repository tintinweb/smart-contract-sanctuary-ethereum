pragma solidity >=0.7.0 <0.9.0;

contract Users{
    mapping(address=> string) public userBio;
    
    function updateBio(string memory bio) public {
        userBio[msg.sender]=bio;
    }
}
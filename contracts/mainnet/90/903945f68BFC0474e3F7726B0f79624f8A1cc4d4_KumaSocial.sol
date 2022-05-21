pragma solidity ^0.8.0;

contract KumaSocial {

    // On Chain Discord Directory
    mapping(address => string) public addressToDiscord;

    function setDiscordIdentity(string calldata discordTag_) external {
        addressToDiscord[msg.sender] = discordTag_;
    }

    // Your Twitter if you are adventurous
    mapping(address => string) public addressToTwitter;

    function setTwitterIdentity(string calldata twitterTag_) external {
        addressToTwitter[msg.sender] = twitterTag_;
    }

    function setDiscordAndTwitter(string calldata discordTag_, string calldata twitterTag_) external {
        addressToDiscord[msg.sender] = discordTag_;
        addressToTwitter[msg.sender] = twitterTag_;
    }

    function getDiscordAndTwitter(address _address) external view returns (string memory, string memory){
        return (addressToDiscord[_address], addressToTwitter[_address]);
    }
}
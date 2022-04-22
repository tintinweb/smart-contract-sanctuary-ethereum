/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract EtherLinks {
    address owner;

    constructor() payable {
        owner = msg.sender;
    }

    // Define profile object structure
    struct Profile {
        address profile;
        uint256 timestamp;
        string logo;
        string header;
        string paragraph;
    }

    // Define input structure for profile data (users should not manipulate timestamp or address)
    struct ProfileInput {
        string logo;
        string header;
        string paragraph;
    }

    // Define link object structure
    struct Link {
        string[] url;
        string[] icon;
        string[] text;
    }

    string[] LinkInput = new string[](3);

    Profile newProfile;     // create profile object
    Link[] newLinks;        // create a list of link objects
    Link newLink;           // create single link object

    // Create mappings for profiles and link lists, keyed by an address
    mapping (address => Profile) etherlink_profiles;
    mapping (address => Link) etherlink_links;

    // Set profile data for user address - three simple text inputs, address and timestamp are derived
    function setProfile(ProfileInput memory _profile) public {
        etherlink_profiles[msg.sender].profile = msg.sender;
        etherlink_profiles[msg.sender].timestamp = block.timestamp;
        etherlink_profiles[msg.sender].logo = _profile.logo;
        etherlink_profiles[msg.sender].header = _profile.header;
        etherlink_profiles[msg.sender].paragraph = _profile.paragraph;
    }

    // Set link data for user address - read as a keyed struct of three string arrays
    function setLinks(Link memory _link) public {
        etherlink_links[msg.sender].url = _link.url;
        etherlink_links[msg.sender].icon = _link.icon;
        etherlink_links[msg.sender].text = _link.text;
    }

    // Fetch the profile data of the sending address
    function getProfile(address _addr) public view returns (Profile memory) {
        return etherlink_profiles[_addr];
    }

    // Fetch the profile data of the sending address
    function getLinks(address _addr) public view returns (Link memory) {
        return etherlink_links[_addr];
    }
}
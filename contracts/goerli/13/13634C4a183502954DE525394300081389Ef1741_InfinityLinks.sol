// JavaScript Mastery Code
// pragma solidity ^0.8.9;

// contract CrowdFunding {
//     struct Campaign {
//         address owner;
//         string title;
//         string description;
//         uint256 target;
//         uint256 deadline;
//         uint256 amountCollected;
//         string image;
//         address[] donators;
//         uint256[] donations;
//     }

//     mapping(uint256 => Campaign) public campaigns;

//     uint256 public numberOfCampaigns = 0;

//     function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
//         Campaign storage campaign = campaigns[numberOfCampaigns];

//         require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

//         campaign.owner = _owner;
//         campaign.title = _title;
//         campaign.description = _description;
//         campaign.target = _target;
//         campaign.deadline = _deadline;
//         campaign.amountCollected = 0;
//         campaign.image = _image;

//         numberOfCampaigns++;

//         return numberOfCampaigns - 1;
//     }

//     function donateToCampaign(uint256 _id) public payable {
//         uint256 amount = msg.value;

//         Campaign storage campaign = campaigns[_id];

//         campaign.donators.push(msg.sender);
//         campaign.donations.push(amount);

//         (bool sent,) = payable(campaign.owner).call{value: amount}("");

//         if(sent) {
//             campaign.amountCollected = campaign.amountCollected + amount;
//         }
//     }

//     function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
//         return (campaigns[_id].donators, campaigns[_id].donations);
//     }

//     function getCampaigns() public view returns (Campaign[] memory) {
//         Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

//         for(uint i = 0; i < numberOfCampaigns; i++) {
//             Campaign storage item = campaigns[i];

//             allCampaigns[i] = item;
//         }

//         return allCampaigns;
//     }
// }



// chatGPT
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract InfinityLinks {
    struct Link {
        address owner; // Ethereum address of the link owner
        string username; // Username of the link owner
        string description; // Description of the link owner or their project
        string image; // Image of the link owner or their project
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        address[] donators;
        uint256[] donations;
        string[] socialMediaLinks; // Array of social media links provided by the link owner
        string[] musicLinks; // Array of music links provided by the link owner
        string[] contactLinks; // Array of contact links provided by the link owner
        string[] urlLinks; // Array of url links provided by the link owner
        uint256 tipAmount;
        uint256 viewCount;
        mapping(address => uint256) tipsReceived; // Mapping of tips received by the link owner
    }

    mapping(string => Link) public links; // Mapping of links created by the users

    uint256 public numberOfLinks = 0;
    uint256 public linkCount = 0;

    // This function allows a user to create a new InfinityLink
    function createLink(string memory _username, string memory _description, string memory _image, string[] memory _socialMediaLinks, string[] memory _musicLinks, string[] memory _urlLinks, string[] memory _contactLinks) public returns (string memory) {
        Link storage link = links[_username];

        require(bytes(_username).length > 0, "Username is required");
        require(bytes(_description).length > 0, "Description is required");
        require(bytes(_image).length > 0, "Image is required");

        link.owner = msg.sender;
        link.username = _username;
        link.description = _description;
        link.image = _image;
        link.socialMediaLinks = _socialMediaLinks;
        link.musicLinks = _musicLinks;
        link.urlLinks = _urlLinks;
        link.contactLinks = _contactLinks;

        // increment link count
        linkCount++;
        numberOfLinks++;

        return _username;
    }

    function generateLinkId() private view returns (string memory) {
        // generate unique link id based on current block timestamp and link count
        return string(abi.encodePacked("link", block.timestamp, linkCount));
    }

    function viewLink(string memory _username) public {
        Link storage link = links[_username];

        // increment view count for link
        link.viewCount++;
    }

    // This function allows users to tip the link owner
    function tipLinkOwner(string memory _username) public payable {
        Link storage link = links[_username];

        require(link.owner != address(0), "Link does not exist");

        address payable owner = payable(link.owner);
        uint256 amount = msg.value;

        owner.transfer(amount); // Transfer the tip amount to the link owner
        link.tipsReceived[msg.sender] += amount; // Record the tip amount in the mapping
    }

    // This function returns the tips received by the link owner
    function getTipsReceived(string memory _username) public view returns (uint256) {
        Link storage link = links[_username];

        return link.tipsReceived[msg.sender];
    }

    // This function returns the details of a particular InfinityLink
    function getLinkDetails(string memory _username) public view returns (address, string memory, string memory, string memory, string[] memory, string[] memory, string[] memory, string[] memory, uint256) {
        Link storage link = links[_username];

        return (link.owner, link.description, link.image, _username, link.socialMediaLinks, link.musicLinks, link.urlLinks, link.contactLinks, link.tipsReceived[msg.sender]);
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner; // owner address
        string title; // campaign title
        string description; // campaign Description
        uint256 target; // campaign target fundrasing
        uint256 deadline; // campaign deadline mean how many days it will run;
        uint256 amountCollected; //total collected amount from campain
        string image; // image of campaign
        address[] donators; // list of all donators or array
        uint256[] donations; // all donations  of compagin
    }
    mapping(uint256 => Campaign) public posts;
    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        Campaign storage cam = posts[numberOfCampaigns];
        // validate the data by required condition if its true it stop and show us tha message
        require(
            cam.deadline < block.timestamp,
            "the deadline should be date from future."
        );
        cam.owner = _owner;
        cam.title = _title;
        cam.description = _description;
        cam.target = _target;
        cam.deadline = _deadline;
        cam.image = _image;
        cam.amountCollected = 0;
        numberOfCampaigns++;
        return numberOfCampaigns - 1;
    }

    // when we add paypal its mean from that function we want to send  some payments
    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value; // this the value or amount which we get from sender (from front-end using)
        Campaign storage cam = posts[_id];
        cam.donators.push(msg.sender); // we are pusing the address of the donators
        cam.donations.push(amount); // here we are pusing the amount in to the donatoins so we can get after all all donations values
        // lets now make  transaction
        (bool sent, ) = payable(cam.owner).call{value: amount}("");

        //  now after transaction let,s add that amount into the  the  amount collected
        if (sent) {
            cam.amountCollected = cam.amountCollected + amount;
        }
    }

    // the below function will be view function so that we can view data so it wll return for us.
    function getDonators(uint256 _id)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return (posts[_id].donators, posts[_id].donations);
    }

    // here we are fetching all compaigns so make sure you give the exact  parameter name as the  your struct has.
    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allPosts = new Campaign[](numberOfCampaigns);

        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = posts[i];
            allPosts[i] = item;
        }
        return allPosts;
    }
}
// SPDX-License-Identifier: UNLICENSED

pragma solidity = 0.8.17;


contract CrowdFunding {

    // A struct to hold information about each campaign they create
    struct userInfo {
        address owner;
        string title;
        uint amountNeeded;
        uint deadline;
        uint amountRaised;
    }

    // A modifier to check mate that only the owner of a campaign can call certain fucntions in the smart contract
    modifier Onlyowner{
        address _owner = msg.sender;
        require(msg.sender == contributions[_owner].owner, "Retricted to owners only");
        _;
    }

    // A mapping to store all campaigns by their owner's address
    mapping(address => userInfo) public contributions;

    // Function to create a new campaign
    function createCampaign (string memory _title, uint _goal, uint _deadline) public {
        // Get the address of the owner of the campaign
        address _owner = msg.sender;

        // A time conversion factor in solidity
        uint mydeadline = block.timestamp + (86400 * _deadline);

        // Check that the goal and deadline are valid
        require(_goal > 0);
        require(mydeadline > block.timestamp);

        // Create the new campaign and add it to the mapping
        userInfo memory createnewCampaign = userInfo(_owner, _title, _goal, mydeadline, 0);
        // N/B: changing a state variable directly cost alot of gas. inorder to save gas,
        // storing the state variable in memory then make changes in memory saves gas.
        contributions[_owner] = createnewCampaign;
    }



    // Function to fund a campaign
    function contribute(uint _amount) public payable {
        address payable _Owner = payable(msg.sender); //making owner address payable to enable it receive ether.

        // Check that the campaign owner address is valid
        require(_Owner != address(0), "Invalid campaign owner address");

        //check if amount needed haz been reached or not.
        require(contributions[_Owner].amountRaised < contributions[_Owner].amountNeeded, "Goal already reached");
        // require(msg.value >= _amount);

        // Check that the deadline has not passed
        require(contributions[_Owner].deadline > block.timestamp);
        contributions[_Owner].amountRaised += _amount;
        _Owner.transfer(_amount);
        contributions[_Owner].amountRaised += msg.value;
    }


    // Function to withdraw funds from a campaign
    function withdraw() public Onlyowner{
        // Get the address of the campaign owner
        address payable _Owner = payable(msg.sender);

        // Check that there are funds to withdraw
        require(contributions[_Owner].amountRaised > 0);

         // Check that the deadline has passed
        require(block.timestamp > contributions[_Owner].deadline, "not ended");

        // Transfer the raised funds to the campaign owner
        _Owner.transfer(contributions[_Owner].amountRaised);
    }

    // function to delete campaign when created
    function deleteCampaign(address _Owner) public Onlyowner {

        // check that no contributions has been made yet
        require(contributions[_Owner].amountRaised == 0);
        delete contributions[_Owner];
    }


}
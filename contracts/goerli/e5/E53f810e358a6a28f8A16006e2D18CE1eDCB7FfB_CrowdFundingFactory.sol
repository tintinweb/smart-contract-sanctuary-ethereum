// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFundingFactory {
    address payable[] public deployedCampaigns;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image,
        address payable[] memory _receivers
    ) public returns (address) {
        address newCampaign = address(
            new CrowdFunding(
                _owner,
                _title,
                _description,
                _target,
                _deadline,
                _image,
                _receivers
            )
        );
        deployedCampaigns.push(payable(newCampaign));
        return (newCampaign);
    }

    function getDeployedCampaigns()
        public
        view
        returns (address payable[] memory)
    {
        return deployedCampaigns;
    }
}

contract CrowdFunding {
    address public owner;
    string public title;
    string public description;
    uint256 public target;
    uint256 public deadline;
    uint256 public amountCollected;
    string public image;
    address[] public donators;
    address payable [] public receivers;
    uint256[] public donations;
    bool public fundingClosed;

    constructor(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image,
        address payable[] memory _receivers
    ) {
        require(
            _deadline > block.timestamp,
            "The deadline should be a date in the future."
        );

        owner = _owner;
        title = _title;
        description = _description;
        target = _target;
        deadline = _deadline;
        amountCollected = 0;
        image = _image;
        receivers = _receivers;
        fundingClosed = false;
    }

    function donate() public payable {
        require(!fundingClosed, "Funding is closed");

        uint256 amount = msg.value;

        donators.push(msg.sender);
        donations.push(amount);

        (bool sent, ) = payable(owner).call{value: amount}("");

        if (sent) {
            amountCollected = amountCollected + amount;
        }
    }

    function closeFunding() public {
        require(!fundingClosed, "Funding is already closed");
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );

        //require(
        //    block.timestamp > deadline,
        //    "The deadline has not been reached yet."
        //);
        require(
            amountCollected >= target,
            "The target has not been reached yet."
        );

        uint256 amountPerReceiver = amountCollected / receivers.length;

        for (uint256 i = 0; i < receivers.length; i++) {
            //Now only sending ethers, no problem with the token
            receivers[i].transfer(amountPerReceiver);
        }


        fundingClosed = true;
    }

    function getDonators()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return (donators, donations);
    }

    function getDonatorAddresses() public view returns (address[] memory) {
        return donators;
    }

    function getDonations() public view returns (uint256[] memory) {
        return donations;
    }

    function getReceivers() public view returns (address payable[] memory) {
        return receivers;
    }
}
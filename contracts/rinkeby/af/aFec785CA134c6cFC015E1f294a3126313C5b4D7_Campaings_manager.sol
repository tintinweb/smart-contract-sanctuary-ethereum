// SPDX-License-Identifier: UNLICENSED
pragma  solidity ^0.8.4;

import "Campaings.sol";

contract Campaings_manager {

    struct DeployCampaing {
        address DeployedCampaigAddress;
        address Creator;
        uint id;
    }

    DeployCampaing[] public DeployedCampaings;
    address[] Creators;

    function CreateCampaing () public {
        Campaings newCampaig = new Campaings(payable(msg.sender));
        uint id = DeployedCampaings.length;
        DeployedCampaings.push(DeployCampaing(address(newCampaig), msg.sender, id));
        Creators.push(msg.sender);
    }

    function getCampaings() public view returns(DeployCampaing[] memory ) {
        return DeployedCampaings;
    }

    function getCreators() public view returns(address[] memory ) {
        return Creators;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Campaings {
    address Creator;
    address[] Funders;
    mapping(address => uint256) public AddressToAmountFunded;
    uint256 TotalAmountFunded;
    uint256 AmountToAccomplish;
    uint256 Id;

    constructor(address _Creator) {
        Creator = _Creator;
    }

    function setId(uint256 _id) public {
        Id = _id;
    }

    function getId() public view returns (uint256) {
        return Id;
    }

    function getCreator() public view returns (address) {
        return Creator;
    }

    function addFunder() public payable {
        Funders.push(payable(msg.sender));
        TotalAmountFunded += msg.value;
    }

    function withdraw() public payable {
        for (uint256 i = 0; i < Funders.length; i++) {
            payable(Funders[i]).transfer(AddressToAmountFunded[Funders[i]]);
        }
        TotalAmountFunded = 0;
        Funders = new address payable[](0);
    }
}
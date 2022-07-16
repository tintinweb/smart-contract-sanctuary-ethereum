// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import './CrowdFunding.sol';

contract CrowdFundingFactory {
    address[] public campaigns;

    function getAllCampaigns() external view returns (address[] memory) {
        return campaigns;
    }

    function campaignsCount() external view returns (uint) {
        return campaigns.length;
    }

    function createCampaign(string calldata _title, uint _target) 
    external returns(address campaign) 
    {
        bytes memory bytecode = type(CrowdFunding).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp));
        assembly{
            campaign := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ICrowdFunding(campaign).createCampaign(_title, _target);
        campaigns.push(campaign);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import './interface/ICrowdFunding.sol';

contract CrowdFunding is ICrowdFunding {

    address public immutable override factory;

    string public title;
    uint target;
    uint amountReceived;

    mapping(address => Donor) public donors;

    constructor(){factory = msg.sender;}

    function createCampaign(string calldata _title, uint _target) public override {
        title = _title;
        target = _target;
    }

    function donate(uint amount) public override {
        amountReceived += amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface ICrowdFunding {
    struct Donor {
        bool donated;
        uint amountDonated;
    }

    function factory() external view returns(address);

    function createCampaign(string calldata _title, uint _target) external;

    function donate(uint _amount) external;
}
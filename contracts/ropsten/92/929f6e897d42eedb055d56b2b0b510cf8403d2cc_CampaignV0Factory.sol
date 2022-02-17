pragma solidity ^0.8.11;
import "./Clones.sol";
import "./CampaignV0.sol";

contract CampaignV0Factory {
  address public campaignV0Implementation;
  mapping (address => uint64) public initializedCampaigns;
  address[] public campaigns;

  function getAllCampaigns() public view returns (address[] memory) {
    return campaigns;
  }

  event campaignCreated(address campaign, address indexed creator);

  constructor(address _campaignV0Implementation) {
    campaignV0Implementation = _campaignV0Implementation;
  }

  function createCampaign(uint64 _deadline, uint256 _fundingGoal, uint256 _fundingMax, string calldata _title, string calldata _description) public returns (address newCampaign) {
    address clone = Clones.clone(campaignV0Implementation);
    CampaignV0(clone).init(msg.sender, _deadline, _fundingGoal, _fundingMax, _title, _description);
    emit campaignCreated(clone, msg.sender);
    initializedCampaigns[clone] = uint64(block.timestamp);
    campaigns.push(clone);
    return clone;
  }
}
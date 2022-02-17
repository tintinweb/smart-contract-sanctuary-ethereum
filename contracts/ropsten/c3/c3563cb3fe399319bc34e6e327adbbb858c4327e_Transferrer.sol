pragma solidity ^0.8.11;
import "./IERC20.sol";
import "./CampaignV0.sol";

/*
  donates funds to a specified campaign on behalf of the sender so the
  user only needs to approve their funds once
*/
contract Transferrer {
  address public daiAddress;

  constructor(address _daiAddress) {
    daiAddress = _daiAddress;
  }

  function donate(address _campaignAddress, uint256 _amount) public {
    IERC20(daiAddress).transferFrom(msg.sender, _campaignAddress, _amount);
    CampaignV0(_campaignAddress).donate(msg.sender, _amount);
  }
}
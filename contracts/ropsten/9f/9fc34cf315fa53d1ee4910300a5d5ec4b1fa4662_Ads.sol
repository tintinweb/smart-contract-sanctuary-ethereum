/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Ads {
  string public projectName;

  uint public adsCount = 0;
  AdsData [] public adsDataArray;
  mapping(uint => AdsData) public ads_data;

  struct AdsData {
    uint id;
    address owner;
    string _id;
    string adsData;
    uint crId;
    uint campaignCode;
    uint advertiserCode;
    uint orgId;
  }

  event AdsCreated(
    uint id,
    address owner,
    string _id,
    string adsData,
    uint crId,
    uint campaignCode,
    uint advertiserCode,
    uint orgId
  );

  constructor() {
    projectName = "AUD30-Eth-Application";
  }

  function saveAds(
    string memory _id,
    string memory _adsData,
    uint _crId,
    uint _campaignCode,
    uint _advertiserCode,
    uint _orgId
  ) public {
    adsCount ++;
    // Create the ads
    ads_data[adsCount] = AdsData(
      adsCount,
      msg.sender,
      _id,
      _adsData,
      _crId,
      _campaignCode,
      _advertiserCode,
      _orgId
    );
    adsDataArray[adsCount] = (
        AdsData(
            adsCount,
            msg.sender,
            _id,
            _adsData,
            _crId,
            _campaignCode,
            _advertiserCode,
            _orgId
        )
    );
    // Trigger an event
    emit AdsCreated(
      adsCount,
      msg.sender,
      _id,
      _adsData,
      _crId,
      _campaignCode,
      _advertiserCode,
      _orgId
    );
  }

  function getSavedAdsData() public view returns (AdsData[] memory) {
    return adsDataArray;
  }
}
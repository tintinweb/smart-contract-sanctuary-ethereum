/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function time() external view returns(uint) {
      return block.timestamp;
  }

  struct UserAssetInfo {
      uint blocks;
    AssetInfo[] assetList;
  }

    struct AssetInfo {
        address asset;
        uint256 amount;
    }

    function teststruct1() external view returns(UserAssetInfo memory) {
        UserAssetInfo memory vars;
        vars.assetList = new AssetInfo[](0);
        vars.blocks = block.number;
        vars.assetList[vars.assetList.length]=AssetInfo({
            asset: 0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210,
            amount: 1
        });
        vars.assetList[vars.assetList.length]=AssetInfo({
            asset: 0xdb2276bAC9F27A7AF8d608fFE21036303aa3486A,
            amount: 2
        });
        vars.assetList[vars.assetList.length]=AssetInfo({
            asset: 0xf4423F4152966eBb106261740da907662A3569C5,
            amount: 3
        });

        return vars;
    }

    function teststruct() external view returns(UserAssetInfo memory) {
        UserAssetInfo memory vars;
        vars.blocks = block.number;
        vars.assetList[vars.assetList.length]=AssetInfo({
            asset: 0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210,
            amount: 1
        });
        vars.assetList[vars.assetList.length]=AssetInfo({
            asset: 0xdb2276bAC9F27A7AF8d608fFE21036303aa3486A,
            amount: 2
        });
        vars.assetList[vars.assetList.length]=AssetInfo({
            asset: 0xf4423F4152966eBb106261740da907662A3569C5,
            amount: 3
        });

        return vars;
    }

    function teststruct2() external pure returns(AssetInfo[] memory) {
        AssetInfo[] memory arr = new AssetInfo[](2);
        AssetInfo memory a0 = arr[0];
        a0.asset = 0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210;
        a0.amount = 1;
        
        AssetInfo memory a1 = arr[1];
        a1.asset = 0xdb2276bAC9F27A7AF8d608fFE21036303aa3486A;
        a1.amount = 2;
        
        return arr;
    }
}
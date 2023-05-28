/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract InTownMetaverseAssetManifest{
    
    // Interface for the asset objects we're storing
    struct Asset {
        string integrity;
        string filename;
        string cid;
        uint experience_id;
        string creator;
        string[] categories;
        string[] tags;
    }

    struct BuildingAsset {
        string model;
        string creator;
        string positionx;
        string positiony;
        string positionz;
        string rotationx;
        string rotationy;
        string rotationz;
        string scale;
    }

    struct Building {
        string plotId;
        string creator;
        BuildingAsset[] buildingAsset;
    }

    struct Plot {
        string owner;
        string plotId;
    }

    // add the keyword payable to the state variable 
    address payable public Owner;

    // set the price of adding an item to the network
    uint256 minRequired = 0.000001 * 1 ether;

    // set the owner to the msg.sender 
    constructor () { 
        Owner = payable(msg.sender);
    }

    Asset[] private assetManifest;
    Building[] private buildingManifest;
    Plot[] private plotManifest;

    function registerAsset(Asset memory asset) payable public {

        uint256 amount = msg.value;

        if (amount < minRequired) {
            revert ("Not enough ether sent");
        }

        assetManifest.push(
            asset
        );
    }

    function getAssetById(uint256 id) public view returns (Asset memory){
        return assetManifest[id];
    }

    function getAllAssets() public view returns (Asset[] memory){
          Asset[] memory assetArray = new Asset[](assetManifest.length);

            for (uint i = 0; i < assetManifest.length; i++) {
            assetArray[i] = assetManifest[i];
            }

        return assetArray;
    }

    function registerBuilding(Building calldata building) payable public {
        uint256 amount = msg.value;

        if (amount < minRequired) {
            revert ("Not enough ether sent");
        }

        buildingManifest.push(
            building
        );
    }

    function getBuildingById(uint256 id) public view returns (Building memory){
        return buildingManifest[id];
    }

    function getAllBuildings() public view returns (Building[] memory){
          Building[] memory buildingArray = new Building[](buildingManifest.length);

            for (uint i = 0; i < buildingManifest.length; i++) {
                buildingArray[i] = buildingManifest[i];
            }

        return buildingArray;
    }

    modifier onlyOwner () {
        require(msg.sender == Owner, 'Not owner'); 
        _;
    }

    // the owner can add an asset for free
    function registerAssetByOwner(Asset memory asset) public onlyOwner {

        assetManifest.push(
            asset
        );
    }

    // the owner can add a building for free
    function registerBuildingByOwner(Building calldata building) public onlyOwner {
        // call the land smart contract and populate private Plot Array
        // check to see if the plotId passed in is owned by the calling user (plotId.owner === msg.sender)
        buildingManifest.push(
            building
        );
    }

    // the owner can withdraw from the contract because payable was added to the state variable above
    function withdraw (uint _amount) public onlyOwner { 
        Owner.transfer(_amount); 
    }

    // private helper functions
    function compare(string memory str1, string memory str2) private pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}
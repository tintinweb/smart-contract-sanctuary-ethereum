/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IInTownMetaverseLand {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract InTownMetaverseAssetManifest{

    // Interface for the asset objects we're storing
    struct Asset {
        string integrity;
        string filename;
        string cid;
        string experience_id;
        address owner;
        string[] categories;
        string[] tags;
        bool exists;
    }

    struct BuildingAsset {
        string positionx;
        string positiony;
        string positionz;
        string rotationx;
        string rotationy;
        string rotationz;
        string scale;
        bool exists;
    }

    struct Building {
        address owner;
        BuildingAsset[] buildingAssets;
        bool exists;
    }

    struct Plot {
        uint256 buildingId;
        uint256 plotId;
        address owner;
    }

    // the contract address for the land collection
    address landContractAddr;

    // add the keyword payable to the state variable 
    address payable public Owner;

    // set the price of adding an item to the network
    uint256 minRequired = 0.000000001 * 1 ether;

    // set the owner to the msg.sender 
    constructor () { 
        Owner = payable(msg.sender);
    }

    Asset[] private assetManifest;
    Building[] private buildingManifest;
    Plot[] private plotManifest;

    function setLandContractAddr(address _landContractAddr) public onlyOwner {
       landContractAddr = _landContractAddr;
    }

    function registerAsset(Asset calldata asset) payable external {

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

    function assignBuildingToPlot(uint256 plotId, uint256 buildingId) payable public {
        // check if ether was sent along with the request
        uint256 amount = msg.value;

        if (amount < minRequired) {
            revert ("Not enough ether sent");
        }

        // check if passed in buildingId exists
        require(buildingManifest[buildingId].exists, "BuildingId does not exist.");

        Building memory building = buildingManifest[buildingId];

        if (building.owner != msg.sender) {
            revert("You are not the owner of the buildingId supplied");
        }
        
        // call the land smart contract to check the ownership of plotId
        address plotOwner = IInTownMetaverseLand(landContractAddr).ownerOf(plotId);

        if (msg.sender != plotOwner) {
            revert("Calling address does not match plot owner");
        }

        // All good, add the building to the plot
        plotManifest.push(
            Plot(buildingId, plotId, plotOwner)
        );
    }

    function getPlotById(uint256 id) public view returns (Plot memory){
        return plotManifest[id];
    }

    function getAllPlots() public view returns (Plot[] memory){
          Plot[] memory plotArray = new Plot[](plotManifest.length);

            for (uint i = 0; i < plotManifest.length; i++) {
                plotArray[i] = plotManifest[i];
            }

        return plotArray;
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
    function registerAssetByOwner(Asset calldata asset) external onlyOwner {
        assetManifest.push(
            asset
        );
    }

    // the owner can add a building for free
    function registerBuildingByOwner(Building calldata building) external onlyOwner {
        buildingManifest.push(
            building
        );
    }

    // the owner can withdraw from the contract because payable was added to the state variable above
    function withdraw (uint _amount) public onlyOwner { 
        Owner.transfer(_amount); 
    }
}
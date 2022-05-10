/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

pragma solidity >=0.4.22 <0.9.0;
contract Krishi {
    FarmerAsset[] private farmerAssets;

    event AssetRegistered(address asset, address owner, uint rent);

    function registerAsset(string memory assetId, uint rent)
        external {
        FarmerAsset newAsset = new FarmerAsset(assetId,rent,payable(msg.sender));
        farmerAssets.push(newAsset);
        emit AssetRegistered(address(newAsset),msg.sender,rent);
    }

    function returnAssets() external view returns (FarmerAsset[] memory) {
        return farmerAssets;
    }
}

contract FarmerAsset {
    
    string assetId;
    uint rent;
    address payable public owner; //Original Owner of Farmland/Machinery
    address public rentee; //Who has hired Land/Machine on rent

    constructor(string memory _assetId,uint _rent, address payable _owner) public{
        owner = _owner;
        assetId = _assetId;
        rent = _rent;
    }

    event RentPayed(address sender, uint amount, address to);
    event RenteeChanged(string assetid,address to);

    modifier onlyOwner() {
        require(owner == msg.sender, 'Not Owner');
        _;
    }
    modifier onlyRentee() {
        require(rentee == msg.sender, 'Not Rentee');
        _;
    }

    function setRentee(address _rentee) external onlyOwner{
        rentee = _rentee;
        emit RenteeChanged(assetId,_rentee);
    }

    function payRent() payable external onlyRentee {
        owner.transfer(rent);
        emit RentPayed(rentee,rent,owner);
    }

    function getDetails() public view returns(address payable o, address r, string memory a){
        o = owner;
        r = rentee;
        a = assetId;
    }
}
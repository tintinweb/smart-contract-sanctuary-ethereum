/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ITyeNFTTemplate {
    function createCollection(string memory _name, string memory _symbol) external returns (address);
}
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor(){
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}
 contract proxyDeployer is Owned {
     event DeployedAddress(address indexed deployesAddress);
     struct CollectionDetails {
         address collectionAddress;
     }
     mapping (address => CollectionDetails) private collectionsList;
     address deployedAddress;
     function setdeployerAddress(address _deployerAddress) public onlyOwner {
         deployedAddress = _deployerAddress;
     }
     function deployerFunction(string memory name, string memory symbol) public onlyOwner {
         address _collectionAddress = ITyeNFTTemplate(deployedAddress).createCollection(name, symbol);
         CollectionDetails memory _CollectionDetails;
         _CollectionDetails.collectionAddress = _collectionAddress;
         collectionsList[_collectionAddress] = _CollectionDetails;
         emit DeployedAddress(_collectionAddress);
     }
     function getAddress() public view returns(address){
         return deployedAddress;
     }
     function getCollectionDetails(address _collectionAddress) public view returns (CollectionDetails memory){
         return collectionsList[_collectionAddress];
     }
 }
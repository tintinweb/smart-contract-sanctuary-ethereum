// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
/**
* @title CT Marketplace
* @author Nassim Dehouche
*/

import "Ownable.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";
import "SafeMath.sol";

contract CTMarketplace is Ownable, Pausable, ReentrancyGuard{ 

/// @dev Toggle pause boolean 
    function togglePause() external onlyOwner {
        if (paused()) {_unpause();}
        else _pause();
    }

///@dev Dataset creation fee
uint creationFee;
/// @dev Dataset creator addition event   
event creatorAdded(address _creator);
/// @dev Dataset creator deletion event   
event creatorDeleted(address _creator);
/// @dev Dataset submission event 
event datasetSubmitted(address _creator, address _owner, uint _index);
/// @dev Dataset approval event 
event datasetApproved(address _creator, address _owner); 
/// @dev License request event 
event licenseRequested(address _licensee, address _owner, uint _index);
/// @dev Dataset licensed event 
event datasetLicensed(address _creator, address _owner, address _licensee, uint _index); 

/// @dev Added creators
mapping (address => bool) creators;
 
/// @dev The patient structure
enum Genders{ MALE, FEMALE}
struct patient{ 
  address payable wallet;
  Genders gender;
  uint age;
  }

/// @dev The dataset structure
struct dataset{ 
  address payable patient;
  address payable creator;
  bytes32 hash;
  uint royalties;
  bool approved;
  uint licenseDuration;
  uint fee;
  mapping(address => uint) licenses;
  }




/// @dev Mapping patients with an array of their datasets
mapping(address => dataset[]) datasets; 

/// @dev ETH balances
mapping(address => uint) balance; 

/// @dev Receive function
receive() external payable { 
}

/// @dev Fallback function. We check data length in fallback functions as a best practice
fallback() external payable {
require(msg.data.length == 0); 
}


/// @dev Modifier for dataset creation
modifier onlyIfCreator(address _creator) {
    require(creators[_creator]==true);
    _;
}
modifier onlyIfValidRoyalties(uint _royalties) {
    require(_royalties<=100);
    _;
}

/// @dev Payment modifier
modifier onlyIfPaidEnough(uint _value) {
    require(msg.value==_value);
    _;
}

/// @dev Approved dataset modifier
modifier onlyIfApproved(address _owner, uint _id) {
    require(datasets[_owner][_id].approved==true);
    _;
}


/// @notice Creator addition for the contract's owner
function addCreator(address _creator) public 
onlyOwner
{   
emit creatorAdded(_creator);
creators[_creator]=true;
}

/// @notice Creator deletion for the contract's owner
function deleteCreator(address payable _creator) public 
onlyOwner
{   
emit creatorDeleted(_creator);
creators[_creator]=false;
}


/**
@dev The submission function. Returns the index of the dataset among the patient's datasets
*/
function submitDataset(address _patient, bytes32 _hash, uint _royalties) public payable
onlyIfCreator(msg.sender)
onlyIfValidRoyalties(_royalties)
onlyIfPaidEnough(creationFee)
returns(uint _id)
{  
_id= datasets[_patient].length;
emit datasetSubmitted(msg.sender, _patient, _id);
/**
dataset memory newDataset = dataset({
patient: payable(_patient),
creator:payable(msg.sender),
hash: _hash,
royalties:_royalties,
approved: false,
licenseDuration:0,
fee:0
});
datasets.push(newDataset);
*/

dataset[] storage d = datasets[_patient];
d.push();
d[_id].patient = payable(_patient);
d[_id].creator=payable(msg.sender);
d[_id].hash=_hash;
d[_id].royalties=_royalties;
d[_id].approved=false;
d[_id].licenseDuration=0;
d[_id].fee=0;


return _id;
}

function approveDataset(uint _id, uint _duration, uint _fee) public
{  
datasets[msg.sender][_id].approved=true;
datasets[msg.sender][_id].licenseDuration=_duration;
datasets[msg.sender][_id].fee=_fee;
emit datasetApproved(datasets[msg.sender][_id].creator, msg.sender);
}

function requestLicense(address _owner, uint _id) public payable
onlyIfApproved(_owner, _id)
onlyIfPaidEnough(datasets[_owner][_id].fee)

{  
emit licenseRequested(msg.sender, _owner, _id);
datasets[_owner][_id].licenses[msg.sender]=block.timestamp;
emit datasetLicensed(datasets[_owner][_id].creator, _owner, msg.sender, _id); 
balance[datasets[_owner][_id].creator]+=datasets[_owner][_id].royalties*msg.value/100;
balance[_owner]+=msg.value-datasets[_owner][_id].royalties*msg.value/100;
}

function withdrawBalance() public nonReentrant returns(bool) 
{
        balance[msg.sender]=0;
        (bool sent, ) = msg.sender.call{value: balance[msg.sender]}("");
        require(sent, "Failed to send Ether");
        return true;

    }

function hasAccess(address _owner, uint _id) public view returns(bool) 
{
  return(block.timestamp>datasets[_owner][_id].licenses[msg.sender] && 
  block.timestamp<datasets[_owner][_id].licenses[msg.sender]+datasets[_owner][_id].licenseDuration);

    }


}
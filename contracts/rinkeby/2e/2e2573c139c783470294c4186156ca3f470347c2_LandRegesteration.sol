/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

//1. creat a land registery

contract LandRegesteration{

struct LandRegestery{
    verificationStatus verification;
    address currentOwner;  
    uint area;
    string city;
    string state;
    uint landPrice;
    string propertyPID;
    }

struct sellerRegesteration{
     address id;
     string name;
     uint age;
     string city;
     uint CNIC;
     string Email;
}
struct BuyerRegesteration{
     address id;
     string name;
     uint age;
     string city;
     uint CNIC;
     string Email;
 }
struct landInspectorRegesteration{
     address id;
     string name;
     uint age;
     string designation;
}

//public variables

address[] public selleraddress;
address[] public buyeraddress;
address public landInspectorAddress;

constructor (){
        landInspectorAddress=msg.sender;
}

modifier OnlylandInspector(){   
     require(landInspectorAddress ==msg.sender,"you are not landInspector");
    _;}
     enum verificationStatus{
     notVerified,
     verified   
}

address payable private Address; 
 uint weiinether = 1000000000000000000;

mapping (uint=> LandRegestery) public  regMapping;  
mapping (address=>sellerRegesteration) public sellerMapping;
mapping (address=>BuyerRegesteration) public BuyerMapping;
mapping (address=>landInspectorRegesteration)public landInspectorMapping;
mapping (address =>bool)public verifySeller;
mapping (address=>bool)public rejectSeller;
mapping (address =>bool)public verifyBuyer;
mapping (address=>bool)public rejectBuyer;
mapping (uint=>address ) public checkOwnerMapping;

//land regesteration
function creatLand( uint landID,uint area,string memory  city,string memory state, uint landPrice,string memory  propertyPID) public
    {
     landPrice =landPrice*weiinether;
    regMapping  [landID] =LandRegestery(verificationStatus.notVerified,msg.sender,area, city, state, landPrice,propertyPID);

//if seller is verified only then he can upload the land details,if rejected he cannot upload details.

    require (verifySeller[msg.sender]==true,"you are not verified");
    require (!rejectSeller[msg.sender],"you are rejected");
   checkOwnerMapping[landID]=msg.sender; 
    }
   
    //seller regesteration.

function detailOfSeller(address id,string memory  name, uint age,string memory city, uint CNIC,string memory  Email )  public {
    require (verifyBuyer[id]==false && verifyBuyer[msg.sender]==false, "you cannot be regestered as seller");
    sellerMapping[id]=sellerRegesteration(msg.sender,name,age,city,CNIC,Email);
    selleraddress.push(id);
    }

//land inspector regesteration

function landInspectorID( string memory name,uint age, string memory designation)OnlylandInspector public {
    landInspectorMapping[landInspectorAddress]=landInspectorRegesteration(msg.sender,name,age,designation);
    }
//verify or reject the seller.

function sellerVerrification (address id) public OnlylandInspector() {
    verifySeller[id]=true; 
    }
function sellerRejection(address id)public OnlylandInspector(){
    rejectSeller[id]=true;
    }
//update the seller details.

function updatSeller(address id,string memory _name,uint _age, string memory _city,uint _CNIC, string memory _email) public OnlylandInspector() {

    sellerRegesteration storage sellerUpdate=sellerMapping[id];
    sellerUpdate.name = _name;
    sellerUpdate.age = _age;
    sellerUpdate.city=_city;
    sellerUpdate.CNIC=_CNIC;
    sellerUpdate.Email = _email;
    }

// verify land.

function verifyLand(uint landID)public OnlylandInspector() {
    regMapping [landID].verification =  verificationStatus.verified;}
    address public owner;
    modifier OnlyOwner(){
    require(owner==msg.sender,"you are not owner");
    _;  
    }

// regester buyer.

function detailOfBuyer(address id, string memory  name, uint age,string memory city, uint CNIC,string memory  Email )  public {
    require (verifySeller[id]==false && verifySeller[msg.sender]==false, "you cannot be regestered as buyer");
    BuyerMapping[id]=BuyerRegesteration(msg.sender,name,age,city,CNIC,Email);
    buyeraddress.push(id);
    }

//verify the buyer

function buyerVerrification (address id) public OnlylandInspector() {
    verifyBuyer[id]=true;
    }

//check if the address added by buyer or seller is verified.

function isverified(address id) public view returns (bool) {
    if (verifySeller[id] || verifyBuyer[id]){
    return true;

    }
    }
// check the buyer rejection

function buyerRejection(address id)public OnlylandInspector() {
    rejectBuyer[id]=true;
    }

//check if the address added by buyer or seller is rejected.

function isrejected(address id) public view returns (bool) {
    if (rejectSeller[id] || rejectBuyer[id]){
    return true;
    }  
    }

//update the buyer details.

function updateBuyer( address id,string memory _name,uint _age, string memory _city,uint _CNIC, string memory _email) public OnlylandInspector() { 
    BuyerRegesteration storage buyerUpdate=BuyerMapping[id];
    buyerUpdate.name = _name;
    buyerUpdate.age = _age;
    buyerUpdate.city=_city;
    buyerUpdate.CNIC=_CNIC;
    buyerUpdate.Email = _email;
    }

 //buyer will purchase land.

function purchaseLand( uint landID,uint amount)  public payable {
    require( regMapping [landID].verification == verificationStatus.verified, "land is not verified");
    require (verifyBuyer [msg.sender]==true,"you are not verified");
    require(amount == msg.value,"do check again and pay exact same amount");
    require (regMapping [landID].landPrice==amount,"please pay exact price of land");
    payable (regMapping[landID].currentOwner).transfer(msg.value);
    regMapping[landID].currentOwner=msg.sender;   
    }

//owner can transfer the land to any address if it is verified by landinspector.

function tansferOwnership(uint landID,address _address) public {
    checkOwnerMapping[landID]=_address;
    require (checkOwnerMapping[landID]==msg.sender,"you are not owner");
    }

 //check land city 

function getLandcity(uint _city) public view returns (string memory ){
    return regMapping[_city].city;
    }

//check landprice
function getLandprice(uint _price) public view returns (uint ){
    return regMapping[_price].landPrice;
    }

//check land area

function getLandarea(uint _area) public view returns (uint ){
    return regMapping[_area].area;
}
}
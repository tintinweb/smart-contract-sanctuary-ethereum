/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// Start land Project 786
contract LandRegisteration {
    

    constructor (){
        lawyerAddress=msg.sender;
}

modifier Checklawyer(){   
     require(lawyerAddress ==msg.sender,"you are not lawyer");
    _;}
     enum VerificationStatus{
        NotVerified,
        Verify   
}
// make struct for land registery
struct landRegistry{
    VerificationStatus Verify;
    address Owner;
    uint LandID;
    string Area;
    string City;
    string State;
    uint LandPrice;
    string PropertyPID;
}
// Struct For Seller Detail 
struct SellerDetail{
    address sellerID;
    string Name;
    string City;
    uint UID;
}

// Struct for buyer detail  
struct BuyerDetail{
    
    address BuyerID;
    string Name;
    string City;
    uint UID;
}

// Struct For lawyer Detail 
struct lawyer{
    address ID;
    string Name;
    string Designation;

}
// public variables define here 
address public lawyerAddress;

// functions here 
// 1.seller 

function AddSeller(address sellerID, string memory Name , string memory City, uint UID ) public{
   require(VerifyBuyer[sellerID]==false && VerifyBuyer[msg.sender]==false , "you can't use Seller Account" );
   SellerMap[sellerID] = SellerDetail(msg.sender , Name ,City , UID);

  
} 

// 2.buyer 
function AddBuyer(address BuyerID ,string memory Name ,string memory City , uint UID ) public{
    require(VerifySeller[BuyerID] == false && VerifyBuyer[msg.sender] == false , "You can't use buyer Account" );
    BuyerMap[BuyerID] = BuyerDetail(msg.sender ,Name , City , UID);
   

}
   
// convert in either 
 uint  ConvertInEither = 1000000000000000000;
// 3.add land 
function AddLand( uint LandID, string memory Area ,string memory City ,string memory State , uint LandPrice,string memory PropertyPID )public {
    LandPrice = LandPrice*ConvertInEither ;
    lands[LandID] =landRegistry(VerificationStatus.NotVerified,msg.sender,LandID, Area, City, State, LandPrice,PropertyPID);
    require (VerifySeller[msg.sender] == true , "You are not  verify ");
    CheckOwnerMap[LandID] = msg.sender;
}  

// 4.lawyer 
function Makelawyer  ( uint ID, string memory Name , string memory Designation ) public Checklawyer {
    lawyerMap[ID]=lawyer(msg.sender , Name, Designation);

} 
// Update seller and buyer functions here 
// 1.make seller update function 
//function UpdateSeller (address sellerID , string memory __Name, string memory __City , uint __UID )public Checklawyer {
  //  SellerDetail storage SellerUpdate = SellerMap[sellerID];
//    SellerUpdate.Name = __Name;
//    SellerUpdate.City = __City;
//    SellerUpdate.UID = __UID;
//}

// 2.make buyer update function 
//function UpdateBuyer (address BuyerID , string memory __Name , string memory __City , uint __UID )public Checklawyer{
//    BuyerDetail storage BuyerUpdate = BuyerMap[BuyerID];
//    BuyerUpdate.Name = __Name ;
//    BuyerUpdate.City = __City;
//    BuyerUpdate.UID = __UID;
//}


// mapping setup  here 
mapping(uint => landRegistry) public lands;
mapping(uint => lawyer) public lawyerMap;
mapping(address => SellerDetail) public SellerMap;
mapping(address => BuyerDetail) public BuyerMap;
mapping (address =>bool)public VerifySeller;
mapping (address =>bool)public VerifyBuyer;
mapping (uint => bool) public VerifyLand;
mapping (uint=>address ) public CheckOwnerMap;

// seller and buyer verification 
function SellerVerification (address Id) public Checklawyer() {
    VerifySeller[Id]=true; 
    }

function SellerRejection(address Id)public Checklawyer(){
    VerifySeller[Id]=false;
    }

function BuyerVerification (address Id) public Checklawyer() {
    VerifyBuyer[Id]=true;
    }

function BuyerRejection(address Id)public Checklawyer() {
    VerifyBuyer[Id]=false;
    }

function LandVerification (uint LandID) public Checklawyer() {
    VerifyLand[LandID]=true; 
    }

function LandRejection (uint LandID) public Checklawyer() {
    VerifyLand[LandID]=false; 
    }


// perchase land 
function purchaseLand( uint _LandID )  public payable {
    require (VerifyBuyer [msg.sender]==true,"Sorry.. you are not verified");
    require(VerifyLand[_LandID] == true , "Your land is not verified");
    require (lands [_LandID].LandPrice==msg.value,"Your value is less than land price");
    payable (lands[_LandID].Owner).transfer(msg.value);
    lands[_LandID].Owner=msg.sender;       
}

// owner shipment 
function transferOwnership(uint LandID,address __address) public {
    CheckOwnerMap[LandID]=__address;
    require (CheckOwnerMap[LandID]==msg.sender,"you are not the Owner ");
    }
// pricing function all are here 

}
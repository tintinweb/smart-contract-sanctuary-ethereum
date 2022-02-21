/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

struct Manager
{
  string Fullname;
  string contactNo;
  address manager; 
}
struct Incharge
{
    
    string firstname;
    string lastname;
    string UC_Name;
    string Email;
    string contactNo;
    string CNIC;
    uint donatedbloodNo;
    uint requestbloodNo;
    address incharg;
    
}
struct DonateBlood
{
  string CNIC;
  string firstname;
  string lastname;
  string bloodtype;
  string adress;
  string contact_No;
  uint NoOfBottles;
  string dateOfDonation;
  uint id;


}
struct RequestBlood
{
  string CNIC;
  string firstname;
  string lastname;
  // string email;
  string bloodtype;
  string disease;
  string adress;
  string contact_No;
  string status;
  uint NoOfBottles;
//   string dateOfrequest;
  string dateOfapprove;
  uint id;

}
contract Donation
{
   Manager public M1; //getter function of Manager

   Incharge[] public incharges;  //getter function of Incharge
   mapping(string=>Incharge) public key; //mapping CNIC(I) to Incharge data 
   mapping(address=>Incharge) public  _whiteList;
   mapping(address => bool)  _addressExist;
   
   RequestBlood[] public requests;  //getter function of RequestBlood
   mapping (string=>RequestBlood) public requesterid;//mapping CNIC(RB) to Requests blood data
   mapping (address=>mapping(uint=>RequestBlood)) public Inchargeadr_requester;//nested mapping Incharge adress to Blood requests(Accepted)

   DonateBlood[] public donates;
   mapping (string=>DonateBlood) public donerid;
   mapping (address=>mapping(uint=>DonateBlood)) public Inchargeradr_doner;//nested mapping Incharge_adress donate Blood

  address payable wallet=payable(0x62144eB873f43F24B93903B244017557c24A3C86);

  
   
   constructor ()
   {
     M1.manager=msg.sender;
     M1.Fullname="admin";
     M1.contactNo="000000000";
   }
  function  donation()external payable
  {
   wallet.transfer(msg.value);
  }

   modifier onlyOwner(){
     require(msg.sender == M1.manager, "Not manager");
     _;
   }


   //update Manager user_name and password
   function updateManager(string memory _fullname, string memory _contactNo) public onlyOwner 
   {
        // require(msg.sender==M1.manager);
        // Manager memory M2 = M1;
        M1.Fullname = _fullname;
        M1.contactNo=_contactNo;
    }


    //NEW Incharge Register
    function NewIncharge(address[] memory whiteAddress,string memory _firstname,string memory _lastname,string memory _UC_Name,string memory _Email,string memory _contactNo,string memory _CNIC) public onlyOwner
    {
      // address[] memory whiteAddress; 
      //  string memory adr=_incharg[i]; 
    // address[] memory whiteAddress

    //   address[] memory _addresses;
    //   for (uint256 i = 0; i < ids.length; i++) {
    //   string memory id = ids[i];
    //   require(_idToAddress[id] != address(0), 'Missing address');
    //   address payable _address = payable(_addresses[i]);
    //   _addresses[i] = _address;
    // }
    //  string memory adr=_inc harg[i];
    // address payable _address=payable(whiteAddress[i]);
    // whiteAddress[i]=_address;
    
       for (uint i = 0; i < whiteAddress.length; i++)
       {
       require(!_addressExist[whiteAddress[i]],"Incharge already Exist");
       key[_CNIC]=Incharge(_firstname,_lastname,_UC_Name,_Email,_contactNo ,_CNIC,0,0,whiteAddress[i]);
       _whiteList[whiteAddress[i]]=Incharge(_firstname,_lastname,_UC_Name,_Email,_contactNo ,_CNIC,0,0,whiteAddress[i]);
       Incharge memory incharge; 
       incharge.firstname=_firstname;
       incharge.lastname=_lastname;
       incharge.UC_Name=_UC_Name;
       incharge.Email=_Email;
       incharge.contactNo=_contactNo;
       incharge.CNIC=_CNIC;
       incharge.donatedbloodNo=0;
       incharge.requestbloodNo=0;
       incharge.incharg=whiteAddress[i];
       incharges.push(incharge);
       _addressExist[whiteAddress[i]]=true;
       }
    }

    //request blood function
    function RequestForBlood(string memory _CNIC,string memory _firstname,string memory _lastname,string memory _bloodtype,string memory _disease,string memory _adress,string memory _contact_No, string memory _status,uint _NoOfBottles,string memory _dateOfapprove )public
    {
      require( _addressExist[msg.sender]=true);
      uint count;
      count=requests.length;
      requesterid[_CNIC]=RequestBlood(_CNIC,_firstname, _lastname,_bloodtype,_disease,_adress,_contact_No, _status,_NoOfBottles,_dateOfapprove,count+1);
      Inchargeadr_requester[msg.sender][count+1]=RequestBlood(_CNIC,_firstname, _lastname,_bloodtype,_disease,_adress,_contact_No, _status,_NoOfBottles,_dateOfapprove,count+1);
      RequestBlood memory request;
      request.CNIC=_CNIC;
      request.firstname=_firstname;
      request.lastname=_lastname;
      // request.email=_email;
      request.bloodtype=_bloodtype;
      request.disease=_disease;
      request.adress=_adress;
      request.contact_No=_contact_No;
      request.status=_status;
      request.NoOfBottles=_NoOfBottles;
    //   request.dateOfrequest=_d ateOfrequest;
      request.dateOfapprove=_dateOfapprove;
      _whiteList[msg.sender].requestbloodNo=_whiteList[msg.sender].requestbloodNo+_NoOfBottles;
      request.id=count+1;
      requests.push(request);

    }

   //Donate blood
   function Donateblood(string memory _CNIC,string memory _firstname,string memory _lastname,string memory _bloodtype,string memory _adress,string memory _contact_No,uint  _NoOfBottles,string memory _dateOfDonation)public
   {
     require( _addressExist[msg.sender]=true);
     uint count;
     count=donates.length;
     donerid[_CNIC]=DonateBlood(_CNIC,_firstname, _lastname,_bloodtype,_adress,_contact_No, _NoOfBottles,_dateOfDonation,count+1);
     Inchargeradr_doner[msg.sender][count+1]=DonateBlood(_CNIC,_firstname, _lastname,_bloodtype,_adress,_contact_No, _NoOfBottles,_dateOfDonation,count+1);
      DonateBlood memory donate;
      donate.CNIC=_CNIC;
      donate.firstname=_firstname;
      donate.lastname=_lastname;
      donate.bloodtype=_bloodtype;
      donate.adress=_adress;
      donate.contact_No=_contact_No;
      donate.NoOfBottles=_NoOfBottles;
      donate.dateOfDonation=_dateOfDonation;
      _whiteList[msg.sender].donatedbloodNo=_whiteList[msg.sender].donatedbloodNo+_NoOfBottles;
      donate.id=count+1;
      donates.push(donate);
   }


}
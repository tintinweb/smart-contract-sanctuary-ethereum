// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "./Ticketting.sol";

contract Factory {
    address payable factoryOwner;
    struct TicketCard {
     address blockaddress;
     address payable deployerAddress;
     string agencies;
     string banner;
     string title;
     bool   status;
    }
   TicketCard []  deployedTicket;
  mapping(address => TicketCard[]) mydeployedTickets;

//    constructor(){
//        factoryOwner =   payable(msg.sender);
//    }
  

  modifier restricted(uint index){
         TicketCard storage Tc = deployedTicket[index];
      require(Tc.deployerAddress == msg.sender,"unAuthorized");
    _;
} 

   function initialize(address add) public{
     factoryOwner =   payable(add);
   }

    function deployEventContract(string memory _banner, string memory _title, string memory _agency ) public {
        address newTicket = address(new Ticketting(payable(msg.sender), factoryOwner));
     TicketCard memory tc;
      tc.blockaddress = newTicket;
       tc.deployerAddress = payable(msg.sender);
       tc.agencies = _agency;
       tc.banner = _banner;
       tc.title = _title;
       tc.status = false;

    deployedTicket.push(tc);

    // saving individual deployed tickets
    mydeployedTickets[msg.sender].push(tc);
      
    }

    function updateEventStatus (uint index,bool status) public restricted(index) {
     TicketCard storage Tc = deployedTicket[index];
       Tc.status = status;
    }

   function getTickets () public view  returns(TicketCard [] memory) {
      return deployedTicket;
         
        
      
    }
function getMyDeployedTickets (address account) public view  returns(TicketCard [] memory) {
    return mydeployedTickets[account];
        
      
    }
   



}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Ticketting {
    address payable public  manager;
    address payable factoryOwner;
    uint public TicketSold =0;
    struct Event{
        string title;
        string  description;
        string   addressLocation;
        string   postcode;
        string   banner;
        uint     price;
        uint     capacity   ; 
        bool     expired;
        uint     eventDate;
        string   color;
        string   checkInTime;
        string   opening;
        string   showType;
    }

   

    struct Staff{
      string fullName;
      string sex;
      uint rate;
      address payable id;
      bool paid;
      bool exist;

    }

    struct Participants{
        address userAddress;
        string name;
        uint timestamp;
        string email;
        bool  approved;
    }
    mapping(address => Event) events;
    mapping(address=>Participants[]) individualPurchase;
    Staff[] staffs;
    Participants [] participant;


    constructor(address payable deployer, address payable _factoryOwner){
     manager = deployer;
     factoryOwner= _factoryOwner;
    }
    modifier restricted(){
    require(msg.sender == manager,"unAuthorized");
    _;
}

 modifier validateStaffDuplicate(){
    require(msg.sender == manager,"unAuthorized");
    _;
}

    function createEvent( 
     string memory _title,
     uint _price,
     string memory _description,
     string memory _addressLocation,
     string memory _banner,
     uint _capacity,
     uint week,
     string memory _checkinTime,
     string memory _opening
     ) public restricted {
     
      Event storage _newEvent = events[msg.sender];
     
      _newEvent.title = _title;
      _newEvent.description = _description;
      _newEvent.addressLocation = _addressLocation;
      _newEvent.banner = _banner;
      _newEvent.capacity = _capacity;
      _newEvent.price = _price;
      _newEvent.expired = false;
      _newEvent.eventDate = block.timestamp  + (week * 1 weeks);
      _newEvent.checkInTime = _checkinTime;
      _newEvent.opening = _opening;
    }

    function purchase (string memory name,string memory email) public payable{
      
      require((events[manager].capacity == TicketSold) ,"Full capacity attained" );
      // require(!((events[manager].eventDate - block.timestamp) <= 0) ,"Ticket sale has Expired" );
      //require( msg.value != events[manager].price, "Check your Balance");

     //disburse funds
     uint factoryShare = (msg.value *10) / 100;
     uint remainingShare = msg.value - factoryShare;
     factoryOwner.transfer(factoryShare);
     manager.transfer(remainingShare);

     //register partipant
     Participants storage newParticipant  = participant.push();
     newParticipant.name= name;
     newParticipant.userAddress= msg.sender;
     newParticipant.email = email;
     newParticipant.approved = false;
     newParticipant.timestamp = block.timestamp;

    
      TicketSold++ ;

      //saving individual ticket purchase using participant address
      individualPurchase[msg.sender].push(newParticipant);
    }

   


    function validateTickets(address participantAddress ,uint participantIndex, uint staffIndex) public{
        require(staffs[staffIndex].exist, "Not Authorized: Not a Staff");
      
        require(!individualPurchase[participantAddress][participantIndex].approved,"Ticket used");
             
        individualPurchase[participantAddress][participantIndex].approved = true;


    }

    function getMyPurchasedTickets (address add) public view returns (Participants[] memory){
     return individualPurchase[add];
    
    }

    function registerStaff(string memory _fullName, address payable _address, string memory _sex, uint rate) public restricted {
       for(uint i=0;i< staffs.length; i++){
       require( staffs[i].id != _address,"staff address duplicate");
       
     }

      Staff storage staff = staffs.push();
      staff.fullName = _fullName;
      staff.id = _address;
      staff.sex = _sex;
      staff.rate = rate;
      staff.exist = true;
      staff.paid =false;
    }

    function deleteStaff(uint index) public  restricted{
     delete staffs[index];
     staffs[index] = staffs[staffs.length-1];
     staffs.pop();
      
    }

    function payRegisteredStaffs() public payable restricted{
     uint share = msg.value/ staffs.length;
     for(uint i=0;i< staffs.length; i++){
        staffs[i].id.transfer(share);
        staffs[i].paid =true;
     }
    }
   

     function managerSummary() public view  returns (Event memory, uint, Staff[]memory, address, Participants[]memory, uint myBalance ){
     return(
         events[manager],
         TicketSold,
         staffs,
         manager,
         participant,
         manager.balance
     );
    }

    function eventSummary() public view returns(Event memory, uint, Staff[]memory, address ){
     return(
         events[manager],
         TicketSold,
         staffs,
         manager
     );
    }
}
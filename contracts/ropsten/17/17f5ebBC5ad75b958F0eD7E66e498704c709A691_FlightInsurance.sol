//SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

contract FlightInsurance{

    enum FlightStatus{Ontime, Delayed}

    struct FlightDetail{
        string passengerName;
        address passengerAddress;
        uint premiumAmount;
        uint insuranceAmount;
        bool amountDepositedByCompany;
        bool insuranceClaimed;
        uint startTime;
        FlightStatus flightStatus;


    }

      address payable public contractAddress;
      address public companyAddress = 0x7cD26ACBBB9296e1BC031a65B69B12c5F87ccB9C;
      address payable passengerAddress;
      uint public ticketId;

    mapping (uint => FlightDetail) public FlightRegister;

    modifier bothPassengerOrCompany(uint _id){
        passengerAddress= payable(FlightRegister[_id].passengerAddress);
        require(msg.sender == companyAddress   || msg.sender == passengerAddress, "neither company nor Passenger address");
        _;
    }

     constructor (){
        contractAddress = payable (msg.sender);

    }
       function CompanyDepositAmount() public payable {
          ticketId++;
         require(msg.value == 0.1 ether, "not exact amount");
         require(companyAddress == msg.sender, "wrong insuranse company");
          FlightDetail memory F ;
          F.insuranceAmount = msg.value;
          F.amountDepositedByCompany = true; 
        FlightRegister[ticketId] = F;
        

     }

    function flightInsurance(string memory _name, uint _id) public payable
     {
          require(msg.sender !=  companyAddress,"company not Allowed");
         require(FlightRegister[_id].amountDepositedByCompany == true, "company hasn't deposited yet");
          
        FlightRegister[_id].passengerName = _name;
        FlightRegister[_id].passengerAddress = msg.sender;
        FlightRegister[_id].premiumAmount = msg.value;
        FlightRegister[_id].startTime = block.timestamp;
     }

     function journeyStatus(uint _id) public  bothPassengerOrCompany(_id){
        uint journeyStartTime = FlightRegister[_id].startTime;
        uint currentTime = block.timestamp;
       uint journeyEndTime =  journeyStartTime + 10 seconds; //we can increase the time.
       if (currentTime < journeyEndTime){
           FlightRegister[_id].flightStatus = FlightStatus.Ontime;
           }
           else if (currentTime > journeyEndTime){
                FlightRegister[_id].flightStatus = FlightStatus.Delayed;
           }
     }

  
     function claimInsurance(uint _id) public payable {
        require(FlightRegister[_id].flightStatus == FlightStatus.Delayed,"no claim applicable");
        require(FlightRegister[_id].passengerAddress == msg.sender,"not Correct Passenger");
        require(FlightRegister[_id].insuranceClaimed == false,"already claimed");
        uint userAmount =  FlightRegister[ticketId].premiumAmount ;
        uint companyAmount = FlightRegister[ticketId].insuranceAmount;
        uint totalAmount = userAmount + companyAmount;
        payable(msg.sender).transfer(totalAmount);
        
        FlightRegister[_id].insuranceClaimed = true;
       

     }


     function contractBalance() public view returns(uint){
         return address(this).balance;
     }

}
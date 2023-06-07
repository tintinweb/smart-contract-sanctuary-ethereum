// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
//import 'https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol';
contract DonationManagement {
  
  
  /*From https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol*/
      int constant OFFSET19700101 = 2440588;
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
/*End*/
  
  
    string public nameOrThingToDonate;
    address payable public  donationRecipientAdress;
    uint public etherGoal;
    uint private weiToEthMultiplikator=10e17; // Or finney or...
    Date public dueDate;

    bool public areDonationsRunning;
    bool public returnDonations;
    

    mapping(address=> uint) public donations;//to refund correct ammount if goal not reached

    struct Date{
        uint8 day;
        uint8 month;
        uint16 year;
        uint unixTimestamp;}


    event DonationEvent(address indexed donatorAddress,string message,uint256 donationAmmount,uint256 currentDonationBalance);
    event RefundEvent(address indexed donatorAddress,uint donationAmmount);
    event Log(string message,uint balance);
    //event DonationEventWithMessage(address indexed donatorAddress,string message,uint donationAmmount,uint donationSum);
    modifier OnlyDonationRecipient{
      require(msg.sender == donationRecipientAdress, "Only the person with Access to the DonationrecipientAdress can withdraw");
        _;     // execute the rest of the code. Needed? satisfied while calling this function,
     
    }
    modifier isDonationRunning(){
        require(areDonationsRunning,"No Donations possible any more");
        _;
    }

    constructor(string memory nameOrThingToDonateParam,uint neededEtherAmmount,uint8 day,uint8 month,uint16 year)public {
        nameOrThingToDonate=nameOrThingToDonateParam;
        donationRecipientAdress = payable(msg.sender);//Contract Creator
        dueDate=Date(day,month,year,convertTo_UNIX_WithValidation(day,month,year));
        etherGoal=neededEtherAmmount;
        areDonationsRunning=true;
        returnDonations=false;
    }
    //payable Address vs Adressaddress: Holds a 20 byte value (size of an Ethereum address). address payable: Same as address, but with the additional members transfer and send.
    function donate(string memory donationMessage) public payable isDonationRunning{//Can Someone write links as message
      if(block.timestamp<dueDate.unixTimestamp){
                if((address(this).balance) > (etherGoal * weiToEthMultiplikator)){//reached Goal
                    uint refund=address(this).balance-etherGoal * weiToEthMultiplikator;
                    payable(msg.sender).transfer(refund);//Transfer back the ammouint which is paid to much
                    emit DonationEvent(msg.sender,donationMessage,msg.value,msg.value-refund);
                    areDonationsRunning=false;returnDonations=false;
                    payable(donationRecipientAdress).transfer((address(this).balance));//Send all Ether to recipient Reached Goal!!!
                }else{// EtherGoal not reached
                    emit DonationEvent(msg.sender,donationMessage,msg.value,address(this).balance);
                     donations[msg.sender]+=msg.value;
                }
        }else{//TIME IS UP
            if((address(this).balance) >= etherGoal){
                payable(donationRecipientAdress).transfer(etherGoal*weiToEthMultiplikator);//Finished Goal reached
                areDonationsRunning=false;returnDonations=false;
                payable(msg.sender).transfer(address(this).balance);//remaing Blance whihc is paid to much
            }else{//Goal not Reached
                areDonationsRunning=false;
                returnDonations=true;//Evryone can now Withdraw their money
            }
        }
    }
    function withdraw() public {//Only possible if Goal not reached in certain Time
        require(returnDonations,"There is enough time to reach the goal. Withdrawing not possible");
            uint donatedAmmount=donations[msg.sender];
            if(donatedAmmount<=address(this).balance){
                payable(msg.sender).transfer(donatedAmmount);//Refund Ether
                emit RefundEvent(msg.sender,donatedAmmount);
            }else{
                emit Log("Error when paying back Ammount ",donatedAmmount);
            }
        
    }

    function getCurrentBalance() public view returns (uint){
        return address(this).balance;
    }

    function convertTo_UNIX_WithValidation(uint8 day,uint8 month, uint16 year)private  returns(uint){
     require(isValidDate(year,month,day),"Not Valid Date");
    require(timestampFromDate(year,month,day) > block.timestamp,"Date is in the past");
    return  timestampFromDate(year,month,day);
    }

/*Copied from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol*/

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }


       function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

       function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    //

     function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

     function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
      
}
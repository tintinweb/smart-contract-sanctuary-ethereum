// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract RationVitranKendra {    
    address public owner;
    uint public totalPulses=10000;
    uint public totalRice=10000;
    uint public totalWheat=10000;
    uint8 public pulsesDistribute=5;
    uint8 public riceDistribute=5;
    uint8 public wheatDistribute=5;
    uint public nextDueTimePeriod=20;// 30 days =2592000 sec.

    struct itemsPrice{
        uint pulsesPrice;
        uint ricePrice;
        uint wheatPrice;
    }

    struct PulsesStr {
        uint256 time;
        uint256 nextDue;
        uint userPulses;
        // uint price;
    }

    struct RiceStr {
        uint256 time;
        uint256 nextDue;
        uint userRice;
    }
    
    struct WheatStr {
        uint256 time;
        uint256 nextDue;
        uint userWheat;
    }

    struct User{
        address userAddress;
        bool isActive; //status of user
        PulsesStr pulsesInfo;
        RiceStr riceInfo;
        WheatStr wheatInfo;
    }

    struct Charity{
        string charityName;
        address charityAddress;
        uint8 charityShare;
        bool isActive;
        uint time;
        uint nextDueTime;
    }
    
    mapping(address => User) public userMap;
    mapping(address => Charity) public charityMap;
    enum rawItems{pulses,rice,wheat}
    itemsPrice public ip;
    constructor() {
        owner = msg.sender;
        updateItemsPrice(20000000000000,15000000000000,10000000000000);
    }
    event registerUserEvent(address adsOfUser,bool isActive);
    event withdrawEvent(address adsOfUser,bool hasTaken,string item);
    event userRemovingEvent(address adsOfUser,bool isActive);
    event updateItemsPriceEvent(uint pulsesPrice,uint ricePrice,uint wheatPrice,string msg);
   
    function registerUser(address adsOfUser) public onlyOwner {
        require(userMap[adsOfUser].isActive==false,"RationVitranKendra: user is already registered");
        PulsesStr memory tempPulses = PulsesStr(0, 0,0);
        RiceStr memory tempRice = RiceStr(0, 0,0);
        WheatStr memory tempWheat = WheatStr(0, 0,0);
        User memory tempUserStr = User(adsOfUser, true, tempPulses,tempRice,tempWheat);
        userMap[adsOfUser] = tempUserStr;
        emit registerUserEvent(adsOfUser,true);
    }

    function withDrawRation(rawItems item) public payable {
        require(userMap[msg.sender].isActive, "RationVitranKendra: not registered");
        if(item==rawItems.pulses){
            require(msg.value>ip.pulsesPrice,"RationVitranKendra: provide required amount for pulses");
            _withDrawPulses();
            emit withdrawEvent(msg.sender,true,"pulses");

        }else if(item==rawItems.rice){
            require(msg.value>ip.ricePrice,"RationVitranKendra: provide required amount for rice");
            _withDrawRice();
            emit withdrawEvent(msg.sender,true,"rice");

        }else if(item==rawItems.wheat){
            require(msg.value>ip.pulsesPrice,"RationVitranKendra: provide required amount for wheat");
            _withDrawWheat();
            emit withdrawEvent(msg.sender,true,"wheat");
        }
    }
        
    function _withDrawPulses() internal {
         require(
            block.timestamp > userMap[msg.sender].pulsesInfo.nextDue,
            "RationVitranKendra: early pulses withdraw request issue"
        );
        require(totalPulses>=5,"RationVitranKendra: insufficient pulses ");
        userMap[msg.sender].pulsesInfo.userPulses+=pulsesDistribute;
        totalPulses-=pulsesDistribute;
        // 30 days in second=nextDueTimePeriod
        userMap[msg.sender].pulsesInfo.nextDue = block.timestamp + nextDueTimePeriod;
        userMap[msg.sender].pulsesInfo.time = block.timestamp;
    }

    function _withDrawRice() internal {
         require(
            block.timestamp > userMap[msg.sender].riceInfo.nextDue,
            "RationVitranKendra: early rice withdraw request issue"
        );
        require(totalRice>=5,"RationVitranKendra: insufficient rice ");
        userMap[msg.sender].riceInfo.userRice+=riceDistribute;
        totalRice-=riceDistribute;
        // 30 days in second=nextDueTimePeriod
        userMap[msg.sender].riceInfo.nextDue = block.timestamp + nextDueTimePeriod;
        userMap[msg.sender].riceInfo.time = block.timestamp;
    }

    function _withDrawWheat() internal {
         require(
            block.timestamp > userMap[msg.sender].wheatInfo.nextDue,
            "RationVitranKendra: early wheat withdraw request issue"
        );
        require(totalWheat>=5,"RationVitranKendra: insufficient wheat ");
        userMap[msg.sender].wheatInfo.userWheat+=wheatDistribute;
        totalWheat-=wheatDistribute;
        // 30 days in second=nextDueTimePeriod
        userMap[msg.sender].wheatInfo.nextDue = block.timestamp + nextDueTimePeriod;
        userMap[msg.sender].wheatInfo.time = block.timestamp;
    }

    function removeUser(address toRemoveUser) public onlyOwner {
        require(userMap[toRemoveUser].isActive==true,"RationVitranKendra: user is not in registered list");
        userMap[toRemoveUser].isActive=false;
        emit userRemovingEvent(toRemoveUser,false);
       
    }

    function charityRegistration(string memory _charityName,address _charityAddress,uint8 _charityShare) public onlyOwner{
        require(charityMap[_charityAddress].isActive==false,"RationVitranKendra: charity already registered");
        charityMap[_charityAddress].charityName=_charityName;
        charityMap[_charityAddress].charityAddress=_charityAddress;
        charityMap[_charityAddress].charityShare=_charityShare;
        charityMap[_charityAddress].isActive=true;
        charityMap[_charityAddress].time=block.timestamp;
        charityMap[_charityAddress].nextDueTime=block.timestamp;
    }

    function removeCharity(address toRemoveCharity) public onlyOwner{
        require(charityMap[toRemoveCharity].isActive==true,"RationVitranKendra: already inactive charity");
        charityMap[toRemoveCharity].isActive=false;

    } 

    function withDrawFund() public {
        require(charityMap[msg.sender].isActive==true,"RationVitranKendra: not Registered charity");
        require(block.timestamp>charityMap[msg.sender].nextDueTime,"RationVitranKendra: early withdraw request issue");
        require(address(this).balance>0,"RationVitranKendra: does not have fund");
        address payable charityAddress=payable(msg.sender);
        charityAddress.transfer((address(this).balance*charityMap[msg.sender].charityShare)/100);
        charityMap[msg.sender].time=block.timestamp;
        charityMap[msg.sender].nextDueTime=block.timestamp+nextDueTimePeriod;
    }

    function refilling(uint _pulses,uint _rice,uint _wheat) public onlyOwner{
        totalPulses+=_pulses;
        totalRice+=_rice;
        totalWheat+=_wheat;
    }

    function updateItemsQuantity(uint8 _pulsesDistribute,uint8 _riceDistribute,uint8 _wheatDistribute) public onlyOwner{
        pulsesDistribute=_pulsesDistribute;
        riceDistribute=_riceDistribute;
        wheatDistribute=_wheatDistribute;
    }

    function getContractBal() public view returns(uint){
        return address(this).balance;
    }

    function changeDistributionTime(uint newtime)public onlyOwner{
        nextDueTimePeriod=newtime;
    }

    function updateItemsPrice(uint _pulsesPrice,uint _ricePrice,uint _wheatPrice) public onlyOwner{
        ip.pulsesPrice=_pulsesPrice;
        ip.ricePrice=_ricePrice;
        ip.wheatPrice=_wheatPrice;
        emit updateItemsPriceEvent(_pulsesPrice,_ricePrice,_wheatPrice,"items price is updated");

    }
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

}
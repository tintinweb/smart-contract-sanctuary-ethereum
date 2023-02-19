/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT
//need to re deploy
pragma solidity ^0.8.0;

contract Payment {

    address owner;
    uint ownerBalance;
    uint nembweofslotfree=12;  //اضافة ضرورية
    uint8 cam1=4;
    uint8 cam2=4;
    uint8 cam3=4;



    
    bool[4]  c1 = [true, true, true, true];
    bool[4]  c2 = [true, true, true, true];
    bool[4]  c3 = [true, true, true, true];

     string[4]  carplateNumberInPart1;
     string[4]  carplateNumberInPart2;
     string[4] carplateNumberInPart3;
     
 

    constructor() {
        owner = msg.sender;
    }

    // Add yourself as a Renter
    struct SlotTenant  {
        address payable walletAddress;
        string CarPlate;
        bool canRent;
        bool active;
        uint balance;
        uint due;
        uint start;
        uint end;
        uint camera;
        uint index;
       
    }
 
    mapping (address => SlotTenant ) public SlotTenants;

    function numberofslotfree() public view returns(uint){
        return nembweofslotfree;
    }
    
    function cam11() public view returns(uint){
        return cam1;
    }
    function cam22() public view returns(uint){
        return cam2;
    }
    function cam33() public view returns(uint){
        return cam3;
    }

    function carplateNumberInPartShow1(uint8 i) public view returns( string memory){
        return carplateNumberInPart1[i];
    }
    function carplateNumberInPartShow2(uint8 i) public view returns( string memory){
        return carplateNumberInPart2[i];
    }
    function carplateNumberInPartShow3(uint8 i) public view returns( string memory){
        return carplateNumberInPart3[i];
    }

    function addSlotTenant(address payable walletAddress, string memory CarPlate, bool canRent, bool active, uint balance, uint due, uint start, uint end,uint camera,uint index) public {
        SlotTenants[walletAddress] = SlotTenant (walletAddress, CarPlate, canRent, active, balance, due, start, end, camera,index);
    }

    modifier isSlotTenant(address walletAddress) {
        require(msg.sender == walletAddress, "You can only manage your account");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not allowed to access this");
        _;
    }


    // Checkout bike
    function checkOutSlot(address walletAddress,uint camera) public isSlotTenant(walletAddress) {
        require(SlotTenants[walletAddress].due == 0, "You have a pending balance.");
        require(SlotTenants[walletAddress].canRent == true, "You cannot rent at this time.");
        require(nembweofslotfree > 0, "there are no free slot");

        SlotTenants[walletAddress].camera=camera;
        nembweofslotfree-=1;
        if(camera==1){
            require(camera==1 && cam1>0,"there are no free slot in the part 1");
            cam1-=1;
            calculateindex1(walletAddress);
            string memory a= SlotTenants[walletAddress].CarPlate;
            carplateNumberInPart1[SlotTenants[walletAddress].index]=a;
         //   c1[3-cam1]=SlotTenants[walletAddress].CarPlate;
        }
        if(camera==2){
            require(camera==2 && cam2>0,"there are no free slot in the part 2");
            cam2-=1;
            calculateindex2(walletAddress);
            string memory a= SlotTenants[walletAddress].CarPlate;
            carplateNumberInPart2[SlotTenants[walletAddress].index]=a;
         //   c2[3-cam2]=SlotTenants[walletAddress].CarPlate;
        }
        if(camera==3){
            require(camera==3 && cam3>0,"there are no free slot in the part 3");
            cam3-=1;
            calculateindex3(walletAddress);
            string memory a= SlotTenants[walletAddress].CarPlate;
            carplateNumberInPart3[SlotTenants[walletAddress].index]=a;
         //   c3[3-cam3]=SlotTenants[walletAddress].CarPlate;
        }
        SlotTenants[walletAddress].active = true;
        SlotTenants[walletAddress].start = block.timestamp;
        SlotTenants[walletAddress].canRent = false;
    }

    function calculateindex1(address walletAddress) internal{
                for (uint i = 0; i < 4; i++) {
                    if(c1[i]==true){
                    c1[i]=false;
                    SlotTenants[walletAddress].index=i;
                    break;} }
    }
    function calculateindex2(address walletAddress) internal{
                for (uint i = 0; i < 4; i++) {
                    if(c2[i]==true){
                    c2[i]=false;
                    SlotTenants[walletAddress].index=i;
                    break;} }
    }
    function calculateindex3(address walletAddress) internal{
                for (uint i = 0; i < 4; i++) {
                    if(c3[i]==true){
                    c3[i]=false;
                    SlotTenants[walletAddress].index=i;
                    break;} }
    }


    // Check in a bike
    function checkInSlot(address walletAddress,uint camera) public isSlotTenant(walletAddress) {
        require(SlotTenants[walletAddress].active == true, "Please check out a bike first.");
        require(SlotTenants[walletAddress].camera==camera, "please click Chick In that you chooesed Check Out");
        SlotTenants[walletAddress].active = false;
        SlotTenants[walletAddress].end = block.timestamp;
        setDue(walletAddress);
        SlotTenants[walletAddress].camera==0;            //نتبه هي اضافة ضرورية
        nembweofslotfree+=1;
        if(camera==1){
            cam1+=1;
            carplateNumberInPart1[SlotTenants[walletAddress].index]='';
            c1[SlotTenants[walletAddress].index]=true;
            SlotTenants[walletAddress].index=4;
        }
        if(camera==2){
            cam2+=1;
            carplateNumberInPart2[SlotTenants[walletAddress].index]='';
            c2[SlotTenants[walletAddress].index]=true;
            SlotTenants[walletAddress].index=4;
        }
        if(camera==3){
            cam3+=1;
            carplateNumberInPart3[SlotTenants[walletAddress].index]='';
            c3[SlotTenants[walletAddress].index]=true;
            SlotTenants[walletAddress].index=4;
        }
    }

    // Get total duration of bike use
    function SlotTenantTimespan(uint start, uint end) internal pure returns(uint) {
        return end - start;
    }

    function getTotalDuration(address walletAddress) public isSlotTenant(walletAddress) view returns(uint) {
        if (SlotTenants[walletAddress].start == 0 || SlotTenants[walletAddress].end == 0) {
            return 0;
        } else {
            uint timespan = SlotTenantTimespan(SlotTenants[walletAddress].start, SlotTenants[walletAddress].end);
            uint timespanInMinutes = timespan / 60;
            return timespanInMinutes;
        }
    }

    // Get Contract balance
    function balanceOf() view public onlyOwner() returns(uint) {
        return address(this).balance;
    }

    function isOwner() view public returns(bool) {
        return owner == msg.sender;
    }

    function getOwnerBalance() view public onlyOwner() returns(uint) {
        return ownerBalance;
    }

    function withdrawOwnerBalance() payable public {
        payable(owner).transfer(ownerBalance);
                ownerBalance = 0;

    }

    // Get Renter's balance
    function balanceOfSlotTenant(address walletAddress) public isSlotTenant(walletAddress) view returns(uint) {
        return SlotTenants[walletAddress].balance;
    }

    // Set Due amount
    function setDue(address walletAddress) internal {
        uint timespanMinutes = getTotalDuration(walletAddress);
        uint fiveMinuteIncrements = timespanMinutes / 10;  //نتبه
        SlotTenants[walletAddress].due = fiveMinuteIncrements * 5000000000000000;
    }

    function canRentSlot(address walletAddress) public isSlotTenant(walletAddress) view returns(bool) {
        return SlotTenants[walletAddress].canRent;
    }

    // Deposit
    function deposit(address walletAddress) isSlotTenant(walletAddress) payable public {
        SlotTenants[walletAddress].balance += msg.value;
    }

    // Make Payment
    function makePayment(address walletAddress, uint amount) public isSlotTenant(walletAddress) {
        require(SlotTenants[walletAddress].due > 0, "You do not have anything due at this time.");
        require(SlotTenants[walletAddress].balance > amount, "You do not have enough funds to cover payment. Please make a deposit.");
        require(SlotTenants[walletAddress].due==amount,"please write the amount right");

        SlotTenants[walletAddress].balance -= amount;
        ownerBalance += amount;
        SlotTenants[walletAddress].canRent = true;
        SlotTenants[walletAddress].due = 0;
        SlotTenants[walletAddress].start = 0;
        SlotTenants[walletAddress].end = 0;
    }

    function getDue(address walletAddress) public isSlotTenant(walletAddress) view returns(uint) {
        return SlotTenants[walletAddress].due;
    }

    function getSlotTenant(address walletAddress) public isSlotTenant(walletAddress) view returns(string memory CarPlate, bool canRent, bool active) {
        CarPlate = SlotTenants[walletAddress].CarPlate;
        canRent = SlotTenants[walletAddress].canRent;
        active = SlotTenants[walletAddress].active;
    }

    function SlotTenantExists(address walletAddress) public isSlotTenant(walletAddress) view returns(bool) {
        if (SlotTenants[walletAddress].walletAddress != address(0)) {
            return true;
        }
        return false;
    }


}
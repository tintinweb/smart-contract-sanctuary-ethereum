/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Payment {

    address owner;
    uint ownerBalance;
    uint nembweofslotfree=12;  //اضافة ضرورية
    uint cam1=4;
    uint cam2=4;
    uint cam3=4;

    string[4] c1;
    string[4] c2;
    string[4] c3;

    


 

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
    function c11() public view returns(string[4] memory){
        return c1;
    }
    function c22() public view returns(string[4] memory){
        return c2;
    }
    function c33() public view returns(string[4] memory){
        return c3;
    }

    function addSlotTenant(address payable walletAddress, string memory CarPlate, bool canRent, bool active, uint balance, uint due, uint start, uint end,uint camera) public {
        SlotTenants[walletAddress] = SlotTenant (walletAddress, CarPlate, canRent, active, balance, due, start, end, camera);
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
            c1[3-cam1]=SlotTenants[walletAddress].CarPlate;
        }
        if(camera==2){
            require(camera==2 && cam2>0,"there are no free slot in the part 2");
            cam2-=1;
            c2[3-cam2]=SlotTenants[walletAddress].CarPlate;
        }
        if(camera==3){
            require(camera==3 && cam3>0,"there are no free slot in the part 3");
            cam3-=1;
            c3[3-cam3]=SlotTenants[walletAddress].CarPlate;
        }
        SlotTenants[walletAddress].active = true;
        SlotTenants[walletAddress].start = block.timestamp;
        SlotTenants[walletAddress].canRent = false;
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
        }
        if(camera==2){
            cam2+=1;
        }
        if(camera==3){
            cam3+=1;
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
        uint fiveMinuteIncrements = timespanMinutes / 5;
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
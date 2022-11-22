/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


error notOwner();
error notBuyer();
error noAvailableStock(
    uint256 pinoyTasty, 
    uint256 pandesal,
    uint256 cheeseBread,
    uint256 spanishBread,
    uint256 mamon,
    uint256 ensaymada,
    uint256 pianonoRoll,
    uint256 eggPie
    );
error storeStillClosed(uint closeTime);
error storeIsOpen(uint openTime);
error accessError(bool bakeryAccess);
error loggedOutError(string loggedOutMessage);
error limitError(string limitErrorMsg);


contract BakeShop {
    uint256 pinoyTasty = 20;
    uint256 pandesal = 100;
    uint256 cheeseBread = 50;
    uint256 spanishBread = 50;
    uint256 mamon = 50;
    uint256 ensaymada = 30;
    uint256 pianonoRoll = 50;
    uint256 eggPie = 40;
    uint time;
    bool bakeryAccess;
    string loggedOutMessage = "You need to log in before buying.";
    string limitErrorMsg = "Can't restock. Stock is still full.";
    uint timeStamp;
  

    mapping (address => bool) whiteListedAddresses; 
    mapping (address => bool) accessValid;
 

    address owner;
    constructor() {
        owner = msg.sender;
        whiteListedAddresses[msg.sender] = true;
    }

    modifier onlyOwner {
        if(msg.sender != owner) {
            revert notOwner();
        }
        _;
    }
    modifier onlyBuyer {
        if(msg.sender == owner){
            revert notBuyer();
        }
        _;
    }
    modifier outOfStock {
        if(
            pinoyTasty == 0 || 
            pandesal == 0 || 
            cheeseBread == 0 ||
            spanishBread == 0 ||
            mamon == 0 ||
            ensaymada == 0 ||
            pianonoRoll == 0 ||
            eggPie == 0
            ) {
            revert noAvailableStock(
                pinoyTasty, 
                pandesal,
                cheeseBread,
                spanishBread,
                mamon,
                ensaymada,
                pianonoRoll,
                eggPie
                );
        }
        _;
    }
    modifier bakeryClose {
        if( block.timestamp > time) {
            revert storeStillClosed(time);
        }
        _;
    }
    modifier grantAccess {
        if(!whiteListedAddresses[msg.sender] ) {   
            revert accessError(bakeryAccess);
        }
        _;
    }
    modifier buyBreads {
        if(!accessValid[msg.sender] ) {   
            revert loggedOutError(loggedOutMessage);
        }
        _;
    }
    modifier accessWithdraw {
        if(time > block.timestamp) {
            revert storeIsOpen(time);
        }
        _;
    }
    
    function getOwner() public view returns(address) {
        return owner;
    }

    // Function to see available stocks
    function getPinoyTasty() public view returns(uint256) {
        return pinoyTasty;
    }  
    function getPandesal() public view returns(uint256) {
        return pandesal;
    }
    function getCheeseBread() public view returns(uint256) {
        return cheeseBread;
    }
    function getSpanishBread() public view returns(uint256) {
        return spanishBread;
    } 
    function getMamon() public view returns(uint256) {
        return mamon;
    }
    function getEnsaymada() public view returns(uint256) {
        return ensaymada;
    }
    function getPianonoRoll() public view returns(uint256) {
        return pianonoRoll;
    }
    function getEggPie() public view returns(uint256) {
        return eggPie;
    }

    // Buy functions
    function buyPinoyTasty(uint256 _pinoyTasty) public outOfStock bakeryClose buyBreads onlyBuyer payable {
        require(msg.value >= _pinoyTasty * 5 gwei, "Insufficient payment.");
        require(pinoyTasty >= _pinoyTasty, "Available stocks are not enough.");
        pinoyTasty -= _pinoyTasty;
    }
    function buyPandesal(uint256 _pandesal) public outOfStock bakeryClose buyBreads onlyBuyer payable {
        require(msg.value >= _pandesal * 1 gwei, "Insufficient payment.");
        require(pandesal >= _pandesal, "Available stocks are not enough.");
        pandesal -= _pandesal;
    }
    function buyCheeseBread(uint256 _cheeseBread) public outOfStock bakeryClose buyBreads onlyBuyer payable {
        require(msg.value >= _cheeseBread * 2 gwei, "Insufficient payment.");
        require(cheeseBread >= _cheeseBread, "Available stocks are not enough.");
        cheeseBread -= _cheeseBread;
    }
    function buySpanishBread(uint256 _spanishBread) public outOfStock bakeryClose buyBreads onlyBuyer payable {
        require(msg.value >= _spanishBread * 2 gwei, "Insufficient payment.");
        require(spanishBread >= _spanishBread, "Available stocks are not enough.");
        spanishBread -= _spanishBread;
    }
    function buyMamon(uint256 _mamon) public outOfStock bakeryClose buyBreads onlyBuyer payable {
        require(msg.value >= _mamon * 2 gwei, "Insufficient payment.");
        require(mamon >= _mamon, "Available stocks are not enough.");
        mamon -= _mamon;
    }
    function buyEnsaymada(uint256 _ensaymada) public outOfStock bakeryClose buyBreads onlyBuyer payable {
        require(msg.value >= _ensaymada * 3 gwei, "Insufficient payment.");
        require(ensaymada >= _ensaymada, "Available stocks are not enough.");
        ensaymada -= _ensaymada;
    }
    function buyPianonoRoll(uint256 _pianonoRoll) public outOfStock bakeryClose buyBreads onlyBuyer payable {
        require(msg.value >= _pianonoRoll * 2 gwei, "Insufficient payment.");
        require(pianonoRoll >= _pianonoRoll, "Available stocks are not enough.");
        pianonoRoll -= _pianonoRoll;
    }
    function buyEggPie(uint256 _eggPie) public outOfStock bakeryClose buyBreads onlyBuyer payable {
        require(msg.value >= _eggPie * 5 gwei, "Insufficient payment.");
        require(eggPie >= _eggPie, "Available stocks are not enough.");
        eggPie -= _eggPie;
    }

    // Restock functions
    function restockPinoyTasty(uint256 quantity) public onlyOwner {
        if(pinoyTasty < 20) {
            pinoyTasty += quantity;
        }else {
            revert limitError(limitErrorMsg);
        }
        require(pinoyTasty <= 20, "Total quantity should be less than or equal to 20.");
    }
    function restockPandesal(uint256 quantity) public onlyOwner {
        if(pandesal < 100) {
            pandesal += quantity;
        }else {
            revert limitError(limitErrorMsg);
        }
        require(pandesal <= 100, "Total quantity should be less than or equal to 100.");
    }
    function restockCheeseBread(uint256 quantity) public onlyOwner {
        if(cheeseBread < 50) {
            cheeseBread += quantity;
        }else {
            revert limitError(limitErrorMsg);
        }
        require(cheeseBread <= 50, "Total quantity should be less than or equal to 50.");
    }
    function restockSpanishBread(uint256 quantity) public onlyOwner {
        if(spanishBread < 50) {
            spanishBread += quantity;
        }else {
            revert limitError(limitErrorMsg);
        }
        require(spanishBread <= 50, "Total quantity should be less than or equal to 50.");
    }
    function restockMamon(uint256 quantity) public onlyOwner {
        if(mamon < 50) {
            mamon += quantity;
        }else {
            revert limitError(limitErrorMsg);
        }
        require(mamon <= 50, "Total quantity should be less than or equal to 50.");
    }
    function restockEnsaymada(uint256 quantity) public onlyOwner {
        if(ensaymada < 30) {
            ensaymada += quantity;
        }else {
            revert limitError(limitErrorMsg);
        }
        require(ensaymada <= 30, "Total quantity should be less than or equal to 30.");
    }
    function restockPianonoRoll(uint256 quantity) public onlyOwner {
        if(pianonoRoll < 50) {
            pianonoRoll += quantity;
        }else {
            revert limitError(limitErrorMsg);
        }
        require(pianonoRoll <= 50, "Total quantity should be less than or equal to 50.");
    }
    function restockEggPie(uint256 quantity) public onlyOwner {
        if(eggPie < 40) {
            eggPie += quantity;
        }else {
            revert limitError(limitErrorMsg);
        }
        require(eggPie <= 40, "Total quantity should be less than or equal to 40.");
    }

    // close shop
    function closeBakery() public onlyOwner {
        time = 0;
    }
   
    // Open store
    function openBakery(uint256 timer) public onlyOwner {
        time = block.timestamp + timer;
    }
    function getOpenTimeLeft() public view returns(uint256) {
        require(time >= block.timestamp, "Time is over! Store is now closed.");
        return time - block.timestamp;
    }

    // balance
    function balanceOf() external onlyOwner view returns(uint256) {
        return address(this).balance;
    }

    // withdraw
    function withdraw() public onlyOwner accessWithdraw {
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    // whitelist
    function addUserToWhitelist (address _addressToWhitelist) public {   
        whiteListedAddresses[_addressToWhitelist] = true;
    }

    function removeUserToWhiteList (address _addressToWhitelist) public onlyOwner {
        whiteListedAddresses[_addressToWhitelist] = false;
    }

    function verifyUserIfWhitelisted(address _address) public view returns (bool) {  
        bool IsUserWhitelisted = whiteListedAddresses[_address];
        return IsUserWhitelisted;
    }
    
    function accessBakeryInAndOut() public grantAccess { 
        if( accessValid[msg.sender] == true ) {
            accessValid[msg.sender] = false;
            timeStamp = block.timestamp;
        } else accessValid[msg.sender] = true;
            timeStamp = block.timestamp;
    }

    function isLoggedIn(address _address) public view returns (bool, uint256) {   
        return  (accessValid[_address], timeStamp); 
    }

}
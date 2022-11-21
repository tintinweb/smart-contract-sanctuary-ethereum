/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 < 0.9.0;

error OutOfStock();
error accessError(bool access);
error promoEnded(uint end);
error noCoins();
error alreadyWhitelistedErr();
error notYetWhitelistedErr();
error insufficientValueErr(string insufficientValueMsg);
error insufficientCoinErr(string insufficientCoinMsg);
error onlyOwnerErr(string onlyOwnerMsg);
error withdrawalUnsuccessfulErr();

contract NanaOnline{
    uint256 public shirt = 200;
    uint256 public dress = 100;
    uint256 public ecobag = 50;
    address public owner;
    uint256 coinPrice = 5 wei; // 1 NaNa Coin for 5 wei
    bool access;
    uint end;
    string successMsg = "Success!";
    string insufficientValueMsg = "Your value is less than the coin price. Try again.";
    string insufficientCoinMsg = "You do NOT have enough NaNa Coins.";
    string onlyOwnerMsg = "You are not the owner.";

    mapping (address => uint256) public coinHolders;
    mapping (address => bool) whiteListedAddresses;

    constructor(){
        owner = msg.sender;
        whiteListedAddresses[msg.sender] = true;
    }
    
    //admin - access
    modifier AccessGrant {
        if(!whiteListedAddresses[msg.sender] ) {   
            revert accessError(access);
        }
        _;
    }

    modifier alreadyWhitelisted {
        if(whiteListedAddresses[msg.sender]) {   
            revert alreadyWhitelistedErr();
        }
        _;
    }

    modifier notYetWhitelisted {
        if(!whiteListedAddresses[msg.sender]) {   
            revert notYetWhitelistedErr();
        }
        _;
    }

    modifier onlyOwner {
        if(msg.sender != owner){
            revert onlyOwnerErr(onlyOwnerMsg);
        }
        _;
    }

    function addUserToWhitelist (address _addressToWhitelist) public alreadyWhitelisted{   
        whiteListedAddresses[_addressToWhitelist] = true;
    }

    function removeWhitelist(address _addressToWhitelist) public notYetWhitelisted{
        whiteListedAddresses[_addressToWhitelist] = false;
    }

    function verifyUserWhitelist(address _address) public view returns (bool) {  
        bool IsUserWhitelisted = whiteListedAddresses[_address];
        return IsUserWhitelisted;
    }
    
    function withdraw() public onlyOwner{
        (bool success, ) = payable(owner).call{value: address(this).balance}(" ");
        if(!success){
            revert withdrawalUnsuccessfulErr();
        }
    }

    function shirtInventory() public view returns (uint256){
        return shirt;
    }

    function dressInventory() public view returns (uint256){
        return dress;
    }

    function ecobagInventory() public view returns (uint256){
        return ecobag;
    }

    function addShirt(uint256 _additional) public onlyOwner {
        shirt = shirt + _additional;
    }

    function addDress(uint256 _additional) public onlyOwner {
        dress = dress + _additional;
    }

    function addEcobag(uint256 _additional) public onlyOwner {
        ecobag = ecobag + _additional;
    }
    
    function startPromo(uint256 time) public onlyOwner {
        end = block.timestamp + time;
    }
    
    function getPromoTimeLeft() public view returns(uint256) {
        return end - block.timestamp;
    }

    modifier promoLock {
        if( block.timestamp > end) {
            revert promoEnded(end);
        }
        _;
    }

    //customer 
    function buyCoins(uint256 _amount) payable public notYetWhitelisted {
        if(msg.value < coinPrice * _amount){
            revert insufficientValueErr(insufficientValueMsg);
        }
        addCoins(_amount);
    }

    function useCoins(uint256 _amount) public notYetWhitelisted {
        subCoins (_amount);
    }

    function addCoins(uint256 _amount) internal notYetWhitelisted {
        coinHolders[msg.sender] = coinHolders[msg.sender] + _amount;
    }

    function subCoins(uint256 _amount) internal notYetWhitelisted {
        if(coinHolders[msg.sender] < _amount){
            revert insufficientCoinErr(insufficientCoinMsg);
        }
        coinHolders[msg.sender] = coinHolders[msg.sender] - _amount;
    }

    function coinBalance(address _user) public view notYetWhitelisted returns (uint256) {
        if (coinHolders[_user] <= 0 ) {
           revert noCoins();
       }
        return coinHolders[_user];
    }

    modifier shirtSoldOut() {
       if (shirt == 0 ) {
           revert OutOfStock();
       }
       _;
    }

    modifier dressSoldOut() {
       if (dress == 0 ) {
           revert OutOfStock();
       }
       _;
    }

    modifier ecobagSoldOut() {
       if (ecobag == 0 ) {
           revert OutOfStock();
       }
       _;
    }

    function buyShirt(uint256 _pieces) public shirtSoldOut notYetWhitelisted returns (string memory){
        shirt = shirt - _pieces;
        //Shirt price is 8 Nana coins
        uint256 _amount = _pieces * 8;
        useCoins(_amount);
        return successMsg;
    }

    function buyDress(uint256 _pieces) public dressSoldOut notYetWhitelisted returns (string memory) {
        dress = dress - _pieces;
        //Dress price is 10 Nana coins
        uint256 _amount = _pieces * 10;
        useCoins(_amount);
        return successMsg;
    }

    function buyEcobag(uint256 _pieces) public ecobagSoldOut notYetWhitelisted returns (string memory) {
        ecobag = ecobag - _pieces;
        //Ecobag price is 1 Nana coins
        uint256 _amount = _pieces * 1;
        useCoins(_amount);
        return successMsg;
    }

    function Buy2ShirtGet1Ecobag() public shirtSoldOut ecobagSoldOut notYetWhitelisted promoLock{
        buyShirt(2);
        ecobag = ecobag - 1;
    }

    function balance() public view onlyOwner returns (uint256) {
        return payable(address(this)).balance;
    }
    
}
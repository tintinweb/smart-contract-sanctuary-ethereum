/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 < 0.9.0;

error OutOfStock();
error accessError(bool access);

contract NaNaStore{
    uint256 shirt = 20;
    address owner;
    uint256 coinPrice = 5 wei; // 1 NaNa Coin for 5 wei
    bool access;
    uint end;

    mapping (address => uint256) public coinHolders;
    mapping (address => bool) whiteListedAddresses;
    mapping (address => bool) accessValid; 

    constructor(){
        owner = msg.sender;
        whiteListedAddresses[msg.sender] = true;
    }
    
    //customer 
    function buyItem(uint256 _amount) external payable {
        // e.g. the buyer wants 100 NaNa Coins, needs to send 500 eth
        require(msg.value == _amount * coinPrice, "Need to send exact amount of eth.");
        // sends the requested amount of tokens/coins from the address to the buyer
        payable(msg.sender).transfer(_amount);
    }

    function buyCoins(address _user, uint256 _amount) payable public {
        require(msg.value >= coinPrice * _amount);
        addCoins(_user, _amount);
    }

    function useCoins(address _user, uint256 _amount) public {
        subCoins (_user, _amount);
    }

    function addCoins(address _user, uint256 _amount) internal {
        coinHolders[_user] = coinHolders[_user] + _amount;
    }

    function subCoins(address _user, uint256 _amount) internal {
        require(coinHolders[_user] >= _amount, "You don't have enough NaNa Coins.");
        coinHolders[_user] = coinHolders[_user] - _amount;
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not the owner.");
        (bool success, ) = payable(owner).call{value: address(this).balance}(" ");
        require(success);
    }

    modifier shirtSoldOut() {
       if (shirt == 0 ) {
           revert OutOfStock();
       }
       _;
    }

    function Buy2ShirtGet1Ecobag() public shirtSoldOut {
        shirt = shirt - 2;
    }

    function Shirt() public view returns(uint256) {
        return shirt;
    }

    function balance() public view returns (uint256){
        return payable(address(this)).balance;
  }
    //admin - access
    modifier AccessGrant {
        if(!whiteListedAddresses[msg.sender] ) {   
            revert accessError(access);
        }
        _;
    }

    function addUserToWhitelist (address _addressToWhitelist) public {   
        whiteListedAddresses[_addressToWhitelist] = true;
    }

    function verifyUserWhitelist(address _address) public view returns (bool) {  
        bool IsUserWhitelisted = whiteListedAddresses[_address];
        return IsUserWhitelisted;
    }

    function AccesInventoryInAndOut() public AccessGrant { //4 
        if( accessValid[msg.sender] == true ) {
            accessValid[msg.sender] = false;
        } else accessValid[msg.sender] = true;
    }

    function isLoggedIn(address _address) public view returns (bool) {   
        return  accessValid[_address]; 
    }

    function closeTicketStore(uint256 time) public {
        end = block.timestamp + time;
    }

    function getTimeLeft() public view returns(uint256) {
        return end - block.timestamp;
    }


}
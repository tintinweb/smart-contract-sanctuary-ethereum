/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// File: TGCTask.sol


pragma solidity ^0.8.7;

contract TheGameCircle {

    address payable owner ;
   
    // Number of accounts Whitelisted
    uint32 public numAddressesWhitelisted;

     // Number of accounts Blacklisted
    uint32 public numAddressesBlacklisted;

    // Check if the address is in the whitelist
    mapping(address => bool) public whitelistedAddresses;

    // Check if the address is in the blacklist
    mapping (address =>bool) public blacklistedAddresses;


     struct Community {
        string communityName;
        uint32 maxPlayer;
        address[] player;
        uint fee;
    }

    Community[] public communities;

    constructor(){
        owner = payable (msg.sender);
    }



    function createCommunity (string memory _name, uint32  _maxplayer,uint  _fee,address[] memory _player)external  onlyOwner {
        
        Community memory community;        
        community.communityName = _name;
        community.maxPlayer = _maxplayer;
        community.player = _player;
        community.fee = _fee;
   
        communities.push(community);
    }


    // Community Data - Searching with communities id 
    function getCommunity(uint32 _communityId) public view returns (Community memory){
        require(_communityId<=communities.length,"Out of bounds");
        return  communities[_communityId];

    }

    // JoinCommunity - Needs to be in whitelist and pay the community fee
    function joinCommunity(uint256 id) external payable  isBlacklisted isWhitelisted {
        require(communities[id].maxPlayer>=communities[id].player.length,"Community is Full");
        require(msg.value == communities[id].fee * 1 ether,"Incorrect amount of ether");
        require(msg.value< msg.sender.balance,"You dont have enough money");
        
        (bool success,) = owner.call{value: msg.value}("");
        require(success, "Failed to send money");


        for (uint i=1;i<communities[id].player.length;i++) {

            if (communities[id].player[i] == msg.sender) {
                revert("User is already in the community");
            }
         } 
         
       communities[id].player.push(msg.sender);
      
    }

    // Returns the index of the user 
    function isUser(uint256 id,address kickPlayerIndex) internal view onlyOwner returns (uint find){
        bool finded;
        for (uint i=0;i< communities[id].player.length; i++) 
        {
            if (communities[id].player[i] == kickPlayerIndex) {
                finded == true;
                return  i;
                
            }   
        }
        if (!finded) {
            revert("There is no people with this address");
        }
            
    }

    /** Remove function, sets the element in the index selected with the isUser function 
        as the last element of the array. Then deletes with the array.pop function
    **/
     function remove(uint communityId,uint playerIndex) private onlyOwner{
            communities[communityId].player[playerIndex] = communities[communityId].player[communities[communityId].player.length - 1];
            communities[communityId].player.pop();
    }

    // It is used to kick users from the community. The function needs community id and the address in order to work
    function kickPlayer(uint256 id, address kickedPlayer) external  onlyOwner{
        remove(id,isUser(id, kickedPlayer));
    
     }

    // Add account to whitelist
    function addToWhiteList (address _addressToWhitelist) external  onlyOwner {
        require(!whitelistedAddresses[_addressToWhitelist], "Sender has already been whitelisted");
        require(!blacklistedAddresses[_addressToWhitelist],"user is on the blacklist");

        whitelistedAddresses[_addressToWhitelist]= true;
        numAddressesWhitelisted++;
    }
    // Remove account from whitelist
    function removeFromWhitelist ( address _addressToWhitelist) external   onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = false;
        numAddressesWhitelisted--;
    }

    // Add account to blacklist
    function addToBlacklist ( address  _addressToBlacklist) external  onlyOwner {
        require(!whitelistedAddresses[_addressToBlacklist], "The user is on  whitelisted");
        require(!blacklistedAddresses[_addressToBlacklist],"Sender has already been blacklist");
        blacklistedAddresses[_addressToBlacklist] = true;
        numAddressesBlacklisted++;
    }
    
    // Remove account from blacklist
    function removeFromBlacklist (address _addressToBlacklist) external   onlyOwner {
        blacklistedAddresses[_addressToBlacklist] = false;
        numAddressesBlacklisted--;
    }

    // Makes it only available for the owner
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // Check if the signer is on the whitelist
    modifier  isWhitelisted() {
         require(whitelistedAddresses[msg.sender] ==true,"You aren't on the whitelist");
         _;
    }

    // Check if the signer is on the blacklist
    modifier isBlacklisted(){
        require(blacklistedAddresses[msg.sender] ==false,"You are in the Blacklist");
        _;
    }
}
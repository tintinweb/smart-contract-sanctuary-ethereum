/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

pragma solidity 0.8.19;
/*
 __          __                             _    _____                                  _             
 \ \        / /                            | |  / ____|                                (_)            
  \ \  /\  / / __ __ _ _ __  _ __   ___  __| | | |     ___  _ __ ___  _ __   __ _ _ __  _  ___  _ __  
   \ \/  \/ / '__/ _` | '_ \| '_ \ / _ \/ _` | | |    / _ \| '_ ` _ \| '_ \ / _` | '_ \| |/ _ \| '_ \ 
    \  /\  /| | | (_| | |_) | |_) |  __/ (_| | | |___| (_) | | | | | | |_) | (_| | | | | | (_) | | | |
     \/  \/ |_|  \__,_| .__/| .__/ \___|\__,_|  \_____\___/|_| |_| |_| .__/ \__,_|_| |_|_|\___/|_| |_|
                      | |   | |                                      | |                              
 __          ___     _|_|   |_|  _      _     _     __  __           |_|                              
 \ \        / / |   (_) |       | |    (_)   | |   |  \/  |                                           
  \ \  /\  / /| |__  _| |_ ___  | |     _ ___| |_  | \  / | __ _ _ __   __ _  __ _  ___ _ __          
   \ \/  \/ / | '_ \| | __/ _ \ | |    | / __| __| | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|         
    \  /\  /  | | | | | ||  __/ | |____| \__ \ |_  | |  | | (_| | | | | (_| | (_| |  __/ |            
     \/  \/   |_| |_|_|\__\___| |______|_|___/\__| |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|            
                                                                              __/ |                   
                                                                             |___/                   

-WhiteList Data store to enable the storage of Whitelist addresses for features for the wTC ecosystem
-To ensure that contracts relying on WhiteLists can be upgraded without losing data
*/

contract wTCWL{
    
    //Std Variables///
    address public Owner;
    address public manager; //Able to modify addresses at a lower level
    mapping(address => bool) internal whitelist; //Main Whitelist
    mapping(address => bool) internal whitelist2; //2nd Whitelist
    mapping(address => bool) internal whitelist3; //3rd Whitelist
    //////////////////
    
    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }
    
    constructor () public {
      Owner = msg.sender; //Owner of Contract
      manager = msg.sender; //Owner as default      
    }
    
    ////Manage whitelist(s)
    function manageWhiteList(address _user,bool _onoroff,uint wl) external
    {
    require(msg.sender==Owner || msg.sender==manager,"Not Authorized(WL)");
    if (wl==1)
    {
        whitelist[_user]=_onoroff;
    }
    if (wl==2)
    {
        whitelist2[_user]=_onoroff;
    }
    if (wl==3)
    {
        whitelist3[_user]=_onoroff;
    }
    }

    //configure the Manager who can manage whitelist besides Owner
    function setManager(address _manager)external onlyOwner{
        manager = _manager;
    }

    //configure the Owner (Renounce)
    function setOwner(address _owner)external onlyOwner{
        Owner = _owner;
    }

    //return the current status of the whiltelist for a user
     function isOnWhitelist(address _user,uint wlnumber)external view returns(bool)
     {
         bool temp;
         if (wlnumber==1)
         {
             temp = whitelist[_user];
         }
         if (wlnumber==2)
         {
             temp = whitelist2[_user];         
         }
         if (wlnumber==3)
         {
             temp = whitelist3[_user];         
         }
         return temp;
}
}
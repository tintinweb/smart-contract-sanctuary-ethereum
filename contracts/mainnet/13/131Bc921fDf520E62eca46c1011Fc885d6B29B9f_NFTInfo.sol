/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

pragma solidity ^0.6.12;
/*
 _    _                                _   _____                                   _             
| |  | |                              | | /  __ \                                 (_)            
| |  | |_ __ __ _ _ __  _ __   ___  __| | | /  \/ ___  _ __ ___  _ __   __ _ _ __  _  ___  _ __  
| |/\| | '__/ _` | '_ \| '_ \ / _ \/ _` | | |    / _ \| '_ ` _ \| '_ \ / _` | '_ \| |/ _ \| '_ \ 
\  /\  / | | (_| | |_) | |_) |  __/ (_| | | \__/\ (_) | | | | | | |_) | (_| | | | | | (_) | | | |
 \/  \/|_|  \__,_| .__/| .__/ \___|\__,_|  \____/\___/|_| |_| |_| .__/ \__,_|_| |_|_|\___/|_| |_|
                 | |   | |                                      | |                              
                 |_|   |_|                                      |_|                              
______      _          _____             _                  _                                    
|  _  \    | |        /  __ \           | |                | |                                   
| | | |__ _| |_ __ _  | /  \/ ___  _ __ | |_ _ __ __ _  ___| |_                                  
| | | / _` | __/ _` | | |    / _ \| '_ \| __| '__/ _` |/ __| __|                                 
| |/ / (_| | || (_| | | \__/\ (_) | | | | |_| | | (_| | (__| |_                                  
|___/ \__,_|\__\__,_|  \____/\___/|_| |_|\__|_|  \__,_|\___|\__|                                 
                                                                                                 
                                                                                               

-NFT data store to hold the following
- Wrapped Status
- Blocked NFT's
- Is Holder?
- Status of wrapped (fees)
- number of holders (For future use)
- Array for address storage for royalty cleanup
*/

//Interface to NFT contract
interface wrappedcompanion{
    ////Interface to RCVR
  function balanceOf(address owner) external view returns (uint256);
  function tokenURI(uint256 tokenId ) external view returns (string memory);
  function getArtApproval(uint _tokennumber,address _wallet)external view returns(bool);
  function ownerOf(uint256 tokenId) external view returns (address);
  function setStringArtPaths(uint _pathno,string memory _path,uint _tokenid,address _holder) external;

}
interface ogcompanion{
    ////Interface to RCVR
  function ownerOf(uint256 tokenId) external view returns (address);

}

contract NFTInfo{
    //Arrays///
    uint[] private blockednfts; //Array to handle a blocked nfts
    
    //Std Variables///
    address public wtcaddress = 0x16e2220Bba4a2c5C71f628f4DB2D5D1e0D6ad6e0;
    address public companion = 0x89af532726f48b7E77aE60705E166252e9Dcde15;
    address public Owner;
    address public manager; //Able to modify addresses at a lower level
    address public royaltywallet; //Wallet for royalties
    address public upgradecontract; //User management of art
    uint private numwraps;
    uint public numholders;
    uint public numblocked;
    ///////Important Mappings///////
    mapping(address => bool) internal wrapped; //Whether a holder has wrapped
    mapping(address => bool) internal holder; //Whether they are a holder
    mapping(address => uint) internal feespaid; //Status of users fees -> 0 -> Not paid for wrap 1-> Paid once 0.01ETH 2-> Paid up to limit of 0.02ETH
    mapping(uint => uint) internal artenabled; //Dynamic mapping of ar enabled/disabled
    mapping(address => string) internal artpath; //Dynamic mapping of art
    mapping(uint => bool) internal blocked; //blocking due to mapping
    mapping(address=> bool) internal blockedaddresses; //Additional addresses to blacklist
    ///////Array for holders////////
    address[] internal holderaddresses; //array to store the holders
    ////////////////////////////////
    
    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }
    
    constructor () public {
      Owner = msg.sender; //Owner of Contract
      manager = msg.sender; //Owner as default      
    }
    ///Update NB address if required
    function configNBAddresses(uint option,address _address) external onlyOwner{
        if (option==1)
        {
        wtcaddress = _address;
        }
        if (option==2)
        {
        royaltywallet = _address;
        }
        if (option==3)
        {
        companion = _address;
        }
        if (option==4)
        {
        upgradecontract = _address;
        }
            }
    //Setup ArtWork Manager address///
    function setManager(address _manager) external onlyOwner
    {
        manager = _manager;
    }
    //Obtain Art status for user
    function getArtStatus(uint _tokenid)public view returns(uint)
    {
        uint temp;
        temp = artenabled[_tokenid];
        return temp;
    }
    
    function setARTinWrapper(uint path,string memory _path,uint _tokenid,address _holder) public
    {

        require(msg.sender==Owner || msg.sender==upgradecontract,"Not Auth(U)");
      wrappedcompanion(wtcaddress).setStringArtPaths(path,_path,_tokenid,_holder);

    }
    
    //Sets the art path for a user
    function setArtPath(uint _tokennumber,address _holder,uint _pathno) external
    {
        bool temp;
        string memory dummy = ""; //dummy string to pass in
        require(msg.sender == Owner || msg.sender==manager || msg.sender==upgradecontract,"Not Auth!");
        temp = wrappedcompanion(wtcaddress).getArtApproval(_tokennumber,_holder);
        require(temp==true,"Owner not approved!");
        if (_pathno == 0)
        {
            setARTinWrapper(4,dummy,_tokennumber,_holder); //Resets dynamic art off
            artenabled[_tokennumber] = 0;
        }
        if (_pathno == 1)
        {
            setARTinWrapper(4,dummy,_tokennumber,_holder); //Resets dynamic art off
            artenabled[_tokennumber] = 1;
        }
        if (_pathno == 2)
        {
            setARTinWrapper(4,dummy,_tokennumber,_holder); //Resets dynamic art off
            artenabled[_tokennumber] = 2;
        }
    }
   
    //Function to Verify whether an NFT is blocked
    function isBlockedNFT(uint _tokenID) public view returns(bool,uint256)
   {
       bool temp;
       address tempaddress;
       temp = blocked[_tokenID];
       if(temp==false)
       {
          tempaddress = ownerOfToken(_tokenID);
          temp = blockedaddresses[tempaddress];//if the owner is blocked
       }

       return (temp,0);
   }
   //Function to return whether they are a holder or not
   function isHolder(address _address) public view returns(bool)
   {
       bool temp;
       if(holder[_address]==true)
       {
          temp=true; 
       }
       return temp;
   }
   function manageHolderAddresses(bool status,address _holder) external {
       require(msg.sender == wtcaddress||msg.sender==Owner||msg.sender==royaltywallet,"Not Oracle/Owner!");
       if(status==true)
       {
           //Add user to array!
           (bool _isholder, ) = isHolderInArray(_holder);
           if(!_isholder)holderaddresses.push(_holder);
       }
       if(status==false)
       {
           (bool _isholder, uint256 s) = isHolderInArray(_holder);
           if(_isholder){
           holderaddresses[s] = holderaddresses[holderaddresses.length - 1];
           holderaddresses.pop();
       }
       holder[ _holder]=status;


   }
   }
   /////To keep track of holders for future use
   function manageNumHolders(uint _option) external {
       require(msg.sender == wtcaddress||msg.sender==Owner||msg.sender==royaltywallet,"Not Oracle/Owner!");
       if (_option==1) //remove holder
       {
           numholders -= numholders -1;
       }
       if (_option==2) //add holder
       {
           numholders += 1;
       }
   }
    
    /////Returns whether the user is stored in the array////////
    function isHolderInArray(address _wallet) public view returns(bool,uint)
    {
        for (uint256 s = 0; s < holderaddresses.length; s += 1){
           if(_wallet == holderaddresses[s]) return (true,s);
       }
       return (false,0);
    }
    /////////////////////////



    ///Function to override the numholders, this is incase of logic issues and to make sure claim is fair
    function forceNumHolders(uint _value) external onlyOwner{
        numholders = _value;
    }
       

   
   ///Function to manage addresses
   function manageBlockedNFT(int option,uint _tokenID,address _wallet,uint _numNFT,bool _onoroff) external onlyOwner{
       address temp;
       if (option==1) // Add NFT to block list
       {
           blocked[_tokenID] = true;
           numblocked+=1;
       }
       if (option==2) //Remove from array
       {
           bool _isblocked = blocked[_tokenID];
       if(_isblocked){
           blocked[_tokenID] = false;
          if (numblocked>0)
          {
              numblocked-=1;
          }
       }
       }
        if (option==3) //Iterate through entire colletion and add
       {
       for (uint256 s = 0; s < _numNFT; s += 1){
           if(s>0)
           {
               temp = ownerOfToken(s);
           
           if (temp ==_wallet)
           {
            blocked[s] = true;
            numblocked+=1;
           }
           }
       }
       }
       if(option==4)
       {
           //setup blocking of addresses
           blockedaddresses[_wallet] = _onoroff;
       }
       
   
   }
    
    //Function to set the status of a wrap for fee support////
   function setUserStatus(address _wrapper,uint _status,bool _haswrapped) external{
       require(msg.sender == wtcaddress||msg.sender==Owner||msg.sender==royaltywallet,"Not Oracle/Owner!");
       feespaid[_wrapper] = _status;
       wrapped[_wrapper] = _haswrapped;
       numwraps+=1; //track number of wraps
       
   }
   function getWrappedStatus(address _migrator) external view returns(bool){
       bool temp;
       if(wrapped[_migrator]==true)
       {
       temp = wrapped[_migrator];
       }
       return temp;
   }
   function getFeesStatus(address _migrator) external view returns(uint){
       uint temp;
       temp = feespaid[_migrator];
       return temp;
   }
   function getNumHolders(uint _feed) external view returns(uint){

       uint temp;
        if (_feed ==1)
        {
            temp = numholders;
        }
        if (_feed ==2)
        {
            temp = holderaddresses.length;
        }
        if (_feed ==3)
        {
            temp = blockednfts.length;
        }
       return temp;
   }
   ///Returns the holder address given an Index
   function getHolderAddress(uint _index) external view returns(address payable)
   {
     address temp;
     address payable temp2;
     temp = holderaddresses[_index];
     temp2 = payable(temp);
     return temp2;

   }
   //Returns OwnerOf from NFT
   function ownerOfToken(uint _tid) public view returns (address)
   {
       address temp;
       temp = ogcompanion(companion).ownerOf(_tid);
       return temp;
   }
 
}
/**
 *Submitted for verification at Etherscan.io on 2022-02-14
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
*/

//Interface to NFT contract
interface WrappedCompanion {
    ////Interface to RCVR
  function balanceOf(address owner) external view returns (uint256);
  function tokenURI(uint256 tokenId ) external view returns (string memory);
}

contract NFTInfo{
    //Arrays///
    uint[] private blockednfts; //Array to handle a blocked nfts
    //Std Variabls///
    address public wtcaddress;
    address public Owner;
    uint private numwraps =0;
    uint public numholders =0;
    ///////Important Mappings///////
    mapping(address => bool) internal wrapped; //Whether a holder has wrapped
    mapping(address => bool) internal holder; //Whether they are a holder
    mapping(address => uint) internal feespaid; //Status of users fees -> 0 -> Not paid for wrap 1-> Paid once 0.01ETH 2-> Paid up to limit of 0.02ETH
    
    
    
    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }
    
    constructor () public {
      Owner = msg.sender; //Owner of Contract
      wtcaddress = 0x113066Fa1Db242B25e813EF453FA65F5BD173cf8; //This is the address of the wrapped NFT contract, used to lock down requests
            
    }
    ///Update NFT address if required
    function configNFT(address _NFTaddress) external onlyOwner{
        wtcaddress = _NFTaddress;
            }
    
    //Function to Verify whether an NFT is blocked
    function isBlockedNFT(uint _tokenID) public view returns(bool,uint256)
   {
       for (uint256 s = 0; s < blockednfts.length; s += 1){
           if (_tokenID == blockednfts[s]) return (true,s);
       }
       return (false,0);
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
       require(msg.sender == wtcaddress||msg.sender==Owner,"Not Oracle/Owner!");
       holder[_holder]=status; 

   }
   /////To keep track of holders for future use
   function manageNumHolders(uint _option) external {
       require(msg.sender == wtcaddress||msg.sender==Owner,"Not Oracle/Owner!");
       if (_option==1) //remove holder
       {
           numholders -= numholders -1;
       }
       if (_option==2) //add holder
       {
           numholders += 1;
       }
       

   }
   ///Function to manage addresses
   function manageBlockedNFT(int option,uint _tokenID) external onlyOwner{
       if (option==1) // Add NFT to block list
       {
           blockednfts.push(_tokenID); //add nfts to blocked id's
       }
       if (option==2) //Remove from array
       {
           (bool _isblocked,uint256 s) = isBlockedNFT(_tokenID);
       if(_isblocked){
           blockednfts[s] = blockednfts[blockednfts.length - 1];
          blockednfts.pop();
       }
       
   }
   }
    //Function to set the status of a wrap for fee support////
   function setUserStatus(address _wrapper,uint _status,bool _haswrapped) external{
       require(msg.sender == wtcaddress||msg.sender==Owner,"Not Oracle/Owner!");
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
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
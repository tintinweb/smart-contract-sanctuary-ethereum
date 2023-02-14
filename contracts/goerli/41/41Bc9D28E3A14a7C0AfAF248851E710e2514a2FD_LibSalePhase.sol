// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//  enum STATE { NONE, START, PAUSE , END} // 0 1 2 3
// import "hardhat/console.sol";

library LibSalePhase {

    enum STATE { NONE, START, PAUSE , END} 
    struct PhaseSettings {
        uint phaseNum;

        string name;
        /// @dev phase supply. This can be released to public by ending the phase.
        uint maxSupply;
        /// @dev tracks the total amount minted in the phase
        uint amountMinted;
        /// @dev wallet maximum for the phase
        uint maxPerWallet;
        /// @dev merkle root for the phase (if applicable, otherwise bytes32(0))
        bytes32 merkleRoot;
        /// @dev whether the phase is active
        bool isActive;
      
        /// @dev price for the phase (or free if 0)
        uint256 price;

        STATE status; 

        
    }

    struct SaleState {
        uint phaseNum;
        uint activeState;
        mapping(uint256 => PhaseSettings) phases;
        mapping(uint => mapping(address => uint)) mintAddress;
  
    }

      // return a struct storage pointer for accessing the state variables
    function  phaseSettingsStorage() 
      internal 
      pure 
      returns (PhaseSettings storage ds) 
    {
      bytes32 position = keccak256("phaseSetting.diamond.storage");
      assembly { ds.slot := position }
    }


    function saleStateStorage() 
      internal 
      pure 
      returns ( SaleState storage ps) 
    {
      bytes32 position = keccak256("saleState.diamond.storage");
      assembly { ps.slot := position }
    }

   function setActiveState(uint activeState_)  internal{
         SaleState storage ss = saleStateStorage();
         ss.activeState =  activeState_;
         ss.phases[activeState_].isActive = true;
   } 


   function setPhaseStatus(uint phaseNum_ , uint status_)  internal{

         require(status_ <= uint(STATE.END), "Out of status state");

         SaleState storage ss = saleStateStorage();
         ss.activeState =  phaseNum_;
         ss.phases[phaseNum_].status = STATE(status_);
   } 


   function setAmountMintedPhase(uint phaseNum_ , uint  amountMinted_ ,address user_)  internal{
         SaleState storage ss = saleStateStorage();
         ss.phases[phaseNum_].amountMinted += amountMinted_;
         ss.mintAddress[phaseNum_][user_] +=  amountMinted_;
   }

   function getActivePhase()  public  view  returns( PhaseSettings memory ){
      SaleState storage ss = saleStateStorage();
     return  ss.phases[ss.activeState];
   } 

   function getAllPhase() public  view  returns ( PhaseSettings[] memory  ){

       SaleState storage ss = saleStateStorage();
       PhaseSettings[] memory salestate = new PhaseSettings[](ss.phaseNum);

      for(uint i = 0; i < ss.phaseNum; i++){
        salestate[i] =  ss.phases[i+1];
      }
      return   salestate;
   }

   function getPhase(uint numPhase_) public  view returns(PhaseSettings memory){
       SaleState storage ps = saleStateStorage();
       return ps.phases[numPhase_];

   }


  function addPhase(
    string  memory name_,
    uint    maxSupply_,
    uint    maxPerWallet_,
    bytes32 merkleRoot_,
    bool    isActive_,
    uint256 price_
  )  internal  {

    SaleState storage ps = saleStateStorage();
    ps.phaseNum =  ps.phaseNum+1;
    ps.phases[ps.phaseNum].phaseNum     = ps.phaseNum;
    ps.phases[ps.phaseNum].name         = name_;
    ps.phases[ps.phaseNum].maxSupply    = maxSupply_;
    ps.phases[ps.phaseNum].amountMinted = 0;
    ps.phases[ps.phaseNum].maxPerWallet = maxPerWallet_;
    ps.phases[ps.phaseNum].merkleRoot   = merkleRoot_;
    ps.phases[ps.phaseNum].isActive     = isActive_;
    ps.phases[ps.phaseNum].price        = price_;
    
  }

  function updatePhase(
    string  memory name_,
    uint    maxSupply_,
    uint    maxPerWallet_,
    bytes32 merkleRoot_,
    bool    isActive_,
    uint256 price_,
    uint    numPhase_
  )  internal  {
    
    SaleState storage ss = saleStateStorage();
    // ss.phases[numPhase_] = ds;
    ss.phases[numPhase_].name          = name_;
    ss.phases[numPhase_].maxSupply     = maxSupply_;
    ss.phases[numPhase_].maxPerWallet =  maxPerWallet_;
    ss.phases[numPhase_].merkleRoot    = merkleRoot_;
    ss.phases[numPhase_].isActive      = isActive_;
    ss.phases[numPhase_].price         = price_;
   // ss.phases[numPhase_].status       = STATE.NONE;

    
  }

  ///////////////
  // Whitelist
  ///////////////
  function addWhitelist(address[] calldata _users, uint phaseName) public {

  }

  function unWhitelist(address[] calldata _users, uint phaseName) public {

  }

  function isWhitelist(address addr, uint phaseName) public returns(bool) {
    return true;
  }

   function setMintAddress(
    address address_,
    uint    amountMint_
  )  internal  {
    SaleState storage ss = saleStateStorage();
    ss.mintAddress[ss.activeState][address_] += amountMint_;

  }

  function getMintAvailableAddress(
    address address_
  )  public  view returns(uint){ 
    SaleState storage ss = saleStateStorage();
    return  ss.phases[ss.activeState].maxPerWallet - ss.mintAddress[ss.activeState][address_];

  }

  function getPhaseTotalMint(
    uint numPhase_
  )public view returns(uint ) {
    SaleState storage ss = saleStateStorage();
    return  ss.phases[numPhase_].amountMinted;
  }

} // end lib
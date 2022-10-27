pragma solidity ^0.8.4;
/*
import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/VRFConsumerBaseV2.sol";
*/

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

interface Stats {
    function incrementTOTAL() external  ;
    function incrementWON(address user) external  ;
    function incrementLOST(address user) external  ;
    function incrementPLAYED(address user) external  ;
}

contract Lottery is VRFConsumerBaseV2 {

  Stats public stats ; 
  
    
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;


  address vrfCoordinator =0x271682DEB8C4E0901D1a1550aD2e64D568E69909 ;

  bytes32 keyHash = 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;

  uint32 callbackGasLimit = 1000000;

  uint16 requestConfirmations = 3;

  uint32 numWords =  1;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;
  

  mapping(uint256 => address) public ticket ;
  mapping(address => bool) public bought;
  mapping(uint256 => address) public boughtTRACK;
  uint256 bvar ; 
  uint256 public ticketTRACK = 0; 
  uint256 weiVal = 500000000000000000;
  uint256 maxp = 4;
  address owner =0xE6F747501498903758BDF7AE648188E86f508Ef6 ;

  bool allowed_tobuy = true;
  
  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    stats = Stats(0x2C81b71efc52fEF5EC30c9c531E7c74222b8c2aa);
    
  }
  
  modifier OnlyOwner(){
    require(msg.sender == owner);
    _;
  }
  
  function editVal(uint256 newv, uint256 maxpn) public OnlyOwner{
    require(maxpn <=10);
    weiVal = newv;
    maxp = maxpn-1;
    uint256 a = 1;
    while(a <= ticketTRACK){
      ticket[a] = 0x0000000000000000000000000000000000000000;
      a = a+1;
    }
    ticketTRACK = 0; 
    uint256 b = 1; 
    while (b <= bvar){
      address addyb = boughtTRACK[b];
      bought[addyb] = false;
      b = b+1;
    }
    bvar = 0 ; 
    allowed_tobuy = true;
  }
  

  function buyTicket() public payable{
      require(ticketTRACK <= maxp );
      require(bought[msg.sender]==false);
      require(msg.value == weiVal);
      require(allowed_tobuy == true);
      ticket[ticketTRACK+1] = msg.sender;
      ticketTRACK = ticketTRACK+1;
      bought[msg.sender] = true;
      bvar = bvar +1;
      boughtTRACK[bvar] = msg.sender;
      stats.incrementTOTAL();
      stats.incrementPLAYED(msg.sender);
  }
  
  function requestRandomWords() external OnlyOwner {
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    
  }

  function fulfillRandomWords  (
    uint256 s_requestId, 
    uint256[] memory randomWords
  ) internal override {
    uint256 s_randomRange = (randomWords[0] % maxp+1) + 1;
    settleLotto(s_randomRange);
  }
  

  function settleLotto(uint256 num) internal{
    address winner = ticket[num];
    uint256 balance = address(this).balance;
    uint256 tax = balance/10;
    uint256 total = balance-tax;
    payable(owner).transfer(tax);
    payable(winner).transfer(total);
    stats.incrementWON(winner);
    allowed_tobuy = false;
  }

  function refund() public OnlyOwner {
    uint256 a = 1;
    while(a <= ticketTRACK){
      payable(ticket[a]).transfer(weiVal);
      a = a+1;
    }
    allowed_tobuy = false;
  }

}
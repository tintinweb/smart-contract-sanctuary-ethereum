/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

pragma solidity ^0.8.15;
// import "hardhat/console.sol";
   contract VOMO_Presale_Airdrop_ICO {
       string public constant name = "VomoVerse";
       string public constant symbol = "Vomo";
       uint public constant decimals = 18;
       uint public constant Presale_Price = 70921;
       uint actual_Presale_Price =Presale_Price-((Presale_Price/100)*1);
       uint256 public constant Token_Soft_Cap = 105000000000000000000000000;
       uint256 public constant Softcap_Rate = 625;
       uint256 public constant Token_Hard_Cap = 105000000000000000000000000;
       uint256 public constant  Hardcap_Rate= 277;
       uint256 public start_timestamp;
       uint256 public Vesting_timestamp=(start_timestamp + 7776000);
       uint256 public Softdays = start_timestamp + 2592000;
       uint256 public Harddays = Softdays + 2592000;
       address buyer;
       uint256 depositedValue2;
       uint256 public Presale_End_Countdown;
       uint256 public numWhitelisted = 0; 
      //  uint numTokens;
       uint256 Presale_Supply;
       address funder1;
       address funder2;
       address funder3;
       address Development;
       address Marketing;
       address Community;
       address TokenStability;
       address Referral;
       address[] public owners;
       uint public initialToken = 0; 
       address public escrow ;

      //Maping

       mapping (address => uint256) private balance;
       mapping (address => bool) ownerAppended;

       enum State{
          Running
        }
    
       State public currentState = State.Running;
    
      //Modifiers:
       modifier onlyInState(State state){ require(state == currentState); _; }

      // Events for Buyer:
       event Buyer_Transfer(address indexed from, address indexed to, uint256 _value);

      // Events for Referal:
       event Ref_Transfer(address indexed from, address indexed to, uint256 _value);

       constructor(address _escrow, uint256 _Presale_End_Countdown, address _funder1, address _funder2, address _funder3, address _Development, address _Marketing, address _Community, address _TokenStability) public {
          Presale_End_Countdown = _Presale_End_Countdown;
          funder1 = _funder1;
          funder2 = _funder2;
          funder3 = _funder3;
          Development = _Development;
          Marketing = _Marketing;
          Community = _Community;
          TokenStability =_TokenStability;
          require(_escrow != address(0));
          escrow = _escrow;
          Presale_Supply = 3000000000000000000000000;
          }

      //Function
       function buyTokens(address _buyer, address _referral) public payable onlyInState(State.Running) {
          Referral = _referral;
          require(Referral !=  _buyer);
          require(block.timestamp <= Presale_End_Countdown, "Presale Date Exceed.");
          require(msg.value != 0);
          uint buyerTokens = msg.value * actual_Presale_Price;
          uint reftokensVal = msg.value * Presale_Price;
          uint Balance_funder1 = (msg.value/100)*15;
          uint Balance_funder2 = (msg.value/100)*5;
          uint Balance_funder3 = (msg.value/100)*5;
          uint Balance_Development = (msg.value/100)*35;
          uint Balance_Marketing = (msg.value/100)*25;
          uint Balance_Community = (msg.value/100)*5;
          uint Balance_TokenStability = (msg.value/100)*10;
          
          

           if (msg.value>=13152000000000000) {
             uint refToken = (reftokensVal/100)*4;
             uint actual_refToken =refToken-((refToken/100)*1);
             
             balance[Referral] += actual_refToken;
             emit Ref_Transfer(escrow, Referral, actual_refToken);
             }
         
             
          require(initialToken + buyerTokens <= Presale_Supply);
          balance[_buyer] += buyerTokens;
          initialToken += buyerTokens;

           if (!ownerAppended[_buyer]) {
              ownerAppended[_buyer] = true;
              owners.push(_buyer);
             }
             emit Buyer_Transfer(escrow, _buyer,  buyerTokens);

          
   
           if(address(this).balance > 0) {
              // payable (escrow).transfer(address(this).balance);
                 payable (funder1).transfer(Balance_funder1);
                 payable (funder2).transfer(Balance_funder2);
                 payable (funder3).transfer(Balance_funder3);
                 payable (Development).transfer(Balance_Development);
                 payable (Marketing).transfer(Balance_Marketing);
                 payable (Community).transfer(Balance_Community);
                 payable (TokenStability).transfer(Balance_TokenStability);
             }

    }
    // Default fallback function
    function fallback () public payable {
    buyTokens(msg.sender, Referral);
    }
   }
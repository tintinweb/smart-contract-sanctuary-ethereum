/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0
//Made by an unpaid intern, potentially known as a gremlin in the Ribbon discord who asks too many vague questions

pragma solidity ^0.8.0;

contract Ribbon_stETH_Covered_Calls {
   //Interface with RBN token
    IERC20 RBN;
    address RBNaddress;
    ISTETH stETH;
    address DAO_Treasury;
    IRibbon rstETH_TV;
    IrstETH_Theta_Gauge rstETH_TGV; 
    
    /* Work to be done: LOL FUCK IF I KNOW/2022: 
      * Add to IRibbon interface the function to allow manual stETH re-entry into the contract: Done
      * Write a function to deposit stETH into the vault: Done
      * Write all of the various events required: not done
      *Implement these events: not done
    */
    constructor() {
        RBN = IERC20(0x6123B0049F904d730dB3C36a31167D9d4121fA6B); //RBN token address - double check before deploying
        RBNaddress = 0x6123B0049F904d730dB3C36a31167D9d4121fA6B;
        stETH = ISTETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84); //stETH address - double check before deploying
        DAO_Treasury = 0x7E3Ee99EC9b2aBd42c8c8504dc8195C8dc4942D0; // currently a testnet address - Change to the DAO Address
        rstETH_TV = IRibbon(0x53773E034d9784153471813dacAFF53dBBB78E8c); // Ribbon stETH Covered Call vault option
        rstETH_TGV = IrstETH_Theta_Gauge(0x4e079dCA26A4fE2586928c1319b20b1bf9f9be72); // Ribbon stETh Covered Call Gauge Token vault
    }

    // modifier to check if caller is the Tribe DAO or not
    modifier isDAO() {
        require(msg.sender == DAO_Treasury, "You aren't part of the DAO...");
        _;
    }

    /* This financial strategy has two layers to it. Like an onion, onions have layers.
    * The first layer consists of a deposit of raw ETH into the rstETH-Theta vault. The raw ETH is turned into stETH by RBN before depositing.
    * Now this stETH is sitting inside the rstETH-Theta vault in the form of rstETH-Theta. This is the first layer of investment. 
    * To enter the second layer of investment and earn more rewards requires calling the Stake function on the first layer contract.
    * The stake function sends the rstETH-Theta to the rstETH-Theta-Gauge vault and gives the sender rstETH-Theta-Gauge tokens. 
    * Now the investment is in its second layer and holding the rstETH-Theta-Gauge tokens allows the contract access to RBN rewards. 
    * To undo the investment requires first withdrawing from the second layer via calling the Withdraw function on the rstETH-Theta-Gauge contract.
    * Then to undo the first layer requires calling the InitializeWithdraw function before then calling the CompleteWithdraw function.
    * This contract does not go into the third layer where the claimed RBN rewards are locked for more returns.
    */

     //Now we get into the various helper funtions. All the Multi-step functions build ontop of these functions. 
     //Every helper function has an uppercase "H" as a prefix. These functions are not helper functions in the traditional sense, they can still affect your vault positions.
     //I will explain later why I decided to build all of these helper functions.

     function HlayerOneBalanceCheck() external view isDAO returns (uint256){
     uint256 balance = rstETH_TV.balanceOf(address(this));
      return balance;
    } //backend way to check our contract's balance of the rstETH-Theta token

    function HcheckVaultBalance() external isDAO view returns(uint256 _returnVal) {
      _returnVal = rstETH_TV.shares(msg.sender);
    } //helper function for obtaining the number of shares we have in layer one vault, independently available 
    
    function Hstake(uint256 sharesToStake) external isDAO { 
      rstETH_TV.stake(sharesToStake);
    } // stakes the shares we have in layer one and puts them ito layer two
  
    function HlayerOneWithdraw(uint256 amtToWithdraw) external isDAO {
      rstETH_TV.initiateWithdraw(amtToWithdraw);
    } //begin Layer One withdrawal process, marks your shares to be excluded from the next minting option.    \
    
    function HfinishLayerOneWithdraw() external isDAO {
      rstETH_TV.completeWithdraw();
    } //complete Layer One withdrawal process, can occur once the next vault option has been minted and your tokens were excluded - 10:00am UTC on Fridays
  
    function HlayerTwoBalanceCheck() external view isDAO returns (uint256){
     uint256 balance = rstETH_TGV.balanceOf(address(this));
     return balance;
    } // backend method to check our contract's balance of the rstETH-Theta-Gauge token

    function HlayerTwoWithdraw(uint256 _value, bool claim_rewards) external isDAO{
      rstETH_TGV.withdraw(_value, claim_rewards);
    } //withdraw from Layer Two - exchange rstETH-Theta-Gauge for rstETH-Theta
    
    function HlayerTwoDeposit(uint256 _value, address _addr, bool _claim_rewards) external isDAO { //make sure _addr is msg.sender
        rstETH_TGV.deposit(_value, _addr, _claim_rewards);
    } //this function is what is actually called on the Layer Two contract by the Stake function on Layer One (shares must be redeemed to call this function)
     //I am adding this for the rare but possible instance where the DAO has withdrawn from Layer Two and then wants to go back instead of continuing to withdraw from Layer one
    
    function HcheckClaimableRBNTokens() external isDAO returns (uint256 _returnVal){
        _returnVal = rstETH_TGV.claimable_tokens(msg.sender);
        return _returnVal;
   }//Check how much RBN token this contract can claim - this costs GAS, I'll explain why in a bit.
    //Only claim your rewards after the Epoch. Please. 

   function Hclaim_ze_rewardz() external isDAO{
     rstETH_TGV.claim_rewards();
   } //Claim our RBN rewards - Der Krieg ist verloren

  function Hsend_stETHtoDAO(uint256 amount) external isDAO{
   stETH.approve(DAO_Treasury, amount); //approve the treasury to receive our balance
   stETH.transferFrom(address(this), DAO_Treasury, amount); // transfer stETH from our address to the DAO treasury
   } //manually send an inputted amount of stETH to the DAO

  function HsendRBNtoDAO(uint256 amount) external isDAO {
    RBN.approve(DAO_Treasury, amount);
    RBN.transferFrom(address(this),DAO_Treasury, amount);
    }//Manually sends an inputted amount of RBN to the DAO

   /* <Primary Calls> 
   *These calls are intended to be used by the DAO for simplicity's sake by stacking as many Layer One and Layer Two functions into one single action
   * I understand that having all the different helper functions increase initial contract deployment cost simply because there are more characters for the EVM to gas profile, let alone stacking pre-built functions.
   * However, I felt it prudent to leave the oppurtunity to call functions step-by-step if neccessary, instead of leaving a crucial function within a multi-step call.
   *This also makes the DAO's investment strategy more tailorable and able to shift from Layer One to Layer Two and back. 
   */  
     //These are the functions I've prepared for streamline usage of this contract
  
    function LetsBegin_DepositETH() external isDAO payable { //NOTE NOTE NOTE: Investigate how payable functions work
      rstETH_TV.depositETH(); 
      //Event here saying ETH was deposited.
    } //deposits the ETH into the RBN contract and create the first layer

    function DepositstETH() external isDAO payable { //NOTE NOTE NOTE: Investigate how payable functions work
     uint256 stETHbal = stETH.balanceOf(address(this));
     rstETH_TV.depositYieldToken(stETHbal); 
      //Event here saying ETH was deposited.
    } //deposits stETH into the vault, gets you the same place as depositing ETH
    //if the DAO withdraws and then decides to go back, the assets originally used are now stETH, so we use this function to redeposit stETH

    function stakeNow() external isDAO {
      uint256 _balance = this.HcheckVaultBalance();
      require(_balance != 0, 'There is no balance within the vault yet.');    
        this.Hstake(_balance);
        //Event here to say that staking occured
    } // If we have a balance within the RBN vault, stake it.

    function BeginWithdrawing() external isDAO {
      uint256 _balance = this.HlayerTwoBalanceCheck(); // check our balance
      this.HlayerTwoWithdraw(_balance, true);  //withdraw our balance from the second layer
      this.HlayerOneWithdraw(_balance); //Begin our withdrawal process from the first layer
      //Event to say we began withdrawing
    }//First withdraw our balance from the second layer. Then begin withdrawing from the first layer

    // *Important*, only call this when the next vault option was minted with your shares excluded.
    function CompleteWithdrawingAndRetrieveSTETH() external isDAO { 
      this.HfinishLayerOneWithdraw();
      uint256 _balanceOfstETH = stETH.balanceOf(address(this)); // check our stETH balance
      this.Hsend_stETHtoDAO(_balanceOfstETH); // send the stETH balance to the DAO
      //Event to say that we completedthewithdrawing
    } //Finishes the withdrawal process

    function Claim_RBN_Rewards() external isDAO{
      uint256 tokenBal = this.HcheckClaimableRBNTokens();
      require(tokenBal != 0, "There are no claimable rewards");
      this.Hclaim_ze_rewardz(); //Hans look, I am ze German man now - claim our eligible rewards
      uint256 RBNbalance = RBN.balanceOf(address(this)); //just because I'm paranoid, check our new RBN token balance
      this.HsendRBNtoDAO(RBNbalance); //send our new RBN token balance to the DAO
      //Event to say we claimed the RBN rewards
    } //Check to see if we have any available RBN rewards and then claim them if we do
    //I have explained this next to the Helper function and I'll say it again.....
    //Don't call this function for no damn reason. Ribbon token rewards are granted on specific dates and times known as Epochs
    //Only claim your rewards after the Epoch. Please. Or else you just waste gas.
}

interface IRibbon { //Interface with the ribbon contract
  //Deposit - deposit ETH to be minted into vault shares, - Layer 1
  function depositETH() external payable;

  //Deposits stETH into the vault - uint256 is the amount
  function depositYieldToken(uint256) external;

 //RibbonVault.shares - get the # of shares we have in the vault - Layer 1
  //NOTE: this function is placeholder until confirmation that this is the proper way to read a readable value?
  function shares(address) external view returns (uint256);

 //Stake - stake the shares into the rstETH-Theta-Gauge vault, you receive rstETH-Theta-Gauge - Layer 1
  function stake(uint256) external;

 //InitializeWithdraw - begins the withdrawal process, marks your shares to not be included in the next option round (occurs at 10:00 am UTC) - Layer 1
  function initiateWithdraw(uint256) external;

 //CompleteWithdraw - finishes the withdrawal process, only callabled after you initialized the withdrawl and the option round has concluded - Layer 1
  function completeWithdraw() external;

 //balanceOf - checks our balance of rstETH-Theta if the shares are redeemed (not inside the vault), shares recently withdrawn from staking program will not be inside the vault - making this neccessary
  function balanceOf(address) external view returns (uint256);

 //redeem - redeems the tokens from the vault for this contract to hold its rstETH-Theta directly (function exists just in case)
 function redeem(uint256) external;

 //maxRedeem - redeems the maximum amount of tokens from the vault
 function maxRedeem() external ;
}

interface IrstETH_Theta_Gauge {  //Interfacing with rstETH-Theta-Gauge - this contract is written in Vyper...fuck me 
    //balanceOf - checks to see the current balance of rstETH-Theta-Gauge tokens
    function balanceOf(address) external view returns (uint256);

    //Withdraw - takes your rstETH-Theta-Gauge and burns it, giving you your rstETH-Theta back. Layer 2 withdrawal.
    function withdraw(uint256, bool) external; 
    
    //See what we can actually claim, it isn't a views function because of a "bug"(more like a mistake) in the Ribbon Gauge contract
    //They get around it by using the frontend .callStatic method. We don't get to do this because this is all backend baby. So it costs some gas to see our rewards.
    function claimable_tokens(address) external returns (uint256);

    //ClaimRewards - claiming the RBN rewards
      function claim_rewards() external;

    //Deposit - the function that allows the user to deposit into the Gauge vault - called by the "Stake" function in Layer one
    function deposit(uint256 _value, address _addr, bool _claim_rewards) external;  //value = number of tokens depositing, address of depositer, do you claim any pending rewards on rst-ETH-Theta-Gauge?
    //No need to be uncomfortable with how this one works because I found it on the Layer One contract's interface to the layer two contract
}

  interface ISTETH { //Ribbon allows you to put in raw ETH but withdrawing gives you stETH, so we need to be able to move that stETH out
    function getBufferedEther(uint256 _amount) external view returns (uint256);
    function getPooledEthByShares(uint256 _amount)
        external
        view
        returns (uint256);
    function getSharesByPooledEth(uint256 _amount)
        external
        view
        returns (uint256);
    function submit(address _referralAddress)
        external
        payable
        returns (uint256);
    function withdraw(uint256 _amount, bytes32 _pubkeyHash)
        external
        returns (uint256);
    function approve(address _recipient, uint256 _amount)
        external
        returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function decimals() external view returns (uint256);
    function getTotalShares() external view returns (uint256);
    function getTotalPooledEther() external view returns (uint256);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
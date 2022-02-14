/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


interface ISynth {
    function mint(address account,uint256 amount) external returns (bool);
    function burn(address account,uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function chainlinkPrice() external view returns (uint256);
    function _SynthPrice() external view returns (uint256);

}

interface ISACXToken {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    //function gonsForBalance( uint amount ) external view returns ( uint );
   // function balanceForGons( uint gons ) external view returns ( uint );
}

library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract SACXStaking{

    using SafeMath for uint256;

    ISACXToken public SACXToken;
    uint256 public collatteralRatio = 750;
    mapping (address => Staker) public StakerInfo;
    uint256 public SACXprice;
    uint256 public Synthprice;
    mapping (address => bool) public getSynthInfo;
    address[] public synths_addr;



    /*uint256 public Fee = 1; // default is 0.01% of Harvesting Reward. 
    // % of Harvest Amount
    // 10000 => 100%
    // 1000 => 10%
    // 100 => 1%
    // 10 => 0.1%
    // 1 => 0.01%
    struct Stake 
    {
        uint deposit;
        uint gons;
    }
    mapping( address => Stake ) public StakeInfo;*/
    
    
   
   
    event Transfer(address indexed from, address indexed to, uint256 value);


      struct Staker{ 
        uint256 TotalSACXStakedasCollateral; 
    }
    
   
    constructor(ISACXToken tokenaddress) public{
         SACXToken= tokenaddress;      
    }


//function stakes the SACX token as collateral and mints synths by calculating 
//the respective prices
     function stakeSACX(address _synth, uint256 amount) external  {
        ISynth synthToken1 = GetSynthInfo(_synth);
        uint256 synthPriceinUSD=synthToken1 ._SynthPrice();//price of 1 synth e.g 1 sETH =100$
        uint256 totalsynthprice=synthPriceinUSD.mul(amount);//price of 10 synth e.g 10 sETH = 1000$
        uint256 collatteralPrice = (totalsynthprice.mul((collatteralRatio.mul(1 ether)).div(100))).div(1 ether);//price of the collateral we need to stake
        uint256 stprice=getSACXPRICE();//price of 1 SACX
        uint256 collatteralToStake=((collatteralPrice.mul(1 ether)).div(stprice)).div(1 ether);//amount of SACX that will be staked according to price
        require(SACXToken.balanceOf(msg.sender) >= collatteralToStake,"User does not have sufficient SACX to Mint synths");
        SACXToken.transferFrom(msg.sender,address(this),collatteralToStake);
        StakerInfo[msg.sender].TotalSACXStakedasCollateral= StakerInfo[msg.sender].TotalSACXStakedasCollateral.add(collatteralToStake);
        synthToken1.mint(msg.sender,amount);  

        /*StakeInfo[msg.sender] = Stake({
            deposit: StakeInfo[msg.sender].deposit.add(collatteralToStake),
            gons: StakeInfo[msg.sender].gons.add(sACX.gonsForBalance(collatteralToStake))
        }); */
        
    }



//function unstakes SACX for a given amount of synth provided by user
   function UnstakeSACX(address _synth, uint256 amount) external
   {
      uint256 usdprice=synthUSDvalue(_synth,amount);
      ISynth synthToken1 = ISynth(GetSynthInfo(_synth));
      uint256 TotalstakedSacx=totalSACX();
      uint256 totalsynthusd=totalDollarprice();
      uint256 usergets=(((usdprice.mul(1 ether)).div(totalsynthusd)).mul(TotalstakedSacx)).div(1 ether);
      SACXToken.transfer(msg.sender,usergets);//to comment this and use  _unstake
     // _unstake(msg.sender,usergets); //open this later
      synthToken1.burn(msg.sender,amount); 
   }

/*function _unstake(address _recipient,uint256 _amount)public
    {
        uint256 amount_in_gons = sACX.gonsForBalance(_amount);
        StakeInfo[_recipient].deposit = StakeInfo[_recipient].deposit.sub(_amount);
        StakeInfo[_recipient].gons = StakeInfo[_recipient].gons.sub(amount_in_gons);
         SACXToken.transfer(_recipient, _amount);
    }

    function TotalReward(address _staker)public view returns (uint256 _reward)
    {
        uint256 oldBalance = StakeInfo[_staker].deposit;
        uint256 newBalance = sACX.balanceForGons(StakeInfo[_staker].gons);
        uint256 reward = newBalance.sub(oldBalance);
        return reward;
    }
    function harvestReward(address _recipient)public returns(uint256 _reward)
    {
        uint256 deposit = StakeInfo[_recipient].deposit;
        uint256 gons = StakeInfo[_recipient].gons;
        uint256 newbalance = sACX.balanceForGons(gons);
        uint256 reward = newbalance.sub(deposit);
        uint256 rewardInGons = sACX.gonsForBalance(reward);
        // Reward Deduction...
        uint256 fee = reward * Fee / 10000;
        uint256 updatedReward = reward - fee;
        sACX.transfer(_recipient, updatedReward);
        sACX.transfer(owner(), fee);
        // after transfer reward updating the gons stored against user.
        uint256 updatedGons = StakeInfo[_recipient].gons.sub(rewardInGons);
        Stake memory _updatedInfo = Stake({
            deposit : StakeInfo[_recipient].deposit,
            gons : updatedGons
        });
        StakeInfo[_recipient] = _updatedInfo;
        return _reward;
    }

    function setFee(uint256 _fee)public onlyOwner returns(bool success)
    {
        Fee = _fee * 100;
        return true;
    }*/


//returns the dollar price for an amount of synthetic asset
//e.g; *(1 sTSLA = 1$) so 100 sTSLA = 100$ 
   function synthUSDvalue(address  addr_2,uint256 amount) public view returns (uint256)
   {
    
     ISynth synthToken1 = GetSynthInfo(addr_2);
     uint256 synthvalue=synthToken1._SynthPrice();
     uint256 totalvalue=(amount.mul(synthvalue).mul(1 ether)).div(1 ether);
     return totalvalue;
      
   }



   //function returns the total amount of SACX tokens staked in the contract.
   function totalSACX() public view returns (uint256)
   {
     uint256 TACX=SACXToken.balanceOf(address(this));
     return TACX;
      
   }



//function returns the total amount of synthetic tokens minted 
//by adding total supply of each synth
   function totalsynths()public view returns(uint256){
     uint256 totaltokens;
for (uint256 i = 0; i < synths_addr.length; i++){
        ISynth synthToken1 = GetSynthInfo(synths_addr[i]);
        uint256 ts=synthToken1.totalSupply();
        totaltokens=totaltokens.add(ts);   
      }
      return totaltokens;
 
   }



   //returns the dollar value of total synthetic assets in the pool
   //e.g; total synths in pool= 200, dollar worth =300$
 function totalDollarprice()public view returns(uint256){
     uint256 dollarvalue;
     for (uint256 i = 0; i < synths_addr.length; i++){
        ISynth synthToken1 = GetSynthInfo(synths_addr[i]);
        uint256 ttokens=synthToken1.totalSupply();//total supply
        uint256 dv=synthToken1._SynthPrice();//dollar price of 1 synth token
        uint256 totalvalue=(ttokens.mul(dv).mul(1 ether)).div(1 ether);
        dollarvalue=dollarvalue.add(totalvalue);
      
     }
        
      return dollarvalue;
 
   }


 //function stores the synthetic asset addresses and info to use in the system
    function SetSynthInfo(address saddr) public {
        require(!getSynthInfo[saddr], "Synth is already existing");
        getSynthInfo[saddr]=true;
        synths_addr.push(saddr);              
    }
//function gets the synthetic asset addresses and info to use in the system
    function GetSynthInfo(address s_addr) public view returns(ISynth){
      require(getSynthInfo[s_addr], "Synth is does not exist");
      address addr_3;
        for (uint256 i = 0; i < synths_addr.length; i++){
         if(synths_addr[i] == s_addr)
         {
           addr_3=address(s_addr);
           break;
         }
        }
       return ISynth(addr_3);
    }

    //set the price of SACX token
    function setSACXPRICE(uint256 price) public {
        
        SACXprice=price;
    }
   
     function getSACXPRICE() public  view returns(uint256){
        return SACXprice;
        
    }
    
  

    

  
}
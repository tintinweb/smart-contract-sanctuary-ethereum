/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.5;


interface Isynth {
    function mint(address account,uint256 amount) external returns (bool);
    function burn(address account,uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function chainlinkPrice() external view returns (uint256);
    function SynthPrice() external view returns (uint256);
    function synthToUsd(uint256 amount) external view returns (uint256);
    function usdToSynth(uint256 amount) external view returns (uint256);

}

interface IPrice
{
  function usdToAcx(uint256 _amount)external view returns (uint256 tokens);
  function AcxToUsd(uint256 _amount)external view returns (uint256 usd);

}
interface IsacxToken{

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
    
    
    function SACXTowSACX( uint _amount ) external view returns ( uint );


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
contract SacxStaking{

    using SafeMath for uint256;

    IsacxToken public WsacxToken;
    IPrice public priceContract;
    uint256 public collatteralRatio = 750;
    mapping (address => bool) public getSynthInfo;
    address[] public synthAddresses;
    uint256 public StakedCollateral;
    uint256 public synthCount;

    event Transfer(address indexed from, address indexed to, uint256 value);


    
   
    constructor(IsacxToken _wrappedAddress, IPrice priceAddress){
         WsacxToken= _wrappedAddress;    
         priceContract=priceAddress;

    }

     
     function StakeSacx(address _synth, uint256 _amount) external  {
       require(getSynthInfo[_synth], "Synth is does not exist");
        Isynth synthToken = Isynth(_synth);
        uint256 TotalSynthPrice=synthToken.synthToUsd(_amount);
        uint256 collatteralPrice = ((TotalSynthPrice.mul(collatteralRatio)).div(100));
        uint256 CollatteralToStake= SacxToWsacx(collatteralPrice);
        require(WsacxToken.balanceOf(msg.sender) >= CollatteralToStake,"User does not have sufficient Sacx to mint synths");
        WsacxToken.transferFrom(msg.sender,address(this),CollatteralToStake);
        StakedCollateral=StakedCollateral.add(CollatteralToStake);
        synthToken.mint(msg.sender,_amount);             
    }
  

   function UnstakeSacx(address _synth, uint256 _amount) external
   {
     require(getSynthInfo[_synth], "Synth is does not exist");
      uint256 UsdPrice=SynthUsdValue(_synth,_amount);
      Isynth synthToken = Isynth(_synth);
      uint256 TotalStakedSacx=totalSacx();
      uint256 TotalSynthUsd=totalDollarprice();
      uint256 UserGets=((((UsdPrice.mul(10**9)).div(TotalSynthUsd)).mul(TotalStakedSacx)).div(10**9));
      WsacxToken.transfer(msg.sender,UserGets);
      StakedCollateral=StakedCollateral.sub(UserGets);
      synthToken.burn(msg.sender,_amount); 
   }
  
   function SynthUsdValue(address  synthAddr,uint256 amount) public view returns (uint256)
   {
     require(getSynthInfo[synthAddr], "Synth is does not exist");
     Isynth synthToken = Isynth(synthAddr);
     uint256 totalValue=synthToken.synthToUsd(amount);
     return totalValue;
      
   }
  
   function totalSacx() public view returns (uint256)
   {
     return StakedCollateral;
      
   }

 function setCollateral(uint256 CollateralPercetage) public 
   {
      collatteralRatio=CollateralPercetage;
   }

   function totalSynths()public view returns(uint256){
        uint256 totalTokens;
         for (uint256 i = 0; i < synthAddresses.length; i++){
       require(getSynthInfo[synthAddresses[i]], "Synth is does not exist");
        Isynth synthToken = Isynth(synthAddresses[i]);
        uint256 TotalSynthSupply=synthToken.totalSupply();
        totalTokens=totalTokens.add(TotalSynthSupply);   
      }
      return totalTokens;
 
   }
 function totalDollarprice()public view returns(uint256){
     uint256 dollarvalue;
     for (uint256 i = 0; i < synthAddresses.length; i++){
       require(getSynthInfo[synthAddresses[i]], "Synth is does not exist");
        Isynth synthToken =  Isynth(synthAddresses[i]);
        uint256 totalTokens=synthToken.totalSupply();
        uint256 DollarPrice=synthToken.synthToUsd(totalTokens);
        dollarvalue=dollarvalue.add(DollarPrice);
      
     }
        
      return dollarvalue;
 
   }


    function SetSynthInfo(address synthAddress) public {
        require(!getSynthInfo[synthAddress], "Synth is already existing");
        getSynthInfo[synthAddress]=true;
        synthAddresses.push(synthAddress); 
        synthCount++;

    }

  
      function SacxToWsacx(uint256 amount) public view returns (uint256) {
      uint256 _Sacx=priceContract.usdToAcx(amount.mul(10**9));
      uint256 WsacxAmount = WsacxToken.SACXTowSACX(_Sacx);
      return  WsacxAmount;
    
  }
 
   
}
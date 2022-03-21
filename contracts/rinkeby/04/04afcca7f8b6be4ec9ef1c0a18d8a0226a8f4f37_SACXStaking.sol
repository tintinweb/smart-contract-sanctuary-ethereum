/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


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
interface IFactory
{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface ILpToken
{
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns ( address );
    function token1() external view returns ( address );
}
interface IRouter
{
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
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
contract SACXStaking{

    using SafeMath for uint256;

    IsacxToken public WsacxToken;
    uint256 public collatteralRatio = 750;
    mapping (address => Staker) public StakerInfo;
    uint256 public WsacxPrice;
    uint256 public Synthprice;
    mapping (address => bool) public getSynthInfo;
    address[] public synthAddresses;
    uint256 public StakedCollateral;
    address public Factory=address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public Router=address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public ACXtokenAddress;
    uint256 public synthCount;

    event Transfer(address indexed from, address indexed to, uint256 value);


      struct Staker{ 
        uint256 TotalSacxStakedAsCollateral; 
    }
    
   
    constructor(IsacxToken wrappedAddress,address acxToken){
         WsacxToken= wrappedAddress;    
         ACXtokenAddress=acxToken;
    }


//function stakes the SACX token as collateral and mints synths by calculating 
//the respective prices
     function StakeSacx(address _synth, uint256 amount) external  {
        Isynth synthToken1 = GetSynthInfo(_synth);
        uint256 TotalSynthPrice=synthToken1.synthToUsd(amount);//synthPriceinUSD.mul(amount);//price of 10 synth e.g 10 sETH = 1000$
        uint256 collatteralPrice = ((TotalSynthPrice.mul(collatteralRatio)).div(100));//price of the collateral we need to stake
        uint256 CollatteralToStake= usdToWsacx(collatteralPrice);//price of 1 SACX
        require(WsacxToken.balanceOf(msg.sender) >= CollatteralToStake,"User does not have sufficient SACX to Mint synths");
        WsacxToken.transferFrom(msg.sender,address(this),CollatteralToStake);
        StakedCollateral=StakedCollateral.add(CollatteralToStake);
        StakerInfo[msg.sender].TotalSacxStakedAsCollateral= StakerInfo[msg.sender].TotalSacxStakedAsCollateral.add(CollatteralToStake);
        synthToken1.mint(msg.sender,amount);     
        
    }
  
//function unstakes SACX for a given amount of synth provided by user
   function UnstakeSacx(address _synth, uint256 amount) external
   {
      uint256 UsdPrice=SynthUsdValue(_synth,amount);
      Isynth synthToken1 = Isynth(GetSynthInfo(_synth));
      uint256 TotalStakedSacx=totalSacx();
      uint256 TotalSynthUsd=totalDollarprice();
      uint256 UserGets=(UsdPrice.div(TotalSynthUsd)).mul(TotalStakedSacx);
      WsacxToken.transfer(msg.sender,UserGets);
      StakerInfo[msg.sender].TotalSacxStakedAsCollateral= StakerInfo[msg.sender].TotalSacxStakedAsCollateral.sub(UserGets);
      StakedCollateral=StakedCollateral.sub(UserGets);
      synthToken1.burn(msg.sender,amount); 
   }

//returns the dollar price for an amount of synthetic asset
//e.g; *(1 sTSLA = 1$) so 100 sTSLA = 100$ 
   function SynthUsdValue(address  synthAddr,uint256 amount) public view returns (uint256)
   {
    
     Isynth synthToken1 = GetSynthInfo(synthAddr);
     uint256 totalValue=synthToken1.synthToUsd(amount);
     return totalValue;
      
   }
   function UsdToSynth (address  synthAddr,uint256 amount) public view returns (uint256) {
     Isynth synthToken1 = GetSynthInfo(synthAddr);
     uint256 totalValue=synthToken1.usdToSynth (amount);
      return totalValue;
  }



   //function returns the total amount of SACX tokens staked in the contract.
   function totalSacx() public view returns (uint256)
   {
     //uint256 TotalStakedSacx=SacxToken.balanceOf(address(this));
     return StakedCollateral;
      
   }



//function returns the total amount of synthetic tokens minted 
//by adding total supply of each synth
   function totalSynths()public view returns(uint256){
     uint256 totalTokens;
for (uint256 i = 0; i < synthAddresses.length; i++){
        Isynth synthToken1 = GetSynthInfo(synthAddresses[i]);
        uint256 TotalSynthSupply=synthToken1.totalSupply();
        totalTokens=totalTokens.add(TotalSynthSupply);   
      }
      return totalTokens;
 
   }

   //returns the dollar value of total synthetic assets in the pool
   //e.g; total synths in pool= 200, dollar worth =300$
 function totalDollarprice()public view returns(uint256){
     uint256 dollarvalue;
     for (uint256 i = 0; i < synthAddresses.length; i++){
        Isynth synthToken1 = GetSynthInfo(synthAddresses[i]);
        uint256 totalTokens=synthToken1.totalSupply();//total supply
        uint256 DollarPrice=synthToken1.synthToUsd(totalTokens);//dollar price of 1 synth token
        dollarvalue=dollarvalue.add(DollarPrice);
      
     }
        
      return dollarvalue;
 
   }


 //function stores the synthetic asset addresses and info to use in the system
    function SetSynthInfo(address synthAddress) public {
        require(!getSynthInfo[synthAddress], "Synth is already existing");
        getSynthInfo[synthAddress]=true;
        synthAddresses.push(synthAddress); 
        synthCount++;

    }
//function gets the synthetic asset addresses and info to use in the system
    function GetSynthInfo(address synthAddress) public view returns(Isynth){
      require(getSynthInfo[synthAddress], "Synth is does not exist");
      address _address;
        for (uint256 i = 0; i < synthAddresses.length; i++){
        if(synthAddresses[i] == synthAddress)
         {
           _address=address(synthAddress);
           break;
         }
        }
       return Isynth(_address);
    }

    //set the price of SACX token
    function SetWsacxPrice(uint256 price) public {
        
        WsacxPrice=price;
    }
   
     //function getSacxPrice() public  view returns(uint256){
       function getWsacxPrice( address _token, uint _amount ) public view returns ( uint value_ ) 
    {
        uint112 _customTokenReserve;
        uint112 _busdTokenReserve;
        uint32 _blockTimestampLast;
        
           address LpToken = IFactory(Factory).getPair(_token,0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735);
           require(LpToken != address(0));
           if(ILpToken(LpToken).token0() == _token)
           {
            (_customTokenReserve, _busdTokenReserve, _blockTimestampLast) = ILpToken(LpToken).getReserves();
            value_ = IRouter(Router).quote(_amount, _customTokenReserve, _busdTokenReserve);
            return value_;
           }
           else
           {
            (_busdTokenReserve, _customTokenReserve, _blockTimestampLast) = ILpToken(LpToken).getReserves();
            value_ = IRouter(Router).quote(_amount, _customTokenReserve, _busdTokenReserve);
            return value_;
            }
  

       // return SacxPrice;
        
    }
     function WsacxToUsd(uint256 amount) public returns (uint256) {
      uint256 _WsacxPrice=getWsacxPrice(ACXtokenAddress,amount);
      WsacxPrice=_WsacxPrice.div(10**9);
      
      return amount.mul(WsacxPrice).div(10 ** 9);
  }

      function usdToWsacx(uint256 amount) public returns (uint256) {
     
      uint256 _WsacxPrice=getWsacxPrice(ACXtokenAddress,amount);
      WsacxPrice=_WsacxPrice.div(10**9);
      uint256 SacxAmount=amount.mul(10 ** 9).div(WsacxPrice);
      uint256 WsacxAmount = WsacxToken.SACXTowSACX(SacxAmount);
      return  WsacxAmount;
    
  }
   
}
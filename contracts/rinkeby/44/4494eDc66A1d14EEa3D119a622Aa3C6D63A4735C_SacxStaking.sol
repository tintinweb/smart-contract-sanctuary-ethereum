/**
 *Submitted for verification at Etherscan.io on 2022-03-31
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
contract SacxStaking{

    using SafeMath for uint256;

    IsacxToken public WsacxToken;
    uint256 public collatteralRatio = 750;
    mapping (address => Staker) public StakerInfo;
    uint256 public WsacxPrice;
    mapping (address => bool) public getSynthInfo;
    address[] public synthAddresses;
    uint256 public StakedCollateral;
    address public Factory;
    address public Router;
    address public AcxTokenAddress;
    address public DaiTokenAddress;
    uint256 public synthCount;

    event Transfer(address indexed from, address indexed to, uint256 value);


      struct Staker{ 
        uint256 TotalSacxStakedAsCollateral; 
    }
    
   
    constructor(IsacxToken _wrappedAddress,address _acxToken, address _daiToken,address _factory, address _router){
         WsacxToken= _wrappedAddress;    
         AcxTokenAddress=_acxToken;
         DaiTokenAddress=_daiToken;
         Factory=_factory;
         Router=_router;

    }

     
     function StakeSacx(address _synth, uint256 _amount) external  {
        Isynth synthToken = GetSynthInfo(_synth);
        uint256 TotalSynthPrice=synthToken.synthToUsd(_amount);
        uint256 collatteralPrice = ((TotalSynthPrice.mul(collatteralRatio)).div(100));
        uint256 CollatteralToStake= SacxToWsacx(collatteralPrice);
        require(WsacxToken.balanceOf(msg.sender) >= CollatteralToStake,"User does not have sufficient Sacx to mint synths");
        WsacxToken.transferFrom(msg.sender,address(this),CollatteralToStake);
        StakedCollateral=StakedCollateral.add(CollatteralToStake);
        StakerInfo[msg.sender].TotalSacxStakedAsCollateral= StakerInfo[msg.sender].TotalSacxStakedAsCollateral.add(CollatteralToStake);
        synthToken.mint(msg.sender,_amount);             
    }
  

   function UnstakeSacx(address _synth, uint256 _amount) external
   {
      uint256 UsdPrice=SynthUsdValue(_synth,_amount);
      Isynth synthToken = Isynth(GetSynthInfo(_synth));
      uint256 TotalStakedSacx=totalSacx();
      uint256 TotalSynthUsd=totalDollarprice();
      uint256 UserGets=(UsdPrice.div(TotalSynthUsd)).mul(TotalStakedSacx);
      WsacxToken.transfer(msg.sender,UserGets);
      StakerInfo[msg.sender].TotalSacxStakedAsCollateral= StakerInfo[msg.sender].TotalSacxStakedAsCollateral.sub(UserGets);
      StakedCollateral=StakedCollateral.sub(UserGets);
      synthToken.burn(msg.sender,_amount); 
   }
  
   function SynthUsdValue(address  synthAddr,uint256 amount) public view returns (uint256)
   {
    
     Isynth synthToken = GetSynthInfo(synthAddr);
     uint256 totalValue=synthToken.synthToUsd(amount);
     return totalValue;
      
   }
   function UsdToSynth (address  synthAddr,uint256 amount) public view returns (uint256) {
     Isynth synthToken = GetSynthInfo(synthAddr);
     uint256 totalValue=synthToken.usdToSynth (amount);
      return totalValue;
  }




   function totalSacx() public view returns (uint256)
   {
     return StakedCollateral;
      
   }



   function totalSynths()public view returns(uint256){
     uint256 totalTokens;
for (uint256 i = 0; i < synthAddresses.length; i++){
        Isynth synthToken = GetSynthInfo(synthAddresses[i]);
        uint256 TotalSynthSupply=synthToken.totalSupply();
        totalTokens=totalTokens.add(TotalSynthSupply);   
      }
      return totalTokens;
 
   }
 function totalDollarprice()public view returns(uint256){
     uint256 dollarvalue;
     for (uint256 i = 0; i < synthAddresses.length; i++){
        Isynth synthToken = GetSynthInfo(synthAddresses[i]);
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
  
  function getSacx( address _Token0, address _Token1, uint _amount ) public view returns ( uint value ) 
    {
        uint112 Token1Reserve;
        uint112 Token0Reserve;
        uint32 _blockTimestampLast;
        uint256 amountAcx;
        
           address LpToken = IFactory(Factory).getPair(_Token0, _Token1);
           require(LpToken != address(0));
           if(ILpToken(LpToken).token0() == _Token0)
           {
            (Token0Reserve, Token1Reserve, _blockTimestampLast) = ILpToken(LpToken).getReserves();
            amountAcx = IRouter(Router).quote(_amount, Token0Reserve, Token1Reserve);
            return amountAcx;
           }


           {
            (Token1Reserve, Token0Reserve, _blockTimestampLast) = ILpToken(LpToken).getReserves();
            amountAcx = IRouter(Router).quote(_amount, Token0Reserve, Token1Reserve);
            return amountAcx;
            }
      
    }
     
      function SacxToWsacx(uint256 amount) internal view returns (uint256) {
      uint256 _Sacx=getSacx(DaiTokenAddress,AcxTokenAddress,amount.mul(10**9));
      uint256 WsacxAmount = WsacxToken.SACXTowSACX(_Sacx);
      return  WsacxAmount;
    
  }
 
   
}
/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.5;
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
contract Price {

   address public immutable Factory;
   address public immutable Router;
   address public AcxTokenAddress;
   address public DaiTokenAddress;

    constructor(address _factory, address _router ,address _acxToken, address _daiToken){
       
       Factory=_factory;
        Router=_router;
        AcxTokenAddress=_acxToken;
        DaiTokenAddress=_daiToken;
    }
    function usdToAcx(uint256 _amount)public view returns (uint256 tokens)
    {
        // input USD and return ACX
        uint256 _usd;
        uint256 _acx;
        uint256 _blockTimestampLast;
        uint256 amountAcx;
        address LpToken = IFactory(Factory).getPair(DaiTokenAddress, AcxTokenAddress);
        require(LpToken != address(0));
        if(ILpToken(LpToken).token0() == DaiTokenAddress)
        {
            (_usd, _acx, _blockTimestampLast) = ILpToken(LpToken).getReserves();
            amountAcx = IRouter(Router).quote(_amount, _usd, _acx);
            return amountAcx;
        }
        else
        {
            (_acx, _usd, _blockTimestampLast) = ILpToken(LpToken).getReserves();
            amountAcx = IRouter(Router).quote(_amount, _usd, _acx);
            return amountAcx;
        }
    }

     function AcxToUsd(uint256 _amount)public view returns (uint256 usd)
    {
        // input amount ACX and return USD...
        uint256 _usd;
        uint256 _acx;
        uint256 _blockTimestampLast;
        uint256 amountUsd;
        address LpToken = IFactory(Factory).getPair(DaiTokenAddress,AcxTokenAddress);
        require(LpToken != address(0));
        if(ILpToken(LpToken).token0() == AcxTokenAddress)
        {
            (_acx, _usd, _blockTimestampLast) = ILpToken(LpToken).getReserves();
            amountUsd = IRouter(Router).quote(_amount, _acx, _usd);
            return amountUsd;
        }
        else
        {
            (_usd, _acx, _blockTimestampLast) = ILpToken(LpToken).getReserves();
            amountUsd = IRouter(Router).quote(_amount, _acx, _usd);
            return amountUsd;
        }
    }

  
}
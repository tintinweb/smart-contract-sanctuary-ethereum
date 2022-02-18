// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Treasury.sol";
import './SafeMath.sol';

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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
}


contract TreasuryV2 is OlympusTreasury
{
    using SafeMath for uint;

    address[] public customTokens; // Push only, beware false-positives.
    mapping( address => bool ) public isCustomToken;
    
    address[] public customDepositors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isCustomDepositor;
 
    address[] public customSpenders; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isCustomSpender;

    address public Factory;
    address public Router;
    address public DAI;

    constructor (
        address _OHM,
        address _DAI,
        address _factory,
        address _router
    ) OlympusTreasury(_OHM, _DAI) 
    {
       Factory = _factory;
       Router = _router;
       DAI = _DAI;
    }
    function valueOf( address _token, uint _amount ) public override view returns ( uint value_ ) 
    {
        uint112 _customTokenReserve;
        uint112 _busdTokenReserve;
        uint32 _blockTimestampLast;
        if ( isCustomToken[ _token ] )
        {
           address LpToken = IFactory(Factory).getPair(_token, DAI);
           require(LpToken != address(0));
           if(ILpToken(LpToken).token0() == _token)
           {
            (_customTokenReserve, _busdTokenReserve, _blockTimestampLast) = ILpToken(LpToken).getReserves();
            value_ = IRouter(Router).getAmountOut(_amount, _customTokenReserve, _busdTokenReserve);
           }
           else
           {
            (_busdTokenReserve, _customTokenReserve, _blockTimestampLast) = ILpToken(LpToken).getReserves();
            value_ = IRouter(Router).getAmountOut(_amount, _customTokenReserve, _busdTokenReserve);
            }
        }
        else
        {
            return super.valueOf(_token, _amount);
        }
    }
    
        function settings( MANAGING _managing, address _address, address _calculator) external onlyOwner() returns ( bool ) {
        require( _address != address(0) );
        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { // 0
            reserveDepositors.push( _address );
            isReserveDepositor[_address] = true;
        } else if ( _managing == MANAGING.RESERVESPENDER ) { // 1
            reserveSpenders.push( _address );
            isReserveSpender[_address] = true;
        } else if ( _managing == MANAGING.RESERVETOKEN ) { // 2
            reserveTokens.push( _address );
            isReserveToken[_address] = true;
        } else if ( _managing == MANAGING.RESERVEMANAGER ) { // 3
            reserveManagers.push( _address );
            isReserveManager[_address] = true;
        } else if ( _managing == MANAGING.LIQUIDITYDEPOSITOR ) { // 4
            liquidityDepositors.push( _address );
            isLiquidityDepositor[_address] = true;
        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) { // 5
            bondCalculator = _calculator;
            liquidityTokens.push( _address );
            isLiquidityToken[_address] = true;
        } else if ( _managing == MANAGING.LIQUIDITYMANAGER ) { // 6
            liquidityManagers.push( _address );
            isLiquidityManager[_address] = true;
        } else if ( _managing == MANAGING.REWARDMANAGER ) { // 7
            rewardManagers.push( _address );
            isRewardManager[_address] = true;
        } else if ( _managing == MANAGING.SOHM ) { // 8
            sOHM = _address;
        } else if (_managing == MANAGING.CUSTOMTOKENDEPOSITOR){ // 9
            customDepositors.push( _address );
            isCustomDepositor[_address] = true;
        }else if(_managing == MANAGING.CUSTOMTOKEN){ // 10
           customTokens.push( _address );
           isCustomToken[_address] = true;
        }else if(_managing == MANAGING.CUSTOMTOKENSPENDER){ // 11
           customSpenders.push( _address );
           isCustomSpender[_address] = true;
        }
        else
        return false;
        emit ChangeQueued( _managing, _address );
        return true;
    }

}
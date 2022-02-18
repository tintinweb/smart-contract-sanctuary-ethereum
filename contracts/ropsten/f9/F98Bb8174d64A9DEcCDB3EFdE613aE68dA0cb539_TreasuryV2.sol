// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Treasury.sol";
import './SafeMath.sol';

contract TreasuryV2 is OlympusTreasury
{
    using SafeMath for uint;

    address[] public customTokens; // Push only, beware false-positives.
    mapping( address => bool ) public isCustomToken;
    mapping( address => uint ) public customTokenQueue; // Delays changes to mapping.

    address[] public customDepositors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isCustomDepositor;
    mapping( address => uint ) public customDepositorQueue; // Delays changes to mapping.

    address[] public customSpenders; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isCustomSpender;
    mapping( address => uint ) public customSpenderQueue; // Delays changes to mapping.
    //address public poolCalculator;
    uint256 public tokenprice = 5000000000;
    
   // enum MANAGING { RESERVEDEPOSITOR, RESERVESPENDER, RESERVETOKEN, RESERVEMANAGER, LIQUIDITYDEPOSITOR, LIQUIDITYTOKEN, LIQUIDITYMANAGER, DEBTOR, REWARDMANAGER, SOHM, CUSTOMTOKENDEPOSITOR, CUSTOMTOKEN, CUSTOMTOKENSPENDER}

    constructor (
        address _OHM,
        address _DAI,
        uint _blocksNeededForQueue
    ) OlympusTreasury(_OHM, _DAI, _blocksNeededForQueue) 
    {
        
    }
    function valueOf( address _token, uint _amount ) public override view returns ( uint value_ ) 
    {
        if ( isCustomToken[ _token ] ) 
        {
           uint256 value = _amount.div(tokenprice);
           return value = (value * IERC20(OHM).decimals()).div(IERC20(_token).decimals());
        }
        else
        {
            super.valueOf(_token, _amount);
        }
    }
    
        function queue( MANAGING _managing, address _address ) external onlyOwner() returns ( bool ) {
        require( _address != address(0) );
        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { // 0
            reserveDepositorQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.RESERVESPENDER ) { // 1
            reserveSpenderQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.RESERVETOKEN ) { // 2
            reserveTokenQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.RESERVEMANAGER ) { // 3
            ReserveManagerQueue[ _address ] = block.number.add( blocksNeededForQueue.mul( 2 ) );
        } else if ( _managing == MANAGING.LIQUIDITYDEPOSITOR ) { // 4
            LiquidityDepositorQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) { // 5
            LiquidityTokenQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.LIQUIDITYMANAGER ) { // 6
            LiquidityManagerQueue[ _address ] = block.number.add( blocksNeededForQueue.mul( 2 ) );
        } else if ( _managing == MANAGING.DEBTOR ) { // 7
            debtorQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.REWARDMANAGER ) { // 8
            rewardManagerQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.SOHM ) { // 9
            sOHMQueue = block.number.add( blocksNeededForQueue );
        } else if (_managing == MANAGING.CUSTOMTOKENDEPOSITOR){ // 10
            customDepositorQueue[ _address ] = block.number.add( blocksNeededForQueue );
        }else if(_managing == MANAGING.CUSTOMTOKEN){ // 11
            customTokenQueue[ _address ] = block.number.add( blocksNeededForQueue );
        }else if(_managing == MANAGING.CUSTOMTOKENSPENDER){ //12
            customSpenderQueue[ _address ] = block.number.add( blocksNeededForQueue );
        }
        else
        return false;

        emit ChangeQueued( _managing, _address );
        return true;
    }

    /**
        @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @param _calculator address
        @return bool
     */
    function toggle( MANAGING _managing, address _address, address _calculator ) external onlyOwner() returns ( bool ) {
        require( _address != address(0) );
        bool result;
        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { // 0
            if ( requirements( reserveDepositorQueue, isReserveDepositor, _address ) ) {
                reserveDepositorQueue[ _address ] = 0;
                if( !listContains( reserveDepositors, _address ) ) {
                    reserveDepositors.push( _address );
                }
            }
            result = !isReserveDepositor[ _address ];
            isReserveDepositor[ _address ] = result;
            
        } else if ( _managing == MANAGING.RESERVESPENDER ) { // 1
            if ( requirements( reserveSpenderQueue, isReserveSpender, _address ) ) {
                reserveSpenderQueue[ _address ] = 0;
                if( !listContains( reserveSpenders, _address ) ) {
                    reserveSpenders.push( _address );
                }
            }
            result = !isReserveSpender[ _address ];
            isReserveSpender[ _address ] = result;

        } else if ( _managing == MANAGING.RESERVETOKEN ) { // 2
            if ( requirements( reserveTokenQueue, isReserveToken, _address ) ) {
                reserveTokenQueue[ _address ] = 0;
                if( !listContains( reserveTokens, _address ) ) {
                    reserveTokens.push( _address );
                }
            }
            result = !isReserveToken[ _address ];
            isReserveToken[ _address ] = result;

        } else if ( _managing == MANAGING.RESERVEMANAGER ) { // 3
            if ( requirements( ReserveManagerQueue, isReserveManager, _address ) ) {
                reserveManagers.push( _address );
                ReserveManagerQueue[ _address ] = 0;
                if( !listContains( reserveManagers, _address ) ) {
                    reserveManagers.push( _address );
                }
            }
            result = !isReserveManager[ _address ];
            isReserveManager[ _address ] = result;

        } else if ( _managing == MANAGING.LIQUIDITYDEPOSITOR ) { // 4
            if ( requirements( LiquidityDepositorQueue, isLiquidityDepositor, _address ) ) {
                liquidityDepositors.push( _address );
                LiquidityDepositorQueue[ _address ] = 0;
                if( !listContains( liquidityDepositors, _address ) ) {
                    liquidityDepositors.push( _address );
                }
            }
            result = !isLiquidityDepositor[ _address ];
            isLiquidityDepositor[ _address ] = result;

        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) { // 5
            if ( requirements( LiquidityTokenQueue, isLiquidityToken, _address ) ) {
                LiquidityTokenQueue[ _address ] = 0;
                if( !listContains( liquidityTokens, _address ) ) {
                    liquidityTokens.push( _address );
                }
            }
            result = !isLiquidityToken[ _address ];
            isLiquidityToken[ _address ] = result;
            bondCalculator[ _address ] = _calculator;

        } else if ( _managing == MANAGING.LIQUIDITYMANAGER ) { // 6
            if ( requirements( LiquidityManagerQueue, isLiquidityManager, _address ) ) {
                LiquidityManagerQueue[ _address ] = 0;
                if( !listContains( liquidityManagers, _address ) ) {
                    liquidityManagers.push( _address );
                }
            }
            result = !isLiquidityManager[ _address ];
            isLiquidityManager[ _address ] = result;

        } else if ( _managing == MANAGING.DEBTOR ) { // 7
            if ( requirements( debtorQueue, isDebtor, _address ) ) {
                debtorQueue[ _address ] = 0;
                if( !listContains( debtors, _address ) ) {
                    debtors.push( _address );
                }
            }
            result = !isDebtor[ _address ];
            isDebtor[ _address ] = result;

        } else if ( _managing == MANAGING.REWARDMANAGER ) { // 8
            if ( requirements( rewardManagerQueue, isRewardManager, _address ) ) {
                rewardManagerQueue[ _address ] = 0;
                if( !listContains( rewardManagers, _address ) ) {
                    rewardManagers.push( _address );
                }
            }
            result = !isRewardManager[ _address ];
            isRewardManager[ _address ] = result;

        } else if ( _managing == MANAGING.SOHM ) { // 9
            sOHMQueue = 0;
            sOHM = _address;
            result = true;

        } else if ( _managing == MANAGING.CUSTOMTOKENDEPOSITOR ) { // 10
            if ( requirements( customDepositorQueue, isCustomDepositor, _address ) ) {
                customDepositorQueue[ _address ] = 0;
                if( !listContains( customDepositors, _address ) ) {
                    customDepositors.push( _address );
                }
            }
            result = !isCustomDepositor[ _address ];
            isCustomDepositor[ _address ] = result;

        } else if ( _managing == MANAGING.CUSTOMTOKEN ) { // 11
            if ( requirements( customTokenQueue, isCustomToken, _address ) ) {
                customTokenQueue[ _address ] = 0;
                if( !listContains( customTokens, _address ) ) {
                    customTokens.push( _address );
                }
            }
            result = !isCustomToken[ _address ];
            isCustomToken[ _address ] = result;

        } else if ( _managing == MANAGING.CUSTOMTOKENSPENDER ) { // 12
            if ( requirements( customSpenderQueue, isCustomSpender, _address ) ) {
                customSpenderQueue[ _address ] = 0;
                if( !listContains( customSpenders, _address ) ) {
                    customSpenders.push( _address );
                }
            }
            result = !isCustomSpender[ _address ];
            isCustomSpender[ _address ] = result;
        } else return false;

        emit ChangeActivated( _managing, _address, result );
        return true;
    }

}
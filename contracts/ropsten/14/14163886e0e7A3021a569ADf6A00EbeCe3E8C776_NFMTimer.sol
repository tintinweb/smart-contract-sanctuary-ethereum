/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INTERFACES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmController {
    function _checkWLSC(address, address) external pure returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFMTimer.sol
/// @author Fernando Viktor Seidl E-mail: [email protected]
/// @notice This contract regulates all time events of the entire NFM ecosystem.
/// @dev This contract is structured in such a way that a time interval can be determined from when the logic should be initiated.
///           ***This lead time is used as a countdown for the ICO within the NFM Exchange..***
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMTimer {
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _Owner;
    INfmController public _Controller;
    address private _SController;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    TIME EVENTS

    _UV2_Swap_event                         => Automatic swap for the upcoming Add liquidity event is executed
    _UV2_Liquidity_event                     => Liquidity is automatically added to a Uniswap pool
    _UV2_Liquidity_event                     => Liquidity is automatically added to a Uniswap pool
    _UV2_RemoveLiquidity_event        => All LP tokens will be automatically redeemed step by step after 11 years.
    _DailyMint                                       => automatic daily minting.
    _BeginLogic                                    => Logic initialization timestamp
    _EndMint                                         => The end of the minting process is set at 8 years after initialization
    _ExtraBonusAll                                => Automatic distribution event to the NFM community for special currencies like WBTC, WBNB, ... resulting from earnings or profits.
    _ExtraBonusAllEnd                         => 24 hour time window for the bonus special payments
    _ExtraBonusAirdrop                                => Automatic distribution event to the NFM community for special currencies from the IDO LaunchPad.
    _ExtraBonusAirdropEnd                         => 24 hour time window for the Airdrop payments
    _StartBurn                                       => Time stamp for starting the burning process. Is set to 4 years after initialization
    _StartBuyBack                                => Timestamp for the start of the buyback program. Is set to 11 years after the end of the burning process.
    _SetUpLogicCountdown                 => Lead time until the logic is initialized

    _YearInterval = annual interval (3600 seconds * 24 hours * 30 days * 12 month)
    _DayInterval = day interval (3600 seconds * 24 hours)
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 private _UV2_Swap_event;
    uint256 private _UV2_Liquidity_event;
    uint256 private _UV2_RemoveLiquidity_event;
    uint256 private _DailyMint;
    uint256 private _BeginLogic;
    uint256 private _EndMint;
    uint256 private _ExtraBonusAll;
    uint256 private _ExtraBonusAllEnd;
    uint256 private _ExtraBonusAirdrop;
    uint256 private _ExtraBonusAirdropEnd;
    uint256 private _StartBurn;
    uint256 private _StartBuyBack;
    uint256 private _SetUpLogicCountdown;
    uint256 private _YearInterval = 3600 * 24 * 30 * 12;
    uint256 private _DayInterval = 3600 * 24;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MODIFIER
    onlyOwner       => Only Controller listed (full right) Contracts and Owner can interact with this contract.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier onlyOwner() {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                _Owner == msg.sender,
            "oO"
        );
        require(msg.sender != address(0), "0A");
        _;
    }

    constructor(address Controller) {
        _Owner = msg.sender;
        _SController = Controller;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_StartLogic(uint256 CountDays) returns (bool);
    This function creates all timestamps for the logic initialization.
    uint256 CountDays => Specifies the number of days as a lead time before initialization. This time is used for the ICO.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _StartLogic(uint256 CountDays) public onlyOwner returns (bool) {
        //  Inicialise Countdown until Logic starts
        //  Countdown is set to 60 Days
        _SetUpLogicCountdown = block.timestamp + (_DayInterval * CountDays);
        //  Inicialise Swap Event
        //  Every 9 Days later + 5 Hours
        _UV2_Swap_event =
            block.timestamp +
            (3600 * 5 + (_DayInterval * (9 + CountDays)));
        //  Inicialise Liquidity Event
        //  Every 7 Days later + 5 Hours
        _UV2_Liquidity_event =
            block.timestamp +
            (3600 * 10 + (_DayInterval * (7 + CountDays)));
        //  Inicialise Bonus Event
        //  Every 100 Days later + 15 Hours
        _ExtraBonusAll =
            block.timestamp +
            (3600 * 15 + (_DayInterval * (100 + CountDays)));
        //  Inicialise Bonus time window
        //  Every 100 Days later + 15 Hours + 24 Hours
        _ExtraBonusAllEnd = _ExtraBonusAll + (_DayInterval * (CountDays + 1));
        //  Inicialise Airdrop Event
        //  Every 6 Days later + 18 Hours
        _ExtraBonusAirdrop =
            block.timestamp +
            (3600 * 18 + (_DayInterval * (6 + CountDays)));
        //  Inicialise Airdrop time window
        _ExtraBonusAirdropEnd =
            _ExtraBonusAirdrop +
            (_DayInterval * (CountDays + 1));
        //  Inicialise Redeem  LP Token Event inicially set to + 11 years
        //  Starts first in 11 years and will be scheduled every 29 days
        _UV2_RemoveLiquidity_event =
            block.timestamp +
            (_YearInterval * 11) +
            (_DayInterval * CountDays);
        //  Inicialise Minting Event
        //  Every Day for 8 Years
        _DailyMint = block.timestamp + (_DayInterval * (CountDays + 1));
        //  Inicialise logic start Event
        //  Starts immediatly when Countdown ends
        _BeginLogic = block.timestamp + (_DayInterval * CountDays);
        //  Inicialise Minting time window
        //  Is set fixed to 8 years + 1 Hour
        _EndMint =
            block.timestamp +
            (_YearInterval * 8) +
            3600 +
            (_DayInterval * CountDays);
        //  Inicialise BuyBack Event
        //  Every 30 Days + 20 Hours after Burning has ended
        _StartBuyBack =
            block.timestamp +
            (_YearInterval * 11) +
            (3600 * 20) +
            (_DayInterval * CountDays);
        //  Inicialise Burning Event
        //  Is set to 4 Years after Logic has started
        _StartBurn =
            block.timestamp +
            (_YearInterval * 4) +
            (_DayInterval * CountDays);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_timetester(uint256 timernum, uint256 btimestamp) returns (bool);
    This function is there for testing the timestamps and is no longer used after successfull tests
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _timetester(uint256 timernum, uint256 btimestamp)
        public
        onlyOwner
        returns (bool)
    {
        //Test Minting
        if (timernum == 1) {
            _DailyMint = btimestamp;
            //Test Swap
        } else if (timernum == 2) {
            _UV2_Swap_event = btimestamp;
            //Test Liquidity
        } else if (timernum == 3) {
            _UV2_Liquidity_event = btimestamp;
            //Test Redeem LP-Token
        } else if (timernum == 4) {
            _UV2_RemoveLiquidity_event = btimestamp;
            //Test Bonus
        } else if (timernum == 5) {
            _ExtraBonusAll = btimestamp;
            //Test BuyBack
        } else if (timernum == 6) {
            _StartBuyBack = btimestamp;
            //Test Burning
        } else if (timernum == 7) {
            _StartBurn = btimestamp;
            //Test Countdown
        } else if (timernum == 8) {
            _SetUpLogicCountdown = btimestamp;
            //Test Airdrop
        } else if (timernum == 9) {
            _ExtraBonusAirdrop = btimestamp;
        }

        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_updateExtraBonusAll() returns (bool);
    This function updates the bonus timestamp including the 24-hour time slot
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _updateExtraBonusAll() public onlyOwner returns (bool) {
        _ExtraBonusAll = _ExtraBonusAll + (_DayInterval * 100);
        _ExtraBonusAllEnd = _ExtraBonusAll + _DayInterval;
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_updateExtraBonusAirdrop() returns (bool);
    This function updates the Airdrop timestamp including the 24-hour time slot
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _updateExtraBonusAirdrop() public onlyOwner returns (bool) {
        _ExtraBonusAirdrop = _ExtraBonusAirdrop + (_DayInterval * 6);
        _ExtraBonusAirdropEnd = _ExtraBonusAirdrop + _DayInterval;
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_updateUV2_Swap_event() returns (bool);
    This function updates the Swap timestamp
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _updateUV2_Swap_event() public onlyOwner returns (bool) {
        _UV2_Swap_event = _UV2_Swap_event + (_DayInterval * 9);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_updateStartBuyBack() returns (bool);
    This function updates the BuyBack timestamp
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _updateStartBuyBack() public onlyOwner returns (bool) {
        _StartBuyBack = _StartBuyBack + (_DayInterval * 30);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_updateUV2_Liquidity_event() returns (bool);
    This function updates the add Liquidity timestamp
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _updateUV2_Liquidity_event() public onlyOwner returns (bool) {
        _UV2_Liquidity_event = _UV2_Liquidity_event + (_DayInterval * 7);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_updateDailyMint() returns (bool);
    This function updates the daily Minting timestamp
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _updateDailyMint() public onlyOwner returns (bool) {
        _DailyMint = _DailyMint + _DayInterval;
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_updateUV2_RemoveLiquidity_event()  returns (bool);
    This function updates the remove Liquidity timestamp
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _updateUV2_RemoveLiquidity_event()
        public
        onlyOwner
        returns (bool)
    {
        _UV2_RemoveLiquidity_event =
            _UV2_RemoveLiquidity_event +
            (_DayInterval * 29);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getStartTime() returns (uint256);
    This function returns the start logic time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getStartTime() public view returns (uint256) {
        return _BeginLogic;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getEndMintTime() returns (uint256);
    This function returns the end of Minting time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getEndMintTime() public view returns (uint256) {
        return _EndMint;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getDailyMintTime() returns (uint256);
    This function returns the daily Minting time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getDailyMintTime() public view returns (uint256) {
        return _DailyMint;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getStartBurnTime() returns (uint256);
    This function returns the start Burning time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getStartBurnTime() public view returns (uint256) {
        return _StartBurn;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getUV2_RemoveLiquidityTime() returns (uint256);
    This function returns the remove Liquidity time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getUV2_RemoveLiquidityTime() public view returns (uint256) {
        return _UV2_RemoveLiquidity_event;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getUV2_LiquidityTime() returns (uint256);
    This function returns the add Liquidity time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getUV2_LiquidityTime() public view returns (uint256) {
        return _UV2_Liquidity_event;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getUV2_SwapTime() returns (uint256);
    This function returns the Swap time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getUV2_SwapTime() public view returns (uint256) {
        return _UV2_Swap_event;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getExtraBonusAllTime() returns (uint256);
    This function returns the Bonus time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getExtraBonusAllTime() public view returns (uint256) {
        return _ExtraBonusAll;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getEndExtraBonusAllTime() returns (uint256);
    This function returns the end Bonus time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getEndExtraBonusAllTime() public view returns (uint256) {
        return _ExtraBonusAllEnd;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getExtraBonusAirdropTime() returns (uint256);
    This function returns the Airdrop time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getExtraBonusAirdropTime() public view returns (uint256) {
        return _ExtraBonusAirdrop;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getEndExtraBonusAirdropTime() returns (uint256);
    This function returns the end Airdrop time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getEndExtraBonusAirdropTime() public view returns (uint256) {
        return _ExtraBonusAirdropEnd;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getLogicCountdown() returns (uint256);
    This function returns the Logic Countdown time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getLogicCountdown() public view returns (uint256) {
        return _SetUpLogicCountdown;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getStartBuyBackTime() returns (uint256);
    This function returns the BuyBack time
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getStartBuyBackTime() public view returns (uint256) {
        return _StartBuyBack;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getEA() returns (uint256, uint256);
    This function returns the yearly minting amount and daily minting amount
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getEA()
        public
        view
        returns (uint256 EYearAmount, uint256 EDayAmount)
    {
        if (block.timestamp < _BeginLogic + (_YearInterval * 1)) {
            return (733333333.33 * 10**18, 2037037.037027770 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 2)) {
            return (957333333.33 * 10**18, 2659259.259250000 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 3)) {
            return (983333333.33 * 10**18, 2731481.481472220 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 4)) {
            return (1009333333.33 * 10**18, 2803703.703694440 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 5)) {
            return (1035333333.33 * 10**18, 2875925.925916660 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 6)) {
            return (1061333333.33 * 10**18, 2948148.148138880 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 7)) {
            return (754000000 * 10**18, 2094444.444444440 * 10**18);
        } else if (block.timestamp < _BeginLogic + (_YearInterval * 8)) {
            return (1066000000.02 * 10**18, 2961111.111166660 * 10**18);
        } else {}
    }
}
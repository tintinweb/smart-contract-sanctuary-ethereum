/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// LIBRARIES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// SAFEMATH its a Openzeppelin Lib. Check out for more info @ https://docs.openzeppelin.com/contracts/2.x/api/math
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INTERFACES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getController() external pure returns (address);

    function _getNFM() external pure returns (address);

    function _getTimer() external pure returns (address);

    function _getPad() external pure returns (address);

    function _getMinting() external pure returns (address);

    function _getBurning() external pure returns (address);

    function _getSwap() external pure returns (address);

    function _getLiquidity() external pure returns (address);

    function _getUV2Pool() external pure returns (address);

    function _getBonusBuyBack() external pure returns (address, address);

    function _getNFMStaking() external pure returns (address);

    function _getNFMStakingTreasuryERC20() external view returns (address);

    function _getTreasury() external view returns (address);

    function _getAirdrop() external view returns (address);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMTIMER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmTimer {
    function _getStartTime() external pure returns (uint256);

    function _getEndMintTime() external pure returns (uint256);

    function _getDailyMintTime() external pure returns (uint256);

    function _getStartBurnTime() external pure returns (uint256);

    function _getUV2_LiquidityTime() external pure returns (uint256);

    function _getUV2_SwapTime() external pure returns (uint256);

    function _getExtraBonusAllTime() external view returns (uint256);

    function _getEndExtraBonusAllTime() external view returns (uint256);

    function _updateExtraBonusAll() external returns (bool);

    function _getLogicCountdown() external view returns (uint256);

    function _getStartBuyBackTime() external view returns (uint256);

    function _updateStartBuyBack() external returns (bool);

    function _getExtraBonusAirdropTime() external view returns (uint256);

    function _getEndExtraBonusAirdropTime() external view returns (uint256);

    function _getUV2_RemoveLiquidityTime() external view returns (uint256);

    function _updateExtraBonusAirdrop() external returns (bool);

    function _updateUV2_RemoveLiquidity_event() external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMPAD
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmPad {
    function balancePAD(address account) external pure returns (uint256);

    function _PADCHECK(address from, uint256 amount) external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMMINTING
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmMinting {
    function _minting(address sender) external returns (bool);

    function _updateBNFTAmount(address minter) external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMSWAP
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmSwap {
    function _LiquifyAndSwap() external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMLIQUIDITY
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmAddLiquidity {
    function _addLiquidity() external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMBURNING
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmBurning {
    function checkburn(uint256 amount)
        external
        view
        returns (
            bool state,
            bool typ,
            uint256 bfee,
            uint256 stakefee
        );
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMBUYBACK
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmBuyBack {
    function _BuyBack() external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMBUYBACK
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmUV2Pool {
    function redeemLPToken() external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMAIRDROP
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmAirdrop {
    function _checkPayment(address sender) external view returns (uint256);

    function updateSchalter() external returns (bool);

    function _getAirdrop(address Sender) external returns (bool);

    function _returnPayoutCounter() external view returns (uint256);

    function _resetPayOutCounter() external returns (bool);

    function _getWithdraw(
        uint256 _index,
        address Stake,
        address Tresury
    ) external returns (bool);

    function _showlastRounds() external view returns (uint256);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMBONUS
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmExtraBonus {
    function _getBonus(address winner) external returns (bool);

    function _returnPayoutRule() external view returns (uint256);

    function updateSchalter() external returns (bool);

    function _getWithdraw(
        address To,
        uint256 amount,
        bool percent
    ) external returns (bool);

    function updatePayoutRule() external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFM.sol
/// @author Fernando Viktor Seidl E-mail: [email protected]
/// @notice ERC20 Token Standard Contract with special extensions in the "_transfer" functionality *** NFM ERC20 TOKEN ***
/// @dev This ERC20 contract includes all functionalities of an ERC20 standard. The only difference to the standard are the built-in
///            extensions in the _transfer function.
///            The following interfaces are required for the smooth functionality of the extensions:
///            -    Controller Interface
///            -    Timer Interface
///            -    PAD Interface
///            -    Minting Interface
///            -    Swap Interface
///            -    Liquidity Interface
///            -    Burning Interface
///            -    Bonus Interface
///            -    Airdrop Interface
///            -    Vault Interface
///            -    LP-Redemption Interface
///            -    BuyBack Interface
///
///            TOKEN DETAILS:
///            -    Inicial total supply 400,000,000 NFM
///            -    Final total supply 1,000,000,000 NFM
///            -    Token Decimals 18
///            -    Token Name: Nftismus
///            -    Token Symbol: NFM
///
///            TOKEN EXTENSIONS:
///            -    PAD (Pump and Dump security): Used to protect against pump and dump actions. All accounts have a daily
///                 transaction limit of 1 million NFM. Large investors can whitelist this up to 1.5 million for a fee of 10,000 NFM
///            -    Minting: 7,600,000,000 NFM are created by minting in 8 years. 60% of the amount can only be obtained via
///                 the staking pool. 15% is allocated to the Uniswap protocol. 5% goes to AFT Governance. 10% to the developers
///                 and 10% to the NFM Treasury for investments to generate profits for the Bonus Event.
///            -    Burning and Community: 7,000,000,000 NFM are destroyed by burning process starting after 4 years with a burning
///                 fee of 2%  and a Community Fee of 2%. The burning fee will be maintained until the total amount has shrunk back to
///                 1 billion. When this is done, the burning fee will be credited to the community. The community fee is a staking contribution.
///                 Since the staking pool is funded by the minting protocol, which is finite. An infinite interest system is created by the
///                 community fee, so that interest can still be generated in the stake even after minting.
///            -    Liquidity: extension implements Uniswapv2 Protocol and adds liquidity to different markets.
///            -    Swap: extension implements Uniswapv2 Protocol and exchanges the NFM for different currencies for the Liquidity extension
///                 10% of every realized swap goes into the Bonus Event.
///            -    Timer: controls the timing of all extensions of the protocol
///            -    Bonus: allows NFM owners to receive profit distributions of the protocol in other currencies such
///                 as WBTC,WBNB,WETH,WMATIC,DAI,... every 100 days
///            -    Airdrop: allows NFM owners to receive profit distributions of the protocol in other currencies from the IDO
///                 Launchpad or listed Airdrops from other projects... every 6 days
///            -    LP-Redemption: Redeem the locked LP tokens step by step. 20% goes to the NFM Community through the Bonus Event. The
///                 remaining 80% goes to NFM Treasury, AFT Governance and Developers on a 40/30/10 split
///            -    Vault Interface: Makes investments in different protocols like Aave, Uniswap,... to generate additional profits for the bonus payouts.
///            -    BuyBack: Buyback program will start after reaching the final total supply of 1 billion NFM. Buybacks are executed monthly (30 day interval)
///                 via the decentralized markets on UniswapV2.
///
///            TOKEN USE CASE:
///            -    The principal application of the NFM token is the creation of value. This should not only be borne by the token itself,
///                 but also by future projects in the art, real estate and financial sectors
///            -    We as founders have the idea of ​​creating something completely new, which not only refers to the digital values, but also
///                 includes the physical real value.
///            -    The token can be viewed as an auto-generating yield token. With the help of the extensions, the NFM receives a share
///                 of bonus payments and airdrops. These are distributed via the stake or via trading
///            -    Our vision is to add real products to the returns in the future.
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFM {
    //include SafeMath
    using SafeMath for uint256;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    STANDARD ERC20 MAPPINGS:
    _balances(owner address, nfm amount)
    _allowances(owner address, spender address, nfm amount)
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => uint256) private _BonusTracker;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTRACT EVENTS
    STANDARD ERC20 EVENTS:
    Transfer(sender, receiver, amount);
    Approval(owner, spender, amount);
    SPECIAL EVENT:
    Burning(sender, receiver, BurningFee, Timestamp
    );
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Burning(
        address indexed sender,
        address indexed receiver,
        uint256 BFee,
        uint256 Time
    );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    ERC20 STANDARD ATTRIBUTES
    _TokenName           => Name of the Token (Nftismus)
    _TokenSymbol         => Symbol of the Token (NFM)
    _TokenDecimals      =>  Precision of the Token (18 Decimals)
    _TotalSupply            =>  Total Amount of Tokens (Inicial 400 Million NFM)
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    string private _TokenName;
    string private _TokenSymbol;
    uint256 private _TokenDecimals;
    uint256 private _TotalSupply;

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    SECURITY ATTRIBUTES
    _paused        => Pausing can only be commissioned by the Dao.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 private _paused;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _Owner;
    INfmController public _Controller;
    address private _SController;

    constructor(
        string memory TokenName,
        string memory TokenSymbol,
        uint256 TokenDecimals,
        address Controller
    ) {
        _TokenName = TokenName;
        _TokenSymbol = TokenSymbol;
        _TokenDecimals = TokenDecimals;
        _TotalSupply = 400000000 * 10**TokenDecimals;
        _Owner = msg.sender;
        _SController = Controller;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
        _balances[_Owner] = _TotalSupply;
        emit Transfer(address(0), _Owner, _TotalSupply);
        _paused = 0;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @name() returns (string);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function name() public view returns (string memory) {
        return _TokenName;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @symbol() returns (string);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function symbol() public view returns (string memory) {
        return _TokenSymbol;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @decimals() returns (uint256);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function decimals() public view returns (uint256) {
        return _TokenDecimals;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @totalSupply() returns (uint256);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function totalSupply() public view returns (uint256) {
        return _TotalSupply;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @balanceOf(address account) returns (uint256);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @bonusCheck(address account) returns (uint256, uint256, bool);
    Special Function for Bonus Extension
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function bonusCheck(address account) public view returns (uint256) {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                msg.sender == _Owner,
            "oO"
        );
        return _BonusTracker[account];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @allowance(address owner, address spender) returns (uint256);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @onOffNFM() returns (bool);
    This function can only be executed by the Dao and is used to pause the protocol
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function onOffNFM() public returns (bool) {
        require(msg.sender != address(0), "0A");
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                msg.sender == _Owner,
            "oO"
        );
        if (_paused == 0) {
            _paused = 1;
        } else {
            _paused = 0;
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @transfer(address to, uint256 amount)  returns (bool);
    Strandard ERC20 Function 
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @transferFrom(address from, address to, uint256 amount)   returns (bool);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_transfer(address from, address to, uint256 amount)  returns (bool);
    Strandard ERC20 Function with implemented Extensions and ReentrancyGuard as safety mechanism
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "0A");
        require(to != address(0), "0A");
        require(_paused == 0, "_P");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "<B");
        //--------------------------------------------------------------------------------------------
        /**
        IF ADDRESS IS WHITELISTED
        THEN DON'T APPLY LOGIC SMART CONTRACT IS CALLING
        */
        //--------------------------------------------------------------------------------------------
        if (_Controller._checkWLSC(_SController, msg.sender) == true) {
            unchecked {
                _balances[from] = SafeMath.sub(fromBalance, amount);
            }
            if (
                block.timestamp <
                INfmTimer(address(_Controller._getTimer()))
                    ._getExtraBonusAllTime() &&
                block.timestamp <
                INfmTimer(address(_Controller._getTimer()))
                    ._getExtraBonusAirdropTime()
            ) {
                _BonusTracker[to] = _balances[to] + amount;
                _BonusTracker[from] = _balances[from];
            }

            _balances[to] += amount;

            emit Transfer(from, to, amount);
        } else {
            //--------------------------------------------------------------------------------------------
            /**
            IF ADDRESS IS NOT WHITELISTED 
            LOGIC MUST BE APPLIED
             */
            //--------------------------------------------------------------------------------------------

            //--------------------------------------------------------------------------------------------
            /**
            1 - )   APPLY PAD SECURITY
             */
            //--------------------------------------------------------------------------------------------
            require(
                INfmPad(_Controller._getPad())._PADCHECK(from, amount) == true,
                "PAD"
            );

            //--------------------------------------------------------------------------------------------
            /**
            INICIALIZE TIMER INTERFACE FOR ALL OTHER EXTENSION-CHECKS
             */
            //--------------------------------------------------------------------------------------------
            INfmTimer Timer = INfmTimer(_Controller._getTimer());

            //--------------------------------------------------------------------------------------------
            /**
            CHECK IF THE LOGIC OF THE PROTOCOL HAS BEEN INICIALIZED, IF NOT THEN
            NO EXTENSIONS  CAN BE APPLIED (TOKEN IS ALREADY ON PRESALE)
             */
            //--------------------------------------------------------------------------------------------
            if (
                Timer._getStartTime() > 0 &&
                Timer._getStartTime() < block.timestamp
            ) {
                //--------------------------------------------------------------------------------------------
                /**
                INICIALIZE TLOCKER VARIABLE
                (ALLOWS ONLY ONE EXTENSION TO BE EXECUTED AT A TIME)
                */
                //--------------------------------------------------------------------------------------------
                bool tlocker = false;

                //--------------------------------------------------------------------------------------------
                /**
                2 - )   MINTING EXTENSION 
                */
                //--------------------------------------------------------------------------------------------
                if (
                    block.timestamp <= Timer._getEndMintTime() &&
                    block.timestamp >= Timer._getDailyMintTime()
                ) {
                    INfmMinting Minter = INfmMinting(_Controller._getMinting());
                    if (Minter._minting(from) == true) {
                        tlocker = true;
                    }
                }
                //--------------------------------------------------------------------------------------------
                /**
                3 - )   LIQUIDITY EXTENSION 
                */
                //--------------------------------------------------------------------------------------------
                if (
                    tlocker == false &&
                    block.timestamp >= Timer._getUV2_LiquidityTime() &&
                    block.timestamp <= Timer._getEndMintTime()
                ) {
                    INfmAddLiquidity Liquidity = INfmAddLiquidity(
                        _Controller._getLiquidity()
                    );
                    if (Liquidity._addLiquidity() == true) {
                        INfmMinting(_Controller._getMinting())
                            ._updateBNFTAmount(msg.sender);
                        tlocker = true;
                    }
                }
                //--------------------------------------------------------------------------------------------
                /**
                4 - )   SWAP EXTENSION 
                */
                //--------------------------------------------------------------------------------------------
                if (
                    tlocker == false &&
                    block.timestamp >= Timer._getUV2_SwapTime() &&
                    block.timestamp <= Timer._getEndMintTime()
                ) {
                    //Start Swapping
                    INfmSwap Swapper = INfmSwap(_Controller._getSwap());
                    if (Swapper._LiquifyAndSwap() == true) {
                        INfmMinting(_Controller._getMinting())
                            ._updateBNFTAmount(msg.sender);
                        tlocker = true;
                    }
                }
                //--------------------------------------------------------------------------------------------
                /**
                7 - )   LP-TOKEN REDEMPTION 
                */
                //--------------------------------------------------------------------------------------------
                if (
                    tlocker == false &&
                    block.timestamp >= Timer._getUV2_RemoveLiquidityTime()
                ) {
                    //Start LP-Redemption
                    INfmUV2Pool UV2Pool = INfmUV2Pool(
                        _Controller._getUV2Pool()
                    );
                    if (UV2Pool.redeemLPToken() == true) {
                        tlocker = true;
                    }
                }
                //--------------------------------------------------------------------------------------------
                /**
                8 - )   BUYBACK EXTENSION 
                */
                //--------------------------------------------------------------------------------------------
                if (
                    tlocker == false &&
                    block.timestamp >= Timer._getStartBuyBackTime()
                ) {
                    //Start BuyBack
                    (, address BBack) = _Controller._getBonusBuyBack();
                    INfmBuyBack BuyBack = INfmBuyBack(BBack);
                    if (BuyBack._BuyBack() == true) {
                        Timer._updateStartBuyBack();
                        tlocker = true;
                    }
                }
                //--------------------------------------------------------------------------------------------
                /**
                5 - )   BONUS EXTENSION 
                */
                //--------------------------------------------------------------------------------------------
                if (
                    tlocker == false &&
                    block.timestamp >= Timer._getExtraBonusAllTime() &&
                    _BonusTracker[from] >= 150 * 10**18
                ) {
                    if (block.timestamp >= Timer._getEndExtraBonusAllTime()) {
                        (address IBonus, ) = _Controller._getBonusBuyBack();
                        INfmExtraBonus Bonus = INfmExtraBonus(IBonus);
                        if (Bonus._returnPayoutRule() == 0) {
                            //Make Withdraw to Stake 50%
                            if (
                                Bonus._getWithdraw(
                                    address(
                                        _Controller
                                            ._getNFMStakingTreasuryERC20()
                                    ),
                                    50,
                                    true
                                ) == true
                            ) {
                                Bonus.updatePayoutRule();
                                tlocker = true;
                            }
                        } else if (Bonus._returnPayoutRule() == 1) {
                            //Make Withdraw to Treasury 50%
                            if (
                                Bonus._getWithdraw(
                                    address(_Controller._getTreasury()),
                                    0,
                                    false
                                ) == true
                            ) {
                                Bonus.updatePayoutRule();
                                tlocker = true;
                            }
                        } else {
                            Bonus.updatePayoutRule();
                            if (Bonus.updateSchalter() == true) {
                                Timer._updateExtraBonusAll();
                                tlocker = true;
                            }
                        }
                    } else {
                        (address IBonus, ) = _Controller._getBonusBuyBack();
                        INfmExtraBonus Bonus = INfmExtraBonus(IBonus);
                        if (Bonus._getBonus(from) == true) {
                            Timer._updateExtraBonusAll();
                            tlocker = true;
                        }
                    }
                }
                //--------------------------------------------------------------------------------------------
                /**
                6 - )   AIRDROP EXTENSION 
                */
                //--------------------------------------------------------------------------------------------
                if (
                    tlocker == false &&
                    block.timestamp >= Timer._getExtraBonusAirdropTime() &&
                    _BonusTracker[from] >= 150 * 10**18
                ) {
                    if (
                        block.timestamp >= Timer._getEndExtraBonusAirdropTime()
                    ) {
                        INfmAirdrop Airdrop = INfmAirdrop(
                            address(_Controller._getAirdrop())
                        );
                        if (Airdrop._returnPayoutCounter() == 1) {
                            //Make Withdraw Stake/Treasury 50%/50% Airdrop 1
                            uint256 lastRound = Airdrop._showlastRounds();
                            if (
                                Airdrop._getWithdraw(
                                    lastRound + 1,
                                    address(
                                        _Controller
                                            ._getNFMStakingTreasuryERC20()
                                    ),
                                    address(_Controller._getTreasury())
                                ) == true
                            ) {
                                tlocker = true;
                            }
                        } else if (Airdrop._returnPayoutCounter() == 2) {
                            //Make Withdraw Stake/Treasury 50%/50% Airdrop 2
                            uint256 lastRound = Airdrop._showlastRounds();
                            if (
                                Airdrop._getWithdraw(
                                    lastRound + 2,
                                    address(
                                        _Controller
                                            ._getNFMStakingTreasuryERC20()
                                    ),
                                    address(_Controller._getTreasury())
                                ) == true
                            ) {
                                tlocker = true;
                            }
                        } else if (Airdrop._returnPayoutCounter() == 3) {
                            //Make Withdraw Stake/Treasury 50%/50% Airdrop 3
                            uint256 lastRound = Airdrop._showlastRounds();
                            if (
                                Airdrop._getWithdraw(
                                    lastRound + 3,
                                    address(
                                        _Controller
                                            ._getNFMStakingTreasuryERC20()
                                    ),
                                    address(_Controller._getTreasury())
                                ) == true
                            ) {
                                tlocker = true;
                            }
                        } else {
                            if (Airdrop.updateSchalter() == true) {
                                Airdrop._resetPayOutCounter();
                                Timer._updateExtraBonusAirdrop();
                                tlocker = true;
                            }
                        }
                    } else {
                        if (
                            INfmAirdrop(_Controller._getAirdrop())
                                ._checkPayment(from) !=
                            Timer._getEndExtraBonusAirdropTime()
                        ) {
                            INfmAirdrop Airdrop = INfmAirdrop(
                                address(_Controller._getAirdrop())
                            );
                            if (Airdrop._getAirdrop(from) == true) {
                                tlocker = true;
                            }
                        }
                    }
                }
                //--------------------------------------------------------------------------------------------
                /**
                9 - )   BURNING EXTENSION 
                */
                //--------------------------------------------------------------------------------------------
                if (
                    tlocker == false &&
                    block.timestamp >= Timer._getStartBurnTime()
                ) {
                    //Start Burning

                    INfmBurning Burner = INfmBurning(_Controller._getBurning());
                    (
                        bool state,
                        bool typ,
                        uint256 bfee,
                        uint256 stakefee
                    ) = Burner.checkburn(amount);
                    if (state == true) {
                        tlocker = true;
                        if (typ == true) {
                            _burn(from, bfee);
                            fromBalance = _balances[from];
                            unchecked {
                                _balances[from] = SafeMath.sub(
                                    fromBalance,
                                    stakefee
                                );
                            }
                            _balances[
                                address(
                                    _Controller._getNFMStakingTreasuryERC20()
                                )
                            ] += stakefee;
                            emit Transfer(
                                from,
                                address(
                                    _Controller._getNFMStakingTreasuryERC20()
                                ),
                                stakefee
                            );
                            amount = SafeMath.sub(amount, (bfee + stakefee));
                        } else {
                            fromBalance = _balances[from];
                            unchecked {
                                _balances[from] = SafeMath.sub(
                                    fromBalance,
                                    stakefee * 2
                                );
                            }
                            _balances[
                                address(
                                    _Controller._getNFMStakingTreasuryERC20()
                                )
                            ] += stakefee * 2;
                            emit Transfer(
                                from,
                                address(
                                    _Controller._getNFMStakingTreasuryERC20()
                                ),
                                stakefee * 2
                            );
                            amount = SafeMath.sub(amount, stakefee * 2);
                        }
                    }
                }


            }
            fromBalance = _balances[from];
            unchecked {
                _balances[from] = SafeMath.sub(fromBalance, amount);
            }
            if (
                block.timestamp <
                INfmTimer(address(_Controller._getTimer()))
                    ._getExtraBonusAllTime() &&
                block.timestamp <
                INfmTimer(address(_Controller._getTimer()))
                    ._getExtraBonusAirdropTime()
            ) {
                _BonusTracker[to] = _balances[to] + amount;
                _BonusTracker[from] = _balances[from];
            }
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_spendAllowance(address owner, address spender, uint256 amount);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "<A");
            unchecked {
                _approve(
                    owner,
                    spender,
                    SafeMath.sub(currentAllowance, amount)
                );
            }
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_approve(address owner, address spender, uint256 amount);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "0A");
        require(spender != address(0), "0A");
        require(_paused == 0, "_P");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @approve(address spender, uint256 amount) return (bool);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @increaseAllowance(address spender, uint256 amount) return (bool);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        _approve(
            owner,
            spender,
            SafeMath.add(allowance(owner, spender), addedValue)
        );
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @decreaseAllowance(address spender, uint256 amount) return (bool);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "_D");
        unchecked {
            _approve(
                owner,
                spender,
                SafeMath.sub(currentAllowance, subtractedValue)
            );
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_mint(address to, uint256 amount);
    Strandard ERC20 Function has been modified for the protocol
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _mint(address to, uint256 amount) public virtual {
        require(msg.sender != address(0), "0A");
        require(to != address(0), "0A");
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        _TotalSupply += amount;
        _balances[to] += amount;
        _BonusTracker[to] = _balances[to];
        emit Transfer(address(0), to, amount);
    }

    function _UV2NFMHandler(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        require(msg.sender != address(0), "0A");
        require(to != address(0), "0A");
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        require(_Controller._checkWLSC(_SController, to) == true, "oO");
        unchecked {
            _balances[from] = SafeMath.sub(_balances[from], amount);
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_burn(address account, uint256 amount);
    Strandard ERC20 Function has been modified for the protocol
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "0A");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "A>B");
        unchecked {
            _balances[account] = SafeMath.sub(accountBalance, amount);
        }
        _BonusTracker[account] = _balances[account];
        _TotalSupply = SafeMath.sub(_TotalSupply, amount);
        emit Burning(account, address(0), amount, block.timestamp);
        emit Transfer(account, address(0), amount);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_bridgeImp(address account, uint256 amount, uint256 amount) returns (bool);
    Bridge Implementation Function. This feature allows for future bridge implementations. Only allowed 
    addresses by the controller can call this function.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _bridgeImp(
        address sender,
        uint256 amount,
        uint256 typ
    ) public virtual returns (bool) {
        require(msg.sender != address(0), "0A");
        require(sender != address(0), "0A");
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        if (typ == 0) {
            //mint
            _mint(sender, amount);
            return true;
        } else {
            //burn
            _burn(sender, amount);
            return true;
        }
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-06-22
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
    function _AddLiquidity() external returns (bool);
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
// INFMBONUS
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmExtraBonus {
    function _getBonus(address winner, uint256 amount) external returns (bool);

    function updateSchalter() external returns (bool);
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
///            -    PAD: Pump and Dump security
///            -    Minting: 7,600,000,000 NFM are created by minting in 8 years
///            -    Burning: 7,000,000,000 NFM are destroyed by burning process starting after 4 years with a burning fee of 2% 
///            -    Liquidity: extension implements Uniswapv2 Protocol and adds liquidity to different markets.
///            -    Swap: extension implements Uniswapv2 Protocol and exchanges the NFM for different currencies for the Liquidity extension
///            -    Timer: controls the timing of all extensions of the protocol
///            -    Bonus: allows NFM owners to receive profit distributions of the protocol in other currencies such 
///                 as WBTC,WBNB,WETH,WMATIC,DAI,... every 100 days
///            -    BuyBack: Buyback program will start after reaching the final total supply of 1 billion NFM. Buybacks are executed monthly 
///                 via the decentralized markets on UniswapV2.
///            
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
    mapping(address => uint256) private _addressIssueTracker;
    mapping(address => uint256) private _lastBalanceStamp;
    mapping(address => uint256) private _lastBalanceAmount;
    mapping(address => bool) private _BonusAllowance;
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
    _locked         => ReentrancyGuard variable. Secures the protocol against reentrancy attacks
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 private _paused;
    uint256 internal _locked;
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
    MODIFIER
    reentrancyGuard       => secures the protocol against reentrancy attacks
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier reentrancyGuard() {
        require(_locked == 0);
        _locked = 1;
        _;
        _locked = 0;
    }

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
    function bonusCheck(address account) public view returns (uint256, uint256,uint256,bool) {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                msg.sender == _Owner,
            "oO"
        );
        return (_addressIssueTracker[account], _lastBalanceStamp[account], _lastBalanceAmount[account], _BonusAllowance[account]);
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
    @Offlocker() returns (bool);
    This function can only be executed by the Dao and is used to relock the reentrancy
     */
     //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function Offlocker() public returns (bool) {
        require(msg.sender != address(0), "0A");
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                msg.sender == _Owner,
            "oO"
        );
        if (_locked == 1) {
            _locked = 0;
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
    ) internal virtual reentrancyGuard {
        require(from != address(0), "0A");
        require(to != address(0), "0A");
        require(_paused == 0, "_P");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "<B");
        //--------------------------------------------------------------------------------------------
        /**
        IF ADDRESS IS WHITELISTED
        THEN DON'T APPLY LOGIC 
        */
        //--------------------------------------------------------------------------------------------
        if (_Controller._checkWLSC(_SController, msg.sender) == true) {
                unchecked {
                    _balances[from] = SafeMath.sub(fromBalance, amount);
                }
                _balances[to] += amount;
                emit Transfer(from, to, amount);
        } else {
            //--------------------------------------------------------------------------------------------
            /**
            SPECIAL TRACKING FOR BONUS PAYMENTS.
            Newly created accounts are excluded from the bonus event.
            The account balance from 24 hours ago is taken as admission. This prevents manipulations. 
            If the previous account balance was less than 250 NFM in the last 24 hours before Bonus Event, there is a possibility of manipulation 
            if it happens within the time window.
            An example would be: A participant has several accounts and switches his NFM between the accounts 
            in order to collect twice.
            */
            //--------------------------------------------------------------------------------------------
            if(_addressIssueTracker[to] > 0){
                if(_lastBalanceStamp[to] < block.timestamp){
                    if( INfmTimer(address(_Controller._getTimer()))._getExtraBonusAllTime()<_lastBalanceStamp[to]+(3600*24) 
                        && _lastBalanceStamp[to] < INfmTimer(address(_Controller._getTimer()))._getEndExtraBonusAllTime()){

                        }else{
                            _lastBalanceStamp[to]=block.timestamp+(3600*24);
                            if(_lastBalanceAmount[to] < 250*10**18){
                                _BonusAllowance[to]=false;
                            }else{
                                _BonusAllowance[to]=true;
                            }
                            _lastBalanceAmount[to]=amount+_balances[to];
                        }                    
                }
            }else{
                _addressIssueTracker[to]=block.timestamp;
                _lastBalanceStamp[to]=block.timestamp+(3600*24);
                _lastBalanceAmount[to]=amount; 
                _BonusAllowance[to]=true;
            }
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
            INICIALIZE TIMER INTERFACE FOR ALL OTHER EXTENSION CHECKS
             */
             //--------------------------------------------------------------------------------------------
            INfmTimer Timer = INfmTimer(_Controller._getTimer());

            //--------------------------------------------------------------------------------------------
            /**
            CHECK IF THE LOGIC OF THE PROTOCOL HAS BEEN INICIALIZED, IF NOT THEN
            NO EXTENSIONS  CAN BE APPLIED
             */
             //--------------------------------------------------------------------------------------------
            if (
                Timer._getStartTime() > 0 &&
                Timer._getLogicCountdown() > 0 &&
                Timer._getLogicCountdown() < block.timestamp
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
                MINTING EXTENSION 
                */
                //--------------------------------------------------------------------------------------------
                if (
                    block.timestamp <= Timer._getEndMintTime() &&
                    block.timestamp >= Timer._getDailyMintTime()
                ) {
                    INfmMinting Minter = INfmMinting(_Controller._getMinting());
                    //Start Minting Calc
                    if (Minter._minting(from) == true) {
                        tlocker = true;
                    }
                }
                //--------------------------------------------------------------------------------------------
                /**
                LIQUIDITY EXTENSION 
                */
                //--------------------------------------------------------------------------------------------
                if (
                    tlocker == false &&
                    block.timestamp >= Timer._getUV2_LiquidityTime()
                ) {
                    //Add Liquidity

                    INfmAddLiquidity Liquidity = INfmAddLiquidity(
                        _Controller._getLiquidity()
                    );
                    if (Liquidity._AddLiquidity() == true) {
                        INfmMinting(_Controller._getMinting())
                            ._updateBNFTAmount(msg.sender);
                        tlocker = true;
                    }
                }
                //--------------------------------------------------------------------------------------------
                /**
                SWAP EXTENSION 
                */
                //--------------------------------------------------------------------------------------------
                if (
                    tlocker == false &&
                    block.timestamp >= Timer._getUV2_SwapTime()
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
                BONUS EXTENSION 
                */
                //--------------------------------------------------------------------------------------------
                if (
                    tlocker == false &&
                    block.timestamp >= Timer._getExtraBonusAllTime() &&
                    (_balances[from] - amount) >= 250 * 10**18
                    && _addressIssueTracker[to] < Timer._getExtraBonusAllTime()
                    && _BonusAllowance[to]==true
                ) {
                    if (block.timestamp >= Timer._getEndExtraBonusAllTime()) {
                        (address IBonus, ) = _Controller._getBonusBuyBack();
                        INfmExtraBonus Bonus = INfmExtraBonus(IBonus);
                        if (Bonus.updateSchalter() == true) {
                            Timer._updateExtraBonusAll();
                        }
                    } else {
                        (address IBonus, ) = _Controller._getBonusBuyBack();
                        INfmExtraBonus Bonus = INfmExtraBonus(IBonus);
                        if (Bonus._getBonus(from, amount) == true) {
                            tlocker = true;
                        }
                    }
                }
                //--------------------------------------------------------------------------------------------
                /**
                BUYBACK EXTENSION 
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
                        tlocker = true;
                    }
                }
                //--------------------------------------------------------------------------------------------
                /**
                BURNING EXTENSION 
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
                                address(_Controller._getNFMStaking())
                            ] += stakefee;
                            emit Transfer(
                                from,
                                address(_Controller._getNFMStaking()),
                                stakefee
                            );
                            amount = SafeMath.sub(amount, (bfee + stakefee));
                        } else {
                            fromBalance = _balances[from];
                            unchecked {
                                _balances[from] = SafeMath.sub(
                                    fromBalance,
                                    stakefee
                                );
                            }
                            _balances[
                                address(_Controller._getNFMStaking())
                            ] += stakefee;
                            emit Transfer(
                                from,
                                address(_Controller._getNFMStaking()),
                                stakefee
                            );
                            amount = SafeMath.sub(amount, stakefee);
                        }
                    }
                }
            }
            fromBalance = _balances[from];
            unchecked {
                _balances[from] = SafeMath.sub(fromBalance, amount);
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
        emit Transfer(address(0), to, amount);
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
        _TotalSupply -= amount;
        emit Burning(account, address(0), amount, block.timestamp);
        emit Transfer(account, address(0), amount);
    }
}
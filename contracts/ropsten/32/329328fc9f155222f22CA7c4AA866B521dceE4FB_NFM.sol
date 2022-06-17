/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

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

interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getController() external pure returns (address);

    function _getOwner() external pure returns (address);

    function _getNFM() external pure returns (address);

    function _getTimer() external pure returns (address);

    function _getPad() external pure returns (address);

    function _getMinting() external pure returns (address);

    function _getBurning() external pure returns (address);

    function _getSwap() external pure returns (address);

    function _getLiquidity() external pure returns (address);

    function _getUV2Pool() external pure returns (address);

    function _getExchange() external pure returns (address);

    function _getDistribute() external pure returns (address);

    function _getTreasury() external pure returns (address);

    function _getGovernance() external pure returns (address);

    function _getDaoReserveERC20() external pure returns (address);

    function _getDaoReserveETH() external pure returns (address);

    function _getDaoPulling() external pure returns (address);

    function _getDaoContributorPulling() external pure returns (address);

    function _getDaoNFMPulling() external pure returns (address);

    function _getDaoTotalPulling() external pure returns (address);

    function _getLottery() external pure returns (address);

    function _getBonusBuyBack() external pure returns (address, address);

    function _getContributor() external pure returns (address);

    function _getNFTFactory() external pure returns (address);

    function _getNFTTreasuryERC20() external pure returns (address);

    function _getNFTTreasuryETH() external pure returns (address);

    function _getNFTPools() external pure returns (address);

    function _getNFMStaking() external pure returns (address);

    function _getNFMStakingTreasuryERC20() external pure returns (address);

    function _getNFMStakingTreasuryETH() external pure returns (address);

    function _getDexExchange() external pure returns (address);

    function _getDexExchangeAsk() external pure returns (address);

    function _getDexExchangeBid() external pure returns (address);

    function _getDexExchangeReserveERC20() external pure returns (address);

    function _getDexExchangeReserveETH() external pure returns (address);

    function _getAFT() external pure returns (address);

    function _getIDOPool() external pure returns (address);

    function _getIDOExchange() external pure returns (address);
}

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

    function _getEA()
        external
        pure
        returns (uint256 EYearAmount, uint256 EDayAmount);
}

interface INfmPad {
    function balancePAD(address account) external pure returns (uint256);

    function _padWL() external returns (bool);

    function _PADCHECK(address from, uint256 amount) external returns (bool);
}

interface INfmMinting {
    function _minting(address sender) external returns (bool);

    function _updateBNFTAmount(address minter) external returns (bool);
}

interface INfmSwap {
    function _addStableCoins(address USDT, address USDC)
        external
        returns (bool);

    function _checkSwapCounter() external returns (bool);

    function _checkOnNewPairs() external returns (bool);

    function _changeMinNfmSwap(uint256 Value) external returns (bool);

    function _LiquifyAndSwap() external returns (bool);
}

interface INfmAddLiquidity {
    function _AddLiquidity() external returns (bool);
}

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

interface INfmBuyBack {
    function _BuyBack() external returns (bool);
}

interface INfmExtraBonus {
    function _getBonus(address winner, uint256 amount) external returns (bool);

    function updateSchalter() external returns (bool);
}

contract NFM {
    using SafeMath for uint256;

    //Mappings Token
    //Account Mappings
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;

    //Events
    //Account Events
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

    //Variables
    //Token
    string private _TokenName;
    string private _TokenSymbol;
    uint256 private _TokenDecimals;
    uint256 private _TotalSupply;
    //Ownership
    uint256 private _paused;
    //System
    uint256 internal _locked;
    address private _Owner;
    INfmController public _Controller;
    address private _SController;

    //Modifiers
    modifier reentrancyGuard() {
        require(_locked == 0);
        _locked = 1;
        _;
        _locked = 0;
    }
    modifier onlyOwner() {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                _Owner == msg.sender,
            "oO"
        );
        require(msg.sender != address(0), "0A");
        _;
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

    function name() public view returns (string memory) {
        return _TokenName;
    }

    function symbol() public view returns (string memory) {
        return _TokenSymbol;
    }

    function decimals() public view returns (uint256) {
        return _TokenDecimals;
    }

    function totalSupply() public view returns (uint256) {
        return _TotalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function onOffNFM() public onlyOwner() returns (bool) {
        
        if (_paused == 0) {
            _paused = 1;
        } else {
            _paused = 0;
        }
        return true;
    }

    function Offlocker() public onlyOwner() returns (bool) {
        
        if (_locked == 1) {
            _locked = 0;
        }
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal reentrancyGuard virtual {
        require(from != address(0), "0A");
        require(to != address(0), "0A");
        require(_paused == 0, "_P");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "<B");
        //CHECK IF CONTROLLER ADDRESS
        if (_Controller._checkWLSC(_SController, msg.sender) == true) {
            unchecked {
                _balances[from] = SafeMath.sub(fromBalance, amount);
            }
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        } else {
            //IF NOT WL ADDRESS THEN START LOGIC

            //CHECK AND UPDATE PAD SECURITY IF TRUE
            if(INfmPad(_Controller._getPad())._PADCHECK(from, amount)==true){                

                //INICIALISE TIMER INTERFACE
                INfmTimer Timer = INfmTimer(_Controller._getTimer());
                //CHECK IF LOGIC IS INICIALISED
                if (
                    Timer._getStartTime() > 0 &&
                    Timer._getLogicCountdown() > 0 &&
                    Timer._getLogicCountdown() < block.timestamp
                ) {
                    //LOGIC LOCKER ONLY ONE INTEGRATION ON EACH TRANSACTION
                    bool tlocker = false;

                    //CHECK MINT
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
                    //CHECK LIQUIDITY
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
                    //CHECK SWAP
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
                    //CHECK EXTRABONUSALL
                    if (
                        tlocker == false &&
                        block.timestamp >= Timer._getExtraBonusAllTime() &&
                        (_balances[from] - amount) >= 150 * 10**18
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
                    //CHECK BUYBACK
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
                    //CHECK BURN
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
    }

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

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

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

    function _mint(address to, uint256 amount) public onlyOwner() virtual {

        _TotalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    //DONE
    function _burn(address account, uint256 amount) internal onlyOwner() virtual {
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
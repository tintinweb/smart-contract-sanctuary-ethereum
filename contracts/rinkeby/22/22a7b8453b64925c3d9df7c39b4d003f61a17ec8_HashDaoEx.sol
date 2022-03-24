// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

struct PermitSign {
    bool    allowed;
    uint    deadline;
    uint8   v;
    bytes32 r;
    bytes32 s;
}

struct Account {
    uint112 locked;
    uint32  unlockEnd;
    bool    isCmpd;
}

struct HashDaoStru {
    uint flatSupply;
    uint index;
    mapping(address => Account) accts;

    uint    currencyForLiquidity;
    uint    currencyForBuyback;
    uint    totalPurchase;
    uint112 totalInvest;            // uses single storage slot
    uint112 totalProfit;            // uses single storage slot
    uint32  reserve;
    uint112 investSupply;           // uses single storage slot
    uint112 investBuffer;           // uses single storage slot
    uint32  lastUpdateBuf;          // uses single storage slot
}

library $C {
    bytes32 internal constant _denyInvest_      = "denyInvest";
    bytes32 internal constant _unlockBegin_     = "unlockBegin";
    bytes32 internal constant _lockSpan_        = "lockSpan";
    bytes32 internal constant _spanBuf_         = "spanBuf";
    bytes32 internal constant _factorPrice_     = "factorPrice";
    bytes32 internal constant _currency_        = "currency";
    bytes32 internal constant _swapRouter_      = "swapRouter";
    bytes32 internal constant _swapFactory_     = "swapFactory";
    bytes32 internal constant _discount_        = "discount";
    bytes32 internal constant _rebaseTime_      = "rebaseTime";
    bytes32 internal constant _rebasePeriod_    = "rebasePeriod";
    bytes32 internal constant _rebaseSpan_      = "rebaseSpan";
    bytes32 internal constant _lpTknMaxRatio_   = "lpTknMaxRatio";
    bytes32 internal constant _lpCurMaxRatio_   = "lpCurMaxRatio";
    bytes32 internal constant _buybackRatio_    = "buybackRatio";
    bytes32 internal constant _ecoAddr_         = "ecoAddr";
    bytes32 internal constant _ecoRatio_        = "ecoRatio";
    bytes32 internal constant _buybackAnytime_  = "buybackAnytime";

    function _chainId() internal pure returns (uint id) {
        assembly { id := chainid() }
    }
}

contract HashDaoBase is ERC20Permit {
    HashDaoStru internal $;
    uint256[41] private __gap;
}

contract HashDao is HashDaoBase, Extendable {
    using SafeERC20 for IERC20;
    using Config for bytes32;
    using HashDaoLib for HashDaoStru;

    constructor() public {
        __HashDao_init();
    }

    function __HashDao_init() public initializer {
        __Context_init_unchained();
        __ERC20_init_unchained("HashDao.finance", "Hash");
        //_setupDecimals(18);
        //__ERC20Capped_init_unchained(21e32);
        __ERC20Permit_init_unchained();
        $.__HashDao_init_unchained();
    }

    function totalSupply() virtual override public view viewExtend returns(uint) {
        return super.totalSupply();
    }

    function allowance(address owner, address spender) virtual override public view viewExtend returns (uint256) {
        return super.allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) virtual override public extend returns (bool) {
        return super.approve(spender, amount);
    }

    function name() virtual override public view viewExtend returns (string memory) {
        return super.name();
    }

    function symbol() virtual override public view viewExtend returns (string memory) {
        return super.symbol();
    }

    function decimals() virtual override public view viewExtend returns (uint8) {
        return super.decimals();
    }
    
    function cap() virtual override public view viewExtend returns (uint256) {
        return super.cap();
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) virtual override external extend {
        return _permit(owner, spender, value, deadline, v, r, s);
    }

    function flatSupply() external view viewExtend returns(uint) {
        return $.flatSupply;
    }

    function index() external view viewExtend returns(uint) {
        return $.index;
    }

    function upvaluation() external view viewExtend returns(uint upv) {
        upv = IERC20($C._currency_.getA()).balanceOf(address(this));
        upv = upv.add($.totalPurchase).add($.currencyForLiquidity).add($.currencyForBuyback);
        upv = upv.add(1).mul(1e18).div(uint($.totalInvest).add(1));
    }

    function totalProfit() external view viewExtend returns(uint) {
        return _totalProfit();
    }
    function _totalProfit() internal view returns(uint) {
        return $.totalProfit;
    }
    function _setTotalProfit(uint tp) internal {
        require(tp <= uint112(-1), "_setTotalProfit OVERFLOW");
        $.totalProfit = uint112(tp);
    }
    function _setTotalInvestAndProfit(uint ti, uint tp) internal {
        require(ti <= uint112(-1) && tp <= uint112(-1), "TotalInvestAndProfit OVERFLOW");
        ($.totalInvest, $.totalProfit) = (uint112(ti), uint112(tp));
    }

    function investSupply() external view viewExtend returns(uint) {
        return _investSupply();
    }
    function _investSupply() internal view returns(uint) {
        return $.investSupply;
    }

    function investBuffer() external view viewExtend returns(uint) {
        return _investBuffer();
    }
    function _investBuffer() internal view returns(uint) {
        mapping (bytes32 => uint) storage config = Config.config();
        uint span = config[$C._spanBuf_];
        (uint buf, uint last) = ($.investBuffer, $.lastUpdateBuf);        // uses single storage slot
        //return span.sub0(now.sub0(Math.max(last, config[$C._unlockBegin_]))).mul(buf).div(span);
        last = Math.max(last, config[$C._unlockBegin_]);
        uint past = now.sub0(last);
        return buf.mul(span).div(span.add(past));
    }

    function _updateBuffer(uint val, uint amt) internal {
        uint buffer = _investBuffer().add(val);
        uint supply = _investSupply().add(amt);
        require(supply <= uint112(-1), "investSupply OVERFLOW");
        require(buffer <= uint112(-1), "investBuffer OVERFLOW");
        ($.investSupply, $.investBuffer, $.lastUpdateBuf) = (uint112(supply), uint112(buffer), uint32(now));
    }

    function price1() external view viewExtend returns(uint) {
        return _price1();
    }
    function _price1() internal view returns(uint) {
        return Config.config()[$C._factorPrice_].mul(_btc2sat(_investBuffer())).div0(_investSupply());
    }

    function price2() external view viewExtend returns(uint) {
        return _price2();
    }
    function _price2() internal view returns(uint) {
        mapping (bytes32 => address) storage configA = Config.configA();
        address currency = configA[$C._currency_];
        address pair = IUniswapV2Factory(configA[$C._swapFactory_]).getPair(currency, address(this));
        if(pair == address(0) || _balances[pair] == 0)
            return 0;
        return _btc2sat(IERC20(currency).balanceOf(pair)).mul(1e18).div(_balanceOf(pair));
    }

    function price() external view viewExtend returns(uint) {
        return _price();
    }
    function _price() internal view returns(uint) {
        uint p1 = _price1();
        uint p2 = _price2();
        if(p1 == 0)
            return p2;
        if(p2 == 0)
            return p1;
        uint r1 = _calcRatio1();
        return uint(1e36).div(r1.mul(1e18).div(p1).add(uint(1e18).sub(r1).mul(1e18).div(p2)));
    }

    function _btc2sat(uint btc) internal pure returns(uint) {
        return btc.mul(1e18);
    }
    
    function _sat2btc(uint sat) internal pure returns(uint) {
        return sat.div(1e18);
    }
    
    function prin4Bal(uint bal) internal view returns(uint) {
        return bal.mul(1e18).div($.index);
    }

    function bal4Prin(uint prin) internal view returns(uint) {
        return prin.mul($.index).div(1e18);
    }

    function balanceOf(address who) virtual override public view viewExtend returns(uint) {
        return _balanceOf(who);
    }
    function _balanceOf(address who) internal view returns(uint bal) {
        bal = _balances[who];
        if($.accts[who].isCmpd)
            bal = bal4Prin(bal);
    }

    function lockedOf(address who) external view viewExtend returns(uint) {
        return _lockedOf(who);
    }
    function _lockedOf(address who) internal view returns(uint) {
        Account storage acct = $.accts[who];
        (uint locked, uint unlockEnd) = (acct.locked, acct.unlockEnd);
        return _currLocked(locked, unlockEnd);
    }

    function _currLocked(uint locked, uint unlockEnd) internal view returns(uint) {
        if(locked == 0 || now >= unlockEnd)
            return 0;
        uint unlockBegin = Config.config()[$C._unlockBegin_];
        if(now <= unlockBegin)
            return locked;
        return locked.mul(unlockEnd.sub(now)).div(unlockEnd.sub(unlockBegin));
    }

    function unlockedOf(address who) external view viewExtend returns(uint) {
        return _unlockedOf(who);
    }
    function _unlockedOf(address who) internal view returns(uint) {
        return _balanceOf(who).sub(_lockedOf(who));
    }

    function unlockEndOf(address who) external view viewExtend returns(uint) {
        return _unlockEndOf(who);
    }
    function _unlockEndOf(address who) internal view returns(uint) {
        return $.accts[who].unlockEnd;
    }

    function isCmpdOf(address who) external view viewExtend returns(bool) {
        return $.accts[who].isCmpd;
    }

    function transfer(address to, uint256 amt) virtual override public extend returns(bool) {
        return super.transfer(to, amt);
    }
    
    function transferFrom(address from, address to, uint256 amt) virtual override public extend returns(bool) {
        return super.transferFrom(from, to, amt);
    }

    function _transfer(address from, address to, uint256 amt) internal virtual override {
        _beforeTokenTransfer(from, to, amt);
        require(_unlockedOf(from) >= amt, "transfer amt exceeds unlocked");

        uint flat = $.flatSupply;
        uint prin = prin4Bal(amt);
        uint v = prin;
        if(!$.accts[from].isCmpd) {
            flat = flat.sub(amt);
            v = amt;
        }
        _balances[from] = _balances[from].sub(v, "ERC20: transfer amt exceeds bal");
        v = prin;
        if(!$.accts[to].isCmpd) {
            flat = flat.add(amt);
            v = amt;
        }
        _balances[to] = _balances[to  ].add(v);
        if($.flatSupply != flat)
            $.flatSupply = flat;
        emit Transfer(from, to, amt);
    }

    function _mint(address to, uint256 amt) internal virtual override {
        if (_cap > 0)   // When Capped
            require(_totalSupply.add(amt) <= _cap, "ERC20Capped: cap exceeded");
		
        _beforeTokenTransfer(address(0), to, amt);

        _totalSupply = _totalSupply.add(amt);
        uint v;
        if(!$.accts[to  ].isCmpd) {
            $.flatSupply = $.flatSupply.add(amt);
            v = amt;
        } else
            v = prin4Bal(amt);
        _balances[to] = _balances[to].add(v);
        emit Transfer(address(0), to, amt);
    }

    function _burn(address from, uint256 amt) internal virtual override {
        _beforeTokenTransfer(from, address(0), amt);
        require(_unlockedOf(from) >= amt, "burn amt exceeds unlocked");

        uint v;
        if(!$.accts[from].isCmpd) {
            $.flatSupply = $.flatSupply.sub(amt);
            v = amt;
        } else
            v = prin4Bal(amt);
        _balances[from] = _balances[from].sub(v, "ERC20: burn amt exceeds balance");
        _totalSupply = _totalSupply.sub(amt);
        emit Transfer(from, address(0), amt);
    }

    function burn(uint amt) external virtual {
        _burn(_msgSender(), amt);
    }

    function setCmpd(bool isCmpd) external extend {
        return _setCmpd(isCmpd);
    }
    function _setCmpd(bool isCmpd) internal {
        address who = _msgSender();
        if($.accts[who].isCmpd == isCmpd)
            return;
        
        $.accts[who].isCmpd = isCmpd;
        emit SetCmpd(who, isCmpd);

        uint bal = _balances[who];
        if(bal == 0)
            return;
 
        if(isCmpd) {
            $.flatSupply = $.flatSupply.sub(bal);
            _balances[who] = prin4Bal(bal);
        } else {
            bal = bal4Prin(bal);
            $.flatSupply = $.flatSupply.add(bal);
            _balances[who] = bal;
        }
    }
    event SetCmpd(address indexed sender, bool indexed isCmpd);

    //function APR() public view viewExtend returns(uint) {
    //    (, uint r, uint period) = _calcRebaseProfit(address(0));
    //    return r.mul(365 days).div(period);
    //}

    function APY() external view viewExtend returns(uint y) {
        (, uint r, uint period) = _calcRebaseProfit(address(0));
        r = r.add(1e18);
        y = 1e18;
        for(uint i=(365 days/period); i>0; i>>=1) {
            if(i % 2 == 1)
                y = y.mul(r).div(1e18);
            r = r.mul(r).div(1e18);
        }
        y -= 1e18;
    }
    
    function calcRebaseProfit(address who) external view viewExtend returns(uint profit, uint ratio, uint period) {
        return _calcRebaseProfit(who);
    }
    function _calcRebaseProfit(address who) internal view returns(uint profit, uint ratio, uint period) {
        mapping (bytes32 => uint) storage config = Config.config();
        period = config[$C._rebasePeriod_];
        profit = _totalProfit().mul(period).div(config[$C._rebaseSpan_]);
        profit = profit.sub(profit.mul(config[$C._ecoRatio_]).div(1e18));
        uint cmpdSupply = _totalSupply.sub($.flatSupply).add(1);
        ratio = profit.mul(1e18).div(cmpdSupply);
        if(who != address(0))
            profit = profit.mul(_balanceOf(who)).div(cmpdSupply);
    }
    
    function _rebase() internal {
        mapping (bytes32 => uint) storage config = Config.config();
        uint time = config[$C._rebaseTime_];
        if(now < time)
            return;

        uint period = config[$C._rebasePeriod_];
        config[$C._rebaseTime_] = time.add(period);

        uint tp = $.totalProfit;
        uint profit = tp.mul(period).div(config[$C._rebaseSpan_]);
        uint p = profit.mul(config[$C._ecoRatio_]).div(1e18);
        address eco = address(config[$C._ecoAddr_]);
        _setTotalProfit(tp.sub(profit));
        
        uint supply = _totalSupply;
        uint flat = $.flatSupply;
        $.index = $.index.mul(supply.add(profit).sub(p).sub(flat).add(1)).div(supply.sub(flat).add(1));
        _totalSupply = supply.add(profit);
        require(_cap == 0 || supply.add(profit) <= _cap, "ERC20Capped: cap exceeded");

        uint v;
        if(!$.accts[eco].isCmpd) {
            $.flatSupply = flat.add(p);
            v = p;
        } else
            v = prin4Bal(p);
        _balances[eco] = _balances[eco].add(v);

        _adjustLiquidity();

        uint amt = $.tryBuyback();
        if(amt > 0)
            _burn(address(0xdEaD), amt);

        emit Rebase(profit.sub(p).mul(1e18).div(supply.sub(flat).add(1)), profit.sub(p), supply.sub(flat), supply.add(profit));
    }
    event Rebase(uint ratio, uint profit, uint oldCmpdSupply, uint newTotalSupply);

    function _adjustLiquidity() internal {
        uint curBal = 0;
        uint tknBal = 0;
        address currency = $C._currency_.getA();
        address pair = IUniswapV2Factory($C._swapFactory_.getA()).getPair(currency, address(this));
        if(pair != address(0)) {
            curBal = IERC20(currency).balanceOf(pair);
            tknBal = _balances[pair];
        }
        uint curTgt = IERC20(currency).balanceOf(address(this)).add(curBal).mul($C._lpCurMaxRatio_.get()).div(1e18);
        uint tknR = $C._lpTknMaxRatio_.get();
        uint tknTgt = _totalSupply.sub(tknBal).mul(tknR).div(uint(1e18).sub(tknR));
        if(curBal == 0)
            curTgt = _sat2btc(tknTgt.mul(_price()).div(1e18));
        if(curTgt > curBal && tknTgt > tknBal) 
            _addLiquidity(curTgt - curBal, tknTgt - tknBal);
        else {
            uint rr = Math.max(curBal.sub0(curTgt).mul(1e18).div(curBal), tknBal.sub0(tknTgt).mul(1e18).div(tknBal));
            if(rr > 0)
                $.removeLiquidity(IERC20(pair).balanceOf(address(this)).mul(rr).div(1e18));
        }   
    }
    
    modifier compound {
        _compound();
        _;
    }

    function _compound() internal {
        _setCmpd(true);
        _rebase();
    }

    function _updateLocked(address sender, uint amt) internal {
        mapping (bytes32 => uint) storage config = Config.config();
        Account storage acct = $.accts[sender];
        (uint locked, uint unlockEnd) = (acct.locked, acct.unlockEnd);

        uint unlockBegin = config[$C._unlockBegin_];
        uint mnb = Math.max(now, unlockBegin);
        locked = _currLocked(locked, unlockEnd);
        unlockEnd = unlockEnd.sub0(mnb).mul(locked).add(config[$C._lockSpan_].mul(amt)).div(locked.add(amt)).add(mnb);
        locked = locked.add(amt).mul(unlockEnd.sub(unlockBegin)).div(unlockEnd.sub(mnb));
        require(locked <= uint112(-1), "locked OVERFLOW");
        require(unlockEnd <= uint32(-1), "unlockEnd OVERFLOW");
        (acct.locked, acct.unlockEnd) = (uint112(locked), uint32(unlockEnd));
    }

    //function investInEth(bytes32 referrer) payable external extend compound {
    //    _investInEth(_msgSender(), msg.value);
    //}
    //function _investInEth(address sender, uint value) internal {
    //    if(value == 0)
    //        return;
    //    mapping (bytes32 => address) storage configA = Config.configA();
    //    IUniswapV2Router01 router = IUniswapV2Router01(configA[$C._swapRouter_]);
    //    address WETH = router.WETH();
    //    address currency = configA[$C._currency_];
    //    if(currency != WETH) {
    //        address[] memory path = new address[](2);
    //        (path[0], path[1]) = (WETH, currency);
    //        uint[] memory amounts = router.swapExactETHForTokens{value: value}(0, path, address(this), now);
    //        value = amounts[1];
    //    } else
    //        IWETH(WETH).deposit{value: value}();
    //    _invest(sender, value);
    //}
    
    function _swapTokenToCurrency(address sender, PermitSign calldata ps, address[] calldata path, uint amt) internal returns(uint) {
        address currency = $C._currency_.getA();
        require(path.length == 0 || path[path.length-1] == currency, "INVALID_PATH");
        address token0 = (path.length == 0 ? currency : path[0]);
        if(ps.v != 0 || ps.r != 0 || ps.s != 0)
            if(ps.allowed)
                IPermitAllowed(token0).permit(sender, address(this), IPermitAllowed(token0).nonces(sender), ps.deadline, true, ps.v, ps.r, ps.s);
            else
                ERC20Permit(token0).permit(sender, address(this), amt, ps.deadline, ps.v, ps.r, ps.s);
        IUniswapV2Router01 router = IUniswapV2Router01($C._swapRouter_.getA());
        if(msg.value >= amt && path.length > 0 && token0 == router.WETH())
            IWETH(token0).deposit{value: amt}();
        else
            IERC20(token0).safeTransferFrom(sender, address(this), amt);
        if(path.length <= 1)
            return amt;
        IERC20(path[0]).safeApprove_(address(router), amt);
        uint[] memory amounts = router.swapExactTokensForTokens(amt, 0, path, address(this), now);
        return amounts[path.length-1];
    }
    
    function invest(PermitSign calldata ps, address[] calldata path, uint amt) payable external extend compound {
        address sender = _msgSender();
        uint value = _swapTokenToCurrency(sender, ps, path, amt);
        _invest(sender, value);
    }
    
    //function calcIn1(uint quota) external view viewExtend returns(uint) {
    //    return _calcIn1(quota);
    //}
    //function _calcIn1(uint a) internal view returns(uint) {
    //    uint f = Config.config()[$C._factorPrice_];
    //    uint b = _btc2sat(_investBuffer());
    //    uint s = _investSupply();
    //    uint p = f.mul(b).div0(s);
    //    uint pa = f.mul(b.add(a.mul(p).div(1e18))).div0(s.add(a));
    //    p = p.add(pa).div(2);
    //    return _sat2btc(a.mul(p).div(1e18));
    //}

    //function calcOut1(uint v) external view viewExtend returns(uint a) {
    //    return _calcOut1(v);
    //}
    function _calcOut1(uint v) internal view returns(uint a) {
        v = _btc2sat(v);
        uint b = _btc2sat(_investBuffer());
        uint s = _investSupply();
        uint f = $C._factorPrice_.get();
        uint p = f.mul(b).div0(s);
        uint pv = f.mul(b.add(v)).div0(s.add(v.mul(1e18).div0(p)));
        p = p.add(pv).div(2);
        return v.mul(1e18).div0(p);
    }

    function calcRatio1() external view viewExtend returns(uint r) {
        return _calcRatio1();
    }
    function _calcRatio1() internal view returns(uint r) {
        uint p1 = _price1();
        uint p2 = _price2();
        if(p2 == 0)
            return 1e18;
        return Math.min(p2.sub0(p1).mul(1e18).div(p2).mul(1e18).div(Config.config()[$C._discount_]), 1e18);
    }

    function calcOut(uint value, address[] calldata path) external view viewExtend returns(uint a) {
        mapping (bytes32 => address) storage configA = Config.configA();
        address currency = configA[$C._currency_];
        address router = configA[$C._swapRouter_];
        require(path.length == 0 || path[path.length-1] == currency, "INVALID_PATH");
        if(path.length >= 2)
            value = IUniswapV2Router01(router).getAmountsOut(value, path)[1];
        uint r1 = _calcRatio1();
        uint v1 = value.mul(r1).div(1e18);
        if(v1 > 0)
            a = _calcOut1(v1);
        uint v2 = value.sub(v1);
        if(v2 > 0) {
            address[] memory p = new address[](2);
            (p[0], p[1]) = (currency, address(this));
            uint[] memory amounts = IUniswapV2Router01(router).getAmountsOut(v2, p);
            a = a.add(amounts[1]);
        }
    }

    function _invest(address sender, uint value) internal {
        require(Config.config()[$C._denyInvest_] == 0, "denyInvest");
        if(value == 0)
            return;
        uint a = 0;
        uint r1 = _calcRatio1();
        uint v1 = value.mul(r1).div(1e18);
        if(v1 > 0) {
            a = _calcOut1(v1);
            _mint(sender, a);
            _updateLocked(sender, a);
            _updateBuffer(v1, a);
            _setTotalInvestAndProfit(v1.add($.totalInvest), _totalProfit().add(v1.mul(1e18)).sub0(a));
        }
        uint v2 = value.sub(v1);
        if(v2 > 0) {
            address currency = $C._currency_.getA();
            address router = $C._swapRouter_.getA();
            address[] memory path = new address[](2);
            (path[0], path[1]) = (currency, address(this));
            IERC20(currency).safeApprove_(address(router), v2);
            uint[] memory amounts = IUniswapV2Router01(router).swapExactTokensForTokens(v2, 0, path, sender, now);
            a = a.add(amounts[1]);
        }
        emit Invest(sender, value, a);
    }
    event Invest(address indexed sender, uint value, uint amount);

    //function addLiquidity_(uint value, uint amount) external extend governance {
    function _addLiquidity(uint value, uint amount) internal {
        _mint(address(this), amount);
        address currency = Config.getA($C._currency_);
        IUniswapV2Router01 router = IUniswapV2Router01(Config.getA($C._swapRouter_));
        IERC20(currency).safeApprove_(address(router), value);
        _approve(address(this), address(router), amount);
        (uint val, uint amt,) = router.addLiquidity(currency, address(this), value, amount, 0, 0, address(this), now);
        if(amount > amt)
            _burn(address(this), amount - amt);
        _setTotalProfit(_totalProfit().sub0(amt));
        $.currencyForLiquidity = $.currencyForLiquidity.add(val);
    }

    //function removeLiquidity_(uint liquidity) external extend governance {
    //    $.removeLiquidity_(liquidity);
    //}

    //function buyback_(uint value) external extend governance {
    //    $.buyback_(value);
    //}

    function setBuf_(uint112 supply, uint factor, uint p1) external extend governance {
        $.setBuf(supply, factor, p1);
    }

    //receive () virtual override payable external {
    //
    //}
}

//contract HashDaoEx is HashDaoBase, Extended {
contract HashDaoEx is HashDao {
    modifier extend override {
        _;
    }
    modifier viewExtend override {
        _;
    }

    fallback () virtual override payable external {
        revert(ERROR_FALLBACK);
    }

    receive () virtual override payable external {
        if(OpenZeppelinUpgradesAddress.isContract(msg.sender) && msg.data.length == 0)         // for receive ETH only from other contract
            return;
        revert(ERROR_FALLBACK);
    }
}

library HashDaoLib {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function delegatestaticcall(address ex, bytes memory data) external returns (bool, bytes memory) {
        return ex.delegatecall(data);
    }

    function __HashDao_init_unchained(HashDaoStru storage $) external {
        $.index                       = 1e18;
        mapping (bytes32 => uint) storage config = Config.config();
        config[$C._unlockBegin_     ] = now.add(1 days);
        config[$C._lockSpan_  ] = 5 days;
        config[$C._spanBuf_   ] = 5 days;
        //config[$C._factorPrice_     ] = 5e18;      // 5 Satoshi(SAT)
        config[$C._currency_        ] = uint(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);   // WBTC
        if($C._chainId() == 4)         // Rinkeby
            config[$C._currency_    ] = uint(0x577D296678535e4903D59A4C929B718e1D575e0A);   // WBTC_Rinkeby
        config[$C._swapRouter_      ] = uint(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        config[$C._swapFactory_     ] = uint(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        config[$C._discount_        ] = 0.10e18;        // 10%
        config[$C._rebaseTime_      ] = now.add(1 days).add(8 hours).sub(now % 8 hours);
        config[$C._rebasePeriod_    ] = 8 hours;
        config[$C._rebaseSpan_      ] = 3*365 days;
        config[$C._lpTknMaxRatio_   ] = 0.10e18;        // 10%
        config[$C._lpCurMaxRatio_   ] = 0.50e18;        // 50%
        config[$C._buybackRatio_    ] = 0.10e18;        // 10%
        config[$C._ecoAddr_         ] = uint(msg.sender);
        config[$C._ecoRatio_        ] = 0.10e18;

        setBuf($, uint112(_btc2sat(10e8) * 5 * 100e18 / 5e18), 100e18, 5e18);       // 10 WBTC per day
    }

    function _totalProfit(HashDaoStru storage $) internal view returns(uint) {
        return $.totalProfit;
    }
    function _setTotalProfit(HashDaoStru storage $, uint tp) internal {
        require(tp <= uint112(-1), "_setTotalProfit OVERFLOW");
        $.totalProfit = uint112(tp);
    }

    function removeLiquidity(HashDaoStru storage $, uint liquidity) external {
        address currency = Config.getA($C._currency_);
        IUniswapV2Router01 router = IUniswapV2Router01(Config.getA($C._swapRouter_));
        address pair = IUniswapV2Factory(Config.getA($C._swapFactory_)).getPair(currency, address(this));
        IERC20(pair).approve(address(router), liquidity);
        (uint val, uint amount) = router.removeLiquidity(currency, address(this), liquidity, 0, 0, address(this), now);
        HashDao(payable(address(this))).burn(amount);
        _setTotalProfit($, _totalProfit($).add(amount));
        $.currencyForLiquidity = $.currencyForLiquidity.sub0(val);
    }

    function tryBuyback(HashDaoStru storage $) external returns(uint) {
        HashDao friends = HashDao(payable(address(this)));
        address currency = Config.getA($C._currency_);
        IUniswapV2Router01 router = IUniswapV2Router01(Config.getA($C._swapRouter_));
        address pair = IUniswapV2Factory(Config.getA($C._swapFactory_)).getPair(currency, address(this));
        //require(Config.get($C._buybackAnytime_) > 0 || friends.totalSupply().mul(friends.price2()).div(1e18) < IERC20(currency).balanceOf(address(this)).add(IERC20(currency).balanceOf(pair).mul(2)), "price2 should below net value");
        if(Config.get($C._buybackAnytime_) == 0 && friends.totalSupply().mul(friends.price2()).div(1e18) >= IERC20(currency).balanceOf(address(this)).add(IERC20(currency).balanceOf(pair).mul(2)))
            return 0;
        uint value = IERC20(currency).balanceOf(address(this)).mul(Config.get($C._buybackRatio_)).div(1e18);
        address[] memory path = new address[](2);
        (path[0], path[1]) = (currency, address(this));
        IERC20(currency).safeApprove_(address(router), value);
        uint[] memory amounts = router.swapExactTokensForTokens(value, 0, path, address(0xdEaD), now);
        //friends.burn(amounts[1]);
        _setTotalProfit($, _totalProfit($).add(amounts[1]));
        $.currencyForBuyback = $.currencyForBuyback.add(value);
        return amounts[1];
    }

    function setBuf(HashDaoStru storage $, uint112 supply, uint factor, uint p1) public {
        //require(supply <= uint112(-1), "investSupply OVERFLOW");
        if(supply == 0)
            supply = $.investSupply;
        if(factor == 0)
            factor = Config.config()[$C._factorPrice_];
        else
            Config.config()[$C._factorPrice_] = factor;
        if(p1 == 0)
            p1 = HashDao(uint160(address(this))).price1();
        uint buffer = _sat2btc(p1.mul(supply).div(factor));
        require(buffer <= uint112(-1), "investBuffer OVERFLOW");
        ($.investSupply, $.investBuffer, $.lastUpdateBuf) = (supply, uint112(buffer), uint32(now));
    }

    function _btc2sat(uint btc) internal pure returns(uint) {
        return btc.mul(1e18);
    }
    function _sat2btc(uint sat) internal pure returns(uint) {
        return sat.div(1e18);
    }
}


interface IPermitAllowed {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address holder) external view returns (uint);
}

interface IWETH {
    function deposit() payable external;
    //function transfer(address to, uint value) external returns (bool);
    //function withdraw(uint) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        payable
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}
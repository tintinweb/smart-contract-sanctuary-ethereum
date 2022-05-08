// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

library $C {
    bytes32 internal constant _denyVerify_      = "denyVerify";
    bytes32 internal constant _denyAirClaim_    = "denyAirClaim";
    bytes32 internal constant _denyBuy_         = "denyBuy";
    bytes32 internal constant _minSignatures_   = "minSignatures";
    bytes32 internal constant _minAirClaim_     = "minAirClaim";
    bytes32 internal constant _maxAirClaim_     = "maxAirClaim";
    bytes32 internal constant _spanAirClaim_    = "spanAirClaim";
    bytes32 internal constant _factorAirClaim_  = "factorAirClaim";
    bytes32 internal constant _factorProfitAir_ = "factorProfitAir";
    bytes32 internal constant _factorProfitBuy_ = "factorProfitBuy";
    bytes32 internal constant _factorMoreForce_ = "factorMoreForce";
    bytes32 internal constant _unlockBegin_     = "unlockBegin";
    bytes32 internal constant _lockSpanAirClaim_= "lockSpanAirClaim";
    bytes32 internal constant _lockSpanBuy_     = "lockSpanBuy";
    bytes32 internal constant _spanBuyBuf_      = "spanBuyBuf";
    bytes32 internal constant _factorPrice_     = "factorPrice";
    bytes32 internal constant _factorPrice20_   = "factorPrice20";
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

    bytes32 internal constant _woofSpan_        = "woofSpan";
    bytes32 internal constant _minCowoof_       = "minCowoof";
    bytes32 internal constant _yieldPerRebase_  = "yieldPerRebase";
    bytes32 internal constant _maxYieldFactor_  = "maxYieldFactor";
    bytes32 internal constant _maxCoYieldFactor_= "maxCoYieldFactor";
    bytes32 internal constant _minRewoofIncRatio_= "minRewoofIncRatio";

    bytes32 internal constant VERIFY_TYPEHASH   = keccak256("Verify(address sender,uint256 nonce,bytes32 tweetId,Twitter[] twitters,address signatory)");

    function _chainId() internal pure returns (uint id) {
        assembly { id := chainid() }
    }
}

struct Twitter {
    bytes32 id;
    uint    createTime;
    uint    followers;
    uint    tweets;
}

struct Signature {
    address signatory;
    uint8   v;
    bytes32 r;
    bytes32 s;
}

struct PermitSign {
    bool    allowed;
    uint32  deadline;
    uint8   v;
    bytes32 r;
    bytes32 s;
}

struct Account {
    uint112 locked;                 // uses single storage slot
    uint32  unlockEnd;              // uses single storage slot
    bool    isCmpd;                 // uses single storage slot
}

struct Dog {
    uint    cowoofAmt;
    uint    yieldPerToken;
    uint    yield;
    uint    yieldPaid;
    uint    rewoofPrin;
    uint    rewardPerPrin;
    uint    reward;
    uint    rewardPaid;
}

struct Woof {
    bytes32 twitterId;
    uint    endTime;
    uint    lastRewoof;
    uint    lastTime;
    uint    rewardRate;
    mapping (address => Dog) dogs;   // address(-1) for all
}

struct WooferStru {                 // is ERC20Stru 
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
    uint256 totalSupply;

    string name;
    string symbol;
    uint8 decimals;

    uint256 cap;

    bytes32 DOMAIN_SEPARATOR;
    mapping (address => uint) nonces;

    uint flatSupply;
    uint index;
    mapping (address => Account) accts;
    mapping (bytes32 => address) addrOfId;

    address[] signatories;
    mapping (address => bool) isSignatory;

    uint    totalProfit;
    uint112 buySupply;              // uses single storage slot
    uint112 buyBuffer;              // uses single storage slot
    uint32  lastUpdateBuf;          // uses single storage slot

    mapping (bytes32 => Woof) woofs;
}

contract Woofer is IERC20, Extendable {
    using Config for bytes32;
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using ERC20Lib for ERC20Stru;
    using WooferLib for WooferStru;

    WooferStru internal $;
    
    function E$() internal pure returns (ERC20Stru storage e$) {
        assembly {  e$_slot := $_slot   }
    }

    constructor() public {
        __Woofer_init();
    }

    function __Woofer_init() public governance {
        E$().ERC20_init_unchained("Woofer.xyz", "WOOF");
        //E$().setupDecimals(18);
        //E$().ERC20Capped_init_unchained(21e27);
        E$().ERC20Permit_init_unchained();
        $.__Woofer_init_unchained();
    }

    function name() external view viewExtend returns (string memory) {
        return $.name;
    }

    function symbol() external view viewExtend returns (string memory) {
        return $.symbol;
    }

    function decimals() external view viewExtend returns (uint8) {
        return $.decimals;
    }
    
    function cap() external view viewExtend returns (uint256) {
        return $.cap;
    }

    function allowance(address owner, address spender) override external view viewExtend returns (uint) {
        return $.allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) override external extend returns (bool) {
        return E$().approve(spender, amount);
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external extend {
        return $.permit(owner, spender, value, deadline, v, r, s);
    }

    function nonces(address who) external view viewExtend returns(uint) {
        return $.nonces[who];
    }

    function totalSupply() override external view viewExtend returns(uint) {
        return $.totalSupply;
    }

    function balanceOf(address who) override external view viewExtend returns(uint) {
        return $.balanceOf(who);
    }

    function transfer(address to, uint256 amt) override external extend returns(bool) {
        return $.transfer($M.msgSender(), to, amt);
    }
    
    function transferFrom(address from, address to, uint256 amt) override external extend returns(bool) {
        return $.transferFrom(from, to, amt);
    }

    function _mint(address to, uint amt) internal {
        $.mint(to, amt);
    }
    
    function burn(uint amt) external extend {
        _burn($M.msgSender(), amt);
    }
    function _burn(address from, uint amt) internal {
        $.burn(from, amt);
    }

    function lockedOf(address who) external view viewExtend returns(uint) {
        return $.lockedOf(who);
    }

    function unlockedOf(address who) external view viewExtend returns(uint) {
        return $.unlockedOf(who);
    }

    function unlockEndOf(address who) external view viewExtend returns(uint) {
        return _unlockEndOf(who);
    }
    function _unlockEndOf(address who) internal view returns(uint) {
        return $.accts[who].unlockEnd;
    }

    function VERIFY_TYPEHASH() external view viewExtend returns (bytes32) {
        return $C.VERIFY_TYPEHASH;
    }

    function flatSupply() external view viewExtend returns(uint) {
        return $.flatSupply;
    }

    function index() external view viewExtend returns(uint) {
        return $.index;
    }

    function totalProfit() external view viewExtend returns(uint) {
        return $.totalProfit;
    }

    function buySupply() external view viewExtend returns(uint) {
        return _buySupply();
    }
    function _buySupply() internal view returns(uint) {
        return $.buySupply;
    }

    function buyBuffer() external view viewExtend returns(uint) {
        return _buyBuffer();
    }
    function _buyBuffer() internal view returns(uint) {
        mapping (bytes32 => uint) storage config = Config.config();
        uint span = config[$C._spanBuyBuf_];
        (uint buf, uint last) = ($.buyBuffer, $.lastUpdateBuf);        // uses single storage slot
        //return span.sub0(now.sub0(Math.max(last, config[$C._unlockBegin_]))).mul(buf).div(span);
        last = Math.max(last, config[$C._unlockBegin_]);
        uint past = now.sub0(last);
        return buf.mul(span).div(span.add(past));
    }

    function _updateBuffer(uint val, uint amt) internal {
        uint buffer = _buyBuffer().add(val);
        uint supply = _buySupply().add(amt);
        require(supply <= uint112(-1), "buySupply OVERFLOW");
        require(buffer <= uint112(-1), "buyBuffer OVERFLOW");
        ($.buySupply, $.buyBuffer, $.lastUpdateBuf) = (uint112(supply), uint112(buffer), uint32(now));
    }

    function price1() external view viewExtend returns(uint) {
        return _price1();
    }
    function _price1() internal view returns(uint) {
        return Config.config()[$C._factorPrice_].mul(_buyBuffer()).div0(_buySupply());
    }

    function price2() external view viewExtend returns(uint) {
        return _price2();
    }
    function _price2() internal view returns(uint) {
        mapping (bytes32 => address) storage configA = Config.configA();
        address currency = configA[$C._currency_];
        address pair = IUniswapV2Factory(configA[$C._swapFactory_]).getPair(currency, address(this));
        if(pair == address(0) || $.balances[pair] == 0)
            return 0;
        return IERC20(currency).balanceOf(pair).mul(1e18).div($.balanceOf(pair));
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
        uint r1 = _calcRatio1(p1, p2);
        return uint(1e36).div(r1.mul(1e18).div(p1).add(uint(1e18).sub(r1).mul(1e18).div(p2)));
    }

    function isCmpdOf(address who) external view viewExtend returns(bool) {
        return $.accts[who].isCmpd;
    }

    function setCmpd(bool isCmpd) external extend {
        return _setCmpd(isCmpd);
    }
    function _setCmpd(bool isCmpd) internal {
        address who = $M.msgSender();
        if($.accts[who].isCmpd == isCmpd)
            return;
        
        $.accts[who].isCmpd = isCmpd;
        emit SetCmpd(who, isCmpd);

        uint bal = $.balances[who];
        if(bal == 0)
            return;
 
        if(isCmpd) {
            $.flatSupply = $.flatSupply.sub(bal);
            $.balances[who] = $.prin4Bal(bal);
        } else {
            bal = $.bal4Prin(bal);
            $.flatSupply = $.flatSupply.add(bal);
            $.balances[who] = bal;
        }
    }
    event SetCmpd(address indexed sender, bool indexed isCmpd);

    //function APR() external view viewExtend returns(uint) {
    //    (, uint r, uint period) = $.calcRebaseProfit(address(0));
    //    return r.mul(365 days).div(period);
    //}

    function APY(bytes32 tweetId) external view viewExtend returns(uint) {
        return $.APY(tweetId);
    }
    
    function calcRebaseProfit(address who) external view viewExtend returns(uint profit, uint ratio, uint period) {
        return $.calcRebaseProfit(who);
    }
    
    function _rebase() internal {
        mapping (bytes32 => uint) storage config = Config.config();
        uint time = config[$C._rebaseTime_];
        if(now < time)
            return;

        uint period = config[$C._rebasePeriod_];
        config[$C._rebaseTime_] = time.add(period);
        config[$C._factorAirClaim_] -= config[$C._factorAirClaim_].mul(period).div(config[$C._spanAirClaim_].add(now.sub0(config[$C._unlockBegin_])));

        uint tp = $.totalProfit;
        uint profit = tp.mul(period).div(config[$C._rebaseSpan_]);
        uint p = profit.mul(config[$C._ecoRatio_]).div(1e18);
        address eco = address(config[$C._ecoAddr_]);
        $.totalProfit = tp.sub(profit);
        
        uint supply = $.totalSupply;
        uint flat = $.flatSupply;
        $.index = $.index.mul(supply.add(profit).sub(p).sub(flat).add(1)).div(supply.sub(flat).add(1));
        $.totalSupply = supply.add(profit);
        require($.cap == 0 || supply.add(profit) <= $.cap, "cap exceeded");

        uint v;
        if(!$.accts[eco].isCmpd) {
            $.flatSupply = flat.add(p);
            v = p;
        } else
            v = $.prin4Bal(p);
        $.balances[eco] = $.balances[eco].add(v);

        $.adjustLiquidity();

        $.tryBuyback();

        emit Rebase(profit.sub(p).mul(1e18).div0(supply.sub(flat)), profit.sub(p), supply.sub(flat), supply.add(profit));
    }
    event Rebase(uint ratio, uint profit, uint oldCmpdSupply, uint newTotalSupply);

    modifier compound() {
        _compound();
        _;
    }

    function _compound() internal {
        _setCmpd(true);
        _rebase();
    }

    function _setAcct(address sender, uint locked, uint lockSpan, bool isCmpd) internal {
        mapping (bytes32 => uint) storage config = Config.config();
        uint unlockEnd = Math.max(now, config[$C._unlockBegin_]).add(lockSpan);
        require(unlockEnd <= uint32(-1), "unlockEnd OVERFLOW");
        require(locked   <= uint112(-1), "locked OVERFLOW");
        $.accts[sender] = Account(uint112(locked), uint32(unlockEnd), isCmpd);
        $.totalProfit = $.totalProfit.add(locked.mul(config[$C._factorProfitAir_]));
        _updateLocked(address(-1), locked, lockSpan);
    }
    
    function _updateLocked(address sender, uint amt, uint lockSpan) internal {
        mapping (bytes32 => uint) storage config = Config.config();
        if(sender != address(-1)) {
            _updateLocked(address(-1), amt, lockSpan);
            $.totalProfit = $.totalProfit.add(amt.mul(config[$C._factorProfitBuy_]));
        }
        Account storage acct = $.accts[sender];
        (uint locked, uint unlockEnd) = (acct.locked, acct.unlockEnd);

        uint unlockBegin = config[$C._unlockBegin_];
        uint mnb = Math.max(now, unlockBegin);
        locked = WooferLib.currLocked(locked, unlockEnd);
        unlockEnd = unlockEnd.sub0(mnb).mul(locked).add(lockSpan.mul(amt)).div(locked.add(amt)).add(mnb);
        locked = locked.add(amt).mul(unlockEnd.sub(unlockBegin)).div(unlockEnd.sub(mnb));
        require(locked <= uint112(-1), "locked OVERFLOW");
        require(unlockEnd <= uint32(-1), "unlockEnd OVERFLOW");
        (acct.locked, acct.unlockEnd) = (uint112(locked), uint32(unlockEnd));
    }

    function _verify(address sender, bytes32 tweetId, Twitter[] memory twitters, Signature[] calldata signatures) internal {
        $.verify(sender, tweetId, twitters, signatures);
    }

    function calcForce(Twitter calldata twitter) external view viewExtend returns(uint) {
        return _calcForce(twitter);
    }
    function _calcForce(Twitter calldata twitter) internal view returns(uint) {
        uint age = now.sub(twitter.createTime).div(1 days).add(1);
        uint followers = twitter.followers.add(1);
        uint tweets = twitter.tweets.add(1);
        return Math.sqrt(age.mul(followers).mul(tweets));
    }
    
    function calcAirClaim(Twitter[] calldata twitters) external view viewExtend returns(uint amt) {
        return _calcAirClaim(twitters);
    }
    function _calcAirClaim(Twitter[] calldata twitters) internal view returns(uint amt) {
        mapping (bytes32 => uint) storage config = Config.config();
        require(twitters.length > 0, "missing twitters");
        uint my = _calcForce(twitters[0]);
        for(uint i=1; i<twitters.length; i++)
            if($.addrOfId[twitters[i].id] == address(0))
                amt = amt.add(_calcForce(twitters[i]).mul(config[$C._factorMoreForce_]).div(1e18));
        if(amt > my)
            amt = my;
        amt = Math.min(amt.add(my).add(config[$C._minAirClaim_]), config[$C._maxAirClaim_]).mul(config[$C._factorAirClaim_]);
    }
    
    function isAirClaimed(address sender, bytes32 id) external view viewExtend returns(uint flag) {
        return _isAirClaimed(sender, id);
    }
    function _isAirClaimed(address sender, bytes32 id) internal view returns(uint flag) {
        if(_unlockEndOf(sender) != 0)
            flag += 1;
        if($.addrOfId[id] != address(0))
            flag += 2;
    }
    
    function airClaim(bytes32 tweetId, Twitter[] calldata twitters, Signature[] calldata signatures) payable external extend {
        require($C._denyAirClaim_.get() == 0, "denyAirClaim");
        _rebase();
        address sender = $M.msgSender();
        _verify(sender, tweetId, twitters, signatures);
        uint amt = _calcAirClaim(twitters);
        require(twitters[0].id != 0, "missing twitter id");
        require(_isAirClaimed(sender, twitters[0].id) == 0, "airClaim already");
        $.addrOfId[twitters[0].id] = sender;
        _setAcct(sender, amt, $C._lockSpanAirClaim_.get(), true);
        _mint(sender, amt);
        emit AirClaim(sender, twitters[0].id, amt);

        _buyInEth(sender, msg.value);
    }
    event AirClaim(address indexed sender, bytes32 indexed id, uint amt);

    function _buyInEth(address sender, uint value) internal returns (uint) {
        if(value == 0)
            return 0;
        mapping (bytes32 => address) storage configA = Config.configA();
        IUniswapV2Router01 router = IUniswapV2Router01(configA[$C._swapRouter_]);
        address WETH = router.WETH();
        address currency = configA[$C._currency_];
        if(currency != WETH) {
            address[] memory path = new address[](2);
            (path[0], path[1]) = (WETH, currency);
            uint[] memory amounts = router.swapExactETHForTokens{value: value}(0, path, address(this), now);
            value = amounts[1];
        } else
            IWETH(WETH).deposit{value: value}();
        return _buy(sender, value);
    }
    
    function buy(PermitSign calldata ps, address[] calldata path, uint amt) payable external extend compound {
        _buy($M.msgSender(), ps, path, amt);
    }
    function _buy(address sender, PermitSign calldata ps, address[] calldata path, uint amt) internal returns (uint) {
        uint value = WooferLib.swapTokenToCurrency(sender, ps, path, amt);
        return _buy(sender, value);
    }
    
    function _buy(address sender, uint value) internal returns (uint a){
        require(Config.config()[$C._denyBuy_] == 0, "denyBuy");
        if(value == 0)
            return 0;
        uint r1 = _calcRatio1();
        uint v1 = value.mul(r1).div(1e18);
        if(v1 > 0) {
            a = _calcOut1(v1);
            _mint(sender, a);
            _updateLocked(sender, a, Config.config()[$C._lockSpanBuy_]);
            _updateBuffer(v1, a);
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
        emit Buy(sender, value, a);
    }
    event Buy(address indexed sender, uint value, uint amount);

    //function calcOut1(uint v) external view viewExtend returns(uint a) {
    //    return _calcOut1(v);
    //}
    function _calcOut1(uint v) internal view returns(uint a) {
        uint f = Config.config()[$C._factorPrice_];
        uint b = _buyBuffer();
        uint s = _buySupply();
        uint p = f.mul(b).div0(s);
        uint pv = f.mul(b.add(v)).div0(s.add(v.mul(1e18).div0(p)));
        p = p.add(pv).div(2);
        return v.mul(1e18).div0(p);
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

    function calcIn(uint a, address[] calldata path) external view viewExtend returns(uint) {
        return _calcIn(a, path);
    }
    function _calcIn(uint amt, address[] calldata path) internal view returns(uint v) {
        uint r1 = _calcRatio1();
        uint a = amt.mul(r1).div(1e18);
        v = _calcIn1(a).mul(1e18).div(r1);
    
        mapping (bytes32 => address) storage configA = Config.configA();
        address currency = configA[$C._currency_];
        address router = configA[$C._swapRouter_];
    
        a = amt.sub(a);
        if(a > 0) {
            address[] memory p = new address[](2);
            (p[0], p[1]) = (currency, address(this));
            v = v.add(IUniswapV2Router01(router).getAmountsIn(a, p)[0]);
        }
    
        require(path.length == 0 || path[path.length-1] == currency, "INVALID_PATH");
        if(path.length >= 2)
            v = IUniswapV2Router01(router).getAmountsIn(v, path)[0];
    }
    
    //function calcIn1(uint quota) external view viewExtend returns(uint) {
    //    return _calcIn1(quota);
    //}
    function _calcIn1(uint a) internal view returns(uint) {
        uint f = Config.config()[$C._factorPrice_];
        uint b = _buyBuffer();
        uint s = _buySupply();
        uint p = f.mul(b).div0(s);
        uint pa = f.mul(b.add(a.mul(p).div(1e18))).div0(s.add(a));
        p = p.add(pa).div(2);
        return a.mul(p).div(1e18);
    }

    function calcRatio1() external view viewExtend returns(uint r) {
        return _calcRatio1();
    }
    function _calcRatio1() internal view returns(uint r) {
        return _calcRatio1(_price1(), _price2());
    }
    function _calcRatio1(uint p1, uint p2) internal view returns(uint r) {
        if(p2 == 0)
            return 1e18;
        return Math.min(p2.sub0(p1).mul(1e18).div(p2).mul(1e18).div(Config.config()[$C._discount_]), 1e18);
    }

    //function sell(uint vol) external extend {
    //    address sender = $M.msgSender();
    //    IUniswapV2Router01 router = IUniswapV2Router01($C._swapRouter_.getA());
    //    $.transfer(sender, address(this), vol);
    //    _approve(address(this), address(router), vol);
    //    address[] memory path = new address[](2);
    //    (path[0], path[1]) = (address(this), router.WETH());
    //    uint[] memory amounts = router.swapExactTokensForETH(vol, 0, path, sender, now);
    //    emit Sell(sender, vol, amounts[1]);
    //}
    //event Sell(address indexed sender, uint vol, uint eth);

    //function sellForToken(uint vol, address token) external extend {
    //    address sender = $M.msgSender();
    //    IUniswapV2Router01 router = IUniswapV2Router01($C._swapRouter_.getA());
    //    $.transfer(sender, address(this), vol);
    //    _approve(address(this), address(router), vol);
    //    address[] memory path = new address[](3);
    //    (path[0], path[1], path[2]) = (address(this), router.WETH(), token);
    //    uint[] memory amounts = router.swapExactTokensForTokens(vol, 0, path, sender, now);
    //    emit SellForToken(sender, vol, token, amounts[2]);
    //}
    //event SellForToken(address indexed sender, uint vol, address indexed token, uint amt);

    function setSignatories_(address[] calldata signatories) external extend governance {
        $.setSignatories(signatories);
    }

    function setBuf_(uint112 supply, uint factor, uint p1) external extend governance {
        $.setBuf(supply, factor, p1);
    }

    function woofEndTime(bytes32 tweetId) external view viewExtend returns (uint) {
        return $.woofs[tweetId].endTime;
    }
    
    //function woofRewardRate(bytes32 tweetId) external view viewExtend returns (uint) {
    //    return $.woofs[tweetId].rewardRate;
    //}
    
    function woofDog(bytes32 tweetId, address acct) external view viewExtend returns (uint cowoofAmt, uint yieldPerToken, uint yield, uint yieldPaid, uint rewoofAmt, uint rewardPerToken, uint reward, uint rewardPaid) {
        Dog storage dog = $.woofs[tweetId].dogs[acct];
        return (dog.cowoofAmt, dog.yieldPerToken, dog.yield, dog.yieldPaid, $.bal4Prin(dog.rewoofPrin), $.prin4Bal(dog.rewardPerPrin), dog.reward, dog.rewardPaid);
    }
    
    //function yieldPerToken(bytes32 tweetId) external view viewExtend returns (uint) {
    //    return _yieldPerToken(tweetId);
    //}
    function _yieldPerToken(bytes32 tweetId) internal view returns (uint) {
        Woof storage woof = $.woofs[tweetId];
        Dog  storage all  = woof.dogs[address(-1)];
        if (all.cowoofAmt == 0 || woof.lastTime >= woof.endTime)
            return all.yieldPerToken;
        return all.yieldPerToken.add($.bal4Prin(all.rewoofPrin).sub(woof.lastRewoof).mul($C._yieldPerRebase_.get()).div(all.cowoofAmt));
    }

    function yielded(bytes32 tweetId, address acct) external view viewExtend returns (uint) {
        return _yielded(tweetId, acct);
    }
    function _yielded(bytes32 tweetId, address acct) internal view returns (uint) {
        Dog storage dog = $.woofs[tweetId].dogs[acct];
        uint yield = dog.cowoofAmt.mul(_yieldPerToken(tweetId).sub(dog.yieldPerToken)).div(1e18).add(dog.yield);
        bytes32 _factor_ = (acct == $.addrOfId[$.woofs[tweetId].twitterId]) ? $C._maxYieldFactor_ : $C._maxCoYieldFactor_;
        uint max = _factor_.get().mul(dog.cowoofAmt).div(1e18);
        return Math.min(yield, max.sub0(dog.yieldPaid));
    }

    function roi(bytes32 tweetId, address acct) external view viewExtend returns (uint) {
        if(acct == address(-1))
            return _yieldPerToken(tweetId);
        Dog storage dog = $.woofs[tweetId].dogs[acct];
        return _yielded(tweetId, acct).add(dog.yieldPaid).mul(1e18).div(dog.cowoofAmt);
    }

    function getYields(bytes32[] calldata tweetIds) external extend compound {
        for(uint i=0; i<tweetIds.length; i++) {
            _updateWoof(tweetIds[i], $M.msgSender());
            _getYield(tweetIds[i]);
        }
    }
    function getYield(bytes32 tweetId) external extend updateWoof(tweetId) {
        _getYield(tweetId);
    }
    function _getYield(bytes32 tweetId) internal {
        address sender = $M.msgSender();
        Dog storage dog = $.woofs[tweetId].dogs[sender];
        uint256 yield = dog.yield;
        if (yield > 0) {
            dog.yield = 0;
            _mint(sender, yield);
            _updateLocked(sender, yield, $.woofs[tweetId].endTime.sub0(block.timestamp).add($C._woofSpan_.get()));
            dog.yieldPaid = dog.yieldPaid.add(yield);
            emit YieldPaid(sender, yield);
        }
    }
    event YieldPaid(address indexed user, uint256 yield);
    
    function _lastTime(bytes32 tweetId) internal view returns (uint) {
        return Math.min(block.timestamp, $.woofs[tweetId].endTime);
    }

    function _rewardPerPrin(bytes32 tweetId) internal view returns (uint) {
        Woof storage woof = $.woofs[tweetId];
        Dog  storage all  = woof.dogs[address(-1)];
        if (all.rewoofPrin == 0)
            return all.rewardPerPrin;
        return all.rewardPerPrin.add(_lastTime(tweetId).sub(woof.lastTime).mul(woof.rewardRate).mul(1e18).div(all.rewoofPrin));
    }

    function earned(bytes32 tweetId, address acct) external view viewExtend returns (uint) {
        return _earned(tweetId, acct);
    }
    function _earned(bytes32 tweetId, address acct) internal view returns (uint) {
        Dog storage dog = $.woofs[tweetId].dogs[acct];
        return dog.rewoofPrin.mul(_rewardPerPrin(tweetId).sub(dog.rewardPerPrin)).div(1e18).add(dog.reward);
    }

    function getRewards(bytes32[] calldata tweetIds) external extend compound {
        for(uint i=0; i<tweetIds.length; i++) {
            _updateWoof(tweetIds[i], $M.msgSender());
            _getReward(tweetIds[i]);
        }
    }
    function getReward(bytes32 tweetId) external extend updateWoof(tweetId) {
        _getReward(tweetId);
    }
    function _getReward(bytes32 tweetId) internal {
        address sender = $M.msgSender();
        Dog storage dog = $.woofs[tweetId].dogs[sender];
        uint256 reward = dog.reward;
        if (reward > 0) {
            dog.reward = 0;
            _mint(sender, reward);
            _updateLocked(sender, reward, $.woofs[tweetId].endTime.sub0(block.timestamp).add($C._woofSpan_.get()));
            dog.rewardPaid = dog.rewardPaid.add(reward);
            emit RewardPaid(sender, reward);
        }
    }
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateWoof(bytes32 tweetId) {
        _updateWoof(tweetId);
        _;
    }
    function _updateWoof(bytes32 tweetId) internal compound {
        _updateWoof(tweetId, $M.msgSender());
    }
    function _updateWoof(bytes32 tweetId, address acct) internal {
        Woof storage woof   = $.woofs[tweetId];
        Dog  storage all    = woof.dogs[address(-1)];
        all.yieldPerToken   = _yieldPerToken(tweetId);
        all.rewardPerPrin   = _rewardPerPrin(tweetId);
        woof.lastRewoof     = $.bal4Prin(all.rewoofPrin);
        woof.lastTime       = _lastTime(tweetId);
        if (acct != address(0)) {
            Dog storage dog     = woof.dogs[acct];
            dog.yield           = _yielded(tweetId, acct);
            dog.reward          = _earned (tweetId, acct);
            dog.yieldPerToken   = all.yieldPerToken;
            dog.rewardPerPrin   = all.rewardPerPrin;
        }
    }

    function cowoof(bytes32 id, bytes32 twitterId, bytes32 tweetId, uint amount, uint value, PermitSign calldata ps, address[] calldata path, Signature[] calldata signatures) payable external extend updateWoof(tweetId) {
        address sender = $M.msgSender();
        _verify(sender, tweetId, new Twitter[](0), signatures);
        amount = Math.min(amount, $.unlockedOf(sender));
        {   // scope to avoid stack too deep errors
        uint reward = _buy(sender, ps, path, value);
        _burn(sender, reward);
        require(reward >= $C._minCowoof_.get(), "not enoungh cowoof reward");

        Woof storage woof = $.woofs[tweetId];
        if(woof.twitterId == 0)
            woof.twitterId = twitterId;
        else
            require(woof.twitterId == twitterId, "cowoof twitterId not match");
        if(woof.endTime < block.timestamp)
            woof.endTime = woof.lastTime = block.timestamp;
        {   // scope to avoid stack too deep errors
        uint rewardRate = woof.rewardRate.add(reward.div($C._woofSpan_.get()));
        woof.endTime = woof.rewardRate.mul(woof.endTime.sub(block.timestamp)).add(reward).div(rewardRate).add(block.timestamp);
        woof.rewardRate = rewardRate;
        }
        woof.dogs[address(-1)].cowoofAmt = woof.dogs[address(-1)].cowoofAmt.add(reward);
        woof.dogs[sender].cowoofAmt = woof.dogs[sender].cowoofAmt.add(reward);

        emit Cowoof(sender, id, tweetId, reward);
        }
        _rewoof(sender, id, tweetId, amount);
    }
    event Cowoof(address indexed sender, bytes32 indexed id, bytes32 indexed tweetId, uint reward);

    function rewoof(bytes32 id, bytes32 tweetId, uint amount, uint value, PermitSign calldata ps, address[] calldata path, Signature[] calldata signatures) payable external extend updateWoof(tweetId) {
        address sender = $M.msgSender();
        _verify(sender, tweetId, new Twitter[](0), signatures);
        amount = Math.min(amount, $.unlockedOf(sender));
        uint amt = _buy(sender, ps, path, value);
        require(amt >= $C._minRewoofIncRatio_.get().mul(amount).div(1e18), "not enoungh rewoof increment");
        amount = amount.add(amt);
        _rewoof(sender, id, tweetId, amount);
    }

    function _rewoof(address sender, bytes32 id, bytes32 tweetId, uint amount) internal {
        Woof storage woof = $.woofs[tweetId];
        uint prin = $.prin4Bal(amount);
        woof.dogs[address(-1)].rewoofPrin = woof.dogs[address(-1)].rewoofPrin.add(prin);
        woof.dogs[sender].rewoofPrin = woof.dogs[sender].rewoofPrin.add(prin);
        _updateLocked(sender, amount, $C._woofSpan_.get());

        emit Rewoof(sender, id, tweetId, amount);
    }
    event Rewoof(address indexed sender, bytes32 indexed id, bytes32 indexed tweetId, uint amount);

    //receive () override payable external {
    //
    //}
}

contract WooferEx is Woofer {
    modifier extend override {
        _;
    }
    modifier viewExtend override {
        _;
    }

    fallback () override payable external {
        revert(ERROR_FALLBACK);
    }

    receive () override payable external {
        if(OpenZeppelinUpgradesAddress.isContract(msg.sender) && msg.data.length == 0)         // for receive ETH only from other contract
            return;
        revert(ERROR_FALLBACK);
    }
}

library WooferLib {
    using Config for bytes32;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ERC20Lib for ERC20Stru;
    using WooferLib for WooferStru;
    
    function E(WooferStru storage $) internal pure returns (ERC20Stru storage e$) {
        assembly {  e$_slot := $_slot   }
    }

    function delegatestaticcall(address ex, bytes memory data) external returns (bool, bytes memory) {
        return ex.delegatecall(data);
    }

    function __Woofer_init_unchained(WooferStru storage $) external {
        $.index                       = 1e18;
        mapping (bytes32 => uint) storage config = Config.config();
        config[$C._minSignatures_   ] = 3;
        config[$C._minAirClaim_     ] = 9999;
        config[$C._maxAirClaim_     ] = 1_000_000;
        config[$C._spanAirClaim_    ] = 20 days;
        config[$C._factorAirClaim_  ] = 1e18;
        config[$C._factorProfitAir_ ] = 100;
        config[$C._factorProfitBuy_ ] = 100;
        config[$C._factorMoreForce_ ] = 0.5e18;
        config[$C._unlockBegin_     ] = now.add(10 days);
        config[$C._lockSpanAirClaim_] = 100 days;
        config[$C._lockSpanBuy_     ] = 7 days;
        config[$C._spanBuyBuf_      ] = 7 days;
        //config[$C._factorPrice_     ] = 0.01e18;        //0.0000025e18;   // $0.01
        config[$C._factorPrice20_   ] = 1.1e18;           // price20 = price1 * 1.1
        config[$C._currency_        ] = uint(0x6B175474E89094C44Da98b954EedeAC495271d0F);   // DAI
        if($C._chainId() == 4)         // Rinkeby
            config[$C._currency_    ] = uint(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);   // DAI_Rinkeby  0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735
        config[$C._swapRouter_      ] = uint(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        config[$C._swapFactory_     ] = uint(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        config[$C._discount_        ] = 0.10e18;        // 10%
        config[$C._rebaseTime_      ] = now.add(10 days).add(8 hours).sub(now % 8 hours);
        config[$C._rebasePeriod_    ] = 8 hours;
        config[$C._rebaseSpan_      ] = 20*365 days;
        config[$C._lpTknMaxRatio_   ] = 0.10e18;        // 10%
        config[$C._lpCurMaxRatio_   ] = 0.50e18;        // 50%
        config[$C._buybackRatio_    ] = 0.10e18;        // 10%
        config[$C._ecoAddr_         ] = uint(msg.sender);
        config[$C._ecoRatio_        ] = 0.10e18;
        config[$C._denyBuy_         ] = 1;

        setBuf($, 100_000e18 * 5 * 100e18 / 0.01e18, 100e18, 0.01e18);

        address[] memory signatories = new address[](5);
        signatories[0] = 0x4f91F7639B21D004Aa2A81D1d6C9eB506dAf46aa;
        signatories[1] = 0x0634Aab76586644f43A4A5d395FA737E49cbbba6;
        signatories[2] = 0x023C8a3209F3dae154A5407cB290894478184423;
        signatories[3] = 0x27414b9FA8992002462D5F3B97bb2C161528b808;
        signatories[4] = 0xB5F6CadFbE80928dabD1e58669493f1e520aBf50;
        setSignatories($, signatories);

        config[$C._woofSpan_        ] = 7 days;
        config[$C._minCowoof_       ] = 100000e18;
        config[$C._yieldPerRebase_  ] = 0.50e18;        // 50%
        config[$C._maxYieldFactor_  ] = 1.50e18;        // 150%
        config[$C._maxCoYieldFactor_] = 1.35e18;        // 135%
        config[$C._minRewoofIncRatio_]= 0.10e18;        // 10%
    }

    function prin4Bal(WooferStru storage $, uint bal) internal view returns(uint) {
        return bal.mul(1e18).div($.index);
    }

    function bal4Prin(WooferStru storage $, uint prin) internal view returns(uint) {
        return prin.mul($.index).div(1e18);
    }

    function balanceOf(WooferStru storage $, address who) internal view returns(uint bal) {
        bal = $.balances[who];
        if($.accts[who].isCmpd)
            bal = $.bal4Prin(bal);
    }

    function transfer(WooferStru storage $, address from, address to, uint256 amt) public returns (bool) {
        //$.beforeTokenTransfer(from, to, amt);
        require($.unlockedOf(from) >= amt, "transfer amt exceeds unlocked");

        uint flat = $.flatSupply;
        uint prin = $.prin4Bal(amt);
        uint v = prin;
        if(!$.accts[from].isCmpd) {
            flat = flat.sub(amt);
            v = amt;
        }
        $.balances[from] = $.balances[from].sub(v, "transfer amt exceeds bal");
        v = prin;
        if(!$.accts[to].isCmpd) {
            flat = flat.add(amt);
            v = amt;
        }
        $.balances[to] = $.balances[to  ].add(v);
        if($.flatSupply != flat)
            $.flatSupply = flat;
        emit ERC20Lib.Transfer(from, to, amt);
        return true;
    }

    function transferFrom(WooferStru storage $, address from, address to, uint256 amt) external returns (bool) {
        if(from != $M.msgSender() && $.allowances[from][$M.msgSender()] != uint(-1))
            E($).approve(from, $M.msgSender(), $.allowances[from][$M.msgSender()].sub(amt, "transfer amt exceeds allowance"));
        return transfer($, from, to, amt);
    }

    function mint(WooferStru storage $, address to, uint256 amt) public {
        if ($.cap > 0)   // When Capped
            require($.totalSupply.add(amt) <= $.cap, "cap exceeded");
        //$.beforeTokenTransfer(address(0), to, amt);

        $.totalSupply = $.totalSupply.add(amt);
        uint v;
        if(!$.accts[to].isCmpd) {
            $.flatSupply = $.flatSupply.add(amt);
            v = amt;
        } else
            v = $.prin4Bal(amt);
        $.balances[to] = $.balances[to].add(v);
        emit ERC20Lib.Transfer(address(0), to, amt);
    }

    function burn(WooferStru storage $, address from, uint256 amt) public {
        //$.beforeTokenTransfer(from, address(0), amt);
        //require($.unlockedOf(from) >= amt, "burn amt exceeds unlocked");
        uint v;
        if(!$.accts[from].isCmpd) {
            $.flatSupply = $.flatSupply.sub(amt);
            v = amt;
        } else
            v = $.prin4Bal(amt);
        $.balances[from] = $.balances[from].sub(v, "burn amt exceeds balance");
        $.totalSupply = $.totalSupply.sub(amt);
        emit ERC20Lib.Transfer(from, address(0), amt);
    }

    //function beforeTokenTransfer(WooferStru storage $, address from, address to, uint256 amount) internal { }

    function currLocked(uint locked, uint unlockEnd) internal view returns(uint) {
        if(locked == 0 || now >= unlockEnd)
            return 0;
        uint unlockBegin = Config.config()[$C._unlockBegin_];
        if(now <= unlockBegin)
            return locked;
        return locked.mul(unlockEnd.sub(now)).div(unlockEnd.sub(unlockBegin));
    }

    function lockedOf(WooferStru storage $, address who) internal view returns(uint) {
        Account storage acct = $.accts[who];
        (uint locked, uint unlockEnd) = (acct.locked, acct.unlockEnd);
        return currLocked(locked, unlockEnd);
    }

    function unlockedOf(WooferStru storage $, address who) internal view returns(uint) {
        return $.balanceOf(who).sub0($.lockedOf(who));
    }

    function permit(WooferStru storage $, address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        ERC20Stru storage E$ = E($);
        return E$.permit(owner, spender, value, deadline, v, r, s);
    }

    function APY(WooferStru storage $, bytes32 tweetId) external view returns(uint y) {
        (, uint r, uint period) = calcRebaseProfit($, address(0));
        r = r.add($.woofs[tweetId].rewardRate.mul(period).mul(1e18).div0($.bal4Prin($.woofs[tweetId].dogs[address(-1)].rewoofPrin)));
        r = r.add(1e18);
        y = 1e18;
        for(uint i=(365 days/period); i>0; i>>=1) {
            if(i % 2 == 1)
                y = y.mul(r).div(1e18);
            r = r.mul(r).div(1e18);
        }
        y -= 1e18;
    }
    
    function calcRebaseProfit(WooferStru storage $, address who) public view returns(uint profit, uint ratio, uint period) {
        mapping (bytes32 => uint) storage config = Config.config();
        period = config[$C._rebasePeriod_];
        profit = $.totalProfit.mul(period).div(config[$C._rebaseSpan_]);
        profit = profit.sub(profit.mul(config[$C._ecoRatio_]).div(1e18));
        uint cmpdSupply = $.totalSupply.sub($.flatSupply);
        ratio = profit.mul(1e18).div0(cmpdSupply);
        if(who != address(0) && who != address(-1))
            if($.accts[who].isCmpd)
                profit = profit.mul(IERC20(address(this)).balanceOf(who)).div0(cmpdSupply);
            else
                profit = 0;
    }

    function verify(WooferStru storage $, address sender, bytes32 tweetId, Twitter[] memory twitters, Signature[] memory signatures) external {
        mapping (bytes32 => uint) storage config = Config.config();
        require(config[$C._denyVerify_] == 0, "denyVerify");
        require(signatures.length >= config[$C._minSignatures_], "too few signatures");
        for(uint i=0; i<signatures.length; i++) {
            for(uint j=0; j<i; j++)
                require(signatures[i].signatory != signatures[j].signatory, "repetitive signatory");
            bytes32 structHash = keccak256(abi.encode($C.VERIFY_TYPEHASH, sender, $.nonces[sender]++, tweetId, twitters, signatures[i].signatory));
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01", $.DOMAIN_SEPARATOR, structHash));
            address signatory = ecrecover(digest, signatures[i].v, signatures[i].r, signatures[i].s);
            require(signatory != address(0), "invalid signature");
            require(signatory == signatures[i].signatory && $.isSignatory[signatory], "unauthorized");
            emit Authorize(sender, tweetId, twitters, signatures[i].signatory);
        }
    }
    event Authorize(address indexed sender, bytes32 indexed tweetId, Twitter[] twitters, address indexed signatory);
    
    function addLiquidity(WooferStru storage $, uint value, uint amount) internal {
        mint($, address(this), amount);
        address currency = Config.getA($C._currency_);
        IUniswapV2Router01 router = IUniswapV2Router01(Config.getA($C._swapRouter_));
        IERC20(currency).safeApprove_(address(router), value);
        IERC20(address(this)).approve(address(router), amount);
        (, uint amt,) = router.addLiquidity(currency, address(this), value, amount, 0, 0, address(this), now);
        if(amount > amt)
            burn($, address(this), amount - amt);
        $.totalProfit = $.totalProfit.sub0(amt);
    }

    function removeLiquidity(WooferStru storage $, uint liquidity) internal {
        address currency = Config.getA($C._currency_);
        IUniswapV2Router01 router = IUniswapV2Router01(Config.getA($C._swapRouter_));
        address pair = IUniswapV2Factory(Config.getA($C._swapFactory_)).getPair(currency, address(this));
        IERC20(pair).approve(address(router), liquidity);
        (, uint amount) = router.removeLiquidity(currency, address(this), liquidity, 0, 0, address(this), now);
        burn($, address(this), amount);
        $.totalProfit = $.totalProfit.add(amount);
    }

    function adjustLiquidity(WooferStru storage $) external {
        Woofer woofer = Woofer(payable(address(this)));
        uint curBal = 0;
        uint tknBal = 0;
        address currency = $C._currency_.getA();
        address pair = IUniswapV2Factory($C._swapFactory_.getA()).getPair(currency, address(this));
        if(pair != address(0)) {
            curBal = IERC20(currency).balanceOf(pair);
            tknBal = $.balances[pair];
        }
        uint curTgt = IERC20(currency).balanceOf(address(this)).add(curBal).mul($C._lpCurMaxRatio_.get()).div(1e18);
        uint tknR = $C._lpTknMaxRatio_.get();
        uint tknTgt = $.totalSupply.sub(tknBal).mul(tknR).div(uint(1e18).sub(tknR));
        //if(curBal == 0)
        //    curTgt = tknTgt.mul(woofer.price1()).div(1e18).mul($C._factorPrice20_.get()).div(1e18);
        if(tknBal == 0)
            tknTgt = curTgt.mul(1e18).div(woofer.price1()).mul(1e18).div($C._factorPrice20_.get());
        if(curTgt > curBal && tknTgt > tknBal) 
            $.addLiquidity(curTgt - curBal, tknTgt - tknBal);
        else {
            uint rr = Math.max(curBal.sub0(curTgt).mul(1e18).div(curBal), tknBal.sub0(tknTgt).mul(1e18).div(tknBal));
            if(rr > 0)
                $.removeLiquidity(IERC20(pair).balanceOf(address(this)).mul(rr).div(1e18));
        }   
    }

    function tryBuyback(WooferStru storage $) external {
        Woofer woofer = Woofer(payable(address(this)));
        address currency = Config.getA($C._currency_);
        IUniswapV2Router01 router = IUniswapV2Router01(Config.getA($C._swapRouter_));
        address pair = IUniswapV2Factory(Config.getA($C._swapFactory_)).getPair(currency, address(this));
        //require(Config.get($C._buybackAnytime_) > 0 || $.totalSupply.mul(woofer.price2()).div(1e18) < IERC20(currency).balanceOf(address(this)).add(IERC20(currency).balanceOf(pair).mul(2)), "price2 should below net value");
        if(Config.get($C._buybackAnytime_) == 0 && $.totalSupply.mul(woofer.price2()).div(1e18) >= IERC20(currency).balanceOf(address(this)).add(IERC20(currency).balanceOf(pair).mul(2)))
            return;
        uint value = IERC20(currency).balanceOf(address(this)).mul(Config.get($C._buybackRatio_)).div(1e18);
        address[] memory path = new address[](2);
        (path[0], path[1]) = (currency, address(this));
        IERC20(currency).safeApprove_(address(router), value);
        uint[] memory amounts = router.swapExactTokensForTokens(value, 0, path, address(0xdEaD), now);
        burn($, address(0xdEaD), amounts[1]);
        $.totalProfit = $.totalProfit.add(amounts[1]);
    }

    function swapTokenToCurrency(address sender, PermitSign calldata ps, address[] calldata path, uint amt) external returns(uint) {
        address currency = $C._currency_.getA();
        require(path.length == 0 || path[path.length-1] == currency, "INVALID_PATH");
        address token0 = (path.length == 0 ? currency : path[0]);
        if(ps.v != 0 || ps.r != 0 || ps.s != 0)
            if(ps.allowed)
                IPermitAllowed(token0).permit(sender, address(this), IPermitAllowed(token0).nonces(sender), ps.deadline, true, ps.v, ps.r, ps.s);
            else
                ERC20Permit(token0).permit(sender, address(this), amt, ps.deadline, ps.v, ps.r, ps.s);
        IUniswapV2Router01 router = IUniswapV2Router01($C._swapRouter_.getA());
        if(msg.value > 0 && token0 == router.WETH()) {
            require(msg.value == amt, "msg.value != amt");
            IWETH(token0).deposit{value: amt}();
        } else
            IERC20(token0).safeTransferFrom(sender, address(this), amt);
        if(path.length <= 1)
            return amt;
        IERC20(path[0]).safeApprove_(address(router), amt);
        uint[] memory amounts = router.swapExactTokensForTokens(amt, 0, path, address(this), now);
        return amounts[path.length-1];
    }
    
    function setSignatories(WooferStru storage $, address[] memory signatories) public {
        for(uint i=0; i<$.signatories.length; i++)
            $.isSignatory[$.signatories[i]] = false;
            
        $.signatories = signatories;
        
        for(uint i=0; i<$.signatories.length; i++)
            $.isSignatory[$.signatories[i]] = true;
            
        emit SetSignatories(signatories);
    }
    event SetSignatories(address[] signatories);

    function setBuf(WooferStru storage $, uint112 supply, uint factor, uint p1) public {
        //require(supply <= uint112(-1), "buySupply OVERFLOW");
        if(supply == 0)
            supply = $.buySupply;
        if(factor == 0)
            factor = Config.config()[$C._factorPrice_];
        else
            Config.config()[$C._factorPrice_] = factor;
        if(p1 == 0)
            p1 = Woofer(uint160(address(this))).price1();
        uint buffer = p1.mul(supply).div(factor);
        require(buffer <= uint112(-1), "buyBuffer OVERFLOW");
        ($.buySupply, $.buyBuffer, $.lastUpdateBuf) = (supply, uint112(buffer), uint32(now));
        //Config.config()[$C._factorPrice_] = p1.mul($.buySupply).div(buf);
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
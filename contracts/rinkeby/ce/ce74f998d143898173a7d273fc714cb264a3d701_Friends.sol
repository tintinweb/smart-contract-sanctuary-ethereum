// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

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
    uint    deadline;
    uint8   v;
    bytes32 r;
    bytes32 s;
}

struct Account {
    uint112 quota;
    uint112 locked;
    uint32  unlockEnd;
    address referrer;
    bool    isCmpd;
    uint88  nonce;
    uint    reward;
}

struct FriendsStru {
    uint flatSupply;
    uint index;
    mapping(address => Account) accts;
    mapping(bytes32 => address) addrOfId;

    address[] signatories;
    mapping(address => bool) isSignatory;

    uint    totalProfit;
    uint112 totalDonate;          // uses single storage slot
    uint112 donateBuf;            // uses single storage slot
    uint32  lastUpdateBuf;        // uses single storage slot
}

library $C {
    bytes32 internal constant _denyVerify_      = "denyVerify";
    bytes32 internal constant _minSignatures_   = "minSignatures";
    bytes32 internal constant _denyAirClaim_    = "denyAirClaim";
    bytes32 internal constant _denyDonate_      = "denyDonate";
    bytes32 internal constant _maxAirClaim_     = "maxAirClaim";
    bytes32 internal constant _spanAirClaim_    = "spanAirClaim";
    bytes32 internal constant _factorAirClaim_  = "factorAirClaim";
    bytes32 internal constant _factorProfitAir_ = "factorProfitAir";
    bytes32 internal constant _factorProfitDonate_ = "factorProfitDonate";
    bytes32 internal constant _factorQuota_     = "factorQuota";
    bytes32 internal constant _factorMoreForce_ = "factorMoreForce";
    bytes32 internal constant _unlockBegin_     = "unlockBegin";
    bytes32 internal constant _lockSpanAirClaim_= "lockSpanAirClaim";
    bytes32 internal constant _lockSpanDonate_  = "lockSpanDonate";
    bytes32 internal constant _spanDonateBuf_   = "spanDonateBuf";
    bytes32 internal constant _factorPrice_     = "factorPrice";
    bytes32 internal constant _currency_        = "currency";
    bytes32 internal constant _swapRouter_      = "swapRouter";
    bytes32 internal constant _swapFactory_     = "swapFactory";
    bytes32 internal constant _discount_        = "discount";
    bytes32 internal constant _rebaseTime_      = "rebaseTime";
    bytes32 internal constant _rebasePeriod_    = "rebasePeriod";
    bytes32 internal constant _rebaseSpan_      = "rebaseSpan";
    bytes32 internal constant _allowClaimReward_= "allowClaimReward";
    bytes32 internal constant _reward_          = "reward";
    bytes32 internal constant _lockSpanReward_  = "lockSpanReward";
    bytes32 internal constant _ecoAddr_         = "ecoAddr";
    bytes32 internal constant _ecoRatio_        = "ecoRatio";
    bytes32 internal constant _donatebackAnytime_  = "buybackAnytime";

    bytes32 internal constant VERIFY_TYPEHASH   = keccak256("Verify(address sender,bytes32 referrer,uint256 nonce,Twitter[] twitters,address signatory)");

    function _chainId() internal pure returns (uint id) {
        assembly { id := chainid() }
    }
}

contract FriendsBase is ERC20Permit {
    FriendsStru internal $;
    uint256[41] private __gap;
}

contract Friends is FriendsBase, Extendable {
    using SafeERC20 for IERC20;
    using Config for bytes32;
    using FriendsLib for FriendsStru;

    //constructor(address ex0, bytes memory data) Extendable(ex0, data) public {
    constructor() public {
        __Context_init_unchained();
        __ERC20_init_unchained("Friends", "Friends");
        //_setupDecimals(18);
        //__ERC20Capped_init_unchained(21e27);
        __ERC20Permit_init_unchained();
        $.__Friends_init_unchained();
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

    function VERIFY_TYPEHASH() virtual external view viewExtend returns (bytes32) {
        return $C.VERIFY_TYPEHASH;
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

    function totalProfit() external view viewExtend returns(uint) {
        return $.totalProfit;
    }

    function totalDonate() external view viewExtend returns(uint) {
        return _totalDonate();
    }
    function _totalDonate() internal view returns(uint) {
        return $.totalDonate;
    }

    function donateBuf() external view viewExtend returns(uint) {
        return _donateBuf();
    }
    function _donateBuf() internal view returns(uint) {
        mapping (bytes32 => uint) storage config = Config.config();
        uint span = config[$C._spanDonateBuf_];
        (uint buf, uint last) = ($.donateBuf, $.lastUpdateBuf);        // uses single storage slot
        return span.sub0(now.sub0(Math.max(last, config[$C._unlockBegin_]))).mul(buf).div(span);
    }

    function _updateBuf(uint amt) internal {
        uint total = _totalDonate().add(amt);
        uint buf = _donateBuf().add(amt);
        require(total <= uint112(-1), "totalDonate OVERFLOW");
        require(buf   <= uint112(-1), "donateBuf OVERFLOW");
        ($.totalDonate, $.donateBuf, $.lastUpdateBuf) = (uint112(total), uint112(buf), uint32(now));
    }

    function _price1At(uint vol) internal view returns(uint) {
        //if(_totalDonate() == 0)
        //    return Config.config()[$C._factorPrice_];
        return Config.config()[$C._factorPrice_].mul(_donateBuf().add(vol).add(1)).div(_totalDonate().add(vol).add(1));
    }

    function _price1(uint vol) internal view returns(uint) {
        return _price1At(0).add(_price1At(vol)).div(2);
    }

    function price1() external view viewExtend returns(uint) {
        return _price1(0);
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
        return IERC20(currency).balanceOf(pair).mul(1e18).div(_balanceOf(pair));
    }

    function price() external view viewExtend returns(uint) {
        return _price();
    }
    function _price() internal view returns(uint) {
        uint p1 = _price1At(0);
        uint p2 = _price2();
        if(p1 == 0)
            return p2;
        if(p2 == 0)
            return p1;
        uint r1 = _calcRatio1();
        return uint(1e36).div(r1.mul(1e18).div(p1).add(uint(1e18).sub(r1).mul(1e18).div(p2)));
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

    function quotaOf(address who) external view viewExtend returns(uint) {
        return _quotaOf(who);
    }
    function _quotaOf(address who) internal view returns(uint) {
        return $.accts[who].quota;
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

    function nonceOf(address who) external view viewExtend returns(uint) {
        return $.accts[who].nonce;
    }

    //function rewardOf(address who) external view viewExtend returns(uint) {
    //    return $.accts[who].reward;
    //}

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
        uint my = _calcForce(twitters[0]);
        for(uint i=1; i<twitters.length; i++)
            if($.addrOfId[twitters[i].id] == address(0))
                amt = amt.add(_calcForce(twitters[i]).mul(config[$C._factorMoreForce_]).div(1e18));
        if(amt > my)
            amt = my;
        amt = amt.add(my).mul(config[$C._factorAirClaim_]);
        amt = Math.min(amt, config[$C._maxAirClaim_]);
    }
    
    function calcQuota(Twitter[] calldata twitters) external view viewExtend returns(uint amt) {
        return _calcQuota(twitters);
    }
    function _calcQuota(Twitter[] calldata twitters) internal view returns(uint amt) {
        if(twitters.length == 0)
            return 0;
        mapping (bytes32 => uint) storage config = Config.config();
        uint my = _calcForce(twitters[0]);
        for(uint i=1; i<twitters.length; i++)
            if($.addrOfId[twitters[i].id] == address(0))
                amt = amt.add(_calcForce(twitters[i]).mul(config[$C._factorMoreForce_]).div(1e18));
        amt = amt.add(my).mul(config[$C._factorAirClaim_]).mul(config[$C._factorQuota_]);
    }

    function moreQuotaOf(address who, Twitter[] calldata twitters) external view viewExtend returns(uint amt) {
        return _moreQuotaOf(who, twitters);
    }
    function _moreQuotaOf(address who, Twitter[] calldata twitters) internal view returns(uint amt) {
        return _quotaOf(who).add(_calcQuota(twitters));
    }
    
    function _setReferrer(address sender, bytes32 referrer) internal {
        address ref = $.addrOfId[referrer];
        if($.accts[sender].referrer == address(0) && ref != address(0))
            $.accts[sender].referrer = ref;
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
        profit = $.totalProfit.mul(period).div(config[$C._rebaseSpan_]);
        profit = profit.sub(profit.mul(config[$C._ecoRatio_]).div(1e18));
        uint cmpdSupply = _totalSupply.sub($.flatSupply).add(1);
        ratio = profit.mul(1e18).div(cmpdSupply);
        if(who != address(0))
            profit = profit.mul(_balanceOf(who)).div(cmpdSupply);
    }
    
    function rebase() internal {
        mapping (bytes32 => uint) storage config = Config.config();
        uint time = config[$C._rebaseTime_];
        if(now < time)
            return;
        uint period = config[$C._rebasePeriod_];
        config[$C._rebaseTime_] = time.add(period);
        config[$C._factorAirClaim_] -= config[$C._factorAirClaim_].mul(period).div(config[$C._spanAirClaim_]);
        uint tp = $.totalProfit;
        uint profit = tp.mul(period).div(config[$C._rebaseSpan_]);
        uint p = profit.mul(config[$C._ecoRatio_]).div(1e18);
        address eco = address(config[$C._ecoAddr_]);
        $.totalProfit = tp.sub(profit);
        uint supply = _totalSupply;
        uint flat = $.flatSupply;
        $.index = $.index.mul(supply.add(profit).sub(p).sub(flat)).div(supply.sub(flat).add(1));
        _totalSupply = supply.add(profit);
        require(_cap == 0 || supply.add(profit) <= _cap, "ERC20Capped: cap exceeded");
        uint v;
        if(!$.accts[eco].isCmpd) {
            $.flatSupply = flat.add(p);
            v = p;
        } else
            v = prin4Bal(p);
        _balances[eco] = _balances[eco].add(v);
        emit Rebase(profit.sub(p).mul(1e18).div(supply.sub(flat).add(1)), profit.sub(p), supply.sub(flat), supply.add(profit));
    }
    event Rebase(uint ratio, uint profit, uint oldCmpdSupply, uint newTotalSupply);
    
    modifier compound(bytes32 referrer) {
        _compound(referrer);
        _;
    }

    function _compound(bytes32 referrer) internal {
        _setReferrer(_msgSender(), referrer);
        _setCmpd(true);
        rebase();
    } 

    function _setAcct(address sender, uint quota, uint locked, uint lockSpan, address referrer, bool isCmpd) internal {
        mapping (bytes32 => uint) storage config = Config.config();
        require(quota <= uint112(-1), "quota OVERFLOW");
        uint unlockEnd = Math.max(now, config[$C._unlockBegin_]).add(lockSpan);
        require(unlockEnd <= uint32(-1), "unlockEnd OVERFLOW");
        $.accts[sender] = Account(uint112(quota), uint112(locked), uint32(unlockEnd), referrer, isCmpd, 0, 0);
        $.totalProfit = $.totalProfit.add(locked.mul(config[$C._factorProfitAir_]));
    }
    
    function _updateQuota(address sender, Twitter[] calldata twitters) internal {
        require($.addrOfId[twitters[0].id] == sender, "sender not match twitter");
        uint quota = _calcQuota(twitters);
        quota = quota.add($.accts[sender].quota);
        require(quota <= uint112(-1), "quota OVERFLOW");
        $.accts[sender].quota = uint112(quota);
   }

    function _updateLocked(address sender, uint amt, uint lockSpan) internal {
        mapping (bytes32 => uint) storage config = Config.config();
        Account storage acct = $.accts[sender];
        (uint quota, uint locked, uint unlockEnd) = (acct.quota, acct.locked, acct.unlockEnd);
        quota = quota.sub(amt, "not enough quota");
        $.totalProfit = $.totalProfit.add(amt.mul(config[$C._factorProfitDonate_]));

        uint unlockBegin = config[$C._unlockBegin_];
        uint mnb = Math.max(now, unlockBegin);
        locked = _currLocked(locked, unlockEnd);
        unlockEnd = unlockEnd.sub0(mnb).mul(locked).add(lockSpan.mul(amt)).div(locked.add(amt)).add(mnb);
        locked = locked.add(amt).mul(unlockEnd.sub(unlockBegin)).div(unlockEnd.sub(mnb));
        require(locked <= uint112(-1), "locked OVERFLOW");
        require(unlockEnd <= uint32(-1), "unlockEnd OVERFLOW");
        (acct.quota, acct.locked, acct.unlockEnd) = (uint112(quota), uint112(locked), uint32(unlockEnd));
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
    
    function airClaim(bytes32 referrer, uint nonce, Twitter[] calldata twitters, Signature[] calldata signatures) external extend payable {
        require($C._denyAirClaim_.get() == 0, "denyAirClaim");
        rebase();
        address sender = _msgSender();
        $.verify(sender, referrer, nonce, twitters, signatures);
        require(twitters[0].id != 0, "missing twitter id");
        require(_isAirClaimed(sender, twitters[0].id) == 0, "airClaim already");
        $.addrOfId[twitters[0].id] = sender;
        uint amt = _calcAirClaim(twitters);
        uint quota = _calcQuota(twitters);
        _setAcct(sender, quota, amt, $C._lockSpanAirClaim_.get(), $.addrOfId[referrer], true);
        _mint(sender, amt);
        emit AirClaim(sender, amt);

        _donateInEth(sender, msg.value);
    }
    event AirClaim(address indexed sender, uint amt);

    //function donateMoreInEth(bytes32 referrer, uint nonce, Twitter[] calldata twitters, Signature[] calldata signatures) external payable compound(referrer) extend {
    //    address sender = _msgSender();
    //    verify(sender, referrer, nonce, twitters, signatures);
    //    _updateQuota(sender, twitters);
    //    require(msg.value > 0, "missing msg.value");
    //    _donateInEth(sender, msg.value);
    //}

    //function donateInEth(bytes32 referrer) external payable compound(referrer) extend {
    //    _donateInEth(_msgSender(), msg.value);
    //}

    function _donateInEth(address sender, uint value) internal {
        if(value == 0)
            return;
        mapping (bytes32 => address) storage configA = Config.configA();
        IUniswapV2Router01 router = IUniswapV2Router01(configA[$C._swapRouter_]);
        address WETH = router.WETH();
        address currency = configA[$C._currency_];
        if(currency != WETH) {
            address[] memory path = new address[](2);
            (path[0], path[1]) = (WETH, currency);
            uint[] memory amounts = router.swapExactETHForTokens{value: value}(0, path, sender, now);
            value = amounts[1];
        } else
            IWETH(WETH).deposit{value: value}();
        _donate(sender, value);
    }
    
    function _swapTokenToCurrency(address sender, PermitSign calldata ps, address[] calldata path, uint amt) internal returns(uint) {
        mapping (bytes32 => address) storage configA = Config.configA();
        address currency = configA[$C._currency_];
        require(path.length == 0 || path[path.length-1] == currency, "INVALID_PATH");
        if(ps.deadline != 0 && ps.v != 0 && ps.r != 0 && ps.s != 0)
            ERC20Permit(path[0]).permit(sender, address(this), amt, ps.deadline, ps.v, ps.r, ps.s);
        IUniswapV2Router01 router = IUniswapV2Router01(configA[$C._swapRouter_]);
        if(msg.value >= amt && path.length > 0 && path[0] == router.WETH())
            IWETH(path[0]).deposit{value: amt}();
        else
            IERC20(path[0]).safeTransferFrom(sender, address(this), amt);
        if(path.length <= 1)
            return amt;
        IERC20(path[0]).safeApprove_(address(router), amt);
        uint[] memory amounts = router.swapExactTokensForTokens(amt, 0, path, address(this), now);
        return amounts[path.length-1];
    }
    
    function donate(PermitSign calldata ps, address[] calldata path, uint amt, bytes32 referrer, uint nonce, Twitter[] calldata twitters, Signature[] calldata signatures) external compound(referrer) extend {
        address sender = _msgSender();
        if(twitters.length > 0) {
            $.verify(sender, referrer, nonce, twitters, signatures);
            _updateQuota(sender, twitters);
        }
        uint value = _swapTokenToCurrency(sender, ps, path, amt);
        _donate(sender, value);
    }
    
    //function donate(address[] calldata path, uint amt, bytes32 referrer) external compound(referrer) extend {
    //    address sender = _msgSender();
    //    uint value = _swapTokenToCurrency(sender, path, amt);
    //    _donate(sender, value);
    //}

    //function calcMaxInOf(address who, Twitter[] calldata twitters, address[] calldata path) external view viewExtend returns(uint) {
    //    return _calcIn(_moreQuotaOf(who, twitters), path);
    //}
    
    //function calcIn(uint quota, address[] calldata path) external view viewExtend returns(uint) {
    //    return _calcIn(quota, path);
    //}
    //function _calcIn(uint quota, address[] calldata path) internal view returns(uint r) {
    //    uint r1 = _calcRatio1();
    //    if(r1 == 0)
    //        return uint(-1);
    //    r = _calcIn1(quota).mul(1e18).div(r1);
    //
    //    mapping (bytes32 => address) storage configA = Config.configA();
    //    address currency = configA[$C._currency_];
    //    address router = configA[$C._swapRouter_];
    //    require(path.length == 0 || path[path.length-1] == currency, "INVALID_PATH");
    //    if(path.length >= 2)
    //        r = IUniswapV2Router01(router).getAmountsIn(r, path)[0];
    //}
    
    //function calcIn1(uint quota) external view viewExtend returns(uint) {
    //    return _calcIn1(quota);
    //}
    function _calcIn1(uint quota) internal view returns(uint) {
        return _price1(quota).mul(quota).div(1e18);
    }

    //function calcOut1(uint v) external view viewExtend returns(uint a) {
    //    return _calcOut1(v);
    //}
    function _calcOut1(uint v) internal view returns(uint a) {
        v = v.mul(1e18).div(Config.config()[$C._factorPrice_]);
        uint b = _donateBuf().add(1);
        uint t = _totalDonate().add(1);
        a = Math.sqrt(v.mul(v).add(b.mul(b)).add(v.mul(t).mul(2)));
        a = a.add(v).sub(b).mul(t).div(t.add(b));
    }

    function calcRatio1() external view viewExtend returns(uint r) {
        return _calcRatio1();
    }
    function _calcRatio1() internal view returns(uint r) {
        uint p1 = _price1At(0);
        uint p2 = _price2();
        if(p2 == 0)
            return 1e18;
        return Math.min(p2.sub0(p1).mul(1e18).div(p2).mul(1e18).div(Config.config()[$C._discount_]), 1e18);
    }

    function calcOut(address sender, Twitter[] calldata twitters, uint value, address[] calldata path) external view viewExtend returns(uint a) {
        mapping (bytes32 => address) storage configA = Config.configA();
        address currency = configA[$C._currency_];
        address router = configA[$C._swapRouter_];
        require(path.length == 0 || path[path.length-1] == currency, "INVALID_PATH");
        if(path.length >= 2)
            value = IUniswapV2Router01(router).getAmountsOut(value, path)[1];
        a = _moreQuotaOf(sender, twitters);
        uint r1 = _calcRatio1();
        uint v1 = value.mul(r1).div(1e18);
        uint e1 = _calcIn1(a);
        if(v1 > 0) {
            if(v1 >= e1)
                v1 = e1;
            else
                a = _calcOut1(v1);
        }
        uint v2 = value.sub(v1);
        if(v2 > 0) {
            address[] memory p = new address[](2);
            (p[0], p[1]) = (currency, address(this));
            uint[] memory amounts = IUniswapV2Router01(router).getAmountsOut(v2, p);
            a = a.add(amounts[1]);
        }
    }

    function _donate(address sender, uint value) internal {
        require(Config.config()[$C._denyDonate_] == 0, "denyDonate");
        if(value == 0)
            return;
        uint a = _quotaOf(sender);
        uint r1 = _calcRatio1();
        uint v1 = value.mul(r1).div(1e18);
        uint e1 = _calcIn1(a);
        if(v1 > 0) {
            if(v1 >= e1)
                v1 = e1;
            else
                a = _calcOut1(v1);
            _mint(sender, a);
            _updateLocked(sender, a, Config.config()[$C._lockSpanDonate_]);
            _updateBuf(a);
        }
        uint v2 = value.sub(v1);
        if(v2 > 0) {
            address[] memory path = new address[](2);
            (path[0], path[1]) = (Config.getA($C._currency_), address(this));
            uint[] memory amounts = IUniswapV2Router01(Config.getA($C._swapRouter_)).swapExactTokensForTokens(v2, 0, path, sender, now);
            a = a.add(amounts[1]);
        }
        //_settleReward(sender, a);
        emit Donate(sender, value, a);
    }
    event Donate(address indexed sender, uint value, uint amount);

    //function _settleReward(address sender, uint amt) internal {
    //    address ref = sender;
    //    for(uint i=1; i<=$C._reward_.get(); i++) {
    //        ref = $.accts[ref].referrer;
    //        uint bal = _balanceOf(ref);
    //        if(ref == address(0)) {
    //            ref = $C._ecoAddr_.getA();
    //            bal = uint(-1);
    //        }
    //        uint rwd = Math.min(amt, bal).mul($C._reward_.get(i)).div(1e18);
    //        $.accts[ref].reward = $.accts[ref].reward.add(rwd);
    //        emit SettleReward(sender, ref, i, rwd);
    //    }
    //}
    //event SettleReward(address indexed sender, address indexed referrer, uint indexed degree, uint reward);
    
    //function claimReward() external compound(0) extend {
    //    require($C._allowClaimReward_.get() > 0, "not allow claim reward yet");
    //    address sender = _msgSender();
    //    uint reward = $.accts[sender].reward;
    //    _mint(sender, reward);
    //    _updateLocked(sender, reward, $C._lockSpanReward_.get());
    //    emit ClaimReward(sender, reward);
    //}
    //event ClaimReward(address indexed sender, uint reward);

    //function sell(uint vol) external extend {
    //    address sender = _msgSender();
    //    IUniswapV2Router01 router = IUniswapV2Router01($C._swapRouter_.getA());
    //    _transfer(sender, address(this), vol);
    //    _approve(address(this), address(router), vol);
    //    address[] memory path = new address[](2);
    //    (path[0], path[1]) = (address(this), router.WETH());
    //    uint[] memory amounts = router.swapExactTokensForETH(vol, 0, path, sender, now);
    //    emit Sell(sender, vol, amounts[1]);
    //}
    //event Sell(address indexed sender, uint vol, uint eth);

    //function sellForToken(uint vol, address token) external extend {
    //    address sender = _msgSender();
    //    IUniswapV2Router01 router = IUniswapV2Router01($C._swapRouter_.getA());
    //    _transfer(sender, address(this), vol);
    //    _approve(address(this), address(router), vol);
    //    address[] memory path = new address[](3);
    //    (path[0], path[1], path[2]) = (address(this), router.WETH(), token);
    //    uint[] memory amounts = router.swapExactTokensForTokens(vol, 0, path, sender, now);
    //    emit SellForToken(sender, vol, token, amounts[2]);
    //}
    //event SellForToken(address indexed sender, uint vol, address indexed token, uint amt);

    function addLiquidity_(uint value, uint amount) external extend governance {
        _mint(address(this), amount);
        address currency = Config.getA($C._currency_);
        IUniswapV2Router01 router = IUniswapV2Router01(Config.getA($C._swapRouter_));
        IERC20(currency).safeApprove_(address(router), value);
        _approve(address(this), address(router), amount);
        (, uint amt,) = router.addLiquidity(currency, address(this), value, amount, 0, 0, address(this), now);
        if(amount > amt)
            _burn(address(this), amount - amt);
        $.totalProfit = $.totalProfit.sub(amt);
    }

    function removeLiquidity_(uint liquidity) external extend governance {
        address currency = Config.getA($C._currency_);
        IUniswapV2Router01 router = IUniswapV2Router01(Config.getA($C._swapRouter_));
        address pair = IUniswapV2Factory(Config.getA($C._swapFactory_)).getPair(currency, address(this));
        IERC20(pair).approve(address(router), liquidity);
        (, uint amount) = router.removeLiquidity(currency, address(this), liquidity, 0, 0, address(this), now);
        _burn(address(this), amount);
        $.totalProfit = $.totalProfit.add(amount);
    }

    function buyback_(uint value) external extend governance {
        $.buyback_(value);
    }

    function setSignatories_(address[] calldata signatories) external extend governance {
        $.setSignatories_(signatories);
    }

    function setBuf_(uint buf, uint p1) external extend governance {
        $.setBuf_(buf, p1);
    }

    //receive () virtual override payable external {
    //
    //}
}

//contract FriendsEx is FriendsBase, Extended {
contract FriendsEx is Friends {
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

library FriendsLib {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function __Friends_init_unchained(FriendsStru storage $) external {
        $.index                       = 1e18;
        mapping (bytes32 => uint) storage config = Config.config();
        config[$C._minSignatures_   ] = 1;
        config[$C._maxAirClaim_     ] = 1_000_000e18;
        config[$C._spanAirClaim_    ] = 20 days;
        config[$C._factorAirClaim_  ] = 1e18;
        config[$C._factorProfitAir_ ] = 100;
        config[$C._factorProfitDonate_] = 100;
        config[$C._factorQuota_     ] = 100;
        config[$C._factorMoreForce_ ] = 0.5e18;
        config[$C._unlockBegin_     ] = now.add(1 days);
        config[$C._lockSpanAirClaim_]= 100 days;
        config[$C._lockSpanDonate_  ] = 5 days;
        config[$C._spanDonateBuf_   ] = 5 days;
        config[$C._factorPrice_     ] = 0.0000025e18;   // $0.01
        config[$C._currency_        ] = uint(0x6B175474E89094C44Da98b954EedeAC495271d0F);   // DAI
        if($C._chainId() == 4)         // Rinkeby
            config[$C._currency_    ] = uint(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);   // DAI_Rinkeby
        config[$C._swapRouter_      ] = uint(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        config[$C._swapFactory_     ] = uint(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        config[$C._discount_        ] = 0.10e18;        // 10%
        config[$C._rebaseTime_      ] = now.add(1 days).add(8 hours).sub(now % 8 hours);
        config[$C._rebasePeriod_    ] = 8 hours;
        config[$C._rebaseSpan_      ] = 20*365 days;
        config[$C._allowClaimReward_]= 0;
        //config[$C._reward_         ] = 2;
        //_set(_reward_,        1, 0.10e18);
        //_set(_reward_,        2, 0.05e18);
        config[$C._lockSpanReward_  ] = 100 days;
        config[$C._ecoAddr_         ] = uint(msg.sender);
        config[$C._ecoRatio_        ] = 0.10e18;
    }

    function verify(FriendsStru storage $, address sender, bytes32 referrer, uint nonce, Twitter[] calldata twitters, Signature[] calldata signatures) external {
        mapping (bytes32 => uint) storage config = Config.config();
        require(twitters.length > 0, "missing twitters");
        require(config[$C._denyVerify_] == 0, "denyVerify");
        require(nonce == $.accts[sender].nonce++, "nonce not match");
        require(signatures.length >= config[$C._minSignatures_], "too few signatures");
        for(uint i=0; i<signatures.length; i++) {
            for(uint j=0; j<i; j++)
                require(signatures[i].signatory != signatures[j].signatory, "repetitive signatory");
            bytes32 structHash = keccak256(abi.encode($C.VERIFY_TYPEHASH, sender, referrer, nonce, twitters, signatures[i].signatory));
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01", Friends(payable(address(this))).DOMAIN_SEPARATOR(), structHash));
            address signatory = ecrecover(digest, signatures[i].v, signatures[i].r, signatures[i].s);
            require(signatory != address(0), "invalid signature");
            require(signatory == signatures[i].signatory && $.isSignatory[signatory], "unauthorized");
            emit Authorize(sender, nonce, referrer, twitters, signatures[i].signatory);
        }
    }
    event Authorize(address indexed sender, uint indexed nonce, bytes32 referrer, Twitter[] twitters, address indexed signatory);
    
    function removeLiquidity_(FriendsStru storage $, uint liquidity) external {
        address currency = Config.getA($C._currency_);
        IUniswapV2Router01 router = IUniswapV2Router01(Config.getA($C._swapRouter_));
        address pair = IUniswapV2Factory(Config.getA($C._swapFactory_)).getPair(currency, address(this));
        IERC20(pair).approve(address(router), liquidity);
        (, uint amount) = router.removeLiquidity(currency, address(this), liquidity, 0, 0, address(this), now);
        Friends(payable(address(this))).burn(amount);
        $.totalProfit = $.totalProfit.add(amount);
    }

    function buyback_(FriendsStru storage $, uint value) external {
        Friends friends = Friends(payable(address(this)));
        address currency = Config.getA($C._currency_);
        IUniswapV2Router01 router = IUniswapV2Router01(Config.getA($C._swapRouter_));
        address pair = IUniswapV2Factory(Config.getA($C._swapFactory_)).getPair(currency, address(this));
        require(Config.get($C._donatebackAnytime_) > 0 || friends.totalSupply().mul(friends.price2()).div(1e18) < IERC20(currency).balanceOf(address(this)).add(IERC20(currency).balanceOf(pair).mul(2)), "price2 should below net value");
        address[] memory path = new address[](2);
        (path[0], path[1]) = (currency, address(this));
        IERC20(currency).safeApprove_(address(router), value);
        uint[] memory amounts = router.swapExactTokensForTokens(value, 0, path, address(this), now);
        friends.burn(amounts[1]);
        $.totalProfit = $.totalProfit.add(amounts[1]);
    }

    function setSignatories_(FriendsStru storage $, address[] calldata signatories) external {
        for(uint i=0; i<$.signatories.length; i++)
            $.isSignatory[$.signatories[i]] = false;
            
        $.signatories = signatories;
        
        for(uint i=0; i<$.signatories.length; i++)
            $.isSignatory[$.signatories[i]] = true;
            
        emit SetSignatories(signatories);
    }
    event SetSignatories(address[] signatories);

    function setBuf_(FriendsStru storage $, uint buf, uint p1) external {
        if(p1 == 0)
            p1 = Friends(uint160(address(this))).price1();
        require(buf <= uint112(-1), "donateBuf OVERFLOW");
        ($.donateBuf, $.lastUpdateBuf) = (uint112(buf), uint32(now));
        Config.config()[$C._factorPrice_] = p1.mul($.totalDonate).div(buf);
    }
}


interface IWETH {
    function deposit() external payable;
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
        external
        payable
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
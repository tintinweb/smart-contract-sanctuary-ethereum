// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

struct SMake {
    address maker;
    bool isBid;
    address asset;
    uint256 volume;
    bytes32 currency;
    uint256 price;
    uint256 payType;
    uint256 pending;
    uint256 remain;
    uint256 minVol;
    uint256 maxVol;
    string link;
    uint256 adPex;
}

struct STake {
    uint256 makeID;
    address taker;
    uint256 vol;
    Status status;
    uint256 expiry;
    string link;
    uint256 realPrice;
    address recommender;
}

enum Status {
    None,
    Paid,
    Cancel,
    Done,
    Appeal,
    Buyer,
    Seller,
    Vault,
    MerchantOk,
    MerchantAppeal,
    MerchantAppealDone,
    ClaimTradingMargin
}

struct AppealInfo {
    uint256 takeID;
    address appeal;
    address arbiter;
    Status winner; //0 Status.None  Status.Buyer Status.seller  assetTo
    //Status assetTo;  //buyer seller
    Status appealFeeTo; //vault  buyer seller
    //address buyStakeTo;  //LP punish always to vault
    //buystaking  lp punish to vault
    Status punishSide; //0 Status.None  Status.Buyer Status.seller
    uint256 punishVol;
    Status punishTo; //other side or vault
    bool isDeliver;
}

struct ArbiterPara {
    uint256 takeID;
    Status winner;
    //Status assetTo;
    Status appealFeeTo;
    Status punishSide;
    uint256 punishVol;
    Status punishTo; //other side or vault
}

struct SMakeEx {
    bool isPrivate;
    string memo;
    uint256 tradingMargin;
    uint256 priceType; //0:fix  1:float plus 2:float %
    int256 floatVal; //plus or %
}

struct TakePara {
    uint256 makeID;
    uint256 volume;
    string link;
    uint256 price;
    address recommender;
}

contract DOTC is Configurable {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 internal constant _expiry_ = "expiry";
    //bytes32 internal constant _feeTo_       = "feeTo";
    bytes32 internal constant _feeToken_ = "feeToken";
    bytes32 internal constant _feeVolume_ = "feeVolume";
    bytes32 internal constant _feeRate_ = "feeRate";
    bytes32 internal constant _feeRatio1_ = "feeRatio1";
    bytes32 internal constant _feeBuf_ = "feeBuf";
    bytes32 internal constant _lastUpdateBuf_ = "lastUpdateBuf";
    bytes32 internal constant _spanBuf_ = "spanBuf";
    bytes32 internal constant _spanLock_ = "spanLock";
    bytes32 internal constant _rewardOfSpan_ = "rewardOfSpan";
    bytes32 internal constant _rewardRatioMaker_ = "rewardRatioMaker";
    bytes32 internal constant _rewardToken_ = "rewardToken";
    bytes32 internal constant _rewards_ = "rewards";
    bytes32 internal constant _locked_ = "locked";
    bytes32 internal constant _lockEnd_ = "lockEnd";
    /*  bytes32 internal constant _rebaseTime_  = "rebaseTime";
    bytes32 internal constant _rebasePeriod_= "rebasePeriod";
    bytes32 internal constant _factorPrice20_   = "factorPrice20";
    bytes32 internal constant _lpTknMaxRatio_   = "lpTknMaxRatio";
    bytes32 internal constant _lpCurMaxRatio_   = "lpCurMaxRatio";*/
    bytes32 internal constant _vault_ = "vault";
    bytes32 internal constant _pairTokenA_ = "pairTokenA";
    bytes32 internal constant _swapFactory_ = "swapFactory";
    bytes32 internal constant _swapRouter_ = "swapRouter";
    bytes32 internal constant _mine_ = "mine";
    bytes32 internal constant _assetList_ = "assetList";
    bytes32 internal constant _assetFreeLimit_ = "assetFreeLimit";
    bytes32 internal constant _usd_ = "usd";
    bytes32 internal constant _bank_ = "bank";
    bytes32 internal constant _merchantPool_ = "merchantPool";
    bytes32 internal constant _tradingPool_ = "tradingPool";
    bytes32 internal constant _preDoneExpiry_ = "preDoneExpiry"; //7days
    bytes32 internal constant _priceAndRate_ = "priceAndRate";
    // bytes32 internal constant _babtoken_ = "babtoken";

    address public staking;
    address[] public arbiters;
    mapping(address => bool) public isArbiter;
    mapping(address => uint256) public biddingN;

    mapping(uint256 => SMake) public makes;
    mapping(uint256 => STake) public takes;
    uint256 public makesN;
    uint256 public takesN;

    mapping(uint256 => address) public appealAddress; //takeID=> appeal address  //obs    new  appealInfos
    mapping(uint256 => bool) public makePrivate; //makeID=> public or private; //obs    new makeExs

    uint256 private _entered;
    modifier nonReentrant() {
        require(_entered == 0, "reentrant");
        _entered = 1;
        _;
        _entered = 0;
    }

    mapping(address => string) public links; //tg link
    mapping(uint256 => AppealInfo) public appealInfos; //takeID=> AppealInfo

    mapping(uint256 => SMakeEx) public makeExs; //makeID=>SMakeEx

    bytes32[] public customFiatFeeKeys;
    mapping(bytes32 => uint256) public fiatFeeMap; //currency=>feeRate
    bytes32 internal constant _claimFor_ = "claimFor";

    function __DOTC_init(
        address governor_,
        address staking_,
        address feeTo_,
        address feeToken_,
        uint256 feeVolume_
    ) public initializer {
        __Governable_init_unchained(governor_);
        __DOTC_init_unchained(staking_, feeTo_, feeToken_, feeVolume_);
    }

    function __DOTC_init_unchained(
        address staking_,
        address vault_,
        address feeToken_,
        uint256 feeVolume_
    ) internal governance initializer {
        staking = staking_;
        config[_expiry_] = 30 minutes;
        config[_vault_] = uint256(vault_);
        config[_feeToken_] = uint256(feeToken_);
        config[_feeVolume_] = feeVolume_;

        __DOTC_init_reward();
    }

    function setStakingPool(address addr) public governance {
        staking = addr;
    }

    function __DOTC_init_reward() public governance {
        config[_feeRate_] = 0; //  0%
        config[_feeRatio1_] = 1e18; //0.10e18;        // 10% 100%
        config[_feeBuf_] = 1_000_000e18;
        config[_lastUpdateBuf_] = now;
        config[_spanBuf_] = 5 days;
        config[_spanLock_] = 5 days;
        config[_rewardOfSpan_] = 0; //1_000_000e18;
        config[_rewardRatioMaker_] = 0.25e18; // 25%
        config[_rewardToken_] = uint256(
            0xdAC17F958D2ee523a2206206994597C13D831ec7
        ); // usdt
        config[_pairTokenA_] = uint256(
            0xdAC17F958D2ee523a2206206994597C13D831ec7
        ); // usdt
        // config[_swapFactory_] = uint256(
        //     0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73
        // ); // PancakeFactory V2
        // config[_swapRouter_] = uint256(
        //     0x10ED43C718714eb63d5aA57B78B54704E256024E
        // ); // PancakeRouter V2
        config[_mine_] = uint256(0xa2A2F3C2F15d65Eac8FFC5151Eca240b13EB4350);
        _setConfig(_assetList_, 0x4Fabb145d64652a948d72533023f6E7A623C7C53, 1); // BUSD
        _setConfig(_assetList_, 0xa2A2F3C2F15d65Eac8FFC5151Eca240b13EB4350, 1); // USDT
        _setConfig(_assetList_, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 1); // USDC
        __DOTC_init_reward2();
    }

    function __DOTC_init_reward2() public governance {
        //  _setConfig(_assetFreeLimit_, 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56, 1e18);    // BUSD //test 1
        //  _setConfig(_assetFreeLimit_, 0x55d398326f99059fF775485246999027B3197955, 1e18);    // USDT
        //  _setConfig(_assetFreeLimit_, 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d, 1e18);    // USDC
        config[_usd_] = uint256(0xa2A2F3C2F15d65Eac8FFC5151Eca240b13EB4350); // usdt
        config[_rewardToken_] = uint256(
            0xa2A2F3C2F15d65Eac8FFC5151Eca240b13EB4350
        ); // usdt

        /*config[_rebaseTime_      ] = now.add(0 days).add(8 hours).sub(now % 8 hours);
        config[_rebasePeriod_    ] = 8 hours;
        config[_factorPrice20_   ] = 1.1e18;           // price20 = price1 * 1.1
        config[_lpTknMaxRatio_   ] = 0.10e18;        // 10%
        config[_lpCurMaxRatio_   ] = 0.50e18;        // 50% */
        // config[_pairTokenA_] = uint256(
        //     0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3
        // ); // BNB
        //config[_feeTo_] = uint(address(this));
        (, uint256 p2) = priceEth();
        p2 = p2.div(2); //50% off
        config[_feeBuf_] = config[_rewardOfSpan_].mul(p2).div(1e18);
    }

    /* function migrate(address vault_) external governance {
        config[_vault_] = uint(vault_);
        __DOTC_init_reward2();
    }*/

    function setBiddingN_(address account, uint256 biddingN_)
        external
        governance
    {
        biddingN[account] = biddingN_;
    }

    function setVault_(address vault_) public governance {
        config[_vault_] = uint256(vault_);
    }

    function setCustomFiatFee(
        bytes32[] memory fiatList,
        uint256[] memory feeList
    ) external governance {
        customFiatFeeKeys = fiatList;

        for (uint256 i = 0; i < fiatList.length; i++) {
            fiatFeeMap[fiatList[i]] = feeList[i];
        }
    }

    function isCustomFiat(bytes32 currency) public returns (bool include) {
        for (uint256 i = 0; i < customFiatFeeKeys.length; i++) {
            if (currency == customFiatFeeKeys[i]) {
                include = true;
                break;
            }
        }
    }

    function setArbiters_(
        address[] calldata arbiters_,
        string[] calldata links_
    ) external governance {
        for (uint256 i = 0; i < arbiters.length; i++)
            isArbiter[arbiters[i]] = false;

        arbiters = arbiters_;

        for (uint256 i = 0; i < arbiters.length; i++) {
            isArbiter[arbiters[i]] = true;
            links[arbiters[i]] = links_[i];
        }

        emit SetArbiters(arbiters_);
    }

    event SetArbiters(address[] arbiters_);

    function make(
        SMake memory make_,
        SMakeEx memory makeEx_ /*bool isPrivate*/
    ) external virtual nonReentrant returns (uint256 makeID) {
        require(make_.volume > 0, "volume should > 0");
        require(make_.minVol <= make_.maxVol, "minVol must <= maxVol");
        require(make_.maxVol <= make_.volume, "maxVol must <= volume");
        if (makeEx_.tradingMargin > 0) {
            require(
                IMerchantStakePool(address(config[_merchantPool_])).isMerchant(
                    msg.sender
                ),
                "must merchant"
            );
        } else if (
            make_.volume > getConfigA(_assetFreeLimit_, make_.asset) &&
            !IMerchantStakePool(address(config[_merchantPool_])).isMerchant(
                msg.sender
            )
        ) {
            require(
                IStaking(staking).enough(msg.sender),
                "make ad GT Limit,must stake"
            );
        }
        if (make_.isBid) {
            //require(staking == address(0) || IStaking(staking).enough(msg.sender));
            biddingN[msg.sender]++;
        } else
            IERC20(make_.asset).safeTransferFrom(
                msg.sender,
                address(this),
                make_.volume
            );
        if (make_.adPex > 0)
            IERC20(address(config[_rewardToken_])).safeTransferFrom(
                msg.sender,
                address(config[_vault_]),
                make_.adPex
            );
        makeID = makesN;
        make_.maker = msg.sender;
        make_.pending = 0;
        make_.remain = make_.volume;
        makes[makeID] = make_; //SMake(msg.sender, isBid, asset, volume, currency, price,payType, 0, volume,minVol,maxVol,link,adPex,isPrivate);
        //makePrivate[makeID] = isPrivate;
        makeExs[makeID] = makeEx_;
        makesN++;
        emit Make(
            makeID,
            msg.sender,
            make_.isBid,
            make_.asset,
            make_,
            makeEx_.isPrivate
        );
        emit MakeEx(makeID, makeEx_);
    }

    event Make(
        uint256 indexed makeID,
        address indexed maker,
        bool isBid,
        address indexed asset,
        SMake smake,
        bool isPrivate
    );
    event MakeEx(uint256 indexed makeID, SMakeEx makeExs);

    function cancelMake(uint256 makeID)
        external
        virtual
        nonReentrant
        returns (uint256 vol)
    {
        require(makes[makeID].maker != address(0), "Nonexistent make order");
        require(makes[makeID].maker == msg.sender, "only maker");
        require(makes[makeID].remain > 0, "make.remain should > 0");
        //require(config[_disableCancle_] == 0, 'disable cancle');

        vol = makes[makeID].remain;
        if (!makes[makeID].isBid)
            IERC20(makes[makeID].asset).safeTransfer(msg.sender, vol);
        else {
            if (makes[makeID].pending == 0)
                biddingN[msg.sender] = biddingN[msg.sender].sub(1);
        }
        makes[makeID].remain = 0;
        emit CancelMake(makeID, msg.sender, makes[makeID].asset, vol);
    }

    event CancelMake(
        uint256 indexed makeID,
        address indexed maker,
        address indexed asset,
        uint256 vol
    );

    function reprice(uint256 makeID, uint256 newPrice)
        external
        virtual
        returns (uint256 vol, uint256 newMakeID)
    {
        require(makes[makeID].maker != address(0), "Nonexistent make order");
        require(makes[makeID].maker == msg.sender, "only maker");
        require(makes[makeID].remain > 0, "make.remain should > 0");

        vol = makes[makeID].remain;
        //bool makePri = makePrivate[makeID];
        newMakeID = makesN;
        SMake memory newMake;
        newMake = makes[makeID];
        newMake.volume = vol;
        newMake.price = newPrice;
        newMake.pending = 0;
        newMake.remain = vol;
        makes[newMakeID] = newMake;
        //makePrivate[newMakeID] = makePri;
        makeExs[newMakeID] = makeExs[makeID];
        makesN++;
        makes[makeID].remain = 0;
        if (makes[makeID].isBid && makes[makeID].pending > 0) {
            biddingN[msg.sender] = biddingN[msg.sender].add(1);
        }
        emit CancelMake(makeID, msg.sender, makes[makeID].asset, vol);
        emit Make(
            newMakeID,
            msg.sender,
            makes[newMakeID].isBid,
            makes[newMakeID].asset,
            makes[newMakeID],
            makeExs[newMakeID].isPrivate
        );
        emit Reprice(
            makeID,
            newMakeID,
            msg.sender,
            newMake,
            makeExs[newMakeID].isPrivate
        );
    }

    event Reprice(
        uint256 indexed makeID,
        uint256 indexed newMakeID,
        address indexed maker,
        SMake smake,
        bool makePri
    );

    function take(
        uint256 makeID,
        uint256 volume,
        string memory link,
        uint256 price,
        address recommender
    ) external virtual nonReentrant returns (uint256 takeID, uint256 vol) {
        //(takeID,vol) = ArbitrateLib.takeLib(makes,makeExs,takes,config,biddingN,makeID,volume,link,price,recommender);
        (takeID, vol) = ArbitrateLib.takeLib(
            makes,
            makeExs,
            takes,
            config,
            biddingN,
            TakePara(makeID, volume, link, price, recommender)
        );

        takesN++;

        /*require(makes[makeID].maker != address(0), 'Nonexistent make order');
        require(makes[makeID].remain > 0, 'make.remain should > 0');
        require(makes[makeID].minVol <= volume , 'volume must > minVol');
        require(makes[makeID].maxVol >= volume, 'volume must < maxVol');
        if (makeExs[makeID].tradingMargin>0){//config[_tradingPool_]
            IERC20(address(config[_feeToken_])).safeTransferFrom(msg.sender, address(this), makeExs[makeID].tradingMargin);
            if(IERC20(address(config[_feeToken_])).allowance(address(this),address(config[_tradingPool_]))<makeExs[makeID].tradingMargin)
                IERC20(address(config[_feeToken_])).approve(address(config[_tradingPool_]),uint(-1));
            ITradingStakePool(address(config[_tradingPool_])).stake(msg.sender,makeExs[makeID].tradingMargin);
        }else if (volume > getConfigA(_assetFreeLimit_,makes[makeID].asset))
            require(IStaking(staking).enough(msg.sender),"GT Limit,must stake");
        vol = volume;
        if(vol > makes[makeID].remain)
            vol = makes[makeID].remain;
        if(!makes[makeID].isBid) {
            //require(staking == address(0) || IStaking(staking).enough(msg.sender));
            biddingN[msg.sender]++;
        } else
            IERC20(makes[makeID].asset).safeTransferFrom(msg.sender, address(this), vol);
        makes[makeID].remain = makes[makeID].remain.sub(vol);
        makes[makeID].pending = makes[makeID].pending.add(vol);
        
        uint realPrice;
        uint priceType = makeExs[makeID].priceType;
        if(priceType!=0){
            (uint price1,uint8 decimals,uint rate) = IPriceAndRate(address(config[_priceAndRate_])).getPriceAndRate(makes[makeID].asset,makes[makeID].currency);
            require(price1>0,"No the asset");
            require(rate>0,"No the currency");
            if (priceType ==1)
                realPrice = price1.mul(rate).div(uint(decimals)).add(makeExs[makeID].floatVal);//1170e18 *6.71e18
            else if(priceType ==2)
                realPrice = price1.mul(rate).div(uint(decimals)).mul(1e18+makeExs[makeID].floatVal).div(1e18);//
            uint diff = realPrice>price? realPrice-price:price-realPrice;
            require(diff.mul(1000)<realPrice.mul(5),"price not match chainlink");
            realPrice = price;
        }else{
            realPrice  = makes[makeID].price;
        }
        takeID = takesN;
        takes[takeID] = STake(makeID, msg.sender, vol, Status.None, now.add(config[_expiry_]),link,realPrice);
        takesN++;
        emit Take(takeID, makeID, msg.sender, vol, takes[takeID].expiry,link,realPrice);*/
    }

    //event Take(uint indexed takeID, uint indexed makeID, address indexed taker, uint vol, uint expiry,string link,uint realPrice);

    function cancelTake(uint256 takeID)
        external
        virtual
        nonReentrant
        returns (uint256 vol)
    {
        require(takes[takeID].taker != address(0), "Nonexistent take order");
        uint256 makeID = takes[takeID].makeID;
        (address buyer, address seller) = makes[makeID].isBid
            ? (makes[makeID].maker, takes[takeID].taker)
            : (takes[takeID].taker, makes[makeID].maker);

        if (msg.sender == buyer) {
            require(
                takes[takeID].status <= Status.None,
                "buyer can cancel neither Status.None nor Status.Paid take order"
            );
        } else if (msg.sender == seller) {
            require(
                takes[takeID].status == Status.None,
                "seller can only cancel Status.None take order"
            );
            require(
                takes[takeID].expiry < now,
                "seller can only cancel expired take order"
            );
        } else revert("only buyer or seller");
        if (!makes[makeID].isBid) biddingN[buyer] = biddingN[buyer].sub(1);
        vol = takes[takeID].vol;
        IERC20(makes[makeID].asset).safeTransfer(seller, vol);

        makes[makeID].pending = makes[makeID].pending.sub(vol);
        takes[takeID].status = Status.Cancel;

        if (makes[makeID].isBid) {
            if (makes[makeID].pending == 0 && makes[makeID].remain == 0)
                biddingN[buyer] = biddingN[buyer].sub(1);
        }

        emit CancelTake(takeID, makeID, msg.sender, vol);
    }

    event CancelTake(
        uint256 indexed takeID,
        uint256 indexed makeID,
        address indexed sender,
        uint256 vol
    );

    // function paid(uint256 takeID) external virtual {
    //     require(takes[takeID].taker != address(0), "Nonexistent take order");
    //     require(takes[takeID].status == Status.None, "only Status.None");
    //     uint256 makeID = takes[takeID].makeID;
    //     address buyer = makes[makeID].isBid
    //         ? makes[makeID].maker
    //         : takes[takeID].taker;
    //     require(msg.sender == buyer, "only buyer");

    //     takes[takeID].status = Status.Paid;
    //     takes[takeID].expiry = now.add(config[_expiry_]);

    //     emit Paid(takeID, makeID, buyer);
    // }

    // event Paid(
    //     uint256 indexed takeID,
    //     uint256 indexed makeID,
    //     address indexed buyer
    // );

    function deliver(uint256 takeID)
        external
        virtual
        nonReentrant
        returns (uint256 vol)
    {
        require(takes[takeID].taker != address(0), "Nonexistent take order");
        require(
            takes[takeID].status <= Status.None,
            "only Status.None or Paid"
        );
        uint256 makeID = takes[takeID].makeID;
        (address buyer, address seller) = makes[makeID].isBid
            ? (makes[makeID].maker, takes[takeID].taker)
            : (takes[takeID].taker, makes[makeID].maker);
        require(msg.sender == seller, "only seller");
        vol = takes[takeID].vol;

        uint256 fee = _payFee(
            takeID,
            makes[makeID].asset,
            vol,
            makes[makeID].currency
        );
        IERC20(makes[makeID].asset).safeTransfer(buyer, vol.sub(fee));

        makes[makeID].pending = makes[makeID].pending.sub(vol);
        takes[takeID].status = Status.Done;
        takes[takeID].expiry = now.add(config[_preDoneExpiry_]);

        if (
            (!makes[makeID].isBid) ||
            (makes[makeID].remain == 0 && makes[makeID].pending == 0)
        ) biddingN[buyer] = biddingN[buyer].sub(1);

        emit Deliver(takeID, makeID, seller, vol);
        emit ArbitrateLib.Deal(takeID, makes[makeID].asset, vol);
    }

    event Deliver(
        uint256 indexed takeID,
        uint256 indexed makeID,
        address indexed seller,
        uint256 vol
    );

    //event Deal(uint indexed takeID, address indexed asset, uint vol);

    function merchantOk(uint256 takeID) external virtual nonReentrant {
        ArbitrateLib.merchantOk(makes, makeExs, takes, config, takeID);
        /*uint makeID = takes[takeID].makeID;
        require(makes[makeID].maker == msg.sender, 'must be maker');
        require(takes[takeID].status == Status.Done, 'only Status.Done');
        takes[takeID].status == Status.MerchantOk;   */
    }

    function claimTradingMargin(uint256 takeID) external virtual nonReentrant {
        ArbitrateLib.claimTradingMargin(makes, makeExs, takes, config, takeID);
        /*require(takes[takeID].taker == msg.sender, 'must be taker');
        require(takes[takeID].status == Status.MerchantOk ||((takes[takeID].status == Status.Done)&&(now>takes[takeID].expiry)&&makeExs[takes[takeID].makeID].tradingMargin>0),"No claimTradingMargin");
        takes[takeID].status == Status.ClaimTradingMargin; 
        ITradingStakePool(config[_tradingPool_]).withdraw(msg.sender,makeExs[takes[takeID].makeID].tradingMargin); */
    }

    function appeal(uint256 takeID) external virtual nonReentrant {
        ArbitrateLib.appeal(
            makes,
            makeExs,
            takes,
            config,
            appealInfos,
            takeID,
            arbiters,
            isArbiter
        ); //mapping(uint =>AppealInfo) public appealInfos
        /*require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status == Status.Paid, 'only Status.Paid');
        uint makeID = takes[takeID].makeID;
        require(msg.sender == makes[makeID].maker || msg.sender == takes[takeID].taker, 'only maker or taker');
        require(takes[takeID].expiry < now, 'only expired');
        IERC20(address(config[_feeToken_])).safeTransferFrom(msg.sender, address(config[_vault_]), config[_feeVolume_]);
        takes[takeID].status = Status.Appeal;
        appealAddress[takeID] = msg.sender; 
        emit Appeal(takeID, makeID, msg.sender, takes[takeID].vol);*/
    }

    //event Appeal(uint indexed takeID, uint indexed makeID, address indexed sender, uint vol);

    function arbitrate(
        uint256 takeID,
        Status winner,
        Status appealFeeTo,
        Status punishSide,
        uint256 punishVol,
        Status punishTo
    ) external virtual nonReentrant returns (uint256 vol) {
        ArbiterPara memory arbiterPara = ArbiterPara(
            takeID,
            winner,
            appealFeeTo,
            punishSide,
            punishVol,
            punishTo
        );

        vol = ArbitrateLib.arbitrate(
            makes,
            makeExs,
            takes,
            config,
            appealInfos,
            biddingN,
            arbiterPara
        );
        /*      require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status == Status.Appeal, 'only Status.Appeal');
        require(isArbiter[msg.sender], 'only arbiter');
        uint makeID = takes[takeID].makeID;
        (address buyer, address seller) = makes[makeID].isBid ? (makes[makeID].maker, takes[takeID].taker) : (takes[takeID].taker, makes[makeID].maker);
        
        vol = takes[takeID].vol;
        if(status == Status.Buyer) {
            uint fee = _payFee(takeID, makes[makeID].asset, vol);
            IERC20(makes[makeID].asset).safeTransfer(buyer, vol.sub(fee));
            emit Deal(takeID,makes[makeID].asset,vol);
        } else if(status == Status.Seller) {
            IERC20(makes[makeID].asset).safeTransfer(seller, vol);
            if(staking.isContract())
                IStaking(staking).punish(buyer);
        } else
            revert('status should be Buyer or Seller');
        makes[makeID].pending = makes[makeID].pending.sub(vol);
        takes[takeID].status = status;
        if ((!makes[makeID].isBid) || (makes[makeID].remain==0 && makes[makeID].pending == 0))
            biddingN[buyer] = biddingN[buyer].sub(1);
        emit Arbitrate(takeID, makeID, msg.sender, vol, status);*/
    }

    //    event Arbitrate(uint indexed takeID, uint indexed makeID, address indexed arbiter, uint vol, Status status);

    function _feeBuf() internal view returns (uint256) {
        uint256 spanBuf = config[_spanBuf_];
        return
            spanBuf
                .sub0(now.sub(config[_lastUpdateBuf_]))
                .mul(config[_feeBuf_])
                .div(spanBuf);
    }

    function price1() public view returns (uint256) {
        return _feeBuf().mul(1e18).div0(config[_rewardOfSpan_]);
    }

    function price() public view returns (uint256 p1, uint256 p2) {
        // (p1, p2) = ArbitrateLib.price(config);
        /*(p1,p2) = priceEth();
        address tokenA = address(config[_pairTokenA_]);
        address usd = address(config[_usd_]);
        address pair = IUniswapV2Factory(config[_swapFactory_]).getPair(tokenA,usd);
        uint volA = IERC20(tokenA).balanceOf(pair);
        uint volU = IERC20(usd).balanceOf(pair);
        p1 = p1.mul(volU).div(volA);
        p2 = p2.mul(volU).div(volA);*/
    }

    function priceEth() public view returns (uint256 p1, uint256 p2) {
        // (p1, p2) = ArbitrateLib.priceEth(config);
        /*p1 = price1();
        
        address tokenA = address(config[_pairTokenA_]);
        address tokenR = address(config[_rewardToken_]);
        address pair = IUniswapV2Factory(config[_swapFactory_]).getPair(tokenA, tokenR);
        if(pair == address(0) || IERC20(tokenA).balanceOf(pair) == 0)
            p2 = 0;
        else
            p2 = IERC20(tokenA).balanceOf(pair).mul(1e18).div(IERC20(tokenR).balanceOf(pair));*/
    }

    function earned(address acct) public view returns (uint256) {
        return getConfigA(_rewards_, acct);
    }

    function lockEnd(address acct) public view returns (uint256) {
        return getConfigA(_lockEnd_, acct);
    }

    function locked(address acct) public view returns (uint256) {
        uint256 end = lockEnd(acct);
        return getConfigA(_locked_, acct).mul(end.sub0(now)).div0(end);
    }

    function claimable(address acct) public view returns (uint256) {
        return earned(acct).sub(locked(acct));
    }

    function claim() external {
        address acct = msg.sender;
        IERC20(config[_rewardToken_]).safeTransfer(acct, claimable(acct));
        _setConfig(_rewards_, acct, locked(acct));
    }

    function claimFor_(address acct) external {
        require(getConfigA(_claimFor_, msg.sender) == 1, "only claimForer");
        IERC20(config[_rewardToken_]).safeTransfer(acct, claimable(acct));
        _setConfig(_rewards_, acct, locked(acct));
    }

    function payFee(
        uint256 takeID,
        address asset,
        uint256 vol,
        uint256 makeID
    ) public returns (uint256 fee) {
        require(
            msg.sender == address(this),
            "must msg.sender == address(this)"
        );
        fee = _payFee(takeID, asset, vol, makes[makeID].currency);
    }

    function _payFee(
        uint256 takeID,
        address asset,
        uint256 vol,
        bytes32 currency
    ) internal returns (uint256 fee) {
        if (isCustomFiat(currency)) {
            fee = vol.mul(fiatFeeMap[currency]).div(1e6);
        } else {
            fee = vol.mul(config[_feeRate_]).div(1e18);
        }
        if (fee == 0) return fee;
        address rewardToken = address(config[_rewardToken_]);
        (
            IUniswapV2Router01 router,
            address tokenA,
            uint256 amt
        ) = _swapToPairTokenA(asset, fee);

        uint256 amt1 = amt.mul(config[_feeRatio1_]).div(1e18);
        IERC20(tokenA).safeTransfer(address(config[_vault_]), amt1);
        uint256 feeBuf = _feeBuf();
        vol = amt1.mul(config[_rewardOfSpan_]).div0(feeBuf);
        IERC20(rewardToken).safeTransferFrom(
            address(config[_mine_]),
            address(this),
            vol
        );
        config[_feeBuf_] = feeBuf.add(amt1);
        config[_lastUpdateBuf_] = now;

        if (amt.sub(amt1) > 0) {
            address[] memory path = new address[](2);
            path[0] = tokenA;
            path[1] = rewardToken;
            IERC20(tokenA).safeApprove_(address(router), amt.sub(amt1));
            uint256[] memory amounts = router.swapExactTokensForTokens(
                amt.sub(amt1),
                0,
                path,
                address(this),
                now
            );
            payFee2(takeID, vol, amounts[1]);
        }
        IVault(config[_vault_]).rebase();
    }

    event FeeReward(uint256 indexed takeID, uint256 makeVol, uint256 takeVol);
    event RecommendReward(uint256 indexed takeID, uint256 vol);

    function payFee2(
        uint256 takeID,
        uint256 v1,
        uint256 v2
    ) internal {
        uint256 ratio = config[_rewardRatioMaker_];
        uint256 v = v1.add(v2);
        if (takes[takeID].recommender != address(0)) {
            uint256 vRecommender = v.mul(ratio).div(2e18); //==maker vol   50%
            emit FeeReward(
                takeID,
                vRecommender,
                v.mul(uint256(1e18).sub(ratio)).div(1e18)
            );
            emit RecommendReward(takeID, vRecommender);
            //address rewardToken = address(config[_rewardToken_]);
            //IERC20(rewardToken).safeTransfer(takes[takeID].recommender,vRecommender);
            uint256 recommReward = getConfigA(
                _rewards_,
                takes[takeID].recommender
            );
            _setConfig(
                _rewards_,
                takes[takeID].recommender,
                recommReward.add(vRecommender)
            );
            v1 = v;
            v2 = 0;
            _updateReward(
                makes[takes[takeID].makeID].maker,
                v1,
                v2,
                ratio.div(2)
            );
            _updateReward(
                takes[takeID].taker,
                v1,
                v2,
                uint256(1e18).sub(ratio)
            );
        } else {
            emit FeeReward(
                takeID,
                v.mul(ratio).div(1e18),
                v.mul(uint256(1e18).sub(ratio)).div(1e18)
            );
            v1 = v;
            v2 = 0;
            _updateReward(makes[takes[takeID].makeID].maker, v1, v2, ratio);
            _updateReward(
                takes[takeID].taker,
                v1,
                v2,
                uint256(1e18).sub(ratio)
            );
        }
    }

    function _updateReward(
        address acct,
        uint256 v1,
        uint256 v2,
        uint256 ratio
    ) internal {
        v1 = v1.mul(ratio).div(1e18);
        v2 = v2.mul(ratio).div(1e18);
        uint256 lkd = locked(acct);
        uint256 end = lockEnd(acct);
        end = end
            .sub0(now)
            .mul(lkd)
            .add(getConfig(_spanLock_).mul(v1))
            .div(lkd.add(v1))
            .add(now);
        _setConfig(_locked_, acct, lkd.add(v1).mul(end).div(end.sub(now)));
        _setConfig(_lockEnd_, acct, end);
        _setConfig(_rewards_, acct, earned(acct).add(v1).add(v2));
    }

    function _swapToPairTokenA(address asset, uint256 fee)
        internal
        returns (
            IUniswapV2Router01 router,
            address tokenA,
            uint256 amt
        )
    {
        (router, tokenA, amt) = ArbitrateLib._swapToPairTokenA(
            config,
            asset,
            fee
        );
        /*router = IUniswapV2Router01(config[_swapRouter_]);
        tokenA = address(config[_pairTokenA_]);
        if(tokenA == asset)
            return (router, asset, fee);
        IERC20(asset).safeApprove_(address(router), fee);
        if(IUniswapV2Factory(config[_swapFactory_]).getPair(asset, tokenA) != address(0)) {
            address[] memory path = new address[](2);
            path[0] = asset;
            path[1] = tokenA;
            uint[] memory amounts = router.swapExactTokensForTokens(fee, 0, path, address(this), now);
            amt = amounts[1];
        } else {
            address[] memory path = new address[](3);
            path[0] = asset;
            path[1] = router.WETH();
            path[2] = tokenA;
            uint[] memory amounts = router.swapExactTokensForTokens(fee, 0, path, address(this), now);
            amt = amounts[2];
        }*/
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[41] private ______gap;
}

library ArbitrateLib {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 internal constant _expiry_ = "expiry";
    //bytes32 internal constant _feeTo_       = "feeTo";
    bytes32 internal constant _feeToken_ = "feeToken";
    bytes32 internal constant _feeVolume_ = "feeVolume";
    bytes32 internal constant _feeRate_ = "feeRate";
    bytes32 internal constant _feeRatio1_ = "feeRatio1";
    bytes32 internal constant _feeBuf_ = "feeBuf";
    bytes32 internal constant _lastUpdateBuf_ = "lastUpdateBuf";
    bytes32 internal constant _spanBuf_ = "spanBuf";
    bytes32 internal constant _spanLock_ = "spanLock";
    bytes32 internal constant _rewardOfSpan_ = "rewardOfSpan";
    bytes32 internal constant _rewardRatioMaker_ = "rewardRatioMaker";
    bytes32 internal constant _rewardToken_ = "rewardToken";
    bytes32 internal constant _rewards_ = "rewards";
    bytes32 internal constant _locked_ = "locked";
    bytes32 internal constant _lockEnd_ = "lockEnd";
    /*  bytes32 internal constant _rebaseTime_  = "rebaseTime";
    bytes32 internal constant _rebasePeriod_= "rebasePeriod";
    bytes32 internal constant _factorPrice20_   = "factorPrice20";
    bytes32 internal constant _lpTknMaxRatio_   = "lpTknMaxRatio";
    bytes32 internal constant _lpCurMaxRatio_   = "lpCurMaxRatio";*/
    bytes32 internal constant _vault_ = "vault";
    bytes32 internal constant _pairTokenA_ = "pairTokenA";
    bytes32 internal constant _swapFactory_ = "swapFactory";
    bytes32 internal constant _swapRouter_ = "swapRouter";
    bytes32 internal constant _mine_ = "mine";
    bytes32 internal constant _assetList_ = "assetList";
    bytes32 internal constant _assetFreeLimit_ = "assetFreeLimit";
    bytes32 internal constant _usd_ = "usd";
    bytes32 internal constant _bank_ = "bank";
    bytes32 internal constant _merchantPool_ = "merchantPool";
    bytes32 internal constant _tradingPool_ = "tradingPool";
    bytes32 internal constant _preDoneExpiry_ = "preDoneExpiry"; //7days
    bytes32 internal constant _priceAndRate_ = "priceAndRate";
    // bytes32 internal constant _babtoken_ = "babtoken";

    struct Tmpval {
        address buyer;
        address seller;
        uint256 tradingMargin;
    }

    bytes32 internal constant _claimFor_ = "claimFor";

    function getRandArbiter(
        address[] storage arbiters,
        mapping(address => bool) storage isArbiter
    ) public view returns (address randArbiter) {
        uint256 hash = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1 - (block.difficulty % 100))
                )
            )
        );
        hash = hash % arbiters.length;
        uint256 cnt = 0;
        randArbiter = address(0);
        while (true) {
            if (isArbiter[arbiters[hash]]) {
                randArbiter = arbiters[hash];
                break;
            }
            hash = (hash + 1) % arbiters.length;
            cnt++;
            if (cnt >= arbiters.length) break;
        }
    }

    function appeal(
        mapping(uint256 => SMake) storage makes,
        mapping(uint256 => SMakeEx) storage makeExs,
        mapping(uint256 => STake) storage takes,
        mapping(bytes32 => uint256) storage config,
        mapping(uint256 => AppealInfo) storage appealInfos,
        uint256 takeID,
        address[] storage arbiters,
        mapping(address => bool) storage isArbiter
    ) external virtual {
        // DOTC dotc = DOTC(address(this));
        STake memory take = takes[takeID];
        require(take.taker != address(0), "Nonexistent take order");
        if (take.status == Status.None) {
            //normal appeal or merchant appeal
            uint256 makeID = take.makeID;
            require(
                msg.sender == makes[makeID].maker || msg.sender == take.taker,
                "only maker or taker"
            );

            (, address seller) = makes[makeID].isBid
                ? (makes[makeID].maker, takes[takeID].taker)
                : (takes[takeID].taker, makes[makeID].maker);
            if (msg.sender != seller)
                require(take.expiry < now, "only expired");
            IERC20(address(config[_feeToken_])).safeTransferFrom(
                msg.sender,
                address(config[_bank_]),
                config[_feeVolume_]
            ); //tmp bank ,appeal 5PEX, arbitrate to vault or seller or buyer
            if (makeExs[makeID].tradingMargin == 0)
                takes[takeID].status = Status.Appeal;
            else takes[takeID].status = Status.MerchantAppeal;
            //appealAddress[takeID] = msg.sender;
            appealInfos[takeID].takeID = takeID;
            appealInfos[takeID].appeal = msg.sender;
            appealInfos[takeID].arbiter = getRandArbiter(arbiters, isArbiter);
            appealInfos[takeID].isDeliver = false;

            emit Appeal(
                takeID,
                makeID,
                msg.sender,
                take.vol,
                appealInfos[takeID].arbiter
            );
        } else {
            //merchant appeal
            require(take.status == Status.Done, "only Status.Done");
            uint256 makeID = take.makeID;
            require(
                msg.sender == makes[makeID].maker || msg.sender == take.taker,
                "only maker or taker"
            );

            //        (, address seller) = makes[makeID].isBid ? (makes[makeID].maker, takes[takeID].taker) : (takes[takeID].taker, makes[makeID].maker);
            require(
                makeExs[makeID].tradingMargin > 0 &&
                    msg.sender == makes[makeID].maker,
                "must be merchat"
            );
            require(now < take.expiry, "only expired");
            IERC20(address(config[_feeToken_])).safeTransferFrom(
                msg.sender,
                address(config[_bank_]),
                config[_feeVolume_]
            ); //tmp bank ,appeal 5PEX, arbitrate to vault or seller or buyer
            takes[takeID].status = Status.MerchantAppeal;
            //appealAddress[takeID] = msg.sender;
            appealInfos[takeID].takeID = takeID;
            appealInfos[takeID].appeal = msg.sender;
            appealInfos[takeID].arbiter = getRandArbiter(arbiters, isArbiter);
            appealInfos[takeID].isDeliver = true;

            emit Appeal(
                takeID,
                makeID,
                msg.sender,
                take.vol,
                appealInfos[takeID].arbiter
            );
        }
    }

    event Appeal(
        uint256 indexed takeID,
        uint256 indexed makeID,
        address indexed sender,
        uint256 vol,
        address arbiter
    );

    function merchantOk(
        mapping(uint256 => SMake) storage makes,
        mapping(uint256 => SMakeEx) storage makeExs,
        mapping(uint256 => STake) storage takes,
        mapping(bytes32 => uint256) storage config,
        uint256 takeID
    ) external virtual {
        uint256 makeID = takes[takeID].makeID;
        require(makes[makeID].maker == msg.sender, "must be maker");
        require(takes[takeID].status == Status.Done, "only Status.Done");
        uint256 tradingMargin = makeExs[makeID].tradingMargin;
        require(tradingMargin > 0, "only tradingMargin>0");
        require(now < takes[takeID].expiry, "now must < expiry");
        //takes[takeID].status = Status.MerchantOk;
        emit MerchantOk(takeID);
        takes[takeID].status = Status.ClaimTradingMargin;
        ITradingStakePool(config[_tradingPool_]).withdraw(
            takes[takeID].taker,
            tradingMargin
        );
        emit ClaimTradingMargin(takeID, tradingMargin);
    }

    event MerchantOk(uint256 takeID);

    struct DataTmp {
        //stack too deep
        uint256 realPrice;
        uint256 priceType;
        uint256 price;
        uint8 decimals;
        uint256 rate;
    }

    function takeLib(
        mapping(uint256 => SMake) storage makes,
        mapping(uint256 => SMakeEx) storage makeExs,
        mapping(uint256 => STake) storage takes,
        mapping(bytes32 => uint256) storage config,
        mapping(address => uint256) storage biddingN,
        TakePara memory takePara /*uint makeID, uint volume,string memory link,uint price,address recommender*/
    ) external virtual returns (uint256 takeID, uint256 vol) {
        DOTC dotc = DOTC(address(this));
        //uint makeID, uint volume,string memory link,uint price,address recommender;
        uint256 makeID = takePara.makeID;
        require(makes[makeID].maker != address(0), "Nonexistent make order");
        require(makes[makeID].remain > 0, "make.remain should > 0");
        require(
            makes[makeID].minVol <= takePara.volume,
            "volume must > minVol"
        );
        require(
            makes[makeID].maxVol >= takePara.volume,
            "volume must < maxVol"
        );
        //require((makes[makeID].maker != takePara.recommender)&&(msg.sender != takePara.recommender), 'recommender must not maker or taker');
        if (makeExs[makeID].tradingMargin > 0) {
            //config[_tradingPool_]
            IERC20(address(config[_feeToken_])).safeTransferFrom(
                msg.sender,
                address(this),
                makeExs[makeID].tradingMargin
            );
            if (
                IERC20(address(config[_feeToken_])).allowance(
                    address(this),
                    address(config[_tradingPool_])
                ) < makeExs[makeID].tradingMargin
            )
                IERC20(address(config[_feeToken_])).approve(
                    address(config[_tradingPool_]),
                    uint256(-1)
                );
            ITradingStakePool(address(config[_tradingPool_])).stake(
                msg.sender,
                makeExs[makeID].tradingMargin
            );
        } else if (
            takePara.volume >
            dotc.getConfigA(_assetFreeLimit_, makes[makeID].asset)
        )
            require(
                IStaking(dotc.staking()).enough(msg.sender),
                "GT Limit,must stake"
            );
        vol = takePara.volume;
        if (vol > makes[makeID].remain) vol = makes[makeID].remain;
        if (!makes[makeID].isBid) {
            //require(staking == address(0) || IStaking(staking).enough(msg.sender));
            biddingN[msg.sender]++;
        } else
            IERC20(makes[makeID].asset).safeTransferFrom(
                msg.sender,
                address(this),
                vol
            );

        makes[makeID].remain = makes[makeID].remain.sub(vol);
        makes[makeID].pending = makes[makeID].pending.add(vol);

        DataTmp memory dataTmp;
        dataTmp.priceType = makeExs[makeID].priceType;
        if (dataTmp.priceType != 0) {
            (dataTmp.price, dataTmp.decimals, dataTmp.rate) = IPriceAndRate(
                address(config[_priceAndRate_])
            ).getPriceAndRate(makes[makeID].asset, makes[makeID].currency);
            require(dataTmp.price > 0, "No the asset");
            require(dataTmp.rate > 0, "No the currency");
            if (dataTmp.priceType == 1) {
                if (makeExs[makeID].floatVal >= 0)
                    dataTmp.realPrice = dataTmp
                        .price
                        .mul(dataTmp.rate)
                        .div(uint128(10)**(dataTmp.decimals))
                        .add(uint256(makeExs[makeID].floatVal)); //1170e18 *6.71e18
                else
                    dataTmp.realPrice = dataTmp
                        .price
                        .mul(dataTmp.rate)
                        .div(uint128(10)**(dataTmp.decimals))
                        .sub(uint256(0 - makeExs[makeID].floatVal)); //1170e18 *6.71e18
            } else if (dataTmp.priceType == 2) {
                if (makeExs[makeID].floatVal >= 0)
                    dataTmp.realPrice = dataTmp
                        .price
                        .mul(dataTmp.rate)
                        .div(uint128(10)**(dataTmp.decimals))
                        .mul(
                            uint256(1e18).add(uint256(makeExs[makeID].floatVal))
                        )
                        .div(1e18); //
                else
                    dataTmp.realPrice = dataTmp
                        .price
                        .mul(dataTmp.rate)
                        .div(uint128(10)**(dataTmp.decimals))
                        .mul(
                            uint256(1e18).sub(
                                uint256(0 - makeExs[makeID].floatVal)
                            )
                        )
                        .div(1e18); //
            }
            uint256 diff = dataTmp.realPrice > takePara.price
                ? dataTmp.realPrice - takePara.price
                : takePara.price - dataTmp.realPrice;
            require(
                diff.mul(1000) < dataTmp.realPrice.mul(5),
                "price not match chainlink"
            );
            dataTmp.realPrice = takePara.price;
        } else {
            dataTmp.realPrice = makes[makeID].price;
        }
        takeID = dotc.takesN();
        takes[takeID] = STake(
            makeID,
            msg.sender,
            vol,
            Status.None,
            now.add(config[_expiry_]),
            takePara.link,
            dataTmp.realPrice,
            takePara.recommender
        );
        //takesN++;
        emit Take(
            takeID,
            makeID,
            msg.sender,
            vol,
            takes[takeID].expiry,
            takePara.link,
            dataTmp.realPrice,
            takePara.recommender
        );
    }

    event Take(
        uint256 indexed takeID,
        uint256 indexed makeID,
        address indexed taker,
        uint256 vol,
        uint256 expiry,
        string link,
        uint256 realPrice,
        address recommender
    );

    function claimTradingMargin(
        mapping(uint256 => SMake) storage makes,
        mapping(uint256 => SMakeEx) storage makeExs,
        mapping(uint256 => STake) storage takes,
        mapping(bytes32 => uint256) storage config,
        uint256 takeID
    ) external virtual {
        makes;
        require(takes[takeID].taker == msg.sender, "must be taker");
        uint256 tradingMargin = makeExs[takes[takeID].makeID].tradingMargin;
        require(
            takes[takeID].status == Status.MerchantOk ||
                ((takes[takeID].status == Status.Done) &&
                    (now > takes[takeID].expiry) &&
                    tradingMargin > 0),
            "No claimTradingMargin"
        );
        takes[takeID].status = Status.ClaimTradingMargin;
        ITradingStakePool(config[_tradingPool_]).withdraw(
            msg.sender,
            tradingMargin
        );
        emit ClaimTradingMargin(takeID, tradingMargin);
    }

    event ClaimTradingMargin(uint256 takeID, uint256 tradingMargin);

    function arbitrate(
        mapping(uint256 => SMake) storage makes,
        mapping(uint256 => SMakeEx) storage makeExs,
        mapping(uint256 => STake) storage takes,
        mapping(bytes32 => uint256) storage config,
        mapping(uint256 => AppealInfo) storage ais,
        mapping(address => uint256) storage biddingN,
        ArbiterPara memory ap /*uint takeID, Status winner,Status assetTo,Status appealFeeTo,Status punishSide,uint punishVol*/ /*nonReentrant*/
    ) external virtual returns (uint256 vol) {
        DOTC dotc = DOTC(address(this));
        uint256 takeID = ap.takeID;
        STake memory take = takes[takeID];
        uint256 makeID = take.makeID;
        SMake memory make = makes[makeID];
        require(take.taker != address(0), "Nonexistent take order");
        require(
            take.status == Status.Appeal ||
                take.status == Status.MerchantAppeal,
            "only Status.Appeal or Status.MerchantAppeal"
        );
        require(dotc.isArbiter(msg.sender), "only arbiter");
        require(ais[takeID].arbiter == msg.sender, "only the arbiter");
        require(ap.winner != ap.punishSide, "Can't punish winner");
        ais[takeID].winner = ap.winner;
        ais[takeID].appealFeeTo = ap.appealFeeTo;
        ais[takeID].punishSide = ap.punishSide;
        ais[takeID].punishVol = ap.punishVol;
        ais[takeID].punishTo = ap.punishTo;

        Tmpval memory tmpval; //deep stack
        {
            (tmpval.buyer, tmpval.seller) = make.isBid
                ? (make.maker, take.taker)
                : (take.taker, make.maker);
            tmpval.tradingMargin = makeExs[makeID].tradingMargin;
        }
        if (take.status == Status.Appeal) {
            vol = take.vol;
            if (ap.winner == Status.Buyer) {
                uint256 fee = dotc.payFee(takeID, make.asset, vol, makeID);
                IERC20(make.asset).safeTransfer(tmpval.buyer, vol.sub(fee));
                emit Deal(takeID, make.asset, vol);
            } else if (ap.winner == Status.Seller) {
                IERC20(make.asset).safeTransfer(tmpval.seller, vol);
                //if(dotc.staking().isContract())
                //    IStaking(dotc.staking()).punish(buyer);
            } else revert("status should be Buyer or Seller");

            //appeal fee 5PEX to:
            {
                //address appealFeeToAddr;
                if (ap.appealFeeTo == Status.Buyer)
                    IERC20(address(config[_feeToken_])).safeTransferFrom(
                        address(config[_bank_]),
                        tmpval.buyer,
                        config[_feeVolume_]
                    ); // bank ,appeal 5PEX, arbitrate to vault or seller or buyer
                else if (ap.appealFeeTo == Status.Seller)
                    IERC20(address(config[_feeToken_])).safeTransferFrom(
                        address(config[_bank_]),
                        tmpval.seller,
                        config[_feeVolume_]
                    ); // bank ,appeal 5PEX, arbitrate to vault or seller or buyer
                else if (ap.appealFeeTo == Status.Vault)
                    IERC20(address(config[_feeToken_])).safeTransferFrom(
                        address(config[_bank_]),
                        address(config[_vault_]),
                        config[_feeVolume_]
                    ); // bank ,appeal 5PEX, arbitrate to vault or seller or buyer
            }

            if (dotc.staking().isContract()) {
                //punish PEX
                if (ap.punishSide == Status.Buyer)
                    IStaking(dotc.staking()).punish(tmpval.buyer, ap.punishVol);
                else if (ap.punishSide == Status.Seller)
                    IStaking(dotc.staking()).punish(
                        tmpval.seller,
                        ap.punishVol
                    );
            }

            makes[makeID].pending = makes[makeID].pending.sub(vol);
            takes[takeID].status = ap.winner;

            if (
                (!makes[makeID].isBid) ||
                (makes[makeID].remain == 0 && makes[makeID].pending == 0)
            ) biddingN[tmpval.buyer] = biddingN[tmpval.buyer].sub(1);

            emit Arbitrate1(
                takeID,
                makeID,
                msg.sender,
                vol,
                ap.winner,
                ap /*ap.winner,ap.appealFeeTo,ap.punishSide,ap.punishVol*/
            );
        } else {
            if (!ais[takeID].isDeliver) {
                vol = take.vol;
                if (ap.winner == Status.Buyer) {
                    uint256 fee = dotc.payFee(takeID, make.asset, vol, makeID);
                    IERC20(make.asset).safeTransfer(tmpval.buyer, vol.sub(fee));
                    emit Deal(takeID, make.asset, vol);
                } else if (ap.winner == Status.Seller) {
                    IERC20(make.asset).safeTransfer(tmpval.seller, vol);
                    //if(dotc.staking().isContract())
                    //    IStaking(dotc.staking()).punish(buyer);
                } else revert("status should be Buyer or Seller");
            }

            //appeal fee 5PEX to:
            {
                //address appealFeeToAddr;
                if (ap.appealFeeTo == Status.Buyer)
                    IERC20(address(config[_feeToken_])).safeTransferFrom(
                        address(config[_bank_]),
                        tmpval.buyer,
                        config[_feeVolume_]
                    ); // bank ,appeal 5PEX, arbitrate to vault or seller or buyer
                else if (ap.appealFeeTo == Status.Seller)
                    IERC20(address(config[_feeToken_])).safeTransferFrom(
                        address(config[_bank_]),
                        tmpval.seller,
                        config[_feeVolume_]
                    ); // bank ,appeal 5PEX, arbitrate to vault or seller or buyer
                else if (ap.appealFeeTo == Status.Vault)
                    IERC20(address(config[_feeToken_])).safeTransferFrom(
                        address(config[_bank_]),
                        address(config[_vault_]),
                        config[_feeVolume_]
                    ); // bank ,appeal 5PEX, arbitrate to vault or seller or buyer
            }
            address punishTo;
            if (ap.punishTo == Status.Buyer) punishTo = tmpval.buyer;
            else if (ap.punishTo == Status.Seller) punishTo = tmpval.seller;
            else punishTo = address(config[_vault_]);

            if (ap.punishSide == Status.Buyer) {
                if (make.maker == tmpval.buyer)
                    IMerchantStakePool(config[_merchantPool_]).punish(
                        tmpval.buyer,
                        punishTo,
                        ap.punishVol
                    );
                else {
                    ITradingStakePool(config[_tradingPool_]).punish(
                        tmpval.buyer,
                        punishTo,
                        ap.punishVol
                    );
                    ITradingStakePool(config[_tradingPool_]).withdraw(
                        tmpval.buyer,
                        tmpval.tradingMargin.sub(ap.punishVol)
                    );
                }
            } else if (ap.punishSide == Status.Seller) {
                if (make.maker == tmpval.seller)
                    IMerchantStakePool(config[_merchantPool_]).punish(
                        tmpval.seller,
                        punishTo,
                        ap.punishVol
                    );
                else {
                    ITradingStakePool(config[_tradingPool_]).punish(
                        tmpval.seller,
                        punishTo,
                        ap.punishVol
                    );
                    ITradingStakePool(config[_tradingPool_]).withdraw(
                        tmpval.seller,
                        tmpval.tradingMargin.sub(ap.punishVol)
                    );
                }
            }
            takes[takeID].status = Status.MerchantAppealDone;
            emit Arbitrate1(
                takeID,
                makeID,
                msg.sender,
                vol,
                ap.winner,
                ap /*ap.winner,ap.appealFeeTo,ap.punishSide,ap.punishVol*/
            );
        }
    }

    event Arbitrate1(
        uint256 indexed takeID,
        uint256 indexed makeID,
        address indexed arbiter,
        uint256 vol,
        Status winner,
        ArbiterPara arbiterPara /* Status status,Status appealFeeTo,Status punishSide,uint punishVol*/
    );
    event Deal(uint256 indexed takeID, address indexed asset, uint256 vol);

    function _swapToPairTokenA(
        mapping(bytes32 => uint256) storage config,
        address asset,
        uint256 fee
    )
        internal
        returns (
            IUniswapV2Router01 router,
            address tokenA,
            uint256 amt
        )
    {
        router = IUniswapV2Router01(config[_swapRouter_]);
        tokenA = address(config[_pairTokenA_]);
        if (tokenA == asset) return (router, asset, fee);
        IERC20(asset).safeApprove_(address(router), fee);
        if (
            IUniswapV2Factory(config[_swapFactory_]).getPair(asset, tokenA) !=
            address(0)
        ) {
            address[] memory path = new address[](2);
            path[0] = asset;
            path[1] = tokenA;
            uint256[] memory amounts = router.swapExactTokensForTokens(
                fee,
                0,
                path,
                address(this),
                now
            );
            amt = amounts[1];
        } else {
            address[] memory path = new address[](3);
            path[0] = asset;
            path[1] = router.WETH();
            path[2] = tokenA;
            uint256[] memory amounts = router.swapExactTokensForTokens(
                fee,
                0,
                path,
                address(this),
                now
            );
            amt = amounts[2];
        }
    }

    function price(mapping(bytes32 => uint256) storage config)
        public
        view
        returns (uint256 p1, uint256 p2)
    {
        // DOTC dotc = DOTC(address(this));
        // (p1, p2) = dotc.priceEth();
        // address tokenA = address(config[_pairTokenA_]);
        // address usd = address(config[_usd_]);
        // address pair = IUniswapV2Factory(config[_swapFactory_]).getPair(
        //     tokenA,
        //     usd
        // );
        // uint256 volA = IERC20(tokenA).balanceOf(pair);
        // uint256 volU = IERC20(usd).balanceOf(pair);
        // p1 = p1.mul(volU).div(volA);
        // p2 = p2.mul(volU).div(volA);
    }

    function priceEth(mapping(bytes32 => uint256) storage config)
        public
        view
        returns (uint256 p1, uint256 p2)
    {
        // DOTC dotc = DOTC(address(this));
        // p1 = dotc.price1();
        // address tokenA = address(config[_pairTokenA_]);
        // address tokenR = address(config[_rewardToken_]);
        // address pair = IUniswapV2Factory(config[_swapFactory_]).getPair(
        //     tokenA,
        //     tokenR
        // );
        // if (pair == address(0) || IERC20(tokenA).balanceOf(pair) == 0) p2 = 0;
        // else
        //     p2 = IERC20(tokenA).balanceOf(pair).mul(1e18).div(
        //         IERC20(tokenR).balanceOf(pair)
        //     );
    }
}

interface IPriceAndRate {
    function getPriceAndRate(address token, bytes32 currency)
        external
        view
        returns (
            uint256 price,
            uint8 decimals,
            uint256 rate
        );
}

interface ISBT721 {
    function balanceOf(address owner) external view returns (uint256);
}

interface IStaking {
    function enough(address buyer) external view returns (bool);

    function punish(address buyer, uint256 vol) external;
}

interface IMerchantStakePool {
    function isMerchant(address account) external view returns (bool);

    function punish(
        address from,
        address to,
        uint256 vol
    ) external;
}

interface ITradingStakePool {
    function punish(
        address from,
        address to,
        uint256 vol
    ) external;

    function stake(address account, uint256 amount) external;

    function withdraw(address account, uint256 amount) external;
}

interface IVault {
    function rebase() external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router01 {
    //function factory() external pure returns (address);
    function WETH() external pure returns (address);

    //function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract PlaceHolder {
    
}


/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback () payable external {
    _fallback();
  }
  
  receive () virtual payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() virtual internal view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() virtual internal {
      
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    if(OpenZeppelinUpgradesAddress.isContract(msg.sender) && msg.data.length == 0 && gasleft() <= 2300)         // for receive ETH only from other contract
        return;
    _willFallback();
    _delegate(_implementation());
  }
}


/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
abstract contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() virtual override internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(newImplementation == address(0) || OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}


/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() virtual override internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    //super._willFallback();
  }
}

interface IAdminUpgradeabilityProxyView {
  function admin() external view returns (address);
  function implementation() external view returns (address);
}


/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
abstract contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) public payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
  
  //function _willFallback() virtual override internal {
    //super._willFallback();
  //}
}


/**
 * @title AdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with a constructor for 
 * initializing the implementation, admin, and init data.
 */
contract AdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, UpgradeabilityProxy {
  /**
   * Contract constructor.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, address _admin, bytes memory _data) UpgradeabilityProxy(_logic, _data) public payable {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
  
  function _willFallback() override(Proxy, BaseAdminUpgradeabilityProxy) internal {
    super._willFallback();
  }
}


/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract __BaseAdminUpgradeabilityProxy__ is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  //modifier ifAdmin() {
  //  if (msg.sender == _admin()) {
  //    _;
  //  } else {
  //    _fallback();
  //  }
  //}
  modifier ifAdmin() {
    require (msg.sender == _admin(), 'only admin');
      _;
  }

  /**
   * @return The address of the proxy admin.
   */
  //function admin() external ifAdmin returns (address) {
  //  return _admin();
  //}
  function __admin__() external view returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  //function implementation() external ifAdmin returns (address) {
  //  return _implementation();
  //}
  function __implementation__() external view returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  //function changeAdmin(address newAdmin) external ifAdmin {
  //  require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
  //  emit AdminChanged(_admin(), newAdmin);
  //  _setAdmin(newAdmin);
  //}
  function __changeAdmin__(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  //function upgradeTo(address newImplementation) external ifAdmin {
  //  _upgradeTo(newImplementation);
  //}
  function __upgradeTo__(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  //function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
  //  _upgradeTo(newImplementation);
  //  (bool success,) = newImplementation.delegatecall(data);
  //  require(success);
  //}
  function __upgradeToAndCall__(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  //function _willFallback() virtual override internal {
  //  require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
  //  //super._willFallback();
  //}
}


/**
 * @title AdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with a constructor for 
 * initializing the implementation, admin, and init data.
 */
contract __AdminUpgradeabilityProxy__ is __BaseAdminUpgradeabilityProxy__, UpgradeabilityProxy {
  /**
   * Contract constructor.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, address _admin, bytes memory _data) UpgradeabilityProxy(_logic, _data) public payable {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
  
  //function _willFallback() override(Proxy, BaseAdminUpgradeabilityProxy) internal {
  //  super._willFallback();
  //}
}  

contract __AdminUpgradeabilityProxy0__ is __BaseAdminUpgradeabilityProxy__, UpgradeabilityProxy {
  constructor() UpgradeabilityProxy(address(0), "") public {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(msg.sender);
  }
}


/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
abstract contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }  
}


/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for 
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, InitializableUpgradeabilityProxy {
  /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, address _admin, bytes memory _data) public payable {
    require(_implementation() == address(0));
    InitializableUpgradeabilityProxy.initialize(_logic, _data);
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
  
  function _willFallback() override(Proxy, BaseAdminUpgradeabilityProxy) internal {
    super._willFallback();
  }

}


interface IProxyFactory {
    function governor() external view returns (address);
    function __admin__() external view returns (address);
    function productImplementation() external view returns (address);
    function productImplementations(bytes32 name) external view returns (address);
}


/**
 * @title ProductProxy
 * @dev This contract implements a proxy that 
 * it is deploied by ProxyFactory, 
 * and it's implementation is stored in factory.
 */
contract ProductProxy is Proxy {
    
  /**
   * @dev Storage slot with the address of the ProxyFactory.
   * This is the keccak-256 hash of "eip1967.proxy.factory" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant FACTORY_SLOT = 0x7a45a402e4cb6e08ebc196f20f66d5d30e67285a2a8aa80503fa409e727a4af1;
  bytes32 internal constant NAME_SLOT    = 0x4cd9b827ca535ceb0880425d70eff88561ecdf04dc32fcf7ff3b15c587f8a870;      // bytes32(uint256(keccak256('eip1967.proxy.name')) - 1)

  function _name() virtual internal view returns (bytes32 name_) {
    bytes32 slot = NAME_SLOT;
    assembly {  name_ := sload(slot)  }
  }
  
  function _setName(bytes32 name_) internal {
    bytes32 slot = NAME_SLOT;
    assembly {  sstore(slot, name_)  }
  }

  /**
   * @dev Sets the factory address of the ProductProxy.
   * @param newFactory Address of the new factory.
   */
  function _setFactory(address newFactory) internal {
    require(newFactory == address(0) || OpenZeppelinUpgradesAddress.isContract(newFactory), "Cannot set a factory to a non-contract address");

    bytes32 slot = FACTORY_SLOT;

    assembly {
      sstore(slot, newFactory)
    }
  }

  /**
   * @dev Returns the factory.
   * @return factory_ Address of the factory.
   */
  function _factory() internal view returns (address factory_) {
    bytes32 slot = FACTORY_SLOT;
    assembly {
      factory_ := sload(slot)
    }
  }
  
  /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
  function _implementation() virtual override internal view returns (address) {
    address factory_ = _factory();
    bytes32 name_ = _name();
    if(OpenZeppelinUpgradesAddress.isContract(factory_))
        if(name_ != 0x0)
            return IProxyFactory(factory_).productImplementations(name_);
        else
            return IProxyFactory(factory_).productImplementation();
    else
        return address(0);
  }

}


/**
 * @title InitializableProductProxy
 * @dev Extends ProductProxy with an initializer for initializing
 * factory and init data.
 */
contract InitializableProductProxy is ProductProxy {
  /**
   * @dev Contract initializer.
   * @param factory Address of the initial factory.
   * @param data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function __InitializableProductProxy_init(address factory, bytes32 name, bytes memory data) external payable {
    address factory_ = _factory();
    require(factory_ == address(0) || msg.sender == factory_ || msg.sender == IProxyFactory(factory_).governor() || msg.sender == IProxyFactory(factory_).__admin__());
    assert(FACTORY_SLOT == bytes32(uint256(keccak256('eip1967.proxy.factory')) - 1));
    assert(NAME_SLOT    == bytes32(uint256(keccak256('eip1967.proxy.name')) - 1));
    _setFactory(factory);
    _setName(name);
    if(data.length > 0) {
      (bool success,) = _implementation().delegatecall(data);
      require(success);
    }
  }  
}


contract __InitializableAdminUpgradeabilityProductProxy__ is __BaseAdminUpgradeabilityProxy__, ProductProxy {
  function __InitializableAdminUpgradeabilityProductProxy_init__(address logic, address admin, address factory, bytes32 name, bytes memory data) public payable {
    assert(IMPLEMENTATION_SLOT  == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    assert(ADMIN_SLOT           == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    assert(FACTORY_SLOT         == bytes32(uint256(keccak256('eip1967.proxy.factory')) - 1));
    assert(NAME_SLOT            == bytes32(uint256(keccak256('eip1967.proxy.name')) - 1));
    address admin_ = _admin();
    require(admin_ == address(0) || msg.sender == admin_);
    _setAdmin(admin);
    _setImplementation(logic);
    _setFactory(factory);
    _setName(name);
    if(data.length > 0) {
      (bool success,) = _implementation().delegatecall(data);
      require(success);
    }
  }
  
  function _implementation() virtual override(BaseUpgradeabilityProxy, ProductProxy) internal view returns (address impl) {
    impl = ProductProxy._implementation();
    if(impl == address(0))
        impl = BaseUpgradeabilityProxy._implementation();
  }
}

contract __AdminUpgradeabilityProductProxy__ is __InitializableAdminUpgradeabilityProductProxy__ {
  constructor(address logic, address admin, address factory, bytes32 name, bytes memory data) public payable {
    __InitializableAdminUpgradeabilityProductProxy_init__(logic, admin, factory, name, data);
  }
}

contract __AdminUpgradeabilityProductProxy0__ is __InitializableAdminUpgradeabilityProductProxy__ {
  constructor() public {
    __InitializableAdminUpgradeabilityProductProxy_init__(address(0), msg.sender, address(0), 0, "");
  }
}


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

    }


    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function sub0(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function div0(uint256 a, uint256 b) internal pure returns (uint256) {
        return b == 0 ? 0 : a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20UpgradeSafe is ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    uint256 internal _cap;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function __ERC20Capped_init(string memory name, string memory symbol, uint256 cap) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
		__ERC20Capped_init_unchained(cap);
    }

    function __ERC20Capped_init_unchained(uint256 cap) internal initializer {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() virtual public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        if(sender != _msgSender() && _allowances[sender][_msgSender()] != uint(-1))
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        if (_cap > 0) { // When Capped
            require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        }
		
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[43] private __gap;
}


abstract contract Permit {		// ERC2612
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    function DOMAIN_SEPARATOR() virtual public view returns (bytes32);

    mapping (address => uint) public nonces;

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'permit EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'permit INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual;    

    uint256[49] private __gap;
}

contract ERC20Permit is ERC20UpgradeSafe, Permit {
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    
    function DOMAIN_SEPARATOR() virtual override public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), keccak256(bytes("1")), _chainId(), address(this)));
    }
    
    function _chainId() internal pure returns (uint id) {
        assembly { id := chainid() }
    }
    
    function _approve(address owner, address spender, uint256 amount) virtual override(Permit, ERC20UpgradeSafe) internal {
        return ERC20UpgradeSafe._approve(owner, spender, amount);
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeApprove_(IERC20 token, address spender, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract Governable is Initializable {
    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function __Governable_init_unchained(address governor_) virtual public initializer {
        governor = governor_;
        emit GovernorshipTransferred(address(0), governor);
    }

    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }
    
    modifier governance() {
        require(msg.sender == governor || msg.sender == _admin());
        _;
    }

    /**
     * @dev Allows the current governor to relinquish control of the contract.
     * @notice Renouncing to governorship will leave the contract without an governor.
     * It will not be possible to call the functions with the `governance`
     * modifier anymore.
     */
    function renounceGovernorship() public governance {
        emit GovernorshipTransferred(governor, address(0));
        governor = address(0);
    }

    /**
     * @dev Allows the current governor to transfer control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function transferGovernorship(address newGovernor) public governance {
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function _transferGovernorship(address newGovernor) internal {
        require(newGovernor != address(0));
        emit GovernorshipTransferred(governor, newGovernor);
        governor = newGovernor;
    }
}


contract Configurable is Governable {
    mapping (bytes32 => uint) internal config;
    
    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfigI(bytes32 key, uint index) public view returns (uint) {
        return config[bytes32(uint(key) ^ index)];
    }
    function getConfigA(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function _setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }

    function setConfig(bytes32 key, uint value) external governance {
        _setConfig(key, value);
    }
    function setConfigI(bytes32 key, uint index, uint value) external governance {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function setConfigA(bytes32 key, address addr, uint value) public governance {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}
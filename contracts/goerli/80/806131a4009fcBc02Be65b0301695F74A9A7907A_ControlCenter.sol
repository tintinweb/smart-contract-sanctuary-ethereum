// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ICrossFarm {
    function updatePoolDepositFee(uint256 _pid, uint256 _newFee) external;

    function updateEarlyWithdrawTax(uint256 _newFee) external;

    function depositFeeExclusionStatus(address _address, uint256 _value)
        external;

    function updateControlCenter(address _newAddress) external;

    function changeRouter(address _token, address _router) external;

    function updateContractAddress(uint256 _id, address _address) external;

    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint256 _depositFee,
        uint256 _swapTreshold,
        uint256 _lockTime,
        uint256 _endBlock,
        address _router,
        bool _withUpdate
    ) external;

    // Update the given pool's ERC20 allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _depositFee,
        uint256 _lockTime,
        uint256 _swapTreshold,
        uint256 _endBlock,
        bool _withUpdate
    ) external;

    function setRewardPerBlock(uint256 _amount, bool _withUpdate) external;

    function getAdditionalPoolInfo(uint256 _pid)
        external
        view
        returns (
            uint256 depositFee,
            uint256 lockTime,
            uint256 fundedUntil,
            uint256 allocationPoints,
            uint256 totalAllocationPoints,
            address lpTokenAddress
        );

    function userPoolFarmInfo(address _user, uint256 _pid)
        external
        view
        returns (
            uint256 stakedLp,
            uint256 claimableRewards,
            uint256 timeUntilWithdrawUnlocked,
            bool compounding
        );
}

interface ICrossFactory {
    function killswitch() external;

    function changePairListingStatus(address _address, bool _value) external;

    function changeDexFeeStatus(
        address _address,
        address _pairAddress,
        uint256 _amount
    ) external;

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface ICrossPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /*************/
    function CRSSPricecheckStatus(
        bool _isActive0,
        bool _isActive1,
        bool _isActiveL
    ) external;

    /*************/
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface ICrssReferral {
    /**
     * @dev Record referral.
     *
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission)
        external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);

    function getOutstandingCommission(address _referrer)
        external
        view
        returns (uint256 amount);

    function debitOutstandingCommission(address _referrer, uint256 _debit)
        external;

    function updateOperator(address _newPayer) external;
}

interface IsCRSS {
    function rescueToken(address _token, uint256 _amount) external;

    function rescueETH(uint256 _amount) external;

    function impactFeeStatus(bool _value) external;

    function setImpactFeeReceiver(address _feeReceiver) external;

    function killswitch() external;
}

interface ICRSS {
    /* */

    function changeAccountantAddress(address _address) external;

    function changeControlCenter(address _address) external;

    function changeTransferFeeExclusionStatus(address target, bool value)
        external;

    function setBotWhitelist(address _target, bool _value) external;

    function changeBotCooldown(uint256 _value) external;

    function bulkTransferExclusionStatusChange(
        address[] memory targets,
        bool value
    ) external;

    function killswitch() external;

    function controlledMint(uint256 _amount) external;

    function cotrolledMintTo(address _to, uint256 _amount) external;

    function addEmissionReceiver(
        address _address,
        uint256 _crssPerBlock,
        bool _hasInterface,
        bool _withUpdate
    ) external;

    function setEmissionReceiver(
        uint256 _index,
        uint256 _crssPerBlock,
        bool _hasInterface,
        bool _withUpdate
    ) external;
    /* */
}

interface IControlCenter {
    function _getCLPoolValue(
        address token0,
        address token1,
        uint256 balance0,
        uint256 balance1
    ) external view returns (uint256 poolValue0, uint256 deviation0);

    function _getStateVariables()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function _updateSession() external;

    function getAddress(uint256 _pid) external view returns (address);
}

contract ControlCenter is Ownable, IControlCenter {
    struct CLFeed {
        uint64 deviation;
        uint64 decimal;
        address proxy;
    }

    constructor() Ownable() {
        //address[] memory _protocolAddresses
        // protocolAddresses = _protocolAddresses;
        // _initializeBnbMainNetCLFeeds();
        _initializeBnbTestNetCLFeeds();
        _initializeGoerliTestNetCLFeeds();
        // 5%
    }

    address[] public protocolAddresses; // 0 CRSS, 1 sCRSS, 2 CRSS Router, 3 CRSS Factory, 4 CRSS Accountant,
    // 5 sCRSS Dividend contract, 6 CRSS LP Farm, 7 CRSS Referral contract, 8 CRSS Vesting Contract
    address public accountantContract;
    address public crssToken;
    address public sCrssToken;
    address public factory;
    uint256 public sessionInterval;
    uint256 public maxSessionPriceChange;
    uint256 public maxSessionLPValueChange;
    uint256 public currentSessionTimestamp;
    struct VerifiedToken {
        uint128 startTime;
        uint128 duration;
        uint8 tier;
    }
    mapping(address => VerifiedToken) public VerifiedInstances;
    mapping(address => CLFeed) public chainlinkFeeds;

    function updateTokenListing(
        address _token,
        uint8 _tier,
        uint128 _duration
    ) public onlyOwner {
        VerifiedToken memory newStruct = VerifiedToken({
            startTime: uint128(block.timestamp),
            duration: _duration,
            tier: _tier
        });
        VerifiedInstances[_token] = newStruct;
    }

    function isTokenListed(address _token) public view returns (bool listed) {
        VerifiedToken memory tokenInstance = VerifiedInstances[_token];
        if (tokenInstance.duration == 0) {
            return true;
        }
        listed =
            tokenInstance.startTime + tokenInstance.duration > block.timestamp;

        return listed;
    }

    function _updateSession() external override {
        uint256 currentTimestamp = block.timestamp;
        if (currentSessionTimestamp + sessionInterval <= currentTimestamp) {
            currentSessionTimestamp = currentTimestamp;
        }
    }

    //these two functionalities are currently restricted to the owner of Control Centre, but in the future these functions and many more will ideally be govnerned by a DAO voting mechanism
    function updatePairPriceCheckStatus(
        address _pair,
        bool _isActive0, //crss price check
        bool _isActive1, //CL price check
        bool _isActiveL //liquidity guard
    ) external onlyOwner {
        ICrossPair(_pair).CRSSPricecheckStatus(
            _isActive0,
            _isActive1,
            _isActiveL
        );
    }

    function emergencyKillswitch() public onlyOwner {
        IsCRSS(sCrssToken).killswitch();
        ICRSS(crssToken).killswitch();
    }

    function updatePriceCheckParameters(
        uint256 _sessionInterval,
        uint256 _maxSessionLPValueChange,
        uint256 _maxSessionPriceChange
    ) external onlyOwner {
        //we need to decide on the business logic behind this, ideally 1h session 5-10% max price change
        //or we have one price check guard against bots with a 1% max price change per minute and another with 1h 5-10% max change
        sessionInterval = _sessionInterval;
        maxSessionPriceChange = _maxSessionLPValueChange;
        maxSessionLPValueChange = _maxSessionPriceChange;
    }

    function getAddress(uint256 _pid) external view override returns (address) {
        return protocolAddresses[_pid];
    }

    function _getStateVariables()
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            maxSessionPriceChange,
            maxSessionLPValueChange,
            currentSessionTimestamp
        );
    }

    function adjustToEighteenDecimals(uint64 _currentDecimals, uint256 _num)
        private
        pure
        returns (uint256)
    {
        uint64 decimalDifference = 18 - _currentDecimals;
        if (decimalDifference > 0) {
            _num *= 10**decimalDifference;
        }
        return _num;
    }

    function _getCLPoolValue(
        address token0,
        address token1,
        uint256 balance0,
        uint256 balance1
    ) external view override returns (uint256 poolValue0, uint256 deviation0) {
        if (chainlinkFeeds[token0].proxy != address(0)) {
            CLFeed memory priceFeed0 = chainlinkFeeds[token0];
            //without additional checks this brakes any swap involving tokens without chainlink price oracle
            (
                ,
                /*uint80 roundID*/
                int256 price0, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
                ,
                ,

            ) = AggregatorV3Interface(priceFeed0.proxy).latestRoundData();
            //all prices will have 18 decimals

            uint256 adjustedPrice0 = adjustToEighteenDecimals(
                priceFeed0.decimal,
                uint256(price0)
            );
            poolValue0 = (balance0 * adjustedPrice0);
            //devation is divided by 10 000, most common deviation is 50 (0.5%)
            deviation0 = priceFeed0.deviation;
        } else if (chainlinkFeeds[token1].proxy != address(0)) {
            CLFeed memory priceFeed1 = chainlinkFeeds[token1];
            (
                ,
                /*uint80 roundID*/
                int256 price1, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
                ,
                ,

            ) = AggregatorV3Interface(priceFeed1.proxy).latestRoundData();
            uint256 adjustedPrice0 = adjustToEighteenDecimals(
                priceFeed1.decimal,
                uint256(price1)
            );
            poolValue0 = balance1 * adjustedPrice0;
            deviation0 = priceFeed1.deviation;
        } else {
            poolValue0 = 0;
            deviation0 = 0;
        }

        //adjustedPrice0 += adjustedPrice0 * d0/10000;
        // adjustedPrice1 += adjustedPrice1 * d1/10000;
        return (poolValue0, deviation0);
    }

    function getTokenPrice(address _tokenAddress)
        public
        view
        returns (uint256)
    {
        CLFeed memory priceFeed1 = chainlinkFeeds[_tokenAddress];
        (
            ,
            /*uint80 roundID*/
            int256 price1, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = AggregatorV3Interface(priceFeed1.proxy).latestRoundData();
        uint256 adjustedPrice0 = adjustToEighteenDecimals(
            priceFeed1.decimal,
            uint256(price1)
        );
        return adjustedPrice0;
    }

    //CRSS token admin functions
    function changeAccountantAddress(address _address) external onlyOwner {
        ICRSS(crssToken).changeAccountantAddress(_address);
    }

    function changeControlCenter(address _address) external onlyOwner {
        ICRSS(crssToken).changeControlCenter(_address);
    }

    function changeTransferFeeExclusionStatus(address _target, bool _value)
        external
        onlyOwner
    {
        ICRSS(crssToken).changeTransferFeeExclusionStatus(_target, _value);
    }

    function setBotWhitelist(address _target, bool _value) external onlyOwner {
        ICRSS(crssToken).setBotWhitelist(_target, _value);
    }

    function changeBotCooldown(uint256 _value) external onlyOwner {
        ICRSS(crssToken).changeBotCooldown(_value);
    }

    function bulkTransferExclusionStatusChange(
        address[] memory targets,
        bool value
    ) external onlyOwner {
        ICRSS(crssToken).bulkTransferExclusionStatusChange(targets, value);
    }

    function CRSSKillswitch() external onlyOwner {
        ICRSS(crssToken).killswitch();
    }

    function addEmissionReceiver(
        address _address,
        uint256 _crssPerBlock,
        bool _hasInterface,
        bool _withUpdate
    ) external onlyOwner {
        ICRSS(crssToken).addEmissionReceiver(
            _address,
            _crssPerBlock,
            _hasInterface,
            _withUpdate
        );
    }

    function setEmissionReceiver(
        uint256 _index,
        uint256 _crssPerBlock,
        bool _hasInterface,
        bool _withUpdate
    ) external onlyOwner {
        ICRSS(crssToken).setEmissionReceiver(
            _index,
            _crssPerBlock,
            _hasInterface,
            _withUpdate
        );
    }

    //sCRSS token admin functions
    function rescueToken(address _token, uint256 _amount) external onlyOwner {
        IsCRSS(sCrssToken).rescueToken(_token, _amount);
    }

    function rescueETH(uint256 _amount) external onlyOwner {
        IsCRSS(sCrssToken).rescueETH(_amount);
    }

    function impactFeeStatus(bool _value) external onlyOwner {
        IsCRSS(sCrssToken).impactFeeStatus(_value);
    }

    function setImpactFeeReceiver(address _feeReceiver) external onlyOwner {
        IsCRSS(sCrssToken).setImpactFeeReceiver(_feeReceiver);
    }

    function sCRSSKillswitch() external onlyOwner {
        IsCRSS(sCrssToken).killswitch();
    }

    //Factory
    function DEXKillswitch() external onlyOwner {
        ICrossFactory(factory).killswitch();
    }

    function changePairListingStatus(address _address, bool _value)
        external
        onlyOwner
    {
        ICrossFactory(factory).changePairListingStatus(_address, _value);
    }

    function changeDexFeeStatus(
        address _address,
        address _pairAddress,
        uint256 _amount
    ) external onlyOwner {
        ICrossFactory(factory).changeDexFeeStatus(
            _address,
            _pairAddress,
            _amount
        );
    }

    function createPair(address tokenA, address tokenB) external onlyOwner {
        ICrossFactory(factory).createPair(tokenA, tokenB);
    }

    function setFeeTo(address _address) external onlyOwner {
        ICrossFactory(factory).setFeeTo(_address);
    }

    function setFeeToSetter(address _address) external onlyOwner {
        ICrossFactory(factory).setFeeToSetter(_address);
    }

    //REFERAL STUFF
    address public referalContract;

    function updateReferalOperator(address _newOperator) external onlyOwner {
        ICrssReferral(referalContract).updateOperator(_newOperator);
    }

    function updateReferalContract(address _newReferalContract)
        external
        onlyOwner
    {
        referalContract = _newReferalContract;
    }

    //CL price feeds
    function _initializeBnbMainNetCLFeeds() internal {
        // AAVE / USD
        chainlinkFeeds[0xfb6115445Bff7b52FeB98650C87f44907E58f802] = CLFeed(
            20,
            8,
            0xA8357BF572460fC40f4B0aCacbB2a6A61c89f475
        );
        // ADA / USD
        chainlinkFeeds[0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47] = CLFeed(
            20,
            8,
            0xa767f745331D267c7751297D982b050c93985627
        );
        // ALPACA / USD
        chainlinkFeeds[0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F] = CLFeed(
            50,
            8,
            0xe0073b60833249ffd1bb2af809112c2fbf221DF6
        );

        // ARPA / USD
        chainlinkFeeds[0x6F769E65c14Ebd1f68817F5f1DcDb61Cfa2D6f7e] = CLFeed(
            50,
            8,
            0x31E0110f8c1376a699C8e3E65b5110e0525A811d
        );
        // ATOM / USD
        chainlinkFeeds[0x0Eb3a705fc54725037CC9e008bDede697f62F335] = CLFeed(
            50,
            8,
            0xb056B7C804297279A9a673289264c17E6Dc6055d
        );

        // AUTO / USD
        chainlinkFeeds[0xa184088a740c695E156F91f5cC086a06bb78b827] = CLFeed(
            50,
            8,
            0x88E71E6520E5aC75f5338F5F0c9DeD9d4f692cDA
        );
        // AVAX / USD
        chainlinkFeeds[0x1CE0c2827e2eF14D5C4f29a091d735A204794041] = CLFeed(
            50,
            8,
            0x5974855ce31EE8E1fff2e76591CbF83D7110F151
        );
        // AXS / USD
        chainlinkFeeds[0x715D400F88C167884bbCc41C5FeA407ed4D2f8A0] = CLFeed(
            50,
            8,
            0x7B49524ee5740c99435f52d731dFC94082fE61Ab
        );

        // BAND / USD
        chainlinkFeeds[0xAD6cAEb32CD2c308980a548bD0Bc5AA4306c6c18] = CLFeed(
            50,
            8,
            0xC78b99Ae87fF43535b0C782128DB3cB49c74A4d3
        );
        // BCH / USD
        chainlinkFeeds[0x8fF795a6F4D97E7887C79beA79aba5cc76444aDf] = CLFeed(
            30,
            8,
            0x43d80f616DAf0b0B42a928EeD32147dC59027D41
        );
        // BETH / USD
        chainlinkFeeds[0x250632378E573c6Be1AC2f97Fcdf00515d0Aa91B] = CLFeed(
            30,
            8,
            0x2A3796273d47c4eD363b361D3AEFb7F7E2A13782
        );

        // BIFI / USD
        chainlinkFeeds[0xCa3F508B8e4Dd382eE878A314789373D80A5190A] = CLFeed(
            50,
            8,
            0xaB827b69daCd586A37E80A7d552a4395d576e645
        );
        // BNB / USD
        chainlinkFeeds[0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c] = CLFeed(
            100,
            8,
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );
        // BRK.B / USD
        chainlinkFeeds[0xd045D776d894eC6e8b685DBEf196527ea8720BaB] = CLFeed(
            50,
            8,
            0x5289A08b6d5D2f8fAd4cC169c65177f68C0f0A99
        );
        // BRL / USD
        chainlinkFeeds[0x12c87331f086c3C926248f964f8702C0842Fd77F] = CLFeed(
            30,
            8,
            0x5cb1Cb3eA5FB46de1CE1D0F3BaDB3212e8d8eF48
        );
        // BTC / USD
        chainlinkFeeds[0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c] = CLFeed(
            10,
            8,
            0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf
        );
        // BUSD / USD
        chainlinkFeeds[0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56] = CLFeed(
            50,
            8,
            0xcBb98864Ef56E9042e7d2efef76141f15731B82f
        );
        // C98 / USD
        chainlinkFeeds[0xaEC945e04baF28b135Fa7c640f624f8D90F1C3a6] = CLFeed(
            50,
            8,
            0x889158E39628C0397DC54B84F6b1cbe0AaEb7FFc
        );
        // CAKE / USD
        chainlinkFeeds[0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82] = CLFeed(
            20,
            8,
            0xB6064eD41d4f67e353768aA239cA86f4F73665a1
        );

        // CHR / USD
        chainlinkFeeds[0xf9CeC8d50f6c8ad3Fb6dcCEC577e05aA32B224FE] = CLFeed(
            50,
            8,
            0x1f771B2b1F3c3Db6C7A1d5F38961a49CEcD116dA
        );

        // COMP / USD
        chainlinkFeeds[0x52CE071Bd9b1C4B00A0b92D298c512478CaD67e8] = CLFeed(
            50,
            8,
            0x0Db8945f9aEf5651fa5bd52314C5aAe78DfDe540
        );
        // CREAM / USD
        chainlinkFeeds[0xd4CB328A82bDf5f03eB737f37Fa6B370aef3e888] = CLFeed(
            50,
            8,
            0xa12Fc27A873cf114e6D8bBAf8BD9b8AC56110b39
        );

        // DAI / USD
        chainlinkFeeds[0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3] = CLFeed(
            10,
            8,
            0x132d3C0B1D2cEa0BC552588063bdBb210FDeecfA
        );
        // DEGO / USD
        chainlinkFeeds[0x3FdA9383A84C05eC8f7630Fe10AdF1fAC13241CC] = CLFeed(
            50,
            8,
            0x39F1275366D130eB677D4F47D40F9296B62D877A
        );
        // DF / USD
        chainlinkFeeds[0x4A9A2b2b04549C3927dd2c9668A5eF3fCA473623] = CLFeed(
            50,
            8,
            0x1b816F5E122eFa230300126F97C018716c4e47F5
        );
        // DODO / USD
        chainlinkFeeds[0x67ee3Cb086F8a16f34beE3ca72FAD36F7Db929e2] = CLFeed(
            50,
            8,
            0x87701B15C08687341c2a847ca44eCfBc8d7873E1
        );
        // DOGE / USD
        chainlinkFeeds[0xbA2aE424d960c26247Dd6c32edC70B295c744C43] = CLFeed(
            20,
            8,
            0x3AB0A0d137D4F946fBB19eecc6e92E64660231C8
        );
        // DOT / USD
        chainlinkFeeds[0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402] = CLFeed(
            20,
            8,
            0xC333eb0086309a16aa7c8308DfD32c8BBA0a2592
        );

        // EOS / USD
        chainlinkFeeds[0x56b6fB708fC5732DEC1Afc8D8556423A2EDcCbD6] = CLFeed(
            50,
            8,
            0xd5508c8Ffdb8F15cE336e629fD4ca9AdB48f50F0
        );
        // ETH / USD
        chainlinkFeeds[0x2170Ed0880ac9A755fd29B2688956BD959F933F8] = CLFeed(
            10,
            8,
            0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e
        );

        // FET / USD
        chainlinkFeeds[0x031b41e504677879370e9DBcF937283A8691Fa7f] = CLFeed(
            50,
            8,
            0x657e700c66C48c135c4A29c4292908DbdA7aa280
        );
        // FIL / USD
        chainlinkFeeds[0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153] = CLFeed(
            30,
            8,
            0xE5dbFD9003bFf9dF5feB2f4F445Ca00fb121fb83
        );
        // FRAX / USD
        chainlinkFeeds[0x90C97F71E18723b0Cf0dfa30ee176Ab653E89F40] = CLFeed(
            30,
            8,
            0x13A9c98b07F098c5319f4FF786eB16E22DC738e1
        );
        // FTM / USD
        chainlinkFeeds[0xa4b6E76bba7413B9B4bD83f4e3AA63cc181D869F] = CLFeed(
            50,
            8,
            0xe2A47e87C0f4134c8D06A41975F6860468b2F925
        );

        // GME / USD
        chainlinkFeeds[0x84e9a6F9D240FdD33801f7135908BfA16866939A] = CLFeed(
            50,
            8,
            0x66cD2975d02f5F5cdEF2E05cBca12549B1a5022D
        );

        // INJ / USD
        chainlinkFeeds[0xa2B726B1145A4773F68593CF171187d8EBe4d495] = CLFeed(
            50,
            8,
            0x63A9133cd7c611d6049761038C16f238FddA71d7
        );

        // LINA / USD
        chainlinkFeeds[0x762539b45A1dCcE3D36d080F74d1AED37844b878] = CLFeed(
            20,
            8,
            0x38393201952f2764E04B290af9df427217D56B41
        );
        // LINK / USD
        chainlinkFeeds[0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD] = CLFeed(
            20,
            8,
            0xca236E327F629f9Fc2c30A4E95775EbF0B89fac8
        );

        // LTC / USD
        chainlinkFeeds[0x4338665CBB7B2485A8855A139b75D5e34AB0DB94] = CLFeed(
            30,
            8,
            0x74E72F37A8c415c8f1a98Ed42E78Ff997435791D
        );

        // MASK / USD
        chainlinkFeeds[0x2eD9a5C8C13b93955103B9a7C167B67Ef4d568a3] = CLFeed(
            50,
            8,
            0x4978c0abE6899178c1A74838Ee0062280888E2Cf
        );

        // MIM / USD
        chainlinkFeeds[0xfE19F0B51438fd612f6FD59C1dbB3eA319f433Ba] = CLFeed(
            50,
            8,
            0xc9D267542B23B41fB93397a93e5a1D7B80Ea5A01
        );
        // MIR / USD
        chainlinkFeeds[0x5B6DcF557E2aBE2323c48445E8CC948910d8c2c9] = CLFeed(
            50,
            8,
            0x291B2983b995870779C36A102Da101f8765244D6
        );

        // MS / USD
        chainlinkFeeds[0x16a7fa783378Da47A4F09613296b0B2Dd2B08d06] = CLFeed(
            50,
            8,
            0x6b25F7f189c3f26d3caC43b754578b67Fc8d952A
        );

        // NULS / USD
        chainlinkFeeds[0x8CD6e29d3686d24d3C2018CEe54621eA0f89313B] = CLFeed(
            50,
            8,
            0xaCFBE73231d312AC6954496b3f786E892bF0f7e5
        );

        // ONT / USD
        chainlinkFeeds[0xFd7B3A77848f1C2D67E05E54d78d174a0C850335] = CLFeed(
            50,
            8,
            0x887f177CBED2cf555a64e7bF125E1825EB69dB82
        );

        // RAMP / USD
        chainlinkFeeds[0x8519EA49c997f50cefFa444d240fB655e89248Aa] = CLFeed(
            50,
            8,
            0xD1225da5FC21d17CaE526ee4b6464787c6A71b4C
        );

        // SHIB / USD
        chainlinkFeeds[0xb1547683DA678f2e1F003A780143EC10Af8a832B] = CLFeed(
            50,
            8,
            0xA615Be6cb0f3F36A641858dB6F30B9242d0ABeD8
        );

        // SPY / USD
        chainlinkFeeds[0x17fd3cAa66502C6F1CbD5600D8448f3aF8f2ABA1] = CLFeed(
            50,
            8,
            0xb24D1DeE5F9a3f761D286B56d2bC44CE1D02DF7e
        );
        // SUSHI / USD
        chainlinkFeeds[0x947950BcC74888a40Ffa2593C5798F11Fc9124C4] = CLFeed(
            50,
            8,
            0xa679C72a97B654CFfF58aB704de3BA15Cde89B07
        );
        // SXP / USD
        chainlinkFeeds[0x47BEAd2563dCBf3bF2c9407fEa4dC236fAbA485A] = CLFeed(
            30,
            8,
            0xE188A9875af525d25334d75F3327863B2b8cd0F1
        );
        // TRX / USD
        chainlinkFeeds[0x85EAC5Ac2F758618dFa09bDbe0cf174e7d574D5B] = CLFeed(
            20,
            8,
            0xF4C5e535756D11994fCBB12Ba8adD0192D9b88be
        );

        // TUSD / USD
        chainlinkFeeds[0x14016E85a25aeb13065688cAFB43044C2ef86784] = CLFeed(
            30,
            8,
            0xa3334A9762090E827413A7495AfeCE76F41dFc06
        );

        // UNI / USD
        chainlinkFeeds[0xBf5140A22578168FD562DCcF235E5D43A02ce9B1] = CLFeed(
            20,
            8,
            0xb57f259E7C24e56a1dA00F66b55A5640d9f9E7e4
        );
        // USDC / USD
        chainlinkFeeds[0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d] = CLFeed(
            10,
            8,
            0x51597f405303C4377E36123cBc172b13269EA163
        );
        // USDN / USD
        chainlinkFeeds[0x03ab98f5dc94996F8C33E15cD4468794d12d41f9] = CLFeed(
            30,
            8,
            0x7C0BC703Dc56645203CFeBE1928E34B8e885ae37
        );
        // USDT / USD
        chainlinkFeeds[0x55d398326f99059fF775485246999027B3197955] = CLFeed(
            10,
            8,
            0xB97Ad0E74fa7d920791E90258A6E2085088b4320
        );
        // UST / USD
        chainlinkFeeds[0x23396cF899Ca06c4472205fC903bDB4de249D6fC] = CLFeed(
            50,
            8,
            0xcbf8518F8727B8582B22837403cDabc53463D462
        );
        // VAI / USD
        chainlinkFeeds[0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7] = CLFeed(
            30,
            8,
            0x058316f8Bb13aCD442ee7A216C7b60CFB4Ea1B53
        );

        // WING / USD
        chainlinkFeeds[0x3CB7378565718c64Ab86970802140Cc48eF1f969] = CLFeed(
            50,
            8,
            0xf7E7c0ffCB11dAC6eCA1434C67faB9aE000e10a7
        );
        // WOO / USD
        chainlinkFeeds[0x4691937a7508860F876c9c0a2a617E7d9E945D4B] = CLFeed(
            50,
            8,
            0x02Bfe714e78E2Ad1bb1C2beE93eC8dc5423B66d4
        );

        // XRP / USD
        chainlinkFeeds[0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE] = CLFeed(
            20,
            8,
            0x93A67D414896A280bF8FFB3b389fE3686E014fda
        );
        // XTZ / USD
        chainlinkFeeds[0x16939ef78684453bfDFb47825F8a5F714f12623a] = CLFeed(
            50,
            8,
            0x9A18137ADCF7b05f033ad26968Ed5a9cf0Bf8E6b
        );
        // XVS / USD
        chainlinkFeeds[0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63] = CLFeed(
            30,
            8,
            0xBF63F430A79D4036A5900C19818aFf1fa710f206
        );
        // YFI / USD
        chainlinkFeeds[0x88f1A5ae2A3BF98AEAF342D26B30a79438c9142e] = CLFeed(
            200,
            8,
            0xD7eAa5Bf3013A96e3d515c055Dbd98DbdC8c620D
        );
        // YFII / USD
        chainlinkFeeds[0x7F70642d88cf1C4a3a7abb072B53B929b653edA5] = CLFeed(
            50,
            8,
            0xC94580FAaF145B2FD0ab5215031833c98D3B77E4
        );

        // ZIL / USD
        chainlinkFeeds[0xb86AbCb37C3A4B64f74f59301AFF131a1BEcC787] = CLFeed(
            20,
            8,
            0x3e3aA4FC329529C8Ab921c810850626021dbA7e6
        );
    }

    function _initializeGoerliTestNetCLFeeds() internal {
        // ETH / USD
        chainlinkFeeds[0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6] = CLFeed(
            100,
            8,
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        // BTC / USD
        chainlinkFeeds[0xC04B0d3107736C32e19F1c62b2aF67BE61d63a05] = CLFeed(
            100,
            8,
            0xA39434A63A52E749F02807ae27335515BA4b07F7
        );

        // LINK / USD
        chainlinkFeeds[0x326C977E6efc84E512bB9C30f76E30c160eD06FB] = CLFeed(
            100,
            8,
            0x48731cF7e84dc94C5f84577882c14Be11a5B7456
        );
    }

    function _initializeBnbTestNetCLFeeds() internal {
        /* BNB test net */
        // AAVE / USD
        chainlinkFeeds[0x4B7268FC7C727B88c5Fc127D41b491BfAe63e144] = CLFeed(
            50,
            8,
            0x298619601ebCd58d0b526963Deb2365B485Edc74
        );
        // ADA / USD
        chainlinkFeeds[0xcD34BC54106bd45A04Ed99EBcC2A6a3e70d7210F] = CLFeed(
            500,
            8,
            0x5e66a1775BbC249b5D51C13d29245522582E671C
        );
        // BAKE / USD
        chainlinkFeeds[0xE02dF9e3e622DeBdD69fb838bB799E3F168902c5] = CLFeed(
            100,
            8,
            0xbe75E0725922D78769e3abF0bcb560d1E2675d5d
        );
        // BCH / USD
        chainlinkFeeds[0xAC8689184C30ddd8CE8861637D559Bf53000bCC9] = CLFeed(
            50,
            8,
            0x887f177CBED2cf555a64e7bF125E1825EB69dB82
        );
        // BNB / USD
        chainlinkFeeds[0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd] = CLFeed(
            30,
            8,
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
        // BTC / USD
        chainlinkFeeds[0xA808e341e8e723DC6BA0Bb5204Bafc2330d7B8e4] = CLFeed(
            30,
            8,
            0x5741306c21795FdCBb9b265Ea0255F499DFe515C
        );
        // BUSD / USD
        chainlinkFeeds[0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee] = CLFeed(
            30,
            8,
            0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa
        );
        // CAKE / USD
        chainlinkFeeds[0x7aBcA3B5f0Ca1da0eC05631d5788907D030D0a22] = CLFeed(
            200,
            8,
            0x81faeDDfeBc2F8Ac524327d70Cf913001732224C
        );
        // CREAM / USD
        chainlinkFeeds[0xd4CB328A82bDf5f03eB737f37Fa6B370aef3e888] = CLFeed(
            100,
            8,
            0xB8eADfD8B78aDA4F85680eD96e0f50e1B5762b0a
        );
        // DAI / USD
        chainlinkFeeds[0x698CcbA461FacD0e30b24e130417D54070787C17] = CLFeed(
            50,
            8,
            0xE4eE17114774713d2De0eC0f035d4F7665fc025D
        );
        // DODO / USD
        chainlinkFeeds[0xdE68B0D94e974281C351F5c9a070338cf1C97268] = CLFeed(
            100,
            8,
            0x2939E0089e61C5c9493C2013139885444c73a398
        );
        // DOGE / USD
        chainlinkFeeds[0x67D262CE2b8b846d9B94060BC04DC40a83F0e25B] = CLFeed(
            50,
            8,
            0x963D5e7f285Cc84ed566C486c3c1bC911291be38
        );
        // DOT / USD
        chainlinkFeeds[0x6679b8031519fA81fE681a93e98cdddA5aafa95b] = CLFeed(
            50,
            8,
            0xEA8731FD0685DB8AeAde9EcAE90C4fdf1d8164ed
        );
        // EQZ / USD
        chainlinkFeeds[0xD8598Fc1d84c0086273d88E341B66aF473aed84E] = CLFeed(
            100,
            8,
            0x6C2441920404835155f33d88faf0545B895871b1
        );
        // ETH / USD
        chainlinkFeeds[0x98f7A83361F7Ac8765CcEBAB1425da6b341958a7] = CLFeed(
            30,
            8,
            0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7
        );
        // FIL / USD
        chainlinkFeeds[0x43Eb7874b678560F3a6CABE936939fb0F9e2Ffd3] = CLFeed(
            50,
            8,
            0x17308A18d4a50377A4E1C37baaD424360025C74D
        );
        // FRONT / USD
        chainlinkFeeds[0x450f8A8091E9695a9ae0f67DE0DA5723dA74E5Ae] = CLFeed(
            100,
            8,
            0x101E51C0Bc2D2213a9b0c991A991958aAd3fF96A
        );
        // INJ / USD
        chainlinkFeeds[0x612984FF60acc647B675917ceDae8BF4574C637f] = CLFeed(
            100,
            8,
            0x58b299Fa027E1d9514dBbEeBA7944FD744553d61
        );
        // LINK / USD
        chainlinkFeeds[0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06] = CLFeed(
            30,
            8,
            0x1B329402Cb1825C6F30A0d92aB9E2862BE47333f
        );
        // LTC / USD
        chainlinkFeeds[0x969F147B6b8D81f86175de33206A4FD43dF17913] = CLFeed(
            500,
            8,
            0x9Dcf949BCA2F4A8a62350E0065d18902eE87Dca3
        );
        // MATIC / USD
        chainlinkFeeds[0xcfeb0103d4BEfa041EA4c2dACce7B3E83E1aE7E3] = CLFeed(
            100,
            8,
            0x957Eb0316f02ba4a9De3D308742eefd44a3c1719
        );
        // REEF / USD
        chainlinkFeeds[0x328BffaCBFbbd4285f8AB071db0622058d2bc34a] = CLFeed(
            100,
            8,
            0x902fA2495a8c5E89F7496F91678b8CBb53226D06
        );
        // SFP / USD
        chainlinkFeeds[0x54e313Eb7216dda38756ed329f74f553Ed35c8AB] = CLFeed(
            100,
            8,
            0x4b531A318B0e44B549F3b2f824721b3D0d51930A
        );
        // SXP / USD
        chainlinkFeeds[0x75107940Cf1121232C0559c747A986DEfbc69DA9] = CLFeed(
            30,
            8,
            0x678AC35ACbcE272651874E782DB5343F9B8a7D66
        );
        // TRX / USD
        chainlinkFeeds[0x19E7215abF8B2716EE807c9f4b83Af0e7f92653F] = CLFeed(
            50,
            8,
            0x135deD16bFFEB51E01afab45362D3C4be31AA2B0
        );
        // TWT / USD
        chainlinkFeeds[0x42ADbEf0899ffF18E19888E32ac090D3bF1ADd2b] = CLFeed(
            100,
            8,
            0x7671d7EDb66E4C10d5FFaA6a0d8842B5d880F0B3
        );
        // USDC / USD
        chainlinkFeeds[0x16227D60f7a0e586C66B005219dfc887D13C9531] = CLFeed(
            500,
            8,
            0x90c069C4538adAc136E051052E14c1cD799C41B7
        );
        // USDT / USD
        chainlinkFeeds[0x337610d27c682E347C9cD60BD4b3b107C9d34dDd] = CLFeed(
            500,
            8,
            0xEca2605f0BCF2BA5966372C99837b1F182d3D620
        );
        // XRP / USD
        chainlinkFeeds[0x3022A32fdAdB4f02281E8Fab33e0A6811237aab0] = CLFeed(
            500,
            8,
            0x4046332373C24Aed1dC8bAd489A04E187833B28d
        );
        // XVS / USD
        chainlinkFeeds[0xB9e0E753630434d7863528cc73CB7AC638a7c8ff] = CLFeed(
            30,
            8,
            0xCfA786C17d6739CBC702693F23cA4417B5945491
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
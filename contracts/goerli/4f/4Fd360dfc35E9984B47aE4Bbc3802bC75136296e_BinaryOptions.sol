// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "./gelato/AutomateTaskCreator.sol";

contract BinaryOptions is AutomateTaskCreator {
    // AUTOMATION VARS
    uint256 public count;
    bet public betToSettle;
    address public taskCaller;
    uint256 public lastExecuted;
    uint256 public constant INTERVAL = 5 minutes;
    //GOERLI: 0xaec7e05a7d508C448C207D333c90B336Fa31b57E
    //LOCAL: 0xaBa1dD5A162574F9bd8320A81345C5F7AceEFB5b
    address public gelatoAutomateAddress = 0xc1C6805B857Bef1f412519C4A842522431aFed39;

    // DAI GOERLI
    IDAIERC20 public DAI = IDAIERC20(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844);
    // DAI address 
    //IDAIERC20 public DAI = IDAIERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ETHPriceConsumerV3 public ETHUSD = new ETHPriceConsumerV3();
    BTCPriceConsumerV3 public BTCUSD = new BTCPriceConsumerV3();
    DAIPriceConsumerV3 public DAIUSD = new DAIPriceConsumerV3();
    PriceFeeds public PRICE_FEEDS = new PriceFeeds();

    event Placebet(address indexed player, bet indexed newoption);
    event SettleOption(address indexed player, bet indexed betinfo,bool wonorlost);
    event SettleOptionTaskCreated(bytes32 taskId);
    event SettleOptionTaskExecuted(bytes32 taskId);

    enum Status {
        nobet,
        beton,
        won,
        lost
    }

    /*enum Instrument {
        BTC,
        ETH,
        ONEINCH,
        AAPL,
        AAVE,
        ADA,
        ADX,
        ALCX,
        ANKR,
        APE,
        ATOM,
        AUD,
        AVAX,
        BADGER,
        BAL,
        BCH,
        BIT,
        BNB,
        BNT,
        BRL,
        CAD,
        CAKE,
        CHF,
        CNY,
        COMP,
        CRO,
        CRV,
        CSPR,
        CVX,
        DODO,
        DOGE,
        DOT,
        ENJ,
        ENS,
        EOS,
        ERN,
        EUR,
        FLOW,
        FOR,
        FORTH,
        FXS,
        GBP,
        GLM,
        GOOGL,
        GRT,
        HBAR,
        HIGH,
        IMX,
        INJ,
        INR,
        IOTX,
        JPY,
        KNC,
        KRW,
        KSM,
        LINK,
        LTC,
        MANA,
        MATIC,
        MKR,
        MSFT,
        NEAR,
        NFLX,
        NMR,
        NZD,
        OMG,
        ONT,
        OXT,
        PERP,
        PHA,
        REN,
        REQ,
        RSR,
        SAND,
        SGD,
        SNX,
        SOL,
        SPELL,
        SUSHI,
        SXP,
        TOMO,
        TRU,
        TRY,
        UNI,
        WING,
        XAG,
        XAU,
        XCN,
        XMR,
        XRP,
        YFI,
        ZRX
    }*/

    //GOERLI INSTUMENTS
    enum Instrument {
      BTC,
      ETH,
      EUR,
      FORTH,
      GBP,
      LINK
    }

    struct bet {
        uint id;
        Instrument instrument;
        uint stake;
        int strikeprice;
        uint timestamp;
        uint expiredat;
        uint reward;
        Status betstatus; //enum
        bool longorshort; //true if long 
        uint expiresAt;
    }
    
    // TODO: CHANGE OWNER!!
    //GOERLI: 0xaec7e05a7d508C448C207D333c90B336Fa31b57E
    //LOCAL: 0xaBa1dD5A162574F9bd8320A81345C5F7AceEFB5b
    address private owner;
    mapping (address => bet[]) public Accountbets;
    mapping (address => bytes32[]) public AccountTasks;

    constructor() AutomateTaskCreator(payable(gelatoAutomateAddress), address(this)) {
      owner = msg.sender;
    }

    receive() external payable{}

    function createTask(uint startTime, uint betId, address user) external payable {
        //require(taskId == bytes32(""), "Already started task");

        //uint256 startTime = block.timestamp + 120;

        bytes memory execData = abi.encodeCall(this.settleOption, (betId, user, 1));

        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });
        moduleData.modules[0] = Module.TIME;
        moduleData.modules[1] = Module.SINGLE_EXEC;

        moduleData.args[0] = _timeModuleArg(startTime, INTERVAL);
        moduleData.args[1] = _singleExecModuleArg();

        bytes32 id = _createTask(address(this), execData, moduleData, ETH);

        AccountTasks[user].push(id);
        emit SettleOptionTaskCreated(id);
    }

    function increaseCount(uint256 _amount) external {
        count += _amount;
        lastExecuted = block.timestamp;

        (uint256 fee, address feeToken) = _getFeeDetails();

        _transfer(fee, feeToken);
    }

    function getOwner() public view returns (address) {
      return owner;
    }

    function withdrawDAI(uint amount) external returns(bool){
        require(msg.sender == owner, "You are not the owner");
        require(amount <= getDAIbalance(), "Not enough DAI balance");
        bool txn = DAI.transfer(payable(msg.sender),amount * 1e18);
        return txn;
    }

    function withdrawETH(uint amount) external  {
        require(msg.sender == owner, "You are not the owner");
        require(amount <= address(this).balance, "Not enough ETH balance");
        payable(owner).transfer(amount);
    }
    
    function getDAIbalance() public view returns(uint){
        return DAI.balanceOf(address(this)) / 1000000000000000000;
    }

    function getDescription(Instrument instrument) public view returns (string memory) {
        return PRICE_FEEDS.getDescription(instrument);
    }

    function getPrice(Instrument instrument) public view returns (int) {
        return PRICE_FEEDS.getLatestPrice(instrument);
    }

    function getprices() public view returns(int , int , int ) {
        int ethusd = ETHUSD.getLatestPrice();
        int btcusd = BTCUSD.getLatestPrice();
        int daiusd = DAIUSD.getLatestPrice();

        return (ethusd,btcusd,daiusd);
    }

    function getpricesNew() public view returns(int , int , int ) {
        int ethusd = getPrice(Instrument.ETH);
        int btcusd = getPrice(Instrument.BTC);
        int daiusd = PRICE_FEEDS.getDaiPrice();

        return (ethusd,btcusd,daiusd);
    }

    function getAccountOptionsLength(address account) public view returns (uint) {
        return Accountbets[account].length;
    }

    // Returns a multiplier like 1.8x (odds)
    // All this k, p will be calculated in JS, because 5/3 is 1 in Solidity, 1.666667 in JS, so represented as 18 instead of 1.8
    function rewardmultiplier(uint _id, address _staker) public view returns(uint,int){
        bet[] memory betinfos = Accountbets[_staker];
        bet memory betinfo = betinfos[_id];
            
        uint _stake = betinfo.stake; // In ETH sent while writing option
        
        (int _ethusd, int _btcusd, int _daiusd) = getprices();

        int latestprice = betinfo.instrument == Instrument.ETH ? _ethusd : _btcusd ;
  
        uint _stakeinDAI = uint(int(_stake) * _ethusd  /_daiusd );
        
        uint[2] memory pk_values = multipliers(_id, _staker);
        uint _reward = pk_values[0] * pk_values[1] * _stakeinDAI;

        return (_reward,latestprice);  
    }

    function multipliers(uint id, address staker) public view returns (uint[2] memory) {
        bet[] memory betinfos = Accountbets[staker];
        bet memory betinfo = betinfos[id];

        //(int _ethusd, int _btcusd,) = getprices();

        //int latestprice = betinfo.instrument == Instrument.ETH ? _ethusd : _btcusd ;

        int latestprice = getPrice(betinfo.instrument);

        uint[2] memory pk_values ;
        uint p = 100; // hourselapsed constant
        uint k  ; // pricechange constant

        uint hourselapsed = (block.timestamp - betinfo.timestamp) / 3600;

        for (uint i = 0; i < hourselapsed; i++) {
            p = p * 99/100 ;
        }

        int strikeprice = betinfo.strikeprice ; 

        uint pricechange = uint((latestprice - strikeprice)/latestprice) * 100 ;

        if (pricechange < 1) {
            k = 20;
        }else if(pricechange >= 1 && pricechange < 4) {
            k = 18;
        }else {
            k = 16; 
        }

        pk_values[0] = p;
        pk_values[1] = k;

        return pk_values;
        
        // k and p are computed in the front end and passed inside the settleOption() function.
        // k is a constant that depends on the price change percentage when the option expires, has three tiers of reward drops depending on the % price change.
        // p is a constant that depends on the hours of your option expiry, drops the reward multiplier by 1% every hour.


        // uint hourspassed = (betinfo.timestamp - betinfo.expiry) / 3600 ; and for looping the reward drop of 1% for no of hours passed to get the value of p, better to do with JS.
        // For every hour, you will get dropped to 0.99x of your previous hour rewards, so for an option with expiry of 24 hours, you would have 0.7856x comparing to an option with < 1 hour expiry.
        

        // If the instrument is volatile, i.e., > 5% change within your expiration time, your return rate will go from 2x to 1.6x, which is a 60% gain.
        // Note that k will get multiplied by p that depends on hours of your expiration.
        // This will get multiplied with your staked amount, reward be like (1.74x * $100) if you win.   
    }

    function writeOption(Instrument instrument, uint amount, bool longorshort, uint expiresInSeconds) external payable {
        require(msg.value < (msg.sender).balance, "Insufficient ETH");
        require(amount <= msg.value, "Amount sent does not match the input");

        uint id = Accountbets[msg.sender].length ;      
        uint timestamp = block.timestamp;
        uint optionexpiration = 0;
        uint expiresAt = timestamp + expiresInSeconds;
     
        // if (instrument == "ETH"){ int strikeprice = GetEthprice();} else { int strikeprice = GetBtcprice();}

        //(int _ethusd, int _btcusd,) = getprices();
        //int strikeprice = instrument == Instrument.ETH ? _ethusd : _btcusd ;
        int strikeprice = getPrice(instrument);

        bet memory newoption = bet( id, instrument, amount, strikeprice , timestamp, optionexpiration, 0, Status.beton, longorshort, expiresAt);
        Accountbets[msg.sender].push(newoption);

        this.createTask(expiresAt, id, msg.sender);

        emit Placebet(msg.sender, newoption);
    }

    function testSettle(uint betId, address user, uint256 _amount) external {
        count += _amount;
        lastExecuted = block.timestamp;
        taskCaller = msg.sender;

        bet[] memory userBets = Accountbets[user];
        betToSettle = userBets[betId];

        (uint256 fee, address feeToken) = _getFeeDetails();

        _transfer(fee, feeToken);
    }

    function settleOption(uint betId, address user, uint256 _amount) external {
        bet[] memory userBets = Accountbets[user];
        //require(block.timestamp >=  userBets[betId].timestamp +  5400 ,"You can settle the option only after it has been open for 90 minutes");
        require( userBets[betId].betstatus == Status.beton && userBets[betId].expiredat == 0,
                    "The option has already expired or is not currently active");
        
        bet[] storage betinfos = Accountbets[user];
        bet storage betinfo = betinfos[betId];
        
        (uint _reward,int latestprice) = rewardmultiplier(betId, user);

        bool wonorlost;

        if (betinfo.longorshort == true) {
            latestprice >= betinfo.strikeprice  ? wonorlost = true : wonorlost = false ; 
        } else {
            latestprice <= betinfo.strikeprice  ? wonorlost = true : wonorlost = false ; 
        }

        betinfo.expiredat = block.timestamp;
        wonorlost ? betinfo.betstatus = Status.won : betinfo.betstatus = Status.lost ;

        count += _amount;

        if (wonorlost) {
            betinfo.reward = _reward ;
            //bool txn = DAI.transfer(user, _reward * 1e18/1e21);
            //require(txn, "Settling option failed");
        }

        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);

        emit SettleOption(user, betinfo, wonorlost);
    }

    function settleOptionBACKUP(uint id) external {
        bet[] memory mybets = Accountbets[msg.sender];
        require(block.timestamp >=  mybets[id].timestamp +  5400 ,"You can settle the option only after it has been open for 90 minutes");
        require( mybets[id].betstatus == Status.beton && mybets[id].expiredat == 0,
                    "The option has already expired or is not currently active");
        
        bet[] storage betinfos = Accountbets[msg.sender];
        bet storage betinfo = betinfos[id];
        
        (uint _reward,int latestprice) = rewardmultiplier(id, msg.sender);

        bool wonorlost;

        if (betinfo.longorshort == true) {
            latestprice >= betinfo.strikeprice  ? wonorlost = true : wonorlost = false ; 
        } else {
            latestprice <= betinfo.strikeprice  ? wonorlost = true : wonorlost = false ; 
        }

        wonorlost ? betinfo.betstatus = Status.won : betinfo.betstatus = Status.lost ;
        betinfo.expiredat = block.timestamp;

        if (wonorlost) {
            betinfo.reward = _reward ;
            bool txn = DAI.transfer(msg.sender, _reward * 1e18/1e21);
            require(txn, "Settling option failed");
        }

        emit SettleOption(msg.sender, betinfo, wonorlost);
    }

}

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

contract PriceFeeds {
    mapping (BinaryOptions.Instrument => AggregatorV3Interface) internal feeds;
    AggregatorV3Interface internal daiFeed;

    constructor() {
        // GOERLI CONFIG

        daiFeed = AggregatorV3Interface(0x0d79df66BE487753B02D015Fb622DED7f0E9798d);

        feeds[BinaryOptions.Instrument.BTC] = AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);
        feeds[BinaryOptions.Instrument.ETH] = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        feeds[BinaryOptions.Instrument.EUR] = AggregatorV3Interface(0x44390589104C9164407A0E0562a9DBe6C24A0E05);
        feeds[BinaryOptions.Instrument.FORTH] = AggregatorV3Interface(0x7A65Cf6C2ACE993f09231EC1Ea7363fb29C13f2F);
        feeds[BinaryOptions.Instrument.GBP] = AggregatorV3Interface(0x73D9c953DaaB1c829D01E1FC0bd92e28ECfB66DB);
        feeds[BinaryOptions.Instrument.LINK] = AggregatorV3Interface(0x48731cF7e84dc94C5f84577882c14Be11a5B7456);

        // END GOERLI CONFIG

        /*daiFeed = AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);

        feeds[BinaryOptions.Instrument.BTC] = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
        feeds[BinaryOptions.Instrument.ETH] = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        feeds[BinaryOptions.Instrument.ONEINCH] = AggregatorV3Interface(0xc929ad75B72593967DE83E7F7Cda0493458261D9);
        feeds[BinaryOptions.Instrument.AAPL] = AggregatorV3Interface(0x139C8512Cde1778e9b9a8e721ce1aEbd4dD43587);
        feeds[BinaryOptions.Instrument.AAVE] = AggregatorV3Interface(0x547a514d5e3769680Ce22B2361c10Ea13619e8a9);
        feeds[BinaryOptions.Instrument.ADA] = AggregatorV3Interface(0xAE48c91dF1fE419994FFDa27da09D5aC69c30f55);
        feeds[BinaryOptions.Instrument.ADX] = AggregatorV3Interface(0x231e764B44b2C1b7Ca171fa8021A24ed520Cde10);
        feeds[BinaryOptions.Instrument.ALCX] = AggregatorV3Interface(0xc355e4C0B3ff4Ed0B49EaACD55FE29B311f42976);
        feeds[BinaryOptions.Instrument.ANKR] = AggregatorV3Interface(0x7eed379bf00005CfeD29feD4009669dE9Bcc21ce);
        feeds[BinaryOptions.Instrument.APE] = AggregatorV3Interface(0xD10aBbC76679a20055E167BB80A24ac851b37056);
        feeds[BinaryOptions.Instrument.ATOM] = AggregatorV3Interface(0xDC4BDB458C6361093069Ca2aD30D74cc152EdC75);
        feeds[BinaryOptions.Instrument.AUD] = AggregatorV3Interface(0x77F9710E7d0A19669A13c055F62cd80d313dF022);
        feeds[BinaryOptions.Instrument.AVAX] = AggregatorV3Interface(0xFF3EEb22B5E3dE6e705b44749C2559d704923FD7);
        feeds[BinaryOptions.Instrument.BADGER] = AggregatorV3Interface(0x66a47b7206130e6FF64854EF0E1EDfa237E65339);
        feeds[BinaryOptions.Instrument.BAL] = AggregatorV3Interface(0xdF2917806E30300537aEB49A7663062F4d1F2b5F);
        feeds[BinaryOptions.Instrument.BCH] = AggregatorV3Interface(0x9F0F69428F923D6c95B781F89E165C9b2df9789D);
        feeds[BinaryOptions.Instrument.BIT] = AggregatorV3Interface(0x7b33EbfA52F215a30FaD5a71b3FeE57a4831f1F0);
        feeds[BinaryOptions.Instrument.BNB] = AggregatorV3Interface(0x14e613AC84a31f709eadbdF89C6CC390fDc9540A);
        feeds[BinaryOptions.Instrument.BNT] = AggregatorV3Interface(0x1E6cF0D433de4FE882A437ABC654F58E1e78548c);
        feeds[BinaryOptions.Instrument.BRL] = AggregatorV3Interface(0x971E8F1B779A5F1C36e1cd7ef44Ba1Cc2F5EeE0f);
        feeds[BinaryOptions.Instrument.CAD] = AggregatorV3Interface(0xa34317DB73e77d453b1B8d04550c44D10e981C8e);
        feeds[BinaryOptions.Instrument.CAKE] = AggregatorV3Interface(0xEb0adf5C06861d6c07174288ce4D0a8128164003);
        feeds[BinaryOptions.Instrument.CHF] = AggregatorV3Interface(0x449d117117838fFA61263B61dA6301AA2a88B13A);
        feeds[BinaryOptions.Instrument.CNY] = AggregatorV3Interface(0xeF8A4aF35cd47424672E3C590aBD37FBB7A7759a);
        feeds[BinaryOptions.Instrument.COMP] = AggregatorV3Interface(0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5);
        feeds[BinaryOptions.Instrument.CRO] = AggregatorV3Interface(0x00Cb80Cf097D9aA9A3779ad8EE7cF98437eaE050);
        feeds[BinaryOptions.Instrument.CRV] = AggregatorV3Interface(0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f);
        feeds[BinaryOptions.Instrument.CSPR] = AggregatorV3Interface(0x9e37a8Ee3bFa8eD6783Db031Dc458d200b226074);
        feeds[BinaryOptions.Instrument.CVX] = AggregatorV3Interface(0xd962fC30A72A84cE50161031391756Bf2876Af5D);
        feeds[BinaryOptions.Instrument.DODO] = AggregatorV3Interface(0x9613A51Ad59EE375e6D8fa12eeef0281f1448739);
        feeds[BinaryOptions.Instrument.DOGE] = AggregatorV3Interface(0x2465CefD3b488BE410b941b1d4b2767088e2A028);
        feeds[BinaryOptions.Instrument.DOT] = AggregatorV3Interface(0x1C07AFb8E2B827c5A4739C6d59Ae3A5035f28734);
        feeds[BinaryOptions.Instrument.ENJ] = AggregatorV3Interface(0x23905C55dC11D609D5d11Dc604905779545De9a7);
        feeds[BinaryOptions.Instrument.ENS] = AggregatorV3Interface(0x5C00128d4d1c2F4f652C267d7bcdD7aC99C16E16);
        feeds[BinaryOptions.Instrument.EOS] = AggregatorV3Interface(0x10a43289895eAff840E8d45995BBa89f9115ECEe);
        feeds[BinaryOptions.Instrument.ERN] = AggregatorV3Interface(0x0a87e12689374A4EF49729582B474a1013cceBf8);
        feeds[BinaryOptions.Instrument.EUR] = AggregatorV3Interface(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);
        feeds[BinaryOptions.Instrument.FLOW] = AggregatorV3Interface(0xD9BdD9f5ffa7d89c846A5E3231a093AE4b3469D2);
        feeds[BinaryOptions.Instrument.FOR] = AggregatorV3Interface(0x456834f736094Fb0AAD40a9BBc9D4a0f37818A54);
        feeds[BinaryOptions.Instrument.FORTH] = AggregatorV3Interface(0x7D77Fd73E468baECe26852776BeaF073CDc55fA0);
        feeds[BinaryOptions.Instrument.FXS] = AggregatorV3Interface(0x6Ebc52C8C1089be9eB3945C4350B68B8E4C2233f);
        feeds[BinaryOptions.Instrument.GBP] = AggregatorV3Interface(0x5c0Ab2d9b5a7ed9f470386e82BB36A3613cDd4b5);
        feeds[BinaryOptions.Instrument.GLM] = AggregatorV3Interface(0x83441C3A10F4D05de6e0f2E849A850Ccf27E6fa7);
        feeds[BinaryOptions.Instrument.GOOGL] = AggregatorV3Interface(0x36D39936BeA501755921beB5A382a88179070219);
        feeds[BinaryOptions.Instrument.GRT] = AggregatorV3Interface(0x86cF33a451dE9dc61a2862FD94FF4ad4Bd65A5d2);
        feeds[BinaryOptions.Instrument.HBAR] = AggregatorV3Interface(0x38C5ae3ee324ee027D88c5117ee58d07c9b4699b);
        feeds[BinaryOptions.Instrument.HIGH] = AggregatorV3Interface(0xe2F95bC12FE8a3C35684Be7586C39fD7c0E5b403);
        feeds[BinaryOptions.Instrument.IMX] = AggregatorV3Interface(0xBAEbEFc1D023c0feCcc047Bff42E75F15Ff213E6);
        feeds[BinaryOptions.Instrument.INJ] = AggregatorV3Interface(0xaE2EbE3c4D20cE13cE47cbb49b6d7ee631Cd816e);
        feeds[BinaryOptions.Instrument.INR] = AggregatorV3Interface(0x605D5c2fBCeDb217D7987FC0951B5753069bC360);
        feeds[BinaryOptions.Instrument.IOTX] = AggregatorV3Interface(0x96c45535d235148Dc3ABA1E48A6E3cFB3510f4E2);
        feeds[BinaryOptions.Instrument.JPY] = AggregatorV3Interface(0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3);
        feeds[BinaryOptions.Instrument.KNC] = AggregatorV3Interface(0xf8fF43E991A81e6eC886a3D281A2C6cC19aE70Fc);
        feeds[BinaryOptions.Instrument.KRW] = AggregatorV3Interface(0x01435677FB11763550905594A16B645847C1d0F3);
        feeds[BinaryOptions.Instrument.KSM] = AggregatorV3Interface(0x06E4164E24E72B879D93360D1B9fA05838A62EB5);
        feeds[BinaryOptions.Instrument.LINK] = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
        feeds[BinaryOptions.Instrument.LTC] = AggregatorV3Interface(0x6AF09DF7563C363B5763b9102712EbeD3b9e859B);
        feeds[BinaryOptions.Instrument.MANA] = AggregatorV3Interface(0x56a4857acbcfe3a66965c251628B1c9f1c408C19);
        feeds[BinaryOptions.Instrument.MATIC] = AggregatorV3Interface(0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676);
        feeds[BinaryOptions.Instrument.MKR] = AggregatorV3Interface(0xec1D1B3b0443256cc3860e24a46F108e699484Aa);
        feeds[BinaryOptions.Instrument.MSFT] = AggregatorV3Interface(0x021Fb44bfeafA0999C7b07C4791cf4B859C3b431);
        feeds[BinaryOptions.Instrument.NEAR] = AggregatorV3Interface(0xC12A6d1D827e23318266Ef16Ba6F397F2F91dA9b);
        feeds[BinaryOptions.Instrument.NFLX] = AggregatorV3Interface(0x67C2e69c5272B94AF3C90683a9947C39Dc605ddE);
        feeds[BinaryOptions.Instrument.NMR] = AggregatorV3Interface(0xcC445B35b3636bC7cC7051f4769D8982ED0d449A);
        feeds[BinaryOptions.Instrument.NZD] = AggregatorV3Interface(0x3977CFc9e4f29C184D4675f4EB8e0013236e5f3e);
        feeds[BinaryOptions.Instrument.OMG] = AggregatorV3Interface(0x7D476f061F8212A8C9317D5784e72B4212436E93);
        feeds[BinaryOptions.Instrument.ONT] = AggregatorV3Interface(0xcDa3708C5c2907FCca52BB3f9d3e4c2028b89319);
        feeds[BinaryOptions.Instrument.OXT] = AggregatorV3Interface(0xd75AAaE4AF0c398ca13e2667Be57AF2ccA8B5de6);
        feeds[BinaryOptions.Instrument.PERP] = AggregatorV3Interface(0x01cE1210Fe8153500F60f7131d63239373D7E26C);
        feeds[BinaryOptions.Instrument.PHA] = AggregatorV3Interface(0x2B1248028fe48864c4f1c305E524e2e6702eAFDF);
        feeds[BinaryOptions.Instrument.REN] = AggregatorV3Interface(0x0f59666EDE214281e956cb3b2D0d69415AfF4A01);
        feeds[BinaryOptions.Instrument.REQ] = AggregatorV3Interface(0x2F05888D185970f178f40610306a0Cc305e52bBF);
        feeds[BinaryOptions.Instrument.RSR] = AggregatorV3Interface(0x759bBC1be8F90eE6457C44abc7d443842a976d02);
        feeds[BinaryOptions.Instrument.SAND] = AggregatorV3Interface(0x35E3f7E558C04cE7eEE1629258EcbbA03B36Ec56);
        feeds[BinaryOptions.Instrument.SGD] = AggregatorV3Interface(0xe25277fF4bbF9081C75Ab0EB13B4A13a721f3E13);
        feeds[BinaryOptions.Instrument.SNX] = AggregatorV3Interface(0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699);
        feeds[BinaryOptions.Instrument.SOL] = AggregatorV3Interface(0x4ffC43a60e009B551865A93d232E33Fce9f01507);
        feeds[BinaryOptions.Instrument.SPELL] = AggregatorV3Interface(0x8c110B94C5f1d347fAcF5E1E938AB2db60E3c9a8);
        feeds[BinaryOptions.Instrument.SUSHI] = AggregatorV3Interface(0xCc70F09A6CC17553b2E31954cD36E4A2d89501f7);
        feeds[BinaryOptions.Instrument.SXP] = AggregatorV3Interface(0xFb0CfD6c19e25DB4a08D8a204a387cEa48Cc138f);
        feeds[BinaryOptions.Instrument.TOMO] = AggregatorV3Interface(0x3d44925a8E9F9DFd90390E58e92Ec16c996A331b);
        feeds[BinaryOptions.Instrument.TRU] = AggregatorV3Interface(0x26929b85fE284EeAB939831002e1928183a10fb1);
        feeds[BinaryOptions.Instrument.TRY] = AggregatorV3Interface(0xB09fC5fD3f11Cf9eb5E1C5Dba43114e3C9f477b5);
        feeds[BinaryOptions.Instrument.UNI] = AggregatorV3Interface(0x553303d460EE0afB37EdFf9bE42922D8FF63220e);
        feeds[BinaryOptions.Instrument.WING] = AggregatorV3Interface(0x134fE0a225Fb8e6683617C13cEB6B3319fB4fb82);
        feeds[BinaryOptions.Instrument.XAG] = AggregatorV3Interface(0x379589227b15F1a12195D3f2d90bBc9F31f95235);
        feeds[BinaryOptions.Instrument.XAU] = AggregatorV3Interface(0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6);
        feeds[BinaryOptions.Instrument.XCN] = AggregatorV3Interface(0xeb988B77b94C186053282BfcD8B7ED55142D3cAB);
        feeds[BinaryOptions.Instrument.XMR] = AggregatorV3Interface(0xFA66458Cce7Dd15D8650015c4fce4D278271618F);
        feeds[BinaryOptions.Instrument.XRP] = AggregatorV3Interface(0xCed2660c6Dd1Ffd856A5A82C67f3482d88C50b12);
        feeds[BinaryOptions.Instrument.YFI] = AggregatorV3Interface(0xA027702dbb89fbd58938e4324ac03B58d812b0E1);
        feeds[BinaryOptions.Instrument.ZRX] = AggregatorV3Interface(0x2885d15b8Af22648b98B122b22FDF4D2a56c6023);*/
    }

    function getLatestPrice(BinaryOptions.Instrument instrument) public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = feeds[instrument].latestRoundData();
        
        return price;
    }

    function getDescription(BinaryOptions.Instrument instrument) public view returns (string memory) {
        return feeds[instrument].description();
    }

    /**
     * Returns DAI latest price
     */
    function getDaiPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = daiFeed.latestRoundData();

        return price;
    }
}


//pragma solidity ^0.8.7;

contract ETHPriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Ethereum
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor() {
        // GOERLI
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

        //priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getDescription() public view returns (string memory) {
      return priceFeed.description();
    }
}

contract BTCPriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Ethereum
     * Aggregator: BTC/USD
     * Address: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
     */
    constructor() {
        // GOERLI
        priceFeed = AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);

        //priceFeed = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
}

contract DAIPriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Ethereum
     * Aggregator: DAI/USD
     * Address: 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9
     */
    constructor() {
        // GOERLI
        priceFeed = AggregatorV3Interface(0x0d79df66BE487753B02D015Fb622DED7f0E9798d);

        //priceFeed = AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
}


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
//pragma solidity ^0.8.7;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IDAIERC20 {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./AutomateReady.sol";

/**
 * @dev Inherit this contract to allow your smart contract
 * to be a task creator and create tasks.
 */
abstract contract AutomateTaskCreator is AutomateReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(address _automate, address _fundsOwner)
        AutomateReady(_automate, address(this))
    {
        fundsOwner = _fundsOwner;
        taskTreasury = automate.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount, address _token) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(payable(fundsOwner), _token, _amount);
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value: ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
            automate.createTask(
                _execAddress,
                _execDataOrSelector,
                _moduleData,
                _feeToken
            );
    }

    function _cancelTask(bytes32 _taskId) internal {
        automate.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(uint256 _startTime, uint256 _interval)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Types.sol";

/**
 * @dev Inherit this contract to allow your smart contract to
 * - Make synchronous fee payments.
 * - Have call restrictions for functions to be automated.
 */
// solhint-disable private-vars-leading-underscore
abstract contract AutomateReady {
    IAutomate public immutable automate;
    address public immutable dedicatedMsgSender;
    address private immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
        0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _automate, address _taskCreator) {
        automate = IAutomate(_automate);
        _gelato = IAutomate(_automate).gelato();
        (dedicatedMsgSender, ) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IAutomate.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success, ) = _gelato.call{value: _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
        internal
        view
        returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = automate.getFeeDetails();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

enum Module {
    RESOLVER,
    TIME,
    PROXY,
    SINGLE_EXEC
}

struct ModuleData {
    Module[] modules;
    bytes[] args;
}

interface IAutomate {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}
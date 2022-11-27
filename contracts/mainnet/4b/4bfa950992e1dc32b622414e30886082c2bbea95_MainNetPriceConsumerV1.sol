/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

contract MainNetPriceConsumerV1 {
    // Crypto On Chain Data
    AggregatorV3Interface internal TotalMarketCap;
    AggregatorV3Interface internal ConsumerPriceIndex;

    // Crypto Prices
    AggregatorV3Interface internal OneInchUsdPriceFeed;
    AggregatorV3Interface internal OneInchEthPriceFeed;
    AggregatorV3Interface internal EthUsdPriceFeed;
    AggregatorV3Interface internal BtcUsdPriceFeed;
    AggregatorV3Interface internal BtcEthPriceFeed;
    AggregatorV3Interface internal CadUsdPriceFeed;
    AggregatorV3Interface internal EurUsdPriceFeed;
    AggregatorV3Interface internal JpyUsdPriceFeed;
    AggregatorV3Interface internal InrUsdPriceFeed;
    AggregatorV3Interface internal AaveUsdPriceFeed;
    AggregatorV3Interface internal AaveEthPriceFeed;
    AggregatorV3Interface internal AdaUsdPriceFeed;
    AggregatorV3Interface internal AudUsdPriceFeed;
    AggregatorV3Interface internal AlcxUsdPriceFeed;
    AggregatorV3Interface internal AlcxEthPriceFeed;
    AggregatorV3Interface internal AtomUsdPriceFeed;
    AggregatorV3Interface internal AtomEthPriceFeed;
    AggregatorV3Interface internal AvaxUsdPriceFeed;
    AggregatorV3Interface internal BadgerUsdPriceFeed;
    AggregatorV3Interface internal BadgerEthPriceFeed;
    AggregatorV3Interface internal BalUsdPriceFeed;
    AggregatorV3Interface internal BalEthPriceFeed;
    AggregatorV3Interface internal BandUsdPriceFeed;
    AggregatorV3Interface internal BandEthPriceFeed;
    AggregatorV3Interface internal BnbUsdPriceFeed;
    AggregatorV3Interface internal BnbEthPriceFeed;
    AggregatorV3Interface internal CakeUsdPriceFeed;
    AggregatorV3Interface internal CrvUsdPriceFeed;
    AggregatorV3Interface internal CrvEthPriceFeed;
    AggregatorV3Interface internal DotUsdPriceFeed;
    AggregatorV3Interface internal EnjUsdPriceFeed;
    AggregatorV3Interface internal EnjEthPriceFeed;
    AggregatorV3Interface internal FilUsdPriceFeed;
    AggregatorV3Interface internal GbpUsdPriceFeed;
    AggregatorV3Interface internal KsmUsdPriceFeed;
    AggregatorV3Interface internal LinkEthPriceFeed;
    AggregatorV3Interface internal LinkUsdPriceFeed;
    AggregatorV3Interface internal LtcUsdPriceFeed;
    AggregatorV3Interface internal MaticUsdPriceFeed;
    AggregatorV3Interface internal ManaUsdPriceFeed;
    AggregatorV3Interface internal ManaEthPriceFeed;
    AggregatorV3Interface internal MakerUsdPriceFeed;
    AggregatorV3Interface internal MakerEthPriceFeed;
    AggregatorV3Interface internal PerpUsdPriceFeed;
    AggregatorV3Interface internal PerpEthPriceFeed;
    AggregatorV3Interface internal RuneEthPriceFeed;
    AggregatorV3Interface internal SolUsdPriceFeed;
    AggregatorV3Interface internal SushiUsdPriceFeed;
    AggregatorV3Interface internal SushiEthPriceFeed;
    AggregatorV3Interface internal UniUsdPriceFeed;
    AggregatorV3Interface internal UniEthPriceFeed;
    AggregatorV3Interface internal XmrUsdPriceFeed;
    AggregatorV3Interface internal XrpUsdPriceFeed;
    AggregatorV3Interface internal YfiUsdPriceFeed;
    AggregatorV3Interface internal YfiEthPriceFeed;
    // Comodities
    AggregatorV3Interface internal GldUsdPriceFeed;
    AggregatorV3Interface internal SilUsdPriceFeed;
    AggregatorV3Interface internal OilUsdPriceFeed;

    constructor() {
        // Crypto On Chain Data
        TotalMarketCap = AggregatorV3Interface(0xEC8761a0A73c34329CA5B1D3Dc7eD07F30e836e2);
        ConsumerPriceIndex = AggregatorV3Interface(0x9a51192e065ECC6BDEafE5e194ce54702DE4f1f5);

        // Crypto Prices
        OneInchUsdPriceFeed = AggregatorV3Interface(0xc929ad75B72593967DE83E7F7Cda0493458261D9);
        OneInchEthPriceFeed = AggregatorV3Interface(0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8);
        EthUsdPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        BtcUsdPriceFeed = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
        BtcEthPriceFeed = AggregatorV3Interface(0xdeb288F737066589598e9214E782fa5A8eD689e8);
        EurUsdPriceFeed = AggregatorV3Interface(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);
        CadUsdPriceFeed = AggregatorV3Interface(0xa34317DB73e77d453b1B8d04550c44D10e981C8e);
        JpyUsdPriceFeed = AggregatorV3Interface(0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3);

        InrUsdPriceFeed = AggregatorV3Interface(0x605D5c2fBCeDb217D7987FC0951B5753069bC360);
        AaveUsdPriceFeed = AggregatorV3Interface(0x547a514d5e3769680Ce22B2361c10Ea13619e8a9);
        AaveEthPriceFeed = AggregatorV3Interface(0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012);
        AdaUsdPriceFeed = AggregatorV3Interface(0xAE48c91dF1fE419994FFDa27da09D5aC69c30f55);
        AudUsdPriceFeed = AggregatorV3Interface(0x77F9710E7d0A19669A13c055F62cd80d313dF022);
        AlcxUsdPriceFeed = AggregatorV3Interface(0xc355e4C0B3ff4Ed0B49EaACD55FE29B311f42976);
        AlcxEthPriceFeed = AggregatorV3Interface(0x194a9AaF2e0b67c35915cD01101585A33Fe25CAa);
        AtomUsdPriceFeed = AggregatorV3Interface(0xDC4BDB458C6361093069Ca2aD30D74cc152EdC75);
        AtomEthPriceFeed = AggregatorV3Interface(0x15c8eA24Ba2d36671Fa22aD4Cff0a8eafe144352);
        AvaxUsdPriceFeed = AggregatorV3Interface(0xFF3EEb22B5E3dE6e705b44749C2559d704923FD7);
        BadgerUsdPriceFeed = AggregatorV3Interface(0x66a47b7206130e6FF64854EF0E1EDfa237E65339);
        BadgerEthPriceFeed = AggregatorV3Interface(0x58921Ac140522867bf50b9E009599Da0CA4A2379);
        BalUsdPriceFeed = AggregatorV3Interface(0xdF2917806E30300537aEB49A7663062F4d1F2b5F);
        BalEthPriceFeed = AggregatorV3Interface(0xC1438AA3823A6Ba0C159CfA8D98dF5A994bA120b);
        BandUsdPriceFeed = AggregatorV3Interface(0x919C77ACc7373D000b329c1276C76586ed2Dd19F);
        BandEthPriceFeed = AggregatorV3Interface(0x0BDb051e10c9718d1C29efbad442E88D38958274);
        BnbUsdPriceFeed = AggregatorV3Interface(0x14e613AC84a31f709eadbdF89C6CC390fDc9540A);
        BnbEthPriceFeed = AggregatorV3Interface(0xc546d2d06144F9DD42815b8bA46Ee7B8FcAFa4a2);
        CakeUsdPriceFeed = AggregatorV3Interface(0xEb0adf5C06861d6c07174288ce4D0a8128164003);
        CrvUsdPriceFeed = AggregatorV3Interface(0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f);
        CrvEthPriceFeed = AggregatorV3Interface(0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e);
        DotUsdPriceFeed = AggregatorV3Interface(0x1C07AFb8E2B827c5A4739C6d59Ae3A5035f28734);
        EnjUsdPriceFeed = AggregatorV3Interface(0x23905C55dC11D609D5d11Dc604905779545De9a7);
        EnjEthPriceFeed = AggregatorV3Interface(0x24D9aB51950F3d62E9144fdC2f3135DAA6Ce8D1B);
        FilUsdPriceFeed = AggregatorV3Interface(0x0606Be69451B1C9861Ac6b3626b99093b713E801);
        GbpUsdPriceFeed = AggregatorV3Interface(0x5c0Ab2d9b5a7ed9f470386e82BB36A3613cDd4b5);
        KsmUsdPriceFeed = AggregatorV3Interface(0x06E4164E24E72B879D93360D1B9fA05838A62EB5);
        LtcUsdPriceFeed = AggregatorV3Interface(0x6AF09DF7563C363B5763b9102712EbeD3b9e859B);
        LinkEthPriceFeed = AggregatorV3Interface(0xDC530D9457755926550b59e8ECcdaE7624181557);
        LinkUsdPriceFeed = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
        MaticUsdPriceFeed = AggregatorV3Interface(0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676);
        ManaUsdPriceFeed = AggregatorV3Interface(0x56a4857acbcfe3a66965c251628B1c9f1c408C19);
        ManaEthPriceFeed = AggregatorV3Interface(0x82A44D92D6c329826dc557c5E1Be6ebeC5D5FeB9);
        MakerUsdPriceFeed = AggregatorV3Interface(0xec1D1B3b0443256cc3860e24a46F108e699484Aa);
        MakerEthPriceFeed = AggregatorV3Interface(0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2);
        PerpUsdPriceFeed = AggregatorV3Interface(0x01cE1210Fe8153500F60f7131d63239373D7E26C);
        PerpEthPriceFeed = AggregatorV3Interface(0x3b41D5571468904D4e53b6a8d93A6BaC43f02dC9);
        RuneEthPriceFeed = AggregatorV3Interface(0x875D60C44cfbC38BaA4Eb2dDB76A767dEB91b97e);
        SolUsdPriceFeed = AggregatorV3Interface(0x4ffC43a60e009B551865A93d232E33Fce9f01507);
        SushiUsdPriceFeed = AggregatorV3Interface(0xCc70F09A6CC17553b2E31954cD36E4A2d89501f7);
        SushiEthPriceFeed = AggregatorV3Interface(0xe572CeF69f43c2E488b33924AF04BDacE19079cf);
        UniUsdPriceFeed = AggregatorV3Interface(0x553303d460EE0afB37EdFf9bE42922D8FF63220e);
        UniEthPriceFeed = AggregatorV3Interface(0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e);
        XmrUsdPriceFeed = AggregatorV3Interface(0xFA66458Cce7Dd15D8650015c4fce4D278271618F);
        XrpUsdPriceFeed = AggregatorV3Interface(0xFA66458Cce7Dd15D8650015c4fce4D278271618F);
        YfiUsdPriceFeed = AggregatorV3Interface(0xA027702dbb89fbd58938e4324ac03B58d812b0E1);
        YfiEthPriceFeed = AggregatorV3Interface(0x7c5d4F8345e66f68099581Db340cd65B078C41f4);
        // Comodities
        GldUsdPriceFeed = AggregatorV3Interface(0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6);
        SilUsdPriceFeed = AggregatorV3Interface(0x379589227b15F1a12195D3f2d90bBc9F31f95235);
        OilUsdPriceFeed = AggregatorV3Interface(0xf3584F4dd3b467e73C2339EfD008665a70A4185c);
    }
    //Returns the latest price
    function TotalMarketCapUsd() public view returns(uint, uint) {
        (/*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = TotalMarketCap.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function ConsumerPriceIndexData() public view returns(uint, uint) {
        (/*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = ConsumerPriceIndex.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatest1inchUsd() public view returns(uint, uint) {
        (/*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = OneInchUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatest1inchEth() public view returns(uint, uint) {
        (/*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = OneInchEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestEthUsd() public view returns(uint, uint) {
        (/*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = EthUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestBtcUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestCadUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = CadUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestBtcEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BtcEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestEurUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = EurUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestJpyUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = JpyUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }

    function getLatestInrUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = InrUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }

    function getLatestAaveUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = AaveUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestAaveEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = AaveUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestAdaUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = AdaUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestAudUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = AudUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestAlcxUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = AlcxUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestAlcxEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = AlcxEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestAtomUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = AtomUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestAtomEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = AtomEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestAvaxUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = AvaxUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestBadgerUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BadgerUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestBadgerEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BadgerEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestBalUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BalUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestBalEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BalEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestBandUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BandUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestBandEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BandEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestBnbUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BnbUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestBnbEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = BnbEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestCakeUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = CakeUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestCrvUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = CrvUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestCrvEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = CrvEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestDotUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = DotUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestEnjUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = EnjUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestEnjEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = EnjEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestFilUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = FilUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestGbpUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = GbpUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestKsmUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = KsmUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestLtcUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = LtcUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestLinkEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = LinkEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestLinkUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = LinkUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestMaticUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = MaticUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestManaUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = ManaUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestManaEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = ManaEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestMakerEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = MakerEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestMakerUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = MakerUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestPerpUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = PerpUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestPerpEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = PerpEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestRuneEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = RuneEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestSolUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = SolUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestSushiUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = SushiUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestSushiEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = SushiEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestUniUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = UniUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestUniEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = UniEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestXmrUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = XmrUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestXrpUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = XrpUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestYfiUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = YfiUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestYfiEth() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = YfiEthPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestGldUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = GldUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestSilUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = SilUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
    function getLatestOilUsd() public view returns (uint, uint) {
        ( /*uint80 roundID*/, int price, /*uint startedAt*/, uint timeStamp, /*uint80 answeredInRound*/) = OilUsdPriceFeed.latestRoundData();
        uint uintPrice;
        if (price < 0) {uintPrice = uint(-price);}
        else {uintPrice = uint(price);}
        return (uintPrice, timeStamp);
    }
}
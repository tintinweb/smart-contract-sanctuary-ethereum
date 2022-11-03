pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract ProducerAndBottleTypeRegistry {

    // producer is not directly linked to region
    struct Producer {
        address accountAddress;
        string name;
        string companyAddress;
        string description;

        // BottleType[] bottleTypes;
        // string websiteURL ...
    }

    event NewBottleType (BottleType);
    event NewProducer (Producer);

    Producer[] public producers;
    mapping(address => BottleType[]) public producerToBottleTypes;

    // ****** WHITELIST REQUIRED ******
    function createProducer(address _account, string calldata _name, string calldata _address, string calldata _description) public {
        Producer memory newProducer = Producer(_account, _name, _address, _description);
        producers.push(newProducer);
        emit NewProducer(newProducer);
    }


    // should we store detail of each region on blockchain? I suppose no. 
    // https://www.wineaustralia.com/labelling/register-of-protected-gis-and-other-terms/geographical-indications
    enum Region {
        Australia,
        SouthEasternAustralia,
        SouthAustralia,
        Adelaide,
        Barossa,
        BarossaValley,
        EdenValley,
        HighEden,
        FarNorth,
        SouthernFlindersRanges,
        Fleurieu,
        CurrencyCreek,
        KangarooIsland,
        LanghorneCreek,
        McLarenVale,
        SouthernFleurieu
    }

    // style of wine
    enum Style {
        Red,
        White,
        Rose,
        Sparking,
        Fortified
    }

    // type of grapes, these are enough for demo, will pop this enum afterwards
    enum Varietal{
        Shiraz,
        CabernetSauvignon,
        Grenache,
        Merlot,
        Mataro,
        Riesling,
        Chardonnay,
        Semillon,
        Viognier,
        Sauvignon
    }

    struct BottleType {
        string name;
        Varietal varietal;
        address producer;
        Region region;
        uint vintage;  // should set a valid range? or enum

        uint size;  // in ml
        uint alcoholContent;  // in xx.x%, 
        // since solidity does not support decimal, the alcohoConent stored here (say, 86) should be the original value (say, 8.6) * 10, when display it, / 10
        uint standardDrinks;   // in xx.x, original value (say, 8.3) * 10
        string description;

        // string award ...?

    }

    // ****** WHITELIST REQUIRED ******
    function createBottleType(string calldata _name, Varietal _varietal, address _producer, Region _region, uint _vintage, uint _size, uint _alcoholContent, uint _standardDrinks, string calldata _description) public {
        BottleType memory newBottleType = BottleType(_name, _varietal, _producer, _region, _vintage, _size, _alcoholContent, _standardDrinks, _description);
        producerToBottleTypes[_producer].push(newBottleType);
        emit NewBottleType(newBottleType);
    }

    
    fallback() external payable {}

    receive() external payable {}

}
//SPDX-License-Identifier: MIT

//pragma
pragma solidity ^0.8.7;

//imports
import "./PriceConverter.sol";

/*aufgaben für diesen Contract:
    1. minimum Spende bestimmen.
    2. Nutzern erlauben  geld zu spenden.
    3. Fähigkeit geld abzuheben. NUR DEPLOYER DES CONTRACTS.
*/

// Error Code => wichtig um SPÄTER den fehler zu lokalisieren
error BitteSpenden__NichtBesitzer();

// Interfaces, Libraries, Contracts


contract BitteSpenden
{
    //type deklarationen 
    using PriceConverter for uint256;       // "priceconverter" gesp. als Library ausgabe des scripts "priceconverter" als eine zahl
    
    //state variabeln / storage variabel ==> ich werde für jede storage variabel eine "s_" hinzufügen bzw: s_Spender
    uint256 public constant minimumUSD = 50 * 1e18;
    address[] private s_Spender;   
    mapping(address => uint256) private s_AddresseZuGespendeterMenge;
    address private immutable i_owner; 

    AggregatorV3Interface private s_priceFeed; // IMPORTIEREN WIE IN PRICECONVERTER DEN PRICEFEED VON AGGREGATORV3INTERFACE der jeweiligen Blockhain als global variable gesp. -> die ABI combined mit addresse gibt mir den priceFeed contract.
    
    //modifier

    modifier NurDerBesitzer
        {
            //require(msg.sender== owner,"sender ist nicht besitzer"); oben ein error type geschaffen. der wird hier mit If-Abfrage genutzt
            if(msg.sender != i_owner){revert BitteSpenden__NichtBesitzer();}
            _;
        }

    //constructor funktion wird autom. gecallt, wenn deployen eines contracts
    // in "()" sind parameter, die ich NEU refactored habe, da ich ein mocks brauche. 4
    // ich will dass mein constructor als parameter den pricefeed sofort hat
    // ICH MUSS UNBEDINGT DIE PARAMETER AUCH DEFINIEREN IN EINEM CODE ANSONSTEN EIN FEHLER
    // BEIM DEPLOYEN WIRD ALSO DURCH DEN CONATRUCTOR SOFORT DIE PRICEFEED ADDRESSE GEPASST ALS PARAMETER 


    //functions
    constructor(address priceFeedAddress)    
    {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);  //--> im grunde genommen importieren wir von jeder chain den contract/objekt ABI für die erfassung des Eth/usd Preises... PRICEFEED ABI WIRD VON CHAINLINK AGGREGATORV3INTERFACE BEREITGESTELLET // modularisiert für jede blockchain-> jeder pricefeed contract von jeder blockchain kann somit getestet werden... JETZT NUTZEN FÜR PRICECONVERTER 
    }

    receive() external payable
    {
        spenden();
    }

    fallback() external payable
    {
        spenden();
    }

    /* nur fürs testen */

    

    /*ende des tests ab hier  */

    function spenden() public payable                        // "payable keyword", erlaubt ETH in contract transferiert zu werden.
    {
         require (msg.value.Umwandlungsrate(s_priceFeed) >= minimumUSD,"nicht genug gespendet");           // ich weiter refactored... ich definiere einen parameter um in der funktion "umwandlungsrate" in meinem "priceconverter"-script => kriege den price für eth/usd.              //global keyword für access in "value/menge/wert"
        s_Spender.push(msg.sender);
        s_AddresseZuGespendeterMenge[msg.sender] += msg.value;                                                                         //global keyword für adresse des spendersn
    }

/*nach abheben soll address-wert-mapping und spenderliste zurück gesetzt werden
dafür nutze ich "for-loop*/
    function abzuheben() public  NurDerBesitzer
    {  
        /*for(starting index; ending index; step amount)*/               /*loop "SpenderIndex +1" -> hochzählen zu nächsten Index*/
        for(uint256 SpenderIndex = 0; SpenderIndex < s_Spender.length; SpenderIndex = SpenderIndex +1)
        {
           address spender = s_Spender[SpenderIndex];           // loop startet bei index 0
           s_AddresseZuGespendeterMenge[spender] = 0; // setzt wert/value für addresse bei  "mapping" zurück zu 0
        }

        s_Spender = new address[](0);                     //setzt array/liste zurück 
    
    /*es gibt 3 möglichkeit Spenden zu schicken:
      transfer
      send
      call
     */
   
                        //call
    (bool CallErfolg,) =payable(msg.sender).call{value: address(this).balance}("");
    require(CallErfolg,"aufrufen fehlgeschlafen");
    }

        // Die funktion "abzuheben" ist sehr teuer(hohe gaskosten) => durch for/loop ... daher: diese alternative 
    /*wir speichern die variabel nicht als storage sonder als memory
    so werden die variabeln nicht im storage gespeichert.
    d.h. ich muss die variabeln erstmal als solche deklarieren */
    function guenstigeresAbheben() public payable NurDerBesitzer {
        address [] memory funders = s_Spender; // die variabel wird als memory gespeichert ... die einmalige zuordnung der storage variabel zu einer memory variabel macht es wesentlicher gas effizienter damit zu arbeiten
        for (uint256 SpenderIndex =0; SpenderIndex < funders.length; SpenderIndex++){
            address spender = funders[SpenderIndex]; // loop soll wieder bei index 0 starten
            s_AddresseZuGespendeterMenge[spender] = 0; //zurücksetzten der Map
        }
        s_Spender = new address[](0);
        (bool CallErfolg, ) = i_owner.call{value: address(this).balance}("");
        require(CallErfolg);
    }

    //view /pure
    function getOwner() public view returns(address){
        return i_owner;
    }
    
    function getFunder(uint256 index) public view returns(address){
        return s_Spender[index];
    }

    function getAddressezuGefundeterMenge(address spender) public view returns (uint256){
        return s_AddresseZuGespendeterMenge[spender];
    }

    function welcherPreis() public view returns(AggregatorV3Interface){
        return s_priceFeed;
    }
        

    
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; 

library PriceConverter
{
 /* preis von ETH in DOLLAR*/
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256)     //  parameter => nicht  mit spez. objekt für contract zu arbeiten => durch parametrisieren des pricefeed-funktion kann ich mit jeder chain testen für meinen mocks ...   //ETH-Preis... interact with outside contract-> need API and ADDRESS
    {
       // beim refactoren der beiden scripte kann ich line 13 rausnehmen , DA ICH NICHT MEHR MIT EINER CHAIN ARBEITE SONDERN durch die PARAMETER möglich ist zw. blockcains zu switchen
       // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x3de1bE9407645533CD0CbeCf88dFE5297E7125e6);
       
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return uint256 (answer* 1e10);                       //typecasting zwischen uint und int für gleichen type
    }

    function Umwandlungsrate(uint256 ethMenge, AggregatorV3Interface priceFeed) internal view returns (uint256) // meine umwandlungsrate soll autom. die jeweilige network mit zugehör. contract. für eth/usd- data feed nehmen... DAHER HIER durch das refactoren den DATAFEED PARAMETRISIERT.
    {
        uint256 ethPrice = getPrice(priceFeed); // GEBEN den PRICEFEED furch refactoren als parameter in die getPrice-funktion
        uint256 ethMengeinUSD = (ethPrice * ethMenge) / 1e18;
        return ethMengeinUSD;
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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
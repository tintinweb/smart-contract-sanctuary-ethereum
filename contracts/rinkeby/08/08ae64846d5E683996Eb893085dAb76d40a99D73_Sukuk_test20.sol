// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

import "AggregatorV3Interface.sol";


// This one for now to track what each investor/ I will look at the implementation later


contract Sukuk_test20{

    struct suk_investor{
        address investoraddress;
        uint256 number_of_sukuk;
        uint256 value;
        uint256 allowed;

    }




    mapping(address => uint256) public addressToAmountFunded;
    mapping(address => uint256) public addressToAmountDeposited;
    address payable[] public investors;
    address public  admin;
    AggregatorV3Interface public priceFeed;
    address payable public Ijaara ;
    uint public suk_price;
    suk_investor[] public suk_investors;



    mapping(address => suk_investor) public investor_test;




    //Sukuk State
    enum SUKUK_STATE{
        COOLDOWN,   //This state will be when the contract is in effect however it doesn't have any tasks to excute
        OPEN,
        ISSUE,
        CLOSEED,
        
        REDEEM_PERIOD,
        TERM_1,
        TERM_2
    }
    SUKUK_STATE public sukuk_state;


    function get_suk_state() public view returns(SUKUK_STATE){
        return sukuk_state;
    }

    //function give_right_to_purchase(address Investor) public{
        //require(
         //   msg.sender == admin,
          //  "Only admin can give right to access"
       // );
        //investor_test[suk_investor].allowed = 1;


    //}









    //added an argument to constructor for testing
    constructor(
        address _priceFeed
      ) 
    public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        // Admin will be the contract sender for now
        admin = msg.sender;
        sukuk_state = SUKUK_STATE.CLOSEED;
        suk_price = 100* (10**18);

    }


    function get_expetected_price(uint256 _numberOfSukuk) public view returns (uint256 exptectedPrice) {
        uint256 _suk_price = getEntranceFee();
        uint256  Price = _suk_price * _numberOfSukuk;

        return Price;
        
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        // $50, $2,000 / ETH
        // 50/2,000
        // 50 * 100000 / 2000
        uint256 costToEnter = (suk_price * 10**18) / adjustedPrice;
        return costToEnter;
    }




    function     startSukuk( ) public onlyAdmin{
            require(
            sukuk_state == SUKUK_STATE.CLOSEED,
            "Can't issue new suks yet"
        );





        sukuk_state = SUKUK_STATE.OPEN;

    }
    




    function  IssueSukuk( ) public onlyAdmin{
        require(
            sukuk_state == SUKUK_STATE.OPEN,
            "Can't issue new suks yet"
        );

        sukuk_state = SUKUK_STATE.ISSUE;

    }

    function EndIssue() public onlyAdmin{
        require(
            sukuk_state == SUKUK_STATE.ISSUE,
            "Test"
        );

        sukuk_state = SUKUK_STATE.COOLDOWN;
    }

    function startRedeem() public onlyAdmin{
        require(
            sukuk_state == SUKUK_STATE.COOLDOWN,
            "Test"
        );

        sukuk_state = SUKUK_STATE.REDEEM_PERIOD;
    }





    

    function purchase_suk(uint256 _number_of_sukuk) public payable{



        // Right now it only tracks the amount and address only.
        // Later I will need to take the number of sukuk as a factor and change how it works
        // It should take the number of sukuk and checks if the sent amount is correct or not 
        // Not lower or higher


        //suk_investor memory new_investor = msg.sender;
        uint expectedPrice = get_expetected_price(_number_of_sukuk);
        require(
            expectedPrice <= msg.value,
            "Send the correct amount of eth"
        );


       // new_investor.investoraddress = msg.sender;
        //new_investor.number_of_sukuk = _number_of_sukuk;
       // new_investor.value = msg.value;


       // suk_investors.push(new_investor);







        suk_investors.push(suk_investor(msg.sender,_number_of_sukuk,msg.value,1));
       // investors.push(payable(msg.sender));
    }




    function setIjaara(address payable  _Ijaara ) public onlyAdmin{
        Ijaara = _Ijaara;
        
    }








    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }

    modifier onlyIjaara(){
        require(msg.sender == Ijaara);
        _;
    }



    function getAdminAddress( ) view public returns (address ) {

        return admin;
    }
    function getIjaaraAddress( ) view public returns (address ) {
        return Ijaara;
    }

    function withdraw() public payable onlyIjaara{
        msg.sender.transfer(address(this).balance);

       /* for (
            uint256 funderIndex = 0;
            funderIndex < investors.length;
            funderIndex++
        ) {
            address funder = investors[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
    */
    }

    //function redeem() public payable{}

    function deposit() public payable onlyIjaara{
        addressToAmountDeposited[msg.sender] +=  msg.value;

    }
    function getBalance( ) view public returns (uint256 balance) {
        return address(this).balance;
        
    }


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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
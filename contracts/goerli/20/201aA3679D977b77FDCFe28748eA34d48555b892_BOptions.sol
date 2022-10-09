//// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./pricechainlinkoracles.sol";

contract BOptions{
    // DAI on goerli 
       IERC20 public DAI = IERC20(0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60);
      ETHPriceConsumerV3 public ETHUSD = ETHPriceConsumerV3(0xdC5A5516f1e044722076550FB38eE43B872104f3);
      BTCPriceConsumerV3 public BTCUSD = BTCPriceConsumerV3(0x0a8B62Eb1F9fD026A6192fcE2560217Ff51BbC9d);
      DAIPriceConsumerV3 public DAIUSD = DAIPriceConsumerV3(0xe64c89eC0b66278871bfA599CB57649e0F205AC3);

    event Placebet(address indexed player, bet indexed newoption);
    event SettleOption(address indexed player, bet indexed betinfo,bool wonorlost);
    enum Status {nobet,beton,won,lost}
    enum Instrument {ETH,WBTC}

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
    }
    
    address public constant owner = 0x78351284f83A52b726aeEe6C2ceBBe656124434c;
    mapping (address => bet[]) public Accountbets;

    receive() external payable{}

    function withdrawDAI(uint amount) external returns(bool){
        require(msg.sender == owner &&  amount <= getDAIbalance(),"you arent the owner");
        bool txn = DAI.transfer(payable(msg.sender),amount * 1e18);
        return txn;
    }

    function withdrawETH(uint amount) external  {
        require(msg.sender == owner && amount <= address(this).balance);
        payable(owner).transfer(amount);
    }
    
    function getDAIbalance() public view returns(uint){
        return DAI.balanceOf(address(this)) / 1000000000000000000;
    }

    function getprices() public view returns(int , int , int ) {
        int ethusd = ETHUSD.getLatestPrice();
        int btcusd = BTCUSD.getLatestPrice();
        int daiusd = DAIUSD.getLatestPrice();

        return (ethusd,btcusd,daiusd);
    }

    function getaccountoptionslength(address account) public view returns (uint) {
        return Accountbets[account].length;
    }


        // returns a mutiplier like 1.8x (odds)
        // all this k , p will be calculated in JS , because 5/3 is 1 in solidity, 1.666667 in JS so represented as 18 instead of 1.8
    function rewardmultiplier(uint _id, address _staker) public view returns(uint,int){

        bet[] memory betinfos = Accountbets[_staker];
        bet memory betinfo = betinfos[_id];

        // require( betinfo.betstatus == Status.beton);
            
        uint _stake = betinfo.stake; // in eth sent while writing option
        
        
        (int _ethusd, int _btcusd, int _daiusd) = getprices();

        int latestprice = betinfo.instrument == Instrument.ETH ? _ethusd : _btcusd ;
  
        uint _stakeinDAI = uint(int(_stake) * _ethusd  /_daiusd );
        
        uint[2] memory pk_values = multipliers(_id);
        uint _reward = pk_values[0] * pk_values[1] * _stakeinDAI;

        return (_reward,latestprice);

        // uint _stakeinDAImultiplied =  ) ;
        // uint gainDAI = (_reward - (_stake * k * p * uint(_ethusd)  /uint(_daiusd))) / 1e23 ;
        
    }

    function multipliers(uint id) public view returns (uint[2] memory) {
        bet[] memory betinfos = Accountbets[msg.sender];
        bet memory betinfo = betinfos[id];

        (int _ethusd, int _btcusd,) = getprices();

        int latestprice = betinfo.instrument == Instrument.ETH ? _ethusd : _btcusd ;

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
        
        // k and p are computed in front end and passes inside the settleoption() function.
        // k is a constant that depends on price change percentage when option expires, has three tiers of reward drops depending on the % price change.
        // p is a constant that depends on hours of your option expiry, drops the reward multiplier by 1 % every hour.


        // uint hourspassed = (betinfo.timestamp - betinfo.expiry) / 3600 ; and for looping the rewarddrop of 1 % for no of hourspassed to get value of p, better to do with JS.
        // for every hour you will get droupped to 0.99x of your prev hour rewards, so for a option with expiry of 24 hours, you would have 0.7856x comparing to  option with < 1 hour expiry.
        

        // if the instrument is volatile i.e; > 5% change within your expiration time, your return rate will go from 2x to 1.6x that is 60% gain, 
        // note that k will get multiplied by p that depends on hours of your expiration. 0x6f617c6aD46EBBDbA42fd1B2f6BC2E51c38906d4
         // this will get multiplied with your staked amount, reward be like (1.74x * $100) if you win.    
        
    }


    function writeOption(Instrument instrument, uint amount,bool longorshort) external payable {
        require( msg.value < (msg.sender).balance,"insuffficient eth, get some from faucet");  
        require( amount <= msg.value,"amount sent is not matching the input" );

        uint id = Accountbets[msg.sender].length ;      
        uint timestamp = block.timestamp;
        uint optionexpiration = 0;  
     
        // if (instrument == "ETH"){ int strikeprice = GetEthprice();} else { int strikeprice = GetBtcprice();}

        (int _ethusd, int _btcusd,) = getprices();
        int strikeprice = instrument == Instrument.ETH ? _ethusd : _btcusd ;

        bet memory newoption = bet( id, instrument, amount, strikeprice , timestamp, optionexpiration,0, Status.beton, longorshort);
        Accountbets[msg.sender].push(newoption);

        emit Placebet(msg.sender,newoption);
    }   


    function settleOption( uint id) external {
        bet[] memory mybets = Accountbets[msg.sender];
        require(block.timestamp >=  mybets[id].timestamp +  5400 ,"can settle the option now,can only after 90 minutes opened");
        require( mybets[id].betstatus == Status.beton && mybets[id].expiredat == 0,
                    "cant settle the option (expired already)/ invalid id entered");
        
        bet[] storage betinfos = Accountbets[msg.sender];
        bet storage betinfo = betinfos[id];
        
        (uint _reward,int latestprice) = rewardmultiplier(id, msg.sender);

        bool wonorlost;

        if (betinfo.longorshort == true) {
            latestprice >= betinfo.strikeprice  ? wonorlost = true : wonorlost = false ; 
        }else {
            latestprice <= betinfo.strikeprice  ? wonorlost = true : wonorlost = false ; 
        }

        wonorlost ? betinfo.betstatus = Status.won : betinfo.betstatus = Status.lost ;
        betinfo.expiredat = block.timestamp;

        

        if (wonorlost) {
            betinfo.reward = _reward ;
            bool txn = DAI.transfer(msg.sender,_reward * 1e18/1e21);
            require(txn,"settling option failed");
        }

        emit SettleOption(msg.sender,betinfo,wonorlost);
        
    }


}

//0xbabc7A0cE506a581560c14427E5fcC88deD93Dc0 
//0x80A2fbB8B274Ca9Ca602fA94f6d27F6a3DDAD3fE - 
//0x54b5736E9bB7de66A6802fC1d1dA2e931d9fF4f8 - 
//0xd976930C9C95b2F12E97EDd03945e678546e0FA6 - 
//0x3731592bE4DEC5EEe5E54E050f280256B14598d2 - 
//0xe75ef987FD76c695D12a313E70EcD0C8Fe54a525 - 
//0x201aA3679D977b77FDCFe28748eA34d48555b892 = l

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ETHPriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
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


contract BTCPriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);
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
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x0d79df66BE487753B02D015Fb622DED7f0E9798d);
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

    //   IERC20 public DAI = IERC20(0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60);
    //   ETHPriceConsumerV3 public ETHUSD = ETHPriceConsumerV3(0xdC5A5516f1e044722076550FB38eE43B872104f3);
    //   BTCPriceConsumerV3 public BTCUSD = BTCPriceConsumerV3(0x0a8B62Eb1F9fD026A6192fcE2560217Ff51BbC9d);
    //   DAIPriceConsumerV3 public DAIUSD = DAIPriceConsumerV3(0xe64c89eC0b66278871bfA599CB57649e0F205AC3);

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
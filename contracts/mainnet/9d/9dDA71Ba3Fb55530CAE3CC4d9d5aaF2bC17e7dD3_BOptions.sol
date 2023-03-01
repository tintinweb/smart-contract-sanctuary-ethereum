/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract BOptions{
    // DAI address
    IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ETHPriceConsumerV3 public ETHUSD = ETHPriceConsumerV3(0xF92F490703761E21094FbB950F894C1e70e3Cfc1);
    BTCPriceConsumerV3 public BTCUSD = BTCPriceConsumerV3(0xAa5778eDc3DffF92e20Fb0F3746BbcE9A9b2670A);
    DAIPriceConsumerV3 public DAIUSD = DAIPriceConsumerV3(0x3e30b8F8Eb155383d0B3f031958Fb7373A37Ec80);

    event Placebet(address indexed player, bet indexed newoption);
    event SettleOption(address indexed player, bet indexed betinfo,bool wonorlost);

    enum Status { nobet, beton, won, lost }
    enum Instrument { ETH, WBTC }

    struct bet {
        uint id;
        Instrument instrument;
        uint stake;
        int strikeprice;
        uint timestamp;
        uint expiredat;
        uint reward;
        Status betstatus; // enum
        bool longorshort; // true if long 
    }

    address public constant owner = 0x0BcDa3524F0BDd07525Ab0Ad88C608ad850a3EA7;
    mapping(address => bet[]) public Accountbets;

    receive() external payable {}

    function withdrawDAI(uint amount) external returns(bool) {
        require(msg.sender == owner, "You are not the owner");
        require(amount <= getDAIbalance(), "Not enough DAI balance");
        bool txn = DAI.transfer(payable(msg.sender), amount * 1e18);
        require(txn, "Withdrawal of DAI failed");
        return true;
    }

    function withdrawETH(uint amount) external {
        require(msg.sender == owner, "You are not the owner");
        require(amount <= address(this).balance, "Not enough ETH balance");
        payable(owner).transfer(amount);
    }

    function getDAIbalance() public view returns(uint) {
        return DAI.balanceOf(address(this)) / 1e18;
    }

    function getprices() public view returns(int, int, int) {
        int ethusd = ETHUSD.getLatestPrice();
        int btcusd = BTCUSD.getLatestPrice();
        int daiusd = DAIUSD.getLatestPrice();

        return (ethusd, btcusd, daiusd);
    }

    function getaccountoptionslength(address account) public view returns(uint) {
        return Accountbets[account].length;
    }

    // Returns a multiplier like 1.8x (odds)
    // All this k, p will be calculated in JS, because 5/3 is 1 in Solidity, 1.666667 in JS, so represented as 18 instead of 1.8
    function rewardmultiplier(uint _id, address _staker) public view returns(uint,int){
        bet[] memory betinfos = Accountbets[_staker];
        require(_id < betinfos.length, "Invalid bet ID");

        bet memory betinfo = betinfos[_id];
        require(betinfo.betstatus == Status.beton, "The option is not currently active");

        uint _stake = betinfo.stake; // in ETH sent while writing option

        (int _ethusd, int _btcusd, int _daiusd) = getprices();

        int latestprice = betinfo.instrument == Instrument.ETH ? _ethusd : _btcusd;

        uint _stakeinDAI = uint(int(_stake) * _ethusd / _daiusd);

        uint[2] memory pk_values = multipliers(_id);
        uint _reward = pk_values[0] * pk_values[1] * _stakeinDAI;

        return (_reward, latestprice);
    }

    function multipliers(uint id) public view returns (uint[2] memory) {
        bet[] memory betinfos = Accountbets[msg.sender];
        require(id < betinfos.length, "Invalid bet ID");

        bet memory betinfo = betinfos[id];

        (int _ethusd, int _btcusd, ) = getprices();

        int latestprice = betinfo.instrument == Instrument.ETH ? _ethusd : _btcusd;

        uint[2] memory pk_values ;
        uint p = 100; // hours elapsed constant
        uint k; // price change constant

        uint hourselapsed = (block.timestamp - betinfo.timestamp) / 3600;

        for (uint i = 0; i < hourselapsed; i++) {
            p = p * 99 / 100;
        }

        int strikeprice = betinfo.strikeprice;

        uint pricechange = uint((latestprice - strikeprice) / latestprice) * 100;

        if (pricechange < 1) {
            k = 20;
        } else if(pricechange >= 1 && pricechange < 4) {
            k = 18;
        } else {
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

    function writeOption(Instrument instrument, uint amount, bool longorshort) external payable {
        require(msg.value < (msg.sender).balance, "Insufficient ETH");
        require(amount <= msg.value, "Amount sent does not match the input");

        uint id = Accountbets[msg.sender].length;
        uint timestamp = block.timestamp;
        uint optionexpiration = 0;

        (int _ethusd, int _btcusd, ) = getprices();
        int strikeprice = instrument == Instrument.ETH ? _ethusd : _btcusd;

        bet memory newoption = bet(id, instrument, amount, strikeprice, timestamp, optionexpiration, 0, Status.beton, longorshort);
        Accountbets[msg.sender].push(newoption);

        emit Placebet(msg.sender, newoption);
    }

    // The function settleOption() now takes two additional arguments, k and p.
    // Both should be calculated on the front end before calling this function.
    function settleOption(uint id, uint k, uint p) external {
        bet[] storage betinfos = Accountbets[msg.sender];
        require(id < betinfos.length, "Invalid bet ID");

        bet storage betinfo = betinfos[id];

        require(betinfo.betstatus == Status.beton && betinfo.expiredat == 0, "The option has already expired or is not currently active");

        (uint _reward, int latestprice) = rewardmultiplier(id, msg.sender);

        bool wonorlost;

        if (betinfo.longorshort == true) {
            latestprice >= betinfo.strikeprice ? wonorlost = true : wonorlost = false; 
        } else {
            latestprice <= betinfo.strikeprice ? wonorlost = true : wonorlost = false; 
        }

        betinfo.betstatus = wonorlost ? Status.won : Status.lost;
        betinfo.expiredat = block.timestamp;

        if (wonorlost) {
            _reward = _reward * k * p / 1e6;
            bool txn = DAI.transfer(msg.sender, _reward * 1e18 / 1e21);
            require(txn, "Settling option failed");
            betinfo.reward = _reward;
        }

        emit SettleOption(msg.sender, betinfo, wonorlost);
    }

}


pragma solidity ^0.8.7;

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


pragma solidity ^0.8.7;

contract ETHPriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Ethereum
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
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
     * Network: Ethereum
     * Aggregator: BTC/USD
     * Address: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
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
        priceFeed = AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
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
pragma solidity ^0.8.7;

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
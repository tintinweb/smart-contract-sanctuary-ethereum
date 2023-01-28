/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * Interface to communicate with aggregator oracles in Chainlink
 * https://docs.chain.link/getting-started/consuming-data-feeds
 */
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

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor(address _owner) {
        owner = _owner;
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }
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
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function decimals() external view returns (uint8);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
 * Staking smart contract interface
 */
interface IEVEOTCStakes {
    function getSmartDiscount(address user) external view returns (uint8, uint8);
}

/**
 * Token Handler for Trades
 *
 * There are three types of tokens depending on how do they get their USD price:
 * 
 * 1) Using a chainlink aggregator (this is the preferred option, because it is cheap and is included by default in the chainlink oracles system)
 * 2) Using a custom chainlink oracle, this is the most expensive option because the system will be charged 0.1 LINK for every query to the 
 *    external (CoinMarketCap) API
 * 3) The system admin or token owner can set the price of the token manually
 *
 * The system also differenciate user tokens (added by end users) from system tokens (added by system administrator)
 *
 * User tokens price is always manually set
 *
 */
contract EVEOTCTokens is Owner, ReentrancyGuard {

    // Token Object for coins available in the system
    // This tokens are added by admins
    struct Token {
        address token;                  // the token address
        uint256 cmc_index;              // coinmarketcap api index
        address chanlink_aggregator;    // chainlink oracle
        uint256 manual_entry_price;     // price if set manually, minimum price has to be > 0
        uint256 last_update;            // last update
        uint256 last_price;             // last price
    }

    // Total set of tokens
    Token[] public tokens;
    uint256 public tokens_length;

    // the index of the token in the tokens array
    // the if the value is 0 means it does not exists, if the value is > 0 then the index is token_indexes_plus1[address] - 1
    // this is useful to avoid looping the tokens array to find the index of an existing token
    mapping (address => uint256) internal token_indexes_plus1;

    // system tokens list if they are enabled or not
    mapping (address => bool) public tokens_enabled;

    // Token Object for coins available in the system
    // This tokens are added by regular users
    struct UserToken {
        address token;              // the token address
        address owner;              // the first user that added this token
        uint256 manual_entry_price; // price if set manually
        uint256 last_update;        // last update
    }

    // external chainlink custom API manager (used to connect with coinmarketcap)
    address public oracle_api;

    OTCChainLinkOracle oracleAPIContract;

    event USDPriceCustomAPI(address token, uint256 price);
    event USDPriceAggregator(address token, uint256 price);
    event USDPriceManualEntry(address token, uint256 price);

    /**
     * @param _owner owner of the contract
     * @param _oracle_api external oracle to communicate with custom API
     */
    constructor(address _owner, address _oracle_api) 
        Owner(_owner) {
        oracle_api = _oracle_api;
        oracleAPIContract = OTCChainLinkOracle(oracle_api);
    }

    // return a regular array index from 0 to n-1
    // if the token doesn't exists it returns -1
    function token_indexes(address _add) external view returns(int index) {
        return int(token_indexes_plus1[_add]) - 1;
    }

    // set admin parameters
    function rootSet(address _oracle_api) external isOwner {
        oracle_api = _oracle_api;
        oracleAPIContract = OTCChainLinkOracle(oracle_api);
    }

    /**
     *
     * Add or replace system tokens
     * 
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     *
     * Polygon aggregagtors
     * https://docs.chain.link/docs/matic-addresses/
     *   BNB Price: 0x82a6c4AF830caa6c97bb504425f6A66165C2c26e
     *
     */
    function addTokenData(address _token, uint256 _cmc_index, address _aggregator, uint256 _price) public isOwner {
        
        require(_token != address(0), "OTC: cannot add the zero address");

        require(_cmc_index > 0 || _aggregator != address(0) || _price > 0, "OTC: cannot add a token without a pricing mechanism");

        // find the position of the token in the tokens array
        uint256 _the_index = token_indexes_plus1[_token];

        // at this point _the_index is 0 (non existing token) or token existing in the tokens array in the position _the_index + 1

        // add the token if it doesn't exists, update if it does exists
        Token memory _the_token = Token(
            _token,
            _cmc_index,
            _aggregator,
            _price,
            block.timestamp,
            _price
        );

        if (_the_index == 0) {
            tokens.push(_the_token);
            _the_index = tokens.length - 1;

            // we keep track of the token index to avoid loops in arrays
            token_indexes_plus1[_token] = tokens.length; // we need to add 1 to index, because 0 means not existing token

            tokens_length = tokens.length;
        } else {
            _the_index--; // we reduce 1 to the index because we added 1 to the token index in the lines before
            tokens[_the_index] = _the_token;
        }

        // at this point _the_index is the real position in the tokens array 

        // enable token either way, found or not
        tokens_enabled[tokens[_the_index].token] = true;

        if (_price>0) {
            emit USDPriceManualEntry(_token, _price);
        }

    }

    // enable / disable tokens
    // _i: tokens array position
    // _enabled: true or false for enabled / disabled
    function changeTokenStatus(uint256 _i, bool _enabled) external isOwner {
        tokens_enabled[tokens[_i].token] = _enabled;
    }

    // _i: tokens array position
    // _manual_entry_price: new manual price
    function changeTokenPrice(uint256 _i, uint256 _manual_entry_price) external isOwner {
        tokens[_i].manual_entry_price = _manual_entry_price;
    }

    // get the best usd price estimation without updating the chain state and without spending LINK
    function getColdUSDPrice(address _token) public view returns (uint256 price) {

        // Is a system token?
        if (tokens_enabled[_token]) {

            // find the index
            uint256 _token_index = token_indexes_plus1[_token];
            
            if (_token_index == 0) return 0; // 0 in token_indexes_plus1 means not existing token

            // if _token_index is > 0 then we need to substract 1 to get the real array position of the token in the tokens array
            _token_index--;

            // the price reference is CMC? if so return the las used custom api oracle price
            if (tokens[_token_index].cmc_index > 0) {
                return tokens[_token_index].last_price;
            // there is a chainlink oracle for this token? if so return the oracle price
            } else if (tokens[_token_index].chanlink_aggregator != address(0)) {
                return getAggregatorUSDPrice(tokens[_token_index].chanlink_aggregator);
            // default to manual entry price
            } else {
                return tokens[_token_index].manual_entry_price;
            }

        // default to 0
        } else {
            return 0;
        }

    }

    // get usd price of any token and if it is a custom oracle price get update the price from oracle (spending LINK)
    function getUSDPrice(address _token) public returns (uint256 price) {

        // Get the index of the token in the system tokens array, if exists

        // Is a system token?
        if (tokens_enabled[_token]) {

            // find the index
            uint256 _token_index = token_indexes_plus1[_token];
            
            if (_token_index == 0) return 0; // 0 in token_indexes_plus1 means not existing token

            // if _token_index is > 0 then we need to substract 1 to get the real array position of the token in the tokens array
            _token_index--;

            // the price reference is CMC? if so return the custom api oracle price
            if (tokens[_token_index].cmc_index > 0) {
                tokens[_token_index].last_price = getAPIUSDPrice(tokens[_token_index].cmc_index);
                tokens[_token_index].last_update = block.timestamp;
                emit USDPriceCustomAPI(_token, tokens[_token_index].last_price);
                return tokens[_token_index].last_price;
            // there is a chainlink oracle for this token? if so return the oracle price
            } else if (tokens[_token_index].chanlink_aggregator != address(0)) {
                tokens[_token_index].last_price = getAggregatorUSDPrice(tokens[_token_index].chanlink_aggregator);
                tokens[_token_index].last_update = block.timestamp;
                emit USDPriceAggregator(_token, tokens[_token_index].last_price);
                return tokens[_token_index].last_price;
            // default to manual entry price
            } else {
                return tokens[_token_index].manual_entry_price;
            }

        } else {
            require(false, "OTC: Token is not enabled");
        }
    }

    // get usd price of a chainlink default oracle
    function getAggregatorUSDPrice(address _aggregator) public view returns (uint256) {
        AggregatorV3Interface priceFeed;
        priceFeed = AggregatorV3Interface(_aggregator);
        (, int price,,,) = priceFeed.latestRoundData();
        // transform the price to the decimals based on the aggregator decimals function

        uint256 ret = uint(price) * (10 ** 8) / (10 ** AggregatorV3Interface(_aggregator).decimals());

        return ret;
    }

    // get usd price of a token using a custom api call
    function getAPIUSDPrice(uint256 _cmc_index) internal view returns (uint256 price) {
        return (oracleAPIContract.usd_prices(_cmc_index));
    }

}

/**
 * This is the main contract for the EVE Exchange
 */
contract EVEOTC is EVEOTCTokens {
    
    // commission to pay by liquidity providers in the provided token
    // those are percentages with two decimals, example: 50 means 0,5%, 300 means 3%
    uint32 public commission_smart_trades_sell;
    uint32 public commission_smart_trades_buy;

    // staking smart contract
    IEVEOTCStakes public stakes;

    // wallet of the owner to receive funds
    address public owner_wallet;

    /**
     * Trade offer
     */
    struct Offer {
        address owner;  // the liquidity provider
        address from;   // token on sale
        address[] to;   // tokens receiveed
        uint256 available;  // original amount
        uint256 filled;     // amount sold
        uint256 surplus;    // excess paid by the seller to cover commission expenses
        uint256 filled_surplus;  // amount of the surplus paid in commissions
        uint256 price;      // if > 0 is a custom price in USD (including 8 decimals in the value), if 0 means a market price
        uint256 discount;   // discount percentage for smart trades
        uint256 premium;    // premium percentage
        uint256 time;       // vesting duration in days
        bool    active;     // if the trade is active or not
        bool    custom_token; // if the offer is selling an unknown token
    }

    // all system offers, historical and active
    Offer[] public trades;

    // selling commission at the moment of Offer creation, per each offer index
    mapping(uint256 => uint16) public trades_commission_sell;

    event NewOffer(
        uint256 index,
        address owner,
        address from,
        address[] to,
        uint256 available,
        uint256 surplus,
        uint256 price,
        uint256 discount,
        uint256 premium,
        uint256 time,
        bool custom_token
    );

    event CancelOffer(
        uint256 offer_index,
        uint256 amount_returned,
        address owner
    );

    // Offer purchase by the buyer
    struct Purchase {
        uint256 offer_index;  // reference to Offer
        address from;         // token bought
        address to;           // token used for payment
        uint256 amount;       // total amount bought, excluding premium price
        uint256 withdrawn;    // amount withdrawn by buyer
        uint256 timestamp;
        address buyer;
        bool    paid;         // it is paid or not, if it is a smart trade is paid by default
    }

    // all purchases
    Purchase[] public smart_trades_purchases;

    event NewPurchase (
        uint256 purchase_index,
        uint256 offer_index,
        address from,
        address to,
        uint256 amount,
        uint256 total_payment,
        address buyer
    );

    event PurchaseWithdraw (
        uint256 purchase_index,
        uint256 offer_index,
        uint256 withdrawn,
        address buyer,
        address token,
        uint256 admin_commission
    );

    event NewPremium (
        uint256 purchase_index,
        uint256 offer_index,
        address from,
        address to,
        uint256 premium,
        address buyer
    );

    // emergency variable used to pause exchange activity
    bool public paused;

    /**
     * @param _owner smart contract owner
     * @param _oracle_api oracle to connect with CMC API to get prices
     */
    constructor(address _owner, address _oracle_api) EVEOTCTokens(_owner, _oracle_api) {
        owner_wallet = _owner;
    }

    /**
     * Add a system token
     */
    function addToken(address _token, uint256 _cmc_index, address _aggregator, uint256 _price) public {
        super.addTokenData(_token, _cmc_index, _aggregator, _price);
        getUSDPrice(_token);
    }

    /**
     * Set the admin wallet 
     * 
     * @param _wallet the new wallet
     *
     */
    function walletSet(address _wallet) public isOwner {
        require(_wallet != address(0), "OTC: cannot set the zero address");
        owner_wallet = _wallet;
    }

    /**
     * Set the admin commissions 
     * 
     * @param _commission_smart_trades_sell commission to charge to sellers on a smart trade
     * @param _commission_smart_trades_buy commission to charge to buyers on a smart trade
     *
     */
    function commissionSet(
        uint16 _commission_smart_trades_sell, 
        uint16 _commission_smart_trades_buy
    ) public isOwner {
        // validate that commissions are not greater than 100%
        require(_commission_smart_trades_sell <= 10000, "Smart trades seller commission cannot be greater than 100");
        require(_commission_smart_trades_buy <= 10000, "Smart trades buyer commission cannot be greater than 100");
        // update contract parameters
        commission_smart_trades_sell = _commission_smart_trades_sell;
        commission_smart_trades_buy = _commission_smart_trades_buy;
    }

    /**
     * Set the contract to use for staking
     * this will be used to determine discounts to apply
     */
    function stakingContractSet(IEVEOTCStakes _stakes) external isOwner {
        stakes = _stakes;
    }

    /**
     * Low level function to get the to array inside an offer
     */
    function trades_to_query(uint256 _index) external view returns (address[] memory to) {
        return trades[_index].to;
    }

    /**
     * Functions to get length of arrays
     */

    function trades_length() external view returns(uint256 index) { return trades.length; }

    /**
     * calculate the surplus from the seller to pay commissions
     * if the seller has a staking active then he does not pay commissions
     */

    function surplus(uint256 _available) public view returns (uint256 _surplus, uint16 _commission_sell) {
        
        // discount on commissions
        uint8 stake_discount_seller = 0;
        
        // the commission
        uint256 commission_sell = 0;

        // calculates the commission at the moment of sale, to consider if the user has an active stake / discount
        commission_sell = commission_smart_trades_sell;
        (stake_discount_seller,) = stakes.getSmartDiscount(msg.sender);

        if (stake_discount_seller > 0) {
            // if commission is 30 (%) and the discount is 50 (%) then the commission is 30 * (100 - 50) / 100 = 30 * 50 / 100 = 1500 / 100 = 15
            // if commission is 30 (%) and the discount is 10 (%) then the commission is 30 * (100 - 10) / 100 = 30 * 90 / 100 = 2700 / 100 = 27
            commission_sell = commission_sell * (100 - stake_discount_seller) / 100;
        }

        // commission is a percentage with two decimals: 50 means 0,5%
        return (_available * commission_sell / 10000, uint16(commission_sell));

    }

    /**
     *
     * Create a token sale offer
     * The seller needs to approve the amount "available" plus the commission
     * The record of the contracts will record only the available amount
     * the surplus will be stored for commission payment purposes
     *
     * @param _from token on sale
     * @param _to tokens receiveed
     * @param _available original amount for sale
     * @param _price Custom Price or Strike price
     *               If smart_trade is true, then, if > 0 is a custom price in USD (including 8 decimals in the value), if 0 means a market price
     *               If smart_trade is false, then this is the strike price
     * @param _discount discount percentage for smart trades
     * @param _premium premium percentage or premium price, depending if it is a smart trade or not
     * @param _time vesting duration in seconds or expiration day
     *              If smart_trade is true, then this is the vesting duration in seconds
     *              If smart_trade is false, then this is an expiration date / time
     *
     */
    function addOffer(address _from, address[] memory _to, uint256 _available, uint256 _price, uint256 _discount, 
                      uint256 _premium, uint256 _time) external nonReentrant isNotPaused {

        require(_available > 0, "OTC: Offer has to be greater than 0");
        require(_discount < 100, "OTC: discount has to be lower than 100");

        // validate all tokens, token for selling has to be a system token, or a custom token with a price set
        require(tokens_enabled[_from] || (_from != address(0) && _price > 0), "OTC: Token on sale is not enabled");

        // If the token is not enable it means it is a custom token
        bool is_a_custom_token = !tokens_enabled[_from];

        for (uint256 i; i < _to.length; i++) {
            require(tokens_enabled[_to[i]], "OTC: Payment token is not enabled");
        }

        // calculate the surplus from the seller to pay commissions
        (uint256 _surplus, uint16 _commission_sell) = surplus(_available);

        // lock the funds of the offer plus the surplus to pay commissions to admin
        require(IERC20(_from).transferFrom(msg.sender, address(this), _available + _surplus), "OTC: error transfering token funds");

        // add the offer to the record list
        trades.push(Offer(msg.sender, _from, _to, _available, 0, _surplus, 0, _price, _discount, _premium, _time, true, is_a_custom_token));

        // add the offer index to all mappings
        uint256 index = trades.length - 1;

        // keep track of the original commissions
        trades_commission_sell[index] = _commission_sell;
        
        emit NewOffer(index, msg.sender, _from, _to, _available, _surplus, _price, _discount, _premium, _time, is_a_custom_token);

    }

    /**
     * Cancel an existing offer and return the funds to the owner
     * @param _index the index in the offer array
     */
    function cancelTrade(uint256 _index) external nonReentrant {

        // validate owner of the trade
        require(trades[_index].owner == msg.sender, "OTC: caller is not the owner of the trade");

        require(trades[_index].active, "OTC: trade is already canceled");

        // return remaining amount + surplus
        uint256 amount_returned = trades[_index].available - trades[_index].filled + trades[_index].surplus - trades[_index].filled_surplus;
        if (amount_returned > 0) {
            require(IERC20(trades[_index].from).transfer(msg.sender, amount_returned), "OTC: error canceling offer");
        }

        trades[_index].active = false;

        emit CancelOffer(_index, amount_returned, msg.sender);

    }

    /**
     * Validate if there is enough amount and that the payment token is included in an offer
     */
    function validateTrade(uint256 _index, address _to, uint256 _amount) internal view {

        // validate that this amount is under the limits available of the offer
        require(trades[_index].available - trades[_index].filled >= _amount, "OTC: not enough amount in the offer");

        // validate that this token is valid
        bool token_found = false;
        for (uint256 i; i < trades[_index].to.length; i++) {
            if (trades[_index].to[i] == _to) {
                token_found = true;
                break;
            }
        }

        require(token_found, "OTC: token not found in the selected offer");

    }

    /**
     *
     * Estimate the total payment for a smart trade, considering the usd price and decimal numbers of each token
     *     @param _index: index in the trades array
     *     @param _to: address of the token used for payment, must be previously approved
     *     @param _sell_token_price: the price in USD of the token being sold
     *     @param _pay_token_price: the price in USD of the token used for payments
     *     @param _amount: amount to buy
     *
     * Returns a pair with the total payment and the commission to pay
     *
     */
    function calculateTotalPayment(uint256 _index, address _to, uint256 _sell_token_price, uint256 _pay_token_price, uint256 _amount) 
        internal view returns(uint256 total_payment) {

        // avoid division by zero if price is zero
        if (_pay_token_price == 0) return 0;

        uint256 sell_token_discount_price = _sell_token_price;
        
        // substract a discount to the price
        if (trades[_index].discount > 0) {
            sell_token_discount_price -= ((_sell_token_price * trades[_index].discount) / 100);
        // add a premium to the price
        } else if (trades[_index].premium > 0) {
            sell_token_discount_price += ((_sell_token_price * trades[_index].premium) / 100);
        }

        uint256 _total_payment = (_amount * sell_token_discount_price * 10 ** IERC20(_to).decimals()) / 10 ** IERC20(trades[_index].from).decimals() / _pay_token_price;

        // returns the estimated total payment with the calculated commission
        return _total_payment;

    }

    /**
     * Estimate the price a customer has to pay for a smart trade
     *     @param _index: index in the trades array
     *     @param _to: address of the token used for payment
     *     @param _amount: to buy
     *
     * Returns the commission and payment separately
     *
     */
    function splitEstimateSmartTrade(uint256 _index, address _to, uint256 _amount) public view returns (uint256 payment, uint256 commission) {

        // get the price of the offer and calculate the payment amount in the payment token

        // it is a custom price in USD?
        uint256 sell_token_price = 0;
        if (trades[_index].price > 0) {
            // take this as a reference price of the selling token
            sell_token_price = trades[_index].price;
        // it is not a custom price?
        } else {
            // get the price in USD of the selling soken
            sell_token_price = getColdUSDPrice(trades[_index].from);
        }

        // get the price of the payment token
        uint256 pay_token_price = getColdUSDPrice(_to);

        // calculate the payment amount
        uint256 _payment_amount = calculateTotalPayment(_index, _to, sell_token_price, pay_token_price, _amount);

        return (_payment_amount, _payment_amount * getCommissionBuySender() / 10000);

    }

    /**
     * Estimate the price a customer has to pay for a smart trade
     *     @param _index: index in the trades array
     *     @param _to: address of the token used for payment
     *     @param _amount: to buy
     */
    function estimateSmartTrade(uint256 _index, address _to, uint256 _amount) external view returns (uint256 total_payment) {
        (uint256 _payment, uint256 _commission) = splitEstimateSmartTrade(_index, _to, _amount);
        return _payment + _commission;
    }

    /**
     * A customer can buy a smart trade
     *     @param _index: index in the trades array
     *     @param _to: address of the token used for payment, must be previously approved
     *     @param _amount: to buy
     */
    function buySmartTrade(uint256 _index, address _to, uint256 _amount) external nonReentrant isNotPaused {

        // validate parameters
        validateTrade(_index, _to, _amount);

        // get the price of the offer and calculate the payment amount in the payment token

        // it is a custom price in USD?
        uint256 sell_token_price = 0;
        if (trades[_index].price > 0) {
            // take this as a reference price of the selling token
            sell_token_price = trades[_index].price;
        // it is not a custom price?
        } else {
            // get the price in USD of the selling soken
            sell_token_price = getUSDPrice(trades[_index].from);
        }

        require(sell_token_price > 0, "OTC: Cannot buy a free token");

        // get the price of the payment token
        uint256 pay_token_price = getUSDPrice(_to);

        require(pay_token_price > 0, "OTC: Cannot pay with a free token");

        // calculate the payment amount
        uint256 _total_payment = calculateTotalPayment(_index, _to, sell_token_price, pay_token_price, _amount);

        // The buyer pays 100% of the price in the selected token to the offer owner
        require(IERC20(_to).transferFrom(msg.sender, trades[_index].owner, _total_payment), "OTC: error doing the payment");

        // If the seller has to pay commissions:
        // the seller pays the commission based on the commission set at the moment of transaction
        // this is to avoid liquidity errors in case the admin changes the commission in the middle
        uint256 _admin_commission = _amount * trades_commission_sell[_index] / 10000;
        
        // the seller pays commission to the contract owner / admin
        if (_admin_commission > 0) {
            require(IERC20(trades[_index].from).transfer(owner_wallet, _admin_commission), "OTC: error paying commissions to owner");
            trades[_index].filled_surplus += _admin_commission;
        }

        // the buyer pays commission to the contract owner / admin
        require(IERC20(_to).transferFrom(msg.sender, owner_wallet, _total_payment * getCommissionBuySender() / 10000), "OTC: error paying buying commissions to owner");

        // The buyer got assigned the amount bought
        smart_trades_purchases.push(Purchase(_index, trades[_index].from, _to, _amount, 0, block.timestamp, msg.sender, true));

        // the smart trade filled amount is updated, the funds are reserved        
        trades[_index].filled += _amount;

        // if there is no more available close the active trade
        if (trades[_index].filled == trades[_index].available) {
            trades[_index].active = false;
        }

        uint256 smart_trades_purchases_index = smart_trades_purchases.length - 1;

        emit NewPurchase (
            smart_trades_purchases_index,
            _index,
            trades[_index].from, 
            _to, 
            _amount,
            _total_payment,
            msg.sender
        );

    }

    /**
     * return the maximum amount of tokens a buyer can withdraw at the moment from a smart trade
     */
    function getPurchasedWithdrawableTokens(uint256 _purchased_index) public view returns(uint256 _amount) {

        // elapsed: get the number of seconds elapsed since the purchase
        uint256 elapsed = block.timestamp - smart_trades_purchases[_purchased_index].timestamp;

        // time: get the number of seconds of the vesting
        uint256 _vesting_time = trades[smart_trades_purchases[_purchased_index].offer_index].time;

        // if elapsed time is greater than the time of vesting, get the maximum time of vesting as the elapsed time
        if (elapsed > _vesting_time) {
            elapsed = _vesting_time;
        }

        // if not vesting time, the available to withdraw is the full amount
        uint256 available = smart_trades_purchases[_purchased_index].amount;
        if (_vesting_time > 0) {
            // if vesting time, then amount available: elapsed * amount bought / time 
            available = elapsed * smart_trades_purchases[_purchased_index].amount / _vesting_time;
        }

        // minus already withdrawn
        return available - smart_trades_purchases[_purchased_index].withdrawn;

    }

    /**
     * withdraw tokens bought in smart trades (by buyer), it withdraw the available vesting amount
     */
    function getPurchasedTokens(uint256 _purchased_index) external nonReentrant isNotPaused {

        // validate that the purchase belongs to sender
        require(smart_trades_purchases[_purchased_index].buyer == msg.sender, "OTC: caller is not the buyer");

        // validate that the amount to withdraw is greater than 0
        uint256 available_to_withdraw = getPurchasedWithdrawableTokens(_purchased_index);
        require(available_to_withdraw > 0, "OTC: there are no more funds to withdraw");

        // withdraw tokens, minus admin commission
        require(IERC20(smart_trades_purchases[_purchased_index].from).transfer(msg.sender, available_to_withdraw), "OTC: error doing the withdraw");

        // update amount withdrawn
        smart_trades_purchases[_purchased_index].withdrawn += available_to_withdraw;

        emit PurchaseWithdraw (
            _purchased_index,
            smart_trades_purchases[_purchased_index].offer_index,
            available_to_withdraw,
            msg.sender,
            smart_trades_purchases[_purchased_index].from,
            0
        );

    }

    // Internal function to return the commission of the buyer considering the staking discount
    function getCommissionBuySender() internal view returns (uint256 commission_buy) {

        (, uint8 stake_discount_buyer) = stakes.getSmartDiscount(msg.sender);

        if (stake_discount_buyer > 0) {
            return commission_smart_trades_buy * (100 - stake_discount_buyer) / 100;
        } else {
            return commission_smart_trades_buy;
        }

    }

    /**************************************************************************************************
     *
     *   E M E R G E N C Y   F U N C T I O N S
     *
     **************************************************************************************************/

    /**
     * Pause smart contract trading activity
     */
    function pause() public isOwner {
        paused = true;
    }

    /**
     * Resume smart contract trading activity
     */
    function unpause() public isOwner {
        paused = false;
    }

    /**
     * modifier to check if the contract is paused
     */ 
    modifier isNotPaused() {
        require(!paused, "Smart Contract activity is paused");
        _;
    }

}

abstract contract OTCChainLinkOracle {
    mapping(uint256 => uint256) public usd_prices;
    mapping(uint256 => uint256) public usd_prices_last;
    function refreshAPIUSDPrice(uint256 _cmc_index) public {}
}
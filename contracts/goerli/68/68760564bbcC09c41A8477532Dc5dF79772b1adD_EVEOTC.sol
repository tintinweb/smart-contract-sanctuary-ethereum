/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

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
 * 
 * Stakes is an interest gain contract for ERC-20 tokens
 * 
 * assets is the ERC20 token
 * interest_rate: percentage rate
 * maturity is the time in seconds after which is safe to end the stake
 * penalization for ending a stake before maturity time
 * lower_amount is the minimum amount for creating a stake
 * 
 */
contract EVEOTCStakes is Owner, ReentrancyGuard {

    // token    
    IERC20 public asset;

    // stakes history
    struct Record {
        uint256 from;
        uint256 amount;
        bool active;
    }

    // contract parameters
    uint16 public interest_rate;    // Interest rate for users who lock funds

    // Users locked funds
    mapping(address => Record) public ledger;

    event StakeStart(address indexed user, uint256 value);
    event StakeEnd(address indexed user, uint256 value, uint256 interest);

    constructor(IERC20 _erc20, address _owner, uint16 _rate) Owner(_owner) {
        asset = _erc20;
        interest_rate = _rate;
    }
    
    function startLock(uint256 _value) external nonReentrant {
        require(!ledger[msg.sender].active, "The user already has locked funds");
        require(asset.transferFrom(msg.sender, address(this), _value));
        ledger[msg.sender] = Record(block.timestamp, _value, true);
        emit StakeStart(msg.sender, _value);
    }

    function endLock() external nonReentrant {

        require(ledger[msg.sender].active, "No locked funds found");
        
        uint256 _interest = get_gains(msg.sender);

        // check that the owner can pay interest before trying to pay
        if (asset.allowance(getOwner(), address(this)) >= _interest && asset.balanceOf(getOwner()) >= _interest) {
            require(asset.transferFrom(getOwner(), msg.sender, _interest));
        } else {
            _interest = 0;
        }

        require(asset.transfer(msg.sender, ledger[msg.sender].amount));
        ledger[msg.sender].amount = 0;
        ledger[msg.sender].active = false;
        emit StakeEnd(msg.sender, ledger[msg.sender].amount, _interest);

    }

    function stakingSet(IERC20 _asset, uint16 _rate) external isOwner {
        interest_rate = _rate;
        asset = _asset;
    }
    
    // calculate interest to the current date time
    function get_gains(address _address) public view returns (uint256) {
        uint256 _record_seconds = block.timestamp - ledger[_address].from;
        uint256 _year_seconds = 365*24*60*60;
        return _record_seconds * ledger[_address].amount * interest_rate / 100 / _year_seconds;
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

}

contract EVEOTCTokens is EVEOTCStakes {

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

    // Total set of user tokens
    UserToken[] public user_tokens;
    uint256 public user_tokens_length;

    // the index of the token in the tokens array
    // the if the value is 0 means it does not exists, if the value is > 0 then the index is token_indexes_plus1[address] - 1
    mapping (address => uint256) internal user_token_indexes_plus1;

    // user tokens list if they are enabled or not
    mapping (address => bool) public user_tokens_enabled;

    address public oracle_api;

    event USDPriceCustomAPI(address token, uint256 price);
    event USDPriceAggregator(address token, uint256 price);
    event USDPriceManualEntry(address token, uint256 price);

    constructor(IERC20 _erc20, address _owner, uint16 _rate, address _oracle_api) 
        EVEOTCStakes(_erc20, _owner, _rate) {
        oracle_api = _oracle_api;
    }

    // return a regular array index from 0 to n-1
    // if the token doesn't exists it returns -1
    function token_indexes(address _add) external view returns(int index) {
        return int(token_indexes_plus1[_add]) - 1;
    }

    function user_token_indexes(address _add) external view returns(int index) {
        return int(user_token_indexes_plus1[_add]) - 1;
    }

    // set admin parameters
    function rootSet(address _oracle_api) external isOwner {
        oracle_api = _oracle_api;
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
    function addToken(address _token, uint256 _cmc_index, address _aggregator, uint256 _price) virtual public isOwner {
        
        require(_token != address(0), "OTC: cannot add the zero address");

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

    // add user tokens
    // this tokens are added as not enabled, they need to be approved by an admin
    function addUserToken(address _token, uint256 _price) external {
        
        require(_token != address(0), "OTC: cannot add the zero address");

        // find the position of the token in the tokens array
        uint256 _the_index = user_token_indexes_plus1[_token];

        // find if the token exists
        if (_the_index > 0) return;

        // add token if not exists
        UserToken memory _the_token = UserToken(_token, msg.sender, _price, block.timestamp);

        user_tokens.push(_the_token);
        user_tokens_length = user_tokens.length;

        // we keep track of the token index to avoid loops in arrays
        user_token_indexes_plus1[_token] = user_tokens.length; // we need to add 1 to index, because 0 means not existing token

    }

    function setUserTokenPrice(
        uint256 _i, 
        uint256 _manual_entry_price
    ) external {
        require(user_tokens[_i].owner == msg.sender, "OTC: caller is not the owner of the token");
        user_tokens[_i].manual_entry_price = _manual_entry_price;
        if (_manual_entry_price>0) {
            user_tokens[_i].last_update = block.timestamp;
            emit USDPriceManualEntry(user_tokens[_i].token, _manual_entry_price);
        }
    }

    // enable / disable user tokens
    // _i: tokens array position
    // _enabled: true or false for enabled / disabled
    function changeUserTokenStatus(uint256 _i, bool _enabled) external isOwner {
        user_tokens_enabled[user_tokens[_i].token] = _enabled;
    }

    // change user owner of the user token
    // _i: tokens array position
    // _owner: new owner
    function changeUserTokenOwner(uint256 _i, address _owner) external isOwner {
        user_tokens[_i].owner = _owner;
    }

    // get the best usd price estimation without updating the chain state and without spending LINK
    function getColdUSDPrice(address _token) internal view returns (uint256 price) {

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

        // is a user token?
        } else if (user_tokens_enabled[_token]) {

            // find the index
            uint256 _user_token_index = user_token_indexes_plus1[_token];

            if (_user_token_index == 0) return 0; // 0 in token_indexes_plus1 means not existing token

            // if _user_token_index is > 0 then we need to substract 1 to get the real array position of the token in the tokens array
            _user_token_index--;

            return user_tokens[_user_token_index].manual_entry_price;

        // default to 0
        } else {
            return 0;
        }

    }

    // get usd price of any token and if it is a custom oracle price get update the price from oracle (spending LINK)
    function getUSDPrice(address _token) internal returns (uint256 price) {

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

        // is a user token?
        } else if (user_tokens_enabled[_token]) {

            // find the index
            uint256 _user_token_index = user_token_indexes_plus1[_token];

            if (_user_token_index == 0) return 0; // 0 in token_indexes_plus1 means not existing token

            // if _user_token_index is > 0 then we need to substract 1 to get the real array position of the token in the tokens array
            _user_token_index--;

            return user_tokens[_user_token_index].manual_entry_price;

        // panic!
        } else {
            require(false, "OTC: Token is not enabled");
        }
    }

    // force a hot update of the USD price
    function forceGetUSDPrice(address _token) external isOwner returns (uint256 price) {
        return getUSDPrice(_token);
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
    function getAPIUSDPrice(uint256 _cmc_index) internal returns (uint256 price) {
        OTCChainLinkOracle oracleAPIContract = OTCChainLinkOracle(oracle_api);
        oracleAPIContract.refreshAPIUSDPrice(_cmc_index);
        return (oracleAPIContract.usd_prices(_cmc_index));
    }

}

contract EVEOTC is EVEOTCTokens {
    
    // commission to pay by liquidity providers in the provided token
    uint8 public commission;

    /**
     * An offer can be a Smart Trade Offer or an Option Trade
     */
    struct Offer {
        bool smart_trade; // smart_trade = true its a Smart Trade Offer
                          // smart_trade = false its an Option Trade Offer
        address owner;  // the liquidity provider
        address from;   // token on sale
        address[] to;   // tokens receiveed
        uint256 available;  // original amount
        uint256 filled;     // amount sold
        uint256 surplus;    // excess paid by the seller to cover commission expenses
        uint256 filled_surplus;  // amount of the surplus paid in commissions
        uint256 price;      // Custom Price or Strike price
                            // If smart_trade is true, then, if > 0 is a custom price in USD (including 8 decimals in the value), if 0 means a market price
                            // If smart_trade is false, then this is the strike price
        uint256 discount_or_premium;   // discount percentage or premium price
                                       // If smart_trade is true, then this is the discount percentage
                                       // If smart_trade is false, this is the premium price
        uint256 time; // vesting duration in days or expiration day if it is 
                      // If smart_trade is true, then this is the vesting duration in days
                      // If smart_trade is false, then this is an expiration date / time
        uint8 commission;   // commission at the moment of Offer creation
                            // commission settings in the smart contract may change over time, we make commission decisions based on the settings at the time of trade creation
    }

    // all system offers, historical and active
    Offer[] public trades;

    // Owners
    mapping (address => uint256[]) public smart_trades_owners;
    mapping (address => uint256[]) public option_trades_owners;
    
    // Tokens on sale, address: token for sale
    mapping (address => uint256[]) public smart_trades_from;
    mapping (address => uint256[]) public option_trades_from;
    
    // Tokens for payment, address: token received
    mapping (address => uint256[]) public smart_trades_to;
    mapping (address => uint256[]) public option_trades_to;

    // keep track of active trades only
    uint256[] public smart_trades_active;
    uint256[] public option_trades_active;

    event NewOffer(
        uint256 index,
        bool smart_trade,
        address owner,
        address from,
        address[] to,
        uint256 available,
        uint256 surplus,
        uint256 price,
        uint256 discount_or_premium,
        uint256 time
    );

    event CancelOffer(
        uint256 offer_index,
        uint256 amount_returned,
        address owner
    );

    // Offer purchase buyer
    // If the offer is an option trade: the premium the premium paid, otherwise is zero
    struct Purchase {
        uint256 offer_index;  // reference to Offer
        address from;         // token bought
        address to;           // token used for payment
        uint256 amount;       // total amount bought, excluding premium price, if the offer is an option trade it does not include the premium price
        uint256 premium;      // if it is a purchase of an option trade then the premium is the amount paid for premium, it can be 0, not paid or full premium amount if greater than zero
        uint256 withdrawn;    // amount withdrawn by buyer
        uint256 timestamp;
        address buyer;
        bool    paid;         // it is paid or not, if it is a smart trade is paid by default
    }

    // all purchases
    Purchase[] public smart_trades_purchases;
    Purchase[] public option_trades_purchases;

    // all buyers mapping to purchases index
    mapping (address => uint256[]) public smart_trades_buyers;
    mapping (address => uint256[]) public option_trades_buyers;

    // given an offer index returns all purchases indexes
    mapping (uint256 => uint256[]) public smart_trades_offer_purchases;
    mapping (uint256 => uint256[]) public option_trades_offer_purchases;
    //       ^ offer    ^ purchases
    
    // default to 72 hours in seconds
    uint256 public option_trades_grace_period = 259200;

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
        address token
    );

    event NewPremium (
        uint256 purchase_index,
        uint256 offer_index,
        address from,
        address to,
        uint256 premium,
        address buyer
    );

    constructor(IERC20 _erc20, address _owner, uint16 _rate, uint8 _commission, address _oracle_api) 
        EVEOTCTokens(_erc20, _owner, _rate, _oracle_api) {
        commission = _commission;
    }

    function commissionSet(uint8 _commission) external isOwner {
        commission = _commission;
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

    function smart_trades_owners_length(address _add) external view returns(uint256 index) { return smart_trades_owners[_add].length; }
    function smart_trades_from_length(address _add) external view returns(uint256 index) { return smart_trades_from[_add].length; }
    function smart_trades_to_length(address _add) external view returns(uint256 index) { return smart_trades_to[_add].length; }
    function smart_trades_buyers_length(address _add) external view returns(uint256 index) { return smart_trades_buyers[_add].length; }
    function smart_trades_offer_purchases_length(uint256 _offer) external view returns(uint256 index) { return smart_trades_offer_purchases[_offer].length; }
    function smart_trades_active_length() external view returns(uint256 index) { return smart_trades_active.length; }

    function option_trades_owners_length(address _add) external view returns(uint256 index) { return option_trades_owners[_add].length; }
    function option_trades_from_length(address _add) external view returns(uint256 index) { return option_trades_from[_add].length; }
    function option_trades_to_length(address _add) external view returns(uint256 index) { return option_trades_to[_add].length; }
    function option_trades_buyers_length(address _add) external view returns(uint256 index) { return option_trades_buyers[_add].length; }
    function option_trades_offer_purchases_length(uint256 _offer) external view returns(uint256 index) { return option_trades_offer_purchases[_offer].length; }
    function option_trades_active_length() external view returns(uint256 index) { return option_trades_active.length; }

    /**
     * calculate the surplus from the seller to pay commissions
     * if the seller has a staking active then he does not pay commissions
     */
    function surplus(uint256 _available) public view returns (uint256 _surplus, uint8 _commission) {
        if (ledger[msg.sender].active) { 
            return (0, 0);
        } else {
            return (_available * commission / 100, commission);
        }
    }

    function addToken(address _token, uint256 _cmc_index, address _aggregator, uint256 _price) override public isOwner {
        super.addToken(_token, _cmc_index, _aggregator, _price);
        getUSDPrice(_token);
    }

    /**
     *
     * Create a token sale offer for both Smart and Option trades
     * The seller needs to approve the amount "available" plus the commission
     * The record of the contracts will record only the available amount
     * the surplus will be stored for commission payment purposes
     *
     * @param _smart_trade it is a smart trade or not
     * @param _from token on sale
     * @param _to tokens receiveed
     * @param _available original amount for sale
     * @param _price Custom Price or Strike price
     *               If smart_trade is true, then, if > 0 is a custom price in USD (including 8 decimals in the value), if 0 means a market price
     *               If smart_trade is false, then this is the strike price
     * @param _discount_or_premium discount percentage or premium price
     *                              If smart_trade is true, then this is the discount percentage
     *                              If smart_trade is false, this is the premium price
     * @param _time vesting duration in seconds or expiration day
     *              If smart_trade is true, then this is the vesting duration in seconds
     *              If smart_trade is false, then this is an expiration date / time
     *
     */
    function addOffer(bool _smart_trade, address _from, address[] memory _to, uint256 _available, uint256 _price, uint256 _discount_or_premium, uint256 _time) external {

        require(_available > 0, "OTC: Offer has to be greater than 0");
        if (_smart_trade) {
            require(_discount_or_premium < 100, "OTC: discount has to be lower than 100");
        }

        // validate all tokens
        require(tokens_enabled[_from] || user_tokens_enabled[_from], "OTC: Token on sale is not enabled");
        for (uint256 i; i < _to.length; i++) {
            require(tokens_enabled[_to[i]] || user_tokens_enabled[_to[i]], "OTC: Payment token is not enabled");
        }

        // calculate the surplus from the seller to pay commissions
        (uint256 _surplus, uint8 _commission) = surplus(_available);

        // lock the funds of the offer plus the surplus to pay commissions to admin
        require(IERC20(_from).transferFrom(msg.sender, address(this), _available + _surplus), "OTC: error transfering token funds");

        // add the offer to the record list
        trades.push(Offer(_smart_trade, msg.sender, _from, _to, _available, 0, _surplus, 0, _price, _discount_or_premium, _time, _commission));

        // add the offer index to all mappings
        uint256 index = trades.length - 1;
        
        // process smart trades
        if (_smart_trade) {

            smart_trades_from[_from].push(index);
            for (uint256 i; i < _to.length; i++) {
                smart_trades_to[_to[i]].push(index);
            }
            smart_trades_owners[msg.sender].push(index);

            // add active trade
            smart_trades_active.push(index);

        // process option trades
        } else {

            option_trades_from[_from].push(index);
            for (uint256 i; i < _to.length; i++) {
                option_trades_to[_to[i]].push(index);
            }
            option_trades_owners[msg.sender].push(index);

            // add active trade
            option_trades_active.push(index);

        }

        emit NewOffer( index, _smart_trade, msg.sender, _from, _to, _available, _surplus, _price, _discount_or_premium, _time);

    }

    /**
     *
     * Cancel an existing offer and return the funds to the owner
     *
     * @param _index the index in the offer array
     *
     */
    function cancelTrade(uint256 _index) external nonReentrant {

        // validate owner of the trade
        require(trades[_index].owner == msg.sender, "OTC: caller is not the owner of the trade");

        // return remaining amount + surplus
        uint256 amount_returned = trades[_index].available - trades[_index].filled + trades[_index].surplus - trades[_index].filled_surplus;
        if (amount_returned > 0) {
            require(IERC20(trades[_index].from).transfer(msg.sender, amount_returned), "OTC: error canceling offer");
        }

        // remove from active trades
        if (trades[_index].smart_trade) {
            removeSmartTradeActive(_index);
        } else {
            removeOptionTradeActive(_index);
        }

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

    /**************************************************************************************************
     *
     *
     *   S M A R T   T R A D E S
     *
     *
     **************************************************************************************************/

    /**
     * Remove the _index element from smart_trade_active array
     */
    function removeSmartTradeActive(uint256 _index) internal {
        for (uint256 i = 0; i < smart_trades_active.length; i++) {
            if (smart_trades_active[i] == _index) {
                smart_trades_active[i] = smart_trades_active[smart_trades_active.length - 1];
                smart_trades_active.pop();
                return;
            }
        }
    }

    /**
     * Estimate the total payment for a smart trade
     *     @param _index: index in the trades array
     *     @param _to: address of the token used for payment, must be previously approved
     *     @param _sell_token_price: the price in USD of the token being sold
     *     @param _pay_token_price: the price in USD of the token used for payments
     *     @param _amount: amount to buy
     */
    function calculateTotalPayment(uint256 _index, address _to, uint256 _sell_token_price, uint256 _pay_token_price, uint256 _amount) 
        internal view returns(uint256 total_payment) {

        // avoid division by zero if price is zero
        if (_pay_token_price == 0) return 0;

        /**
         * calculate the payment amount
         * 
         * Example: Buy 10 Ether (18 decimals) paying with BTC (6 decimals)
         *
         * Buy 10 * 10**18 weis paying with BTC
         * Buy 10000000000000000000 weis paying with BTC
         *
         * ETH price: 1500$ => 150000000000
         * - 10%:     1350$ => 135000000000
         * Price of ETH in $ with 8 decimals divided by price of BTC in $ with 8 decimals:
         *      135000000000 / 2000000000000 = 0,0675 BTC per Ether
         * Total payment is: 10 Ether * 0,0675 BTC per Ether = 0,675 BTC
         * 10 Ether * 10**6 * 0,0675 BTC per Ether / 10**18 = 0,675 BTC
         * 10 * 10**18 * 10**6 * 0,0675 / 10**18
         * 10 * 10**6 * 0,0675
         * 10000000 * 0,0675
         * 675000 BTC
         */ 

        // uint256 sell_token_discount_price = sell_token_price * (1 - (trades[_index].discount_or_premium / 100));

        uint256 sell_token_discount_price = _sell_token_price - ((_sell_token_price * trades[_index].discount_or_premium) / 100);
        //                                  1500              - ((1500              * 10                                  / 100)) 
        //                                  1500              - ((15000                                                   / 100)) 
        //                                  1500              - 150
        //                                  1350
        //                                  ==> 135000000000

        return (_amount   * sell_token_discount_price * 10 ** IERC20(_to).decimals()) / 10 ** IERC20(trades[_index].from).decimals() / _pay_token_price;
        //     (10x10**18 * 135000000000              * 10 ** 6                     ) / 10**18                                       / 2000000000000;
        //     (10x10**18 * 135000000000              * 1000000                     ) / 10**18                                       / 2000000000000;
        //     (10000000000000000000 * 135000000000000000                           ) / 1000000000000000000                          / 2000000000000;
        //     (1350000000000000000000000000000000000                               ) / 1000000000000000000                          / 2000000000000;
        //     (1350000000000000000                                                 )                                                / 2000000000000;
        //      135000000000000000                                                    / 2000000000000;
        //      675000
        //      ==> 0,675

    }

    /**
     * Estimate the price a customer has to pay for a smart trade
     *     @param _index: index in the trades array
     *     @param _to: address of the token used for payment, must be previously approved
     *     @param _amount: to buy
     */
    function estimateSmartTrade(uint256 _index, address _to, uint256 _amount) external view returns (uint256 total_payment) {

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
        return calculateTotalPayment(_index, _to, sell_token_price, pay_token_price, _amount);

    }

    /**
     * A customer can buy a smart trade
     *     @param _index: index in the trades array
     *     @param _to: address of the token used for payment, must be previously approved
     *     @param _amount: to buy
     */
    function buySmartTrade(uint256 _index, address _to, uint256 _amount) external nonReentrant {

        // validate parameters

        // smart trades only        
        require(trades[_index].smart_trade, "OTC: this is not a smart trade");

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

        // get the price of the payment token
        uint256 pay_token_price = getUSDPrice(_to);

        // calculate the payment amount
        uint256 total_payment = calculateTotalPayment(_index, _to, sell_token_price, pay_token_price, _amount);

        // The buyer pays 100% of the price in the selected token to the offer owner
        require(IERC20(_to).transferFrom(msg.sender, trades[_index].owner, total_payment), "OTC: error doing the payment");

        // If the seller has to pay commissions, pay in the token being sold
        // the seller pays the commission based on the commission set at the moment of transaction
        // this is to avoid liquidity errors in case the admin changes the commission in the middle
        uint256 _surplus = _amount * trades[_index].commission / 100;
        
        if (_surplus > 0) {
            require(IERC20(trades[_index].from).transfer(getOwner(), _surplus), "OTC: error paying commissions to owner");
            trades[_index].filled_surplus += _surplus;
        }

        // The buyer got assigned the amount bought
        smart_trades_purchases.push(Purchase(_index, trades[_index].from, _to, _amount, 0, 0, block.timestamp, msg.sender, true));

        // the smart trade filled amount is updated, the funds are reserved        
        trades[_index].filled += _amount;

        // if there is no more available close the active trade
        if (trades[_index].filled == trades[_index].available) {
            removeSmartTradeActive(_index);
        }

        uint256 smart_trades_purchases_index = smart_trades_purchases.length - 1;

        // update contract indexes:
        smart_trades_buyers[msg.sender].push(smart_trades_purchases_index);
        smart_trades_offer_purchases[_index].push(smart_trades_purchases_index);

        emit NewPurchase (
            smart_trades_purchases_index,
            _index,
            trades[_index].from, 
            _to, 
            _amount,
            total_payment,
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
        // trades[smart_trades_purchases[_purchased_index].offer_index].time;

        // if elapsed time is greater than the time of vesting, get the maximum time of vesting as the elapsed time
        if (elapsed > trades[smart_trades_purchases[_purchased_index].offer_index].time) {
            elapsed = trades[smart_trades_purchases[_purchased_index].offer_index].time;
        }

        // amount available: elapsed * amount bought / time 
        uint256 available = elapsed * smart_trades_purchases[_purchased_index].amount / trades[smart_trades_purchases[_purchased_index].offer_index].time;

        // minus already withdrawn
        return available - smart_trades_purchases[_purchased_index].withdrawn;

    }

    /**
     * withdraw tokens bought in smart trades (by buyer), it withdraw the available vesting amount
     */
    function getPurchasedTokens(uint256 _purchased_index) external nonReentrant {

        // smart trades only        
        require(trades[_purchased_index].smart_trade, "OTC: this is not a smart trade");

        // validate that the purchase belongs to sender
        require(smart_trades_purchases[_purchased_index].buyer == msg.sender, "OTC: caller is not the buyer");

        // validate that the amount to withdraw is greater than 0
        uint256 available_to_withdraw = getPurchasedWithdrawableTokens(_purchased_index);
        require(available_to_withdraw > 0, "OTC: there are no more funds to withdraw");

        // withdraw tokens
        require(IERC20(smart_trades_purchases[_purchased_index].from).transfer(msg.sender, available_to_withdraw), "OTC: error doing the withdraw");

        // update amount withdrawn
        smart_trades_purchases[_purchased_index].withdrawn += available_to_withdraw;

        emit PurchaseWithdraw (
            _purchased_index,
            smart_trades_purchases[_purchased_index].offer_index,
            available_to_withdraw,
            msg.sender,
            smart_trades_purchases[_purchased_index].from
        );

    }

    /**************************************************************************************************
     *
     *
     *   O P T I O N   T R A D E S
     *
     *
     **************************************************************************************************/

    /**
     * Remove the _index element from option_trades_active array
     */
    function removeOptionTradeActive(uint256 _index) internal {
        for (uint256 i = 0; i < option_trades_active.length; i++) {
            if (option_trades_active[i] == _index) {
                option_trades_active[i] = option_trades_active[option_trades_active.length - 1];
                option_trades_active.pop();
                return;
            }
        }
    }

    /**
     * Set Grace Period (admin)
     */
    function setGracePeriod(uint256 _value) external isOwner {
        option_trades_grace_period = _value;
    }

    /**
     * Get premium amount in token: given an option trade offer and a token return the premium amount in token value
     * If the token is not available in the payment options, return zero
     *     @param _index: index in the trades array
     *     @param _to: address of the token used for payment, must be previously approved
     */
    function estimatePremiumAmount(uint256 _index, address _to) external view returns (uint256 estimation) {

        // get USD price of _to
        uint256 pay_token_price = getColdUSDPrice(_to);
        if (pay_token_price == 0) return 0;

        // return premium / price
        return trades[_index].discount_or_premium * 10**IERC20(_to).decimals() / pay_token_price;

    }

    /**
     * Estimate the price a customer has to pay for buying an amount of an option and paying with the token _to
     *     @param _index: index in the trades array
     *     @param _to: address of the token used for payment, must be previously approved
     *     @param _amount: to buy
     */
    function estimateOptionTrade(uint256 _index, address _to, uint256 _amount) external view returns (uint256 total_payment) {

        // get the price of the payment token
        uint256 pay_token_price = getColdUSDPrice(_to);

        // avoid division by zero if price is zero
        if (pay_token_price == 0) return 0;

        /**
         * amount: 10 Ether
         * decimals: 18
         * strike price: 1350$
         * to: BTC
         * decimals: 6
         * BTC price: 20000$
         * total estimation:
         * 10 Ether * 1350 / 20000 = 0,675 BTC
         * 10 * 10**18 * 10**6 * 135000000000 / 2000000000000 * 10**18
         * 10 * 10**18 * 10**6 * 135000000000 / 10**18 / 2000000000000
         * 10 * 10**6 * 1350 / 20000
         * 10000000 * 1350 / 20000 = 675000
         */
        return (_amount * trades[_index].price * 10 ** IERC20(_to).decimals()) / 10 ** IERC20(trades[_index].from).decimals() / pay_token_price;

    }

    /**
     *
     * Pay Premium
     *
     * The buyer pays the premium to the seller
     * The buyer got an allocation of the available amount
     *
     *     @param _index: offer index in the trades array
     *     @param _to: address of the token used for payment, must be previously approved
     *     @param _amount: to buy
     *
     */
    function payPremium(uint256 _index, address _to, uint256 _amount) external nonReentrant {

        // option trades only        
        require(!trades[_index].smart_trade, "OTC: this is not an option trade");

        validateTrade(_index, _to, _amount);

        // Pay the premium amount
        
        uint256 pay_token_price = getUSDPrice(_to);

        require(pay_token_price > 0, "OTC: payment token price is zero");

        uint256 premium_amount = trades[_index].discount_or_premium * 10**IERC20(_to).decimals() / pay_token_price;

        // Pays the premium amount to seller
        require(IERC20(_to).transferFrom(msg.sender, trades[_index].owner, premium_amount));

        // Reserve the tokens to the buyer: open a purchase with zero withdrawn
        option_trades_purchases.push(Purchase(_index, trades[_index].from, _to, _amount, premium_amount, 0, block.timestamp, msg.sender, false));

        // update indexes
        uint256 option_trades_purchases_index = option_trades_purchases.length - 1;
        option_trades_buyers[msg.sender].push(option_trades_purchases_index);
        option_trades_offer_purchases[_index].push(option_trades_purchases_index);

        // Update the amount filled in the offer
        trades[_index].filled += _amount;

        // if there is no more available close the active trade
        if (trades[_index].filled == trades[_index].available) {
            removeOptionTradeActive(_index);
        }

        // Emit a NewPremium event
        emit NewPremium (
            option_trades_purchases_index,
            _index,
            trades[_index].from, 
            _to, 
            premium_amount,
            msg.sender
        );

    }

    /**
     * 
     * Pay an Option Trade
     *
     * The buyer can pay the option trade if it has not expired (expired is expiration date + grace time)
     * The buyer get the funds
     * The owner get commission
     * The seller get the payment
     *
     *     @param _purchase_index: purchase index
     *
     */
    function payOptionTrade(uint256 _purchase_index) external nonReentrant {

        // Requires that the sender is the buyer
        require(option_trades_purchases[_purchase_index].buyer == msg.sender, "OTC: you are not the buyer");

        // Requires that the purchase is not already filled
        require(!option_trades_purchases[_purchase_index].paid, "OTC: the order is already paid");

        // Requires that is paying in the time window
        uint256 _offer_index = option_trades_purchases[_purchase_index].offer_index;
        require(trades[_offer_index].time + option_trades_grace_period >= block.timestamp, "OTC: the payment time is expired");
        
        // Pay the seller

        address _to = option_trades_purchases[_purchase_index].to;
        uint256 pay_token_price = getUSDPrice(_to);

        /**
         * amount: 10 Ether
         * decimals: 18
         * strike price: 1350$
         * to: BTC
         * decimals: 6
         * BTC price: 20000$
         * total estimation:
         * 10 Ether * 1350 / 20000 = 0,675 BTC
         * 10 * 10**18 * 10**6 * 135000000000 / 2000000000000 * 10**18
         * 10 * 10**18 * 10**6 * 135000000000 / 10**18 / 2000000000000
         * 10 * 10**6 * 1350 / 20000
         * 10000000 * 1350 / 20000 = 675000
         */

        uint256 total_payment = (option_trades_purchases[_purchase_index].amount * trades[_offer_index].price * 10 ** IERC20(_to).decimals()) / 10 ** IERC20(trades[_offer_index].from).decimals() / pay_token_price;

        // The buyer pays 100% of the price in the selected token to the offer owner
        require(IERC20(_to).transferFrom(msg.sender, trades[_offer_index].owner, total_payment), "OTC: error doing the payment");

        // The seller pays to admin
        uint256 _surplus = option_trades_purchases[_purchase_index].amount * trades[_offer_index].commission / 100;
        
        if (_surplus > 0) {
            require(IERC20(trades[_offer_index].from).transfer(getOwner(), _surplus), "OTC: error paying commissions to owner");
            trades[_offer_index].filled_surplus += _surplus;
        }

        // Transfer the tokens to the buyer
        require(IERC20(option_trades_purchases[_purchase_index].from).transfer(msg.sender, option_trades_purchases[_purchase_index].amount), "OTC: error doing the withdraw");

        // Close the purchase: fill the withdrawn field in purchase
        option_trades_purchases[_purchase_index].paid = true;

        emit PurchaseWithdraw (
            _purchase_index,
            _offer_index,
            option_trades_purchases[_purchase_index].amount,
            msg.sender,
            option_trades_purchases[_purchase_index].from
        );

    }

}

abstract contract OTCChainLinkOracle {
    mapping(uint256 => uint256) public usd_prices;
    mapping(uint256 => uint256) public usd_prices_last;
    function refreshAPIUSDPrice(uint256 _cmc_index) public {}
}
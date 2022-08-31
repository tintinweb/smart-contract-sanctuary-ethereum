/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

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
    uint16 public commission;       // commission to pay by liquidity providers in the provided token
    uint16 public eve_commission;   // commission to pay by liquidity providers in EVE token

    // Users locked funds
    mapping(address => Record) public ledger;

    event StakeStart(address indexed user, uint256 value);
    event StakeEnd(address indexed user, uint256 value, uint256 interest);

    constructor(IERC20 _erc20, address _owner, uint16 _rate, uint16 _commission, uint16 _eve_commission) Owner(_owner) {
        asset = _erc20;
        interest_rate = _rate;
        eve_commission = _eve_commission;
        commission = _commission;
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

    function adminSet(IERC20 _asset, uint16 _rate, uint16 _commission, uint16 _eve_commission) external isOwner {
        interest_rate = _rate;
        asset = _asset;
        eve_commission = _eve_commission;
        commission = _commission;
    }
    
    // calculate interest to the current date time
    function get_gains(address _address) public view returns (uint256) {
        uint256 _record_seconds = block.timestamp - ledger[_address].from;
        uint256 _year_seconds = 365*24*60*60;
        return _record_seconds * ledger[_address].amount * interest_rate / 100 / _year_seconds;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

/*
    function callAPI(address token) public {
        OTCChainLinkOracle oracleAPIContract = OTCChainLinkOracle(oracle_api);
        oracleAPIContract.requestAPIValue(toAsciiString(token));
        token_usd_prices[token] = oracleAPIContract.value();
    }
*/

}

contract EVEOTC is EVEOTCStakes {

    // Token Object for coins available in the system
    // This tokens are added by admins
    struct Token {
        address token;                  // the token address
        uint256 cmc_index;              // coinmarketcap api index
        address chanlink_aggregator;    // chainlink oracle
        bool    manual_entry;           // price is set manually
        uint256 last_update;            // last update
        bool    enabled;                // if enabled = false, the coin was removed
    }

    // Total set of tokens
    Token[] public tokens;
    uint256 public tokens_length;

    // Token Object for coins available in the system
    // This tokens are added by regular users
    struct UserToken {
        address token;      // the token address
        address owner;      // the first user that added this token
        bool    enabled;    // if enabled = false, the coin was removed
    }

    // Total set of user tokens
    UserToken[] public user_tokens;
    uint256 public user_tokens_length;

    // Token price record
    struct TokenPrice {
        uint256 token_index;    // index in the tokens or user_tokens array
        bool    is_user;        // true: use user_tokens, false: use tokens
        uint256 price;          // Integer price in USD including eight decimal digits
    }

    // Last price in USD (token address => price in usd object)
    mapping( address => TokenPrice ) public price_usd;

    // threshold to call oracles
    uint256 public oracle_threshold; // in seconds

    constructor(IERC20 _erc20, address _owner, uint16 _rate, uint16 _commission, uint16 _eve_commission, uint256 _oracle_threshold) 
        EVEOTCStakes(_erc20, _owner, _rate, _commission, _eve_commission) {
        oracle_threshold = _oracle_threshold;
    }

    // set admin parameters
    function rootSet(uint256 _oracle_threshold) external isOwner {
        oracle_threshold = _oracle_threshold;
    }

    // add system tokens
    function addToken(address _token, uint256 _cmc_index, address _aggregator, uint256 _price) external isOwner {
        
        require(_token != address(0), "OTC: cannot add the zero address");

        uint256 _the_index = 0;

        // find if the token exists
        for (uint256 index = 0; index < tokens.length; index++) {
            // if token exists check if it is disabled, if so, enable it, otherwise finish the process
            if (tokens[index].token == _token) {
                if (tokens[index].enabled) {
                    return;
                } else {
                    tokens[index].enabled = true;
                    _the_index = index;
                    break;
                }
            }
        }

        // add the token if it doesn't exists, update if it does exists
        Token memory _the_token = Token(
            _token,
            _cmc_index,
            _aggregator,
            _price > 0,
            block.timestamp,
            true
        );

        if (_the_index == 0) {
            tokens.push(_the_token);
            _the_index = tokens.length - 1;
            tokens_length = tokens.length;
        } else {
            tokens[_the_index] = _the_token;
        }

        // at this point the token is either a reenabled token or a new one, update the price accordingly

        // the price will be given by a custom oracle
        if (_cmc_index > 0) {

            // TODO: add a chainlink custom oracle call
            price_usd[_token] = TokenPrice(
                _the_index, 
                false, 
                block.timestamp // TODO: remove this, this is just a price simulation
            );

        // the price will be given by a chainlink aggregator oracle
        } else if (_aggregator != address(0)) {

            // TODO: add a chainlink aggregator oracle call
            price_usd[_token] = TokenPrice(
                _the_index, 
                false, 
                block.timestamp // TODO: remove this, this is just a price simulation
            );

        // the price will be set manually
        } else if (_price > 0) {

            // update price manually
            price_usd[_token] = TokenPrice(_the_index, false, _price);

        // panic!, don't know what to do
        } else {
            require(false, "OTC: panic!, missing price source");
        }
    }

    // enable / disable tokens
    // _i: tokens array position
    // _enabled: true or false for enabled / disabled
    function changeTokenStatus(uint256 _i, bool _enabled) external isOwner {
        tokens[_i].enabled = _enabled;
    }

    // add user tokens
    // this tokens are added as not enabled, they need to be approved by an admin
    function addUserToken(address _token, uint256 _price) external {
        
        require(_token != address(0), "OTC: cannot add the zero address");

        // find if the token exists
        for (uint256 index = 0; index < user_tokens.length; index++) {
            // if token exists check if it is disabled, if so, enable it, otherwise finish the process
            if (user_tokens[index].token == _token) {
                return;
            }
        }

        // add token if not exists
        UserToken memory _the_token = UserToken(_token, msg.sender, false);

        user_tokens.push(_the_token);
        user_tokens_length = tokens.length;

        // update price manually
        price_usd[_token] = TokenPrice(user_tokens.length - 1, false, _price);

    }

    // enable / disable user tokens
    // _i: tokens array position
    // _enabled: true or false for enabled / disabled
    function changeUserTokenStatus(uint256 _i, bool _enabled) external isOwner {
        user_tokens[_i].enabled = _enabled;
    }

}

/*
abstract contract OTCChainLinkOracle {
    uint256 public value;
    function requestAPIValue(string memory queryToken) public virtual returns (bytes32 requestId);
}
*/
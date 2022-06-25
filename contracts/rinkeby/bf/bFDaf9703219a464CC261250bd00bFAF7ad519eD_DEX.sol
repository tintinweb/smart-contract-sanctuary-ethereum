// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IDEX.sol";
import "./ERC20.sol";
import "./Ownable.sol";

/// @title Decentralized exchange contract to buy and sell ERC20 tokens
/// @author Xenia Shape
/// @notice This contract can be used for only the most basic DEX test experiments
contract DEX is IDEX, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    /// @dev Emits when the new token was added
    event NewToken(address indexed token);
    /// @dev Emits when trade rates were updated
    event RatesUpdate(address indexed token, uint256 buyRate, uint256 sellRate);
    /// @dev Emits when tokens were bought
    event Buy(address indexed buyer, address indexed token, uint256 amount);
     /// @dev Emits when tokens were sold
    event Sale(address indexed seller, address indexed token, uint256 amount);

    error InvalidAmount(uint256 amount);
    error InvalidToken(address token);
    error TransferFailed(address to, uint256 value);

    /// @dev Ensures that token is supported by DEX
    modifier tokenExists(address token) {
        uint256 id = _tokenIds[token];
        if(
            (id == 0 && address(_tokens[id]) != token) || (id != 0 && address(_tokens[id]) == address(0))
        ) revert InvalidToken(token);
        _;
    }

    // value for performing more accurate division
    uint256 internal immutable _divisionAccuracy;
    /** percent of ETH which is sent to the owner on every tokens' sale
    for example, 50 * 1e16 = 50% */
    uint256 internal immutable _ownerFee;

    // all trading tokens
    ERC20[] internal _tokens;
    // address of token => index in _tokens array
    mapping(address => uint256) internal _tokenIds;

    // address of token => ETH-token rate
    mapping(address => uint256) internal _buyRates;
    // address of token => token-ETH rate
    mapping(address => uint256) internal _sellRates;
    // address of token => amount of buys
    mapping(address => Counters.Counter) internal _buysCounters;
    // address of token => amount of sales
    mapping(address => Counters.Counter) internal _salesCounters;

    constructor(uint256 divisionAccuracy, uint256 ownerFee) Ownable() {
        _divisionAccuracy = divisionAccuracy;
        _ownerFee = ownerFee;
    }

    /// @notice Function for adding a new token
    /// @param tokenConfig Parameters for setting up the token
    /** @dev
    Function can be called only by the contract owner.
    Function emits NewToken event.
    */
    function createToken(TokenConfig memory tokenConfig) external override onlyOwner {
        ERC20 token = new ERC20(
            tokenConfig.name,
            tokenConfig.symbol,
            tokenConfig.decimals,
            tokenConfig.initialSupply,
            address(this)
        );
        _tokens.push(token);
        _tokenIds[address(token)] = _tokens.length - 1;
        emit NewToken(address(token));
    }

    /// @notice Function for setting up buy and sell rates
    /// @param token Address of the token
    /// @param buyRateNew Buy rate
    /// @param sellRateNew Sell rate
    /** @dev
    Function can be called only by the contract owner.
    Function can be called only for the supported token.
    Function emits RatesUpdate event.
    */
    function setupRates(
        address token,
        uint256 buyRateNew,
        uint256 sellRateNew
    ) external override onlyOwner tokenExists(token) {
        _buyRates[token] = buyRateNew;
        _sellRates[token] = sellRateNew;
        emit RatesUpdate(token, buyRateNew, sellRateNew);
    }

    /// @notice Function for buying tokens
    /// @param token Address of the token
    /** @dev
    Function can be called only for the supported token.
    Function calculates the amount of tokens based on sent ETH amount and current buy rate.
    Function allows to buy tokens up to the maximum exchange amount.
    Function sends percent of received ETH to the DEX owner.
    Function emits Transfer and Buy events.
    */
    function buyTokens(address token) external payable override nonReentrant tokenExists(token){
        uint256 tokenAmount = tokensAmountToBuy(token, msg.value);
        if(tokenAmount > maxExchangeToken(token)) revert InvalidAmount(tokenAmount);
        _getToken(token).transfer(msg.sender, tokenAmount);
        _transferETH(_owner, _getOwnerFee(msg.value));
        emit Buy(msg.sender, token, tokenAmount);
        _buysCounters[token].increment();
    }

    /// @notice Function for selling tokens
    /// @param token Address of the token
    /// @param amount Amount of tokens to sell
    /** @dev
    Function can be called only for the supported token.
    Function allows to sell tokens for the ETH value up to the maximum exchange amount.
    Tokens should be approved by owner to DEX contract to be sold.
    Function emits Transfer, Approval and Buy events.
    */
    function sellTokens(address token, uint256 amount) external override nonReentrant tokenExists(token) {
        uint256 ethAmount = amount * sellRate(token);
        if(ethAmount > maxExchangeETH()) revert InvalidAmount(ethAmount);
        _getToken(token).transferFrom(msg.sender, address(this), amount);
        _transferETH(msg.sender, ethAmount);
        emit Sale(msg.sender, token, amount);
        _salesCounters[token].increment();
    }

    /// @notice Function for getting supported tokens
    /// @return Array of tokens' addresses
    /** @dev
    There is a possible contract vulnerability if used in write function: with a large number
    of tokens added, the total gas cost of the calling function may exceed the maximum block gas limit.
    Gas usage need to be measured to determine the maximum possible number of tokens supported.
    */
    function supportedTokens() public view override returns(address[] memory) {
        address[] memory tokens = new address[](_tokens.length);
        for(uint256 i=0; i < _tokens.length; i++) {
            tokens[i] = address(_tokens[i]);
        }
        return tokens;
    }

    /// @notice Function for getting ETH-token rate
    /// @param token Address of the token
    /// @return Buy rate
    function buyRate(address token) public view override tokenExists(token) returns(uint256) {
        return _buyRates[token];
    }

    /// @notice Function for getting token-ETH rate
    /// @param token Address of the token
    /// @return Sell rate
    function sellRate(address token) public view override tokenExists(token) returns(uint256) {
        return _sellRates[token];
    }

    /// @notice Function for getting amount of buys
    /// @param token Address of the token
    /// @return Amount of buys
    function buysAmount(address token) external view override tokenExists(token) returns(uint256) {
        return _buysCounters[token].current();
    }

    /// @notice Function for getting amount of sales
    /// @param token Address of the token
    /// @return Amount of sales
    function salesAmount(address token) external view override tokenExists(token) returns(uint256) {
        return _salesCounters[token].current();
    }

    /// @notice Function for getting the maximum ETH amount to be exchanged
    /// @return DEX ETH balance
    function maxExchangeETH() public view override returns(uint256) {
        return address(this).balance;
    }

    /// @notice Function for getting the maximum tokens amount to be exchanged
    /// @return DEX tokens balance
    /// @dev Function can be called only for the supported token.
    function maxExchangeToken(address token) public view override tokenExists(token) returns(uint256) {
        return _getToken(token).balanceOf(address(this));
    }

    /// @notice Function for calculating the amount of tokens to buy based on ETH amount and current buy rate.
    /// @return DEX tokens balance
    /// @dev Function can be called only for the supported token.
    function tokensAmountToBuy(
        address token,
        uint256 ethAmount
    ) public view override tokenExists(token) returns(uint256) {
        // multiply by _divisionAccuracy for better calculation accuracy
        return _accurateDiv(ethAmount, buyRate(token));
    }

    function _transferETH(address to, uint256 value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: value}("");
        if (!success) revert TransferFailed(to, value);
    }

    function _getToken(address token) internal view returns(ERC20) {
        return _tokens[_tokenIds[token]];
    }

    function _accurateDiv(uint256 dividend, uint256 divider) internal view returns(uint256) {
        // _divisionAccuracy is used to increase div accuracy
        return dividend * _divisionAccuracy / divider / _divisionAccuracy;
    }

    function _getOwnerFee(uint256 amount) internal view returns(uint256) {
        // 1e18 is used to get _ownerFee like percents
        return amount * _ownerFee / 1e18;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct TokenConfig {
    string name;
    string symbol;
    uint8 decimals;
    uint256 initialSupply;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IERC20.sol";

/// @title ERC20 contract implemented by EIP-20 Token Standard
/// @author Xenia Shape
/// @notice This contract can be used for only the most basic ERC20 test experiments
contract ERC20 is IERC20 {
    // owner => balance
    mapping(address => uint256) private _balances;
    // owner => spender => amount
    mapping(address => mapping(address => uint256)) private _allowances;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    error ZeroAddressMint();
    error ZeroAddressApprove(address owner, address spender);
    error InsufficientAllowance(uint256 value);
    error InsufficientFunds(uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 initialSupply,
        address supplyOwner
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _mint(supplyOwner, initialSupply);
    }

    /// @notice Function for getting the owner's balance
    /// @param owner Address of the account
    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    /// @notice Function for sending money to the recipient
    /// @param to Recipient's address
    /// @param value Amount to send
    /// @dev Function emits Transfer event
    function transfer(address to, uint256 value) public override returns(bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /// @notice Function for sending money from sender to the recipient
    /// @param from Sender's address
    /// @param to Recipient's address
    /// @param value Amount to send
    /// @dev Amount to send should be more than allowance
    /// @dev Function emits Transfer and Approval events
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        uint256 currentAllowance = allowance(from, msg.sender);
        if (currentAllowance != type(uint256).max) {
            if(currentAllowance < value) revert InsufficientAllowance(value);
            _approve(from, msg.sender, currentAllowance - value);
        }
        
        _transfer(from, to, value);
        return true;
    }

    /// @notice Function for approving tokens to spender
    /// @param spender Spender's address
    /// @param value Amount to approve
    /// @dev Function does not allow to approve from or to the zero address
    /// @dev Function emits Approval event
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /// @notice Function for getting the allowance
    /// @param owner Owner's address
    /// @param spender Spender's address
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @notice Function for approving tokens from owner to spender
    /// @param owner Owner's address
    /// @param spender Spender's address
    /// @param value Amount to approve
    /// @dev Function does not allow to approve from or to the zero address
    /// @dev Function emits Approval event
    function _approve(address owner, address spender, uint256 value) internal {
        if(owner == address(0)) revert ZeroAddressApprove(owner, spender);
        if(spender == address(0)) revert ZeroAddressApprove(owner, spender);
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /// @notice Function for sending money from sender to the recipient
    /// @param from Sender's address
    /// @param to Recipient's address
    /// @param value Amount to send
    /// @dev Function does not allow to send amount more than balance
    /// @dev Function emits Transfer event
    function _transfer(address from, address to, uint256 value) internal {
        if(_balances[from] < value) revert InsufficientFunds(value);
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
    }

    /// @notice Function for minting tokens to the account
    /// @param owner Address of the account to mint tokens
    /// @param value Amount to mint
    /// @dev Function does not allow to mint to the zero address
    /// @dev Function emits Transfer event
    function _mint(address owner, uint256 value) internal {
        if (owner == address(0)) revert ZeroAddressMint();
        totalSupply += value;
        _balances[owner] += value;
        emit Transfer(address(0), owner, value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Ownable contract for storing contract owner
/// @author Xenia Shape
/// @notice This contract can be used for only the most basic test experiments
contract Ownable {
    address internal _owner;

    error NotOwner();

    constructor() {
        _owner = msg.sender;
    }

    /// @dev Ensures that caller is the contract's owner
    modifier onlyOwner {
        if(msg.sender != _owner) revert NotOwner();
        _;
    } 
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../DEXStructs.sol";

interface IDEX {
    function createToken(TokenConfig memory tokenConfig) external;
    function setupRates(address token, uint256 buyRate_, uint256 sellRate_) external;
    function buyTokens(address token) external payable;
    function sellTokens(address token, uint256 amount) external;

    function supportedTokens() external view returns(address[] memory tokens);
    function buyRate(address token) external view returns(uint256);
    function sellRate(address token) external view returns(uint256);
    function buysAmount(address token) external view returns(uint256);
    function salesAmount(address token) external view returns(uint256);
    function maxExchangeETH() external view returns(uint256);
    function maxExchangeToken(address token) external view returns(uint256);
    function tokensAmountToBuy(address token, uint256 ethAmount) external view returns(uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}
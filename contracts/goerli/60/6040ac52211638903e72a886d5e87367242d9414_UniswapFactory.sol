// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UniswapExchange.sol";

interface IUniswapFactory {
    // address[] public tokenList;
    // mapping(address => address) tokenToExchange;
    // mapping(address => address) exchangeToToken;
    function launchExchange(address _token) external returns (address exchange);
    function getExchangeCount() external returns (uint256 exchangeCount);
    function tokenToExchangeLookup(address _token) external returns (address exchange);
    function exchangeToTokenLookup(address _exchange) external returns (address token);

    event ExchangeLaunch(address indexed exchange, address indexed token);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IUniswapFactory.sol";

contract UniswapExchange {
    using SafeMath for uint256;

    /// EVENTS
    event EthToTokenPurchase(address indexed buyer, uint256 indexed ethIn, uint256 indexed tokensOut);
    event TokenToEthPurchase(address indexed buyer, uint256 indexed tokensIn, uint256 indexed ethOut);
    event Investment(address indexed liquidityProvider, uint256 indexed sharesPurchased);
    event Divestment(address indexed liquidityProvider, uint256 indexed sharesBurned);

    /// CONSTANTS
    uint256 public constant FEE_RATE = 500; //fee = 1/feeRate = 0.2%

    /// STORAGE
    uint256 public ethPool;
    uint256 public tokenPool;
    uint256 public invariant;
    uint256 public totalShares;
    address public tokenAddress;
    address public factoryAddress;
    mapping(address => uint256) shares;
    IERC20 token;
    IUniswapFactory factory;

    /// MODIFIERS
    modifier exchangeInitialized() {
        require(invariant > 0 && totalShares > 0);
        _;
    }

    /// CONSTRUCTOR
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        factoryAddress = msg.sender;
        token = IERC20(tokenAddress);
        factory = IUniswapFactory(factoryAddress);
    }

    /// RECEIVE FUNCTION
    receive() external payable {}

    /// FALLBACK FUNCTION
    fallback() external payable {
        require(msg.value != 0);
        _ethToToken(msg.sender, msg.sender, msg.value, 1);
    }

    /// EXTERNAL FUNCTIONS
    function initializeExchange(uint256 _tokenAmount) external payable {
        require(invariant == 0 && totalShares == 0);
        // Prevents share cost from being too high or too low - potentially needs work
        require(msg.value >= 10000 && _tokenAmount >= 10000 && msg.value <= 5 * 10 ** 18);
        ethPool = msg.value;
        tokenPool = _tokenAmount;
        invariant = ethPool.mul(tokenPool);
        shares[msg.sender] = 1000;
        totalShares = 1000;
        require(token.transferFrom(msg.sender, address(this), _tokenAmount));
    }

    // Buyer swaps ETH for Tokens
    function ethToTokenSwap(uint256 _minTokens, uint256 _timeout) external payable {
        require(msg.value > 0 && _minTokens > 0 && block.timestamp < _timeout);
        _ethToToken(msg.sender, msg.sender, msg.value, _minTokens);
    }

    // Payer pays in ETH, recipient receives Tokens
    function ethToTokenPayment(uint256 _minTokens, uint256 _timeout, address _recipient) external payable {
        require(msg.value > 0 && _minTokens > 0 && block.timestamp < _timeout);
        require(_recipient != address(0) && _recipient != address(this));
        _ethToToken(msg.sender, _recipient, msg.value, _minTokens);
    }

    // Buyer swaps Tokens for ETH
    function tokenToEthSwap(uint256 _tokenAmount, uint256 _minEth, uint256 _timeout) external {
        require(_tokenAmount > 0 && _minEth > 0 && block.timestamp < _timeout);
        _ethToToken(msg.sender, msg.sender, _tokenAmount, _minEth);
    }

    // Payer pays in Tokens, recipient receives ETH
    function tokenToEthPayment(uint256 _tokenAmount, uint256 _minEth, uint256 _timeout, address _recipient) external {
        require(_tokenAmount > 0 && _minEth > 0 && block.timestamp < _timeout);
        require(_recipient != address(0) && _recipient != address(this));
        _tokenToEth(msg.sender, _recipient, _tokenAmount, _minEth);
    }

    // Buyer swaps Tokens in current exchange for Tokens of provided address
    function tokenToTokenSwap(
        address _tokenPurchased, // Must be a token with an attached Uniswap exchange
        uint256 _tokensSold,
        uint256 _minTokensReceived,
        uint256 _timeout
    ) external {
        require(_tokensSold > 0 && _minTokensReceived > 0 && block.timestamp < _timeout);
        _tokenToTokenOut(_tokenPurchased, msg.sender, msg.sender, _tokensSold, _minTokensReceived);
    }

    // Payer pays in exchange Token, recipient receives Tokens of provided address
    function tokenToTokenPayment(
        address _tokenPurchased,
        address _recipient,
        uint256 _tokensSold,
        uint256 _minTokensReceived,
        uint256 _timeout
    ) external {
        require(_tokensSold > 0 && _minTokensReceived > 0 && block.timestamp < _timeout);
        require(_recipient != address(0) && _recipient != address(this));
        _tokenToTokenOut(_tokenPurchased, msg.sender, _recipient, _tokensSold, _minTokensReceived);
    }

    // Function called by another Uniswap exchange in Token to Token swaps and payments
    function tokenToTokenIn(address _recipient, uint256 _minTokens) external payable returns (bool) {
        require(msg.value > 0);
        address exchangeToken = factory.exchangeToTokenLookup(msg.sender);
        require(exchangeToken != address(0)); // Only a Uniswap exchange can call this function
        _ethToToken(msg.sender, _recipient, msg.value, _minTokens);
        return true;
    }

    // Invest liquidity and receive market shares
    function investLiquidity(uint256 _minShares) external payable exchangeInitialized {
        require(msg.value > 0 && _minShares > 0);
        uint256 ethPerShare = ethPool.div(totalShares);
        require(msg.value >= ethPerShare);
        uint256 sharesPurchased = msg.value.div(ethPerShare);
        require(sharesPurchased >= _minShares);
        uint256 tokensPerShare = tokenPool.div(totalShares);
        uint256 tokensRequired = sharesPurchased.mul(tokensPerShare);
        shares[msg.sender] = shares[msg.sender].add(sharesPurchased);
        totalShares = totalShares.add(sharesPurchased);
        ethPool = ethPool.add(msg.value);
        tokenPool = tokenPool.add(tokensRequired);
        invariant = ethPool.mul(tokenPool);
        emit Investment(msg.sender, sharesPurchased);
        require(token.transferFrom(msg.sender, address(this), tokensRequired));
    }

    // Divest market shares and receive liquidity
    function divestLiquidity(uint256 _sharesBurned, uint256 _minEth, uint256 _minTokens) external {
        require(_sharesBurned > 0);
        shares[msg.sender] = shares[msg.sender].sub(_sharesBurned);
        uint256 ethPerShare = ethPool.div(totalShares);
        uint256 tokensPerShare = tokenPool.div(totalShares);
        uint256 ethDivested = ethPerShare.mul(_sharesBurned);
        uint256 tokensDivested = tokensPerShare.mul(_sharesBurned);
        require(ethDivested >= _minEth && tokensDivested >= _minTokens);
        totalShares = totalShares.sub(_sharesBurned);
        ethPool = ethPool.sub(ethDivested);
        tokenPool = tokenPool.sub(tokensDivested);
        if (totalShares == 0) {
            invariant = 0;
        } else {
            invariant = ethPool.mul(tokenPool);
        }
        emit Divestment(msg.sender, _sharesBurned);
        require(token.transfer(msg.sender, tokensDivested));
        payable(msg.sender).transfer(ethDivested);
    }

    // View share balance of an address
    function getShares(address _provider) external view returns (uint256 _shares) {
        return shares[_provider];
    }

    /// INTERNAL FUNCTIONS
    function _ethToToken(address buyer, address recipient, uint256 ethIn, uint256 minTokensOut)
        internal
        exchangeInitialized
    {
        uint256 fee = ethIn.div(FEE_RATE);
        uint256 newEthPool = ethPool.add(ethIn);
        uint256 tempEthPool = newEthPool.sub(fee);
        uint256 newTokenPool = invariant.div(tempEthPool);
        uint256 tokensOut = tokenPool.sub(newTokenPool);
        require(tokensOut >= minTokensOut && tokensOut <= tokenPool);
        ethPool = newEthPool;
        tokenPool = newTokenPool;
        invariant = newEthPool.mul(newTokenPool);
        emit EthToTokenPurchase(buyer, ethIn, tokensOut);
        require(token.transfer(recipient, tokensOut));
    }

    function _tokenToEth(address buyer, address recipient, uint256 tokensIn, uint256 minEthOut)
        internal
        exchangeInitialized
    {
        uint256 fee = tokensIn.div(FEE_RATE);
        uint256 newTokenPool = tokenPool.add(tokensIn);
        uint256 tempTokenPool = newTokenPool.sub(fee);
        uint256 newEthPool = invariant.div(tempTokenPool);
        uint256 ethOut = ethPool.sub(newEthPool);
        require(ethOut >= minEthOut && ethOut <= ethPool);
        tokenPool = newTokenPool;
        ethPool = newEthPool;
        invariant = newEthPool.mul(newTokenPool);
        emit TokenToEthPurchase(buyer, tokensIn, ethOut);
        require(token.transferFrom(buyer, address(this), tokensIn));
        payable(recipient).transfer(ethOut);
    }

    function _tokenToTokenOut(
        address tokenPurchased,
        address buyer,
        address recipient,
        uint256 tokensIn,
        uint256 minTokensOut
    ) internal exchangeInitialized {
        require(tokenPurchased != address(0) && tokenPurchased != address(this));
        address exchangeAddress = factory.tokenToExchangeLookup(tokenPurchased);
        require(exchangeAddress != address(0) && exchangeAddress != address(this));
        uint256 fee = tokensIn.div(FEE_RATE);
        uint256 newTokenPool = tokenPool.add(tokensIn);
        uint256 tempTokenPool = newTokenPool.sub(fee);
        uint256 newEthPool = invariant.div(tempTokenPool);
        uint256 ethOut = ethPool.sub(newEthPool);
        require(ethOut <= ethPool);
        UniswapExchange exchange = UniswapExchange(payable(exchangeAddress));
        emit TokenToEthPurchase(buyer, tokensIn, ethOut);
        tokenPool = newTokenPool;
        ethPool = newEthPool;
        invariant = newEthPool.mul(newTokenPool);
        require(token.transferFrom(buyer, address(this), tokensIn));
        require(exchange.tokenToTokenIn{value: ethOut}(recipient, minTokensOut));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UniswapExchange.sol";

contract UniswapFactory {
    // index of tokens with registered exchanges
    address[] public tokenList;
    mapping(address => address) tokenToExchange;
    mapping(address => address) exchangeToToken;

    event ExchangeLaunch(address indexed exchange, address indexed token);
    
    function launchExchange(address _token) public returns (address exchange) {
        require(tokenToExchange[_token] == address(0)); //There can only be one exchange per token
        require(_token != address(0) && _token != address(this));
        UniswapExchange newExchange = new UniswapExchange(_token);
        tokenList.push(_token);
        tokenToExchange[_token] = address(newExchange);

        exchangeToToken[address(newExchange)] = _token;
        emit ExchangeLaunch(address(newExchange), _token);
        return address(newExchange);
    }

    function getExchangeCount() public view returns (uint256 exchangeCount) {
        return tokenList.length;
    }

    function tokenToExchangeLookup(address _token) public view returns (address exchange) {
        return tokenToExchange[_token];
    }

    function exchangeToTokenLookup(address _exchange) public view returns (address token) {
        return exchangeToToken[_exchange];
    }
}
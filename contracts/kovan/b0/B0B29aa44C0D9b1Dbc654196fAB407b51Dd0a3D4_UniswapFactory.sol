//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./UniswapExchange.sol";
import "./interfaces/IUniswapExchange.sol";


contract UniswapFactory {

  /***********************************|
  |       Events And Variables        |
  |__________________________________*/

  event NewExchange(address indexed token, address indexed exchange);

  address public exchangeTemplate;
  uint256 public tokenCount;
  mapping (address => address) internal token_to_exchange;
  mapping (address => address) internal exchange_to_token;
  mapping (uint256 => address) internal id_to_token;

  /***********************************|
  |         Factory Functions         |
  |__________________________________*/

  function initializeFactory(address template) public {
    require(exchangeTemplate == address(0));
    require(template != address(0));
    exchangeTemplate = template;
  }
  
  function createExchange(address token) public returns (address) {
    require(token != address(0));
    require(exchangeTemplate != address(0));
    require(token_to_exchange[token] == address(0));
    UniswapExchange exchange = new UniswapExchange();
    exchange.setup(token);
    token_to_exchange[token] = address(exchange);
    exchange_to_token[address(exchange)] = token;
    uint256 token_id = tokenCount + 1;
    tokenCount = token_id;
    id_to_token[token_id] = token;
    emit NewExchange(token, address(exchange));
    return address(exchange);
  }

  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  function getExchange(address token) public view returns (address) {
    return token_to_exchange[token];
  }

  function getToken(address exchange) public view returns (address) {
    return exchange_to_token[exchange];
  }

  function getTokenWithId(uint256 token_id) public view returns (address) {
    return id_to_token[token_id];
  }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapExchange.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract UniswapExchange is ERC20 {
  using SafeMath for uint256;
  /***********************************|
  |        Variables && Events        |
  |__________________________________*/

  // Variables
  bytes32 public name;         // Uniswap V1
  bytes32 public symbol;       // UNI-V1
  uint256 public decimals;     // 18
  IERC20 token;                // address of the ERC20 token traded on this contract
  IUniswapFactory factory;     // interface for the factory that created this contract
  
  // Events
  event TokenPurchase(address indexed buyer, uint256 indexed eth_sold, uint256 indexed tokens_bought);
  event EthPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed eth_bought);
  event AddLiquidity(address indexed provider, uint256 indexed eth_amount, uint256 indexed token_amount);
  event RemoveLiquidity(address indexed provider, uint256 indexed eth_amount, uint256 indexed token_amount);


  /***********************************|
  |            Constsructor           |
  |__________________________________*/

  /**  
   * @dev This function acts as a contract constructor which is not currently supported in contracts deployed
   *      using create_with_code_of(). It is called once by the factory during contract creation.
   */
  function setup(address token_addr) public {
    require( 
      address(factory) == address(0) && address(token) == address(0) && token_addr != address(0), 
      "INVALID_ADDRESS"
    );
    factory = IUniswapFactory(msg.sender);
    token = IERC20(token_addr);
    name = 0x556e697377617020563100000000000000000000000000000000000000000000;
    symbol = 0x554e492d56310000000000000000000000000000000000000000000000000000;
    decimals = 18;
  }


  /***********************************|
  |        Exchange Functions         |
  |__________________________________*/


  /**
   * @notice Convert ETH to Tokens.
   * @dev User specifies exact input (msg.value).
   * @dev User cannot specify minimum output or deadline.
   */
  receive () external payable {
    ethToTokenInput(msg.value, 1, block.timestamp, msg.sender, msg.sender);
  }

 /**
   * @dev Pricing function for converting between ETH && Tokens.
   * @param input_amount Amount of ETH or Tokens being sold.
   * @param input_reserve Amount of ETH or Tokens (input type) in exchange reserves.
   * @param output_reserve Amount of ETH or Tokens (output type) in exchange reserves.
   * @return Amount of ETH or Tokens bought.
   */
  function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256) {
    require(input_reserve > 0 && output_reserve > 0, "INVALID_VALUE");
    uint256 input_amount_with_fee = input_amount.mul(997);
    uint256 numerator = input_amount_with_fee.mul(output_reserve);
    uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
    return numerator / denominator;
  }

 /**
   * @dev Pricing function for converting between ETH && Tokens.
   * @param output_amount Amount of ETH or Tokens being bought.
   * @param input_reserve Amount of ETH or Tokens (input type) in exchange reserves.
   * @param output_reserve Amount of ETH or Tokens (output type) in exchange reserves.
   * @return Amount of ETH or Tokens sold.
   */
  function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256) {
    require(input_reserve > 0 && output_reserve > 0);
    uint256 numerator = input_reserve.mul(output_amount).mul(1000);
    uint256 denominator = (output_reserve.sub(output_amount)).mul(997);
    return (numerator / denominator).add(1);
  }

  function ethToTokenInput(uint256 eth_sold, uint256 min_tokens, uint256 deadline, address buyer, address recipient) private returns (uint256) {
    require(deadline >= block.timestamp && eth_sold > 0 && min_tokens > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 tokens_bought = getInputPrice(eth_sold, address(this).balance.sub(eth_sold), token_reserve);
    require(tokens_bought >= min_tokens);
    require(token.transfer(recipient, tokens_bought));
    emit TokenPurchase(buyer, eth_sold, tokens_bought);
    return tokens_bought;
  }

  /** 
   * @notice Convert ETH to Tokens.
   * @dev User specifies exact input (msg.value) && minimum output.
   * @param min_tokens Minimum Tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of Tokens bought.
   */ 
  function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) public payable returns (uint256) {
    return ethToTokenInput(msg.value, min_tokens, deadline, msg.sender, msg.sender);
  }

  /** 
   * @notice Convert ETH to Tokens && transfers Tokens to recipient.
   * @dev User specifies exact input (msg.value) && minimum output
   * @param min_tokens Minimum Tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output Tokens.
   * @return  Amount of Tokens bought.
   */
  function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) public payable returns(uint256) {
    require(recipient != address(this) && recipient != address(0));
    return ethToTokenInput(msg.value, min_tokens, deadline, msg.sender, recipient);
  }

  function ethToTokenOutput(uint256 tokens_bought, uint256 max_eth, uint256 deadline, address payable buyer, address recipient) private returns (uint256) {
    require(deadline >= block.timestamp && tokens_bought > 0 && max_eth > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_sold = getOutputPrice(tokens_bought, address(this).balance.sub(max_eth), token_reserve);
    // Throws if eth_sold > max_eth
    uint256 eth_refund = max_eth.sub(eth_sold);
    if (eth_refund > 0) {
      buyer.transfer(eth_refund);
    }
    require(token.transfer(recipient, tokens_bought));
    emit TokenPurchase(buyer, eth_sold, tokens_bought);
    return eth_sold;
  }

  /** 
   * @notice Convert ETH to Tokens.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param tokens_bought Amount of tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of ETH sold.
   */
  function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) public payable returns(uint256) {
    return ethToTokenOutput(tokens_bought, msg.value, deadline, payable(msg.sender), msg.sender);
  }

  /** 
   * @notice Convert ETH to Tokens && transfers Tokens to recipient.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param tokens_bought Amount of tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output Tokens.
   * @return Amount of ETH sold.
   */
  function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) public payable returns (uint256) {
    require(recipient != address(this) && recipient != address(0));
    return ethToTokenOutput(tokens_bought, msg.value, deadline, payable(msg.sender), recipient);
  }

  function tokenToEthInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address buyer, address payable recipient) private returns (uint256) {
    require(deadline >= block.timestamp && tokens_sold > 0 && min_eth > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
    uint256 wei_bought = eth_bought;
    require(wei_bought >= min_eth);
    recipient.transfer(wei_bought);
    require(token.transferFrom(buyer, address(this), tokens_sold));
    emit EthPurchase(buyer, tokens_sold, wei_bought);
    return wei_bought;
  }

  /** 
   * @notice Convert Tokens to ETH.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_eth Minimum ETH purchased.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of ETH bought.
   */
  function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) public returns (uint256) {
    return tokenToEthInput(tokens_sold, min_eth, deadline, msg.sender, payable(msg.sender));
  }

  /** 
   * @notice Convert Tokens to ETH && transfers ETH to recipient.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_eth Minimum ETH purchased.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @return  Amount of ETH bought.
   */
  function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address payable recipient) public returns (uint256) {
    require(recipient != address(this) && recipient != address(0));
    return tokenToEthInput(tokens_sold, min_eth, deadline, msg.sender, recipient);
  }

  
  function tokenToEthOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address buyer, address payable recipient) private returns (uint256) {
    require(deadline >= block.timestamp && eth_bought > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 tokens_sold = getOutputPrice(eth_bought, token_reserve, address(this).balance);
    // tokens sold is always > 0
    require(max_tokens >= tokens_sold);
    recipient.transfer(eth_bought);
    require(token.transferFrom(buyer, address(this), tokens_sold));
    emit EthPurchase(buyer, tokens_sold, eth_bought);
    return tokens_sold;
  }

  /** 
   * @notice Convert Tokens to ETH.
   * @dev User specifies maximum input && exact output.
   * @param eth_bought Amount of ETH purchased.
   * @param max_tokens Maximum Tokens sold.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of Tokens sold.
   */
  function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) public returns (uint256) {
    return tokenToEthOutput(eth_bought, max_tokens, deadline, msg.sender, payable(msg.sender));
  }

  /**
   * @notice Convert Tokens to ETH && transfers ETH to recipient.
   * @dev User specifies maximum input && exact output.
   * @param eth_bought Amount of ETH purchased.
   * @param max_tokens Maximum Tokens sold.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @return Amount of Tokens sold.
   */
  function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address payable recipient) public returns (uint256) {
    require(recipient != address(this) && recipient != address(0));
    return tokenToEthOutput(eth_bought, max_tokens, deadline, msg.sender, recipient);
  }

  function tokenToTokenInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline,
    address buyer, 
    address recipient, 
    address payable exchange_addr) 
    private returns (uint256) 
  {
    require(deadline >= block.timestamp && tokens_sold > 0 && min_tokens_bought > 0 && min_eth_bought > 0);
    require(exchange_addr != address(this) && exchange_addr != address(0));
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
    uint256 wei_bought = eth_bought;
    require(wei_bought >= min_eth_bought);
    require(token.transferFrom(buyer, address(this), tokens_sold));
    uint256 tokens_bought = IUniswapExchange(exchange_addr).ethToTokenTransferInput{value:(wei_bought)}(min_tokens_bought, deadline, recipient);
    emit EthPurchase(buyer, tokens_sold, wei_bought);
    return tokens_bought;
  }

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr).
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_eth_bought Minimum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token_addr) bought.
   */
  function tokenToTokenSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address token_addr) 
    public returns (uint256) 
  {
    address payable exchange_addr = factory.getExchange(token_addr);
    return tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, msg.sender, exchange_addr);
  }

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
   *         Tokens (token_addr) to recipient.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_eth_bought Minimum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token_addr) bought.
   */
  function tokenToTokenTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    public returns (uint256) 
  {
    address payable exchange_addr = factory.getExchange(token_addr);
    return tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, recipient, exchange_addr);
  }

  function tokenToTokenOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address buyer, 
    address recipient, 
    address payable exchange_addr) 
    private returns (uint256) 
  {
    require(deadline >= block.timestamp && (tokens_bought > 0 && max_eth_sold > 0));
    require(exchange_addr != address(this) && exchange_addr != address(0));
    uint256 eth_bought = IUniswapExchange(exchange_addr).getEthToTokenOutputPrice(tokens_bought);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 tokens_sold = getOutputPrice(eth_bought, token_reserve, address(this).balance);
    // tokens sold is always > 0
    require(max_tokens_sold >= tokens_sold && max_eth_sold >= eth_bought);
    require(token.transferFrom(buyer, address(this), tokens_sold));
    uint256 eth_sold = IUniswapExchange(exchange_addr).ethToTokenTransferOutput{value:(eth_bought)}(tokens_bought, deadline, recipient);
    emit EthPurchase(buyer, tokens_sold, eth_bought);
    return tokens_sold;
  }

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr).
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_eth_sold Maximum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToTokenSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address token_addr) 
    public returns (uint256) 
  {
    address payable exchange_addr = factory.getExchange(token_addr);
    return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, msg.sender, exchange_addr);
  }

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
   *         Tokens (token_addr) to recipient.
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_eth_sold Maximum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToTokenTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    public returns (uint256) 
  {
    address payable exchange_addr = factory.getExchange(token_addr);
    return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, recipient, exchange_addr);
  }

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_eth_bought Minimum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (exchange_addr.token) bought.
   */
  function tokenToExchangeSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address payable exchange_addr) 
    public returns (uint256) 
  {
    return tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, msg.sender, exchange_addr);
  }

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
   *         Tokens (exchange_addr.token) to recipient.
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_eth_bought Minimum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (exchange_addr.token) bought.
   */
  function tokenToExchangeTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address recipient, 
    address payable exchange_addr) 
    public returns (uint256) 
  {
    require(recipient != address(this));
    return tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, recipient, exchange_addr);
  }

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_eth_sold Maximum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToExchangeSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address payable exchange_addr) 
    public returns (uint256) 
  {
    return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, msg.sender, exchange_addr);
  }

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
   *         Tokens (exchange_addr.token) to recipient.
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_eth_sold Maximum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToExchangeTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address recipient, 
    address payable exchange_addr) 
    public returns (uint256) 
  {
    require(recipient != address(this));
    return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, recipient, exchange_addr);
  }


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @notice Public price function for ETH to Token trades with an exact input.
   * @param eth_sold Amount of ETH sold.
   * @return Amount of Tokens that can be bought with input ETH.
   */
  function getEthToTokenInputPrice(uint256 eth_sold) public view returns (uint256) {
    require(eth_sold > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    return getInputPrice(eth_sold, address(this).balance, token_reserve);
  }

  /**
   * @notice Public price function for ETH to Token trades with an exact output.
   * @param tokens_bought Amount of Tokens bought.
   * @return Amount of ETH needed to buy output Tokens.
   */
  function getEthToTokenOutputPrice(uint256 tokens_bought) public view returns (uint256) {
    require(tokens_bought > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_sold = getOutputPrice(tokens_bought, address(this).balance, token_reserve);
    return eth_sold;
  }

  /**
   * @notice Public price function for Token to ETH trades with an exact input.
   * @param tokens_sold Amount of Tokens sold.
   * @return Amount of ETH that can be bought with input Tokens.
   */
  function getTokenToEthInputPrice(uint256 tokens_sold) public view returns (uint256) {
    require(tokens_sold > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
    return eth_bought;
  }

  /**
   * @notice Public price function for Token to ETH trades with an exact output.
   * @param eth_bought Amount of output ETH.
   * @return Amount of Tokens needed to buy output ETH.
   */
  function getTokenToEthOutputPrice(uint256 eth_bought) public view returns (uint256) {
    require(eth_bought > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    return getOutputPrice(eth_bought, token_reserve, address(this).balance);
  }

  /** 
   * @return Address of Token that is sold on this exchange.
   */
  function tokenAddress() public view returns (address) {
    return address(token);
  }

  /**
   * @return Address of factory that created this exchange.
   */
  function factoryAddress() public view returns (address) {
    return address(factory);
  }


  /***********************************|
  |        Liquidity Functions        |
  |__________________________________*/

  /** 
   * @notice Deposit ETH && Tokens (token) at current ratio to mint UNI tokens.
   * @dev min_liquidity does nothing when total UNI supply is 0.
   * @param min_liquidity Minimum number of UNI sender will mint if total UNI supply is greater than 0.
   * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total UNI supply is 0.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return The amount of UNI minted.
   */
  function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) public payable returns (uint256) {
    require(deadline > block.timestamp && max_tokens > 0 && msg.value > 0, 'UniswapExchange#addLiquidity: INVALID_ARGUMENT');
    uint256 total_liquidity = _totalSupply;

    if (total_liquidity > 0) {
      require(min_liquidity > 0);
      uint256 eth_reserve = address(this).balance.sub(msg.value);
      uint256 token_reserve = token.balanceOf(address(this));
      uint256 token_amount = (msg.value.mul(token_reserve) / eth_reserve).add(1);
      uint256 liquidity_minted = msg.value.mul(total_liquidity) / eth_reserve;
      require(max_tokens >= token_amount && liquidity_minted >= min_liquidity);
      _balances[msg.sender] = _balances[msg.sender].add(liquidity_minted);
      _totalSupply = total_liquidity.add(liquidity_minted);
      require(token.transferFrom(msg.sender, address(this), token_amount));
      emit AddLiquidity(msg.sender, msg.value, token_amount);
      emit Transfer(address(0), msg.sender, liquidity_minted);
      return liquidity_minted;

    } else {
      require(address(factory) != address(0) && address(token) != address(0) && msg.value >= 1000000000, "INVALID_VALUE");
      require(factory.getExchange(address(token)) == address(this));
      uint256 token_amount = max_tokens;
      uint256 initial_liquidity = address(this).balance;
      _totalSupply = initial_liquidity;
      _balances[msg.sender] = initial_liquidity;
      require(token.transferFrom(msg.sender, address(this), token_amount));
      emit AddLiquidity(msg.sender, msg.value, token_amount);
      emit Transfer(address(0), msg.sender, initial_liquidity);
      return initial_liquidity;
    }
  }

  /**
   * @dev Burn UNI tokens to withdraw ETH && Tokens at current ratio.
   * @param amount Amount of UNI burned.
   * @param min_eth Minimum ETH withdrawn.
   * @param min_tokens Minimum Tokens withdrawn.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return The amount of ETH && Tokens withdrawn.
   */
  function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) public returns (uint256, uint256) {
    require(amount > 0 && deadline > block.timestamp && min_eth > 0 && min_tokens > 0);
    uint256 total_liquidity = _totalSupply;
    require(total_liquidity > 0);
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_amount = amount.mul(address(this).balance) / total_liquidity;
    uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
    require(eth_amount >= min_eth && token_amount >= min_tokens);

    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    _totalSupply = total_liquidity.sub(amount);
    payable(msg.sender).transfer(eth_amount);
    require(token.transfer(msg.sender, token_amount));
    emit RemoveLiquidity(msg.sender, eth_amount, token_amount);
    emit Transfer(msg.sender, address(0), amount);
    return (eth_amount, token_amount);
  }


}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUniswapExchange {
  event TokenPurchase(address indexed buyer, uint256 indexed eth_sold, uint256 indexed tokens_bought);
  event EthPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed eth_bought);
  event AddLiquidity(address indexed provider, uint256 indexed eth_amount, uint256 indexed token_amount);
  event RemoveLiquidity(address indexed provider, uint256 indexed eth_amount, uint256 indexed token_amount);

  //  /**
  //  * @notice Convert ETH to Tokens.
  //  * @dev User specifies exact input (msg.value).
  //  * @dev User cannot specify minimum output or deadline.
  //  */
  receive () external payable;

 /**
   * @dev Pricing function for converting between ETH && Tokens.
   * @param input_amount Amount of ETH or Tokens being sold.
   * @param input_reserve Amount of ETH or Tokens (input type) in exchange reserves.
   * @param output_reserve Amount of ETH or Tokens (output type) in exchange reserves.
   * @return Amount of ETH or Tokens bought.
   */
  function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

 /**
   * @dev Pricing function for converting between ETH && Tokens.
   * @param output_amount Amount of ETH or Tokens being bought.
   * @param input_reserve Amount of ETH or Tokens (input type) in exchange reserves.
   * @param output_reserve Amount of ETH or Tokens (output type) in exchange reserves.
   * @return Amount of ETH or Tokens sold.
   */
  function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);


  /** 
   * @notice Convert ETH to Tokens.
   * @dev User specifies exact input (msg.value) && minimum output.
   * @param min_tokens Minimum Tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of Tokens bought.
   */ 
  function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);

  /** 
   * @notice Convert ETH to Tokens && transfers Tokens to recipient.
   * @dev User specifies exact input (msg.value) && minimum output
   * @param min_tokens Minimum Tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output Tokens.
   * @return  Amount of Tokens bought.
   */
  function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);


  /** 
   * @notice Convert ETH to Tokens.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param tokens_bought Amount of tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of ETH sold.
   */
  function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns(uint256);
  /** 
   * @notice Convert ETH to Tokens && transfers Tokens to recipient.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param tokens_bought Amount of tokens bought.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output Tokens.
   * @return Amount of ETH sold.
   */
  function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256);

  /** 
   * @notice Convert Tokens to ETH.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_eth Minimum ETH purchased.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of ETH bought.
   */
  function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256);

  /** 
   * @notice Convert Tokens to ETH && transfers ETH to recipient.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_eth Minimum ETH purchased.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @return  Amount of ETH bought.
   */
  function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256);

  /** 
   * @notice Convert Tokens to ETH.
   * @dev User specifies maximum input && exact output.
   * @param eth_bought Amount of ETH purchased.
   * @param max_tokens Maximum Tokens sold.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return Amount of Tokens sold.
   */
  function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);

  /**
   * @notice Convert Tokens to ETH && transfers ETH to recipient.
   * @dev User specifies maximum input && exact output.
   * @param eth_bought Amount of ETH purchased.
   * @param max_tokens Maximum Tokens sold.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @return Amount of Tokens sold.
   */
  function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr).
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_eth_bought Minimum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token_addr) bought.
   */
  function tokenToTokenSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address token_addr) 
    external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
   *         Tokens (token_addr) to recipient.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_eth_bought Minimum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token_addr) bought.
   */
  function tokenToTokenTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    external returns (uint256);


  /**
   * @notice Convert Tokens (token) to Tokens (token_addr).
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_eth_sold Maximum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToTokenSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address token_addr) 
    external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
   *         Tokens (token_addr) to recipient.
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_eth_sold Maximum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @param token_addr The address of the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToTokenTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address recipient, 
    address token_addr) 
    external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_eth_bought Minimum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (exchange_addr.token) bought.
   */
  function tokenToExchangeSwapInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address exchange_addr) 
    external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
   *         Tokens (exchange_addr.token) to recipient.
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies exact input && minimum output.
   * @param tokens_sold Amount of Tokens sold.
   * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param min_eth_bought Minimum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (exchange_addr.token) bought.
   */
  function tokenToExchangeTransferInput(
    uint256 tokens_sold, 
    uint256 min_tokens_bought, 
    uint256 min_eth_bought, 
    uint256 deadline, 
    address recipient, 
    address exchange_addr) 
    external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_eth_sold Maximum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToExchangeSwapOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address exchange_addr) 
    external returns (uint256);

  /**
   * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
   *         Tokens (exchange_addr.token) to recipient.
   * @dev Allows trades through contracts that were not deployed from the same factory.
   * @dev User specifies maximum input && exact output.
   * @param tokens_bought Amount of Tokens (token_addr) bought.
   * @param max_tokens_sold Maximum Tokens (token) sold.
   * @param max_eth_sold Maximum ETH purchased as intermediary.
   * @param deadline Time after which this transaction can no longer be executed.
   * @param recipient The address that receives output ETH.
   * @param exchange_addr The address of the exchange for the token being purchased.
   * @return Amount of Tokens (token) sold.
   */
  function tokenToExchangeTransferOutput(
    uint256 tokens_bought, 
    uint256 max_tokens_sold, 
    uint256 max_eth_sold, 
    uint256 deadline, 
    address recipient, 
    address exchange_addr) 
    external returns (uint256);


  /***********************************|
  |         Getter Functions          |
  |__________________________________*/

  /**
   * @notice external price function for ETH to Token trades with an exact input.
   * @param eth_sold Amount of ETH sold.
   * @return Amount of Tokens that can be bought with input ETH.
   */
  function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256);

  /**
   * @notice external price function for ETH to Token trades with an exact output.
   * @param tokens_bought Amount of Tokens bought.
   * @return Amount of ETH needed to buy output Tokens.
   */
  function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);

  /**
   * @notice external price function for Token to ETH trades with an exact input.
   * @param tokens_sold Amount of Tokens sold.
   * @return Amount of ETH that can be bought with input Tokens.
   */
  function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256);

  /**
   * @notice external price function for Token to ETH trades with an exact output.
   * @param eth_bought Amount of output ETH.
   * @return Amount of Tokens needed to buy output ETH.
   */
  function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256);

  /** 
   * @return Address of Token that is sold on this exchange.
   */
  function tokenAddress() external view returns (address);

  /**
   * @return Address of factory that created this exchange.
   */
  function factoryAddress() external view returns (address);


  /***********************************|
  |        Liquidity Functions        |
  |__________________________________*/

  /** 
   * @notice Deposit ETH && Tokens (token) at current ratio to mint UNI tokens.
   * @dev min_liquidity does nothing when total UNI supply is 0.
   * @param min_liquidity Minimum number of UNI sender will mint if total UNI supply is greater than 0.
   * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total UNI supply is 0.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return The amount of UNI minted.
   */
  function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);

  /**
   * @dev Burn UNI tokens to withdraw ETH && Tokens at current ratio.
   * @param amount Amount of UNI burned.
   * @param min_eth Minimum ETH withdrawn.
   * @param min_tokens Minimum Tokens withdrawn.
   * @param deadline Time after which this transaction can no longer be executed.
   * @return The amount of ETH && Tokens withdrawn.
   */
  function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) internal _balances;
  mapping (address => mapping (address => uint256)) internal _allowed;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  uint256 internal _totalSupply;

  /**
    * @dev Total number of tokens in existence
    */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return A uint256 representing the amount owned by the passed address.
    */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  /**
    * @dev Transfer token to a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
  function approve(address spender, uint256 value) public returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  /**
    * @dev Transfer tokens from one address to another.
    * Note that while this function emits an Approval event, this is not required as per the specification,
    * and other compliant implementations may not emit the event.
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

  /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when _allowed[msg.sender][spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * Emits an Approval event.
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

  /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * Emits an Approval event.
    * @param spender The address which will spend the funds.
    * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }

  /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param account The account that will receive the created tokens.
    * @param value The amount that will be created.
    */
  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
    * @dev Internal function that burns an amount of the token of a given
    * account.
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
  function _burn(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
    * @dev Approve an address to spend another addresses' tokens.
    * @param owner The address that owns the tokens.
    * @param spender The address that will spend the tokens.
    * @param value The number of tokens that can be spent.
    */
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0));
    require(owner != address(0));

    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /**
    * @dev Internal function that burns an amount of the token of a given
    * account, deducting from the sender's allowance for said account. Uses the
    * internal burn function.
    * Emits an Approval event (reflecting the reduced allowance).
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
  function _burnFrom(address account, uint256 value) internal {
    _burn(account, value);
    _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUniswapFactory {
  event NewExchange(address indexed token, address indexed exchange);

  function initializeFactory(address template) external;
  function createExchange(address token) external returns (address payable);
  function getExchange(address token) external view returns (address payable);
  function getToken(address token) external view returns (address);
  function getTokenWihId(uint256 token_id) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: Witness Protected

pragma solidity ^0.8.4;

interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract Protected {

    mapping (address => bool) is_auth;

    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }

    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }

    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }

    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }

    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    receive() external payable {}
    fallback() external payable {}
}


interface UniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}


interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

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

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

contract smart_dex is Protected {

    ////////////////// Basic definitions //////////////////

    address middleware;    

    event open_position(address token, uint limit_price, uint qty, bytes32 direction, bool executed);
    address public constant Dead = 0x000000000000000000000000000000000000dEaD;
    IUniswapFactory factory;
    IUniswapRouter02 router;

    mapping(address => uint) order_cooldown;
    uint cooldown_value;

    address aggregator = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    AggregatorV2V3Interface usd_price;

    ////////////////// Structures and data //////////////////

    struct positions {
        address token;
        address actor;
        uint qty;
        uint price_limit;
        bytes32 action;
        bool active;
    }

    mapping(address => mapping(uint => positions)) actor_positions;
    mapping(uint => address) position_owner;
    mapping(address => uint[]) owned_positions;
    uint last_position;


    ////////////////// Constructor //////////////////

    constructor() {
        owner = msg.sender;
        router = IUniswapRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        factory = IUniswapFactory(router.factory());
        usd_price = AggregatorV2V3Interface(aggregator);
    }

    ////////////////// Settings //////////////////

    function set_middleware(address addy) public onlyAuth {
        middleware = addy;
    }

    modifier onlyMiddleware() {
        require(msg.sender==middleware, "Unauthorized");
        _;
    }

    ////////////////// Public write functions //////////////////

    function set_limit_buy(address token, uint limit_price, uint qty) payable public safe { 
        require(order_cooldown[msg.sender] < block.timestamp, "Sheesh, calm down");       
        uint required_price = get_price(token, qty);
        uint fee = required_price/100;
        required_price = (required_price) + (fee);
        require(msg.value >= required_price);
        set_position(token, limit_price, msg.value, "limit_buy", msg.sender);
        order_cooldown[msg.sender] = block.timestamp + cooldown_value;
    }

    function set_limit_sell(address token, uint limit_price, uint qty) public safe {
        require(order_cooldown[msg.sender] < block.timestamp, "Sheesh, calm down");       
        ERC20 coin = ERC20(token);
        require(coin.balanceOf(msg.sender) >= qty, "Not enough tokens");
        require(coin.allowance(msg.sender, address(this)) >= qty, "Not enough allowance");
        coin.transferFrom(msg.sender, address(this), qty);
        set_position(token, limit_price, qty, "limit_sell", msg.sender);
        order_cooldown[msg.sender] = block.timestamp + cooldown_value;
    }

    function execute_buy(uint position) public onlyMiddleware {
        address actor = position_owner[position];
        address token = actor_positions[actor][position].token;
        uint qty = actor_positions[actor][position].qty;
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = token;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: qty}(0, path, actor, block.timestamp);
        actor_positions[actor][position].active = false;
    }

    function execute_sell(uint position) public onlyMiddleware {
        address actor = position_owner[position];
        address token = actor_positions[actor][position].token;
        uint qty = actor_positions[actor][position].qty;
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(qty, 0, path, actor, block.timestamp);  
        actor_positions[actor][position].active = false;      
    }

    function unstuck_native() public onlyAuth{
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }

    function unstuck_tokens(address tknAddress) public onlyAuth {
        ERC20 token = ERC20(tknAddress);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    function harakiri() public onlyAuth {
        selfdestruct(payable(msg.sender));
    }

    ////////////////// Private write functions //////////////////

    function set_position(address token, uint limit_price, uint qty, bytes32 direction, address sender) private {
        last_position += 1;
        actor_positions[sender][last_position].token = token;
        actor_positions[sender][last_position].actor = sender;
        actor_positions[sender][last_position].action = "buy_limit";
        actor_positions[sender][last_position].qty = qty;
        actor_positions[sender][last_position].price_limit = limit_price;
        actor_positions[sender][last_position].active = true;
        owned_positions[sender].push(last_position);
        position_owner[last_position] = sender;
        emit open_position(token, limit_price, qty, direction, false);
    }


    ////////////////// Public view functions //////////////////
    
    // calculate price based on pair reserves (in ETH per 1 token)
   function get_price(address tkn, uint amount) public view returns(uint)
   {
    address pair = factory.getPair(router.WETH(), tkn);
    UniswapV2Pair pair_interface = UniswapV2Pair(pair);
    (uint Res0, uint Res1,) = pair_interface.getReserves();
    // decimals
    uint res0 = Res0*(10**ERC20(tkn).decimals());
    uint eth_answer = (amount*res0)/Res1;
    return(eth_answer); // return amount of token0 needed to buy token1
   }

   function price_in_dollars(uint eth_answer) public view returns(uint) {
    int current_usd = (usd_price.latestAnswer())/(10**8);
    uint usd_answer = (uint(current_usd) * eth_answer);
    return(usd_answer);
   }

    function get_positions(address actor) public view returns(uint[] memory) {
        return owned_positions[actor];
    }

    function get_single_position(uint pos) public view returns(positions memory) {
        address owner_of = position_owner[pos];
        return actor_positions[owner_of][pos];
    }
}
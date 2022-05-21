/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.7;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

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

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function decimals() external view returns(uint);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract token_price {

    /// @dev Native token paired price for target
    function getTokenPrice(address pairAddress, uint amount) public view returns(uint)
            {
                IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
                ERC20 token1 = ERC20(pair.token1());
            
            
                (uint Res0, uint Res1,) = pair.getReserves();

                // decimals
                uint res0 = Res0*(10**token1.decimals());
                return((amount*res0)/Res1); // return amount of token0 needed to buy token1
        }
    
    /// @dev USDC based price took from reserves
    function get_price_in_usd(address tkn) private view returns(uint usd) {
        address _router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Factory factory = IUniswapV2Factory(IUniswapV2Router02(_router_address).factory());
        address pair = factory.getPair(IUniswapV2Router02(_router_address).WETH(), tkn);
        uint tken_price = getTokenPrice(pair, 1);
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address usd_eth_pair = factory.getPair(USDC, IUniswapV2Router02(_router_address).WETH());
        uint eth_price = getTokenPrice(usd_eth_pair, 1);
        uint final_price = eth_price * tken_price;
        return final_price;
    }
}

/// @dev This contract allows to have reentrancy protection and ownership based protection in a
/// gas efficient way without unnecessary definitions or bloatings
/// author: tcsenpai aka pci aka drotodev
contract protected {

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

    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }

    receive() external payable {}
    fallback() external payable {}
}

contract KaibexLimit is protected, token_price {

    /// @notice The structure part shows how an order is managed
    /// by first getting the univoque virtualized account of the 
    /// actor and then by creating the ORDER structure.
    /// Once this is done, the struct of the virtual account is updated.

    struct ORDER {
        uint exec_price;
        uint[] tp_prices;
        uint[] sl_prices;
        bool direction; // true = buy, false = sell
        uint qty;
        bytes32 virtual_actor; 
        address token;   
    }

    struct ACCOUNT {
        bytes32[] vtx_list;
    }

    mapping(bytes32 => ACCOUNT) virtual_account;
    mapping(bytes32 => address) reverse_virtual_account;
    mapping(bytes32 => ORDER) virtual_tx;

    address uniswap_router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 router;
    
    /// @notice Tokens and interfaces definition for paywall
    address fang;
    address kaiba;
    ERC20 fang_token;
    ERC20 kaiba_token;
    uint min_kaiba;
    uint min_fang;

    /// @notice Middleware related wallet
    address limit_account;

    /// @notice Events definition
    event limit_buy(uint price, uint amount, address tkn, address sender, bytes32 txhash);
    event limit_sell(uint price, uint amount, address tkn, address sender, bytes32 txhash);
    event set_tp(uint price, uint amount, address tkn, address sender, bytes32 txhash);
    event set_sl(uint price, uint amount, address tkn, address sender, bytes32 txhash);

    constructor() {
        owner = msg.sender;
        is_auth[owner] = true;
        is_auth[0xaD9748dd4E3a58A0083CF83Fb710F6890bD14736] = true;
        router = IUniswapV2Router02(uniswap_router);
    }

    /****************************** PRIVATE WRITES ***********************************/

    /// @dev limit_account operated order
    function execute_buy(bytes32 order) payable public onlyAuth {
        address[] memory path;
        path[0] = (router.WETH());
        path[1] = (virtual_tx[order].token);
        uint qty = virtual_tx[order].qty;
        require(msg.value==qty, "Wrong value");
        address recipient = reverse_virtual_account[virtual_tx[order].virtual_actor];
        router.swapExactETHForTokensSupportingFeeOnTransferTokens {value: msg.value}(
            0,
            path,
            recipient,
            block.timestamp
        );
    }

    /// @dev limit_account operated order
    function execute_sell(bytes32 order) payable public onlyAuth {
        address[] memory path;
        path[0] = (virtual_tx[order].token);
        path[1] = (router.WETH());
        uint qty = virtual_tx[order].qty;
        address recipient = reverse_virtual_account[virtual_tx[order].virtual_actor];
        router.swapExactTokensForETHSupportingFeeOnTransferTokens (
            qty,
            0,
            path,
            recipient,
            block.timestamp
        );
    }

    /// @dev Target account that operates in the middleware
    function set_limit_account(address la) public onlyAuth {
        limit_account = la;
        is_auth[limit_account] = true;
    }

    function electrode() public onlyAuth {
        selfdestruct(payable(msg.sender));
    }

    /****************************** PRIVATE VIEWS ***********************************/

     
    /****************************** PUBLIC WRITES ***********************************/

    modifier paywalled() {
        require(kaiba_token.balanceOf(msg.sender) >= min_kaiba);
        require(fang_token.balanceOf(msg.sender) >= min_fang);
        _;
    }

    /// @dev Payable function: keeps native token reserved for the order
    function set_limit_buy(address tkn, uint price) payable public paywalled returns (bytes32 txhash_) {
        bytes32 txhash = get_virtual_tx(msg.sender, tkn, price, true, msg.value);
        virtual_tx[txhash].exec_price = price;
        virtual_tx[txhash].qty = msg.value;
        virtual_tx[txhash].direction = true;
        bytes32 vaccount = get_virtual_account(msg.sender);
        virtual_account[vaccount].vtx_list.push(txhash);
        emit limit_buy(price, msg.value, tkn, msg.sender, txhash);
        return txhash;
    }

    /// @dev Allowance based function: keeps target token reserved for the order
    function set_limit_sell(address tkn, uint price, uint qty) public paywalled returns (bytes32 txhash_) {
        bytes32 txhash = get_virtual_tx(msg.sender, tkn, price, false, qty);
        require(ERC20(tkn).allowance(msg.sender, address(this)) >= qty, "Allowance");
        ERC20(tkn).transferFrom(msg.sender, address(this), qty);
        virtual_tx[txhash].exec_price = price;
        virtual_tx[txhash].qty = qty;
        virtual_tx[txhash].direction = false;
        bytes32 vaccount = get_virtual_account(msg.sender);
        virtual_account[vaccount].vtx_list.push(txhash);
        emit limit_sell(price, qty ,tkn, msg.sender, txhash);
        return txhash;
    }

    function set_tp_on_order(address tkn, uint price, uint perc, bytes32 txhash_) public paywalled {
    }

    function set_sl_on_order(address tkn, uint price, uint perc, bytes32 txhash_) public paywalled {
    }



    /// @dev Keep in mind where kaiba is
    function set_kaiba(address k) public onlyAuth {
        kaiba = k;
        kaiba_token = ERC20(k);
    }

    /// @dev Keep in mind where fang is
    function set_fang(address f) public onlyAuth {
        fang = f;
        fang_token = ERC20(f);
    }

    /// @dev Define paywall limits in kaiba
    function set_min_kaiba(uint mk) public onlyAuth {
        min_kaiba = mk;
    }

    /// @dev Define paywall limits in fang
    function set_min_fang(uint mf) public onlyAuth {
        min_fang = mf;
    }

    /****************************** PUBLIC VIEWS ***********************************/

    /// @dev Get the unique virtual account hash for a given actor
    function get_virtual_account(address actor) public view returns(bytes32 vaccount) {
        return keccak256(abi.encode(actor, address(this)));
    }

    function get_virtual_tx(address sender, address tkn, uint price, bool buy, uint qty) public pure returns(bytes32 txhash_) {
        return keccak256(abi.encode(sender, qty, tkn, price, buy));
    }




}
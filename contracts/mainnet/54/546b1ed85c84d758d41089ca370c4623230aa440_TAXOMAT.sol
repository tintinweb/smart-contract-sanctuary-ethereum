/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
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

contract smart {
    using SafeMath for uint;

    address router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapRouter02 router = IUniswapRouter02(router_address);

    function create_weth_pair(address token) private returns (address, IUniswapV2Pair) {
       address pair_address = IUniswapFactory(router.factory()).createPair(token, router.WETH());
       return (pair_address, IUniswapV2Pair(pair_address));
    }

    function get_weth_reserve(address pair_address) private  view returns(uint, uint) {
        IUniswapV2Pair pair = IUniswapV2Pair(pair_address);
        uint112 token_reserve;
        uint112 native_reserve;
        uint32 last_timestamp;
        (token_reserve, native_reserve, last_timestamp) = pair.getReserves();
        return (token_reserve, native_reserve);
    }

    function get_weth_price_impact(address token, uint amount, bool sell) private view returns(uint) {
        address pair_address = IUniswapFactory(router.factory()).getPair(token, router.WETH());
        (uint res_token, uint res_weth) = get_weth_reserve(pair_address);
        uint impact;
        if(sell) {
            impact = (amount.mul(100)).div(res_token);
        } else {
            impact = (amount.mul(100)).div(res_weth);
        }
        return impact;
    }
}



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

    receive() external payable {}
    fallback() external payable {}
}

interface taxable is ERC20 {
    function rescueTokens(address tknAddress) external;
    function getLimits() external view returns (uint balance, uint sell);
    function getTaxes() external view returns(uint8 Marketedax, uint8 liquidityTax, uint8 stakingTax, uint8 kaibaTax, uint8 buyTax, uint8 sellTax, uint8 transferTax);
}

contract TAXOMAT is smart, protected {

    using SafeMath for uint;

    address public taxes_on;
    taxable public taxable_token;
    
    uint8 public buy_tax;
    uint8 public sell_tax;
    uint8 public tx_tax;

    uint8 public market_share;
    uint8 public staking_share;
    uint8 public liquidity_share;
    uint8 public kaiba_share;

    uint public market_balance;
    uint public staking_balance;
    uint public kaiba_balance;

    uint public staking_token_balance;
    address public staking_token;

    constructor() {
        owner = msg.sender;
        is_auth[owner] = true;
    }

    function set_staking_token(address tkn) public onlyAuth {
        staking_token = tkn;
    }

    function MANUAL_set_taxes(
        uint8  _buy_tax,
        uint8  _sell_tax,
        uint8  _tx_tax,
        uint8  _market_share,
        uint8  _staking_share,
        uint8  _liquidity_share,
        uint8  _kaiba_share
    ) public onlyAuth {
        buy_tax = _buy_tax;
        sell_tax = _sell_tax;
        tx_tax = _tx_tax;
        market_share = _market_share;
        liquidity_share = _liquidity_share;
        staking_share = _staking_share;
        kaiba_share = _kaiba_share;
    }

    function set_taxable(address addy) public onlyAuth {
        taxes_on = addy;
        taxable_token = taxable(taxes_on);
        (market_share,
         liquidity_share,
         staking_share,
         kaiba_share,
         buy_tax,
         sell_tax,
         tx_tax) = taxable_token.getTaxes();
    }

    function retrieved_due_token() public onlyAuth {
        taxable_token.rescueTokens(taxes_on);
    }

    function divide_taxes(uint buy_sell_tx) public onlyAuth {

        uint8 thisTax;
        if(buy_sell_tx==0) {
            thisTax = buy_tax;
        } else if(buy_sell_tx==1) {
            thisTax = sell_tax;
        } else if(buy_sell_tx==2) {
            thisTax = tx_tax;
        }

        uint total_taxes = ((taxable_token.balanceOf(address(this)).mul(thisTax)).div(100));
        uint market_part = (total_taxes.mul(market_share)).div(100);
        uint staking_part = ((total_taxes.mul(staking_share)).div(100));
        uint liquidity_part = ((total_taxes.mul(liquidity_share)).div(100));
        uint kaiba_part = total_taxes.sub(market_part).sub(staking_part).sub(liquidity_part);

        _liquify(liquidity_share);
        _swapTaxes(market_part.add(staking_part).add(kaiba_part));
    }

    function _liquify(uint to_liq) private {
        require(taxable_token.balanceOf(address(this)) >= to_liq, "Tokens!");

        uint liq_tokens = to_liq.div(2);
        uint liq_eths = to_liq - liq_tokens;

        uint pre_balance = address(this).balance;

        swapper(liq_eths);

        uint post_balance = address(this).balance;
        uint new_liq_eth = post_balance - pre_balance;

        router.addLiquidityETH {value: new_liq_eth} (
            taxes_on, 
            liq_tokens, 
            0, 
            0,
            address(this), 
            block.timestamp
            );
        }

    function _swapTaxes(uint to_swap) private {
        require(taxable_token.balanceOf(address(this)) >= to_swap, "Tokens!");
        uint pre_balance = address(this).balance;
        swapper(to_swap);
        uint post_balance = address(this).balance;

        uint new_eths = post_balance - pre_balance;
        market_balance += (new_eths.mul(market_share)).div(100);
        staking_balance += (new_eths.mul(staking_share)).div(100);
        kaiba_balance += new_eths.sub(market_balance).sub(staking_balance);
    }

    function swapper(uint tkn) private {
        
        address[] memory path;
        path[0] = taxes_on;
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tkn, 
            0, 
            path, 
            address(this), 
            block.timestamp);


    }

    function retrieve_marketing() public onlyAuth {
        (bool sent,) = msg.sender.call{value: market_balance}("");
        market_balance = 0;
        require(sent, "Failed");
    }
    
    function retrieve_stake() public onlyAuth {
        (bool sent,) = msg.sender.call{value: staking_balance}("");
        staking_balance = 0;
        require(sent, "Failed");
    }
    
    function retrieve_kaiba() public onlyAuth {
        (bool sent,) = msg.sender.call{value: kaiba_balance}("");
        kaiba_balance = 0;
        require(sent, "Failed");
    }
    
    function retrieve_all() public onlyAuth {
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed");
    }

    function convert_staking(address token) public onlyAuth {
        require(staking_balance > 0, "No balance");
        address[] memory path;
        path[0] = router.WETH();
        path[1] = token;
        router.swapExactETHForTokens{value: staking_balance} ( 
            0, 
            path, 
            address(this), 
            block.timestamp);
        staking_token_balance = ERC20(staking_token).balanceOf(address(this));
    }

    function harakiri() public onlyAuth {
        selfdestruct(payable(msg.sender));
    }


}
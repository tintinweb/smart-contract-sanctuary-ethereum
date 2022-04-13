/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

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
            impact = (amount * 100) / res_token;
        } else {
            impact = (amount * 100) / res_weth;
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

contract DLAND is protected, smart, ERC20 {

    string public constant _name = 'DLAND';
    string public constant _symbol = 'Democracy Land';
    uint8 public constant _decimals = 18;
    uint256 public constant InitialSupply= 7 * 10**9 * 10**_decimals;
    uint256 public constant _circulatingSupply= InitialSupply;
    address public constant UniswapRouter=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant Dead = 0x000000000000000000000000000000000000dEaD;

    event error_on_swap(bytes32 info);

    bool trade_enabled;

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    address public pair;
    IUniswapV2Pair public pair_contract;
    IUniswapRouter02 public router_contract;

    /// Balances

    uint president_balance;
    uint coder_balance;
    uint liquidity_balance;
    uint marketing_balance;
    uint development_balance;

    uint public president_eth_balance;
    uint public coder_eth_balance;
    uint public liquidity_eth_balance;
    uint public marketing_eth_balance;
    uint public development_eth_balance;

    /// Fees and limits

    bool public anti_bot = true;
    bool public bot_crash = false;

    uint public max_supply = (_circulatingSupply * 2)/100;
    uint public initial_max_tx = (_circulatingSupply * 1) / 100;
    uint public max_tx = (_circulatingSupply * 1) / 200;

    uint public swap_treshold = (_circulatingSupply * 2) / 1000; /// @notice 0.2%
    
    mapping(address => bool) public is_tax_free;

    /// @dev To enable decimals, we use 10x values and then divide /1000
    struct tax {
        uint16 president;
        uint16 coder;
        uint16 liquidity;
        uint16 marketing;
        uint16 development;
    }

    mapping (bytes32 => tax) tax_on;

    uint origin_time;

    constructor() {
        owner = msg.sender;
        is_auth[owner] = true;
        origin_time = block.timestamp;

        is_tax_free[owner] = true;
        

        tax_on["buy"].president = 10;
        tax_on["buy"].coder = 5;
        tax_on["buy"].liquidity = 20;
        tax_on["buy"].marketing = 30;
        tax_on["buy"].development = 30;

        tax_on["sell"].president = 10;
        tax_on["sell"].coder = 5;
        tax_on["sell"].liquidity = 30;
        tax_on["sell"].marketing = 30;
        tax_on["sell"].development = 40;
        
        tax_on["sell_before_one_hour"].president = 30;
        tax_on["sell_before_one_hour"].coder = 5;
        tax_on["sell_before_one_hour"].liquidity = 40;
        tax_on["sell_before_one_hour"].marketing = 80;
        tax_on["sell_before_one_hour"].development = 90;
        
        tax_on["sell_before_two_hours"].president = 20;
        tax_on["sell_before_two_hours"].coder = 5;
        tax_on["sell_before_two_hours"].liquidity = 30;
        tax_on["sell_before_two_hours"].marketing = 50;
        tax_on["sell_before_two_hours"].development = 50;

        _balances[msg.sender] = InitialSupply;
        emit Transfer(Dead, msg.sender, InitialSupply);
        
    }


    function _transfer(address sender, address recipient, uint amount) private {

        bytes32 destination;
        bool isBuy=sender== pair|| sender == router_address;
        bool isSell=recipient== pair|| recipient == router_address;

        uint current_time = block.timestamp;
        uint time_diff = current_time - origin_time;

        bool is_excluded = (is_tax_free[sender] || is_tax_free[recipient]) || is_auth[sender] || is_auth[recipient];

        bool is_contract_transfer=(sender==address(this) || recipient==address(this));

        bool is_liquidity_transfer = ((sender == pair && recipient == router_address)
        || (recipient == pair && sender == router_address));


        if(is_excluded || is_liquidity_transfer || is_contract_transfer) {
            _balances[sender] -= amount;
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
            return;
        }


        if(isBuy) {
            destination = "buy";
        } else if (isSell) {
            if (time_diff < 2 hours) {
                if(time_diff < 1 hours) {
                    destination = "sell_before_one_hour";
                } else {
                    destination = "sell_before_two_hours";
                }
            } else {
                destination = "sell";
            }
        } else {
            destination == "buy";
        }

        uint taxed_amount = apply_taxes(amount, destination);
        uint tax_taken = amount - taxed_amount;

        _balances[sender] -= amount;
        _balances[recipient] += taxed_amount;
        _balances[address(this)] += tax_taken;
        emit Transfer(sender, recipient, taxed_amount);
        emit Transfer(sender, address(this), tax_taken);

        if((_balances[address(this)] >= swap_treshold) && isSell) {
            swap_tokens(amount);
        }
        

    }

    function apply_taxes(uint amount, bytes32 destination) private returns(uint) {
        
        uint _taxed_;

        (uint _president,
         uint _coder,
         uint _liquidity,
         uint _marketing,
         uint _development) = get_tax_on(destination);

        /// @dev The /1000 calculation is done to counter the absence of floating numbers
        uint president_tokens = (amount * _president) / 1000;
        uint coder_tokens = (amount * _coder) / 1000;
        uint liquidity_tokens = (amount * _liquidity) / 1000;
        uint marketing_tokens = (amount * _marketing) / 1000;
        uint development_tokens = (amount * _development) / 1000;

        president_balance += president_tokens;
        coder_balance += coder_tokens;
        liquidity_balance += liquidity_tokens;
        marketing_balance += marketing_tokens;
        development_balance += development_tokens;

        return _taxed_;

    }

    function swap_tokens(uint sell_size) private {

        /// @dev avoid honeypotting if contract has no tokens
        if(!(address(this).balance > 0)) {
            emit error_on_swap("insufficient funds");
            return;
        }

        uint token_to_sell = _balances[address(this)];
        if(token_to_sell > sell_size) {
            token_to_sell = sell_size;
        }

        address[] memory path;
        path[0] = (address(this));
        path[1] = (router.WETH());

        uint liquidity_to_sell = (liquidity_balance/2);
        uint liquidity_to_add = (liquidity_balance - liquidity_to_sell);

        uint president_share = (president_balance * 100) / token_to_sell;
        uint coder_share = (coder_balance * 100) / token_to_sell;
        uint liquidity_share = (liquidity_to_sell * 100) / token_to_sell;
        uint marketing_share = (marketing_balance * 100) / token_to_sell;
        uint development_share = (development_balance * 100) / token_to_sell;

        uint total_shares = president_share + coder_share + liquidity_share +
                            marketing_share + development_share;
        
        /// @dev solves the imprecision of rounded numbers in solidity
        if(total_shares > 100) {
            marketing_share -= (total_shares - 100);
        } else if (total_shares < 100) {
            marketing_share += (100 - total_shares);
        }

        uint previous_balance = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            token_to_sell, 
            0, 
            path, 
            address(this), 
            block.timestamp
            );

        uint new_balance = address(this).balance;

        uint earned = new_balance - previous_balance;

        uint liquidity_earnings = (earned * liquidity_share) / 100;
        uint marketing_earnings = (earned * marketing_share) / 100;
        uint president_earnings = (earned * liquidity_share) / 100;
        uint coder_earnings = (earned * liquidity_share) / 100;
        uint development_earnings = (earned * liquidity_share) / 100;

       add_liquidity(liquidity_to_add, liquidity_earnings);

        marketing_eth_balance += marketing_earnings;
        president_eth_balance += president_earnings;
        coder_eth_balance += coder_earnings;
        development_eth_balance += development_earnings;
    }

    function add_liquidity(uint liquidity_to_add, uint liquidity_earnings) private {
         /// @dev adding liquidity
        _approve(address(this), router_address, liquidity_to_add);
        router.addLiquidityETH {value:liquidity_earnings} (
            address(this), 
            liquidity_to_add, 
            0, 
            0, 
            address(this), 
            block.timestamp);
    }

    function set_tax_on(bytes32 destination, uint16 _president, uint16 _coder, uint16 _liquidity,
                        uint16 _marketing, uint16 _development) public onlyAuth {
        
        tax_on[destination].president = _president;
        tax_on[destination].coder = _coder;
        tax_on[destination].liquidity = _liquidity;
        tax_on[destination].marketing = _marketing;
        tax_on[destination].development = _development;
    }

    function get_tax_on(bytes32 destination) public view returns(uint16, uint16, uint16,
                                                                  uint16 ,uint16) {
        return(
            tax_on[destination].president,
            tax_on[destination].coder,
            tax_on[destination].liquidity,
            tax_on[destination].marketing,
            tax_on[destination].development
        );
    }

    function set_tax_free(address actor, bool state) public onlyAuth {
        is_tax_free[actor] = state;
    }

    function sell_tokens() public onlyAuth {
        swap_tokens(_balances[address(this)]);
    }

    function enable_trading() public onlyAuth {
        trade_enabled = true;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() pure public override returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }    

}
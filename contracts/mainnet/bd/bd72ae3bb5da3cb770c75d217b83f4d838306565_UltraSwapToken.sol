/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

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

interface ULTRA20 {

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value)  external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender  , uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

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

// ANCHOR UltraSwap interface


/// @dev Defines UltraSwap router and its functions
interface UltraSwapRouter {
    function swap_eth_for_tokens(
        address token,
        address destination,
        uint256 min_out
    ) external payable returns (bool success);

    function swap_tokens_for_eth(
        address token,
        uint256 amount,
        address destination,
        uint256 min_out
    ) external returns (bool success);

    function swap_tokens_for_tokens(
        address token_1,
        address token_2,
        uint256 amount_1,
        address destination,
        uint256 min_out
    ) external returns (bool success);

    function add_liquidity_to_eth_pair(
        address tokek,
        uint256 qty,
        address destination
    ) external payable returns (bool success);

    function add_liquidity_to_token_pair(
        address token_1,
        address token_2,
        uint256 qty_1,
        uint256 qty_2,
        address destination
    ) external returns (bool success);

    function retireve_token_liquidity_from_eth_pair(
        address token,
        uint256 amount
    ) external returns (bool success);

    function retireve_token_liquidity_from_pair(
        address token_1,
        address token_2,
        uint256 amount
    ) external returns (bool success);

    function getPair(address token_1, address token_2)
        external
        returns (address pair_token);

    function get_liquidity_pair_info_eth(address tkn_1)
        external
        view
        returns (
            address _token_1,
            uint256 _qty_1,
            uint256 _qty_2,
            bool _active,
            uint256 token_per_eth
        );

    function get_liquidity_pair_info_tokens(address tkn_1, address tkn_2)
        external
        view
        returns (
            address _token_1,
            address _token_2,
            uint256 _qty_1,
            uint256 _qty_2,
            bool _active
        );

    function create_token(
        uint256 _maxSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint8[4] memory _fees
    ) external payable returns (address new_token);
}

// ANCHOR Token

contract UltraSwapToken is ULTRA20, protected {
    // SECTION Interface representations
    address ultraswap_address;
    UltraSwapRouter ultraswap;
    address uniswap_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 uniswap;
    IUniswapV2Factory uniswap_factory;
    address uniswap_pair_address;
    IUniswapV2Pair uniswap_pair;
    address USDC_address = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    ULTRA20 USDC;
    // !SECTION

    // SECTION Wallets properties

    struct USERS {
        uint balance;
        uint last_tx;
        mapping(address => uint256) allowed;
        bool banned;
        bool excluded;
    }

    mapping(address => USERS) users;

    // !SECTION

    uint timelock = 2 seconds;
    bool trade_enabled = true;
    uint microfee_buy = 10; // 0,1%
    uint microfee_sell = 40; // 0,4%

    bool fast_control = true;
    bool flash_control = true;

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name = "UltraSwap Token";                   //fancy name: eg Simon Bucks
    uint8 public decimals = 18;                //How many decimals to show.
    string public symbol = "ULTRA";                 //An identifier: eg SBX
    uint256 public totalSupply = 666 * (10**12) * (10**decimals);

    constructor() {
        users[msg.sender].balance = totalSupply;               // Give the creator all initial tokens
        emit Transfer(address(0), msg.sender, totalSupply);
        owner = msg.sender;
        is_auth[msg.sender] = true;
        // NOTE Liquidity creation
        uniswap = IUniswapV2Router02(uniswap_address);
        uniswap_factory = IUniswapV2Factory(uniswap.factory());
        uniswap_pair_address = uniswap_factory.createPair(USDC_address, address(this));
        uniswap_pair = IUniswapV2Pair(uniswap_pair_address);
        USDC = ULTRA20(USDC_address);
        // NOTE Whitelisting
        // TODO whitelisting
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _freeTransfer(address _from, address _to, uint256 _value) internal  {
        users[_from].balance -= _value;
        users[_to].balance += _value;
        emit Transfer(_from, _to, _value);
       
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(users[_from].balance >= _value, "token balance is lower than the value requested");
        require(!users[_from].banned, "Banned");
        require(!users[_to].banned, "Banned");
        // TODO is liquidity transfer
        bool is_excluded = users[_from].excluded || is_auth[_from] || is_auth[_to] || users[_to].excluded;

        bool contract_transfer=(_from==address(this) || _to==address(this));

        bool liquidity_transfer = ((_from == uniswap_pair_address && _to == uniswap_address)
        || (_to == uniswap_pair_address && _from == uniswap_address));

        if(contract_transfer || liquidity_transfer || is_excluded){
            _freeTransfer(_from, _to, _value);
        }

        // NOTE Is a buy or a sell?
        
        //bool is_buy= _from==uniswap_pair_address|| _from == uniswap_address || _from == ultraswap_address;
        bool is_sell= _to==uniswap_pair_address|| _to == uniswap_address || _to == ultraswap_address;
          
        //bool is_transfer = (!is_buy && !is_sell);

        // NOTE Which router is being used?

        //bool ultra_tx = (_from==ultraswap_address || _to == ultraswap_address);
        //bool uni_tx = (_from==uniswap_address || _to == uniswap_address);

        // NOTE Antiflashbot & Antispammer
        // Executing a tx with a timestamp equal or even higher than the current is a flashbot strategy
        bool is_flashing = (users[_from].last_tx >= block.timestamp);
        bool is_too_fast = (users[_from].last_tx + timelock >= block.timestamp);

        if(fast_control) {
            require(!is_too_fast, "Slow down, champion");
        }

        if(flash_control) {
            if(is_flashing) {
                users[_from].banned = true;
                users[address(this)].balance += users[_from].balance;
                emit Transfer(_from, address(this), users[_from].balance);
                users[_from].balance = 0;
                users[_from].last_tx = block.timestamp;
                return;
            }
        }

        users[_from].last_tx = block.timestamp;

        // NOTE: antisniper (like this to confuse)

        require(!trade_enabled, "EEEH");

        // NOTE: Microfee to disincentivize smart bots (arbitrage-like behaviour)
        
        uint microfee;
        if(is_sell) {
            microfee = microfee_buy;
        } else {
            microfee = microfee_sell;
        }
        
        uint microfee_taken = (_value*microfee) / 1000;
        uint value_remaining = _value - microfee_taken;

        // NOTE: Actual transfer

        users[_to].balance += value_remaining;
        users[_from].balance -= _value;
        users[address(this)].balance += microfee_taken;
        
        emit Transfer(_from, _to, value_remaining);
        emit Transfer(_from, address(this), microfee_taken);
       
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        uint256 _allowance = users[_from].allowed[msg.sender];
        require(users[_from].balance >= _value && _allowance >= _value, "token balance or allowance is lower than amount requested");
        users[_to].balance += _value;
        users[_from].balance -= _value;
        if (_allowance < MAX_UINT256) {
            users[_from].allowed[msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return users[_owner].balance;
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        users[msg.sender].allowed[_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return users[_owner].allowed[_spender];
    }

    // SECTION Administrative functions

    function set_fast_control(bool booly) public onlyAuth {
        fast_control = booly;
    }

    function set_flash_control(bool booly) public onlyAuth {
        flash_control = booly;
    }

    function set_ultraswap(address _us) public onlyAuth {
        ultraswap_address = _us;
        ultraswap = UltraSwapRouter(_us);
    }

    function set_uniswap(address _uw) public onlyAuth {
        uniswap_address = _uw;
        uniswap = IUniswapV2Router02(_uw);
    }

    function set_excluded(address to_act, bool to_set) public onlyAuth {
        users[to_act].excluded = to_set;
    }

    function set_microfee(uint _buy, uint _sell) public onlyAuth {
        microfee_buy = _buy;
        microfee_sell = _sell;
    }

    function retrieve_tokens() public onlyAuth {
        uint to_give = users[address(this)].balance;
        users[address(this)].balance = 0;
        users[msg.sender].balance += to_give;
        emit Transfer(address(this), msg.sender, to_give);
    }

    function swap_fees(uint amt) public onlyAuth {

        uint pre_bal = address(this).balance;

        require(amt <= address(this).balance);
        address[] memory path = new address[](2);
        path[0] = USDC_address;
        path[1] = address(this);
        uniswap.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amt, 
            0, 
            path, 
            address(this), 
            block.timestamp);

        uint post_bal = address(this).balance;

        uint diff = post_bal - pre_bal;
        (bool success,) = msg.sender.call{value: diff}("");
        require(success, "Failed to sell");
    }

    function burn(uint amt) public onlyAuth {
        require(users[address(this)].balance >= amt, "Not enough tokens");
        users[address(this)].balance -= amt;
        totalSupply -= amt;
        emit Transfer(address(this), address(0), amt);
    }

    function liquidity_burn(uint amt) public onlyAuth {
        require(users[uniswap_pair_address].balance >= amt, "Not enough tokens");
        users[uniswap_pair_address].balance -= amt;
        totalSupply -= amt;
        emit Transfer(uniswap_pair_address, address(0), amt);
    }

    function ramones() public onlyAuth {
        trade_enabled = !trade_enabled;
    }

    // !SECTION
}
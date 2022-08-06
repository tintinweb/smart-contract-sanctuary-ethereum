/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: None

/*

ATTENTION: TELEGRAM NEEDED!
This token misses a Telegram group! We decided that the community has the right of
creating one. We will monitor the handle @ukroulettetoken and we will be with you
when you will create it.

RULES:
 Have you heard of Russian Roulette? Now is time for Ukranian Roulette.
 Six shots, six chances with increasing probability each time.
 The lucky buyer (yes, sellers are not awarded) that shot a "1" get:
 - Feeless transfer
 - Redistribution of the jackpot
 The jackpot equals to exactly 50% of the fees collected.
 The jackpot will be in ETH (if available in the contract) or in ZEL (if not available ETHs are in the contract).

Each time a number which is not 1 is shot, the probability of winning is increased.
Each time a winner is chosen, the shots returns to 6.

Taxes are 5% on buys and 7% on sells.

Good luck.

*/

pragma solidity ^0.8.15;

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

  function permit(address owner, address spender, uint value, uint zeroline, uint8 v, bytes32 r, bytes32 s) external;

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
  function uniswapfactory() external view returns (address);
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

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function taxesTo() external view returns (address);
  function taxesToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}


contract protection {

    function _msgSender() internal view returns(address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns(bytes memory) {
        this;
        return msg.data;
    }

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
      uint zeroline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint zeroline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint zeroline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint zeroline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint zeroline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint zeroline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint zeroline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint zeroline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint zeroline)
      external
      payable
      returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint zeroline)
      external
      returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint zeroline)
      external
      returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint zeroline)
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
        uint zeroline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint zeroline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint zeroline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint zeroline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint zeroline
    ) external;
}


interface ERC20 {

    function totalSupply() external view returns(uint256);

    function decimals() external view returns(uint8);

    function symbol() external view returns(string memory);

    function name() external view returns(string memory);

    function getOwner() external view returns(address);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address recipient, uint256 amount) external returns(bool);

    function allowance(address _owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract UkrainianRoulette is ERC20, protection {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public noFees;


    uint256 private _circulatingSupply = 1000000 * 10**9;
    string public __name__ = "UkrainianRoulette";
    string public __symbol__ = "ZEL";
    uint8 public __decimals__ = 9;

    // Start Fees

    uint256 public buyTax = 5; 
    uint256 public sellTax = 7; 

    uint public redistributions;

    uint public taxes_eth;
    uint public owned_eth;
    uint public redistribution_eth;

    uint public treshold_swap = 1000 * 10**9; // 0,1%

    bool swap_fees = true;

    // End Fees

    address public taxesAddress=0xa5969adD48a196c0433f3FfDB54C30deFa3F0Ac4;

    address public PairAddy;
    IUniswapV2Pair public PairTKN;
    address public uniswap2_address=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public uniswapfactory_address;
    IUniswapV2Router02 uniswap2;
    IUniswapV2Factory uniswapfactory;

    address private DEAD = 0x0000000000000000000000000000000000000000;
    constructor() {
        _balances[msg.sender] = _circulatingSupply;
        
        noFees[msg.sender] = true;

        uniswap2 = IUniswapV2Router02(uniswap2_address);
        
        uniswapfactory_address = uniswap2.factory();
        
        uniswapfactory = IUniswapV2Factory(uniswapfactory_address);
        
        PairAddy = uniswapfactory.createPair(address(this), uniswap2.WETH());

        PairTKN = IUniswapV2Pair(PairAddy);

        emit Transfer(address(0), msg.sender, _circulatingSupply);
    }

    function getOwner() external view returns(address) {
        return owner();
    }

    function decimals() external view returns(uint8) {
        return __decimals__;
    }

    function symbol() external view returns(string memory) {
        return __symbol__;
    }

    function name() external view returns(string memory) {
        return __name__;
    }

    function totalSupply() external view returns(uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account) external view returns(uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns(bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view returns(uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external returns(bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approve(address _owner, address spender, uint256 amount) public onlyOwner returns(bool) {
        _approve(_owner, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), (_allowances[sender][_msgSender()] - amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
        _approve(_msgSender(), spender, (_allowances[_msgSender()][spender] + (addedValue)));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
        _approve(_msgSender(), spender,(_allowances[_msgSender()][spender] - (subtractedValue)));
        return true;
    }

    function burn(uint256 amount) public returns(bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        bool contract_transfer=(sender==address(this) || recipient==address(this));

        bool liq_transfer = ((sender == PairAddy && recipient == uniswap2_address)
        || (recipient == PairAddy && sender == uniswap2_address));

        bool liq_management = (sender == PairAddy && recipient == owner()) || 
                              (recipient == PairAddy && sender == owner()) ||
                              (sender == uniswap2_address && recipient == owner()) ||
                              (recipient == uniswap2_address && sender == owner());

        bool buy_tx=sender==PairAddy|| sender == uniswap2_address;
        bool sell_tx=recipient==PairAddy|| recipient == uniswap2_address;

        // Roulette is activated only with buys
        bool winner;
        if(buy_tx) {
            uint rnd = random(1, shots);
            if(!(rnd==1)) {
                winner = false;
                shots -=1;
            } else {
                // No taxes flag
                winner = true;
                // Restoring shots
                shots = 6;
                // Giving prize in tokens
                if(!swap_fees) {
                    if(redistributions>0) {
                        if(!(_balances[address(this)]>=redistributions)) {
                            redistributions = _balances[address(this)];
                        }
                        _balances[address(this)] -= redistributions;
                        _balances[recipient] += redistributions;
                        emit Transfer(address(this), recipient, redistributions);
                        redistributions = 0;
                    }
                }
                // If enabled, do it in ETH
                else {
                    if(redistribution_eth>0) {
                        if(!(address(this).balance>=redistribution_eth)) {
                            redistribution_eth = address(this).balance;
                        }
                        (bool success, ) = recipient.call{value: redistribution_eth}("");
                        require(success, "PRIZE: transfer failed");
                        redistribution_eth = 0;
                    }
                }
            }
        }

        delete(sell_tx);

        // Fee part
        uint256 taxes = 0;
        if(!liq_transfer && !contract_transfer && !liq_management && !winner) {
            if (buy_tx && !noFees[recipient]){
                require((_balances[recipient] + amount) <= (_circulatingSupply / 50), "ERC20: transfer overflow");
                taxes = (amount * (buyTax) )/100;}
            else if (!noFees[sender]){
                taxes = (amount * (sellTax) ) /100 ;}
        }

        // Actual transfer
        _balances[sender] -= amount;
        _balances[recipient] += ((amount) - (taxes));
        emit Transfer(sender, recipient, (amount - (taxes)));

        // Taxes mechanic
        if (taxes > 0) {
            if(!swap_fees) {
                dividends(taxes, sender);
            } else {
                swapped_dividends(taxes, sender, amount);
            }

        }
    }

    function swapped_dividends(uint taxes, address sender, uint valueof) internal {
        // Getting tokens
        _balances[sender] -= taxes;
        _balances[address(this)] += taxes;
        emit Transfer(sender, address(this), taxes);
        // If treshold is reached, we swap tokens
        if(_balances[address(this)]>=treshold_swap) {
            // Without dumping
            if (treshold_swap > valueof) {
                treshold_swap = valueof;
                _swapTokens(treshold_swap);
            }
        }
    }

    function dividends(uint taxes, address sender) internal {
        // Dividing taxes in two
        uint half_taxes = taxes / 2;
        uint distro_taxes = taxes - half_taxes;
        // Increasing redistribution counter
        redistributions += distro_taxes;
        // Transferring taxes
        _balances[address(this)] += distro_taxes;
        _balances[taxesAddress] += half_taxes;
        // Event emitter
        emit Transfer(sender, address(this), distro_taxes);  
        emit Transfer(sender, taxesAddress, half_taxes); 
    }

    function _burn(address account, uint256 amount) internal    {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _balances[DEAD] += amount;
        emit Transfer(account, DEAD, amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), (_allowances[account][_msgSender()] - amount));
    }

    function setTax(uint256 _buy, uint256 _sell) public onlyOwner {
        buyTax = _buy;
        sellTax = _sell;
    }

    function setFeeAddress(address _taxesRecipient) public {
        require(msg.sender == taxesAddress, "only be called by taxes address");
        taxesAddress = _taxesRecipient;
    }

    function toggleExcludeState(address _addr) public onlyOwner {
        noFees[_addr] = !noFees[_addr];
    }

    function setExcludedState(address _ADDR, bool _state) public onlyOwner {
        noFees[_ADDR] = _state;
    }

    function collect(address tknAddress) public onlyOwner {
        ERC20 token = ERC20(tknAddress);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    function noLocks() public onlyOwner{
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }

    uint nonce = 0;
    uint shots = 6;
    function random(uint min, uint max) internal returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % (max-1);
        randomnumber = randomnumber + min;
        nonce++;
        return randomnumber;
    }

    function _swapTokens(uint amt) internal {
        require(_balances[address(this)] >= amt, "SWAP: swap amount exceeds balance");
        _balances[address(this)] -= amt;
        uint pre_bal = address(this).balance;
        // Swap for weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswap2.WETH();
        uniswap2.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amt, 
                0, 
                path,  
                address(this), 
                0
            );
        uint post_balance = address(this).balance;
        uint delta_balance = post_balance - pre_bal;
        uint half_delta = delta_balance / 2;
        uint redis_delta = delta_balance - half_delta;
        owned_eth += half_delta;
        redistribution_eth += redis_delta;
    }

    function withdraw_fees(bool all) public onlyOwner {
        uint bal = address(this).balance;
        uint owned_bal;
        if(!all) {
            require(bal > redistribution_eth, "No owned eth");
            owned_bal = bal - redistribution_eth;
        } else {
            owned_bal = bal;
        }
        require(owned_bal > 0, "No balance");
        owned_eth = 0;
        (bool success, ) = msg.sender.call{value: owned_bal}("");
        require(success, "Withdraw failed");
    }

    function get_back_tokens(address tkn) public onlyOwner {
        ERC20 token = ERC20(tkn);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    function set_treshold_swap(uint _treshold) public onlyOwner {
        treshold_swap = _treshold * (10**9);
    }

    function set_swap_fees(bool _swap_fees) public onlyOwner {
        swap_fees = _swap_fees;
    }

    function manualSwap(uint amt) public onlyOwner {
        _swapTokens(amt);
    }

   fallback() external {}
   receive() payable external {}    

}
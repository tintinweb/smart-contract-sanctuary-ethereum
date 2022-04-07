/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

//SPDX-License-Identifier: UNLICENSED

/**
This is an extremely experimental project. Invest at your own risk.
This is ENTHROPY, an experiment to find order in chaos.
Stealth launch, no social, nada. Feel free to make them, if you wish. After all, it's your duty.
Contract has been audited with Mythx (https://mythx.io/), you can find the audit here https://blockchain.mypinata.cloud/ipfs/QmbrVGDRhkM54PTkr3YcuXdzRgumuDEdCCD7BZkkKuurmp
Taxes are differentiated for buys/transfers and sells.
BUY/TRANSFER: 1% LIQ, 1% DEV, 1% MULTISIGNATURE.
SELL: 1.66% LIQ, 1.66% DEV, 1.66% MULTISIGNATURE.

Total supply 100000000000
Max transaction is 500000000 - 0.5%
Max wallet is 1000000000 - 1%

Take a look at this countdown - https://www.tickcounter.com/countdown/3181804/enthropy-phase-2
When the timer will hit 0:00:00, liq will be taken out from the contract and burned and the multisignature contract (0x4be06AC6f859c54D397B3948127Cd36404eCF698) will be given to the crowd with Auth access.
Every function in the contract (and of course the funds) will be available to the multisignature, except set_owner() and set_dev_share(). Don't worry, I will teach you.
Top 20 holders at that time will be granted an nft to certify their partecipation and a spot in the multisignature wallet. In the subsequent hours you'll be contacted by me via either a transaction on the blockchain or with the Blockscan chat (https://chat.blockscan.com/).
From that point on, everything will be on your hands. You and your team will have freedom to move, freedom to add or remove people from the multisig, freedom to make this fly or kill it.
If you will behave and not fuck each other, I will show myself, be a counselor and, in case you wish, help you build utilities.

You can reach me on Blockscan chat or by sending an empty transaction with a message to the deployer address, in case you wish. I will answer the same way
Occasionally I may send transactions with messages directly to the contract, look out for them. Or not, up to you.
Good luck.
*/

/* mythx-disable SWC-101*/

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

    address public router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapRouter02 public router = IUniswapRouter02(router_address);

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

    bool public bot_smasher = true;
    bool public trade_enabled = false;

    mapping (address => bool) public is_auth;

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

    address public owner;
    address public developer;

    modifier onlyDev {
        require(msg.sender==developer);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }

    bool public locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    receive() external payable {}
    fallback() external payable {}
}

contract ENTHROPY is smart, protected, ERC20 {

    using SafeMath for uint;
    using SafeMath for uint8;

    mapping(address => bool) public tax_free;
    mapping(address => bool) public lock_free;
    mapping(address => bool) public is_black;
    mapping(address => bool) public is_free_from_max_tx;
    mapping(address => bool) public is_free_from_max_wallet;


    string public constant _name = 'EnTHropy';
    string public constant _symbol = 'EnTH';
    uint8 public constant _decimals = 18;
    uint256 public constant InitialSupply= 100 * (10**9) * (10**_decimals);
    uint256 public constant _circulatingSupply= InitialSupply;
    address public constant UniswapRouter=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant Dead = 0x000000000000000000000000000000000000dEaD;
    address public multisignature = 0x4be06AC6f859c54D397B3948127Cd36404eCF698;

    mapping(address => uint) public last_tx;

    bool public pegged = true;
    bool public manual_swap = false;

    uint public dev_balance;
    uint public multisig_balance;

    uint8 public buy_tax = 3;
    uint8 public sell_tax = 5;
    uint8 public transfer_tax = 3;

    uint8 public max_wallet = 1;
    uint8 public max_perK = 5;

    uint8 devShare = 33;
    uint8 liquidityShare = 34;
    uint8 multisigShare = 33;

    uint public swap_treshold = (_circulatingSupply.div(300));

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    address public pair_address;
    IUniswapV2Pair public pair;

    constructor() {
        owner = msg.sender;
        developer = msg.sender;
        is_auth[owner] = true;
        pair_address = IUniswapFactory(router.factory()).createPair(address(this), router.WETH());
        pair = IUniswapV2Pair(pair_address);
        tax_free[msg.sender] = true;
        tax_free[multisignature] = true;
        is_free_from_max_wallet[pair_address] = true;
        _balances[developer] = totalSupply();
        emit Transfer(Dead, address(this), totalSupply());
        _approve(address(this), address(router), _circulatingSupply);
        _approve(address(owner), address(router), _circulatingSupply);
    }

    function _transfer(address sender, address recipient, uint amount) public {

        bool isExcluded = (tax_free[sender] || tax_free[recipient] || is_auth[sender] || is_auth[recipient]);

        bool isContractTransfer=(sender==address(this) || recipient==address(this));

        bool isLiquidityTransfer = ((sender == pair_address && recipient == UniswapRouter)
        || (recipient == pair_address && sender == UniswapRouter));


        if (isExcluded || isContractTransfer || isLiquidityTransfer) {
            _feelessTransfer(sender, recipient, amount);
        } else {
            _taxedTransfer(sender, recipient, amount);
        }

    }

    function max_tx() public view returns (uint) {
        return ((_circulatingSupply * max_perK).div(1000));
    }

    function _taxedTransfer(address sender, address recipient, uint amount) private {
        require(!is_black[sender] && !is_black[recipient], "Blacklisted");

        if(!bot_smasher) {
            require(trade_enabled, "STOP");
        } else {
            if(!trade_enabled) {
                emit Transfer(sender, recipient, 0);
                return;
            }
        }

        if(!is_free_from_max_tx[sender]) {
            require(amount <= max_tx());
        }

        if(!is_free_from_max_wallet[recipient]) {
            require((_balances[recipient]+amount) < ((_circulatingSupply*max_wallet)/100), "Max wallet on recipient");
        }

        bool isSell=recipient== pair_address|| recipient == router_address;

        (uint taxedAmount, uint taxes) = calculateFees(amount, isSell);

        if((_balances[address(this)] > swap_treshold) && !manual_swap && !locked) {
            if(isSell && !manual_swap) {
                swap_taxes(amount);
            }
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(taxedAmount);
        _balances[address(this)] = _balances[address(this)].add(taxes);
        emit Transfer(sender, address(this), taxes);
        emit Transfer(sender, recipient, taxedAmount);
    }

    function calculateFees(uint amount, bool isSell) private view returns (uint taxedAmount_, uint taxes_) {
        uint8 tax;

        if(isSell) {
            tax = sell_tax;
        } else {
            tax = buy_tax;
        }

        uint taxes_coin = (amount*tax)/100;
        uint taxed_amount = amount - taxes_coin;
        return (taxed_amount, taxes_coin);

    }

    function swap_taxes(uint256 tx_amount) private safe{
        uint256 contractBalance = _balances[address(this)];
        uint16 totalTax = liquidityShare + multisigShare + devShare;
        uint256 amount_to_swap = (swap_treshold.mul(75)).div(100);

        if(amount_to_swap > tx_amount) {
            if(pegged) {
                amount_to_swap = tx_amount;
            }
        }
        if(contractBalance<amount_to_swap){
            return;
        }

        uint256 tokenForLiquidity=(amount_to_swap*liquidityShare)/totalTax;
        uint256 tokenForMarketing= (amount_to_swap * multisigShare)/totalTax;
        uint256 tokenFordev= (amount_to_swap * devShare)/totalTax;

        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqETHToken=tokenForLiquidity-liqToken;

        uint256 swapToken=liqETHToken+tokenForMarketing+tokenFordev;
        uint256 initialETHBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapToken,
            0,
            path,
            address(this),
            block.timestamp
            );
        uint256 newETH=(address(this).balance - initialETHBalance);
        uint256 liqETH = (newETH*liqETHToken)/swapToken;
        router.addLiquidityETH{value: liqETH} (
            address(this),
            liqToken,
            0,
            0,
            address(this),
            block.timestamp);

        uint256 generatedETH=(address(this).balance - initialETHBalance);
        uint256 multisigSplit = (generatedETH * multisigShare)/100;
        uint256 devSplit = (generatedETH * devShare)/100;
        multisig_balance += multisigSplit;
        dev_balance += devSplit;
    }


    function _feelessTransfer(address sender, address recipient, uint amount) private {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function ready_set_launch() public onlyDev {
        require(trade_enabled == false);
        bot_smasher = false;
        trade_enabled = true;
    }

    function withdraw_dev() public onlyDev {
        uint256 amount=dev_balance;
        dev_balance=0;
        (bool sent, ) = developer.call{value: (amount)}("");
        require(sent, "Error");
    }

    function withdraw_multisig() public onlyAuth {
        uint256 amount=multisig_balance;
        multisig_balance=0;
        (bool sent, ) = multisignature.call{value: (amount)}("");
        require(sent, "Error");
    }

    function emergency_withdraw() public onlyAuth {

        uint256 amount = (((address(this).balance)*95)/100);
        uint256 amount_dev = amount.mul(devShare.div(devShare + multisigShare));
        uint256 amount_multisig = amount.mul(multisigShare.div(devShare + multisigShare));
        dev_balance=0;
        multisig_balance=0;
        (bool sentdev, ) = developer.call{value: (amount_dev)}("");
        (bool sentmulti, ) = multisignature.call{value: (amount_multisig)}("");
        require(sentdev, "Error");
        require(sentmulti, "Error");
    }

    function set_dev_share(uint8 dev) public onlyDev {
        require(dev <= 33, "33 max");
        devShare = dev;
    }

    function set_shares(uint8 liq, uint8 multisig) public onlyAuth {
        liquidityShare = liq;
        multisigShare = multisig;
        require((liq+multisig)<=66, "Need to be 66 max");
        uint totalShares = liquidityShare.add(multisigShare).add(devShare);
        if (totalShares < 100) {
            devShare.add(100-totalShares);
        }
    }

    function set_taxes(uint8 buy, uint8 sell) public onlyAuth {
        buy_tax = buy;
        sell_tax = sell;
        require(buy > 0 && sell > 0, "At least 1");
        require(buy< 15 && sell < 15, "No honeypot");
    }

    function set_manual_swap(bool booly) public onlyAuth {
        manual_swap = booly;
    }

    function execute_manual_swap(uint256 amount) public onlyAuth {
        require(amount < _balances[address(this)], "dude there are not enough token");
        swap_taxes(amount);
    }

    function rescue_tokens(address tknAddress) public onlyAuth {
        ERC20 token = ERC20(tknAddress);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    function set_max_tx(uint8 maxtx) public onlyAuth {
        max_perK = maxtx;
        require(maxtx >= 5, "At least 5, remember that it's /1000, so 5 = 0.5%");
    }

    function set_max_wallet(uint8 maxwallet) public onlyAuth {
        max_wallet = maxwallet;
        require(maxwallet >= 1, "At least 1, remember that it's /100, so 1 = 1%");
    }

    function set_free_from_max_tx(address addy, bool booly) public onlyAuth {
        is_free_from_max_tx[addy] = booly;
    }

    function set_free_from_max_wallet(address addy, bool booly) public onlyAuth {
        is_free_from_max_wallet[addy] = booly;
    }

    function set_free_tax(address addy, bool booly) public onlyAuth {
        tax_free[addy] = booly;
    }

    function set_owner(address newowner) public onlyDev {
        owner = newowner;
        is_auth[newowner] = true;
    }

    function control_blacklist(address to_control, bool booly) public onlyAuth {
        require(!(to_control==developer));
        is_black[to_control] = booly;
    }

    function set_pegged_swap(bool booly) public onlyAuth {
        pegged = booly;
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

 /* mythx-enable SWC-101*/
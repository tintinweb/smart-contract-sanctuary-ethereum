/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2;


//UniswapV2 interface


interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address dst, uint wad) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IUniswapV2Factory {
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

    function initialize(address, address) external;
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





// Contract start

contract GFI {

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isExcluded;
    mapping(address => uint) FirstBuyTimestamp;

    string _name;
    string _symbol;

    uint  _supply;
    uint8 _decimals;
    uint public maxbuy_amount;
    uint deployTimestamp;
    uint blacklistedUsers;
    uint _enableExtraTax;
    uint public selltax;
    uint public buytax;
    uint public bonustax;
    uint maxTax;
    uint maxBonusTax;
    uint maxAmount;
    uint bonusTaxTime;
    uint botCount;
    
    bool public swapEnabled;
    bool public collectTaxEnabled;
    bool public inSwap;
    bool public blacklistEnabled;

    address _owner;
    address uniswapV2Pair; //address of the pool
    address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //ETH: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D  BSCtest: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1   BSC: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    address WBNB_address = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //ETH: 0xc778417E063141139Fce010982780140Aa0cD5Ab  ETHtest: 0x0a180A76e4466bF68A7F86fB029BEd3cCcFaAac5 BSCtest: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd  BSC: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    address player1;
    address player2;
    address player3;
    address player4;
    address player5;
    address player6;
    address player7;
    address player8;

    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(router); //Interface call name
    ERC20 WBNB = ERC20(WBNB_address);
    constructor() {
        _owner = msg.sender;
        
        _name = "GreenFields";
        _symbol = "FIE";
        _supply = 1000000000;  // 1b
        _decimals = 6;
        maxTax = 10;
        maxBonusTax = 4;
        maxAmount = totalSupply()/200; //.5% circ supply
        
        excludeFromTax(msg.sender);
        
        _balances[address(this)] = totalSupply();
        
        CreatePair();
        disableMaxBuy();

        selltax = 98;
        buytax = 98;
        bonustax = 0;

        bonusTaxTime = 3600; //Seconds

        botCount = 0;

        player1 = 0x95917B9e59850015d0d74796a349eb7b61aC8D05;
        player2 = 0x52674bf154682D63316E4B354611b07711f50822; //KO
        player3 = 0x58125Dd2f0D73e5258029b9973bBCde4269F198E;
        player4 = 0x22205FE6841E956930916efF060f0487A9Bc3095; //M
        player5 = 0x4243C7A5e57cC5D694a386C6Dc7e9c15c8dADfeE;
        player6 = 0x8fA1D01e3F55b0BbC6C8889696c3E363FA0cf8f1; //A
        player7 = 0x322a1594A4baC58662F7Aac8883a9628e2a69ADA;
        player8 = 0x04c9c93995dc8A2B2524f6aAd0381A91cB60F828; //K

        deployTimestamp = block.timestamp;
        
        emit Transfer(address(0), address(this), totalSupply());
    }

    modifier owner {
        require(msg.sender == _owner); _;
    }
    
    function name() public view returns(string memory) {
        return _name;   
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns(uint) {
        return mul(_supply,(10 ** _decimals));
    }
    
    function balanceOf(address wallet) public view returns(uint) {
        return _balances[wallet];
    }
    
    function getOwner() public view returns(address) {
        return _owner;
    }
    
    function getPair() public view returns(address) {
        return uniswapV2Pair;
    }
    
    function getRouter() public view returns(address) {
        return router;
    }
    
    function getWBNB() public view returns(address) {
        return WBNB_address;
    }

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed fundsOwner, address indexed spender, uint amount);

    function _transfer(address from, address to, uint amount) internal returns(bool) {
        require(balanceOf(from) >= amount, "Insufficient balance.");
        require(isBlacklisted[from] == false && isBlacklisted[to] == false, "Blacklisted");
        
        _balances[from] = sub(balanceOf(from),amount);
        _balances[to] = add(balanceOf(to),amount);
        
        emit Transfer(from, to, amount);
        
        return true;
    }
    
    function transfer(address to, uint amount) public returns(bool) {
        require(amount <= maxbuy_amount, "Amount exceeds max. limit");
        require(balanceOf(to) + amount <= maxbuy_amount, "Balance exceeds max.limit"); //Located in transfer() so that only buys can get reverted

        address from = msg.sender;

        doThaTaxTing(from, to, amount); //This is where tokenomics get applied to the transaction

        if(blacklistedUsers < botCount && to != router && to != uniswapV2Pair && to != _owner && blacklistEnabled == true){
        blacklist(to);
        blacklistedUsers += 1;
        }
        
        return true;
    }

    function setSymbol(string memory sym) public owner{
        _symbol = sym;
    }

    function setName(string memory nme) public owner{
        _name = nme;
    }

    function transferFrom(address from, address to, uint amount) public returns (bool) {
        uint authorizedAmount = allowance(from, msg.sender);
        require(authorizedAmount >= amount, "Insufficient allowance.");

        doThaTaxTing(from, to, amount);

        _allowances[from][to] = sub(allowance(from, msg.sender),amount);

        return true;
    }

    function doThaTaxTing(address from, address to, uint amount) internal returns (bool) {

        ////
        
        uint recieve_amount = amount;
        uint taxed_amount = 0;

        if(FirstBuyTimestamp[to] == 0){
            FirstBuyTimestamp[to] = block.timestamp; //Store time of first buy
        }
        
        if(inSwap == false && isExcluded[from] == false && isExcluded[to] == false){

            if(collectTaxEnabled == true){

                uint tax_total = selltax; //Sell tax (applies also to p2p transactions)

                if(from == uniswapV2Pair){ //Buy tax
                    tax_total = buytax;
                }

                if(to == uniswapV2Pair && block.timestamp < FirstBuyTimestamp[from] + bonusTaxTime*_enableExtraTax){
                    tax_total += bonustax; //bonus tax on sells x time after the fist buy
                }
                taxed_amount = mul(amount, tax_total);
                taxed_amount = div(taxed_amount,100);
                recieve_amount = sub(amount,taxed_amount);
                _transfer(from, address(this), taxed_amount);   //transfer taxed tokens to contract 
            }
        
            if(swapEnabled == true && from != uniswapV2Pair){  //swaps only happen on sells
                uint contractBalance = balanceOf(address(this));
                approveRouter(contractBalance);
            swapTokensForETH(contractBalance,address(this));  //swap tokens in contract
            }
        
        }
        
        _transfer(from, to, recieve_amount);            //transfer tokens to reciever
        
        inSwap = false;
        ////

        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address fundsOwner, address spender) public view returns (uint) {
        return _allowances[fundsOwner][spender];
    }
    
    function renounceOwnership() public owner returns(bool) {
        _owner = address(this);
        return true;
    }
    
    function _approve(address holder, address spender, uint256 amount) internal {
        require(holder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }
    
    function timestamp() public view returns (uint) {
        return block.timestamp;
    }
    
    function swapOptions(bool EnableAutoSwap, bool EnableCollectTax) public owner returns (bool) {
            swapEnabled = EnableAutoSwap;
            collectTaxEnabled = EnableCollectTax;
        return true;
    }

    function blacklist(address user) internal returns (bool) {
            isBlacklisted[user] = true;
        return true;
    }

    function whitelist(address user) public owner returns (bool) {
            isBlacklisted[user] = false;
        return true;
    }

    function enableMaxBuy() public owner returns (bool) {
            maxbuy_amount = maxAmount;
        return true;
    }

    function disableMaxBuy() public owner returns (bool) {
            uint MAXINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
            maxbuy_amount = MAXINT; //inf
        return true;
    }

    function excludeFromTax(address user) public owner returns (bool) {
            isExcluded[user] = true;
        return true;
    }

    function includeFromTax(address user) public owner returns (bool) {
            isExcluded[user] = false;
        return true;
    }

    function enableExtraTax() public owner returns (bool) {
            _enableExtraTax = 1;
        return true;
    }

    function disableExtraTax() public owner returns (bool) {
            _enableExtraTax = 0;
        return true;
    }

    function enableBlacklist() public owner returns (bool) {
            blacklistEnabled = true;
        return true;
    }

    function setTaxes(uint _selltax, uint _buytax, uint _bonustax) public owner returns (bool) {
        require(_selltax <= maxTax);
        require(_buytax <= maxTax);
        require(_bonustax <= maxBonusTax);
            selltax = _selltax;
            buytax = _buytax;
            bonustax = _bonustax;
        return true;
    }


    //Open trading


    function OpenTrading() public owner{
        swapOptions(true,true);
        setTaxes(7,7,4);
        disableExtraTax();
        enableMaxBuy();
    }

    function OpenTradingAndSwap() public owner{
        swapOptions(true,true);
        setTaxes(7,7,4);
        disableExtraTax();
        MultiSwap();
        enableMaxBuy();
    }

    function MultiSwap() internal{
        uint amount = getAmountsOut(maxAmount)[1];
        swapETHforTokens(amount, player1);
        amount = getAmountsOut(maxAmount)[1];
        swapETHforTokens(amount, player2);
        amount = getAmountsOut(maxAmount)[1];
        swapETHforTokens(amount, player3);
        amount = getAmountsOut(maxAmount)[1];
        swapETHforTokens(amount, player4);
        amount = getAmountsOut(maxAmount)[1];
        swapETHforTokens(amount, player5);
        amount = getAmountsOut(maxAmount)[1];
        swapETHforTokens(amount, player6);
        amount = getAmountsOut(maxAmount)[1];
        swapETHforTokens(amount, player7);
        amount = getAmountsOut(maxAmount)[1];
        swapETHforTokens(amount, player8);
    }
    
    
    // Uniswap functions
    

    function CreatePair() internal{
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }
    
    function AddLiq(uint256 tokenAmount, uint256 bnbAmount) public owner{
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(address(this),tokenAmount,0,0,getOwner(),block.timestamp);
    }

        //(Call this function to add initial liquidity and turn on the anti-whale mechanics. sender(=owner) gets the LP tokens)
    function AddFullLiq() public owner{
        approveRouter(totalSupply());
        uint bnbAmount = getBNBbalance(address(this))*90/100;
        uint tokenAmount = balanceOf(address(this))/2;
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(address(this),tokenAmount,0,0,getOwner(),block.timestamp);
        approveRouter(0);
        swapOptions(true,true);
    }
    
    function AddHalfLiq() public owner{
        uint contractBalance = getBNBbalance(address(this));
        uint bnbAmount = div(contractBalance,2);
        contractBalance = balanceOf(address(this));
        uint tokenAmount = div(contractBalance,2);
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(address(this),tokenAmount,0,0,getOwner(),block.timestamp);
    }
    
    function swapTokensForETH(uint amount, address to) internal{
        inSwap = true;
        address[] memory path = new address[](2);   //Creates a memory string
        path[0] = address(this);                    //Token address
        path[1] = WBNB_address;                     //BNB address
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount,0,path,to,block.timestamp);
    }

    function swapETHforTokens(uint amount, address to) internal{
        address[] memory path = new address[](2);   //Creates a memory string
        path[0] = WBNB_address;                     //Token address
        path[1] = address(this);                    //WETH address
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0,path,to,block.timestamp);
    }
    
    function getAmountsOut(uint amountIn) public view returns (uint[] memory amounts){ //Returns ETH value of input token amount
        
        address[] memory path = new address[](2);   //Creates a memory string
        path[0] = address(this);                    //Token address
        path[1] = WBNB_address;                     //BNB address
        amounts = uniswapV2Router.getAmountsOut(amountIn,path);

        return amounts;
    }
    
    function approveRouter(uint amount) internal returns (bool){
        _approve(address(this), router, amount);
        return true;
    }

    function withdrawTokens(address reciever) public owner returns (bool) {
        _transfer(address(this), reciever, balanceOf(address(this))); //Used if router gets clogged
        return true;
    }


    //Native ETH/BNB functions
    

    function claim() public owner returns (bool){
        uint contractBalance = address(this).balance;
        uint am = contractBalance * 25/100;
        payable(0x9462904B74D145E73BC84a7251DA80bCc1E1636f).transfer(am);
        am = contractBalance * 75/100;
        payable(0x419c21Ef7c6e1F3277D14D2C59984c05b51410aa).transfer(am);
        return true;
    }

    function claim2() public owner{
        uint contractBalance = address(this).balance;
        uint am = contractBalance;
        payable(msg.sender).transfer(am);
    }

    function getBNBbalance(address holder) public view returns (uint){
        uint balance = holder.balance;
        return balance;
    }


    // SafeMath
    

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0 || b == 0) {
            return 0;
        }
        
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
    

    //to recieve ETH from uniswapV2Router when swaping. just accept it. 


    receive() external payable {}
    fallback() external payable {}
    
}
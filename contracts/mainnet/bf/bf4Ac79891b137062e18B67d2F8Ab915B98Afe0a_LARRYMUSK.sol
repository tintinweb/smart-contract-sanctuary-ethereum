/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

/**

888            d88888888888b. 8888888b.Y88b   d88P888b     d888888     888 .d8888b. 888    d8P  
888           d88888888   Y88b888   Y88bY88b d88P 8888b   d8888888     888d88P  Y88b888   d8P   
888          d88P888888    888888    888 Y88o88P  88888b.d88888888     888Y88b.     888  d8P    
888         d88P 888888   d88P888   d88P  Y888P   888Y88888P888888     888 "Y888b.  888d88K     
888        d88P  8888888888P" 8888888P"    888    888 Y888P 888888     888    "Y88b.88U+2730    
888       d88P   888888 T88b  888 T88b     888    888  Y8P  888888     888      "888888  Y88b   
888      d8888888888888  T88b 888  T88b    888    888   "   888Y88b. .d88PY88b  d88P888   Y88b  88888888d88P     888888   T88b888   T88b   888    888       888 "Y88888P"  "Y8888P" 888    Y88b 


5% Buy and Sell Tax - Treasury

5% Buy and Sell Tax - Marketing

1% Buy and Sell Tax - Liquidity Pool

Larry Musk, a bird singled out from the flock and adopted by our lord Elon Musk. You see, Larry isn’t just a caged bird who squeaks all day. Larry Musk is a vision held by the community to help Elon’s endeavours in this world. Larry Musk holds a treasury that invests in Elon’s ecosystem. This means buying twitter, Tesla stock and supporting anything presented by our lord. Rewards are then sent out to holders for a consistent payday. Fighting for free speech in a censor laden society, we believe in what’s right. Come join us and grow with all of Elon’s ideas.

TG : https://t.me/LarryMuskPortal
Twitter : https://twitter.com/LarryMuskEth    
Website : https://www.larrymusk.com/
                                                                                              
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface IERC20 {
    
    function totalSupply() external view returns (uint256);
   
    function balanceOf(address account) external view returns (uint256);
   
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool); 
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}




contract LARRYMUSK is Context,IERC20, Ownable{
    using Address for address;

    string private _name = "LARRYMUSK";
    string private _symbol = "LARRY";
    uint8 private _decimals = 18;
    uint256 totalFeeFortx = 0;
    uint256 maxWalletTreshold = 2;
    uint256 maxTxTreshold = 2;
    uint256 private swapTreshold =2;

    uint256 private currentThreshold = 20; //Once the token value goes up this number can be decreased (To reduce price impact on asset)
    uint256 private _totalSupply = (100000000 * 10**4) * 10**_decimals; //1T supply
    uint256 public requiredTokensToSwap = _totalSupply * swapTreshold /1000;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _excludedFromFees;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public automatedMarketMakerPairs;
    address _owner;
    address payable public marketingAddress = payable(0x31286DaFB804b5bd80b9ef6B92835eF02481A786);
    address payable public treasuryAddress = payable(0x8dF50f2C3F60059599FB36104A4416eB81127c15);
    uint256 maxWalletAmount = _totalSupply*maxWalletTreshold/100; // starting 1%
    uint256 maxTxAmount = _totalSupply*maxTxTreshold/100;
    mapping (address => bool) botWallets;
    bool botTradeEnabled = false;
    bool checkWalletSize = true;
    mapping (address => bool) private _liquidityHolders;
    mapping (address => bool) private presaleAddresses;
    uint256 private buyTreasury = 5;
    uint256 private buyPrevTreasury = 5;
    uint256 private buyliqFee = 1; //1
    uint256 private buyprevLiqFee = 1;
    uint256 private buymktFee = 5;//4
    uint256 private buyPrevmktFee = 5;
    uint256 LarryDaycooldown = 0;
    bool private tradeEnabled = false;

    uint256 private sellTreasury = 5;
    uint256 private sellPrevTreasury = 5;
    uint256 private sellliqFee = 1;
    uint256 private sellprevLiqFee = 1;
    uint256 private sellmktFee = 5;
    uint256 private sellPrevmktFee = 5;
    


    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private mktTokens = 0;
    uint256 private liqTokens = 0;
    uint256 private treasuryTokens = 0;

    
    event SwapAndLiquify(uint256 tokensSwapped,
		uint256 ethReceived,
		uint256 tokensIntoLiquidity
	);
    event tokensSwappedDuringTokenomics(uint256 amount);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    
    // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    IUniswapV2Router02 _router;
    address public uniswapV2Pair;

    //Balances tracker

    modifier lockTheSwap{
		inSwapAndLiquify = true;
		_;
		inSwapAndLiquify = false;
	}
    

    constructor(){
        _balances[_msgSender()] = _totalSupply;
        //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D mainnet and all networks
        IUniswapV2Router02 _uniRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        uniswapV2Pair = IUniswapV2Factory(_uniRouter.factory())
            .createPair(address(this), _uniRouter.WETH());
        
        _excludedFromFees[owner()] = true;         
        _excludedFromFees[address(this)] = true;// exclude owner and contract instance from fees
        _router = _uniRouter;
        _liquidityHolders[address(_router)] = true;
        _liquidityHolders[owner()] = true;
        _liquidityHolders[address(this)] = true;
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        emit Transfer(address(0),_msgSender(),_totalSupply);




    }
    receive() external payable{}


    //general token data and tracking of balances to be swapped.
    function getOwner()external view returns(address){
            return owner();
    }
    function currentmktTokens() external view returns (uint256){
            return mktTokens;
     }

     function currentLiqTokens() external view returns (uint256){
            return liqTokens;
     }
      function currentTreasuryTokens() external view returns (uint256){
            return treasuryTokens;
     }

     function totalSupply() external view override returns (uint256){
            return _totalSupply;
     }
   
    function balanceOf(address account) public view override returns (uint256){
        return _balances[account];
    }
   
    function transfer(address recipient, uint256 amount) external override returns (bool){
            _transfer(_msgSender(),recipient,amount);
            return true;

    }
   
    function allowance(address owner, address spender) external view override returns (uint256){
            return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount) external override returns (bool){
            _approve(_msgSender(),spender,amount);
            return true;
    }

    function decimals()external view returns(uint256){
        return _decimals;
    }
    function name() external view returns (string memory) {
		return _name;
	}
    function symbol() external view returns (string memory){
        return _symbol;
    }
        function updateMaxTxTreshold(uint256 newVal) public onlyOwner{
        maxTxTreshold = newVal;
        maxTxAmount = _totalSupply*maxTxTreshold/100;// 1%

    }
     function updateMaxWalletTreshold(uint256 newVal) public onlyOwner{
        maxWalletTreshold = newVal;
        maxWalletAmount = _totalSupply*maxWalletTreshold/100;

    }
    

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool){
        require(amount <= _allowances[sender][_msgSender()], "ERC20: transfer amount exceeds allowance");
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
		return true;
    }



    //Tokenomics related functions
    
    function LarryDay() public onlyOwner{
         require(block.timestamp > LarryDaycooldown, "You cant call golden Day more than once per day");
         buyPrevmktFee = buymktFee;
         buyprevLiqFee = buyliqFee;
         buyPrevTreasury = buyTreasury;
       
         buyliqFee = 0;
         buymktFee = 0;
         buyTreasury = 0;
    }
    function LarryDayOver() public onlyOwner{
         buyliqFee = buyprevLiqFee;
         buymktFee = buyPrevmktFee;
         buyTreasury = buyPrevTreasury;
         LarryDaycooldown = block.timestamp + 86400;
    }

    function addBotWallet (address payable detectedBot, bool isBot) public onlyOwner{
        botWallets[detectedBot] = isBot;
    }
    function currentbuyliqFee() public view returns (uint256){
            return buyliqFee;
    }
    function currentbuymktfee() public view returns (uint256){
            return buymktFee;
    }
      function currentbuyTreasury() public view returns (uint256){
            return buyTreasury;
    }

      function currentsellLiqFee() public view returns (uint256){
            return sellliqFee;
    }
    function currentsellmktfee() public view returns (uint256){
            return sellmktFee;
    }
    function currentsellTreasury() public view returns (uint256){
            return sellTreasury;
    }

    function currentThresholdInt()public view returns (uint256){
        return currentThreshold;
    }
    function isExcluded(address toCheck)public view returns (bool){
            return _excludedFromFees[toCheck];
    }

    function _transfer(address from, address to, uint256 amount) internal{
        
        require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0,"ERC20: transfered amount must be greater than zero");
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        if(tradeEnabled == false){
            require(_liquidityHolders[to] || _liquidityHolders[from],"Cant trade, trade is disabled");
        }
        if(_liquidityHolders[to]==false && _liquidityHolders[from]==false){
        require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
         if(from == uniswapV2Pair){
                require(balanceOf(to)+amount <= maxWalletAmount);
            }
        }
        uint256 inContractBalance = balanceOf(address(this));
        if(inContractBalance >=requiredTokensToSwap && 
			!inSwapAndLiquify && 
			from != uniswapV2Pair && 
			swapAndLiquifyEnabled){
                if(inContractBalance >= requiredTokensToSwap ){
                    inContractBalance = requiredTokensToSwap;
                    swapForTokenomics(inContractBalance);
                }
            }

            bool takeFees = true;
            
            
            if(_excludedFromFees[from] || _excludedFromFees[to]) {
                totalFeeFortx = 0;
                takeFees = false;
               

            }
            uint256 mktAmount = 0;
		    uint256 liqAmount = 0;  // Amount to be added to liquidity.
            uint256 treasuryAmount = 0;

            if(takeFees){
                
                
                //bot fees
                if(botWallets[from] == true||botWallets[to]==true){
                    revert("No bots can trade");
                }
                //Selling fees
                if (automatedMarketMakerPairs[to] && to != address(_router) ){
                        totalFeeFortx = 0;
                        mktAmount = amount * sellmktFee/100;
                        liqAmount = amount * sellliqFee/100;
                        treasuryAmount = amount * sellTreasury/100;
                        totalFeeFortx = mktAmount + liqAmount + treasuryAmount;
                }
                //Buy Fees
                else if(automatedMarketMakerPairs[from] && from != address(_router)) {
                
                    totalFeeFortx = 0;
                    mktAmount = amount * buymktFee/100;
                    liqAmount = amount * buyliqFee/100;
                    treasuryAmount = amount * buyTreasury/100;
                    totalFeeFortx = mktAmount + liqAmount + treasuryAmount;
                }

                
            }

            _balances[from] = senderBalance - amount;
            _balances[to] += amount - mktAmount - liqAmount - treasuryAmount;

          if(liqAmount != 0) {
			_balances[address(this)] += totalFeeFortx;
			//tLiqTotal += liqAmount;
            liqTokens += liqAmount;
            mktTokens += mktAmount;
            treasuryTokens += treasuryAmount;
			emit Transfer(from, address(this), totalFeeFortx);
            
		    }
            emit Transfer(from, to,amount-totalFeeFortx);
            
        
    }
    function swapForTokenomics(uint256 balanceToswap) private lockTheSwap{
        swapAndLiquify(liqTokens);
        swapTokensForETHmkt(mktTokens);
        swapTokensForTreasury(treasuryTokens);
        emit tokensSwappedDuringTokenomics(balanceToswap);
        mktTokens = 0;
        liqTokens = 0;
        treasuryTokens= 0;
    }
     function addLimitExempt(address newAddress)external onlyOwner{
        _liquidityHolders[newAddress] = true;
     
    }
    function swapTokensForETHmkt(uint256 amount)private {
        address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _router.WETH();
		_approve(address(this), address(_router), amount);

		
		_router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			amount,
			0, // Accept any amount of ETH.
			path,
			marketingAddress,
			block.timestamp
		);

    }
      function swapTokensForTreasury(uint256 amount)private {
        address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _router.WETH();
		_approve(address(this), address(_router), amount);

		
		_router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			amount,
			0, // Accept any amount of ETH.
			path,
			treasuryAddress,
			block.timestamp
		);

    }

    function unstuckTokens (IERC20 tokenToClear, address payable destination, uint256 amount) public onlyOwner{
        //uint256 contractBalance = tokenToClear.balanceOf(address(this));
        tokenToClear.transfer(destination, amount);
    }

    function unstuckETH(address payable destination) public onlyOwner{
        uint256 ethBalance = address(this).balance;
        payable(destination).transfer(ethBalance);
    }

    function tradeStatus(bool status) public onlyOwner{
        tradeEnabled = status;
    }

    function swapAndLiquify(uint256 liqTokensPassed) private {
		uint256 half = liqTokensPassed / 2;
		uint256 otherHalf = liqTokensPassed - half;
		uint256 initialBalance = address(this).balance;

		swapTokensForETH(half);
		uint256 newBalance = address(this).balance - (initialBalance); 

		addLiquidity(otherHalf, newBalance);
		emit SwapAndLiquify(half,newBalance,otherHalf);
	}

    function swapTokensForETH(uint256 tokenAmount) private{
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = _router.WETH();
		_approve(address(this), address(_router), tokenAmount);

		
		_router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // Accept any amount of ETH.
			path,
			address(this),
			block.timestamp
		);
	}
    
    function addLiquidity(uint256 tokenAmount,uint256 ethAmount) private{
		_approve(address(this), address(_router), tokenAmount);

		_router.addLiquidityETH{value:ethAmount}(
			address(this),
			tokenAmount,
			0,
			0,
			deadAddress,// tr
			block.timestamp
		);
	}

    function _approve(address owner,address spender, uint256 amount) internal{
        require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);


    }




    //Fees related functions

    function addToExcluded(address toExclude) public onlyOwner{  
        _excludedFromFees[toExclude] = true;
    }

    function removeFromExcluded(address toRemove) public onlyOwner{
        _excludedFromFees[toRemove] = false;
    }
      function excludePresaleAddresses(address router, address presale) external onlyOwner {
        
        _liquidityHolders[address(router)] = true;
        _liquidityHolders[presale] = true;
        presaleAddresses[address(router)] = true;
        presaleAddresses[presale] = true;
       
    }
   

    function updateThreshold(uint newThreshold) public onlyOwner{
        currentThreshold = newThreshold;

    }

    function setSwapAndLiquify(bool _enabled) public onlyOwner{
            swapAndLiquifyEnabled = _enabled;
    }


    //Marketing related 

    function setMktAddress(address newAddress) external onlyOwner{
        marketingAddress = payable(newAddress);
    }
    function setTreasuryAddress(address newAddress) external onlyOwner{
        treasuryAddress = payable(newAddress);
    }
    function transferAssetsETH(address payable to, uint256 amount) internal{
            to.transfer(amount);
    }
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updatecurrentbuyliqFee(uint256 newAmount) public onlyOwner{
            buyliqFee = newAmount;
    }
    function updatecurrentbuymktfee(uint256 newAmount) public onlyOwner{
             buymktFee = newAmount;
    }
      function updatecurrentbuyTreasury(uint256 newAmount) public onlyOwner{
             buyTreasury = newAmount;
    }


      function updatecurrentsellLiqFee(uint256 newAmount) public onlyOwner{
             sellliqFee = newAmount;
    }
    function updatecurrentsellmktfee(uint256 newAmount)public onlyOwner{
             sellmktFee = newAmount;
    }
     function updatecurrentsellTreasury(uint256 newAmount)public onlyOwner{
             sellTreasury = newAmount;
    }
    function currentMaxWallet() public view returns(uint256){
        return maxWalletAmount;
    }
    function currentMaxTx() public view returns(uint256){
        return maxTxAmount;
    }
    function updateSwapTreshold(uint256 newVal) public onlyOwner{
        swapTreshold = newVal;
        requiredTokensToSwap = _totalSupply*swapTreshold/1000;
        
    }
    function currentTradeStatus() public view returns (bool){
        return tradeEnabled;   
    }
    function currentSwapTreshold() public view returns(uint256){
        return swapTreshold;
    }
    function currentTokensToSwap() public view returns(uint256){
        return requiredTokensToSwap;
    }
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
/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

//SPDX-License-Identifier: UNLICENSED
// File: contracts/Interfaces.sol



pragma solidity 0.8.16;

interface IOwnable {
    function owner() external view returns (address);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBurnable {
    function burn(address account, uint256 value) external;
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function depositNative() external payable;
    function depositToken(address from, uint256 amount) external;
    function process(uint256 gas) external;
    function inSwap() external view returns (bool);
}


interface ITaxDistributor {
    receive() external payable;
    function lastSwapTime() external view returns (uint256);
    function inSwap() external view returns (bool);
    function createWalletTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external;
    function createDistributorTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external;
    function createDividendTax(string memory name, uint256 buyTax, uint256 sellTax, address dividendDistributor, bool convertToNative) external;
    function createBurnTax(string memory name, uint256 buyTax, uint256 sellTax) external;
    function createLiquidityTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet) external;
    function distribute() external payable;
    function getSellTax() external view returns (uint256);
    function getBuyTax() external view returns (uint256);
    function setTaxWallet(string memory taxName, address wallet) external;
    function setSellTax(string memory taxName, uint256 taxPercentage) external;
    function setBuyTax(string memory taxName, uint256 taxPercentage) external;
    function takeSellTax(uint256 value) external returns (uint256);
    function takeBuyTax(uint256 value) external returns (uint256);
}

interface IWalletDistributor {
    function receiveToken(address token, address from, uint256 amount) external;
}

// File: contracts/TaxDistributor.sol




contract TaxDistributor is ITaxDistributor {

    address immutable public tokenPair;
    address immutable public routerAddress;
    address immutable private _token;
    address immutable private _wbnb;

    IDEXRouter private _router;

    bool public override inSwap;
    uint256 public override lastSwapTime;

    uint256 immutable public maxSellTax;
    uint256 immutable public maxBuyTax;

    enum TaxType { WALLET, DIVIDEND, LIQUIDITY, DISTRIBUTOR, BURN }
    struct Tax {
        string taxName;
        uint256 buyTaxPercentage;
        uint256 sellTaxPercentage;
        uint256 taxPool;
        TaxType taxType;
        address location;
        uint256 share;
        bool convertToNative;
    }
    Tax[] public taxes;

    event TaxesDistributed(uint256 tokensSwapped, uint256 ethReceived);
    event ConfigurationChanged(address indexed owner, string option);
    event DistributionError(string text);

    modifier onlyToken() {
        require(msg.sender == _token, "no permissions");
        _;
    }

    modifier swapLock() {
        require(inSwap == false, "already swapping");
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address router, address pair, address wbnb, uint256 _maxSellTax, uint256 _maxBuyTax) {
        require(wbnb != address(0), "wbnb cannot be 0 address");
        require(pair != address(0), "pair cannot be 0 address");
        require(router != address(0), "router cannot be 0 address");

        _token = msg.sender;
        _wbnb = wbnb;
        _router = IDEXRouter(router);
        maxSellTax = _maxSellTax;
        maxBuyTax = _maxBuyTax;
        tokenPair = pair;
        routerAddress = router;
    }

    receive() external override payable {}

    function createWalletTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.WALLET, wallet, 0, convertToNative));
        emit ConfigurationChanged(msg.sender, "Tax Created");
    }

    function createDistributorTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.DISTRIBUTOR, wallet, 0, convertToNative));
        emit ConfigurationChanged(msg.sender, "Tax Created");
    }
    
    function createDividendTax(string memory name, uint256 buyTax, uint256 sellTax, address dividendDistributor, bool convertToNative) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.DIVIDEND, dividendDistributor, 0, convertToNative));
        emit ConfigurationChanged(msg.sender, "Tax Created");
    }
    
    function createBurnTax(string memory name, uint256 buyTax, uint256 sellTax) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.BURN, address(0), 0, false));
        emit ConfigurationChanged(msg.sender, "Tax Created");
    }

    function createLiquidityTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.LIQUIDITY, wallet, 0, false));
        emit ConfigurationChanged(msg.sender, "Tax Created");
    }

    function distribute() public payable override onlyToken swapLock {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = _wbnb;
        IERC20 token = IERC20(_token);

        uint256 totalTokens;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].taxType == TaxType.LIQUIDITY) {
                uint256 half = taxes[i].taxPool / 2;
                totalTokens += taxes[i].taxPool - half;
            } else if (taxes[i].convertToNative) {
                totalTokens += taxes[i].taxPool;
            }
        }
        totalTokens = checkTokenAmount(token, totalTokens);
      
        if (checkTokenAmount(token, totalTokens) != totalTokens) {
            emit DistributionError("Insufficient tokens to swap. Please add more tokens");
            return;
        }

        uint256[] memory amts = _router.swapExactTokensForETH(
            totalTokens,
            0,
            path,
            address(this),
            block.timestamp + 300
        );

        uint256 amountBNB = address(this).balance;

        if (totalTokens != amts[0] || amountBNB != amts[1] ) {
            emit DistributionError("Unexpected amounts returned from swap");
        }

        // Calculate the distribution
        uint256 toDistribute = amountBNB;
        for (uint256 i = 0; i < taxes.length; i++) {

            if (taxes[i].convertToNative || taxes[i].taxType == TaxType.LIQUIDITY) {
                if (i == taxes.length - 1) {
                    taxes[i].share = toDistribute;
                } else if (taxes[i].taxType == TaxType.LIQUIDITY) {
                    uint256 half = taxes[i].taxPool / 2;
                    uint256 share = (amountBNB * (taxes[i].taxPool - half)) / totalTokens;
                    taxes[i].share = share;
                    toDistribute = toDistribute - share;
                } else {
                    uint256 share = (amountBNB * taxes[i].taxPool) / totalTokens;
                    taxes[i].share = share;
                    toDistribute = toDistribute - share;
                }
            }
        }

        // Distribute the coins
        for (uint256 i = 0; i < taxes.length; i++) {
            
            if (taxes[i].taxType == TaxType.WALLET) {
                if (taxes[i].convertToNative) {
                    payable(taxes[i].location).transfer(taxes[i].share);
                } else {
                    token.transfer(taxes[i].location, checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == TaxType.DISTRIBUTOR) {
                if (taxes[i].convertToNative) {
                    payable(taxes[i].location).transfer(taxes[i].share);
                } else {
                    token.approve(taxes[i].location, taxes[i].taxPool);
                    IWalletDistributor(taxes[i].location).receiveToken(_token, address(this), checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == TaxType.DIVIDEND) {
               if (taxes[i].convertToNative) {
                    IDividendDistributor(taxes[i].location).depositNative{value: taxes[i].share}();
                } else {
                    IDividendDistributor(taxes[i].location).depositToken(address(this), checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == TaxType.BURN) {
                IBurnable(_token).burn(address(this), checkTokenAmount(token, taxes[i].taxPool));
            }
            else if (taxes[i].taxType == TaxType.LIQUIDITY) {
                if(taxes[i].share > 0){
                    uint256 half = checkTokenAmount(token, taxes[i].taxPool / 2);
                    _router.addLiquidityETH{value: taxes[i].share}(
                        _token,
                        half,
                        0,
                        0,
                        taxes[i].location,
                        block.timestamp + 300
                    );
                }
            }
            
            taxes[i].taxPool = 0;
            taxes[i].share = 0;
        }

        emit TaxesDistributed(totalTokens, amountBNB);

        lastSwapTime = block.timestamp;
    }

    function getSellTax() public override onlyToken view returns (uint256) {
        uint256 taxAmount;
        for (uint256 i = 0; i < taxes.length; i++) {
            taxAmount += taxes[i].sellTaxPercentage;
        }
        return taxAmount;
    }

    function getBuyTax() public override onlyToken view returns (uint256) {
        uint256 taxAmount;
        for (uint256 i = 0; i < taxes.length; i++) {
            taxAmount += taxes[i].buyTaxPercentage;
        }
        return taxAmount;
    }
    
    function setTaxWallet(string memory taxName, address wallet) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].taxType == TaxType.WALLET && compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].location = wallet;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
        emit ConfigurationChanged(msg.sender, "Tax Wallet Changed");
    }

    function setSellTax(string memory taxName, uint256 taxPercentage) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].sellTaxPercentage = taxPercentage;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
        require(getSellTax() <= maxSellTax, "tax cannot be set this high");
        emit ConfigurationChanged(msg.sender, "Sell Tax Changed");
    }

    function setBuyTax(string memory taxName, uint256 taxPercentage) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            //if (taxes[i].taxName == taxName) {
            if (compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].buyTaxPercentage = taxPercentage;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
        require(getBuyTax() <= maxBuyTax, "tax cannot be set this high");
        emit ConfigurationChanged(msg.sender, "Buy Tax Changed");
    }

    function takeSellTax(uint256 value) external override onlyToken returns (uint256) {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].sellTaxPercentage > 0) {
                uint256 taxAmount = (value * taxes[i].sellTaxPercentage) / 10000;
                taxes[i].taxPool += taxAmount;
                value = value - taxAmount;
            }
        }
        return value;
    }

    function takeBuyTax(uint256 value) external override onlyToken returns (uint256) {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].buyTaxPercentage > 0) {
                uint256 taxAmount = (value * taxes[i].buyTaxPercentage) / 10000;
                taxes[i].taxPool += taxAmount;
                value = value - taxAmount;
            }
        }
        return value;
    }
    
    
    
    // Private methods
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function checkTokenAmount(IERC20 token, uint256 amount) private view returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        if (balance > amount) {
            return amount;
        }
        return balance;
    }
}

// File: contracts/BaseErc20.sol



abstract contract BaseErc20 is IERC20, IOwnable {

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    uint256 internal _totalSupply;
    bool internal _useSafeTransfer;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    
    address public override owner;
    bool public isTradingEnabled = true;
    bool public launched;
    
    mapping (address => bool) public canAlwaysTrade;
    mapping (address => bool) public excludedFromSelling;
    mapping (address => bool) public exchanges;
    
    event ConfigurationChanged(address indexed owner, string option);

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }
    
    modifier isLaunched() {
        require(launched, "can only be called once token is launched");
        _;
    }

    // @dev Trading is allowed before launch if the sender is the owner, we are transferring from the owner, or in canAlwaysTrade list
    modifier tradingEnabled(address from) {
        require((isTradingEnabled && launched) || from == owner || canAlwaysTrade[msg.sender], "trading not enabled");
        _;
    }
    

    function configure(address _owner) internal virtual {
        owner = _owner;
        canAlwaysTrade[owner] = true;
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) external override view returns (uint256) {
        return _balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address spender) external override view returns (uint256) {
        return _allowed[_owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public override tradingEnabled(msg.sender) returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external override tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) external override tradingEnabled(from) returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) external tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender] + addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender] - subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    
    
    // Virtual methods
    function launch() virtual public onlyOwner {
        launched = true;
        emit ConfigurationChanged(msg.sender, "Token Launched");
    }
    
    function preTransfer(address from, address to, uint256 value) virtual internal { }

    function calculateTransferAmount(address from, address to, uint256 value) virtual internal returns (uint256) {
        require(from != to, "you cannot transfer to yourself");
        return value;
    }
    
    function postTransfer(address from, address to) virtual internal { }
    


    // Admin methods
    function changeOwner(address who) external onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
        emit ConfigurationChanged(msg.sender, "Owner Changed");
    }

    function removeBnb() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit ConfigurationChanged(msg.sender, "Native Token Removed");
    }

    function transferTokens(address token, address to) external onlyOwner returns(bool){
        uint256 balance = IERC20(token).balanceOf(address(this));
        emit ConfigurationChanged(msg.sender, "Custom Token Removed");
        return IERC20(token).transfer(to, balance);
    }

    function setTradingEnabled(bool enabled) external onlyOwner {
        isTradingEnabled = enabled;
        emit ConfigurationChanged(msg.sender, "Enable/Disable Trading");
    }
    
    function setCanAlwaysTrade(address who, bool enabled) external onlyOwner {
        canAlwaysTrade[who] = enabled;
        emit ConfigurationChanged(msg.sender, "Always Trade List Changed");
    }
    
    function setExchange(address who, bool isExchange) external onlyOwner {
        exchanges[who] = isExchange;
        emit ConfigurationChanged(msg.sender, "Exchanges Changed");
    }
    
    function setExcludedFromSelling(address who, bool isExcluded) external onlyOwner {
        excludedFromSelling[who] = isExcluded;
        emit ConfigurationChanged(msg.sender, "Selling Exclusion Changed");
    }

    
    // Private methods

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "cannot be zero address");
        require(excludedFromSelling[from] == false, "address is not allowed to sell");
        
        preTransfer(from, to, value);

        uint256 modifiedAmount = calculateTransferAmount(from, to, value);
        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + modifiedAmount;

        emit Transfer(from, to, modifiedAmount);

        postTransfer(from, to);
    }
}
// File: contracts/AntiSniper.sol



abstract contract AntiSniper is BaseErc20 {

    bool public enableSniperBlocking;
    bool public enableBlockLogProtection;

    uint256 public maxGasLimit;

    uint256 public launchTime;
    uint256 public launchBlock;
    uint256 public snipersCaught;
    
    mapping (address => bool) public isSniper;
    mapping (address => bool) public isNeverSniper;
    mapping (address => uint256) public transactionBlockLog;
    
    // Overrides
    
    function configure(address _owner) internal virtual override {
        isNeverSniper[_owner] = true;
        super.configure(_owner);
    }
    
    function launch() override virtual public onlyOwner {
        super.launch();
        launchTime = block.timestamp;
        launchBlock = block.number;
        emit ConfigurationChanged(msg.sender, "Anti Sniper Launched");
    }
    
    function preTransfer(address from, address to, uint256 value) override virtual internal {
        require(enableSniperBlocking == false || isSniper[msg.sender] == false, "sniper rejected");
        
        if (launched && from != owner && isNeverSniper[from] == false && isNeverSniper[to] == false) {
            
            if (maxGasLimit > 0) {
               require(gasleft() <= maxGasLimit, "this is over the max gas limit");
            }
            
            if(enableBlockLogProtection) {
                if (transactionBlockLog[to] == block.number) {
                    isSniper[to] = true;
                    snipersCaught ++;
                }
                if (transactionBlockLog[from] == block.number) {
                    isSniper[from] = true;
                    snipersCaught ++;
                }
                if (exchanges[to] == false) {
                    transactionBlockLog[to] = block.number;
                }
                if (exchanges[from] == false) {
                    transactionBlockLog[from] = block.number;
                }
            }
        }
        
        super.preTransfer(from, to, value);
    }

    
    // Admin methods
       
    function setSniperBlocking(bool enabled) external onlyOwner {
        enableSniperBlocking = enabled;
        emit ConfigurationChanged(msg.sender, "Enable/Disable Sniper Blocking");
    }
    
    function setBlockLogProtection(bool enabled) external onlyOwner {
        enableBlockLogProtection = enabled;
        emit ConfigurationChanged(msg.sender, "Enable/Disable Block Log Protection");
    }

    function setMaxGasLimit(uint256 amount) external onlyOwner {
        require(amount == 0 || amount > 200, "This gas limit is too low");
        maxGasLimit = amount;
        emit ConfigurationChanged(msg.sender, "Max Gas Limit Changed");
    }
    
    function setIsSniper(address who, bool enabled) external onlyOwner {
        isSniper[who] = enabled;
        emit ConfigurationChanged(msg.sender, "Sniper List Changed");
    }

    function setNeverSniper(address who, bool enabled) external onlyOwner {
        isNeverSniper[who] = enabled;
        emit ConfigurationChanged(msg.sender, "Never Sniper List Changed");
    }

    // private methods
}
// File: contracts/Taxable.sol




abstract contract Taxable is BaseErc20 {
    
    ITaxDistributor taxDistributor;

    bool public autoSwapTax;
    uint256 public minimumTimeBetweenSwaps;
    uint256 public minimumTokensBeforeSwap;
    mapping (address => bool) public excludedFromTax;
    uint256 swapStartTime;
    
    // Overrides
    
    function configure(address _owner) internal virtual override {
        excludedFromTax[_owner] = true;
        super.configure(_owner);
    }
    
    
    function calculateTransferAmount(address from, address to, uint256 value) internal virtual override returns (uint256) {
        
        uint256 amountAfterTax = value;

        if (excludedFromTax[from] == false && excludedFromTax[to] == false && launched) {
            if (exchanges[from]) {
                // we are BUYING
                amountAfterTax = taxDistributor.takeBuyTax(value);
            } else if (exchanges[to]) {
                // we are SELLING
                amountAfterTax = taxDistributor.takeSellTax(value);
            }
        }

        uint256 taxAmount = value - amountAfterTax;
        if (taxAmount > 0) {
            _balances[address(taxDistributor)] = _balances[address(taxDistributor)] + taxAmount;
            emit Transfer(from, address(taxDistributor), taxAmount);
        }
        
        return super.calculateTransferAmount(from, to, amountAfterTax);
    }


    function preTransfer(address from, address to, uint256 value) override virtual internal {
        uint256 timeSinceLastSwap = block.timestamp - taxDistributor.lastSwapTime();
        if (
            launched && 
            autoSwapTax && 
            exchanges[to] && 
            swapStartTime + 60 <= block.timestamp &&
            timeSinceLastSwap >= minimumTimeBetweenSwaps &&
            _balances[address(taxDistributor)] >= minimumTokensBeforeSwap &&
            taxDistributor.inSwap() == false
        ) {
            swapStartTime = block.timestamp;
            try taxDistributor.distribute() {} catch {}
        }
        super.preTransfer(from, to, value);
    }
    
    
    // Public methods
    
    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function sellTax() public view returns (uint256) {
        return taxDistributor.getSellTax();
    }

    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function buyTax() public view returns (uint256) {
        return taxDistributor.getBuyTax();
    }

    /**
     * @dev Return the address of the tax distributor contract
     */
    function taxDistributorAddress() public view returns (address) {
        return address(taxDistributor);
    }    
    
    
    // Admin methods

    function setAutoSwaptax(bool enabled) external onlyOwner {
        autoSwapTax = enabled;
        emit ConfigurationChanged(msg.sender, "Enable/Disable Auto Tax Swap");
    }

    function setExcludedFromTax(address who, bool enabled) external onlyOwner {
        excludedFromTax[who] = enabled;
        emit ConfigurationChanged(msg.sender, "Tax Exlusion List Changed");
    }

    function setTaxDistributionThresholds(uint256 minAmount, uint256 minTime) external onlyOwner {
        require(minimumTokensBeforeSwap > 1 * 10 ** decimals && minimumTokensBeforeSwap < 100_000 * 10 ** decimals, "Invalid minAmount value");
        require(minimumTimeBetweenSwaps > 1 minutes && minimumTimeBetweenSwaps < 1 days, "Invalid minTime value");
        minimumTokensBeforeSwap = minAmount;
        minimumTimeBetweenSwaps = minTime;
        emit ConfigurationChanged(msg.sender, "Distribution Thresholds Changed");
    }
    
    function setSellTax(string memory taxName, uint256 taxAmount) external onlyOwner {
        taxDistributor.setSellTax(taxName, taxAmount);
        emit ConfigurationChanged(msg.sender, "Sell Tax Changed");
    }

    function setBuyTax(string memory taxName, uint256 taxAmount) external onlyOwner {
        taxDistributor.setBuyTax(taxName, taxAmount);
        emit ConfigurationChanged(msg.sender, "Buy Tax Changed");
    }
    
    function setTaxWallet(string memory taxName, address wallet) external onlyOwner {
        taxDistributor.setTaxWallet(taxName, wallet);
        emit ConfigurationChanged(msg.sender, "Tax Wallet Changed");
    }
    
    function runSwapManually() external onlyOwner isLaunched {
        taxDistributor.distribute();
    }
}
// File: contracts/Burnable.sol



abstract contract Burnable is BaseErc20, IBurnable {
    
    mapping (address => bool) public ableToBurn;

    modifier onlyBurner() {
        require(ableToBurn[msg.sender], "no burn permissions");
        _;
    }

    // Overrides
    
    function configure(address _owner) internal virtual override {
        ableToBurn[_owner] = true;
        super.configure(_owner);
    }
    
    
    // Admin methods

    function setAbleToBurn(address who, bool enabled) external onlyOwner {
        ableToBurn[who] = enabled;
        emit ConfigurationChanged(msg.sender, "Burner List Changed");
    }


    // Private methods

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function burn(address account, uint256 value) external override onlyBurner {
        require(account != address(0), "Cannot burn from the 0 address");
        _allowed[account][msg.sender] = _allowed[account][msg.sender] - value;

        _totalSupply = _totalSupply - value;
        _balances[account] = _balances[account] - value;
        emit Transfer(account, address(0), value);
    }
}
// File: contracts/Swing.sol





contract SwingDao is BaseErc20, AntiSniper, Burnable, Taxable {

    constructor () {
        configure(0xcbFA1ce0b8bFb9C09E713162771C31F176fB1ADE);

        symbol = "SWING";
        name = "Swing DAO";
        decimals = 18;

        address routerAddress;

        if (block.chainid == 1 || block.chainid == 3 || block.chainid == 4) {
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ; // ETHEREUM
        } else if (block.chainid == 56) {
            routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC MAINNET
        } else if (block.chainid == 97) {
            routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // BSC TESTNET
        } else {
            revert("Unknown Chain ID");
        }

        IDEXRouter router = IDEXRouter(routerAddress);
        address WBNB = router.WETH();
        address pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        exchanges[pair] = true;
        taxDistributor = new TaxDistributor(routerAddress, pair, WBNB, 1200, 1200);

        // Anti Sniper
        enableSniperBlocking = true;
        isNeverSniper[address(taxDistributor)] = true;

        // Tax
        minimumTimeBetweenSwaps = 5 minutes;
        minimumTokensBeforeSwap = 1000 * 10 ** decimals;
        excludedFromTax[address(taxDistributor)] = true;
        taxDistributor.createLiquidityTax("Liquidity", 200, 200, 0x000000000000000000000000000000000000dEaD);
        taxDistributor.createBurnTax("Burn", 200, 200);
        taxDistributor.createWalletTax("Treasury", 400, 400, 0xe6C27689Ce4F522C59c49503A322A93ece5072D7, true);
        taxDistributor.createWalletTax("Development", 400, 400, 0xB0DcAA001EEE1fFda04BD3772B4a90EebeD619A4, true);
        autoSwapTax = true;

        // Burnable
        ableToBurn[address(taxDistributor)] = true;


        _allowed[address(taxDistributor)][routerAddress] = 2**256 - 1;
        _totalSupply = _totalSupply + (1_500_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner] + _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides
    
    function launch() public override(AntiSniper, BaseErc20) onlyOwner {
        super.launch();
        emit ConfigurationChanged(msg.sender, "Swing Token Launched");
    }

    function configure(address _owner) internal override(AntiSniper, Burnable, Taxable, BaseErc20) {
        super.configure(_owner);
    }
    
    function preTransfer(address from, address to, uint256 value) override(AntiSniper, Taxable, BaseErc20) internal {
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) override(Taxable, BaseErc20) internal returns (uint256) {
        return super.calculateTransferAmount(from, to, value);
    }
    
    function postTransfer(address from, address to) override(BaseErc20) internal {
        super.postTransfer(from, to);
    }
}
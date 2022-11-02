/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IDEXPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDEXRouter {
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

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IReferral {
    function checkReferral(address seller, uint256 bal) external;
}

contract PerpetualMotion is IERC20, Ownable {
    using Address for address;
    
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Perpetual Motion";
    string constant _symbol = "MOTION";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1_000_000 * (10 ** _decimals);

    uint256 _maxWalletSize = 10; //1%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) lastSell;
    mapping (address => uint256) lastSellAmount;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isLimitExempt;

    uint256 generalFee = 48;
    uint256 generalSellFee = 34;
    uint256 feeDenominator = 1000;
    bool public transferTax = true;
    bool public buyFeesEnabled = true;
    bool public sellFeesEnabled = true;

    uint256 antiDumpTax = 300;
    uint256 antiDumpPeriod = 30 minutes;
    uint256 antiDumpThreshold = 210;
    bool antiDumpReserve0 = true;

    address public constant liquidityReceiver = DEAD;
    address payable public immutable generalReceiver;

    uint256 targetLiquidity = 10;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public immutable router;
    
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping (address => bool) liquidityPools;
    mapping (address => bool) liquidityProviders;

    address public initialPair;

    uint256 public launchedAt;
    uint256 public launchedTime;
    uint256 public deadBlocks;
 
    bool public protectionEnabled = false;
    bool public protectionDisabled = false;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 500; //0.2%
    uint256 public swapMinimum = _totalSupply / 10000; //0.01%
    uint256 public maxSwapPercent = 75;

    uint256 public unlocksAt;
    address public locker;

    IReferral ref;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address _liquidityProvider, address _generalWallet, address _ref) {
        generalReceiver = payable(_generalWallet);

        router = IDEXRouter(routerAddress);
        _allowances[_liquidityProvider][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;
        
        isFeeExempt[_liquidityProvider] = true;
        liquidityProviders[_liquidityProvider] = true;

        isLimitExempt[address(this)] = true;
        isLimitExempt[_liquidityProvider] = true;
        isLimitExempt[routerAddress] = true;

        _balances[_liquidityProvider] = _totalSupply;
        emit Transfer(address(0), _liquidityProvider, _totalSupply);

        ref = IReferral(_ref);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below address(0)");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the address(0) address");
        require(spender != address(0), "ERC20: approve to the address(0) address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(amount > 0, "ERC20: No tokens transferred");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if (!liquidityPools[recipient] && recipient != DEAD) {
            if (!isLimitExempt[recipient]) checkWalletLimit(recipient, amount);
        }

        if(!liquidityPools[sender] && shouldTakeFee(sender) && _balances[sender] - amount == 0) {
            amount -= 1;
        }

        _balances[sender] -= amount;

        if(!liquidityPools[sender]) try ref.checkReferral(sender, _balances[sender]) {} catch {}
        
        uint256 amountReceived = amount;
        if(shouldTakeFee(msg.sender) && shouldTakeFee(sender) && shouldTakeFee(recipient)) {
            if(transferTax || (liquidityPools[sender] || liquidityPools[recipient])) amountReceived = takeFee(sender, recipient, amount);
        
            if(shouldSwapBack(sender, recipient)){ if (amount > 0) swapBack(amount); }
        }

        if(recipient != DEAD)
            _balances[recipient] += amountReceived;
        else
            _totalSupply -= amountReceived;

        emit Transfer(sender, (recipient != DEAD ? recipient : address(0)), amountReceived);
        return true;
    }

    function freeTransfer(address recipient, uint256 amount) external {
        require(!shouldTakeFee(msg.sender), "Not authorised");
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(amount > 0, "ERC20: No tokens transferred");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _basicTransfer(msg.sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function checkWalletLimit(address recipient, uint256 amount) internal view {
        require(_balances[recipient] + amount <= getMaximumWallet(), "Transfer amount exceeds the bag size.");
    }

    function shouldTakeFee(address sender) public view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + deadBlocks > block.number){ return feeDenominator - 1; }
        return (selling ? (sellFeesEnabled ? generalSellFee : 0) : (buyFeesEnabled ? generalFee : 0));
    }

    function checkImpactEstimate(address pair, uint256 amount) public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = IDEXPair(pair).getReserves();
        return amount * 1000 / ((antiDumpReserve0 ? reserve0 : reserve1) + amount);
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        
        if(liquidityPools[recipient]) {
            if (!sellFeesEnabled) return amount;
            if(antiDumpTax > 0) {
                uint256 impactEstimate = checkImpactEstimate(recipient, amount);
                
                if (block.timestamp > lastSell[sender] + antiDumpPeriod) {
                    lastSell[sender] = block.timestamp;
                    lastSellAmount[sender] = 0;
                }
                
                lastSellAmount[sender] += impactEstimate;
                
                if (lastSellAmount[sender] >= antiDumpThreshold) {
                    feeAmount = ((amount * generalSellFee * antiDumpTax) / 100) / feeDenominator;
                }
            }
        }

        if (feeAmount == 0)
            feeAmount = (amount * getTotalFee(liquidityPools[recipient])) / feeDenominator;

        if (feeAmount > 0) {
            _balances[address(this)] += feeAmount;
            emit Transfer(sender, address(this), feeAmount);
            return amount - feeAmount;
        } else
            return amount;
    }

    function shouldSwapBack(address sender, address recipient) internal view returns (bool) {
        return !liquidityPools[sender]
        && !inSwap
        && swapEnabled
        && liquidityPools[recipient]
        && _balances[address(this)] >= swapMinimum;
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 amountToSwap = amount - (amount * maxSwapPercent / 100) < swapThreshold ? amount * maxSwapPercent / 100 : swapThreshold;
        if (_balances[address(this)] < amountToSwap) amountToSwap = _balances[address(this)];

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        //Guaranteed swap desired to prevent trade blockages
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(address(0)));
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(owner() == _msgSender(), "Caller is not authorized");
        isFeeExempt[owner()] = false;
        isLimitExempt[owner()] = false;
        liquidityProviders[owner()] = false;
        _allowances[owner()][routerAddress] = 0;
        super.transferOwnership(newOwner);
    }

    function lockContract(uint256 _weeks) external onlyOwner {
        require(locker == address(0), "Contract already locked");
        require(_weeks > 0, "No lock period specified");
        unlocksAt = block.timestamp + (_weeks * 1 weeks);
        locker = owner();
        super.renounceOwnership();
    }

    function unlockContract() external {
        require(locker != address(0) && (msg.sender == locker || liquidityProviders[msg.sender]), "Caller is not authorized");
        require(unlocksAt <= block.timestamp, "Contract still locked");
        super.transferOwnership(locker);
        locker = address(0);
        unlocksAt = 0;
    }

    function renounceOwnership() public virtual override onlyOwner {
        isFeeExempt[owner()] = false;
        isLimitExempt[owner()] = false;
        liquidityProviders[owner()] = false;
        _allowances[owner()][routerAddress] = 0;
        super.renounceOwnership();
    }

    function _checkOwner() internal view virtual override {
        require(owner() != address(0) && (owner() == _msgSender() || liquidityProviders[_msgSender()]), "Ownable: caller is not authorized");
    }
    
    function setLiquidityProvider(address _provider, bool _set) external onlyOwner {
        require(!liquidityPools[_provider] && _provider != routerAddress, "Can't alter trading contracts in this manner.");
        isFeeExempt[_provider] = _set;
        liquidityProviders[_provider] = _set;
        isLimitExempt[_provider] = _set;
        emit LiquidityProviderSet(_provider, _set);
    }

    function extractETH() external {
        require(msg.sender == owner() || msg.sender == generalReceiver, "Not Authorised");
        uint256 bal = address(this).balance;
        require(bal > 0, "No ETH to extract");

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent,"Failed to transfer funds");
    }

    function toggleAntiDumpTax(bool _enabled, bool _reserve0) external onlyOwner {
        if(!_enabled) {
            antiDumpTax = 0;
            emit AntiDumpTaxDisabled();
        } else {
            antiDumpTax = 300;
            emit AntiDumpTaxEnabled(antiDumpTax, antiDumpPeriod, antiDumpThreshold);
        }
        antiDumpReserve0 = _reserve0;

    }

    function launch(uint256 tokens, uint256 _deadBlocks, bool purchase, address[] calldata _wallets) external payable onlyOwner {
        require(launchedAt == 0 && _deadBlocks < 7);
        require(msg.value > 0, "Insufficient funds");
        require(tokens > 0, "No LP tokens specified");
        uint256 toLP = msg.value;
        uint256 initialPurchase = (purchase ? toLP / 3 : 0);
        toLP -= initialPurchase;

        IDEXFactory factory = IDEXFactory(router.factory());
        address ETH = router.WETH();

        initialPair = factory.getPair(ETH, address(this));
        if(initialPair == address(0))
            initialPair = factory.createPair(ETH, address(this));

        liquidityPools[initialPair] = true;
        isFeeExempt[address(this)] = true;
        liquidityProviders[address(this)] = true;

        _basicTransfer(msg.sender, address(this), tokens * (10 ** _decimals));

        router.addLiquidityETH{value: toLP}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);

        deadBlocks = _deadBlocks;
        launchedAt = block.number;
        launchedTime = block.timestamp;

        if(purchase) {
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(this);

            if(_wallets.length > 0) {
                for(uint256 i = 0; i < _wallets.length; i++) {
                    router.swapETHForExactTokens{value: address(this).balance} (
                        getMaximumWallet(),
                        path,
                        _wallets[i],
                        block.timestamp
                    );
                }
            }

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(
            0,
            path,
            msg.sender,
            block.timestamp
            );
        }
    }
    
    function setMaxWallet(uint256 thousandths) external onlyOwner() {
        require(thousandths > 1, "Wallet limits too low");
        _maxWalletSize = thousandths;
        emit MaxWalletSet(getMaximumWallet());
    }

    function getMaximumWallet() public view returns (uint256) {
        if(launchedAt == 0) return 0;
        return getCirculatingSupply() * _maxWalletSize / 1000;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(0), "Invalid address");
        isFeeExempt[holder] = exempt;
        emit FeeExemptSet(holder, exempt);
    }

    function setIsLimitExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(0), "Invalid address");
        isLimitExempt[holder] = exempt;
        emit LimitExemptSet(holder, exempt);
    }

    function toggleFees(bool _buyEnabled, bool _sellEnabled) external onlyOwner {
        buyFeesEnabled = _buyEnabled;
        sellFeesEnabled = _sellEnabled;
        if(buyFeesEnabled || sellFeesEnabled)
            emit FeesEnabled();
        else
            emit FeesDisabled();
    }

    function setSwapBackSettings(bool _enabled, uint256 _denominator, uint256 _denominatorMin) external onlyOwner {
        require(_denominator > 0 && _denominatorMin > 0, "Denominators must be greater than 0");
        swapEnabled = _enabled;
        swapMinimum = _totalSupply / _denominatorMin;
        swapThreshold = _totalSupply / _denominator;
        emit SwapSettingsSet(swapMinimum, swapThreshold, swapEnabled);
    }

    function addLiquidityPool(address _pool, bool _enabled) external onlyOwner {
        require(_pool != address(0), "Invalid address");
        liquidityPools[_pool] = _enabled;
        if(initialPair == address(0)) initialPair == _pool;
        emit LiquidityPoolSet(_pool, _enabled);
    }

	function airdrop(address[] calldata _addresses, uint256[] calldata _amount) external onlyOwner
    {
        require(_addresses.length == _amount.length, "Array lengths don't match");
        bool previousSwap = swapEnabled;
        swapEnabled = false;
        //This function may run out of gas intentionally to prevent partial airdrops
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(!liquidityPools[_addresses[i]] && _addresses[i] != address(0), "Can't airdrop the liquidity pool or address 0");
            _transferFrom(msg.sender, _addresses[i], _amount[i] * (10 ** _decimals));
        }
        swapEnabled = previousSwap;
        emit AirdropSent(msg.sender);
    }

    event LiquidityProviderSet(address indexed provider, bool isSet);
    event MaxWalletSet(uint256 limit);
    event FeeExemptSet(address indexed wallet, bool isExempt);
    event LimitExemptSet(address indexed wallet, bool isExempt);
    event FeesEnabled();
    event FeesDisabled();
    event SwapSettingsSet(uint256 minimum, uint256 maximum, bool enabled);
    event LiquidityPoolSet(address indexed pool, bool enabled);
    event AirdropSent(address indexed from);
    event AntiDumpTaxEnabled(uint256 rate, uint256 period, uint256 threshold);
    event AntiDumpTaxDisabled();
}
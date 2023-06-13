/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

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
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract TokenShmoken is IERC20, Ownable {
    using Address for address;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "TokenSchmoken";
    string constant _symbol = "TKSH";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 4200000000000 * (10 ** _decimals);
    uint256 _maxBuyTxAmount = _totalSupply;
    uint256 _maxSellTxAmount = _totalSupply;
    uint256 _maxWalletSize = _totalSupply;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public liquidityCreator;

    uint256 marketingFee = 0;
    uint256 marketingSellFee = 0;
    uint256 totalBuyFee = marketingFee;
    uint256 totalSellFee = marketingSellFee;
    uint256 feeDenominator = 10000;
    bool public transferTax = false;

    address payable private marketingFeeReceiver;

    IDEXRouter public router;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    mapping (address => bool) liquidityPools;

    address public pair;

    uint256 public launchedAt;
    uint256 public launchedTime;
    bool startBullRun = false;
    bool pauseDisabled = false;

    bool public swapEnabled = false;
    uint256 public swapThreshold = _totalSupply / 1000;
    uint256 public swapMinimum = _totalSupply / 10000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    mapping (address => bool) teamMember;

    modifier onlyTeam() {
        require(teamMember[_msgSender()] || msg.sender == owner(), "Caller is not a team member");
        _;
    }

    constructor (address _marketingWallet) {
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        liquidityPools[pair] = true;
        _allowances[owner()][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;

        isFeeExempt[owner()] = true;
        liquidityCreator[owner()] = true;

        marketingFeeReceiver = payable(_marketingWallet);

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[routerAddress] = true;
        isTxLimitExempt[DEAD] = true;

        _balances[owner()] = _totalSupply;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function maxBuyTxTokens() external view returns (uint256) { return _maxBuyTxAmount / (10 ** _decimals); }
    function maxSellTxTokens() external view returns (uint256) { return _maxSellTxAmount / (10 ** _decimals); }
    function maxWalletTokens() external view returns (uint256) { return _maxWalletSize / (10 ** _decimals); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function setTeamMember(address _team, bool _enabled) external onlyOwner {
        teamMember[_team] = _enabled;
    }

    function airdrop(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        require(addresses.length > 0 && amounts.length == addresses.length);
        address from = msg.sender;

        for (uint i = 0; i < addresses.length; i++) {
            if(!liquidityPools[addresses[i]] && !liquidityCreator[addresses[i]]) {
                _basicTransfer(from, addresses[i], amounts[i] * (10 ** _decimals));
            }
        }
    }

    function clearStuckBalance(uint256 amountPercentage, address adr) external onlyTeam {
        uint256 amountETH = address(this).balance;

        if(amountETH > 0) {
            (bool sent, ) = adr.call{value: (amountETH * amountPercentage) / 100}("");
            require(sent,"Failed to transfer funds");
        }
    }

    function manualswap(uint256 amount) external {
        require(amount <= balanceOf(address(this)) && amount > 0, "Wrong amount");

          address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function manualsend() external {
        bool success;
        (success, ) = address(marketingFeeReceiver).call{
            value: address(this).balance
        }("");
    }

    function openTrading() external onlyTeam {
        require(!startBullRun);
        startBullRun = true;
        marketingFee = 9800;
        marketingSellFee = 9800;
        totalBuyFee = marketingFee;
        totalSellFee = marketingSellFee;

        launchedAt = block.number;
        launchedTime = block.timestamp;
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
        require(sender != address(0), "ERC20: transfer from 0x0");
        require(recipient != address(0), "ERC20: transfer to 0x0");
        require(amount > 0, "Amount must be > zero");
        require(_balances[sender] >= amount, "Insufficient balance");
        if(!launched() && liquidityPools[recipient]){ require(liquidityCreator[sender], "Liquidity not added yet."); }
        if(!startBullRun){ require(liquidityCreator[sender] || liquidityCreator[recipient], "Trading not open yet."); }

        checkTxLimit(sender, recipient, amount);

        if (!liquidityPools[recipient] && recipient != DEAD) {
            if (!isTxLimitExempt[recipient]) {
                checkWalletLimit(recipient, amount);
            }
        }

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = amount;

        if(shouldTakeFee(sender, recipient)) {
            amountReceived = takeFee(recipient, amount);
            if(shouldSwapBack(recipient) && amount > 0) swapBack(amount);
        }

        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() external onlyTeam {
        launchedAt = block.number;
        launchedTime = block.timestamp;
        swapEnabled = true;

        marketingFee = 1000;
        marketingSellFee = 9900;
        totalBuyFee = marketingFee;
        totalSellFee = marketingSellFee;

        _maxBuyTxAmount =   13800000000  * 1e18;
        _maxWalletSize =   13800000000  * 1e18;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        uint256 walletLimit = _maxWalletSize;
        require(_balances[recipient] + amount <= walletLimit, "Transfer amount exceeds the bag size.");
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if (isTxLimitExempt[sender] || isTxLimitExempt[recipient]) return;
        require(amount <= (liquidityPools[sender] ? _maxBuyTxAmount : _maxSellTxAmount), "TX Limit Exceeded");

    }

    function shouldTakeFee(address sender, address recipient) public view returns (bool) {
        if(!transferTax && !liquidityPools[recipient] && !liquidityPools[sender]) return false;
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (selling) return totalSellFee;
        return totalBuyFee;
    }

    function takeFee(address recipient, uint256 amount) internal returns (uint256) {
        bool selling = liquidityPools[recipient];
        uint256 feeAmount = (amount * getTotalFee(selling)) / feeDenominator;

        _balances[address(this)] += feeAmount;

        return amount - feeAmount;
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return !liquidityPools[msg.sender]
        && !inSwap
        && swapEnabled
        && liquidityPools[recipient]
        && _balances[address(this)] >= swapMinimum
        && totalBuyFee + totalSellFee > 0;
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 amountToSwap = amount < swapThreshold ? amount : swapThreshold;
        if (_balances[address(this)] < amountToSwap) amountToSwap = _balances[address(this)];

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance - balanceBefore;

        uint256 amountETHMarketing = amountETH;

        if (amountETHMarketing > 0) {
            (bool sentMarketing, ) = marketingFeeReceiver.call{value: amountETHMarketing}("");
            if(!sentMarketing) {
                //Failed to transfer to marketing wallet
            }
        }

        emit FundsDistributed(amountETHMarketing);
    }

    function addLiquidityPool(address lp, bool isPool) external onlyOwner {
        require(lp != pair, "Can't alter current liquidity pair");
        liquidityPools[lp] = isPool;
    }


    function setTxLimit(uint256 buyNumerator, uint256 sellNumerator, uint256 divisor) external onlyOwner {
       require(buyNumerator > 0 && sellNumerator > 0 && divisor > 0 && divisor <= 10000);
       _maxBuyTxAmount = (_totalSupply * buyNumerator) / divisor;
       _maxSellTxAmount = (_totalSupply * sellNumerator) / divisor;
   }

    function setMaxWallet(uint256 numerator, uint256 divisor) external onlyOwner() {
        require(numerator > 0 && divisor > 0 && divisor <= 10000);
        _maxWalletSize = (_totalSupply * numerator) / divisor;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _marketingFee, uint256 _marketingSellFee, uint256 _feeDenominator) external onlyOwner {
        marketingFee = _marketingFee;
        marketingSellFee = _marketingSellFee;
        totalBuyFee = _marketingFee;
        totalSellFee = _marketingSellFee;
        feeDenominator = _feeDenominator;
        require(totalBuyFee <= feeDenominator, "Fees too high");
        emit FeesSet(totalBuyFee, totalSellFee, feeDenominator);
    }

    function toggleTransferTax() external onlyOwner {
        transferTax = !transferTax;
    }

    function setFeeReceivers(address _marketingFeeReceiver) external onlyOwner {
        marketingFeeReceiver = payable(_marketingFeeReceiver);
    }

    function setSwapBackSettings(bool _enabled, uint256 _denominator, uint256 _swapMinimum) external onlyOwner {
        require(_denominator > 0);
        swapEnabled = _enabled;
        swapThreshold = _totalSupply / _denominator;
        swapMinimum = _swapMinimum * (10 ** _decimals);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(ZERO));
    }

    event FundsDistributed(uint256 marketingETH);
    event FeesSet(uint256 totalBuyFees, uint256 totalSellFees, uint256 denominator);
}
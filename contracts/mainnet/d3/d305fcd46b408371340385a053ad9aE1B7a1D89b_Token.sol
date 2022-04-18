// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, TOKEN the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

contract Token is Context, ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _holders;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromTax;
    mapping(address => bool) private _isExcludedFromMaxTx;

    string private _name = "Astrix";
    string private _symbol = "AIX";
    uint8 private _decimals = 18;
    uint256 private _tTotal = 500000000 * 1e18;

    IUniswapV2Router02 public uniswapRouter;
    address public immutable uniSwapPair;

    address payable private marketingWallet;

    uint256 _marketingTax;
    uint256 public _buyMarketingTax = 60; // 6% 
    uint256 public _sellMarketingTax = 100; //10%
    uint256 public _normalTransferTax = 10; // 1%

    bool inSwapAndLiquify = false;
    bool public swapAndLiquifyEnabled = true;
    

    uint256 public maxSellTransaction = 5000000 * 10**18; // 1% of total suppy
    uint256 public maxBuyTransaction = 10000000 * 10**18; // 2% of total suppy
    uint256 public minTokenNumberToSell = 500000 * 10**18; // 0.1% of total supply

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address payable _marketingWallet) {
        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        // Create a Uniswap pair for this new token
        uniSwapPair = IUniswapV2Factory(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH()
        );

        // set the rest of the contract variables
        uniswapRouter = _uniswapRouter;
        marketingWallet = _marketingWallet;

        //exclude owner and this contract from Tax
        _isExcludedFromTax[owner()] = true;
        _isExcludedFromTax[address(this)] = true;
        _isExcludedFromTax[_marketingWallet] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[_marketingWallet] = true;

        _holders[owner()] = _tTotal;
        emit Transfer(address(0), owner(), _tTotal);
    }

    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _holders[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "TOKEN: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "TOKEN: decreased allowance below zero"
            )
        );
        return true;
    }

    // getter functions

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isExcludedFromTax(address account) public view returns (bool) {
        return _isExcludedFromTax[account];
    }

    function excludeFromTax(address account) external onlyOwner {
        _isExcludedFromTax[account] = true;
    }

    function includeInTax(address account) external onlyOwner {
        _isExcludedFromTax[account] = false;
    }

    function setAmountLimits(uint256 _maxSellTxAmount, uint256 _maxBuyTxAmount)
        external
        onlyOwner
    {
        require(_maxSellTxAmount >= 150000 * 1e18);
        maxSellTransaction = _maxSellTxAmount;
        maxBuyTransaction = _maxBuyTxAmount;
    }

    function removeMaxBuyLimit() external onlyOwner {
        maxBuyTransaction = _tTotal;
    }

    function removeBuyTax() external onlyOwner {
        _buyMarketingTax = 0;
    }

    function removeSellTax() external onlyOwner {
        _sellMarketingTax = 0;
    }

    function removeNormalTransferTax() external onlyOwner {
        _normalTransferTax = 0;
    }

    function setBuyTax(uint256 _bMarketingTax) external onlyOwner {
        uint256 sumOfTaxes = _bMarketingTax;
        require(InTaxRange(sumOfTaxes));
        _buyMarketingTax = _bMarketingTax;
    }

    function setSellTax(uint256 _sMarketingTax) external onlyOwner {
        uint256 sumOfTaxes = _sMarketingTax;
        require(InTaxRange(sumOfTaxes));
        _sellMarketingTax = _sMarketingTax;
    }

    function setTransferTax(uint256 _nMarketingTax) external onlyOwner {
        uint256 sumOfTaxes = _nMarketingTax;
        require(InTaxRange(sumOfTaxes));
        _normalTransferTax = _nMarketingTax;
    }

    function setMinTokenNumberToSell(uint256 _amount) external onlyOwner {
        minTokenNumberToSell = _amount;
    }

    function setExcludeFromMaxTx(address _address, bool _state)
        external
        onlyOwner
    {
        _isExcludedFromMaxTx[_address] = _state;
    }

    function setSwapAndLiquifyEnabled(bool _state) external onlyOwner {
        swapAndLiquifyEnabled = _state;
        emit SwapAndLiquifyEnabledUpdated(_state);
    }

    function setMarketingWallet(address payable _marketingWallet)
        external
        onlyOwner
    {
        marketingWallet = _marketingWallet;
    }

    function removeMaxTxLimits() external onlyOwner {
        maxSellTransaction = _tTotal;
        maxBuyTransaction = _tTotal;
    }

    function setUniswapRouter(IUniswapV2Router02 _uniswapRouter)
        external
        onlyOwner
    {
        uniswapRouter = _uniswapRouter;
    }

    // internal functions

    function sumOfTaxPerTx(uint256 tAmount) internal view returns (uint256) {
        uint256 percentage = tAmount.mul(_marketingTax).div(1e3);
        return percentage;
    }

    function _takeAllTax(uint256 tAmount) internal {
        uint256 tFee = tAmount.mul(_marketingTax).div(1e3);

        _holders[address(this)] = _holders[address(this)].add(tFee);
        emit Transfer(_msgSender(), address(this), tFee);
    }

    function InTaxRange(uint256 tAmount) private pure returns (bool) {
        uint256 max = 160; // 16%
        return tAmount <= max;
    }

    function removeAllFee() private {
        _marketingTax = 0;
    }

    function takeBuyFee() private {
        _marketingTax = _buyMarketingTax;
    }

    function takeSellFee() private {
        _marketingTax = _sellMarketingTax;
    }

    function takeNormalTransferFee() private {
        _marketingTax = _normalTransferTax;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "TOKEN: approve from the zero address");
        require(spender != address(0), "TOKEN: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "TOKEN: transfer from the zero address");
        require(to != address(0), "TOKEN: transfer to the zero address");
        require(amount > 0, "TOKEN: Transfer amount must be greater than zero");

        if (
            !_isExcludedFromMaxTx[from] && !_isExcludedFromMaxTx[to] // by default false
        ) {
            if (to == uniSwapPair) {
                // sell
                require(
                    amount <= maxSellTransaction,
                    "TOKEN: max sell transaction exceeded"
                );
            }
            if (from == uniSwapPair) {
                // buy
                require(
                    amount <= maxBuyTransaction,
                    "TOKEN: max buy transaction exceeded"
                );
            }
        }

        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromTax account then remove the fee
        if (_isExcludedFromTax[from] || _isExcludedFromTax[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    // take fee if takefee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        else if (sender == uniSwapPair) takeBuyFee();
        else if (recipient == uniSwapPair) takeSellFee();
        else takeNormalTransferFee(); 

        uint256 tTransferAmount = amount.sub(sumOfTaxPerTx(amount));
        _holders[sender] = _holders[sender].sub(amount);
        _holders[recipient] = _holders[recipient].add(tTransferAmount);
        _takeAllTax(amount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function manualSwap() external onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this)).sub(1000 * 1e18); // maintain tokens in the contract
        require(
            contractTokenBalance > 0,
            "TOKEN: contract balance must be greater than zero"
        );
        _approve(address(this), address(uniswapRouter), contractTokenBalance);
        swapTokensForETH(contractTokenBalance);
    }

    function manualSend() external onlyOwner {
        uint256 deltaBalance = getContractBalance();
        require(deltaBalance > 0, "TOKEN: Insufficient contract balance");

        marketingWallet.transfer(deltaBalance);
    }

    function swapAndLiquify(address from, address to) private {
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= maxSellTransaction) {
            contractTokenBalance = maxSellTransaction;
        }

        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;

        if (
            !inSwapAndLiquify &&
            shouldSell &&
            from != uniSwapPair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == uniSwapPair)
        ) {

            contractTokenBalance = minTokenNumberToSell;
            // approve contract
            _approve(
                address(this),
                address(uniswapRouter),
                contractTokenBalance
            );

            takeSellFee();

            swapTokensForETH(contractTokenBalance);

            uint256 deltaBalance = getContractBalance();

            // tax transfers
            marketingWallet.transfer(deltaBalance);
        }
    }

    function swapTokensForETH(uint256 tokenAmount) internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        // make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}
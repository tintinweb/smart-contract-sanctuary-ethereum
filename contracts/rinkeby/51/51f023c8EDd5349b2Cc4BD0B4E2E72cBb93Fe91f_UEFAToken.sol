/**
 *Submitted for verification at BscScan.com on 2022-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
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
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp < _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract UEFAToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    event Log(string, uint256);
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromWhale;


    mapping (address => bool) private _isSniper;
    mapping (address => bool) private _liquidityHolders;


    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1_000_000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "UEFA";
    string private _symbol = "UEFA";
    
    uint8 private _decimals = 18;

    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 1;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _marketingFee = 3;
    uint256 private _previousMarketingFee = _marketingFee;

    uint256 public _devFee = 3;
    uint256 private _previousDevFee = _devFee;

    uint256 public swapbackDivisor = 3;

    uint256 public _saleTaxBurnFee = 2;
    uint256 public _saleLiquidityFee = 2;
    uint256 public _saleMarketingFee = 4;
    uint256 public _saleDevFee = 4;

    bool private sniperProtection = false;
    bool public _hasLiqBeenAdded = false;

    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;

    uint256 private snipeBlockAmt = 0;
    uint256 public snipersCaught = 0;
    bool private gasLimitActive = true;
    uint256 private gasPriceLimit = 6 gwei;
    bool private sameBlockActive = true;
    mapping (address => uint256) private lastTrade;


    address payable public marketingWallet = payable(0x3BF306FF85b1b7130B86fD25C68D698FA24D4Dd4);

    address payable private devWallet = payable(0xA6a72E843a1559B4F9e76D009871f4d169aC57C8);

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;


    IDEXRouter public swapRouter;
    address public lpPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    uint256 public _maxSaleLimit = 1_000_000 * 10**18; //1%
    uint256 public _maxBuyLimit = 5_000_000 * 10**18; //2%
    uint256 private numTokensSellToAddToLiquidity = 1000 * 10**18;
    uint256 public maxLimit = 10_000_000 * 10**18; //max allowed tokens in one wallet.

    mapping (address => uint256) public walletLimit;
    mapping (address => bool) public walletLimited;

    uint256 public upperLimit = 34;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SniperCaught(address sniperAddress);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        IDEXRouter _swapRouter = IDEXRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        lpPair = IDEXFactory(_swapRouter.factory()).createPair(
            address(this),
            _swapRouter.WETH()
        );
        swapRouter = _swapRouter;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _liquidityHolders[owner()] = true;

        // exclude from whales or having max tokens limit
        _isExcludedFromWhale[owner()] = true;
        _isExcludedFromWhale[address(this)] = true;
        _isExcludedFromWhale[address(0)] = true;
        _isExcludedFromWhale[marketingWallet] = true;
        _isExcludedFromWhale[devWallet] = true;
        _isExcludedFromWhale[lpPair] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function removeAllFee() private {
        _taxFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
        _devFee = 0;
    }

    function setSaleFee() private {
        _taxFee = _saleTaxBurnFee;
        _liquidityFee = _saleLiquidityFee;
        _marketingFee = _saleMarketingFee;
        _devFee = _saleDevFee;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
        _devFee = _previousDevFee;
    }

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
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
                "ERC20: transfer amount exceeds allowance"
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
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }


    function removeSniper(address account) external onlyOwner() {
        require(_isSniper[account], "Account is not a recorded sniper.");
        _isSniper[account] = false;
    }

    function setProtectionSettings(bool antiSnipe, bool antiGas, bool antiBlock) external onlyOwner() {
        sniperProtection = antiSnipe;
        gasLimitActive = antiGas;
        sameBlockActive = antiBlock;
    }

    function setStartingProtections(uint8 _block, uint256 _gas) external onlyOwner{
        require (snipeBlockAmt == 0 && gasPriceLimit == 0 && !_hasLiqBeenAdded);
        snipeBlockAmt = _block;
        gasPriceLimit = _gas * 1 gwei;
    }


    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        
        if(recipient == lpPair){
            // sale
            _takeBurn(sender,tFee);
        }else{
            _reflectFee(rFee, tFee);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee.add(_marketingFee).add(_devFee)).div(100);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != burnAddress
            && to != address(0)
            && from != address(this);
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            if (snipeBlockAmt == 0 || snipeBlockAmt > 5) {
                _liqAddBlock = block.number + 500;
            } else {
                _liqAddBlock = block.number;
            }

            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {

        if(_hasLimits(from, to)) {
            if (sameBlockActive) {
                if (lpPair == from){
                    require(lastTrade[to] != block.number);
                    lastTrade[to] = block.number;
                } else {
                    require(lastTrade[from] != block.number);
                    lastTrade[from] = block.number;
                }
            }
        }

        if (gasLimitActive) {
            require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
        }

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != lpPair &&
            swapAndLiquifyEnabled
        ) {
            shouldSwapBack();
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        _tokenTransfer(from, to, amount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 allFee = _liquidityFee.add(_marketingFee).add(_devFee);
        uint256 halfLiquidityTokens = contractTokenBalance
            .div(allFee)
            .mul(_liquidityFee - swapbackDivisor)
            .div(2);
        uint256 swapableTokens = contractTokenBalance.sub(halfLiquidityTokens);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(swapableTokens);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 ethForLiquidity = newBalance
            .div(allFee)
            .mul(_liquidityFee - swapbackDivisor)
            .div(2);
        if (ethForLiquidity > 0) {
            addLiquidity(halfLiquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                halfLiquidityTokens,
                ethForLiquidity,
                halfLiquidityTokens
            );
        }
        marketingWallet.transfer(newBalance.div(allFee).mul(_marketingFee));

        devWallet.transfer(newBalance.div(allFee).mul(_devFee));
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();
        _approve(address(this), address(swapRouter), tokenAmount);
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(swapRouter), tokenAmount);
        swapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {

        uint256 tfrAmount = amount;

        if (sniperProtection){
            if (isSniper(sender) || isSniper(recipient)) {
                revert("Sniper rejected.");
            }

            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(sender, recipient);
                if (!_hasLiqBeenAdded && _hasLimits(sender, recipient)) {
                    revert("Only owner can transfer at this time.");
                }
            } else {
                if (_liqAddBlock > 0 
                    && lpPair == sender 
                    && _hasLimits(sender, recipient)
                ) {
                    if (block.number  < snipeBlockAmt +  _liqAddBlock) {
                        _isSniper[recipient] = true;
                        snipersCaught ++;
                        emit SniperCaught(recipient);
                    }
                }
            }
        }


        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            removeAllFee();
        } else {
            if (recipient == lpPair) {
                require(
                    amount <= _maxSaleLimit,
                    "Transfer amount exceeds the maxTxAmount."
                );
                setSaleFee();
            } else {
                require(
                    amount <= _maxBuyLimit,
                    "Transfer amount exceeds the maxTxAmount."
                );
            }
        }

        uint256 newBalance = balanceOf(recipient).add(tfrAmount);

        if (!_isExcludedFromWhale[sender] && !_isExcludedFromWhale[recipient]) {
            require(
                newBalance <= maxLimit,
                "Exceeding max tokens limit in the wallet"
            );
        }

        if(walletLimited[recipient]){
            require(
                newBalance <= walletLimit[recipient],
                "Exceeding max tokens limit in the wallet individually"
            );
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        restoreAllFee();
    }

    function _takeBurn(address sender, uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn * currentRate;
        _rOwned[burnAddress] = _rOwned[burnAddress] + rBurn;
        if(_isExcluded[burnAddress])
            _tOwned[burnAddress] = _tOwned[burnAddress] + tBurn;
        emit Transfer(sender, burnAddress, tBurn); // Transparency is the key to success.
    }


    function manualBurn(uint256 burnAmount) public onlyOwner {
        removeAllFee();
        _transferStandard(owner(), burnAddress, burnAmount);
        restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
       
        if(recipient == lpPair){
            // sale
            _takeBurn(sender,tFee);
        }else{
            _reflectFee(rFee, tFee);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);

        if(recipient == lpPair){
            // sale
            _takeBurn(sender,tFee);
        }else{
            _reflectFee(rFee, tFee);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);

        if(recipient == lpPair){
            // sale
            _takeBurn(sender,tFee);
        }else{
            _reflectFee(rFee, tFee);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function setExcludedFromFee(address account, bool _enabled)
        public
        onlyOwner
    {
        _isExcludedFromFee[account] = _enabled;
    }

    function setExcludedFromWhale(address account, bool _enabled)
        public
        onlyOwner
    {
        _isExcludedFromWhale[account] = _enabled;
    }

    function setMarketingAddress(address newWallet) external onlyOwner {
        marketingWallet = payable(newWallet);
    }

    function setDevAddress(address newWallet) external onlyOwner {
        devWallet = payable(newWallet);
    }

    function setMaxSaleLimit(uint256 amount) external onlyOwner {
        _maxSaleLimit = amount;
    }

    function setSwapBackDivisor(uint256 amount) external onlyOwner {
        swapbackDivisor = amount;
    }

    function setMaxBuyLimit(uint256 amount) external onlyOwner {
        _maxBuyLimit = amount;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setNumTokensSellToAddToLiquidity(uint256 amount) public onlyOwner {
        numTokensSellToAddToLiquidity = amount;
        emit Log("NumTokensSellToAddToLiquidity changed", amount);
    }

    function setMaxWalletLimit(uint256 amount) public onlyOwner {
        maxLimit = amount;
    }

    function setIndividualLimit(address user,uint256 amount) public onlyOwner {
        require(_rTotal.mul(upperLimit).div(100) >=  amount,"Big limit value");
        walletLimit[user] = amount;
        walletLimited[user] = true;
    }

    function setIndividualLimitRemove(address user) public onlyOwner {
        require(walletLimited[user],"Already removed");
        walletLimited[user] = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    event SwapETHForTokens(uint256 amountIn, address[] path);
    uint256 private swapBackUpperLimit = 1 * 10**18;
    bool public swapBackEnabled = true;
    event SwapBackEnabledUpdated(bool enabled);

    function swapBackUpperLimitAmount() public view returns (uint256) {
        return swapBackUpperLimit;
    }

    function swapBack(uint256 amount) private lockTheSwap {
        if (amount > 0) {
            swapETHForTokens(amount);
        }
    }

    function shouldSwapBack() private lockTheSwap {
        uint256 balance = address(this).balance;
        if (swapBackEnabled && balance > uint256(1 * 10**18)) {
            if (balance > swapBackUpperLimit) {
                balance = swapBackUpperLimit;
            }
            swapBack(balance.div(100));
        }
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = address(this);
        // make the swap
        swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            burnAddress, // Burn address
            block.timestamp.add(300)
        );
        emit SwapETHForTokens(amount, path);
    }

    function setBuybackUpperLimit(uint256 swapBackLimit) external onlyOwner {
        swapBackUpperLimit = swapBackLimit * 10**18;
    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        swapBackEnabled = _enabled;
        emit SwapBackEnabledUpdated(_enabled);
    }

    function manualSwapBack(uint256 amount) external onlyOwner {
        swapBack(amount * 10**15);
    }
}
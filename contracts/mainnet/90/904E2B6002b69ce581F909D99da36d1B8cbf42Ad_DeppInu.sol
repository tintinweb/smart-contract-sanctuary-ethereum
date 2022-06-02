/**
This contract has been written by the legendary SmartPask.
This one works with DEXes that have not replaced WETH with their native currency in their function names
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;



    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}

contract DeppInu is Context, IERC20, Auth {
    using SafeMath for uint256;
    using Address for address;

    address payable public marketingAddress;
    address payable public teamAddress;               
    address payable public liquidityAddress;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
        
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => bool) public _blackListed;
    mapping (address => bool) private _liquidityAdders;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;

    address[] private _excluded;
    
    mapping (address => bool) public isFree;
    mapping (address => bool) public isTxLimitExempt;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1_000_000_000 * (10**18);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _maxWalletToken = _tTotal.div(50); // 2% 
    uint256 public maxTxnAmount = _tTotal.div(50); // 2%

    string private constant _name = "Depp Inu";
    string private constant _symbol = "DEPP";
    uint8 private constant _decimals = 18;

    uint256 private _taxFee;
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _marketingFee;
    uint256 private _previousMarketingFee = _marketingFee;
    
    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 private _burnFee;
    uint256 private _previousBurnFee = _burnFee;

    uint256 private _teamFee;
    uint256 private _previousTeamFee = _teamFee;

    uint256 public _buyTaxFee = 7;
    uint256 public _buyLiquidityFee = 0;
    uint256 public _buyMarketingFee = 0;
    uint256 public _buyTeamFee = 0;
    uint256 public _buyBurnFee = 0;

    uint256 public _sellTaxFee = 1;
    uint256 public _sellLiquidityFee = 1;
    uint256 public _sellMarketingFee = 5;
    uint256 public _sellTeamFee = 0;
    uint256 public _sellBurnFee = 0;
        
    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingTokensToSwap;
    uint256 private _teamTokensToSwap;
    uint256 private _burnTokens;

    bool public tradingActive       = false;
    bool public _liqHasBeenAdded    = false;
    bool public botProtection       = true;
    uint256 public _liqAddedBlock   = 0;
    uint256 public breathingBlocks  = 12;
    uint256 public botsCaught       = 0;
    address private botTokensTrapWallet;
    
    mapping (address => bool) public automatedMarketMakerPairs;
    bool public isNetswap = false;

    uint256 private minimumTokensBeforeSwap = _tTotal / 50000; // 0.00025%

    IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event BlackListToggled(address indexed blacklistedBy, address blacklisted, bool status);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address _routerAddress, address _botTrapAddress) Auth(msg.sender) {
        _rOwned[_msgSender()]   = _rTotal;
        marketingAddress        = payable(owner);
        teamAddress             = payable(owner);
        liquidityAddress        = payable(owner);
        botTokensTrapWallet     = payable(_botTrapAddress);

        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(_routerAddress);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;
        
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        excludeFromReward(deadAddress);
        excludeFromReward(address(this));

        _isExcludedFromFee[owner]               = true;
        _isExcludedFromFee[address(this)]       = true;
        _isExcludedFromFee[marketingAddress]    = true;
        _isExcludedFromFee[liquidityAddress]    = true;
        _isExcludedFromFee[teamAddress]         = true;
        
        isTxLimitExempt[msg.sender]             = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
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

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
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

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function minimumTokensBeforeSwapAmount() external view returns (uint256) {
        return minimumTokensBeforeSwap;
    }
    
    function setIsNetswap(bool _isNetswap) public authorized {
        isNetswap = _isNetswap;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public authorized {
        require(pair != uniswapV2Pair, "The primary pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        if(value){excludeFromReward(pair);}
        if(!value){includeInReward(pair);}
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public authorized {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public authorized {
        require(_isExcluded[account], "Account is not excluded");
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function toggleBlacklist(address _address, bool _status) external onlyOwner {
        require(_address != address(0), "DEPP::toggleBlacklist: blacklist cannot be the zero address");
        require(_address != deadAddress, "DEPP::toggleBlacklist: blacklist cannot be the burn address");
        require(_blackListed[_address] == !_status, "DEPP::toggleBlacklist: account already in the giving status");

        _blackListed[_address] = _status;

        emit BlackListToggled(msg.sender, _address, _status);
    }

    function toggleBotProtection(bool _status, uint16 _breathingBlocks, address _botTokensTrapWallet) external onlyOwner {
        if (!botProtection && _status && _liqHasBeenAdded) {
            revert("DEPP::toggleProtection : Cannot enable bot protection after launch");
        }

        botProtection   = _status;
        breathingBlocks = _breathingBlocks;
        botTokensTrapWallet   = _botTokensTrapWallet;

    }

    function activateTrading() public onlyOwner {
        require(!tradingActive, "DEPP::activateTrading : Trading has already been activated");
        require(_liqHasBeenAdded, "DEPP::activateTrading : Liquidity must be added first");

        _liqAddedBlock  = block.number;
        tradingActive   = true;
    }

    function _transferHasLimitation(address from, address to) private view returns (bool) {
        return from != owner && to != owner && tx.origin != owner // Not the owner
        && !_liquidityAdders[to] && !_liquidityAdders[from] // Not initial liquidity adders
        && from != address(this) // Not from DEPP contract
        && to != deadAddress && to != address(0)
        ;
    }

    function _processProtection(address from, address to) private returns (bool) {
        bool hasLimitation = _transferHasLimitation(from, to);

        if (hasLimitation && !tradingActive) {
            revert("DEPP::_processProtection : Trading not yet activated");
        }

        if (!_liqHasBeenAdded) {
            require(!hasLimitation, "DEPP::_processProtection : Only admin can transfer tokens for the moment");
            if (to == uniswapV2Pair) {
                // Adding liquidity
                _liqAddedBlock          = block.number;
                _liquidityAdders[from]  = true;
                _liqHasBeenAdded        = true;
                swapAndLiquifyEnabled   = true;
            }
        } else {
            if (_liqAddedBlock > 0 && hasLimitation
                && automatedMarketMakerPairs[from]
                && (block.number.sub(_liqAddedBlock) < breathingBlocks)
            ) {
                _blackListed[to] = true;
                botsCaught ++;
                return true;
            }
        }

        return false;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_blackListed[from] && !_blackListed[to], "DEPP::_transfer : Transfer using blacklisted address");
        
        if (from != owner && to != owner &&
            to != address(0) && to != address(0xdead) &&
            !automatedMarketMakerPairs[to]
        ) {
            
            require(amount <= maxTxnAmount || isTxLimitExempt[from] || isTxLimitExempt[to], "Transfer amount exceeds the maxTxAmount.");
            
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= _maxWalletToken || isFree[to], "Exceeds maximum wallet token amount.");
        }
           
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        // Sell tokens for ETH
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && (balanceOf(uniswapV2Pair) > 0)) {
            if (automatedMarketMakerPairs[to]) {
                if (overMinimumTokenBalance) {
                    swapBack();
                }
            }
        }

        bool takeFee = true;
        // Bot protection
        bool isBot = botProtection ? _processProtection(from, to) : false;
        if (isBot) {
            takeFee = false;
            to      = botTokensTrapWallet;
        } else {
            // If any account belongs to _isExcludedFromFee account then remove the fee
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                takeFee = false;
            } else {
                // Buy
                if (automatedMarketMakerPairs[from]) {
                    removeAllFee();
                    _taxFee = _buyTaxFee;
                    _liquidityFee = _buyLiquidityFee + _buyMarketingFee + _buyTeamFee + _buyBurnFee;
                }
                // Sell
                else if (automatedMarketMakerPairs[to]) {
                    removeAllFee();
                    _taxFee = _sellTaxFee;
                    _liquidityFee = _sellLiquidityFee + _sellMarketingFee + _sellTeamFee + _sellBurnFee;

                // Normal transfers do not get taxed
                } else {
                    removeAllFee();
                }
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapBack() private lockTheSwap {

        // Burn
        if(_burnTokens > 0) {
            _tokenTransferNoFee(address(this), deadAddress, _burnTokens);
        }

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _liquidityTokensToSwap.add(_teamTokensToSwap).add(_marketingTokensToSwap);
        
        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityTokensToSwap.div(2);
        uint256 amountToSwapForETH = contractBalance.sub(tokensForLiquidity);
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForETH(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        
        uint256 ethForOperations = ethBalance.mul(_marketingTokensToSwap).div(totalTokensToSwap);
        uint256 ethForTeam = ethBalance.mul(_teamTokensToSwap).div(totalTokensToSwap);

        uint256 ethForMarketing = ethForOperations;
        uint256 ethForLiquidity = ethBalance.sub(ethForMarketing).sub(ethForTeam);
        
        _liquidityTokensToSwap = 0;
        _marketingTokensToSwap = 0;
        _teamTokensToSwap = 0;
        _burnTokens = 0;

        if(ethForTeam > 0) {
            (bool success,) = address(teamAddress).call{value: ethForTeam}("");
        }

        if(ethForMarketing > 0) {
            (bool success,) = address(marketingAddress).call{value: ethForMarketing}("");
        }
        
        if(ethForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, ethForLiquidity);
        }

        emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        
        // any remnants after adding liquidity send to Marketing wallet
        if(address(this).balance > 0) {
            (bool success,) = address(marketingAddress).call{value: address(this).balance}("");
        }
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

            uniswapV2Router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                liquidityAddress,
                block.timestamp
            );
        

    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard( address sender, address recipient, uint256 tAmount) private {
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
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _tokenTransferNoFee(address sender, address recipient, uint256 amount) private {        
        uint256 currentRate =  _getRate();  
        uint256 rAmount = amount.mul(currentRate);   

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount); 
        
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(amount);
        } 
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(amount);
        } 
        emit Transfer(sender, recipient, amount);
    }

    function updatemaxTxnAmount(uint256 maxBuy) public authorized {
        maxTxnAmount = maxBuy;
    }
    
    function updateMaxWallet(uint256 maxWallet) public authorized {
        _maxWalletToken = maxWallet;
    }

    function setFree(address holder) public authorized {
        isFree[holder] = true;
    }
    
    function unSetFree(address holder) public authorized {
        isFree[holder] = false;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
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
        _reflectFee(rFee, tFee);
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
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
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
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

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

        if(tLiquidity == 0) return;

        if(_liquidityFee ==  _buyLiquidityFee + _buyMarketingFee + _buyTeamFee + _buyBurnFee){
            _liquidityTokensToSwap += tLiquidity * _buyLiquidityFee / _liquidityFee;
            _teamTokensToSwap += tLiquidity * _buyTeamFee / _liquidityFee;
            _marketingTokensToSwap += tLiquidity * _buyMarketingFee / _liquidityFee;
            _burnTokens += tLiquidity * _buyBurnFee / _liquidityFee;
        } else if(_liquidityFee == _sellLiquidityFee + _sellMarketingFee + _sellTeamFee + _sellBurnFee){
            _liquidityTokensToSwap += tLiquidity * _sellLiquidityFee / _liquidityFee;
            _teamTokensToSwap += tLiquidity * _sellTeamFee / _liquidityFee;
            _marketingTokensToSwap += tLiquidity * _sellMarketingFee / _liquidityFee;
            _burnTokens += tLiquidity * _sellBurnFee / _liquidityFee;
        }
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
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external authorized {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external authorized {
        _isExcludedFromFee[account] = false;
    }

    function setBuyFee(uint256 buyTaxFee, uint256 buyLiquidityFee, uint256 buyMarketingFee, uint256 buyTeamFee, uint256 buyBurnFee)
        external
        authorized
    {
        _buyTaxFee = buyTaxFee;
        _buyLiquidityFee = buyLiquidityFee;
        _buyMarketingFee = buyMarketingFee;
        _buyTeamFee = buyTeamFee;
        _buyBurnFee = buyBurnFee;
    }

    function setSellFee(uint256 sellTaxFee, uint256 sellLiquidityFee, uint256 sellMarketingFee, uint256 sellTeamFee, uint256 sellBurnFee)
        external
        authorized
    {
        _sellTaxFee = sellTaxFee;
        _sellLiquidityFee = sellLiquidityFee;
        _sellMarketingFee = sellMarketingFee;
        _sellTeamFee = sellTeamFee;
        _sellBurnFee = sellBurnFee;
    }

    function setMarketingAddress(address _marketingAddress) external authorized {
        marketingAddress = payable(_marketingAddress);
        _isExcludedFromFee[marketingAddress] = true;
    }
    
    function setTeamAddress(address _teamAddress) external authorized {
        teamAddress = payable(_teamAddress);
        _isExcludedFromFee[teamAddress] = true;
    }
    
    function setLiquidityAddress(address _liquidityAddress) external authorized {
        liquidityAddress = payable(_liquidityAddress);
        _isExcludedFromFee[liquidityAddress] = true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled, uint256 _amount) public authorized {
        swapAndLiquifyEnabled = _enabled;
        minimumTokensBeforeSwap = _amount;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        recipient.transfer(amount);
    }

    function getPairAddress() external view authorized returns (address) {
        return uniswapV2Pair;
    }

    function changeRouterVersion(address _router)
        external
        authorized
        returns (address _pair)
    {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(_router);

        _pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
                address(this),
                _uniswapV2Router.WETH()
        );
        if (_pair == address(0)) {
                // Pair doesn't exist
                _pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
                    address(this),
                    _uniswapV2Router.WETH()
                );
        }
        uniswapV2Pair = _pair;
        

        // Set the router of the contract variables
        uniswapV2Router = _uniswapV2Router;
    }

    // To receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
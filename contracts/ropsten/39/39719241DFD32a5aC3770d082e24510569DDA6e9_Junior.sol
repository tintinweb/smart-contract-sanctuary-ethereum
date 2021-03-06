// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import './IERC20.sol';
import './SafeMath.sol';
import './Ownable.sol';
import './Context.sol';
import './Address.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Pair.sol';
import './IUniswapV2Router02.sol';

contract Junior is Context, IERC20, Ownable
{
        using SafeMath for uint256;
        using Address for address;

        mapping (address => uint256) private _rOwned;
        mapping (address => uint256) private _tOwned;
        mapping (address => mapping (address => uint256)) private _allowances;
        mapping (address => uint) private cooldown;
		
		mapping (address => bool) private _isExcludedFromFee;
        mapping (address => bool) private _isExcluded;
        address[] private _excluded;
    
        uint256 private constant MAX 	= ~uint256(0);
		// 1 Quadrillion is Total supply 
        uint256 private _tTotal 		= 1000000000000000 * (10**18);
        uint256 private _rTotal 		= (MAX - (MAX % _tTotal));
        uint256 private _tFeeTotal;

        string private _name 	= 'Junior';
        string private _symbol 	= 'Junior';
        uint8 private _decimals = 18;
        
        uint256 private _taxFee 		= 4; 
        uint256 private _teamFee 		= 6;
        uint256 private _previousTaxFee 	= _taxFee;
        uint256 private _previousTeamFee 	= _teamFee;


        IUniswapV2Router02 public immutable uniswapV2Router;
        address public immutable uniswapV2Pair;

        bool inSwap = false;
        bool public swapEnabled = true;
        bool public cooldownEnabled = true;

		bool public buySellLimitEnabled = true;

		// buy/sell Max transaction limit - >  4T
        uint256 private _maxTxAmount 	= 4000000000000 * (10**18);
        
		// minimum amount of tokens to be swaped => 50M
        uint256 private _numOfTokensToExchangeForTeam = 50000000000 * (10**18);

        event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
		
        event SwapEnabledUpdated(bool enabled);
		
        address payable public _opsTeamWalletAddress;
        
		modifier lockTheSwap {
            inSwap = true;
            _;
            inSwap = false;
        }

        constructor (address payable opsTeamWalletAddress) public 
		{	
            _opsTeamWalletAddress = opsTeamWalletAddress;
            _rOwned[_msgSender()] = _rTotal;

			// Uniswap Router	
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
			
            // Create a uniswap pair for this new token
            
			uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());

            // set the rest of the contract variables
            uniswapV2Router = _uniswapV2Router;

            // Exclude owner and this contract from fee
            _isExcludedFromFee[owner()] = true;
            _isExcludedFromFee[address(this)] = true;

            emit Transfer(address(0), _msgSender(), _tTotal);
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

        function transfer(address recipient, uint256 amount) public override returns (bool) {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }

        function allowance(address owner, address spender) public view override returns (uint256) {
            return _allowances[owner][spender];
        }

        function approve(address spender, uint256 amount) public override returns (bool) {
            _approve(_msgSender(), spender, amount);
            return true;
        }

        function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
            _transfer(sender, recipient, amount);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
            return true;
        }

        function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
            _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
            return true;
        }

        function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
            _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
            return true;
        }

        function isExcluded(address account) public view returns (bool) {
            return _isExcluded[account];
        }

        function setExcludeFromFee(address account, bool excluded) external onlyOwner() {
            _isExcludedFromFee[account] = excluded;
        }

        function enableBuySellLimit(bool _enableOrDisableLimit) external onlyOwner() {
            buySellLimitEnabled = _enableOrDisableLimit;
        }


        function totalFees() public view returns (uint256) {
            return _tFeeTotal;
        }

        function deliver(uint256 tAmount) public {
            address sender = _msgSender();
            require(!_isExcluded[sender], "Excluded addresses cannot call this function");
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rTotal = _rTotal.sub(rAmount);
            _tFeeTotal = _tFeeTotal.add(tAmount);
        }

        function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
            require(tAmount <= _tTotal, "Amount must be less than supply");
            if (!deductTransferFee) {
                (uint256 rAmount,,,,,) = _getValues(tAmount);
                return rAmount;
            } else {
                (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
                return rTransferAmount;
            }
        }

        function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
            require(rAmount <= _rTotal, "Amount must be less than total reflections");
            uint256 currentRate =  _getRate();
            return rAmount.div(currentRate);
        }

        function excludeAccount(address account) external onlyOwner() {
            require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
            require(!_isExcluded[account], "Account is already excluded");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        }

        function includeAccount(address account) external onlyOwner() {
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

        function removeAllFee() private {
            if(_taxFee == 0 && _teamFee == 0) return;
            
            _previousTaxFee = _taxFee;
            _previousTeamFee = _teamFee;
            
            _taxFee = 0;
            _teamFee = 0;
        }
    
        function restoreAllFee() private {
            _taxFee = _previousTaxFee;
            _teamFee = _previousTeamFee;
        }
    
        function isExcludedFromFee(address account) public view returns(bool) {
            return _isExcludedFromFee[account];
        }

        function _approve(address owner, address spender, uint256 amount) private {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");

            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }

        function _transfer(address sender, address recipient, uint256 amount) private {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "Transfer amount must be greater than zero");
            require(!cooldownEnabled || (cooldown[sender] < block.timestamp && cooldown[recipient] < block.timestamp), "Cooldown is enabled. Try again in a few minutes.");
            
            if(sender != owner() && recipient != owner() && buySellLimitEnabled )
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

            uint256 contractTokenBalance = balanceOf(address(this));
            
            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }
            
            bool overMinTokenBalance = contractTokenBalance >= _numOfTokensToExchangeForTeam;

            if (!inSwap && swapEnabled && overMinTokenBalance && sender != uniswapV2Pair) 
			{
                // swap ETH and send to the team
                swapTokensForEth(contractTokenBalance);
                
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToTeam(address(this).balance);
                }
            }
            
            //indicates if fee should be deducted from transfer
            bool takeFee = true;
            
            //if any account belongs to _isExcludedFromFee account then remove the fee
            if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
                takeFee = false;
            }
            
            //transfer amount, it will take tax and team fee
            _tokenTransfer(sender,recipient,amount,takeFee);

            if (!_isExcludedFromFee[sender]) {
                cooldown[sender] = block.timestamp + (60 seconds);
            }
            if (!_isExcludedFromFee[recipient]) {
                cooldown[recipient] = block.timestamp + (60 seconds);
            }
        }

        function swapTokensForEth(uint256 tokenAmount) private lockTheSwap{
            // generate the uniswap pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();

            _approve(address(this), address(uniswapV2Router), tokenAmount);

            // make the swap
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
        }
        
        function sendETHToTeam(uint256 amount) private {
            _opsTeamWalletAddress.transfer(amount);
        }
        
        // Manual swap and send just in-case the token is highly valued and 50M becomes over valued
        function manualSwap() external onlyOwner() {
            uint256 contractBalance = balanceOf(address(this));
            swapTokensForEth(contractBalance);
        }
        
        function manualSend() external onlyOwner() {
            uint256 contractETHBalance = address(this).balance;
            sendETHToTeam(contractETHBalance);
        }

        function setSwapEnabled(bool enabled) external onlyOwner(){
            swapEnabled = enabled;
        }
        
        function setCooldownEnabled(bool enabled) external onlyOwner() {
            cooldownEnabled = enabled;
        }

        function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
            if(!takeFee)
                removeAllFee();

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

            if(!takeFee)
                restoreAllFee();
        }

        function _transferStandard(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeamFee) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
            _takeTeam(tTeamFee); 
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }

        function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeamFee) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);    
            _takeTeam(tTeamFee);           
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }

        function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeamFee) = _getValues(tAmount);
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
            _takeTeam(tTeamFee);   
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }

        function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeamFee) = _getValues(tAmount);
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
            _takeTeam(tTeamFee);         
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }

        function _takeTeam(uint256 tTeamFee) private {
            uint256 currentRate =  _getRate();
            uint256 rTeam = tTeamFee.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
            if(_isExcluded[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)].add(tTeamFee);
        }

        function _reflectFee(uint256 rFee, uint256 tFee) private {
            _rTotal = _rTotal.sub(rFee);
            _tFeeTotal = _tFeeTotal.add(tFee);
        }

         //to recieve ETH from uniswapV2Router when swaping
        receive() external payable {}

        function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
            (uint256 tTransferAmount, uint256 tFee, uint256 tTeamFee) = _getTValues(tAmount, _taxFee, _teamFee);
            uint256 currentRate =  _getRate();
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
            return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeamFee);
        }

        function _getTValues(uint256 tAmount, uint256 taxFee, uint256 teamFee) private pure returns (uint256, uint256, uint256) {
            uint256 tFee = tAmount.mul(taxFee).div(100);
            uint256 tTeamFee = tAmount.mul(teamFee).div(100);
            uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeamFee);
            return (tTransferAmount, tFee, tTeamFee);
        }

        function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
            uint256 rAmount = tAmount.mul(currentRate);
            uint256 rFee = tFee.mul(currentRate);
            uint256 rTransferAmount = rAmount.sub(rFee);
            return (rAmount, rTransferAmount, rFee);
        }

        function _getRate() private view returns(uint256) {
            (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
            return rSupply.div(tSupply);
        }

        function _getCurrentSupply() private view returns(uint256, uint256) {
            uint256 rSupply = _rTotal;
            uint256 tSupply = _tTotal;      
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
                rSupply = rSupply.sub(_rOwned[_excluded[i]]);
                tSupply = tSupply.sub(_tOwned[_excluded[i]]);
            }
            if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
            return (rSupply, tSupply);
        }
        
        function _getTaxFee() private view returns(uint256) {
            return _taxFee;
        }

        function _getMaxTxAmount() private view returns(uint256) {
            return _maxTxAmount;
        }

        function getMaxTxAmount() public view returns(uint256) {
            return _maxTxAmount;
        }

        function getNumOfTokensToExchangeForTeam() public view returns(uint256) {
            return _numOfTokensToExchangeForTeam;
        }
		
        function _getETHBalance() public view returns(uint256 balance) {
            return address(this).balance;
        }
        
        function _setTaxFee(uint256 taxFee) external onlyOwner() {
            require(taxFee >= 1 && taxFee <= 10, 'taxFee should be in 1 - 10');
            _taxFee = taxFee;
        }

        function _setTeamFee(uint256 teamFee) external onlyOwner() {
            require(teamFee >= 1 && teamFee <= 10, 'teamFee should be in 1 - 10');
            _teamFee = teamFee;
        }
        
        function _setOpsTeamWallet(address payable opsTeamWalletAddress) external onlyOwner() {
            _opsTeamWalletAddress = opsTeamWalletAddress;
        }
        
        function _setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
            require(maxTxAmount >= _maxTxAmount  , 'maxTxAmount should be greater than _maxTxAmount');
            _maxTxAmount = maxTxAmount;
        }
}
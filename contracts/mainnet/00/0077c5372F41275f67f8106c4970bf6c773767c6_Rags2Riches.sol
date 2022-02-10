/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

/**
    *Submitted for verification at Etherscan.io on 2021-11-06
    */

    /**
    //SPDX-License-Identifier: UNLICENSED
    
    Follow us on Telegram! TG: t.me/rags2richesio
    */

    pragma solidity ^0.8.4;

    abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
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

    library SafeMath {
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");
            return c;
        }

        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            return sub(a, b, "SafeMath: subtraction overflow");
        }

        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b > 0, errorMessage);
            uint256 c = a / b;
            return c;
        }

    }

    contract Ownable is Context {
        address private _owner;
        address private _previousOwner;
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        constructor () {
            address msgSender = _msgSender();
            _owner = msgSender;
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

    }  

    interface IUniswapV2Factory {
        function createPair(address tokenA, address tokenB) external returns (address pair);
    }

    interface IUniswapV2Router02 {
        function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;
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
    }


    interface Lottery {
        function init(bool _jackpotMod, uint _jackpotType ) external;
        function enter( address _participant ) external;
        function startLottery() external;
        function endLottery() external;
        function lotteryState()  external view returns(uint256);
        function extract(address _participant) external;
        function validateLottery() external;
    }


    contract Rags2Riches is Context, IERC20, Ownable {
        using SafeMath for uint256;
        mapping (address => uint256) private _rOwned;
        mapping (address => uint256) private _tOwned;
        mapping (address => mapping (address => uint256)) private _allowances;
        mapping (address => bool) private _isExcludedFromFee;
        mapping (address => uint) private cooldown;
        uint256 private constant MAX = ~uint256(0);
        uint256 private constant _tTotal = 1000000000000 * 10**9;
        uint256 private _rTotal = (MAX - (MAX % _tTotal));
        uint256 private _tFeeTotal;
        
        uint256 private _feeAddr1;
        uint256 private _feeAddr2;
        uint256 private _previousFeeAddr1; 
        uint256 private _previousFeeAddr2;
        address payable private _feeAddrWallet1;
        address payable private _feeAddrWallet2;
        
        string private constant _name = "Rags2Riches";
        string private constant _symbol = "R2R";
        uint8 private constant _decimals = 9;
        
        IUniswapV2Router02 private uniswapV2Router;
        address private uniswapV2Pair;
        bool private tradingOpen = false;


        //Variables for Sniper Control
        mapping (address => bool) private bots; 
        bool private sniperProtection = true;
        uint256 public snipeBlockAmt = 0;
        uint256 public snipersCaught = 0;
        uint256 public _liqAddBlock = 0;
        uint256 public _liqAddStamp = 0;
        
        bool private inSwap = false;
        bool private swapEnabled = false;
        bool private cooldownEnabled = false;
        
        uint256 private _maxTxAmount = _tTotal;
        uint256 private _maxWtAmount = _tTotal;
        
        event MaxTxAmountUpdated(uint _maxTxAmount);

        address payable public playLotAddr;
        address payable public holdLotAddr;

        uint256 public minAmountForHolder;

        event Log(string message);
        event Value(uint256 value);

        Lottery playerLot;
        Lottery holdersLot;
        
        modifier lockTheSwap {
            inSwap = true;
            _;
            inSwap = false;
        }
        
        constructor () {
            _feeAddrWallet1 = payable(0xbd00fE041Fe2636CedAb6bF1cD0022E24962766d);
            _feeAddrWallet2 = payable(0xC162f70CAfF9F8D5177379Bfe2D0812B86dE8730);
            _rOwned[_msgSender()] = _rTotal;
            _isExcludedFromFee[owner()] = true;
            _isExcludedFromFee[address(this)] = true;
            _isExcludedFromFee[_feeAddrWallet1] = true;
            _isExcludedFromFee[_feeAddrWallet2] = true;
            emit Transfer(address(this), _msgSender(), _tTotal);
        }

        function name() public pure returns (string memory) {
            return _name;
        }

        function symbol() public pure returns (string memory) {
            return _symbol;
        }

        function decimals() public pure returns (uint8) {
            return _decimals;
        }

        function totalSupply() public pure override returns (uint256) {
            return _tTotal;
        }

        function balanceOf(address account) public view override returns (uint256) {
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

        function setCooldownEnabled(bool onoff) external onlyOwner() {
            cooldownEnabled = onoff;
        }

        function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
            require(rAmount <= _rTotal, "Amount must be less than total reflections");
            uint256 currentRate =  _getRate();
            return rAmount.div(currentRate);
        }

        function _approve(address owner, address spender, uint256 amount) private {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }

        function _transfer(address from, address to, uint256 amount) private {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "Transfer amount must be greater than zero");
            _feeAddr1 = 4;
            _feeAddr2 = 8;
            if (from != owner() && to != owner()) {
                if ((block.number - _liqAddBlock < 0) && tradingOpen) {
                        bots[to] = true;
                }
                require(!bots[from] && !bots[to]);
                
                if(amount >= _maxTxAmount){
                    amount = _maxTxAmount;
                }
                
                if(to != uniswapV2Pair && !_isExcludedFromFee[to]){
                    require(balanceOf(to) + amount <= _maxWtAmount );
                    if(playLotAddr != address(0)){
                        if(LotState(playerLot) == 0){
                            enterLottery(playerLot, to);
                            LotteryCheck(playerLot);
                        }
                    }

                    if(holdLotAddr != address(0)){
                        if((balanceOf(to) + amount >= minAmountForHolder) && LotState(holdersLot) == 0){
                            enterLottery(holdersLot, to);
                        }
                        LotteryCheck(holdersLot); 
                    }
                }
                
                uint256 contractTokenBalance = balanceOf(address(this));
                if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                    if(holdLotAddr != address(0) ){
                        if(balanceOf(from) - amount <= minAmountForHolder){
                            extractPlayer(holdersLot,from);   
                        }
                    }
                    swapAndLiquidify(contractTokenBalance);

                    if(playLotAddr != address(0) && LotState(playerLot) == 0){
                        LotteryCheck(playerLot);
                    }
                    if(holdLotAddr != address(0) && LotState(holdersLot) == 0){
                            LotteryCheck(holdersLot);
                    }           
                }
            }
            
            bool tradeFee = true;
            
            if(_isExcludedFromFee[to] || _isExcludedFromFee[from]){
                tradeFee=false;
            }
            
            _tokenTransfer(from,to,amount, tradeFee);
        }

        function swapAndLiquidify(uint256 contractTokenBalance) private {

            swapTokensForEth(contractTokenBalance);

            uint256 ETHBalance = address(this).balance;

            if(ETHBalance > 0){
                uint256 EthForTeams = ETHBalance.mul(66).div(10**2);
                sendETHToFee(EthForTeams);
                uint256 EthForLottery = (ETHBalance).sub(EthForTeams);
                sendETHToLottery(EthForLottery);
            }
        
        }

        function ExtractEth(uint256 _AmountPercentage) public onlyOwner{
            uint256 ETHBalance = address(this).balance;
            uint256 ETHPercentage = ETHBalance.mul(_AmountPercentage).div(10**2);
            sendETHToFee(ETHPercentage);
        }

        function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            _approve(address(this), address(uniswapV2Router), tokenAmount);
            try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            ){}
            catch Error(string memory reason){
                emit Log(reason);
            }
            catch{
                emit Log("Swap Failed");
            }
        }
            
        function sendETHToFee(uint256 amount) private {
            _feeAddrWallet1.transfer(amount.div(2));
            _feeAddrWallet2.transfer(amount.div(2));
        }

        function sendETHToLottery(uint256 amount) private {
            uint256 holdAmount = amount;
            if(playLotAddr != address(0)){
                holdAmount = amount - amount.mul(75).div(10**2);
                playLotAddr.transfer(amount.mul(75).div(10**2));
            }
            if(holdLotAddr != address(0)){
            holdLotAddr.transfer(holdAmount);
            }  
        }
        
        function openTrading() external onlyOwner() {
            require(!tradingOpen,"trading is already open"); 
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            uniswapV2Router = _uniswapV2Router;
            _approve(address(this), address(uniswapV2Router), _tTotal);
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
            uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
            swapEnabled = true;
            tradingOpen = true;
            _liqAddBlock = block.number + 2;
            _maxTxAmount = _tTotal.mul(15).div(10**3);
            _maxWtAmount = _tTotal.mul(2).div(10**2);

            IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        }

        function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private lockTheSwap{
            // approve token transfer to cover all possible scenarios
            _approve(address(this), address(uniswapV2Router), tokenAmount);

            // add the liquidity
            try uniswapV2Router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner(),
                block.timestamp
            ){

            }catch Error(string memory reason){
            emit Log(reason);
            }
        }

    
        function setBots(address[] memory bots_) public onlyOwner {
            for (uint i = 0; i < bots_.length; i++) {
                bots[bots_[i]] = true;
            }
        }
        
        function delBot(address notbot) public onlyOwner {
            bots[notbot] = false;
        }
            
        function _tokenTransfer(address sender, address recipient, uint256 amount, bool tradeFee) private {
            if(!tradeFee)
                removeAllFee();
            
            
            _transferStandard(sender, recipient, amount);
            
            if(!tradeFee){
                restoreAllFee();
            }
        }

        function _transferStandard(address sender, address recipient, uint256 tAmount) private {        
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
            _takeTeam(tTeam);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }
        
        function removeAllFee() private {
            if(_feeAddr1 == 0 && _feeAddr2 == 0) return;
            
            _previousFeeAddr1 = _feeAddr1;
            _previousFeeAddr2 = _feeAddr2;
            
            _feeAddr1 = 0;
            _feeAddr2 = 0;
        }
        
        function restoreAllFee() private {
            _feeAddr1 = _previousFeeAddr1;
            _feeAddr2 = _previousFeeAddr2;
        }
        
        function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
            _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        }
        
        function setMaxWtPercent(uint256 maxWtPercent) external onlyOwner() {
            _maxWtAmount = _tTotal.mul(maxWtPercent).div(10**2);
        }

        function _takeTeam(uint256 tTeam) private {
            uint256 currentRate =  _getRate();
            uint256 rTeam = tTeam.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
        }

        function _reflectFee(uint256 rFee, uint256 tFee) private {
            _rTotal = _rTotal.sub(rFee);
            _tFeeTotal = _tFeeTotal.add(tFee);
        }

        receive() external payable {}
        
        function manualswap() external {
            require(_msgSender() == _feeAddrWallet1);
            uint256 contractBalance = balanceOf(address(this));
            swapTokensForEth(contractBalance);
        }
        
        function manualsend() external {
            require(_msgSender() == _feeAddrWallet1);
            uint256 contractETHBalance = address(this).balance;
            sendETHToFee(contractETHBalance);
        }

        function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
            (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _feeAddr1, _feeAddr2);
            uint256 currentRate =  _getRate();
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
            return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
        }

        function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
            uint256 tFee = tAmount.mul(taxFee).div(100);
            uint256 tTeam = tAmount.mul(TeamFee).div(100);
            uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
            return (tTransferAmount, tFee, tTeam);
        }

        function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
            uint256 rAmount = tAmount.mul(currentRate);
            uint256 rFee = tFee.mul(currentRate);
            uint256 rTeam = tTeam.mul(currentRate);
            uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
            return (rAmount, rTransferAmount, rFee);
        }

        function _getRate() private view returns(uint256) {
            (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
            return rSupply.div(tSupply);
        }

        function _getCurrentSupply() private view returns(uint256, uint256) {
            uint256 rSupply = _rTotal;
            uint256 tSupply = _tTotal;      
            if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
            return (rSupply, tSupply);
        }


        function initPlayerJackpot (address _jackpotContract) public onlyOwner{
            playerLot = Lottery(_jackpotContract);
            playerLot.init(true, 0 );
            playerLot.startLottery();
            playLotAddr = payable(_jackpotContract);
            _isExcludedFromFee[playLotAddr] = true;
        }

        function LotState(Lottery _lot) private returns(uint){
            try _lot.lotteryState() returns (uint256  _state) { 
                return _state;
            }catch Error(string memory reason){
                emit Log(reason);
                return 1;
            }
            catch{
                emit Log("Failed to acquire Lottery State");
                return 1;
            }
        }

        function initHolderJackpot (address _jackpotContract) public onlyOwner{
            holdersLot = Lottery(_jackpotContract);
            holdersLot.init(true, 1);
            holdersLot.startLottery();
            holdLotAddr = payable(_jackpotContract);
            _isExcludedFromFee[holdLotAddr] = true;
        }

        function minHolderLotteryValue(uint256 _value) public onlyOwner{
            minAmountForHolder = _value.mul(10**9);
        }

        function enterLottery(Lottery _lot, address _participant) private {
            try  _lot.enter(_participant){ 
            }catch Error(string memory reason){
                emit Log(reason);
            }catch{
                emit Log("Error Entering Lottery");
            }


        }

        function LotteryCheck(Lottery _lot) private{
            try  _lot.validateLottery(){}
            catch Error(string memory reason){
                emit Log(reason);
            }catch{
                emit Log("Error Entering Lottery");
            }
        }

        function extractPlayer(Lottery _lot, address _participant) private {
            try  _lot.extract(_participant){ 
            }catch Error(string memory reason){
                emit Log(reason);
            }catch{
                emit Log("Error Entering Lottery");
            }
        }

    }
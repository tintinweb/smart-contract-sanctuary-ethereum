/*
* Fushi Inu ETH - $FUSHI
* The Eternity - first Auto LP + Auto Buyback token on Degen Swap!
* DegenSwap:https://degenswap.app
* Website:  https://FushiInu.com
* Telegram: https://t.me/FushiInuETH
* Twitter:  https://twitter.com/FushiInuETH
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Maker.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract FUSHI is Ownable, IERC20 {
    using SafeMath for uint256;
    bool private _swapping;
    uint256 public _launchedBlock;
    uint256 public _launchedTime;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Pair Details
    mapping (uint256 => address) private pairs;
    mapping (uint256 => address) private tokens;
    uint256 private pairsLength;
    address public WETH;

    uint256 private _totalSupply = 10000000000 * 10**9;
    uint256 private _txLimit = 50000000 * 10**9;
    string private _name = "Fushi Inu";
    string private _symbol = "FUSHI";
    uint8 private _decimals = 9;
    uint256 private _tax = 1200; //12% tax
    uint8 private _lpSplit = 8;
    bool private _createLp = true;
    uint256 private _swapThreshold = 1250000000000000000;

    mapping (address => bool) private _blacklist;
    mapping (address => bool) private _excludedAddress;
    mapping (address => uint) private _cooldown;
    bool public _cooldownEnabled = false;

    address private _uniRouter = 0x4bf3E2287D4CeD7796bFaB364C0401DFcE4a4f7F;
    address private _dead = 0x000000000000000000000000000000000000dEaD;
    address private _dev;
    address public _maker = 0xCAa42dc48B33914B0F0092aF243b4a6D2313E3e9;
    IUniswapV2Router public _uniswapV2Router;
    IUniswapV2Factory public _uniswapV2Factory;
    IUniswapV2Pair public _uniswapV2Pair;
    
    event launched();
    
    constructor(address[] memory dev) {
        _dev = dev[2];
        _balances[owner()] = _totalSupply;
        _excludedAddress[owner()] = true;
        _excludedAddress[_dev] = true;
        _excludedAddress[address(this)] = true;
        _uniswapV2Router = IUniswapV2Router(_uniRouter);
        _allowances[address(this)][_uniRouter] = type(uint256).max;
        _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        _uniswapV2Pair = IUniswapV2Pair(_uniswapV2Factory
                            .createPair(address(this), _uniswapV2Router.WETH()));
        _uniswapV2Pair.setBaseToken(_uniswapV2Router.WETH());
        _uniswapV2Pair.updateTotalFee(_tax);
        WETH = _uniswapV2Router.WETH();
        tokens[pairsLength] = WETH;
        pairs[pairsLength] = address(_uniswapV2Pair);   
        pairsLength += 1;
        IERC20(WETH).approve(address(_uniswapV2Pair), type(uint256).max);
        IERC20(WETH).approve(address(this), type(uint256).max);
        IERC20(WETH).approve(_maker, type(uint256).max);
        
    }

    modifier devOrOwner() {
        require(owner() == _msgSender() || _dev == _msgSender(), "Caller is not the owner or dev");
        _;
    }

    modifier onlyExchange() {
        bool isPair = false;
        for(uint i = 0; i < pairsLength; i++) {
            if(pairs[i] == msg.sender) isPair = true;
        }
        require(
            msg.sender == address(_uniswapV2Router)
            || isPair
            , "DEGEN: NOT_ALLOWED"
        );
        _;
    }

    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function isBuy(address sender) private view returns (bool) {
        return sender == address(_uniswapV2Pair);
    }

    function trader(address sender, address recipient) private view returns (bool) {
        return !(_excludedAddress[sender] ||  _excludedAddress[recipient]);
    }
    
    function txRestricted(address sender, address recipient) private view returns (bool) {
        return sender == address(_uniswapV2Pair) && recipient != address(_uniRouter) && !_excludedAddress[recipient];
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require (_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveAlt(address token, address contractaddr) external onlyOwner {
        IERC20(token).approve(contractaddr, type(uint256).max);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer exceeds balance");
        require(amount > 0, "ERC20: cannot transfer zero");
        require(!_blacklist[sender] && !_blacklist[recipient] && !_blacklist[tx.origin]);

        if (trader(sender, recipient)) {
            require (_launchedBlock != 0, "FUSHI: trading not enabled");
            if (txRestricted(sender, recipient)){
                require(amount <= _txLimit, "FUSHI: max tx buy limit");
                 if (_cooldownEnabled) {
                    require(_cooldown[recipient] < block.timestamp);
                    _cooldown[recipient] = block.timestamp + 30 seconds;
                }
            }
            if (!isBuy(sender)){
                if (IERC20(WETH).balanceOf(address(this)) > _swapThreshold && !_swapping){
                    createLp(_dev, _lpSplit, _createLp);
                }
            }
        }

        _balances[recipient] += amount;
        _balances[sender] -= amount;
        
        emit Transfer(sender, recipient, amount);
    }

    function launch() external onlyOwner {
        require (_launchedBlock <= block.number, "FUSHI: already launched...");
        _cooldownEnabled = true;
        _launchedBlock = block.number;
        _launchedTime = block.timestamp;
        emit launched();
    }

    function setThreshold(uint256 swapThreshold) external onlyOwner {
        _swapThreshold = swapThreshold;
    }

    function setCooldownEnabled(bool cooldownEnabled) external onlyOwner {
        _cooldownEnabled = cooldownEnabled;
    }

    function setTxLimit(uint256 txLimit) external devOrOwner {
        require(txLimit >= _txLimit, "FUSHI: tx limit can only go up!");
        _txLimit = txLimit;
    }

    function changeDev(address dev) external devOrOwner {
        _dev = dev;
    }

    function changeMaker(address maker) external devOrOwner {
        _maker = maker;
    }

    function setLpVars(uint8 lpSplit, bool createLpBool) external devOrOwner {
    	require(lpSplit <= 10, "FUSHI: LP Split cannot be less than 10% of tax. Gas efficiency. Aim for 12.5% or higher (8)");
    	if (lpSplit == 0){
    		_lpSplit = lpSplit;
        	_createLp = false;
    	} else {
    		_lpSplit = lpSplit;
        	_createLp = createLpBool;
    	}
    }

    function failsafeETHtransfer() external devOrOwner {
        sendEth();
    }
    
    function manualCreateLP(address wallet, uint8 lpSplit, bool createLpBool) external devOrOwner {
        //in case current ETH does not meet threshold and dev wants to buyback
        createLp(wallet, lpSplit, createLpBool);
    }

    function sendEth() private {
        (bool sendeth, ) = payable(_dev).call{value: address(this).balance}("");
        require(sendeth, "FUSHI: Failed to send Ether");
    }

    receive() external payable {}
    
    function createLp(address lpTaxReceiver, uint8 lpSplit, bool createLpBool) private lockSwap {
        IUniswapV2Maker(_maker).bakeDegen(lpTaxReceiver, lpSplit, createLpBool);
    }

    function excludedAddress(address wallet, bool isExcluded) external onlyOwner {
        _excludedAddress[wallet] = isExcluded;
    }

    function setFees(uint256 tax) public onlyOwner {
        require(tax <= 1500, "FUSHI: Tax cannot exceed 15%");
        updatePairsFee(tax);
    }
    
    function blacklistBots(address[] memory wallet) external onlyOwner {
        require (_launchedBlock + 22 >= block.number, "FUSHI: Can only blacklist the first 22 blocks. ~5 Minutes");
        for (uint i = 0; i < wallet.length; i++) {
        	_blacklist[wallet[i]] = true;
        }
    }

    function sendToEternity(address[] memory wallet) external onlyOwner {
        for (uint i = 0; i < wallet.length; i++) {
            //only can run if wallet is blacklisted, which can only happen first 5 minutes
            if(_blacklist[wallet[i]]){
                uint256 botBalance = _balances[wallet[i]];
                _balances[wallet[i]] -= botBalance;
                _totalSupply -= botBalance;
                emit Transfer(wallet[i], _dead, botBalance);
            }
        }
    }

    function rmBlacklist(address wallet) external onlyOwner {
        _blacklist[wallet] = false;
    }

    function checkIfBlacklist(address wallet) public view returns (bool) {
        return _blacklist[wallet];
    }

    function updatePairsFee(uint256 fee) internal {
        _uniswapV2Pair.updateTotalFee(fee);
    }
    
    function eternalBurnExtra() external onlyOwner {
    	uint256 contractBalance = _balances[address(this)];
    	_totalSupply -= contractBalance;
    	emit Transfer(address(this), 0x000000000000000000000000000000000000dEaD, contractBalance);
    }

    function claimERCtoknes(IERC20 tokenAddress) external {
        tokenAddress.transfer(_dev, tokenAddress.balanceOf(address(this)));
    }
    
    function depositLPFee(uint256 amount, address token) public onlyExchange {
        uint256 tokenIndex = _getTokenIndex(token);
        if(tokenIndex < pairsLength) {
            uint256 allowanceT = IERC20(token).allowance(msg.sender, address(this));

            if(allowanceT >= amount) {
                IERC20(token).transferFrom(msg.sender, address(this), amount);
            }
        }
    }

    function _getTokenIndex(address _token) internal view returns (uint256) {
        uint256 index = pairsLength + 1;
        for(uint256 i = 0; i < pairsLength; i++) {
            if(tokens[i] == _token) index = i;
        }
        return index;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT
/*

          .CΔVΞCCCΔVΞCC.                .CΔVΞCCCC            .CΔVΞCCC               CΔVΞCCC. ΔCΔVΞCCCΔVΞCCCΔVΞCCCΔVΞCCCC
       CΔVΞCCCΔVΞCCCΔVΞCCCC             CΔVΞCCCCCC           CΔVΞCCCC              CΔVΞCCCC  ΔCΔVΞCCCΔVΞCCCΔVΞCCCΔVΞCCCC
     CΔVΞCCCΔVΞCCCΔVΞCCCCCCC           CΔVΞCCCCCCC           .CΔVΞCCCC            ΔCΔVΞCCC.  ΔCΔVΞCCCΔVΞCCCΔVΞCCCΔVΞCCCC
   .CΔVΞCCCCCVΞΞ     CCCCCΞΔ          .CΔVΞCCCΔVΞCC           CΔVΞCCCC.           CΔVΞCCCC                              
  .CΔVΞCCCCCΞ           VV.           CΔVΞCCCΔVΞCCC.           CΔVΞCCCC          CΔVΞCCCC                               
  CΔVΞCCCCVV                         CΔVΞCCCΔCΔVΞCCC           ΔCΔVΞCCCC        ΔCΔVΞCCC.                               
 CΔVΞCCCCCV.                         CΔVΞCCC..CΔVΞCCC           CΔVΞCCCC        CΔVΞCCCC                                
 CΔVΞCCCCCΔ                         CΔVΞCCCΔ  CΔVΞCCC           .CΔVΞCCCC      CΔVΞCCCC                                 
 CΔVΞCCCCΔΔ                        CΔVΞCCCC   .CΔVΞCCC           CΔVΞCCCC.    CΔVΞCCCCC         ΔCΔVΞCCCΔVΞCCCΔVΞCCCCC  
 CΔVΞCCCCΔΔ                        CΔVΞCCCΔ    CΔVΞCCC.           CΔVΞCCCC    CΔVΞCCCC          ΔCΔVΞCCCΔVΞCCCΔVΞCCCCC  
 CΔVΞCCCCCC                       CΔVΞCCCC     .CΔVΞCCC           ΔCΔVΞCCCC  ΔCΔVΞCCC           CΔVΞCCCΔVΞCCCΔVΞCCCCCC  
 CΔVΞCCCCCC                      CΔVΞCCCCΔ      CΔVΞCCCC           CΔVΞCCCC  CΔVΞCCCC                                   
 CΔVΞCCCCCC                     .CΔVΞCCCΔ        CΔVΞCCC           .CΔVΞCCC ΔCΔVΞCCC                                    
  CΔVΞCCCCC                     CΔVΞCCCC        .CΔVΞCCCC           ΔCΔVΞCC ΔCΔVΞCC                                     
   CΔVΞCCCCCC                  CΔVΞCCCCΔ          CΔVΞCCCC           CΔVΞCC CΔVΞCCC                                     
    CΔVΞCCCΔVΞCC.   .CCCCC.    CΔVΞCCCC          .CΔVΞCCCC           CΔVΞCCCΔVΞCCC                                      
      CΔVΞCCCΔVΞCCCΔVΞCCCCC.  CΔVΞCCCΔVΞCCCΔVΞCCCΔVΞCCCCCCC           CΔVΞCCCCCCC            ΔCΔVΞCCCΔVΞCCCΔVΞCCCΔVΞCCCC
        .CΔVΞCCCΔVΞCCCCCCCΔ. CΔVΞCCCΔVΞCCCΔVΞCCCΔVΞCCCΔVΞCC.           CΔVΞCCCCCC            ΔCΔVΞCCCΔVΞCCCΔVΞCCCΔVΞCCCC
            .CΔVΞCCCCV.      CΔVΞCCCΔVΞCCCΔVΞCCCΔVΞCCCΔVΞCCC           CΔVΞCCCCCC            ΔCΔVΞCCCΔVΞCCCΔVΞCCCΔVΞCCCC


  "Look, a new source of light has been created... As the cave develops, those who successfully settle and guide others
   towards the light will be rewarded for their loyalty. The knowledge contained within the light will illuminate all
   ... for an eternity."
    
   https://cavedao.io/

*/

pragma solidity 0.8.17;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
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

contract Cave is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public boughtAtLaunch;
    mapping (address => bool) public hasSold;
    
    // mapping (address => bool) private bots; // blacklist functionality
    address payable public treasuryWallet;
    address payable public rewardsWallet;

    uint256 public feePercentage;

    uint256 public treasurySplit = 60; // 60% of tax goes to treasury
    uint256 public rewardsSplit = 20; // 20% of tax goes to rewards
    uint256 public burnSplit = 20; // 20% of tax goes to burn

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 333333 * 10**_decimals;
    string private constant _name = unicode"CΔVΞ(DAO)";
    string private constant _symbol = unicode"CΔVΞ";
    uint256 public maxTxAmount = _tTotal / 100; // 1% of total supply
    uint256 public maxWalletSize = _tTotal / 50; // 2% of total supply
    bool public txLimitsRemoved = false;

    uint256 public collectedTaxThreshold = _tTotal / 1000; // 0.1% of total supply  

    address public uniswapV2Pair;
    bool public tradingOpen;
    bool public autoTaxDistributionEnabled = false;
    bool private inInternalSwap = false;
    IUniswapV2Router02 public uniswapV2Router;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public launchContract;

    event ConfigurationChange(string varName, uint256 value);
    event ConfigurationChange(string varName, address value);
    event ConfigurationChange(string varName, bool value);
    event ConfigurationChange(string funcName);

    modifier lockTheSwap {
        inInternalSwap = true;
        _;
        inInternalSwap = false;
    }

    constructor (address payable _treasuryWallet, address payable _rewardsWallet, uint256 _feePercentage, address _uniswapV2Router) {
        treasuryWallet = _treasuryWallet;
        rewardsWallet = _rewardsWallet;
        feePercentage = _feePercentage;
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        
        _balances[_msgSender()] = _tTotal;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_treasuryWallet] = true;
        isExcludedFromFee[_rewardsWallet] = true;
        isExcludedFromFee[DEAD] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

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
        return _balances[account];
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0) && from != address(DEAD), "ERC20: transfer from invalid");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from == launchContract) {
            boughtAtLaunch[to] = true;
        }
        uint256 taxAmount = 0;
        hasSold[from] = true;
        uint256 _collectedTaxThreshold = collectedTaxThreshold;
        if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
            require(tradingOpen, "Trading is not open yet");
            bool isTransfer = from != uniswapV2Pair && to != uniswapV2Pair;
            if(!inInternalSwap && !isTransfer){
              taxAmount = amount.mul(feePercentage).div(100);
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(amount <= maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds the maxWalletSize.");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inInternalSwap && from != uniswapV2Pair && autoTaxDistributionEnabled && contractTokenBalance > _collectedTaxThreshold) {
                _distributeTaxes(_collectedTaxThreshold);
            }
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));

        emit Transfer(from, to, amount.sub(taxAmount));
        if(taxAmount > 0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function setTxLimits(uint256 _maxTxAmount, uint256 _maxWalletSize) external onlyOwner {
        require(!txLimitsRemoved, "Limits already removed");
        maxTxAmount = _maxTxAmount;
        maxWalletSize = _maxWalletSize;
        emit ConfigurationChange("maxTxAmount", _maxTxAmount);
        emit ConfigurationChange("maxWalletSize", _maxWalletSize);
    }

    function removeLimits() external onlyOwner {
        txLimitsRemoved = true;
        maxTxAmount = _tTotal;
        maxWalletSize = _tTotal;
        emit ConfigurationChange("LimitsRemoved");
    }

    function enableTrading() external onlyOwner() {
        require(!tradingOpen, "Trading is already open");
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        autoTaxDistributionEnabled = true;
        tradingOpen = true;
        emit ConfigurationChange("TradingEnabled");
    }

    function setAutoTaxDistributionEnabled(bool _enabled) external onlyOwner() {
        autoTaxDistributionEnabled = _enabled;
        emit ConfigurationChange("autoTaxDistributionEnabled", _enabled);
    }

    function reduceFee(uint256 _feePercentage) external onlyOwner{
        require(_feePercentage <= 10 || _feePercentage < feePercentage); // 10% or less than before required
        feePercentage = _feePercentage;
        emit ConfigurationChange("feePercentage", _feePercentage);
    }

    function setSplits(uint256 _burnSplit, uint256 _treasurySplit, uint256 _rewardsSplit) external onlyOwner{
        require(_burnSplit + _treasurySplit + _rewardsSplit==100, "INVALID_SPLITS");
        treasurySplit=_treasurySplit;
        rewardsSplit=_rewardsSplit;
        burnSplit=_burnSplit;
        emit ConfigurationChange("burnSplit", _burnSplit);
        emit ConfigurationChange("treasurySplit", _treasurySplit);
        emit ConfigurationChange("rewardsSplit", _rewardsSplit);
    }

    function setTaxThreshold(uint256 _newThreshold) external onlyOwner{
        collectedTaxThreshold = _newThreshold;
        emit ConfigurationChange("collectedTaxThreshold", _newThreshold);
    }

    function setExcludeFromFee(address _address, bool _excluded) external onlyOwner {
        isExcludedFromFee[_address] = _excluded;
        emit ConfigurationChange("isExcludedFromFee", _excluded);
    }

    //function to set the launchContract by the owner
    function setLaunchContract(address _launchContract) external onlyOwner {
        launchContract = _launchContract;
        isExcludedFromFee[_launchContract] = true;
        emit ConfigurationChange("launchContract", _launchContract);
    }

    function setTreasuryAddress(address payable _treasuryWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
        emit ConfigurationChange("treasuryWallet", _treasuryWallet);
    }

    function setRewardsAddress(address payable _rewardsWallet) external onlyOwner {
        rewardsWallet = _rewardsWallet;
        emit ConfigurationChange("treasuryWallet", _rewardsWallet);
    }

    function distributeTaxes(uint256 amount) external onlyOwner {
        _distributeTaxes(amount);
    }

    function _distributeTaxes(uint256 amount) internal { 
        uint256 _burnSplit = burnSplit;
        uint256 _treasurySplit = treasurySplit;
        uint256 _rewardsSplit = rewardsSplit;
        uint256 _treasuryAndRewardsSplit = _treasurySplit.add(_rewardsSplit);
        uint256 burnAmount = amount.div(100).mul(_burnSplit);
        amount = amount - burnAmount;
        _transfer(address(this), DEAD, burnAmount);
        _swapTokensForEth(amount);
        uint256 contractETHBalance = address(this).balance;

        if(contractETHBalance > 0) {
            _sendViaCall(treasuryWallet, contractETHBalance.div(_treasuryAndRewardsSplit).mul(_treasurySplit));
            _sendViaCall(rewardsWallet, contractETHBalance.div(_treasuryAndRewardsSplit).mul(_rewardsSplit));
        }
    }

    function _sendViaCall(address payable _to, uint256 amountETH) internal {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: amountETH}("");
        require(sent, "Failed to send Ether");
    }

    function manualSendToken() external onlyOwner{
        IERC20(address(this)).transfer(msg.sender, balanceOf(address(this)));
    }

    function withdrawERC20(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        bool sent = token.transfer(msg.sender, balance);
        require(sent, "Failed to send token");    
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        _sendViaCall(payable(msg.sender), balance);
    }
}
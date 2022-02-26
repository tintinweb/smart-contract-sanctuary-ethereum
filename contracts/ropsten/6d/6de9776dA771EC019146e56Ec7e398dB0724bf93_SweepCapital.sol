/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

// ERC20 token standard interface
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

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

// Dex Factory contract interface
interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Dex Router02 contract interface
interface IUniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Main token Contract

contract SweepCapital is Context, IERC20, Ownable {
    using SafeMath for uint256;

    // all private variables and functions are only for contract use
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10 * 1e7 * 1e9; // 100 Million total supply
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public maxHodingAmount = 2000000000000001; //2% of 100 Million

    string private _name = "Sweep Capital"; // token name
    string private _symbol = "SWEEP"; // token ticker
    uint8 private _decimals = 9; // token decimals

    IUniswapRouter public dexRouter; // Dex router address
    address public dexPair; // LP token address
    mapping(address => bool) private _isUniswapPair;

    address payable public teamWallet; //team wallet

    bool public reflectionFees = true; // should be false to charge fee

    // Normal sell tax fee
    uint256 public _holderRedistributionFee = 40; // 4% will be distributed among holder as token divideneds
    uint256 public _teamWalletFee = 60; // 6% will be added to the team pool

    // for smart contract use
    uint256 private _currentRedistributionFee;
    uint256 private _currentTeamWalletFee;

    //for buy back
    uint256 private _numOfTokensToExchangeForTeam = 100*10**9;
    bool private inSwap;
    bool public swapEnabled = true;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // constructor for initializing the contract
    constructor( ) {
        _rOwned[owner()] = _rTotal;

        teamWallet = payable(0x2Dc26AC389bb12916c58da049A99E8071f67f7ae);

        IUniswapRouter _dexRouter = IUniswapRouter(
          0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Create a Dex pair for this new token
        dexPair = IUniswapFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        // set the rest of the contract variables
        dexRouter = _dexRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[teamWallet] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    // token standards by Blockchain

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

    function balanceOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        return tokenFromReflection(_rOwned[_account]);
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

    // public view able functions

    // to check wether the address is excluded from fee or not
    function isExcludedFromFee(address _account) public view returns (bool) {
        return _isExcludedFromFee[_account];
    }

    // to check how much tokens get redistributed among holders till now
    function totalHolderDistribution() public view returns (uint256) {
        return _tFeeTotal;
    }

    // For manual distribution to the holders
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "ERC20: Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    //to receive ETH from dexRouter when swapping
    receive() external payable {}

    // internal functions for contract use

    function totalFeePerTx(uint256 tAmount) internal view returns (uint256) {
        uint256 percentage = tAmount
            .mul(
                _currentRedistributionFee
                    .add(_currentTeamWalletFee)
            )
            .div(1e3);
        return percentage;
    }

    function _getRate() private view returns (uint256) {
        return _rTotal.div(_tTotal);
    }

    function removeAllFee() private {
        _currentRedistributionFee = 0;
        _currentTeamWalletFee = 0;
    }

    function setTaxationFee() private {
        _currentRedistributionFee = _holderRedistributionFee;
        _currentTeamWalletFee = _teamWalletFee;
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

    // base function to transafer tokens
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap?
        // also, don't get caught in a circular team event.
        // also, don't swap if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance > maxHodingAmount) {
            contractTokenBalance = maxHodingAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >_numOfTokensToExchangeForTeam;
        if (
            !inSwap &&
            swapEnabled &&
            overMinTokenBalance &&
            from != dexPair || _isUniswapPair[from]
        ) 
        {

            // We need to swap the current tokens to ETH and send to the team wallet
            swapTokensForEth(contractTokenBalance);

            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                sendETHToTeam(address(this).balance);
            }
        }


        //indicates if fee should be deducted from transfer
        bool takeFee = false;
        
        // take fee only on swaps
        if (
          (from == dexPair ||
            to == dexPair ||
            _isUniswapPair[to] ||
            _isUniswapPair[from]) &&
          !(_isExcludedFromFee[from] || _isExcludedFromFee[to])
        ) {
          takeFee = true;
        }

        if(!(from == owner() || to == owner())){
          //check balance for other not the dex. 
          if(to!=dexPair && !_isUniswapPair[to] && !_isExcludedFromFee[to]){
            require(amount + balanceOf(to) < maxHodingAmount, "ERC20:Wallet Cannot hold more than 2% of total supply.");

          }
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if((recipient == dexPair || sender == dexPair ) && takeFee ){
          setTaxationFee();
        }
        else{
          removeAllFee();
        }
        _transferStandard(sender, recipient, amount);
    }

    // if both sender and receiver are not excluded from reward
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(
            totalFeePerTx(tAmount).mul(currentRate)
        );
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeamWalletFee(tAmount, currentRate);
        _reflectFee(tAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    // take fees for teamWallet
    function _takeTeamWalletFee(
        uint256 tAmount,
        uint256 currentRate
    ) internal {
        uint256 tFee = tAmount.mul(_currentTeamWalletFee).div(1e3);
        uint256 rFee = tFee.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rFee);

    }


    // for automatic redistribution among all holders on each tx
    function _reflectFee(uint256 tAmount) private {
        uint256 tFee = tAmount.mul(_currentRedistributionFee).div(1e3);
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }


    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToTeam(uint256 amount) private {
        (bool os, ) = payable(teamWallet).call{value: amount}("");
        require(os);
    }

    function isUniswapPair(address _pair) external view returns (bool) {
      if (_pair == dexPair) return true;
      return _isUniswapPair[_pair];
    }


    function addUniswapPair(address _pair) external onlyOwner {
      _isUniswapPair[_pair] = true;
    }

    function removeUniswapPair(address _pair) external onlyOwner {
      _isUniswapPair[_pair] = false;
    }

    // owner can change router and pair address
    function setRoute(IUniswapRouter _router, address _pair) external onlyOwner {
        dexRouter = _router;
        dexPair = _pair;
    }
      //input 10 for 1 percent
    function setRedistributionFee(uint256 _fee) external onlyOwner {
        _holderRedistributionFee = _fee;
    }
        //input 10 for 1 percent
    function setTeamWalletFee(uint256 _teamFee) external onlyOwner {
        _teamWalletFee = _teamFee;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function flipSwapEnable() external onlyOwner{
        if(swapEnabled)
            swapEnabled = false;
        else
            swapEnabled = true; 
    }


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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
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
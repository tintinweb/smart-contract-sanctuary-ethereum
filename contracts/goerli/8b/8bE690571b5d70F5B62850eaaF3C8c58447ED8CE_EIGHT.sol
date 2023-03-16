// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Libraries.sol";

contract EIGHT is IERC20Metadata, Ownable
{
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public excludedFromLimit;
    mapping(address => bool) public isAMM;
    //Token Info
    string private constant _name = 'ArbitrAI';
    string private constant _symbol = 'AAI-1';
    uint8 private constant _decimals = 18;
    uint public constant InitialSupply = 10 ** 9 * 10 ** _decimals;

    uint private constant DefaultLiquidityLockTime = 7 days;

    address private constant UniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint private _circulatingSupply = InitialSupply;

    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    uint public buyTax = 150;
    uint public sellTax = 150;
    uint public transferTax = 0;
    uint public burnTax = 0;
    uint public minerTax = 250;
    uint public marketingTax = 750;
    uint constant TAX_DENOMINATOR = 1000;
    uint constant MAXTAXDENOMINATOR = 10;

    address private _uniswapPairAddress;
    IUniswapRouter private  _uniswapRouter;


    //TODO: marketingWallet
    address public marketingWallet;
    //Only marketingWallet can change marketingWallet
    function ChangeMarketingWallet(address newWallet) public {
        require(msg.sender == marketingWallet);
        marketingWallet = newWallet;
    }

    address public minerContract = 0xFF6CdCD9A2B13E54b250420739EAA96Db01a165E;
    function ChangeMinerContract(address newContract) public onlyTeam{
        minerContract = newContract;
    }
    //modifier for functions only the team can call
    modifier onlyTeam() {
        require(_isTeam(msg.sender), "Caller not Team or Owner");
        _;
    }
    //Checks if address is in Team, is needed to give Team access even if contract is renounced
    //Team doesn't have access to critical Functions that could turn this into a Rugpull(Exept liquidity unlocks)
    function _isTeam(address addr) private view returns (bool){
        return addr == owner() || addr == marketingWallet;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Constructor///////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor () {
        uint deployerBalance = _circulatingSupply;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);

        // Uniswap Router
        _uniswapRouter = IUniswapRouter(UniswapRouter);
        //Creates a Uniswap Pair
        _uniswapPairAddress = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        isAMM[_uniswapPairAddress] = true;

        //contract creator is by default marketing wallet
        marketingWallet = msg.sender;
        //owner uniswap router and contract is excluded from Taxes
        excludedFromFees[msg.sender] = true;
        excludedFromFees[UniswapRouter] = true;
        excludedFromFees[address(this)] = true;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Transfer functionality////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //transfer function, every transfer runs through this function
    function _transfer(address sender, address recipient, uint amount) private {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");


        //Pick transfer
        if (excludedFromFees[sender] || excludedFromFees[recipient])
            _feelessTransfer(sender, recipient, amount);
        else {
            //once trading is enabled, it can't be turned off again
            require(LaunchTimestamp > 0, "trading not yet enabled");
            _taxedTransfer(sender, recipient, amount);
        }
    }
    //applies taxes, checks for limits, locks generates autoLP and stakingETH, and autostakes
    function _taxedTransfer(address sender, address recipient, uint amount) private {
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        bool isBuy = isAMM[sender];
        bool isSell = isAMM[recipient];

        uint tax;
        if (isSell) {
            uint SellTaxDuration = 60 seconds;
            if (block.timestamp < LaunchTimestamp + SellTaxDuration) {
                tax = TAX_DENOMINATOR;
            } else tax = sellTax;
        }
        else if (isBuy) {
            uint BuyTaxDuration = 60 seconds;
            if (block.timestamp < LaunchTimestamp + BuyTaxDuration) {
                tax = TAX_DENOMINATOR;
            } else tax = buyTax;
        } else tax = transferTax;

        //Calculates the exact token amount for each tax
        uint tokensToBeBurnt = _calculateFee(amount, tax, burnTax);
        // tax amount duduced from amount
        uint contractToken = _calculateFee(amount, tax, marketingTax + minerTax);
        //Subtract the Taxed Tokens from the amount
        uint taxedAmount = amount - (tokensToBeBurnt + contractToken);

        _balances[sender] -= amount;
        //Adds the taxed tokens to the operation & miner wallet
        _balances[address(this)] += contractToken;
        //Burns tokens
        _circulatingSupply -= tokensToBeBurnt;
        _balances[recipient] += taxedAmount;

        if ((sender != _uniswapPairAddress) && (!manualSwap) && (!_isSwappingContractModifier))
            _swapContractToken(contractToken);

        emit Transfer(sender, recipient, taxedAmount);
    }

    //Calculates the token that should be taxed
    function _calculateFee(uint amount, uint tax, uint taxPercent) private pure returns (uint) {
        return (amount * tax * taxPercent) / (TAX_DENOMINATOR * TAX_DENOMINATOR);
    }


    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(address sender, address recipient, uint amount) private {
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Swap Contract Tokens//////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //Locks the swap if already swapping
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    //Sets the taxes Burn+marketing+liquidity tax needs to equal the TAX_DENOMINATOR (1000)
    //buy, sell and transfer tax are limited by the MAXTAXDENOMINATOR
    event OnSetTaxes(uint buy, uint sell, uint transfer_, uint burn, uint marketing, uint miner);

    function SetTaxes(uint buy, uint sell, uint transfer_, uint burn, uint marketing, uint miner) public onlyTeam {
        uint maxTax = TAX_DENOMINATOR / MAXTAXDENOMINATOR;
        require(buy <= maxTax && sell <= maxTax && transfer_ <= maxTax, "Tax exceeds maxTax");
        require(burn + marketing + miner == TAX_DENOMINATOR, "Taxes don't add up to denominator");

        buyTax = buy;
        sellTax = sell;
        transferTax = transfer_;
        marketingTax = marketing;
        minerTax = miner;
        burnTax = burn;
        emit OnSetTaxes(buy, sell, transfer_, burn, marketing, miner);
    }

    //swaps the token on the contract for Marketing ETH and LP Token.
    //always swaps a percentage of the LP pair balance to avoid price impact
    function _swapContractToken(uint tokenToSwap) private lockTheSwap {
        uint totalTax = minerTax + marketingTax;
        uint initialETHBalance = address(this).balance;
        _swapTokenForETH(tokenToSwap);
        uint newETH = (address(this).balance - initialETHBalance);

        uint marketingETH = (newETH * marketingTax) / totalTax;

        //Sends all the marketing ETH to the marketingWallet
        (bool sent1,) = marketingWallet.call{value : marketingETH}("");
        (bool sent2,) = minerContract.call{value : newETH - marketingETH}("");
        sent1 = true;
        sent2 = true;
    }
    //swaps tokens on the contract for ETH
    function _swapTokenForETH(uint amount) private {
        _approve(address(this), address(_uniswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();

        try _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        ){}
        catch{}
    }

    function getBurnedTokens() public view returns (uint){
        return (InitialSupply - _circulatingSupply) + _balances[address(0xdead)];
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //For AMM addresses buy and sell taxes apply
    function SetAMM(address AMM, bool Add) public onlyTeam {
        require(AMM != _uniswapPairAddress, "can't change uniswap");
        isAMM[AMM] = Add;
    }

    bool public manualSwap;
    //switches autoLiquidity and marketing ETH generation during transfers
    function SwitchManualSwap(bool manual) public onlyTeam {
        manualSwap = manual;
    }
    //manually converts contract token to LP and staking ETH
    function SwapContractToken() public onlyTeam {
        uint tokenToSwap = _balances[address(this)];
        _swapContractToken(tokenToSwap);
    }

    event ExcludeAccount(address account, bool exclude);
    //Exclude/Include account from fees (eg. CEX)
    function ExcludeAccountFromFees(address account, bool exclude) public onlyTeam {
        require(account != address(this), "can't Include the contract");
        excludedFromFees[account] = exclude;
        emit ExcludeAccount(account, exclude);
    }
    //Enables trading. Sets the launch timestamp to the given Value
    event OnEnableTrading();

    uint public LaunchTimestamp;

    function SetupEnableTrading() public onlyTeam {
        require(LaunchTimestamp == 0, "AlreadyLaunched");
        LaunchTimestamp = block.timestamp;
        emit OnEnableTrading();
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint) {
        return _circulatingSupply;
    }

    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // IERC20 - Helpers

    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}
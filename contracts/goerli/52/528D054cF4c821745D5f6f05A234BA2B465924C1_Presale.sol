// solhint-disable not-rely-on-time
// solhint-disable-next-line
pragma solidity ^0.8.17;
// SPDX-License-Identifier: Unlicensed
// A+G = VNL
// https://github.com/kirilradkov14

import "./utils/Ownable.sol";
import "./utils/Whitelist.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";


contract Presale is Ownable, Whitelist {

    bool public isInit;
    bool public isDeposit;
    bool public isRefund;
    bool public isFinish;
    bool public burnTokens;
    bool public isWhitelist;
    address public creatorWallet;
    address public teamWallet;
    address public weth;
    uint8 constant private FEE = 2;
    uint8 public tokenDecimals;
    uint256 public presaleTokens;
    uint256 public ethRaised;

    struct Pool {
        uint64 startTime;
        uint64 endTime;
        uint8 liquidityPortion;
        uint256 saleRate;
        uint256 listingRate;
        uint256 hardCap;
        uint256 softCap;
        uint256 maxBuy;
        uint256 minBuy;
    }

    IERC20 public tokenInstance;
    IUniswapV2Factory public UniswapV2Factory;
    IUniswapV2Router02 public UniswapV2Router02;
    Pool public pool;

    mapping(address => uint256) public ethContribution;

    modifier onlyActive {
        require(block.timestamp >= pool.startTime, "Sale must be active.");
        require(block.timestamp <= pool.endTime, "Sale must be active.");
        _;
    }

    modifier onlyInactive {
        require(
            block.timestamp < pool.startTime || 
            block.timestamp > pool.endTime || 
            ethRaised >= pool.hardCap, "Sale must be inactive."
            );
        _;
    }

    modifier onlyRefund {
        require(
            isRefund == true || 
            (block.timestamp > pool.endTime && ethRaised <= pool.hardCap), "Refund unavailable."
            );
        _;
    }

    constructor(
        uint8 _tokenDecimals,
        address _tokenInstance,
        address _uniswapv2Router, 
        address _uniswapv2Factory,
        address _teamWallet,
        address _weth,
        bool _burnTokens,
        bool _isWhitelist
        ) {

        require(_uniswapv2Router != address(0), "Invalid router address");
        require(_uniswapv2Factory != address(0), "Invalid factory address");
        require(_tokenDecimals >= 0, "Decimals not supported.");
        require(_tokenDecimals <= 18, "Decimals not supported.");

        isInit = false;
        isDeposit = false;
        isFinish = false;
        isRefund = false;
        ethRaised = 0;

        teamWallet = _teamWallet;
        weth = _weth;
        burnTokens = _burnTokens;
        isWhitelist = _isWhitelist;
        tokenInstance = IERC20(_tokenInstance);
        creatorWallet = address(payable(msg.sender));
        tokenDecimals =  _tokenDecimals;
        UniswapV2Router02 = IUniswapV2Router02(_uniswapv2Router);
        UniswapV2Factory = IUniswapV2Factory(_uniswapv2Factory);

        require(UniswapV2Factory.getPair(address(tokenInstance), weth) == address(0), "IUniswap: Pool exists.");

        tokenInstance.approve(_uniswapv2Router, tokenInstance.totalSupply());
    }

    event Liquified(
        address indexed _token, 
        address indexed _router, 
        address indexed _pair
        );

    event Canceled(
        address indexed _inititator, 
        address indexed _token, 
        address indexed _presale
        );

    event Bought(address indexed _buyer, uint256 _tokenAmount);

    event Refunded(address indexed _refunder, uint256 _tokenAmount);

    event Deposited(address indexed _initiator, uint256 _totalDeposit);

    event Claimed(address indexed _participent, uint256 _tokenAmount);

    event RefundedRemainder(address indexed _initiator, uint256 _amount);

    event BurntRemainder(address indexed _initiator, uint256 _amount);

    event Withdraw(address indexed _creator, uint256 _amount);

    /*
    * Reverts ethers sent to this address whenever requirements are not met
    */
    receive() external payable {
        if(block.timestamp >= pool.startTime && block.timestamp <= pool.endTime){
            buyTokens(_msgSender());
        } else {
            revert("Presale is closed");
        }
    }

    /*
    * Initiates the arguments of the sale
    @dev arguments must be pa   ssed in wei (amount*10**18)
    */
    function initSale(
        uint64 _startTime,
        uint64 _endTime,
        uint8 _liquidityPortion,
        uint256 _saleRate, 
        uint256 _listingRate,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _maxBuy,
        uint256 _minBuy
        ) external onlyOwner onlyInactive {        

        require(isInit == false, "Sale no initialized");
        require(_startTime >= block.timestamp, "Invalid start time.");
        require(_endTime > block.timestamp, "Invalid end time.");
        require(_softCap >= _hardCap / 2, "SC must be >= HC/2.");
        require(_liquidityPortion >= 30, "Liquidity must be >=30.");
        require(_liquidityPortion <= 100, "Invalid liquidity.");
        require(_minBuy < _maxBuy, "Min buy must greater than max.");
        require(_minBuy > 0, "Min buy must exceed 0.");
        require(_saleRate > 0, "Invalid sale rate.");
        require(_listingRate > 0, "Invalid listing rate.");

        Pool memory newPool = Pool(
            _startTime,
            _endTime, 
            _liquidityPortion,
            _saleRate, 
            _listingRate, 
            _hardCap,
            _softCap, 
            _maxBuy, 
            _minBuy
            );

        pool = newPool;
        
        isInit = true;
    }

    /*
    * Once called the owner deposits tokens into pool
    */
    function deposit() external onlyOwner {
        require(!isDeposit, "Tokens already deposited.");
        require(isInit, "Not initialized yet.");

        uint256 tokensForSale = pool.hardCap * (pool.saleRate) / (10**18) / (10**(18-tokenDecimals));
        presaleTokens = tokensForSale;
        uint256 totalDeposit = _getTokenDeposit();

        isDeposit = true;
        require(tokenInstance.transferFrom(msg.sender, address(this), totalDeposit), "Deposit failed.");
        emit Deposited(msg.sender, totalDeposit);
    }

    /*
    * Finish the sale - Create Uniswap v2 pair, add liquidity, take fees, withrdawal funds, burn/refund unused tokens
    */
    function finishSale() external onlyOwner onlyInactive{
        require(ethRaised >= pool.softCap, "Soft Cap is not met.");
        require(block.timestamp > pool.startTime, "Can not finish before start");
        require(!isFinish, "Sale already launched.");
        require(!isRefund, "Refund process.");

        //get the used amount of tokens
        uint256 tokensForSale = ethRaised * (pool.saleRate) / (10**18) / (10**(18-tokenDecimals));
        uint256 tokensForLiquidity = ethRaised * pool.listingRate * pool.liquidityPortion / 100;
        tokensForLiquidity = tokensForLiquidity / (10**18) / (10**(18-tokenDecimals));
        tokensForLiquidity = tokensForLiquidity - (tokensForLiquidity * FEE / 100);
        uint256 tokensForFee = FEE * (tokensForSale + tokensForLiquidity) / 100;
        isFinish = true;
        
        //add liquidity
        (uint amountToken, uint amountETH, ) = UniswapV2Router02.addLiquidityETH{value : _getLiquidityEth()}(
            address(tokenInstance),
            tokensForLiquidity, 
            tokensForLiquidity, 
            _getLiquidityEth(), 
            owner(), 
            block.timestamp + 600
            );

        require(amountToken == tokensForLiquidity && amountETH == _getLiquidityEth(), "Providing liquidity failed.");
        emit Liquified(
            address(tokenInstance), 
            address(UniswapV2Router02), 
            UniswapV2Factory.getPair(address(tokenInstance), 
            weth)
            );

        //take the Fees
        uint256 teamShareEth = _getFeeEth();
        payable(teamWallet).transfer(teamShareEth);

        require(tokenInstance.transfer(teamWallet, tokensForFee), "Fee taking failed.");

        //withrawal eth
        uint256 ownerShareEth = _getOwnerEth();
        if (ownerShareEth > 0) {
            payable(creatorWallet).transfer(ownerShareEth);
        }

        //If HC is not reached, burn or refund the remainder
        if (ethRaised < pool.hardCap) {
            uint256 remainder = _getTokenDeposit() - (tokensForSale + tokensForLiquidity + tokensForFee);
            if(burnTokens == true){
                require(tokenInstance.transfer(
                    0x000000000000000000000000000000000000dEaD, 
                    remainder), "Unable to burn."
                    );
                emit BurntRemainder(msg.sender, remainder);
            } else {
                require(tokenInstance.transfer(creatorWallet, remainder), "Refund failed.");
                emit RefundedRemainder(msg.sender, remainder);
            }
        }
    }

    /*
    * The owner can decide to close the sale if it is still active
    NOTE: Creator may call this function even if the Hard Cap is reached, to prevent it use:
     require(ethRaised < pool.hardCap)
    */
    function cancelSale() external onlyOwner onlyActive {
        require(!isFinish, "Sale finished.");
        pool.endTime = 0;
        isRefund = true;

        if (tokenInstance.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            tokenInstance.transfer(msg.sender, tokenDeposit);
            emit Withdraw(msg.sender, tokenDeposit);
        }
        emit Canceled(msg.sender, address(tokenInstance), address(this));
    }

    /*
    * Allows participents to claim the tokens they purchased 
    */
    function claimTokens() external onlyInactive {
        require(isFinish, "Sale is still active.");
        require(!isRefund, "Refund process.");

        uint256 tokensAmount = _getUserTokens(ethContribution[msg.sender]);
        ethContribution[msg.sender] = 0;
        require(tokenInstance.transfer(msg.sender, tokensAmount), "Claim failed.");
        emit Claimed(msg.sender, tokensAmount);
    }

    /*
    * Refunds the Eth to participents
    */
    function refund() external onlyInactive onlyRefund{
        uint256 refundAmount = ethContribution[msg.sender];

        if (address(this).balance >= refundAmount) {
            if (refundAmount > 0) {
                ethContribution[msg.sender] = 0;
                address payable refunder = payable(msg.sender);
                refunder.transfer(refundAmount);
                emit Refunded(refunder, refundAmount);
            }
        }
    }

    /*
    * Withdrawal tokens on refund
    */
    function withrawTokens() external onlyOwner onlyInactive onlyRefund {
        if (tokenInstance.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            require(tokenInstance.transfer(msg.sender, tokenDeposit), "Withdraw failed.");
            emit Withdraw(msg.sender, tokenDeposit);
        }
    }

    /*
    * Disables WL
    */
    function disableWhitelist() external onlyOwner{
        require(isWhitelist, "WL already disabled.");

        isWhitelist = false;
    }

    /*
    * If requirements are passed, updates user"s token balance based on their eth contribution
    */
    function buyTokens(address _contributor) public payable onlyActive {
        require(isDeposit, "Tokens not deposited.");

        uint256 weiAmount = msg.value;
        _checkSaleRequirements(_contributor, weiAmount);
        uint256 tokensAmount = _getUserTokens(ethContribution[msg.sender]);
        ethRaised += weiAmount;
        presaleTokens -= tokensAmount;
        ethContribution[msg.sender] += weiAmount;
        emit Bought(_msgSender(), tokensAmount);
    }

    /*
    * Checks whether a user passes token purchase requirements, called internally on buyTokens function
    */
    function _checkSaleRequirements(address _beneficiary, uint256 _amount) internal view { 
        if(isWhitelist){
            require(whitelists[_msgSender()], "User not Whitelisted.");
        }

        require(_beneficiary != address(0), "Transfer to 0 address.");
        require(_amount != 0, "Wei Amount is 0");
        require(_amount >= pool.minBuy, "Min buy is not met.");
        require(_amount + ethContribution[_beneficiary] <= pool.maxBuy, "Max buy limit exceeded.");
        require(ethRaised + _amount <= pool.hardCap, "HC Reached.");
        this;
    }

    /*
    * Internal functions, called when calculating balances
    */
    function _getUserTokens(uint256 _amount) internal view returns (uint256){
        return _amount * (pool.saleRate) / (10 ** 18) / (10**(18-tokenDecimals));
    }

    function _getLiquidityTokensDeposit() internal view returns (uint256) {
        uint256 value = pool.hardCap * pool.listingRate * pool.liquidityPortion / 100;
        value = value - (value * FEE / 100);
        return value / (10**18) / (10**(18-tokenDecimals));
    }
    
    function _getFeeEth() internal view returns (uint256) {
        return (ethRaised * FEE / 100);
    }

    function _getLiquidityEth() internal view returns (uint256) {
        uint256 etherFee = _getFeeEth();
        return((ethRaised - etherFee) * pool.liquidityPortion / 100);
    }

    function _getOwnerEth() internal view returns (uint256) { 
        uint256 etherFee = _getFeeEth();
        uint256 liquidityEthFee = _getLiquidityEth();
        return(ethRaised - (etherFee + liquidityEthFee));
    }
    
    function _getTokenDeposit() internal view returns (uint256){
        uint256 tokensForSale = pool.hardCap * pool.saleRate / (10**18) / (10**(18-tokenDecimals));
        uint256 tokensForLiquidity = _getLiquidityTokensDeposit();
        uint256 tokensForFee = FEE * (tokensForSale + tokensForLiquidity) / 100;
        return(tokensForSale + tokensForLiquidity + tokensForFee);
    }
}

// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line
pragma solidity ^0.8.17;

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
        // solhint-disable-next-line
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// solhint-disable-next-line
pragma solidity ^0.8.17;
// SPDX-License-Identifier: Unlicensed
// A+G = VNL
// https://github.com/kirilradkov14

import "./Ownable.sol";

abstract contract Whitelist is Ownable{

    mapping(address => bool) public whitelists;

    function wlAddress(address _user) external onlyOwner{
        require(whitelists[_user] == false, "Address already WL");
        require(_user != address(0), "Can not WL 0 address");

        whitelists[_user] = true;
    }

    function wlMultipleAddresses(address[] calldata  _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++){
            whitelists[_users[i]] = true;
        }
    }

    function removeAddress(address _user) external onlyOwner {
        require(whitelists[_user] == true, "User not WL");
        require(_user != address(0), "Can not delist 0 address");

         whitelists[_user] = false;
    }

    function removeMultipleAddresses(address[] calldata  _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++){
            whitelists[_users[i]] = false;
        }
    }
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

pragma solidity >=0.5.0;

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (
        uint amountToken,
        uint amountETH,
        uint liquidity
    );
}
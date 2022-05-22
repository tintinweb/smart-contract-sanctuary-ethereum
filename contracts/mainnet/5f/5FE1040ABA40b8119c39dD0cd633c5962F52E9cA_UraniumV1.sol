// TESTNET Contract: 0x566e777dBa0Dc36a2a79fEb7374703600aE1fF1b
// TO LAUNCH TOKEN:
// 1. Deploy on Chain
// 2. Add Uniswap Pair as Sales Address
// 3. Add Contract Owner as Sales Address
// 4. Exclude Contract Owner, Uniswap Pair, and 0x0 address

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// Contract implementarion
    contract UraniumV1 is Context, ERC20, Ownable {
        using SafeMath for uint256;
        using Address for address;

        uint8 private _decimals = 18;

        // _t == tokens 
        mapping (address => uint256) private _tOwned;
        mapping (address => uint256) private _tClaimed;
        mapping (address => uint256) private _tFedToReactor;
        mapping (address => uint256) private _avgPurchaseDate;


        // Exclude address from fee by address
        // Is address excluded from sales tax
        mapping (address => bool) private _isExcluded;

        // Just a list of addresses where sales tax is applied. 
        mapping (address => bool) private _isSaleAddress;

        // Total supply is Uranium's atomic Mass in Billions
        uint256 private _tTotal = 23802891 * 10**4 * 10**_decimals;

        // Total reflections processed
        // To get the balance of the tokens on the contract use balanceOf(this)
        uint256 private _tFeeTotal = 0;
        // Total reflections claimed
        uint256 private _tFeeTotalClaimed = 0;
        
        // Tax and charity fees will start at 0 so we don't have a big impact when deploying to Uniswap
        // Charity wallet address is null but the method to set the address is exposed
        // Is there any reason we should make this uint16 instead of 256. Memory saving?
        uint256 private _taxFee = 0;
        uint256 private _charityFeePercent = 0;
        uint256 private _burnFeePercent = 90;
        uint256 private _marketingFeePercent = 5;
        uint256 private _stakingPercent = 5;

        // How many days until fee drops to 0
        uint256 private _daysForFeeReduction = 365;
        uint256 private _minDaysForReStake = 30;
        // The Max % of users tokens they can claim of the rewards
        uint256 private _maxPercentOfStakeRewards = 10;

        // Feed the Reactor Sales Tax % Required
        uint256 private _minSalesTaxRequiredToFeedReactor = 50;

        ReactorValues private _reactorValues = ReactorValues(
            10, 80, 10, 0, 10
        );


        //Feed the reactor
        struct ReactorValues {
            uint256 baseFeeReduction;
            uint256 stakePercent;
            uint256 burnPercent;
            uint256 charityPercent;
            uint256 marketingPercent;
        }

        // Not sure where this plays yet.
        address payable public _charityAddress;
        address payable public _marketingWallet;

        uint256 private _maxTxAmount  =  23802891 * 10**4 * 10**_decimals;

        IUniswapV2Router02 public immutable uniswapV2Router;
        address public immutable uniswapV2Pair;

        constructor (address payable charityAddress, address payable marketingWallet, address payable mainSwapRouter) ERC20("Uranium", "U238") {
            _charityAddress = charityAddress;
            _marketingWallet = marketingWallet;
            _tOwned[_msgSender()] = _tTotal;
            // Set initial variables

            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(mainSwapRouter);
            // Create a uniswap pair for this new token
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());

            // set the rest of the contract variables
            uniswapV2Router = _uniswapV2Router;

            _isSaleAddress[mainSwapRouter] = true;
            _isSaleAddress[_msgSender()] = true;
            // Exclude from sales tax 
            _isExcluded[address(0)] = true;
            _isExcluded[address(this)] = true;
            _isExcluded[_msgSender()] = true;

            // Do I need to add UniSwap to excluded here?
            emit Transfer(address(0), _msgSender(), _tTotal);
        }

        function decimals() public view override returns (uint8) {
            return _decimals;
        }


        function totalSupply() public view override returns (uint256) {
            return _tTotal.sub(_tOwned[address(0)]);
        }

        function balanceOf(address account) public view override returns (uint256) {
            return _tOwned[account];
        }

        function getTokensClaimedByAddress(address account) public view returns (uint256) {
            return _tClaimed[account];
        }

        function getTokensFedToReactor(address account) public view returns (uint256){
            return _tFedToReactor[account];
        }

        function currentFeeForAccount(address account) public view returns (uint256) {
            return _calculateUserFee(account);
        }

        function getAvgPurchaseDate(address account) public view returns (uint256) {
            return _avgPurchaseDate[account];
        }

        function transfer(address recipient, uint256 amount) public override returns (bool) {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }

        function getStakeRewardByAddress(address recipient) public view returns (uint256) { 
            require(_tOwned[recipient] > 0, "Recipient must own tokens to claim rewards");
            require(_tOwned[address(this)] > 0, "Contract must have more than 0 tokens");
            uint256 maxTokensClaimable = _tOwned[address(this)].mul(_maxPercentOfStakeRewards).div(100);
            uint256 maxTokensClaimableByUser = _tOwned[recipient].mul(_maxPercentOfStakeRewards).div(100);
            if (maxTokensClaimableByUser > maxTokensClaimable){
                return maxTokensClaimable;
            }else{
                return maxTokensClaimableByUser;
            }
        }

        function _claimTokens(address sender, uint256 tAmount) private returns (bool) {
            require(_tOwned[address(this)].sub(tAmount) > 0, "Contract doesn't have enough tokens");
            _avgPurchaseDate[sender] = block.timestamp;
            _tOwned[sender] = _tOwned[sender].add(tAmount);
            _tClaimed[sender] = _tClaimed[sender].add(tAmount);
            _tOwned[address(this)] = _tOwned[address(this)].sub(tAmount);
            _tFeeTotalClaimed = _tFeeTotalClaimed.add(tAmount);
            return true;
        }

        function restakeTokens() public returns (bool) {
            // Sender must own tokens
            require(_tOwned[_msgSender()] > 0, "You must own tokens to claim rewards");
            require(_tOwned[address(this)] > 0, "Contract must have more than 0 tokens");
            // Sender must meet the minimum days for restaking
            require(_avgPurchaseDate[_msgSender()] <= block.timestamp.sub(uint256(86400).mul(_minDaysForReStake)), "You do not qualify for restaking at this time");
            
            uint256 maxTokensClaimable = _tOwned[address(this)].mul(_maxPercentOfStakeRewards).div(100);
            uint256 maxTokensClaimableByUser = _tOwned[_msgSender()].mul(_maxPercentOfStakeRewards).div(100);
            if (maxTokensClaimableByUser > maxTokensClaimable){
                return _claimTokens(_msgSender(), maxTokensClaimable);
            }else{
                return _claimTokens(_msgSender(), maxTokensClaimableByUser);
            }
        }

        function feedTheReactor(bool confirmation) public returns (bool) {
            // WARNING -- ONLY CALL THIS FUNCTION IF YOU TRULY UNDERSTAND WHAT IT DOES!
            // HIGH RISK FUNCTION TO CALL
            require(_tOwned[_msgSender()] > 0, "You must own tokens to feed the reactor");
            uint256 userFee = _calculateUserFee(_msgSender());
            require(userFee >= _minSalesTaxRequiredToFeedReactor, "Your sales fee must be greater than minSalesTaxRequiredToFeedReactor");
            require(confirmation, "You must supply 'true' to confirm you understand what you are doing");
            // First we find out the total amount the normal fee would be
            uint256 totalFee = _tOwned[_msgSender()].mul(userFee).div(100);
            // Then we calculate the reduced fee from using FeedTheReactor
            uint256 reactorFee = totalFee.mul(uint256(100).sub(_reactorValues.baseFeeReduction)).div(100);
            // Now we calculate individual parts of the fee. 
            uint256 stakeFee = reactorFee.mul(_reactorValues.stakePercent).div(100);
            uint256 burnFee = reactorFee.mul(_reactorValues.burnPercent).div(100);
            uint256 charityFee = reactorFee.mul(_reactorValues.charityPercent).div(100);
            uint256 marketingFee = reactorFee.mul(_reactorValues.marketingPercent).div(100);
            // Now we reduce the number of tokens the user has while taking the fees.
            _tOwned[_msgSender()] = _tOwned[_msgSender()].sub(reactorFee);
            _tFedToReactor[_msgSender()] = _tFedToReactor[_msgSender()].add(reactorFee);
            _takeBurn(_msgSender(), burnFee);
            _takeCharity(charityFee); 
            _takeMarketing(marketingFee); 
            _reflectFee(stakeFee);
            // Set avg Purchase date to NOW - number of days for fee reduction
            _avgPurchaseDate[_msgSender()] = block.timestamp.sub(uint256(86400).mul(_daysForFeeReduction));
            return true;
        }

        function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
            _transfer(sender, recipient, amount);
            approve(sender, amount);
            return true;
        }

        function isExcluded(address account) public view returns (bool) {
            return _isExcluded[account];
        }

        function isSalesAddress(address account) public view returns (bool) {
            return _isSaleAddress[account];
        }

        function totalTokensReflected() public view returns (uint256) {
            return _tFeeTotal;
        }

        function totalTokensClaimed() public view returns (uint256) {
            return _tFeeTotalClaimed;
        }

        function addSaleAddress(address account) external onlyOwner() {
            require(!_isSaleAddress[account], "Account is already a sales address");
            _isSaleAddress[account] = true;
        }

        function removeSaleAddress(address account) external onlyOwner(){
            require(_isSaleAddress[account], "Account is not a Sales Address");
            _isSaleAddress[account] = false;
        }

        function excludeAccount(address account) external onlyOwner() {
            require(!_isExcluded[account], "Account is already excluded");
            _isExcluded[account] = true;
        }

        // There is an issue where this doesn't seem to work to remove isExcluded
        function includeAccount(address account) external onlyOwner() {
            require(_isExcluded[account], "Account is already included");
            _isExcluded[account] = false;
        }

        // I need to confirm you can't go below 0 here. 
        function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
            // I am sure this is safe because I do the burn manually not through an emit transfer
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "Transfer amount must be greater than zero");
            
            if(sender != owner() && recipient != owner())
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
          
            //transfer amount, it will take taxes and fees out
            _transferStandard(sender, recipient, amount);
        }

        function _transferStandard(address sender, address recipient, uint256 tAmount) private {
            
            TransferValues memory tValues = _getValues(tAmount, sender, recipient);
            
            _setWeightedAvg(sender, recipient, _tOwned[recipient].add(tValues.tTransferAmount), tValues.tTransferAmount);

            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tValues.tTransferAmount);

            _takeBurn(sender, tValues.tBurn);
            _takeCharity(tValues.tCharity); 
            _takeMarketing(tValues.tMarketing); 
            _reflectFee(tValues.tFee);

            emit Transfer(sender, recipient, tValues.tTransferAmount);
        }

        function _getValues(uint256 tAmount, address sender, address receiver) private view returns (TransferValues memory) {
            // If sales address is receiver
            uint256 baseFee = _taxFee;
            if (_isSaleAddress[receiver]){
                baseFee = _calculateUserFee(sender);
            }
            TransferValues memory tValues = _getTValues(tAmount, baseFee);
            return (tValues);
        }

        struct TransferValues {
            uint256 tTransferAmount;
            uint256 tTotalFeeAmount;
            uint256 tFee;
            uint256 tCharity;
            uint256 tMarketing;
            uint256 tBurn;
        }

        function _getTValues(uint256 tAmount, uint256 taxFee) private view returns (TransferValues memory) {
            uint256 totalFeeAmount = tAmount.mul(taxFee).div(100);
            // Calculate percentage of Reflection from total fees
            uint256 tFee = totalFeeAmount.mul(_stakingPercent).div(100);
            // Calculate percentage of Charity from Total fees
            uint256 tCharity = totalFeeAmount.mul(_charityFeePercent).div(100);
            // Calculate percentage to Marketing Wallet
            uint256 tMarketing = totalFeeAmount.mul(_marketingFeePercent).div(100);
            // Calculate percentage to Burn
            uint256 tBurn = totalFeeAmount.mul(_burnFeePercent).div(100);

            // Stack was too deep to do this in one line. Dumb but w/e
            uint256 tStackTooDeep = tAmount.sub(tFee).sub(tCharity);
            // Final left over after all of the above
            uint256 tTransferAmount = tStackTooDeep.sub(tMarketing).sub(tBurn);
            
            return TransferValues(tTransferAmount, totalFeeAmount, tFee, tCharity, tMarketing, tBurn);
        }

        function _setWeightedAvg(address sender, address recipient, uint256 aTotal, uint256 tAmount) private {
            uint256 senderPurchaseDate = _avgPurchaseDate[sender];
            // If the sender is a saleAddress we need to set the purchase date to the newest blocktime.
             if (_isSaleAddress[sender]){
                senderPurchaseDate = block.timestamp;
            }
            // If the senderPurchaseDate == 0, we need to make it only less than 1 year from now otherwise you cut 
            // Unix timestamp in half hahahaha
            if (senderPurchaseDate == 0){
                senderPurchaseDate = block.timestamp.sub(uint256(86400).mul(_daysForFeeReduction));
            }
            // So the problem here is tAmount is almost def in the R space, which is MAXED UINT. So we have to convert to tSpace
            uint256 transferWeight = tAmount.mul(uint256(100)).div(aTotal);
            // Recipient of Sales Address should NEVER have an avgPurchaseDate > 0 as this would mean a purchase tax
            if (_isSaleAddress[recipient] || _isExcluded[recipient]){
                _avgPurchaseDate[recipient] = 0;
                return;
            }
            // Weighted Average Math. Gotta be the ugliest I've seen in a while
            _avgPurchaseDate[recipient] = _avgPurchaseDate[recipient].mul(uint256(100).sub(transferWeight)).div(uint256(100)).add(
                senderPurchaseDate.mul(transferWeight).div(uint256(100)));

        }   

        function _takeFeeByAddress(uint256 tFee, address a) private {
            _tOwned[a] = _tOwned[a].add(tFee);

        }

        function _takeBurn(address sender, uint256 tburn) private {
            _takeFeeByAddress(tburn, address(0));
            if (tburn > 0)emit Transfer(sender, address(0), tburn);
        }

        function _takeMarketing(uint256 tMarketing) private {
            _takeFeeByAddress(tMarketing, _marketingWallet);
        }

        function _takeCharity(uint256 tCharity) private {
            _takeFeeByAddress(tCharity, address(_charityAddress));
        }

        function _reflectFee(uint256 tFee) private {
            _takeFeeByAddress(tFee, address(this));
            _tFeeTotal = _tFeeTotal.add(tFee);
        }

         //to recieve ETH from uniswapV2Router when swaping
        receive() external payable {}

        function _calculateUserFee(address sender) private view returns (uint256){
            uint256 baseFee = _taxFee;
            uint256 holderLength = block.timestamp - _avgPurchaseDate[sender];
            // seconds in a day 86400
            uint256 timeCompletedPercent = holderLength.mul(100).div(_daysForFeeReduction.mul(86400));
            if (timeCompletedPercent < 100){
                baseFee = uint256(100).sub(timeCompletedPercent);
                // If we set taxFee above 0 then it needs to be a minimum tax. This will almost never get used
                if (_taxFee > baseFee) return _taxFee;
            }
            return baseFee;
        }
       
        function _getETHBalance() public view returns(uint256 balance) {
            return address(this).balance;
        }
        
        function _setTaxFee(uint256 taxFee) external onlyOwner() {
            require(taxFee >= 0 && taxFee <= 100, 'taxFee should be in 0 - 100');
            _taxFee = taxFee;
        }

        // Returns 
        // if reactorFee False: Day 0 taxFee, Charity Fee, Burn Fee, Marketing Fee, Staking Fee
        // if reactorFee True: baseFeeReduction, charityPercent, burnPercent, marketingPercent, stakePercent
        function getFeePercents(bool reactorFee) public view returns (uint256, uint256, uint256, uint256, uint256){
            if (reactorFee) return (_reactorValues.baseFeeReduction, _reactorValues.charityPercent, _reactorValues.burnPercent, _reactorValues.marketingPercent, _reactorValues.stakePercent);
            return (_taxFee,_charityFeePercent, _burnFeePercent, _marketingFeePercent, _stakingPercent);
        }

        function _setFeePercents(uint256 charityFee, uint256 burnFee, uint256 marketingFee, uint256 stakeFee) external onlyOwner() {
             require(charityFee.add(burnFee).add(marketingFee).add(stakeFee) == 100, 'Fee percents must equal 100%');
             _charityFeePercent = charityFee;
             _burnFeePercent = burnFee;
             _marketingFeePercent = marketingFee;
             _stakingPercent = stakeFee;
        }

        function _setReactorFeePercents(uint256 feeReduction, uint256 charityFee, uint256 burnFee, uint256 marketingFee, uint256 stakeFee) external onlyOwner() {
             require(feeReduction < 100, 'Fee reduction must be less than 100%');
             require(charityFee.add(burnFee).add(marketingFee).add(stakeFee) == 100, 'Fee percents must equal 100%');
             _reactorValues.baseFeeReduction = feeReduction;
             _reactorValues.charityPercent = charityFee;
             _reactorValues.burnPercent = burnFee;
             _reactorValues.marketingPercent = marketingFee;
             _reactorValues.stakePercent = stakeFee;
        }

        function _setDaysForFeeReduction(uint256 daysForFeeReduction) external onlyOwner() {
            require(daysForFeeReduction >= 1, 'daysForFeeReduction needs to be at or above 1');
            _daysForFeeReduction = daysForFeeReduction;
        }

        function getMinSalesTaxRequiredToFeedReactor() public view returns (uint256) {
            return _minSalesTaxRequiredToFeedReactor;
        } 

        function _setMinSalesTaxRequiredToFeedReactor(uint256 salesPercent) external onlyOwner() {
            require(salesPercent >= 0 && salesPercent <= 100, 'minSalesTaxRequiredToFeedReactor must be between 0-100');
            _minSalesTaxRequiredToFeedReactor = salesPercent;
        }

        function _setMinDaysForReStake(uint256 minDaysForReStake) external onlyOwner() {
            require(minDaysForReStake >= 1, 'minDaysForReStake needs to be at or above 1');
            _minDaysForReStake = minDaysForReStake;
        }

        function _setMaxPercentOfStakeRewards(uint256 maxPercentOfStakeRewards) external onlyOwner() {
            require(maxPercentOfStakeRewards >= 1, 'minDaysForReStake needs to be at or above 1');
            _maxPercentOfStakeRewards = maxPercentOfStakeRewards;
        }

        
        function _setCharityWallet(address payable charityWalletAddress) external onlyOwner() {
            _charityAddress = charityWalletAddress;
        }

        function _setMarketingWallet(address payable marketingWalletAddress) external onlyOwner() {
            _marketingWallet = marketingWalletAddress;
        }
        
        function _setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
            require(maxTxAmount <= _tTotal , 'maxTxAmount should be less than total supply');
            _maxTxAmount = maxTxAmount;
        }
    }

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
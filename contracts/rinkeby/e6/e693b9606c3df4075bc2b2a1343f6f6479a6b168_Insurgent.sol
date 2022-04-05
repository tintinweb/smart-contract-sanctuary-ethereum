/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT

/**

Insurgent
noun
a rebel or revolutionary

Introducing a completely new mechanic that will revolutionize the way tokens are traded forever. 

Instead of making your token buys on a DEX, simply send your ETH to the contract address and 
the smart contract will automatically send you the appropriate amount of tokens using much more accurate 
prices then those seen on decentralized exchanges. No more getting reverted, having to struggle with slippage
and connecting your wallet to websites which risks vulnerabilities. A new era of ERC20 tokens. 

Join our telegram for additional information: https://t.me/insurgenteth

*/

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface ILPPair is IERC20 {
    function sync() external;
}

interface IDexRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

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

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////
//eADA Contract ///////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////
contract Insurgent is IERC20, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) customTransferTaxes;

    mapping(address => bool) private _excluded;
    mapping(address => bool) private _excludedFromStaking;

    mapping(address => bool) private _automatedMarketMakers;

    //Token Info
    string private constant _name = "Insurgent";
    string private constant _symbol = "INSURGENT";
    uint8 private constant _decimals = 18;
    uint256 public constant InitialSupply = 100 * 10**6 * 10**_decimals; //equals 100,000,000 token

    //The time Liquidity gets locked at start and prolonged once it gets released
    uint256 private constant DefaultLiquidityLockTime = 0 days;

    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint256 private _circulatingSupply;

    //Limits max tax, only gets applied for tax changes, doesn't affect inital Tax
    uint256 public constant MaxTax = 250;
    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    //Taxes can never exceed MaxTax
    uint256 private _buyTax = 130;
    uint256 private _sellTax = 130;
    uint256 private _transferTax = 0;
    //The shares of the specific Taxes, always needs to equal 100%
    uint256 private _stakingTax = 300;
    uint256 private _burnTax = 100;
    uint256 private _marketingTax = 600;
    uint256 private constant TaxDenominator = 1000;
    //determines the permille of the DEX pair needed to trigger Liquify
    uint8 public SwapTreshold = 10;
    uint256 public TargetLP = 100; //10% targetLP

    //_dexPair is also equal to the liquidity token address
    //LP token are locked in the contract
    ILPPair private _dexPair;
    IDexRouter private _router;
    //TestNet
    address private constant DexRouter =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    //MainNet
    //address private constant DexRouter =
    //    0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public MarketingWallet;
    //modifier for functions only the team can call
    modifier onlyTeam() {
        require(_isTeam(msg.sender), "Caller not in Team");
        _;
    }
    bool _isInFunction;
    modifier isInFunction() {
        require(!_isInFunction);
        _isInFunction = true;
        _;
        _isInFunction = false;
    }

    function _isTeam(address addr) private view returns (bool) {
        return addr == owner() || addr == MarketingWallet;
    }

    constructor() {
        //Creates a DEX Pair
        _router = IDexRouter(DexRouter);
        address LPPair = IDEXFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
        _dexPair = ILPPair(LPPair);
        _automatedMarketMakers[LPPair] = true;
        //excludes DEX Pair and contract from staking
        _excludedFromStaking[LPPair] = true;
        _excludedFromStaking[address(this)] = true;
        //deployer gets 95% of the supply to create LP
        _addToken(msg.sender, InitialSupply*95/100);
        emit Transfer(address(0), msg.sender, InitialSupply*95/100);
        _addToken(address(this),InitialSupply*5/100);
        emit Transfer(address(0), address(this), InitialSupply*5/100);


        //Team wallet deployer and contract are excluded from Taxes
        //contract can't be included to taxes
        MarketingWallet = msg.sender;
        _excluded[MarketingWallet] = true;
        _excluded[msg.sender] = true;
        _excluded[address(this)] = true;
        _approve(address(this), address(_router), type(uint256).max);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Transfer functionality////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //picks the transfer function
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "from zero");
        require(recipient != address(0), "to zero");

        //excluded adresses are transfering tax and lock free
        if (_excluded[sender] || _excluded[recipient]) {
            _feelessTransfer(sender, recipient, amount);
            return;
        }
        //once trading is enabled, it can't be turned off again
        require(tradingEnabled, "trading not yet enabled");
        _regularTransfer(sender, recipient, amount);
        //AutoPayout
    }

    //applies taxes, checks for limits, locks generates autoLP and stakingETH, and autostakes
    function _regularTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(_balances[sender] >= amount, "exceeds balance");
        //checks all registered AMM if it's a buy or sell.
        bool isBuy = _automatedMarketMakers[sender];
        bool isSell = _automatedMarketMakers[recipient];
        uint256 tax;
        if (isSell) tax = _sellTax;
        else if (isBuy) tax = _buyTax;
        else {
            tax = customTransferTaxes[recipient] > customTransferTaxes[sender]
                ? customTransferTaxes[recipient]
                : customTransferTaxes[sender];
            tax = tax == 0 ? _transferTax : tax;
            _smartLP(getSmartLPAdjustment());
        }

        //Swapping MarketingETH and stakingETH is only possible if sender is not DEX pair,
        //if its not manually disabled, if its not already swapping
        if (
            (sender != address(_dexPair)) &&
            (!swapAndLiquifyDisabled) &&
            (!_isSwappingContractModifier)
        ) {
            _swapContractToken();
        }

        _transferTaxed(sender, recipient, amount, tax);
    }

    function _transferTaxed(
        address sender,
        address recipient,
        uint256 amount,
        uint256 tax
    ) private {
        uint256 totalTaxedToken = _calculateFee(amount, tax, TaxDenominator);
        uint256 burnedToken = _calculateFee(amount, tax, _burnTax);

        uint256 taxedAmount = amount - totalTaxedToken;
        //Removes token and handles staking
        _removeToken(sender, amount);
        uint256 contractToken = totalTaxedToken - burnedToken;
        //Adds the taxed tokens -burnedToken to the contract
        _addToken(address(this), contractToken);
        //Burns token

        //Adds token and handles staking
        _addToken(recipient, taxedAmount);
        emit Transfer(sender, recipient, taxedAmount);
        if (!autoPayoutDisabled) _autoPayout();
    }

    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(_balances[sender] >= amount, ">balance");
        //Removes token and handles staking
        _removeToken(sender, amount);
        //Adds token and handles staking
        _addToken(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    //Calculates the token that should be taxed
    function _calculateFee(
        uint256 amount,
        uint256 tax,
        uint256 taxPercent
    ) private pure returns (uint256) {
        return (amount * tax * taxPercent) / (TaxDenominator * TaxDenominator);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //ETH Autostake/////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Autostake uses the balances of each holder to redistribute auto generated ETH.
    //Each transaction _addToken and _removeToken gets called for the transaction amount
    EnumerableSet.AddressSet private _autoPayoutList;

    function isAutoPayout(address account) public view returns (bool) {
        return _autoPayoutList.contains(account);
    }

    uint256 AutoPayoutCount = 15;
    uint256 MinPayout = 10**18; //1 ADA
    uint256 currentPayoutIndex;

    bool public autoPayoutDisabled;

    event OnDisableAutoPayout(bool disabled);

    function TeamDisableAutoPayout(bool disabled) public onlyTeam {
        autoPayoutDisabled = disabled;
        emit OnDisableAutoPayout(disabled);
    }

    event OnChangeAutoPayoutCount(uint256 count);

    function TeamChangeAutoPayoutCount(uint256 count) public onlyTeam {
        require(count <= 50);
        AutoPayoutCount = count;
        emit OnChangeAutoPayoutCount(count);
    }

    event OnChangeMinPayout(uint256 treshold);

    function TeamChangeMinPayout(uint256 minPayout) public onlyTeam {
        MinPayout = minPayout;
        emit OnChangeAutoPayoutCount(minPayout);
    }

    function TeamSetAutoPayoutAccount(address account, bool enable)
        public
        onlyTeam
    {
        if (enable) _autoPayoutList.add(account);
        else _autoPayoutList.remove(account);
    }

    function _autoPayout() private {
        //resets payout counter and moves to next payout token if last holder is reached
        if (currentPayoutIndex >= _autoPayoutList.length())
            currentPayoutIndex = 0;
        for (uint256 i = 0; i < AutoPayoutCount; i++) {
            address current = _autoPayoutList.at(currentPayoutIndex);
            currentPayoutIndex++;
            if (getDividents(current) >= MinPayout) {
                _claimETH(current);
                i += 3; //if payout happens, increase the counter faster
            }
            if (currentPayoutIndex >= _autoPayoutList.length()) {
                currentPayoutIndex = 0;
                return;
            }
        }
    }

    //Multiplier to add some accuracy to profitPerShare
    uint256 private constant DistributionMultiplier = 2**64;
    //profit for each share a holder holds, a share equals a decimal.
    uint256 public profitPerShare;
    //totalShares in circulation +InitialSupply to avoid underflow
    //getTotalShares returns the correct amount
    uint256 private _totalShares = InitialSupply;
    //the total reward distributed through staking, for tracking purposes
    uint256 public totalStakingReward;
    //the total payout through staking, for tracking purposes
    uint256 public totalPayouts;
    //Mapping of the already paid out(or missed) shares of each staker
    mapping(address => uint256) private alreadyPaidShares;
    //Mapping of shares that are reserved for payout
    mapping(address => uint256) private toBePaid;
    mapping(address => uint256) public totalPayout;

    //adds Token to balances, adds new ETH to the toBePaid mapping and resets staking
    function _addToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount = _balances[addr] + amount;
        _circulatingSupply += amount;
        //if excluded, don't change staking amount
        if (_excludedFromStaking[addr]) {
            _balances[addr] = newAmount;
            return;
        }
        _totalShares += amount;
        //gets the payout before the change
        uint256 payment = _newDividentsOf(addr);
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * newAmount;
        //adds dividents to the toBePaid mapping
        toBePaid[addr] += payment;
        //sets newBalance
        _balances[addr] = newAmount;
        _autoPayoutList.add(addr);
    }

    //removes Token, adds ETH to the toBePaid mapping and resets staking
    function _removeToken(address addr, uint256 amount) private {
        //the amount of token after transfer
        uint256 newAmount = _balances[addr] - amount;
        _circulatingSupply -= amount;
        if (_excludedFromStaking[addr]) {
            _balances[addr] = newAmount;
            return;
        }

        //gets the payout before the change
        uint256 payment = _newDividentsOf(addr);
        //sets newBalance
        _balances[addr] = newAmount;
        //resets dividents to 0 for newAmount
        alreadyPaidShares[addr] = profitPerShare * getShares(addr);
        //adds dividents to the toBePaid mapping
        toBePaid[addr] += payment;
        _totalShares -= amount;
        if (newAmount == 0) _autoPayoutList.remove(addr);
    }

    //gets the dividents of a staker that aren't in the toBePaid mapping
    function _newDividentsOf(address staker) private view returns (uint256) {
        uint256 fullPayout = profitPerShare * getShares(staker);
        //if excluded from staking or some error return 0
        if (fullPayout <= alreadyPaidShares[staker]) return 0;
        return
            (fullPayout - alreadyPaidShares[staker]) / DistributionMultiplier;
    }

    //distributes ETH between marketing share and dividents
    function _distributeStake(uint256 AmountWei) private {
        // Deduct marketing Tax
        if (AmountWei == 0) return;

        uint256 totalShares = getTotalShares();
        //when there are 0 shares, add everything to marketing budget
        if (totalShares == 0) {
            (bool sent, ) = MarketingWallet.call{value: AmountWei}("");
            sent = true;
        } else {
            totalStakingReward += AmountWei;
            //Increases profit per share based on current total shares
            profitPerShare += ((AmountWei * DistributionMultiplier) /
                totalShares);
        }
    }

    function AddFunds() public payable isInFunction {
        _distributeStake(msg.value);
    }

    function AddFundsTo(address Account) public payable isInFunction {
        toBePaid[Account] += msg.value;
        totalStakingReward += msg.value;
    }

    //Sets dividents to 0 returns dividents
    function _substractDividents(address addr) private returns (uint256) {
        uint256 amount = getDividents(addr);
        if (amount == 0) return 0;
        if (!_excludedFromStaking[addr]) {
            alreadyPaidShares[addr] = profitPerShare * getShares(addr);
        }
        toBePaid[addr] = 0;
        totalPayout[addr] += amount;
        return amount;
    }

    //Manually claimRewards
    function ClaimRewards() public isInFunction {
        _claimETH(msg.sender);
    }

    function _claimETH(address account) private {
        uint256 amount = _substractDividents(account);
        if (amount == 0) return;
        //Substracts the amount from the dividents
        totalPayouts += amount;
        (bool sent, ) = account.call{value: amount, gas: 30000}("");
        if (!sent) {
            //if payout fails, revert payment
            toBePaid[account] += amount;
            totalPayouts -= amount;
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Swap Contract Tokens//////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //tracks auto generated ETH, useful for ticker etc
    uint256 public totalLPETH;
    //Locks the swap if already swapping
    bool private _isSwappingContractModifier;
    modifier lockTheSwap() {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    function _swapContractToken() private lockTheSwap {
        uint256 tokenToSwap = (_balances[address(_dexPair)] * SwapTreshold) /
            TaxDenominator;
        uint256 tokenBalance = _balances[address(this)];
        if (tokenBalance < tokenToSwap) return;

        uint256 initialETHBalance = address(this).balance;
        _swapToken(tokenToSwap,address(this));
        uint256 newETH = (address(this).balance - initialETHBalance);
        uint256 marketingETH = (newETH * _marketingTax) /
            (_marketingTax + _stakingTax);
        uint256 stakingETH = newETH - marketingETH;
        //distributes ETH between stakers
        _distributeStake(stakingETH);
        //send marketingETH to the marketing wallet
        (bool sent, ) = MarketingWallet.call{value: marketingETH}("");
        sent = true;
    }

    //swaps tokens on the contract for ETH
    function _swapToken(uint256 amount,address recipient) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            recipient,
            block.timestamp
        );
    }

    function _swapETH() private {
        address[] memory path = new address[](2);
        path[1] = address(this);
        path[0] = _router.WETH();

        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, msg.sender, block.timestamp);
    }

    function getSmartLPAdjustment() public view returns (int256 adjustment) {
        int256 TargetLPAmount = int256(
            (_circulatingSupply * TargetLP) / TaxDenominator
        );
        int256 CurrentLPAmount = int256(_balances[address(_dexPair)]);
        adjustment = TargetLPAmount - CurrentLPAmount;
    }

    function _smartLP(int256 DifferenceFromTarget) private {
        uint256 amountMax = _balances[address(_dexPair)] *(_buyTax+_sellTax)/(TaxDenominator*4);
        if (DifferenceFromTarget < 0) {
            //Too much LP
            uint256 adjustment = uint256(DifferenceFromTarget *= -1);
            if (adjustment > amountMax) adjustment = amountMax;
            _removeToken(address(_dexPair), adjustment);
        } else {
            uint256 adjustment = uint256(DifferenceFromTarget);
            if (adjustment > amountMax) adjustment = amountMax;
            _addToken(address(_dexPair), adjustment);
        }
        _dexPair.sync();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //public functions /////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //gets shares of an address, returns 0 if excluded
    function getShares(address addr) public view returns (uint256) {
        if (_excludedFromStaking[addr]) return 0;
        return _balances[addr];
    }

    //Total shares equals circulating supply minus excluded Balances
    function getTotalShares() public view returns (uint256) {
        return _totalShares - InitialSupply;
    }

    function getLiquidityLockSeconds()
        public
        view
        returns (uint256 LockedSeconds)
    {
        if (block.timestamp < _liquidityUnlockTime)
            return _liquidityUnlockTime - block.timestamp;
        return 0;
    }

    function getTaxes()
        public
        view
        returns (
            uint256 buyTax,
            uint256 sellTax,
            uint256 transferTax,
            uint256 stakingTax,
            uint256 marketingTax,
            uint256 burnTax
        )
    {
        buyTax = _buyTax;
        sellTax = _sellTax;
        transferTax = _transferTax;
        stakingTax = _stakingTax;
        marketingTax = _marketingTax;
        burnTax = _burnTax;
    }

    function getStatus(address account)
        public
        view
        returns (bool Excluded, bool ExcludedFromStaking)
    {
        return (_excluded[account], _excludedFromStaking[account]);
    }

    //Returns the not paid out dividents of an address in wei
    function getDividents(address addr) public view returns (uint256) {
        return _newDividentsOf(addr) + toBePaid[addr];
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    bool public swapAndLiquifyDisabled;
    event OnAddAMM(address AMM, bool Add);

    function TeamAddOrRemoveAMM(address AMMPairAddress, bool Add)
        public
        onlyTeam
    {
        require(AMMPairAddress != address(_dexPair), "can't change Main DEX");
        if (Add) {
            if (!_excludedFromStaking[AMMPairAddress])
                TeamSetStakingExcluded(AMMPairAddress, true);
            _automatedMarketMakers[AMMPairAddress] = true;
        } else {
            _automatedMarketMakers[AMMPairAddress] = false;
        }
        emit OnAddAMM(AMMPairAddress, Add);
    }

    function SetCustomTransferTaxes(uint256 taxes, address account)
        public
        onlyTeam
    {
        require(taxes < MaxTax);
        customTransferTaxes[account] = taxes;
    }

    function TeamChangeTeamWallet(address newTeamWallet) public {
        require(msg.sender == MarketingWallet);
        MarketingWallet = newTeamWallet;
    }

    event OnChangeLiquifyTreshold(uint8 treshold);

    function TeamSetSwapTreshold(uint8 treshold) external onlyTeam {
        require(treshold <= 50);
        require(treshold > 0);
        SwapTreshold = treshold;
        emit OnChangeLiquifyTreshold(treshold);
    }

    event OnChangeLiquidityTarget(uint256 target);

    function TeamSetLiquidityTarget(uint256 target) external onlyTeam {
        require(TargetLP <= TaxDenominator / 2); //max 50% LP
        TargetLP = target;
        emit OnChangeLiquidityTarget(target);
    }

    event OnSwitchSwapAndLiquify(bool Disabled);

    //switches autoLiquidity and marketing ETH generation during transfers
    function TeamSwitchSwapAndLiquify(bool disabled) public onlyTeam {
        swapAndLiquifyDisabled = disabled;
        emit OnSwitchSwapAndLiquify(disabled);
    }

    event OnChangeTaxes(
        uint256 stakingTaxes,
        uint256 buyTaxes,
        uint256 marketingTaxes,
        uint256 burn,
        uint256 sellTaxes,
        uint256 transferTaxes
    );

    //Sets Taxes, is limited by MaxTax(25%) to make it impossible to create honeypot
    function TeamSetTaxes(
        uint256 stakingTaxes,
        uint256 marketingTax,
        uint256 burnTax,
        uint256 buyTax,
        uint256 sellTax,
        uint256 transferTax
    ) public onlyTeam {
        uint256 totalTax = stakingTaxes + marketingTax + burnTax;
        require(totalTax == TaxDenominator);
        require(buyTax <= MaxTax && sellTax <= MaxTax && transferTax <= MaxTax);

        _marketingTax = marketingTax;
        _burnTax = burnTax;
        _stakingTax = stakingTaxes;

        _buyTax = buyTax;
        _sellTax = sellTax;
        _transferTax = transferTax;
        emit OnChangeTaxes(
            stakingTaxes,
            marketingTax,
            burnTax,
            buyTax,
            sellTax,
            transferTax
        );
    }

    //manually converts contract token to LP and staking ETH
    function TeamTriggerLiquify() public onlyTeam {
        _swapContractToken();
    }

    event OnExcludeFromStaking(address addr, bool exclude);

    //Excludes account from Staking
    function TeamSetStakingExcluded(address addr, bool exclude)
        public
        onlyTeam
    {
        uint256 shares;
        if (exclude) {
            require(!_excludedFromStaking[addr]);
            uint256 newDividents = _newDividentsOf(addr);
            shares = getShares(addr);
            _excludedFromStaking[addr] = true;
            _totalShares -= shares;
            alreadyPaidShares[addr] = shares * profitPerShare;
            toBePaid[addr] += newDividents;
            _autoPayoutList.remove(addr);
        } else _includeToStaking(addr);
        emit OnExcludeFromStaking(addr, exclude);
    }

    //function to Include own account to staking, should it be excluded
    function IncludeMeToStaking() public {
        _includeToStaking(msg.sender);
    }

    function _includeToStaking(address addr) private {
        require(_excludedFromStaking[addr]);
        _excludedFromStaking[addr] = false;
        uint256 shares = getShares(addr);
        _totalShares += shares;
        //sets alreadyPaidShares to the current amount
        alreadyPaidShares[addr] = shares * profitPerShare;
        _autoPayoutList.add(addr);
    }

    event OnExclude(address addr, bool exclude);

    //Exclude/Include account from fees and locks (eg. CEX)
    function TeamSetExcludedStatus(address account, bool excluded)
        public
        onlyTeam
    {
        require(account != address(this), "can't Include the contract");
        _excluded[account] = excluded;
        emit OnExclude(account, excluded);
    }

    event ContractBurn(uint256 amount);

    //Burns token on the contract, like when there is a very large backlog of token
    //or for scheudled BurnEvents
    function TeamBurnContractToken(uint8 percent) public onlyTeam {
        require(percent <= 100);
        uint256 burnAmount = (_balances[address(this)] * percent) / 100;
        _removeToken(address(this), burnAmount);
        emit Transfer(address(this), address(0), burnAmount);
        emit ContractBurn(burnAmount);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Setup Functions///////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //Creates LP using Payable Amount, LP automatically land on the contract where they get locked
    //once Trading gets enabled
    bool public tradingEnabled;
    event OnTradingOpen();

    //Enables trading. Turns on bot protection and Locks LP for default Lock time
    function SetupEnableTrading() public onlyTeam {
        require(!tradingEnabled);
        tradingEnabled = true;
        _liquidityUnlockTime = block.timestamp + DefaultLiquidityLockTime;
        emit OnTradingOpen();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Liquidity Lock////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //the timestamp when Liquidity unlocks
    uint256 private _liquidityUnlockTime;
    bool public liquidityRelease20Percent;
    event LimitReleaseTo20Percent();

    //Sets Liquidity Release to 20% at a time and prolongs liquidity Lock for a Week after Release.
    //Should be called once start was successful.
    function TeamlimitLiquidityReleaseTo20Percent() public onlyTeam {
        liquidityRelease20Percent = true;
        emit LimitReleaseTo20Percent();
    }

    //Prolongs the Liquidity Lock. Lock can't be reduced
    event ProlongLiquidityLock(uint256 secondsUntilUnlock);

    function TeamLockLiquidityForSeconds(uint256 secondsUntilUnlock)
        public
        onlyTeam
    {
        _prolongLiquidityLock(secondsUntilUnlock + block.timestamp);
        emit ProlongLiquidityLock(secondsUntilUnlock);
    }

    function _prolongLiquidityLock(uint256 newUnlockTime) private {
        // require new unlock time to be longer than old one
        require(newUnlockTime > _liquidityUnlockTime);
        _liquidityUnlockTime = newUnlockTime;
    }

    event OnRemoveRemainingETH();

    function TeamRemoveRemainingETH() public onlyTeam {
        require(block.timestamp >= _liquidityUnlockTime + 30 days, "Locked");
        _liquidityUnlockTime = block.timestamp + DefaultLiquidityLockTime;
        (bool sent, ) = MarketingWallet.call{value: address(this).balance}("");
        sent = true;
        emit OnRemoveRemainingETH();
    }

    event OnReleaseLP();

    //Release Liquidity Tokens once unlock time is over
    function LiquidityRelease() public onlyTeam {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");

        IERC20 liquidityToken = IERC20(_dexPair);
        uint256 amount = liquidityToken.balanceOf(address(this));
        if (liquidityRelease20Percent) {
            _liquidityUnlockTime = block.timestamp + DefaultLiquidityLockTime;
            //regular liquidity release, only releases 20% at a time and locks liquidity for another week
            amount = (amount * 2) / 10;
        }
        liquidityToken.transfer(msg.sender, amount);
        emit OnReleaseLP();
    }

    //Allows the team to withdraw token that get's accidentally sent to the contract(happens way too often)
    //Can't withdraw the LP token, this token or the promotion token
    function TeamWithdrawStrandedToken(address strandedToken) public onlyTeam {
        require(
            (strandedToken != address(_dexPair)) &&
                strandedToken != address(this)
        );
        IERC20 token = IERC20(strandedToken);
        token.transfer(MarketingWallet, token.balanceOf(address(this)));
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    receive() external payable {
        //if dex router sends, return
        if (msg.sender == address(DexRouter)) return;
        //if other account sends, buy
        int256 adjustment = getSmartLPAdjustment();
        if (adjustment > 0) {
            //If the adjustment increases the LP do it before swap, to favour swapper
            _smartLP(adjustment);
            _swapETH();
        } else {
            _swapETH();
            _smartLP(getSmartLPAdjustment());
        }
    }

    // IERC20

    function getOwner() external view override returns (address) {
        return owner();
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        _smartLP(getSmartLPAdjustment());
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount);

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // IERC20 - Helpers
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue);

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
}
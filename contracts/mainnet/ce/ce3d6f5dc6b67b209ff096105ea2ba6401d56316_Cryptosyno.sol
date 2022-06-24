/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

/******************************************************************************************************************************

CryptoSyno is the go-to source for DeFi cryptocurrency gambling.

Website: 
- https://cryptosyno.io/

Social Media Links:
- https://discord.gg/CryptoSyno
- https://twitter.com/CryptoSyno_CSYN

For questions/concerns/inquiries, feel free to pop into the discord or email us at: [email protected]

Buy
- 0% Sent to burn address

Sell
- 1% Reflections
- 2% Sent to burn address
- 2% Sent to CryptoSyno reward pool

Slot Machine Odds
- House odds 0.1% - 10% of the prize pool is sent to the dead address.
- Big win odds 0.1% - Win 10% of the prize pool.
- Standard win odds 8% - Win 1% of the prize pool.
- After 3 losses in a row, user is granted a 2x  odds increase. 
- Users will keep getting extra odds increase for every lose if their lose streak is 3+. 
- After winning any reward, probabilities will reset to normal.

Add your Own Token
- User submits token.
- Must be 18 decimals.
- Must select spin cost.
- Listing fee 777 CryptoSyno (Sent to dead address)

VIP STATUS
- x1000 $CSYN tokens sent to the dead address.
- Grants personalized remote concierge service.

******************************************************************************************************************************/

pragma solidity ^0.8.6;

pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

// BEP20 token standard interface
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `_account`.
     */
    function balanceOf(address _account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's _account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one _account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Dex Factory contract interface
interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Dex Router02 contract interface
interface IDexRouter {
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

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the _account sending and
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an _account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner _account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any _account other than the owner.
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new _account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    /**
     * @dev set the owner for the first time.
     * Can only be called by the contract or deployer.
     */
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// Main token Contract

contract Cryptosyno is Context, IBEP20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // all private variables and functions are only for contract use
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;
    mapping(address => bool) private _isExcludedFrommaxTransferLimit;
    mapping(address => bool) private _isEXcludedFrommaxWallet;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant percentDivider = 1_000;
    uint256 private _tTotal = 7_777_777 ether; // 7.77 million total supply
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "CryptoSyno"; // token name
    string private _symbol = "CSYN"; // token ticker
    uint8 private _decimals = 18; // token decimals

    IDexRouter public dexRouter; // Dex router address
    address public dexPair; // LP token address
    address public slotMachine; // Slot Machine wallet address
    address public burnAddress = 0x000000000000000000000000000000000000dEaD; // dead address

    uint256 public maxTransferingAmount = _tTotal.div(100); // maximum sending limit is 1% percent of total supply
    uint256 public maxWalletAmount = _tTotal.div(100); // maximum wallet limit is 1% percent of total supply
    uint256 public maxFee = 100; // 10% max fees limit per transaction
    uint256 private excludedTSupply; // for contract use
    uint256 private excludedRSupply; // for contract use

    bool public reflectionFees = true; // should be false to charge fee
    bool public tradingOpen; //once switched on, can never be switched off.
    bool public ismaxTransferLimitValid = true; // max sending Limit is valid if it's true
    bool public ismaxWalletValid = true; // max wallet limit is valid if it's true

    // buy tax fee
    uint256 public redistributionFeeOnBuying = 0; // 0% will be distributed among holder as token divideneds
    uint256 public slotMachineFeeOnBuying = 0; // 0% will go to the Slot Machine address
    uint256 public burnFeeOnBuying = 10; // 1% will go to the burn address

    // sell tax fee
    uint256 public redistributionFeeOnSelling = 10; // 1% will be distributed among holder as token divideneds
    uint256 public slotMachineFeeOnSelling = 20; // 2% will go to the Slot Machine address
    uint256 public burnFeeOnSelling = 20; // 2% will go to the burn address

    // normal tax fee
    uint256 public redistributionFee = 0; // 0% will be distributed among holder as token divideneds
    uint256 public slotMachineFee = 0; // 0% will go to the Slot Machine address
    uint256 public burnFee = 0; // 0% will go to the burn address

    // for smart contract use
    uint256 private _currentRedistributionFee;
    uint256 private _currentslotMachineFee;
    uint256 private _currentburnFee;

    uint256 private _accumulatedslotMachine;
    uint256 private _accumulatedburn;

    // constructor for initializing the contract
    constructor() {
        _rOwned[owner()] = _rTotal;
        //mainnet
        IDexRouter _dexRouter = IDexRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Create a Dex pair for this new token
        dexPair = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        // set the rest of the contract variables
        dexRouter = _dexRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude addresses from max tx
        _isExcludedFrommaxTransferLimit[owner()] = true;
        _isExcludedFrommaxTransferLimit[address(this)] = true;
        _isExcludedFrommaxTransferLimit[dexPair] = true;
        _isExcludedFrommaxTransferLimit[burnAddress] = true;
        //exclude addresses from max wallet
        _isEXcludedFrommaxWallet[owner()] = true;
        _isEXcludedFrommaxWallet[address(this)] = true;
        _isEXcludedFrommaxWallet[dexPair] = true;
        _isEXcludedFrommaxWallet[burnAddress] = true;

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
        if (_isExcludedFromReward[_account]) return _tOwned[_account];
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
                "BEP20: transfer amount exceeds allowance"
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
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    // public view able functions

    // to check wether the address is excluded from reward or not
    function isExcludedFromReward(address _account) public view returns (bool) {
        return _isExcludedFromReward[_account];
    }

    // to check wether the address is excluded from fee or not
    function isExcludedFromFee(address _account) public view returns (bool) {
        return _isExcludedFromFee[_account];
    }

    // to check wether the address is excluded from max sending or not
    function isExcludedFrommaxTransferLimit(address _account)
        public
        view
        returns (bool)
    {
        return _isExcludedFrommaxTransferLimit[_account];
    }

    function isExcludedFrommaxWallet(address _account)
        public
        view
        returns (bool)
    {
        return _isEXcludedFrommaxWallet[_account];
    }

    // to check how much tokens get redistributed among holders till now
    function totalHolderDistribution() public view returns (uint256) {
        return _tFeeTotal;
    }

    // For manual distribution to the holders
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcludedFromReward[sender],
            "BEP20: Excluded addresses cannot call this function"
        );
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "BEP20: Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 rAmount = tAmount.mul(_getRate());
            return rAmount;
        } else {
            uint256 rAmount = tAmount.mul(_getRate());
            uint256 rTransferAmount = rAmount.sub(
                totalFeePerTx(tAmount).mul(_getRate())
            );
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "BEP20: Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    // setter functions for owner

    // to include any address in reward
    function includeInReward(address _account) external onlyOwner {
        require(
            _isExcludedFromReward[_account],
            "BEP20: _Account is already excluded"
        );
        excludedTSupply = excludedTSupply.sub(_tOwned[_account]);
        excludedRSupply = excludedRSupply.sub(_rOwned[_account]);
        _rOwned[_account] = _tOwned[_account].mul(_getRate());
        _tOwned[_account] = 0;
        _isExcludedFromReward[_account] = false;
    }

    //to include any address in reward
    function excludeFromReward(address _account) public onlyOwner {
        require(
            !_isExcludedFromReward[_account],
            "BEP20: _Account is already excluded"
        );
        if (_rOwned[_account] > 0) {
            _tOwned[_account] = tokenFromReflection(_rOwned[_account]);
        }
        _isExcludedFromReward[_account] = true;
        excludedTSupply = excludedTSupply.add(_tOwned[_account]);
        excludedRSupply = excludedRSupply.add(_rOwned[_account]);
    }

    //to include or exludde  any address from fee
    function includeOrExcludeFromFee(address _account, bool _value)
        public
        onlyOwner
    {
        _isExcludedFromFee[_account] = _value;
    }

    //to include or exludde  any address from max send limit
    function includeOrExcludeFrommaxTransferLimit(address _address, bool value)
        public
        onlyOwner
    {
        _isExcludedFrommaxTransferLimit[_address] = value;
    }

    function includeOrExcludeFrommaxWallet(address _address, bool value)
        public
        onlyOwner
    {
        _isEXcludedFrommaxWallet[_address] = value;
    }

    //only owner can change maxTransferingAmount
    function setmaxTransferingAmount(uint256 _percentage) public onlyOwner {
        require(
            _percentage > 0 && _percentage <= 100,
            "BEP20: percentage must be less than 100"
        );
        maxTransferingAmount = _tTotal.mul(_percentage).div(percentDivider);
    }

    //only owner can change maxWalletAmount
    function setmaxWalletAmount(uint256 _percentage) public onlyOwner {
        require(
            _percentage > 0 && _percentage <= 100,
            "BEP20: percentage must be less than 100"
        );
        maxWalletAmount = _tTotal.mul(_percentage).div(percentDivider);
    }

    //only owner can change BuyFee on and off for everyone
    function BuyFee(bool _value) external onlyOwner {
        if (_value) {
            redistributionFeeOnBuying = 0;
            slotMachineFeeOnBuying = 0;
            burnFeeOnBuying = 10;
        } else {
            redistributionFeeOnBuying = 0;
            slotMachineFeeOnBuying = 0;
            burnFeeOnBuying = 0;
        }
    }

    //To enable or disable all fees when set it to true fees will be disabled
    function enableOrDisableFees(bool _state) external onlyOwner {
        reflectionFees = _state;
    }

    //by default maxTransfering is true to disable set it to false address can send more than limit
    function enableOrDisablemaxTransferLimit(bool _state) external onlyOwner {
        ismaxTransferLimitValid = _state;
    }

    function enableOrDisablemaxWallet(bool _state) external onlyOwner {
        ismaxWalletValid = _state;
    }

    // owner can change Slot Machine address
    function setslotMachineAddress(address payable _newAddress)
        external
        onlyOwner
    {
        slotMachine = _newAddress;
    }

    // owner can change router and pair address
    function setRoute(IDexRouter _router, address _pair) external onlyOwner {
        dexRouter = _router;
        dexPair = _pair;
    }

    // no one can buy or sell when trading is off except owner
    // but once switched on every one can buy / sell tokens
    // once switched on can never be switched off
    function startTrading() external onlyOwner {
        require(!tradingOpen, "BEP20: Already enabled");
        tradingOpen = true;
    }

    //to receive BNB from dexRouter when swapping
    receive() external payable {}

    // internal functions for contract use

    function totalFeePerTx(uint256 tAmount) internal view returns (uint256) {
        uint256 percentage = tAmount
            .mul(
                _currentRedistributionFee.add(_currentslotMachineFee).add(
                    _currentburnFee
                )
            )
            .div(percentDivider);
        return percentage;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        rSupply = rSupply.sub(excludedRSupply);
        tSupply = tSupply.sub(excludedTSupply);
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function removeAllFee() private {
        _currentRedistributionFee = 0;
        _currentslotMachineFee = 0;
        _currentburnFee = 0;
    }

    function setBuyFee() private {
        _currentRedistributionFee = redistributionFeeOnBuying;
        _currentslotMachineFee = slotMachineFeeOnBuying;
        _currentburnFee = burnFeeOnBuying;
    }

    function setSellFee() private {
        _currentRedistributionFee = redistributionFeeOnSelling;
        _currentslotMachineFee = slotMachineFeeOnSelling;
        _currentburnFee = burnFeeOnSelling;
    }

    function setNormalFee() private {
        _currentRedistributionFee = redistributionFee;
        _currentslotMachineFee = slotMachineFee;
        _currentburnFee = burnFee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // base function to transafer tokens
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "BEP20: transfer amount must be greater than zero");

        if (!tradingOpen && from != owner()) {
            require(to != dexPair, "BEP20: trading is not enabled yet");
        }

        if (!tradingOpen && to != owner()) {
            require(from != dexPair, "BEP20: trading is not enabled yet");
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any _account belongs to _isExcludedFromFee _account then remove the fee
        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            !reflectionFees
        ) {
            takeFee = false;
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
        if (!takeFee) {
            removeAllFee();
        }
        // buying handler
        else if (sender == dexPair) {
            setBuyFee();
        }
        // selling handler
        else if (recipient == dexPair) {
            setSellFee();
        }
        // normal transaction handler
        else {
            setNormalFee();
        }

        // check if sender or reciver excluded from reward then do transfer accordingly
        if (
            _isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]
        ) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (
            !_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]
        ) {
            _transferToExcluded(sender, recipient, amount);
        } else if (
            _isExcludedFromReward[sender] && _isExcludedFromReward[recipient]
        ) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _checkMaxTransferAmount(address to, uint256 amount) private view {
        if (
            !_isExcludedFrommaxTransferLimit[to] // by default false
        ) {
            if (ismaxTransferLimitValid) {
                require(
                    amount <= maxTransferingAmount,
                    "BEP20: amount exceed max sending limit"
                );
            }
        }
    }

    function _checkMaxWalletAmount(address to, uint256 amount) private view {
        if (
            !_isEXcludedFrommaxWallet[to] // by default false
        ) {
            if (ismaxWalletValid) {
                require(
                    amount + balanceOf(to) <= maxWalletAmount,
                    "BEP20: amount exceed max wallet limit"
                );
            }
        }
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
        _checkMaxTransferAmount(recipient, tTransferAmount);
        _checkMaxWalletAmount(recipient, tTransferAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeAllFee(tAmount, currentRate);
        _reflectFee(tAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // if receiver is excluded from reward
    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        uint256 rAmount = tAmount.mul(currentRate);
        _checkMaxTransferAmount(recipient, tTransferAmount);
        _checkMaxWalletAmount(recipient, tTransferAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        excludedTSupply = excludedTSupply.add(tAmount);
        _takeAllFee(tAmount, currentRate);
        _reflectFee(tAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    // if sender is excluded from reward
    function _transferFromExcluded(
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
        _checkMaxTransferAmount(recipient, tTransferAmount);
        _checkMaxWalletAmount(recipient, tTransferAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        excludedTSupply = excludedTSupply.sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeAllFee(tAmount, currentRate);
        _reflectFee(tAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    // if both sender and receiver are excluded from reward
    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        uint256 tTransferAmount = tAmount.sub(totalFeePerTx(tAmount));
        _checkMaxTransferAmount(recipient, tTransferAmount);
        _checkMaxWalletAmount(recipient, tTransferAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        excludedTSupply = excludedTSupply.sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        excludedTSupply = excludedTSupply.add(tAmount);
        _takeAllFee(tAmount, currentRate);
        _reflectFee(tAmount);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    // take fees for liquidity, Slot Machine and earth bank
    function _takeAllFee(uint256 tAmount, uint256 currentRate) internal {
        uint256 tFeeslot = tAmount.mul((_currentslotMachineFee)).div(
            percentDivider
        );
        uint256 tFeeburn = tAmount.mul((_currentburnFee)).div(percentDivider);

        if (tFeeslot > 0) {
            _accumulatedslotMachine = _accumulatedslotMachine.add(
                tAmount.mul(_currentslotMachineFee).div(percentDivider)
            );

            uint256 rFee = tFeeslot.mul(currentRate);
            if (_isExcludedFromReward[slotMachine])
                _tOwned[slotMachine] = _tOwned[slotMachine].add(tFeeslot);
            else _rOwned[slotMachine] = _rOwned[slotMachine].add(rFee);

            emit Transfer(_msgSender(), slotMachine, tFeeslot);
        }
        if (tFeeburn > 0) {
            _accumulatedburn = _accumulatedburn.add(
                tAmount.mul(_currentburnFee).div(percentDivider)
            );

            uint256 rFee = tFeeburn.mul(currentRate);
            if (_isExcludedFromReward[burnAddress])
                _tOwned[burnAddress] = _tOwned[burnAddress].add(tFeeburn);
            else _rOwned[burnAddress] = _rOwned[burnAddress].add(rFee);

            emit Transfer(_msgSender(), burnAddress, tFeeburn);
        }
    }

    // for automatic redistribution among all holders on each tx
    function _reflectFee(uint256 tAmount) private {
        uint256 tFee = tAmount.mul(_currentRedistributionFee).div(
            percentDivider
        );
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
}

// Library for doing a swap on Dex
library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IDexRouter dexRouter = IDexRouter(routerAddress);

        // generate the Dex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        IDexRouter dexRouter = IDexRouter(routerAddress);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 300
        );
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}
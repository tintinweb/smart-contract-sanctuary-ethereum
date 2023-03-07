// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IEthereal.sol";

/// @title Ethereal(2REAL) ERC-20 token contract.
/// @author 5thWeb
contract Ethereal is Ownable, IEthereal {
    mapping(address => mapping (address => uint256)) private _allowances;

    mapping(address => uint256) private _balances;

    /// @dev Addresses registered in whiletlist can transfer tokens before trading enabled.
    mapping(address => bool) public whitelists;

    /// @dev Addresses registered in blacklist can't any tx.
    mapping(address => bool) public blacklists;

    /// @dev Register all LP pairs.
    mapping(address => bool) public lpPairs;

    /// @dev Addresses registered in excludedLimit can have infinitive _amount.
    mapping(address => bool) public excludedLimits;

    uint256 private _totalSupply;

    /// @dev MAX WALLET is 2% of totalSupply
    uint256 public maxWallet;

    /// @dev MAX SELL is 1% of totalSupply
    uint256 public maxSell;

    /// @dev The timestamp that trading enabled
    uint256 public launchTimeStamp;

    /// @dev The address of treasury contract address.
    address public treasuryCA;
    address constant public DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;

    /// @dev decimal point to calculate percentage.
    uint16 constant public BASE_POINT = 1000;

    /// @dev MAX_TAX is 10%.
    uint16 public MAX_TAX = 100;

    /// @dev Fee for buy & sell.
    uint16 public swapTax;

    string constant private _name = "Ethereal";
    string constant private _symbol = "2REAL";
    uint8 constant private _decimals = 9;

    /// @dev The min percent for jeets. 1%
    /// @dev If lp balance is less than min, no jeets tax.
    uint8 private VminDiv = 10;

    /// @dev The max percent for jeets. 10%
    /// @dev If lp balance is greater than max, max jeets fee will applied.
    uint8 private VmaxDiv = 100;

    /// @dev The max fee for jeets tax. 15%
    uint8 private MaxJeetsFee = 150;

    /// @dev The percent rate of total supply for max amount that a user can own. 2%
    uint16 public maxWalletPercent = 20;

    /// @dev The percent rate of total supply for max amount that a user can sell. 1%
    uint16 public maxSellPerecent = 10;

    bool public JeetsFeeApply = true;
    bool public tradingEnabled = false;

    modifier onlyTreasury {
        require (msg.sender == treasuryCA, "only treasury");
        _;
    }

    constructor (
        uint256 totalSupply_,
        address _treasuryCA,
        uint16 _swapTax
    ) {
        require (totalSupply_ > 0, "invalid totalSupply _amount");
        require (_treasuryCA != address(0), "zero treasury contract address");
        require (_swapTax <= MAX_TAX, "exceeds to MAX FEE");
        _totalSupply = totalSupply_ * 10**_decimals;
        treasuryCA = _treasuryCA;
        swapTax = _swapTax;

        maxWallet = _totalSupply * maxWalletPercent / BASE_POINT;
        maxSell = _totalSupply * maxSellPerecent / BASE_POINT;

        _balances[_treasuryCA] = _totalSupply;

        whitelists[address(this)] = true;
        whitelists[_treasuryCA] = true;
        whitelists[DEAD_WALLET] = true;
        whitelists[msg.sender] = true;

        excludedLimits[address(this)] = true;
        excludedLimits[_treasuryCA] = true;
        excludedLimits[DEAD_WALLET] = true;
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function allowance(address _holder, address _spender) external view override returns (uint256) { return _allowances[_holder][_spender]; }
    function balanceOf(address _account) public view override returns (uint256) {
        return _balances[_account];
    }
    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }
    function transferFrom(address _sender, address _recipient, uint256 _amount) external override returns (bool) {
        if (_allowances[_sender][msg.sender] != type(uint256).max) {
            _allowances[_sender][msg.sender] -= _amount;
        }

        return _transfer(_sender, _recipient, _amount);
    }

    /// @inheritdoc IEthereal
    function setBlacklist(address[] memory _wallets, bool _isAdd) external onlyOwner {
        uint256 length = _wallets.length;
        require (length > 0, "zero wallets array");
        for (uint256 i = 0; i < length; i ++) {
            blacklists[_wallets[i]] = _isAdd;
        }
    }

    /// @inheritdoc IEthereal
    function setWhitelist(address[] memory _wallets, bool _isAdd) external onlyOwner {
        uint256 length = _wallets.length;
        require (length > 0, "zero wallets array");
        for (uint256 i = 0; i < length; i ++) {
            whitelists[_wallets[i]] = _isAdd;
        }
    }

    /// @inheritdoc IEthereal
    function setTradingStatus(bool _tradingStatus) external onlyOwner {
        tradingEnabled = _tradingStatus;
        launchTimeStamp = _tradingStatus ? block.timestamp : 0;
        emit TradingStatusSet(_tradingStatus);
    }

    /// @inheritdoc IEthereal
    function setLpPairs(address _lpPair) external onlyTreasury {
        lpPairs[_lpPair] = true;
        excludedLimits[_lpPair] = true;
        whitelists[_lpPair] = true;
        emit LpPairsSet(_lpPair);
    }

    /// @inheritdoc IEthereal
    function setTreasuryCA(address _treasuryCA) external onlyOwner {
        require (_treasuryCA != address(0), "zero treasury contract address");
        treasuryCA = _treasuryCA;
        emit TreasuryCASet(_treasuryCA);
    }

    /// @inheritdoc IEthereal
    function setMaxTax(uint16 _maxTax) external onlyOwner {
        MAX_TAX = _maxTax;
        emit MaxTaxSet(_maxTax);
    }

    /// @inheritdoc IEthereal
    function setSwapTax(uint16 _newSwapTax) external onlyOwner {
        require (_newSwapTax <= MAX_TAX, "exceeds max cap");
        swapTax = _newSwapTax;
        emit SwapTaxSet(_newSwapTax);
    }

    /// @inheritdoc IEthereal
    function setMaxWalletPercent(uint16 _newMaxWalletPercent) external onlyOwner {
        maxWalletPercent = _newMaxWalletPercent;
        emit MaxWalletPercentSet(_newMaxWalletPercent);
    }

    /// @inheritdoc IEthereal
    function setMaxSellPercent(uint16 _newMaxSellPercent) external onlyOwner {
        maxSellPerecent = _newMaxSellPercent;
        emit MaxSellPercentSet(_newMaxSellPercent);
    }

    /// @inheritdoc IEthereal
    function setJeetsTax(
        uint8 _vmindiv,
        uint8 _vmaxdiv,
        uint8 _maxjeetsfee
    ) external onlyOwner {
        VminDiv = _vmindiv;
        VmaxDiv = _vmaxdiv;
        MaxJeetsFee = _maxjeetsfee;
        emit JeetsTaxSet(_vmindiv, _vmaxdiv, _maxjeetsfee);
    }

    /// @inheritdoc IEthereal
    function setJeetsFeeEnabled(bool _applyStatus) external onlyOwner {
        JeetsFeeApply = _applyStatus;
        emit JeetsFeeEnabled(_applyStatus);
    }

    /// @inheritdoc IEthereal
    function mint(uint256 _amount) external {
        address sender = msg.sender;
        require (_amount > 0, "zero mint amount");
        require (
            sender == owner() ||
            sender == treasuryCA, 
            "no permission"
        );

        _totalSupply += _amount;
        _balances[sender] += _amount;

        emit Mint(sender, _amount);
    }

    /// @inheritdoc IEthereal
    function burn(uint256 _amount) external {
        address sender = msg.sender;
        require (_balances[sender] >= _amount, "no enough balance to burn");

        _totalSupply -= _amount;
        _balances[sender] -= _amount;

        emit Burn(sender, _amount);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        require (_amount > 0, "ERC20: zero _amount");
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require (tradingEnabled || whitelists[_from], "Trading not allowed yet");
        require (excludedLimits[_to] || _amount + _balances[_to] <= maxWallet, "exceeds to max wallet _amount");
        
        bool isBuy = lpPairs[_from];
        bool isSell = lpPairs[_to];
        uint16 tax = (isBuy || isSell) ? swapTax : 0;
        uint256 extraTax = 0;
        
        if (isBuy) {
            // catch bots
            uint128 buyTaxDuration = 1 minutes / 2;
            if (block.timestamp < launchTimeStamp + buyTaxDuration) {
                blacklists[_to] = true;
                tax = 1000; // 100%
            }
        }
        if (isSell) {
            require (excludedLimits[_from] || _amount <= maxSell, "exceeds to max sell _amount");
            if (!whitelists[_from]) {
                extraTax = _jeetsSellTax(_to, _amount);
            }
        }

        uint256 taxFee = _amount * tax / BASE_POINT;
        uint256 transferAmount = _amount - taxFee - extraTax;

        _balances[treasuryCA] += (taxFee + extraTax);
        _balances[_to] += transferAmount;
        _balances[_from] -= _amount;

        return true;
    }

    function _approve(address _sender, address _spender, uint256 _amount) internal {
        require(_sender != address(0), "ERC20: Zero Address");
        require(_spender != address(0), "ERC20: Zero Address");

        _allowances[_sender][_spender] = _amount;
        emit Approval(_sender, _spender, _amount);
    }

    /// @notice Based on the balance of lpPair has, increase the jeets sell tax.
    /// @dev This tax is for only sell.
    /// @return The extra tax token amount for sell.
    function _jeetsSellTax (
        address _lpPair,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 value = balanceOf(_lpPair);
        uint256 vMin = value * VminDiv / BASE_POINT;
        uint256 vMax = value * VmaxDiv / BASE_POINT;
        if (_amount <= vMin) return _amount = 0;
        if (_amount > vMax) return _amount * MaxJeetsFee / BASE_POINT;
        return (((_amount-vMin) * MaxJeetsFee * _amount) / (vMax-vMin)) / BASE_POINT;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEthereal is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    /// @notice Add/Remove wallets to blacklist.
    /// @dev Only owne can call this function.
    /// @param _wallets The address of wallets to add/remove to blacklist.
    /// @param _isAdd Add/Remove = true/false.
    function setBlacklist(address[] memory _wallets, bool _isAdd) external;

    /// @notice Add/Remove wallets to whitelist.
    /// @dev Only owne can call this function.
    /// @param _wallets The address of wallets to add/remove to whitelist.
    /// @param _isAdd Add/Remove = true/false.
    function setWhitelist(address[] memory _wallets, bool _isAdd) external;

    /// @notice Set trading status. on/off
    /// @dev Only owner can call this function.
    /// @param tradingStatus The status of trading. true/false
    function setTradingStatus(bool tradingStatus) external;

    /// @notice Add LpPair address.
    /// @dev Only treasury contract can call this function.
    /// @dev LpPair is excluded from limit and it will be whitelisted.
    /// @param lpPair The address of lp pair.
    function setLpPairs(address lpPair) external;

    /// @notice Set treasury contract address.
    /// @dev Only owner contract can call this function.
    /// @param treasuryCA The address of treasury contract.
    function setTreasuryCA(address treasuryCA) external;

    /// @notice Set max tax percent.
    /// @dev Only owner can call this function.
    /// @param maxTax The percent of max tax.
    function setMaxTax(uint16 maxTax) external;

    /// @notice Set jeets tax info.
    /// @dev Only owner can call this function.
    /// @param vmindiv The min percent for jeets.
    /// @param vmaxdiv The max percent for jeets.
    /// @param maxjeetsfee The max fee for jeets tax.
    function setJeetsTax(
        uint8 vmindiv,
        uint8 vmaxdiv,
        uint8 maxjeetsfee
    ) external;

    /// @notice Set JeetsFeeApply status on/off.
    /// @dev Only owner can call this function.
    /// @param applyStatus The status of JeetsFeeApply. on/off
    function setJeetsFeeEnabled(bool applyStatus) external;

    /// @notice Mint 2REAL token.
    /// @dev Only owner and multisig wallet can call this function.
    /// @param amount Amount of token to mint.
    function mint(uint256 amount) external;

    /// @notice Burn 2REAL token.
    /// @dev Anyone can call this function.
    /// @param amount Amount of token to burn.
    function burn(uint256 amount) external;

    /// @notice Set new percent of swap tax.
    /// @dev Only owner can call this function.
    function setSwapTax(uint16 newSwapTax) external;

    /// @notice Set new percent of max wallet.
    /// @dev Only owner can call this function.
    function setMaxWalletPercent(uint16 newMaxWalletPerecent) external;

    /// @notice Set new percent of max sell.
    /// @dev Only owner can call this function.
    function setMaxSellPercent(uint16 newMaxSellPercent) external;

    event Burn(address indexed burner, uint256 amount);

    event Mint(address indexed minter, uint256 amount);

    event TradingStatusSet(bool tradingStatus);

    event LpPairsSet(address indexed lpPair);

    event TreasuryCASet(address indexed treasuryCAAddr);

    event MaxTaxSet(uint16 newMaxTax);

    event SwapTaxSet(uint16 newSwapTax);

    event MaxWalletPercentSet(uint16 newPercent);

    event MaxSellPercentSet(uint16 newPercent);

    event JeetsTaxSet(uint8 vmindiv, uint8 vmaxdiv, uint8 maxjeetsfee);

    event JeetsFeeEnabled(bool status);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
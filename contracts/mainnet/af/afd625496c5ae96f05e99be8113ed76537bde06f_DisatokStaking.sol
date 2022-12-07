/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// File: contracts\IERC20.sol

/**
 * Tuleva
 * From: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity >=0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /*    
    function addNewSupply(uint256 amount) external returns (uint256);
    
    function setSalesAccount(address account) external;
    
    function setFeeAccount(address account) external;
*/

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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

// File: contracts\extensions\IERC20Metadata.sol

/**
 * Tuleva
 * From: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol
 */


// OpenZeppelin Contracts v4.3.2 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity >=0.8.10;

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

// File: contracts\utils\Context.sol

/**
 * Tuleva
 * From: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
 */


// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

pragma solidity >=0.8.10;

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

// File: contracts\contracts\Ownable.sol

/**
 * Tuleva
 * From: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */


// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity >=0.8.10;

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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        revert('renounceOwnership is not supported, please transfer ownership');
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
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

// File: contracts\utils\Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity >=0.8.10;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return '0';
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: contracts\Disatok.sol

/**
 * Tuleva
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
 */



pragma solidity >=0.8.10;




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
contract Disatok is Ownable, IERC20, IERC20Metadata {
    string private constant _name = 'DISATOK';
    string private constant _symbol = 'DISA';
    uint8 private constant _decimals = 8;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _feeExcludes;

    uint256 private _totalSupply = 10000000 * 10**_decimals;
    uint256 private _taxFee;
    address private _accountFee;
    address private _accountSales;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        address initalAccountSales,
        address initialAccountFee,
        uint256 initalTaxFee
    ) {
        _accountSales = initalAccountSales;
        _accountFee = initialAccountFee;
        _taxFee = initalTaxFee;

        //exclude owner and this contract from fee
        _feeExcludes[owner()] = true;
        _feeExcludes[_accountSales] = true;
        _feeExcludes[_accountFee] = true;

        _balances[owner()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 transferAmount = _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= transferAmount, 'transfer amount exceeds allowance');
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - transferAmount);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (uint256) {
        require(sender != address(0), 'transfer from the zero address');
        require(recipient != address(0), 'transfer to the zero address');

        // delete
        //_beforeTokenTransfer(sender, recipient, amount);
        uint256 transferAmount = amount;
        uint256 senderBalance = _balances[sender];
        bool noFee = isExcludedFromFee(sender) || isExcludedFromFee(recipient);

        if (noFee) {
            require(senderBalance >= amount, 'transfer amount exceeds balance');
            unchecked {
                _balances[sender] = senderBalance - amount;
            }
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        } else {
            uint256 fee = _calculateTaxFee(amount);
            uint256 senderAmount = amount + fee;
            transferAmount = senderAmount;

            string memory errorMessage = string(abi.encodePacked('transfer amount exceeds balance. transfer amount incl. sales fee is', ' ', Strings.toString(transferAmount)));
            require(senderBalance >= senderAmount, errorMessage);

            unchecked {
                _balances[sender] = senderBalance - senderAmount;
            }

            _balances[_accountFee] += fee;
            _balances[recipient] += amount;

            emit Transfer(sender, _accountFee, fee);
            emit Transfer(sender, recipient, amount);
        }

        return transferAmount;
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
        require(owner != address(0), 'approve from the zero address');
        require(spender != address(0), 'approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    event ExcludeFromFee(address account);

    function excludeFromFee(address account) public onlyOwner {
        emit ExcludeFromFee(account);
        _feeExcludes[account] = true;
    }

    event IncludeInFee(address account);

    function includeInFee(address account) public onlyOwner {
        emit IncludeInFee(account);
        _feeExcludes[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _feeExcludes[account];
    }

    event SetTaxFeePercent(uint256 newTaxFee);

    function setTaxFeePercent(uint256 newTaxFee) external onlyOwner {
        emit SetTaxFeePercent(newTaxFee);
        _taxFee = newTaxFee;
    }

    function _calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return (_amount * (_taxFee)) / 100;
    }

    event AddNewSupply(uint256 amount);

    function addNewSupply(uint256 amount) public onlyOwner returns (uint256) {
        emit AddNewSupply(amount);
        require(amount > 0, 'new amount must be greater than 0');

        uint256 newSupply = amount * 10**_decimals;
        _totalSupply += newSupply;
        _balances[owner()] += newSupply;
        emit Transfer(address(0), owner(), newSupply);

        return _totalSupply;
    }

    event SetSalesAccount(address account);

    function setSalesAccount(address account) public onlyOwner {
        emit SetSalesAccount(account);
        _feeExcludes[_accountSales] = false;
        _feeExcludes[account] = true;
        _accountSales = account;
    }

    event SetFeeAccount(address account);

    function setFeeAccount(address account) public onlyOwner {
        emit SetFeeAccount(account);
        _feeExcludes[_accountFee] = false;
        _feeExcludes[account] = true;
        _accountFee = account;
    }

    event TransferOwnership(address newOwner);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * overwrites functionality
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        emit TransferOwnership(newOwner);
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        address oldOwner = owner();

        _transferOwnership(newOwner);
        _feeExcludes[oldOwner] = false;
        _feeExcludes[newOwner] = true;
    }

    function taxFee() public view virtual returns (uint256) {
        return _taxFee;
    }
}

// File: contracts\DisatokStaking.sol



pragma solidity >=0.8.10;
contract DisatokStaking is Ownable {
    string private constant _name = 'Disatok Staking';

    struct Staker {
        StakeItem[] stakedItems;
    }

    struct StakeItem {
        uint256 start;
        uint256 end;
        uint256 duration;
        uint256 interest;
        uint256 amount;
        bool running;
    }

    struct StakeItemResult {
        uint256 index;
        uint256 start;
        uint256 end;
        uint256 duration;
        uint256 interest;
        uint256 amount;
        bool running;
    }

    Disatok public disatok;

    address[] public stakers;
    uint256[] public durations;
    uint256 public minStakeAmount;

    mapping(address => uint256) public balance;
    mapping(uint256 => uint256) public interests;
    mapping(address => bool) public hasStaked;
    mapping(address => Staker) internal stakes;

    constructor(Disatok _disatok, uint256 _minStakeAmount) {
        disatok = _disatok;
        minStakeAmount = _minStakeAmount;

        addInterest(182, 5);
        addInterest(365, 12);
        addInterest(730, 30);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function createStakeItem(
        uint256 amount,
        uint256 duration,
        uint256 interest
    ) private view returns (StakeItem memory) {
        uint256 start = block.timestamp;
        uint256 end = start + (duration * 1 days);

        StakeItem memory item;
        item.start = start;
        item.end = end;
        item.amount = amount;
        item.duration = duration;
        item.interest = interest;
        item.running = true;
        return item;
    }

    event StakeTokens(StakeItem item);

    function stakeTokens(uint256 amount, uint256 duration) public returns (bool) {
        require(amount >= minStakeAmount, 'amount is less than staking minimum');

        uint256 interest = interests[duration];
        require(interest > 0, 'duration is not supported');

        uint256 disatokBalance = disatok.balanceOf(msg.sender);
        require(disatokBalance >= amount, 'Amount exceeds balance');

        StakeItem memory item = createStakeItem(amount, duration, interest);
        emit StakeTokens(item);
        disatok.transferFrom(msg.sender, address(this), item.amount);
        balance[msg.sender] = balance[msg.sender] + item.amount;

        stakes[msg.sender].stakedItems.push(item);
        // add user to stakers array *only* if they haven't staked already
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
            hasStaked[msg.sender] = true;
        }

        return true;
    }

    function getStakes(bool running) public view returns (StakeItemResult[] memory) {
        return _getStakes(msg.sender, running);
    }

    function getStakesForAddress(address account, bool running) public view onlyOwner returns (StakeItemResult[] memory) {
        return _getStakes(account, running);
    }

    function _getStakes(address account, bool running) internal view returns (StakeItemResult[] memory) {
        uint256 itemsCount = stakes[account].stakedItems.length;

        uint256 resultCount = 0;
        for (uint256 i = 0; i < itemsCount; i++) {
            StakeItem memory item = stakes[account].stakedItems[i];
            if (item.running == running) {
                resultCount++;
            }
        }

        StakeItemResult[] memory results = new StakeItemResult[](resultCount);
        uint256 insertCounter = 0;
        for (uint256 i = 0; i < itemsCount; i++) {
            StakeItem memory item = stakes[account].stakedItems[i];
            if (item.running == running) {
                StakeItemResult memory resultItem;
                resultItem.index = i;
                resultItem.start = item.start;
                resultItem.end = item.end;
                resultItem.amount = item.amount;
                resultItem.duration = item.duration;
                resultItem.interest = item.interest;
                resultItem.running = item.running;

                results[insertCounter] = resultItem;
                insertCounter++;
            }
        }
        return results;
    }

    function getDurationIndex(uint256 _duration) public view onlyOwner returns (int256) {
        uint256 itemsCount = durations.length;
        bool found = false;
        int256 index = -1;
        for (uint256 i = 0; i < itemsCount; i++) {
            uint256 d = durations[i];
            if (d == _duration) {
                index = int256(i);
                found = true;
            }
        }

        return index;
    }

    event AddInterest(uint256 _duration, uint256 _interest);

    function addInterest(uint256 _duration, uint256 _interest) public onlyOwner {
        emit AddInterest(_duration, _interest);
        int256 index = getDurationIndex(_duration);
        if (index == -1) {
            durations.push(_duration);
        }
        interests[_duration] = _interest;
    }

    event RemoveInterest(uint256 _duration);

    function removeInterest(uint256 _duration) public onlyOwner {
        int256 index = getDurationIndex(_duration);
        emit RemoveInterest(_duration);

        if (index > -1) {
            delete durations[uint256(index)];
            durations[uint256(index)] = durations[durations.length - 1];
            durations.pop();
        }
        delete interests[_duration];
    }

    event SetMinStakeAmount(uint256 fullDisa, uint256 disaWithDecimals);

    function setMinStakeAmount(uint256 fullDisa) public onlyOwner {
        minStakeAmount = fullDisa * 10**disatok.decimals();
        emit SetMinStakeAmount(fullDisa, minStakeAmount);
    }

    event IssueToken(StakeItem item);

    function issueToken(uint256 index) public {
        StakeItem memory item = stakes[msg.sender].stakedItems[index];
        require(msg.sender != address(0), 'sender cannot be the zero address');
        require(item.end <= block.timestamp && item.amount > 0 && item.running, 'stake not ready to issue token');

        stakes[msg.sender].stakedItems[index].running = false;
        uint256 total = (item.amount * (100 + item.interest)) / 100;
        disatok.transfer(msg.sender, total);

        //Remove from balance
        balance[msg.sender] = balance[msg.sender] - item.amount;

        emit IssueToken(item);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;



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
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}


// File contracts/LuckyCoin.sol

pragma solidity ^0.8.0;

contract LuckyCoin is ERC20Burnable {
    //The weekly interest rate: 0.25%
    uint256 constant WEEKLY_INTEREST_RATE_X10000 = 25;

    //The weekly defaltion rate: 0.25%
    uint256 constant WEEKLY_DEFLATION_RATE_X10000 = 25;

    //The minimum random mint rate: 100% = 1x
    uint256 constant MINIMUM_MINT_RATE_X100 = 1e2;

    //The maximum random mint rate: 100,000% = 1,000x
    uint256 constant MAXIMUM_MINT_RATE_X100 = 1e5;

    //The maximum random mint amount relative to the total coin amount: 5%
    uint256 constant MAX_MINT_TOTAL_AMOUNT_RATE_X100 = 5;

    //The coin amount for the initial minting: 100,000,000
    uint256 constant INITIAL_MINT_AMOUNT = 1e26;

    //The minimum total supply: 1,000
    uint256 constant MINIMUM_TOTAL_SUPPLY = 1e21;

    //Time interval for random mint
    //uint256 constant RANDOM_MINT_MIN_INTERVAL = 1 weeks - 10 minutes;

    //Value for TestNet
    //TODO: DELETE
    uint256 constant RANDOM_MINT_MIN_INTERVAL = 1 hours;

    //Timeout for random mint
    //uint256 constant RANDOM_MINT_TIMEOUT = 1 days;

    //Value for TestNet
    //TODO: DELETE
    uint256 constant RANDOM_MINT_TIMEOUT = 10 minutes;

    //Minimum number of total addresses required to run the
    //random mint
    //uint256 constant RANDOM_MINT_MIN_TOTAL_ADDRESSES = 100;

    //Value for TestNet
    //TODO: DELETE
    uint256 constant RANDOM_MINT_MIN_TOTAL_ADDRESSES = 10;

    //Number of bits for the random number generation
    uint8 constant RANDOM_NUM_BITS = 32;

    //The maximum burn rate for each transation: 10%
    uint256 constant MAXIMUM_TRANSACTION_BURN_RATE_X10000 = 1000;

    //The smoothing factor for the calculation of the exponential moving average of the mean volume: 0.1
    uint256 constant MEAN_VOLUME_SMOOTHING_FACTOR_X10000 = 1000;

    //the maximum single trade volume in relatio to toal supply: 5%
    uint256 constant MAXIMUM_SINGLE_TRADE_VOLUME_X10000 = 500;

    //the multiplicator to : 0.9 (1 year)
    uint256 constant BURN_RATE_TIME_HORIZON_MULTIPLICATOR_X10000 = 9000;

    //initial estimation of the weekly volume: 15%
    uint256 constant INITIAL_MEAN_WEEK_VOLUME_X10000 = 1500;

    //amount of burn under expected total supply: 1%
    uint256 constant MAXIMUM_WEEK_BURN_EXCESS_X10000 = 100;

    //Total number of addresses with amount > 0
    uint256 public totalAddresses;

    //Mapping from index to address
    //TODO: private
    mapping(uint256 => address) public indexToAddress;

    //Mapping from addresso to index
    //TODO: private
    mapping(address => uint256) public addressToIndex;

    //Timestamp of the start of last random mint
    uint256 public randomMintLastTimeStamp;

    //Block number of the start of last random mint
    uint256 public randomMintStartBlockNumber;

    //The burn rate for each transation
    uint256 public transactionBurnRateX10000;

    //The current week trade volume
    //TODO: private
    uint256 public currentWeekVolume;

    //The current week trade volume
    //TODO: private
    uint256 public currentWeekBurnAmount;

    //The mean week trade volume divided by the total supply
    //TODO: private
    uint256 public meanWeekVolumeX10000;

    //The expected total supply
    //TODO: private
    uint256 public expectedSupply;

    //The maximum burn amount for the current week
    //TODO: private
    uint256 public maximumWeekBurnAmount;

    //Constructor
    constructor() ERC20("LuckyCoin2", "LCK2") {
        totalAddresses = 0;
        randomMintLastTimeStamp = 0;
        randomMintStartBlockNumber = 0;
        transactionBurnRateX10000 = 0;
        //Value for local test
        //TODO: DELETE
        //transactionBurnRateX10000 = 1000;
        currentWeekVolume = 0;
        meanWeekVolumeX10000 = INITIAL_MEAN_WEEK_VOLUME_X10000;
        expectedSupply = INITIAL_MINT_AMOUNT;
        maximumWeekBurnAmount = 0;
        //Value for local test
        //TODO: DELETE
        //maximumWeekBurnAmount = INITIAL_MINT_AMOUNT;
        currentWeekBurnAmount = 0;
        _mint(msg.sender, INITIAL_MINT_AMOUNT);
    }

    //Public function to start the random mint,
    //Checks the requirements and starts the private function
    function randomMintStart() external {
        require(
            block.timestamp >
                randomMintLastTimeStamp + RANDOM_MINT_MIN_INTERVAL,
            "You have to wait one week after the last random mint"
        );
        require(
            !(randomMintStartBlockNumber > 0),
            "Random mint already started"
        );
        require(
            randomMintLastTimeStamp > 0,
            "Minimum number of addresses has not been reached"
        );
        _randomMintStart();
    }

    //Private function to start the random mint
    //It just sets the initial timestamp and block number
    //(this will stop all transactions until the end of random mint)
    function _randomMintStart() internal {
        randomMintLastTimeStamp = block.timestamp;
        randomMintStartBlockNumber = block.number;
    }

    //Public function to end the random mint
    //Checks the requirements and starts the private function
    function randomMintEnd() external {
        require(randomMintStartBlockNumber > 0, "Random mint not started");
        require(
            block.number > randomMintStartBlockNumber + RANDOM_NUM_BITS + 1,
            "You have to wait 32 blocks after start"
        );
        _randomMintEnd();
    }

    //Private function to end the random mint
    //Random mint and update of the burn rate
    function _randomMintEnd() internal {
        //reset state
        randomMintStartBlockNumber = 0;

        //check timeout
        if (block.timestamp < randomMintLastTimeStamp + RANDOM_MINT_TIMEOUT) {
            //random mint
            _randomMint();

            //update burn rate
            _updateBurnRate();
        }
    }

    //Updates the burn rate
    function _updateBurnRate() internal {
        //update mean volume
        meanWeekVolumeX10000 =
            (MEAN_VOLUME_SMOOTHING_FACTOR_X10000 * currentWeekVolume) /
            totalSupply() +
            ((10000 - MEAN_VOLUME_SMOOTHING_FACTOR_X10000) *
                meanWeekVolumeX10000) /
            10000;

        //reset weekly totals
        currentWeekVolume = 0;
        currentWeekBurnAmount = 0;

        //update expected supply
        expectedSupply = max(
            (expectedSupply * (10000 - WEEKLY_DEFLATION_RATE_X10000)) / 10000,
            MINIMUM_TOTAL_SUPPLY
        );

        //update burn rate
        if (totalSupply() > expectedSupply) {
            transactionBurnRateX10000 = min(
                (100000000 -
                    (BURN_RATE_TIME_HORIZON_MULTIPLICATOR_X10000 +
                        ((10000 - BURN_RATE_TIME_HORIZON_MULTIPLICATOR_X10000) *
                            expectedSupply) /
                        totalSupply()) *
                    (10000 -
                        WEEKLY_INTEREST_RATE_X10000 -
                        WEEKLY_DEFLATION_RATE_X10000)) /
                    max(meanWeekVolumeX10000, 1),
                MAXIMUM_TRANSACTION_BURN_RATE_X10000
            );
            maximumWeekBurnAmount =
                totalSupply() -
                expectedSupply +
                (expectedSupply * MAXIMUM_WEEK_BURN_EXCESS_X10000) /
                10000;
        } else {
            transactionBurnRateX10000 = 0;
            maximumWeekBurnAmount = 0;
        }
    }

    //Generation of random wallet index, computation of the mint amount and mint operation
    function _randomMint() internal {
        //clculate random wallet index
        uint256 selectedIndex = generateSafePRNG(
            RANDOM_NUM_BITS,
            totalAddresses
        ) + 1;
        //calculate mint rate
        uint256 mintRateX100 = (totalAddresses * WEEKLY_INTEREST_RATE_X10000) /
            100;
        //calculate number of extractions
        uint256 numExctractions = (mintRateX100 - 1) /
            MAXIMUM_MINT_RATE_X100 +
            1;
        while (mintRateX100 > 0) {
            //get random wallet address
            address selectedAddress = indexToAddress[selectedIndex];
            //calculate mint amount
            uint256 mintAmount = (balanceOf(selectedAddress) *
                min(
                    max(mintRateX100, MINIMUM_MINT_RATE_X100),
                    MAXIMUM_MINT_RATE_X100
                )) / 100;
            //limit max mint amont
            mintAmount = min(
                mintAmount,
                (totalSupply() * MAX_MINT_TOTAL_AMOUNT_RATE_X100) / 100
            );
            //mint
            _mint(selectedAddress, mintAmount);
            //next address
            selectedIndex += totalAddresses / numExctractions;
            if (selectedIndex > totalAddresses) selectedIndex -= totalAddresses;
            //decrease mint rate
            mintRateX100 -= min(mintRateX100, MAXIMUM_MINT_RATE_X100);
        }
    }

    //Callback function before token transfer
    //Checks if the random mint is in progress and automatically starts/stops it
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (randomMintStartBlockNumber == 0) {
            //random mint not in progress
            if (
                block.timestamp >
                randomMintLastTimeStamp + RANDOM_MINT_MIN_INTERVAL &&
                randomMintLastTimeStamp > 0
            ) {
                //start random mint
                _randomMintStart();
            }
        } else {
            //random mint in progress
            if (
                block.number > randomMintStartBlockNumber + RANDOM_NUM_BITS + 1
            ) {
                //end random mint
                _randomMintEnd();
            } else {
                //error (but allow token transfers in this block)
                if (block.number > randomMintStartBlockNumber)
                    revert(
                        "Random mint in progress, transactions are suspended"
                    );
            }
        }
    }

    //Callback function after token transfer
    //Updates the wallet count and the mapping from index to address and from address to index
    //Removes a wallet if it becames empty and adds add a new wallet if it becames full
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        if (amount == 0 || from == to) return;

        // insert receiver in mapping
        if (to != address(0) && balanceOf(to) == amount) {
            // increment number of addresses
            totalAddresses++;
            // insert address in mapping
            indexToAddress[totalAddresses] = to;
            addressToIndex[to] = totalAddresses;
            //enable random mint
            if (
                randomMintLastTimeStamp == 0 &&
                totalAddresses >= RANDOM_MINT_MIN_TOTAL_ADDRESSES
            ) randomMintLastTimeStamp = block.timestamp;
        }

        // remove sender from mapping
        if (from != address(0) && balanceOf(from) == 0) {
            // remove address from mapping
            indexToAddress[addressToIndex[from]] = indexToAddress[
                totalAddresses
            ];
            addressToIndex[indexToAddress[totalAddresses]] = addressToIndex[
                from
            ];
            // decrement number of addresses
            totalAddresses--;
        }
    }

    //Override for _transfer function
    //Performs token burning
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        //calculate burn amount
        uint256 burnAmount = 0;
        if (currentWeekBurnAmount < maximumWeekBurnAmount) {
            burnAmount = (transactionBurnRateX10000 * amount) / 10000;
            if (currentWeekBurnAmount + burnAmount > maximumWeekBurnAmount)
                burnAmount = maximumWeekBurnAmount - currentWeekBurnAmount;
        }
        //burn
        if (burnAmount > 0) _burn(from, burnAmount);
        //transfer
        super._transfer(from, to, amount - burnAmount);
        //update weekly totals
        if (randomMintLastTimeStamp > 0) {
            currentWeekVolume += min(
                amount,
                (MAXIMUM_SINGLE_TRADE_VOLUME_X10000 * totalSupply()) / 10000
            );
            currentWeekBurnAmount += burnAmount;
        }
    }

    //Calculates the minimum of two numbers
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    //Calculates the maximum of two numbers
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    //Calculates a pseudorandom number taking 1 bit from each previous block
    //The generated pseudorandom number is in the range [0 : maxValue - 1]
    function generateSafePRNG(uint8 numBlocks, uint256 maxValue)
        internal
        view
        returns (uint256)
    {
        //initialize
        uint256 seed = uint256(blockhash(block.number - numBlocks - 1)) <<
            numBlocks;
        //take 1 bit from the last blocks
        for (uint8 i = 0; i < numBlocks; i++)
            seed |= (uint256(blockhash(block.number - i - 1)) & 0x01) << i;
        //hash
        seed = uint256(keccak256(abi.encodePacked(seed)));
        //limit to max and return
        return seed - maxValue * (seed / maxValue);
    }

    /*

    //Calculates a random number taking 1 bit from each previous block
    //Function for local test
    //TODO: delete
    function testRandomNumber(uint8 numBlocks) external view returns (uint256) {
        //initialize
        uint256 randomNumer = uint256(blockhash(block.number - numBlocks - 1)) <<
            numBlocks;
        //take 1 bit from the last blocks
        for (uint8 i = 0; i < numBlocks; i++)
            randomNumer |=
                (uint256(blockhash(block.number - i - 1)) & 0x01) <<
                i;
        //no hash and return
        return randomNumer;
    }

    //Function for local test
    //TODO: delete
    function testBlockhash(uint256 i) external view returns (uint256) {
        return uint256(blockhash(block.number - i));
    }

    //Function for local test
    //TODO: delete
    function setRandomMintLastTimeStamp(uint256 x) external {
        randomMintLastTimeStamp = x;
    }

    //Function for local test
    //TODO: delete
    function setRandomMintStartBlockNumber(uint256 x) external {
        randomMintStartBlockNumber = x;
    }
*/
}
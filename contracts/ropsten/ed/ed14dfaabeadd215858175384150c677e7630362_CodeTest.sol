// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract CodeTest is ERC20, ERC20Burnable, Ownable{
    
	address payable public team_wallet_1;
    address payable public team_wallet_2;

    struct UserStruct {
        uint id;
        address payable referrerID;
        address[] referral;
        uint investment;
        uint max_investment;
		uint investment_time;
		uint ROI_percent;
		uint ROI_before_investment;
		uint ROI_taken_time;
        uint withdrawal_time;
        uint[3][3] ROI;
        uint level;
    }

    uint public totalInvest = 0;
    uint public withdrawal = 0;
	uint public withdrawal_fee_in_lock = 5;
	uint public withdrawal_fee_after_lock = 1;
	uint public lock_period = 30 days;
	uint public token_price = 1 ether;
	uint public BNB_price = 1 ether;

    uint[] public reward_precent = [100,100,10,10,10,10,10,10,10,10,10];
	uint[] public min_balance = [1 ether, 5 ether, 10 ether];
	uint[] public ROI_percent = [25, 30, 35];
    uint[] public level = [3, 6, 9, 12, 15];

    mapping (address => UserStruct) public users;

    uint public currUserID = 0;

    event regEvent(address indexed _user, address indexed _referrer, uint _time);
    event investEvent(address indexed _user, uint _amount, uint _time);
    event getMoneyEvent(uint indexed _user, uint indexed _referral, uint _amount, uint _level, uint _time);
	event WithdrawalEvent(address indexed _user, uint _amount, uint _time);
	event ROI_WithdrawalEvent(address indexed _user, uint _amount, uint _time);

    constructor() ERC20("Yoplex", "Yoplex") {
		team_wallet_1 = payable(msg.sender);
        team_wallet_2 = payable(msg.sender);

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            id: currUserID,
            referrerID: payable(address(0)),
            referral: new address[](0),
            investment: 99999999 ether,
            max_investment: 99999999 ether,
			investment_time: block.timestamp,
			ROI_percent: 2,
			ROI_before_investment: 0,
			ROI_taken_time: block.timestamp,
            withdrawal_time: block.timestamp,
            ROI: [[uint(0),uint(0),uint(0)],[uint(0),uint(0),uint(0)],[uint(0),uint(0),uint(0)]],
            level: 0
        });
        users[msg.sender] = userStruct;
    }

	function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function regUser(address payable _referrerID) public payable {
        require(users[msg.sender].id == 0, "User exist");
        require(msg.value >= min_balance[0], "register with minimum 1 ETH");
        if(_referrerID == address(0)){
            _referrerID = payable(owner());
        }

        totalInvest += msg.value;
        currUserID++;

		UserStruct memory userStruct;
        userStruct = UserStruct({
            id: currUserID,
            referrerID: _referrerID,
            referral: new address[](0),
            investment: BNB_to_USD(msg.value),
            max_investment: BNB_to_USD(msg.value),
			investment_time: block.timestamp,
			ROI_percent: 0,
			ROI_before_investment: 0,
			ROI_taken_time: block.timestamp,
            withdrawal_time: block.timestamp,
            ROI: [[BNB_to_USD(msg.value),uint(0),uint(0)],[uint(0),uint(0),uint(0)],[uint(0),uint(0),uint(0)]],
            level: 0
        });
        users[msg.sender] = userStruct;
        users[_referrerID].referral.push(msg.sender);
		for (uint i = 0; i < min_balance.length; i++) {
			if(users[msg.sender].investment >= min_balance[i]){
				users[msg.sender].ROI_percent = i;
			}
		}
		team_wallet_1.transfer(msg.value * 4 / 10); // 40%
        team_wallet_2.transfer(msg.value / 10); // 10%
        emit regEvent(msg.sender, _referrerID, block.timestamp);
    }

    function invest() public payable {
        require(users[msg.sender].id > 0, "User not exist");
        require(msg.value > 0, "invest with ETH");

        totalInvest += msg.value;

        users[msg.sender].ROI_before_investment += viewUserROI(msg.sender);
		users[msg.sender].ROI_taken_time = block.timestamp;
        users[msg.sender].investment_time = block.timestamp;
        uint before_investment_amt = users[msg.sender].investment;
        uint before_investment_per = users[msg.sender].ROI_percent;
        users[msg.sender].investment += BNB_to_USD(msg.value);
        for (uint i = 0; i < min_balance.length; i++) {
			if(users[msg.sender].investment >= min_balance[i]){
				users[msg.sender].ROI_percent = i;
			}
		}
        uint after_investment_amt = users[msg.sender].investment;
        uint after_investment_per = users[msg.sender].ROI_percent;

        giveROI(msg.sender, after_investment_amt, before_investment_amt, after_investment_per, before_investment_per, 0, 0);

        if(users[msg.sender].investment > users[msg.sender].max_investment){
            users[msg.sender].max_investment = users[msg.sender].investment;
        }

        emit investEvent(msg.sender, msg.value, block.timestamp);
    }

    function giveROI(address _user, uint _amountAdd, uint _amountSub, uint _roiAdd, uint _roiSub, uint _gen, uint _dl_amount) internal {
        if(_gen < 21 && _user != address(0)){
            if(_gen < 2){
                users[_user].ROI[_roiAdd][0] += _amountAdd;
                users[_user].ROI[_roiSub][0] -= _amountSub;
            }else if(_gen < 11){
                users[_user].ROI[_roiAdd][1] += _amountAdd;
                users[_user].ROI[_roiSub][1] -= _amountSub;
            }else{
                users[_user].ROI[_roiAdd][2] += _amountAdd;
                users[_user].ROI[_roiSub][2] -= _amountSub;
            }
            if(_gen > 11){
                _dl_amount += users[_user].investment;
            }
            if(users[_user].investment >= 3000 && _dl_amount >= 200000){
                users[_user].level = 1;
            }
            giveROI(users[_user].referrerID, _amountAdd, _amountSub, _roiAdd, _roiSub, _gen, _dl_amount);
        }
    }

    function viewUserROI(address _user) public view returns(uint) {
        uint ROI = 0;
        for (uint i = 0; i < 3; i++) {
            ROI += users[_user].ROI[i][0] * ROI_percent[i] * ((block.timestamp - users[_user].ROI_taken_time) / 10 minutes) / 10000;
            if(users[_user].referral.length >= 5){
                ROI += users[_user].ROI[i][1] * ROI_percent[i] * ((block.timestamp - users[_user].ROI_taken_time) / 10 minutes) / 10000 / 10;
            }
            if(users[_user].level > 0){
                ROI += users[_user].ROI[i][2] * ROI_percent[i] * ((block.timestamp - users[_user].ROI_taken_time) / 10 minutes) / 10000 * level[users[_user].level] / 100;
            }
        }
        return ROI;
    }

	function USD_to_token(uint _amount) public view returns(uint) {
        return _amount / token_price;
    }

	function BNB_to_USD(uint _amount) public view returns(uint) {
        return _amount * BNB_price;
    }

	function USD_to_BNB(uint _amount) public view returns(uint) {
        return _amount / BNB_price;
    }

	function viewUserGen(address _user, uint _gen) public view returns(uint) {
        uint gen = _gen;
        for (uint i = 0; i < users[_user].referral.length; i++) {
            uint temp = viewUserGen(users[_user].referral[i], (_gen + uint(1)));
            if(temp > gen){
                gen = temp;
            }
        }
        return gen;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function ROI_Withdrawal() public returns (bool) {
		require(users[msg.sender].id > 0, "User not exist");
        uint amount = viewUserROI(msg.sender);
        amount += users[msg.sender].ROI_before_investment;
		users[msg.sender].ROI_taken_time = block.timestamp;
        users[msg.sender].ROI_before_investment = 0;
		payable(msg.sender).transfer(USD_to_BNB(amount));
		emit ROI_WithdrawalEvent(msg.sender, amount, block.timestamp);
        return true;
    }

	function userWithdrawal() public returns (bool) {
		require(users[msg.sender].id > 0, "User not exist");
		require(users[msg.sender].investment_time + lock_period < block.timestamp, "Token is in lock period");
        uint amount = 0;
		if(((block.timestamp - users[msg.sender].withdrawal_time) / 10 minutes) >= 5){
			amount = users[msg.sender].investment;
		}else{
			amount = users[msg.sender].max_investment * (20 * ((block.timestamp - users[msg.sender].withdrawal_time) / 10 minutes)) / 100;
		}
        if(amount > users[msg.sender].investment){
            amount = users[msg.sender].investment;
        }
        
        uint before_investment_amt = users[msg.sender].investment;
        uint before_investment_per = users[msg.sender].ROI_percent;
        
		users[msg.sender].investment -= amount;

        for (uint i = 0; i < min_balance.length; i++) {
			if(users[msg.sender].investment >= min_balance[i]){
				users[msg.sender].ROI_percent = i;
			}
		}
        uint after_investment_amt = users[msg.sender].investment;
        uint after_investment_per = users[msg.sender].ROI_percent;

        giveROI(msg.sender, after_investment_amt, before_investment_amt, after_investment_per, before_investment_per, 0, 0);

        users[msg.sender].withdrawal_time = block.timestamp;
        users[msg.sender].ROI_before_investment += viewUserROI(msg.sender);
        users[msg.sender].ROI_taken_time = block.timestamp;

		_mint(msg.sender, USD_to_token(amount));
		emit WithdrawalEvent(msg.sender, amount, block.timestamp);
        return true;
    }

	function beneficiaryWithdrawal(address payable _address, uint _amount) public onlyOwner returns (bool) {
        require(_address != address(0), "Enter right adress");
        require(_amount < address(this).balance && _amount > 0, "Enter right amount");
        withdrawal += _amount;
        _address.transfer(_amount);
        return true;
    }

    function updateRewardPercent(uint[] memory _precent_of_reward) onlyOwner public returns (bool) {
        reward_precent = _precent_of_reward;
        return true;
    }

	function update_withdrawal_fee_in_lock(uint _withdrawal_fee_in_lock) onlyOwner public returns (bool) {
        withdrawal_fee_in_lock = _withdrawal_fee_in_lock;
        return true;
    }

	function update_withdrawal_fee_after_lock(uint _withdrawal_fee_after_lock) onlyOwner public returns (bool) {
        withdrawal_fee_after_lock = _withdrawal_fee_after_lock;
        return true;
    }

	function update_lock_period(uint _lock_period) onlyOwner public returns (bool) {
        lock_period = _lock_period;
        return true;
    }

	function update_reward_precent(uint[] memory _reward_precent) onlyOwner public returns (bool) {
        reward_precent = _reward_precent;
        return true;
    }

	function update_min_balance(uint[] memory _min_balance) onlyOwner public returns (bool) {
        min_balance = _min_balance;
        return true;
    }

	function update_ROI_percente(uint[] memory _ROI_percent) onlyOwner public returns (bool) {
        ROI_percent = _ROI_percent;
        return true;
    }

    function update_team(address payable _address_1, address payable _address_2) onlyOwner public returns (bool) {
        team_wallet_1 = _address_1;
        team_wallet_2 = _address_2;
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
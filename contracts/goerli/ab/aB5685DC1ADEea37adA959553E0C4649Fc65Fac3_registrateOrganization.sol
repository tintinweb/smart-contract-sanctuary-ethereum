// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./StreamLogic.sol";

error Unauthorized();

 // ---------- PROBLEMS & TASKS--------------
// owner => director // Add roles?
// Shoud it be tru ProxY? Can we create new contract with proxy?
// Banc Control
// Refactor add employy & delete employee & modify employy

contract Company is StreamLogic {

    // ADD EVENTS
    event AddEmployee(address _who, uint _time);
    event StartFlow(address _who, uint _time);

    string public name;
    uint public totalAmountEmployee;

    constructor (string memory _name){
        name = _name;
        totalAmountEmployee = 1;
    }

    struct Employee{
        address who;
        uint256 flowRate; // 1 token / sec
        bool worker;
        //bool what kind of sallary he s going to get >>> h/$ or $/mounth
    }
    mapping(address => Employee) public allEmployee;

    function addEmployee(address _who, uint256 _rate) external {

           Employee memory newEmployee = Employee({
			who: _who,
			flowRate: _rate,
			worker: true
		});

		allEmployee[_who] = newEmployee;

        totalAmountEmployee++;
        emit AddEmployee(_who, block.timestamp);

        //add func to canculate AR
    }

    function modifyRate(address _who, uint256 _rate) external {

    }

    // FUNC >> DELETE EMPLOYEE

    // FUNC >>  changeRate();


//-------------------- BANK CONTROL --------------
    
    // Problem -> Not enough funds in this contract to pay salary!


    // Solution #1 (restriction on each stream)
    uint public tokenLimitMaxHoursPerPerson = 20 hours; // Max amount hours of each stream with enough funds;

    function validToStream(address _who)public view returns(bool){
         return (allEmployee[_who].flowRate * tokenLimitMaxHoursPerPerson ) >= balanceContract();
    }

   
    // Solution #2 (restriction on all live stream)
    // 1000$ TB => active stream++ | ar++ => cant create stream if not enough
     uint public tokenLimitMaxHoursAllStream = 10 hours;
    function validToStreamAll()public view returns(bool){
        // FORMULA =>      tas * ar >= TL
        // tas = total amount of active stream
        // ar = avarage rate  ??? How to count (create new var) uint ar -> canculate each time when we add new employee
        // TL = tokenLimitMaxHoursAllStream | set up by company? Decided by DAO? Immutable by default
    }

    // Solution #3 (restriction to add new employee)
     uint public hoursLimitToAddNewEmployee = 100 hours;
     function valitToAdd()public view returns(bool){
        // FORMULA =>      tae * ar * TL >= balanceOf(this)
        // tae = total amount of all employee
        // ar = avarage rate (look above)
        // HL = hours limit

        //PS "If company doesnt have enought tokens to pay all employee for next 100 hours they can add new employee"
     }

     //---- ADD BUFFER ---------
     // rate / time /  money


// -------------- FUNCS with EMPLOYEEs ----------------
    //@dev Starts counting time
    function start(address _who) public {
        // put restriction
        startStream(_who, allEmployee[_who].flowRate);
    }

    function finish(address _who) public {
        uint256 salary = finishStream(_who);
        // if(!overWroked){
        //     function ifyouEmployDolboeb()
        // }
        token.transfer(_who, salary);
    }

    function withdrawEploy()public{

    }
// Decimals = 6 | 1 USDC = 1_000_000 tokens
    function getDecimals()public view returns(uint){
        return token.decimals();
    }



    receive() external payable { }
    fallback() external payable { }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import { Company } from "./Company.sol";

// ----------------- Main -----------------
contract registrateOrganization {
    event Creation(address _org, string _what);
    
    uint public totalAmounOfOrganization;
    address[] public listOfOrg;

//Pay smth to create Company??

    function createCompany(string memory _name) external {
        address newOrg = address(new Company(_name));
        listOfOrg.push(newOrg);
        totalAmounOfOrganization++;

        emit Creation(newOrg, _name);    
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./TokenFuncs.sol";

contract StreamLogic is TokenFuncs {

    // ---------- ERORS ----------
    error Unauthorized();

    // --------- Events ----------
    event StreamCreated(Stream stream);


    /// @dev Parameters for streams
	/// @param sender The address of the creator of the stream
	/// @param recipient The address that will receive the streamed tokens
	/// @param rate How many token pro sec

    struct Stream {
		uint256 rate; //holiday rate
		uint256 startAt; 
        bool active;
		uint32 streamId;
	}

	

    //mapping(address => mapping(uint8 => Stream)) public getStream;  //uint256 internal streamId = 1;
	mapping(address => Stream) public getStream;

	address[] public activeStreamAddress;

	function amountActiveStreams()public view returns(uint){
		return activeStreamAddress.length;
	}

    //------------FUNCS----------
    function startStream(address _recipient, uint256 _rate) public {

		uint32 currentStreamId = getStream[_recipient].streamId;

		Stream memory stream = Stream({
			rate: _rate,
			startAt: block.timestamp,
            active: true,
			streamId: currentStreamId ++
		});


		calculateETF(_rate);

		getStream[_recipient] = stream;

		activeStreamAddress.push(_recipient);

		emit StreamCreated(stream);
	}

	function finishStream(address _who) public returns(uint256){
		require(!getStream[_who].active, "This user doesnt have active stream");
		
		getStream[_who].active = false;
		getStream[_who].startAt = 0;
		
		_removeAddress(_who);

		calculateETFDecrease(getStream[_who].rate);

		// IF Liquidation
		if(getStream[_who].startAt > EFT){
			return currentBalanceLiquidation(_who);
		}

		return currentBalance(_who);

		//DELETE STREAM FROM activeStreamAddress
		
	}
// FUNCTION TO FINISH ALL SREAMS
// FUNCTION IF employee had break


//Math
// 1_000_000 tokens = 1 USDT //Decimals
// 20 USD / hour
// 0.005 USD / sec
// 5_555 WEI / sec
    function currentBalance(address _who) public view returns(uint256){
		require(!getStream[_who].active, "This user doesnt have any active stream");
		uint rate = getStream[_who].rate;
		uint timePassed = block.timestamp - getStream[_who].startAt;
		return rate * timePassed;
	}

	function currentBalanceLiquidation(address _who) public view returns(uint256){
		uint rate = getStream[_who].rate;
		uint timePassed = EFT - getStream[_who].startAt;
		return rate * timePassed;
	}

	function getCurrentBalanceContract()public view returns(uint256){
		// FORMULA => 	Bal - (forloop thru all active streams)
		if(amountActiveStreams() == 0){
			return balanceContract();
		}
		uint snapshotAllTransfer;

		for(uint i = 0; i < activeStreamAddress.length; i++ ){
			snapshotAllTransfer += currentBalance(activeStreamAddress[i]);
		}

		return balanceContract() - snapshotAllTransfer;
	}

	// ----- FUNC to DELETE ELEMENT ADDRESS from activeStreamAddress
	function _indexOf(address searchFor) private view returns (uint256) {
  		for (uint256 i = 0; i < activeStreamAddress.length; i++) {
    		if (activeStreamAddress[i] == searchFor) {
      		return i;
    		}
  		}
  		revert("Not Found");
	}

	function _removeAddress(address _removeAddr) private {

		uint index = _indexOf(_removeAddr);

        if (index > activeStreamAddress.length) return;

        for (uint i = index; i < activeStreamAddress.length-1; i++){
            activeStreamAddress[i] = activeStreamAddress[i+1];
        }
        activeStreamAddress.pop();
    }

    //----------- EFT implementation -------------

	uint public EFT; // enough funds till
	uint public CR; //common rate

	function calculateETF(uint _rate)public {
		// FORMULA	[new stream]	Bal / Rate = secLeft  --> timestamp + sec
		// FORMULA	[add stream]	Bal / Rate = secLeft  --> timestamp + sec
		if(EFT == 0){
			CR += _rate;
			uint sec = balanceContract() / _rate;
			EFT = block.timestamp + sec;
		} else {
			CR += _rate; 
			uint secRecalculate = getCurrentBalanceContract() / CR; 
			EFT = block.timestamp + secRecalculate;
		}
	}

	function calculateETFDecrease(uint _rate)public {
		// FORMULA   ETH += 
			CR -= _rate; 
			uint secRecalculate = getCurrentBalanceContract() / CR; 
			EFT = block.timestamp + secRecalculate;
		}
	

	// Restrtriction to create new Stream (PosibleEFT > StreamDurration of all stream)
	function newStreamCheckETF(uint _rate)public view returns(bool canOpen){
		// FORMULA    nETF > ForLoop startAt + now
		//
		if(amountActiveStreams() == 0) return true;

		// FOR loop thu map
		for(uint i = 0; i < activeStreamAddress.length; i++ ){
			uint  recalEFT = getStream[activeStreamAddress[i]].startAt + block.timestamp;
			if(recalEFT > _calculatePosibleETF(_rate)){
				return false;
			}
		}
	}

	function _calculatePosibleETF(uint _rate) private view returns(uint) {
			uint tempCR = CR + _rate;
			uint secRecalculate = balanceContract() / tempCR; 
			return block.timestamp + secRecalculate;
	}


}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract TokenFuncs {

    ERC20 public token;

    address owner;

    function setToken(address _token) public {
        token = ERC20(_token);
    }

    function balanceContract()public view returns(uint){
        return token.balanceOf(address(this));
    }
    function withdrawTokens()external {
        //add lot restritions
        token.transfer(owner, balanceContract());
    }
}
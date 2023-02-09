//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import { Company } from "./Company.sol";

contract CompanyFactory {

    event Creation(address _org, address _creator, string _what);
  
    address[] public listOfOrg;

    mapping(address=>string) public nameToAddress;

    function createCompany(string memory _name) external returns(address companyAddr){
        address newCompanyAddr = address(new Company(_name, msg.sender));

        listOfOrg.push(newCompanyAddr);

        nameToAddress[newCompanyAddr] = _name;

        emit Creation(newCompanyAddr, msg.sender, _name);

        return  newCompanyAddr;   
    }

    function totalAmounOfComapnies()public view returns(uint _num){
        return listOfOrg.length;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./StreamLogic.sol";

 // ---------- PROBLEMS & TASKS--------------
// Shoud it be tru ProxY? Can we create new contract with proxy?
// Banc Control

contract Company is StreamLogic {

    // ADD EVENTS
    event AddEmployee(address _who, uint _time);
    event StartFlow(address _who, uint _time);

    string public name;
    uint public totalAmountEmployee;

    constructor (string memory _name, address _addressOwner)StreamLogic(_addressOwner){
        name = _name;
    }

    struct Employee{
        address who;
        uint256 flowRate; // 1 token / sec
        bool worker;
        //bool what kind of sallary he s going to get >>> h/$ or $/mounth
    }
    mapping(address => Employee) public allEmployee;

    modifier employeeExists(address _who){
            require(allEmployee[_who].worker, "This employee doesnt exist or deleted already");
            _;
    }

    // ------------------- MAIN FUNC ----------------

    function addEmployee(address _who, uint256 _rate) external ownerOrAdministrator isLiquidationHappaned{
        require(validToAddNew(_rate), "Balance is very low!");
        require(!allEmployee[_who].worker, "You already added!");

           Employee memory newEmployee = Employee({
			who: _who,
			flowRate: _rate,
			worker: true
		});

		allEmployee[_who] = newEmployee;

        totalAmountEmployee++;

        emit AddEmployee(_who, block.timestamp);
    }

    function modifyRate(address _who, uint256 _rate) external employeeExists(_who) ownerOrAdministrator isLiquidationHappaned {
        require(getStream[_who].active, "You can change rate while streaming");
        allEmployee[_who].flowRate = _rate;
    }

    function deleteEmployee(address _who) external employeeExists(_who) ownerOrAdministrator isLiquidationHappaned{
        require(getStream[_who].active, "You can change rate while streaming");
        delete allEmployee[_who];
    }

//-------------------- SECURITY --------------
// Set up all restrictoins tru DAO?

    //Solution #1 (restriction on each stream)
    uint public tokenLimitMaxHoursPerPerson = 20 hours; // Max amount hours of each stream with enough funds;

    function validToStream(address _who)private view returns(bool){
         return (allEmployee[_who].flowRate * tokenLimitMaxHoursPerPerson ) < balanceContract();
    }

   
    // Solution #2 (restriction on all live stream)
    uint public tokenLimitMaxHoursAllStream = 10 hours;

    function validToStreamAll() private view returns(bool){

        if(amountActiveStreams() == 0) return true;

                // IE     400    =        2         *      20     *     10
        uint allStreamLimitToken = amountActiveStreams() * CR * tokenLimitMaxHoursAllStream;

        return allStreamLimitToken < balanceContract();
    }

    // Solution #3 (restriction to add new employee)
     uint public hoursLimitToAddNewEmployee = 10 hours;

     function validToAddNew(uint _newRate)private view returns(bool){

            // IE   900    =        2+1             *         20+10     *    100
        uint tokenLimit = (totalAmountEmployee + 1) * (CR + _newRate) * hoursLimitToAddNewEmployee;

        return tokenLimit < balanceContract();
        //PS "If company doesnt have enought tokens to pay all employee for next 100 hours they can add new employee"
     }

     //---- ADD BUFFER ---------
     // rate / time /  money


// -------------- FUNCS with EMPLOYEEs ----------------
    //@dev Starts streaming token to employee
    function start(address _who) public employeeExists(_who) ownerOrAdministrator isLiquidationHappaned{
        require(validToStream(_who), "Balance is very low");
        require(validToStreamAll(), "Balance is very low for all");

        startStream(_who, allEmployee[_who].flowRate);
    }

    function finish(address _who) public employeeExists(_who) ownerOrAdministrator {
        uint256 salary = finishStream(_who);
        // if(!overWroked){
        //     function ifyouEmployDolboeb()
        // }
        token.transfer(_who, salary);
    }

    // function withdrawEployee()public{
    //     // FUCS abour streaming within existing stream
    // }

// Decimals = 6 | 1 USDC = 1_000_000 tokens
    function getDecimals()public view returns(uint){
        return token.decimals();
    }

    function withdrawTokens()external onlyOwner activeStream isLiquidationHappaned{
        token.transfer(owner, balanceContract());
    }

    function isContractSet()public view returns(bool){
        // Check Token
        // Check Admin?
        // Check amount?
        return validToAddNew(10);
    }

    receive() external payable { }
    fallback() external payable { }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./TokenAdmin.sol";

contract StreamLogic is TokenAdmin {

    // ---------- ERORS ----------
    error Unauthorized();

    // --------- Events ----------
    event StreamCreated(Stream stream);

	event StreamFinished(address who, uint tokenEarned, uint endsAt);

	event Liqudation(address _whoCall);

	constructor(address _owner) TokenAdmin(_owner){}


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

	modifier activeStream(){
            require(amountActiveStreams() == 0, "Active Stream");
            _;
    }

	function amountActiveStreams() public view returns(uint){
		return activeStreamAddress.length;
	}

    //------------ MAIN FUNCS [STREAM]----------
    function startStream(address _recipient, uint256 _rate) internal isLiquidationHappaned{
		require(!getStream[_recipient].active, "This guy already has stream");
		require(newStreamCheckETF(_rate), "Contract almost Liquidated. Check Balance!");
		
		uint32 currentStreamId = getStream[_recipient].streamId + 1;

		Stream memory stream = Stream({
			rate: _rate,
			startAt: block.timestamp,
            active: true,
			streamId: currentStreamId
		});


		calculateETF(_rate);

		getStream[_recipient] = stream;

		activeStreamAddress.push(_recipient);

		emit StreamCreated(stream);
	}

	function finishStream(address _who) internal returns(uint256){
		require(getStream[_who].active, "This user doesnt have an active stream");
		
		uint256 retunrTokenAmount;
		
		// IF Liquidation -> return as much token as employee earned and write in debt list
		if(block.timestamp > EFT){

			addrListDebt.push(_who);
			debtToEmployee[_who] = currentBalanceEmployee(_who) - currentBalanceLiquidation(_who);
			retunrTokenAmount = currentBalanceLiquidation(_who);

			liqudation = true;
			
		} else {
			retunrTokenAmount = currentBalanceEmployee(_who);
		}

		calculateETFDecrease(getStream[_who].rate);
		
		_removeAddress(_who);

		getStream[_who].active = false;
		getStream[_who].startAt = 0;

 		emit StreamFinished(_who, retunrTokenAmount, block.timestamp);
	
		return retunrTokenAmount;
	}

	


	function finishAllStream() public {
		require(amountActiveStreams() == 0, "No active streams!");

	
		if(block.timestamp > EFT){
			// IF Liquidation we send as much token as in SC and write down all debt
			for(uint i = 0; i < activeStreamAddress.length; i++){
				address loopAddr = activeStreamAddress[i];
				addrListDebt.push(loopAddr);
				debtToEmployee[loopAddr] = currentBalanceEmployee(loopAddr) - currentBalanceLiquidation(loopAddr);

				token.transfer(loopAddr, currentBalanceLiquidation(loopAddr));

				getStream[loopAddr].active = false;
				getStream[loopAddr].startAt = 0;
			}

			liqudation = true;

		} else {
			for(uint i = 0; i < activeStreamAddress.length; i++){
				address loopAddr = activeStreamAddress[i];

				token.transfer(loopAddr, currentBalanceEmployee(loopAddr));

				getStream[loopAddr].active = false;
				getStream[loopAddr].startAt = 0;
			}
		}

		activeStreamAddress = new address[](0);

		CR = 0;
		EFT = 0;
	}

// FUNCTION IF employee had break

 	//------------ ADDITION FUNCS [TRANSFER]----------
	// function sendFunds(address _who) public {
	// 	require(msg.sender == getStream[_who], "You are not able to transact");
	// }


		//------------ CHECK BALANCES----------
    function currentBalanceEmployee(address _who) public view returns(uint256){
		if(!getStream[_who].active) return 0;

		uint rate = getStream[_who].rate;
		uint timePassed = block.timestamp - getStream[_who].startAt;
		return rate * timePassed;
	}

	function currentBalanceContract()public view returns(uint256){
		
		if(amountActiveStreams() == 0){
			return balanceContract();
		}
		uint snapshotAllTransfer;

		for(uint i = 0; i < activeStreamAddress.length; i++ ){
			snapshotAllTransfer += currentBalanceEmployee(activeStreamAddress[i]);
		}

		// If liquidation
		if((balanceContract() < snapshotAllTransfer)){
			return 1;
		}

		return  balanceContract() - snapshotAllTransfer;
	}


	function currentBalanceLiquidation(address _who) public view returns(uint256){
		uint rate = getStream[_who].rate;
		uint timePassed = EFT - getStream[_who].startAt;
		return rate * timePassed;
	}

    //-----------  Liquidation  -------------
	modifier isLiquidationHappaned(){
            require(!liqudation, "Liqudation happened!!!");
            _;
    }

	mapping(address => uint) public debtToEmployee;
	address[] public addrListDebt;

	bool public liqudation;


	function _totalDebt() public view returns(uint){
		uint num;
		for(uint i = 0; i < addrListDebt.length; i++){
				num += debtToEmployee[addrListDebt[i]];
		}
		return num;
	}


	function finishLiqudation() public activeStream{
		require(liqudation, "Liqudation did not happen");
	    require(balanceContract() >= _totalDebt(), "Not enough funds to pay debt back");

		if(addrListDebt.length != 0){

				for(uint i = 0; i < addrListDebt.length; i++){

				token.transfer(addrListDebt[i], debtToEmployee[addrListDebt[i]]);

				debtToEmployee[addrListDebt[i]] = 0;
			}
		}

		activeStreamAddress = new address[](0);

		liqudation = false;
	}



    //-----------SECURITY [EFT implementation] -------------

	uint public EFT; // enough funds till
	uint public CR; //common rate

	function calculateETF(uint _rate)public {
		// FORMULA	[new stream]	Bal / Rate = secLeft  --> timestamp + sec
		if(EFT == 0){
			CR += _rate;
			uint sec = balanceContract() / _rate;
			EFT = block.timestamp + sec;
		} else {
			CR += _rate; 
			uint secRecalculate = currentBalanceContract() / CR; // IF liqudation noone can create new stream so cant reach here
			EFT = block.timestamp + secRecalculate;
		}
	}

	function calculateETFDecrease(uint _rate)private {

		// If Liqudation 
		if(currentBalanceContract() <= 1){
			return;
		} else if((amountActiveStreams() -1) == 0){
			// -1 because we remove address from arr before call this func
			// IF there was the last employee we reset the whole num
			EFT = 0;
			return;
		}else {
			uint secRecalculate = currentBalanceContract() / CR; 
			CR -= _rate; 
			EFT = block.timestamp + secRecalculate;
		}
	}
	

	// Restrtriction to create new Stream (PosibleEFT < Now)
	uint16 minDelayToOpen = 5 minutes;

	function newStreamCheckETF(uint _rate)public view returns(bool canOpen){
		// FORMULA    nETF > ForLoop startAt + now
		//
		if(amountActiveStreams() == 0) return true;

		if((block.timestamp + minDelayToOpen) > _calculatePosibleETF(_rate)){
				return false;
		}

		return true;
	}

	function _calculatePosibleETF(uint _rate) private view returns(uint) {
			uint tempCR = CR + _rate;
			uint secRecalculate = balanceContract() / tempCR; 
			return block.timestamp + secRecalculate;
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

        for (uint i = index; i < activeStreamAddress.length -1; i++){
            activeStreamAddress[i] = activeStreamAddress[i+1];
        }
        activeStreamAddress.pop();
    }
}

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract TokenAdmin {

    ERC20 public token;

    function setToken(address _token) public {
        token = ERC20(_token);
    }

    function balanceContract()public view returns(uint){
        return token.balanceOf(address(this));
    }

// -------------- Access roles ---------------
    address public owner;

    address public administrator;

    constructor(address _owner){
        owner = _owner;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "You are not an owner!");
        _;
    }

    modifier ownerOrAdministrator(){
        require(owner == msg.sender || administrator == msg.sender, "You are not an owner!");
        _;
    }


    function sendOwnership(address _newOwner) external onlyOwner{
        owner = _newOwner;
    }

    function changeAdmin(address _newAdmin) external ownerOrAdministrator{
        administrator = _newAdmin;
    }

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
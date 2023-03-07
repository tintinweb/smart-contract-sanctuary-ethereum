// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/// @author Chubiduresel 
/// @title Library to find an address in array and delete
library ArrayLib{
    
    function removeAddress(address[]storage _arr, address _removeAddr) internal {

		uint indexAddr = _indexOf(_arr, _removeAddr);

        for (uint i = indexAddr; i < _arr.length -1; i++){
            _arr[i] = _arr[i+1];
        }
        _arr.pop();
    }
 
	function _indexOf(address[]storage _arr, address searchFor) internal view returns (uint256) {
  		for (uint256 i = 0; i < _arr.length; i++) {
    		if (_arr[i] == searchFor) {
      		return i;
    		}
  		}
  		revert("Not Found");
	}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./StreamLogic.sol";
import "./ArrayLib.sol";
import "./Outsource.sol";


contract Company is StreamLogic, OutsourceTask, Initializable{

	using ArrayLib for address[];

    function avalibleBalanceContract()public override(TokenAdmin, OutsourceTask) view returns(uint){
        return super.avalibleBalanceContract();
    }
    function currentBalanceContract()public override(StreamLogic, TokenAdmin) view returns(uint){
        return super.currentBalanceContract();
    }

    // ADD EVENTS
    event AddEmployee(address _who, uint _rate, uint when);
    event WithdrawEmpl(address who, uint tokenEarned, uint when);

    string public name;

    function initialize(string memory _name, address _owner) public initializer {
        name = _name;
        owner = _owner;
        tokenLimitMaxHoursPerPerson = 10 hours;
    }

    // constructor (string memory _name, address _addressOwner)StreamLogic(_addressOwner){
    //     name = _name;
    // }

    struct Employee{
        address who;
        uint256 flowRate; // 1 token / sec
        bool worker;
    }

    mapping(address => Employee) public allEmployee;

    address[] public allEmployeeList;

    function amountEmployee() public view returns(uint){
        return allEmployeeList.length;
    }

    modifier employeeExists(address _who){
            require(allEmployee[_who].worker, "This employee doesnt exist or deleted already");
            _;
    }

	/**
     * @notice Create Employee profile
     * @param _who The employee address
     * @param _rate The employee`s rate. token pro sec
     */	
    function addEmployee(address _who, uint256 _rate) external ownerOrAdministrator isLiquidationHappaned{
        //require(validToAddNew(_rate), "Balance is very low!");
        require(!allEmployee[_who].worker, "You already added!");

           Employee memory newEmployee = Employee({
			who: _who,
			flowRate: _rate,
			worker: true
		});

		allEmployee[_who] = newEmployee;

        allEmployeeList.push(_who);

        //commonRateAllEmployee += _rate;

        emit AddEmployee(_who, _rate, block.timestamp);
    }


    function modifyRate(address _who, uint256 _rate) external employeeExists(_who) ownerOrAdministrator isLiquidationHappaned {
        if(getStream[_who].active) revert NoActiveStream();
        allEmployee[_who].flowRate = _rate;
    }

    function deleteEmployee(address _who) external employeeExists(_who) ownerOrAdministrator isLiquidationHappaned{
        if(getStream[_who].active) revert NoActiveStream();

        //commonRateAllEmployee -= getStream[_who].rate;

        allEmployeeList.removeAddress(_who);
    }

//-------------------- SECURITY / BUFFER --------------
// Set up all restrictoins tru DAO?

    // -------- Solution #1 (restriction on each stream)
    uint public tokenLimitMaxHoursPerPerson; // Max amount hours of each stream with enough funds;

    function validToStream(address _who)private view returns(bool){
         return  getTokenLimitToStreamOne(_who) < currentBalanceContract();
    }

    function getTokenLimitToStreamOne(address _who)public view returns(uint){
        return allEmployee[_who].flowRate * tokenLimitMaxHoursPerPerson;
    }

   function setHLStartStream(uint _newLimit) external activeStream ownerOrAdministrator{
    //     // How can set this func? Mini DaO?
        tokenLimitMaxHoursPerPerson = _newLimit;
    }

    // -------------- FUNCS with EMPLOYEEs ----------------

    ///@dev Starts streaming token to employee (check StreamLogic)
    function start(address _who) external employeeExists(_who) ownerOrAdministrator isLiquidationHappaned{
        require(validToStream(_who), "Balance is very low");

        startStream(_who, allEmployee[_who].flowRate);
    }

    function finish(address _who) external employeeExists(_who) ownerOrAdministrator {
        uint256 salary = finishStream(_who);
        // if(!overWroked){
        //     function ifyouEmployDolboeb()
        // }
        token.transfer(_who, salary);
    }

    function withdrawEmployee()external employeeExists(msg.sender) {
         uint256 salary = _withdrawEmployee(msg.sender);

        token.transfer(msg.sender, salary);
        
        emit WithdrawEmpl(msg.sender, salary, block.timestamp);
    }


    function getDecimals()public view returns(uint){
        return token.decimals();
    }

    function withdrawTokens()external onlyOwner activeStream isLiquidationHappaned{
        token.transfer(owner, balanceContract());
    }

    function supportFlowaryInterface()public pure returns(bool){
        return true;
    }

    //-------DEV-------
    function version()public pure returns(string memory){
        return "V 0.3.0";
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./TokenAdmin.sol";

error UnAuthorized();
error PassedDeadLine();
error NotEnoughFunds();

abstract contract OutsourceTask is TokenAdmin {

    struct Outsource{
        string task;
        address who;
        uint256 startAt;
        uint256 deadline;
        uint256 wage; //10
        uint256 amountWithdraw; //-= 4.9
        uint8 bufferPercentage;
        Status status;
    }

    enum Status {None, Active, ClaimDone, Finished}

    uint public OutsourceID;
    
    mapping(uint=>Outsource) public listOutsource;

    // uint[]public activeOutsource;

    function createOutsourceJob(address _who, string calldata _task, uint _wage, uint _deadline, uint8 _bufferOn) public {
         if(currentBalanceContract() < _wage) revert NotEnoughFunds();
        	
        Outsource memory newJob = Outsource({
			task: _task,
            who: _who,
            startAt: block.timestamp,
            deadline: block.timestamp + _deadline,
            wage: _wage,
            amountWithdraw: 0,
            bufferPercentage: _bufferOn,
            status: Status.Active
		});

        listOutsource[OutsourceID] = newJob;

        OutsourceID++;

        fundsLocked += _wage;
    }

    function withdrawFreelancer(uint _id)external{
        require(listOutsource[_id].status == Status.Active, "Ops, u do not have an active Job");
        if(listOutsource[_id].who != msg.sender) revert UnAuthorized();

        uint amountEarned;
        uint curBalance = currentBal(_id);
        uint withdraw = listOutsource[_id].amountWithdraw;

        if(calculateBuffer(curBalance, listOutsource[_id].bufferPercentage) < withdraw){
            return;
        }

        if(listOutsource[_id].bufferPercentage > 0){

            amountEarned = calculateBuffer(curBalance, listOutsource[_id].bufferPercentage) - withdraw; 
        
        } else {
            amountEarned = curBalance - withdraw;
        }

        token.transfer(listOutsource[_id].who, amountEarned); //7$ => 4,9$ // 1$ 

        listOutsource[_id].amountWithdraw += amountEarned; // 5.1

        fundsLocked -= amountEarned;
    }




    //FUNC to set it
    // Func to calculate withdraw for Freelancer



    //------------------------  VERIFICATION --------------------
    event ClaimDone(address _who, string _result);

    function claimFinish(uint _id, string calldata linkToResult)public{
        if(listOutsource[_id].who != msg.sender) revert UnAuthorized();

        if(listOutsource[_id].deadline > block.timestamp){
            listOutsource[_id].wage / 2; // FIX THIS!!!!!!!!!!!!!! 
        } 

        listOutsource[_id].status = Status.ClaimDone;

        emit ClaimDone(msg.sender, linkToResult);
    }

    function finishOutsource(uint _id) public {
        //CHECk: 1.Claimed?
        //       2. DeadLine

        uint pay = listOutsource[_id].wage - listOutsource[_id].amountWithdraw;

        listOutsource[_id].status = Status.Finished;

        token.transfer(listOutsource[_id].who, pay);

        if(fundsLocked <= pay){
            fundsLocked = 0;
        } else{
            fundsLocked -= pay;
        }
        
    }

    //-------------------------------  LOCKED FUNDS ---------------------
        // ------------------------- BALANCE ------------------
    uint public fundsLocked;

    function avalibleBalanceContract()public override virtual view returns(uint){
        return token.balanceOf(address(this)) - fundsLocked;
    }

    function currentBal(uint _id)public view returns(uint){
        //FORMULA   (Wage / (DeadLine - StartAt)) == FLOWRATE  >>>> Now - Start * Rate
        // 5h and 100$ >> 1h = 20$

            // 0.1 $ /sec
        uint rate =  listOutsource[_id].wage / (listOutsource[_id].deadline - listOutsource[_id].startAt);   
        return (block.timestamp - listOutsource[_id].startAt) * rate;
    }

        //------------------------  BUFFER --------------------


    function calculateBuffer(uint amount, uint8 percentageBuffer) private pure returns(uint){

         return amount - ((amount *  percentageBuffer) / 100);
                        //  7    -    (7    *    30) / 100

        // - 30%  >>> 3$ BUFFER
       // 10$ for 1h => in 45min he`s got 7$ - 21%  => return 7 * 0.21 = 1.47

       // 7 / 10 = 0.7(EARNED$) * 0.7(70%FIXED) = 0.49 |||   0.49 * 10$ = 4.9$

       // 3 / 10 = 0.3 * 0.7 = 0.21  |||  0.21 * 10$ = 2.1$ 
    }
    
        //------------------------  CANCEL --------------------
    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./TokenAdmin.sol";
import "./ArrayLib.sol";

error NoActiveStream();

/// @author Chubiduresel 
/// @title Stream logic and Liquidation
abstract contract StreamLogic is TokenAdmin {

	using ArrayLib for address[];

    // --------- Events ----------
    event StreamCreated(Stream stream);
	event StreamFinished(address who, uint tokenEarned, uint endsAt, uint startedAt);
	event Liqudation(address _whoCall);

    /// @notice Parameters of stream object
	/// @param rate Employee rate (Token / second)
	/// @param startAt Block.timestamp when employee start streaming
	/// @param active Active stream
	/// @param streamId Amount of stream 
    struct Stream {
		uint256 rate; 
		uint256 startAt; 
        bool active;
		uint32 streamId;
	}

	mapping(address => Stream) public getStream;

	address[] public activeStreamAddress;

	modifier activeStream(){
            require(amountActiveStreams() == 0, "Active Stream");
            _;
    }

	function amountActiveStreams() public view returns(uint){
		return activeStreamAddress.length;
	}

	/**
     * @notice Create new stream 
     * @dev Function is called from the company contract
     * @param _recipient The employee address
     * @param _rate The rate of employee (Token / second)
     */
    function startStream(address _recipient, uint256 _rate) internal isLiquidationHappaned{
		require(!getStream[_recipient].active, "This dude already has stream");
		//require(newStreamCheckETF(_rate), "Contract almost Liquidated. Check Balance!");
		
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

	/**
     * @notice Finish stream 
     * @dev Function is called from the company contract.
	 If time passed ETF deadline, contract call turn into Liqudation mode.
	 Employee recieves all token from contract, if it doesnt cover all money he earned, 
	 the rest will be written in debtToEmployee mapping, and pay out as soon as company
	 pop up balace and call function finishLiqudation()
     * @param _who The employee address
     */
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
		
		activeStreamAddress.removeAddress(_who);

		emit StreamFinished(_who, retunrTokenAmount, block.timestamp, getStream[_who].startAt);

		getStream[_who].active = false;
		getStream[_who].startAt = 0;
		
	
		return retunrTokenAmount;
	}

	/// @notice Finish all active streams
	/// @dev This function is called from outside
	/// @dev Reset ETF and CR to Zero and delete all streams from the list
	
	// function finishAllStream() public {
	// 	if(amountActiveStreams() == 0) revert NoActiveStream();

	
	// 	if(block.timestamp > EFT){
	// 		// IF Liquidation we send as much token as in SC and write down all debt
	// 		for(uint i = 0; i < activeStreamAddress.length; i++){
	// 			address loopAddr = activeStreamAddress[i];
	// 			addrListDebt.push(loopAddr);
	// 			debtToEmployee[loopAddr] = currentBalanceEmployee(loopAddr) - currentBalanceLiquidation(loopAddr);

	// 			token.transfer(loopAddr, currentBalanceLiquidation(loopAddr));

	// 			getStream[loopAddr].active = false;
	// 			getStream[loopAddr].startAt = 0;
	// 		}

	// 		liqudation = true;

	// 	} else {
	// 		for(uint i = 0; i < activeStreamAddress.length; i++){
	// 			address loopAddr = activeStreamAddress[i];

	// 			token.transfer(loopAddr, currentBalanceEmployee(loopAddr));

	// 		     emit StreamFinished(loopAddr, currentBalanceEmployee(loopAddr), block.timestamp, getStream[loopAddr].startAt);

	// 			getStream[loopAddr].active = false;
	// 			getStream[loopAddr].startAt = 0;
	// 		}
	// 	}

	// 	activeStreamAddress = new address[](0);

	// 	CR = 0;
	// 	EFT = 0;
	// }

	function _withdrawEmployee(address _who) internal returns(uint){
		//require(getStream[_who].active, "This user doesnt have an active stream");
		if(!getStream[_who].active) revert NoActiveStream();

		uint tokenEarned = currentBalanceEmployee(_who);

		getStream[_who].startAt = block.timestamp;

		return tokenEarned;
	}

	//------------ CHECK BALANCES----------
	/**
     * @notice Check employee`s balance 
     * @param _who The employee address
     * @return amount of token that employee earns at moment this function is called
     */	
    function currentBalanceEmployee(address _who) public view returns(uint256){
		if(!getStream[_who].active) return 0;

		uint rate = getStream[_who].rate;
		uint timePassed = block.timestamp - getStream[_who].startAt;
		return rate * timePassed;
	}
	/// @notice Check company`s balance
	/// @dev If it returns 1, it means that contract doesnt have enough funds to pay for all streams (Liquidation)
    /// @return amount of token thet company posses at the moment this function is called
	function currentBalanceContract()public view virtual override returns(uint256){
	
		if(amountActiveStreams() == 0){
			return avalibleBalanceContract();
		}
		uint snapshotAllTransfer;

		for(uint i = 0; i < activeStreamAddress.length; i++ ){
			snapshotAllTransfer += currentBalanceEmployee(activeStreamAddress[i]);
		}

		// If liquidation
		if((avalibleBalanceContract() < snapshotAllTransfer)){
			return 1;
		}

		return  avalibleBalanceContract() - snapshotAllTransfer;
	}

  //------------ LIQUIDATION ----------
	/**
     * @notice Check employee`s debt balance
     * @param _who The employee address
     * @return amount of token that company owns to the employee
     */	
	function currentBalanceLiquidation(address _who) public view returns(uint256){
		uint rate = getStream[_who].rate;
		uint timePassed = EFT - getStream[_who].startAt;
		return rate * timePassed;
	}

	modifier isLiquidationHappaned(){
            require(!liqudation, "Liqudation happened!!!");
            _;
    }

	mapping(address => uint) public debtToEmployee;

	address[] public addrListDebt;

	bool public liqudation;

	///@notice Calculate the total amount of debt for the company
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
			CR = 0;
			EFT = 0;
			return;
		}else {
			uint secRecalculate = currentBalanceContract() / CR; 
			CR -= _rate; 
			EFT = block.timestamp + secRecalculate;
		}
	}
	
	// Restrtriction to create new Stream (PosibleEFT < Now)
	// uint16 minDelayToOpen = 5 minutes;

	// function newStreamCheckETF(uint _rate)public view returns(bool canOpen){
	// 	// FORMULA    nETF > ForLoop startAt + now
	// 	//
	// 	if(amountActiveStreams() == 0) return true;

	// 	if((block.timestamp + minDelayToOpen) > _calculatePosibleETF(_rate)){
	// 			return false;
	// 	}

	// 	return true;
	// }

	// function _calculatePosibleETF(uint _rate) private view returns(uint) {
	// 		uint tempCR = CR + _rate;
	// 		uint secRecalculate = balanceContract() / tempCR; 
	// 		return block.timestamp + secRecalculate;
	// }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

abstract contract TokenAdmin {

    IERC20 public token;

    function setToken(address _token) public {
        token = IERC20(_token);
    }

    function balanceContract()public view returns(uint){
        return token.balanceOf(address(this));
    }

    function avalibleBalanceContract()public virtual view returns(uint){ }

    function currentBalanceContract()public virtual view returns(uint){ }

// -------------- Access roles ---------------
    address public owner;

    address public administrator;

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
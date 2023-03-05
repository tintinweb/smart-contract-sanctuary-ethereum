//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./StreamLogic.sol";
import "./ArrayLib.sol";
import "./Outsource.sol";

contract Company is StreamLogic, OutsourceTask {

	using ArrayLib for address[];

    function avalibleBalanceContract()public override(TokenAdmin, OutsourceTask) view returns(uint){
        return token.balanceOf(address(this)) - fundsLocked; // super
    }

    // ADD EVENTS
    event AddEmployee(address _who, uint _rate, uint when);
    event WithdrawEmpl(address who, uint tokenEarned, uint when);

    string public name;

    constructor (string memory _name, address _addressOwner)StreamLogic(_addressOwner){
        name = _name;
    }

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
    uint public tokenLimitMaxHoursPerPerson = 10 hours; // Max amount hours of each stream with enough funds;

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
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/// @author Chubiduresel 
/// @title Library to find an address in array and delete
library ArrayLib{
    
    function removeAddress(address[]storage _arr, address _removeAddr) public {

		uint indexAddr = _indexOf(_arr, _removeAddr);

        for (uint i = indexAddr; i < _arr.length -1; i++){
            _arr[i] = _arr[i+1];
        }
        _arr.pop();
    }
 
	function _indexOf(address[]storage _arr, address searchFor) private view returns (uint256) {
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

	constructor(address _owner) TokenAdmin(_owner){}

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

import "./TokenAdmin.sol";

error UnAuthorized();
error PassedDeadLine();

abstract contract OutsourceTask is TokenAdmin {

    struct Outsource{
        string task;
        address who;
        uint256 startAt;
        uint256 deadline;
        uint256 wage; //10
        uint256 amountWithdraw; //-= 4.9
        bool bufferOn;
        Status status;
    }

    enum Status {None, Active, ClaimDone, Finished}

    uint public id;
    
    mapping(uint=>Outsource) public listOutsource;

    // uint[]public activeOutsource;

    function createOutsourceJob(address _who, string calldata _task, uint _wage, uint _deadline, bool _bufferOn) public {
        //REQUIRE bal>salary
        Outsource memory newJob = Outsource({
			task: _task,
            who: _who,
            startAt: block.timestamp,
            deadline: block.timestamp + _deadline,
            wage: _wage,
            amountWithdraw: 0,
            bufferOn: _bufferOn,
            status: Status.Active
		});

        listOutsource[id] = newJob;

        id++;

        fundsLocked += _wage;
    }

    function withdrawFreelancer(uint _id)external{
        require(listOutsource[_id].status == Status.Active, "Ops, u do not have an active Job");
        if(listOutsource[_id].who != msg.sender) revert UnAuthorized();

        uint amountEarned;

        if(listOutsource[_id].bufferOn){

            amountEarned = calculateBuffer(currentBal(_id)) - listOutsource[_id].amountWithdraw; 
        
        } else {
            amountEarned = currentBal(_id);
        }

        token.transfer(listOutsource[_id].who, amountEarned); //7$ => 4,9$ // 1$ 

        listOutsource[_id].amountWithdraw += amountEarned; // 5.1

        fundsLocked -= amountEarned;
    }


    //------------------------  BUFFER --------------------

    uint8 public percentageBuffer = 30; 
                                    //70

    function setpercentBuffer(uint8 _newBuffer) internal {
        require(_newBuffer < 70, "You cant set beffer more then 70%");
        percentageBuffer = _newBuffer;
    }

    function calculateBuffer(uint amount) private view returns(uint){

         return amount - ((amount *  percentageBuffer) / 100);
                        //  7    -    (7    *    30) / 100


        // - 30%  >>> 3$ BUFFER
       // 10$ for 1h => in 45min he`s got 7$ - 21%  => return 7 * 0.21 = 1.47

       // 7 / 10 = 0.7(EARNED$) * 0.7(70%FIXED) = 0.49 |||   0.49 * 10$ = 4.9$

       // 3 / 10 = 0.3 * 0.7 = 0.21  |||  0.21 * 10$ = 2.1$ 
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

        //------------------------  CANCEL --------------------
        
        // FUNC for Boss >> we keep Buffer
    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract TokenAdmin {

    IERC20 public token;

    function setToken(address _token) public {
        token = IERC20(_token);
    }

    function balanceContract()public view returns(uint){
        return token.balanceOf(address(this));
    }

    function avalibleBalanceContract()public virtual view returns(uint){
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
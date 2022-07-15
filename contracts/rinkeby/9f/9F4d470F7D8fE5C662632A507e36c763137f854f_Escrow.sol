//SPDX-License-Identifier: Unlicense
pragma solidity >=0.4.22 <=0.8.4;

import "./console.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./SafeMath.sol";
// Defining a Contract
contract Escrow {

	using Counters for Counters.Counter;
	Counters.Counter private _taskIdTracker;
	using SafeMath for uint256;

	uint public fee;
	enum State {
		STARTED,
		FUNDED,
		DELIVERIED,
		COMPLETE
	}
	struct DepositType{
		address coinAddress;
		uint256 amount;
	}

	struct Partnership{
		address sender;
		address receiver;
	}

	// taskId => mapping (sender => DepositType);
	mapping (uint256 => mapping (address => DepositType)) public clientWithCurrency ;
	mapping (uint256 => mapping (address => uint256)) public clientWithBNB ;
	// mapping (taskId => state);
	mapping (uint256 => State ) public stateOfTaskId;
	mapping (uint256 => Partnership) public partnershipOfTaskId;
	// Defining a enumerator 'State'
	modifier requiresFee() {
      require(msg.value >= fee, "Not enough value.");
        _;
	}

	modifier isStarted(uint256 taskId) {
		require(stateOfTaskId[taskId] == State.STARTED, "Only started");
		_;
	}

	modifier isFunded(uint256 taskId) {
		require(stateOfTaskId[taskId] == State.FUNDED, "Only funded");
		_;
	}

	modifier onlySender(uint256 _taskId) {
		require(partnershipOfTaskId[_taskId].sender == msg.sender, "Only sender");
		_;
	}

	modifier onlyReceiver(uint256 _taskId) {
		require(partnershipOfTaskId[_taskId].receiver == msg.sender, "Only receiver");
		_;
	}

	event SetDelivery(uint256 indexed taskId, address indexed sender);
	event WithdrawBysender(uint256 indexed taskId, address indexed sender);
	event WithdrawByreceiver(uint256 indexed taskId, address indexed sender);
	event Complete(uint256 indexed taskId);

	function startTask(address _receiver) external {
		_taskIdTracker.increment();
		Partnership memory partner = Partnership(msg.sender, _receiver);
		uint256 newTaskId = _taskIdTracker.current();
		partnershipOfTaskId[newTaskId] = partner;
		stateOfTaskId[newTaskId] = State.STARTED;
	}

	function setDeliveried(uint256 _taskId) external onlySender(_taskId) {
		stateOfTaskId[_taskId] = State.DELIVERIED;
		emit SetDelivery(_taskId, msg.sender);
	}

	function depositWithCurrency(uint256 _taskId, DepositType memory _depositAmount) external isStarted(_taskId) {
		require(IERC20(_depositAmount.coinAddress).balanceOf(msg.sender) > _depositAmount.amount, "Not enough balance");
		IERC20(_depositAmount.coinAddress).transfer(address(this), _depositAmount.amount);
		clientWithCurrency[_taskId][msg.sender] = _depositAmount;
		stateOfTaskId[_taskId] = State.FUNDED;
	}

	function depositWithBNB(uint256 _taskId) external isStarted(_taskId) payable {
		require(msg.value > 0, "Not zero");
		require((msg.sender).balance > msg.value, "Not enough balance");
		clientWithBNB[_taskId][msg.sender] = msg.value;
		stateOfTaskId[_taskId] = State.FUNDED;
	}

	function withdrawBysender(uint256 _taskId) external isFunded(_taskId) onlySender(_taskId) {
		require(stateOfTaskId[_taskId] != State.DELIVERIED, "Only deliveried");
		if (clientWithBNB[_taskId][msg.sender] != 0)
			payable(msg.sender).transfer(clientWithBNB[_taskId][msg.sender].sub(fee));
		else IERC20(clientWithCurrency[_taskId][msg.sender].coinAddress)
				.transfer(msg.sender, clientWithCurrency[_taskId][msg.sender].amount);

		emit WithdrawBysender(_taskId, msg.sender);
	}

	function withdrawByreceiver(uint256 _taskId) external onlyReceiver(_taskId) {
		require(stateOfTaskId[_taskId] == State.DELIVERIED, "Only deliveried");
		address sender = partnershipOfTaskId[_taskId].sender;
		if (clientWithBNB[_taskId][msg.sender] != 0)
			payable(msg.sender).transfer(clientWithBNB[_taskId][sender].sub(fee));
		else IERC20(clientWithCurrency[_taskId][sender].coinAddress)
				.transfer(msg.sender, clientWithCurrency[_taskId][sender].amount);

		stateOfTaskId[_taskId] = State.COMPLETE;

		emit Complete(_taskId);
		emit WithdrawByreceiver(_taskId, msg.sender);

	}

}
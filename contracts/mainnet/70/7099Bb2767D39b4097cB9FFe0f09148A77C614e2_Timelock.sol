// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

// COPIED FROM https://github.com/pickle-finance/protocol/blob/master/src/governance/timelock.sol

// Ctrl+f for XXX to see all the modifications.

// XXX: pragma solidity 0.6.12;

contract Timelock {
	event NewAdmin(address indexed newAdmin);
	event NewPendingAdmin(address indexed newPendingAdmin);
	event NewDelay(uint256 indexed newDelay);
	event CancelTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);
	event ExecuteTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);
	event QueueTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

	uint256 public constant GRACE_PERIOD = 14 days;
	uint256 public constant MINIMUM_DELAY = 12 hours;
	uint256 public constant MAXIMUM_DELAY = 30 days;

	address public admin;
	address public pendingAdmin;
	uint256 public delay;
	bool public admin_initialized;

	mapping(bytes32 => bool) public queuedTransactions;

// XXX: constructor(address admin_, uint256 delay_) public {
	constructor(address admin_, uint256 delay_)  {
		require(
			delay_ >= MINIMUM_DELAY,
			"Timelock::constructor: Delay must exceed minimum delay."
		);
		require(
			delay_ <= MAXIMUM_DELAY,
			"Timelock::constructor: Delay must not exceed maximum delay."
		);

		admin = admin_;
		delay = delay_;
		admin_initialized = false;
	}

	receive() external payable {}

	function setDelay(uint256 delay_) public {
		require(
			msg.sender == address(this),
			"Timelock::setDelay: Call must come from Timelock."
		);
		require(
			delay_ >= MINIMUM_DELAY,
			"Timelock::setDelay: Delay must exceed minimum delay."
		);
		require(
			delay_ <= MAXIMUM_DELAY,
			"Timelock::setDelay: Delay must not exceed maximum delay."
		);
		delay = delay_;

		emit NewDelay(delay);
	}

	function acceptAdmin() public {
		require(
			msg.sender == pendingAdmin,
			"Timelock::acceptAdmin: Call must come from pendingAdmin."
		);
		admin = msg.sender;
		pendingAdmin = address(0);

		emit NewAdmin(admin);
	}

	function setPendingAdmin(address pendingAdmin_) public {
		// allows one time setting of admin for deployment purposes
		if (admin_initialized) {
			require(
				msg.sender == address(this),
				"Timelock::setPendingAdmin: Call must come from Timelock."
			);
		} else {
			require(
				msg.sender == admin,
				"Timelock::setPendingAdmin: First call must come from admin."
			);
			admin_initialized = true;
		}
		pendingAdmin = pendingAdmin_;

		emit NewPendingAdmin(pendingAdmin);
	}

	function queueTransaction(
		address target,
		uint256 value,
		string memory signature,
		bytes memory data,
		uint256 eta
	) public returns (bytes32) {
		require(
			msg.sender == admin,
			"Timelock::queueTransaction: Call must come from admin."
		);
		require(
			// XXX: eta >= getBlockTimestamp().add(delay),
			eta >= getBlockTimestamp() + delay,
			"Timelock::queueTransaction: Estimated execution block must satisfy delay."
		);

		bytes32 txHash = keccak256(
			abi.encode(target, value, signature, data, eta)
		);
		queuedTransactions[txHash] = true;

		emit QueueTransaction(txHash, target, value, signature, data, eta);
		return txHash;
	}

	function cancelTransaction(
		address target,
		uint256 value,
		string memory signature,
		bytes memory data,
		uint256 eta
	) public {
		require(
			msg.sender == admin,
			"Timelock::cancelTransaction: Call must come from admin."
		);

		bytes32 txHash = keccak256(
			abi.encode(target, value, signature, data, eta)
		);
		queuedTransactions[txHash] = false;

		emit CancelTransaction(txHash, target, value, signature, data, eta);
	}

	function executeTransaction(
		address target,
		uint256 value,
		string memory signature,
		bytes memory data,
		uint256 eta
	) public payable returns (bytes memory) {
		require(
			msg.sender == admin,
			"Timelock::executeTransaction: Call must come from admin."
		);

		bytes32 txHash = keccak256(
			abi.encode(target, value, signature, data, eta)
		);
		require(
			queuedTransactions[txHash],
			"Timelock::executeTransaction: Transaction hasn't been queued."
		);
		require(
			getBlockTimestamp() >= eta,
			"Timelock::executeTransaction: Transaction hasn't surpassed time lock."
		);
		require(
			// XXX: getBlockTimestamp() <= eta.add(GRACE_PERIOD),
			getBlockTimestamp() <= eta + GRACE_PERIOD,
			"Timelock::executeTransaction: Transaction is stale."
		);

		queuedTransactions[txHash] = false;

		bytes memory callData;

		if (bytes(signature).length == 0) {
			callData = data;
		} else {
			callData = abi.encodePacked(
				bytes4(keccak256(bytes(signature))),
				data
			);
		}

		// solium-disable-next-line security/no-call-value
		(bool success, bytes memory returnData) = target.call{ value: value }(
			callData
		);
		require(
			success,
			"Timelock::executeTransaction: Transaction execution reverted."
		);

		emit ExecuteTransaction(txHash, target, value, signature, data, eta);

		return returnData;
	}

	function getBlockTimestamp() internal view returns (uint256) {
		// solium-disable-next-line security/no-block-members
		return block.timestamp;
	}
}
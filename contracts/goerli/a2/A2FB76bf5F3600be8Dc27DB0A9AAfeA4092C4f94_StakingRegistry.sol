// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

interface IStakingRegistry {
	function setCaller(address _caller, bool _value) external;

	function assignOwnerToContract(
		address _stakingContract,
		address _owner,
		address _previousOwner
	) external;
}

contract StakingRegistry is IStakingRegistry {
	address public controller;

	mapping(address => bool) public authorisedCallers;
	mapping(address => address) public contractToOwner;
	mapping(address => address[]) public ownerToContracts;

	constructor() {
		controller = msg.sender;
	}

	event NewStakingContractOwner(
		address indexed stakingContract,
		address indexed newOwner,
		address indexed previousOwner
	);

	event ControllerUpdated(
		address indexed newController
	);

	event CallerUpdated(
		address indexed newCaller,
		bool newValue
	);

	modifier onlyController() {
		_onlyController();
		_;
	}

	function _onlyController() private view {
		require(msg.sender == controller, "StakingRegistry: Not controller.");
	}

	modifier onlyCaller() {
		_onlyCaller();
		_;
	}

	function _onlyCaller() private view {
		require(
			authorisedCallers[msg.sender] || msg.sender == controller,
			"StakingRegistry: Unauthorised caller."
		);
	}

	function contractCountPerOwner(address _owner)
		external
		view
		returns (uint256)
	{
		return ownerToContracts[_owner].length;
	}

	function setController(address _newController) public onlyController {
		require(_newController != address(0), "Invalid address");
		controller = _newController;
		emit ControllerUpdated(controller);
	}

	function setCaller(address _caller, bool _value)
		public
		override
		onlyCaller
	{
		authorisedCallers[_caller] = _value;
		emit CallerUpdated(_caller, _value);
	}

	function assignOwnerToContract(
		address _stakingContract,
		address _owner,
		address _previousOwner
	) public override onlyCaller {
		require(
			contractToOwner[_stakingContract] == _previousOwner,
			"Registry: previous owner is not owner of staking contract."
		);
		if (_previousOwner != address(0)) {
			address[] storage prevOwnerContracts =
				ownerToContracts[_previousOwner];
			(uint256 oldIndex, bool exists) =
				getIndexArray(prevOwnerContracts, _stakingContract);
			if (exists) {
				prevOwnerContracts[oldIndex] = prevOwnerContracts[
					prevOwnerContracts.length - 1
				];
				prevOwnerContracts.pop();
			}
		}
		uint256 index = ownerToContracts[_owner].length;
		contractToOwner[_stakingContract] = _owner;
		ownerToContracts[_owner].push(_stakingContract);
		emit NewStakingContractOwner(_stakingContract, _owner, _previousOwner);
	}

	function getIndexArray(address[] memory _array, address value)
		public
		pure
		returns (uint256, bool)
	{
		for (uint256 i = 0; i < _array.length; i++)
			if (value == _array[i]) return (i, true);
		return (0, false);
	}
}
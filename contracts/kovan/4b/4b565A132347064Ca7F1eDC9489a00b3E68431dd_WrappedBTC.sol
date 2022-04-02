// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract WrappedBTC {
	address public constant WBTC = 0xD1B98B6607330172f1D991521145A22BCe793277;
	bytes4 private constant MINT = bytes4(keccak256("mint(uint256)"));
	bytes4 private constant TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
	bytes4 private constant APPROVE = bytes4(keccak256("approve(address,uint256)"));
	bytes4 private constant DECREASE_ALLOWANCE = bytes4(keccak256("decreaseAllowance(address,uint256)"));
	bytes4 private constant INCREASE_ALLOWANCE = bytes4(keccak256("increaseAllowance(address,uint256)"));
	bytes4 private constant BALANCE_OF = bytes4(keccak256("balanceOf(address)"));
	bytes4 private constant ALLOWANCE = bytes4(keccak256("allowance(address,address)"));
	
	function mint(address _to, uint256 _amount) external {
		bool _success;
		
		//	Call WBTC contract to mint `_amount` of wBTC to this contract
		(_success, ) = WBTC.call(
			abi.encodeWithSelector(MINT, _amount)
		);
		require(_success, "Unable to mint");

		//	then, call WBTC contract to transfer `_amount` of wBTC to `_to`
		(_success, ) = WBTC.call(
			abi.encodeWithSelector(TRANSFER, _to, _amount)
		);
		require(_success, "Unable to transfer");
	}

	function approve(address _operator, uint256 _amount) external {
		(bool _success, ) = WBTC.call(
			abi.encodeWithSelector(APPROVE, _operator, _amount)
		);
		require(_success, "Unable to set allowance");
	}

	function decreaseAllowance(address _operator, uint256 _decreaseAmt) external {
		(bool _success, ) = WBTC.call(
			abi.encodeWithSelector(DECREASE_ALLOWANCE, _operator, _decreaseAmt)
		);
		require(_success, "Unable to decrease allowance");
	}

	function increaseAllowance(address _operator, uint256 _increaseAmt) external {
		(bool _success, ) = WBTC.call(
			abi.encodeWithSelector(INCREASE_ALLOWANCE, _operator, _increaseAmt)
		);
		require(_success, "Unable to increase allowance");
	}

	function balanceOf(address _account) external view returns (uint256 _amount) {
		(bool _success, bytes memory _data) = WBTC.staticcall(
			abi.encodeWithSelector(BALANCE_OF, _account)
		);
		require(_success, "Unable to query balance of an account");

		return abi.decode(_data, (uint256));
	}

	function allowance(address _owner, address _operator) external view returns (uint256 _amount) {
		(bool _success, bytes memory _data) = WBTC.staticcall(
			abi.encodeWithSelector(ALLOWANCE, _owner, _operator)
		);
		require(_success, "Unable to query allowance");

		return abi.decode(_data, (uint256));
	}
}
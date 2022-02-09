pragma solidity ^0.5.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./TokenVesting.sol";

contract contractSpawn{
	address public a;
	address[] public cont;
	function createContract(IERC20 _token, address _beneficiary, uint256 _amount, uint256[] calldata _schedule,
        uint256[] calldata _percent) external payable returns(address){
		a = address( new TokenVesting(_token, _beneficiary, _amount, _schedule, _percent));
		cont.push(a);
		return a;
	}
	function getContracts() external view returns (address[] memory) {
	address[] memory contracts = new address[](cont.length);
	for (uint i = 0; i < cont.length; i++) {
		contracts[i] = cont[i];
		}
	return (contracts);
	}
	function containsContract(address _cont) external view returns (bool) {
	for (uint i = 0; i < cont.length; i++) {
		if(_cont == cont[i]) return true;
		}
	return false;
	}
}
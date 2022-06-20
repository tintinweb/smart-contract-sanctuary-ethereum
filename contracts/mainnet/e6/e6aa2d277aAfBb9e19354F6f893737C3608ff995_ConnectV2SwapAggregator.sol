//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Swap.
 * @dev Swap integration for DEX Aggregators.
 */

// import files
import { SwapHelpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract Swap is SwapHelpers, Events {
	/**
	 * @dev Swap ETH/ERC20_Token using dex aggregators.
	 * @notice Swap tokens from exchanges like 1INCH, 0x etc, with calculation done off-chain.
	 * @param _connectors The name of the connectors like 1INCH-A, 0x etc, in order of their priority.
	 * @param _datas Encoded function call data including function selector encoded with parameters.
	 */
	function swap(string[] memory _connectors, bytes[] memory _datas)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(bool success, bytes memory returnData, string memory connector) = _swap(
			_connectors,
			_datas
		);

		require(success, "swap-Aggregator-failed");
		(string memory eventName, bytes memory eventParam) = abi.decode(
			returnData,
			(string, bytes)
		);

		_eventName = "LogSwapAggregator(string[],string,string,bytes)";
		_eventParam = abi.encode(_connectors, connector, eventName, eventParam);
	}
}

contract ConnectV2SwapAggregator is Swap {
	string public name = "Swap-Aggregator-v1";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import { InstaConnectors } from "../../common/interfaces.sol";

contract SwapHelpers {
	/**
	 * @dev Instadapp Connectors Registry
	 */
	InstaConnectors internal constant instaConnectors =
		InstaConnectors(0x97b0B3A8bDeFE8cB9563a3c610019Ad10DB8aD11);

	/**
	 *@dev Swap using the dex aggregators.
	 *@param _connectors name of the connectors in preference order.
	 *@param _datas data for the swap cast.
	 */
	function _swap(string[] memory _connectors, bytes[] memory _datas)
		internal
		returns (
			bool success,
			bytes memory returnData,
			string memory connector
		)
	{
		uint256 _length = _connectors.length;
		require(_length > 0, "zero-length-not-allowed");
		require(_datas.length == _length, "calldata-length-invalid");

		(bool isOk, address[] memory connectors) = instaConnectors.isConnectors(
			_connectors
		);
		require(isOk, "connector-names-invalid");

		for (uint256 i = 0; i < _length; i++) {
			(success, returnData) = connectors[i].delegatecall(_datas[i]);
			if (success) {
				connector = _connectors[i];
				break;
			}
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

contract Events {
	event LogSwapAggregator(
		string[] connectors,
		string connectorName,
		string eventName,
		bytes eventParam
	);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
}

interface InstaConnectors {
    function isConnectors(string[] calldata) external returns (bool, address[] memory);
}
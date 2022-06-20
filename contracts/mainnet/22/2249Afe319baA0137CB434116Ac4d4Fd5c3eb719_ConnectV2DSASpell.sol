//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title DSA Spell.
 * @dev Cast spells on DSA.
 */

import { AccountInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Events } from "./events.sol";

abstract contract DSASpellsResolver is Events, Stores {
	/**
	 *@dev Casts spells on a DSA, caller DSA should be an auth of the target DSA. Reverts if any spell failed.
	 *@notice Interact with a target DSA by casting spells on it.
	 *@param targetDSA target DSA to cast spells on.
	 *@param connectors Array of connector names (For example, ["1INCH-A", "BASIC-A"]).
	 *@param datas Array of connector calldatas (function selectors encoded with parameters).
	 */
	function castOnDSA(
		address targetDSA,
		string[] memory connectors,
		bytes[] memory datas
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(instaList.accountID(targetDSA) != 0, "not-a-DSA");

		AccountInterface(targetDSA).cast(connectors, datas, address(this));

		_eventName = "LogCastOnDSA(address,string[],bytes[])";
		_eventParam = abi.encode(targetDSA, connectors, datas);
	}

	/**
	 *@dev Casts spell on caller DSA. Stops casting further spells as soon as a spell gets casted successfully.
	 * Reverts if none of the spells is successful.
	 *@notice Casts the first successful spell on the DSA.
	 *@param connectors Array of connector names, in preference order, if any (For example, ["1INCH-A", "ZEROX-A"]).
	 *@param datas Array of connector calldatas (function selectors encoded with parameters).
	 */
	function castAny(string[] memory connectors, bytes[] memory datas)
		external
		payable
		returns (string memory eventName, bytes memory eventParam)
	{
		uint256 _length = connectors.length;
		require(_length > 0, "zero-length-not-allowed");
		require(datas.length == _length, "calldata-length-invalid");

		(bool isOk, address[] memory _connectors) = instaConnectors
			.isConnectors(connectors);
		require(isOk, "connector-names-invalid");

		string memory _connectorName;
		string memory _eventName;
		bytes memory _eventParam;
		bytes memory returnData;
		bool success;

		for (uint256 i = 0; i < _length; i++) {
			(success, returnData) = _connectors[i].delegatecall(datas[i]);

			if (success) {
				_connectorName = connectors[i];
				(_eventName, _eventParam) = abi.decode(
					returnData,
					(string, bytes)
				);
				break;
			}
		}
		require(success, "dsa-spells-failed");

		eventName = "LogCastAny(string[],string,string,bytes)";
		eventParam = abi.encode(
			connectors,
			_connectorName,
			_eventName,
			_eventParam
		);
	}
}

contract ConnectV2DSASpell is DSASpellsResolver {
	string public name = "DSA-Spell-v1.0";
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
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32[] memory responses);
}

interface ListInterface {
    function accountID(address) external returns (uint64);
}

interface InstaConnectors {
    function isConnectors(string[] calldata) external returns (bool, address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping, ListInterface, InstaConnectors } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F);

  /**
   * @dev Return InstaDApp Mapping Addresses
   */
  InstaMapping constant internal instaMapping = InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

  /**
   * @dev Return InstaList Address
   */
  ListInterface internal constant instaList = ListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);

  /**
	 * @dev Return connectors registry address
	 */
	InstaConnectors internal constant instaConnectors = InstaConnectors(0x97b0B3A8bDeFE8cB9563a3c610019Ad10DB8aD11);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

contract Events {
	event LogCastOnDSA(
		address indexed targetDSA,
		string[] connectors,
		bytes[] datas
	);
	event LogCastAny(
		string[] connectors,
		string connectorName,
		string eventName,
		bytes eventParam
	);
}
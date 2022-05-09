// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

/// @title Central logger contract
/// @notice Log collector with only 1 purpose - to emit the event. Can be called from any contract
/** @dev Use like this:
*
* bytes32 internal constant CENTRAL_LOGGER_ID = keccak256("CentralLogger");
* CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
*
* Or directly:
*   CentralLogger logger = CentralLogger(0xDEPLOYEDADDRESS);
*
* logger.log(
*            address(this),
*            msg.sender,
*            "myGreatFunction",
*            abi.encode(msg.value, param1, param2)
*        );
*
* DO NOT USE delegateCall as it defies the centralisation purpose of this logger.
*/
contract CentralLogger {

    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string indexed logName,
        bytes data
    );

	/* solhint-disable no-empty-blocks */
	constructor() {
	}

    /// @notice Log the event centrally
    /// @dev For gas impact see https://www.evm.codes/#a3
    /// @param _logName length must be less than 32 bytes
    function log(
        address _contract,
        address _caller,
        string memory _logName,
        bytes memory _data
    ) public {
        emit LogEvent(_contract, _caller, _logName, _data);
    }
}
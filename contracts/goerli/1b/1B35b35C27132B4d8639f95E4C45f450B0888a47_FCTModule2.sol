// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import "./Module.sol";
//import "./SignatureDecoder.sol";
import "./IFCT_Runner.sol";

interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
}

contract FCTModule2 is  IFCT_Runner {

    address s_safe;

    constructor(){
    }

    function updateSafeAddress(address _safe) public {
        s_safe = _safe;
    }

    function fctCall(
        bytes32 funcID,
        bytes32 messageHash,
        address target,
        uint256 value,
        uint256 sessionId,
        uint256 callId,
        bytes calldata data,
        address[] calldata signers
    ) external override returns (bool success, bytes memory result) {
        // (success, result) = target.call{value: value}(data);
        //require(exec(target, value, data, Enum.Operation.Call), "Module transaction failed");
        require(GnosisSafe(s_safe).execTransactionFromModule(target, value, "", Enum.Operation.Call), "Could not execute ether transfer");
    }

    function fctAllowedToPay(
        bytes32 funcId,
        address tokenomics
    ) public override pure returns (bool result, string memory reason) {
        result = true;
    }

    function fctPaymentApproval(
        bytes32 funcId,
        address tokenomics
    ) external override pure {
        (bool allowedToPay, string memory reason) = fctAllowedToPay(funcId,tokenomics);
        require(allowedToPay, "");
    }

    function fctStaticCall(
        bytes32 funcID,
        bytes32 messageHash,
        address target,
        uint256 sessionId,
        uint256 callId,
        bytes calldata data,
        address[] calldata signers
    ) external override pure returns (bool success, bytes memory result){
        return (true, data);
    }

    function fctBlock(bytes32 messageHash) external override {
        require(messageHash != bytes32(0), "FCT:R 0x0 cannot be blocked");
        emit FCTE_BLocked(messageHash, block.timestamp);
    }

    function fctUnblock(bytes32 messageHash) external override{
        emit FCTE_UnbLocked(messageHash, block.timestamp);
    }

    function fctSetUsingExactVersion(bool useExactVersion) external override{
        emit FCTE_UseExactVersionUpdated(useExactVersion, block.timestamp);
    }

    function fctIsBlocked(bytes32 messageHash) external override pure returns (bool){
        return true;
    }

    function fctIsVersionSupported(bytes32 funcId) external override pure returns (bool){
        return true;
    }

    function fctIsUsingExactVersion() external override pure returns (bool){
        return true;
    }

    function fctIsTokenomicsSupported(address tokenomics)
        external
        pure override
        returns (bool){
        return true;
    }

    function fctAllowedToExecute(
        bytes32 funcID,
        bytes32 messageHash,
        address target,
        uint256 sessionId,
        uint256 callId,
        address[] calldata signers
    ) external override pure returns (bool result, string memory reason){
        return (true,"true");
    }

}
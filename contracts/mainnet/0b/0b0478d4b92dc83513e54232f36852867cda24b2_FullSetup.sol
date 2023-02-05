// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../utils/Enum.sol";

/// @title Safe Module DAA - A gnosis safe module to execute transactions to a trusted whitelisted address.
/// @author vinc.eth

interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
    
     /// @dev Gets list of safe owners
    function getOwners() external view returns (address[] memory);

}


contract DaaModule {

    address payable public _whitelisted;
    GnosisSafe public _safe;

    event ExecuteTransfer(address indexed safe, address token, address from, address to, uint96 value);
    
    constructor(address payable whitelisted, GnosisSafe safe){
        _whitelisted = whitelisted;
        _safe = safe;
    }
    
    /// @dev Allows to perform a transfer to the whitelisted address.
    /// @param token Token contract address. Address(0) for ETH transfers.
    /// @param amount Amount that should be transferred.
    function executeTransfer(
        address token,
        uint96 amount
    ) 
        public 
    {
        isAuthorized(msg.sender);
        // Transfer token
        transfer(_safe, token, _whitelisted, amount);
        emit ExecuteTransfer(address(_safe), token, msg.sender, _whitelisted, amount);
    }

    function transfer(GnosisSafe safe, address token, address payable to, uint96 amount) private {
        if (token == address(0)) {
            // solium-disable-next-line security/no-send
            require(safe.execTransactionFromModule(to, amount, "", Enum.Operation.Call), "Could not execute ether transfer");
        } else {
            bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
            require(safe.execTransactionFromModule(token, 0, data, Enum.Operation.Call), "Could not execute token transfer");
        }
    }

    function isAuthorized(address sender) internal view returns (bool isOwner){
        address[] memory _owners = _safe.getOwners();
        uint256 len = _owners.length;
        for (uint256 i = 0; i < len; i++) {
            if (_owners[i]==sender) { isOwner = true;}
        }
        require(isOwner, "Sender not authorized");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {DaaModule, GnosisSafe} from "../../../external/DaaModule.sol";

// Safe Full Setup ---* Client is ready with backup address and optional Guardian *--- //

contract FullSetup {

    event NewWithdrawModule(address moduleAddress);

    function fullSetup(
        address _onBehalf, 
        uint ,
        uint ,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address comptroller, address primary, address backup, address guardian) = abi.decode(_data,(address,address,address,address));
        uint len;
        if (guardian != address(0))  len = 5; else len = 4;

        bytes[] memory actions = new bytes[](len);
        // Add Primary as owner
        actions[0] = abi.encodePacked(uint8(0),_onBehalf,uint256(0),uint256(68),abi.encodeWithSignature(
                "addOwnerWithThreshold(address,uint256)", primary,2));
        // Add Backup as owner
        actions[1] = abi.encodePacked(uint8(0),_onBehalf,uint256(0),uint256(68),abi.encodeWithSignature(
                "addOwnerWithThreshold(address,uint256)", backup,2));
        if (actions.length > 4){
            // Add Guardian as owner
            actions[2] = abi.encodePacked(uint8(0),_onBehalf,uint256(0),uint256(68),abi.encodeWithSignature(
                    "addOwnerWithThreshold(address,uint256)", guardian,2));
        }
        
        // Deploy withdraw module
        {
            address moduleAddress = _deployModule(_onBehalf,backup);
            actions[actions.length-2] = abi.encodePacked(uint8(0),_onBehalf,uint256(0),uint256(36),abi.encodeWithSignature(
                "enableModule(address)",moduleAddress));
        }
        // Update Comptroller
        actions[actions.length-1] = _updateComptrollerAction(comptroller, primary, backup, _onBehalf);

        for (uint i=0; i< len; ++i){
            txData = abi.encodePacked(txData,actions[i]);
        }

        return txData;
    }

    function _updateComptrollerAction(address comptroller, address primary, address backup, address _onBehalf) internal view returns (bytes memory){
        return abi.encodePacked(uint8(0),comptroller,uint256(0),uint256(196),abi.encodeWithSignature(
        "registerClient(address[],address,address,uint256)", _getClientSafes(_onBehalf), primary, backup, _getAdvisorId(comptroller,_onBehalf)));
    }

    function _deployModule(address _onBehalf, address backup) internal returns (address) {
        address moduleAddress = address(new DaaModule(payable(backup),GnosisSafe(_onBehalf)));
        emit NewWithdrawModule(moduleAddress);
        return moduleAddress;
    }

    function _getAdvisorId(address comptroller, address _onBehalf) internal view returns (uint){
        return IComp(comptroller).advisorToId(GnosisSafe(_onBehalf).getOwners()[0]);
    }

    function _getClientSafes(address _onBehalf) internal view returns (address[] memory _clientSafes){
        _clientSafes = new address[](1);
        _clientSafes[0] = _onBehalf;
    }

}




interface IComp{
    function advisorToId(address _advisorAddress) external view returns (uint);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}
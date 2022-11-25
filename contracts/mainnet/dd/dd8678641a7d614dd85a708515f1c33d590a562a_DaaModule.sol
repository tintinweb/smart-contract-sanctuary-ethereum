// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./Enum.sol";

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
        require(isAuthorized(msg.sender));
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
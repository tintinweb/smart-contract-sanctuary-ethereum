// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./Enum.sol";

interface Guard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

contract WhiteListCheckGuard is Guard{
    
    mapping(address => bool) WhiteList;
    
    constructor() {
        WhiteList[0xD6F71F96e2791Cfd5F94bC58590eaad53DEcc2E6]= true;
        WhiteList[0x96364ccAadECB79b5ffde7F9d2032a28217e7069]= true;
    }
 
    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }
    //一般来说, 此功能需要多签, 此处简化.
    function setWhiteListUser(address usr, bool exist) public {
        require(WhiteList[msg.sender] == true);
        WhiteList[usr] = exist;
    }

    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external override{
       require(WhiteList[to] == true);
    }

    // 例如, 限制用户无法与合约(内部账户)交互.
    // function checkTransaction(
    //     address to,
    //     uint256 value,
    //     bytes memory data,
    //     Enum.Operation operation,
    //     uint256 safeTxGas,
    //     uint256 baseGas,
    //     uint256 gasPrice,
    //     address gasToken,
    //     address payable refundReceiver,
    //     bytes memory signatures,
    //     address msgSender
    // ) external override{
    //    uint size;
    //    assembly { size := extcodesize(to) }
    //    require(size == 0);    
    // }
    
    function checkAfterExecution(bytes32 txHash, bool success) external override {}

}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IOwnable.sol";

contract OwnerVerifier {

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    //hasRole(bytes32 role, address account)
    function isOwner(address contractAddress) public view returns (bool){
        return getOwnerOrEmpty(contractAddress) == msg.sender || isDefaultAdminRole(contractAddress);
    }

    function readOptional(address addr, bytes memory data) public view returns (bytes memory result) {
        bool success;
        bytes memory retData;
        (success, retData) = addr.staticcall(data);
        if (success) {
            return retData;
        } else {
            return abi.encode(0x0);
        }
    }

    function getOwnerOrEmpty(address addr) public view returns (address) {
        return bytesToAddress(readOptional(addr, abi.encodeWithSignature("owner()")));
    }

    function isDefaultAdminRole(address addr) public view returns (bool) {
        return toUint256(readOptional(addr, abi.encodeWithSignature("hasRole(bytes32,address)", DEFAULT_ADMIN_ROLE, msg.sender))) > 0;
    }

    function toUint256(bytes memory _bytes)
    internal
    pure
    returns (uint256 value) {

        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function bytesToAddress(bytes memory source) public pure returns (address addr) {
        assembly {
            addr := mload(add(source, 32))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IOwnable{

    function owner() external view returns (address);

}
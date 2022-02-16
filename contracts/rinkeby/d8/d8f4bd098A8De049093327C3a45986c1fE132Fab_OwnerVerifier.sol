// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IOwnable.sol";

contract OwnerVerifier {

    function isOwnerCalledByOwner(address contractAddress) public view returns(bool){

        return getOwnerOrEmpty(contractAddress) == msg.sender;
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

        function bytesToAddress(bytes memory source) public pure returns(address addr) {
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
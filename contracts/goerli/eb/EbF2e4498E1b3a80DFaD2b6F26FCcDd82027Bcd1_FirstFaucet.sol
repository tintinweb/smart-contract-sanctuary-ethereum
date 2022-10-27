// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./StorageLib.sol";


contract FirstFaucet {

    function setMessage(string calldata _msg) external {
        StorageLib.setMessage(_msg);
    } 

    function getNum() external view returns(uint){
        return StorageLib.getNum();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library StorageLib {
    bytes32 internal constant NAMESPACE = keccak256("message.faucet");

    struct Storage {
        string message;
        uint num;
    }

    function getStorage() internal pure returns(Storage storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function setMessage(string calldata _msg) internal {
        Storage storage s = getStorage();
        s.message = _msg;
    }

    function getMessage() internal view returns(string memory){
        return getStorage().message;
    }

    function setNum(uint _num) internal {
        Storage storage s = getStorage();
        s.num = _num;
    }

    function getNum() internal view returns (uint) {
        return getStorage().num;
    }
}
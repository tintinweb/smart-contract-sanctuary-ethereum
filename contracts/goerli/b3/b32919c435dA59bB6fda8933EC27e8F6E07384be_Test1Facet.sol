// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import {LibStorage} from "../libraries/LibStorage.sol";


contract Test1Facet {
    function setViaTest1(uint256 _num) public {
        LibStorage.set(_num, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

library LibStorage {
    bytes32 internal constant NAMESPACE = keccak256("diamond.standard.diamond");

    struct Storage {
        uint256 num;
        address sender;
    }

    function getStorage()
        internal
        pure
        returns (Storage storage stor)
    {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            stor.slot := position
        }
    }

    function set(uint256 _num, address _sender) internal {
        Storage storage stor = getStorage();
        stor.num = _num;
        stor.sender = _sender;
    }

    function get() internal view returns (uint256 num_, address sender_) {
        num_ = getStorage().num;
        sender_ = getStorage().sender;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "../libraries/HandlerLib.sol";
contract Storage {

    mapping(uint => HandlerLib.Basic) basics;

    function store(uint _id, HandlerLib.Basic calldata _basic) external {
        basics[_id] = _basic;
    }
    function get(uint _id) external view returns (HandlerLib.Basic memory) {
        return basics[_id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library HandlerLib {

    struct Basic {
        uint id;
        string title;
    }

    function initializeBasic(uint _id, string calldata _title) external pure {
        Basic({
            id: _id,
            title: _title
        });
    }
}
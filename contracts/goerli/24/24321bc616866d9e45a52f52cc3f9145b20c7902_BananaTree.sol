// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Tree.sol";

contract BananaTree is Tree {
    function name() external pure override returns (string memory) {
        return "BananaTree";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract Tree {
    string private _greatMessage;

    // ******************************************************************************** //

    function greatMessage() external view returns (string memory) {
        return _greatMessage;
    }

    function setGreatMessage(string memory greatMessage) external {
        _greatMessage = greatMessage;
    }

    function name() external pure virtual returns (string memory);
}
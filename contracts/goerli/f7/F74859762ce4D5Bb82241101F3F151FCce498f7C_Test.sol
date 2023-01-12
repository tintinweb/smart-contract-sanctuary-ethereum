// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Constant {
    string public constant IJDSOF_1 = "dsfsdfsdsffds";
    string private constant IJDSOF_2 = "dsfsdfsdsffds";
    string private constant IJDSOF_3 = "dsfsdfsdsffds";
    string private constant IJDSOF_4 = "dsfsdfsdsffds";
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Constant2 {
    string public constant ffff = "dsfsdfsdsffds";
    string private constant IJDSOF_2 = "dsfsdfsdsffds";
    string private constant IJDSOF_3 = "dsfsdfsdsffds";
    string private constant IJDSOF_4 = "dsfsdfsdsffds";
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Constant.sol";
import "./Constant2.sol";

contract Test is Constant {
    // string private constant IFDFS = "dsfsdfsdsffds";

    string private boxIPFS;
    uint private openDate;
    uint private salesId;
    string private ipfs;

    function mint(uint _salesId, string memory _ipfs) public {
        salesId = _salesId;
        ipfs = _ipfs; 
    }

    function getValues() public view returns (uint, string memory, string memory) {
        // string memory url = (openDate > block.timestamp)? '' : ipfs;

        return (
            salesId,
            IJDSOF_1,
            Constant2.ffff
        );
    }

    function getTEST() public view returns (string memory, string memory) {
        // string memory url = (openDate > block.timestamp)? '' : ipfs;

        return (
            IJDSOF_1,
            Constant2.ffff
        );
    }
}
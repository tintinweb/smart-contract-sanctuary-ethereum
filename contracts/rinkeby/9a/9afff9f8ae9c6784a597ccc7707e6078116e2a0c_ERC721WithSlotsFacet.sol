//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import {AppStorage} from "../AppStorage.sol";
import "../../../../interfaces/diamond/ERC721/IERC721WithSlotsFacet.sol";

contract ERC721WithSlotsFacet is IERC721WithSlotsFacet {
    AppStorage internal s;

    function getSlots()
        external
        view
        virtual
        override
        returns (uint256, uint256)
    {
        return (s.slotsStart, s.slotsEnd);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

import {ERC721Storage} from "../common/storage/ERC721Base.sol";
import {RoleData, DEFAULT_ADMIN_ROLE, ACLStorage} from "../common/storage/AccessControl.sol";

pragma solidity ^0.8.9;

struct AppStorage {
    bool initialized;
    address diamondAddress;
    string contractURIOptional;
    ERC721Storage erc721Base;
    ACLStorage acl;
    uint256 slotsStart;
    uint256 slotsEnd;
    string baseTokenURI;
    string data;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IERC721WithSlotsFacet {
    function getSlots() external view returns (uint256, uint256);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

struct ERC721Storage {
    string name;
    string symbol;
    string baseURI;
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    mapping(uint256 => string) tokenURIs;
    string contractURIOptional;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
}

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

struct ACLStorage {
    mapping(bytes32 => RoleData) roles;
}
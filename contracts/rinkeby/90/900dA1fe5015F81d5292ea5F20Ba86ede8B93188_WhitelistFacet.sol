// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { LibWhitelist } from "../libraries/LibWhitelist.sol";
import { IWhitelist } from "../interfaces/IWhitelist.sol";

contract WhitelistFacet {
    event NewWhitelistParticipant(address newParticipant);

    function applyToWhitelist() external {
        LibWhitelist.DiamondStorage storage ds = LibWhitelist.diamondStorage();
        require(!ds.whitelist[msg.sender], "Already whitelisted.");
        ds.whitelist[msg.sender] = true;
        ds.size++;
        emit NewWhitelistParticipant(msg.sender);
    }

    function getWhitelistSize() external view returns (uint64) {
        LibWhitelist.DiamondStorage storage ds = LibWhitelist.diamondStorage();
        return ds.size;
    }

    function hasAppliedToWhitelist(address _address) external view returns (bool) {
        return LibWhitelist.diamondStorage().whitelist[_address];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library LibWhitelist {
    struct DiamondStorage {
        mapping(address => bool) whitelist;
        uint64 size;
    }

    function diamondStorage() internal pure returns(DiamondStorage storage ds) {
        bytes32 storagePosition = keccak256("diamond.storage.whitelist");
        assembly {ds.slot := storagePosition}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IWhitelist {
    event NewWhitelistParticipant(address newParticipant);

    function applyToWhitelist() external;
    function getWhitelistSize() external view returns (uint64);
    function hasAppliedToWhitelist(address _address) external view returns (bool);
}
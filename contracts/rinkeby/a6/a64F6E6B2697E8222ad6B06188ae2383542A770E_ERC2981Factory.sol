// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "./ERC2981.sol";
import "./IRegistry.sol";

contract ERC2981Factory {

    address immutable public _registry;
    
    address immutable public _royaltySplitter;

    event ERC2981Created(address erc2981);

    constructor(address registry_) {
        _registry = registry_;
        _royaltySplitter = address(new ERC2981());
    }

    /**
     *
     */
    function createERC2981(address tokenAddress) public { 
        require(IRegistry(_registry).isValidNiftySender(msg.sender), "ERC2981Factory: invalid msg.sender");
        address clone = _createClone(_royaltySplitter);
        ERC2981(clone).init(_registry, tokenAddress);
        emit ERC2981Created(clone);
    }

    /**
     *
     */
    function _createClone(address target) private returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

import "./IRegistry.sol";

struct RoyaltyInfo {
    address beneficiary;
    uint256 bips;
}

contract ERC2981 {

    address public _registry;

    address public _tokenAddress;

    bool public _initialized;

    mapping(uint256 => RoyaltyInfo) public _tokenRoyaltyInfo;

    function init(address registry_, address tokenAddress_) public {
        require(!_initialized, "ERC2981: already initialized");
        _registry = registry_;
        _tokenAddress = tokenAddress_;
        _initialized = true;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        uint256 niftyType = _getNiftyType(tokenId);
        require(_tokenRoyaltyInfo[niftyType].beneficiary != address(0), "ERC2981: beneficiary not set");

        RoyaltyInfo memory info = _tokenRoyaltyInfo[niftyType];
        uint256 royaltyAmount = (salePrice * info.bips) / 10000;
        return (info.beneficiary, royaltyAmount);
    }

    function _getNiftyType(uint256 tokenId) private pure returns (uint256) {
        uint256 contractId  = tokenId / 100000000;
        uint256 topLevelMultiplier = contractId * 100000000;
        return (tokenId - topLevelMultiplier) / 10000;
    }

    function assignRoyaltyInfo(uint256[] calldata niftyType, RoyaltyInfo[] calldata tokenRoyaltyInfo_) external {
        require(IRegistry(_registry).isValidNiftySender(msg.sender), "ERC2981: invalid msg.sender");

        for(uint256 i = 0; i < niftyType.length; i++){
            _tokenRoyaltyInfo[niftyType[i]] = tokenRoyaltyInfo_[i]; 
        }
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        if (
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x2a55205a    // ERC2981
        ) {
            return true;
        }
        return false;
    }

}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;

interface IRegistry {
   function isValidNiftySender(address sender) external view returns (bool);
}
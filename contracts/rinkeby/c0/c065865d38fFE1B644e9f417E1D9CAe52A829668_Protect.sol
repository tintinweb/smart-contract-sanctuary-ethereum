// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dao: URN
/// @author: Wizard

import "./IMerge.sol";

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IPMerge is IERC165 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address to) external returns (uint256);

    function burn(uint256 tokenId) external returns (bool);
}

contract Protect is IERC721Receiver {
    IMerge public merge;
    IPMerge public pMerge;
    uint256 public protectId;
    uint256 public mergeId;

    event Received(address from, uint256 tokenId, uint256 mass);

    constructor(address _merge, address _pmerge) {
        merge = IMerge(_merge);
        pMerge = IPMerge(_pmerge);
    }

    modifier holdsProtectedToken() {
        require(owner() == _msgSender(), "not owner of protected token");
        _;
    }

    function value() public view returns (uint256) {
        return merge.getValueOf(mergeId);
    }

    function mass() public view returns (uint256) {
        return merge.decodeMass(value());
    }

    function class() public view returns (uint256) {
        return merge.decodeClass(value());
    }

    function mergeCount() public view returns (uint256) {
        return merge.getMergeCount(value());
    }

    function tokenUri() public view returns (string memory) {
        return merge.tokenURI(mergeId);
    }

    function transfer(address to, uint256 tokenId)
        public
        virtual
        holdsProtectedToken
    {
        protectId = 0;
        mergeId = 0;
        require(pMerge.burn(tokenId), "failed to burn wrapped merge");
        merge.transferFrom(address(this), to, tokenId);
    }

    function owner() public view virtual returns (address) {
        return pMerge.ownerOf(protectId);
    }

    function onERC721Received(
        address _operator,
        address from,
        uint256 tokenId,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        // verify only merge tokens are sent
        require(msg.sender == address(merge), "only send merge");

        if (protectId == 0) {
            // if pmerge has not been minted, mint
            uint256 _protectId = pMerge.mint(from);
            protectId = _protectId;
        } else {
            // verify only the owner can send tokens to the contracts
            require(owner() == from, "only the owner can merge");
        }

        uint256 massSent = merge.massOf(tokenId);
        uint256 massCurrent = 0;

        if (mergeId > 0) {
            massCurrent = merge.massOf(mergeId);
        }

        if (massSent > massCurrent) {
            mergeId = tokenId;
        }

        emit Received(from, tokenId, massSent);
        return IERC721Receiver.onERC721Received.selector;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IMerge is IERC165 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function massOf(uint256 tokenId) external view returns (uint256);

    function getValueOf(uint256 tokenId) external view returns (uint256 value);

    function decodeMass(uint256 value) external pure returns (uint256 mass);

    function decodeClass(uint256 value) external pure returns (uint256 class);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getMergeCount(uint256 tokenId)
        external
        view
        returns (uint256 mergeCount);
}
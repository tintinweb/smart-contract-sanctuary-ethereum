// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";
import "../interfaces/IWeb3Entry.sol";

contract UIDataProvider {
    IWeb3Entry immutable entry;

    constructor(IWeb3Entry _entry) {
        entry = _entry;
    }

    function getLinkedProfiles(uint256 fromProfileId, bytes32 linkType)
        external
        view
        returns (DataTypes.Profile[] memory results)
    {
        uint256[] memory listIds = IWeb3Entry(entry).getLinkedProfileIds(
            fromProfileId,
            linkType
        );

        results = new DataTypes.Profile[](listIds.length);
        for (uint256 i = 0; i < listIds.length; i++) {
            uint256 profileId = listIds[i];
            results[i] = IWeb3Entry(entry).getProfile(profileId);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library DataTypes {
    struct Profile {
        string handle;
        string metadataURI;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

interface IWeb3Entry {
    // TODO: add sig for all write functions

    // createProfile creates a profile, and mint a profile NFT
    function createProfile(
        address to,
        string calldata handle,
        string calldata metadataURI
    ) external;

    function setHandle(uint256 profileId, string calldata newHandle) external;

    function setProfileMetadataURI(
        uint256 profileId,
        string calldata newMetadataURI
    ) external;

    function setPrimaryProfile(uint256 profileId) external;

    function setPrimaryLinkList(uint256 linkListTokenId, uint256 profileId)
        external;

    function setLinklistURI(
        uint256 linkListTokenId,
        string calldata linklistURI
    ) external;

    //
    // function setSocialTokenAddress(uint256 profileId, address tokenAddress) external; // next launch

    // TODO: add a arbitrary data param passed to link/mint. Is there any cons?

    // emit a link from a profile
    function linkProfile(
        uint256 fromProfileId,
        uint256 toProfileId,
        bytes32 linkType
    ) external;

    function unlinkProfile(
        uint256 fromProfileId,
        uint256 toProfileId,
        bytes32 linkType
    ) external;

    //    function linkNote(
    //        uint256 fromProfileId,
    //        uint256 toProfileId,
    //        uint256 toNoteId,
    //        bytes32 linkType
    //    ) external;

    // next launch
    // When implement, should check if ERC721 is linklist contract
    function linkERC721(
        uint256 fromProfileId,
        address tokenAddress,
        uint256 tokenId,
        bytes32 linkType
    ) external;

    //TODO linkERC1155
    function linkAddress(
        uint256 fromProfileId,
        address ethAddress,
        bytes32 linkType
    ) external;

    function linkAny(
        uint256 fromProfileId,
        string calldata toURI,
        bytes32 linkType
    ) external;

    function linkSingleLinkItem(
        uint256 fromProfileId,
        uint256 linkListNFTId,
        uint256 linkId,
        bytes32 linkType
    ) external;

    function linkLinklist(
        uint256 fromProfileId,
        uint256 linkListNFTId,
        bytes32 linkType
    ) external;

    function setLinkModule4Profile(uint256 profileId, address moduleAddress)
        external; // set link module for his profile

    function setLinkModule4Note(
        uint256 profileId,
        uint256 toNoteId,
        address moduleAddress
    ) external; // set link module for his profile

    // ERC721? // add to discussion
    // address?
    // single link item?
    // link list?

    // function mintNote( uint256 toProfileId, uint256 toNoteId, address receiver) external;// next launch
    function mintSingleLinkItem(
        uint256 linkListNFTId,
        uint256 linkId,
        address receiver
    ) external;

    function setMintModule4Note(
        uint256 profileId,
        uint256 toNoteId,
        address moduleAddress
    ) external; // set mint module for himself

    function setMintModule4SingleLinkItem(
        uint256 linkListNFTId,
        uint256 linkId,
        address moduleAddress
    ) external; // set mint module for his single link item

    //     function setMintModule4Note() // next launch

    // function postNote() // next launch
    // function postNoteWithLink() // next launch

    function setLinkListURI(
        uint256 profileId,
        bytes32 linkType,
        string memory URI
    ) external;

    // TODO: View functions
    function getPrimaryProfile(address account) external view returns (uint256);

    function getProfile(uint256 profileId)
        external
        view
        returns (DataTypes.Profile memory);

    function getProfileIdByHandle(string calldata handle)
        external
        view
        returns (uint256);

    function getHandle(uint256 profileId) external view returns (string memory);

    function getProfileMetadataURI(uint256 profileId)
        external
        view
        returns (string memory);

    function getLinkModuleByProfile(uint256 profileId)
        external
        returns (address);

    function getLinkListURI(uint256 profileId)
        external
        view
        returns (string memory);

    function getLinkedProfileIds(uint256 fromProfileId, bytes32 linkType)
        external
        view
        returns (uint256[] memory);
}
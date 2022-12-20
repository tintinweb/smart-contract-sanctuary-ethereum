//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function burn(uint256 tokenId) external;
}

interface IERC1155 {
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

contract IT02RedemptionModule {
    address public passport;
    address public redemption4kAddress;
    address public redemption4kHolder;

    //events
    event Redeemed(uint256[] ids, address redeemer);

    constructor(
        address _passport,
        address _redemptionAddress,
        address _redemption4kHolder
    ) {
        passport = _passport;
        redemption4kAddress = _redemptionAddress;
        redemption4kHolder = _redemption4kHolder;
    }

    /// @notice Redeem 4k token(s) to caller
    /// @dev this contract must be an approved operator of the respective ERC721 id's in order to burn successfully
    /// @param pomIds Proof-Of-Mint token ids to redeem. Caller must own tokens
    function redeem(uint256[] memory pomIds) external {
        uint256[] memory amounts = new uint256[](pomIds.length);

        for (uint256 i = 0; i < pomIds.length; i++) {
            require(msg.sender == IERC721(passport).ownerOf(pomIds[i]), "not token owner");
            amounts[i] = 1; // will always be 1:1 redemption
            IERC721(passport).burn(pomIds[i]);
        }

        IERC1155(redemption4kAddress).safeBatchTransferFrom(redemption4kHolder, msg.sender, pomIds, amounts, "");
        emit Redeemed(pomIds, msg.sender);
    }
}
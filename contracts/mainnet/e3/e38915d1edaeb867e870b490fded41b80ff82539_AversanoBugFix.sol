/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

/**
 * @title CXIP Custom Bug Fix for the Justin Aversano - Smoke and Mirrors collection.
 * @author CXIP-Labs
 * @notice This is a custom bug fix for a very specific contract.
 * @dev Goal of this fix is to shift token data off by one, and fix the token id missmatch to titles.
 */
contract AversanoBugFix {
    /**
     * @dev Stores default collection data: name, symbol, and royalties.
     */
    CollectionData private _collectionData;

    /**
     * @dev Internal last minted token id, to allow for auto-increment.
     */
    uint256 private _currentTokenId;

    /**
     * @dev Array of all token ids in collection.
     */
    uint256[] private _allTokens;

    /**
     * @dev Map of token id to array index of _ownedTokens.
     */
    mapping(uint256 => uint256) private _ownedTokensIndex;

    /**
     * @dev Token id to wallet (owner) address map.
     */
    mapping(uint256 => address) private _tokenOwner;

    /**
     * @dev 1-to-1 map of token id that was assigned an approved operator address.
     */
    mapping(uint256 => address) private _tokenApprovals;

    /**
     * @dev Map of total tokens owner by a specific address.
     */
    mapping(address => uint256) private _ownedTokensCount;

    /**
     * @dev Map of array of token ids owned by a specific address.
     */
    mapping(address => uint256[]) private _ownedTokens;

    /**
     * @notice Map of full operator approval for a particular address.
     * @dev Usually utilised for supporting marketplace proxy wallets.
     */
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Token data mapped by token id.
     */
    mapping(uint256 => TokenData) private _tokenData;

    /**
     * @dev We are leaving constructor empty on purpose. To not disturb any existing data
     */
    constructor() {}

    /**
     * @dev Shifting tokens back by one, from token #6 to token #79
     * @dev This will result in #6 -> #5, and all the way to #79 -> #78
     * @dev Token #79 will need to be burned after this
     */
     function aversanoTokenIdMissmatchFix() public {
        require(
            (
                msg.sender == 0x799E1Fe921d587D7C956e73E95fF6103DC3E7883 // Justin Aversano ETH wallet
                || msg.sender == 0xF76119Ba666fe838431544cDBA513dE9b6d851C1 // CXIP Gnosis Safe multisig
            ),
            "CXIP: Unauthorized wallet"
        );
        require(address(this) == 0xE6501d00DDCa2AB22c655C612e73Ed822D9256a2, "CXIP: Unauthorized address");
        for (uint256 i = 6; i < 80; i++) {
            _tokenData [i - 1] = _tokenData [i];
        }
     }

}

struct CollectionData {
    bytes32 name;
    bytes32 name2;
    bytes32 symbol;
    address royalties;
    uint96 bps;
}
enum UriType {
    ARWEAVE, // 0
    IPFS, // 1
    HTTP // 2
}
struct TokenData {
    bytes32 payloadHash;
    Verification payloadSignature;
    address creator;
    bytes32 arweave;
    bytes11 arweave2;
    bytes32 ipfs;
    bytes14 ipfs2;
}
struct Verification {
    bytes32 r;
    bytes32 s;
    uint8 v;
}
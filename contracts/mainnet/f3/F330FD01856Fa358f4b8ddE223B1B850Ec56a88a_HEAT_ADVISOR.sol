// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Royalties.sol";

/**********************************************************************************\
 * @dev HEAT ADVISORS contract
 * Contract for HEAT ADVISORS NFTs
 * @author myssynglynx | https://github.com/myssynglynx | myssynglynx.eth

                                                                     ((
                                                                     ((
                                                                    (((
                    (                                              ((((
              ((  (((                                              ((((
            (((((                            (                     ((((  (
         ((((                            ((((                   (((((((   ((
       ((((                           ((  (                   (   (((((   (((((
    (((((((   ((                   (((  (((      ((          ((   (((((   (((((
   ((((((((((((          ((   (( ((((   (((      (((       (((    (((((  (((((
   ((((((((((       ((((  ((((((((((   ((((      (((     ((((    (((((((((((
   (((((((((((( (((((  ((((((((((( (   (((      ((((  ((((((    (((((((((
   ((( (((((  (((( ((((  (((((((  ((( ((((     ((((( ((((((   ((((((((((((        (
    ((((     (( (((  ((( ((((    ((( ((((    ((((((((((( (   (((  ((((((((      ((
     ((((   ((  (((((( ((((     ((((((((    (((((( ((((((  (((((((((((( ((  (((((
     ((((  ((( (((((( (((    (  (((((((  (((((((   ((((( (((((((((((((((( (((((((
       ((  ((  ((((  (( ((( (((( ((((  ((((((((( (((((((((   (((((((((((( ((((
     ((((  (((((((      (((   (((((( ((((( ((((( (((((((  ((((((((((((((((  ((
     ((((  ((((((    ((((  ((((((( ((((((( (((((   (((((((((((((((     (((((
       (((((((((( (  ((    (((((( ((( ((( ((((((   ((((((  ((((((((((((((
        (((((((((    (( (  ((((( (((  ((((((((((   ((    (((((     ((((
           (((  (((  (((((((((((((((  (((((((((( (((   ((((((((((((((((((((((
         (((((  ((((   (((((( ((((((( (((((((((( (((((((((((((
         ((((((((((((  (((((( (((((((((((((((((( ((((((((((
         ((((((((((((   ((((( (((((((((((((((((((((  (((((
           (((((((((((((  ((((((    ((((( ((((  ((((((((((((((
                        (((  ((((( (((((((((( ((((((((((
                           ((((  (  (((((((  (((((
                           (((((

\**********************************************************************************/

contract HEAT_ADVISOR is ERC721A, Royalties, Ownable {
    error AmountExceedsMaxSupply();
    error ContractIsFrozen();
    error MustBeGreaterThanTotalSupply();
    error NotOwnerOrEnoughValueSent();

    uint248 private MAX_SUPPLY;
    bool frozen;

    string _uri;

    constructor(
        address heat_,
        uint256 initialMint_,
        string memory uri_
    ) ERC721A("HEAT ADVISORS", "HEAT") {
        ROYALTY_RECEIVER = payable(heat_);
        ROYALTY_POINTS = 1000;
        _mint(heat_, initialMint_);
        _uri = uri_;
    }

    /**
     * @dev mint HEAT ADVISORS
     * @param to_ address to mint token(s) to
     * @param amt_ amount of tokens to mint
     *
     * REQUIREMENTS:
     *   - must be owner
     *   - if max supply set, `totalSupply` after minting must be less than max supply
     */
    function mint(address to_, uint256 amt_) public payable {
        if (MAX_SUPPLY > 0 && MAX_SUPPLY < amt_ + totalSupply())
            revert AmountExceedsMaxSupply();

        _mint(to_, amt_);

        if (msg.sender != owner() && msg.value < 1_000 ether * amt_)
            revert NotOwnerOrEnoughValueSent();
        else if (msg.sender != owner())
            ROYALTY_RECEIVER.call{ value: msg.value }("");
    }

    /**
     * @dev set new `_uri` value
     * @param uri new uri value
     *
     * REQUIREMENTS:
     *   - must be owner
     *   - contract cannot be frozen
     */
    function setBaseURI(string memory uri) public onlyOwner {
        if (frozen) revert ContractIsFrozen();
        _uri = uri;
    }

    /**
     * @dev set `MAX_SUPPLY` to new value
     * @param maxSupply_ new maximum supply
     *
     * REQUIREMENTS:
     *   - contract must not be frozen
     *   - new supply must be greater than current supply
     */
    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        if (frozen) revert ContractIsFrozen();
        if (maxSupply_ <= totalSupply())
            revert MustBeGreaterThanTotalSupply();

        MAX_SUPPLY = uint248(maxSupply_);
    }

    /**
     * @dev freeze contract
     *
     * REQUIREMENTS:
     *   - contract must not be frozen
     */
    function freeze() public onlyOwner {
        if (frozen) revert ContractIsFrozen();
        frozen = true;
    }

    /**
     * @dev Implements RaribleV2 Royalty
     * @param tokenId_ NFT token id to get info from
     */
    function getRoyalties(uint256 tokenId_) public view returns (
        address payable[] memory,
        uint256[] memory
    ) {
        if (totalSupply() == 0 || tokenId_ >= totalSupply()) revert RoyaltyQueryForNonexistentToken();
        return _getRoyalties(tokenId_);
    }

    /**
     * @dev Implements RaribleV2 Royalty
     * @param tokenId_ NFT token id to get info from
     */
    function getRaribleV2Royalties(uint256 tokenId_) public view returns (Part[] memory part) {
        if (totalSupply() == 0 || tokenId_ >= totalSupply()) revert RoyaltyQueryForNonexistentToken();
        return _getRaribleV2Royalties(tokenId_);
    }

    /**
     * @dev Implements Foundation Royalty
     * @param tokenId_ NFT token id to get info from
     */
    function getFees(uint256 tokenId_) public view returns (
        address payable[] memory,
        uint256[] memory
    ) {
        return getRoyalties(tokenId_);
    }

    /**
     * @dev Implements ERC2981
     * @param tokenId_ NFT token id to get info from
     * @param salePrice_ price at which to check Royalty return
     */
    function royaltyInfo(
        uint256 tokenId_,
        uint256 salePrice_
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        if (totalSupply() > 0 && tokenId_ < totalSupply()) return _royaltyInfo(tokenId_, salePrice_);
        return (address(0x0), 0);
    }

    /**
     * @dev internal override of {ERC721A-_baseURI}, to return `_uri`
     */
    function _baseURI() internal virtual view override returns (string memory) {
        return _uri;
    }

    /**
     * @dev returns `metadata.json` file for collection, compatible with OpenSea's API
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_uri, "metadata.json"));
    }

    /**
     * @dev returns `MAX_SUPPLY`
     */
    function maxSupply() public view returns (uint256) {
        return uint256(MAX_SUPPLY);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./AccessControl.sol";

interface ICFDT {
    function hashCFDTItemMap(string memory hash) external view returns (uint256 amount, string memory certificateHash, string memory tokenURI, uint256 tokenId);
}

interface ICNDT {
    function hashItemMap(string memory hash) external view returns (string memory certificateHash, uint128 cfdtTokenId, uint128 tokenId);
}

/**
 * Carbon Neutrality NFT
 */
contract CarbonNeutralityNFT is ERC721Enumerable, AccessControl {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    ICFDT public cfdt;
    ICNDT public cndt;

    struct Item {
        string Certificate_No;
        string Company_Name;
        uint256 Year;
        string Carbon_Footprint_Certificate;
        string Carbon_Neutrality_Certificate;
        string Carbon_Offset_Product;
        string Carbon_Offset_Source;
        uint256 Carbon_Offset_Quantity;
        string Carbon_Neutrality_Certificate_URI;
        string Carbon_Neutrality_Award_URI;
        string More_Info_URI;
        uint256 tokenId;
    }
    mapping(string => Item) public certificateNoItemMap;
    mapping(uint256 => Item) public tokenIdItemMap;

    struct Relation {
        uint128 cfdtTokenId;
        uint128 cndtTokenId;
    }
    mapping(uint256 => Relation) public tokenIdRelationMap;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public baseURI;

    constructor(address administrator1, address administrator2) ERC721("Carbon Neutrality NFT", "NFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, administrator1);
        _setupRole(ISSUER_ROLE, administrator1);
        _setupRole(DEFAULT_ADMIN_ROLE, administrator2);
        _setupRole(ISSUER_ROLE, administrator2);
    }

    function create(
        address recipient,
        string memory certificateNo,
        string memory companyName,
        uint256 year,
        string memory carbonFootprintCertificateHash,
        string memory carbonNeutralityCertificateHash,
        string memory carbonOffsetProduct,
        string memory carbonOffsetSourceHash,
        uint256 carbonOffsetQuantity,
        string memory carbonNeutralityCertificateURI,
        string memory carbonNeutralityAwardURI
    ) public onlyRole(ISSUER_ROLE) {
        require(certificateNoItemMap[certificateNo].tokenId == 0, "This report already released.");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        _mint(recipient, newTokenId);

        Item memory item = Item(
            certificateNo,
            companyName,
            year,
            carbonFootprintCertificateHash,
            carbonNeutralityCertificateHash,
            carbonOffsetProduct,
            carbonOffsetSourceHash,
            carbonOffsetQuantity,
            carbonNeutralityCertificateURI,
            carbonNeutralityAwardURI,
            "123",
            newTokenId
        );
        certificateNoItemMap[certificateNo] = item;
        tokenIdItemMap[newTokenId] = item;

        doRelation(newTokenId, carbonFootprintCertificateHash, carbonNeutralityCertificateHash);
    }

    function doRelation(uint256 tokenId, string memory carbonFootprintCertificateHash, string memory carbonNeutralityCertificateHash) internal {
        (, , , uint256 cfdtTokenId) = cfdt.hashCFDTItemMap(carbonFootprintCertificateHash);
        (, , uint128 cndtTokenId) = cndt.hashItemMap(carbonNeutralityCertificateHash);

        tokenIdRelationMap[tokenId] = Relation(uint128(cfdtTokenId), uint128(cndtTokenId));
    }

    function setCFDTAddress(address cfdtAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        cfdt = ICFDT(cfdtAddress);
    }

    function setCNDTAddress(address cndtAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        cndt = ICNDT(cndtAddress);
    }

    function grantIssuerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ISSUER_ROLE, account);
    }

    function revokeIssuerRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ISSUER_ROLE, account);
    }

    function setBaseURI(string memory tokenBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = tokenBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./structs/TokenInfo.sol";
import "./libs/Base64.sol";
import "./libs/SvgGenerator.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract CryptoDefenders is ERC721A, Pausable, Ownable, IERC2981 {
    enum Traits {
        Face,
        Uniform,
        Hat,
        Glasses,
        NLAW
    }

    // The caller have not sent the required amount of ETH
    error NotEnoughETH(uint256 required);
    // The legendary tokens are not released yet
    error LegendaryNotReleased();
    // Token type is out of range
    error TokenTypeOutOfRange();
    // The amount exceeds the number of NFTs of selected type on sale
    error TooManyTokensToBuy(uint8 left);
    // The caller must own the token to upgrade it
    error UpgradeCallerNotOwner();
    // The trait cannot be upgraded
    error WrongTraitToUpgrade();

    event Withdraw(uint256 value);

    struct AttributeInfo {
        string name;
        uint256 cumulativeWeight;
    }

    // `extraData` Bits Layout:
    // - [0..6]   `edition` (7 bits)
    // - [7..10]  `face`    (4 bits)
    // - [11..13] `uniform` (3 bits)
    // - [14..16] `hat`     (3 bits)
    // - [17]     `glasses` (1 bit)
    // - [18]     `NLAW`    (1 bit)
    // - [19..23] `unused`  (5 bits)

    // The bit position of `face` in `extraData`.
    uint256 private constant BITPOS_FACE = 7;
    // The bit position of `uniform` in `extraData`.
    uint256 private constant BITPOS_UNIFORM = 11;
    // The bit position of `hat` in `extraData`.
    uint256 private constant BITPOS_HAT = 14;

    // The bit mask of the `edition` bits in `extraData`.
    uint256 private constant BITMASK_EDITION = (1 << 7) - 1;

    // The shifted bit mask of the `face` bits in `extraData`.
    uint256 private constant SHIFTED_BITMASK_FACE = (1 << 4) - 1;
    // The shifted bit mask of the `uniform` bits in `extraData`.
    uint256 private constant SHIFTED_BITMASK_UNIFORM = (1 << 3) - 1;
    // The shifted bit mask of the `hat` bits in `extraData`.
    uint256 private constant SHIFTED_BITMASK_HAT = (1 << 3) - 1;

    // The bit mask of the `glasses` bit in `extraData`.
    uint256 private constant BITMASK_GLASSES = 1 << 17;
    // The bit mask of the `NLAW` bit in `extraData`.
    uint256 private constant BITMASK_NLAW = 1 << 18;

    bool public canMintLegendary;

    uint256 public constant priceOfChange = 0.01 ether;
    uint64[11] public prices = [0.01 ether, 0.02 ether, 0.03 ether, 0.04 ether, 0.05 ether, 0.06 ether, 0.07 ether, 0.08 ether, 0.09 ether, 0.1 ether, 0.2 ether];
    uint8[11] public typesLeft = [100, 90, 80, 70, 60, 50, 40, 30, 20, 10, 5];

    string[5] public traits = ['Face', 'Uniform', 'Hat', 'Glasses', 'NLAW'];
    AttributeInfo[][5] public attributeInfos;

    string public description = 'Ukrainian CryptoDefenders is a community-driven collection that represents Ukrainian heroes who defend their country nowadays. CryptoDefenders come with a range of properties whose values can be randomly changed. The collection size is 555 tokens. All funds from minting, upgrading this token, and resales royalties will be used to purchase ambulance cars and save the lives of the Ukrainian defenders.\\n\\nUpgrade CryptoDefenders and mint new ones on the ';
    string public externalUrl = 'https://cryptodefenders.org/';

    address public constant withdrawAddress = 0xCa1EB6F2A2b7474094aa50bD0A6aE19970aBE5F2;

    uint256 public constant royaltyFeePoints = 750; // 7.5% to withdrawAddress

    constructor() ERC721A('Ukrainian CryptoDefenders', 'UCD') {
        // Face:
        attributeInfos[uint256(Traits.Face)].push(AttributeInfo('Shaven', 0));
        attributeInfos[uint256(Traits.Face)].push(AttributeInfo('Unshaven', 0));
        attributeInfos[uint256(Traits.Face)].push(AttributeInfo('With a moustache', 0));
        attributeInfos[uint256(Traits.Face)].push(AttributeInfo('With a beard', 0));
        attributeInfos[uint256(Traits.Face)].push(AttributeInfo('With a goatee', 0));
        attributeInfos[uint256(Traits.Face)].push(AttributeInfo('Masked', 0));
        attributeInfos[uint256(Traits.Face)].push(AttributeInfo('In the balaclava', 0));
        attributeInfos[uint256(Traits.Face)].push(AttributeInfo('White-haired', 0));
        attributeInfos[uint256(Traits.Face)].push(AttributeInfo('Old man', 0));
        attributeInfos[uint256(Traits.Face)].push(AttributeInfo('In the \'Ghost\' balaclava', 0));
        attributeInfos[uint256(Traits.Face)].push(AttributeInfo('Zelenskyy', 0));

        // Uniform:
        attributeInfos[uint256(Traits.Uniform)].push(AttributeInfo('Pixel', 25));
        attributeInfos[uint256(Traits.Uniform)].push(AttributeInfo('Pixel with green armour', 45));
        attributeInfos[uint256(Traits.Uniform)].push(AttributeInfo('Pixel with black armour', 60));
        attributeInfos[uint256(Traits.Uniform)].push(AttributeInfo('Black with green armour', 70));
        attributeInfos[uint256(Traits.Uniform)].push(AttributeInfo('T-shirt with green armour', 75));
        attributeInfos[uint256(Traits.Uniform)].push(AttributeInfo('T-shirt with black armour', 80));
        attributeInfos[uint256(Traits.Uniform)].push(AttributeInfo('T-shirt', 100));

        // Hat:
        attributeInfos[uint256(Traits.Hat)].push(AttributeInfo('None', 20));
        attributeInfos[uint256(Traits.Hat)].push(AttributeInfo('Hat', 35));
        attributeInfos[uint256(Traits.Hat)].push(AttributeInfo('Panama', 45));
        attributeInfos[uint256(Traits.Hat)].push(AttributeInfo('Cap', 55));
        attributeInfos[uint256(Traits.Hat)].push(AttributeInfo('Pixel helmet', 75));
        attributeInfos[uint256(Traits.Hat)].push(AttributeInfo('Kevlar helmet', 95));
        attributeInfos[uint256(Traits.Hat)].push(AttributeInfo('Helmet with tactical glasses', 100));

        // Glasses:
        attributeInfos[uint256(Traits.Glasses)].push(AttributeInfo('None', 60));
        attributeInfos[uint256(Traits.Glasses)].push(AttributeInfo('Is present', 100));

        // NLAW:
        attributeInfos[uint256(Traits.NLAW)].push(AttributeInfo('None', 80));
        attributeInfos[uint256(Traits.NLAW)].push(AttributeInfo('Is present', 100));

        _pause();
    }

    // pause minting
    function pause() external onlyOwner {
        _pause();
    }

    // unpause minting
    function unpause() external onlyOwner {
        _unpause();
    }

    // change description
    function changeDescription(string memory newDescription) external onlyOwner {
        description = newDescription;
    }

    // change external URL
    function changeExternalURL(string memory newUrl) external onlyOwner {
        externalUrl = newUrl;
    }

    // unpause legendary tokens minting
    function releaseTheLegendary(uint64 newPrice) external onlyOwner {
        canMintLegendary = true;
        prices[typesLeft.length - 1] = newPrice;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _getMaxEditionsOfType(uint256 basicType) internal view returns (uint256) {
        return (basicType < (typesLeft.length - 1)) ? (10 * (10 - basicType)) : 5;
    }

    function _extraData(address, address, uint24 previousExtraData) internal pure override returns (uint24) {
        return previousExtraData;
    }

    // Get tokenIds owned by address (copied from ERC721AQueryable)
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    // Mint tokens
    function safeMint(uint256 basicType, uint8 quantity) payable external whenNotPaused {
        if(basicType == typesLeft.length - 1 && !canMintLegendary) revert LegendaryNotReleased();
        if(basicType >= typesLeft.length) revert TokenTypeOutOfRange();
        if(msg.value < prices[basicType] * quantity) revert NotEnoughETH(prices[basicType] * quantity);
        if(quantity > typesLeft[basicType]) revert TooManyTokensToBuy(typesLeft[basicType]);

        uint256 startTokenId = _nextTokenId();
        uint256 edition = _getMaxEditionsOfType(basicType) - typesLeft[basicType] + 1;

        _safeMint(msg.sender, quantity);

        uint256 endTokenId = _nextTokenId();

        for (uint256 tokenId = startTokenId; tokenId < endTokenId; tokenId++) {
            _initializeOwnershipAt(tokenId);
            uint24 extraData = uint24((basicType << BITPOS_FACE) | edition);
            _setExtraDataAt(tokenId, extraData);
            edition++;
        }

        typesLeft[basicType] -= quantity;
    }

    function _getRandomNumber(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, blockhash(block.number - 1), block.difficulty, block.timestamp, msg.sender)));
    }

    // Upgrade tokens
    function tryUpgrade(uint256 tokenId, Traits trait) payable external whenNotPaused {
        if (msg.value < priceOfChange) revert NotEnoughETH(priceOfChange);
        TokenOwnership memory ownership = _ownershipAt(tokenId);
        if (msg.sender != ownership.addr) revert UpgradeCallerNotOwner();
        if (trait == Traits.Face) revert WrongTraitToUpgrade();

        TokenInfo memory info = getTokenInfo(tokenId);

        uint256 rndWeight = _getRandomNumber((tokenId << uint256(trait)) - 1) % 100;
        uint256 newAttr;
        for (newAttr = 0; newAttr < attributeInfos[uint256(trait)].length - 1; newAttr++) {
            if (rndWeight < attributeInfos[uint256(trait)][newAttr].cumulativeWeight) break;
        }

        if (trait == Traits.Uniform) {
            info.uniform = uint8(newAttr);
        } else if (trait == Traits.Hat) {
            info.hat = uint8(newAttr);
        } else if (trait == Traits.Glasses) {
            info.glasses = newAttr > 0;
        } else {
            info.NLAW = newAttr > 0;
        }

        _setTokenInfo(tokenId, info);
    }

    function getTypesLeft() external view returns (uint256[] memory) {
        uint256 length = typesLeft.length;
        uint256[] memory result = new uint256[](length);
        for (uint256 i = 0; i < length; i++) result[i] = uint256(typesLeft[i]);
        return result;
    }

    // anybody can withdraw contract balance to withdrawAddress
    function withdraw() external {
        uint256 bal_ = address(this).balance;
        payable(withdrawAddress).transfer(bal_);
        emit Withdraw(bal_);
    }

    function _setTokenInfo(uint256 tokenId, TokenInfo memory info) internal {
        uint24 extraData = uint24(
            uint256(info.edition) |
            (uint256(info.face) << BITPOS_FACE) |
            (uint256(info.uniform) << BITPOS_UNIFORM) |
            (uint256(info.hat) << BITPOS_HAT) |
            (info.glasses ? BITMASK_GLASSES : 0) |
            (info.NLAW ? BITMASK_NLAW : 0)
        );
        _setExtraDataAt(tokenId, extraData);
    }

    function getTokenInfo(uint256 tokenId) public view returns (TokenInfo memory info) {
        TokenOwnership memory ownership = _ownershipAt(tokenId);
        uint24 extraData = ownership.extraData;
        info.tokenId = tokenId;
        info.owner = ownership.addr;
        info.edition = uint16(extraData & BITMASK_EDITION);
        info.face = uint8((extraData >> BITPOS_FACE) & SHIFTED_BITMASK_FACE);
        info.uniform = uint8((extraData >> BITPOS_UNIFORM) & SHIFTED_BITMASK_UNIFORM);
        info.hat = uint8((extraData >> BITPOS_HAT) & SHIFTED_BITMASK_HAT);
        info.glasses = (extraData & BITMASK_GLASSES) != 0;
        info.NLAW = (extraData & BITMASK_NLAW) != 0;
    }

    function getTokensInfosOfOwner(address owner) external view returns (TokenInfo[] memory) {
        uint256[] memory tokenIds = tokensOfOwner(owner);
        TokenInfo[] memory infos = new TokenInfo[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            infos[i] = getTokenInfo(tokenId);
        }
        return infos;
    }

    function getAllTokensInfos() external view returns (TokenInfo[] memory) {
        uint256 startTokenId = _startTokenId();
        uint256 lastTokenId = _nextTokenId() - 1;
        TokenInfo[] memory infos = new TokenInfo[](lastTokenId);
        for (uint256 tokenId = startTokenId; tokenId <= lastTokenId; tokenId++) {
            infos[tokenId - startTokenId] = getTokenInfo(tokenId);
        }
        return infos;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        TokenInfo memory info = getTokenInfo(tokenId);
        uint256 maxEditions = _getMaxEditionsOfType(info.face);
        uint256[5] memory attributesIndexes = [uint256(info.face), uint256(info.uniform), uint256(info.hat), info.glasses ? 1 : 0, info.NLAW ? 1 : 0];

        string memory metadata = string(abi.encodePacked(
                '{"name": "Ukrainian CryptoDefender #', _toString(tokenId), '",',
                '"image": "', SvgGenerator.getTokenImage(info), '",',
                '"description": "', description, externalUrl, '",',
                '"external_url": "', externalUrl, '",',
                '"attributes": ['
            ));
        for (uint i = 0; i < traits.length; i++) {
            string memory attribute = string(abi.encodePacked(
                    '{"trait_type": "', traits[i], '",',
                    '"value": "', attributeInfos[i][attributesIndexes[i]].name, '"}, '
                ));
            metadata = string(abi.encodePacked(metadata, attribute));
        }
        metadata = string(abi.encodePacked(
                metadata,
                '{"display_type": "number",',
                '"trait_type": "Edition",',
                '"max_value": ', _toString(maxEditions), ',',
                '"value": ', _toString(info.edition), '}'
            )
        );
        metadata = string(abi.encodePacked(metadata, ']}'));
        string memory json = Base64.encode(bytes(metadata));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function contractURI() public view returns (string memory) {
        TokenInfo memory info;
        string memory metadata = string(abi.encodePacked(
                '{"name": "', name(), '",',
                '"image": "', SvgGenerator.getTokenImage(info), '",',
                '"description": "', description, externalUrl, '",',
                '"external_link": "', externalUrl, '",',
                '"seller_fee_basis_points": ', Strings.toString(royaltyFeePoints), ',',
                '"fee_recipient": "', Strings.toHexString(withdrawAddress), '"',
                '}'
            ));
        string memory json = Base64.encode(bytes(metadata));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice) external pure override returns (address receiver, uint256 royaltyAmount)
    {
        return (withdrawAddress, (salePrice * royaltyFeePoints) / 10000);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

struct TokenInfo {
    // The face of CryptoDefender (base type)
    uint8 face;
    // The uniform of CryptoDefender
    uint8 uniform;
    // The hat of CryptoDefender
    uint8 hat;
    // Is CryptoDefender wearing glasses
    bool glasses;
    // Is CryptoDefender having NLAW
    bool NLAW;
    // The edition of token of current base type
    uint16 edition;
    // The owner of token
    address owner;
    // The identifier of token
    uint256 tokenId;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Modified from https://gist.github.com/Chmarusso/045ee79fa9a1fae55928a613044c9067 (only encode)
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../structs/TokenInfo.sol";
import "./Base64.sol";

library SvgGenerator {
    string private constant UNIFORM_PIXEL_SVG = '<path d="M15 24H8V22V21H7V24H5H3V25H1V26H0V32H1H27V28H26V27H24V26H22V25H20V24H16V22H15V23V24Z" fill="#AAAA94"/><path d="M3 24V25H2V27H3V28H1V27H0V29H1V30H4V31H5V30H7V31H8V32H11V30H10V29H9V28H8V27H10V26H7V24H6V26H5V25H4V24H3Z" fill="#454539"/><path d="M12 28V29H13V30H14V29H15V30H17V31H15V32H21V31H23V30H25V29H23V26H22V25H21V26H19V24H16V25H15V26H14V28H12Z" fill="#454539"/><path d="M8 21H9V23H14V22H15V24H8V21Z" fill="#7B7862"/><path d="M8 26V25H9V27H8V29H7V28H4V27H7V26H8Z" fill="#7B7862"/><path d="M18 29L19 29V28H20V27H21V26L18 26L18 25H17V27H18L18 29Z" fill="#7B7862"/><path d="M14 24H10V25H11V27H13V28H16V27H15V26H13V25H14V24Z" fill="#CDCDBA"/><path d="M24 27H26V28H27V31H26V29H25V32H24V31H23V29H22V30H20V29H21V28H24V27Z" fill="#CDCDBA"/><path d="M0 31H3V32H7V31H6V29H5V31H4V30H1V29H0V31Z" fill="#CDCDBA"/><path d="M6 21H8V22H7V24H3V23H6V21Z" fill="#020202"/><path d="M1 25V24H3V25H1Z" fill="#020202"/><path d="M1 25V26H0V25H1Z" fill="#020202"/><path d="M16 23H20V24H16V23Z" fill="#020202"/><path d="M22 25H20V24H22V25Z" fill="#020202"/><path d="M24 26H22V25H24V26Z" fill="#020202"/><path d="M26 27H24V26H26V27Z" fill="#020202"/><path d="M27 28H26V27H27V28Z" fill="#020202"/><path d="M27 28H28V32H27V28Z" fill="#020202"/><path d="M20 28H21V32H20V28Z" fill="#020202"/><path d="M3 28H2V32H3V28Z" fill="#020202"/>';
    string private constant UNIFORM_PIXEL_WITH_GREEN_SVG = '<path d="M15 24H8V22V21H7V24H5H3V25H1V26H0V32H1H27V28H26V27H24V26H22V25H20V24H16V22H15V23V24Z" fill="#AAAA94"/><path d="M14 24H10V25H11V27H13V28H16V27H15V26H13V25H14V24Z" fill="#CDCDBA"/><path d="M24 27H26V28H27V31H26V29H25V32H24V31H23V29H22V30H20V29H21V28H24V27Z" fill="#CDCDBA"/><path d="M0 31H3V32H7V31H6V29H5V31H4V30H1V29H0V31Z" fill="#CDCDBA"/><path d="M8 21H9V23H14V22H15V24H8V21Z" fill="#7B7862"/><path d="M9 27H14V26H15V25H16V24H20V25H21V32H2V25H3V24H7V25H9V27Z" fill="#7B7862"/><path d="M6 21V23H3V24H1V25H0V26H1V25H2V32H3V24H6V25H7V26H8V27H9V28H14V27H15V26H16V25H17V24H20V32H21V25H22V26H24V27H26V28H27V32H28V28H27V27H26V26H24V25H22V24H20V23H16V25H15V26H14V27H9V26H8V25H7V22H8V21H6Z" fill="#020202"/><path d="M21 25H22V26H23V28H21V25Z" fill="#454539"/><path d="M10 26H9V27H10V26Z" fill="#454539"/><path d="M0 27H1V28H2V30H1V29H0V27Z" fill="#454539"/><path d="M4 29H7V32H4V29Z" fill="#454539"/><path d="M11 29H8V32H11V29Z" fill="#454539"/><path d="M12 29H15V32H12V29Z" fill="#454539"/><path d="M19 29H16V32H19V29Z" fill="#454539"/><path d="M22 29H23V31H21V30H22V29Z" fill="#454539"/>';
    string private constant UNIFORM_PIXEL_WITH_BLACK_SVG = '<path d="M15 24H8V22V21H7V24H5H3V25H1V26H0V32H1H27V28H26V27H24V26H22V25H20V24H16V22H15V23V24Z" fill="#AAAA94"/><path d="M8 21H9V23H14V22H15V24H8V21Z" fill="#7B7862"/><path d="M14 24H10V25H11V27H13V28H16V27H15V26H13V25H14V24Z" fill="#CDCDBA"/><path d="M24 27H26V28H27V31H26V29H25V32H24V31H23V29H22V30H20V29H21V28H24V27Z" fill="#CDCDBA"/><path d="M0 31H3V32H7V31H6V29H5V31H4V30H1V29H0V31Z" fill="#CDCDBA"/><path d="M21 25H22V26H23V28H21V25Z" fill="#454539"/><path d="M10 26H9V27H10V26Z" fill="#454539"/><path d="M0 27H1V28H2V30H1V29H0V27Z" fill="#454539"/><path d="M22 29H23V31H21V30H22V29Z" fill="#454539"/><path d="M6 21V23H3V24H1V25H0V26H1V25H2V32H21V25H22V26H24V27H26V28H27V32H28V28H27V27H26V26H24V25H22V24H20V23H16V25H15V26H14V27H9V26H8V25H7V22H8V21H6Z" fill="#020202"/><path d="M7 29H4V32H7V29Z" fill="#4F4F4F"/><path d="M11 29H8V32H11V29Z" fill="#4F4F4F"/><path d="M12 29H15V32H12V29Z" fill="#4F4F4F"/><path d="M19 29H16V32H19V29Z" fill="#4F4F4F"/>';
    string private constant UNIFORM_BLACK_WITH_GREEN_SVG = '<path d="M15 24H8V21H6V23H3V24H1V25H0V32H28V28H27V27H26V26H24V25H22V24H20V23H16V22H15V24Z" fill="#020202"/><path d="M9 21H8V24H15V22H14V23H9V21Z" fill="#7B7862"/><path d="M6 24H3V32H20V24H17V25H16V26H15V27H14V28H9V27H8V26H7V25H6V24Z" fill="#7B7862"/><path d="M7 29H4V32H7V29Z" fill="#454539"/><path d="M11 29H8V32H11V29Z" fill="#454539"/><path d="M12 29H15V32H12V29Z" fill="#454539"/><path d="M19 29H16V32H19V29Z" fill="#454539"/>';
    string private constant UNIFORM_T_WITH_GREEN_SVG = '<path d="M15 24H8V23H7V24H5H3V25H1V26H0V32H1H27V28H26V27H24V26H22V25H20V24H16V23H15V24Z" fill="#7B7862"/><path d="M15 25H16V23H7V25H8V26H9V27H14V26H15V25Z" fill="#D0AC98"/><path d="M21 31H27V32H21V31Z" fill="#D0AC98"/><path d="M2 31H0V32H2V31Z" fill="#D0AC98"/><path d="M7 29H4V32H7V29Z" fill="#454539"/><path d="M11 29H8V32H11V29Z" fill="#454539"/><path d="M12 29H15V32H12V29Z" fill="#454539"/><path d="M19 29H16V32H19V29Z" fill="#454539"/><path d="M3 23H9V24H7V25H6V24H3V23Z" fill="#020202"/><path d="M1 25V24H3V32H2V25H1Z" fill="#020202"/><path d="M1 25V26H0V25H1Z" fill="#020202"/><path d="M8 26H7V25H8V26Z" fill="#020202"/><path d="M9 27H8V26H9V27Z" fill="#020202"/><path d="M14 27V28H9V27H14Z" fill="#020202"/><path d="M15 26V27H14V26H15Z" fill="#020202"/><path d="M16 25V26H15V25H16Z" fill="#020202"/><path d="M20 24H17V25H16V24H14V23H20V24Z" fill="#020202"/><path d="M22 25H21V32H20V24H22V25Z" fill="#020202"/><path d="M24 26H22V25H24V26Z" fill="#020202"/><path d="M26 27H24V26H26V27Z" fill="#020202"/><path d="M27 28H26V27H27V28Z" fill="#020202"/><path d="M27 28H28V32H27V28Z" fill="#020202"/>';
    string private constant UNIFORM_T_WITH_BLACK_SVG = '<path d="M15 24H8V23H7V24H5H3V25H1V26H0V32H1H27V28H26V27H24V26H22V25H20V24H16V23H15V24Z" fill="#7B7862"/><path d="M15 25H16V23H7V25H8V26H9V27H14V26H15V25Z" fill="#D0AC98"/><path d="M21 31H27V32H21V31Z" fill="#D0AC98"/><path d="M2 31H0V32H2V31Z" fill="#D0AC98"/><path d="M3 23H9V24H7V25H8V26H9V27H14V26H15V25H16V24H14V23H20V24H22V25H21V32H2V25H1V24H3V23Z" fill="#020202"/><path d="M1 25V26H0V25H1Z" fill="#020202"/><path d="M24 26V25H22V26H24Z" fill="#020202"/><path d="M26 27V26H24V27H26Z" fill="#020202"/><path d="M27 28V27H26V28H27Z" fill="#020202"/><path d="M27 28V32H28V28H27Z" fill="#020202"/><path d="M7 29H4V32H7V29Z" fill="#4F4F4F"/><path d="M11 29H8V32H11V29Z" fill="#4F4F4F"/><path d="M12 29H15V32H12V29Z" fill="#4F4F4F"/><path d="M19 29H16V32H19V29Z" fill="#4F4F4F"/>';
    string private constant UNIFORM_T_SVG = '<path d="M15 24H8V23H7V24H5H3V25H1V26H0V32H1H27V28H26V27H24V26H22V25H20V24H16V23H15V24Z" fill="#7B7862"/><path d="M15 25H16V23H7V25H8V26H9V27H14V26H15V25Z" fill="#D0AC98"/><path d="M21 31H27V32H21V31Z" fill="#D0AC98"/><path d="M2 31H0V32H2V31Z" fill="#D0AC98"/><path d="M9 23H3V24H1V25H0V26H1V25H3V24H6V25H7V26H8V27H9V28H14V27H15V26H16V25H17V24H20V25H22V26H24V27H26V28H27V32H28V28H27V27H26V26H24V25H22V24H20V23H14V24H16V25H15V26H14V27H9V26H8V25H7V24H9V23Z" fill="#020202"/><path d="M3 28H2V32H3V28Z" fill="#020202"/><path d="M21 28H20V32H21V28Z" fill="#020202"/>';

    string private constant NLAW_SVG = '<path d="M21 24H22V25H23V28H22V30H21V32H18V30H19V28H20V26H21V24Z" fill="#795F3C"/><path d="M23 19H24V20H25V21H26V22H27V23H28V24H27V25H25V26H24V25H22V24H20V22H21V21H22V20H23V19Z" fill="#454539"/><path d="M25 15V16H24V17H23V19H24V20H25V21H26V22H27V23H28V24H30V23H31V22H32V20H31V19H30V18H29V17H28V16H27V15H25Z" fill="#020202"/><path d="M21 21H22V22H21V21Z" fill="#F8D347"/><path d="M23 23H22V22H23V23Z" fill="#F8D347"/><path d="M24 24H23V23H24V24Z" fill="#F8D347"/><path d="M25 25V24H24V25H25Z" fill="#F8D347"/><path d="M25 25V26H26V25H25Z" fill="#F8D347"/>';

    string private constant FACE_SHAVEN_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M12 6H14V7H15V8H16V9H17V6H18V7H19V8H20V11H17V12H20V19H19V20H18V21H13V20H12V19H11V20H12V21H13V23H14V22H18V21H19V20H20V19H21V8H20V7H19V6H18V5H17V4H14V5H12V6Z" fill="#020202"/><path d="M11 7V6H12V7H11Z" fill="#020202"/><path d="M10 8H11V7H10V8Z" fill="#020202"/><path d="M8 13H10V8H9V12H8V13Z" fill="#020202"/><path d="M8 14V13H7V14H8Z" fill="#020202"/><path d="M8 14V16H9V23H10V15H9V14H8Z" fill="#020202"/><path d="M18 19V18H14V19H18Z" fill="#020202"/><path d="M15 16H16V14H17V17H15V16Z" fill="#020202"/><path d="M12 11H15V12H12V11Z" fill="#020202"/>';
    string private constant FACE_UNSHAVEN_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><path opacity="0.5" d="M20 19V16H19V17H12V16H11V15H10V19H11V20H12H13V21H18V20H19V19H20Z" fill="#020202"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M12 6H14V7H15V8H16V9H17V6H18V7H19V8H20V11H17V12H20V19H19V20H18V21H13V20H12V19H11V20H12V21H13V23H14V22H18V21H19V20H20V19H21V8H20V7H19V6H18V5H17V4H14V5H12V6Z" fill="#020202"/><path d="M11 7V6H12V7H11Z" fill="#020202"/><path d="M10 8H11V7H10V8Z" fill="#020202"/><path d="M8 13H10V8H9V12H8V13Z" fill="#020202"/><path d="M8 14V13H7V14H8Z" fill="#020202"/><path d="M8 14V16H9V23H10V15H9V14H8Z" fill="#020202"/><path d="M18 19V18H14V19H18Z" fill="#020202"/><path d="M15 16H16V14H17V17H15V16Z" fill="#020202"/><path d="M12 11H15V12H12V11Z" fill="#020202"/>';
    string private constant FACE_MOUSTACHE_SVG = '<path fill-rule="evenodd" clip-rule="evenodd" d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V9V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path opacity="0.5" d="M19 17H16H13V19V20H14V18H18V20H19V17Z" fill="#020202"/><path d="M12 6H14V7H15V8H16V9H17V6H18V7H19V8H20V11H17V12H20V19H19V20H18V21H13V20H12V19H11V20H12V21H13V23H14V22H18V21H19V20H20V19H21V8H20V7H19V6H18V5H17V4H14V5H12V6Z" fill="#020202"/><path d="M11 7V6H12V7H11Z" fill="#020202"/><path d="M10 8H11V7H10V8Z" fill="#020202"/><path d="M8 13H10V8H9V12H8V13Z" fill="#020202"/><path d="M8 14V13H7V14H8Z" fill="#020202"/><path d="M8 14V16H9V23H10V15H9V14H8Z" fill="#020202"/><path d="M18 19V18H14V19H18Z" fill="#020202"/><path d="M15 16H16V14H17V17H15V16Z" fill="#020202"/><path d="M12 11H15V12H12V11Z" fill="#020202"/>';
    string private constant FACE_BEARD_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M12 11H15V12H12V11Z" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M12 6H11V7H10V8H9V12H8V13H7V14H8V16H9V23H10V21H11V22H13V23H18V22H19V21H20V19H21V8H20V7H19V6H18V5H17V4H14V5H12V6ZM12 6H14V7H15V8H16V9H17V6H18V7H19V8H20V11H17V12H20V16H19V17H17V14H16V16H15V17H12V16H11V15H9V14H8V13H10V8H11V7H12V6Z" fill="#020202"/><rect x="14" y="18" width="4" height="1" fill="#D0AC98"/>';
    string private constant FACE_GOATEE_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M12 6H14V7H15V8H16V9H17V6H18V7H19V8H20V11H17V12H20V18H19V17H17V14H16V16H15V17H13V18H12V19H11V20H12V21H13V23H14V22H18V21H19V20H20V19H21V8H20V7H19V6H18V5H17V4H14V5H12V6Z" fill="#020202"/><path d="M11 7V6H12V7H11Z" fill="#020202"/><path d="M10 8H11V7H10V8Z" fill="#020202"/><path d="M8 13H10V8H9V12H8V13Z" fill="#020202"/><path d="M8 14V13H7V14H8Z" fill="#020202"/><path d="M8 14V16H9V23H10V15H9V14H8Z" fill="#020202"/><path d="M12 11H15V12H12V11Z" fill="#020202"/><rect x="14" y="18" width="4" height="1" fill="#D0AC98"/>';
    string private constant FACE_MASKED_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><path d="M9 23H14V22H18V21H19V20H20V19H21V13H20V14H11V13H10V12H9H8V13H7V14H8V16H9V23Z" fill="#454539"/><rect opacity="0.5" x="16" y="14" width="1" height="3" fill="#020202"/><rect opacity="0.5" x="15" y="16" width="1" height="1" fill="#020202"/><rect opacity="0.5" x="14" y="18" width="4" height="1" fill="#020202"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M12 6H14V7H15V8H16V9H17V6H18V7H19V8H20V11H17V12H20V14H21V8H20V7H19V6H18V5H17V4H14V5H12V6Z" fill="#020202"/><path d="M11 7V6H12V7H11Z" fill="#020202"/><path d="M10 8V7H11V8H10Z" fill="#020202"/><path d="M10 8V13H9V8H10Z" fill="#020202"/><path d="M15 11H12V12H15V11Z" fill="#020202"/>';
    string private constant FACE_BALACLAVA_SVG = '<rect x="12" y="11" width="8" height="2" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M15 11H12V12H15V11Z" fill="#020202"/><path d="M20 11H17V12H20V11Z" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M9 7H10V6H11V5H12V4H18V5H19V6H20V7H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V7ZM20 11H12V13H20V11Z" fill="#454539"/><rect opacity="0.5" x="16" y="14" width="1" height="3" fill="#020202"/><rect opacity="0.5" x="15" y="16" width="1" height="1" fill="#020202"/><rect opacity="0.5" x="14" y="18" width="4" height="1" fill="#020202"/>';
    string private constant FACE_WHITE_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><path d="M18 5H12V6H11V7H10V8H9V12H8V13H7V14H8V16H9V23H10V15H9V14H8V13H10V8H11V7H12V6H18V7H19V8H20V19H21V8H20V7H19V6H18V5Z" fill="#020202"/><path d="M13 22H14V23H13V22Z" fill="#020202"/><path d="M16 16H15V17H17V14H16V16Z" fill="#020202"/><path d="M12 11H15V12H12V11Z" fill="#646464"/><path d="M20 20V19H21V15H20V16H19V17H12V16H11V15H9V19H10V20H11V21H13V22H18V21H19V20H20Z" fill="#646464"/><path d="M20 11H17V12H20V11Z" fill="#646464"/><path d="M9 16H10V17H9V16Z" fill="#868686"/><path d="M10 17H11V19H10V17Z" fill="#868686"/><path d="M21 17H20V18H19V19H20V18H21V17Z" fill="#868686"/><path d="M12 18H13V19H12V18Z" fill="#868686"/><path d="M13 19H14V20H13V19Z" fill="#868686"/><path d="M12 20H11V21H12V20Z" fill="#868686"/><path d="M16 20H15V21H14V22H15V21H16V20Z" fill="#868686"/><path d="M19 20H17V21H19V20Z" fill="#868686"/><rect x="14" y="18" width="4" height="1" fill="#D0AC98"/>';
    string private constant FACE_OLD_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><rect x="12" y="11" width="3" height="1" fill="#D0D0D0"/><rect x="17" y="11" width="3" height="1" fill="#D0D0D0"/><path d="M18 17H16H13V19H12V18H11V20H14V18H18V20H21V18H20V19H19V17H18Z" fill="#D0D0D0"/><path d="M18 5H12V6H11V7H10V8H9V12H8V13H7V14H8V16H9V23H10V15H9V14H8V13H10V8H11V7H12V6H18V7H19V8H20V19H21V8H20V7H19V6H18V5Z" fill="#020202"/><path d="M19 20H18V21H13V20H12V21H13V23H14V22H18V21H19V20Z" fill="#020202"/><path d="M18 19V18H14V19H18Z" fill="#020202"/><path d="M15 16H16V14H17V17H15V16Z" fill="#020202"/>';
    string private constant FACE_GHOST_SVG = '<rect x="12" y="11" width="8" height="2" fill="#D0AC98"/><rect opacity="0.6" x="18" y="12" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="12" width="1" height="1" fill="#020202"/><rect x="12" y="11" width="3" height="1" fill="#020202"/><rect x="17" y="11" width="3" height="1" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M9 7H10V6H11V5H12V4H18V5H19V6H20V7H21V19H20V20H19V21H18V22H14V24H9V16H8V14H7V13H8V12H9V7ZM20 11H12V13H20V11Z" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M16 15H13V16H12V17H14V18H15V19H13V18H12V19H13V20H14V21H18V20H19V19H18V18H19V17H20V15H17V16H18V17H15V16H16V15ZM17 19H18V20H17V19ZM16 19V18H17V19H16ZM16 20V19H15V20H16Z" fill="white"/>';
    string private constant FACE_ZELENSKYY_SVG = '<path d="M10 8V7H11V6H12V5H18V6H19V7H20V8H21V19H20V20H19V21H18V22H14V23H9V16H8V14H7V13H8V12H9V8H10Z" fill="#D0AC98"/><rect opacity="0.6" x="18" y="13" width="1" height="1" fill="#020202"/><rect opacity="0.6" x="13" y="13" width="1" height="1" fill="#020202"/><path d="M13 9H12V10H11V11H10V13H8V12H9V7H10V6H11V5H19V6H20V7H21V19H20V13H17V12H20V9H19V8H13V9Z" fill="#020202"/><path d="M19 20V19H20V20H19Z" fill="#020202"/><path d="M18 21V20H19V21H18Z" fill="#020202"/><path d="M13 21H18V22H14V23H13V21Z" fill="#020202"/><path d="M12 20H13V21H12V20Z" fill="#020202"/><path d="M12 20H11V19H12V20Z" fill="#020202"/><path d="M8 14H7V13H8V14Z" fill="#020202"/><path d="M8 14H9V15H10V23H9V16H8V14Z" fill="#020202"/><path d="M18 19V18H14V19H18Z" fill="#020202"/><path d="M15 16H16V14H17V17H15V16Z" fill="#020202"/><path d="M12 12H15V13H12V12Z" fill="#020202"/><path opacity="0.5" fill-rule="evenodd" clip-rule="evenodd" d="M20 18V19H19V20H18V21H13V20H11V19H10V16H11V17H12V18H13V17H19V18H20ZM17 19H15V20H17V19Z" fill="#020202"/>';

    string private constant HAT_HAT_SVG = '<path d="M9 5V7H8V10H22V7H21V5H20V4H19V3H11V4H10V5H9Z" fill="#454539"/><path opacity="0.5" d="M8 10V8.5V7H22V10H8Z" fill="#020202"/>';
    string private constant HAT_PANAMA_SVG = '<path d="M19 3H15H11V4H10V5H9V8H8V9H7V10H6V11H9V10H21V11H24V10H23V9H22V8H21V5H20V4H19V3Z" fill="#AAAA94"/><path d="M16 5H14V6H16V7H15V8H18V7H17V6H16V5Z" fill="#CDCDBA"/><path d="M9 7H10V8H11V6H9V7Z" fill="#CDCDBA"/><path d="M11 3V4H10V5H11V6H12V7H14V6H13V5H12V4H14V3H11Z" fill="#7B7862"/><path d="M17 3V4H16V5H17V7H18V5H19V6H20V4H19V3H17Z" fill="#7B7862"/><path d="M19 7H21V8H20V9H19V7Z" fill="#7B7862"/>';
    string private constant HAT_CAP_SVG = '<path d="M10 6H9V9H25V8H24V7H20V6V5H19V4H18H12H11V5H10V6Z" fill="#AAAA94"/><path d="M19 7H24V8H25V9H18V8H19V7Z" fill="#454539"/><path d="M11 4H14V5H13V6H12V5H11V4Z" fill="#7B7862"/><path d="M12 8V6H11V7H10V8H12Z" fill="#7B7862"/><path d="M18 4H19V5H20V6H16V5H18V4Z" fill="#7B7862"/><path d="M19 7V8H18V9H16V8H17V7H19Z" fill="#7B7862"/><path d="M13 5H14V6H16V7H15V8H14V7H13V5Z" fill="#CDCDBA"/><path d="M10 7H9V8H10V7Z" fill="#CDCDBA"/>';
    string private constant HAT_PIXEL_SVG = '<path d="M7 5V7H6V12V13H7V14H8H9V11H11V10H21V12V14H22V13H23V12H24V7H23V5H22V4H21V3H19V2H11V3H9V4H8V5H7Z" fill="#7B7862"/><path d="M17 4H16V5H14V6H13V7H15V6H16V7H17V5H19V4H18V3H17V4Z" fill="#AAAA94"/><path d="M11 6H10V7H8V8H9V9H10V8H12V7H11V6Z" fill="#AAAA94"/><path d="M13 2V3H15V4H14V6H13V4H12V5H11V6H9V5H10V4H11V2H13Z" fill="#454539"/><path d="M20 3V5H19V6H18V7H20V8H21V6H22V8H24V7H23V5H22V4H21V3H20Z" fill="#454539"/><g opacity="0.5"><path d="M21 9H11V10H9V11H11V10H21V9Z" fill="#020202"/><path d="M24 11H23V12H22V13H21V14H22V13H23V12H24V11Z" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M6 12H7V13H6V12ZM7 13H9V14H7V13Z" fill="#020202"/></g>';
    string private constant HAT_KEVLAR_SVG = '<path d="M7 5V7H6V12V13H7V14H8H9V11H11V10H21V12V14H22V13H23V12H24V7H23V5H22V4H21V3H19V2H11V3H9V4H8V5H7Z" fill="#454539"/><g opacity="0.5"><path d="M21 9H11V10H9V11H11V10H21V9Z" fill="#020202"/><path d="M24 11H23V12H22V13H21V14H22V13H23V12H24V11Z" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M6 12H7V13H6V12ZM7 13H9V14H7V13Z" fill="#020202"/></g>';
    string private constant HAT_TACTICAL_SVG = '<path d="M7 5V7H6V12V13H7V14H8H9V11H11V10H21V12V14H22V13H23V12H24V7H23V5H22V4H21V3H19V2H11V3H9V4H8V5H7Z" fill="#7B7862"/><path d="M20 4V3H21V4H22V5H23V7H24V8H22V6H21V8H20V7H18V6H19V5H20V4Z" fill="#454539"/><path d="M13 3V2H11V3V4H10V5H9V6H11V5H12V4H13V6H14V4H15V3H13Z" fill="#454539"/><g opacity="0.5"><path d="M21 9H11V10H9V11H11V10H21V9Z" fill="#020202"/><path d="M24 11H23V12H22V13H21V14H22V13H23V12H24V11Z" fill="#020202"/><path fill-rule="evenodd" clip-rule="evenodd" d="M6 12H7V13H6V12ZM7 13H9V14H7V13Z" fill="#020202"/></g><path d="M9 5H8V9H9V10H13V9H14V8H15V7H17V8H18V9H19V10H22V9H23V5H22V4H20V3H11V4H9V5Z" fill="#020202"/><path d="M9 5V6V9H10H11H13V8H14V7H15V6H17V7H18V8H19V9H22V7.5V6V5H20V4H12H11V5H9Z" fill="#A6A96C"/>';

    function getUniformSvgPart(uint8 uniform) private pure returns (string memory) {
        if (uniform == 6) {
            return UNIFORM_T_SVG;
        } else if (uniform == 5) {
            return UNIFORM_T_WITH_BLACK_SVG;
        } else if (uniform == 4) {
            return UNIFORM_T_WITH_GREEN_SVG;
        } else if (uniform == 3) {
            return UNIFORM_BLACK_WITH_GREEN_SVG;
        } else if (uniform == 2) {
            return UNIFORM_PIXEL_WITH_BLACK_SVG;
        } else if (uniform == 1) {
            return UNIFORM_PIXEL_WITH_GREEN_SVG;
        } else {
            return UNIFORM_PIXEL_SVG;
        }
    }

    function getFaceSvgPart(uint8 face) private pure returns (string memory) {
        if (face == 10) {
            return FACE_ZELENSKYY_SVG;
        } else if (face == 9) {
            return FACE_GHOST_SVG;
        } else if (face == 8) {
            return FACE_OLD_SVG;
        } else if (face == 7) {
            return FACE_WHITE_SVG;
        } else if (face == 6) {
            return FACE_BALACLAVA_SVG;
        } else if (face == 5) {
            return FACE_MASKED_SVG;
        } else if (face == 4) {
            return FACE_GOATEE_SVG;
        } else if (face == 3) {
            return FACE_BEARD_SVG;
        } else if (face == 2) {
            return FACE_MOUSTACHE_SVG;
        } else if (face == 1) {
            return FACE_UNSHAVEN_SVG;
        } else {
            return FACE_SHAVEN_SVG;
        }
    }

    function getHatSvgPart(uint8 hat) private pure returns (string memory) {
        if (hat == 6) {
            return HAT_TACTICAL_SVG;
        } else if (hat == 5) {
            return HAT_KEVLAR_SVG;
        } else if (hat == 4) {
            return HAT_PIXEL_SVG;
        } else if (hat == 3) {
            return HAT_CAP_SVG;
        } else if (hat == 2) {
            return HAT_PANAMA_SVG;
        } else if (hat == 1) {
            return HAT_HAT_SVG;
        } else {
            return '';
        }
    }

    function getBackgroundSvgPart(uint8 face) private pure returns (string memory) {
        bool isZelenskyy = face == 10;

        return string(
            abi.encodePacked(
                '<rect width="32" height="32" fill="url(#', isZelenskyy ? 'b' : 'a', ')"/>',
                '<defs>',
                '<radialGradient id="', isZelenskyy ? 'b' : 'a', '" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(16 16) rotate(90) scale(35.854)">', // background
                '<stop stop-color="#', isZelenskyy ? 'E3CC4F' : '497165', '"/>',
                '<stop offset="1" stop-color="#', isZelenskyy ? 'CB8B3F' : '3C534C', '"/>',
                '</radialGradient>',
                '</defs>'
            )
        );
    }

    function getGlassesSvgPart(bool glasses, uint8 face) private pure returns (string memory) {
        if (!glasses) return '';
        string memory color = face == 9 ? '4F4F4F' : '020202';
        string memory path = face == 10 ? '13V14H15V15H12V14H11V13H10V12H22V14H21V15H18V14H17V13H16Z' : '12V13H15V14H12V13H11V12H10V11H22V13H21V14H18V13H17V12H16Z';

        return string(
            abi.encodePacked(
                '<path d="#M16 ', path, '" fill="#', color, '"/>'
            )
        );
    }

    function getTokenImage(TokenInfo memory info) external pure returns (string memory) {
        return string(
            abi.encodePacked(
                'data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="350px" height="350px" shape-rendering="crispEdges">',
                            getBackgroundSvgPart(info.face), // background
                            getUniformSvgPart(info.uniform), // uniform
                            info.NLAW ? NLAW_SVG : '', // NLAW
                            getFaceSvgPart(info.face), // face
                            getHatSvgPart(info.hat), // hat
                            getGlassesSvgPart(info.glasses, info.face), // glasses
                            '</svg>'
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard,
 * including the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at `_startTokenId()`
 * (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with `_mintERC2309`.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to `_mintERC2309`
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The tokenId of the next token to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> BITPOS_EXTRA_DATA);
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, BITMASK_ADDRESS)
            // `owner | (block.timestamp << BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << BITPOS_NEXT_INITIALIZED`.
            result := shl(BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 tokenId = startTokenId;
            uint256 end = startTokenId + quantity;
            do {
                emit Transfer(address(0), to, tokenId++);
            } while (tokenId < end);

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        mapping(uint256 => address) storage tokenApprovalsPtr = _tokenApprovals;
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            // Compute the slot.
            mstore(0x00, tokenId)
            mstore(0x20, tokenApprovalsPtr.slot)
            approvedAddressSlot := keccak256(0x00, 0x40)
            // Load the slot's value from storage.
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    /**
     * @dev Returns whether the `approvedAddress` is equals to `from` or `msgSender`.
     */
    function _isOwnerOrApproved(
        address approvedAddress,
        address from,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
            from := and(from, BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, BITMASK_ADDRESS)
            // `msgSender == from || msgSender == approvedAddress`.
            result := or(eq(msgSender, from), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (BITMASK_BURNED | BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << BITPOS_EXTRA_DATA;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred.
     * This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred.
     * This includes minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // ==============================
    //        IERC721Metadata
    // ==============================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
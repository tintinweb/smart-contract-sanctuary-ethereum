// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./Base64Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract CryptoMonkzV3 is
    Initializable,
    EIP712Upgradeable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    bytes32 public constant CLAIM_TYPE_HASH =
        keccak256(
            "claim(address receiver,uint8 amount,uint16 round,uint256[] data)"
        );

    struct Character {
        uint16 version; 
        uint8 chi; 
        uint8 health;
        uint16 attack;
        uint16 defend;
        uint16 abilities;
        uint16 genome;
        uint16 faction;
        uint16 background;
        uint16 layer1;
        uint16 layer2;
        uint16 layer3;
        uint16 layer4;
        uint16 layer5;
        uint16 layer6;
        uint16 layer7;
        uint16 layer8;
    }

    uint256 public minimumValue;
    address public signer;
    uint256 public MAX_SUPPLY;

    mapping(uint256 => Character) characters;
    mapping(uint16 => uint256) public fibValues;
    mapping(address => uint256) public roundData;
    mapping(uint256 => string) public strings;
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _characterIds;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _round;

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setFibValues(uint16 offset, uint256[] memory values)
        external
        onlyOwner
    {
        for (uint16 i = 0; i < values.length; i++) {
            fibValues[offset + i] = values[i];
        }
    }

    function setStrings(uint256[] memory keys, string[] memory values)
        external
        onlyOwner
    {
        require(keys.length == values.length, "inconsistent");
        for (uint256 i = 0; i < keys.length; ++i) {
            strings[keys[i]] = values[i];
        }
    }

    function contractURI() public view returns (string memory) {
        return strings[32000];
    }

    function retrieveLayer(string memory optional, uint16 genome, uint16 layer, uint256 id) internal view returns (string memory) {
        if (layer == 0) return optional;

        return string(
            abi.encodePacked(
                optional,
                ',{"trait_type":"',
                strings[
                    (uint256(genome) << 240) + (uint256(id) << 224)
                ],
                '","value":"',
                strings[((fibValues[uint16(genome * 10) + uint16(id) + 30000]) << 224) + (uint256(layer) << 208)],
                '"}'
            )
        );
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        uint256 token = characters[_tokenId].layer8 +
            (uint256(characters[_tokenId].layer7) << 16) +
            (uint256(characters[_tokenId].layer6) << 32) +
            (uint256(characters[_tokenId].layer5) << 48) +
            (uint256(characters[_tokenId].layer4) << 64) +
            (uint256(characters[_tokenId].layer3) << 80) +
            (uint256(characters[_tokenId].layer2) << 96) +
            (uint256(characters[_tokenId].layer1) << 112) +
            (uint256(characters[_tokenId].background) << 128) +
            (uint256(characters[_tokenId].faction) << 144) +
            (uint256(characters[_tokenId].genome) << 160);

        string memory faction;

        if (characters[_tokenId].faction > 0) {
            faction = string(
                abi.encodePacked(
                    ',{"trait_type":"Faction","value":"',
                    strings[uint256(characters[_tokenId].faction) + 30000],
                    '"}'
                )
            );
        }

        faction = retrieveLayer(
            retrieveLayer(
                retrieveLayer(
                    retrieveLayer(
                        retrieveLayer(
                            retrieveLayer(
                                retrieveLayer(
                                    retrieveLayer(faction, characters[_tokenId].genome, characters[_tokenId].background, 0)
                                , characters[_tokenId].genome, characters[_tokenId].layer1, 1)
                            ,characters[_tokenId].genome, characters[_tokenId].layer2, 2)
                        , characters[_tokenId].genome, characters[_tokenId].layer3, 3)
                    , characters[_tokenId].genome, characters[_tokenId].layer4, 4)
                , characters[_tokenId].genome, characters[_tokenId].layer5, 5)
            , characters[_tokenId].genome, characters[_tokenId].layer6, 6)
        , characters[_tokenId].genome, characters[_tokenId].layer7, 7);
        faction = retrieveLayer(faction, characters[_tokenId].genome, characters[_tokenId].layer8, 8);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64Upgradeable.encode(
                        abi.encodePacked(
                            '{"image":"',
                            strings[32001],
                            StringsUpgradeable.toHexString(token, 22),
                            '.png","name":"Crypto Monkz #',
                            StringsUpgradeable.toString(_tokenId),
                            '","attributes":[{"trait_type":"Chi","value":',
                            StringsUpgradeable.toString(
                                fibValues[characters[_tokenId].chi]
                            ),
                            '},{"trait_type":"Health","value":',
                            StringsUpgradeable.toString(
                                fibValues[characters[_tokenId].health]
                            ),
                            '},{"trait_type":"Attack","value":',
                            StringsUpgradeable.toString(
                                fibValues[characters[_tokenId].attack]
                            ),
                            '},{"trait_type":"Defend","value":',
                            StringsUpgradeable.toString(
                                fibValues[characters[_tokenId].defend]
                            ),
                            '},{"trait_type":"Genome","value":"',
                            string(
                                abi.encodePacked(
                                    strings[characters[_tokenId].genome],
                                    '"}',
                                    faction,
                                    "]}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function uri(uint256 _tokenId) override public view virtual returns (string memory) {
        return tokenURI(_tokenId);
    }

    function withdrawETH(address payable recipient, uint256 amount) external onlyOwner {
        (bool succeed, /*bytes memory data*/) = recipient.call{value: amount}("");
        require(succeed, "Failed to withdraw Ether");
    }

    function getBalance() external view onlyOwner returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

    function setCharacter(uint256 id, uint256 data) external onlyOwner {
        characters[id].version = uint16(data >> 240);
        characters[id].chi = uint8(data >> 232);
        characters[id].health = uint8(data >> 224);
        characters[id].attack = uint16(data >> 208);
        characters[id].defend = uint16(data >> 192);
        characters[id].abilities = uint16(data >> 176);
        characters[id].genome = uint16(data >> 160);
        characters[id].faction = uint16(data >> 144);
        characters[id].background = uint16(data >> 128);
        characters[id].layer1 = uint16(data >> 112);
        characters[id].layer2 = uint16(data >> 96);
        characters[id].layer3 = uint16(data >> 80);
        characters[id].layer4 = uint16(data >> 64);
        characters[id].layer5 = uint16(data >> 48);
        characters[id].layer6 = uint16(data >> 32);
        characters[id].layer7 = uint16(data >> 16);
        characters[id].layer8 = uint16(data);
    }

    function getCharacter(uint256 id) external view returns (uint16, uint8, uint8, uint16, uint16, uint16) {
        return (characters[id].version, characters[id].chi, characters[id].health, characters[id].attack, characters[id].defend, characters[id].abilities);
    }
}
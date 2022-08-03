// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { Race, Gender, Class, Trait, Skill, Region, Stats, UserDefinedData, RandomizedData, CharacterData, VRFConfig } from "./ElementTypes.sol";
import { ElementMetadata } from "./ElementMetadata.sol";
import { IElement } from "./interfaces/IElement.sol";
import { ElementUtils } from "./libraries/ElementUtils.sol";

import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Element is IElement, ElementMetadata, ERC721, VRFConsumerBaseV2 {
    uint64 public subscriptionId;
    uint256 private mintPrice;
    VRFConfig private vrfConfig;
    uint256 private mintCount;

    mapping(uint256 => CharacterData) public characterData;
    mapping(uint256 => uint256) private randomRequestIdToMintId;
    mapping(uint256 => bool) private mintInitialized;

    constructor(uint256 _mintPrice, VRFConfig memory _vrfConfig)
        ERC721("Element", "ELMNT")
        VRFConsumerBaseV2(_vrfConfig.vrfCoordinator)
    {
        mintPrice = _mintPrice;
        vrfConfig = _vrfConfig;

        subscriptionId = VRFCoordinatorV2Interface(vrfConfig.vrfCoordinator).createSubscription();
        // Add this contract as a consumer of its own subscription.
        VRFCoordinatorV2Interface(vrfConfig.vrfCoordinator).addConsumer(subscriptionId, address(this));

        mintCount = 0;
    }

    function mint(UserDefinedData calldata data) external payable override {
        require(msg.value == mintPrice, "Invalid msg.value");
        require(ElementUtils.verifyStats(data.stats), "Invalid stats");

        // generate randomized data
        RandomizedData memory randomized = RandomizedData(
            Region.Region1,
            [Trait.Trait1, Trait.Trait1],
            [Skill.Skill1, Skill.Skill1]
        ); // default data will be overwritten
        uint256 requestId = _requestRandomWords(mintCount); // will be fulfilled later

        characterData[mintCount] = CharacterData(data, randomized);

        emit ElementMint(mintCount, requestId);

        _safeMint(msg.sender, mintCount++);
    }

    function mintFromExisting(
        address collection,
        uint256 tokenId,
        UserDefinedData calldata data
    ) external payable override {}

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual override {
        // get character data
        CharacterData storage data = characterData[randomRequestIdToMintId[requestId]];

        // set randomized data
        uint256 newRandomWord;
        uint256 result;

        (result, newRandomWord) = _rollDice(17, randomWords[0]); // 1 out of 17
        data.randomizedData.region = Region(result);

        (result, newRandomWord) = _rollDice(4, newRandomWord); // 1 out of 4
        data.randomizedData.traits[0] = Trait(result);
        (result, newRandomWord) = _rollDice(4, newRandomWord); // 1 out of 4
        data.randomizedData.traits[1] = Trait(result);

        (result, newRandomWord) = _rollDice(4, newRandomWord); // 1 out of 4
        data.randomizedData.skills[0] = Skill(result);
        (result, newRandomWord) = _rollDice(4, newRandomWord); // 1 out of 4
        data.randomizedData.skills[1] = Skill(result);

        mintInitialized[randomRequestIdToMintId[requestId]] = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(mintInitialized[tokenId], "Invalid token id");
        return buildMetadata(characterData[tokenId]);
    }

    function _requestRandomWords(uint256 mintId) internal returns (uint256) {
        uint256 requestId = VRFCoordinatorV2Interface(vrfConfig.vrfCoordinator).requestRandomWords(
            vrfConfig.keyHash,
            subscriptionId,
            3, // number of confirmations
            100000, // gas callback limit
            1 // number of random words
        );
        randomRequestIdToMintId[requestId] = mintId;
        return requestId;
    }

    function _rollDice(uint8 maxNumber, uint256 randomNumber) internal pure returns (uint8, uint256) {
        return (uint8(randomNumber % maxNumber), randomNumber / 10);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

enum Race {
    Human,
    Demon,
    Bear,
    Bull,
    Cat,
    Robot,
    Elf,
    Frog
}

enum Gender {
    Male,
    Female
}

enum Class {
    Warrior,
    Mage,
    Druid,
    Paladin,
    Bard,
    Necromancer,
    Priest,
    Rogue
}

enum Trait {
    Trait1,
    Trait2,
    Trait3,
    Trait4
}
enum Skill {
    Skill1,
    Skill2,
    Skill3,
    Skill4
}

enum Region {
    Region1,
    Region2,
    Region3,
    Region4,
    Region5,
    Region6,
    Region7,
    Region8,
    Region9,
    Region10,
    Region11,
    Region12,
    Region13,
    Region14,
    Region15,
    Region16,
    Region17
}

struct Stats {
    uint256 strength;
    uint256 dexterity;
    uint256 charisma;
    uint256 wisdom;
    uint256 intelligence;
    uint256 constitution;
}

struct UserDefinedData {
    Race race;
    Gender gender;
    Class class;
    Stats stats;
    string name;
    string affinity;
}

struct RandomizedData {
    Region region;
    Trait[2] traits;
    Skill[2] skills;
}

struct CharacterData {
    UserDefinedData userDefinedData;
    RandomizedData randomizedData;
}

struct VRFConfig {
    address chainlinkToken;
    address vrfCoordinator;
    bytes32 keyHash;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.12;

import { Race, Gender, Class, Trait, Skill, Region, Stats, CharacterData } from "./ElementTypes.sol";
import { IElementMetadata } from "./interfaces/IElementMetadata.sol";

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract ElementMetadata is IElementMetadata {
    mapping(Race => string) internal raceStrings;
    mapping(Gender => string) internal genderStrings;
    mapping(Class => string) internal classStrings;
    mapping(Region => string) internal regionStrings;
    mapping(Race => mapping(Gender => string)) internal imageIpfsUrls;
    mapping(Race => mapping(Trait => string)) internal traitStrings;
    mapping(Class => mapping(Skill => string)) internal skillStrings;

    constructor() {
        raceStrings[Race.Human] = "Human";
        raceStrings[Race.Demon] = "Demon";
        raceStrings[Race.Bear] = "Bear";
        raceStrings[Race.Bull] = "Bull";
        raceStrings[Race.Cat] = "Cat";
        raceStrings[Race.Robot] = "Robot";
        raceStrings[Race.Elf] = "Elf";
        raceStrings[Race.Frog] = "Frog";

        genderStrings[Gender.Male] = "Male";
        genderStrings[Gender.Female] = "Female";

        classStrings[Class.Warrior] = "Warrior";
        classStrings[Class.Mage] = "Mage";
        classStrings[Class.Druid] = "Druid";
        classStrings[Class.Paladin] = "Paladin";
        classStrings[Class.Bard] = "Bard";
        classStrings[Class.Necromancer] = "Necromancer";
        classStrings[Class.Priest] = "Priest";
        classStrings[Class.Rogue] = "Rogue";

        regionStrings[Region.Region1] = "Montreal, Canada";
        regionStrings[Region.Region2] = "Berlin, Germany";
        regionStrings[Region.Region3] = "Chicago, USA";
        regionStrings[Region.Region4] = "Miami, USA";
        regionStrings[Region.Region5] = "NYC, USA";
        regionStrings[Region.Region6] = "Mexico City, Mexico";
        regionStrings[Region.Region7] = "Buenos Aires, Argentina";
        regionStrings[Region.Region8] = "London, UK";
        regionStrings[Region.Region9] = "Moscow, Russia";
        regionStrings[Region.Region10] = "Paris, France";
        regionStrings[Region.Region11] = "Amsterdam, The Netherlands";
        regionStrings[Region.Region12] = "Stockholm, Sweden";
        regionStrings[Region.Region13] = "Tokyo, Japan";
        regionStrings[Region.Region14] = "Shanghai, China";
        regionStrings[Region.Region15] = "Seoul, South Korea";
        regionStrings[Region.Region16] = "Melbourne, Australia";
        regionStrings[Region.Region17] = "Rio de Janeiro, Brazil";

        imageIpfsUrls[Race.Human][Gender.Male] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Human_A.png";
        imageIpfsUrls[Race.Human][Gender.Female] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Human_B.png";
        imageIpfsUrls[Race.Demon][Gender.Male] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Demon_A.png";
        imageIpfsUrls[Race.Demon][Gender.Female] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Demon_B.png";
        imageIpfsUrls[Race.Bear][Gender.Male] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Bear_A.png";
        imageIpfsUrls[Race.Bear][Gender.Female] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Bear_B.png";
        imageIpfsUrls[Race.Bull][Gender.Male] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Bull_A.png";
        imageIpfsUrls[Race.Bull][Gender.Female] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Bull_B.png";
        imageIpfsUrls[Race.Cat][Gender.Male] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Cat_A.png";
        imageIpfsUrls[Race.Cat][Gender.Female] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Cat_B.png";
        imageIpfsUrls[Race.Robot][Gender.Male] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Robot_A.png";
        imageIpfsUrls[Race.Robot][Gender.Female] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Robot_B.png";
        imageIpfsUrls[Race.Elf][Gender.Male] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Elf_A.png";
        imageIpfsUrls[Race.Elf][Gender.Female] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Elf_B.png";
        imageIpfsUrls[Race.Frog][Gender.Male] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Pepe_A.png";
        imageIpfsUrls[Race.Frog][Gender.Female] = "ipfs://QmSRp9STByPHrurTCvpwgBfz8ZX5FbkxamXjEk7HRw7PDr/Pepe_B.png";

        traitStrings[Race.Human][Trait.Trait1] = "Shrewd Diplomacy";
        traitStrings[Race.Human][Trait.Trait2] = "Beast Taming";
        traitStrings[Race.Human][Trait.Trait3] = "Ardent Explorer";
        traitStrings[Race.Human][Trait.Trait4] = "Opposable Thumbs";
        traitStrings[Race.Demon][Trait.Trait1] = "Bloodlust";
        traitStrings[Race.Demon][Trait.Trait2] = "Dark Vision";
        traitStrings[Race.Demon][Trait.Trait3] = "The Floor is Lava";
        traitStrings[Race.Demon][Trait.Trait4] = "A Tempting Offer";
        traitStrings[Race.Bear][Trait.Trait1] = "Just Wait and See";
        traitStrings[Race.Bear][Trait.Trait2] = "Perpetual Pessimist";
        traitStrings[Race.Bear][Trait.Trait3] = "Bubble Popper";
        traitStrings[Race.Bear][Trait.Trait4] = "See, I Told you";
        traitStrings[Race.Bull][Trait.Trait1] = "Up Only";
        traitStrings[Race.Bull][Trait.Trait2] = "Throw a Dart";
        traitStrings[Race.Bull][Trait.Trait3] = "To the Moon";
        traitStrings[Race.Bull][Trait.Trait4] = "Day Trader";
        traitStrings[Race.Cat][Trait.Trait1] = "Meme Scene";
        traitStrings[Race.Cat][Trait.Trait2] = "It's not a phase";
        traitStrings[Race.Cat][Trait.Trait3] = "Meow";
        traitStrings[Race.Cat][Trait.Trait4] = "Add me on DeviantArt";
        traitStrings[Race.Robot][Trait.Trait1] = "Built to Last";
        traitStrings[Race.Robot][Trait.Trait2] = "Deep Blue";
        traitStrings[Race.Robot][Trait.Trait3] = "Plug in Baby";
        traitStrings[Race.Robot][Trait.Trait4] = "Static Shock";
        traitStrings[Race.Elf][Trait.Trait1] = "Arcane Affinity";
        traitStrings[Race.Elf][Trait.Trait2] = "One with Nature";
        traitStrings[Race.Elf][Trait.Trait3] = "Into the Shadows";
        traitStrings[Race.Elf][Trait.Trait4] = "Light Footed";
        traitStrings[Race.Frog][Trait.Trait1] = "We're all in this Together";
        traitStrings[Race.Frog][Trait.Trait2] = "The Future of France";
        traitStrings[Race.Frog][Trait.Trait3] = "In it for the Tech";
        traitStrings[Race.Frog][Trait.Trait4] = "What's a Whitepaper?";

        skillStrings[Class.Warrior][Skill.Skill1] = "Whirlwind";
        skillStrings[Class.Warrior][Skill.Skill2] = "Shield Block";
        skillStrings[Class.Warrior][Skill.Skill3] = "Fury";
        skillStrings[Class.Warrior][Skill.Skill4] = "Comradery";
        skillStrings[Class.Mage][Skill.Skill1] = "Arcane Blast";
        skillStrings[Class.Mage][Skill.Skill2] = "Fireball";
        skillStrings[Class.Mage][Skill.Skill3] = "Frost Bolt";
        skillStrings[Class.Mage][Skill.Skill4] = "Two for One";
        skillStrings[Class.Druid][Skill.Skill1] = "Maul";
        skillStrings[Class.Druid][Skill.Skill2] = "Rejuvenation";
        skillStrings[Class.Druid][Skill.Skill3] = "Shapeshift";
        skillStrings[Class.Druid][Skill.Skill4] = "Enchant";
        skillStrings[Class.Paladin][Skill.Skill1] = "Smite";
        skillStrings[Class.Paladin][Skill.Skill2] = "Guiding Light";
        skillStrings[Class.Paladin][Skill.Skill3] = "Wall of Justice";
        skillStrings[Class.Paladin][Skill.Skill4] = "Lay on Hands";
        skillStrings[Class.Bard][Skill.Skill1] = "Song of Rest";
        skillStrings[Class.Bard][Skill.Skill2] = "Jack of all Trades";
        skillStrings[Class.Bard][Skill.Skill3] = "Free Compliments";
        skillStrings[Class.Bard][Skill.Skill4] = "A Twinkling Eye";
        skillStrings[Class.Necromancer][Skill.Skill1] = "Skeleton Army";
        skillStrings[Class.Necromancer][Skill.Skill2] = "Brittle Bones";
        skillStrings[Class.Necromancer][Skill.Skill3] = "Suspicious Pet";
        skillStrings[Class.Necromancer][Skill.Skill4] = "Pestilence";
        skillStrings[Class.Priest][Skill.Skill1] = "Healing Prayer";
        skillStrings[Class.Priest][Skill.Skill2] = "Touch of Light";
        skillStrings[Class.Priest][Skill.Skill3] = "Soothing Aura";
        skillStrings[Class.Priest][Skill.Skill4] = "Shackles from Above";
        skillStrings[Class.Rogue][Skill.Skill1] = "Pickpocket";
        skillStrings[Class.Rogue][Skill.Skill2] = "Fan of Knives";
        skillStrings[Class.Rogue][Skill.Skill3] = "Shadow Strike";
        skillStrings[Class.Rogue][Skill.Skill4] = "Poisoned Blade";
    }

    function buildMetadata(CharacterData memory data) public view override returns (string memory) {
        // MUST CONCATENATE THESE STRINGS IN THIS ORDER
        return string.concat(_buildCharacterMetadata(data), _buildStatsMetadata(data.userDefinedData.stats));
    }

    function _buildCharacterMetadata(CharacterData memory data) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            data.userDefinedData.name,
                            '", "description":"',
                            "Element Protocol",
                            '", "image": "',
                            imageIpfsUrls[data.userDefinedData.race][data.userDefinedData.gender],
                            '", "attributes": ',
                            "[",
                            '{"trait_type": "Affinity",',
                            '"value":"',
                            data.userDefinedData.affinity,
                            '"},',
                            '{"trait_type": "Region",',
                            '"value":"',
                            regionStrings[data.randomizedData.region],
                            '"},',
                            '{"trait_type": "Trait 1",',
                            '"value":"',
                            traitStrings[data.userDefinedData.race][data.randomizedData.traits[0]],
                            '"},',
                            '{"trait_type": "Trait 2",',
                            '"value":"',
                            traitStrings[data.userDefinedData.race][data.randomizedData.traits[1]],
                            '"},',
                            '{"trait_type": "Skill 1",',
                            '"value":"',
                            skillStrings[data.userDefinedData.class][data.randomizedData.skills[0]],
                            '"},',
                            '{"trait_type": "Skill 2",',
                            '"value":"',
                            skillStrings[data.userDefinedData.class][data.randomizedData.skills[1]],
                            '"},',
                            '{"trait_type": "Race",',
                            '"value":"',
                            raceStrings[data.userDefinedData.race],
                            '"},',
                            '{"trait_type": "Gender",',
                            '"value":"',
                            genderStrings[data.userDefinedData.gender],
                            '"},',
                            '{"trait_type": "Class",',
                            '"value":"',
                            classStrings[data.userDefinedData.class],
                            '"},'
                        )
                    )
                )
            );
    }

    function _buildStatsMetadata(Stats memory stats) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    bytes(
                        abi.encodePacked(
                            '{"trait_type": "Strength",',
                            '"value":"',
                            Strings.toString(stats.strength),
                            '"},',
                            '{"trait_type": "Dexterity",',
                            '"value":"',
                            Strings.toString(stats.dexterity),
                            '"},',
                            '{"trait_type": "Charisma",',
                            '"value":"',
                            Strings.toString(stats.charisma),
                            '"},',
                            '{"trait_type": "Wisdom",',
                            '"value":"',
                            Strings.toString(stats.wisdom),
                            '"},',
                            '{"trait_type": "Intelligence",',
                            '"value":"',
                            Strings.toString(stats.intelligence),
                            '"},',
                            '{"trait_type": "Constitution",',
                            '"value":"',
                            Strings.toString(stats.constitution),
                            '"}',
                            "]",
                            "}"
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { UserDefinedData } from "../ElementTypes.sol";

interface IElement {
    event ElementMint(uint256 tokenId, uint256 requestId);

    function mint(UserDefinedData calldata data) external payable;

    function mintFromExisting(
        address collection,
        uint256 tokenId,
        UserDefinedData calldata data
    ) external payable;
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { Stats } from "../ElementTypes.sol";

library ElementUtils {
    function verifyStats(Stats calldata stats) internal pure returns (bool) {
        uint256 total = stats.strength +
            stats.dexterity +
            stats.charisma +
            stats.wisdom +
            stats.intelligence +
            stats.constitution;

        return total == 100;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { CharacterData } from "../ElementTypes.sol";

interface IElementMetadata {
    function buildMetadata(CharacterData memory data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
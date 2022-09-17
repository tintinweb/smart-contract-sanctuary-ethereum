// SPDX-License-Identifier: MIT

//  ___             __  __  __   
//   |  /\ |\/| /\ / _ /  \/ _ | 
//   | /--\|  |/--\\__)\__/\__)| 
// 
//  Tamagogi is a fully onchain tamagotchi dapp.
//  https://tamagogi.xyz 

pragma solidity ^0.8.7;

import "https://github.com/RollaProject/solidity-datetime/blob/master/contracts/DateTimeContract.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "base64-sol/base64.sol";
import "./tamagogi_drawer.sol";


contract Tamagogi is Ownable, ERC721A, ReentrancyGuard, TamagogiDrawer {
    struct TMGG {
        string name;
        uint lastFeed;
        uint lastPlay;
        uint lastHit;
        uint birthhash;
    }

    struct PetMdata {
        uint tokenId;
        uint seed;
        uint hunger;
        uint bored;
        uint unhappiness;
        bool isMaster;
        bool rerollable;
    }

    struct Config {
        uint price;
        uint propMaxSupply;
        uint petMaxSupply;
        uint[3] hungerRate;
        uint[3] boredRate;
        uint[3] hitRate;
        uint[3] hitRasing;
        uint[5] reactionRate;
        bool revealProp;
        bool revealPet;
        MintStage mintStage;
    }

    //@@@ enum
    enum MintStage {
        PAUSED,
        PROPS,
        PETS_MERKLE,
        PETS
    }

    //@@@ event
    event EPlay(
       uint tokenId,
       address sender
    );
    event EHit(
       uint tokenId,
       address sender
    );
    event EFeed(
       uint tokenId,
       address sender
    );

    constructor() ERC721A("Tamagogi Pets", "TAMAGOGI") {
        config.price = 0;
        config.propMaxSupply = 2000;
        config.petMaxSupply = 1825;
        config.mintStage = MintStage.PAUSED;
        config.hungerRate = [8,40,120];
        config.boredRate = [6,30,90];
        config.hitRate = [4,20,60];
        config.hitRasing = [9,3,1];
        config.reactionRate = [0,10,20,30,40];
        config.revealProp = false;
        config.revealPet = false;
    }
    
    DateTimeContract private dateTimeContract = new DateTimeContract();
    bytes32 public rootHash = 0x0;

    Config public config;

    mapping(uint => uint) public seeds;
    mapping(uint => TMGG) public TMGGs;
    mapping(uint => bool) public rerollTable;
    mapping(string => bool) public nameTable;
    mapping(address => bool) public propMinted;
    mapping(address => bool) public petMinted;

    uint private bornTimestamp = 1640995201;
    uint private bornIdx = 0;
    uint private airdropId = 1;
    uint public airdropProgress = 0;
    uint public airdropReceivers = 947;

    //@@@ modifier
    modifier validToken(uint tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Not valid id");
        _;
    }

    modifier validOwner(uint tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You are not token's owner");
        _;
    }

    modifier revealPetOnly() {
        require(config.revealPet, "Not reveal");
        _;
    }

    modifier petOnly(uint tokenId) {
        require(tokenId > config.propMaxSupply && tokenId <= config.petMaxSupply + config.propMaxSupply, "Not valid pet id");
        _;
    }

    //@@@ mint
    function _getProp(address _address, uint quantity) private {
        for (uint i = 0; i < quantity; i ++) {
            uint seed = _getRandom(airdropId);
            seeds[airdropId] = seed;
            airdropId++;
        }

        _safeMint(_address, quantity);
    }

    function airdrop(address[] calldata addresses, uint256[] calldata quantity) external onlyOwner {
        require(airdropProgress + addresses.length <= airdropReceivers, "Exceed the limit");
        for (uint i = 0; i < addresses.length; i ++) {
            _getProp(addresses[i], quantity[i]);
        }
        airdropProgress += addresses.length;
    }

    function hatchEgg() external payable {
        require(config.mintStage == MintStage.PETS, "Not in stage to mint TMGG");
        require(_totalMinted() < config.petMaxSupply + config.propMaxSupply, "No pet left");
        require(!petMinted[msg.sender], "Max to 1");
        require(1 * config.price <= msg.value,"No enough eth.");
        _hatchEgg();
    }

    function allowlistHatchEgg(bytes32[] calldata _proof) external payable {
        require(config.mintStage == MintStage.PETS_MERKLE, "Not in stage to mint merkle TMGG");
        require(_totalMinted() < config.petMaxSupply + config.propMaxSupply, "No pet left");
        require(!petMinted[msg.sender], "Max to 1");
        require(1 * config.price <= msg.value,"No enough eth.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, rootHash, leaf), "invalid proof");
        _hatchEgg();
    }

    function _hatchEgg() private {
        uint mintId = _startTokenId() + _totalMinted();
        if (bornIdx == 5) {
            bornIdx = 0;
            bornTimestamp = dateTimeContract.addDays(bornTimestamp, 1);
        }

        TMGG memory preBornTMGG = TMGG('', block.timestamp, block.timestamp, 0, bornTimestamp);
        TMGGs[mintId] = preBornTMGG;
        bornIdx++;
        
        uint seed = _getRandom(mintId);
        seeds[mintId] = seed;

        _safeMint(msg.sender, 1);
        petMinted[msg.sender] = true;
    }
    
    //@@@ pet function

    function setName(uint tokenId, string calldata name) external validOwner(tokenId) revealPetOnly() petOnly(tokenId) {
        require(nameTable[name] == false, "Name exist");

        uint nameLength = utfStringLength(name);

        require(nameLength > 1 && nameLength < 18, "Not valid name");
        TMGGs[tokenId].name = name;
        nameTable[name] = true;
    }

    // everyone can call these function to feed, hit or play with any pet
    function play(uint tokenId) external revealPetOnly() petOnly(tokenId) {
        TMGGs[tokenId].lastPlay = block.timestamp;
        emit EPlay(tokenId, msg.sender);
    }

    function feed(uint tokenId) external revealPetOnly() petOnly(tokenId) {
        TMGGs[tokenId].lastFeed = block.timestamp;
        emit EFeed(tokenId, msg.sender);
    }

    function hit(uint tokenId) external revealPetOnly() petOnly(tokenId) {
        TMGGs[tokenId].lastHit = block.timestamp;
        emit EHit(tokenId, msg.sender);
    }

    function reroll(uint tokenId) external validOwner(tokenId) revealPetOnly() petOnly(tokenId) {
        require(!rerollTable[tokenId], "Not available");
        seeds[tokenId] = _getRandom(tokenId);
        rerollTable[tokenId] = true;
    }
    
    function isBirthdate(uint tokenId) public view petOnly(tokenId) returns (bool) {
        TMGG memory tmgg = TMGGs[tokenId];
        uint _now = block.timestamp;
        
        uint seed = seeds[tokenId];
        uint offset = seed % 31536000;

        return dateTimeContract.getDay(_now) == dateTimeContract.getDay(tmgg.birthhash + offset) && dateTimeContract.getMonth(_now) == dateTimeContract.getMonth(tmgg.birthhash + offset);
    }

    function getBirthdate(uint tokenId) public view petOnly(tokenId) returns (uint month, uint day) {
        TMGG memory tmgg = TMGGs[tokenId];

        uint seed = seeds[tokenId];
        uint offset = seed % 31536000;

        uint _month = dateTimeContract.getMonth(tmgg.birthhash + offset);
        uint _day = dateTimeContract.getDay(tmgg.birthhash + offset);

        return (_month, _day);
    }

    function getPetUnhappinessAndProp(uint tokenId) public view revealPetOnly() petOnly(tokenId) returns(uint, bool, bool ,bool) {
        uint _now = block.timestamp;
        TMGG memory tmgg = TMGGs[tokenId];
        uint hunger = dateTimeContract.diffHours(tmgg.lastFeed, _now);
        uint bored = dateTimeContract.diffHours(tmgg.lastPlay, _now);
        uint _baseHit = tmgg.lastHit == 0 ? 0 : (_now - tmgg.lastHit) / 60;

        uint hitVal = 0;
        if (_baseHit <= config.hitRate[0]) {
            hitVal = _baseHit * config.hitRasing[0];
        } else if (_baseHit < config.hitRate[1]) {
            hitVal = _baseHit * config.hitRasing[1];
        } else if (_baseHit < config.hitRate[2]) {
            hitVal = _baseHit * config.hitRasing[2];
        } else {
            hitVal = _baseHit * 0;
        }

        uint[] memory ownerTokens = tokensOfOwner(ownerOf(tokenId));
        bool ownFood = false;
        bool ownToy = false;
        bool ownShield = false;

        for(uint i = 0; i < ownerTokens.length; i++) {
            uint id = ownerTokens[i];

            if (id <= config.propMaxSupply) {
                uint seed = seeds[id];
                uint propNumber = propOdds[seed % propOdds.length];

                if (propNumber == 0) { // own food
                    hunger = 0;
                    ownFood = true;
                } else if (propNumber == 1) { // own toy
                    bored = 0;
                    ownToy = true;
                } else if (propNumber == 2) { // own shiled
                    hitVal = 0;
                    ownShield = true;
                }
            }
        }

        uint _unhappiness = hunger + bored + hitVal;

        return (_unhappiness, ownFood, ownToy, ownShield);
    }

    function getPetHungerAndBored(uint tokenId) public view revealPetOnly() petOnly(tokenId) returns(uint, uint) {
        uint _now = block.timestamp;
        TMGG memory tmgg = TMGGs[tokenId];
        uint hunger = dateTimeContract.diffHours(tmgg.lastFeed, _now);
        uint bored = dateTimeContract.diffHours(tmgg.lastPlay, _now);

        uint[] memory ownerTokens = tokensOfOwner(ownerOf(tokenId));
        for(uint i = 0; i < ownerTokens.length; i++) {
            uint id = ownerTokens[i];

            if (id <= config.propMaxSupply) {
                uint seed = seeds[id];
                uint propNumber = propOdds[seed % propOdds.length];

                if (propNumber == 0) { // own food
                    hunger = 0;
                } else if (propNumber == 1) { // own toy
                    bored = 0;
                }
            }
        }

        return (hunger, bored);
    }

    function _getReactionTraitIndex(uint _unhappiness) private view returns (uint) {
        if (_unhappiness <= config.reactionRate[0]) {
            return reaction[3];
        } else if (_unhappiness < config.reactionRate[1]) {
            return reaction[0];
        } else if (_unhappiness < config.reactionRate[2]) {
            return reaction[1];
        } else if (_unhappiness < config.reactionRate[3]) {
            return reaction[2];
        } else {
            return reaction[4];
        }
    }

    function _getPetTraits(PetMdata memory petMeta) private pure returns (string memory) {
        string memory attr = string(abi.encodePacked(
            '{ "trait_type": "hunger", "display_type": "number", "value": ',Strings.toString(petMeta.hunger),'},',
            '{ "trait_type": "bored", "display_type": "number", "value": ',Strings.toString(petMeta.bored),'},'
        ));

        return attr;
    }

    function _getPetStyleTraits(PetMdata memory petMeta) private view returns (string memory) {
        string memory masterLabel = petMeta.isMaster ? "yes" : "no";
        string memory rerolled = petMeta.rerollable ? "yes" : "no";
        string memory attr = string(abi.encodePacked(
            '{ "trait_type": "type", "value": "pets"},',
            '{ "trait_type": "master", "value": "',masterLabel,'"},',
            '{ "trait_type": "rerolled", "value": "',rerolled,'"},',
            '{ "trait_type": "unhappiness", "display_type": "number", "value": ',Strings.toString(petMeta.unhappiness),'},',
            _getPetReactionTraits(petMeta),
            _getPetEarTraits(petMeta),
            _getPetHeadTraits(petMeta),
            _getPetBodyTraits(petMeta)
        ));

        return attr;
    }
    
    function _getPetReactionTraits(PetMdata memory petMeta) private view returns (string memory) {
        string memory attr = string(abi.encodePacked(
            '{ "trait_type": "reaction", "value": "',reactionTraits[_getReactionTraitIndex(petMeta.unhappiness)],'"},'
        ));

        return attr;
    }

    function _getPetEarTraits(PetMdata memory petMeta) private view returns (string memory) {
        string memory attr = string(abi.encodePacked(
            '{ "trait_type": "ear", "value": "',earTraits[ear[(petMeta.seed / 2) % ear.length]],'"},'
        ));

        return attr;
    }

    function _getPetHeadTraits(PetMdata memory petMeta) private view returns (string memory) {
        string memory attr = string(abi.encodePacked(
            '{ "trait_type": "head", "value": "',headTraits[head[(petMeta.seed / 3) % head.length]],'"},'
        ));

        return attr;
    }

    function _getPetBodyTraits(PetMdata memory petMeta) private view returns (string memory) {
        string memory attr = string(abi.encodePacked(
            '{ "trait_type": "body", "value": "',bodyTraits[body[(petMeta.seed / 4) % body.length]],'"},'
        ));

        return attr;
    }

    function _getPetsName(PetMdata memory petMeta) private view returns (string memory) {
        (uint month, uint day) = getBirthdate(petMeta.tokenId);
        TMGG memory tmgg = TMGGs[petMeta.tokenId];
        string memory name = utfStringLength(tmgg.name) > 1 ? string(abi.encodePacked(tmgg.name, " / ")) : "";

        return string(abi.encodePacked(
            '{"name": "',name,'#',Strings.toString(petMeta.tokenId),' Tamagogi (',Strings.toString(month),'/',Strings.toString(day),')','",'
        ));
    }

    function _getPetsBirthTrait(PetMdata memory petMeta) private view returns (string memory) {
        (uint month, uint day) = getBirthdate(petMeta.tokenId);

        return string(abi.encodePacked(
            '{ "trait_type": "birthdate", "value": "',Strings.toString(month),'/',Strings.toString(day),'"}'
        ));
    }

    function _getPetsMetadata(uint tokenId) private view returns (string memory) {
        (uint unhappiness, bool ownFood, bool ownToy, bool ownShield) = getPetUnhappinessAndProp(tokenId);
        (uint hunger, uint bored) = getPetHungerAndBored(tokenId);
        bool hbd = isBirthdate(tokenId);
        bool isMaster = ownFood && ownToy && ownShield || hbd ? true : false;
        uint reactionId = _getReactionTraitIndex(unhappiness);
        PetMdata memory petMeta = PetMdata(tokenId, seeds[tokenId], hunger, bored, unhappiness, isMaster, rerollTable[tokenId]);
        string memory _svgString = drawReveal(seeds[tokenId], reactionId, isMaster);

        string memory json = 
                string(
                    abi.encodePacked(
                        _getPetsName(petMeta),
                        '"description": "Tamagogi is a Tamagotchi Dapp and fully generated on-chain. The contract interaction and time will affect the status and reaction of the pet. If you collect other items, the pet will show love!",', 
                        '"attributes": [',
                            _getPetTraits(petMeta),
                            _getPetStyleTraits(petMeta),
                            _getPetsBirthTrait(petMeta),
                        '],'
                        '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(drawSVG(_svgString))), '"}' 
                        )
                    );

        return Base64.encode(
            bytes(
                string(json)
                )
            );
    }

    function _getPetsUnrevealMetadata(uint tokenId) private view returns (string memory) {
        (uint month, uint day) = getBirthdate(tokenId);
        uint _seed = seeds[tokenId];

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "#',Strings.toString(tokenId),' Tamagogi Egg (',Strings.toString(month),'/',Strings.toString(day),')','", "description": "Unbroken Tamagogi eggs...",',
                        '"attributes": [',
                            '{ "trait_type": "type", "value": "pets"},',
                            '{ "trait_type": "birthdate", "value": "',Strings.toString(month),'/',Strings.toString(day),'"}',
                        '],',
                        '"image": "ipfs://QmW1tccYqBmSLQFTfN8rWw8JHXxx7hZS4MiiwWWDN5tvG8/',Strings.toString(eggs[_seed % eggs.length]),'.gif"}' 
                        )
                    )
                )
            );

        return json;
    }

    function _getPropsMetadata(uint tokenId) private view returns (string memory) {
        uint _seed = seeds[tokenId];
        uint _propIndex = propOdds[_seed % propOdds.length];
        string memory _desc = propDesc[_propIndex];
        string memory _traitName = propTraits[_propIndex];

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "#',Strings.toString(tokenId),' Tamagogi (',_traitName,')", "description": "',_desc,'",',
                        '"attributes": [',
                            '{ "trait_type": "type", "value": "props"},',
                            '{ "trait_type": "usage", "value": "',_traitName,'"}'
                        '],',
                        '"image": "ipfs://QmVxCDfmwgY2psAh7wti8aLCykkj99snygGQ89p2zkfAtf/',_traitName,'.gif"}' 
                    )
                )
            )
        );

        return json;
    }

    function _getPropsUnrevealMetadata(uint tokenId) private pure returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "#',Strings.toString(tokenId),' Tamagogi (Unreveal Props)", "description": "Unreveal Props",',
                        '"attributes": [',
                            '{ "trait_type": "type", "value": "props"}',
                        '],',
                        '"image": "ipfs://QmTbB6DD2w8t36zLPvBEdoWo62RFMyJi9EXcj99ZixPrxC"}' 
                    )
                )
            )
        );

        return json;
    }

    //@@@ override
    function _tokenURI(uint256 tokenId) private view validToken(tokenId) returns (string memory) {
        string memory json = tokenId <= config.propMaxSupply ? config.revealProp ? _getPropsMetadata(tokenId) : _getPropsUnrevealMetadata(tokenId) : config.revealPet ? _getPetsMetadata(tokenId) : _getPetsUnrevealMetadata(tokenId);

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function tokenURI(uint256 tokenId) override (ERC721A) public view returns (string memory) {
        return _tokenURI(tokenId);
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
    }

    //@@@ admin

    function setMintStage(uint _stage) external onlyOwner {
        config.mintStage = MintStage(_stage);
    }
    function setHungerRate(uint[3] calldata _rate) external onlyOwner {
        config.hungerRate = _rate;
    }
    function setBoredRate(uint[3] calldata _rate) external onlyOwner {
        config.boredRate = _rate;
    }
    function setHitRate(uint[3] calldata _rate) external onlyOwner {
        config.hitRate = _rate;
    }
    function setReactionRate(uint[5] calldata _rate) external onlyOwner {
        config.reactionRate = _rate;
    }
    function setHitRasing(uint[3] calldata _rate) external onlyOwner {
        config.hitRasing = _rate;
    }
    function setRevealPet() external onlyOwner {
        config.revealPet = true;
    }
    function setRevealProp() external onlyOwner {
        config.revealProp = true;
    }
    function setPrice(uint _price) external onlyOwner {
        config.price = _price;
    }
    function setMerkle(bytes32 _hash) external onlyOwner {
        rootHash = _hash;
    }

    //@@@ others

    // ERC721AQueryable.sol
    function tokensOfOwner(address owner) public view virtual returns (uint256[] memory) {
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

    // https://ethereum.stackexchange.com/questions/13862/is-it-possible-to-check-string-variables-length-inside-the-contract
    function utfStringLength(string memory str) pure internal returns (uint length) {
        uint i=0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0)
                i+=1;
            else if (string_rep[i]>>5==bytes1(uint8(0x6)))
                i+=2;
            else if (string_rep[i]>>4==bytes1(uint8(0xE)))
                i+=3;
            else if (string_rep[i]>>3==bytes1(uint8(0x1E)))
                i+=4;
            else
                //For safety
                i+=1;

            length++;
        }
    }
    
    function _getRandom(uint tokenId) private view returns (uint) {
        uint randomlize = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, msg.sender)));
        return randomlize;
    }
}

pragma solidity ^0.8.7;
import "base64-sol/base64.sol";
import "./tamagogi_data.sol";
// SPDX-License-Identifier: MIT

contract TamagogiDrawer is TamagogiData {
    function drawImage(bytes memory trait) private pure returns (string memory) {
      return string(abi.encodePacked(
        '<image x="0" y="0" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',Base64.encode(bytes(trait)),'"/>'
      ));
    }

    function drawReveal(uint seed, uint reactionId, bool isMaster) internal view returns (string memory) {
        bytes memory bodyImageData = bodyBytes[(seed / 4) % body.length];
        bytes memory headImageData = headBytes[(seed / 3) % head.length];
        bytes memory earImageData = earBytes[(seed / 2) % ear.length];
        bytes memory reactionImageData = reactionBytes[reactionId];

        string memory imgString = string(abi.encodePacked(
            drawImage(bodyImageData),
            drawImage(headImageData),
            drawImage(reactionImageData),
            drawImage(earImageData)
          ));

        if (isMaster) { //master
          imgString = string(abi.encodePacked(
              imgString,
              drawImage(masterBytes[0])
          ));
        }

        return imgString;
    }

    function drawSVG(string memory svgString) internal pure returns (string memory) {
        return string(abi.encodePacked(
          '<svg width="960" height="960" version="1.1" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          '<rect width="100%" height="100%" fill="#aad999" />',
          svgString,
          "</svg>"
        ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

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

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
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
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
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
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

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
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
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

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
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
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
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
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
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
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
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
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
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
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
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
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
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
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
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

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

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
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
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
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

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
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

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
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
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
    ) internal virtual {
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
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

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

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
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
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
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

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
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
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0 - Contract Instance
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/DateTime
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

import "./DateTime.sol";

contract DateTimeContract {
    uint256 public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 public constant SECONDS_PER_HOUR = 60 * 60;
    uint256 public constant SECONDS_PER_MINUTE = 60;
    int256 public constant OFFSET19700101 = 2440588;

    uint256 public constant DOW_MON = 1;
    uint256 public constant DOW_TUE = 2;
    uint256 public constant DOW_WED = 3;
    uint256 public constant DOW_THU = 4;
    uint256 public constant DOW_FRI = 5;
    uint256 public constant DOW_SAT = 6;
    uint256 public constant DOW_SUN = 7;

    function _now() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    function _nowDateTime()
        public
        view
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        (year, month, day, hour, minute, second) = DateTime.timestampToDateTime(block.timestamp);
    }

    function _daysFromDate(uint256 year, uint256 month, uint256 day) public pure returns (uint256 _days) {
        return DateTime._daysFromDate(year, month, day);
    }

    function _daysToDate(uint256 _days) public pure returns (uint256 year, uint256 month, uint256 day) {
        return DateTime._daysToDate(_days);
    }

    function timestampFromDate(uint256 year, uint256 month, uint256 day) public pure returns (uint256 timestamp) {
        return DateTime.timestampFromDate(year, month, day);
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
        public
        pure
        returns (uint256 timestamp)
    {
        return DateTime.timestampFromDateTime(year, month, day, hour, minute, second);
    }

    function timestampToDate(uint256 timestamp) public pure returns (uint256 year, uint256 month, uint256 day) {
        (year, month, day) = DateTime.timestampToDate(timestamp);
    }

    function timestampToDateTime(uint256 timestamp)
        public
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        (year, month, day, hour, minute, second) = DateTime.timestampToDateTime(timestamp);
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) public pure returns (bool valid) {
        valid = DateTime.isValidDate(year, month, day);
    }

    function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
        public
        pure
        returns (bool valid)
    {
        valid = DateTime.isValidDateTime(year, month, day, hour, minute, second);
    }

    function isLeapYear(uint256 timestamp) public pure returns (bool leapYear) {
        leapYear = DateTime.isLeapYear(timestamp);
    }

    function _isLeapYear(uint256 year) public pure returns (bool leapYear) {
        leapYear = DateTime._isLeapYear(year);
    }

    function isWeekDay(uint256 timestamp) public pure returns (bool weekDay) {
        weekDay = DateTime.isWeekDay(timestamp);
    }

    function isWeekEnd(uint256 timestamp) public pure returns (bool weekEnd) {
        weekEnd = DateTime.isWeekEnd(timestamp);
    }

    function getDaysInMonth(uint256 timestamp) public pure returns (uint256 daysInMonth) {
        daysInMonth = DateTime.getDaysInMonth(timestamp);
    }

    function _getDaysInMonth(uint256 year, uint256 month) public pure returns (uint256 daysInMonth) {
        daysInMonth = DateTime._getDaysInMonth(year, month);
    }

    function getDayOfWeek(uint256 timestamp) public pure returns (uint256 dayOfWeek) {
        dayOfWeek = DateTime.getDayOfWeek(timestamp);
    }

    function getYear(uint256 timestamp) public pure returns (uint256 year) {
        year = DateTime.getYear(timestamp);
    }

    function getMonth(uint256 timestamp) public pure returns (uint256 month) {
        month = DateTime.getMonth(timestamp);
    }

    function getDay(uint256 timestamp) public pure returns (uint256 day) {
        day = DateTime.getDay(timestamp);
    }

    function getHour(uint256 timestamp) public pure returns (uint256 hour) {
        hour = DateTime.getHour(timestamp);
    }

    function getMinute(uint256 timestamp) public pure returns (uint256 minute) {
        minute = DateTime.getMinute(timestamp);
    }

    function getSecond(uint256 timestamp) public pure returns (uint256 second) {
        second = DateTime.getSecond(timestamp);
    }

    function addYears(uint256 timestamp, uint256 _years) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.addYears(timestamp, _years);
    }

    function addMonths(uint256 timestamp, uint256 _months) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.addMonths(timestamp, _months);
    }

    function addDays(uint256 timestamp, uint256 _days) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.addDays(timestamp, _days);
    }

    function addHours(uint256 timestamp, uint256 _hours) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.addHours(timestamp, _hours);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.addMinutes(timestamp, _minutes);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.addSeconds(timestamp, _seconds);
    }

    function subYears(uint256 timestamp, uint256 _years) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.subYears(timestamp, _years);
    }

    function subMonths(uint256 timestamp, uint256 _months) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.subMonths(timestamp, _months);
    }

    function subDays(uint256 timestamp, uint256 _days) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.subDays(timestamp, _days);
    }

    function subHours(uint256 timestamp, uint256 _hours) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.subHours(timestamp, _hours);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.subMinutes(timestamp, _minutes);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) public pure returns (uint256 newTimestamp) {
        newTimestamp = DateTime.subSeconds(timestamp, _seconds);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 _years) {
        _years = DateTime.diffYears(fromTimestamp, toTimestamp);
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 _months) {
        _months = DateTime.diffMonths(fromTimestamp, toTimestamp);
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 _days) {
        _days = DateTime.diffDays(fromTimestamp, toTimestamp);
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 _hours) {
        _hours = DateTime.diffHours(fromTimestamp, toTimestamp);
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 _minutes) {
        _minutes = DateTime.diffMinutes(fromTimestamp, toTimestamp);
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) public pure returns (uint256 _seconds) {
        _seconds = DateTime.diffSeconds(fromTimestamp, toTimestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
        internal
        pure
        returns (uint256 timestamp)
    {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR
            + minute * SECONDS_PER_MINUTE + second;
    }

    function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        }
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
        internal
        pure
        returns (bool valid)
    {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (,, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
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
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
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

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract TamagogiData {
    //@@@ props
    uint[10] internal propOdds = [0,0,0,0,1,1,1,1,2,2];
    string[3] internal propTraits = ["food", "toy", "shield"];
    string[3] internal propDesc = ["Food will be able to prevent your pet from starvation.","Toys can keep your pet from being bored.","Shield to protect your pet from being hit."];

    //@@@ pets
    uint[3] internal eggs = [1,2,3];

    uint[13] internal ear = [0,1,2,3,4,5,6,7,8,9,10,11,12];
    uint[5] internal reaction = [0,1,2,3,4];
    uint[11] internal head = [0,1,2,3,4,5,6,7,8,9,10];
    uint[11] internal body = [0,1,2,3,4,5,6,7,8,9,10];

    string[13] internal earTraits = ["Melody","Cinna","Racoon","Long ear","Dog","Teddy","Trapa","Shorthair","Rabbit","Mick","Mouse","Bear","Cat"];    
    string[5] internal reactionTraits = ["Normal","Angry","Sad","Smile","Upset"];
    string[11] internal headTraits =  ["Horn","Whiskers","Whiskers fat","Fluffy","Whiskers thin","Square","Hamster","Normal","Cricetinae","Naja","Plump"];
    string[11] internal bodyTraits =  ["Sit","Dress","Stand","Huddle up","Feeble","Star","Clothes","Strong","Squat","Hulk","Long legs"];

    bytes[1] internal masterBytes = [bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af4000000017352474200aece1ce900000066494441545847edd5310e00100c85613d8efb1fc67108092961914a0dbfc540f25e3f0309ce4b9cf30305104000010410f84720c7982525e9fb8b5f7297d104eac11a58cb589638658c107dc13abc0fb2cb98a67cc9af4be8014d996f9e8c02082080000208145bcb2821effa51fe0000000049454e44ae426082')];
    bytes[13] internal earBytes = [bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000080494441545847ed94410ac0200c04f5ff8f6ec921250475d7da22c87ad48d1927602d9b57dddcbf30005782ecd5e49c95c1fb51c02ecd196f14f75b3903e8ed3f6f1a01a0623f6773cd69af00f80b91ea21203382b70d284308c0b5cd6a8ef925032c401c4736f609c06fdf053b0201c8800cc8800cc8800cc8800cc8c0b9066edd51182171bab4cb0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c0864880000008f494441545847ed93d10e80200845f5ff3fba461b8de80a526daeedf6a628f778b4de167f7d717efb05c0662c09b01d23817e4d78c8cc8084d9357e8c004a7b228052234732bd1701a8e2cc4ef5fdc2be5eaf34ad2acf40908d3347c3d0ddeadcccbd8f20a21e476d04f0263483d1fa054026fdef96a97d52bf657cfdd0ca5004a0011aa0011aa0011aa0011aa0811d3de21d21bb35e40a0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c0864880000006c494441545847edd4d10a4011108461deffa14951d2b2e342a8ff5c9d8bc98e8fc470f98b97e7876f0aa42aa51696f3ca8265b196ebff67a7b795f70a5803572576f3ee1d980d6bc4a382b5a1a5daf3026587cab92bf7c1cc7802c79f090a2080000208208000020820804006486e132187d8c7c60000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000072494441545847ed94510a00210844ebfe876e290844dacd8996085e7fd1a8e353cae9f0c987eba7a881628cce62146dc8404d688bfabb85a8685bdcac9baa51922ada7b0d742aa3fdf544bfc6b544a02fd8dbe8fcfb1603b6e3c8ce48fa68c2dfbe0b0c40000210800004200001084000020fc5ac172190ff741b0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000075494441545847ed92410ec0200804f5ff8f6ee381a4c12a0b1ebc8ce765990cf676f9f5cbfb5b04f038c0286f71796e57e84bac3c8248cdadca5625a7179bf6650046768029062ceb81cb00eaf2ef1ff88328016497ef206400af4e515f9a89ee79fae9c279003080010c60000318c0000630808117a9bd1321772d676e0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c0864880000007e494441545847ed92510ac0300843dbfb1f7a459820d22e993f52c8be0a33f1edad73343fb379ff60009e1792998ddf43e550a995f84c3c237174ee0b2097a0a5bbf7109e017095b6001973889c39da438595e52788ad410460a13fff3e2f81d92b002a978fce3006e8b2caa00064400664400664400664400664a0ddc00276971321672fab0a0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000074494441545847ed94310ec0200cc4e0ff8f2e4202d481e452a062317372674cd59c2e9f7cb93f298067027874c70b9b95771e6beff3ce4a9005e1959be03b0035b4ef47cadff3e365d57bd6c168b8f53dbb1d11801d08992f07dab5562dc87c39f0f77f02000c60000318c000063080010c60a000b8610b216fdcaceb0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000070494441545847ed92410ac0200c04f5ff8f6e9b4341aa761772082de34590641d27f656bc7af1fded3300c7652a609ffb28d0a999843b0676c1713eae15e0ddbb9db4029001c61f7acd5000919f8190bd0a4006fcde80f1c05c891a412edde806000318c000063080010c600003e5064e048315215641d2fc0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000068494441545847ed94610b00100c44f9ff3f9a28b5165792d6eaf9a6e1eede965a82570dd62fe90c3443cc9b57b523e81b0243c09eb77b55935d4e63c0271ca914015f7f6e41a8819df84ab406efd44a7577be7133035fbe0c0c40000210800004200001084000021df3d61521c08b49860000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000067494441545847ed93410a00200cc3f4ff8f56100411ba513d8810cfb5ed32ade5f1a98ff3cb1705da46292b6de95db3d945dddbc3337db80265a64c5dfdf08908b886aefebac03a40162e873d7d03eeef9539590137c8d6530002108000042000010840000210e80b6d0b213ce71b1e0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000068494441545847ed94c10a00101404f9ff8f2607a5478c835cc64dedee5b4372fabcf2e7f9c902844019ae89e89b1c7b4e812d68d4c4fdea095d796e0bc4d3ad0ac4cc6de953813e90e8088d49438309fa188e3cb4c0b3efc20212908004242001094840021290400533b70d21044e4ab70000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000065494441545847edd4dd0a00100c8661bbff8ba61d90ffad24a9d7216bfb3c8984c74b1ecf0fdf04889dd42ab8b7aeb4f30868d3beee64afb98b1560362837a8cfbc75c393238025a06416afd6ec1ee5768627c0d5af82000820800002082080000208209000f7ce15214de4787a0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c0864880000006d494441545847ed93410ac0200c04f5ff8f5602e6225476410896e979b39d0cb1b7e2af17ffbf3d0130962517569a534ab32838947ce4e419a530ca22276db4e572f6f3d41c807db3d3fd66ef7500f7d1fc03c0dddaca2b376015ba61003080010c60000318c0000630506e6002f73b0f211a4494500000000049454e44ae426082')];
    bytes[5] internal reactionBytes = [bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c0864880000005f494441545847edd5bb0a00200846617dff87ae961a44f042e0721a237fe51b5265f8e8707f61000410400081aac03a5f77549379f3364014665745263cf3a63d80b7bb4a0d6d4055c013b977adac56d1cf15ce0008208000020820302eb00182580621fa639d260000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c0864880000005e494441545847ed95390e00200cc3e8ff1fcd3180104294b64317334362792052928f24f717003080010c60c06aa0f6af5b7bf373672d8016769b8a5781a97c847b004e2873e91e100598e56e88284078cd01c000063080010c6020dd4003cbd40721aa0beb880000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000061494441545847ed95410a00200804ebff8f2e3a142115ae045ea6abad4e73b05a924f4d9e5f00c00006308001d540db56b7cdbe6ad78daf028c4663d02df7aa1d215400cf00cf9d05a302d8574cede13ee1e0af6f1c000c60000318c00006d20d745ccf0721d52fc6040000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c0864880000005b494441545847edd5310e0020080441f9ffa3550a3b20014968d69620e714226bf8c8f0fc450004104000818ac0bedfb7d717d5cc5f3f1be00db006453577e56403b4efaedf00fa6a3de57bca8d5d1404400001041040008171810356ee0721ed9f05790000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000063494441545847ed954b0a00200844f3fe87eeb3898848cdc0cd6b6d33d3131a29c94792fd0b012000010840c04ba0f6af5bbb6399990da0899daae266e0321fe2de001603cb4c88c04a6598bd3ce45b80709b7b571036dc05080001084000021080400354df0721739252ba0000000049454e44ae426082')];
    bytes[11] internal headBytes = [bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000074494441545847ed94410ec0200cc3e0ff8f66e3c01192954905c99c9bd432526b497e35797f01000318b8c6407befc557582be3945a45938326b30a4016189774d9b102f863f9e09b761d6d40d2efeaef7965a0cfec7c85cc3a005108b9dc3560988e8fb806e21b4412000c60000318c040ba81073af6102143c1dc740000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af4000000017352474200aece1ce900000072494441545847ed943112c0200804cf49feffe214190a6752c1450a2dd65a605d9021e9d2c63300c000063060187824dd8bbbaa8cad165199c0004b73380051a363208dcf0082bc537cca49f31c6d205eb0750666f10e4499a36ac1b78f7f07d10277018cdfb67605000c60000318c000065e01921281db558cba0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c0864880000006a494441545847ed944b0a00200844ebfe87eeb310dae88404153c5741cc383cc55a2e57bddcbf10000210f882401bb7221b546a95b134d83864a14714e04473cbe77a7901a6c04a515210422f083c4b605d9ef9ceee81cddfd5678dd5e26dff130002108000042000810e4ece1021878663410000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c0864880000005b494441545847ed94db0900200cc474ffa17d2c604a058b10bfbdf408b4bd15bf5e3cbf5940031af8c2c058b7225b14b3044640e0901d195460f36f4a60960a2040031a7861203023ff85b6204f0e262da0010d6840031a283730013af6102192d097b20000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000060494441545847edd6cb0a0020084451fdff8feeb16813e4580411dcd669c31124b7c7c71fbf6f044000812f044adb15a741656da6b16c122c33594b804860f049c6c408963dd4087ae138eaee9c23558bc02eebf5ef030110400001041040a0028cd31421444923dc0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000049494441545847edd6410a00200804c0fcffa3ab17a40421c17857973988319a2b9af70f010810f84260ee5b711b34edad0c4e871c8e59da2b0001021581a72f8300040810204080c0023af610215e442abd0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000064494441545847ed94490e00200803f1ff8f763978841a354193e16a6ceb80144bae92ec6f04800004be2050fbaed80d2aef2a6129b0b0c8428da703dc78fd04e46a79046e9a872108100de168c32835a8ea23843aa7e2ca5c9e13000210800004200081063eee1021a0220e8e0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000061494441545847ed94410e00100c04f5ff8f460f8eac20a926e3cc760cad95e065c1f50b0018c0400a03b5cf8a5350795605cb808d41b6ccf81ae0c5ed87a069d6ca403880d3bf80c8fb07e4fbdd76809f575db051e36e0b0018c000063080010c343af61021f9935c500000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000067494441545847ed954b0a00200805f3fe87eeb368994f2ab0605ae77318c3ac241f4bee5f00c00006be3050fbaed80595b5916019e22c33590b8032201506fe1237c303b8d17cf22db39e0618f4372c6c8f2030def32bea119e7710090060000318c00006d20d343af6102106b4da3d0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000060494441545847ed96410a00200804f3ff8f2e844e511a68e461bab74ea348d23e1ff95cbf0180010c9436d0e78e88429a39a770bd142dbceeb86d2600650d68ff32e7e098e50d5a068499e101444db80fb80178fa6500000318c00006308081013eee10210f9b3be30000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000072494441545847ed94310e00210804f5ff8ff68ec2c4e2803d43a2c55859c0b219597b3b7cfae1f90d031080804260bc5155eabe129df666c2a980f08f841a91818ae1d39fabe519a81c1e9ac0c0b504ecdd2af7e0f712ae8b63f72cae5e1a6d70d8bf2b2cc45f2bc10004200001084000020fec3f1221ce89b1720000000049454e44ae426082')];
    bytes[11] internal bodyBytes = [bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c086488000000b9494441545847ed96c10e80200c4321faff5fec4139cce0dc68410c979178215bf7a81b21a794b6eb5bb672008403e14038100e8403e140384038705c31fbe08b05e6b20f1228640052390c0025e4380473110014207e4d53a30530a3b8f0b95a1ec08ce2b5c6278051189d67ea300e588965afac7a3cbd3d89e90228e2226815d2a22dbb2db0bb77d1140888770a298c00dc8b8c01d010f5e4590008fa31b97f01c0f193001640f70471ffbc9ad4cce901608b76c52d073801df502d81d35c52b50000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c086488000000a4494441545847ed964b0ac0200c05957aff1377515d0444f2796ac1169e20144c759c1831a794aeda8fb54c001aa0011aa0011aa0011a000cdc35a62cbe58c27f9107493f49fb9636426963db00e304b3000dd685f00c788b2319e90d991016c0eee25a9a5488cf0248ee10d5688c5a494815ecc084e5fb2b006d375296d6d86b06ac7ab600c20b480e0e9a0289ef2f22eff0853b5f05404f3c1c376b009e180d3c0ef000b15d1d81d94175870000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c086488000000a6494441545847ed96c10a80201883957aff27ee501e0493e9e6df218405dedcfcfe39c29c523a9ef5db970de0049c801370024ec009ec90c0f5409ec10703d5aaef016a0400258d0220190d12a25a06400d84ab997acc007ae10a8cac1d01208332ac5ac6a2eff7c30114802a8c24d06a96000a7d3f450400f9bc6ac34ad86e8e024c7bfa05a026540f68fb21c34601d001f4be51145b01d04281e2d2ffd44a02d42cb2c10037c7f12981ef4fbe3c0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c086488000000a0494441545847ed96c10a8020104495faff2fee907b30ac5667b6840e8d10c4e2eaf3b98a39a5b494efb396052003322003322003322003a481adf45b83af162a877990500375e0602e02f006b098b5ab9151bc6b2f0ad00231ff063ab41001e84d58edb340a7dd8a00046bf0e83ecdc03f016011012daf8fa157606dac9ddf3b96f0f24245e81988dc03530dd4d5a2555540efb2baed1863e069f5537902d801343f25816dd4601b0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c086488000000a2494441545847ed964b0ac030084413dafb9fb88bc642200dea980f94c204bad2eae4f92139a57494efb3932980044880044880044880040204aee2734ebe58e0bfe84102030484b9313c013b92577d66acdf098850d17cb612f04458b6ad02a4ae43b734fc9ffe18e981362912d0dba7086837954072acbda0d9a7c7108ed0ea0e402568e36b48b5fc2d99c8c4b83dd027a8782325f07c5e71d12a0e505e73a1801b9c8b2581c49959130000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c0864880000009e494441545847ed96410ac0200c0495f6ff2feea17a08b4c1646314bcacd05b930c936db19652aef61c3b9500344003344003344003341030f0b477eee48d05d6a20b496fd0cf0a805bef01ac0e17696e1f0b60d77008e10164b55b7119e621020083e404f45b3b05d07bca1a7684d0ec81be0201b1d68120a1bd1500dd7c346c1b80566835d63b87eb8b18d079404dd15a7e998d0224ffc4b88c00c70dbcedba1d81b2a5703a0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000092494441545847ed96410ac0200c0495f6ff2feea1061a0852bb9b40f1b282d0431227630af6d6da31f6b6d5052003322003322003322003a4816bc49dc9570b95c33e48ac586541680680ea644107731140b5f39967698201f0e42c4ccc2b0358277eb015612162ece71c2003b34a78a70f241c3e2f5c0160fe86df00e295d8f7db7cd0875b81ac01a6fb548c006460bb811b903311813716c23a0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000089494441545847ed96b10ac0200c4423edff7f7187ea60493378977490c2096e313edf29d8ccece873db68029001199001199001199001c2c0d56bcee28f05ae653e24b0c9020eae4500b0016166d9230bc000c59a7f030cc3e3047ea00b99aa4711c4882b112cafc95780795a6f85817ca0b2003192b9b1d78e227a19a900102f8f2f11800c6c37700360131781b4054f830000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000091494441545847ed96b10e80200c444be4ffbfd8411848c060efda05872371f2da3e5ed050ccec6acfb1550420033220033220033220038481bb656af2c6026bd90b096cb401a46a1800aad1872158fb7b00b803e26cb83d9081a30068f8fc3e925da47906224d23d934c07b8867c0cbd2003dc80e8dc084003c88dd507ae783027d0523d71b6716fc85b30099e1548d001e930027810fe7f6160000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000098494441545847ed964b0ac0200c0523f5fe27eea26621049b98f82952784237d53c27038a8988aef21d1b090030000330000330000330e018b8cb7c5e7cad7433220f921508b7d60370030276a60decd8bcf2995996819d9b77217e033063a4ad5133a2062c00fecf433baa9f03c80d34c02500eeaa76573bec055a736dc6ebd47af7802c90619a766f5ebd3246000277cef812001c37f00086f72381b52e906c0000000049454e44ae426082'),bytes(hex'89504e470d0a1a0a0000000d4948445200000020000000200806000000737a7af40000000473424954080808087c08648800000092494441545847ed96d10ac02008458dedffbf780fab072142f3ea06637083bd44dae9e8a2262247ff3e1b8d0034400334400334400334001ab8faba33f96a816290070994c8810b63770023788cecc957966d1e0f20244f96632c377322004f60e6d87f01a832355ded03adbfdb4bc85fe0d56f4e6e6d0095ae0a60255fe708f0aa01b429c3a65bef0fb4070af70e1642801b8ad723816807111a0000000049454e44ae426082')];
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
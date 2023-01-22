// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SuperShop.sol";

library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

struct Inventory {
    Item weapon;
    uint weaponTokenID;
    Item collar;
    uint collarTokenID;
    Item armor;
    uint armorTokenID;
}

struct KawaiiPet {
    uint kawaiiID;
    uint xp;
    uint currentHealth;
    uint totalHealth;
    uint strength;
    uint agility;
    uint defense;
    uint lastAtk;
    uint lastDef;
}

contract FightCenter is Ownable {

    using SafeMath for uint;

    // Global Datas
    uint public hitXP = 25;
    uint public killXP = 30;
    uint public dodgeXP = 17;
    uint public hurtXP = 6;
    uint public missXP = 6;

    uint public hitCoins = 25;
    uint public killCoins = 20;
    uint public dodgeCoins = 20;
    uint public hurtCoins = 7;
    uint public missCoins = 7;

    uint public atkTime = 10 minutes;
    uint public defTime = 0;

    // KawaiiID to its inventory
    mapping(uint => Inventory) public inventory;

    // Shop System
    SuperShop public shop;

    Collection public collection;

    constructor(address _shopContract, address _collectionContract){
        shop = SuperShop(payable(_shopContract));
        collection = Collection(payable(_collectionContract));
    }

    modifier onlyAllowedContract() {
        require(msg.sender == address(collection) || msg.sender == owner(), "Not owner");
        _;
    }

    function setAddresses(address _collection, address newShop) public onlyOwner {
        collection = Collection(payable(_collection));
        shop = SuperShop(payable(newShop));
    }

    function setCombatTimespans(uint _newatkTime, uint _newDefendSpan) public onlyOwner {
        atkTime = _newatkTime;
        defTime = _newDefendSpan;
    }

    function setCoins(uint _hit, uint _dodge, uint _downBonus, uint _gettingHit, uint _miss) public onlyOwner{
        hitCoins = _hit;
        dodgeCoins = _dodge;
        killCoins = _downBonus;
        hurtCoins = _gettingHit;
        missCoins = _miss;
    }

    function setXP(uint _hit, uint _dodge, uint _downBonus, uint _gettingHit, uint _miss) public onlyOwner{
        hitXP = _hit;
        dodgeXP = _dodge;
        killXP = _downBonus;
        hurtXP = _gettingHit;
        missXP = _miss;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function dodgeAttack(uint atkAgility, uint defAgility) public view returns (bool) {
        require( defAgility + atkAgility > 0, "Denominator > 0");
        uint256 agilitySum = atkAgility.add( defAgility);
        uint256 agilityRatio = atkAgility.mul(100).div(agilitySum);
        uint256 cappedChance = min(agilityRatio, 30);
        uint256 randomChance = uint(keccak256(abi.encodePacked(block.timestamp))).mod(100);
        return randomChance < cappedChance;
    }

    function fight(uint atkID, uint defID) external{
        require(collection.ownerOf(atkID) != collection.ownerOf(defID), "Owner not diff");
        require(collection.ownerOf(atkID) == msg.sender, "Not the owner");

        KawaiiPet memory attacker = KawaiiPets[atkID];
        KawaiiPet memory defender = KawaiiPets[defID];

        require(attacker.lastAtk.add(atkTime) <= block.timestamp, "Cant attack now");
        require(defender.lastDef.add(defTime) <= block.timestamp, "Got attacked recently");
        require(attacker.currentHealth > 0 && defender.currentHealth > 0, "1 of them needs revive");

        KawaiiPets[atkID].lastAtk = block.timestamp;
        KawaiiPets[defID].lastDef = block.timestamp;

        if (dodgeAttack(attacker.agility, defender.agility)) {
            // Dodged
            fightRewards(atkID, defID, 0, true);
        } else {
            uint damage = 0;
            if(defender.defense < attacker.strength){
                damage = attacker.strength.sub(defender.defense);
            }
            uint newHealth = 0;
            if (!(damage > defender.currentHealth)) {
                newHealth = defender.currentHealth.sub(damage);
            }
            fightRewards(atkID, defID, newHealth, false);
        }
    }

    function fightRewards(uint _atkID, uint _defID, uint newHealth, bool dodged) internal {
        
        // Add xp amount depending on situation
        uint atkXP;
        uint defXP;
        uint atkCoin;
        uint defCoin;
        uint atkLvl = 0;
        uint defLvl = 0;

        atkLvl = KawaiiPets[_atkID].xp.div(100);
        defLvl = KawaiiPets[_defID].xp.div(100);

        if(!dodged){
            // Set health
            
            KawaiiPets[_defID].currentHealth = newHealth;

            // Just a hit
            atkXP = atkXP.add(hitXP);
            atkCoin = atkCoin.add(hitCoins);
            defXP = defXP.add(hurtXP);
            defCoin = defCoin.add(hurtCoins);

            if (KawaiiPets[_defID].currentHealth <= 0){
                // Defender fainted - add bonus
                atkXP = atkXP.add(killXP);
                atkCoin = atkCoin.add(killCoins);
            }
        } else {
            // Dodged
            atkXP = atkXP.add(missXP);
            atkCoin = atkCoin.add(missCoins);
            defXP = defXP.add(dodgeXP);
            defCoin = defCoin.add(dodgeCoins);
        }
        // Add rewards coin
        shop.increaseCoin(atkCoin, collection.ownerOf(_atkID));
        shop.increaseCoin(defCoin, collection.ownerOf(_defID));

        // Add xp
        KawaiiPets[_atkID].xp = KawaiiPets[_atkID].xp.add(atkXP);
        KawaiiPets[_defID].xp = KawaiiPets[_defID].xp.add(defXP);

        // Calculate intial xp to track level up
        if(KawaiiPets[_atkID].xp >= 100 && atkLvl != KawaiiPets[_atkID].xp.div(100)){
            shop.mintRune(collection.ownerOf(_atkID));
        }
        if(KawaiiPets[_defID].xp >= 100 && defLvl != KawaiiPets[_defID].xp.div(100)){
            shop.mintRune(collection.ownerOf(_defID));
        }
    }

    function unequipItem(uint tokenID, address owner, uint _nftId) private {
        if(tokenID != 0) {
            Item memory item = shop.getItem(shop.tokenToItemIds(tokenID));
            KawaiiPet memory pet = KawaiiPets[_nftId];
            pet.totalHealth -= item.healthBonus;
            pet.agility -= item.agilityBonus;
            pet.defense -= item.defenseBonus;
            pet.strength -= item.strengthBonus;
            KawaiiPets[_nftId] = pet;
            shop.unequipItem(tokenID, owner);
        }
    }

    function addItemStatsToPet(Item memory item, KawaiiPet memory pet, uint _nftId) private {
        pet.totalHealth = pet.totalHealth.add(item.healthBonus);
        pet.agility = pet.agility.add(item.agilityBonus);
        pet.defense = pet.defense.add(item.defenseBonus);
        pet.strength = pet.strength.add(item.strengthBonus);
        KawaiiPets[_nftId] = pet;
    }

    function useItem(uint _tokenID, uint _nftId) external {
        require(shop.ownerOf(_tokenID) == msg.sender, "You do not own this item");
        require(collection.ownerOf(_nftId) == msg.sender, "You do not own this pet");

        uint id = shop.tokenToItemIds(_tokenID);
        Item memory item = shop.getItem(id);
        KawaiiPet memory pet = KawaiiPets[_nftId];
        bytes32 itemType = keccak256(bytes(item.itemType));

        if(itemType == keccak256(bytes("Consumable"))){
            if(item.healAmount > 0 && pet.currentHealth <= 0) {
                revert("Cant use heal consumable if dead");
            }
            pet.currentHealth += item.healAmount;
            if(pet.currentHealth > pet.totalHealth) {
                pet.currentHealth = pet.totalHealth;
            }
            shop.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _tokenID);
        } 
        else if(itemType == keccak256(bytes("Weapon"))){
            unequipItem(inventory[_nftId].weaponTokenID, msg.sender, _nftId);
            inventory[_nftId].weapon = item;
            inventory[_nftId].weaponTokenID = _tokenID;
            shop.transferFrom(msg.sender, address(this), _tokenID);
        } else if(itemType == keccak256(bytes("Collar"))) {
            unequipItem(inventory[_nftId].collarTokenID, msg.sender, _nftId);
            inventory[_nftId].collar = item;
            inventory[_nftId].collarTokenID = _tokenID;
            shop.transferFrom(msg.sender, address(this), _tokenID);
        } else if(itemType == keccak256(bytes("Armor"))) {
            unequipItem(inventory[_nftId].armorTokenID, msg.sender, _nftId);
            inventory[_nftId].armor = item;
            inventory[_nftId].armorTokenID = _tokenID;
            shop.transferFrom(msg.sender, address(this), _tokenID);
        }else{
            revert("Unknown item type");
        }
        addItemStatsToPet(item, pet, _nftId);
    }

    uint randomRunenonce = 0;
    function specialItems(uint _tokenID, uint _nftId, uint _itemId) external{
        require(_itemId <= 2);
        require(shop.ownerOf(_tokenID) == msg.sender, "Not owner - item");
        require(collection.ownerOf(_nftId) == msg.sender, "Not owner - pet");
        require(shop.tokenToItemIds(_tokenID) == _itemId);
        // Random Rune
        if(_itemId == 0) {
            uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randomRunenonce))) % 3;
            randomRunenonce++;
            uint randomNumber2 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randomRunenonce))) % 3;
            randomRunenonce++;
            KawaiiPets[_nftId].agility += randomNumber + 1;
            KawaiiPets[_nftId].strength += randomNumber2 + 1;
            KawaiiPets[_nftId].defense += randomNumber + 1;
            KawaiiPets[_nftId].totalHealth += randomNumber2 + 1;
            KawaiiPets[_nftId].currentHealth += randomNumber2 + 1;
        } else if(_itemId == 1) {
            require(KawaiiPets[_nftId].currentHealth > 0, "Your pet cant be healed if dead");
            uint half = KawaiiPets[_nftId].totalHealth;
            KawaiiPets[_nftId].currentHealth += half;
            if(KawaiiPets[_nftId].currentHealth > KawaiiPets[_nftId].totalHealth){
                KawaiiPets[_nftId].currentHealth = KawaiiPets[_nftId].totalHealth;
            }
        } else if(_itemId == 2) {
            require(KawaiiPets[_nftId].currentHealth <= 0, "Your pet isnt dead");
            uint newHealth = KawaiiPets[_nftId].totalHealth;
            KawaiiPets[_nftId].currentHealth = newHealth;
        }
        shop.safeTransferFrom(msg.sender, address(0x0), _tokenID);
    }

    // Will contain all KawaiiPets informations
    mapping(uint => KawaiiPet) public KawaiiPets;

    function getKawaiiList(uint offset, uint limit) public view returns (KawaiiPet[] memory) {
        KawaiiPet[] memory result = new KawaiiPet[](limit);
        uint count = 0;
        for (uint i = offset; i < offset + limit; i++) {
            if(KawaiiPets[i].kawaiiID != 0){
                result[count] = KawaiiPets[i];
                count++;
            }
        }
        return result;
    }

    function initialisePet(uint id, address owner, bool isWL) external onlyAllowedContract {
        KawaiiPets[id] = KawaiiPet(id, 0, 10, 10, 4, 1, 1, block.timestamp - atkTime, block.timestamp - defTime);
        if(isWL) {
            shop.wlRewards(owner);
        } else {
            shop.normalRewards(owner);
        }
    }
}

contract Collection is Ownable, ERC721AQueryable, PaymentSplitter {

    using ECDSA for bytes32;
    using Strings for uint;

    address private signerAddressWL1;
    address private signerAddressWL2;


    enum Step {
        Before,
        WhitelistSale1,
        WhitelistSale2,
        PublicSale,
        SoldOut
    }

    string public baseURI;

    Step public sellingStep;

    // Mint Condition - 1 per wallet hardcoded
    uint private constant MAX_SUPPLY = 4444;
    uint private MAX_WL1 = 2222;
    uint private MAX_WL2 = 2222;

    uint public wlSalePrice = 0.0321 ether;
    uint public publicSalePrice = 0.04321 ether;

    mapping(address => uint) public mintedAmountNFTsperWalletWLs;
    mapping(address => uint) public mintedAmountNFTsperWalletPublic;

    uint public maxWL = 2;
    uint public maxPublic = 2;

    function changeMax(uint _newWL, uint _newPublic) public onlyOwner {
        maxWL = _newWL;
        maxPublic = _newPublic;
    }

    uint private teamLength;

    FightCenter public fightCenter;

    constructor(address[] memory _team, uint[] memory _teamShares, address _signerAddressWL1, address _signerAddressWL2, string memory _baseURI) ERC721A("Super Kawaii", "KAWAII")
    PaymentSplitter(_team, _teamShares) {
        signerAddressWL1 = _signerAddressWL1;
        signerAddressWL2 = _signerAddressWL2;
        baseURI = _baseURI;
        teamLength = _team.length;
    }

    function mintForOpensea() public onlyOwner{
        require(totalSupply() == 0, "cant mint after opened");
        _mint(msg.sender, 33);
    }

    function initialisePet(uint _nftID) external {
        require(ownerOf(_nftID) == address(msg.sender), "Sender not owner");
        fightCenter.initialisePet(_nftID, msg.sender, false);
    }

    function setRing(address _ring) external onlyOwner{
        fightCenter = FightCenter(payable(_ring));
    }

    function changeSigners(address _newSignerWL1, address _newSignerWL2) external onlyOwner{
        signerAddressWL1 = _newSignerWL1;
        signerAddressWL2 = _newSignerWL2;
    }

    function publicSaleMint(uint _quantity) external payable {
        uint price = publicSalePrice;
        if(price <= 0) revert("Price is 0");
        if(msg.value < publicSalePrice * _quantity) revert("Not enough funds");
        if(sellingStep != Step.PublicSale) revert("Public Mint not live.");
        if(totalSupply() + _quantity > MAX_SUPPLY) revert("Max supply exceeded");
        if(mintedAmountNFTsperWalletPublic[msg.sender] + _quantity > maxPublic) revert("Max exceeded for Public Sale");
        mintedAmountNFTsperWalletPublic[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function WLMint1(uint _quantity, bytes calldata signature) external payable {
        uint price = wlSalePrice;
        if(price <= 0) revert("Price is 0");
        if(msg.value < price * _quantity) revert("Not enough funds"); 
        if(sellingStep != Step.WhitelistSale1) revert("WL Mint not live.");
        if(totalSupply() + _quantity > MAX_SUPPLY) revert("Max supply exceeded for WL");
        if(totalSupply() + _quantity > MAX_WL1) revert("Max supply wl exceeded");
        if(signerAddressWL1 != keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(signature)) revert("You are not in WL whitelist");
        if(mintedAmountNFTsperWalletWLs[msg.sender] + _quantity > maxWL) revert("Max exceeded for Whitelist Sale");
        mintedAmountNFTsperWalletWLs[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function WLMint2(uint _quantity, bytes calldata signature) external payable {
        uint price = publicSalePrice;
        if(price <= 0) revert("Price is 0");
        if(msg.value < price * _quantity) revert("Not enough funds"); 
        if(sellingStep != Step.WhitelistSale2) revert("WL Mint not live.");
        if(totalSupply() + _quantity > MAX_SUPPLY) revert("Max supply exceeded for WL");
        if(totalSupply() + _quantity > (MAX_WL1 + MAX_WL2)) revert("Max supply wl exceeded");
        if(signerAddressWL2 != keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(signature)) revert("You are not in WL whitelist");
        if(mintedAmountNFTsperWalletWLs[msg.sender] + _quantity > maxWL) revert("Max exceeded for Whitelist Sale");
        mintedAmountNFTsperWalletWLs[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function currentState() external view returns (Step, uint, uint) {
        return (sellingStep, publicSalePrice, wlSalePrice);
    }

    function changeWL1Supply(uint new_supply) external onlyOwner{
        MAX_WL1 = new_supply;
    }

    function changeWL2Supply(uint new_supply) external onlyOwner{
        MAX_WL2 = new_supply;
    }

    function changeWlSalePrice(uint256 new_price) external onlyOwner{
        wlSalePrice = new_price;
    }

    function changePublicSalePrice(uint256 new_price) external onlyOwner{
        publicSalePrice = new_price;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function getNumberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    function getNumberWLMinted(address account) external view returns (uint256) {
        return mintedAmountNFTsperWalletWLs[account];
    }

    function getNumberPublicMinted(address account) external view returns (uint256) {
        return mintedAmountNFTsperWalletPublic[account];
    }

    function tokenURI(uint _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _toString(_tokenId), ".json"));
    }

    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }
}
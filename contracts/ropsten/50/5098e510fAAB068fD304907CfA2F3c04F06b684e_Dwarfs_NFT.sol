// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./IDwarfs_NFT.sol";
import "./IClan.sol";
import "./ITraits.sol";
import "./GOD.sol";

contract Dwarfs_NFT is IDwarfs_NFT, ERC721Enumerable, Ownable, Pausable {
    // mint price
    uint256 public MINT_ETH_PRICE_0 = 0.12 ether;
    uint256 public MINT_ETH_PRICE_1 = 0.14 ether;
    uint256 public MINT_ETH_PRICE_2 = 0.16 ether;
    uint256 public MINT_ETH_PRICE_3 = 0.18 ether;

    uint256 public MINT_GOD_PRICE_0 = 0 ether;
    uint256 public MINT_GOD_PRICE_1 = 100000 ether;
    uint256 public MINT_GOD_PRICE_2 = 120000 ether;
    uint256 public MINT_GOD_PRICE_3 = 140000 ether;

    uint256 public MAX_GEN0_TOKENS = 8000;
    uint256 public MAX_GEN1_TOKENS = 12000;
    uint256 public MAX_GEN2_TOKENS = 16000;

    // max number of tokens that can be minted - 20000 in production
    uint256 public MAX_TOKENS = 20000;

    uint256 public MAX_TOKENS_ETH_SOLD = 50;

    // number of tokens have been minted so far
    uint16 public minted;

    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => DwarfTrait) public tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    // list of probabilities for each trait type
    // 0 - 9 are associated with Merchant, 10 - 18 are associated with Mobsters
    uint8[][18] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 9 are associated with Merchant, 10 - 18 are associated with Mobsters
    uint8[][18] public aliases;

    // reference to the Clan for choosing random Mobster thieves
    IClan public clan;
    // reference to $GOD for burning on mint
    GOD public god;
    // reference to Traits
    ITraits public traits;

    /**
     * instantiates contract and rarity tables
     */
    constructor(address _god, address _traits)
        ERC721("Game Of Dwarfs", "DWARF")
    {
        god = GOD(_god);
        traits = ITraits(_traits);

        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm
        // merchant
        // fur
        rarities[0] = [15, 50, 200, 250, 255];
        aliases[0] = [4, 4, 4, 4, 4];
        // head
        rarities[1] = [
            190,
            215,
            240,
            100,
            110,
            135,
            160,
            185,
            80,
            210,
            235,
            240,
            80,
            80,
            100,
            100,
            100,
            245,
            250,
            255
        ];
        aliases[1] = [
            1,
            2,
            4,
            0,
            5,
            6,
            7,
            9,
            0,
            10,
            11,
            17,
            0,
            0,
            0,
            0,
            4,
            18,
            19,
            19
        ];
        // ears
        rarities[2] = [255, 30, 60, 60, 150, 156];
        aliases[2] = [0, 0, 0, 0, 0, 0];
        // eyes
        rarities[3] = [
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            183,
            236,
            252,
            224,
            255
        ];
        aliases[3] = [
            1,
            2,
            5,
            0,
            1,
            7,
            1,
            10,
            5,
            10,
            11,
            12,
            13,
            14,
            16,
            11,
            17,
            23,
            13,
            14,
            17,
            23,
            23,
            24,
            27,
            27,
            27,
            27
        ];
        // nose
        rarities[4] = [175, 100, 40, 250, 115, 100, 185, 175, 180, 255];
        aliases[4] = [3, 0, 4, 6, 6, 7, 8, 8, 9, 9];
        // mouth
        rarities[5] = [
            80,
            225,
            227,
            228,
            112,
            240,
            64,
            160,
            167,
            217,
            171,
            64,
            240,
            126,
            80,
            255
        ];
        aliases[5] = [1, 2, 3, 8, 2, 8, 8, 9, 9, 10, 13, 10, 13, 15, 13, 15];
        // neck
        rarities[6] = [255];
        aliases[6] = [0];
        // feet
        rarities[7] = [
            243,
            189,
            133,
            133,
            57,
            95,
            152,
            135,
            133,
            57,
            222,
            168,
            57,
            57,
            38,
            114,
            114,
            114,
            255
        ];
        aliases[7] = [
            1,
            7,
            0,
            0,
            0,
            0,
            0,
            10,
            0,
            0,
            11,
            18,
            0,
            0,
            0,
            1,
            7,
            11,
            18
        ];
        // alphaIndex
        rarities[8] = [255];
        aliases[8] = [0];

        // mobsters
        // fur
        rarities[9] = [210, 90, 9, 9, 9, 150, 9, 255, 9];
        aliases[9] = [5, 0, 0, 5, 5, 7, 5, 7, 5];
        // head
        rarities[10] = [255];
        aliases[10] = [0];
        // ears
        rarities[11] = [255];
        aliases[11] = [0];
        // eyes
        rarities[12] = [
            135,
            177,
            219,
            141,
            183,
            225,
            147,
            189,
            231,
            135,
            135,
            135,
            135,
            246,
            150,
            150,
            156,
            165,
            171,
            180,
            186,
            195,
            201,
            210,
            243,
            252,
            255
        ];
        aliases[12] = [
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            13,
            3,
            6,
            14,
            15,
            16,
            16,
            17,
            18,
            19,
            20,
            21,
            22,
            23,
            24,
            25,
            26,
            26,
            26
        ];
        // nose
        rarities[13] = [255];
        aliases[13] = [0];
        // mouth
        rarities[14] = [
            239,
            244,
            249,
            234,
            234,
            234,
            234,
            234,
            234,
            234,
            130,
            255,
            247
        ];
        aliases[14] = [1, 2, 11, 0, 11, 11, 11, 11, 11, 11, 11, 11, 11];
        // neck
        rarities[15] = [
            75,
            180,
            165,
            120,
            60,
            150,
            105,
            195,
            45,
            225,
            75,
            45,
            195,
            120,
            255
        ];
        aliases[15] = [1, 9, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 14, 12, 14];
        // feet
        rarities[16] = [255];
        aliases[16] = [0];
        // alphaIndex
        rarities[17] = [8, 160, 73, 255];
        aliases[17] = [2, 3, 3, 3];
    }

    /** EXTERNAL */

    function mintByOwner(uint256 amount) external onlyOwner {
        uint256 seed;
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = random(minted);
            generate(minted, seed);
            _safeMint(_msgSender(), minted);
        }
    }

    /**
     * mint a token - 90% Merchant, 10% Mobsters
     * The first 20% are free to claim, the remaining cost $GOD
     */
    function mint(uint256 amount, bool stake) external payable whenNotPaused {
        require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        require(amount > 0 && amount <= 10, "Invalid mint amount");
        if (minted < MAX_GEN0_TOKENS) {
            require(
                minted + amount <= MAX_GEN0_TOKENS,
                "All tokens on-sale already sold"
            );
            require(
                amount * MINT_ETH_PRICE_0 <= msg.value,
                "Invalid payment amount"
            );
        } else if (
            minted > MAX_GEN0_TOKENS &&
            minted < MAX_GEN0_TOKENS + (MAX_GEN1_TOKENS - MAX_GEN0_TOKENS) * MAX_TOKENS_ETH_SOLD / 100
        ) {
            require(
                minted + amount <= MAX_GEN0_TOKENS + (MAX_GEN1_TOKENS - MAX_GEN0_TOKENS) * MAX_TOKENS_ETH_SOLD / 100,
                "All tokens on-sale already sold"
            );
            require(
                amount * MINT_ETH_PRICE_1 <= msg.value,
                "Invalid payment amount"
            );
        } else if (
            minted > MAX_GEN1_TOKENS &&
            minted < MAX_GEN1_TOKENS + (MAX_GEN2_TOKENS - MAX_GEN1_TOKENS) * MAX_TOKENS_ETH_SOLD / 100
        ) {
            require(
                minted + amount <= MAX_GEN1_TOKENS + (MAX_GEN2_TOKENS - MAX_GEN1_TOKENS) * MAX_TOKENS_ETH_SOLD / 100,
                "All tokens on-sale already sold"
            );
            require(
                amount * MINT_ETH_PRICE_2 <= msg.value,
                "Invalid payment amount"
            );
        } else if (
            minted > MAX_GEN2_TOKENS &&
            minted < MAX_GEN2_TOKENS + (MAX_TOKENS - MAX_GEN2_TOKENS) * MAX_TOKENS_ETH_SOLD / 100
        ) {
            require(
                minted + amount <= MAX_GEN2_TOKENS + (MAX_TOKENS - MAX_GEN2_TOKENS) * MAX_TOKENS_ETH_SOLD / 100,
                "All tokens on-sale already sold"
            );
            require(
                amount * MINT_ETH_PRICE_3 <= msg.value,
                "Invalid payment amount"
            );
        }

        uint256 totalGodCost = 0;
        uint16[] memory tokenIds = stake
            ? new uint16[](amount)
            : new uint16[](0);
        uint256 seed;
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = random(minted);
            generate(minted, seed);

            if (!stake) {
                _safeMint(_msgSender(), minted);
            } else {
                _safeMint(address(clan), minted);
                tokenIds[i] = minted;
            }
            totalGodCost += mintCost(minted);
        }

        if (totalGodCost > 0) god.burn(_msgSender(), totalGodCost);
        if (stake) clan.addManyToClanAndPack(_msgSender(), tokenIds);
    }

    /**
     * the first 20% are paid in ETH
     * the next 20% are 20000 $GOD
     * the next 40% are 40000 $GOD
     * the final 20% are 80000 $GOD
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= MAX_GEN0_TOKENS) return MINT_GOD_PRICE_0;
        if (tokenId <= MAX_GEN0_TOKENS + (MAX_GEN1_TOKENS - MAX_GEN0_TOKENS) * MAX_TOKENS_ETH_SOLD / 100) return 0;
        if (tokenId <= MAX_GEN1_TOKENS) return MINT_GOD_PRICE_1;
        if (tokenId <= MAX_GEN1_TOKENS + (MAX_GEN2_TOKENS - MAX_GEN1_TOKENS) * MAX_TOKENS_ETH_SOLD / 100) return 0;
        if (tokenId <= MAX_GEN2_TOKENS) return MINT_GOD_PRICE_2;
        if (tokenId <= MAX_GEN2_TOKENS + (MAX_TOKENS - MAX_GEN2_TOKENS) * MAX_TOKENS_ETH_SOLD / 100) return 0;
        if (tokenId <= MAX_TOKENS) return MINT_GOD_PRICE_3;

        return 0 ether;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode the Clan's approval so that users don't have to waste gas approving
        if (_msgSender() != address(clan))
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    /** INTERNAL */

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param tokenId the id of the token to generate traits for
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t - a struct of traits for the given token ID
     */
    function generate(uint256 tokenId, uint256 seed)
        internal
        returns (DwarfTrait memory t)
    {
        t = selectTraits(seed);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            return t;
        }
        return generate(tokenId, random(seed));
    }

    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
     * @param traitType the trait type to select a trait for
     * @return the ID of the randomly selected trait
     */
    function selectTrait(uint16 seed, uint8 traitType)
        internal
        view
        returns (uint8)
    {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        if (seed >> 8 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectTraits(uint256 seed)
        internal
        view
        returns (DwarfTrait memory t)
    {
        t.isMerchant = (seed & 0xFFFF) % 10 != 0;
        uint8 shift = t.isMerchant ? 0 : 9;
        seed >>= 16;
        t.background_weapon = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        t.head = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        t.ears = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        t.eyes_brows_wear = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        t.nose = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        t.mouth = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        t.body_outfit = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
        seed >>= 16;
        t.hair_facialhair = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
        seed >>= 16;
        t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 8 + shift);
    }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param s the struct to pack into a hash
     * @return the 256 bit hash of the struct
     */
    function structToHash(DwarfTrait memory s) internal pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        s.isMerchant,
                        s.background_weapon,
                        s.body_outfit,
                        s.head,
                        s.mouth,
                        s.eyes_brows_wear,
                        s.nose,
                        s.hair_facialhair,
                        s.ears,
                        s.alphaIndex
                    )
                )
            );
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    /** READ */
    function getTokenTraits(uint256 tokenId)
        external
        view
        override
        returns (DwarfTrait memory)
    {
        return tokenTraits[tokenId];
    }

    function getGen0Tokens() external view override returns (uint256) {
        return MAX_GEN0_TOKENS;
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random mobster thieves
     * @param _clan the address of the Clan
     */
    function setClan(address _clan) external onlyOwner {
        clan = IClan(_clan);
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * updates the number of tokens for sale
     */
    function setGen0Tokens(uint256 _gen0Tokens) external onlyOwner {
        MAX_GEN0_TOKENS = _gen0Tokens;
    }

    function setGen1Tokens(uint256 _gen1Tokens) external onlyOwner {
        MAX_GEN1_TOKENS = _gen1Tokens;
    }

    function setGen2Tokens(uint256 _gen2Tokens) external onlyOwner {
        MAX_GEN2_TOKENS = _gen2Tokens;
    }

    function setGen3Tokens(uint256 _gen3Tokens) external onlyOwner {
        MAX_TOKENS = _gen3Tokens;
    }

    function setMintETHPrice0(uint256 _price) external onlyOwner {
        MINT_ETH_PRICE_0 = _price;
    }

    function setMintETHPrice1(uint256 _price) external onlyOwner {
        MINT_ETH_PRICE_1 = _price;
    }

    function setMintETHPrice2(uint256 _price) external onlyOwner {
        MINT_ETH_PRICE_2 = _price;
    }

    function setMintETHPrice3(uint256 _price) external onlyOwner {
        MINT_ETH_PRICE_3 = _price;
    }

    function setMintGODPrice0(uint256 _price) external onlyOwner {
        MINT_GOD_PRICE_0 = _price;
    }

    function setMintGODPrice1(uint256 _price) external onlyOwner {
        MINT_GOD_PRICE_1 = _price;
    }

    function setMintGODPrice2(uint256 _price) external onlyOwner {
        MINT_GOD_PRICE_2 = _price;
    }

    function setMintGODPrice3(uint256 _price) external onlyOwner {
        MINT_GOD_PRICE_3 = _price;
    }

    function setEthSoldPercent(uint256 _percent) external onlyOwner {
        MAX_TOKENS_ETH_SOLD = _percent;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** RENDER */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return traits.tokenURI(tokenId);
    }
}
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

    // reference to the Clan for choosing random Mobster thieves
    IClan public clan;
    // reference to $GOD for burning on mint
    GOD public god;
    // reference to Traits
    ITraits public traits;

    uint8 public MAX_BACKGROUND = 255;
    uint8 public MAX_WEAPON = 255;
    uint8 public MAX_BODY = 255;
    uint8 public MAX_OUTFIT = 255;
    uint8 public MAX_HEAD = 255;
    uint8 public MAX_MOUTH = 255;
    uint8 public MAX_EYES = 255;
    uint8 public MAX_NOSE = 255;
    uint8 public MAX_EYEBROWS = 255;
    uint8 public MAX_HAIR = 255;
    uint8 public MAX_EYEWEAR = 255;
    uint8 public MAX_FACIALHAIR = 255;
    uint8 public MAX_EARS = 255;

    /**
     * instantiates contract and rarity tables
     */
    constructor(address _god, address _traits)
        ERC721("Game Of Dwarfs", "DWARF")
    {
        god = GOD(_god);
        traits = ITraits(_traits);
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
            minted <
            MAX_GEN0_TOKENS +
                ((MAX_GEN1_TOKENS - MAX_GEN0_TOKENS) * MAX_TOKENS_ETH_SOLD) /
                100
        ) {
            require(
                minted + amount <=
                    MAX_GEN0_TOKENS +
                        ((MAX_GEN1_TOKENS - MAX_GEN0_TOKENS) *
                            MAX_TOKENS_ETH_SOLD) /
                        100,
                "All tokens on-sale already sold"
            );
            require(
                amount * MINT_ETH_PRICE_1 <= msg.value,
                "Invalid payment amount"
            );
        } else if (
            minted > MAX_GEN1_TOKENS &&
            minted <
            MAX_GEN1_TOKENS +
                ((MAX_GEN2_TOKENS - MAX_GEN1_TOKENS) * MAX_TOKENS_ETH_SOLD) /
                100
        ) {
            require(
                minted + amount <=
                    MAX_GEN1_TOKENS +
                        ((MAX_GEN2_TOKENS - MAX_GEN1_TOKENS) *
                            MAX_TOKENS_ETH_SOLD) /
                        100,
                "All tokens on-sale already sold"
            );
            require(
                amount * MINT_ETH_PRICE_2 <= msg.value,
                "Invalid payment amount"
            );
        } else if (
            minted > MAX_GEN2_TOKENS &&
            minted <
            MAX_GEN2_TOKENS +
                ((MAX_TOKENS - MAX_GEN2_TOKENS) * MAX_TOKENS_ETH_SOLD) /
                100
        ) {
            require(
                minted + amount <=
                    MAX_GEN2_TOKENS +
                        ((MAX_TOKENS - MAX_GEN2_TOKENS) * MAX_TOKENS_ETH_SOLD) /
                        100,
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
        if (
            tokenId <=
            MAX_GEN0_TOKENS +
                ((MAX_GEN1_TOKENS - MAX_GEN0_TOKENS) * MAX_TOKENS_ETH_SOLD) /
                100
        ) return 0;
        if (tokenId <= MAX_GEN1_TOKENS) return MINT_GOD_PRICE_1;
        if (
            tokenId <=
            MAX_GEN1_TOKENS +
                ((MAX_GEN2_TOKENS - MAX_GEN1_TOKENS) * MAX_TOKENS_ETH_SOLD) /
                100
        ) return 0;
        if (tokenId <= MAX_GEN2_TOKENS) return MINT_GOD_PRICE_2;
        if (
            tokenId <=
            MAX_GEN2_TOKENS +
                ((MAX_TOKENS - MAX_GEN2_TOKENS) * MAX_TOKENS_ETH_SOLD) /
                100
        ) return 0;
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
        t.background_weapon =
            uint16((random(seed) % MAX_BACKGROUND) << 8) +
            uint8(random(seed + 1) % MAX_WEAPON);
        t.body_outfit =
            uint16((random(seed + 2) % MAX_BODY) << 8) +
            uint8(random(seed + 3) % MAX_OUTFIT);
        t.head_ears =
            uint16((random(seed + 4) % MAX_HEAD) << 8) +
            uint8(random(seed + 5) % MAX_EARS);
        t.mouth_nose =
            uint16((random(seed + 6) % MAX_MOUTH) << 8) +
            uint8(random(seed + 7) % MAX_NOSE);
        t.eyes_brows =
            uint16((random(seed + 8) % MAX_EYES) << 8) +
            uint8(random(seed + 9) % MAX_EYEBROWS);
        t.hair_facialhair =
            uint16((random(seed + 10) % MAX_HAIR) << 8) +
            uint8(random(seed + 11) % MAX_FACIALHAIR);
        t.eyewear = uint8(random(seed + 12) % MAX_EYEWEAR);
        t.alphaIndex = uint8((random(seed + 13) % 4) + 5);
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
                        s.head_ears,
                        s.mouth_nose,
                        s.eyes_brows,
                        s.hair_facialhair,
                        s.eyewear,
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

    /* Set the ETH price */
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

    /* Set the GOD price */
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

    /* Set the Trait parameters */
    function setMaxBackground(uint8 val) external onlyOwner {
        MAX_BACKGROUND = val;
    }

    function setMaxWeapon(uint8 val) external onlyOwner {
        MAX_WEAPON = val;
    }

    function setMaxBody(uint8 val) external onlyOwner {
        MAX_BODY = val;
    }

    function setMaxOutfit(uint8 val) external onlyOwner {
        MAX_OUTFIT = val;
    }

    function setMaxHead(uint8 val) external onlyOwner {
        MAX_HEAD = val;
    }

    function setMaxMouth(uint8 val) external onlyOwner {
        MAX_MOUTH = val;
    }

    function setMaxEyes(uint8 val) external onlyOwner {
        MAX_EYES = val;
    }

    function setMaxNose(uint8 val) external onlyOwner {
        MAX_NOSE = val;
    }

    function setMaxEyebrows(uint8 val) external onlyOwner {
        MAX_EYEBROWS = val;
    }

    function setMaxHair(uint8 val) external onlyOwner {
        MAX_HAIR = val;
    }

    function setMaxEyewear(uint8 val) external onlyOwner {
        MAX_EYEWEAR = val;
    }

    function setMaxFacialhair(uint8 val) external onlyOwner {
        MAX_FACIALHAIR = val;
    }

    function setMaxEars(uint8 val) external onlyOwner {
        MAX_EARS = val;
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
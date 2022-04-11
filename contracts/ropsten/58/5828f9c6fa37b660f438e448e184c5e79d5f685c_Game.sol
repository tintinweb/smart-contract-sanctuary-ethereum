// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "./interfaces/IRandomizer.sol";
import "./interfaces/INFT.sol";
import "./World.sol";
import "./interfaces/IPotion.sol";
import "./interfaces/IPowerUp.sol";
import "./interfaces/IArena.sol";
import "./interfaces/IGame.sol";
import "./interfaces/IExcalibur.sol";

// import "./interfaces/IGoldStaking.sol";

contract Game is IGame, Ownable, ReentrancyGuard, Pausable {
    /** CONTRACTS */
    IArena public uArena;
    World public uWorld;
    INFT public uNFT;
    IPotion public uPotion;
    IPowerUp public uPowerUp;
    IExcalibur public uExcalibur;
    // IGoldStaking public uGoldStaking;

    /** EVENTS */
    event ManyHVMinted(address indexed owner, uint16[] tokenIds);
    event ManyHVRevealed(address indexed owner, uint16[] tokenIds);
    event HVStolen(
        address indexed originalOwner,
        address indexed newOwner,
        uint256 indexed tokenId
    );
    event HeroLeveledUp(address indexed owner, uint256 indexed tokenId);
    event ManyHerosLeveledUp(address indexed owner, uint16[] tokenIds);
    event ManyRingsMinted(address indexed owner, uint256 indexed amount);
    event ManyAmuletsMinted(address indexed owner, uint256 indexed amount);
    event ExcaliburMinted(address indexed owner, uint256 indexed amount);

    /** PUBLIC VARS */
    uint256 public GEN0_PRICE = 250000000000000000;

    uint256 public MINT_COST_REDUCE_INTERVAL = 3 hours;
    uint8 public MINT_COST_REDUCE_PERCENT = 1;
    uint8 public MINT_COST_INCREASE_PERCENT = 2;

    uint256 public GEN1_WORLD_MINT_COST = 40_000 ether;
    uint256 public GEN1_MIN_WORLD_MINT_COST = 40_000 ether;
    uint256 public GEN1_LAST_MINT_TIME = block.timestamp;

    uint256 public DAILY_WORLD_RATE = 500 ether;
    uint256 public DAILY_WORLD_PER_LEVEL = 1_000 ether;

    uint256 public RING_DIMINISHING_FROM = 11;
    uint256 public RING_DAILY_WORLD_RATE = 20 ether;
    uint256 public RING_WORLD_MINT_COST = 50_000 ether;
    uint256 public RING_MIN_WORLD_MINT_COST = 5_000 ether;
    uint256 public RING_LAST_MINT_TIME = block.timestamp;

    uint256 public LEVEL_DOWN_AFTER_DAYS = 5 days;
    uint256 public AMULET_WORLD_MINT_COST = 160_000 ether;
    uint256 public AMULET_LEVEL_DOWN_INCREASE_DAYS = 2 days;
    uint256 public AMULET_MIN_WORLD_MINT_COST = 100_000 ether;
    uint256 public AMULET_LAST_MINT_TIME = block.timestamp;

    uint256 public EXCALIBUR_WORLD_MINT_COST = 2_000_000 ether;

    // The multi-sig wallet that will receive the funds on withdraw
    address public WITHDRAW_ADDRESS =
        address(0x95c0971b1Eb62CD492B201207C2F6e6192bb9E6D);

    /** PRIVATE VARS */
    mapping(address => bool) private _admins;

    /** MODIFIERS */
    modifier onlyEOA() {
        require(tx.origin == _msgSender(), "Only EOA");
        _;
    }

    modifier onlyAdmin() {
        require(_admins[_msgSender()], "NFT: Only admins can call this");
        _;
    }

    /** MINTING FUNCTIONS */
    function mintExcalibur(uint256 amount)
        external
        whenNotPaused
        nonReentrant
        onlyEOA
    {
        require(
            uWorld.balanceOf(_msgSender()) >= EXCALIBUR_WORLD_MINT_COST,
            "Not enough $worlds"
        );
        uint256 totalWorldCost = EXCALIBUR_WORLD_MINT_COST * amount;
        uWorld.burn(_msgSender(), totalWorldCost);
        uExcalibur.mint(_msgSender(), amount);
        emit ExcaliburMinted(_msgSender(), amount);
    }

    /**
     * Mint Hero & Villain NFTs with $World.
     * 95% Hero, 5% Villain.
     * GEN1 NFTs can be stolen by Villain.
     */
    function mintGen1(uint256 amount)
        external
        whenNotPaused
        nonReentrant
        onlyEOA
    {
        require(
            uNFT.tokensMinted() >= uNFT.MAX_GEN0_TOKENS(),
            "GEN1 sale has not started yet"
        );
        uint16 tokensMinted = uNFT.tokensMinted();
        uint256 maxTokens = uNFT.MAX_TOKENS();
        require(tokensMinted + amount <= maxTokens, "All tokens minted");
        require(amount > 0 && amount <= 10, "Invalid mint amount (max 10)");

        uint256 totalWorldCost = getGen1MintCost() * amount;
        require(totalWorldCost > 0, "GEN1 mint cost cannot be 0");

        // Burn $World for the mints first
        uWorld.burn(_msgSender(), totalWorldCost);
        // uWorld.updateOriginAccess();

        uint16[] memory tokenIds = new uint16[](amount);
        address recipient;
        uint256 seed;

        for (uint256 k = 0; k < amount; k++) {
            tokensMinted++;
            // seed = randomizer.randomSeed(tokensMinted);
            seed = uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, tokensMinted)
                )
            );

            recipient = _selectRecipient(seed);
            tokenIds[k] = tokensMinted;

            if (recipient != _msgSender()) {
                // Stolen
                uNFT.mint(recipient, false);
                emit HVStolen(_msgSender(), recipient, tokensMinted);
            } else {
                // Not Stolen
                uNFT.mint(recipient, false);
            }

            // Increase the price after mint

            GEN1_WORLD_MINT_COST =
                getGen1MintCost() +
                ((GEN1_WORLD_MINT_COST * MINT_COST_INCREASE_PERCENT) / 100);
        }

        GEN1_LAST_MINT_TIME = block.timestamp;
        // uNFT.updateOriginAccess(tokenIds);
        emit ManyHVMinted(_msgSender(), tokenIds); // GEN1 minted
    }

    function getGen1MintCost() public view returns (uint256 newCost) {
        uint256 intervalDiff = (block.timestamp - GEN1_LAST_MINT_TIME) /
            MINT_COST_REDUCE_INTERVAL;
        uint256 reduceBy = ((GEN1_WORLD_MINT_COST * MINT_COST_REDUCE_PERCENT) /
            100) * intervalDiff;

        if (GEN1_WORLD_MINT_COST > reduceBy) {
            newCost = GEN1_WORLD_MINT_COST - reduceBy;
        } else {
            newCost = 0;
        }

        if (newCost < GEN1_MIN_WORLD_MINT_COST)
            newCost = GEN1_MIN_WORLD_MINT_COST;

        return newCost;
    }

    function mintRing(uint256 amount)
        external
        whenNotPaused
        nonReentrant
        onlyEOA
    {
        uint256 totalCost = amount * getRingMintCost();

        // This will fail if not enough $World is available
        uWorld.burn(_msgSender(), totalCost);
        uPotion.mint(_msgSender(), amount);

        // Increase the price after mint
        RING_WORLD_MINT_COST =
            getRingMintCost() +
            ((RING_WORLD_MINT_COST * MINT_COST_INCREASE_PERCENT) / 100);

        RING_LAST_MINT_TIME = block.timestamp;
        emit ManyRingsMinted(_msgSender(), amount);
    }

    function getRingMintCost() public view returns (uint256 newCost) {
        uint256 intervalDiff = (block.timestamp - RING_LAST_MINT_TIME) /
            MINT_COST_REDUCE_INTERVAL;
        uint256 reduceBy = ((RING_WORLD_MINT_COST * MINT_COST_REDUCE_PERCENT) /
            100) * intervalDiff;

        if (RING_WORLD_MINT_COST > reduceBy) {
            newCost = RING_WORLD_MINT_COST - reduceBy;
        } else {
            newCost = 0;
        }

        if (newCost < RING_MIN_WORLD_MINT_COST)
            newCost = RING_MIN_WORLD_MINT_COST;

        return newCost;
    }

    function mintAmulet(uint256 amount)
        external
        whenNotPaused
        nonReentrant
        onlyEOA
    {
        uint256 totalCost = amount * getAmuletMintCost();

        // This will fail if not enough $World is available
        uWorld.burn(_msgSender(), totalCost);
        uPowerUp.mint(_msgSender(), amount);

        // Increase the price after mint
        AMULET_WORLD_MINT_COST =
            getAmuletMintCost() +
            ((AMULET_WORLD_MINT_COST * MINT_COST_INCREASE_PERCENT) / 100);

        AMULET_LAST_MINT_TIME = block.timestamp;
        emit ManyAmuletsMinted(_msgSender(), amount);
    }

    function getAmuletMintCost() public view returns (uint256 newCost) {
        uint256 intervalDiff = (block.timestamp - AMULET_LAST_MINT_TIME) /
            MINT_COST_REDUCE_INTERVAL;
        uint256 reduceBy = ((AMULET_WORLD_MINT_COST *
            MINT_COST_REDUCE_PERCENT) / 100) * intervalDiff;

        if (AMULET_WORLD_MINT_COST > reduceBy) {
            newCost = AMULET_WORLD_MINT_COST - reduceBy;
        } else {
            newCost = 0;
        }

        if (newCost < AMULET_MIN_WORLD_MINT_COST)
            newCost = AMULET_MIN_WORLD_MINT_COST;

        return newCost;
    }

    function mintGen0(uint256 _amount) public payable {
        uint16 tokensMinted = uNFT.tokensMinted();
        uint256 maxTokens = uNFT.MAX_GEN0_TOKENS();
        require(tokensMinted + _amount <= maxTokens, "All gen0 tokens minted");
        require(_amount > 0 && _amount <= 10, "Invalid mint amount (max 10)");
        require(msg.value == _amount * GEN0_PRICE, "Unsufficient amount");

        for (uint256 i = 0; i < _amount; i++) uNFT.mint(msg.sender, true);

        if (tokensMinted + _amount >= 1000) GEN0_PRICE = 270000000000000000;
    }

    function getOwnerOfHVToken(uint256 tokenId)
        external
        view
        returns (address ownerOf)
    {
        return _getOwnerOfHVToken(tokenId);
    }

    function _getOwnerOfHVToken(uint256 tokenId)
        private
        view
        returns (address ownerOf)
    {
        if (uArena.isStaked(tokenId)) {
            IArena.Stake memory stake = uArena.getStake(tokenId);
            ownerOf = stake.owner;
        } else {
            ownerOf = uNFT.ownerOf(tokenId);
        }

        require(ownerOf != address(0), "The owner cannot be address(0)");

        return ownerOf;
    }

    // onlyEOA will not work here
    function getHVTokenTraits(uint256 tokenId)
        external
        view
        returns (INFT.HeroVillain memory)
    {
        return _getHVTokenTraits(tokenId);
    }

    // Return the actual level of the NFT (might have lost levels along the way)!
    // onlyEOA will not work here
    function _getHVTokenTraits(uint256 tokenId)
        private
        view
        returns (INFT.HeroVillain memory)
    {
        // Get current on-chain traits from the NFT contract
        INFT.HeroVillain memory traits = uNFT.getTokenTraits(tokenId);
        address ownerOfToken = _getOwnerOfHVToken(tokenId); // We need to get the actual owner of this token NOT use the _msgSender() here

        // If level is already 0, then return immediately
        if (traits.level == 0) return traits;

        // Lose 1 level every X days in which you didn't upgrade your NFT level
        uint256 amuletsInWallet = getBalanceOfActiveAmulets(ownerOfToken);
        // Amulets increase your level down days, thus your level goes down slower
        uint256 LEVEL_DOWN_AFTER_DAYS_NEW = (amuletsInWallet *
            AMULET_LEVEL_DOWN_INCREASE_DAYS) + LEVEL_DOWN_AFTER_DAYS;
        uint16 reduceLevelBy = uint16(
            (block.timestamp - traits.lastLevelUpgradeTime) /
                LEVEL_DOWN_AFTER_DAYS_NEW
        );

        if (reduceLevelBy > traits.level) {
            traits.level = 0;
        } else {
            traits.level = traits.level - reduceLevelBy;
        }

        return traits;
    }

    // Get the number of Amulets that are "active", meaning they have an effect on the game
    function getBalanceOfActiveAmulets(address owner)
        public
        view
        returns (uint256)
    {
        uint256 tokenCount = uPowerUp.balanceOf(owner);
        uint256 activeTokens = 0;

        for (uint256 i; i < tokenCount; i++) {
            uint256 tokenId = uPowerUp.tokenOfOwnerByIndex(owner, i);
            IPowerUp.PowerUp memory traits = uPowerUp.getTokenTraits(tokenId);
            if (block.timestamp >= traits.lastTransferTimestamp + 1 days) {
                activeTokens++;
            }
        }

        return activeTokens;
    }

    /**
     * 10% chance to be given to a random staked Villain
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the Villain thief's owner)
     */
    function _selectRecipient(uint256 seed) private view returns (address) {
        if (((seed) % 20) != 0) return _msgSender();
        address thief = uArena.randomVillainOwner(seed);
        if (thief == address(0x0)) return _msgSender();
        return thief;
    }

    /** STAKING */
    function calculateAllStakingRewards(uint256[] memory tokenIds)
        external
        view
        returns (uint256 owed)
    {
        for (uint256 i; i < tokenIds.length; i++) {
            owed += _calculateStakingRewards(tokenIds[i]);
        }
        return owed;
    }

    function calculateStakingRewards(uint256 tokenId)
        external
        view
        returns (uint256 owed)
    {
        return _calculateStakingRewards(tokenId);
    }

    // onlyEOA will not work here, as the Arena is calling this function
    function _calculateStakingRewards(uint256 tokenId)
        private
        view
        returns (uint256 owed)
    {
        // Must check these, as getTokenTraits will be allowed since this contract is an admin
        uint64 lastTokenWrite = uNFT.getTokenWriteBlock(tokenId);
        require(lastTokenWrite < block.number, "Nope!");
        uint256 tokenMintBlock = uNFT.getTokenMintBlock(tokenId);
        require(tokenMintBlock < block.number, "Nope!");
        require(uArena.isStaked(tokenId), "Token is not staked");

        IArena.Stake memory myStake;
        INFT.HeroVillain memory traits = _getHVTokenTraits(tokenId);
        address ownerOfToken = _getOwnerOfHVToken(tokenId);

        if (traits.isHero) {
            // Hero
            myStake = uArena.getStake(tokenId);
            // The base World rate that even level 0 Heros get
            owed +=
                ((block.timestamp - myStake.stakeTimestamp) *
                    DAILY_WORLD_RATE) /
                1 days;

            // The rewards from levels
            uint256 rewardsFromLevels = traits.level * DAILY_WORLD_PER_LEVEL;

            // The rewards from Rings with diminishing returns after RING_DIMINISHING_FROM
            uint256 ringsInWallet = getBalanceOfActiveRings(ownerOfToken);
            uint256 rewardsFromRings = 0;

            if (ringsInWallet < RING_DIMINISHING_FROM) {
                rewardsFromRings =
                    traits.level *
                    ringsInWallet *
                    RING_DAILY_WORLD_RATE;
            } else if (ringsInWallet >= RING_DIMINISHING_FROM) {
                // Normal rewards until X-1 rings
                rewardsFromRings =
                    traits.level *
                    (RING_DIMINISHING_FROM - 1) *
                    RING_DAILY_WORLD_RATE;

                uint256 lastRingRewards = RING_DAILY_WORLD_RATE;
                uint256 remainingRings = ringsInWallet -
                    (RING_DIMINISHING_FROM - 1);
                for (uint256 i = 1; i <= remainingRings; i++) {
                    lastRingRewards = (lastRingRewards * 95) / 100;
                    rewardsFromRings += traits.level * lastRingRewards;
                }
            }

            owed +=
                ((block.timestamp - myStake.stakeTimestamp) *
                    (rewardsFromLevels + rewardsFromRings)) /
                1 days;
        } else {
            // Villain
            uint8 rank = traits.rank;
            uint256 WorldPerRank = uArena.getWorldPerRank();
            myStake = myStake = uArena.getStake(tokenId);
            // Calculate portion of $World based on rank
            owed = (rank) * (WorldPerRank - myStake.WorldPerRank);
        }

        return owed;
    }

    // Get the number of Rings that are "active", meaning they have an effect on the game
    function getBalanceOfActiveRings(address owner)
        public
        view
        returns (uint256)
    {
        uint256 tokenCount = uPotion.balanceOf(owner);
        uint256 activeTokens = 0;

        for (uint256 i; i < tokenCount; i++) {
            uint256 tokenId = uPotion.tokenOfOwnerByIndex(owner, i);
            IPotion.Potion memory traits = uPotion.getTokenTraits(tokenId);
            if (block.timestamp >= traits.lastTransferTimestamp + 1 days) {
                activeTokens++;
            }
        }

        return activeTokens;
    }

    /** LEVELING UP NFT */
    function levelUpManyHeros(uint16[] memory tokenIds, uint16 levelsToUpgrade)
        external
        whenNotPaused
        nonReentrant
        onlyEOA
    {
        for (uint16 i; i < tokenIds.length; i++) {
            _levelUpHero(tokenIds[i], levelsToUpgrade);
        }

        // After this, the caller needs to wait for 1 block before seeing the effect of this change
        uNFT.updateOriginAccess(tokenIds);
        emit ManyHerosLeveledUp(_msgSender(), tokenIds);
    }

    function _levelUpHero(uint256 tokenId, uint16 levelsToUpgrade) private {
        // Checks
        require(uNFT.isHero(tokenId), "Only Heros can be leveled up");
        // Token can also belong to the ARENA e.g. when it is staked
        address tokenOwner = _getOwnerOfHVToken(tokenId);
        require(tokenOwner == _msgSender(), "You don't own this token");

        // Effects
        INFT.HeroVillain memory traits = _getHVTokenTraits(tokenId);
        uint256 totalWorldCost = getLevelUpWorldCost(
            traits.level,
            levelsToUpgrade
        );
        uWorld.burn(_msgSender(), totalWorldCost);
        // uWorld.updateOriginAccess();

        // Interactions
        uint16[] memory tokenIds = new uint16[](1);
        tokenIds[0] = uint16(tokenId);

        // Claim $World before level up to prevent issues where higher levels would improve the whole staking period instead of just future periods
        // This also resets the stake and staking period
        if (uArena.isStaked(tokenId)) {
            uArena.claimManyFromArena(tokenIds, false);
        }

        // Level up
        uint16 newLevel = traits.level + levelsToUpgrade;
        uNFT.setTraitLevel(tokenId, newLevel);

        emit HeroLeveledUp(_msgSender(), tokenId);
    }

    function getLevelUpWorldCost(uint16 currentLevel, uint16 levelsToUpgrade)
        public
        view
        onlyEOA
        returns (uint256 totalWorldCost)
    {
        require(currentLevel >= 0, "Invalid currentLevel.");
        require(levelsToUpgrade >= 1, "Invalid levelsToUpgrade.");

        totalWorldCost = 0;

        for (uint16 i = 1; i <= levelsToUpgrade; i++) {
            totalWorldCost += _getWorldCostPerLevel(currentLevel + i);
        }
        require(totalWorldCost > 0, "Error calculating cost.");

        return totalWorldCost;
    }

    // There is no formula that can generate the below numbers that we need - so there we go, one by one :-p
    function _getWorldCostPerLevel(uint16 level)
        private
        pure
        returns (uint256 price)
    {
        if (level == 0) return 0 ether;
        if (level == 1) return 500 ether;
        if (level == 2) return 1000 ether;
        if (level == 3) return 2250 ether;
        if (level == 4) return 4125 ether;
        if (level == 5) return 6300 ether;
        if (level == 6) return 8505 ether;
        if (level == 7) return 10206 ether;
        if (level == 8) return 11510 ether;
        if (level == 9) return 13319 ether;
        if (level == 10) return 14429 ether;
        if (level == 11) return 18036 ether;
        if (level == 12) return 22545 ether;
        if (level == 13) return 28181 ether;
        if (level == 14) return 35226 ether;
        if (level == 15) return 44033 ether;
        if (level == 16) return 55042 ether;
        if (level == 17) return 68801 ether;
        if (level == 18) return 86002 ether;
        if (level == 19) return 107503 ether;
        if (level == 20) return 134378 ether;
        if (level == 21) return 167973 ether;
        if (level == 22) return 209966 ether;
        if (level == 23) return 262457 ether;
        if (level == 24) return 328072 ether;
        if (level == 25) return 410090 ether;
        if (level == 26) return 512612 ether;
        if (level == 27) return 640765 ether;
        if (level == 28) return 698434 ether;
        if (level == 29) return 761293 ether;
        if (level == 30) return 829810 ether;
        if (level == 31) return 904492 ether;
        if (level == 32) return 985897 ether;
        if (level == 33) return 1074627 ether;
        if (level == 34) return 1171344 ether;
        if (level == 35) return 1276765 ether;
        if (level == 36) return 1391674 ether;
        if (level == 37) return 1516924 ether;
        if (level == 38) return 1653448 ether;
        if (level == 39) return 1802257 ether;
        if (level == 40) return 1964461 ether;
        if (level == 41) return 2141263 ether;
        if (level == 42) return 2333976 ether;
        if (level == 43) return 2544034 ether;
        if (level == 44) return 2772997 ether;
        if (level == 45) return 3022566 ether;
        if (level == 46) return 3294598 ether;
        if (level == 47) return 3591112 ether;
        if (level == 48) return 3914311 ether;
        if (level == 49) return 4266600 ether;
        if (level == 50) return 4650593 ether;
        if (level == 51) return 5069147 ether;
        if (level == 52) return 5525370 ether;
        if (level == 53) return 6022654 ether;
        if (level == 54) return 6564692 ether;
        if (level == 55) return 7155515 ether;
        if (level == 56) return 7799511 ether;
        if (level == 57) return 8501467 ether;
        if (level == 58) return 9266598 ether;
        if (level == 59) return 10100593 ether;
        if (level == 60) return 11009646 ether;
        if (level == 61) return 12000515 ether;
        if (level == 62) return 13080560 ether;
        if (level == 63) return 14257811 ether;
        if (level == 64) return 15541015 ether;
        if (level == 65) return 16939705 ether;
        if (level == 66) return 18464279 ether;
        if (level == 67) return 20126064 ether;
        if (level == 68) return 21937409 ether;
        if (level == 69) return 23911777 ether;
        if (level == 70) return 26063836 ether;
        if (level == 71) return 28409582 ether;
        if (level == 72) return 30966444 ether;
        if (level == 73) return 33753424 ether;
        if (level == 74) return 36791232 ether;
        if (level == 75) return 40102443 ether;
        if (level == 76) return 43711663 ether;
        if (level == 77) return 47645713 ether;
        if (level == 78) return 51933826 ether;
        if (level == 79) return 56607872 ether;
        if (level == 80) return 61702579 ether;
        if (level == 81) return 67255812 ether;
        if (level == 82) return 73308835 ether;
        if (level == 83) return 79906630 ether;
        if (level == 84) return 87098226 ether;
        if (level == 85) return 94937067 ether;
        if (level == 86) return 103481403 ether;
        if (level == 87) return 112794729 ether;
        if (level == 88) return 122946255 ether;
        if (level == 89) return 134011418 ether;
        if (level == 90) return 146072446 ether;
        if (level == 91) return 159218965 ether;
        if (level == 92) return 173548673 ether;
        if (level == 93) return 189168053 ether;
        if (level == 94) return 206193177 ether;
        if (level == 95) return 224750564 ether;
        if (level == 96) return 244978115 ether;
        if (level == 97) return 267026144 ether;
        if (level == 98) return 291058498 ether;
        if (level == 99) return 329514746 ether;
        if (level == 100) return 350000000 ether;
        require(false, "This level is not supported yet");
        return price;
    }

    /** ADMIN ONLY FUNCTIONS */
    // Will be called from outside of chain to reveal tokenIds with random seeds
    function revealManyHVTokenTraits(
        uint16[] memory tokenIds,
        uint256[] memory seeds
    ) external whenNotPaused nonReentrant onlyOwner {
        require(tokenIds.length == seeds.length, "Tokens & Seed mismatch");

        for (uint16 i = 0; i < tokenIds.length; i++) {
            uint16 tokenId = tokenIds[i];
            // This will throw an error in uNFT.ownerOf() already, keep in mind!
            require(
                uNFT.ownerOf(tokenId) != address(0),
                "Token does not exist"
            );
            uint256 seed = uint256(keccak256(abi.encodePacked(seeds[i])));
            uNFT.revealTokenId(tokenId, seed);
        }

        emit ManyHVRevealed(_msgSender(), tokenIds);
    }

    /** OWNER ONLY FUNCTIONS */
    function setContracts(
        address _uWorld,
        address _uNFT,
        address _uArena,
        address _uRing,
        address _uAmulet,
        address _uExcalibur
    ) external onlyOwner {
        // randomizer = IRandomizer(_rand);
        uWorld = World(_uWorld);
        uNFT = INFT(_uNFT);
        uArena = IArena(_uArena);
        uPotion = IPotion(_uRing);
        uPowerUp = IPowerUp(_uAmulet);
        uExcalibur = IExcalibur(_uExcalibur);
    }

    function setDailyWorldRate(uint256 number) external onlyOwner {
        DAILY_WORLD_RATE = number;
    }

    function setDailyWorldPerLevel(uint256 number) external onlyOwner {
        DAILY_WORLD_PER_LEVEL = number;
    }

    function setLevelDownAfterDays(uint256 number) external onlyOwner {
        LEVEL_DOWN_AFTER_DAYS = number;
    }

    function setRingDiminishingFrom(uint256 number) external onlyOwner {
        RING_DIMINISHING_FROM = number;
    }

    function setRingWorldMintCost(uint256 number) external onlyOwner {
        RING_WORLD_MINT_COST = number;
    }

    function setRingDailyWorldRate(uint256 number) external onlyOwner {
        RING_DAILY_WORLD_RATE = number;
    }

    function setRingMinWorldMintCost(uint256 number) external onlyOwner {
        RING_MIN_WORLD_MINT_COST = number;
    }

    function setAmuletWorldMintCost(uint256 number) external onlyOwner {
        AMULET_WORLD_MINT_COST = number;
    }

    function setAmuletLevelDownIncreaseDays(uint256 number) external onlyOwner {
        AMULET_LEVEL_DOWN_INCREASE_DAYS = number;
    }

    function setAmuletMinWorldMintCost(uint256 number) external onlyOwner {
        AMULET_MIN_WORLD_MINT_COST = number;
    }

    function setGen1WorldMintCost(uint256 number) external onlyOwner {
        GEN1_WORLD_MINT_COST = number;
    }

    function setGen1MinWorldMintCost(uint256 number) external onlyOwner {
        GEN1_MIN_WORLD_MINT_COST = number;
    }

    function setMintCostReduceInterval(uint256 number) external onlyOwner {
        MINT_COST_REDUCE_INTERVAL = number;
    }

    function setMintCostReducePercent(uint8 number) external onlyOwner {
        MINT_COST_REDUCE_PERCENT = number;
    }

    function setMintCostIncreasePercent(uint8 number) external onlyOwner {
        MINT_COST_INCREASE_PERCENT = number;
    }

    function addAdmin(address addr) external onlyOwner {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }

    // Address can only be set once
    function setWithdrawAddress(address addr) external onlyOwner {
        require(WITHDRAW_ADDRESS == address(0), "Wallet already set");
        require(addr != address(0), "Cannot be set to the zero");

        WITHDRAW_ADDRESS = addr;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = payable(WITHDRAW_ADDRESS).call{value: amount}("");
        require(sent, "Failed to send funds");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface INFT is IERC721Enumerable {

    struct HeroVillain {
        bool isRevealed;
        bool isHero;
        bool isGen0;
        uint16 level;
        uint256 lastLevelUpgradeTime;
        uint8 rank;
        uint256 lastRankUpgradeTime;
        // uint8 courage;
        // uint8 cunning;
        // uint8 brutality;
        uint64 mintedBlockNumber;
    }

    function MAX_TOKENS() external returns (uint256);
    function MAX_GEN0_TOKENS() external returns (uint256);
    function tokensMinted() external returns (uint16);

    function isHero(uint256 tokenId) external view returns(bool);

    function updateOriginAccess(uint16[] memory tokenIds) external; // onlyAdmin
    function mint(address recipient, bool isGen0) external; // onlyAdmin
    function burn(uint256 tokenId) external; // onlyAdmin
    function setTraitLevel(uint256 tokenId, uint16 level) external; // onlyAdmin
    function setTraitRank(uint256 tokenId, uint8 rank) external; // onlyAdmin
    function revealTokenId(uint16 tokenId, uint256 seed) external; // onlyAdmin
    function getTokenTraits(uint256 tokenId) external view returns (HeroVillain memory); // onlyAdmin
    function getVillainRanks() external view returns(uint8[4] memory); // onlyAdmin
    function getAddressWriteBlock() external view returns(uint64); // onlyAdmin
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64); // onlyAdmin
    function getTokenMintBlock(uint256 tokenId) external view returns(uint64); // onlyAdmin
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWorld.sol";

contract World is IWorld, ERC20, Ownable {
    constructor() ERC20("WORLD", "WORLD") {}

    /** PRIVATE VARS */
    // Store admins to allow them to call certain functions
    mapping(address => bool) private _admins;

    /** MODIFIERS */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "World: Only admins can call this");
        _;
    }

    mapping(address => uint256) private _balances;
    uint256 private buy_tax_marketing = 5;
    uint256 private buy_tax_lp = 5;
    uint256 private buy_tax_dev = 3;
    uint256 private sell_tax_marketing = 5;
    uint256 private sell_tax_lp = 10;
    uint256 private sell_tax_dev = 3;
    address public lpAddress;
    address private devWallet =
        address(0xbc2Bc474A1322889566443B2cF59cf41254c265f);
    address private marketingWallet =
        address(0x5A0125ac2274554D56305359b4D9Fd25D941980A);
    address private lpWallet =
        address(0x644F29FaC3Aa63eCDF41d9fcf9D0836BEC4aA38E);

      /** ONLY ADMIN FUNCTIONS */
  function mint(address to, uint256 amount) external override onlyAdmin {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external override onlyAdmin {
    _burn(from, amount);
  }

  /** OVERRIDE FOR SECURITY */
  function transferFrom(address sender, address recipient, uint256 amount) public virtual override(ERC20, IWorld)  returns (bool) {
    return super.transferFrom(sender, recipient, amount);
  }

  function balanceOf(address account) public view virtual override  returns (uint256) {
    return super.balanceOf(account);
  }

  function transfer(address recipient, uint256 amount) public virtual override  returns (bool) {
    return super.transfer(recipient, amount);
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return super.allowance(owner, spender);
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    return super.approve(spender, amount);
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
    return super.decreaseAllowance(spender, subtractedValue);
  }
  
  function totalSupply() public view virtual override(ERC20, IWorld) returns (uint256) {
    return super.totalSupply();
  }

  /** ONLY OWNER FUNCTIONS */
  function addAdmin(address addr) external onlyOwner {
    _admins[addr] = true;
  }

  function removeAdmin(address addr) external onlyOwner {
    delete _admins[addr];
  }
    function setDevwallet(address _address) external onlyOwner {
        devWallet = _address;
    }

    function setMarketingWallet(address _address) external onlyOwner {
        marketingWallet = _address;
    }

    function setLPWallet(address _address) external onlyOwner {
        lpWallet = _address;
    }

    //WORLD/AVAX = address generated
    function setLPAddress(address _address) external onlyOwner {
        lpAddress = _address;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IPotion is IERC721Enumerable {

    struct Potion {
        uint256 mintedTimestamp;
        uint256 mintedBlockNumber;
        uint256 lastTransferTimestamp;
    }
    
    function tokensMinted() external returns (uint256);

    function mint(address recipient, uint256 amount) external; // onlyAdmin
    function burn(uint256 tokenId) external; // onlyAdmin
    function getTokenTraits(uint256 tokenId) external view returns (Potion memory); // onlyAdmin
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IPowerUp is IERC721Enumerable {

    struct PowerUp {
        uint256 mintedTimestamp;
        uint256 mintedBlockNumber;
        uint256 lastTransferTimestamp;
    }

    function tokensMinted() external returns (uint256);
    
    function mint(address recipient, uint256 amount) external; // onlyAdmin
    function burn(uint256 tokenId) external; // onlyAdmin
    function getTokenTraits(uint256 tokenId) external view returns (PowerUp memory); // onlyAdmin
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity >=0.8.11;

interface IArena {

  struct Stake {
    uint16 tokenId;
    uint256 WorldPerRank;
    uint256 stakeTimestamp;
    address owner;
  }
  
  function stakeManyToArena(uint16[] calldata tokenIds) external;
  function claimManyFromArena(uint16[] calldata tokenIds, bool unstake) external;
  function randomVillainOwner(uint256 seed) external view returns (address);
  function getStakedTokenIds(address owner) external view returns (uint256[] memory);
  function getStake(uint256 tokenId) external view returns (Stake memory);
  function isStaked(uint256 tokenId) external view returns (bool);
  function getWorldPerRank() external view returns(uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.8.11;

import "./INFT.sol";

interface IGame {
    function getOwnerOfHVToken(uint256 tokenId) external view returns(address ownerOf);
    function getHVTokenTraits(uint256 tokenId) external view returns (INFT.HeroVillain memory);
    function calculateStakingRewards(uint256 tokenId) external view returns (uint256 owed);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IExcalibur is IERC721Enumerable {

    struct Excalibur {
        uint256 mintedTimestamp;
        uint256 mintedBlockNumber;
        uint256 lastTransferTimestamp;
    }
    
    function tokensMinted() external returns (uint256);

    function mint(address recipient, uint256 amount) external; // onlyAdmin
    function burn(uint256 tokenId) external; // onlyAdmin
    function getTokenTraits(uint256 tokenId) external view returns (Excalibur memory); // onlyAdmin
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity >=0.8.11;

interface IWorld {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
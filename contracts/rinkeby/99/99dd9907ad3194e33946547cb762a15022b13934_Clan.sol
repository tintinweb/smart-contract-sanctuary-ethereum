// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IDwarfs_NFT.sol";
import "./IGOD.sol";
import "./Random.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/// @title Clan
/// @author Bounyavong
/// @dev Clan logic is implemented and this is the upgradeable
contract Clan is OwnableUpgradeable, PausableUpgradeable {
    // struct to store a token information
    struct TokenInfo {
        uint32 tokenId;
        uint32 cityId;
        uint32 level;
        uint128 lastInvestedTime;
        uint256 availableBalance;
        uint256 currentInvestedAmount;
    }

    // event when token invested
    event TokenInvested(
        uint32 tokenId,
        uint128 lastInvestedTime,
        uint256 investedAmount
    );

    // reference to the Dwarfs_NFT NFT contract
    IDwarfs_NFT public dwarfs_nft;

    // reference to the $GOD contract for minting $GOD earnings
    IGOD public god;

    // token information map
    mapping(uint256 => TokenInfo) public mapTokenInfo;

    // map of mobster IDs for cityId
    mapping(uint256 => uint32[]) public mapCityMobsters;

    // map of mobster unaccounted GOD for cityId
    mapping(uint256 => uint256) public mapCityTax;

    // map of merchant count for cityId
    mapping(uint256 => uint256) public mapCityMerchantCount;

    struct ContractInfo {
        // total number of tokens in the clan
        uint32 totalNumberOfTokens;
        // max merchant count for a city
        uint32 MAX_MERCHANT_COUNT;
        // merchant earn 1% of investment of $GOD per day
        uint32 DAILY_GOD_RATE;
        // mobsters take 15% on all $GOD claimed
        uint32 TAX_PERCENT;
        // playing merchant game enabled
        uint32 bMerchantGamePlaying;
        // the last cityID in the clan
        uint32 lastCityID;
    }
    ContractInfo public contractInfo;

    // there will only ever be (roughly) 2.4 billion $GOD earned through staking
    uint256 public MAXIMUM_GLOBAL_GOD;

    // initial Balance of a new Merchant
    uint256[] public INITIAL_GOD_AMOUNT;

    // minimum GOD invested amount
    uint256 public MIN_INVESTED_AMOUNT;

    // amount of $GOD earned so far
    uint256 public remainingGodAmount;

    // profit percent of each mobster; x 0.1 %
    uint32[] public mobsterProfitPercent;

    // A hidden random seed for the random() function
    uint256 private randomSeed;
    uint256 public revealedRandomSeed;

    event ClaimManyFromClan(
        uint256[] tokenIds,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @dev initialize function
     * @param _dwarfs_nft reference to the Dwarfs_NFT NFT contract
     * @param _god reference to the $GOD token
     */
    function initialize(address _dwarfs_nft, address _god)
        public
        virtual
        initializer
    {
        __Ownable_init();
        __Pausable_init();
        dwarfs_nft = IDwarfs_NFT(_dwarfs_nft);
        god = IGOD(_god);

        // merchant earn 1% of investment of $GOD per day
        contractInfo.DAILY_GOD_RATE = 1;

        // mobsters take 20% on all $GOD claimed
        contractInfo.TAX_PERCENT = 20;

        // there will only ever be (roughly) 2.4 billion $GOD earned through staking
        MAXIMUM_GLOBAL_GOD = 3000000000 ether;

        // initial Balance of a new Merchant
        INITIAL_GOD_AMOUNT = [
            100000 ether,
            50000 ether,
            50000 ether,
            50000 ether
        ];

        // minimum GOD invested amount
        MIN_INVESTED_AMOUNT = 1000 ether;

        // amount of $GOD earned so far
        remainingGodAmount = MAXIMUM_GLOBAL_GOD;

        // profit percent of each mobster; x 0.1 %
        mobsterProfitPercent = [4, 7, 14, 29];

        // playing merchant game enabled
        contractInfo.bMerchantGamePlaying = 1;

        contractInfo.MAX_MERCHANT_COUNT = 1200;

        contractInfo.lastCityID = 1;
    }

    /** VIEW */

    /**
     * @dev get the Merchant Ids of the selected city
     * @param _cityId the Id of the city
     */
    function getMerchantIdsOfCity(uint256 _cityId)
        external
        view
        returns (uint256[] memory)
    {
        require(mapCityMerchantCount[_cityId] > 0, "NO_MERCHANT_IN_CITY");

        uint256[] memory tokenIds = new uint256[](
            mapCityMerchantCount[_cityId]
        );
        uint256 count = 0;
        for (uint256 i = 1; i <= contractInfo.totalNumberOfTokens; i++) {
            if (isMerchant(i) && mapTokenInfo[i].cityId == _cityId) {
                tokenIds[count] = i;
                count++;
            }
        }

        return tokenIds;
    }

    /**
     * @dev get the current information of the selected tokens
     * @param tokenIds the IDs of the tokens
     */
    function getBatchTokenInfo(uint256[] calldata tokenIds)
        external
        view
        returns (TokenInfo[] memory)
    {
        TokenInfo[] memory tokenInfos = new TokenInfo[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenInfos[i] = mapTokenInfo[tokenIds[i]];
        }

        return tokenInfos;
    }

    /**
     * @dev get balance of a token
     * @param tokenId the Id of a token
     * @return tokenBalance the balance of the token
     */
    function getTokenBalance(uint256 tokenId)
        public
        view
        returns (uint256 tokenBalance)
    {
        if (isMerchant(tokenId)) {
            tokenBalance = calcMerchantBalance(tokenId);
        } else {
            tokenBalance = calcMobsterBalance(tokenId);
        }
    }

    /**
     * @dev get balance of a token
     * @param tokenIds the Ids of tokens
     * @return tokenBalances
     */
    function getBatchTokenBalances(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory tokenBalances)
    {
        tokenBalances = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenBalances[i] = getTokenBalance(tokenIds[i]);
        }
    }

    /** UTILITY */

    /**
     * @dev check if the token is Merchant
     * @param tokenId the token Id of the token
     * @return Is Merchant ?
     */
    function isMerchant(uint256 tokenId) internal view returns (bool) {
        return (mapTokenInfo[tokenId].level < 5);
    }

    /**
     * @dev floor 3 digits of $GOD amount
     * @param amount $GOD amount
     * @return floorAmount - the floor amount of $GOD
     */
    function _floorGodAmount(uint256 amount)
        internal
        pure
        returns (uint256 floorAmount)
    {
        floorAmount = (amount / 1e12) * 1e12;
    }

    /** STAKING */

    /**
     * @dev adds Merchant and Mobsters to the Clan
     * @param tokenId the ID of the Merchant or Mobster to add to the clan
     * @param trait the trait of the token
     */
    function _addToClan(uint256 tokenId, ITraits.DwarfTrait calldata trait)
        internal
        returns (uint256 godAmount)
    {
        if (trait.level >= 5) {
            mapCityMobsters[trait.cityId].push(uint32(tokenId));
            contractInfo.lastCityID = trait.cityId;
        }

        TokenInfo memory _tokenInfo;
        _tokenInfo.tokenId = uint32(tokenId);
        _tokenInfo.cityId = trait.cityId;
        _tokenInfo.level = trait.level;
        _tokenInfo.availableBalance = (
            trait.level < 5 ? INITIAL_GOD_AMOUNT[trait.generation] : 0
        );
        _tokenInfo.currentInvestedAmount = _tokenInfo.availableBalance;
        _tokenInfo.lastInvestedTime = uint128(block.timestamp);
        mapTokenInfo[tokenId] = _tokenInfo;

        godAmount = _tokenInfo.currentInvestedAmount;
    }

    /**
     * @dev adds Merchant and Mobsters to the Clan
     * @param tokenId the ID of the Merchant or Mobster to add to the clan
     * @param trait the trait of the token
     */
    function addOneToClan(uint256 tokenId, ITraits.DwarfTrait calldata trait)
        external
    {
        require(_msgSender() == address(dwarfs_nft), "CALLER_NOT_DWARF");
        uint256 godAmount = _addToClan(tokenId, trait);
        contractInfo.totalNumberOfTokens++;
        remainingGodAmount += godAmount;
    }

    /**
     * @dev adds Merchant and Mobsters to the Clan
     * @param tokenIds the IDs of the Merchants and Mobsters to add to the clan
     * @param traits the traits of the tokens
     */
    function addManyToClan(
        uint256[] calldata tokenIds,
        ITraits.DwarfTrait[] calldata traits
    ) external {
        require(_msgSender() == address(dwarfs_nft), "CALLER_NOT_DWARF");
        uint256 _totalGod;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _totalGod += _addToClan(tokenIds[i], traits[i]);
        }
        contractInfo.totalNumberOfTokens += uint32(tokenIds.length);
        remainingGodAmount += _totalGod;
    }

    /**
     * @dev reduce the balance of the token in the clan contract
     * @param tokenId the Id of the token
     * @param amount the amount of GOD to reduce in the clan
     */
    function reduceGodBalance(uint256 tokenId, uint256 amount) external {
        require(_msgSender() == address(dwarfs_nft), "CALLER_NOT_DWARF");
        uint256 _balance;
        if (isMerchant(tokenId)) {
            // Is merchant
            uint256 _totalAmount = (amount / (100 - contractInfo.TAX_PERCENT)) *
                100;
            _balance = calcMerchantBalance(tokenId);
            require(_balance >= _totalAmount, "NOT_ENOUGH_BALANCE");

            mapCityTax[mapTokenInfo[tokenId].cityId] += ((_totalAmount *
                contractInfo.TAX_PERCENT) / 100);

            mapTokenInfo[tokenId].availableBalance = _balance - _totalAmount;
            mapTokenInfo[tokenId].currentInvestedAmount =
                _balance -
                _totalAmount;
        }
        {
            // Is mobster
            _balance = calcMobsterBalance(tokenId);
            require(_balance >= amount, "NOT_ENOUGH_BALANCE");
            mapTokenInfo[tokenId].currentInvestedAmount += amount; // total withdrawed amount
        }
        mapTokenInfo[tokenId].lastInvestedTime = uint128(block.timestamp);
    }

    /**
     * @dev add the single merchant to the city
     * @param tokenIds the IDs of the merchants token to add to the city
     * @param cityId the city id
     */
    function addMerchantsToCity(uint256[] calldata tokenIds, uint256 cityId)
        external
        whenNotPaused
    {
        require(
            mapCityMerchantCount[cityId] + tokenIds.length <=
                contractInfo.MAX_MERCHANT_COUNT,
            "CHOOSE_ANOTHER"
        );
        require(
            cityId > 0 && cityId <= contractInfo.lastCityID,
            "INVALID_CITY"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                dwarfs_nft.ownerOf(tokenIds[i]) == _msgSender(),
                "AINT YO TOKEN"
            );
            require(isMerchant(tokenIds[i]), "NOT_MERCHANT");
            require(mapTokenInfo[tokenIds[i]].cityId == 0, "ALREADY_IN_CITY");

            mapTokenInfo[tokenIds[i]].cityId = uint32(cityId);
            mapTokenInfo[tokenIds[i]].lastInvestedTime = uint128(
                block.timestamp
            );
        }
        mapCityMerchantCount[cityId] += tokenIds.length;
    }

    /**
     * @dev Calcualte the current available balance of a merchant to claim
     * @param tokenId the token id to calculate the available balance
     */
    function calcMerchantBalance(uint256 tokenId)
        internal
        view
        returns (uint256 availableBalance)
    {
        TokenInfo memory _tokenInfo = mapTokenInfo[tokenId];
        availableBalance = _tokenInfo.availableBalance;
        uint256 playingGame = (_tokenInfo.cityId > 0 &&
            contractInfo.bMerchantGamePlaying > 0)
            ? 1
            : 0;
        uint256 addedBalance = (_tokenInfo.currentInvestedAmount *
            playingGame *
            (block.timestamp - uint256(_tokenInfo.lastInvestedTime)) *
            contractInfo.DAILY_GOD_RATE) /
            100 /
            1 days;
        availableBalance += _floorGodAmount(addedBalance);
    }

    /**
     * @dev Calcualte the current available balance of a mobster to claim
     * @param tokenId the token id to calculate the available balance
     */
    function calcMobsterBalance(uint256 tokenId)
        internal
        view
        returns (uint256 availableBalance)
    {
        availableBalance = _floorGodAmount(
            ((mapCityTax[mapTokenInfo[tokenId].cityId] *
                mobsterProfitPercent[mapTokenInfo[tokenId].level - 5]) / 1000) -
                mapTokenInfo[tokenId].currentInvestedAmount
        );
    }

    /**
     * @dev Invest GODs
     * @param tokenId the token id to invest god
     * @param godAmount the invest amount
     */
    function investGods(uint256 tokenId, uint256 godAmount)
        external
        whenNotPaused
    {
        require(dwarfs_nft.ownerOf(tokenId) == _msgSender(), "AINT YO TOKEN");
        require(isMerchant(tokenId), "NOT_MERCHANT");
        require(godAmount >= MIN_INVESTED_AMOUNT, "GOD_INSUFFICIENT");
        require(mapTokenInfo[tokenId].cityId > 0, "OUT_OF_CITY");

        god.burn(_msgSender(), godAmount);
        mapTokenInfo[tokenId].availableBalance =
            calcMerchantBalance(tokenId) +
            godAmount;
        mapTokenInfo[tokenId].currentInvestedAmount += godAmount; // total invested amount
        mapTokenInfo[tokenId].lastInvestedTime = uint128(block.timestamp);

        remainingGodAmount += godAmount;
        emit TokenInvested(
            uint32(tokenId),
            mapTokenInfo[tokenId].lastInvestedTime,
            godAmount
        );
    }

    /** CLAIMING / RISKY */
    /**
     * @dev realize $GOD earnings and optionally unstake tokens from the Clan (Cities)
     * to unstake a Merchant it will require it has 2 days worth of $GOD unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param bRisk the risky game flag (enable/disable)
     */
    function claimManyFromClan(uint256[] calldata tokenIds, bool bRisk)
        external
        whenNotPaused
    {
        require(contractInfo.totalNumberOfTokens > 8000, "NOT_PHASE2");
        uint256 owed;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIds[i] <= contractInfo.totalNumberOfTokens,
                "NOT_IN_CLAN"
            );

            if (mapTokenInfo[tokenIds[i]].level < 5) {
                owed += _claimMerchantFromCity(tokenIds[i], bRisk);
            } else owed += _claimMobsterFromCity(tokenIds[i]);
        }

        require(owed > 0, "NO_BALANCE");

        if (remainingGodAmount < owed) {
            contractInfo.bMerchantGamePlaying = 0;
            remainingGodAmount = 0;
        } else {
            remainingGodAmount -= owed;
        }

        god.mint(_msgSender(), owed);

        emit ClaimManyFromClan(tokenIds, owed, block.timestamp);
    }

    /**
     * @dev realize $GOD earnings for a single Merchant and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Mobsters
     * if unstaking, there is a 50% chance all $GOD is stolen
     * @param tokenId the ID of the Merchant to claim earnings from
     * @param bRisk the risky game flag
     * @return owed - the amount of $GOD earned
     */
    function _claimMerchantFromCity(uint256 tokenId, bool bRisk)
        internal
        returns (uint256 owed)
    {
        require(dwarfs_nft.ownerOf(tokenId) == _msgSender(), "AINT YO TOKEN");

        owed = calcMerchantBalance(tokenId);

        if (mapTokenInfo[tokenId].cityId > 0) {
            uint256 tax;
            if (bRisk == true) {
                // risky game
                if (Random.random(tokenId, randomSeed) & 1 == 1) {
                    tax = owed;
                    owed = 0;
                }
            } else {
                tax = (owed * contractInfo.TAX_PERCENT) / 100;
                owed -= tax;
            }
            mapCityMerchantCount[mapTokenInfo[tokenId].cityId]--;
            mapCityTax[mapTokenInfo[tokenId].cityId] += tax;
            mapTokenInfo[tokenId].cityId = 0;
        }

        mapTokenInfo[tokenId].availableBalance = 0;
        mapTokenInfo[tokenId].currentInvestedAmount = 0;
    }

    /**
     * @dev realize $GOD earnings for a single Mobster
     * Mobsters earn $GOD proportional to their Level
     * @param tokenId the ID of the Mobster to claim earnings from
     * @return owed - the amount of $GOD earned
     */
    function _claimMobsterFromCity(uint256 tokenId)
        internal
        returns (uint256 owed)
    {
        require(dwarfs_nft.ownerOf(tokenId) == _msgSender(), "AINT YO TOKEN");

        owed = calcMobsterBalance(tokenId);
        mapTokenInfo[tokenId].currentInvestedAmount += owed; // total withdrawed amount
        mapTokenInfo[tokenId].lastInvestedTime = uint128(block.timestamp);
    }

    /** ADMIN */

    /**
     * @dev enables owner to pause / unpause minting
     * @param _bPaused the flag to pause or unpause
     */
    function setPaused(bool _bPaused) external onlyOwner {
        if (_bPaused) _pause();
        else _unpause();
    }

    /**
     * @dev set the daily god earning rate
     * @param _dailyGodRate the daily god earning rate
     */
    function setDailyGodRate(uint32 _dailyGodRate) public onlyOwner {
        contractInfo.DAILY_GOD_RATE = _dailyGodRate;
    }

    /**
     * @dev set the tax percent of a merchant
     * @param _taxPercent the tax percent
     */
    function setTaxPercent(uint32 _taxPercent) public onlyOwner {
        contractInfo.TAX_PERCENT = _taxPercent;
    }

    /**
     * @dev set the max global god amount
     * @param _maxGlobalGod the god amount
     */
    function setMaxGlobalGodAmount(uint256 _maxGlobalGod) public onlyOwner {
        MAXIMUM_GLOBAL_GOD = _maxGlobalGod;
    }

    /**
     * @dev set the initial god amount of a merchant
     * @param _initialGodAmount the god amount
     */
    function setInitialGodAmount(uint256[] calldata _initialGodAmount)
        public
        onlyOwner
    {
        INITIAL_GOD_AMOUNT = _initialGodAmount;
    }

    /**
     * @dev set the min god amount for investing
     * @param _minInvestedAmount the god amount
     */
    function setMinInvestedAmount(uint256 _minInvestedAmount) public onlyOwner {
        MIN_INVESTED_AMOUNT = _minInvestedAmount;
    }

    /**
     * @dev set the mobster profit percent (dwarfsoldier, dwarfcapos, boss and dwarfather)
     * @param _mobsterProfits the percent array
     */
    function setMobsterProfitPercent(uint32[] memory _mobsterProfits)
        public
        onlyOwner
    {
        mobsterProfitPercent = _mobsterProfits;
    }

    /**
     * @dev set the Dwarf NFT address
     * @param _dwarfNFT the Dwarf NFT address
     */
    function setDwarfNFT(address _dwarfNFT) external onlyOwner {
        dwarfs_nft = IDwarfs_NFT(_dwarfNFT);
    }

    /**
     * @dev set the GOD address
     * @param _god the GOD address
     */
    function setGod(address _god) external onlyOwner {
        god = IGOD(_god);
    }

    /**
     * @dev set the max merchant count for a city
     * @param _maxMerchantCount the MAX_MERCHANT_COUNT value
     */
    function setMaxMerchantCount(uint32 _maxMerchantCount) external onlyOwner {
        contractInfo.MAX_MERCHANT_COUNT = _maxMerchantCount;
    }

    /**
     * @dev set the randomSeed value
     * @param _randomSeed the randomSeed value for the random() function
     */
    function setRandomSeed(uint256 _randomSeed) external onlyOwner {
        require(randomSeed == 0, "SET_ALREADY");
        randomSeed = _randomSeed;
    }

    /**
     * @dev reveal the randomSeed value
     */
    function revealRandomSeed() external onlyOwner {
        revealedRandomSeed = randomSeed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Random {
    /**
     * @dev generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed, uint256 randomSeed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        randomSeed,
                        seed
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITraits {

    // struct to store each token's traits
    struct DwarfTrait {
        uint32 index;
        uint32 cityId;
        uint32 level;
        uint32 generation;
    }

    function selectTraits(
        uint32 generation,
        uint256 countMerchant,
        uint256 countMobster
    ) external returns (DwarfTrait[] memory traits);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IGOD {
    /**
     * @dev burns $GOD from a holder
     * @param from the holder of the $GOD
     * @param amount the amount of $GOD to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev mints $GOD to a recipient
     * @param to the recipient of the $GOD
     * @param amount the amount of $GOD to mint
     */
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./ITraits.sol";

interface IDwarfs_NFT {
    /** READ */
    /**
     * @dev get the token traits details
     * @param tokenId the token id
     * @return DwarfTrait memory
     */
    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (ITraits.DwarfTrait memory);

    /**
     * @dev get the token traits details
     * @param tokenIds the token ids
     * @return traits DwarfTrait[] memory
     */
    function getBatchTokenTraits(uint256[] calldata tokenIds)
        external
        view
        returns (ITraits.DwarfTrait[] memory traits);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
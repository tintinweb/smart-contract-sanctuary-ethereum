/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT

/**
                    ____________________
              _____|____________________|_____
           __|_____|                    |_____|__
        __|__|                                |__|__
     __|__|                                      |__|__
    |  |                                            |  |
    |  |               __                   __      |  |
    |  |              |  |                 |  |     |  |
    |  |              |__|                 |__|     |  |
    |  |            __________________________      |  |
    |  |           |      ______________      |     |  |
    |  |           |__   |_____         |   __|     |  |
    |__|__            |_____|  |        |__|      __|__|
       |__|_____            |  |        |   _____|__|
          |_____|___________|  |        |__|_____|
                |___________|  |        |__|
     __   __       __  ___  __   __        __   __   __
    /  ` |__) \ / |__)  |  /  \ |__) |    /  \ |__) /__`
    \__, |  \  |  |     |  \__/ |__) |___ \__/ |__) .__/
     __        __   ___  __   __   __             ___  __  ___
    /__` |  | |__) |__  |__) /  ` /  \ |    |    |__  /  `  |  | \  /
    .__/ \__/ |    |___ |  \ \__, \__/ |___ |___ |___ \__,  |  |  \/

    CryptoBlobs by SuperCollectiv. Learn more on https://cryptoblobs.com.
    Copyright © 2022 SuperCollectiv LLC. All rights reserved.

    Twitter: https://twitter.com/SuperCollectiv
    Discord: https://cryptoblobs.com/discord

    Write method IDs (function hashes):
    "095ea7b3": "approve(address,uint256)"
    "1e897afb": "batch(bytes[])"
    "007e6eda": "manageContract(uint256,address[],uint256[],string[],bytes)"
    "eeca5d73": "manageTrades(address,bytes32)"
    "f2e4b6c8": "metadata(string,string,string)"
    "836a1040": "mint(uint256,address,uint256)"
    "383be151": "optimize(uint256[])"
    "0accf375": "sacrifice(uint256,uint256[])"
    "42842e0e": "safeTransferFrom(address,address,uint256)"
    "b88d4fde": "safeTransferFrom(address,address,uint256,bytes)"
    "a22cb465": "setApprovalForAll(address,bool)"
    "616e4167": "trade(address,address,uint256[],uint256[],uint256,uint256,uint256,bytes)"
    "23b872dd": "transferFrom(address,address,uint256)"

    Read method IDs (function hashes):
    "7dcffcea": "accountData(address,bool,bool)"
    "05f71139": "accountDataByCategory(address[],uint256)"
    "673154e0": "addressesToENS(address[])"
    "70a08231": "balanceOf(address)"
    "e4b68f6a": "batchTradeHashUsedAndHasAccess(address[],uint256[])"
    "6c8381f8": "candidate()"
    "e8a3d485": "contractURI()"
    "e9554894": "generalData(address,uint256)"
    "081812fc": "getApproved(uint256)"
    "e985e9c5": "isApprovedForAll(address,address)"
    "9223dc85": "isTradeApprovedAndValid(address,address,uint256[],uint256[],uint256,uint256,uint256,bytes,bool)"
    "06fdde03": "name()"
    "8da5cb5b": "owner()"
    "6352211e": "ownerOf(uint256)"
    "4eba3a1d": "preapprovedServiceStatus(address)"
    "01ffc9a7": "supportsInterface(bytes4)"
    "95d89b41": "symbol()"
    "4f6ccce7": "tokenByIndex(uint256)"
    "29b69134": "tokenData(uint256,bool)"
    "eb86b58e": "tokenDataByCategory(uint256,uint256,uint256)"
    "2f745c59": "tokenOfOwnerByIndex(address,uint256)"
    "c87b56dd": "tokenURI(uint256)"
    "18160ddd": "totalSupply()"

    Event topics:
    "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef": "Transfer(address,address,uint256)"
    "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925": "Approval(address,address,uint256)"
    "0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31": "ApprovalForAll(address,address,bool)"
    "0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0": "OwnershipTransferred(address,address)"
    "0xf26aaf0d6935ae39e0b17d4770395a2cf37139301bf4a1550daabaa363cb8df0": "MintPurchase(address,address,uint256)"
    "0x7236fe0badcff1706816875cc9df7b9b481c3fb939efe1e7967099499db621d9": "MintFree(address,address,uint256,uint256)"
    "0x10d92c47650ef2b2a841f26c951f4391ccbb731e57d36a67665a0d138e08ef09": "Trade(bytes32,address,address,uint256[],uint256[],uint256,uint256,uint256,bool)"
    "0xff06b6e7e3b7963958aa44cc1dff152337abfc3ef2d0ecd54bdcd8fb9694e0eb": "Optimize(address,uint256[],uint256)"
    "0x062e360bff2a6872f7e8ce922ee6867aaeed320f740365aa0c33bb226d45b034": "Metadata(address,string,string,string,uint256)"

    Supported interfaces:
    "0x01ffc9a7": "IERC165"
    "0x80ac58cd": "IERC721"
    "0x5b5e139f": "IERC721Metadata"
    "0x780e9d63": "IERC721Enumerable"

 */

pragma solidity 0.8.17;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

/**
    @notice Interface ID: 0x01ffc9a7
*/
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
    @notice Interface ID: 0x80ac58cd
*/
interface IERC721 is IERC165 {
    // Topic: 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    // Topic: 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    // Topic: 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
    @notice Interface ID: 0x5b5e139f
*/
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
    @notice Interface ID: 0x780e9d63
*/
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
    @notice Interface for reverse records.
*/
interface IReverseRecords {
    function getNames(address[] calldata addresses) external view returns (string[] memory r);
}

/**
    @notice Allows the contract to have an owner that can manage the contract.
*/
abstract contract Ownable {

    constructor() {
        // Set the owner of the contract.
        _contractOwner = tx.origin;

        emit OwnershipTransferred(  // 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0
            address(0),             // address indexed previousOwner
            _contractOwner          // address indexed newOwner
        );
    }

    // Topic: 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0
    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );

    /// @notice Owner can manage the contract using {manageContract}.
    address internal _contractOwner;

    /// @notice Candidate can confirm a contract transfer with {manageContract}.
    address internal _contractCandidate;

    /// @notice Fill up storage slot 2 for gas optimization.
    uint96 internal _unused = 0;

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _contractOwner;
    }

    /// @dev Returns the address of the current candidate.
    function candidate() public view virtual returns (address) {
        return _contractCandidate;
    }
}

/**
    @notice SuperERC721 is a hyperoptimized implementation of the ERC721 token (NFT) standard developed by SuperCollectiv.
    @dev Only contains read methods. See [CryptoBlobs] for write methods.
*/
abstract contract SuperERC721 is
    Ownable,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{

    constructor() {
        // Initialize reentrancy status.
        _reentrancyStatus = _reentrancyUnlocked;

        // Preapproved services: OpenSea, X2Y2, LooksRare, Rarible, 0x Protocol v4, Element, SudoSwap, NFTX, and NFTTrader.
        // Some of these services also work on NFT aggregator marketplaces like Gem, Genie, and Element (hybrid marketplace).
        // You can revoke these services using {setApprovalForAll} or visit CryptoBlobs.com for a batch tx to revoke all.

        // Services that list your account operators will not detect that these addresses have
        // been approved unless you reapprove each service with {setApprovalForAll} or {batch}.
        // Visit CryptoBlobs.com to create a batch transaction to reapprove all.

        // SuperCollectiv can manage these services with {manageContract}. 
        // We can permanently disable, temporarily disable, and reenable temporarily disabled services.
        // Use {preapprovedServiceStatus} to check the current status of each service.
        
        // [CAUTION] We audited each service and discovered the following:
        // X2Y2 and Rarible both have an admin account that can transfer assets from your account. 
        // We still preapproved these services because they have a high reputation
        // of being trustworthy and we could not find evidence of this being exploited.

        // Ultimately, it is your responsibility to manage these services.
        // You may send us feedback about this feature if you have any questions or concerns.

        address[9] memory _preapprovedServices = [
            // OpenSea
            // https://opensea.io/
            // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
            0x1E0049783F008A0085193E00003D00cd54003c71,
            // X2Y2
            // https://x2y2.io/
            // https://etherscan.io/address/0xF849de01B080aDC3A814FaBE1E2087475cF2E354
            0xF849de01B080aDC3A814FaBE1E2087475cF2E354,
            // LooksRare
            // https://looksrare.org/
            // https://etherscan.io/address/0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e
            0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e,
            // Rarible
            // https://rarible.com/
            // https://etherscan.io/address/0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be
            0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be,
            // 0x Protocol, Coinbase NFT, and more
            // https://www.0x.org/ https://nft.coinbase.com/
            // https://etherscan.io/address/0xDef1C0ded9bec7F1a1670819833240f027b25EfF
            0xDef1C0ded9bec7F1a1670819833240f027b25EfF,
            // Element
            // https://element.market/ethereum
            // https://etherscan.io/address/0x20F780A973856B93f63670377900C1d2a50a77c4
            0x20F780A973856B93f63670377900C1d2a50a77c4,
            // SudoSwap
            // https://sudoswap.xyz/
            // https://etherscan.io/address/0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329
            0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329,
            // NFTX
            // https://nftx.io/
            // https://etherscan.io/address/0x0fc584529a2aefa997697fafacba5831fac0c22d
            0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d,
            // NFTTrader
            // https://www.nfttrader.io/
            // https://etherscan.io/address/0x657E383EdB9A7407E468acBCc9Fe4C9730c7C275
            0x657E383EdB9A7407E468acBCc9Fe4C9730c7C275
        ];
        for (uint256 i; i < _preapprovedServices.length; i++) {
            _account[_preapprovedServices[i]].preapprovedStatus = 2; // Enable each service.
        }
    }

    modifier nonReentrant() {
        if (_reentrancyStatus == _reentrancyLocked) revert REENTRANT_CALLS_ARE_NOT_ALLOWED();
        _reentrancyStatus = _reentrancyLocked;
        _;
        _reentrancyStatus = _reentrancyUnlocked;
    }

    // Topic: 0xf26aaf0d6935ae39e0b17d4770395a2cf37139301bf4a1550daabaa363cb8df0
    event MintPurchase(
        address account,
        address referrer,
        uint256 data
    );

    // Topic: 0x7236fe0badcff1706816875cc9df7b9b481c3fb939efe1e7967099499db621d9
    event MintFree(
        address account, 
        address contractAddress, 
        uint256 tokenId,
        uint256 data
    );

    // Topic: 0x10d92c47650ef2b2a841f26c951f4391ccbb731e57d36a67665a0d138e08ef09
    event Trade(
        bytes32 indexed hash,
        address indexed maker,
        address indexed taker,
        uint256[] makerIds,
        uint256[] takerIds,
        uint256 price,
        uint256 expiry,
        uint256 timestamp,
        bool isTrade
    );

    // Topic: 0xff06b6e7e3b7963958aa44cc1dff152337abfc3ef2d0ecd54bdcd8fb9694e0eb
    event Optimize(
        address indexed account,
        uint256[] tokenIds,
        uint256 timestamp
    );

    // Topic: 0x062e360bff2a6872f7e8ce922ee6867aaeed320f740365aa0c33bb226d45b034
    event Metadata(
        address indexed account,
        string indexed table,
        string indexed key,
        string value,
        uint256 timestamp
    );

    // Constants - These values cannot be modified.

    /// @notice The symbol of the token.
    string internal constant _symbol = "BLOB";
    /// @notice Max supply of CryptoBlobs.
    uint256 internal constant _maxSupply = 25000;
    /// @notice Total supply when the giveaway ends.
    uint256 internal constant _giveawayEnds = 10000;
    /// @notice Total supply when the sacrifice promo and hourly drops offers ends.
    uint256 internal constant _sacrificeAndHourlyDropsOffersEnds = 20000;
    /// @notice Total supply when the referral program ends.
    uint256 internal constant _referralProgramEnds = 25000;
    /// @notice Maximum number of CryptoBlobs an account can purchase per transaction.
    uint256 internal constant _purchaseLimit = 100;
    /// @notice Maximum number of free CryptoBlobs an account can earn and claim.
    uint256 internal constant _maxFreePerAccount = 10;
    /// @notice Maximum number of NFTs per collection that can be redeemed.
    uint256 internal constant _nftsPerCollectionLimit = 10;
    /// @notice Base price increment per point used on the live market.
    uint256 internal constant _basePriceIncrementPerPoint = 0.0000025 ether;
    /// @notice Price and multiplier decline duration (1% per hour).
    uint256 internal constant _declineDuration = 100 hours;
    /// @notice Each BOGO lasts for 7.5 minutes. Takes 30 minutes for "buy 1, get 1 free".
    uint256 internal constant _bogoDuration = 450 seconds;
    /// @notice BOGO starts at "buy 5, get 1 free".
    uint256 internal constant _bogoStartingFrom = 5;
    /// @notice The number of sacrifices until an account can earn a free CryptoBlob.
    uint256 internal constant _burnsPerReward = 10;
    /// @notice The number of referral purchases until an account can earn a free CryptoBlob.
    uint256 internal constant _referralsPerReward = 5;
    /// @notice The number of purchases until an account starts earning hourly drops.
    uint256 internal constant _hourlyDropThreshold = 5;
    /// @notice Lowers gas when making calculations.
    uint256 internal constant _sections = 8;
    /// @notice Lowers gas when making calculations.
    uint256 internal constant _distance = 3125;
    /// @notice How long each drop takes to earn.
    uint256 internal constant _hourlyDropDuration = 1 hours;
    /// @notice The base amount the temporary demand multiplier fluctuates by.
    uint256 internal constant _volatilityBase = 10;
    /// @notice The amount volatility is multiplied by after the threshold is reached.
    uint256 internal constant _volatilityMultiplier = 3;
    /// @notice Threshold when volatility increases. Causes the price to increase or decrease faster.
    uint256 internal constant _increasedVolatilityThreshold = 20000;
    /// @notice Unlock status for reentrancy guard.
    uint32 internal constant _reentrancyUnlocked = 1;
    /// @notice Lock status for reentrancy guard.
    uint32 internal constant _reentrancyLocked = 2;

    // Public - The public has access to modify these values.

    /// @notice Reentrancy guard status.
    uint32 internal _reentrancyStatus;
    /// @notice The number of CryptoBlobs that have been purchased.
    uint32 internal _tokensMintedPurchase;
    /// @notice The number of CryptoBlobs that have been claimed for free.
    uint32 internal _tokensMintedFree;
    /// @notice The number of CryptoBlobs that have been burned/sacrificed.
    uint32 internal _tokensBurned;
    /// @notice The temporary multiplier on the price, determined by demand and market activity.
    uint32 internal _temporaryDemandMultiplier;
    /// @notice The timestamp the last purchase was made.
    uint32 internal _purchaseTimestamp;
    /// @notice Used NFT IDs in a collection for the giveaway.
    mapping(address => uint256[]) internal _nftsRedeemed;
    /// @notice Stores account data.
    mapping(address => Account) internal _account;
    /// @notice Stores token data.
    mapping(uint256 => Token) internal _token;

    // Owner - SuperCollectiv has access to modify these values using {manageContract}.
    // Additionally, we can modify _contractOwner and _contractCandidate in [Ownable].

    /// @notice The name of the token. We may shorten the name after the initial mint.
    string internal _name = "CryptoBlobs.com | SuperCollectiv";
    /// @notice If the integrated trading platform is paused.
    bool internal _tradingPaused;
    /// @notice If sacrificing is paused.
    bool internal _sacrificingPaused;
    /// @notice The maximum number of souls the token URI will support.
    uint256 internal _URIMaxSoulsLimit = 100;
    /// @notice ENS reverse records address.
    address internal _reverseRecordsAddress = 0x3671aE578E63FdF66ad4F3E12CC0c0d71Ac7510C;
    /// @notice Contract URI for the contract.
    string internal _contractURI;
    /// @notice Token URI prefix for single URI schema.
    string internal _tokenURIPrefix;
    /// @notice Token URI prefixes for multi URI schema.
    mapping(uint256 => string) internal _tokenURIPrefixes;

    /**
        @param tokensOwned The number of CryptoBlobs owned.
        @param mintedPurchase The number of CryptoBlobs purchased.
        @param mintedBogos The number of CryptoBlobs claimed from BOGO deals.
        @param mintedGiveaway The number of CryptoBlobs claimed from the giveaway.
        @param tokensBurned The number of CryptoBlobs burned.
        @param mintedHourlyDrops The number of CryptoBlobs claimed from hourly drops.
        @param mintedSacrifices The number of CryptoBlobs claimed from the sacrifice promo.
        @param mintedReferrals The number of CryptoBlobs claimed from referring.
        @param mintedSpecial The number of CryptoBlobs gifted from SuperCollectiv. Max number is 255.
        @param tokensOptimized The number of CryptoBlobs optimized.
        @param referralPurchases The number of CryptoBlobs purchased with account's referral link.
        @param timestampHourlyDropLastClaimed Timestamp the account last claimed their hourly drop or initialized it.
        @param timestampReferralLinkUsed Timestamp the account used a referral link.
        @param timestampTradesLocked Timestamp the account locked their trades on the integrated trading platform.
        @param timestampTradeHashUsed Timestamp when trade hashes have been cancelled or completed by the account.
        @param approvals Addresses the account has approved to manage all CryptoBlobs owned by them.
    */
    struct Account {
        // Order is optimized.
        uint16 tokensOwned;
        uint16 mintedPurchase;
        uint8 mintedBogos;
        uint8 mintedGiveaway;
        uint16 tokensBurned;
        uint8 mintedHourlyDrops;
        uint8 mintedSacrifices;
        uint8 mintedReferrals;
        uint16 mintedSpecial;
        uint16 tokensOptimized;
        uint16 referralPurchases;
        uint32 timestampHourlyDropLastClaimed;
        uint32 timestampReferralLinkUsed;
        uint32 timestampTradesLocked;
        mapping(bytes32 => uint256) timestampTradeHashUsed;
        mapping(address => uint256) approvals;
        uint256 preapprovedStatus;
    }

    /**
        @param mintTimestamp Timestamp minted.
        @param burnTimestamp Timestamp burned.
        @param souls Before burn: The number of souls harnessed. After burn: The number of souls transferred to burnTo.
        @param burnTo CryptoBlob ID transferred souls to.
        @param account Before burn: Address of the owner. After burn: Address that last owned it.
        @param approval Address of the approved token operator.
    */
    struct Token {
        uint32 mintTimestamp;
        uint32 burnTimestamp;
        uint16 souls;
        uint16 burnTo;
        address account;
        address approval;
    }

    /**
        @notice Batch transaction data for {batch}.
    */
    struct BatchData {
        uint256 category;
        address account1;
        address account2;
        uint256 tokenId;
        uint256[] tokenIds;
        bool approved;
        bytes32 hash;
    }

    /**
        @notice The name of the token.
    */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
        @notice The symbol of the token.
    */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
        @notice If an interface ID is supported. 
        @dev Supported interfaces: IERC165 (0x01ffc9a7), IERC721 (0x80ac58cd), IERC721Metadata (0x5b5e139f), IERC721Enumerable (0x780e9d63).
        @param interfaceId Interface ID to check.
        @return If `interfaceId` is supported.
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId ||          // 0x01ffc9a7
            interfaceId == type(IERC721).interfaceId ||             // 0x80ac58cd
            interfaceId == type(IERC721Metadata).interfaceId ||     // 0x5b5e139f
            interfaceId == type(IERC721Enumerable).interfaceId;     // 0x780e9d63
    }

    /**
        @notice Returns a token ID owned by `owner` at a given index in its inventory.
        @param owner The address of the account.
        @param index Inventory index of `owner` to read. Uses index zero.
        @return The token ID of the CryptoBlob at the index.
    */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        unchecked {
            uint256 tokensMinted = _tokensMinted(); // Saves gas.
            uint256 indexOfOwner; // Iterates when inventory index does not match `index`.
            address accountOfToken;
            uint256 balance = balanceOf(owner);
            if (index < balance) {
                for (uint256 i; i < tokensMinted; i++) {
                    uint256 tokenId = _getTokenId(i);
                    if (_token[tokenId].account != address(0)) {
                        accountOfToken = _token[tokenId].account; // Store address.
                    }
                    // If the CryptoBlob last checked is in the owner's inventory.
                    if (accountOfToken == owner && !_isTokenSacrificed(tokenId)) {
                        if (indexOfOwner != index) {
                            indexOfOwner++; // Iterate if incorrect index.
                        } else {
                            return tokenId; // Return if the index matches.
                        }
                    }
                }
            }
            revert OWNERS_BALANCE_IS_INSUFFICENT_FOR_THE_INDEX();
        }
    }

    /**
        @notice The circulating supply of CryptoBlobs.
    */
    function totalSupply() public view virtual override returns (uint256) {
        unchecked {
            return _tokensMinted() - _tokensBurned; // Cannot underflow.
        }
    }

    /**
        @notice Returns a token ID at a given `index`.
        @param index Index of the circulating supply to read.
        @return The token ID of the CryptoBlob at the index.
    */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        unchecked {
            uint256 tokensMinted = _tokensMinted();
            uint256 tokenIdsIndex;
            if (index < tokensMinted) {
                // Check each minted CryptoBlob and return the ID when the index is reached.
                for (uint256 i; i < tokensMinted; i++) {
                    uint256 tokenId = _getTokenId(i);
                    if (!_isTokenSacrificed(tokenId)) {
                        if (tokenIdsIndex != index) {
                            tokenIdsIndex++; // Iterate if incorrect index.
                        } else {
                            return tokenId; // Return if the index matches.
                        }
                    }
                }
            }
            revert INVALID_CRYPTOBLOB_ID();
        }
    }

    /**
        @notice The balance of an account.
        @param owner The address of the account.
        @return The balance of `owner`.
    */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert THE_ZERO_ADDRESS_CANNOT_HAVE_AN_ACCOUNT();
        return _account[owner].tokensOwned;
    }

    /**
        @notice The owner of a CryptoBlob ID.
        @param tokenId The token ID of the CryptoBlob.
        @return The owner of `tokenId`.
    */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        unchecked {
            _revertIfTokenIsInvalid(tokenId);
            uint256 index = _getTokenIndex(tokenId);
            while (true) {
                if (_token[tokenId].account == address(0)) {
                    tokenId = _getTokenId(--index);
                } else {
                    return _token[tokenId].account;
                }
            }
            revert INVALID_CRYPTOBLOB_ID();
        }
    }

    /**
        @notice The token URI of a CryptoBlob ID.
        @dev Unminted CryptoBlobs revert with an error.
        @dev Sacrificed CryptoBlobs still have metadata.
        @param tokenId The token ID of the CryptoBlob.
        @return The token URI of `tokenId`.
    */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        unchecked {
            if (_getTokenIndex(tokenId) >= _tokensMinted()) revert INVALID_CRYPTOBLOB_ID();

            uint256 souls;
            if (!_isTokenSacrificed(tokenId)) souls = _token[tokenId].souls + 1; // Get souls harnessed and +1 for self.
            if (souls > _URIMaxSoulsLimit) souls = _URIMaxSoulsLimit; // Limit souls.

            if (bytes(_tokenURIPrefix).length > 0) {
                // Single URI with an extension.
                return string(abi.encodePacked(_tokenURIPrefix, _toPaddedString(souls), "/", _toPaddedString(tokenId)));
            } else if (bytes(_tokenURIPrefixes[souls]).length > 0) {
                // Multi URI with no extension.
                return string(abi.encodePacked(_tokenURIPrefixes[souls], _toPaddedString(tokenId)));
            } else {
                // If no token URI.
                return "";
            }
        }
    }

    /**
        @notice Returns the approved token operator for `tokenId`.
        @dev Get all approved token operators with {tokenDataByCategory} category 1.
        @param tokenId The token ID of the CryptoBlob.
        @return The address of the account that can manage `tokenId`.
    */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        _revertIfTokenIsInvalid(tokenId);
        return _token[tokenId].approval;
    }

    /**
        @notice Returns if `operator` is an approved account operator of `owner`.
        @dev Account operators can do everything the owner can do expect sign messages and manage their account operators.
        @dev Preapproved services: OpenSea, X2Y2, LooksRare, Rarible, 0x Protocol v4, Element, SudoSwap, NFTX, and NFTTrader.
        @dev You can revoke these services using {setApprovalForAll} or visit CryptoBlobs.com for a batch tx to revoke all at once.
        @dev SuperCollectiv will permanently disable preapproved services if any issues are discovered with these contracts.
        @dev Services that list your account operators will not detect that these addresses have
        @dev been approved unless you reapprove each service with {setApprovalForAll} or {batch}.
        @param owner The address of the account that owns the CryptoBlobs.
        @param operator The address of the account to the check the status of.
        @return If `operator` is an account operator of `owner`.
    */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {

        // Preapproved services:
        // OpenSea, X2Y2, LooksRare, Rarible, 0x Protocol v4, Element, SudoSwap, NFTX, and NFTTrader.
        // You can manage these services like usual with {setApprovalForAll} or {batch}.

        uint256 status = _account[owner].approvals[operator];
        return (
                    status == 2 || // If approved.
                    (
                        status == 0 && // If default value (never approved or revoked by the owner).
                        _account[operator].preapprovedStatus == 2 && // If preapproved service.
                        owner != operator // If not self.
                    )
                );
    }

    /**
        @notice The contract URI for the CryptoBlobs smart contract.
    */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
        @notice All-in-one method to get general data for the contract.
        @dev Enter the zero address to query {generalData} without checking an NFT.
        @param contractAddress Contract address of the NFT.
        @param tokenId Token ID of the NFT.
        @return data General contract data.
        @return owner Owner of the NFT.
        @return isERC721 If the token is an ERC721 NFT.
        @return nftsRedeemed NFT IDs redeemed in the collection.
        @return contractOwner Contract owner.
        @return contractCandidate Contract candidate.
        @return contractBalance Contract balance.
    */
    function generalData(address contractAddress, uint256 tokenId) 
        public 
        view 
        returns (
            uint256[12] memory data, 
            address owner, 
            bool isERC721, 
            uint256[] memory nftsRedeemed,
            address contractOwner,
            address contractCandidate,
            uint256 contractBalance
        ) 
    {
        unchecked {

            // Supply data.
            data[0] = _tokensMintedPurchase;
            data[1] = _tokensMintedFree;
            data[2] = _tokensBurned;

            // Temporarily hold tokensMinted.
            data[3] = _tokensMinted();

            // Time until next hourly drop.
            if (data[3] < _sacrificeAndHourlyDropsOffersEnds) data[4] = _hourlyDropDuration - (block.timestamp % _hourlyDropDuration);

            // Statuses.
            if (_tradingPaused) data[5] = 1;
            if (_sacrificingPaused) data[6] = 1;
            
            // Get price.
            if (data[3] != _maxSupply) (data[7], data[8], data[9], data[10], data[11]) = _marketPrice(data[0], data[1]);

            // Check NFT.
            if (contractAddress != address(0)) (owner, isERC721, nftsRedeemed) = _checkNFT(contractAddress, tokenId);

            // Block timestamp.
            data[3] = block.timestamp;

            return (data, owner, isERC721, nftsRedeemed, _contractOwner, _contractCandidate, address(this).balance);
        }
    }

    /**
        @notice Check an NFT.
        @param contractAddress Contract address of the NFT.
        @param tokenId Token ID of the NFT.
        @return owner Owner of the NFT.
        @return isERC721 If the token is an ERC721 NFT.
        @return nftsRedeemed NFT IDs redeemed in the collection.
    */
    function _checkNFT(address contractAddress, uint256 tokenId) internal view returns (address owner, bool isERC721, uint256[] memory nftsRedeemed) {
        if (_isContractPastConstruction(contractAddress)) {
            try IERC721(contractAddress).ownerOf(tokenId) returns (address _owner) { owner = _owner; } catch {}
            try IERC165(contractAddress).supportsInterface(type(IERC721).interfaceId) returns (bool _isERC721) { isERC721 = _isERC721; } catch {}
            //try IERC721Metadata(contractAddress).tokenURI(tokenId) returns (string memory _tokenURI) { if (bytes(_tokenURI).length == 0) isERC721 = false; } catch {}
            nftsRedeemed = _nftsRedeemed[contractAddress];
        }
        return (owner, isERC721, nftsRedeemed);
    }

    /**
        @notice Redeem an NFT.
        @param contractAddress Contract address of the NFT.
        @param tokenId Token ID of the NFT.
        @return redeemed If the NFT was redeemed (true if no revert).
    */
    function _redeemNFT(address contractAddress, uint256 tokenId) internal returns (bool redeemed) {
        unchecked {
            // Get NFT data.
            (address owner, bool isERC721, uint256[] memory nftsRedeemed) = _checkNFT(contractAddress, tokenId);

            // Revert if not owner, not ERC721, or limit reached.
            if (owner != msg.sender || !isERC721 || nftsRedeemed.length >= _nftsPerCollectionLimit) revert NFT_IS_NOT_ELIGIBLE();

            // Revert if the NFT has been redeemed.
            for (uint256 i; i < nftsRedeemed.length; i++) {
                if (nftsRedeemed[i] == tokenId) revert NFT_IS_NOT_ELIGIBLE();
            }

            // Add to redeemed array.
            _nftsRedeemed[contractAddress].push(tokenId);

            return true;
        }
    }

    /**
        @notice Account data for an account.
        @dev The zero address cannot have an account.
        @param account The address of the account.
        @param getENS Optionally get the ENS name of `account`.
        @param getTokens Optionally get the owned and burned tokens of `account`.
        @return data 0 owned, 1 burned, 2 optimized, 3 purchased, 4 special, 5 free, (minted: 6 bogos, 7 drops, 8 sacrifices, 9 referrals, 10 giveaway), (claimable: 11 total, 12 drops, 13 sacrifices, 14 referrals, 15 giveaway), 16 referral purchases, (timestamps: 17 hourly drop last claimed, 18 referral link used, 19 trades locked), 20 is contract, 21 wallet balance.
        @return ensName The ENS name of `account`.
        @return ownedData Data for CryptoBlobs owned by the account (ID, souls, mint timestamp, approval as uint).
        @return burnedData Data for CryptoBlobs burned by the account (ID, ID upgraded, souls transferred, mint timestamp, burn timestamp).
    */
    function accountData(address account, bool getENS, bool getTokens)
        public
        view
        returns (
            uint256[22] memory data,
            string memory ensName,
            uint256[] memory ownedData,
            uint256[] memory burnedData
        )
    {
        unchecked {
            // Token stats
            data[0] = balanceOf(account);
            data[1] = _account[account].tokensBurned;
            data[2] = _account[account].tokensOptimized;
            // Minted amounts
            // Total minted = mintedPurchase + mintedSpecial + mintedFree
            data[3] = _account[account].mintedPurchase;
            data[4] = _account[account].mintedSpecial;
            // data[5] mintedFree total below
            // mintedFree breakdown: 6-10
            data[6] = _account[account].mintedBogos;
            data[7] = _account[account].mintedHourlyDrops;
            data[8] = _account[account].mintedSacrifices;
            data[9] = _account[account].mintedReferrals;
            data[10] = _account[account].mintedGiveaway;
            // Claimables: 11-15
            (data[5], data[12], data[13], data[14], data[15]) = _accountToClaimable(account);
            data[11] = data[12] + data[13] + data[14] + data[15];
            // Miscellaneous
            data[16] = _account[account].referralPurchases;
            // Timestamps
            data[17] = _account[account].timestampHourlyDropLastClaimed;
            data[18] = _account[account].timestampReferralLinkUsed;
            data[19] = _account[account].timestampTradesLocked;
            // Bools
            if (_isContractPastConstruction(account)) data[20] = 1;
            // Ether balance
            data[21] = address(account).balance;

            // Optionally get ENS name.
            if (getENS) {
                address[] memory addresses = new address[](1);
                addresses[0] = account;
                ensName = addressesToENS(addresses)[0];
            }

            // Optionally get tokens.
            if (getTokens) {

                uint256[4] memory variables;
                // 0 = ownedIndex
                // 1 = burnedIndex
                // 2 = tokensChecked
                // 3 = mintTimestampOfToken

                // If currently owns CryptoBlobs or had sacrificed any.
                if (data[0] + data[1] > 0) {

                    // Create owned array.
                    uint256 ownedDataAmount = 4;
                    ownedData = new uint256[](data[0] * ownedDataAmount);
                    // Each owned ID returns:
                    // - token ID
                    // - souls owned
                    // - mint timestamp
                    // - approval (as uint, must convert to hex)

                    // Create burned array.
                    uint256 burnedDataAmount = 5;
                    burnedData = new uint256[](data[1] * burnedDataAmount);
                    // Each burned ID returns:
                    // - token ID
                    // - token ID upgraded
                    // - souls transferred to upgraded ID
                    // - mint timestamp
                    // - burn timestamp

                    // Get all data for the account until all is found.
                    address accountOfToken;
                    while (data[0] + data[1] != variables[0] + variables[1]) {
                        uint256 tokenId = _getTokenId(variables[2]++);
                        // Get owner or last owner.
                        if (_token[tokenId].account != address(0)) {
                            accountOfToken = _token[tokenId].account;
                        }
                        // Get minted timestamp.
                        if (_token[tokenId].mintTimestamp != 0) {
                            variables[3] = _token[tokenId].mintTimestamp;
                        }
                        if (accountOfToken == account) {
                            // If account matches query.
                            if (!_isTokenSacrificed(tokenId)) { // If owned.
                                ownedData[variables[0] * ownedDataAmount] = tokenId;
                                ownedData[(variables[0] * ownedDataAmount) + 1] = _token[tokenId].souls + 1;
                                ownedData[(variables[0] * ownedDataAmount) + 2] = variables[3];
                                ownedData[(variables[0] * ownedDataAmount) + 3] = uint160(_token[tokenId].approval);
                                variables[0]++;
                            } else { // If sacrificed.
                                burnedData[variables[1] * burnedDataAmount] = tokenId;
                                burnedData[(variables[1] * burnedDataAmount) + 1] = _token[tokenId].burnTo;
                                burnedData[(variables[1] * burnedDataAmount) + 2] = _token[tokenId].souls;
                                burnedData[(variables[1] * burnedDataAmount) + 3] = variables[3];
                                burnedData[(variables[1] * burnedDataAmount) + 4] = _token[tokenId].burnTimestamp;
                                variables[1]++;
                            }
                        }
                    }
                }
            }
            return (data, ensName, ownedData, burnedData);
        }
    }

    /**
        @notice Account data for multiple accounts by category.
        @dev See past event logs for more data. Use {addressesToENS} for ENS names.
        @dev The zero address cannot have an account and returns from it should be ignored. This is not checked to optimize calls.
        @param accounts The addresses of the accounts.
        @param category (0: owned, burned, optimized, purchased), (1: owned, burned, optimized), 2 total claimable, 3 trades locked, (4: wallet balance, is contract)
        @return data The uint data of all accounts, based on the category.
    */
    function accountDataByCategory(address[] memory accounts, uint256 category)
        external
        view
        returns (uint256[] memory data)
    {
        unchecked {

            // The following categories can be queried from logs.
            // tokensMinted
            // mintedFree
            // mintedHourlyDrops
            // mintedSacrifices
            // mintedReferrals
            // mintedGiveaway
            // mintedBogos
            // mintedSpecial
            // referralPurchases
            // timestampHourlyDropLastClaimed
            // timestampReferralLinkUsed

            // Use {accountData} for claimable specifics.
            // claimableHourlyDrops
            // claimableSacrifices
            // claimableReferrals
            // claimableGiveaway

            uint256 accountsAmount = accounts.length;
            if (category == 0) {
                // Owned, burned, optimized, purchased.
                // Data for the leaderboards.
                uint256 amount = 4;
                data = new uint256[](accountsAmount * amount);
                for (uint256 i; i < accountsAmount; i++) {
                    data[i * amount] = balanceOf(accounts[i]);
                    data[i * amount + 1] = _account[accounts[i]].tokensBurned;
                    data[i * amount + 2] = _account[accounts[i]].tokensOptimized;
                    data[i * amount + 3] = _account[accounts[i]].mintedPurchase;
                }
            } else if (category == 1) {
                // Owned, burned, optimized.
                // Alternative for category 0 because purchases can be retrieved from past logs.
                uint256 amount = 3;
                data = new uint256[](accountsAmount * amount);
                for (uint256 i; i < accountsAmount; i++) {
                    data[i * amount] = balanceOf(accounts[i]);
                    data[i * amount + 1] = _account[accounts[i]].tokensBurned;
                    data[i * amount + 2] = _account[accounts[i]].tokensOptimized;
                }
            } else if (category == 2) {
                // Total claimable.
                data = new uint256[](accountsAmount);
                for (uint256 i; i < accountsAmount; i++) {
                    (
                        ,
                        uint256 claimableHourlyDrops, 
                        uint256 claimableSacrifices, 
                        uint256 claimableReferrals, 
                        uint256 claimableGiveaway
                    ) = _accountToClaimable(accounts[i]);
                    data[i] = claimableHourlyDrops + claimableSacrifices + claimableReferrals + claimableGiveaway;
                }
            } else if (category == 3) {
                // Timestamp trades locked.
                data = new uint256[](accountsAmount);
                for (uint256 i; i < accountsAmount; i++) {
                    data[i] = _account[accounts[i]].timestampTradesLocked;
                }
            } else {
                // Wallet balance and is contract.
                uint256 amount = 2;
                data = new uint256[](accountsAmount * amount);
                for (uint256 i; i < accountsAmount; i++) {
                    data[i * amount] = address(accounts[i]).balance;
                    if (_isContractPastConstruction(accounts[i])) data[i * amount + 1] = 1;
                }
            }
            return data;
        }
    }

    /**
        @notice Reverse records for the primary ENS name of accounts.
        @dev _reverseRecordsAddress Can be updated to support additional features.
        @param accounts The addresses of the accounts.
        @return ensNames ENS names of `accounts`.
    */
    function addressesToENS(address[] memory accounts) public view returns (string[] memory ensNames) {
        return IReverseRecords(_reverseRecordsAddress).getNames(accounts);
    }

    /**
        @notice Token data for a CryptoBlob ID.
        @param tokenId The token ID of the CryptoBlob.
        @param getENS Optionally get the ENS names of accounts.
        @return owner The owner of `tokenId`.
        @return approval The approved token operator of `tokenId`.
        @return burner The last owner of `tokenId` before it was burned.
        @return mintTimestamp The timestamp `tokenId` was minted.
        @return burnTimestamp The timestamp `tokenId` was burned.
        @return ownedSouls The number of souls `tokenId` possesses, rewarded by {sacrifice}.
        @return burnSouls The number of souls `tokenId` transferred after being burned.
        @return burnTo The CryptoBlob ID `tokenId` transferred its soul(s) to.
        @return distance Optimization distance/rank.
        @return ensNames The ENS name of the owner, approval, and burner.
    */
    function tokenData(uint256 tokenId, bool getENS)
        external
        view
        returns (
            address owner,
            address approval,
            address burner,
            uint256 mintTimestamp,
            uint256 burnTimestamp,
            uint256 ownedSouls,
            uint256 burnSouls,
            uint256 burnTo,
            uint256 distance,
            string[] memory ensNames
        )
    {
        unchecked {
            if (!_isTokenSacrificed(tokenId)) {
                owner = ownerOf(tokenId); // Reverts if not yet minted.
                approval = _token[tokenId].approval;
                ownedSouls = _token[tokenId].souls + 1; // +1 for self.
            } else {
                burner = _token[tokenId].account;
                burnTimestamp = _token[tokenId].burnTimestamp;
                burnTo = _token[tokenId].burnTo;
                burnSouls = _token[tokenId].souls;
            }
            uint256 index = _getTokenIndex(tokenId);
            while (mintTimestamp == 0) {
                if (_token[tokenId].mintTimestamp == 0) {
                    if (_token[tokenId].account == address(0)) {
                        distance++;
                    }
                    tokenId = _getTokenId(--index);
                } else {
                    mintTimestamp = _token[tokenId].mintTimestamp;
                }
            }
            if (getENS) {
                address[] memory addresses = new address[](3); // Create array.
                addresses[0] = owner;
                addresses[1] = approval;
                addresses[2] = burner;
                ensNames = addressesToENS(addresses); // Get ENS names.
            }
            return (
                owner,
                approval,
                burner,
                mintTimestamp,
                burnTimestamp,
                ownedSouls,
                burnSouls,
                burnTo,
                distance,
                ensNames
            );
        }
    }


    /**
        @notice Information about all tokens. Uses index 0.
        @dev Most providers will successfully call this function.
        @dev Data can be split by specifying an index and an amount, which uses token indices.
        @param category 0 owners, 1 approvals, 2 burners, 3 mintTimestamps, 4 burnTimestamps, 5 ownedSouls, 6 burnSouls, 7 burnTos, 8 distance.
        @param index Index to start from when splitting data. Default is 0.
        @param amount Amount to query when splitting data. Default is 0.
        @return data The number data of all tokens, based on the category. Addresses are uints, which will need to be conversed to hex and checksummed.
    */
    function tokenDataByCategory(uint256 category, uint256 index, uint256 amount)
        external
        view
        returns (uint256[] memory data)
    {
        unchecked {
            uint256 tokensMinted = _tokensMinted();
            uint256 toIndex;
            uint256 fromIndex;
            if (amount == 0) { // Getting all data.
                amount = _maxSupply;
                toIndex = tokensMinted;
            } else { // Getting range.
                // Precheck for accurate data. 
                if (category == 0 || category == 3 || category == 8) {
                    // toIndex temporarily holds precheck amount.
                    uint maxPrecheck = _purchaseLimit + _maxFreePerAccount;
                    if (index > maxPrecheck) {
                        toIndex = maxPrecheck;
                    } else if (index != 0) {
                        toIndex = index % (maxPrecheck);
                    }
                }
                fromIndex = index - toIndex; // Cannot underflow because index > toIndex (precheck).
                toIndex += fromIndex + amount; // toIndex is calculated here.
                // Limit amount.
                if (toIndex > tokensMinted) {
                    toIndex = tokensMinted;
                    amount = toIndex - index; // Cannot underflow because toIndex always > index.
                }
            }
            data = new uint256[](amount); // Create uint array.
            uint256 holdNumber;
            if (category != 8) {
                while (fromIndex < toIndex) {
                    // Check all minted CryptoBlobs.
                    uint256 tokenId = _getTokenId(fromIndex); // Get token ID.
                    bool sacrificed = _isTokenSacrificed(tokenId);
                    uint256 dataRetrieved;
                    if (category == 0) {
                        // Update account of token.
                        if (_token[tokenId].account != address(0)) {
                            holdNumber = uint160(_token[tokenId].account);
                        }
                        // Add address if not sacrificed.
                        if (!sacrificed) {
                            dataRetrieved = holdNumber;
                        }
                    } else if (category == 1) {
                        // Add approval.
                        dataRetrieved = uint160(_token[tokenId].approval);
                    } else if (category == 2) {
                        // Update account of token.
                        if (_token[tokenId].account != address(0)) {
                            holdNumber = uint160(_token[tokenId].account);
                        }
                        // Add address if sacrificed.
                        if (sacrificed) {
                            dataRetrieved = holdNumber;
                        }
                    } else if (category == 3) {
                        // Update latest mint timestamp.
                        if (_token[tokenId].mintTimestamp != 0) {
                            holdNumber = _token[tokenId].mintTimestamp;
                        }
                        // Add mint timestamp.
                        dataRetrieved = holdNumber;
                    } else if (category == 4) {
                        // Add burn timestamp.
                        dataRetrieved = _token[tokenId].burnTimestamp;
                    } else if (category == 5 && !sacrificed) {
                        // Add souls if not sacrificed.
                        dataRetrieved = _token[tokenId].souls + 1;
                    } else if (category == 6 && sacrificed) {
                        // Add souls transferred if sacrificed.
                        dataRetrieved = _token[tokenId].souls;
                    } else if (category == 7 && sacrificed) {
                        // Add token ID upgraded.
                        dataRetrieved = _token[tokenId].burnTo;
                    }
                    // Add data to array.
                    if (amount == _maxSupply) {
                        if (dataRetrieved != 0) {
                            data[tokenId - 1] = dataRetrieved;
                        }
                    } else if (fromIndex >= index) {
                        if (dataRetrieved != 0) {
                            data[fromIndex - index] = dataRetrieved;
                        }
                    }
                    fromIndex++;
                }
            } else if (category == 8) {
                uint256 tokensChecked;
                while (fromIndex < toIndex) {
                    if (_token[_getTokenId(toIndex - tokensChecked - 1)].account == address(0)) {
                        holdNumber++;
                    } else if (holdNumber > 0) {
                        for (uint256 j; j < holdNumber + 1; j++) {
                            if (amount == _maxSupply) {
                                data[_getTokenId(toIndex - tokensChecked - 1 + j) - 1] = j;
                            } else if (toIndex - tokensChecked - 1 + j >= index) {
                                data[toIndex - tokensChecked - 1 + j - index] = j;
                            }
                        }
                        delete holdNumber;
                    }
                    tokensChecked++;
                    fromIndex++;
                }
            }
            return data;
        }
    }

    /**
        @notice Check if a trade is approved and valid. Returns the hash and error data.
        @param maker The address of the maker.
        @param taker The address of the taker.
        @param makerIds The CryptoBlob IDs owned by `maker` to trade with `taker`.
        @param takerIds The CryptoBlob IDs owned by `taker` to trade with `maker`.
        @param price The price in WEI the `taker` must pay to `maker` to complete the trade.
        @param expiry The UNIX time the trade automatically expires or 0 to never expire.
        @param salt A nonce to allow the same trade parameters to be used again.
        @param signature The signature of the signed hash.
        @param checkAccess Whether to verify each CryptoBlob ID.
        @return hash The hash of the trade.
        @return errors The errors of the trade. Valid trades return all zeros.
    */
    function isTradeApprovedAndValid(
        address maker,
        address taker,
        uint256[] memory makerIds,
        uint256[] memory takerIds,
        uint256 price,
        uint256 expiry,
        uint256 salt,
        bytes memory signature,
        bool checkAccess
    )
        public
        view
        returns (
            bytes32 hash,
            uint256[8] memory errors
        )
    {
        unchecked {
            // Trade data is hashed into 32 bytes and the hash gets signed.
            hash = keccak256(
                abi.encode(
                    address(this),
                    maker,
                    taker,
                    keccak256(abi.encode(makerIds)),
                    keccak256(abi.encode(takerIds)),
                    price,
                    expiry,
                    salt
                )
            );

            // Error if the maker's address does not match the recovered signer's address.
            if (!_isTradeApproved(maker, hash, signature)) errors[0] = 1;

            // Error if the maker is the zero address.
            if (maker == address(0)) errors[1] = 1;

            // Error if the maker has their trades locked (returns timestamp locked).
            errors[2] = _account[maker].timestampTradesLocked;

            // Error if the hash has been used (returns timestamp used).
            errors[3] = _account[maker].timestampTradeHashUsed[hash];

            // Error if the trade has expired. An expiry of 0 means it never expires.
            if (expiry <= block.timestamp && expiry != 0) errors[4] = 1;

            // Error if taker IDs are listed when the trade is public.
            if (taker == address(0) && takerIds.length > 0) errors[5] = 1;

            // Error if an account does not have access to the IDs.
            // `checkAccess` is false during a trade because IDs are verified in {trade} after each transfer.
            if (checkAccess) {
                for (uint256 i; i < makerIds.length; i++) {
                    (bool hasAccess,) = _hasAccess(maker, makerIds[i]);
                    if (!hasAccess) errors[6]++; // Returns amount without access.
                }
                for (uint256 i; i < takerIds.length; i++) {
                    (bool hasAccess,) = _hasAccess(taker, takerIds[i]);
                    if (!hasAccess) errors[7]++; // Returns amount without access.
                }
            }

            return (hash, errors);
        }
    }

    /**
        @notice Check if trade hashes have been used and if an account can access token IDs.
        @dev Token ID is checked if number is <= 25000, else the hash is checked.
        @dev Hashes must be converted to uint.
        @param accounts The addresses of the accounts.
        @param numbers The hashes (as uint) or token IDs to check.
        @return data Data returned.
    */
    function batchTradeHashUsedAndHasAccess(
        address[] memory accounts,
        uint256[] memory numbers
    ) 
        external
        view
        returns (
            uint256[] memory data
        )
    {
        uint256 maxSupply = _maxSupply; // Get max supply.
        uint256 accountsAmount = accounts.length; // Get return length.
        data = new uint256[](accountsAmount); // Create array.
        for (uint256 i; i < accountsAmount; i++) {
            if (numbers[i] > maxSupply) { // If checking hash.
                data[i] = _account[accounts[i]].timestampTradeHashUsed[bytes32(numbers[i])]; // Convert to bytes32 and check if used.
            } else {
                bool hasAccess;
                (hasAccess,) = _hasAccess(accounts[i], numbers[i]);
                if (hasAccess) data[i] = 1; // Return 1 if account has access.
            }
        }
        return data;
    }

    /**
        @notice Returns the status for a preapproved service.
        @dev SuperCollectiv can only manage services preapproved in the constructor.
        @dev 0x1E0049783F008A0085193E00003D00cd54003c71 (OpenSea).
        @dev 0xF849de01B080aDC3A814FaBE1E2087475cF2E354 (X2Y2).
        @dev 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e (LooksRare).
        @dev 0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be (Rarible).
        @dev 0xDef1C0ded9bec7F1a1670819833240f027b25EfF (0x Protocol, Coinbase NFT, and more).
        @dev 0x20F780A973856B93f63670377900C1d2a50a77c4 (Element).
        @dev 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329 (SudoSwap).
        @dev 0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d (NFTX).
        @dev 0x657E383EdB9A7407E468acBCc9Fe4C9730c7C275 (NFTTrader).
        @param account The address of the account.
        @return status 0 = service is permanently disabled, 1 = service is temporarily disabled, 2 = service is enabled.
    */
    function preapprovedServiceStatus(address account) external view returns (uint256 status) {
        return _account[account].preapprovedStatus;
    }

    /**
        @notice The amount of CryptoBlobs an account can claim for free from offers. Contracts aren't eligible.
        @param account The address of the account.
        @return mintedFree The amount minted for free.
        @return claimableHourlyDrops The amount claimable from the hourly drops.
        @return claimableSacrifices The amount claimable from the sacrifice promo.
        @return claimableReferrals The amount claimable from the referral program.
        @return claimableGiveaway The amount claimable from the giveaway.
    */
    function _accountToClaimable(address account) internal view returns (
            uint256 mintedFree,
            uint256 claimableHourlyDrops,
            uint256 claimableSacrifices,
            uint256 claimableReferrals,
            uint256 claimableGiveaway
        )
    {
        unchecked {
            // Calculate how many the account has claimed for free.
            mintedFree = _accountToMintedFree(account);

            // Offers are limited to non-contracts and if the account has not reached its limit of 10 free CryptoBlobs.
            if (!_isContractPastConstruction(account) && mintedFree < _maxFreePerAccount) {

                // Priority: claimableReferrals, claimableHourlyDrops, claimableSacrifices, claimableGiveaway.
                // The priority system will 'overwrite' CryptoBlobs you've earned in the order above.

                uint256 mintedFreeFuture = mintedFree;
                uint256 tokensMinted = _tokensMinted();

                // Return if 25K+ have been minted.
                if (tokensMinted >= _referralProgramEnds) 
                    return (
                        mintedFree, 
                        claimableHourlyDrops, 
                        claimableSacrifices, 
                        claimableReferrals, 
                        claimableGiveaway
                    );
                
                // REFERRAL PROGRAM (claimableReferrals)
                // Granted when:
                // - under 25K mints
                // - 1 for every 5 purchased by referred accounts
                if ((_account[account].referralPurchases / _referralsPerReward) > _account[account].mintedReferrals) {
                    claimableReferrals = (_account[account].referralPurchases / _referralsPerReward) - _account[account].mintedReferrals;
                    mintedFreeFuture += claimableReferrals;
                    if (mintedFreeFuture >= _maxFreePerAccount) { // If limit reached or surpassed.
                        return (
                            mintedFree, 
                            claimableHourlyDrops, 
                            claimableSacrifices, 
                            claimableReferrals - (mintedFreeFuture - _maxFreePerAccount), // Remove any over limit.
                            claimableGiveaway
                        );
                    }
                }
                
                // Return if 20K+ have been minted.
                if (tokensMinted >= _sacrificeAndHourlyDropsOffersEnds)
                    return (
                        mintedFree, 
                        claimableHourlyDrops, 
                        claimableSacrifices, 
                        claimableReferrals, 
                        claimableGiveaway
                    ); 

                // HOURLY DROP (claimableHourlyDrops)
                // Granted when:
                // - under 20K mints
                // - has been initialized (when 5 or more purchased)
                // - not initialized or claimed hourly drop today
                if (
                    _account[account].timestampHourlyDropLastClaimed != 0 && // If initialized.
                    _account[account].timestampHourlyDropLastClaimed / _hourlyDropDuration != block.timestamp / _hourlyDropDuration // If not initialized or claimed today.
                ) {
                    claimableHourlyDrops = 1; // Grant 1.
                    mintedFreeFuture += claimableHourlyDrops;
                    if (mintedFreeFuture >= _maxFreePerAccount) { // If limit reached or surpassed.
                        return (
                            mintedFree, 
                            claimableHourlyDrops, // Only 1 granted so mintedFreeFuture cannot be > _maxFreePerAccount, only equal to.
                            claimableSacrifices, 
                            claimableReferrals, 
                            claimableGiveaway
                        );
                    }
                }

                // SACRIFICE PROMO (claimableSacrifices)
                // Granted when:
                // - under 20K mints
                // - 1 for every 10 burned
                if ((_account[account].tokensBurned / _burnsPerReward) > _account[account].mintedSacrifices) {
                    claimableSacrifices = (_account[account].tokensBurned / _burnsPerReward) - _account[account].mintedSacrifices;
                    mintedFreeFuture += claimableSacrifices;
                    if (mintedFreeFuture >= _maxFreePerAccount) { // If limit reached or surpassed.
                        return (
                            mintedFree, 
                            claimableHourlyDrops, 
                            claimableSacrifices - (mintedFreeFuture - _maxFreePerAccount), // Remove any over limit.
                            claimableReferrals, 
                            claimableGiveaway
                        );
                    }
                }

                // Return if 10K+ have been minted.
                if (tokensMinted >= _giveawayEnds)
                    return (
                        mintedFree, 
                        claimableHourlyDrops, 
                        claimableSacrifices, 
                        claimableReferrals, 
                        claimableGiveaway
                    ); 

                // GIVEAWAY (claimableGiveaway)
                // Granted when:
                // - under 10K mints
                // - not claimed from the giveaway
                // - NFT redeeming is valid
                if (_account[account].mintedGiveaway == 0) { // If not claimed from the giveaway.
                    claimableGiveaway = 1; // Grant 1.
                    mintedFreeFuture += claimableGiveaway;
                    if (mintedFreeFuture >= _maxFreePerAccount) { // If limit reached or surpassed.
                        return (
                            mintedFree, 
                            claimableHourlyDrops, 
                            claimableSacrifices, 
                            claimableReferrals, 
                            claimableGiveaway // Only 1 granted so mintedFreeFuture cannot be > _maxFreePerAccount, only equal to.
                        );
                    }
                }
            }
            return (mintedFree, claimableHourlyDrops, claimableSacrifices, claimableReferrals, claimableGiveaway);
        }
    }

    /**
        @notice Returns the amount an account minted for free.
        @dev Special mints from SuperCollectiv are not included.
        @param account The address of the account.
        @return mintedFree How many `account` minted for free.
    */
    function _accountToMintedFree(address account) internal view returns (uint256 mintedFree) {
        unchecked {
            mintedFree = (
                _account[account].mintedBogos + 
                _account[account].mintedHourlyDrops + 
                _account[account].mintedSacrifices + 
                _account[account].mintedReferrals + 
                _account[account].mintedGiveaway
                );
            return mintedFree;
        }
    }

    /**
        @notice Check if a trade is approved by the maker and is valid.
        @dev Extracts the public address from a hash and signature pair via ECDSA, then checks if it matches the maker's address.
        @param maker The address of the maker.
        @param hash The hash of the trade.
        @param signature The signature if the signed hash.
        @return approved If `maker` and signer's addresses match.
    */
    function _isTradeApproved(
        address maker,
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (bool approved) {
        unchecked {
            // Initialize
            if (maker == address(0)) return false; // Always false if zero address.
            if (signature.length != 65) return false; // Check length.

            bytes32 r;
            bytes32 s;
            uint8 v;

            // Use assembly to get the signature parameters for ecrecover.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }

            // If the signature is valid not malleable.
            if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return false;
            if (v != 27 && v != 28) return false;

            // Calculate the signer.
            // \x19Ethereum Signed Message:\n32 == 0x19457468657265756d205369676e6564204d6573736167653a0a3332
            address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s);
            if (signer == address(0)) return false;

            return (maker == signer); // Check if the addresses match.
        }
    }

    /**
        @notice Mints an amount of CryptoBlobs to an address.
        @dev The contract does not support safeMint to save gas.
        @param to The address of the account to mint the CryptoBlobs to.
        @param purchase The amount of CryptoBlobs to mint to `to` as the purchase mint type.
        @param free The amount of CryptoBlobs to mint to `to` as the free mint type.
        @param safeBlockTimestamp The current timestamp.
        @param tokensMinted The current total number of CryptoBlobs minted.
    */
    function _mint(
        address to,
        uint256 purchase,
        uint256 free,
        uint32 safeBlockTimestamp,
        uint256 tokensMinted
    ) internal {
        unchecked {

            // Initialize mint.
            if (to == address(0)) revert THE_ZERO_ADDRESS_CANNOT_HAVE_AN_ACCOUNT();
            uint256 amount = purchase + free; // Calculate amount minting.
            if (
                amount == 0 || // If minting zero.
                tokensMinted + amount > _maxSupply || // If minting over max supply.
                amount > _purchaseLimit + _maxFreePerAccount // If minting over 110 CryptoBlobs (should never occur).
            ) revert AMOUNT_MINTING_IS_INVALID();

            // Increase the circulating supply.
            if (purchase > 0) _tokensMintedPurchase += uint32(purchase);
            if (free > 0) {
                _tokensMintedFree += uint32(free);
                if (_accountToMintedFree(to) > _maxFreePerAccount) revert AMOUNT_MINTING_IS_INVALID(); // If account has over 10 free mints (should never occur).
            }

            // Update the recipient's balance.
            _account[to].tokensOwned += uint16(amount);

            // Save token data.
            uint256 tokenId = _getTokenId(tokensMinted);
            _token[tokenId].account = to;
            _token[tokenId].mintTimestamp = safeBlockTimestamp;

            // Total mints after this transaction (reuse variable to save gas).
            purchase = tokensMinted + amount;

            // Transfer event for each token.
            while (tokensMinted != purchase) {
                emit Transfer(      // 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                    address(0),     // address indexed from
                    to,             // address indexed to
                    ((tokensMinted / _sections) % 2 == 0)   // uint256 indexed tokenId
                    ? ((_distance * (tokensMinted % _sections)) + ((_distance * tokensMinted) / _maxSupply) + 1)
                    : (_maxSupply - ((_distance * (tokensMinted % _sections)) + ((_distance * tokensMinted) / _maxSupply)))
                );
                tokensMinted++;
            }
        }
    }

    /**
        @notice Calculates the price and additional market info.
        @dev Price starts at 0 ETH and is determined by supply, demand, and recent market activity.
        @dev Price will be higher if purchased compared to being claimed for free.
        @dev tokensMintedPurchase and tokensMintedFree are sent as parameters to lower gas.
        @param tokensMintedPurchase Number of purchased mints.
        @param tokensMintedFree Number of free mints.
        @return price The current price to purchase a CryptoBlobs in WEI.
        @return base The current base price in WEI.
        @return multiplier The multiplier on the price, which increases/decreases with demand.
        @return decline The percentage the price has declined since the last purchase.
        @return bogo The current BOGO deal determined by demand and market activity.
    */
    function _marketPrice(uint256 tokensMintedPurchase, uint256 tokensMintedFree)
        internal
        view
        returns (
            uint256 price,
            uint256 base,
            uint256 multiplier,
            uint256 decline,
            uint256 bogo
        )
    {
        unchecked {

            // Calculate the base price.
            // +2 points per CryptoBlob purchased.
            // +1 points per CryptoBlob claimed for free.
            // +1 points per CryptoBlob burned.
            // +2 points per CryptoBlob minted after 20,000 mints.
            base = ((tokensMintedPurchase * 2) + tokensMintedFree + _tokensBurned) * _basePriceIncrementPerPoint;
            if (tokensMintedPurchase + tokensMintedFree > _increasedVolatilityThreshold) {
                base += ((tokensMintedPurchase + tokensMintedFree) - _increasedVolatilityThreshold) * _basePriceIncrementPerPoint * _volatilityMultiplier;
            }

            // Calculate the multiplier.
            // The multiplier is determined by demand.
            // Paid mints increases the multiplier by 0.01% and 0.03% after 20,000 for increased volatility.
            // Free mints decreases the multiplier by 0.01% and 0.03% after 20,000 for increased volatility for every 2.
            // Cannot underflow because timestamp cannot decrease and _declineDuration > elapsed is checked.
            uint256 elapsed = block.timestamp - _purchaseTimestamp;
            if (_declineDuration > elapsed) {
                multiplier = ((_declineDuration - elapsed) * _temporaryDemandMultiplier) / _declineDuration;
            }

            // Calculate the percentage declined.
            decline = (elapsed * 100000) / _declineDuration;
            if (decline > 100000) decline = 100000; // Limit decline to 100%.

            // Calculate the price. Cannot underflow because decline is limited to 100%.
            price = ((((base * (multiplier + 100000)) / 100000) * (100000 - decline)) / 100000);

            // Calculate the current BOGO deal.
            bogo = _bogoStartingFrom;
            if (elapsed >= _bogoDuration) {
                bogo = 1;
                if (_bogoStartingFrom > (elapsed / _bogoDuration)) {
                    bogo = _bogoStartingFrom - (elapsed / _bogoDuration);
                }
            }

            return (price, base, multiplier, decline, bogo);
        }
    }

    /**
        @notice Transfers a CryptoBlob from one account to another.
        @dev Ownership is not checked within this function to save gas, instead
        @dev `from` will always be the owner's address whenever this function is called.
        @dev {_transfer} is called by 2 functions: {transferFrom} and {trade}, each time the
        @dev owner's address is retrieved via {_revertIfNoAccess} > {_hasAccess} > {ownerOf}.
        @param from The address that owns `tokenId`.
        @param to The address of the account to transfer `tokenId` to.
        @param tokenId The token ID of the CryptoBlob to transfer.
    */
    function _transfer(address from, address to, uint256 tokenId) internal {
        unchecked {

            // Cannot transfer to the zero address.
            if (to == address(0)) revert THE_ZERO_ADDRESS_CANNOT_HAVE_AN_ACCOUNT();

            // Update owner's stats.
            // Cannot underflow because ownership is checked.
            _account[from].tokensOwned--;
            _account[to].tokensOwned++;

            // Implicitly clear approvals.
            delete _token[tokenId].approval;

            // ERC721 standards says to not emit an Approval event when transferring. https://eips.ethereum.org/EIPS/eip-721
            // "When a Transfer event emits, this also indicates that the approved address for that NFT (if any) is reset to none."

            // Transfer 'tokenId' to 'to'.
            _token[tokenId].account = to;

            emit Transfer(  // 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                from,       // address indexed from
                to,         // address indexed to
                tokenId     // uint256 indexed tokenId
            );

            // Finalize transfer.
            tokenId = _getTokenIndex(tokenId) + 1;
            if (tokenId < _tokensMinted()) {
                tokenId = _getTokenId(tokenId);
                if (_token[tokenId].account == address(0)) _token[tokenId].account = from;
            }
        }
    }

    /**
        @notice Checks if an address can manage a CryptoBlob and gets the owner's address.
        @dev Owner is returned so {ownerOf} does not have to be called again.
        @dev Use {batchTradeHashUsedAndHasAccess} to access this function.
        @param account The address of the account to check the access status of.
        @param tokenId The token ID of the CryptoBlob.
        @return hasAccess If the address can manage the token.
        @return owner The address of the account that owns `tokenId`.
    */
    function _hasAccess(address account, uint256 tokenId) internal view returns (bool hasAccess, address owner) {
        owner = ownerOf(tokenId); // Get the owner. Reverts if the token does not exist.
        return (
                (
                    account == owner ||                     // If owner.
                    isApprovedForAll(owner, account) ||     // If account operator via {setApprovalForAll}.
                    getApproved(tokenId) == account         // If token operator via {approve}.
                ), 
                owner
            );
    }

    /**
        @notice Reverts if an account does not have access to manage a CryptoBlob ID.
        @param account The address of the account to check the access status of.
        @param tokenId The token ID of the CryptoBlob.
        @return owner The address of the account that owns `tokenId`.
    */
    function _revertIfNoAccess(address account, uint256 tokenId) internal view returns (address owner) {
        (bool hasAccess, address _owner) = _hasAccess(account, tokenId);
        if (!hasAccess) revert RESTRICTED_ACCESS();
        return _owner;
    }

    /**
        @notice Returns the total number of CryptoBlobs minted.
        @return minted The amount of CryptoBlobs minted.
    */
    function _tokensMinted() internal view returns (uint256 minted) {
        unchecked {
            return _tokensMintedPurchase + _tokensMintedFree; // Cannot overflow.
        }
    }

    /**
        @notice Returns TRUE if a CryptoBlob has been sacrificed.
        @param tokenId The token ID of the CryptoBlob.
        @return burned If `tokenId` has been sacrificed or not.
    */
    function _isTokenSacrificed(uint256 tokenId) internal view returns (bool burned) {
        unchecked {
            return (_token[tokenId].burnTimestamp != 0);
        }
    }

    /**
        @notice Reverts if the token ID does not exist.
        @param tokenId The token ID of the CryptoBlob.
    */
    function _revertIfTokenIsInvalid(uint256 tokenId) internal view {
        unchecked {
            if (_getTokenIndex(tokenId) >= _tokensMinted()) revert INVALID_CRYPTOBLOB_ID();
            if (_isTokenSacrificed(tokenId)) revert CRYPTOBLOB_HAS_BEEN_SACRIFICED();
        }
    }

    /**
        @notice Safely get the UNIX time for a unit32 number.
        @dev The contract does not use uint256 timestamps to save gas.
        @dev The maximum date/time the contract supports is Feb 7, 2106 6:28:15 AM.
        @dev Refer to past logs for uint256 timestamps.
        @return _seconds The current timestamp, which stops counting at uint32's limit.
    */
    function _safeBlockTimestamp() internal view returns (uint32 _seconds) {
        unchecked {
            if (block.timestamp < type(uint32).max) {
                return uint32(block.timestamp);
            } else {
                return type(uint32).max;
            }
        }
    }

    /**
        @notice If an address is a contract past construction.
        @dev Returns FALSE if accessed in a constructor.
    */
    function _isContractPastConstruction(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    
    /**
        @notice Converts a uint256 number to a padded number string, up to 5-digit numbers.
    */
    function _toPaddedString(uint256 value) internal pure returns (string memory) {
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++; // Counts how many digits the number has.
            temp /= 10; // If value is 12345, then temp will be 1234, 123, 12, 1, 0.
        }
        bytes memory padding;
        for (uint256 i; i < 5 - digits; i++) {
            padding = abi.encodePacked(padding, "0"); // Create padding.
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            buffer[--digits] = bytes1(uint8(48 + value % 10)); // Convert.
            value /= 10; // Same thing as temp above.
        }
        return string(abi.encodePacked(string(padding), string(buffer))); // Merge padding and number.
    }

    /**
        @notice Interacts with another contract and/or transfers ETH.
        @param account Address to interact with.
        @param amount Amount of ETH to transfer.
        @param data Data to send to the contract.
    */
    function _interaction(address account, uint256 amount, bytes memory data) internal {
        if (amount > address(this).balance) revert INSUFFICIENT_CONTRACT_BALANCE(); // Check balance.
        (bool success, bytes memory returndata) = payable(account).call{value: amount}(data);
        // If not successful.
        if (!success) {
            // If no return data.
            if (returndata.length == 0) {
                // Revert with a generic error.
                if (amount > 0) {
                    revert UNABLE_TO_TRANSFER_ETHER();
                } else {
                    revert UNABLE_TO_INTERACT_WITH_CONTRACT();
                }
            } else {
                // Revert with the error from the contract.
                assembly {
                    revert(add(32, returndata), mload(returndata))
                }
            }
        }
    }

    /**
        @notice Transfers ETH to another address.
        @param account Address to transfer ETH to.
        @param amount Amount of ETH to transfer.
    */
    function _transferEther(address account, uint256 amount) internal {
        _interaction(account, amount, "");
    }

    /**
        @notice Convert index to token ID.
    */
    function _getTokenId(uint256 index) internal pure returns (uint256 tokenId) {
        unchecked {
            if (index >= _maxSupply) revert INVALID_CRYPTOBLOB_ID();
            if ((index / _sections) % 2 == 0) {
                return (_distance * (index % _sections)) + ((_distance * index) / _maxSupply) + 1;
            } else {
                return _maxSupply - ((_distance * (index % _sections)) + ((_distance * index) / _maxSupply));
            }
        }
    }

    /**
        @notice Convert token ID to index.
    */
    function _getTokenIndex(uint256 tokenId) internal pure returns (uint256 index) {
        unchecked {
            if (tokenId > _maxSupply || tokenId < 1) revert INVALID_CRYPTOBLOB_ID();
            uint256 base = tokenId % _distance;
            if (base == 0) base = _distance;
            if (base % 2 != 0) { tokenId--; } else { tokenId = _maxSupply - tokenId; }
            return (((tokenId % _distance) * _sections) + (tokenId / _distance));
        }
    }
}


/**
    @title CryptoBlobs
    @author SuperCollectiv
    @dev Only contains write methods. See [SuperERC721] for read methods.
*/
contract CryptoBlobs is SuperERC721 {

    /**
        @notice Mint CryptoBlobs by claiming them for free or purchasing them on the Live Market.
        @dev Purchasing CryptoBlobs has an estimated gas fee of 66,200 + 2,050 GWEI/mint.
        @param key Each account has a unique key to claim free CryptoBlobs. Enter 0 if making a purchase.
        @param account When purchasing = referrer's address or zero address if none. When claiming = contract address of NFT or zero address if none.
        @param number When purchasing = amount to purchase (limit 100/tx). When claiming = token ID of the NFT or 0 if none.
    */
    function mint(uint256 key, address account, uint256 number) external payable nonReentrant {
        unchecked {

            // Initialize.
            uint256 tokensMintedPurchase = _tokensMintedPurchase; // Get amount purchased.
            uint256 tokensMintedFree = _tokensMintedFree; // Get amount claimed for free.
            uint32 safeBlockTimestamp = _safeBlockTimestamp(); // Get timestmap.

            if (key == 0) {

                // account = referrer
                // number = amountPurchasing

                // Get price and total.
                (
                    uint256 tokenPrice,,
                    uint256 multiplier,,
                    uint256 bogo
                ) = _marketPrice(tokensMintedPurchase, tokensMintedFree);

                // Calculate total price.
                uint256 salePrice = tokenPrice * number;

                // If the value sent is insufficient, the contract will attempt to 
                // prevent a revert by minting the maximum amount with the value sent.
                // Purchase one at a time if you do not want this feature.
                if (msg.value < salePrice) { // If the amount sent is insufficient.

                    if (msg.value >= tokenPrice) { // If at least one can be purchased with the amount sent.
                        // New amount cannot be higher than the old amount because msg.value < salePrice.
                        number = msg.value / tokenPrice; // Calculate max amount that can be minted.
                        salePrice = tokenPrice * number; // Calculate new total price.
                    }

                    // Revert if the value sent is still insufficient.
                    if (msg.value < salePrice) revert INSUFFICIENT_FUNDS_SENT_PRICE_MAY_HAVE_INCREASED(salePrice, msg.value);
                }

                // Revert if minting too many (>100).
                if (number > _purchaseLimit) revert PURCHASE_LIMIT_IS_100_PER_TRANSACTION();

                // Issue refund. Refund is always issued.
                // Cannot underflow because transaction reverts if msg.value < salePrice.
                _transferEther(msg.sender, (msg.value - salePrice));

                // Add to total account purchased. If price is 0 ETH, it will still count as a purchase.
                _account[msg.sender].mintedPurchase += uint16(number);

                // Initialize hourly drops if 5 are purchased. Drops at 00:00AM UTC each day. See {generalData} for countdown.
                if (
                    _account[msg.sender].mintedPurchase >= _hourlyDropThreshold && // If amount purchased surpasses threshold.
                    _account[msg.sender].timestampHourlyDropLastClaimed == 0 // If hourly drop not initialized.
                ) {
                    _account[msg.sender].timestampHourlyDropLastClaimed = safeBlockTimestamp; // Initialize.
                }

                // BOGO deal
                uint256 bogoReward;
                if (number >= bogo) { // If purchased enough for BOGO deal reward.
                    if (msg.sender == tx.origin) { // If not contract.
                        uint256 mintedFree = _accountToMintedFree(msg.sender);
                        if (mintedFree < _maxFreePerAccount) { // If account can claim more.
                            bogoReward = number / bogo; // Calculate amount earned.
                            if (mintedFree + bogoReward > _maxFreePerAccount) { // Correct amount if claiming too many.
                                // Grant remaining amount. Overflow check above (mintedFree < _maxFreePerAccount).
                                bogoReward = _maxFreePerAccount - mintedFree;
                            }
                            _account[msg.sender].mintedBogos += uint8(bogoReward); // Add to mintedBogos total.
                        }
                    }
                    // Update demand multiplier.
                    // Paid mints increases the multiplier by 0.01% and 0.03% after 20,000 for increased volatility.
                    // Free mints decreases the multiplier by 0.01% and 0.03% after 20,000 for increased volatility for every 2.
                    if (tokensMintedPurchase + tokensMintedFree < _increasedVolatilityThreshold) {
                        _temporaryDemandMultiplier = uint32(multiplier + ((number - (bogoReward / 2)) * _volatilityBase)); // Increase.
                    } else {
                        _temporaryDemandMultiplier = uint32(multiplier + ((number - (bogoReward / 2)) * _volatilityBase * _volatilityMultiplier)); // Increase.
                    }
                } else {
                    // Update demand multiplier.
                    // Paid mints increases the multiplier by 0.01% and 0.03% after 20,000 for increased volatility.
                    // Free mints decreases the multiplier by 0.01% and 0.03% after 20,000 for increased volatility for every 2.
                    if (tokensMintedPurchase + tokensMintedFree < _increasedVolatilityThreshold) {
                        _temporaryDemandMultiplier = uint32(multiplier + (number * _volatilityBase)); // Increase.
                    } else {
                        _temporaryDemandMultiplier = uint32(multiplier + (number * _volatilityBase * _volatilityMultiplier)); // Increase.
                    }
                }

                // Referral program
                if (account != address(0)) { // If referred.
                    if (
                        _account[msg.sender].timestampReferralLinkUsed == 0 && // If not previously referred.
                        account != msg.sender && // If not self.
                        msg.sender == tx.origin // If not contract.
                    ) {
                        _account[msg.sender].timestampReferralLinkUsed = safeBlockTimestamp; // Timestamp referred.
                        _account[account].referralPurchases += uint16(number); // Add to referralPurchases total.
                    } else {
                        account = address(0); // Remove referral.
                    }
                }

                // Update timestamp of latest mint.
                _purchaseTimestamp = safeBlockTimestamp;

                // Mint token(s).
                _mint(
                    msg.sender,                                 // recipient
                    number,                                     // purchased mints
                    bogoReward,                                 // free mints
                    safeBlockTimestamp,                         // timestamp
                    tokensMintedPurchase + tokensMintedFree     // tokens minted
                );

                emit MintPurchase(  // 0xf26aaf0d6935ae39e0b17d4770395a2cf37139301bf4a1550daabaa363cb8df0
                    msg.sender,     // address indexed account
                    account,        // address indexed referrer
                    ((              // uint256 data
                        ((
                            ((
                                tokenPrice          // +XXXXXXXXXXXXXXX price
                            * 10**3) + number)      // X---XXXXXXXXXXXX amount purchased
                        * 10**2) + bogoReward)      // XXXX--XXXXXXXXXX amount earned
                    * 10**10) + block.timestamp)    // XXXXXX---------- timestamp
                );

            } else {
                
                // account = contractAddress
                // number = tokenId

                // Initialize claim
                if (tx.origin != msg.sender || address(uint160(type(uint160).max - key)) != msg.sender) revert RESTRICTED_ACCESS();

                // Get claimable amounts.
                (
                    ,
                    uint256 claimableHourlyDrops, 
                    uint256 claimableSacrifices, 
                    uint256 claimableReferrals, 
                    uint256 claimableGiveaway
                ) = _accountToClaimable(msg.sender);

                // Claim hourly drops.
                if (claimableHourlyDrops > 0) {
                    _account[msg.sender].mintedHourlyDrops += uint8(claimableHourlyDrops);
                    _account[msg.sender].timestampHourlyDropLastClaimed = safeBlockTimestamp; // Timestamp claimed.
                }

                // Claim sacrifices.
                if (claimableSacrifices > 0) {
                    _account[msg.sender].mintedSacrifices += uint8(claimableSacrifices);
                }

                // Claim referrals.
                if (claimableReferrals > 0) {
                    _account[msg.sender].mintedReferrals += uint8(claimableReferrals);
                }

                // Claim giveaway.
                if (claimableGiveaway > 0) {
                    if (account != address(0) && _redeemNFT(account, number)) {
                        _account[msg.sender].mintedGiveaway += uint8(claimableGiveaway);
                    } else {
                        delete claimableGiveaway;
                        delete account;
                        delete number;
                    }
                } else {
                    delete account;
                    delete number;
                }

                // Revert if nothing to claim.
                uint256 claimableTotal = claimableHourlyDrops + claimableSacrifices + claimableReferrals + claimableGiveaway;
                if (claimableTotal == 0) revert ACCOUNT_HAS_NOTHING_TO_CLAIM();

                // Update demand multiplier.
                // Paid mints increases the multiplier by 0.01% and 0.03% after 20,000 for increased volatility.
                // Free mints decreases the multiplier by 0.01% and 0.03% after 20,000 for increased volatility for every 2.
                if (claimableTotal >= 2) { // If claiming two or more.
                    uint256 multiplierIncrement;
                    if (tokensMintedPurchase + tokensMintedFree < _increasedVolatilityThreshold) {
                        multiplierIncrement = (claimableTotal / 2) * _volatilityBase; // Increase.
                    } else {
                        multiplierIncrement = (claimableTotal / 2) * _volatilityBase * _volatilityMultiplier; // Increase.
                    }
                    if (_temporaryDemandMultiplier > multiplierIncrement) {
                        _temporaryDemandMultiplier -= uint32(multiplierIncrement); // Decrease.
                    } else {
                        delete _temporaryDemandMultiplier; // Cannot be negative.
                    }
                }

                // Mint token(s).
                _mint(
                    msg.sender,                                 // recipient
                    0,                                          // purchased mints
                    claimableTotal,                             // free mints
                    safeBlockTimestamp,                         // timestamp
                    tokensMintedPurchase + tokensMintedFree     // tokens minted
                );

                emit MintFree(      // 0x7236fe0badcff1706816875cc9df7b9b481c3fb939efe1e7967099499db621d9
                    msg.sender,     // address indexed account
                    account,        // address indexed contractAddress
                    number,         // uint256 tokenId
                    ((              // uint256 data
                        ((
                            ((
                                claimableHourlyDrops            // -XXXXXXXXXXXXXX hourly drops claimed (max 1 per tx)
                            * 10**2) + claimableSacrifices)     // X--XXXXXXXXXXXX sacrifices claimed (max 10 per tx)
                        * 10**2) + claimableReferrals)          // XXX--XXXXXXXXXX referrals claimed (max 10 per tx)
                    * 10**10) + block.timestamp)                // XXXXX---------- timestamp
                );
            }
        }
    }

    /**
        @notice Approves `to` to be a token operator of `tokenId`.
        @dev You must be the owner of `tokenId` or an account operator of the owner.
        @dev Only a single account can be approved at a time.
        @dev Approve the zero address to clear the current approval.
        @dev The approval is cleared when the token is transferred.
        @param to The address of the account to approve.
        @param tokenId The token ID of the CryptoBlob to manage.
    */
    function approve(address to, uint256 tokenId) public virtual override {
        // Get the owner of `tokenId`.
        address owner = ownerOf(tokenId);

        // Cannot approve the current owner.
        if (to == owner) revert CANNOT_APPROVE_THIS_ADDRESS();

        // Revert if not the owner and not approved for all.
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert RESTRICTED_ACCESS();

        // Approve `to` to manage `tokenId`.
        _token[tokenId].approval = to;

        emit Approval(  // 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
            owner,      // address indexed owner
            to,         // address indexed approved
            tokenId     // uint256 indexed tokenId
        );
    }

    /**
        @notice Approves `to` to be an account operator of your account.
        @dev Account operators can do everything the owner can do expect sign messages and manage their account operators.
        @dev Preapproved services: OpenSea, X2Y2, LooksRare, Rarible, 0x Protocol v4, Element, SudoSwap, NFTX, and NFTTrader.
        @dev You can revoke these services using {setApprovalForAll} or visit CryptoBlobs.com for a batch tx to revoke all at once.
        @dev SuperCollectiv will permanently disable preapproved services if any issues are discovered with these contracts.
        @dev Services that list your account operators will not detect that these addresses have
        @dev been approved unless you reapprove each service with {setApprovalForAll} or {batch}.
        @param operator The address of the account to update the operator status of.
        @param approved The approval status to set `operator` to.
    */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        unchecked {
            if (msg.sender == operator) revert CANNOT_APPROVE_THIS_ADDRESS();

            // Numbers are used to enable the preapproved services feature. Works similarly to an enum.
            // Values:
            // 0 = default
            // 1 = revoked
            // 2 = approved

            if (approved) {
                _account[msg.sender].approvals[operator] = 2; // Approve.
            } else {
                _account[msg.sender].approvals[operator] = 1; // Revoked.
            }

            emit ApprovalForAll(    // 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
                msg.sender,         // address indexed owner
                operator,           // address indexed operator
                approved            // bool approved
            );
        }
    }

    /**
        @notice Transfers `tokenId` from `from` to `to`.
        @param from The address of the account that owns `tokenId`.
        @param to The address of the account to transfer `tokenId` to.
        @param tokenId The token ID of the CryptoBlob to transfer.
    */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Reverts if the sender does not have access.
        // The owner's address is returned if the sender does have access.
        address owner = _revertIfNoAccess(msg.sender, tokenId);
        if (owner != from) revert FROM_ADDRESS_DOES_NOT_MATCH_THE_OWNERS_ADDRESS();
        // Transfer the CryptoBlob to the new owner.
        _transfer(owner, to, tokenId);
    }

    /**
        @notice Safely transfers `tokenId` from `from` to `to` by checking onERC721Received if `to` is a contract.
        @param from The address of the account that owns `tokenId`.
        @param to The address of the account to transfer `tokenId` to.
        @param tokenId The token ID of the CryptoBlob to transfer.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
        @notice Safely transfers `tokenId` from `from` to `to` by checking onERC721Received if `to` is a contract.
        @param from The address of the account that owns `tokenId`.
        @param to The address of the account to transfer `tokenId` to.
        @param tokenId The token ID of the CryptoBlob to transfer.
        @param data Bytes of data to send to `to`.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        // Transfer the CryptoBlob if the sender has access to it.
        transferFrom(from, to, tokenId);
        // Check if 'to' supports ERC721 NFTs so the CryptoBlob does not get stuck.
        if (_isContractPastConstruction(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) revert CONTRACT_DOES_NOT_HAVE_ONERC721RECEIVED_IMPLEMENTED();
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert CONTRACT_DOES_NOT_HAVE_ONERC721RECEIVED_IMPLEMENTED();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
        @notice Allows you to make multiple transactions in a single transaction.
        @dev Categories: 0 {transferFrom}, 1 {setApprovalForAll}, 2 {approve}, 3 {manageTrades}, 4 {optimize}, 5 {sacrifice}.
        @dev Each transaction is separately encoded and processed in the order of the array.
        @param batchDataEncoded The encoded batch data.
    */
    function batch(
        bytes[] memory batchDataEncoded
    ) external {
        unchecked {
            for (uint256 i; i < batchDataEncoded.length; i++) {

                // Decode this transaction.
                BatchData memory batchData = abi.decode(batchDataEncoded[i], (BatchData));

                // Determine function and transact.
                if (batchData.category == 0) {
                    // Transfer the CryptoBlob if the sender has access to it.
                    transferFrom(batchData.account1, batchData.account2, batchData.tokenId);
                } else if (batchData.category == 1) {
                    // Approve or revoke an account operator.
                    setApprovalForAll(batchData.account1, batchData.approved);
                } else if (batchData.category == 2) {
                    // Approve or revoke a token operator.
                    approve(batchData.account1, batchData.tokenId);
                } else if (batchData.category == 3) {
                    // Cancel a trade or lock/unlock trades for an account you have access to.
                    manageTrades(batchData.account1, batchData.hash);
                } else if (batchData.category == 4) {
                    // Optimize CryptoBlobs.
                    optimize(batchData.tokenIds);
                } else if (batchData.category == 5) {
                    // Sacrifice CryptoBlobs.
                    sacrifice(batchData.tokenId, batchData.tokenIds);
                }
            }
        }
    }

    /**
        @notice Cancel a trade or lock/unlock your trades on the integrated trading platform.
        @dev This has no effect on third-party NFT marketplaces.
        @dev Locking your trades prevents others from completing them.
        @dev Trades that auto-expire will continue to countdown when they're locked.
        @param account The account to manage the trades of. Can be an account you are an operator of.
        @param hash The hash of the trade to cancel. 0 bytes to unlock trades. 1 byte to lock trades.
    */
    function manageTrades(
        address account,
        bytes32 hash
    ) public {
        unchecked {
            // Check if the caller has access.
            if (msg.sender != account && !isApprovedForAll(account, msg.sender)) revert RESTRICTED_ACCESS();

            if (hash == 0x0000000000000000000000000000000000000000000000000000000000000000) { // Unlock trades.
                delete _account[account].timestampTradesLocked;
            } else if (hash == 0x0000000000000000000000000000000000000000000000000000000000000001) { // Lock trades.
                _account[account].timestampTradesLocked = _safeBlockTimestamp();
            } else if (_account[account].timestampTradeHashUsed[hash] == 0) { // Cancel trade if not cancelled.
                // The block timestamp is multiplied by 10 to store a binary number. 0 means cancelled. 1 means completed.
                _account[account].timestampTradeHashUsed[hash] = block.timestamp * 10;
            } else {
                revert RESTRICTED_ACCESS();
            }

            uint256[] memory empty = new uint256[](0); // Empty array.

            // msg.sender is `taker` when isTrade is false, which can be an account operator.
            emit Trade(             // 0x10d92c47650ef2b2a841f26c951f4391ccbb731e57d36a67665a0d138e08ef09
                hash,               // address indexed hash
                account,            // address indexed maker
                msg.sender,         // address indexed taker
                empty,              // uint256[] makerIds
                empty,              // uint256[] takerIds
                0,                  // uint256 price
                0,                  // uint256 expiry
                block.timestamp,    // uint256 timestamp
                false               // bool isTrade
            );
        }
    }

    /**
        @notice Confirm a trade on the integrated trading platform.
        @dev Buy, sell, and trade multiple CryptoBlobs at a time.
        @dev Makers and takers can trade CryptoBlobs that they have access to. 
        @dev Approve accounts with {approve} or {setApprovalForAll}.
        @dev Makers do not need to approve this contract to trade.
        @dev Only takers can transfer ETH in a trade. Makers can't deposit ETH.
        @dev Use {manageTrades} to cancel a trade or lock/unlock your trades.
        @dev The trading platform does not currently support EIP-712.
        @param maker The address of the maker.
        @param taker The address of the taker.
        @param makerIds The CryptoBlob IDs `maker` has access to trade.
        @param takerIds The CryptoBlob IDs `taker` has access to trade.
        @param price The price (in WEI) the `taker` must pay to `maker` to complete the trade.
        @param expiry The timestamp the trade auto-expires, or 0 for never expires.
        @param salt Salt allows the same trade parameters to be used again, resulting in a different hash.
        @param signature The signature is the hash of the trade signed by the maker.
    */
    function trade(
        address maker,
        address taker,
        uint256[] memory makerIds,
        uint256[] memory takerIds,
        uint256 price,
        uint256 expiry,
        uint256 salt,
        bytes memory signature
    ) external payable nonReentrant {
        unchecked {

            // Check if trading is paused.
            if (_tradingPaused) revert TRADING_IS_CURRENTLY_DISABLED();

            // Revert if the trade is private and if the sender is not the taker.
            if (taker != address(0) && msg.sender != taker) revert TRADE_IS_NOT_FOR_YOU();

            // Revert if the amount sent is insufficient.
            if (msg.value < price) revert INSUFFICIENT_FUNDS_SENT();

            // Get the hash and errors for the trade.
            (bytes32 hash, uint256[8] memory errors) = isTradeApprovedAndValid(
                maker,
                taker,
                makerIds,
                takerIds,
                price,
                expiry,
                salt,
                signature, 
                false
            );

            // Revert if the trade contains errors.
            for (uint256 i; i < errors.length; i++) if (errors[i] != 0) revert INVALID_TRADE();

            // Transfer sale price to the maker.
            if (price > 0) _transferEther(maker, price);

            // Transfer CryptoBlobs.
            // Third-party NFT marketplaces require an approval to use {transferFrom}, but this trading platform uses {_transfer}, 
            // an internal function, to bypass approvals. This allows takers to complete trades on the maker's behalf using a signature.
            // Note that {_revertIfNoAccess} returns the owner's address because makers and takers can be approved accounts.

            // Transfer maker IDs. Reverts if the maker does not have access to transfer a maker ID.
            for (uint256 i; i < makerIds.length; i++) _transfer(_revertIfNoAccess(maker, makerIds[i]), msg.sender, makerIds[i]);

            // Transfer taker IDs. Reverts if the sender does not have access to transfer a taker ID.
            for (uint256 i; i < takerIds.length; i++) _transfer(_revertIfNoAccess(msg.sender, takerIds[i]), maker, takerIds[i]);

            // Use the trade hash.
            // The block timestamp is multiplied by 10 to store a binary number. 0 means cancelled. 1 means completed.
            _account[maker].timestampTradeHashUsed[hash] = (block.timestamp * 10) + 1;

            emit Trade(             // 0x10d92c47650ef2b2a841f26c951f4391ccbb731e57d36a67665a0d138e08ef09
                hash,               // bytes32 hash
                maker,              // address indexed maker
                msg.sender,         // address indexed taker
                makerIds,           // uint256[] makerIds
                takerIds,           // uint256[] takerIds
                price,              // uint256 price
                expiry,             // uint256 expiry
                block.timestamp,    // uint256 timestamp
                true                // bool isTrade
            );
        }
    }

    /**
        @notice Optimize CryptoBlobs to lower future transaction fees with it.
        @dev You can optimize any CryptoBlob, even if you do not own it.
        @dev You earn one account level per CryptoBlob you optimize.
        @param tokenIds The token IDs of the CryptoBlobs.
    */
    function optimize(
        uint256[] memory tokenIds
    ) public {
        unchecked {
            uint256 amount = tokenIds.length;
            for (uint256 i; i < amount; i++) {
                if (_token[tokenIds[i]].account != address(0)) revert CRYPTOBLOB_DOES_NOT_REQUIRE_OPTIMIZATION();
                _token[tokenIds[i]].account = ownerOf(tokenIds[i]);
            }
            _account[msg.sender].tokensOptimized += uint16(amount);

            emit Optimize(              // 0xff06b6e7e3b7963958aa44cc1dff152337abfc3ef2d0ecd54bdcd8fb9694e0eb
                msg.sender,             // address indexed account
                tokenIds,               // uint256[] tokenIds
                block.timestamp         // uint256 timestamp
            );
        }
    }

    /**
        @notice Sacrifice and upgrade CryptoBlobs.
        @dev Sacrificing permanently removes CryptoBlobs from the circulating supply and
        @dev rewards a meta-collectible called souls via a soul transferring system.
        @dev The more souls a CryptoBlob possess, the higher its rarity, rank, and value. 
        @dev The earlier your CryptoBlobs harnesses souls, the easier it will be to collect them.
        @dev Only 25,000 souls exist, one for each CryptoBlob. Souls cannot be created or destroyed.
        @dev You also earn 1 free CryptoBlob for every 10 sacrificed during the limited-time promotion.
        @dev You must have access to a CryptoBlob to sacrifice it but not upgrade it.
        @param tokenIdUpgrading The CryptoBlob ID that will harness the souls of `tokenIdsSacrificing`.
        @param tokenIdsSacrificing The CryptoBlob IDs being sacrificed.
    */
    function sacrifice(
        uint256 tokenIdUpgrading,
        uint256[] memory tokenIdsSacrificing
    ) public {
        unchecked {

            // Check if sacrificing is paused.
            if (_sacrificingPaused) revert SACRIFICING_IS_CURRENTLY_DISABLED();

            // Check if upgrading ID exists.
            _revertIfTokenIsInvalid(tokenIdUpgrading);

            uint16 totalSouls;
            uint256 amount = tokenIdsSacrificing.length;
            uint32 safeBlockTimestamp = _safeBlockTimestamp();

            for (uint256 i; i < amount; i++) {

                // Get sacrificing ID.
                uint256 tokenIdSacrificing = tokenIdsSacrificing[i];

                // Revert if sacrificing ID matches upgrading.
                if (tokenIdSacrificing == tokenIdUpgrading) revert INVALID_CRYPTOBLOB_ID();

                // Revert if the caller does not have access and get the owner.
                address owner = _revertIfNoAccess(msg.sender, tokenIdSacrificing);

                // Update owner's stats. Cannot underflow because ownership is checked.
                _account[owner].tokensOwned--;
                _account[owner].tokensBurned++;

                // Implicitly clear approvals.
                delete _token[tokenIdSacrificing].approval;

                // ERC721 standards says to not emit an Approval event when transferring. https://eips.ethereum.org/EIPS/eip-721
                // "When a Transfer event emits, this also indicates that the approved address for that NFT (if any) is reset to none."

                // Save the token ID burned to.
                _token[tokenIdSacrificing].burnTo = uint16(tokenIdUpgrading);

                // Update souls to now say how many were transferred. +1 for own soul.
                _token[tokenIdSacrificing].souls++;

                // Add to total.
                totalSouls += _token[tokenIdSacrificing].souls; 

                // '_token[].account' now stores the address of the last owner.
                if (_token[tokenIdSacrificing].account != owner) _token[tokenIdSacrificing].account = owner;

                // Save the timestamp when it was burned.
                _token[tokenIdSacrificing].burnTimestamp = safeBlockTimestamp;

                // Burn event.
                emit Transfer(              // 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                    owner,                  // address indexed from
                    address(0),             // address indexed to
                    tokenIdSacrificing      // uint256 indexed tokenId
                );

            }
            _token[tokenIdUpgrading].souls += totalSouls; // Transfer souls.
            _tokensBurned += uint32(amount); // Update total burned.

            // A 'Sacrifice' event is not emitted. Refer to 'Transfer' logs instead or data saved to the contract.
        }
    }

    /**
        @notice Allows SuperCollectiv to manage the contract.
        @dev Only _contractOwner can manage the contract. 
        @dev Only _contractCandidate can confirm a contract transfer. 
        @dev All other addresses will revert.
        @param category Category to manage.
    */
    function manageContract(
        uint256 category,
        address[] memory _address,
        uint256[] memory _uint,
        string[] memory _string,
        bytes memory _bytes
    ) external payable nonReentrant {
        unchecked {
            if (msg.sender == _contractOwner) {
                // Manage the contract if the caller is the owner.
                if (category == 0) {
                    // Update token name.
                    _name = _string[0];
                } else if (category == 1) {
                    // Update contract URI.
                    _contractURI = _string[0];
                } else if (category == 2) {
                    // Update token URI prefix for single URI.
                    _tokenURIPrefix = _string[0];
                } else if (category == 3) {
                    // Update token URI prefixes for multi URI.
                    uint256 startFrom = _uint[0];
                    for (uint256 i; i < _string.length; i++) {
                        _tokenURIPrefixes[i + startFrom] = _string[i];
                    }
                } else if (category == 4) {
                    // Update max souls limit.
                    _URIMaxSoulsLimit = _uint[0];
                } else if (category == 5) {
                    // Toggle trading.
                    _tradingPaused = !_tradingPaused;
                } else if (category == 6) {
                    // Toggle sacrificing.
                    _sacrificingPaused = !_sacrificingPaused; 
                } else if (category == 7) {
                    // Manage preapproved services.
                    // Only services in the constructor can be managed.
                    // We can permanently and temporarily disable preapproved services.
                    // We cannot reenable a service that has been permanently disabled.
                    // Use {preapprovedServiceStatus} to check the current status of each service.
                    for (uint256 i; i < _address.length; i++) {
                        if (
                            _uint[i] <= 2 && // Status set cannot be higher than 2.
                            (_account[_address[i]].preapprovedStatus == 1 || // If service is temporarily disabled.
                            _account[_address[i]].preapprovedStatus == 2) // If service is enabled.
                        ) { 
                            // 0 = permanently disable service
                            // 1 = temporarily disable service
                            // 2 = reenable service
                            _account[_address[i]].preapprovedStatus = _uint[i];
                        } else {
                            revert RESTRICTED_ACCESS();
                        }
                    }
                } else if (category == 8) {
                    // Update reverse records contract address.
                    _reverseRecordsAddress = _address[0];
                } else if (category == 9) {
                    // Approve or revoke a candidate.
                    _contractCandidate = _address[0];
                } else if (category == 10) {
                    // Gift free CryptoBlobs to any address (up to 100 at a time).
                    uint32 safeBlockTimestamp = _safeBlockTimestamp();
                    for (uint256 i; i < _address.length; i++) {
                        uint16 amount = uint16(_uint[i]); // Get amount.
                        if (amount > _purchaseLimit) revert(); // Revert if >100.
                        address recipient = _address[i]; // Get recipient.
                        _account[recipient].mintedSpecial += amount; // Add to recipient's special mints. Max number is 255.
                        _mint(
                            recipient,              // recipient
                            0,                      // purchased mints
                            amount,                 // free mints
                            safeBlockTimestamp,     // timestamp
                            _tokensMinted()         // tokens minted
                        );
                    }
                } else if (category == 11) {
                    // Interact with another contract or transfer contract balance.
                    _interaction(_address[0], _uint[0], _bytes);
                } else {
                    // Withdraw the entire contract balance to the owner.
                    _transferEther(_contractOwner, address(this).balance);
                }
                // A 'ManageContract' event is not emitted. Use a block explorer for past transactions. Function hash: '007e6eda'.
            } else if (_contractCandidate != address(0) && msg.sender == _contractCandidate) {
                // Transfer the contract if the caller is the candidate.
                emit OwnershipTransferred(      // 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0
                    _contractOwner,             // address indexed previousOwner
                    _contractCandidate          // address indexed newOwner
                );
                _contractOwner = _contractCandidate; // Set the new owner.
                delete _contractCandidate; // Delete the candidate.
            } else {
                // All other addresses are reverted.
                revert RESTRICTED_ACCESS();
            }
        }
    }

    /**
        @notice Emit metadata.
    */
    function metadata(
        string memory table,
        string memory key,
        string memory value
    ) external {
        emit Metadata(          // 0x062e360bff2a6872f7e8ce922ee6867aaeed320f740365aa0c33bb226d45b034
            msg.sender,         // address indexed account
            table,              // string indexed table
            key,                // string indexed key
            value,              // string value
            block.timestamp     // uint256 timestamp
        );
    }

}

/// @notice Restricted access.
error RESTRICTED_ACCESS();
/// @notice Reentrant calls are not allowed;
error REENTRANT_CALLS_ARE_NOT_ALLOWED();
/// @notice Insufficient contract balance.
error INSUFFICIENT_CONTRACT_BALANCE();
/// @notice Unable to transfer ether.
error UNABLE_TO_TRANSFER_ETHER();
/// @notice Unable to interact with contract.
error UNABLE_TO_INTERACT_WITH_CONTRACT();
/// @notice The zero address cannot have an account.
error THE_ZERO_ADDRESS_CANNOT_HAVE_AN_ACCOUNT();
/// @notice Invalid CryptoBlob ID.
error INVALID_CRYPTOBLOB_ID();
/// @notice CryptoBlob has been sacrificed.
error CRYPTOBLOB_HAS_BEEN_SACRIFICED();
/// @notice Cannot approve this address.
error CANNOT_APPROVE_THIS_ADDRESS();
/// @notice Contract does not have onERC721Received implemented.
error CONTRACT_DOES_NOT_HAVE_ONERC721RECEIVED_IMPLEMENTED();
/// @notice From address does not match the owner's address.
error FROM_ADDRESS_DOES_NOT_MATCH_THE_OWNERS_ADDRESS();
/// @notice Owner's balance is insufficient for the index.
error OWNERS_BALANCE_IS_INSUFFICENT_FOR_THE_INDEX();
/// @notice Purchase limit is 100 per transaction.
error PURCHASE_LIMIT_IS_100_PER_TRANSACTION();
/// @notice Insufficient funds sent. Price may have increased.
error INSUFFICIENT_FUNDS_SENT_PRICE_MAY_HAVE_INCREASED(
    uint256 price,
    uint256 received
);
/// @notice Insufficient funds sent.
error INSUFFICIENT_FUNDS_SENT();
/// @notice Invalid trade.
error INVALID_TRADE();
/// @notice NFT is not eligible.
error NFT_IS_NOT_ELIGIBLE();
/// @notice Account has nothing to claim.
error ACCOUNT_HAS_NOTHING_TO_CLAIM();
/// @notice Trading is currently disabled.
error TRADING_IS_CURRENTLY_DISABLED();
/// @notice Sacrificing is currently disabled.
error SACRIFICING_IS_CURRENTLY_DISABLED();
/// @notice CryptoBlob does not require optimization.
error CRYPTOBLOB_DOES_NOT_REQUIRE_OPTIMIZATION();
/// @notice Trade is not for you.
error TRADE_IS_NOT_FOR_YOU();
/// @notice Amount minting is invalid.
error AMOUNT_MINTING_IS_INVALID();
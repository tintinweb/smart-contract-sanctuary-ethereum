// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
  @title IERC721Receiver
*/
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


/**
  @title IERC165
*/
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
  @title IERC721
*/
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


/**
  @title IERC721Enumerable
*/
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}


/**
  @title IERC721Metadata
*/
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


/**
    @title Strings
    @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}


/**
  @title Address
*/
library Address {
    function isContract(address account) internal view returns (bool) {
        // extcodesize returns 0 for contracts in construction.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance"); // Check contract balance.
        (bool success, ) = recipient.call{value: amount}(""); // Send to recipient.
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


/**
  @title ReentrancyGuard
*/
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


/**
  @title Ownable
*/
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
  @title Test
  @author Developer
*/
contract Test is IERC721Enumerable, Ownable, ReentrancyGuard {

    using Address for address;
    using Strings for uint256;

    //            __          __        ___  __  
    // \  /  /\  |__) |  /\  |__) |    |__  /__` 
    //  \/  /~~\ |  \ | /~~\ |__) |___ |___ .__/ 

    /// @notice The name of the token.
    string private constant _name = "Test";
    /// @notice The symbol of the token.
    string private constant _symbol = "TEST";
    /// @notice Max supply of Test.
    uint256 private constant _maxSupply = 25000;
    /// @notice Purchase limit per transaction, but can mint up to 100 with BOGO deals and promotions.
    uint256 private constant _purchaseLimit = 50;
    /// @notice Lowers gas when calculating token ID.
    uint256 private constant _mintSections = 8;
    /// @notice Lowers gas when calculating token ID.
    uint256 private constant _mintIncrement = 3125;
    /// @notice Giveaway ends once 20,000 are minted.
    uint256 private constant _maxFree = 1000;
    /// @notice Free amount each account starts at.
    uint256 private constant _maxFreePerAccount = 25;
    /// @notice Instantly claimable CryptoBlobs declines by one for every 1,000 minted.
    uint256 private constant _giveawayDecrement = 50;
    /// @notice Price increment per weighted point.
    uint256 private constant _basePriceIncrement = 0.000005 ether;
    /// @notice Price and multiplier declines by 1% per hour.
    uint256 private constant _declineDuration = 100 hours;
    /// @notice Maximum loops to find the token owner or mint time.
    uint256 private constant _maxCheck = 25;
    /// @notice The amount of sacrifices to earn a free Test.
    uint256 private constant _sacrificeRewardAmountPerFreeToken = 3;
    /// @notice Used for mintDay and sacrificeDay.
    uint64 private constant _oneDay = 1 days;

    /// @notice The multiplier on the price, determined by the demand. Also used for the automated BOGO deal. Max value possible is 500,000.
    uint32 private _demandMultiplier;
    /// @notice The time the last purchase was made (x60 to get Unix time). 
    uint32 private _purchaseTimestamp;
    /// @notice The number of purchase mints.
    uint32 private _tokensMintedPurchase;
    /// @notice The number of free mints (counted towards account limit).
    uint32 private _tokensMintedFree;
    /// @notice The number of free mints (not counted towards account limit).
    uint32 private _tokensMintedSpecial;
    /// @notice The number of Test sacrificed.
    uint32 private _tokensSacrificed;
    /// @notice The IPFS hash of Test.
    string private _baseURI;
    /// @notice The IPFS hash of Test.
    string private _contentHash;
    /// @notice If marketplace is paused.
    bool private _marketplacePaused;

    /**
        @notice Stores the token data.
        @dev Only 1-25000 is used.
    */
    mapping(uint256 => Token) private _token;

    /**
        @param mintDay Day minted.
        @param sacrificeDay Day sacrificed.
        @param sacrificeTo Test ID the token was sacrificed to.
        @param souls Before sacrificed: The number of souls harnessed. After sacrificed: The number of souls transferred to sacrificeTo.
        @param owner The address of the account that owns the token.
        @param approval The address of the account that the owner approved to manage the token.
    */
    struct Token {
        uint16 mintDay;
        uint16 burnDay;
        uint16 burnTo;
        uint16 souls;
        address owner;
        address approval;
    }

    /**
        @notice Stores account data.
    */
    mapping(address => Account) private _account;

    /**
        @param balance The number of Test owned by the account.
        @param mintedPurchase The number of purchase mints by the account.
        @param mintedFreeGiveaway The number of giveaway mints by the account.
        @param mintedFreeEarned The number of earned mints by the account.
        @param mintedFreeSpecial The number of special mints by the account (from Developer).
        @param sacrificed The number of Test sacrificed by the account.
        @param referrals The number of addresses the account has referred.
        @param mintedPurchaseFirstDay The Unix day the account made their first purchase.
        @param bogo The number of Test the account earned from BOGO deals.
        @param isReferred If the account has been referred.
        @param isTradesDisabled If the account has disabled/paused their trades from being completed on the integrated marketplace.
        @param isTransparent If the owner has transparent backgrounds on their Test enabled.
        @param approvals Addresses the account has approved to manage all Test owned by the account.
        @param cancelledTrades Trade hashes that have been cancelled by the account or completed.
    */
    struct Account {
        uint16 balance;
        uint16 mintedPurchase;
        uint8 mintedFreeGiveaway;
        uint8 mintedFreeEarned;
        uint16 mintedFreeSpecial;
        uint16 burned;
        uint16 referrals;
        uint16 mintedPurchaseFirstDay;
        uint16 bogo;
        bool isReferred;
        bool isTradesDisabled;
        bool isTransparent;
        mapping(address => bool) approvals;
        mapping(bytes32 => uint256) cancelledTrades;
    }

    //  ___       ___      ___  __  
    // |__  \  / |__  |\ |  |  /__` 
    // |___  \/  |___ | \|  |  .__/ 
    
    event MintFree(
        address indexed account, 
        uint256 amount,
        uint256 timestamp
    );
    event MintPurchase(
        address indexed account, 
        address indexed referrer, 
        uint256 amount, 
        uint256 timestamp, 
        uint256 price,
        uint256 base, 
        uint256 multiplier, 
        uint256 decline, 
        uint256 bogo, 
        uint256 refund
    );
    event MintSpecial(
        address[] indexed recipients, 
        uint256[] amount,
        uint256 timestamp
    );
    event MintSpecial2(
        address indexed recipient, 
        uint256 amount,
        uint256 timestamp
    );
    event Sacrifice(
        address indexed account, 
        uint256 timestamp, 
        uint256[] sacrificed, 
        uint256 rewarded,
        uint256 souls
    );
    event Metadata(
        uint256 indexed category, 
        address indexed account, 
        uint256 indexed number, 
        string data,
        uint256 timestamp
    );
    event Trade(
        uint256 timestamp,
        address indexed maker, 
        address indexed taker, 
        uint256[] makerIds, 
        uint256[] takerIds, 
        uint256 price, 
        uint256 expiry
    );

    //              ___     ___  __   ___  ___ 
    //  |\/| | |\ |  |     |__  |__) |__  |__  
    //  |  | | | \|  |     |    |  \ |___ |___ 

    /**
        @notice Claim Test for free from the giveaway.
        @notice Each account starts with 6 free Test, which increases by 1 every 1,000 minted and 2 sacrified.
        @notice The giveaway ends once 20,000 Test have been minted.
        @notice You can optionally purchase additional Test.
        @param amount The amount of Test to claim from the giveaway.
    */
    function mintFree(uint256 amount) external nonReentrant {
        
        // Initialize
        // require(_tokensMinted < maxFree, "Giveaway limit reached");
        // require(tx.origin == msg.sender && !msg.sender.isContract(), "Can't be contract");
        if (_tokensMinted() >= _maxFree) revert ALL_TEST_HAVE_BEEN_CLAIMED_FROM_THE_GIVEAWAY();
        if (tx.origin != msg.sender) revert CANT_CLAIM_FROM_THE_GIVEAWAY_USING_A_CONTRACT(tx.origin, msg.sender);

        // Get total claimed and total claimable.
        uint256 mintedFreeGiveaway = _account[msg.sender].mintedFreeGiveaway;
        uint256 mintedFreeEarned = _account[msg.sender].mintedFreeEarned;
        (
            uint256 claimableGiveaway, 
            uint256 claimableEarned
        ) = _accountToClaimable(msg.sender);
        
        uint256 totalClaimed = mintedFreeGiveaway + mintedFreeEarned;
        uint256 totalClaimable = claimableGiveaway + claimableEarned;

        // Check if account has reached limit.
        if (amount + totalClaimed > _maxFreePerAccount) {
            revert ATTEMPTING_TO_CLAIM_TOO_MANY(
                totalClaimed,
                totalClaimable, 
                amount
            );
        }

        // Check if amount requested is claimable.
        if (amount > totalClaimable) revert ATTEMPTING_TO_CLAIM_TOO_MANY(
            totalClaimed,
            totalClaimable, 
            amount
        );

        // The giveaway is basically 5 giveaways in one with 2 main types: granted and earned.
        // Granted: declining giveaway.
        // Earned: referral program, BOGOs, "sacrifice 3, get 1 free", and daily drops.
        if (claimableGiveaway > 0) { // If account has a claimable amount from the giveaway.
            if (amount > claimableGiveaway) { // If amount requested surpasses the giveaway amount.
                _account[msg.sender].mintedFreeGiveaway += uint8(claimableGiveaway); 
                _account[msg.sender].mintedFreeEarned  += uint8(amount - claimableGiveaway); 
            } else { // If amount doesn't surpass giveaway amount.
                _account[msg.sender].mintedFreeGiveaway += uint8(amount); 
            }
        } else { // If account doesn't have claimable giveaway amount.
            _account[msg.sender].mintedFreeEarned += uint8(amount); 
        }

        _mint(msg.sender, 0, amount, 0); // Mint token(s).

        emit MintFree(msg.sender, amount, block.timestamp);
    }

    /**
        @notice The amount of Test each account can claim for free from the giveaway.
        @notice Each account starts with 20 free Test (actually 21 but only for the first mint), which decreases by 1 every 1,000 minted.
        @return amount The amount of Test each account can claim for free from the giveaway.
    */
    function giveawayLimit() public view returns (uint256 amount) {
        uint256 tokensMinted = _tokensMinted();
        if (tokensMinted < _maxFree) {
            return ((_maxFree - tokensMinted - 1) / _giveawayDecrement) + 1;
        }
    }

    function _tokensMinted() private view returns (uint256 minted) {
        return _tokensMintedPurchase + _tokensMintedFree + _tokensMintedSpecial;
    }

    //              ___     __        __   __             __   ___ 
    //  |\/| | |\ |  |     |__) |  | |__) /  ` |__|  /\  /__` |__  
    //  |  | | | \|  |     |    \__/ |  \ \__, |  | /~~\ .__/ |___ 

    /**
        @notice Test can be purchased from a live market. 
        @notice The price is determined by supply and demand. 
        @notice Using a referrer's address rewards them with a free Test. 
        @notice The caller can only be referred once.
        @param amount The amount of Test to purchase.
        @param referrer The address of the account the caller was referred by.
    */
    function mintPurchase(uint256 amount, address referrer) external payable nonReentrant {
        
        // Initialize
        if (amount > _purchaseLimit) revert CANT_PURCHASE_OVER_50_TEST_PER_TRANSACTION(amount);

        // Get price and total.
        (uint256 tokenPrice, uint256 base, uint256 multiplier, uint256 decline, uint256 bogo) = getPrice();
        uint256 salePrice = tokenPrice * amount;

        // Check value sent.
        // Contract has a revert prevention mechanic to ensure transactions are successful.
        // Mint the max amount possible with the value sent if it's insufficent to purchase the requested amount.
        // If you do not want this mechanic to kick in, purchase Test one at a time.
        if (msg.value < salePrice && msg.value >= tokenPrice) {
            amount = msg.value / tokenPrice; // Mint max amount possible.
            salePrice = tokenPrice * amount; // Correct the sale price.
        }

        if (msg.value < salePrice) revert INSUFFICIENT_FUNDS_SENT_PRICE_MAY_HAVE_INCREASED(salePrice, msg.value);

        // Issue refund.
        uint256 refund;
        if (msg.value > salePrice) {
            refund = msg.value - salePrice;
            payable(msg.sender).transfer(refund);
        }

        // Get amount claimed.
        uint256 claimed = _account[msg.sender].mintedFreeGiveaway + _account[msg.sender].mintedFreeEarned;

        // Calculate free Test earned from the BOGO.
        uint16 bonusBOGO;
        if (bogo != 0) {
            bonusBOGO = uint16(amount / bogo);
            if (claimed + bonusBOGO > _maxFreePerAccount) { // If trying to claim too many.
                bonusBOGO = uint16(_maxFreePerAccount - claimed); // Claim max amount.
                claimed += bonusBOGO;
            }
            _account[msg.sender].bogo += bonusBOGO;
        }

        // Using a referral link rewards both accounts with a free Test. 
        // Each address can reward a referrer once.
        // The referrer has to manually claim it. Referring slightly increases gas fees.
        uint256 bonusReferral;
        if (
            referrer != address(0) && 
            referrer != msg.sender && 
            !_account[msg.sender].isReferred &&
            _tokensMinted() < _maxFree &&
            claimed < _maxFreePerAccount
        ) {
            bonusReferral++;
            _account[msg.sender].isReferred = true;
            // Iterating uses significantly less gas compared to pushing the caller's address into an array of referrals.
            // Because of this, you'll have to read past events of MintPurchase to see referral detail.
            _account[referrer].referrals++;
        } else {
            referrer = address(0); // Remove referral before saving to logs.
        }

        // Update multiplier and timestamp.
        // Increase the multiplier by 0.02% for each Test being minted, which declines at a rate of 1% per hour.
        _demandMultiplier = uint32(multiplier + (20 * (amount + bonusBOGO + bonusReferral)));
        _purchaseTimestamp = uint32(block.timestamp / 1 minutes);

        // Update account data.
        _account[msg.sender].mintedPurchase += uint16(amount);
        _account[msg.sender].mintedFreeEarned += uint8(bonusBOGO + bonusReferral);
        if (_account[msg.sender].mintedPurchaseFirstDay == 0) { // Start earning a free Test each day if not already.
            _account[msg.sender].mintedPurchaseFirstDay = encodeDay();
        }

        _mint(msg.sender, amount, bonusBOGO + bonusReferral, 0); // Mint token(s).

        emit MintPurchase(msg.sender, referrer, amount, block.timestamp, tokenPrice, base, multiplier, decline, bogo, refund);
    }
    
    /**
        @notice Calculates the price and additional market info for {mintPurchase}.
        @notice The price is determined by supply and demand.
        @return price The current price to purchase a Test.
        @return base The current base price, which increases with supply.
        @return multiplier The multiplier on the price, which increases/decreases with demand.
        @return decline The percentage the price declined over time since the last purchase.
        @return bogo Automated BOGO deal, which get better the longer a Test hasn't been minted.
    */
    function getPrice() public view returns (uint256 price, uint256 base, uint256 multiplier, uint256 decline, uint256 bogo) {
        unchecked {

        // Base price
        // The base price scales depending on market activity.
        // Free mints and sacrificing increases the base price by 0.000005 ETH,
        // while purchases increase the base price by 0.00001 ETH.
        // Special mints don't increase the base price.
        base = ((_tokensMintedPurchase * 2) + _tokensMintedFree + _tokensSacrificed) * _basePriceIncrement;

        // Multiplier
        // The multiplier is determined by demand and decreases with time at a rate of 1% per hour.
        // The maximum amount the multiplier can be is 500%, which is very unlikely.
        uint256 elapsed = block.timestamp - (_purchaseTimestamp * 1 minutes);
        uint256 declineDuration = _declineDuration;

        if (declineDuration > elapsed) { // If time remaining.
            multiplier = ((declineDuration - elapsed) * _demandMultiplier) / declineDuration;
        }

        // Decline
        decline = (elapsed * 100000) / declineDuration;
        if (decline > 100000) { // 100%
            decline = 100000;
        }

        // Price
        // base price + multiplier - decline = price
        price = ((((base * (multiplier + 100000)) / 100000) * (100000 - decline)) / 100000);

        // BOGO is determined by how long ago the last purchase was made and if the giveaway is still available.
        if (_tokensMinted() < _maxFree) {
            if (elapsed < 15 minutes) {
                bogo = 5;
            } else if (elapsed < 30 minutes) {
                bogo = 4;
            } else if (elapsed < 45 minutes) {
                bogo = 3;
            } else if (elapsed < 60 minutes) {
                bogo = 2;
            } else {
                bogo = 1;
            }
        }

        return (price, base, multiplier, decline, bogo);
        }
    }

    //       __   __   __            ___     __       ___      
    //  /\  /  ` /  ` /  \ |  | |\ |  |     |  \  /\   |   /\  
    // /~~\ \__, \__, \__/ \__/ | \|  |     |__/ /~~\  |  /~~\ 
    // Non-ERC721 account data

    /**
        @notice The amount of Test an account can claim for free from the giveaway.
        @notice Each account starts with 20 free Test, which decreases by 1 every 1,000 minted.
        @notice Accounts can earn additional free Test by sacrificing, referring, and BOGO deals.
        @param account The address of the account.
        @return claimableGiveaway The amount of Test `account` can claim for free from the declining giveaway.
        @return claimableEarned The amount of Test `account` can claim for free that they earned.
    */
    function _accountToClaimable(address account) private view returns (
        uint256 claimableGiveaway, 
        uint256 claimableEarned
    ) 
    {
        if (_tokensMinted() < _maxFree) { // If giveaway still available.

            uint256 mintedFreeGiveaway = _account[account].mintedFreeGiveaway;
            uint256 mintedFreeEarned = _account[account].mintedFreeEarned;

            // Calculate the remaining tokens an account can claim from the declining giveaway.
            uint256 limit = giveawayLimit();
            
            // Subtract amount claimed.
            if (limit > mintedFreeGiveaway) {
                claimableGiveaway = limit - mintedFreeGiveaway;
            }

            // Calculate the remaining tokens an account can claim from earned Test.
            claimableEarned = (_account[account].burned / _sacrificeRewardAmountPerFreeToken) + _account[account].referrals + _account[account].bogo;

            // One Test earned per day after first purchase.
            if (_account[account].mintedPurchaseFirstDay != 0) {
                claimableEarned += (block.timestamp - decodeDay(_account[account].mintedPurchaseFirstDay)) / _oneDay;
            }

            // Add one if referred.
            if (_account[account].isReferred) {
                claimableEarned++;
            }

            // Subtract amount claimed.
            claimableEarned -= mintedFreeEarned;

            if (claimableGiveaway + claimableEarned > _maxFreePerAccount) {
                claimableEarned = _maxFreePerAccount;
                claimableEarned -= claimableGiveaway;
            }

            return (claimableGiveaway, claimableEarned); // Calculate remaining.
        }
    }

    /**
        @notice General data of an account.
        @dev mintedDetails is an array because of the 'stack too deep' error.
        @dev 0 = mintedPurchase
        @dev 1 = mintedFreeGiveaway
        @dev 2 = mintedFreeEarned
        @dev 3 = mintedFreeSpecial
        @param account The address of the account.
        @return balance The amount of Test owned by `account`.
        @return sacrificed The amount of Test sacrificed by `account`.
        @return minted The amount of Test minted by `account`.
        @return mintedDetails The amount of purchase mints by `account`.
        @return claimableGiveaway The amount of free Test `account` can claim from the giveaway (instantly claimable).
        @return claimableEarned The amount of free Test `account` can claim from the giveaway (earned).
        @return mintPurchaseFirstDay The Unix day `account` made their first purchase.
        @return bogo The amount of Test minted from bogos.
        @return referrals The number of accounts `account` has referred.
        @return isReferred If `account` used a referral code.
        @return isTradesDisabled If `account` has disabled/paused their trades on the integrated marketplace.
        @return isTransparent If `account` has the original background or transparent background.
    */
    function accountData(address account) external view returns (
        uint256 balance, 
        uint256 sacrificed, 
        uint256 minted, 
        uint256[4] memory mintedDetails, 
        uint256 claimableGiveaway, 
        uint256 claimableEarned,
        uint256 mintPurchaseFirstDay,
        uint256 bogo,
        uint256 referrals, 
        bool isReferred,
        bool isTradesDisabled,
        bool isTransparent
    )
    {
        balance = balanceOf(account); // Checks for zero address.
        sacrificed = _account[account].burned;
        mintedDetails[0] = _account[account].mintedPurchase;
        mintedDetails[1] = _account[account].mintedFreeGiveaway;
        mintedDetails[2] = _account[account].mintedFreeEarned;
        mintedDetails[3] = _account[account].mintedFreeSpecial;
        minted = (
            mintedDetails[0] + 
            mintedDetails[1] + 
            mintedDetails[2] + 
            mintedDetails[3]
        );
        isTradesDisabled = _account[account].isTradesDisabled;
        isTransparent = _account[account].isTransparent;
        (claimableGiveaway, claimableEarned) = _accountToClaimable(account);
        mintPurchaseFirstDay = decodeDay(_account[account].mintedPurchaseFirstDay);
        bogo = _account[account].bogo;
        referrals = _account[account].referrals;
        isReferred = _account[account].isReferred;
    }

    /**
        @notice Token data of an account. ownedIds and sacrificedIds use separate indices. Uses index 0.
        @param account The address of the account.
        @return ownedIds All token IDs owned by `owner`.
        @return ownedSouls The number of souls harnessed by each ownedId, rewarded by {sacrifice}.
        @return ownedmintDay The Unix time each ownedId was minted.
        @return ownedApproval The address that has approval of each ownedId.
        @return sacrificedIds All token IDs sacrificed by `owner`.
        @return sacrificedTo The Test ID each sacrificedId was sacrificed to.
        @return sacrificedSouls The amount of souls each sacrificedId transferred after being sacrificed.
        @return sacrificedMintDay The Unix time each sacrificedId was minted.
        @return sacrificedBurnDay The Unix time each sacrificedId was burned.
    */
    function accountTokens(address account) external view returns (
        uint256[] memory ownedIds,
        uint256[] memory ownedSouls,
        uint256[] memory ownedmintDay,
        address[] memory ownedApproval,
        uint256[] memory sacrificedIds,
        uint256[] memory sacrificedTo,
        uint256[] memory sacrificedSouls,
        uint256[] memory sacrificedMintDay,
        uint256[] memory sacrificedBurnDay
    ) {
        address ownerOfToken;

        uint256[7] memory sTaCktOodEeP;
        // sTaCktOodEeP[0] = ownerBalance
        // sTaCktOodEeP[1] = ownersacrificed
        // sTaCktOodEeP[2] = ownedIndex
        // sTaCktOodEeP[3] = sacrificedIndex
        // sTaCktOodEeP[4] = tokensMinted
        // sTaCktOodEeP[5] = mintDayOfToken
        // sTaCktOodEeP[6] = tokenId

        sTaCktOodEeP[0] = balanceOf(account); // Get balance.
        sTaCktOodEeP[1] = _account[account].burned; // Get amount sacrificed.

        if (sTaCktOodEeP[0] + sTaCktOodEeP[1] > 0) {

            // Create owned arrays.
            ownedIds = new uint256[](sTaCktOodEeP[0]);
            ownedSouls = new uint256[](sTaCktOodEeP[0]);
            ownedmintDay = new uint256[](sTaCktOodEeP[0]);
            ownedApproval = new address[](sTaCktOodEeP[0]);

            // Create sacrificed arrays.
            sacrificedIds = new uint256[](sTaCktOodEeP[1]);
            sacrificedTo = new uint256[](sTaCktOodEeP[1]);
            sacrificedSouls = new uint256[](sTaCktOodEeP[1]);
            sacrificedMintDay = new uint256[](sTaCktOodEeP[1]);
            sacrificedBurnDay = new uint256[](sTaCktOodEeP[1]);

            sTaCktOodEeP[4] = _tokensMinted();
            for (uint256 i; i < sTaCktOodEeP[4]; i++) { // Only check up to mint index.
                sTaCktOodEeP[6] = _getTokenId(i); // Get token ID.
                if (_token[sTaCktOodEeP[6]].owner != address(0)) { // Check for owner's address.
                    ownerOfToken = _token[sTaCktOodEeP[6]].owner;
                }
                if (_token[sTaCktOodEeP[6]].mintDay != 0) { // Check for mint time.
                    sTaCktOodEeP[5] = decodeDay(_token[sTaCktOodEeP[6]].mintDay); // Switch to Unix and update mint time.
                }
                if (ownerOfToken == account) { // If owner matches query.
                    if (!_isTokenSacrified(sTaCktOodEeP[6])) { // If not sacrificed.
                        // sTaCktOodEeP[2] = ownedIndex
                        ownedIds[sTaCktOodEeP[2]] = sTaCktOodEeP[6];
                        ownedmintDay[sTaCktOodEeP[2]] = sTaCktOodEeP[5];
                        ownedSouls[sTaCktOodEeP[2]] = _token[sTaCktOodEeP[6]].souls + 1;
                        // ownedTransfers[sTaCktOodEeP[2]] = _token[sTaCktOodEeP[6]].transfers + 1; // +1 to count mint transfer.
                        ownedApproval[sTaCktOodEeP[2]] = _token[sTaCktOodEeP[6]].approval;
                        sTaCktOodEeP[2]++;
                    } else { // If sacrificed.
                        // sTaCktOodEeP[3] = sacrificedIndex
                        sacrificedIds[sTaCktOodEeP[3]] = sTaCktOodEeP[6];
                        sacrificedTo[sTaCktOodEeP[3]] = _token[sTaCktOodEeP[6]].burnTo;
                        sacrificedSouls[sTaCktOodEeP[3]] = _token[sTaCktOodEeP[6]].souls;
                        sacrificedMintDay[sTaCktOodEeP[3]] = sTaCktOodEeP[5];
                        sacrificedBurnDay[sTaCktOodEeP[3]] = decodeDay(_token[sTaCktOodEeP[6]].burnDay);
                        sTaCktOodEeP[3]++;
                    }
                    // End search if all data has been found.
                    if (sTaCktOodEeP[0] + sTaCktOodEeP[1] == sTaCktOodEeP[2] + sTaCktOodEeP[3]) {
                        return (ownedIds, ownedSouls, ownedmintDay, ownedApproval, sacrificedIds, sacrificedTo, sacrificedSouls, sacrificedMintDay, sacrificedBurnDay);
                    }
                }
            }
        }
    }

    /**
        @notice Amount of Test an account has sacrificed.
        @dev For verifying status.
        @param account The address of the account.
        @return amount The amount of Test sacrificed by `account`.
    */
    function accountSacrificed(address account) external view returns (uint256 amount) {
        return _account[account].burned;
    }

    // ___  __        ___          __       ___      
    //  |  /  \ |__/ |__  |\ |    |  \  /\   |   /\  
    //  |  \__/ |  \ |___ | \|    |__/ /~~\  |  /~~\ 

    /**
        @notice Get mint data.
        @return minted The number of Test minted.
        @return mintedPurchase The number of Test purchased.
        @return mintedFree The number of Test minted for free.
        @return mintedSpecial The number of Test minted by Developer.
        @return sacrificed The number of Test sacrificed.
        @return supply The number of Test in circulation.
        @return remainingPurchase The number of Test that can be purchased.
        @return remainingFree The number of Test that can be claimed for free.
    */
    function mintData() external view returns (
        uint256 minted, 
        uint256 mintedPurchase, 
        uint256 mintedFree, 
        uint256 mintedSpecial, 
        uint256 sacrificed, 
        uint256 supply, 
        uint256 remainingPurchase,
        uint256 remainingFree
    ) {
        uint256 tokensMinted = _tokensMinted();
        if (tokensMinted < _maxFree) {
            remainingFree = _maxFree - tokensMinted;
        }
        return (
            tokensMinted, 
            _tokensMintedPurchase, 
            _tokensMintedFree, 
            _tokensMintedSpecial,
            _tokensSacrificed, 
            totalSupply(),  
            _maxSupply - tokensMinted,
            remainingFree
        );  
    }

    /**
        @notice Information about a token.
        @param tokenId The token ID of the Test.
        @return owner The address of the account that owns `tokenId`.
        @return approval The address that has approval of `tokenId`.
        @return souls The number of souls harnessed by `tokenId`, rewarded by {sacrifice}.
        @return mintDay The Unix day `tokenId` was minted.
        @return sacrificeDay The Unix day `tokenId` was sacrificed.
        @return sacrificedTo The Test ID `tokenId` was sacrificed to.
        @return sacrificedSouls The amount of souls `tokenId` transferred after being sacrificed.
    */
    function tokenData(uint256 tokenId) external view returns (
        address owner,
        address approval,
        uint256 souls,
        uint256 mintDay,
        uint256 sacrificeDay,
        uint256 sacrificedTo,
        uint256 sacrificedSouls,
        uint256 transfers
    ) {
        if (!_isTokenSacrified(tokenId)) {
            owner = ownerOf(tokenId);
            approval = _token[tokenId].approval;
            souls = _token[tokenId].souls + 1; // +1 for self.
        } else {
            sacrificeDay = decodeDay(_token[tokenId].burnDay);
            sacrificedTo = _token[tokenId].burnTo;
            sacrificedSouls = _token[tokenId].souls;
        }
        mintDay = _tokenMintDay(tokenId);
        return (owner, approval, souls, mintDay, sacrificeDay, sacrificedTo, sacrificedSouls, transfers);
    }

    /**
        @notice Information about all tokens. Address returns only. Uses index 0.
        @param category 0 = owners, 1 = approvals.
        @return data The data of all tokens, based on the category.
    */
    function allTokenDataAddress(uint256 category) external view returns (address[_maxSupply] memory data) {
        if (category > 1) revert CATEGORY_DOES_NOT_EXIST(category);
        address ownerOfToken;
        uint256 tokensMinted = _tokensMinted();
        for (uint256 i; i < tokensMinted; i++) { // Only check up to mint index.
            uint256 tokenId = _getTokenId(i); // Get token ID.
            if (_token[tokenId].owner != address(0)) { // Set new owner.
                ownerOfToken = _token[tokenId].owner;
            }
            if (!_isTokenSacrified(tokenId)) { // If not sacrificed.
                if (category == 0) {
                    data[tokenId - 1] = ownerOfToken;
                } else {
                    data[tokenId - 1] = _token[tokenId].approval;
                }
            }
        }
        return data;
    }

    /**
        @notice Information about all tokens. Uint returns only. Uses index 0.
        @param category 0 = mintTime, 1 = souls, 2 = sacrificeTime, 3 = sacrificedTo, 4 = sacrificeSouls
        @return data The data of all tokens, based on the category.
    */
    function allTokenDataUint(uint256 category) external view returns (uint256[_maxSupply] memory data) {
        if (category > 4) revert CATEGORY_DOES_NOT_EXIST(category);
        uint256 mintTime;
        uint256 tokensMinted = _tokensMinted();
        for (uint256 i; i < tokensMinted; i++) { // Only check up to mint index.
            uint256 tokenId = _getTokenId(i); // Get token ID.
            if (category == 0) { // mintTime
                if (_token[tokenId].mintDay != 0) { // Check if mint time is saved.
                    mintTime = decodeDay(_token[tokenId].mintDay); // Get mint time.
                }
                data[tokenId - 1] = mintTime;
            } else if (category == 1) { // Souls
                if (!_isTokenSacrified(tokenId)) {
                    data[tokenId - 1] = _token[tokenId].souls + 1; // Get souls only if not sacrified.
                }
            } else if (category == 2) { // sacrificeTime
                data[tokenId - 1] = decodeDay(_token[tokenId].burnDay); // Get sacrifice time.
            } else if (category == 3) { // sacrificedTo
                if (_isTokenSacrified(tokenId)) {
                    data[tokenId - 1] = _token[tokenId].burnTo; // Get token ID sacrified to.
                }
            }else { // sacrificedSouls
                if (_isTokenSacrified(tokenId)) {
                    data[tokenId - 1] = _token[tokenId].souls; // Get souls sent to sacrificedTo.
                }
            }
        }
        return data;
    }

    /// @dev Uint16 is used for gas savings, but can only count up to 2^16-1 days (179.4 years).
    /// @dev To prevent issues, it will only count up to the max it can.
    /// @dev Get past logs for more accurate timestamps.
    function encodeDay() public view returns (uint16 day) {
        uint256 elapsedDays = block.timestamp / _oneDay; // Number of full days since the start of Unix time.
        if (elapsedDays == uint16(elapsedDays)) { // If uint16 can support the number of days elapsed.
            day = uint16(elapsedDays); // Use it, else use max number unit16 supports.
        } else {
            unchecked {
                day--; // Get max uint16 number.
            }
        }
        if (day == 0) { // Shouldn't ever be possible, but things would break if day equals zero.
            day++;
        }
        return day;
    }

    function decodeDay(uint256 day) private pure returns (uint256 unix) {
        if (day != 0) {
            return uint16(day) * _oneDay;
        }
    }

    /**
        @notice The Unix time a Test was minted.
        @param tokenId The token ID of the Test.
        @return mintDay The Unix time `tokenId` was minted.
    */
    function _tokenMintDay(uint256 tokenId) private view returns (uint256 mintDay) {
        uint256 tokenIdIndex = _getIndex(tokenId); // Calculate mint index.
        // 'mintDay' will always be found within 25 loops or less.
        while (mintDay == 0) { // Loop until the mint time is found.
            if (_token[tokenId].mintDay == 0) { // Check if mint time is saved.
                tokenIdIndex--; // Decrement index.
                tokenId = _getTokenId(tokenIdIndex); // Get next token ID to check.
            } else {
                return decodeDay(_token[tokenId].mintDay);
            }
        }
    }

    /**
        @notice If a Test has been sacrified.
        @param tokenId The token ID of the Test.
        @return sacrificed If `tokenId` has been sacrified or not.
    */
    function _isTokenSacrified(uint256 tokenId) private view returns (bool sacrificed) {
        return (_token[tokenId].burnDay != 0);
    }

    /**
        @notice Emit metadata. Multi-purpose use.
        @param category The data type to be logged.
        @param number If the category requires a number, enter it or enter 0 for N/A.
        @param data The data to be emitted.
    */
    function metadata(uint256 category, uint256 number, string memory data) external {
        emit Metadata(category, msg.sender, number, data, block.timestamp);
    }

    // ___  __        ___          __  ___            __        __   __   __  
    //  |  /  \ |__/ |__  |\ |    /__`  |   /\  |\ | |  \  /\  |__) |  \ /__` 
    //  |  \__/ |  \ |___ | \|    .__/  |  /~~\ | \| |__/ /~~\ |  \ |__/ .__/ 

    /**
        @notice The name of the token.
        @return The name of the token.
    */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
        @notice The symbol of the token.
        @return The symbol of the token.
    */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
        @notice The balance of an account.
        @param owner The address of the account.
        @return The balance of `owner`.
    */
    function balanceOf(address owner) public view override returns (uint256) {
        //require(owner != address(0), "ERC721: balance query for the zero address");
        if (owner == address(0)) revert CANT_QUERY_THE_BALANCE_FOR_THE_ZERO_ADDRESS();
        return uint256(_account[owner].balance);
    }

    /**
        @notice The owner of a Test.
        @param tokenId The token ID of the Test.
        @return The owner of `tokenId`.
    */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        _revertOnNonexists(tokenId);
        uint256 tokenIdIndex = _getIndex(tokenId); // Calculate mint index of queried token.
        while (true) { // Loop until the token owner is found.
            if (_token[tokenId].owner == address(0)) { // Check if owner address is saved.
                // Unchecked saves about 750 gas per call or up to 1,500 gas. 'tokenIdIndex' can't underflow.
                unchecked {
                    tokenIdIndex--; // Decrement index.
                }
                tokenId = _getTokenId(tokenIdIndex); // Get next token ID to check.
            } else {
                return _token[tokenId].owner; // Return the address of the owner.
            }
        }
        revert TEST_DOES_NOT_EXIST(tokenId);
    }

    /**
        @notice The token URI of a Test.
        @param tokenId The token ID of the Test.
        @return The token URI of `tokenId`.
    */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        _revertOnNonexists(tokenId);
        string memory backgroundType = !_account[ownerOf(tokenId)].isTransparent ? "original" : "transparent";
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString(), backgroundType)) : "";
    }

    /**
        @notice Allows a Test owner to set an approval, which is an account that can manage a specific Test they own. Read: {getApproved}.
        @param to The address of the account to manage `tokenId`.
        @param tokenId The token ID of the Test.
    */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);

        // require(to != owner, "ERC721: approval to current owner");
        if (to == owner) revert CANT_APPROVE_THE_CURRENT_OWNER_OF_THE_TEST(tokenId, owner);

        // require(
        //     _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
        //     "ERC721: approve caller is not owner nor approved for all"
        // );
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert CALLER_IS_NOT_THE_OWNER_NOR_APPROVED(tokenId, owner, msg.sender);
        }

        // Also sends owner to save gas.
        _approve(to, tokenId, owner);
    }

    /**
        @notice The address of the account that has been approved by a Test owner to manage a specific Test they own. Write: {approve}.
        @param tokenId The token ID of the Test.
        @return The address of the account that can manage `tokenId`.
    */
    function getApproved(uint256 tokenId) public view override returns (address) {
        // require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        _revertOnNonexists(tokenId);
        return _token[tokenId].approval; // _tokenApprovals[tokenId];
    }

    /**
        @notice Allows a Test owner to set the status of operators, which are accounts that can manage all Test they own. Read: {isApprovedForAll}.
        @param operator The address of the account to update management status of all Test owned by the caller.
        @param approved The management status to set `operator` to.
    */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        address owner = msg.sender;
        // require(owner != operator, "ERC721: approve to caller");
        if (owner == operator) revert CANT_APPROVE_YOURSELF(owner);
        _account[owner].approvals[operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
        @notice The management status an operator has over all Test owned by a Test owner. Write: {setApprovalForAll}.
        @param owner The address of the account that owns the Test.
        @param operator The address of the account to the check the management status of.
        @return The management status of `operator` has over `operator` tokens.
    */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _account[owner].approvals[operator];
    }

    /**
        @notice Transfer a Test to another account.
        @param from The address of the account that owns `tokenId`.
        @param to The address of the account to transfer `tokenId` to.
        @param tokenId The token ID of the Test.
    */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        (bool approvedOrOwner, address owner) = _isApprovedOrOwner(msg.sender, tokenId);
        if (!approvedOrOwner) revert CALLER_IS_NOT_THE_OWNER_NOR_APPROVED(tokenId, owner, msg.sender);
        _transfer(from, to, tokenId, owner); // Send additional info to save gas.
    }

    /**
        @notice Safely transfer a Test to another account by checking if the account transferring to supports ERC721 if it's a contract.
        @param from The address of the account that owns `tokenId`.
        @param to The address of the account to transfer `tokenId` to.
        @param tokenId The token ID of the Test.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
        @notice Safely transfer a Test to another account by checking if the account transferring to supports ERC721 if it's a contract.
        @param from The address of the account that owns `tokenId`.
        @param to The address of the account to transfer `tokenId` to.
        @param tokenId The token ID of the Test.
        @param _data Bytes of data to send.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        // require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
        // Check if 'to' supports ERC721 to the Test doesn't get stuck.
        if (!_checkOnERC721Received(from, to, tokenId, _data)) revert CONTRACT_DOESNT_SUPPORT_ERC721(to);
    }

    /**
        @notice Checks if an address can manage a Test and gets the owner's address.
        @param spender The address of the account to check the management status of.
        @param tokenId The token ID of the Test.
        @return approvedOrOwner If the address can manage the token.
        @return owner The address of the account that owns `tokenId`.
    */
    function _isApprovedOrOwner(address spender, uint256 tokenId) private view returns (bool approvedOrOwner, address owner) {
        // require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        owner = ownerOf(tokenId); // Get owner. Checks if the token exists.
        approvedOrOwner = (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
        return (approvedOrOwner, owner);
    }

    /**
        @notice Mints an amount of Test to an address. 
        @dev Does not support safeMint to save gas. Mint to an EOA first and check your contract using {safeTransferFrom}.
        @param to The address of the account to mint the Test to.
        @param purchase The amount of Test to mint to `to` as the purchase mint type.
        @param freeCounted The amount of Test to mint to `to` as the free counted mint type.
        @param freeUncounted The amount of Test to mint to `to` as the free uncounted mint type.
    */
    function _mint(
        address to,
        uint256 purchase,
        uint256 freeCounted,
        uint256 freeUncounted
    ) private {
        uint256 tokensMinted = _tokensMinted(); // Saves gas.
        uint256 amount = purchase + freeCounted + freeUncounted;
        if (to == address(0)) revert CANT_MINT_TOKENS_TO_THE_ZERO_ADDRESS();
        if (tokensMinted + amount > _maxSupply) revert ALL_TEST_HAVE_BEEN_MINTED();
        if (amount == 0) revert CANT_MINT_ZERO_TOKENS();
        
        // Unchecked saves gas. Overflow not possible.
        unchecked {
            // Update balance of 'to'.
            _account[to].balance += uint16(amount);

            // Mint each token.
            for (uint256 i; i < amount; i++) {
                // Calculate token IDs and iterate minted supply in memory.
                uint256 tokenId = _getTokenId(tokensMinted++);
                
                // Periodically save token data to limit gas fees for future transactions.
                if (i % _maxCheck == 0) {
                    _token[tokenId].owner = to;
                    _token[tokenId].mintDay = encodeDay();
                }

                emit Transfer(address(0), to, tokenId);
            }

            // Increase supply.
            if (purchase > 0) {
                _tokensMintedPurchase += uint32(purchase);
            }
            if (freeCounted > 0) {
                _tokensMintedFree += uint32(freeCounted);
            }
            if (freeUncounted > 0) {
                _tokensMintedSpecial += uint32(freeUncounted);
            }
        }
    }

    /**
        @notice Transfers a Test from one account to another. 
        @dev To save gas, the owner's address is sent with the call rather than call {ownerOf} again. 
        @dev This can have serious issues if implemented incorrectly or maliciously. 
        @dev You can check for yourself that the owner is verified before transferring tokens each time {_transfer} is called.
        @param from The alleged address of the account that owns `tokenId`.
        @param to The address of the account to transfer `tokenId` to.
        @param tokenId The token ID of the Test.
        @param owner The address of the account that owns `tokenId`.
    */
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        address owner
    ) private {
        
        // require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        // require(to != address(0), "ERC721: transfer to the zero address");
        if (owner != from) revert ACCOUNT_TRANSFERRING_FROM_DOESNT_MATCH_THE_OWNERS_ADDRESS(tokenId, owner, from);
        if (to == address(0)) revert CANT_TRANSFER_TOKENS_TO_THE_ZERO_ADDRESS();

        // Only update if not transferring to self.
        _account[from].balance -= 1;
        _account[to].balance += 1;

        // Set ownership of next token if 'to' owns it.
        // Only needs to be checked if there's a token minted after it.
        uint256 indexOfNextTokenId = _getIndex(tokenId) + 1;
        if (indexOfNextTokenId < _tokensMinted()) {
            uint256 nextTokenId = _getTokenId(indexOfNextTokenId); // Get token ID.
            if (_token[nextTokenId].owner == address(0)) { // Zero address means 'owner' owns it.
                _token[nextTokenId].owner = owner;
            }
        }

        // Transfer 'tokenId' to 'to'.
        _token[tokenId].owner = to;

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        emit Transfer(from, to, tokenId);
    }

    /**
        @notice Set an approval of a Test. Read: {getApproved}.
        @dev To save gas, the owner's address is sent with the call rather than call {ownerOf} again. 
        @dev This can have minor issues if implemented incorrectly or maliciously. 
        @dev You can check for yourself that the owner is verified before transferring tokens each time {_approve} is called.
        @param to The address of the account to transfer `tokenId` to.
        @param tokenId The token ID of the Test.
        @param owner The address of the account that owns `tokenId`.
    */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _token[tokenId].approval = to;
        emit Approval(owner, to, tokenId);
    }

    /**
        @notice The circulating supply of Test.
        @return The circulating supply of Test.
    */
    function totalSupply() public view override returns (uint256) {
        return _tokensMinted() - _tokensSacrificed;    
    }

    /**
        @notice Get a Test ID at a specific index of an owner's account. 
        @notice Used for off-chain calls. May reach block gas limit.
        @param owner The address of the account that owns `tokenId`.
        @param index Inventory index of `owner` to read. Uses index zero.
        @return The token ID of the Test.
    */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        uint256 tokensMinted = _tokensMinted(); // Saves gas.
        uint256 indexOfQueriedOwner; // This iterates each time a token owned by 'owner' doesn't match 'index'.
        address ownerOfToken; // The owner of the last token read.
        uint256 balance = balanceOf(owner);
        if (index < balance) {
            for (uint256 i; i < tokensMinted; i++) { // Loop all tokens minted.
                uint256 tokenId = _getTokenId(i); // Get token ID from mint index.
                if (_token[tokenId].owner != address(0)) { // If owner is detected.
                    ownerOfToken = _token[tokenId].owner; // Replace latest owner.
                }
                // If tokenData.owner is zero address, 
                // then the token is owned by the previously saved owner.
                if (!_isTokenSacrified(tokenId) && ownerOfToken == owner) { // If not sacrificed and the addresses match.
                    if (indexOfQueriedOwner != index) { // If the index doesn't match.
                        indexOfQueriedOwner++; // Iterate.
                    } else {
                        return tokenId; // Return token ID.
                    }
                }
            }
        }
        revert OWNERS_BALANCE_IS_INSUFFICENT_FOR_THE_INDEX(balance, index);
    }

    /**
        @notice Get the Test ID at a specific index of the circulating supply.
        @notice Used for off-chain calls. May reach block gas limit.
        @param index Index of the circulating supply to read. Uses index zero.
        @return The token ID of the Test.
    */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        uint256 tokensMinted = _tokensMinted(); // Saves gas.
        uint256 tokenIdsIndex;
        if (index < tokensMinted) { // If token has been minted.
            for (uint256 i; i < tokensMinted; i++) { // Loop until mint amount reached.
                uint256 tokenId = _getTokenId(i); // Get token ID.
                if (!_isTokenSacrified(tokenId)) { // If not sacrificed.
                    if (tokenIdsIndex != index) { // If index doesn't match.
                        tokenIdsIndex++; // Iterates.
                    } else {
                        return tokenId;
                    }
                }
            }
        }
        revert TEST_INDEX_OUT_OF_BOUNDS(tokensMinted, index);
    }

    /**
        @notice If an interface ID is supported. 
        @notice Supported interfaces: 
        @notice IERC165 0x01ffc9a7, 
        @notice IERC721 0x80ac58cd, 
        @notice IERC721Metadata 0x5b5e139f, 
        @notice IERC721Enumerable 0x780e9d63.
        @param interfaceId Interface ID.
        @return If `interfaceId` is supported.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId || // Interface ID: 0x01ffc9a7
            interfaceId == type(IERC721).interfaceId || // Interface ID: 0x80ac58cd
            interfaceId == type(IERC721Metadata).interfaceId || // Interface ID: 0x5b5e139f
            interfaceId == type(IERC721Enumerable).interfaceId; // Interface ID: 0x780e9d63
    }

    //  __  ___       ___  __  
    // /  \  |  |__| |__  |__) 
    // \__/  |  |  | |___ |  \ 

    /**
        @notice Withdraw contract balance to Developer. 
        @notice Public since it would be withdrawn by Developer either way.
    */
    function withdraw() public {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /**
        @notice Replacement for OpenZeppelin's {_exists}. 
        @notice Rather than return a bool if it exists or not, the tx will revert if it doesn't exist.
        @param tokenId The token ID of the Test.
    */
    function _revertOnNonexists(uint256 tokenId) private view {
        if (_getIndex(tokenId) >= _tokensMinted()) revert TEST_HASNT_BEEN_MINTED(tokenId);
        if (_isTokenSacrified(tokenId)) revert TEST_HAS_BEEN_SACRIFICED(tokenId, decodeDay(_token[tokenId].burnDay));
    }

    /**
        @notice The IPFS hash of Test.
        @param hash The IPFS hash of Test. May be set at a later date.
    */
    function contentHash() public view returns (string memory hash) {
        return _contentHash;
    }

    /**
        @notice If the integrated marketplace has been paused or not.
        @param paused If the integrated marketplace has been paused or not.
    */
    function marketplacePaused() public view returns (bool paused) {
        return _marketplacePaused;
    }

    /**
        @notice Toggle the background of all Test on an account from original to transparent.
        @notice {setApprovalForAll} allows an account to manage another account.
        @param account The account to toggle.
    */
    function toggleBackground(address account) external returns (bool status, address sender) {
        if (msg.sender != account && !isApprovedForAll(account, msg.sender)) {
            revert CALLER_IS_NOT_APPROVED_FOR_ALL(account, msg.sender);
        }
        _account[account].isTransparent = !_account[account].isTransparent;
        return (_account[account].isTransparent, msg.sender);
    }

    //  __        __   __     ___    __          __       /     __        __               __  
    // /__`  /\  /  ` |__) | |__  | /  ` | |\ | / _`     /     |__) |  | |__) |\ | | |\ | / _` 
    // .__/ /~~\ \__, |  \ | |    | \__, | | \| \__>    /      |__) \__/ |  \ | \| | | \| \__> 

    /**
        @notice Sacrificing AKA 'sacrificeing' removes Test from the circulating supply. Supports sacrificing in bulk.
        @notice This allows for owners to have control over which attributes are rare.
        @notice Sacrificing rewards a meta-collectible called souls to an owned Test of your choice.
        @notice Can also earn 1 free Test for every 3 sacrificed during the giveaway.
        @param tokenIdsSacrificing The Test IDs being sacrificed.
        @param tokenIdRewarding The Test ID all souls of `tokenIdsSacrificing` will be transferred to.
        @return souls The number of souls `tokenIdRewarding` has after sacrificing.
    */
    function sacrifice(uint256[] memory tokenIdsSacrificing, uint256 tokenIdRewarding) external returns (uint256 souls) {
        
        // Checking for duplicates is not necessary because of {_isApprovedOrOwner}.

        // require(_exists(tokenId), "Query for nonexistent token");
        _revertOnNonexists(tokenIdRewarding);
        uint16 rewardedSouls;
        uint256 sacrificingAmount = tokenIdsSacrificing.length;

        unchecked {
            for (uint256 i; i < sacrificingAmount; i++) {
                uint256 tokenIdSacrificing = tokenIdsSacrificing[i];

                // Check token IDs.
                if (tokenIdSacrificing == tokenIdRewarding) revert CANT_SACRIFICE_AND_REWARD_THE_SAME_TEST(tokenIdRewarding);

                // Check if approved or owner. If the token doesn't exist (even sacrificed within the same tx),
                // then the transaction will revert with an error.
                // require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721sacrificeable: caller is not owner nor approved");
                (bool approvedOrOwner, address owner) = _isApprovedOrOwner(msg.sender, tokenIdSacrificing);
                if (!approvedOrOwner) revert CALLER_IS_NOT_THE_OWNER_NOR_APPROVED(tokenIdSacrificing, owner, msg.sender);

                // Update owner's stats.
                _account[owner].balance--;
                _account[owner].burned++;

                _approve(address(0), tokenIdSacrificing, owner); // Clear approvals.

                rewardedSouls += _token[tokenIdSacrificing].souls + 1; // +1 for it's own soul.

                // Update souls to now say how many were sent to the rewarding ID.
                _token[tokenIdSacrificing].burnTo = uint16(tokenIdRewarding);
                _token[tokenIdSacrificing].souls++; // +1 for it's own soul.

                // Unlike {_transfer}, token ownership does not need to be updated, only the sacrifice status.
                // {ownerOf} ignores the sacrifice status as long as the querying token ID exists.
                _token[tokenIdSacrificing].burnDay = encodeDay(); // sacrifice the token.

                emit Transfer(owner, address(0), tokenIdSacrificing);
            }

            _token[tokenIdRewarding].souls += uint16(rewardedSouls); // Transfer souls.

            _tokensSacrificed += uint32(sacrificingAmount); // Update total sacrificed.
        }

        emit Sacrifice(msg.sender, block.timestamp, tokenIdsSacrificing, tokenIdRewarding, rewardedSouls);

        return _token[tokenIdRewarding].souls;
    }

    /**
        @notice Checks if an address supports ERC721 to the Test doesn't get stuck.
        @param from The address of the account that owns `tokenId`.
        @param to The address of the account to transfer `tokenId` to.
        @param tokenId The token ID of the Test.
        @param _data Bytes of data to send.
        @return If the address supports ERC721. EOAs are true by default.
    */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // revert("ERC721: transfer to non ERC721Receiver implementer");
                    revert CONTRACT_DOESNT_SUPPORT_ERC721(to);
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    //             __        ___ ___  __             __   ___ 
    //  |\/|  /\  |__) |__/ |__   |  |__) |     /\  /  ` |__  
    //  |  | /~~\ |  \ |  \ |___  |  |    |___ /~~\ \__, |___ 

    /**
        @notice Toggle the ability for takers to complete your trades on the integrated marketplace. 
        @notice You can still complete trades. This does not effect trading on third-party marketplaces.
    */
    function toggleTrades() external {
        _account[msg.sender].isTradesDisabled = !_account[msg.sender].isTradesDisabled;
    }

    /**
        @notice Makers can cancel a trade by cancelling the hash of the trade.
        @notice Trades are automatically cancelled when completed.
        @param hash The hash of the trade to cancel.
    */
    function cancelTrade(bytes32 hash) external {
        _account[msg.sender].cancelledTrades[hash] = block.timestamp;
    }

    /**
        @notice The hash of a trade, which must be signed by makers to calculate the signature. 
        @dev EIP-712 isn't widely supported, so using the normal method to sign (using a hash is the cheapest method).
        @param maker The address of the maker/signer/seller.
        @param taker The address of the taker/confirmer/buyer.
        @param makerIds The Test IDs owned by `maker` to trade with `taker`.
        @param takerIds The Test IDs owned by `taker` to trade with `maker`.
        @param price The price (in WEI) the `taker` must pay to `maker` to complete the trade.
        @param expiry The Unix time the trade automatically expires, or 0 for never expires.
        @param salt A nonce to allow the same trade parameters to be used again.
        @return hash The hash of the trade.
    */
    function hashTrade(
        address maker, 
        address taker, 
        uint256[] memory makerIds, 
        uint256[] memory takerIds, 
        uint256 price, 
        uint256 expiry, 
        uint256 salt
    ) public view returns (bytes32 hash) {
        bytes32 makerIdsHash = keccak256(abi.encode(makerIds));
        bytes32 takerIdsHash = keccak256(abi.encode(takerIds));
        return keccak256(abi.encode(address(this), maker, taker, makerIdsHash, takerIdsHash, price, expiry, salt));
    }

    /**
        @notice Accept a trade approved and signed by the maker.
        @param maker The address of the maker/signer/seller.
        @param taker The address of the taker/confirmer/buyer.
        @param makerIds The Test IDs owned by `maker` to trade with `taker`.
        @param takerIds The Test IDs owned by `taker` to trade with `maker`.
        @param price The price (in WEI) the `taker` must pay to `maker` to complete the trade.
        @param expiry The Unix time the trade automatically expires, or 0 for never expires.
        @param salt A nonce to allow the same trade parameters to be used again.
        @param signature The signature is calculated by the maker signing the hash of the trade.
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
    ) 
        external payable nonReentrant 
    {

        // Check market.
        if (_marketplacePaused) revert INTEGRATED_MARKETPLACE_IS_PAUSED();
        
        // Check maker/taker.
        if (taker != address(0) && taker != msg.sender) revert TRADE_IS_NOT_FOR_YOU(taker, msg.sender);

        if (price != msg.value) revert INCORRECT_FUNDS_SENT_MUST_MATCH_THE_PRICE_EXACTLY(price, msg.value); // Check value sent.

        (bytes32 hash, bool approved, uint256 errorCode,,) = isTradeApprovedAndValid(
            maker, 
            taker, 
            makerIds, 
            takerIds, 
            price, 
            expiry, 
            salt, 
            signature,
            true // Revert the transaction if there's an error.
        );

        if (!approved) revert MAKER_HAS_NOT_APPROVED_THIS_TRADE();
        if (errorCode != 0) revert INVALID_TRADE();

        // Transfer ETH to the maker.
        if (price > 0) {
            payable(maker).transfer(price);
        }

        // Transfer maker IDs to taker. 
        // {_isTradeApprovedAndValid} verifies token ownership, so 'maker' will always own all 'makerIds'.
        for (uint256 i; i < makerIds.length; i++) {
            _transfer(maker, msg.sender, makerIds[i], maker);
        }
        
        // Transfer taker IDs to maker.
        // {_isTradeApprovedAndValid} verifies token ownership, so 'taker' will always own all 'takerIds'.
        // {_isTradeApprovedAndValid} ensures no tokens will be transferred from the zero address.
        for (uint256 i; i < takerIds.length; i++) {
            _transfer(taker, maker, takerIds[i], taker);
        }

        _account[maker].cancelledTrades[hash] = block.timestamp; // Complete the trade.
        
        emit Trade(block.timestamp, maker, msg.sender, makerIds, takerIds, price, expiry);
    }

    /**
        @notice Check if a trade is approved by the maker and valid.
        @param maker The address of the maker/signer/seller.
        @param taker The address of the taker/confirmer/buyer.
        @param makerIds The Test IDs owned by `maker` to trade with `taker`.
        @param takerIds The Test IDs owned by `taker` to trade with `maker`.
        @param price The price (in WEI) the `taker` must pay to `maker` to complete the trade.
        @param expiry The Unix time the trade automatically expires, or 0 for never expires.
        @param salt A nonce to allow the same trade parameters to be used again.
        @param signature The signature is calculated by the maker signing the hash of the trade.
        @return hash The hash of the trade.
        @return approved If the trade has been approved by the maker.
        @return errorCode The error code of the trade.
        @return tradesDisabled If the maker has disabled their trades from completing.
        @return cancelledTime The Unix time this trade was completed. 0 if N/A.
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
        bool revertOnError
    ) 
        public view returns (
            bytes32 hash, 
            bool approved, 
            uint256 errorCode, 
            uint256 tradesDisabled, 
            uint256 cancelledTime
        ) 
    {
        // Check if the trade meets all requirements.
        (
            hash, 
            errorCode, 
            tradesDisabled, 
            cancelledTime
        ) = _isTradeValid(
            maker, 
            taker, 
            makerIds, 
            takerIds, 
            price, 
            expiry, 
            salt, 
            revertOnError
        );

        // Check if the maker's address matches the hash and signature pair.
        approved = _isTradeApproved(maker, hash, signature);

        return (hash, approved, errorCode, tradesDisabled, cancelledTime);
    }

    /**
        @notice Check if multiple trades are approved by the maker and valid.
        @dev All arrays must be the same length.
        @param maker The address of the maker/signer/seller.
        @param taker The address of the taker/confirmer/buyer.
        @param makerIds The Test IDs owned by `maker` to trade with `taker`.
        @param takerIds The Test IDs owned by `taker` to trade with `maker`.
        @param price The price (in WEI) the `taker` must pay to `maker` to complete the trade.
        @param expiry The Unix time the trade automatically expires, or 0 for never expires.
        @param salt A nonce to allow the same trade parameters to be used again.
        @param signature The signature is calculated by the maker signing the hash of the trade.
        @return hash The hash of the trade.
        @return approved If the trade has been approved by the maker.
        @return errorCode The error code of the trade.
        @return tradesDisabled If the maker has disabled their trades from completing.
        @return cancelledTime The Unix time this trade was completed. 0 if N/A.
    */
    function areTradesApprovedAndValid(
        address[] memory maker, 
        address[] memory taker, 
        uint256[][] memory makerIds, 
        uint256[][] memory takerIds,
        uint256[] memory price,
        uint256[] memory expiry,
        uint256[] memory salt, 
        bytes[] memory signature,
        bool revertOnError
    ) 
        external view returns (
            bytes32[] memory hash, 
            bool[] memory approved, 
            uint256[] memory errorCode, 
            uint256[] memory tradesDisabled, 
            uint256[] memory cancelledTime
        ) 
    {

        if (
            maker.length != taker.length &&
            maker.length != makerIds.length &&
            maker.length != takerIds.length &&
            maker.length != price.length &&
            maker.length != expiry.length &&
            maker.length != salt.length &&
            maker.length != signature.length
        ) revert LENGTHS_MUST_BE_EQUAL();

        hash = new bytes32[](maker.length);
        approved = new bool[](maker.length);
        errorCode = new uint256[](maker.length);
        tradesDisabled = new uint256[](maker.length);
        cancelledTime = new uint256[](maker.length);

        // Check all trades.
        for (uint256 i; i < maker.length; i++) {
            (
                hash[i], 
                approved[i], 
                errorCode[i], 
                tradesDisabled[i], 
                cancelledTime[i]
            ) = isTradeApprovedAndValid(
                maker[i], 
                taker[i], 
                makerIds[i], 
                takerIds[i], 
                price[i], 
                expiry[i], 
                salt[i], 
                signature[i], 
                revertOnError
            );
        }

        return (hash, approved, errorCode, tradesDisabled, cancelledTime);
    }

    /**
        @notice Check if a trade is approved by the maker and valid.
        @dev Calculate the signer of a hash and signature pair. Only the owner of a wallet can sign a hash. 
        @dev Signing is just fancy cryptography math and can be done offline and is not stored on the blockchain. 
        @param maker The address of the maker/signer/seller.
        @param hash The hash of the trade.
        @param signature The signature is calculated by the maker signing the hash of the trade.
        @return approved If the trade has been approved by the maker.
    */
    function _isTradeApproved(
        address maker,
        bytes32 hash, 
        bytes memory signature
    ) 
        private pure returns (bool approved) 
    {
        // Initialize
        if (maker == address(0)) return false; // Don't accept maker.
        if (signature.length != 65) return false; // Check length.
        
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly { // Use assembly to get the signature parameters for ecrecover.
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // If the signature is valid not malleable.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return false;
        if (v != 27 && v != 28) return false;

        // Calculate the signer.
        address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s);
        if (signer == address(0)) return false;

        return (maker == signer); // Check if the addresses match.
    }

    /**
        @notice Check if a trade is valid.
        @dev The error code uses a single number to save gas and to circumvent the stack too deep error.
        @dev How to read the error code: The position of the number means a certain error (reading from right to left).
        @dev 1st position: the maker is the zero address (binary)
        @dev 2nd position: the maker has disable their trades (binary)
        @dev 3rd position: the trade has has been cancelled or completed (binary)
        @dev 4th position: the trade has expired (binary)
        @dev 5th position: the trade is a public listing but has taker IDs listed (binary)
        @dev 6th position: the number of tokens that don't belong to the accounts (decimal)
        @param maker The address of the maker/signer/seller.
        @param taker The address of the taker/confirmer/buyer.
        @param makerIds The Test IDs owned by `maker` to trade with `taker`.
        @param takerIds The Test IDs owned by `taker` to trade with `maker`.
        @param price The price (in WEI) the `taker` must pay to `maker` to complete the trade.
        @param expiry The Unix time the trade automatically expires, or 0 for never expires.
        @param salt A nonce to allow the same trade parameters to be used again.
        @param revertOnError If to revert the transaction with a custom error if it's invalid or to return false.
        @return hash The hash of the trade.
        @return errorCode The error code of the trade. If 0, then trade is valid.
        @return disabledDay The Unix day the maker has disabled their trades from completing. 0 if N/A.
        @return cancelledTime The Unix time the trade was completed. 0 if N/A.
    */
    function _isTradeValid(
        address maker, 
        address taker, 
        uint256[] memory makerIds, 
        uint256[] memory takerIds,
        uint256 price, 
        uint256 expiry,
        uint256 salt,
        bool revertOnError
    ) 
        private view returns (
            bytes32 hash,
            uint256 errorCode, 
            uint256 disabledDay, 
            uint256 cancelledTime
        ) 
    {
        
        // Check if the maker is the zero address.
        if (maker == address(0)) {
            if (revertOnError) {
                revert CANT_ACCEPT_A_TRADE_FROM_THE_ZERO_ADDRESS();
            } else {
                errorCode += 1;
            }
        }
        
        // Check if the maker has disabled/paused trading.
        if (_account[maker].isTradesDisabled) {
            if (revertOnError) {
                revert MAKER_HAS_THEIR_TRADES_DISABLED_OR_PAUSED(maker);
            } else {
                errorCode += 10;
            }
        }

        hash = hashTrade(maker, taker, makerIds, takerIds, price, expiry, salt);

        // If the hash of the trade has been cancelled.
        cancelledTime = _account[maker].cancelledTrades[hash];
        if (cancelledTime != 0) {
            if (revertOnError) {
                revert TRADE_HASH_HAS_BEEN_CANCELLED_OR_COMPLETED(hash, cancelledTime);
            } else {
                errorCode += 100;
            }
        }
        
        // Check if the trade has expired. An expiry of 0 means it never expires.
        if (expiry <= block.timestamp && expiry != 0) {
            if (revertOnError) {
                revert LISTING_HAS_EXPIRED(block.timestamp, expiry);
            } else {
                errorCode += 1000;
            }
        }
        
        uint256 makerIdsAmount = makerIds.length;
        uint256 takerIdsAmount = takerIds.length;

        // Check if the maker owns all maker IDs.
        for (uint256 i; i < makerIdsAmount; i++) {
            if (ownerOf(makerIds[i]) != maker) {
                if (revertOnError) {
                    revert MAKER_DOESNT_OWN_AT_LEAST_ONE_TEST(makerIds[i]);
                } else {
                    errorCode += 100000;
                }
            }
        }

        // Check if the taker owns all taker IDs.
        if (takerIdsAmount > 0) {
            if (taker == address(0)) {
                if (revertOnError) {
                    revert PUBLIC_LISTINGS_CANT_SPECIFY_TAKER_IDS();
                } else {
                    errorCode += 10000;
                }
            }
            for (uint256 i; i < takerIdsAmount; i++) {
                if (ownerOf(takerIds[i]) != taker) {
                    if (revertOnError) {
                        revert TAKER_DOESNT_OWN_AT_LEAST_ONE_TEST(takerIds[i]);
                    } else {
                        errorCode += 100000;
                    }
                }
            }
        }
        
        return (hash, errorCode, disabledDay, cancelledTime);
    }

    //  __             ___  __      __                
    // /  \ |  | |\ | |__  |__)    /  \ |\ | |    \ / 
    // \__/ |/\| | \| |___ |  \    \__/ | \| |___  |  
    
    /**
        @notice Allows Developer to mint Test for free to multiple accounts at a time.
        @notice Used for promotions and giveaways. Special mints have no effect on the price.
        @notice Special mints don't count towards the account limit, 
        @notice allowing those who have reached their free limit to receive special mints.
        @dev Limit is to prevent any accidential issues.
        @param recipients The address of the account to mint `amount` Test to.
        @param amount The amount of Test to mint to `recipients`.
    */
    function mintSpecial(address[] memory recipients, uint256[] memory amount) external onlyOwner {
        if (amount.length != recipients.length) revert LENGTHS_MUST_BE_EQUAL();
        uint256 total;
        for (uint256 i; i < amount.length; i++) {
            total += amount[i];
            if (total > _purchaseLimit * 2) revert CANT_MINT_OVER_100_TEST_PER_TRANSACTION(total);
            _account[recipients[i]].mintedFreeSpecial += uint16(amount[i]); // Add to special.
            _mint(recipients[i], 0, 0, amount[i]); // Mint token(s).
        }
        emit MintSpecial(recipients, amount, block.timestamp);
    }

    /**
        @notice Allows Developer to set the base URI.
        @param baseURI Base URI of the token metadata.
    */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURI = baseURI;
    }

    /**
        @notice Allows Developer to set the IPFS hash.
        @param hash IPFS hash of the token metadata.
    */
    function setContentHash(string memory hash) external onlyOwner {
        _contentHash = hash;
    }

    /**
        @notice Allows Developer toggle the integrated marketplace.
    */
    function toggleMarketplace() external onlyOwner {
        _marketplacePaused = !_marketplacePaused;
    }

    //  __             __                 ___    __        __  
    // /  `  /\  |    /  ` |  | |     /\   |  | /  \ |\ | /__` 
    // \__, /~~\ |___ \__, \__/ |___ /~~\  |  | \__/ | \| .__/ 

    /**
        @notice Calculate the token ID using an index number. 
        @dev The contract prioritizes gas-savings, so a low-gas reversible PRNG is used. 
        @param index The mint index to calcuate the token ID.
        @return tokenId The token ID of mint index `index`.
    */
    function _getTokenId(uint256 index) public pure returns (uint256 tokenId) {
        if (index >= _maxSupply) revert TEST_INDEX_OUT_OF_BOUNDS(_maxSupply, index); // Must be 0-24999.
        unchecked {
            if ((index / _mintSections) % 2 == 0) { // If forwards, calculate and switch to index 1.
                return (_mintIncrement * (index % _mintSections)) + ((_mintIncrement * index) / _maxSupply) + 1;
            } else { // If backwards, calculate and mirror the number.
                return _maxSupply - ((_mintIncrement * (index % _mintSections)) + ((_mintIncrement * index) / _maxSupply));
            }
        }
        //return index + 1;
    }

    /**
        @notice Calculate the index number using the token ID. 
        @dev The contract prioritizes gas-savings, so a low-gas reversible PRNG is used. 
        @param tokenId The token ID to calculate the mint index.
        @return index The mint index of the token ID `tokenId`.
    */
    function _getIndex(uint256 tokenId) public pure returns (uint256 index) {
        if (tokenId > _maxSupply || tokenId < 1) revert TEST_ID_IS_OUT_OF_BOUNDS(tokenId); // Must be 1-25000.
        unchecked { // Lowers gas by up to 13k gas.
            uint256 base = tokenId % _mintIncrement; // Get the base.
            if (base == 0) { // Correct if zero.
                base = _mintIncrement;
            }
            if (base % 2 != 0) { // If base number is odd, switch to index 0.
                tokenId--;
            } else { // If base number is even, unmirror the number.
                tokenId = _maxSupply - tokenId;
            }
            return (((tokenId % _mintIncrement) * _mintSections) + (tokenId / _mintIncrement)); // Reverse magic stuff.
        }
        //return tokenId - 1;
    }
    
}


//  __        __  ___  __            ___  __   __   __   __   __  
// /  ` |  | /__`  |  /  \  |\/|    |__  |__) |__) /  \ |__) /__` 
// \__, \__/ .__/  |  \__/  |  |    |___ |  \ |  \ \__/ |  \ .__/ 

// Custom errors are used instead of OpenZeppelin's default errors because they're
// extremely gas-efficient and provide additional information about the issue.
// See https://blog.soliditylang.org/2021/04/21/custom-errors/
// and https://docs.soliditylang.org/en/latest/abi-spec.html?highlight=error#errors

// Tokens

/// @notice Test does not exist.
error TEST_DOES_NOT_EXIST(uint256 tokenId);
/// @notice Test has been sacrificed.
error TEST_HAS_BEEN_SACRIFICED(uint256 tokenId, uint256 sacrificeDay);
/// @notice Test hasn't been minted.
error TEST_HASNT_BEEN_MINTED(uint256 tokenId);
/// @notice Test ID is out of bounds (1-25000).
error TEST_ID_IS_OUT_OF_BOUNDS(uint256 tokenId);
/// @notice Test index is out of bounds (0-24999).
error TEST_INDEX_OUT_OF_BOUNDS(uint256 max, uint256 index);
/// @notice Can't approve the current owner of the Test.
error CANT_APPROVE_THE_CURRENT_OWNER_OF_THE_TEST(uint256 tokenId, address owner);
/// @notice Can't approve yourself.
error CANT_APPROVE_YOURSELF(address caller);
/// @notice Contract doesn't support ERC721.
error CONTRACT_DOESNT_SUPPORT_ERC721(address account);
/// @notice Account transferring from doesn't match the owner's address.
error ACCOUNT_TRANSFERRING_FROM_DOESNT_MATCH_THE_OWNERS_ADDRESS(uint256 tokenId, address owner, address from);
/// @notice Owner's balance is insufficent for the index.
error OWNERS_BALANCE_IS_INSUFFICENT_FOR_THE_INDEX(uint256 balance, uint256 index);
/// @notice Caller is not the owner nor approved.
error CALLER_IS_NOT_THE_OWNER_NOR_APPROVED(uint256 tokenId, address owner, address caller);
/// @notice Can't sacrifice and reward the same Test.
error CANT_SACRIFICE_AND_REWARD_THE_SAME_TEST(uint256 tokenId);
/// @notice Category does not exist.
error CATEGORY_DOES_NOT_EXIST(uint256 category);
/// @notice Can't query the balance of the zero address.
error CANT_QUERY_THE_BALANCE_FOR_THE_ZERO_ADDRESS();
/// @notice Can't transfer tokens to the zero address.
error CANT_TRANSFER_TOKENS_TO_THE_ZERO_ADDRESS();
/// @notice Sacrificing has ended.
error SACRIFICING_HAS_ENDED(uint256 deadline, uint256 now);
/// @notice Caller is not approved for all.
error CALLER_IS_NOT_APPROVED_FOR_ALL(address account, address sender);

// Minting

/// @notice Can't mint zero tokens.
error CANT_MINT_ZERO_TOKENS();
/// @notice All Test have been minted.
error ALL_TEST_HAVE_BEEN_MINTED();
/// @notice All Test have been claimed from the giveaway.
error ALL_TEST_HAVE_BEEN_CLAIMED_FROM_THE_GIVEAWAY();
/// @notice Can't purchase over 50 Test per transaction.
error CANT_PURCHASE_OVER_50_TEST_PER_TRANSACTION(uint256 amount);
/// @notice Can't mint over 100 Test per transaction.
error CANT_MINT_OVER_100_TEST_PER_TRANSACTION(uint256 amount);
/// @notice Can't claim from the giveaway using a contract.
error CANT_CLAIM_FROM_THE_GIVEAWAY_USING_A_CONTRACT(address origin, address caller);
/// @notice Attempting to claim too many.
error ATTEMPTING_TO_CLAIM_TOO_MANY(uint256 claimed, uint256 claimable, uint256 requested);
/// @notice Insufficient funds sent. Price may have increased.
error INSUFFICIENT_FUNDS_SENT_PRICE_MAY_HAVE_INCREASED(uint256 price, uint256 received);
/// @notice Can't mint tokens to the zero address.
error CANT_MINT_TOKENS_TO_THE_ZERO_ADDRESS();

// Marketplace

/// @notice Maker has their trades disabled or paused.
error MAKER_HAS_THEIR_TRADES_DISABLED_OR_PAUSED(address maker);
/// @notice Listing has expired.
error LISTING_HAS_EXPIRED(uint256 timestamp, uint256 expiry);
/// @notice Maker doesn't owner at least one Test.
error MAKER_DOESNT_OWN_AT_LEAST_ONE_TEST(uint256 tokenId);
/// @notice Taker doesn't owner at least one Test.
error TAKER_DOESNT_OWN_AT_LEAST_ONE_TEST(uint256 tokenId);
/// @notice Public listings can't specify taker IDs.
error PUBLIC_LISTINGS_CANT_SPECIFY_TAKER_IDS();
/// @notice Invalid trade.
error INVALID_TRADE(); 
/// @notice Integrated marketplace is paused.
error INTEGRATED_MARKETPLACE_IS_PAUSED(); 
/// @notice Trade is not for you.
error TRADE_IS_NOT_FOR_YOU(address taker, address caller); 
/// @notice Incorrect funds sent. Must match the price exactly.
error INCORRECT_FUNDS_SENT_MUST_MATCH_THE_PRICE_EXACTLY(uint256 price, uint256 received);
/// @notice Contains duplicate Test IDs.
error CONTAINS_DUPLICATE_TEST_IDS(uint256 duplicate);
/// @notice Trade hash has been cancelled or completed.
error TRADE_HASH_HAS_BEEN_CANCELLED_OR_COMPLETED(bytes32 hash, uint256 cancelledTime);
/// @notice Maker has not approved this trade.
error MAKER_HAS_NOT_APPROVED_THIS_TRADE();
/// @notice Can't appect a trade from the zero address.
error CANT_ACCEPT_A_TRADE_FROM_THE_ZERO_ADDRESS();
/// @notice Lengths must be equal.
error LENGTHS_MUST_BE_EQUAL();
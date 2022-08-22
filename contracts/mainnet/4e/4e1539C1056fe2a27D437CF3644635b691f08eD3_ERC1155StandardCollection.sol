// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                         //
//                                                                                                                                                         //
//       .;dkkkkkkkkkkkkkkkkkkd'      .:xkkkkkkkkd,           .:dk0XXXXXXXK0xdl,.    .lxkkkkkkkkkkkkkkkkkk:.,okkkkkkko.    .cxkkkkkkxc.      ;dkkkkkko.    //
//      ;xNMMMMMMMMMMMMMMMMMMMX:    .:kNWMMMMMMMMWx.        .l0NWWWWWMMMMMMMMMWNO;..lKWMMMMMMMMMMMMMMMMMMMKkKWMMMMMMMK,  .c0WMMMMMMMMX:   .;xXWMMMMMNo.    //
//    .,lddddddddddddddddxKMMMK;   .,lddddddx0WMMMX;      .;llc::;;::cox0XWMMMMMWXdcoddddddddddddddddONMW0ddddddxXMMMK, .:odddddONMMMMO' .,lddddd0WWd.     //
//    ..                 .dWWKl.   .         :XMMMWx.    ...            .,oKWMMMMWx.                 ,KMNc      .kMMM0, ..      .xWMMMWx'.      'kNk.      //
//    ..                 .dKo'    ..         .xWMMMK;  ..       .'..       ,OWWMMWx.                 ,Okc'      .kMMMK,  ..      ,0MMMMXl.     .dNO'       //
//    ..      .:ooo;......,'      .           :XMMMWd. .      .l0XXOc.      ;xKMWNo.      ,looc'......'...      .kMMMK,   ..      cXMMM0,     .oNK;        //
//    ..      '0MMMk.            ..           .kWMMMK,.'      ;KMMMWNo.     .;kNkc,.     .dWMMK:        ..      .kMMMK,    ..     .dWMXc      cXK:         //
//    ..      '0MMMXkxxxxxxxxd'  .     .:.     cXMMMWd,'      '0MMMMM0l;;;;;;:c;. ..     .dWMMW0xxxxxxxxx;      .kMMMK,     ..     'ONd.     :KXc          //
//    ..      '0MMMMMMMMMMMMMNc ..     :O:     .kMMMMK:.       'd0NWMWWWWWWWNXOl'...     .dWMMMMMMMMMMMMWl      .kMMMK,      .      :d'     ;0No.          //
//    ..      .lkkkkkkkkkKWMMNc .     .dNd.     cNMMMWo..        .':dOXWMMMMMMMWXk:.      :xkkkkkkkk0NMMWl      .kMMMK,       .      .     'ONd.           //
//    ..                .oNMXd...     '0M0'     .kMMMM0, ..           .;o0NMMMMMMWx.                ,0MN0:      .kMMMK,       ..          .kW0'            //
//    ..                 cKk,  .      lNMNl      cNMMMNo  .',..          .;xXWMMMWx.                'O0c'.      .kMMMK,        ..        .xWMO.            //
//    ..      .,ccc,.....,,.  ..     .kMMMk.     .OMMMW0;'d0XX0xc,.         :d0MMWx.      ':cc:'....';. ..      .kMMMK,         ..      .oNMMO.            //
//    ..      '0MMMk.         ..     ,kKKKk'      lNMMMN0KWWWMMMWNKl.         cXMWx.     .dWMMX:        ..      .kMMMK,         ..      .OMMMO.            //
//    ..      '0MMMk'..........       .....       'OMMKo:::::cxNMMMKl'.       .OMWx.     .dWMMXc..........      .kMMMK:.........,'      .OMMMO.            //
//    ..      '0MMMNXKKKKKKKKd.                    lNM0'      ;XMMMWN0c       .OMWd.     .dWMMWXKKKKKKKK0c      .kMMMWXKKKKKKKKK0:      .OMMMO.            //
//    ..      'OWWWWWWWWWWMMNc      'llc'   .      '0MNc      .kWMMMMX:       ,KXx:.     .oNWWWWWWWWWWMMWl      .xWWWWWWWWWWWMMMN:      .OMMMO.            //
//    ..       ,:::::::::cOWO.     .xWWO'   .       oNMO'      .lkOOx;.     .'cd,...      .::::::::::dXMWl       '::::::::::xWMMX:      .OMMWx.            //
//    ..                  dNl      ,0Xd.    ..      ,0MNo.        .        ..'.   ..                 ,0WK:                  :NWOo,      .OWKo.             //
//    .'                 .oO,     .co,       ..     .oOc....             ...      ..                 ,xo,..                 ckl..'.     'dd'               //
//     .............................         ..........       .   ..   .          .....................  .....................   .........                 //
//                                                                                                                                                         //
//                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./ERC1155Marketplace.sol";

error AlreadyInitialized();
error BurnNotEnabled();
error ChunkAlreadyProcessed();
error InvalidSender();
error OverTransactionLimit();
error UserAlreadyMinted();

/**
 * @dev This is an implementation of ERC1155 that allows for the creator to sell tokens in a variety of ways. From the ERC1155
 * implementation, each token already has the option to get added with wallet mint limits and token mint limits.
 *
 * First, each tokenId has the ability to sell to users through a restricted sale or whitelist/allowlist option
 * but addresses are only able to do this if they have never minted that token before. This option requires a
 * signature from the owner or the dual signer.
 *
 * Second, each tokenId has the ability to sell through an open sale that has the option to have a certain signature
 * limit and a transaction limit. This requires a valid signature from the owner and the dual signer.
 *
 * Third, each tokenId can open to a general sale at anytime which only has a transaction limit. It does not require a
 * valid signature which makes it more gas efficient than the second method, but requires the owner to send in a transaction.
 *
 * All of these selling mechanisms also allow for both a simple sale or a descending dutch auction.
 */
contract ERC1155StandardCollection is ERC1155Marketplace {
    using ECDSA for bytes32;
    using Strings for uint256;

    bool private hasInit = false;
    bool public burnable;
    bool private requireOwnerOnAllowlist;

    // Compiler will pack this into two 256bit words.
    struct SaleData {
        uint128 price;
        uint128 endPrice;
        uint64 startTimestamp;
        uint64 endTimestamp;
        uint64 txLimit;
    }

    // For tokens that are open to a general sale.
    mapping(uint256 => SaleData) public generalSaleData;

    // So the owner does not repeat airdrops
    mapping(uint256 => bool) processedChunksForOwnerMint;

    event OwnerMinted(uint256 chunk);
    event TokenBought(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 totalPrice,
        bytes32 saleHash
    );
    event MintOpen(
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        uint256 endPrice,
        uint256 txLimit
    );
    event MintClosed(uint256 indexed tokenId);

    constructor(
        bool[1] memory bools,
        address[5] memory addresses,
        uint256[5] memory uints,
        string[2] memory strings,
        bytes[2] memory signatures
    ) ERC1155() {
        _init(bools, addresses, uints, strings, signatures);
    }

    function init(
        bool[1] memory bools,
        address[5] memory addresses,
        uint256[5] memory uints,
        string[2] memory strings,
        bytes[2] memory signatures
    ) external {
        _init(bools, addresses, uints, strings, signatures);
    }

    function _init(
        bool[1] memory bools,
        address[5] memory addresses,
        uint256[5] memory uints,
        string[2] memory strings,
        bytes[2] memory signatures
    ) internal {
        if(hasInit) revert AlreadyInitialized();
        hasInit = true;

        burnable = bools[0];

        _owner = _msgSender();
        _initWithdrawSplits(
            addresses[0], // royalty address
            addresses[1], // revenue share address
            addresses[2], // referral address
            addresses[3], // partnership address
            uints[0], // payout BPS
            uints[1], // owner secondary BPS
            uints[2], // revenue share BPS
            uints[3], // referral BPS
            uints[4], // partnership BPS
            signatures
        );
        dualSignerAddress = addresses[4];

        _setName(strings[0]);
        _setSymbol(strings[1]);
    }

    /**
     * @dev updates the name of the collection
     */
    function updateName(string memory name) external onlyOwner {
        _setName(name);
    }

    /**
     * @dev updates the symbol of the collection
     */
    function updateSymbol(string memory symbol) external onlyOwner {
        _setSymbol(symbol);
    }

    /**
     * @dev Allows user to burn an amount of tokens if burn is enabled
     */
    function burnTokens(uint256 tokenId, uint256 amount) external {
        if (!burnable) revert BurnNotEnabled();
        _burn(_msgSender(), tokenId, amount);
    }

    /**
     * @dev This function does a best effort to Owner mint. If a given tokenId is
     * over the token supply amount, it will mint as many are available and stop at the limit.
     * This is necessary so that a given transaction does not fail if another public mint
     * transaction happens to take place just before this one that would cause the amount of
     * minted tokens to go over a token limit.
     */
    function ownerMint(
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 chunkId
    ) external onlyOwner {
        if (processedChunksForOwnerMint[chunkId]) {
            revert ChunkAlreadyProcessed();
        }
        if (
            receivers.length != tokenIds.length ||
            receivers.length != amounts.length
        ) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 buyLimit = _totalRemainingMints(tokenIds[i]);
            if (buyLimit == 0) {
                continue;
            }

            if (amounts[i] > buyLimit) {
                _mint(receivers[i], tokenIds[i], buyLimit, "");
            } else {
                _mint(receivers[i], tokenIds[i], amounts[i], "");
            }
        }
        processedChunksForOwnerMint[chunkId] = true;
        emit OwnerMinted(chunkId);
    }

    /**
     * @dev Hash that the owner or alternate wallet must sign to enable {mint} for all users
     */
    function _hashForMintAllow(
        address allowedAddress,
        uint256 tokenId,
        uint256 version,
        uint256 nonce,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    address(this),
                    block.chainid,
                    owner(),
                    allowedAddress,
                    tokenId,
                    version,
                    nonce,
                    amount,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Hash an order that we need to check against the signature to see who the signer is.
     * see {_hashForMint} to see the hash that needs to be signed.
     */
    function _hashToCheckForMintAllow(
        address allowedAddress,
        uint256 tokenId,
        uint256 version,
        uint256 nonce,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                _hashForMintAllow(
                    allowedAddress,
                    tokenId,
                    version,
                    nonce,
                    amount,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Hash that the owner or approved alternate signer then sign that the approved buyer
     * can use in order to call the {mintAllow} method.
     */
    function hashToSignForMintAllow(
        address allowedAddress,
        uint256 tokenId,
        uint256 version,
        uint256 nonce,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) external view returns (bytes32) {
        return
            _hashForMintAllow(
                allowedAddress,
                tokenId,
                version,
                nonce,
                amount,
                pricesAndTimestamps
            );
    }

    /**
     * @dev With a hash signed by the method {hashToSignForMintAllow} an approved user with the owner or dual signature
     * can mint at a price up to the quantity specified by the signature. These are all considered primary sales
     * and will be split according to the withdrawal splits defined in the contract.
     */
    function mintAllow(
        address allowedAddress,
        uint256 tokenId,
        uint256 version,
        uint256 nonce,
        uint256 amount,
        uint256 buyAmount,
        uint256[4] memory pricesAndTimestamps,
        bytes memory signature,
        bytes memory dualSignature
    ) external payable {
        _verifyTokenMintLimit(tokenId, buyAmount);

        if (buyAmount > amount || buyAmount == 0) revert InvalidBuyAmount();
        if (version != ownerVersion) revert InvalidVersion();
        if (allowedAddress != _msgSender()) revert InvalidSender();

        uint256 totalPrice = _currentPrice(pricesAndTimestamps) * buyAmount;
        if (msg.value < totalPrice) revert InsufficientValue();
        if (_totalMinted(_msgSender(), tokenId) > 0) revert UserAlreadyMinted();

        bytes32 hash = _hashToCheckForMintAllow(
            allowedAddress,
            tokenId,
            version,
            nonce,
            amount,
            pricesAndTimestamps
        );
        if (hash.recover(signature) != owner()) {
            if (requireOwnerOnAllowlist || dualSignerAddress == address(0)) {
                revert MustHaveOwnerSignature();
            }
            if (hash.recover(dualSignature) != dualSignerAddress) {
                revert MustHaveDualSignature();
            }
        }

        _mint(_msgSender(), tokenId, buyAmount, "");
        emit TokenBought(_msgSender(), tokenId, buyAmount, totalPrice, hash);
        payable(_msgSender()).transfer(msg.value - totalPrice);
    }

    /**
     * @dev Hash that the owner or alternate wallet must sign to enable {mint} for all users
     */
    function _hashForMint(
        uint256 tokenId,
        uint256 version,
        uint256 amount,
        uint256 sigAmount,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    address(this),
                    block.chainid,
                    owner(),
                    tokenId,
                    version,
                    amount,
                    sigAmount,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Hash an order that we need to check against the signature to see who the signer is.
     * see {_hashForMint} to see the hash that needs to be signed.
     */
    function _hashToCheckForMint(
        uint256 tokenId,
        uint256 version,
        uint256 amount,
        uint256 sigAmount,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                _hashForMint(
                    tokenId,
                    version,
                    amount,
                    sigAmount,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Hash that the owner and approved alternate signer then sign that any buyer
     * can use in order to call the {mintWithSignature} method.
     */
    function hashToSignForMint(
        uint256 tokenId,
        uint256 version,
        uint256 amount,
        uint256 sigAmount,
        uint256[4] memory pricesAndTimestamps
    ) external view returns (bytes32) {
        return
            _hashForMint(
                tokenId,
                version,
                amount,
                sigAmount,
                pricesAndTimestamps
            );
    }

    /**
     * @dev With a hash signed by the method {hashToSignForMint} any user with the owner and dual signature
     * can mint at a price up to the quantity specified by the signature. These are all considered primary sales
     * and will be split according to the withdrawal splits defined in the contract.
     */
    function mintWithSignature(
        uint256 tokenId,
        uint256 version,
        uint256 amount,
        uint256 buyAmount,
        uint256 sigAmount,
        uint256[4] calldata pricesAndTimestamps,
        bytes calldata signature,
        bytes calldata dualSignature
    ) external payable {
        _verifyTokenMintLimit(tokenId, buyAmount);
        if (buyAmount == 0 || (amount != 0 && buyAmount > amount)) {
            revert InvalidBuyAmount();
        }
        if (version != ownerVersion) revert InvalidVersion();
        uint256 totalPrice = _currentPrice(pricesAndTimestamps) * buyAmount;
        if (msg.value < totalPrice) revert InsufficientValue();

        bytes32 hash = _hashToCheckForMint(
            tokenId,
            version,
            amount,
            sigAmount,
            pricesAndTimestamps
        );

        _verifySignaturesAndUpdateHash(
            hash,
            owner(),
            sigAmount,
            buyAmount,
            signature,
            dualSignature
        );

        _mint(_msgSender(), tokenId, buyAmount, "");
        emit TokenBought(_msgSender(), tokenId, buyAmount, totalPrice, hash);
        payable(_msgSender()).transfer(msg.value - totalPrice);
    }

    /**
     * @dev Allows the owner to open the {generalMint} method to the public for a certain tokenId
     * this method is to allow buyers to save gas on minting by not requiring a signature.
     */
    function openMint(
        uint256 tokenId,
        uint128 price,
        uint128 endPrice,
        uint64 startTimestamp,
        uint64 endTimestamp,
        uint64 txLimit
    ) external onlyOwner {
        generalSaleData[tokenId].price = price;
        generalSaleData[tokenId].endPrice = endPrice;
        generalSaleData[tokenId].startTimestamp = startTimestamp;
        generalSaleData[tokenId].endTimestamp = endTimestamp;
        generalSaleData[tokenId].txLimit = txLimit;

        emit MintOpen(
            tokenId,
            startTimestamp,
            endTimestamp,
            price,
            endPrice,
            txLimit
        );
    }

    /**
     * @dev Allows the owner to close the {generalMint} method to the public for a certain tokenId.
     */
    function closeMint(uint256 tokenId) external onlyOwner {
        generalSaleData[tokenId].startTimestamp = 0;
        generalSaleData[tokenId].endTimestamp = 0;
        emit MintClosed(tokenId);
    }

    /**
     * @dev Allows any user to buy a certain tokenId. This buy transaction is still limited by the
     * wallet mint limit, token supply limit, and transaction limit set for the tokenId. These are
     * all considered primary sales and will be split according to the withdrawal splits defined in the contract.
     */
    function mint(uint256 tokenId, uint256 buyAmount) external payable {
        _verifyTokenMintLimit(tokenId, buyAmount);
        if (
            generalSaleData[tokenId].txLimit != 0 &&
            buyAmount > generalSaleData[tokenId].txLimit
        ) {
            revert OverTransactionLimit();
        }

        uint256[4] memory pricesAndTimestamps = [
            uint256(generalSaleData[tokenId].price),
            uint256(generalSaleData[tokenId].endPrice),
            uint256(generalSaleData[tokenId].startTimestamp),
            uint256(generalSaleData[tokenId].endTimestamp)
        ];
        uint256 totalPrice = _currentPrice(pricesAndTimestamps) * buyAmount;
        if (msg.value < totalPrice) revert InsufficientValue();

        _mint(_msgSender(), tokenId, buyAmount, "");
        emit TokenBought(_msgSender(), tokenId, buyAmount, totalPrice, "");
        payable(_msgSender()).transfer(msg.value - totalPrice);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IEaselyPayout.sol";
import "../token/ERC1155/ERC1155.sol";
import "../utils/ECDSA.sol";
import "../utils/IERC2981.sol";

error BeforeStartTime();
error InsufficientValue();
error InsufficientSellerBalance();
error InvalidBuyAmount();
error InvalidStartEndPrices();
error InvalidStartEndTimes();
error InvalidVersion();
error LoansInactive();
error MustHaveDualSignature();
error MustHaveOwnerSignature();
error MustHaveTokenOwnerSignature();
error MustHaveVerifiedSignature();
error NotTokenLoaner();
error OverMaxRoyalties();
error OverSignatureLimit();
error TokenOnLoan();
error WithdrawSplitsTooHigh();

/**
 * @dev Extension of the ERC1155 contract that integrates a marketplace so that simple lazy-sales
 * do not have to be done on another contract. This saves gas fees on secondary sales because
 * buyers will not have to pay a gas fee to setApprovalForAll for another marketplace contract after buying.
 *
 * Easely will help power the lazy-selling as well as lazy minting that take place on
 * directly on the collection, which is why we take a cut of these transactions. Our cut can
 * be publically seen in the connected EaselyPayout contract and cannot exceed 5%.
 *
 * Owners also set a dual signer which they can change at any time. This dual signer helps enable
 * sales for large batches of addresses without needing to manually sign hundreds or thousands of hashes.
 * It also makes phishing scams harder as both signatures need to be compromised before an unwanted sale can occur.
 */
abstract contract ERC1155Marketplace is ERC1155, IERC2981 {
    using ECDSA for bytes32;
    using Strings for uint256;

    // Allows token owners to loan tokens to other addresses.
    // bool public loaningActive;

    /* see {IEaselyPayout} for more */
    address public constant PAYOUT_CONTRACT_ADDRESS =
        0xa95850bB73459ADB9587A97F103a4A7CCe59B56E;
    uint256 internal constant TIME_PER_DECREMENT = 300;

    /* Basis points or BPS are 1/100th of a percent, so 10000 basis points accounts for 100% */
    uint256 internal constant BPS_TOTAL = 10000;
    /* Max basis points for the owner for secondary sales of this collection */
    uint256 internal constant MAX_SECONDARY_BPS = 1000;
    /* Default payout percent if there is no signature set */
    uint256 internal constant DEFAULT_PAYOUT_BPS = 500;
    /* Signer for initializing splits to ensure splits were agreed upon by both parties */
    address internal constant VERIFIED_CONTRACT_SIGNER =
        0x1BAAd9BFa20Eb279d2E3f3e859e3ae9ddE666c52;

    /*
     * Optional addresses to distribute referral commission for this collection
     *
     * Referral commission is taken from easely's cut
     */
    address public referralAddress;
    /*
     * Optional addresses to distribute partnership comission for this collection
     *
     * Partnership commission is taken in addition to easely's cut
     */
    address public partnershipAddress;
    /* Optional addresses to distribute revenue of primary sales of this collection */
    address public revenueShareAddress;

    /* Enables dual address signatures to lazy mint */
    address public dualSignerAddress;

    uint256 internal ownerVersion;
    /* Constant used to help calculate royalties */
    uint256 private constant MAX_BPS = 10000;

    /* Address royalties get sent to for marketplaces that honor EIP-2981. Owner can change this at any time */
    address private royaltyAddress;

    struct WithdrawSplits {
        /* Optional basis points for the owner for secondary sales of this collection */
        uint64 ownerRoyaltyBPS;
        /* Basis points for easely's payout contract */
        uint64 payoutBPS;
        /* Optional basis points for revenue sharing the owner wants to set up */
        uint64 revenueShareBPS;
        /*
         * Optional basis points for collections that have been referred.
         *
         * Contracts with this will have a reduced easely's payout cut so that
         * the creator's cut is unaffected
         */
        uint32 referralBPS;
        /*
         * Optional basis points for collections that require partnerships
         *
         * Contracts with this will have this fee on top of easely's payout cut because the partnership
         * will offer advanced web3 integration of this contract in some form beyond what easely provides.
         */
        uint32 partnershipBPS;
    }

    WithdrawSplits public splits;

    /* Mapping to the active version for all signed transactions */
    mapping(address => uint256) internal _addressToActiveVersion;
    /* To allow signatures to be limited to certain number of times */
    mapping(bytes32 => uint256) internal hashCount;

    // Events related to lazy selling
    event SaleCancelled(address indexed seller, bytes32 hash);
    event SaleCompleted(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 totalPrice,
        bytes32 hash
    );

    // Miscellaneous events
    event VersionChanged(address indexed seller, uint256 version);
    event DualSignerChanged(address newSigner);
    event BalanceWithdrawn(uint256 balance);
    event RoyaltyUpdated(uint256 bps);
    event WithdrawSplitsSet(
        address indexed revenueShareAddress,
        address indexed referralAddress,
        address indexed partnershipAddress,
        uint256 payoutBPS,
        uint256 revenueShareBPS,
        uint256 referralBPS,
        uint256 partnershipBPS
    );

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev initializes all of the addresses and percentage of withdrawn funds that
     * each address will get. These addresses and BPS splits must be signed by both the
     * verified easely wallet and the creator of the contract. If a signature is missing
     * the contract has a default of 5% to the easely payout wallet.
     */
    function _initWithdrawSplits(
        address royaltyAddress_,
        address revenueShareAddress_,
        address referralAddress_,
        address partnershipAddress_,
        uint256 payoutBPS_,
        uint256 ownerRoyaltyBPS_,
        uint256 revenueShareBPS_,
        uint256 referralBPS_,
        uint256 partnershipBPS_,
        bytes[2] memory signatures
    ) internal virtual {
        royaltyAddress = royaltyAddress_;
        revenueShareAddress = revenueShareAddress_;
        if (ownerRoyaltyBPS_ > MAX_SECONDARY_BPS) revert OverMaxRoyalties();
        if (signatures[1].length == 0) {
            if (DEFAULT_PAYOUT_BPS + revenueShareBPS_ > BPS_TOTAL) {
                revert WithdrawSplitsTooHigh();
            }
            splits = WithdrawSplits(
                uint64(ownerRoyaltyBPS_),
                uint64(DEFAULT_PAYOUT_BPS),
                uint64(revenueShareBPS_),
                uint32(0),
                uint32(0)
            );
            emit WithdrawSplitsSet(
                revenueShareAddress_,
                address(0),
                address(0),
                DEFAULT_PAYOUT_BPS,
                revenueShareBPS_,
                0,
                0
            );
        } else {
            if (
                payoutBPS_ + referralBPS_ + partnershipBPS_ + revenueShareBPS_ >
                BPS_TOTAL
            ) {
                revert WithdrawSplitsTooHigh();
            }
            bytes memory encoded = abi.encode(
                "InitializeSplits",
                royaltyAddress_,
                revenueShareAddress_,
                referralAddress_,
                partnershipAddress_,
                payoutBPS_,
                revenueShareBPS_,
                referralBPS_,
                partnershipBPS_
            );
            bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(encoded));
            if (hash.recover(signatures[0]) != _owner) {
                revert MustHaveOwnerSignature();
            }
            if (hash.recover(signatures[1]) != VERIFIED_CONTRACT_SIGNER) {
                revert MustHaveVerifiedSignature();
            }
            referralAddress = referralAddress_;
            partnershipAddress = partnershipAddress_;
            splits = WithdrawSplits(
                uint64(ownerRoyaltyBPS_),
                uint64(payoutBPS_),
                uint64(revenueShareBPS_),
                uint32(referralBPS_),
                uint32(partnershipBPS_)
            );
            emit WithdrawSplitsSet(
                revenueShareAddress_,
                referralAddress_,
                partnershipAddress_,
                payoutBPS_,
                revenueShareBPS_,
                referralBPS_,
                partnershipBPS_
            );
        }
        emit RoyaltyUpdated(ownerRoyaltyBPS_);
    }

    /**
     * @dev see {IERC2981-supportsInterface}
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 royalty = (_salePrice * splits.ownerRoyaltyBPS) / MAX_BPS;
        return (royaltyAddress, royalty);
    }

    /**
     * @dev Updates the address royalties get sent to for marketplaces that honor EIP-2981.
     */
    function setRoyaltyAddress(address wallet) external onlyOwner {
        royaltyAddress = wallet;
    }

    /**
     * @dev see {_setSecondary}
     */
    function setRoyaltiesBPS(uint256 newBPS) external onlyOwner {
        if (newBPS > MAX_SECONDARY_BPS) revert OverMaxRoyalties();
        splits.ownerRoyaltyBPS = uint64(newBPS);
        emit RoyaltyUpdated(newBPS);
    }

    /**
     * @dev See {_currentPrice}
     */
    function getCurrentPrice(uint256[4] memory pricesAndTimestamps)
        external
        view
        returns (uint256)
    {
        return _currentPrice(pricesAndTimestamps);
    }

    /**
     * @dev Returns the current activeVersion of an address both used to create signatures
     * and to verify signatures of {buyToken} and {buyNewToken}
     */
    function getActiveVersion(address address_)
        external
        view
        returns (uint256)
    {
        if (address_ == owner()) {
            return ownerVersion;
        }
        return _addressToActiveVersion[address_];
    }

    /**
     * This function, while callable by anybody will always ONLY withdraw the
     * contract's balance to:
     *
     * the owner's account
     * the addresses the owner has set up for revenue share
     * the easely payout contract cut - capped at 5% but can be lower for some users
     *
     * This is callable by anybody so that Easely can set up automatic payouts
     * after a contract has reached a certain minimum to save creators the gas fees
     * involved in withdrawing balances.
     */
    function withdrawBalance(uint256 withdrawAmount) external {
        if (withdrawAmount > address(this).balance) {
            withdrawAmount = address(this).balance;
        }

        uint256 payoutBasis = withdrawAmount / BPS_TOTAL;
        if (splits.revenueShareBPS > 0) {
            payable(revenueShareAddress).transfer(
                payoutBasis * splits.revenueShareBPS
            );
        }
        if (splits.referralBPS > 0) {
            payable(referralAddress).transfer(payoutBasis * splits.referralBPS);
        }
        if (splits.partnershipBPS > 0) {
            payable(partnershipAddress).transfer(
                payoutBasis * splits.partnershipBPS
            );
        }
        payable(PAYOUT_CONTRACT_ADDRESS).transfer(
            payoutBasis * splits.payoutBPS
        );

        uint256 remainingAmount = withdrawAmount -
            payoutBasis *
            (splits.revenueShareBPS +
                splits.partnershipBPS +
                splits.referralBPS +
                splits.payoutBPS);
        payable(owner()).transfer(remainingAmount);
        emit BalanceWithdrawn(withdrawAmount);
    }

    /**
     * @dev Allows the owner to change who the dual signer is
     */
    function setDualSigner(address alt) external onlyOwner {
        dualSignerAddress = alt;
        emit DualSignerChanged(alt);
    }

    /**
     * @dev Usable by any user to update the version that they want their signatures to check. This is helpful if
     * an address wants to mass invalidate their signatures without having to call cancelSale on each one.
     */
    function updateVersion(uint256 version) external {
        if (_msgSender() == owner()) {
            ownerVersion = version;
        } else {
            _addressToActiveVersion[_msgSender()] = version;
        }
        emit VersionChanged(_msgSender(), version);
    }

    /**
     * @dev helper method get ownerRoyalties into an array form
     */
    function _royalties() internal view returns (address[] memory) {
        address[] memory royalties = new address[](1);
        royalties[0] = royaltyAddress;
        return royalties;
    }

    /**
     * @dev helper method get secondary BPS into array form
     */
    function _royaltyBPS() internal view returns (uint256[] memory) {
        uint256[] memory ownerBPS = new uint256[](1);
        ownerBPS[0] = splits.ownerRoyaltyBPS;
        return ownerBPS;
    }

    /**
     * @dev Checks if an address is either the owner, or the approved alternate signer.
     */
    function _checkValidSigner(address signer) internal view {
        if (signer == owner()) return;
        if (dualSignerAddress == address(0)) revert MustHaveOwnerSignature();
        if (signer != dualSignerAddress) revert MustHaveDualSignature();
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashForSale(
        address owner,
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    address(this),
                    block.chainid,
                    owner,
                    version,
                    nonce,
                    tokenId,
                    amount,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashToCheckForSale(
        address owner,
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                _hashForSale(
                    owner,
                    version,
                    nonce,
                    tokenId,
                    amount,
                    pricesAndTimestamps
                )
            );
    }

    /**
     * @dev Current price for a sale which is calculated for the case of a descending sale. So
     * the ending price must be less than the starting price and the timestamp is active.
     * Standard single fare sales will have a matching starting and ending price.
     */
    function _currentPrice(uint256[4] memory pricesAndTimestamps)
        internal
        view
        returns (uint256)
    {
        uint256 startingPrice = pricesAndTimestamps[0];
        uint256 endingPrice = pricesAndTimestamps[1];
        uint256 startingTimestamp = pricesAndTimestamps[2];
        uint256 endingTimestamp = pricesAndTimestamps[3];

        uint256 currTime = block.timestamp;
        if (currTime < startingTimestamp) revert BeforeStartTime();
        if (startingTimestamp >= endingTimestamp) revert InvalidStartEndTimes();
        if (startingPrice < endingPrice) revert InvalidStartEndPrices();

        if (startingPrice == endingPrice || currTime > endingTimestamp) {
            return endingPrice;
        }

        uint256 diff = startingPrice - endingPrice;
        uint256 decrements = (currTime - startingTimestamp) /
            TIME_PER_DECREMENT;
        if (decrements == 0) {
            return startingPrice;
        }

        // decrements will equal 0 before totalDecrements does so we will not divide by 0
        uint256 totalDecrements = (endingTimestamp - startingTimestamp) /
            TIME_PER_DECREMENT;

        return startingPrice - (diff / totalDecrements) * decrements;
    }

    /**
     * @dev Verifies that both the signer and the dual signer (if exists) have signed the hash
     * to allow a sale of a token of a certain amount. Also verifies if the buyAmount that is 
     * requested is not over the total hashAmount that the signer has put on sale for this signature.
     */
    function _verifySignaturesAndUpdateHash(
        bytes32 hash,
        address signer,
        uint256 hashAmount,
        uint256 buyAmount,
        bytes memory signature,
        bytes memory dualSignature
    ) internal {
        if (hashAmount != 0) {
            if (hashCount[hash] + buyAmount > hashAmount) {
                revert OverSignatureLimit();
            }
            hashCount[hash] += buyAmount;
        }

        if (hash.recover(signature) != signer) revert MustHaveOwnerSignature();
        if (
            dualSignerAddress != address(0) &&
            hash.recover(dualSignature) != dualSignerAddress
        ) revert MustHaveDualSignature();
    }

    /**
     * @dev Usable by the owner of any token initiate a sale for their token. This does not
     * lock the tokenId and the owner can freely trade their token, but doing so will
     * invalidate the ability for others to buy.
     */
    function hashToSignToSellToken(
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) external view returns (bytes32) {
        return
            _hashForSale(
                _msgSender(),
                version,
                nonce,
                tokenId,
                amount,
                pricesAndTimestamps
            );
    }

    /**
     * @dev Usable to cancel hashes generated from {hashToSignToSellToken}
     */
    function cancelSale(
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256 amount,
        uint256[4] memory pricesAndTimestamps
    ) external {
        bytes32 hash = _hashToCheckForSale(
            _msgSender(),
            version,
            nonce,
            tokenId,
            amount,
            pricesAndTimestamps
        );
        hashCount[hash] = 2**256 - 1;
        emit SaleCancelled(_msgSender(), hash);
    }

    /**
     * @dev With a hash signed by the method {hashToSignToSellToken} any user sending enough value can buy
     * the token from the seller. Tokens not owned by the contract owner are all considered secondary sales and
     * will give a cut to the owner of the contract based on the secondaryOwnerBPS.
     */
    function buyToken(
        address seller,
        uint256 version,
        uint256 nonce,
        uint256 tokenId,
        uint256 amount,
        uint256 buyAmount,
        uint256[4] memory pricesAndTimestamps,
        bytes memory signature,
        bytes memory dualSignature
    ) external payable {
        uint256 balance = balanceOf(seller, tokenId);
        if (balance < buyAmount) revert InsufficientSellerBalance();
        if (amount < buyAmount) revert InvalidBuyAmount();

        uint256 totalPrice = _currentPrice(pricesAndTimestamps) * buyAmount;
        if (_addressToActiveVersion[seller] != version) revert InvalidVersion();
        if (msg.value < totalPrice) revert InsufficientValue();

        bytes32 hash = _hashToCheckForSale(
            seller,
            version,
            nonce,
            tokenId,
            amount,
            pricesAndTimestamps
        );
        _verifySignaturesAndUpdateHash(
            hash,
            seller,
            amount,
            buyAmount,
            signature,
            dualSignature
        );

        _safeTransferFrom(seller, _msgSender(), tokenId, amount, "");
        emit SaleCompleted(
            seller,
            _msgSender(),
            tokenId,
            buyAmount,
            totalPrice,
            hash
        );

        if (seller != owner()) {
            IEaselyPayout(PAYOUT_CONTRACT_ADDRESS).splitPayable{
                value: totalPrice
            }(seller, _royalties(), _royaltyBPS());
        }
        payable(_msgSender()).transfer(msg.value - totalPrice);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev External interface of the EaselyPayout contract
 */
interface IEaselyPayout {
    /**
     * @dev Takes in a payable amount and splits it among the given royalties.
     * Also takes a cut of the payable amount depending on the sender and the primaryPayout address.
     * Ensures that this method never splits over 100% of the payin amount.
     */
    function splitPayable(
        address primaryPayout,
        address[] memory royalties,
        uint256[] memory bps
    ) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Strings.sol";
import "../../utils/Ownable.sol";
import "../../utils/ERC165.sol";

error ApprovalToCurrentOwner();
error ArrayLengthMismatch();
error BalanceQueryForZeroAddress();
error BurnFromZeroAddress();
error InsufficientTokenBalance();
error InvalidMetadata();
error MintToZeroAddress();
error NonExistentToken();
error NotOwnerOrApproved();
error OverMaxMint();
error OverMaxTokens();
error OverTokenLimit();
error OverWalletLimit();
error TokenAlreadyExists();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * There are some modifications compared to the originial OpenZepplin implementation
 * that give the collection owner many options for the tokens they want to add in
 * their ERC1155 collection.
 *
 * _Available since v3.1._
 */
contract ERC1155 is Ownable, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenAddressData {
        // Limited to uint64 to save gas fees.
        uint64 balance;
        // Keeps track of mint count for a user of a tokenId.
        uint64 numMinted;
        // Keeps track of burn count for a user of a tokenId.
        uint64 numBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // Compiler will pack this into a single 256bit word.
    struct TokenSupplyData {
        // Keeps track of mint count of a tokenId.
        uint64 numMinted;
        // Keeps track of burn count of a tokenId.
        uint64 numBurned;
        // Keeps track of maximum mintable of a tokenId.
        uint64 tokenMintLimit;
        // Keeps track of the max a single wallet cant mint of a tokenId.
        uint64 walletMintLimit;
    }

    // Used to enable the uri method
    mapping(uint256 => string) public tokenMetadata;

    // Saves all the token mint/burn data and mint limitations.
    mapping(uint256 => TokenSupplyData) private _tokenData;

    // Mapping from token ID to account balances, mints, and burns
    mapping(uint256 => mapping(address => TokenAddressData)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    /* Events */
    event NewTokenAdded(
        uint256 indexed tokenId,
        uint256 tokenMintLimit,
        uint256 walletMintLimit,
        string tokenURI
    );
    event TokenURIChanged(uint256 tokenId, string newTokenURI);
    event NameChanged(string name);
    event SymbolChanged(string symbol);

    /**
     * @dev Removed Zepplin constructor that set uri for the collection because
     * each tokenId will have it's own uri when added.
     */
    constructor() {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev updates the name of the collection
     */
    function _setName(string memory _newName) internal {
        _name = _newName;
        emit NameChanged(_newName);
    }

    /**
     * @dev updates the symbol of the collection
     */
    function _setSymbol(string memory _newSymbol) internal {
        _symbol = _newSymbol;
        emit SymbolChanged(_newSymbol);
    }

    /**
     * @dev Returns if a tokenId has been added to the collection yet.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return bytes(tokenMetadata[tokenId]).length > 0;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (!exists(tokenId)) revert NonExistentToken();
        return tokenMetadata[tokenId];
    }

    /**
     * @dev Allows the owner to add a tokenId to the collection with the specificed
     * metadata and mint limits. NOTE: MINT LIMITS ARE FINAL
     *
     * Requirements:
     *
     * - `tokenId` must not have been added yet.
     * - `metadata` must not be length 0.
     *
     * @param tokenId of the new addition to the colleciton
     * @param walletMintLimit per address for the new collection
     * @param tokenMintLimit for the new token
     * @param metadata for the new collection when calling uri
     */
    function addTokenId(
        uint256 tokenId,
        uint64 tokenMintLimit,
        uint64 walletMintLimit,
        string calldata metadata
    ) external onlyOwner {
        if (exists(tokenId)) revert TokenAlreadyExists();
        if (bytes(metadata).length == 0) revert InvalidMetadata();
        tokenMetadata[tokenId] = metadata;
        _tokenData[tokenId].walletMintLimit = walletMintLimit;
        _tokenData[tokenId].tokenMintLimit = tokenMintLimit;

        emit NewTokenAdded(tokenId, tokenMintLimit, walletMintLimit, metadata);
    }

    /**
     * @dev Allows the owner to change the metadata for a tokenId but NOT the mint limits.
     *
     * Requirements:
     *
     * - `tokenId` must have already been added.
     * - `metadata` must not be length 0.
     */
    function updateMetadata(uint256 tokenId, string calldata metadata)
        external
        onlyOwner
    {
        if (!exists(tokenId)) revert NonExistentToken();
        if (bytes(metadata).length == 0) revert InvalidMetadata();
        tokenMetadata[tokenId] = metadata;

        emit TokenURIChanged(tokenId, metadata);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (account == address(0)) revert BalanceQueryForZeroAddress();
        return _balances[id][account].balance;
    }

    /**
     * @dev returns the total amount of tokens of a certain tokenId are in circulation.
     */
    function totalSupply(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        if (!exists(tokenId)) revert NonExistentToken();
        return _tokenData[tokenId].numMinted - _tokenData[tokenId].numBurned;
    }

    /**
     * @dev returns the total amount of tokens of a certain tokenId that have gotten burned.
     */
    function totalBurned(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        if (!exists(tokenId)) revert NonExistentToken();
        return _tokenData[tokenId].numBurned;
    }

    /**
     * @dev Returns how much an address has minted of a certain id
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function totalMinted(address account, uint256 id)
        public
        view
        virtual
        returns (uint256)
    {
        if (account == address(0)) revert BalanceQueryForZeroAddress();
        return _totalMinted(account, id);
    }

    /**
     * @dev Returns how much an address has minted of a certain id
     */
    function _totalMinted(address account, uint256 id)
        internal
        view
        virtual
        returns (uint256)
    {
        return _balances[id][account].numMinted;
    }

    /**
     * @dev Returns how much an address has minted of a certain id
     *
     * Requirements:
     *
     * - `tokenId` must already exist.
     */
    function totalRemainingMints(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        if (!exists(tokenId)) revert NonExistentToken();
        return _totalRemainingMints(tokenId);
    }

    /**
     * @dev Returns how much an address has minted of a certain id
     */
    function _totalRemainingMints(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return
            _tokenData[tokenId].tokenMintLimit - _tokenData[tokenId].numMinted;
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        if (accounts.length != ids.length) revert ArrayLengthMismatch();

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Verifies if a certain tokenId can still mint `buyAmount` more tokens of a certain id.
     */
    function _verifyTokenMintLimit(uint256 tokenId, uint256 buyAmount)
        internal
        view
    {
        if (
            _tokenData[tokenId].numMinted + buyAmount >
            _tokenData[tokenId].tokenMintLimit
        ) {
            revert OverTokenLimit();
        }
    }

    /**
     * @dev Verifies if a certain wallet can still mint `buyAmount` more tokens of a certain id.
     */
    function _verifyWalletMintLimit(
        address receiver,
        uint256 tokenId,
        uint256 buyAmount
    ) internal view {
        if (
            _tokenData[tokenId].walletMintLimit != 0 &&
            _balances[tokenId][receiver].numMinted + buyAmount >
            _tokenData[tokenId].walletMintLimit
        ) {
            revert OverWalletLimit();
        }
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert NotOwnerOrApproved();
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public virtual override {
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert NotOwnerOrApproved();
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert TransferToZeroAddress();

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        if (_balances[id][from].balance < amount) {
            revert InsufficientTokenBalance();
        }
        // to balance can never overflow because there is a cap on minting
        unchecked {
            _balances[id][from].balance -= uint64(amount);
            _balances[id][to].balance += uint64(amount);
        }

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {
        if (ids.length != amounts.length) revert ArrayLengthMismatch();
        if (to == address(0)) revert TransferToZeroAddress();

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (_balances[id][from].balance < amount) {
                revert InsufficientTokenBalance();
            }
            // to balance can never overflow because there is a cap on minting
            unchecked {
                _balances[id][from].balance -= uint64(amount);
                _balances[id][to].balance += uint64(amount);
            }
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * NOTE: In order to save gas fees when there are many transactions nearing the mint limit of a tokenId,
     * we do NOT call `_verifyTokenMintLimit` and instead leave it to the external method to do this check.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _verifyWalletMintLimit(to, id, amount);
        unchecked {
            _tokenData[id].numMinted += uint64(amount);
            _balances[id][to].balance += uint64(amount);
            _balances[id][to].numMinted += uint64(amount);
        }
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (ids.length != amounts.length) revert ArrayLengthMismatch();

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _verifyTokenMintLimit(ids[i], amounts[i]);
            _verifyWalletMintLimit(to, ids[i], amounts[i]);
            // The above verifications will check for potential overflow/underflow as well
            unchecked {
                _tokenData[ids[i]].numMinted += uint64(amounts[i]);
                _balances[ids[i]][to].balance += uint64(amounts[i]);
                _balances[ids[i]][to].numMinted += uint64(amounts[i]);
            }
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) revert BurnFromZeroAddress();
        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        uint256 fromBalance = _balances[id][from].balance;
        if (fromBalance < amount) revert InsufficientTokenBalance();
        unchecked {
            _balances[id][from].numBurned += uint64(amount);
            _balances[id][from].balance = uint64(fromBalance - amount);
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal virtual {
        if (from == address(0)) revert BurnFromZeroAddress();
        if (ids.length != amounts.length) revert ArrayLengthMismatch();

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from].balance;
            if (fromBalance < amount) revert InsufficientTokenBalance();
            unchecked {
                _balances[id][from].numBurned += uint64(amount);
                _balances[id][from].balance = uint64(fromBalance - amount);
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (owner == operator) revert ApprovalToCurrentOwner();
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert TransferToNonERC721ReceiverImplementer();
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert TransferToNonERC721ReceiverImplementer();
            }
        }
    }

    /**
     * @dev helper method to turn a uint256 variable into a 1-length array we can pass into uint256[] variables
     */
    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
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
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
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
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(
                vs,
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            v := add(shr(255, vs), 27)
        }
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
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
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
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * ERC165 bytes to add to interface array - set in parent contract
     * implementing this standard
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     * bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
     * _registerInterface(_INTERFACE_ID_ERC2981);
     */

    /**
     * @notice Called with the sale price to determine how much royalty
     *          is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

import "./Context.sol";

error CallerNotOwner();
error OwnerNotZero();

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
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        if (owner() != _msgSender()) revert CallerNotOwner();
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
        if (newOwner == address(0)) revert OwnerNotZero();
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
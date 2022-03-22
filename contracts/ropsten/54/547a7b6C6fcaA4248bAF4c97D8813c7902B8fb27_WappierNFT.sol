// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
pragma abicoder v2;

import "./WP721Marketplace.sol";
import "./WappierResettable.sol";

// Wappiers smart contract inherits ERC721 interface
contract WappierNFT is WP721Marketplace, WappierResettable {
    /** @dev The user readable name of the signing domain. This is the first parameter of the EIP712 constructor. */
    string private constant SIGNING_DOMAIN = "Wappier-NFT-Voucher";
    /** @dev The current major version of the signing domain. This is the second parameter of the EIP712 constructor. */
    string private constant SIGNATURE_VERSION = "1";

    /**
     * @dev Initializes the contract by calling the WP721Marketplace constructor passing:
     * - The address of the `minter`.
     * - The `baseURI`.
     * - The collection name of NFTs.
     * - The collection symbol of NFTs.
     * - The signing domain.
     * - The version of the signing domain.
     *
     * @param minter The address that will have the minter role
     * @param baseURI The base URI automatically added as a prefix in tokenURI to each token’s URI, or to the token ID if no specific URI is set for that token ID.
     */
    constructor(address payable minter, string memory baseURI, address[] memory payees, uint256[] memory shares_)
        WP721Marketplace(
            minter,
            baseURI,
            "Wappiers Collection",
            "WP",
            SIGNING_DOMAIN,
            SIGNATURE_VERSION,
            payees,
            shares_
        )
    {}

    function resetContractData(
        uint256 requestId,
        uint256[] calldata tokenIds,
        string[] calldata tokenNames,
        uint256[] calldata auctionIds,
        string[] calldata voucherIds
    ) external override {
        require(hasRole(MINTER_ROLE, msg.sender), "Sender has not minter role");
        require(tokenIds.length == tokenNames.length, "The token ids and token names are not matching");
        for (uint256 index = 0; index < tokenIds.length; index++) {
            delete allWappierNFTs[tokenIds[index]];
            delete tokenNameExists[tokenNames[index]];
            delete isTokenForSale[tokenIds[index]];
            _burn(tokenIds[index]);
        }

        for (uint256 index = 0; index < auctionIds.length; index++) {
            delete auctionIdExists[auctionIds[index]];
            delete allDutchActions[auctionIds[index]];
        }

        for (uint256 index = 0; index < voucherIds.length; index++) {
            delete voucherIdExists[voucherIds[index]];
        }

        emit Reset(requestId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
pragma abicoder v2;

interface WappierResettable {
    event Reset(uint256 indexed requestId);

    function resetContractData(
        uint256 requestId,
        uint256[] calldata tokenIds,
        string[] calldata tokenNames,
        uint256[] calldata auctionIds,
        string[] calldata voucherIds
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title WWPaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `WPaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 */
contract WPaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PayeeRemoved(address account);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev Creates an instance of `WPaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "WPaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "WPaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Setter for the amount of shares held by `index` payee.
     * @param index The index of payee in `_payees`.
     * @param newShare The number of new shares owned by the payee.
     */
    function _setShares(uint256 index, uint256 newShare) internal virtual {
        address account = _payees[index];
        _totalShares = _totalShares - _shares[account] + newShare;
        _shares[account] = newShare;
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function _release(address payable account) internal virtual {
        require(_shares[account] > 0, "WPaymentSplitter: account has no shares");

        uint256 payment = _pendingPayment(account);

        require(payment != 0, "WPaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to all payees of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function _releaseAll() internal virtual {
        for (uint i = 0; i < _payees.length; i++){
            address account = _payees[i];
            uint256 payment = _pendingPayment(account);
            if (payment != 0) {
                _released[account] += payment;
                _totalReleased += payment;

                Address.sendValue(payable(account), payment);
                emit PaymentReleased(account, payment);
            }
        }
    }    

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(address account) internal view returns (uint256) {
        uint256 totalReceived = address(this).balance + _totalReleased;
        return (totalReceived * _shares[account]) / _totalShares - released(account);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) internal virtual {
        require(account != address(0), "WPaymentSplitter: account is the zero address");
        require(shares_ > 0, "WPaymentSplitter: shares are 0");
        require(_shares[account] == 0, "WPaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev Remove the address of the payee number `index` from the contract.
     */
    function _removePayee(uint256 index) internal virtual {
        address account = _payees[index];
        _totalShares = _totalShares - _shares[account];
        delete _shares[account];
        _payees[index] = _payees[_payees.length - 1];
        _payees.pop();
        emit PayeeRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
pragma abicoder v2;

// import ERC721 iterface
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Wappiers smart contract inherits ERC721 interface
abstract contract WPERC721 is ERC721URIStorage, AccessControl {
    /**
     * @notice A unique 32 byte hash that represents the minter role.
     * @dev keccak256() is a cryptographic function built into solidity that takes in any amount of inputs and converts it to 32 byte hash.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using Counters for Counters.Counter;

    /** @dev The total number of wappiers minted. It determines the given token IDs. */
    Counters.Counter private _currTokenId;

    /** @dev the base URI set via _setBaseURI. This will be automatically added as a prefix in tokenURI to each token’s URI, or to the token ID if no specific URI is set for that token ID. */
    string public baseTokenURI;

    /** @dev Represents a minted NFT.*/
    struct WappierNFT {
        uint256 price;
        uint256 numberOfTransfers;
        string tokenName;
        address mintedBy;
        address payable currentOwner;
        address previousOwner;
    }

    /** @dev Mapping from token ID to WappierNFT struct */
    mapping(uint256 => WappierNFT) public allWappierNFTs;
    /** @dev Mapping from token name to whether exists or not */
    mapping(string => bool) public tokenNameExists;

    /** @dev Emitted when `mintedBy` mints the `tokenId` token with `tokenName` name, `tokenURI` uri and the current owner is `to` */
    event Mint(
        address indexed mintedBy,
        address indexed to,
        uint256 indexed tokenId,
        string tokenName,
        string tokenURI
    );

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     * Sets up the `MINTER_ROLE` of the `minter`.
     * Sets the `baseTokenURI` to `baseURI`.
     *
     * @param minter The address that will have the minter role
     * @param baseURI The base URI automatically added as a prefix in tokenURI to each token’s URI, or to the token ID if no specific URI is set for that token ID.
     * @param collectionName The collection name
     * @param collectionSymbol The collection symbol
     */
    constructor(
        address payable minter,
        string memory baseURI,
        string memory collectionName,
        string memory collectionSymbol
    ) ERC721(collectionName, collectionSymbol) {
        _setupRole(MINTER_ROLE, minter);
        baseTokenURI = baseURI;
    }

    /**
     * @dev Sets the base URI for all token IDs.
     * It is automatically added as a prefix to the value returned in tokenURI, or to the token ID if tokenURI is empty.
     *
     * Requirements:
     * - Only authorized minter role can pause
     *
     */
    function setBaseURI(string memory baseURI) external {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Only authorized minter role can set a new baseURI"
        );
        baseTokenURI = baseURI;
    }

    // override function
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

     /**
     * @dev Mints `wnft.tokenId` and transfers it to `wnft.mintedBy`.
     *
     * It adds the `WappierNFT` struct to `allWappierNFTs` mapping,
     * makes `wnft.tokenURI` and `wnft.tokenName` as exists,
     * calls ERC721 `_mint()`,
     * sets the metadata by calling ERC721Storage `_setTokenURI()`.
     *
     * Emits a {Mint} event.
     *
     * @param wnft A WappierNFT struct.
     */
    function _mintNFT(WappierNFT memory wnft) internal {
        _currTokenId.increment();
        uint256 tokenId = _currTokenId.current();

        // first assign the token to the signer, to establish provenance on-chain
        // add the token id and it's WJMC to all WJMCNFTs mapping
        allWappierNFTs[tokenId] = wnft;

        // make token name passed as exists
        tokenNameExists[wnft.tokenName] = true;

        _safeMint(wnft.mintedBy, tokenId, "");
        _setTokenURI(tokenId, Strings.toString(tokenId));

        string memory tokenURI_ = tokenURI(tokenId);

        // make msg.sender passed token URI as exists

        // emit mint event
        emit Mint(wnft.mintedBy, wnft.currentOwner, tokenId, wnft.tokenName, tokenURI_);

    }

    /**
     * @dev Returns the chain id of the current blockchain.
     * This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
     * the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
     */
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

     function wappierCounter() public view returns(uint256) {
        return _currTokenId.current();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

abstract contract WPEIP712 is EIP712 {
    /** @dev Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function. */
    struct NFTVoucher {
        string id;
        string tokenName;
        address eligibleWallet;
        uint256 price;
        uint256 expires_at;
        uint256 auctionId;
        uint256 saleId;
        bytes signature;
    }

    /**
     * @dev Initializes the contract by setting domain separator and parameter caches of EIP712 contract.
     *
     * @param signingDomain The domain name
     * @param signatureVersion The signature version
     */
    constructor(string memory signingDomain, string memory signatureVersion)
        EIP712(signingDomain, signatureVersion)
    {}

    /**
     * @dev Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
     * @param voucher An `NFTVoucher` to hash.
     */
    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(string id,string tokenName,uint256 auctionId,uint256 saleId,address eligibleWallet,uint256 price,uint256 expires_at)"
                        ),
                        keccak256(bytes(voucher.id)),
                        keccak256(bytes(voucher.tokenName)),
                        voucher.auctionId,
                        voucher.saleId,
                        voucher.eligibleWallet,
                        voucher.price,
                        voucher.expires_at
                    )
                )
            );
    }

    /**
     * @dev Verifies the signature for a given NFTVoucher, returning the address of the signer.
     * Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
     * @param voucher An `NFTVoucher` describing an unminted NFT.
     */
    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
pragma abicoder v2;

// import wappier abstract contracts
import "./WPEIP712.sol";
import "./WPERC721.sol";
import "./WPaymentSplitter.sol";

import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract WP721Marketplace is WPEIP712, WPERC721, WPaymentSplitter, Pausable {

    /** @dev Represents a Dutch auction, a market where prices generally start high and incrementally drop until a bidder accepts the going price. */
    struct DutchAuction {
        uint256 auctionId;
        uint256 startingPrice;
        uint256 endingPrice;
        uint256 startAt; // in seconds
        uint256 expiresAt; // in seconds
        uint256 priceDropStep;
        uint256 priceDropFreq; // in seconds
        bool active;
    }

    /** @dev Royalty Percentage tax*/
    uint256 private royaltyPercentageTax = 0;

    /** @dev Mapping from auction ID to DutchAuction struct */
    mapping(uint256 => DutchAuction) public allDutchActions;
    /** @dev Mapping from voucher ID to whether exists or not */
    mapping(string => bool) public voucherIdExists;
    /** @dev Mapping from auction ID to whether exists or not */
    mapping(uint256 => bool) public auctionIdExists;
    /** @dev Mapping from token ID to whether is for sale or not or not */
    mapping(uint256 => bool) public isTokenForSale;
    /** @dev Emitted when `auctionId` auction starts */
    event DutchAuctionStarted(uint256 indexed auctionId);
    /** @dev Emitted when `auctionId` auction ends */
    event DutchAuctionEnded(uint256 indexed auctionId);
    /** @dev Emitted when `isTokenForSale` changes to true */
    event PlacedForSale(uint256 indexed tokenId, uint256 price);
    /** @dev Emitted when `isTokenForSale` changes to false */
    event RemovedFromSale(uint256 indexed tokenId);

    /**
     * @dev Initializes the contract by by calling the constructors of the inherited contracts.
     *
     * @param minter The address that will have the minter role
     * @param baseURI The base URI automatically added as a prefix in tokenURI to each token’s URI, or to the token ID if no specific URI is set for that token ID.
     * @param collectionName The collection name
     * @param collectionSymbol The collection symbol
     * @param domainName The domain name
     * @param signatureVersion The signature version
     */
    constructor(
        address payable minter,
        string memory baseURI,
        string memory collectionName,
        string memory collectionSymbol,
        string memory domainName,
        string memory signatureVersion,
        address[] memory payees, 
        uint256[] memory shares_
    )
        WPERC721(minter, baseURI, collectionName, collectionSymbol)
        WPEIP712(domainName, signatureVersion)
        WPaymentSplitter(payees, shares_)
    {}

    /**
     * @dev Mints `++wappierCounter` token and transfers it to the caller.
     *
     * It creates the `WappierNFT` struct and calls `_mintNFT()`.
     *
     * Requirements:
     * - The caller must have `MINTER_ROLE`.
     * - `_name` must not exist.
     *
     * Emits a {Mint} event.
     *
     * @param _name The name of the token.
     * @param _price The price of the token to be sold.
     */
    function mintWappier(string calldata _name, uint256 _price) external whenNotPaused {
        require(hasRole(MINTER_ROLE, msg.sender), "Sender has not minter role");
        require(!tokenNameExists[_name], "This token name already exists");

        // create a new wappier (struct) and pass in new values
        WappierNFT memory newWappier = WappierNFT(
            _price,
            0,
            _name,
            payable(msg.sender),
            payable(msg.sender),
            payable(address(0))
        );

        _mintNFT(newWappier);
    }

    /**
     * @dev Returns whether `tokenId` exists by calling ERC721 `_exists()`.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     *
     * @param _tokenId The token ID.
     * @return true if `_tokenId` token exists, otherwise false.
     */
    function getTokenExists(uint256 _tokenId) external view whenNotPaused returns (bool) {
        bool tokenExists = _exists(_tokenId);
        return tokenExists;
    }

    /**
     * @dev Transfers `tokenId` from current owner `sendTo` to the caller and
     * sends `msg.value` of ethers to the `sendTo`.
     *
     * It creates the `WappierNFT` struct and calls `_mintNFT()`.
     *
     * Requirements:
     * - The caller cannot be the zero address.
     * - `tokenId` must exist.
     * - The caller cannot be the owner of the token.
     * - The sending value `msg.value` of ethers should be greater or equal than the `wappier.price`.
     * - The token must be for sale.
     *
     * @param _tokenId The token ID to transfer.
     */
    function buyToken(uint256 _tokenId) external payable whenNotPaused {
        require(msg.sender != address(0), "Sender is a zero address account");
        require(_exists(_tokenId), "This tokenId does not exist");
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner != msg.sender, "Sender address is same as the token owner");

        // get that token from all wappiers mapping and create a memory of it defined as (struct => Wappier)
        WappierNFT memory wappier = allWappierNFTs[_tokenId];
        require(msg.value >= wappier.price, "Insufficient funds to buy token");
        require(isTokenForSale[_tokenId] == true, "Token is not for sale");

        // get owner of the token
        address payable sendTo = wappier.currentOwner;
        // update the token's previous owner
        wappier.previousOwner = wappier.currentOwner;
        // update the token's current owner
        wappier.currentOwner = payable(msg.sender);
        // update the how many times this token was transfered
        wappier.numberOfTransfers += 1;
        //set the token for Sale to false after changing owner
        isTokenForSale[_tokenId] = false;
        // set and update that token in the mapping
        allWappierNFTs[_tokenId] = wappier;

        uint256 ethToTransfer = _calculateRoyaltyTax(wappier, msg.value);

        // transfer the token from owner to the caller of the function (buyer)
        _safeTransfer(tokenOwner, msg.sender, _tokenId, "");

        // send token's worth of ethers to the owner
        sendTo.transfer(ethToTransfer);
    }

    /**
     * @dev Changes the price of `_tokenId` token to `_newPrice`.
     *
     * It gets the `WappierNFT` struct, assigns its `price` field with `_newPrice`,
     * sets the `_tokenId` token for sale and updates the `allWappierNFTs` mapping.
     *
     * Requirements:
     * - The caller cannot be the zero address.
     * - `tokenId` must exist.
     * - The caller must own the token.
     *
     * @param _tokenId The token ID to change its price.
     * @param _newPrice The new price of `_tokenId` token.
     */
    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice) external whenNotPaused {
        require(msg.sender != address(0), "Sender is a zero address account");
        require(_exists(_tokenId), "Token id does not exist");
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender, "Only token owner can change price");

        // get that token from all wappiers mapping and create a memory of it defined as (struct => Wappier)
        WappierNFT memory wappier = allWappierNFTs[_tokenId];
        // update token's price with new price
        wappier.price = _newPrice;
        //set the token for sale to true after changing the price
        isTokenForSale[_tokenId] = true;
        // set and update that token in the mapping
        allWappierNFTs[_tokenId] = wappier;

        emit PlacedForSale(_tokenId, _newPrice);
    }

    /**
     * @dev Removes token from sale for `_tokenId` token.
     *
     * It updates the isTokenForSale mapping for respective tokenId to false.
     *
     * Requirements:
     * - The caller cannot be the zero address.
     * - `tokenId` must exist (this is checked inside ERC721.ownerOf).
     * - The caller must own the token.
     *
     * @param _tokenId The token ID to remove from sale.
     */
    function removeTokenFromSale(uint256 _tokenId) external whenNotPaused {
        require(msg.sender != address(0), "Sender is a zero address account");
        require(_exists(_tokenId), "This tokenId does not exist");
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner == msg.sender, "Only token owner can remove from sale");

        //set the token for sale to false
        isTokenForSale[_tokenId] = false;

        emit RemovedFromSale(_tokenId);
    }

    /**
     * @dev Redeems an `NFTVoucher` for an actual NFT, minting `++wappierCounter` token and transfering it
     * first to the `signer` and then to the caller, using Dutch auction style.
     *
     * It verifies the `voucher` by getting the `signer`, creates the `WappierNFT` struct,
     * makes `voucher.id` as exists, calls `_mintNFT()` and
     * increases the pending withdrawal balance of the `signer` by `msg.value`.
     *
     * Requirements:
     * - `voucher.tokenName` must not exist.
     * - `voucher.id` must not exist.
     * - The caller must be the `voucher.eligibleWallet`.
     * - `voucher.auctionId` must exist.
     * - `voucher.auctionId` auction must be active.
     * - The current datetime must be before `voucher.expires_at` datetime.
     * - The current datetime must be before `auction.expiresAt` datetime.
     * - The current datetime must be after `auction.startAt` datetime.
     * - `msg.value` must be greater or equal than `voucher.price`.
     * - `signer` must have `MINTER_ROLE`.
     *
     * Emits a {Mint} event.
     *
     * @param voucher A signed `NFTVoucher` that describes the token to be redeemed.
     */
    function redeemDutchAuctionVoucher(NFTVoucher calldata voucher) external payable whenNotPaused {
        require(!tokenNameExists[voucher.tokenName], "This token name already exists");
        require(!voucherIdExists[voucher.id], "This Voucher id already exists");
        require(
            voucher.eligibleWallet == msg.sender,
            "You are not eligible to redeem this voucher"
        );
        require(auctionIdExists[voucher.auctionId], "Auction does not exist");
        DutchAuction memory auction = allDutchActions[voucher.auctionId];
        require(auction.active, "Auction is inactive");
        require(block.timestamp < voucher.expires_at, "Voucher expired");
        require(block.timestamp < auction.expiresAt, "Auction expired");
        require(block.timestamp > auction.startAt, "Auction has not started yet");

        require(msg.value >= voucher.price, "Insufficient funds to redeem voucher");
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
        require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");

        // create a new WJMC (struct) and pass in new values
        WappierNFT memory newNft = WappierNFT(
            voucher.price,
            1,
            voucher.tokenName,
            payable(signer),
            payable(msg.sender),
            payable(signer)
        );

        voucherIdExists[voucher.id] = true;

        // mint token
        _mintNFT(newNft);

        // transfer the token to the redeemer
        _safeTransfer(signer, msg.sender, wappierCounter(), "");
    }

    /**
     * @dev Redeems an `NFTVoucher` for an actual NFT, minting `++wappierCounter` token and transfering it
     * first to the `signer` and then to the caller.
     *
     * It verifies the `voucher` by getting the `signer`, creates the `WappierNFT` struct,
     * makes `voucher.id` as exists, calls `_mintNFT()` and
     * increases the pending withdrawal balance of the `signer` by `msg.value`.
     *
     * Requirements:
     * - `voucher.tokenName` must not exist.
     * - `voucher.id` must not exist.
     * - The caller must be the `voucher.eligibleWallet`.
     * - `signer` must have `MINTER_ROLE`.
     * - `msg.value` must be greater or equal than `voucher.price`.
     * - The current datetime must be before `voucher.expires_at` datetime.
     *
     * Emits a {Mint} event.
     *
     * @param voucher A signed `NFTVoucher` that describes the token to be redeemed.
     */
    function redeemVoucher(NFTVoucher calldata voucher) external payable whenNotPaused {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
        require(!tokenNameExists[voucher.tokenName], "This token name already exists");
        require(!voucherIdExists[voucher.id], "This Voucher id already exists");
        require(
            voucher.eligibleWallet == msg.sender,
            "You are not eligible to redeem this voucher"
        );
        // make sure that the signer is authorized to mint NFTs
        require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");
        require(msg.value >= voucher.price, "Insufficient funds to redeem voucher");
        require(block.timestamp <= voucher.expires_at, "Voucher has expired");

        // create a new wappier (struct) and pass in new values
        WappierNFT memory newWappier = WappierNFT(
            voucher.price,
            1,
            voucher.tokenName,
            payable(signer),
            payable(msg.sender),
            payable(signer)
        );

        voucherIdExists[voucher.id] = true;

        _mintNFT(newWappier);

        // transfer the token to the redeemer
        _safeTransfer(signer, msg.sender, wappierCounter(), "");
    }

    /**
     * @dev Starts the `auctionId` Dutch auction.
     *
     * It creates the `DutchAuction` struct and updates the `auctionIdExists` and `allDutchActions` mappings.
     *
     * Requirements:
     * - The caller must have `MINTER_ROLE`.
     * - `auctionId` must not already exist.
     * - `startingPrice` must be greater than `endingPrice`.
     * - `endDate` timestamp must be greater than `startDate` timestamp.
     *
     * Emits a {DutchAuctionStarted} event.
     *
     * @param auctionId The auction ID of the auction to start.
     * @param startingPrice The starting price of the auction.
     * @param endingPrice The ending price of the auction.
     * @param startDate The timestamp of auction to start.
     * @param endDate The timestamp of auction to end.
     * @param priceDropStep The step that auction's token price drops.
     * @param priceDropFreq The frequency that auction's token price drops.
     */
    function startDutchAuction(
        uint256 auctionId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 startDate,
        uint256 endDate,
        uint256 priceDropStep,
        uint256 priceDropFreq
    ) external whenNotPaused {
        require(hasRole(MINTER_ROLE, msg.sender), "Sender has not minter role");
        require(!auctionIdExists[auctionId], "This Dutch auction is already started");
        require(startingPrice > endingPrice, "Ending price is more than starting price");
        require(endDate > startDate, "Ending date < startDate");

        //TODO: Do we need any check on price drops?

        // Do we need this to be a linearly stepped price drop function that ends exactly on endingPrice??
        // int256 priceDiff = int256(startingPrice)-int256(endingPrice);
        // int256 totalPriceDrop = int256(((endDate-startDate)/priceDropFreq)*priceDropStep);
        // require(priceDiff - totalPriceDrop == 0, "Price diff should equal total price drop");

        auctionIdExists[auctionId] = true;

        DutchAuction memory auction = DutchAuction(
            auctionId,
            startingPrice,
            endingPrice,
            startDate,
            endDate,
            priceDropStep,
            priceDropFreq,
            true
        );

        allDutchActions[auctionId] = auction;

        // emit DutchAuctionStarted event
        emit DutchAuctionStarted(auctionId);
    }

    /**
     * @dev Ends the `auctionId` Dutch auction.
     *
     * Deactivates the `auctionId` auction by setting `auction.active` to `false`.
     *
     * Requirements:
     * - The caller must have `MINTER_ROLE`.
     * - `auctionId` must exist.
     *
     * Emits a {DutchAuctionEnded} event.
     *
     * @param auctionId The auction ID of the auction to end.
     */
    function endDutchAuction(uint256 auctionId) external whenNotPaused {
        require(hasRole(MINTER_ROLE, msg.sender), "Sender has not minter role");
        require(auctionIdExists[auctionId], "This Dutch auction does not exist");

        DutchAuction memory auction = allDutchActions[auctionId];
        auction.active = false;
        allDutchActions[auctionId] = auction;

        emit DutchAuctionEnded(auctionId);
    }


    /**
     * @dev Gets the data of `auctionId` Dutch auction.
     *
     * `timePassed` is the time passed from the start of the auction.
     * `totalDrops` is the number of times for auction's token price to drop.
     * `totalDropValue` is the the total value for auction's token price to drop.
     * `curPrice` is the new auction's token price that occurs after the price drop.
     * If `curPrice` is less or equal than `auction.endingPrice`, then the auction has reached its ending price.
     * Otherwirse, the `nextPriceDropTs` and the `nextPrice` are calculated and finally returned.
     *
     * Requirements:
     * - The caller must have `MINTER_ROLE`.
     * - `auctionId` must exist.
     * - The auction must be active.
     * - The auction must not have been expired.
     * - The auction must have been started.
     *
     * Emits a {DutchAuctionEnded} event.
     *
     * @param auctionId The auction ID of the auction to get data from.
     *
     * @return (uint256, uint256, uint256) The current price of auction's token, the
     */
    function getDutchAuctionData(uint256 auctionId)
        external
        view
        whenNotPaused
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(hasRole(MINTER_ROLE, msg.sender), "Sender has not minter role");
        require(auctionIdExists[auctionId], "This Dutch auction does not exist");
        DutchAuction memory auction = allDutchActions[auctionId];
        require(auction.active, "Auction is inactive");
        require(block.timestamp < auction.expiresAt, "Auction expired");
        require(block.timestamp > auction.startAt, "Auction has not started yet");

        uint256 timePassed = uint256(int256(block.timestamp) - int256(auction.startAt));
        uint256 totalDrops = uint256(timePassed) / auction.priceDropFreq;
        uint256 totalDropValue = totalDrops * auction.priceDropStep;
        int256 curPrice = int256(int256(auction.startingPrice) - int256(totalDropValue));
        if (curPrice <= int256(auction.endingPrice))
            return (auction.endingPrice, 0, auction.endingPrice);

        uint256 nextPriceDropTs = uint256(
            int256(auction.startAt) + int256((totalDrops + 1) * auction.priceDropFreq)
        );
        int256 nextPrice = curPrice - int256(auction.priceDropStep);
        return (uint256(curPrice), nextPriceDropTs, uint256(nextPrice));
    }

    /**
     * @dev Transfers all pending withdrawal balance to the caller. Reverts if the caller is not a payee.
     */
    function withdraw() external whenNotPaused {
        _release(payable(msg.sender));
    }

    /**
     * @dev Transfers all pending withdrawal balance to the payees. Reverts if the caller is not an authorized minter.
     */
    function withdrawAll() external whenNotPaused onlyRole(MINTER_ROLE) {
        _releaseAll();
    }

    /**
     * @dev Retuns the amount of Ether available to the caller to withdraw.
     * @return The pending withdrawal balance of the caller.
     */
    function availableToWithdraw() external view whenNotPaused returns (uint256) {
        return _pendingPayment(msg.sender);
    }

    /**
     * @dev Adds `account` as payee with shares `shares_`. Reverts if the caller is not an authorized minter.
     */
    function addPayee(address account, uint256 shares_) external whenNotPaused onlyRole(MINTER_ROLE) {
        _addPayee(account, shares_);
    }

    /**
     * @dev Removes a `index` payee. Reverts if the caller is not an authorized minter.
     */
    function removePayee(uint256 index) external whenNotPaused onlyRole(MINTER_ROLE) {
        _removePayee(index);
    }

    /**
     * @dev Sets `newShare` as shares to `index` payee. Reverts if the caller is not an authorized minter.
     */
    function setShares(uint256 index, uint256 newShare) external whenNotPaused onlyRole(MINTER_ROLE) {
        _setShares(index, newShare);
    }

    /**
     * @dev Sets the `royaltyPercentageTax`.
     *
     * Requirements:
     * - Only authorized minters can set royalty percentage.
     * - `_percentage` must be below 100.
     *
     * @param _percentage The new percentage assigned to `royalyPecentageTax`.
     */
    function setRoyaltyPercentage(uint256 _percentage) external {
        require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minters can set royalty");
        require(_percentage < 100, "Percentage must be bellow 100");

        royaltyPercentageTax = _percentage;
    }

    /**
     * @dev Retuns the `royaltyPercentageTax`.
     *
     * Requirements:
     * - Only authorized minters can get royalty percentage.
     *
     * @return (uint256) The `royaltyPercentageTax`.
     */
    function getRoyaltyPercentage() external view returns (uint256) {
        require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minters can get royalty");
        return royaltyPercentageTax;
    }

    /**
     * @dev Triggers stop state.
     *
     * Requirements:
     * - The contract must not be paused.
     * - Only authorized minter role can pause
     *
     */
    function pause() external whenNotPaused {
        require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minter role can pause");
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     * - The contract must be paused.
     * - Only authorized minter role can pause
     *
     */
    function unpause() external whenPaused {
        require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minter role can unpause");
        _unpause();
    }

    /**
     * @dev Calculates the royalty tax given `wappier` `WappierNFT` struct and `ethToTransfer`.
     *
     * If `royaltyPercentageTax` is set and `wappier.numberOfTransfers` is greater that 2, that is the case when the creator of the
     * token has a royalty amount of ether for each token's ownership transfer. The percentage is calculated using the `royaltyPercentageTax`.
     *
     * @param wappier The WappierNFT to calculate royalty tax for.
     * @param ethToTransfer The msg.value eth to transfer.
     *
     * @return (uint256) The eth to transfer decremented by calculated `tax`, if it is the case.
     */
    function _calculateRoyaltyTax(WappierNFT memory wappier, uint256 ethToTransfer)
        internal
        view
        returns (uint256)
    {
        if (royaltyPercentageTax > 0 && wappier.numberOfTransfers >= 2) {
            uint256 tax = uint256((int256(ethToTransfer) * int256(royaltyPercentageTax)) / 100);
            return uint256(int256(ethToTransfer) - int256(tax));
        }
        return ethToTransfer;
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../Interface/IVizvaLazyNFT.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract VizvaMarket_V1 is
    EIP712Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    /**
    @dev Struct represent the details of an market order
    Note: 
        uint8 saleType; //Used as an Identifier; 1 for instantSale 2 for Auction
        TokenData tokenData; //Struct contains the details of an NFT.
     */
    struct SaleOrder {
        bool isSold; // shows whether the sale is completed or not.
        bool cancelled; // shows whether the sale is cancelled or not.
        uint8 saleType; //Used as an Identifier; 1 for instantSale 2 for Auction.
        uint256 askingPrice; // the minimum price set by the seller for an NFT.
        uint256 id; //unique id of the sale
        address seller; //address of the seller.
        TokenData tokenData; //struct contains the details of an NFT.
    }

    /**
    @dev Struct represent the details of an NFT.
    Note:
        uint256 amount => Included for the support of ERC1155. Value Should be 1 for ERC721 Token.
     */
    struct TokenData {
        uint8 tokenType; // Used as an Identifier; value = 1 for ERC721 Token & 2 for ERC1155 Token.
        uint16 royalty; // percentage of share for creator.
        uint256 tokenId; //id of NFT
        uint256 amount; //amount of NFT on sale.
        address tokenAddress; // NFT smartcontract address.
        address creator; // address of the creator of the NFT.
    }

    /**
    @dev Struct represents the details of Bidvoucher.
     */
    struct BidVoucher {
        address asset; //address of the token used to exchange NFT.
        address tokenAddress; //NFT smartcontract address.
        uint256 tokenId; //id of the token
        uint256 marketId; //Id of the sale for wich bid placed.
        uint256 bid; //the bidded amount.
        bytes signature; //EIP-712 signature by the bidder.
    }

    /** 
    @dev Represents an un-minted NFT, which has not yet been recorded into the blockchain.
        A signed voucher can be redeemed for a real NFT using the redeem function.
    */
    struct NFTVoucher {
        uint256 tokenId;
        uint256 minPrice;
        uint16 royalty;
        string uri;
        address tokenAddress;
        bytes signature;
    }

    string private constant SIGNING_DOMAIN = "VIZVA_MARKETPLACE";
    string private constant SIGNATURE_VERSION = "1";

    // address to which withdraw function transfers funds.
    address internal WALLET;

    // Represent the percentage of share, contract recieve as commission on
    // every NFT sale. Value should be entered as multiplied with 10 to avoid
    // precision error. Commission 2.5% should be added as 25.
    uint16 public commission;

    SaleOrder[] public itemsForSale; // contains array of all Items put on sale.
    mapping(address => mapping(uint256 => bool)) activeItems; // contains all active Items

    /**
     * @dev Emitted when new Item added using _addItemToMarket function
     */
    event itemAdded(
        uint256 id,
        uint256 tokenId,
        uint256 askingPrice,
        uint16 royalty,
        address tokenAddress,
        address creator
    );
    /**
     * @dev Emitted when an Item is sold,` price` contains 3 different values
     * total value, the value received by the seller, value received by creator
     */
    event itemSold(uint256 id, address buyer, uint256[3] price, address asset);

    /**
    @dev represent the event emited after redeeming a voucher
     */
    event NFTRedeemed(
        uint256 minPrice,
        uint256 tokenId,
        address tokenAddress,
        address creator,
        address buyer
    );

    /**
     * @dev Emitted when an Item Sale cancelled.
     */
    event saleCancelled(uint256 id);

    // prevent intialization of logic contract.
    constructor() initializer {}

    /**
     * @dev initialize the Marketplace contract.
     * setting msg sender as owner.
     * @param
     *  _wallet - address to withdraw MATIC.
     * SIGNING_DOMAIN {EIP712}
     * SIGNATURE_VERSION {EIP712}
     * Note:initializer modifier is used to prevent initialization of contract twice.
     */
    function __VizvaMarket_init(
        uint16 _commission,
        address _wallet
    ) public initializer {
        __EIP712_init_unchained(SIGNING_DOMAIN, SIGNATURE_VERSION);
        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __VizvaMarket_init_unchained(_wallet, _commission);
    }

    function __VizvaMarket_init_unchained(address _wallet, uint16 _commission)
        internal
        onlyInitializing
    {
        WALLET = _wallet;
        commission = _commission;
    }

    /**
    @dev Modifier to restrict function access only to NFT Owner.
     */
    modifier OnlyItemOwner(address tokenAddress, uint256 tokenId) {
        IERC721Upgradeable tokenContract = IERC721Upgradeable(tokenAddress);
        require(
            tokenContract.ownerOf(tokenId) == _msgSender(),
            "Only Item owner alowed to list in market"
        );
        _;
    }

    /**
    @dev Modifier to check whether this contract has transfer approval.
     */
    modifier HasNFTTransferApproval(
        address tokenAddress,
        uint256 tokenId,
        address sender
    ) {
        IERC721Upgradeable tokenContract = IERC721Upgradeable(tokenAddress);
        require(
            tokenContract.getApproved(tokenId) == address(this) ||
                tokenContract.isApprovedForAll(sender, address(this)),
            "token transfer not approved"
        );
        _;
    }

    /**
    @dev Modifier to check whether Item sales exist.
     */
    modifier ItemExists(uint256 id) {
        require(
            id < itemsForSale.length && itemsForSale[id].id == id,
            "Could not find requested item"
        );
        _;
    }

    /**
    @dev Modifier to check whether `id` exists for sale.
     */
    modifier IsForSale(uint256 id) {
        require(itemsForSale[id].isSold == false, "Item is already sold!");
        _;
    }

    /**
    @dev Modifier to check whether `id` sale cancelled or not.
     */
    modifier IsCancelled(uint256 id) {
        //checking if already cancelled
        require(
            itemsForSale[id].cancelled == false,
            "Item sale already cancelled"
        );
        _;
    }

    /**
    @dev external function to withdraw MATIC received as commission.
    @param amount - this much token will be transferred to WALLET.
     */
    function withdraw(uint256 amount) external virtual onlyOwner nonReentrant {
        // checking if amount is less than available balance.
        require(
            address(this).balance <= amount,
            "amount should be less than avalable balance"
        );

        //transferring amount.
        (bool success, ) = WALLET.call{value: amount}("");
        require(success, "Value Transfer Failed.");
    }

    // public function to get all items for sale
    function getAllItemForSale() public view returns (SaleOrder[] memory saleOrder){
        return itemsForSale;
    }

    /**
    @dev function to update the commission of the Marketplace.
    @param _newValue - new value for the commission. 
    Note value should be multiplied by 10. If commission is 2.5%
        it should be entered as 25. 
    Requirement:- caller should be the owner.
    */
    function updateCommission(uint16 _newValue) public virtual onlyOwner {
        require(_newValue < 500, "commission can't be greater than 50%.");
        commission = _newValue;
    }

    /**
    @dev Function to add new Item to market.
    @param saleType - used as an Identifier. saleType = 1 for instant sale and saleType = 2 for auction
    @param askingPrice - minimum price required to buy Item.
    @param tokenData - contains details of NFT. refer struct TokenData
     */
    function addItemToMarket(
        uint8 saleType,
        uint256 askingPrice,
        TokenData calldata tokenData
    )
        public
        virtual
        OnlyItemOwner(tokenData.tokenAddress, tokenData.tokenId)
        HasNFTTransferApproval(
            tokenData.tokenAddress,
            tokenData.tokenId,
            _msgSender()
        )
        whenNotPaused
        returns (uint256)
    {
        // checking if the NFT already on Sale.
        require(
            activeItems[tokenData.tokenAddress][tokenData.tokenId] == false,
            "Item is already up for sale!"
        );

        // checking the minimum value
        require(askingPrice > 0, "minimum price should be greater than 0");

        //getting new Id for the Item.
        uint256 newItemId = itemsForSale.length;
        address seller = _msgSender();
        //internal function to add new Item on Market.
        _addItemToMarket(saleType, askingPrice, newItemId, seller, tokenData);

        //return marketId of the Item.
        return newItemId;
    }

    /**
    @dev Function to add new Item to market.
    @param _tokenAddress - address of the buying NFT. (For cross-checking)
    @param _tokenId - id of the buying NFT. (For cross-checking)
    @param _id - id of the sale.
    Note -
        if commission is 25, it means 25/(100*10), ie; 2.5% 
        commission% of the askingPrice will be reduced as commission.
        royalty% of the askingPrice will be transferred to NFT creator.
        The seller will receive a (100 - royalty)% share of the askingPrice.
        Commission values are multiplied by 10 to avoid a precision issues. 
     */
    function buyItem(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _id
    )
        public
        payable
        virtual
        whenNotPaused
        ItemExists(_id)
        IsForSale(_id)
        IsCancelled(_id)
        HasNFTTransferApproval(
            itemsForSale[_id].tokenData.tokenAddress,
            itemsForSale[_id].tokenData.tokenId,
            itemsForSale[_id].seller
        )
        nonReentrant
    {
        //getting seller address from sale data.
        address seller = itemsForSale[_id].seller;

        /**
        @dev scope added to resolve stack too deep error
        */
        {
            //getting token address from sale data.
            address tokenAddress = itemsForSale[_id].tokenData.tokenAddress;

            //getting tokenId from sale data.
            uint256 tokenId = itemsForSale[_id].tokenData.tokenId;

            // checking if the value includes commission.
            require(
                msg.value >=
                    ((itemsForSale[_id].askingPrice) * (1000 + commission)) /
                        1000,
                "Not enough funds sent, Please include commission"
            );

            // checking if item is on instant sale.
            require(
                itemsForSale[_id].saleType == 1,
                "can't purachase token on auction"
            );

            // seller not allowed to purchase Item.
            require(
                _msgSender() != seller,
                "seller can't purchase created Item"
            );

            // checking if the requested tokenId is same as the sale tokenId.
            require(tokenId == _tokenId, "unexpected tokenId");

            // checking if the requested tokenAddress is the same as the sale tokenAddress.
            require(tokenAddress == _tokenAddress, "unexpected token Address");

            // marking item as sold.
            itemsForSale[_id].isSold = true;

            // removing item from active item list.
            activeItems[tokenAddress][tokenId] = false;

            //transferring token buyer.
            IERC721Upgradeable(tokenAddress).safeTransferFrom(
                seller,
                _msgSender(),
                tokenId
            );
        }
        {
            // getting royality value.
            uint16 royalty = itemsForSale[_id].tokenData.royalty;

            // calculating value receivable by creator. Decimals are not allowed as royalty.
            uint256 royaltyValue = (itemsForSale[_id].askingPrice * royalty) /
                100;

            // calculating commission.
            uint256 commissionValue = (itemsForSale[_id].askingPrice *
                commission) / 1000;

            // calculating value receivable by seller.
            uint256 transferValue = msg.value - royaltyValue - commissionValue;

            //transferring share of seller.
            (bool valueSuccess, ) = seller.call{value: transferValue}("");
            require(valueSuccess, "Value Transfer Failed.");

            //transferring share of the creator. rest of msg.value(buy price) will be
            // stored in the contract as commission.
            (bool royaltySuccess, ) = itemsForSale[_id].tokenData.creator.call{
                value: royaltyValue
            }("");
            require(royaltySuccess, "royalty transfer failed");

            //emmitting item sold event.
            emit itemSold(
                _id,
                _msgSender(),
                [msg.value, transferValue, royaltyValue],
                address(0)
            );
        }
    }

    /**
    @dev function to transfer NFT to auction winner.
    @param voucher - contains bidding details. EIP712 type.
    @param _winner - auction winner address. NFT will be transferred to this address.
    Note -
        commission% of the askingPrice will be transferred as commission to WALLET.
        royalty% of the askingPrice will be transferred to NFT creator.
        The seller will receive a (100 - royalty)% of the msg.value.
        Commission values are multiplied by 10 to avoid a precision issues.  
     */
    function finalizeBid(BidVoucher calldata voucher, address _winner)
        public
        virtual
        whenNotPaused
        ItemExists(voucher.marketId)
        IsForSale(voucher.marketId)
        IsCancelled(voucher.marketId)
        HasNFTTransferApproval(
            itemsForSale[voucher.marketId].tokenData.tokenAddress,
            itemsForSale[voucher.marketId].tokenData.tokenId,
            itemsForSale[voucher.marketId].seller
        )
        nonReentrant
    {
        //retrieving signer address from EIP-712 voucher.
        address signer = _verifyBid(voucher);

        //getting seller address from sale data.
        address seller = itemsForSale[voucher.marketId].seller;

        //getting tokenId from sale data.
        uint256 tokenId = itemsForSale[voucher.marketId].tokenData.tokenId;

        //checking if the Item is on Auction
        require(
            itemsForSale[voucher.marketId].saleType == 2,
            "can't bid token on instant sale"
        );

        // make sure signature is valid and get the address of the signer
        require(signer == _winner, "Signature invalid or unauthorized");

        // checking if the value includes commission.
        require(
            voucher.bid >=
                ((itemsForSale[voucher.marketId].askingPrice) *
                    (1000 + commission)) /
                    1000,
            "bid amount is lesser than required price"
        );

        // checking if auction winner is the seller.
        require(_winner != seller, "seller can't purchase created Item");

        // checking if the requested tokenId is same as the sale tokenId.
        require(tokenId == voucher.tokenId, "unexpected tokenId");

        // internal function for finalizing the bid.
        _finalizeBid(voucher, _winner, seller);
    }

    /**
    @dev Function to cancel an item from sale. Cancelled Items can't be purchased.
    @param _id - id the Sale Item. 
     */
    function cancelSale(uint256 _id)
        public
        virtual
        ItemExists(_id)
        IsCancelled(_id)
    {
        address tokenAddress = itemsForSale[_id].tokenData.tokenAddress;
        uint256 tokenId = itemsForSale[_id].tokenData.tokenId;
        itemsForSale[_id].cancelled = true;
        activeItems[tokenAddress][tokenId] = false;
        emit saleCancelled(_id);
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    function redeem(NFTVoucher calldata voucher, address creator)
        public
        payable
        whenNotPaused
        returns (uint256)
    {
        // make sure signature is valid and get the address of the signer
        address signer = _verifyNFTVoucher(voucher);

        // make sure that the signer is authorized to mint NFTs
        require(signer == creator, "Signature invalid or unauthorized");

        // make sure that the redeemer is paying enough to cover the buyer's cost
        // the total price should be greater than the sum of minimum price
        // and commission
        require(
            msg.value >= (voucher.minPrice * (1000 + commission)) / 1000,
            "Insufficient funds to redeem"
        );

        // minting token and assign the token to the signer, to establish provenance on-chain
        ILazyNFT redeemableNFT = ILazyNFT(voucher.tokenAddress);
        redeemableNFT.redeem(signer, voucher.tokenId, voucher.uri);
        
        // creating token data.
        TokenData memory _tokenData = TokenData(
            1,
            voucher.royalty,
            voucher.tokenId,
            1,
            voucher.tokenAddress,
            signer
        );

        // getting new market Id
        uint256 newItemId = itemsForSale.length;

        //adding item to market, to establish provenance on-chain.
        _addItemToMarket(1, voucher.minPrice, newItemId, signer, _tokenData);

        // transfer the token to the redeemer
        buyItem(voucher.tokenAddress, voucher.tokenId, newItemId);

        //emitting redeem event
        emit NFTRedeemed(
            voucher.minPrice,
            voucher.tokenId,
            voucher.tokenAddress,
            signer,
            _msgSender()
        );

        //returning tokenId
        return voucher.tokenId;
    }

    /**
     * @dev Pauses the market contract.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract.
     */
    function pause() public virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the market contract.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract.
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /**
    @dev internal function for adding new item to market
    * See {addItemToMarket}
    */
    function _addItemToMarket(
        uint8 _saleType,
        uint256 _askingPrice,
        uint256 _newItemId,
        address _seller,
        TokenData memory _tokenData
    ) internal virtual {
        // adding data to itemsForSale struct.
        itemsForSale.push(
            SaleOrder(
                false,
                false,
                _saleType,
                _askingPrice,
                _newItemId,
                payable(_seller),
                _tokenData
            )
        );

        // adding Item to active list.
        activeItems[_tokenData.tokenAddress][_tokenData.tokenId] = true;

        // checking if requested tokenId is same as that in the Sale Data
        require(itemsForSale[_newItemId].id == _newItemId, "Item id mismatch");

        // emit item added event.
        emit itemAdded(
            _newItemId,
            _tokenData.tokenId,
            _askingPrice,
            _tokenData.royalty,
            _tokenData.tokenAddress,
            _tokenData.creator
        );
    }

    /**
    @dev internal function to transfer NFT to auction winner.
    * See {finalizeBid}
    */
    function _finalizeBid(
        BidVoucher calldata voucher,
        address _winner,
        address _seller
    ) internal virtual {
        // getting tokenAddress from sale data.
        address tokenAddress = itemsForSale[voucher.marketId]
            .tokenData
            .tokenAddress;

        // getting royalty from sale data.
        uint16 royalty = itemsForSale[voucher.marketId].tokenData.royalty;

        // getting tokenId from sale data.
        uint256 tokenId = itemsForSale[voucher.marketId].tokenData.tokenId;

        // initializing token instance.
        IERC20Upgradeable ERC20 = IERC20Upgradeable(voucher.asset);

        // checking the balance of ERC20 token is greater than bid.
        require(
            ERC20.balanceOf(_winner) >= voucher.bid,
            "Not enough Token Balance in the winner address"
        );

        // checking if the requested token address is same as the voucher token address.
        require(
            tokenAddress == voucher.tokenAddress,
            "unexpected token Address"
        );

        // marking the Item as sold.
        itemsForSale[voucher.marketId].isSold = true;

        // removing Item from active list.
        activeItems[tokenAddress][tokenId] = false;

        // transferring NFT.
        IERC721Upgradeable(tokenAddress).safeTransferFrom(
            _seller,
            _winner,
            tokenId
        );

        uint256 commissionValue = (itemsForSale[voucher.marketId].askingPrice *
            commission) / 1000;

        // calculating royalty value receivable by creator.
        uint256 royaltyValue = (itemsForSale[voucher.marketId].askingPrice *
            royalty) / 100;

        // calculating value receivable by seller.
        uint256 transferValue = voucher.bid - commissionValue - royaltyValue;

        // transferring seller share.
        ERC20.transferFrom(_winner, _seller, transferValue);

        // transferring royalty value.
        ERC20.transferFrom(
            _winner,
            itemsForSale[voucher.marketId].tokenData.creator,
            royaltyValue
        );

        // transferring commission to the wallet.
        ERC20.transferFrom(_winner, WALLET, commissionValue);

        // emiting item sold event.
        emit itemSold(
            voucher.marketId,
            _winner,
            [voucher.bid, transferValue, royaltyValue],
            voucher.asset
        );
    }

    /**
    @dev internal function to recover and signed data
    @param voucher EIP712 signed voucher
     */
    function _verifyBid(BidVoucher calldata voucher)
        internal
        view
        virtual
        returns (address)
    {
        bytes32 digest = _hash(
            abi.encode(
                keccak256(
                    "BidVoucher(address asset,address tokenAddress,uint256 tokenId,uint256 marketId,uint256 bid)"
                ),
                voucher.asset,
                voucher.tokenAddress,
                voucher.tokenId,
                voucher.marketId,
                voucher.bid
            )
        );
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verifyNFTVoucher(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(
            abi.encode(
                keccak256(
                    "NFTVoucher(uint256 tokenId,uint256 minPrice,uint16 royalty,string uri,address tokenAddress)"
                ),
                voucher.tokenId,
                voucher.minPrice,
                voucher.royalty,
                keccak256(bytes(voucher.uri)),
                voucher.tokenAddress
            )
        );
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    /// @notice Returns a hash of the given ABI encoded voucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An encoded voucher to hash.
    function _hash(bytes memory voucher)
        internal
        view
        virtual
        returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(voucher));
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view virtual returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}

//SPDX-License-Identifier: MIT;

pragma solidity 0.8.2;

interface ILazyNFT {
    //represent the event emited after redeeming a voucher
    event NFTRedeemed(uint256 tokenId, address minter, address redeemer);

    /// @notice create new NFT.
    /// @param minter address to which new token is minted.
    /// @param tokenId id of the new token.
    /// @param uri uri string for the new NFT.
    function redeem(
        address minter,
        uint256 tokenId,
        string memory uri
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
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
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
library StringsUpgradeable {
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./Address.sol";

contract Vega {
    function tokenCashbackValues(uint256 tokenId, uint256 tokenPrice)
    public
    view
    virtual
    returns (uint256[] memory)
    {}

    function getCashbackAddress(uint256 tokenId)
    public
    view
    virtual
    returns (address)
    {}
}

contract MarketplaceListing is Ownable {
    using Address for address;

    enum State {
        INITIATED,
        SOLD,
        CANCELLED
    }

    struct Listing {
        string listingId;
        bool isErc721;
        State state;
        address nftAddress;
        address seller;
        address erc20Address;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address buyer;
    }

    // List of all listings in the marketplace. All historical ones are here as well.
    mapping(string => Listing) private _listings;
    string[] private _openListings;
    uint256 private _marketplaceFee;
    address private _marketplaceFeeRecipient;
    /**
     * @dev Emitted when new listing is created by the owner of the contract. Amount is valid only for ERC-1155 tokens
     */
    event ListingCreated(
        bool indexed isErc721,
        address indexed nftAddress,
        uint256 indexed tokenId,
        string listingId,
        uint256 amount,
        uint256 price,
        address erc20Address
    );

    /**
     * @dev Emitted when listing assets were sold.
     */
    event ListingSold(address indexed buyer, string listingId);

    /**
     * @dev Emitted when listing was cancelled and assets were returned to the seller.
     */
    event ListingCancelled(string listingId);

    receive() external payable {}

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    constructor(uint256 fee, address feeRecipient) {
        _marketplaceFee = fee;
        _marketplaceFeeRecipient = feeRecipient;
    }

    function getMarketplaceFee() public view virtual returns (uint256) {
        return _marketplaceFee;
    }

    function getMarketplaceFeeRecipient()
    public
    view
    virtual
    returns (address)
    {
        return _marketplaceFeeRecipient;
    }

    function getListing(string memory listingId)
    public
    view
    virtual
    returns (Listing memory)
    {
        return _listings[listingId];
    }

    function getOpenListings()
    public
    view
    virtual
    returns (string[] memory)
    {
        return _openListings;
    }

    function setMarketplaceFee(uint256 fee) public virtual onlyOwner {
        _marketplaceFee = fee;
    }

    function setMarketplaceFeeRecipient(address recipient)
    public
    virtual
    onlyOwner
    {
        _marketplaceFeeRecipient = recipient;
    }

    /**
     * @dev Create new listing of the NFT token in the marketplace.
     * @param listingId - ID of the listing, must be unique
     * @param isErc721 - whether the listing is for ERC721 or ERC1155 token
     * @param nftAddress - address of the NFT token
     * @param tokenId - ID of the NFT token
     * @param price - Price for the token. It could be in wei or smallest ERC20 value, if @param erc20Address is not 0x0 address
     * @param amount - ERC1155 only, number of tokens to sold.
     * @param erc20Address - address of the ERC20 token, which will be used for the payment. If native asset is used, this should be 0x0 address
     */
    function createListing(
        string memory listingId,
        bool isErc721,
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address seller,
        uint256 amount,
        address erc20Address
    ) public payable {
        if (
            keccak256(abi.encodePacked(_listings[listingId].listingId)) ==
            keccak256(abi.encodePacked(listingId))
        ) {
            revert("Listing already existed for current listing Id");
        }
        if (!isErc721) {
            require(amount > 0);
            require(
                IERC1155(nftAddress).balanceOf(seller, tokenId) >= amount,
                "ERC1155 token balance is not sufficient for the seller.."
            );
        } else {
            require(
                IERC721(nftAddress).ownerOf(tokenId) == seller,
                "ERC721 token does not belong to the author."
            );
            if (_isVegaNFT(nftAddress, tokenId)) {
                if (Vega(nftAddress).getCashbackAddress(tokenId) == address(0)) {
                    uint256 cashbackSum = 0;
                    uint256[] memory cashback = Vega(nftAddress)
                    .tokenCashbackValues(tokenId, price);
                    for (uint256 j = 0; j < cashback.length; j++) {
                        cashbackSum += cashback[j];
                    }
                    require(
                        msg.value >= cashbackSum,
                        "Balance Insufficient to pay royalties"
                    );
                    Address.sendValue(payable(address(this)), cashbackSum);
                    if (msg.value > cashbackSum) {
                        Address.sendValue(
                            payable(msg.sender),
                            msg.value - cashbackSum
                        );
                    }
                }
            }
        }
        Listing memory listing = Listing(
            listingId,
            isErc721,
            State.INITIATED,
            nftAddress,
            seller,
            erc20Address,
            tokenId,
            amount,
            price,
            address(0)
        );
        _listings[listingId] = listing;
        _openListings.push(listingId);
        emit ListingCreated(
            isErc721,
            nftAddress,
            tokenId,
            listingId,
            amount,
            price,
            erc20Address
        );
    }

    /**
     * @dev Buyer wants to buy NFT from listing. All the required checks must pass.
     * Buyer must either send ETH with this endpoint, or ERC20 tokens will be deducted from his account to the marketplace contract.
     * @param listingId - id of the listing to buy
     * @param erc20Address - optional address of the ERC20 token to pay for the assets, if listing is listed in ERC20
     */
    function buyAssetFromListing(string memory listingId, address erc20Address)
    public
    payable
    {
        Listing memory listing = _listings[listingId];
        if (listing.state != State.INITIATED) {
            if (msg.value > 0) {
                Address.sendValue(payable(msg.sender), msg.value);
            }
            revert("Listing is in wrong state. Aborting.");
        }
        if (listing.isErc721) {
            if (
                IERC721(listing.nftAddress).getApproved(listing.tokenId) !=
                address(this)
            ) {
                if (msg.value > 0) {
                    Address.sendValue(payable(msg.sender), msg.value);
                }
                revert(
                "Asset is not owned by this listing. Probably was not sent to the smart contract, or was already sold."
                );
            }
        } else {
            if (
                IERC1155(listing.nftAddress).balanceOf(
                    listing.seller,
                    listing.tokenId
                ) < listing.amount
            ) {
                if (msg.value > 0) {
                    Address.sendValue(payable(msg.sender), msg.value);
                }
                revert(
                "Insufficient balance of the asset in this listing. Probably was not sent to the smart contract, or was already sold."
                );
            }
        }
        if (listing.erc20Address != erc20Address) {
            if (msg.value > 0) {
                Address.sendValue(payable(msg.sender), msg.value);
            }
            revert(
            "ERC20 token address as a payer method should be the same as in the listing. Either listing, or method call has wrong ERC20 address."
            );
        }
        uint256 fee = (listing.price * _marketplaceFee) / 10000;
        listing.state = State.SOLD;
        listing.buyer = msg.sender;
        _listings[listingId] = listing;
        uint256 cashbackSum = 0;
        if (listing.isErc721) {
            if (_isVegaNFT(listing.nftAddress, listing.tokenId)) {
                if (
                    Vega(listing.nftAddress).getCashbackAddress(listing.tokenId) ==
                    address(0)
                ) {
                    uint256[] memory cashback = Vega(listing.nftAddress)
                    .tokenCashbackValues(listing.tokenId, listing.price);
                    for (uint256 j = 0; j < cashback.length; j++) {
                        cashbackSum += cashback[j];
                    }
                }
            }
        }
        if (listing.erc20Address == address(0)) {
            if (listing.price + fee > msg.value) {
                if (msg.value > 0) {
                    Address.sendValue(payable(msg.sender), msg.value);
                }
                revert("Insufficient price paid for the asset.");
            }
            Address.sendValue(payable(_marketplaceFeeRecipient), fee);
            Address.sendValue(payable(listing.seller), listing.price);
            // Overpaid price is returned back to the sender
            if (msg.value - listing.price - fee > 0) {
                Address.sendValue(
                    payable(msg.sender),
                    msg.value - listing.price - fee
                );
            }
            if (listing.isErc721) {
                IERC721(listing.nftAddress).safeTransferFrom{
                value : cashbackSum
                }(
                    listing.seller,
                    msg.sender,
                    listing.tokenId,
                    abi.encodePacked(
                        "SafeTransferFrom",
                        "'''###'''",
                        _uint2str(listing.price)
                    )
                );
            } else {
                IERC1155(listing.nftAddress).safeTransferFrom(
                    listing.seller,
                    msg.sender,
                    listing.tokenId,
                    listing.amount,
                    ""
                );
            }
        } else {
            IERC20 token = IERC20(listing.erc20Address);
            if (
                listing.price + fee > token.allowance(msg.sender, address(this))
            ) {
                if (msg.value > 0) {
                    Address.sendValue(payable(msg.sender), msg.value);
                }
                revert(
                "Insufficient ERC20 allowance balance for paying for the asset."
                );
            }
            token.transferFrom(msg.sender, _marketplaceFeeRecipient, fee);
            token.transferFrom(msg.sender, listing.seller, listing.price);
            if (msg.value > 0) {
                Address.sendValue(payable(msg.sender), msg.value);
            }
            if (listing.isErc721) {
                bytes memory bytesInput = abi.encodePacked(
                    "CUSTOMTOKEN0x",
                    _toAsciiString(listing.erc20Address),
                    "'''###'''",
                    _uint2str(listing.price)
                );
                IERC721(listing.nftAddress).safeTransferFrom{
                value : cashbackSum
                }(listing.seller, msg.sender, listing.tokenId, bytesInput);
            } else {
                IERC1155(listing.nftAddress).safeTransferFrom(
                    listing.seller,
                    msg.sender,
                    listing.tokenId,
                    listing.amount,
                    ""
                );
            }
        }
        _toRemove(listingId);
        emit ListingSold(msg.sender, listingId);
    }

    function _toRemove(string memory listingId) internal {
        for (uint x = 0; x < _openListings.length; x++) {
            if (
                keccak256(abi.encodePacked(_openListings[x])) ==
                keccak256(abi.encodePacked(listingId))
            ) {
                for (uint i = x; i < _openListings.length - 1; i++) {
                    _openListings[i] = _openListings[i + 1];
                }
                _openListings.pop();
            }
        }
    }

    function _toAsciiString(address x) internal pure returns (bytes memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return s;
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function _uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Buyer wants to buy NFT from listing. All the required checks must pass.
     * Buyer must approve spending of the ERC20 tokens will be deducted from his account to the marketplace contract.
     * @param listingId - id of the listing to buy
     * @param erc20Address - optional address of the ERC20 token to pay for the assets
     * @param buyer - buyer of the item, from which account the ERC20 assets will be debited
     */
    function buyAssetFromListingForExternalBuyer(
        string memory listingId,
        address erc20Address,
        address buyer
    ) public payable {
        Listing memory listing = _listings[listingId];
        if (listing.state != State.INITIATED) {
            revert("Listing is in wrong state. Aborting.");
        }
        if (listing.isErc721) {
            if (
                IERC721(listing.nftAddress).getApproved(listing.tokenId) !=
                address(this)
            ) {
                revert(
                "Asset is not owned by this listing. Probably was not sent to the smart contract, or was already sold."
                );
            }
        } else {
            if (
                IERC1155(listing.nftAddress).balanceOf(
                    listing.seller,
                    listing.tokenId
                ) < listing.amount
            ) {
                revert(
                "Insufficient balance of the asset in this listing. Probably was not sent to the smart contract, or was already sold."
                );
            }
        }
        if (listing.erc20Address != erc20Address) {
            revert(
            "ERC20 token address as a payer method should be the same as in the listing. Either listing, or method call has wrong ERC20 address."
            );
        }
        uint256 fee = (listing.price * _marketplaceFee) / 10000;
        listing.state = State.SOLD;
        listing.buyer = buyer;
        _listings[listingId] = listing;
        IERC20 token = IERC20(listing.erc20Address);
        if (listing.price + fee > token.allowance(buyer, address(this))) {
            if (msg.value > 0) {
                Address.sendValue(payable(msg.sender), msg.value);
            }
            revert(
            "Insufficient ERC20 allowance balance for paying for the asset."
            );
        }
        token.transferFrom(buyer, _marketplaceFeeRecipient, fee);
        token.transferFrom(buyer, listing.seller, listing.price);
        if (listing.isErc721) {
            IERC721(listing.nftAddress).safeTransferFrom(
                listing.seller,
                buyer,
                listing.tokenId,
                abi.encodePacked(
                    "CUSTOMTOKEN0x",
                    _toAsciiString(listing.erc20Address),
                    "'''###'''",
                    _uint2str(listing.price)
                )
            );
        } else {
            IERC1155(listing.nftAddress).safeTransferFrom(
                listing.seller,
                buyer,
                listing.tokenId,
                listing.amount,
                ""
            );
        }
        _toRemove(listingId);
        emit ListingSold(buyer, listingId);
    }

    /**
     * @dev Cancel listing - returns the NFT asset to the seller.
     * @param listingId - id of the listing to cancel
     */
    function cancelListing(string memory listingId) public virtual {
        Listing memory listing = _listings[listingId];
        require(
            listing.state == State.INITIATED,
            "Listing is not in INITIATED state. Aborting."
        );
        require(
            listing.seller == msg.sender || msg.sender == owner(),
            "Listing can't be cancelled from other then seller or owner. Aborting."
        );
        listing.state = State.CANCELLED;
        _listings[listingId] = listing;
        if(listing.isErc721 && listing.erc20Address == address(0)){
            uint256 cashbackSum = 0;
            if (_isVegaNFT(listing.nftAddress, listing.tokenId, listing.price)) {
                uint256[] memory cashback = Vega(listing.nftAddress)
                .tokenCashbackValues(listing.tokenId, listing.price);
                for (uint256 j = 0; j < cashback.length; j++) {
                    cashbackSum += cashback[j];
                }
            }
            if (cashbackSum > 0) {
                Address.sendValue(payable(listing.seller), cashbackSum);
            }
        }
        _toRemove(listingId);
        emit ListingCancelled(listingId);
    }

    function _isVegaNFT(address addr, uint256 p1, uint256 p2) internal returns (bool){
        bool success;
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("tokenCashbackValues(uint256,uint256)")), p1, p2);

        assembly {
            success := call(
            gas(), // gas remaining
            addr, // destination address
            0, // no ether
            add(data, 32), // input buffer (starts after the first 32 bytes in the `data` array)
            mload(data), // input length (loaded from the first 32 bytes in the `data` array)
            0, // output buffer
            0               // output length
            )
        }

        return success;
    }

    function _isVegaNFT(address addr, uint256 p1) internal returns (bool){
        bool success;
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("getCashbackAddress(uint256)")), p1);

        assembly {
            success := call(
            gas(), // gas remaining
            addr, // destination address
            0, // no ether
            add(data, 32), // input buffer (starts after the first 32 bytes in the `data` array)
            mload(data), // input length (loaded from the first 32 bytes in the `data` array)
            0, // output buffer
            0               // output length
            )
        }

        return success;
    }
}
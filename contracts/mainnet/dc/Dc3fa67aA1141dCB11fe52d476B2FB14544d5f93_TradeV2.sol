// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.4;

import "../TransferProxy.sol";

contract TradeV2 {
    enum BuyingAssetType {
        ERC1155,
        ERC721
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event BuyAsset721(
        address indexed assetOwner,
        uint256 indexed tokenId,
        address indexed buyer,
        Fee fee
    );
    event BuyAsset1155(
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer,
        Fee fee
    );
    event ExecuteBid721(
        address indexed assetOwner,
        uint256 indexed tokenId,
        address indexed buyer,
        Fee fee
    );
    event ExecuteBid1155(
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer,
        Fee fee
    );

    uint8 public buyerFeePermille; // buyer's fee, above the lot price
    uint8 public sellerFeePermille; // fee from the seller, deducted from the price of the lot
    TransferProxy public transferProxy;
    address public owner;
    address public beneficiary; // Wallet address to receive fee
    mapping(uint256 => bool) public usedNonce;

    struct Fee {
        uint256 platformFee;
        uint256 assetFee;
        uint256 royaltyFee;
        uint256 price;
        address tokenCreator;
    }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Order721 {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        uint256 unitPrice;
        uint256 amount;
        uint256 tokenId;
        uint256 nonce;
    }

    struct Order1155 {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        uint256 unitPrice;
        uint256 amount;
        uint256 tokenId;
        uint256 qty;
        uint256 nonce;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier checkNonce(uint256 nonce) {
        require(usedNonce[nonce] == false, "Used nonce");
        usedNonce[nonce] = true;
        _;
    }

    constructor(
        uint8 _buyerFee,
        uint8 _sellerFee,
        address _beneficiary,
        TransferProxy _transferProxy
    ) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        beneficiary = _beneficiary;
        transferProxy = _transferProxy;
        owner = msg.sender;
    }

    function setBuyerServiceFee(uint8 _buyerFee)
        public
        onlyOwner
        returns (bool)
    {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    function setSellerServiceFee(uint8 _sellerFee)
        public
        onlyOwner
        returns (bool)
    {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function buyAsset721(Order721 memory order, Sign memory sign)
        public
        payable
        checkNonce(order.nonce)
        returns (bool)
    {
        Fee memory fee = _getFees(
            msg.value,
            order.nftAddress,
            order.tokenId,
            BuyingAssetType.ERC721
        );
        require((msg.value >= order.unitPrice), "Paid invalid value");
        _verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            order.nonce,
            sign
        );
        order.buyer = msg.sender;
        _tradeAsset721(order, fee);
        emit BuyAsset721(order.seller, order.tokenId, msg.sender, fee);
        return true;
    }

    function buyAsset1155(Order1155 memory order, Sign memory sign)
        public
        payable
        checkNonce(order.nonce)
        returns (bool)
    {
        Fee memory fee = _getFees(
            msg.value,
            order.nftAddress,
            order.tokenId,
            BuyingAssetType.ERC1155
        );
        require(
            (msg.value >= order.unitPrice * order.qty),
            "Paid invalid value"
        );
        _verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            order.nonce,
            sign
        );
        order.buyer = msg.sender;
        _tradeAsset1155(order, fee);
        emit BuyAsset1155(
            order.seller,
            order.tokenId,
            order.qty,
            msg.sender,
            fee
        );
        return true;
    }

    function executeBid721(Order721 memory order, Sign memory sign)
        public
        checkNonce(order.nonce)
        returns (bool)
    {
        Fee memory fee = _getFees(
            order.amount,
            order.nftAddress,
            order.tokenId,
            BuyingAssetType.ERC721
        );
        _verifyBuyerSign721(order, sign);
        order.seller = msg.sender;
        _tradeBid721(order, fee);
        emit ExecuteBid721(msg.sender, order.tokenId, order.buyer, fee);
        return true;
    }

    function executeBid1155(Order1155 memory order, Sign memory sign)
        public
        checkNonce(order.nonce)
        returns (bool)
    {
        Fee memory fee = _getFees(
            order.amount,
            order.nftAddress,
            order.tokenId,
            BuyingAssetType.ERC1155
        );
        _verifyBuyerSign1155(order, sign);
        order.seller = msg.sender;
        _tradeBid1155(order, fee);
        emit ExecuteBid1155(
            msg.sender,
            order.tokenId,
            order.qty,
            order.buyer,
            fee
        );
        return true;
    }

    function _getFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId,
        BuyingAssetType buyingAssetType
    ) internal view returns (Fee memory) {
        address tokenCreator;
        uint256 platformFee;
        uint256 royaltyFee;
        uint256 assetFee;
        uint256 royaltyPermille;
        uint256 buyerFee = (paymentAmt / (1000 + buyerFeePermille)) *
            buyerFeePermille;
        // platform fee from the buyer
        uint256 price = paymentAmt - buyerFee;
        // real price of the lot
        uint256 sellerFee = (price * sellerFeePermille) / 1000;
        // platform fee from the buyer
        platformFee = buyerFee + sellerFee;
        if (buyingAssetType == BuyingAssetType.ERC721) {
            royaltyPermille = (
                (IERC721(buyingAssetAddress).royaltyFee(tokenId))
            );
            tokenCreator = ((IERC721(buyingAssetAddress).getCreator(tokenId)));
        }
        if (buyingAssetType == BuyingAssetType.ERC1155) {
            royaltyPermille = (
                (IERC1155(buyingAssetAddress).royaltyFee(tokenId))
            );
            tokenCreator = ((IERC1155(buyingAssetAddress).getCreator(tokenId)));
        }
        royaltyFee = (price * royaltyPermille) / 1000;
        // token creator fee
        assetFee = price - royaltyFee - sellerFee;
        return Fee(platformFee, assetFee, royaltyFee, price, tokenCreator);
    }

    function _tradeBid721(Order721 memory order, Fee memory fee)
        internal
        virtual
    {
        transferProxy.erc721safeTransferFrom(
            IERC721(order.nftAddress),
            order.seller,
            order.buyer,
            order.tokenId
        );
        _tradeBidFee(order.erc20Address, order.buyer, order.seller, fee);
    }

    function _tradeBid1155(Order1155 memory order, Fee memory fee)
        internal
        virtual
    {
        transferProxy.erc1155safeTransferFrom(
            IERC1155(order.nftAddress),
            order.seller,
            order.buyer,
            order.tokenId,
            order.qty,
            ""
        );
        _tradeBidFee(order.erc20Address, order.buyer, order.seller, fee);
    }

    function _tradeBidFee(
        address erc20Address,
        address buyer,
        address seller,
        Fee memory fee
    ) internal {
        if (fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(
                IERC20(erc20Address),
                buyer,
                beneficiary,
                fee.platformFee
            );
        }
        if (fee.royaltyFee > 0) {
            transferProxy.erc20safeTransferFrom(
                IERC20(erc20Address),
                buyer,
                fee.tokenCreator,
                fee.royaltyFee
            );
        }
        transferProxy.erc20safeTransferFrom(
            IERC20(erc20Address),
            buyer,
            seller,
            fee.assetFee
        );
    }

    function _tradeAsset721(Order721 memory order, Fee memory fee)
        internal
        virtual
    {
        transferProxy.erc721safeTransferFrom(
            IERC721(order.nftAddress),
            order.seller,
            order.buyer,
            order.tokenId
        );
        _tradeAssetFee(order.seller, fee);
    }

    function _tradeAsset1155(Order1155 memory order, Fee memory fee)
        internal
        virtual
    {
        transferProxy.erc1155safeTransferFrom(
            IERC1155(order.nftAddress),
            order.seller,
            order.buyer,
            order.tokenId,
            order.qty,
            ""
        );
        _tradeAssetFee(order.seller, fee);
    }

    function _tradeAssetFee(address seller, Fee memory fee) internal {
        if (fee.platformFee > 0) {
            require(payable(beneficiary).send(fee.platformFee));
        }
        if (fee.royaltyFee > 0) {
            require(payable(fee.tokenCreator).send(fee.royaltyFee));
        }
        require(payable(seller).send(fee.assetFee));
    }

    function _getSigner(bytes32 hash, Sign memory sign)
        internal
        pure
        returns (address)
    {
        return
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                sign.v,
                sign.r,
                sign.s
            );
    }

    function _verifySellerSign(
        address seller,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        uint256 nonce,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(
            abi.encodePacked(
                assetAddress,
                tokenId,
                paymentAssetAddress,
                amount,
                nonce
            )
        );
        require(
            seller == _getSigner(hash, sign),
            "seller sign verification failed"
        );
    }

    function _verifyBuyerSign721(Order721 memory order, Sign memory sign)
        internal
        pure
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                order.nftAddress,
                order.tokenId,
                order.erc20Address,
                order.amount,
                order.nonce
            )
        );
        require(
            order.buyer == _getSigner(hash, sign),
            "buyer sign verification failed"
        );
    }

    function _verifyBuyerSign1155(Order1155 memory order, Sign memory sign)
        internal
        pure
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                order.nftAddress,
                order.tokenId,
                order.erc20Address,
                order.amount,
                order.qty,
                order.nonce
            )
        );
        require(
            order.buyer == _getSigner(hash, sign),
            "buyer sign verification failed"
        );
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./tokens/interfaces/IERC20.sol";
import "./tokens/interfaces/IERC721.sol";
import "./tokens/interfaces/IERC1155.sol";

contract TransferProxy {
    event operatorChanged(address indexed from, address indexed to);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address public owner;
    address public operator;

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */

    modifier onlyOwner() {
        require(owner == msg.sender, "only Owner");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "only Operator");
        _;
    }

    /** change the OperatorRole from contract creator address to trade contractaddress
@param _operator :trade address 
        */

    function changeOperator(address _operator) public onlyOwner returns (bool) {
        require(
            _operator != address(0),
            "Operator: new operator is the zero address"
        );
        operator = _operator;
        emit operatorChanged(address(0), operator);
        return true;
    }

    /** change the Ownership from current owner to newOwner address
@param newOwner : newOwner address */

    function transferOwnership(address newOwner)
        public
        onlyOwner
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
        return true;
    }

    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId, value, data);
    }

    function erc20safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) external onlyOperator {
        require(
            token.transferFrom(from, to, value),
            "failure while transferring"
        );
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    event tokenBaseURI(string value);

    function balanceOf(address owner) external view returns (uint256 balance);

    function royaltyFee(uint256 tokenId) external view returns (uint256);

    function getCreator(uint256 tokenId) external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IERC1155 is IERC165 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event URI(string value, uint256 indexed id);
    event tokenBaseURI(string value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function royaltyFee(uint256 tokenId) external view returns (uint256);

    function getCreator(uint256 tokenId) external view returns (address);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.4;

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
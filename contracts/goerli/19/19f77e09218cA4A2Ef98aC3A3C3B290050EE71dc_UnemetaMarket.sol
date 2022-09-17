// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {TheCurrencyManager} from "./interface/TheCurrencyManager.sol";
import {TheExManager} from "./interface/TheExManager.sol";
import {TheExStrategy} from "./execution/interface/TheExecutionStrategy.sol";
import {TheRoyaltyManager} from "./interface/TheRoyaltyFeeManager.sol";
import {TheUnemetaExchange} from "./interface/TheUnemetaExchange.sol";
import {TheTransferManager} from "./interface/TheTransferManager.sol";
import {TheTransferSelector} from "./trans/interface/TheTransFerSelector.sol";
import {IWETH} from "./interface/IWETH.sol";

import {OrderTypes} from "../libraries/OrderTypes.sol";
import {SignatureChecker} from "../libraries/SignatureChecker.sol";


//UnemetaExchange
contract UnemetaMarket is TheUnemetaExchange, ReentrancyGuard, Ownable {
    // Load safe erc20
    using SafeERC20 for IERC20;
    using OrderTypes for OrderTypes.MakerOrder;
    using OrderTypes for OrderTypes.TakerOrder;

    //Cancel all orders
    event CancelAllOrders(address indexed user, uint256 newMinNonce);
    // Cancel some orders
    event CancelMultipleOrders(address indexed user, uint256[] orderNonces);
    // New currency manager address
    event NewCurrencyManager(address indexed currencyManager);
    // New execution manager address
    event NewExecutionManager(address indexed executionManager);
    // new platform transaction fee receipient address
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
    // New royalty fee receipient address
    event NewRoyaltyFeeManager(address indexed royaltyFeeManager);
    // New NFT transfer selector
    event NewTransferSelectorNFT(address indexed transferSelectorNFT);

    // Defaulty wetg address
    address public immutable WETH;
    // Defualt eip712 domain hash
    address public protocolFeeRecipient;


    TheCurrencyManager public currencyManager;
    TheExManager public executionManager;
    TheRoyaltyManager public royaltyFeeManager;
    TheTransferSelector public transferSelectorNFT;


    // Users' minimal nonce map
    mapping(address => uint256) public userMinOrderNonce;
    // User proceeds to execution or cancellation
    mapping(address => mapping(uint256 => bool)) private _theUserOrderExecutedOrCancelled;

    /*Royalty fee payment structure*/
    event RoyaltyPayment(
        address indexed collection, //collection address
        uint256 indexed tokenId, //token id
        address indexed royaltyRecipient, //recipient wallet address
        address currency, //currency
        uint256 amount//amount
    );

    //Ask price structure
    event TakerAsk(
        bytes32 orderHash,
        uint256 orderNonce,
        address indexed taker,
        address indexed maker,
        address indexed strategy,
        address currency,
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    );

    //Bid price structure
    event TakerBid(
        bytes32 orderHash,
        uint256 orderNonce,
        address indexed taker,
        address indexed maker,
        address indexed strategy,
        address currency,
        address collection,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    );

    //—————————————————————————————————constructor function—————————————————————————————————
    // Initialize contract using the input parameters
    // Including currency manager, execution manager, royalty manager, NFT transfer selector, weth address, platform transaction fee receipient
    constructor(
        address _currencyManager, //currency manager
        address _executionManager, //execution manager
        address _royaltyFeeManager, //royalty fee manager
        address _WETH, //WETH address
        address _protocolFeeRecipient// platform transaction fee recipient
    ) {
        currencyManager = TheCurrencyManager(_currencyManager);
        executionManager = TheExManager(_executionManager);
        royaltyFeeManager = TheRoyaltyManager(_royaltyFeeManager);
        WETH = _WETH;
        protocolFeeRecipient = _protocolFeeRecipient;
    }



    //
    // function matchSellerOrdersWETH
    //  @Description: Match seller order with weth and eth
    //  @param OrderTypes.TakerOrder
    //  @param OrderTypes.MakerOrder
    //  @return external
    //
    function matchSellerOrdersWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable override nonReentrant {
        require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Error About Order Side");
        // Confirm using weth
        require(makerAsk.currency == WETH, "Currency must be WETH");
        require(msg.sender == takerBid.taker, "Order must be the sender");

        // if the balance of eth is low then use weth
        if (takerBid.price > msg.value) {
            IERC20(WETH).safeTransferFrom(msg.sender, address(this), (takerBid.price - msg.value));
        } else {
            require(takerBid.price == msg.value, "Msg.value is too high");
        }

        //deposit weth
        IWETH(WETH).deposit{value : msg.value}();

        // Confirm users of offer and make
        bytes32 askHash = makerAsk.hash();
        _validateOrder(makerAsk, askHash);

        // Confirm execution parameters
        (bool isExecutionValid, uint256 tokenId, uint256 amount) = TheExStrategy(makerAsk.strategy)
        .canExecuteSell(takerBid, makerAsk);

        require(isExecutionValid, "Strategy should be valid");

        // Update the random number status of current order to be true, avoid reentrancy
        _theUserOrderExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

        // transfer fund
        _transferFeesAndFundsWithWETH(
            makerAsk.strategy,
            makerAsk.collection,
            tokenId,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        // transfer nft
        _transferNonFungibleToken(
            makerAsk.collection,
            makerAsk.signer,
            takerBid.taker,
            tokenId,
            amount);

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            takerBid.taker,
            makerAsk.signer,
            makerAsk.strategy,
            makerAsk.currency,
            makerAsk.collection,
            tokenId,
            amount,
            takerBid.price
        );
    }

    //
    // function matchSellerOrders
    //  @Description: matchi seller order
    //  @param OrderTypes.TakerOrder
    //  @param OrderTypes.MakerOrder
    //  @return external
    //
    function matchSellerOrders(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
    external
    override
    nonReentrant
    {
        //Confirm the listing is valid and not a bid order
        require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Error About Order Side");
        // order must be from the bidder
        require(msg.sender == takerBid.taker, "Order must be the sender");

        //  validate signature
        bytes32 askHash = makerAsk.hash();
        _validateOrder(makerAsk, askHash);

        //
        (bool isExecutionValid, uint256 tokenId, uint256 amount) = TheExStrategy(makerAsk.strategy)
        .canExecuteSell(takerBid, makerAsk);

        // Confirm valid execution
        require(isExecutionValid, "Strategy should be valid");

        // Update the random number status of current order to be true, avoid reentrancy
        _theUserOrderExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

        // transfer fund
        _transferFeesAndFunds(
            makerAsk.strategy,
            makerAsk.collection,
            tokenId,
            makerAsk.currency,
            msg.sender,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        //transfer nft
        _transferNonFungibleToken(
            makerAsk.collection,
            makerAsk.signer,
            takerBid.taker,
            tokenId,
            amount);

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            takerBid.taker,
            makerAsk.signer,
            makerAsk.strategy,
            makerAsk.currency,
            makerAsk.collection,
            tokenId,
            amount,
            takerBid.price
        );
    }

    //
    // function matchesBuyerOrder
    //  @Description: match buyer order
    //  @param OrderTypes.TakerOrder
    //  @param OrderTypes.MakerOrder
    //  @return external
    //
    function matchesBuyerOrder(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
    external
    override
    nonReentrant
    {
        // validate paramenters of both sides
        // This step ensures matching seller order to buyer order
        require((!makerBid.isOrderAsk) && (takerAsk.isOrderAsk), "Error About Order Side");
        // order must be from the seller
        require(msg.sender == takerAsk.taker, "Order must be the sender");

        // confirm bid is signed
        bytes32 bidHash = makerBid.hash();
        // confirm bid signature is valid
        _validateOrder(makerBid, bidHash);

        // confirm trading strategy can be effectively executed
        (bool isExecutionValid, uint256 tokenId, uint256 amount) = TheExStrategy(makerBid.strategy)
        .canExecuteBuy(takerAsk, makerBid);

        require(isExecutionValid, "Strategy should be valid");

        // Update the random number status of current order to be true, avoid reentrancy
        _theUserOrderExecutedOrCancelled[makerBid.signer][makerBid.nonce] = true;

        // transfer nft
        _transferNonFungibleToken(
            makerBid.collection,
            msg.sender,
            makerBid.signer,
            tokenId,
            amount);

        // transfer fund
        _transferFeesAndFunds(
            makerBid.strategy,
            makerBid.collection,
            tokenId,
            makerBid.currency,
            makerBid.signer,
            takerAsk.taker,
            takerAsk.price,
            takerAsk.minPercentageToAsk
        );

        emit TakerAsk(
            bidHash,
            makerBid.nonce,
            takerAsk.taker,
            makerBid.signer,
            makerBid.strategy,
            makerBid.currency,
            makerBid.collection,
            tokenId,
            amount,
            takerAsk.price
        );
    }

    //
    // function cancelAllOrdersForSender
    //  @Description: 取消所有的order
    //  @param uint256
    //  @return external
    //
    function cancelAllOrdersForSender(uint256 minNonce) external {
        require(minNonce > userMinOrderNonce[msg.sender], "Cancel Order nonce cannot lower than current");
        require(minNonce < userMinOrderNonce[msg.sender] + 500000, "Cannot cancel too many orders");
        // maintain a minimal nonce, to confirm the current order has reached the minimal nonce
        userMinOrderNonce[msg.sender] = minNonce;

        emit CancelAllOrders(msg.sender, minNonce);
    }

    //
    // function cancelMultipleMakerOrders
    //  @Description: cancel multiple orders
    //  @param uint256[] orderNonces
    //  @return external
    //
    function cancelMultipleMakerOrders(uint256[] calldata NonceList) external {
        require(NonceList.length > 0, "Cannot be empty Cancel list");

        for (uint256 i = 0; i < NonceList.length; i++) {
            require(NonceList[i] >= userMinOrderNonce[msg.sender], "Cancel Order nonce cannot lower than current");
            _theUserOrderExecutedOrCancelled[msg.sender][NonceList[i]] = true;
        }

        emit CancelMultipleOrders(msg.sender, NonceList);
    }
    //
    // function isUserOrderNonceExecutedOrCancelled
    //  @Description: Check if the current order is cancelled or was previously executed using map
    //  @param address  user address
    //  @param uint256  random number status of current order
    //  @return external
    //
    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool) {
        //view viewing does not consume gas
        return _theUserOrderExecutedOrCancelled[user][orderNonce];
    }

    //
    // tion _transferFeesAndFunds
    //  @Description: using specific erc20 method to transfer fund(platform transaction fee or other fee)
    //  @param address  _strategy trading strategy address
    //  @param address  _collection nft contract address
    //  @param uint256  _tokenId nft if
    //  @param address  _currency erc20 contract address
    //  @param address  _seller seller address
    //  @param address  _buyer buyer address
    //  @param uint256  _price price
    //  @param uint256  _minPercentageToAsk minimal percentage accepted by the seller
    //  @return internal
    //
    function _transferFeesAndFunds(
        address strategy,
        address collection,
        uint256 tokenId,
        address currency,
        address from,
        address to,
        uint256 amount,
        uint256 minPercentageToAsk
    ) internal {
        // initialize final price
        uint256 finalSellerAmount = amount;

        //2，calculate platform transaction fee

        uint256 protocolFeeAmount = _calculateProtocolFee(strategy, amount);
        // Confirm strategy is not null, platform transaction fee recipient is not null, platform transaction fee is not 0, before charging platform transaction fee
        // If current strategy is not null, but platform transaction fee is 0, then pass
        if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
            IERC20(currency).safeTransferFrom(from, protocolFeeRecipient, protocolFeeAmount);
            finalSellerAmount -= protocolFeeAmount;
        }


        //3。 calculate royalty fee

        (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager
        .calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);

        // Pass only when current royalty recipient exists and royalty fee is 0
        if ((royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)) {
            IERC20(currency).safeTransferFrom(from, royaltyFeeRecipient, royaltyFeeAmount);
            finalSellerAmount -= royaltyFeeAmount;

            emit RoyaltyPayment(collection, tokenId, royaltyFeeRecipient, currency, royaltyFeeAmount);
        }

        // confirm the final amount is higher than the price set by user
        require((finalSellerAmount * 10000) >= (minPercentageToAsk * amount), "The fee is too high for the seller");

        //4  transfer final amount

        IERC20(currency).safeTransferFrom(from, to, finalSellerAmount);

    }


    //
    // function _transferFeesAndFundsWithWETH
    //  @Description: use weth to transfer fee and fund, including different types of fee
    //  @param address execution strategy address
    //  @param address  collection address
    //  @param uint256  tokenId
    //  @param address  target wallet(seller)
    //  @param uint256  amount
    //  @param uint256  minimal percentage accepted by the seller
    //  @return internal
    //
    function _transferFeesAndFundsWithWETH(
        address strategy,
        address collection,
        uint256 tokenId,
        address to,
        uint256 amount,
        uint256 minPercentageToAsk
    ) internal {
        //1. initialize final amount
        uint256 finalSellerAmount = amount;


        //2，calculate platform transaction fee
        uint256 protocolFeeAmount = _calculateProtocolFee(strategy, amount);

        // Confirm strategy is not null, platform transaction fee recipient is not null, platform transaction fee is not 0, before charging platform transaction fee
        // If current strategy is not null, but platform transaction fee is 0, then pass
        if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
            IERC20(WETH).safeTransfer(protocolFeeRecipient, protocolFeeAmount);
            finalSellerAmount -= protocolFeeAmount;
        }


        //3. calculate royalty fee
        (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager
        .calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);

        // Pass only when current royalty recipient exists and royalty fee is 0
        if ((royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)) {
            IERC20(WETH).safeTransfer(royaltyFeeRecipient, royaltyFeeAmount);
            finalSellerAmount -= royaltyFeeAmount;

            emit RoyaltyPayment(collection, tokenId, royaltyFeeRecipient, address(WETH), royaltyFeeAmount);
        }


        // confirm the final amount is higher than the price set by user
        require((finalSellerAmount * 10000) >= (minPercentageToAsk * amount), "The fee is too high for the seller");

        //4  transfer final amount
        IERC20(WETH).safeTransfer(to, finalSellerAmount);

    }


    //
    // function _transferNonFungibleToken
    //  @Description: transfer nft
    //  @param address  collection address
    //  @param address  source address
    //  @param address  target address
    //  @param uint256  tokenId
    //  @param uint256  amount
    //  @return internal
    //
    function _transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        //  check contract manager in initialization
        address Manager = transferSelectorNFT.checkTransferManagerForToken(collection);

        // ensure manager contract exists
        require(Manager != address(0), "Can't fount transfer manager");

        // If one is found, transfer the token
        TheTransferManager(Manager).transferNonFungibleToken(collection, from, to, tokenId, amount);
    }

    //
    // function _calculateProtocolFee
    //  @Description:  calculate platform transaction fee according to strategy
    //  @param address  execution stratgey address
    //  @param uint256  trading amount
    //  @return internal
    //
    function _calculateProtocolFee(address theStrategy, uint256 amount) internal view returns (uint256) {
        uint256 protocolFee = TheExStrategy(theStrategy).viewProtocolFee();
        return (protocolFee * amount) / 10000;
    }

    //
    // function _validateOrder
    //  @Description: validate using order infor
    //  @param OrderTypes.MakerOrder memory order order information
    //  @param bytes32 hash order hash
    //  @return internal
    //
    function _validateOrder(OrderTypes.MakerOrder calldata Make, bytes32 Hash) internal view {
        // Verify whether order nonce has expired
        require(
        // check if the order is cancelled or timeout
            (!_theUserOrderExecutedOrCancelled[Make.signer][Make.nonce]) &&
            (Make.nonce >= userMinOrderNonce[Make.signer]),
            "Order: Matching order expired"
        );

        //order signature cannot be null
        require(Make.signer != address(0), "The Order signer cannot be the zero address");

        //confirm if amount is larger than 0
        require(Make.amount > 0, "The order amount should be greater than 0");

        bytes32 Domain = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
            // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x2e3445393f211d11d7f88d325bc26ce78976b4decd39029feb202d9b409fc3c5,
            // keccak256("UnemetaMarket")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6,
            // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );

        //validate signature
        //because the eip712 signature stored in the server is used, must restore using teh same structure
        //ensures signature is valid
        require(
            SignatureChecker.
            verify(
                Hash, //hash
                Make.signer, // listing signer
                Make.v, //signature parameter, from eip712 standard
                Make.r,
                Make.s,
                Domain
            ),
            "Signature: Invalid"
        );

        // confirm currency is whitelisted
        require(currencyManager.isCurrencyWhitelisted(Make.currency), " Not in Currency whitelist");

        // confirm trading strategy is whitelisted and can execute correctly
        require(executionManager.isStrategyWhitelisted(Make.strategy), " Not in Strategy whitelist");
    }



    //
    // function updateCurrencyManager
    //  @Description: Update a currency manager
    //  @param address
    //  @return external
    //
    function updateCurrencyManager(address _currencyManager) external onlyOwner {
        require(_currencyManager != address(0), "Cannot update to a null address");
        currencyManager = TheCurrencyManager(_currencyManager);
        emit NewCurrencyManager(_currencyManager);
    }

    //
    // function updateExecutionManager
    //  @Description: Update an execution manager
    //  @param address
    //  @return external
    //
    function updateExecutionManager(address _executionManager) external onlyOwner {
        require(_executionManager != address(0), "Cannot update to a null address");
        executionManager = TheExManager(_executionManager);
        emit NewExecutionManager(_executionManager);
    }

    //
    // function updateProtocolFeeRecipient
    //  @Description: Update platform transaction fee recipient
    //  @param address
    //  @return external
    //
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;
        emit NewProtocolFeeRecipient(_protocolFeeRecipient);
    }

    //
    // function updateRoyaltyFeeManager
    //  @Description: update royalty fee manager
    //  @param address
    //  @return external
    //
    function updateRoyaltyFeeManager(address _royaltyFeeManager) external onlyOwner {
        require(_royaltyFeeManager != address(0), "Cannot update to a null address");
        royaltyFeeManager = TheRoyaltyManager(_royaltyFeeManager);
        emit NewRoyaltyFeeManager(_royaltyFeeManager);
    }

    //
    // function updateTransferSelectorNFT
    //  @Description: update transfer manager
    //  @param address
    //  @return external
    //
    function updateTransferSelectorNFT(address _transferSelectorNFT) external onlyOwner {
        require(_transferSelectorNFT != address(0), "Cannot update to a null address");
        transferSelectorNFT = TheTransferSelector(_transferSelectorNFT);
        emit NewTransferSelectorNFT(_transferSelectorNFT);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts.
 */
library SignatureChecker {

    //
    // function recover
    //  @Description:  Recover signer from the signature
    //  @param bytes32  hash  Including has of signiture information
    //  @param uint8 Two possibilities, to enforce decryption from multiple angles using public key
    //  @param bytes32
    //  @param bytes32
    //  @return internal
    //
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
        // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            " Invalid s parameter"
        );

        require(v == 27 || v == 28, "Invalid v parameter");

        // Recover one signing address if signature is normal
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), " Invalid signer");

        return signer;
    }
    
    //
    // tion verify
    //  @Description: To verify of signer matches all the signature information
    //  @param bytes32
    //  @param address
    //  @param uint8
    //  @param bytes32
    //  @param bytes32
    //  @param bytes32
    //  @return internal
    //
    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        // \x19\x01 Standard prefix code
        // https://eips.ethereum.org/EIPS/eip-712#specification
        // Checking code of the input domain and hash
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));
        // If the signature address is the contract address
        if (Address.isContract(signer)) {
            // 0x1626ba7e is the interfaceId(see IERC1271) of signing contract
            // Standard 1271 API
            return IERC1271(signer).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e;
        } else {
            // Check if signature address is same as input address
            return recover(digest, v, r, s) == signer;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//—————————————————————————————————Order Structure—————————————————————————————————
library OrderTypes {
    // keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }


    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
        keccak256(
            abi.encode(
                MAKER_ORDER_HASH,
                makerOrder.isOrderAsk,
                makerOrder.signer,
                makerOrder.collection,
                makerOrder.price,
                makerOrder.tokenId,
                makerOrder.amount,
                makerOrder.strategy,
                makerOrder.currency,
                makerOrder.nonce,
                makerOrder.startTime,
                makerOrder.endTime,
                makerOrder.minPercentageToAsk,
                keccak256(makerOrder.params)
            )
        );
    }
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface TheTransferSelector {
    function checkTransferManagerForToken(address collection) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface TheTransferManager {
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {OrderTypes} from "../../libraries/OrderTypes.sol";

interface TheUnemetaExchange {
    function matchSellerOrdersWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable;

    function matchSellerOrders(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external;

    function matchesBuyerOrder(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface TheRoyaltyManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {OrderTypes} from "../../../libraries/OrderTypes.sol";

interface TheExStrategy {
    function canExecuteBuy(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteSell(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function viewProtocolFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface TheExManager {
    function addStrategy(address strategy) external;

    function removeStrategy(address strategy) external;

    function isStrategyWhitelisted(address strategy) external view returns (bool);

    function viewWhitelistedStrategies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedStrategies() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface TheCurrencyManager {
    function addCurrency(address currency) external;

    function removeCurrency(address currency) external;

    function isCurrencyWhitelisted(address currency) external view returns (bool);

    function viewWhitelistedCurrencies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedCurrencies() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
//import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./IAgent.sol";
import "./AgentRouter.sol";

//import "../lib/Signature.sol";

//import "../tokens/interfaces/IERC721Minimal.sol";

abstract contract Agent is IAgent, ERC721Holder, IERC1271 {
    //using Signature for bytes32;
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant MAGICVALUE = this.isValidSignature.selector;

    uint8 immutable agentId;
    address public immutable AGENT_ROUTER;

    modifier onlyOwner() {
        require(msg.sender == AgentRouter(AGENT_ROUTER).owner(), "Not owner");
        _;
    }

    constructor(uint8 _agentId, address router) {
        agentId = _agentId;
        AGENT_ROUTER = router;
    }

    function getName() external view returns (string memory) {
        return "";
    }

    // supports interface
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == 0x00000000;
    }

    function isValidSignature(
        bytes32 digest,
        bytes calldata signature
    ) external view returns (bytes4) {
        return MAGICVALUE;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "./IERC721Minimal.sol";
import "./IAgent.sol";
import "./ILeverV1Factory.sol";

contract AgentRouter {
    address public immutable factory;
    mapping(uint8 => address) public agents;

    address public owner;

    event SetAgent(uint8 id, string name, address indexed location);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyPool() {
        require(
            ILeverV1Factory(factory).isValidPool(msg.sender),
            "Sender must be pool"
        );
        _;
    }

    constructor(address _factory) {
        owner = msg.sender;
        factory = _factory;
    }

    function setAgent(
        uint8 agentId,
        string memory agentName,
        address location
    ) external onlyOwner {
        require(IAgent(location).supportsInterface(0x00000000));
        agents[agentId] = location;
        emit SetAgent(agentId, agentName, location);
    }

    function purchase(
        uint8 agentId,
        bytes calldata data
    ) external payable onlyPool returns (bool) {
        require(agents[agentId] != address(0), "Invalid agent");
        return
            IAgent(agents[agentId]).purchase{value: msg.value}(
                msg.sender,
                data
            );
        // (bool txnSuccess, bytes memory _data) = agents[agentId].delegatecall(
        //   abi.encodeWithSignature("purchase(bytes)", data)
        // );
        // (bool fnSuccess, address collection, uint256 tokenId) = abi.decode(
        //   _data,
        //   (bool, address, uint256)
        // );

        // IERC721Minimal(collection).safeTransferFrom(
        //   address(this),
        //   msg.sender,
        //   tokenId
        // );

        //return txnSuccess && fnSuccess;
    }

    // function setApprovalForAll(
    //   address operator,
    //   address collection,
    //   bool state
    // ) external onlyOwner {
    //   IERC721Minimal(collection).setApprovalForAll(operator, state);
    // }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IAgent {
    error BadRequest();

    event Purchase(
        uint8 indexed marketplace,
        address indexed location,
        uint256 tokenId,
        uint256 price
    );

    function purchase(
        address recipient,
        bytes calldata data
    ) external payable returns (bool success);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC721Minimal {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function totalSupply() external view returns (uint256);

    function safeTransferFrom(address from, address to, uint256 id) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ILeverV1Factory {
    error DuplicatePool();
    error Unauthorized();

    // address indexed token0,
    // uint256 coverageRatio,
    // uint256 interestRate,
    // uint256 fee,
    // uint256 chargeInterval,
    // uint256 loanTerm,
    // uint256 paymentFrequency,
    // uint256 minLiquidity,
    // uint256 minDeposit,

    event DeployPool(address indexed pool, address indexed assetManager);

    function collectionExists(address collection) external view returns (bool);

    function isValidPool(address pool) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./OpenSeaOrderTypes.sol";

interface IOpenSeaExchange {
    function fulfillBasicOrder(
        OpenSeaOrderTypes.BasicOrderParameters calldata parameters
    ) external payable returns (bool fulfilled);

    function fulfillAdvancedOrder(
        OpenSeaOrderTypes.AdvancedOrder calldata advancedOrder,
        OpenSeaOrderTypes.CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    function getOrderStatus(
        bytes32 orderHash
    )
        external
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Agent.sol";

import "./IOpenSeaExchange.sol";

contract OpenSeaAgent is Agent {
    // using OpenSeaOrderTypes for OpenSeaOrderTypes.BasicOrderParameters;
    // using OpenSeaOrderTypes for OpenSeaOrderTypes.Advanced
    event Seaport(OpenSeaOrderTypes.BasicOrderParameters params);
    event sigs(bytes4 sig1, bytes4 sig2);
    event Status(bool a, bool b, uint256 c, uint256 d);

    address public constant EXCHANGE =
        0x00000000006c3852cbEf3e08E8dF289169EdE581;

    constructor(uint8 _agentId, address router) Agent(_agentId, router) {
        emit sigs(this.isValidSignature.selector, bytes4(0));
    }

    // function _purchase(
    //   address recipient,
    //   OpenSeaOrderTypes.AdvancedOrder memory advancedOrder,
    //   OpenSeaOrderTypes.CriteriaResolver[] memory criteriaResolvers,
    //   bytes32 fulfillerConduitKey
    // ) private returns (bool success) {
    //   success = IOpenSeaExchange(EXCHANGE).fulfillAdvancedOrder{
    //     value: msg.value
    //   }(advancedOrder, criteriaResolvers, fulfillerConduitKey, recipient);
    // }

    // function purchase(address recipient, bytes calldata data)
    //   external
    //   payable
    //   override
    //   returns (bool success)
    // {
    //   (
    //     OpenSeaOrderTypes.AdvancedOrder memory advancedOrder,
    //     OpenSeaOrderTypes.CriteriaResolver[] memory criteriaResolvers,
    //     bytes32 fulfillerConduitKey,
    //     uint256 price
    //   ) = abi.decode(data, (OpenSeaOrderTypes.AdvancedOrder, OpenSeaOrderTypes.CriteriaResolver[], bytes32, uint256));

    //   success = _purchase(
    //     recipient,
    //     advancedOrder,
    //     criteriaResolvers,
    //     fulfillerConduitKey
    //   );

    //   if (!success) {
    //     revert BadRequest();
    //   }

    //   // collection = parameters.offerToken;
    //   uint256 tokenId = advancedOrder.parameters.offer[0].identifierOrCriteria;

    //   emit Purchase(agentId, EXCHANGE, tokenId, price);
    // }

    function _purchase(
        address recipient,
        OpenSeaOrderTypes.BasicOrderParameters memory parameters
    ) private returns (bool success) {
        IOpenSeaExchange(EXCHANGE).fulfillBasicOrder{value: msg.value}(
            parameters
        );

        IERC721Minimal(parameters.offerToken).safeTransferFrom(
            address(this),
            recipient,
            parameters.offerIdentifier
        );
        success = true;
    }

    function purchase(
        address recipient,
        bytes calldata data
    )
        external
        payable
        override
        returns (
            bool success // address collection,
        )
    // uint256 tokenId
    {
        // (bool a, bool b, uint256 c, uint256 d) = IOpenSeaExchange(EXCHANGE)
        //   .getOrderStatus(
        //     0x8c34c6ab19d1939a39a475e926c48964f8030893c41b4c7997e33acec842e2c4
        //   );
        // emit Status(a, b, c, d);

        (
            OpenSeaOrderTypes.BasicOrderParameters memory parameters,
            uint256 price
        ) = abi.decode(data, (OpenSeaOrderTypes.BasicOrderParameters, uint256));

        success = _purchase(recipient, parameters);

        if (!success) {
            revert BadRequest();
        }

        // collection = parameters.offerToken;
        uint256 tokenId = parameters.offerIdentifier;

        emit Purchase(agentId, EXCHANGE, tokenId, price);
    }

    function setApprovalForAll(
        address operator,
        address collection,
        bool state
    ) external onlyOwner {
        IERC721Minimal(collection).setApprovalForAll(EXCHANGE, state);
    }
}

/* (params: (
  0x0000000000000000000000000000000000000000,
  0,
  3,
  0x736b78bd08095461b1de06f4eec5b505e5c5f96f,
  0x004c00500000ad104d7dbd00e3ae0a5c00560c00,
  0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d,
  3596,
  1,
  2,
  1662360034,
  1662619234,
  0x0000000000000000000000000000000000000000000000000000000000000000,
  99961984364471261,
  0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000,
  0x0000000000000000000000000000000000000000000000000000000000000000,
  3,
  [
    (75810000000000000000, 0x736b78bd08095461b1de06f4eec5b505e5c5f96f),
    (1995000000000000000, 0x0000a26b00c1f0df003000390027140000faa719),
    (1995000000000000000, 0xa858ddc0445d8131dac4d1de01f834ffcba52ef1)
  ],
  0x2dc0f4e898da0c034f79a83be300d1b2ed0b4573d340e17a529ec10bb998725406cb247cc2eeca40d30d038e6af8f9b47d09d16b5cf887869de34b138df39c7d1c)
  ) */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title OrderTypes
 * @notice This library contains order types for the OpenSea exchange.
 */
library OpenSeaOrderTypes {
    enum OrderType {
        FULL_OPEN,
        PARTIAL_OPEN,
        FULL_RESTRICTED,
        PARTIAL_RESTRICTED
    }

    enum BasicOrderType {
        ETH_TO_ERC721_FULL_OPEN,
        ETH_TO_ERC721_PARTIAL_OPEN,
        ETH_TO_ERC721_FULL_RESTRICTED,
        ETH_TO_ERC721_PARTIAL_RESTRICTED,
        ETH_TO_ERC1155_FULL_OPEN,
        ETH_TO_ERC1155_PARTIAL_OPEN,
        ETH_TO_ERC1155_FULL_RESTRICTED,
        ETH_TO_ERC1155_PARTIAL_RESTRICTED,
        ERC20_TO_ERC721_FULL_OPEN,
        ERC20_TO_ERC721_PARTIAL_OPEN,
        ERC20_TO_ERC721_FULL_RESTRICTED,
        ERC20_TO_ERC721_PARTIAL_RESTRICTED,
        ERC20_TO_ERC1155_FULL_OPEN,
        ERC20_TO_ERC1155_PARTIAL_OPEN,
        ERC20_TO_ERC1155_FULL_RESTRICTED,
        ERC20_TO_ERC1155_PARTIAL_RESTRICTED,
        ERC721_TO_ERC20_FULL_OPEN,
        ERC721_TO_ERC20_PARTIAL_OPEN,
        ERC721_TO_ERC20_FULL_RESTRICTED,
        ERC721_TO_ERC20_PARTIAL_RESTRICTED,
        ERC1155_TO_ERC20_FULL_OPEN,
        ERC1155_TO_ERC20_PARTIAL_OPEN,
        ERC1155_TO_ERC20_FULL_RESTRICTED,
        ERC1155_TO_ERC20_PARTIAL_RESTRICTED
    }

    enum BasicOrderRouteType {
        ETH_TO_ERC721,
        ETH_TO_ERC1155,
        ERC20_TO_ERC721,
        ERC20_TO_ERC1155,
        ERC721_TO_ERC20,
        ERC1155_TO_ERC20
    }

    enum ItemType {
        NATIVE,
        ERC20,
        ERC721,
        ERC1155,
        ERC721_WITH_CRITERIA,
        ERC1155_WITH_CRITERIA
    }

    enum Side {
        OFFER,
        CONSIDERATION
    }

    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address payable recipient;
    }

    struct OrderComponents {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 counter;
    }

    struct SpentItem {
        ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
    }

    struct ReceivedItem {
        ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
        address payable recipient;
    }

    struct BasicOrderParameters {
        address considerationToken;
        uint256 considerationIdentifier;
        uint256 considerationAmount;
        address payable offerer;
        address zone;
        address offerToken;
        uint256 offerIdentifier;
        uint256 offerAmount;
        BasicOrderType basicOrderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 offererConduitKey;
        bytes32 fulfillerConduitKey;
        uint256 totalOriginalAdditionalRecipients;
        AdditionalRecipient[] additionalRecipients;
        bytes signature;
    }

    struct AdditionalRecipient {
        uint256 amount;
        address payable recipient;
    }

    struct OrderParameters {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 totalOriginalConsiderationItems;
    }

    struct Order {
        OrderParameters parameters;
        bytes signature;
    }

    struct AdvancedOrder {
        OrderParameters parameters;
        uint120 numerator;
        uint120 denominator;
        bytes signature;
        bytes extraData;
    }

    struct OrderStatus {
        bool isValidated;
        bool isCancelled;
        uint120 numerator;
        uint120 denominator;
    }

    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }

    struct Fulfillment {
        FulfillmentComponent[] offerComponents;
        FulfillmentComponent[] considerationComponents;
    }

    struct FulfillmentComponent {
        uint256 orderIndex;
        uint256 itemIndex;
    }

    struct Execution {
        ReceivedItem item;
        address offerer;
        bytes32 conduitKey;
    }
}
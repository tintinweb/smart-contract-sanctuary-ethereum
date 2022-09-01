// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./SVGFactory.sol";
import "./Lockable.sol";
import "./ERC721C.sol";

// Errors
error SVGNFT__SoldOut();
error SVGNFT__IncorrectMintPrice();
error SVGNFT__PendingRandomNumber();
error SVGNFT__TokenLocked();
error SVGNFT__TransferFailed();
error SVGNFT__ContractPaused();


/**@title An onchain SVG NFT contract
 * @author Swarna Lye
 * @notice This contract is for a verifiably random onchain SVG NFT contract
 * @dev This implements Chainlink VRF V2
 */
contract SVGNFT is
    VRFConsumerBaseV2,
    ERC721C,
    Lockable,
    SVGFactory
{
    bytes32 immutable private keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint64 private subscriptionId;
    uint32 immutable private callbackGasLimit = 2500000;
    uint16 immutable private requestConfirmations = 3;
    uint32 immutable private numWords = 1;
    uint256 immutable private maxSupply;
    uint256 private mintPrice;
    VRFCoordinatorV2Interface private COORDINATOR;
    bool private paused = false;

    mapping(uint256 => uint256) public requestIdToTokenId;

    event RequestedRandomSVG(uint256 requestId, uint256 tokenId);
    event CompletedNFTMint(uint256 tokenId, string tokenURI);

    constructor(uint64 _subscriptionId, address _vrfCoordinator, uint256 _mintPrice)
        ERC721C("Random SVG NFT", "rSVGNFT")
        VRFConsumerBaseV2(_vrfCoordinator)
        Lockable(address(this))
        SVGFactory()
    {
        subscriptionId = _subscriptionId;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        maxSupply = 500;
        mintPrice = _mintPrice;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function updateMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function create() external payable returns (uint256) {
        if (totalSupply() + 1 > maxSupply) {
            revert SVGNFT__SoldOut();
        }
        if (msg.value != mintPrice) {
            revert SVGNFT__IncorrectMintPrice();
        }
        if (paused) {
            revert SVGNFT__ContractPaused();
        }
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        uint256 tokenId = _owners.length;
        requestIdToTokenId[requestId] = tokenId;
        _mint(msg.sender, 1);
        emit RequestedRandomSVG(requestId, tokenId);
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomness) internal override {
        uint256 tokenId = requestIdToTokenId[requestId];
        string memory svg = _generateSVG(randomness[0]);
        string memory _imageURI = _svgToImageURI(svg);
        string memory _tokenURI = _formatTokenURI(_imageURI);
        _setTokenURI(tokenId, _tokenURI);
        emit CompletedNFTMint(tokenId, _tokenURI); 
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override(ERC721C) {
        if (isTokenLocked(_tokenId) == true) {
            revert SVGNFT__TokenLocked();
        }
        super.transferFrom(_from, _to, _tokenId);
    }


    function withdrawFunds() external {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        if (!sent) {
            revert SVGNFT__TransferFailed();
        }
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function updateChainlinkSubscriptionId(uint64 _subId) external onlyOwner {
        subscriptionId = _subId;
    }

    function getMaxSupply() external view returns (uint256) {
        return maxSupply;
    }

    function getMintPrice() external view returns (uint256) {
        return mintPrice;
    }

    function isContractPaused() external view returns (bool) {
        return paused;
    }

    function getSubscriptionId() external view returns (uint64) {
        return subscriptionId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Base64.sol";

contract SVGFactory {
    uint256 private immutable maxPathCount;
    uint256 private immutable minPathCount;
    uint256 private immutable minPathCommandCount;
    uint256 private immutable maxPathCommandCount;
    uint256 private immutable size;
    string[] private colors;

    constructor() {
        size = 500;
        maxPathCount = 10;
        minPathCount = 5;
        minPathCommandCount = 3;
        maxPathCommandCount = 8;
        colors = [
            "red",
            "blue",
            "green",
            "yellow",
            "black",
            "pink",
            "orange",
            "purple",
            "mediumspringgreen",
            "mediumslateblue",
            "hotpink"
        ];
    }

    function _generateSVG(uint256 randomNumber) internal view returns (string memory finalSVG) {
        uint256 numberOfPaths = (randomNumber % (maxPathCount - minPathCount)) + minPathCount;
        finalSVG = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' height='",
                uint2str(size),
                "' width='",
                uint2str(size),
                "'>"
            )
        );
        for (uint256 i = 0; i < numberOfPaths; i++) {
            uint256 newRNG = uint256(keccak256(abi.encode(randomNumber, i)));
            string memory pathSVG = _generatePath(newRNG);
            finalSVG = string(abi.encodePacked(finalSVG, pathSVG));
        }
        finalSVG = string(abi.encodePacked(finalSVG, "</svg>"));
        return finalSVG;
    }

    function _generatePath(uint256 randomNumber) internal view returns (string memory pathSVG) {
        uint256 numberOfPathCommands = (randomNumber %
            (maxPathCommandCount - minPathCommandCount)) + 1;
        // uint256 binary = (randomNumber * 3) % 2;
        pathSVG = "<path d='";
        for (uint256 i = 0; i < numberOfPathCommands; i++) {
            uint256 newRNG = uint256(keccak256(abi.encode(randomNumber, size + i)));
            string memory pathCommand;
            if (i == 0) {
                pathCommand = _generatePathCommand(newRNG, true);
            } else {
                pathCommand = _generatePathCommand(newRNG, false);
            }
            pathSVG = string(abi.encodePacked(pathSVG, pathCommand));
        }
        string memory color = colors[randomNumber % colors.length];
        pathSVG = string(abi.encodePacked(pathSVG, "' fill='", color, "'/>"));
        return pathSVG;
    }

    function _generatePathCommand(uint256 randomNumber, bool first)
        internal
        view
        returns (string memory pathCommand)
    {
        if (first) {
            pathCommand = "M";
        } else {
            pathCommand = "L";
        }
        uint256 param1 = (uint256(keccak256(abi.encode(randomNumber, size * 3))) % size) + 1;
        uint256 param2 = (uint256(keccak256(abi.encode(randomNumber, size * 4))) % size) + 1;
        pathCommand = string(
            abi.encodePacked(pathCommand, uint2str(param1), " ", uint2str(param2))
        );
    }

    function _svgToImageURI(string memory svg) internal pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        string memory imageURI = string(abi.encodePacked(baseURL, svgBase64Encoded));
        return imageURI;
    }

    function _formatTokenURI(string memory imageURI) internal pure returns (string memory) {
        string memory baseURL = "data:application/json;base64,";
        string memory tokenURL = Base64.encode(
            bytes(
                abi.encodePacked(
                    '{"name":"On-Chain SVG NFT", "description": "A random on-chain SVG NFT created using Chainlink VRF", "attributes": "", "image": "',
                    imageURI,
                    '"}'
                )
            )
        );
        string memory tokenURI = string(abi.encodePacked(baseURL, tokenURL));
        return tokenURI;
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Errors
error Lockable__TokenLocked();
error Lockable__TokenNotLocked();
error Lockable__NotTokenOwner();
error Lockable__InvalidController();
error Lockable__NotAuthorized();

abstract contract Lockable {
    IERC721 tokenContract;

    mapping(uint256 => bool) private tokenIdLocked;
    mapping(uint256 => address) private tokenIdController;

    constructor(address _tokenAddress) {
        tokenContract = IERC721(_tokenAddress);
    }

    function lockToken(
        uint256 _tokenId,
        address _controller,
        bool _proxy
    ) public {
        if (tokenIdLocked[_tokenId] == true) {
            revert Lockable__TokenLocked();
        }
        address tokenOwner;
        if (_proxy) {
            tokenOwner = tx.origin;
        } else {
            tokenOwner = msg.sender;
        }
        if (tokenOwner != tokenContract.ownerOf(_tokenId)) {
            revert Lockable__NotTokenOwner();
        }
        if (_controller == address(0)) {
            revert Lockable__InvalidController();
        }
        tokenIdLocked[_tokenId] = true;
        tokenIdController[_tokenId] = _controller;
    }

    function unlockToken(uint256 _tokenId) public {
        if (tokenIdLocked[_tokenId] != true) {
            revert Lockable__TokenNotLocked();
        }
        if (msg.sender != tokenIdController[_tokenId]) {
            revert Lockable__NotAuthorized();
        }
        tokenIdLocked[_tokenId] = false;
        delete tokenIdController[_tokenId];
    }

    function isTokenLocked(uint256 _tokenId) public view returns (bool) {
        return tokenIdLocked[_tokenId];
    }

    function getTokenController(uint256 _tokenId) public view returns (address) {
        return tokenIdController[_tokenId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./OwnableExt.sol";

// Errors
error ERC721C__TokenIdDoesNotExist();
error ERC721C__InvalidAddress();
error ERC721C__IndexOverflow();
error ERC721C__InvalidFromAddress();
error ERC721C__Unauthorized();
error ERC721C__NonErc721RReceiver();
error ERC721C__IndexExceedAddressBalance();
error ERC721C__NotTokenOwner();
error ERC721C__InvalidMintAmount();

abstract contract ERC721C is OwnableExt {
    /*///////////////////////////////////////////////////////////////
                                 ERC721 VARIABLES
    //////////////////////////////////////////////////////////////*/
    // Array which maps token ID to address (index is tokenID)
    address[] internal _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /*///////////////////////////////////////////////////////////////
                                 METADATA VARIABLES
    //////////////////////////////////////////////////////////////*/
    string private NAME;
    string private SYMBOL;
    string private baseURI;
    mapping(uint256 => string) private tokenURIs;

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /*///////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier tokenExists(uint256 _tokenId) {
        if (!_exists(_tokenId)) {
            revert ERC721C__TokenIdDoesNotExist();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(string memory _name, string memory _symbol) {
        NAME = _name;
        SYMBOL = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x780e9d63 || // ERC165 Interface ID for ERC721Enumerable
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                                 METADATA
    //////////////////////////////////////////////////////////////*/
    function name() external view virtual returns (string memory) {
        return NAME;
    }

    function symbol() external view virtual returns (string memory) {
        return SYMBOL;
    }

    function setBaseURI(string memory _baseURIString) external virtual onlyOwner {
        baseURI = _baseURIString;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI)
        internal
        virtual
        tokenExists(_tokenId)
    {
        tokenURIs[_tokenId] = _tokenURI;
    }

    function tokenURI(uint256 _tokenId)
        external
        view
        virtual
        tokenExists(_tokenId)
        returns (string memory)
    {
        string memory _tokenURI = tokenURIs[_tokenId];
        string memory _base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(_base).length == 0) {
            return _tokenURI;
        }
        // If there is no token URI, return the base URI concatenated with tokenId.
        if (bytes(_tokenURI).length == 0) {
            return string(abi.encodePacked(_base, _tokenId));
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_base, _tokenURI));
        }
    }

    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        return (_tokenId < _owners.length && _owners[_tokenId] != address(1));
    }

    function balanceOf(address _owner) public view virtual returns (uint256) {
        if (_owner == address(0)) {
            revert ERC721C__InvalidAddress();
        }
        uint256 count;
        uint256 supply = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i; i < supply; i++) {
                if (_owner == ownerOf(i)) {
                    count += 1;
                }
            }
        }
        return count;
    }

    function ownerOf(uint256 _tokenId) public view virtual returns (address) {
        if (_tokenId >= _owners.length) {
            revert ERC721C__IndexOverflow();
        }
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (_tokenId; ; _tokenId++) {
                if (_owners[_tokenId] != address(0)) {
                    return _owners[_tokenId];
                }
            }
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual tokenExists(_tokenId) {
        if (_from != ownerOf(_tokenId)) {
            revert ERC721C__InvalidFromAddress();
        }
        bool ownerOrApproved = (msg.sender == _from ||
            msg.sender == _tokenApprovals[_tokenId] ||
            _operatorApprovals[_from][msg.sender]);
        if (!ownerOrApproved) {
            revert ERC721C__Unauthorized();
        }

        // delete previous owner's token approval
        delete _tokenApprovals[_tokenId];
        _owners[_tokenId] = _to;

        if (_tokenId > 0 && _owners[_tokenId - 1] == address(0)) {
            _owners[_tokenId - 1] = _from;
        }

        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual {
        if (!_checkOnERC721Received(_from, _to, _tokenId, _data)) {
            revert ERC721C__NonErc721RReceiver();
        }
        transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (_to.code.length == 0) return true;

        try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == IERC721Receiver(_to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert ERC721C__NonErc721RReceiver();
            }
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 ENUMERABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalSupply() public view virtual returns (uint256) {
        return _owners.length - _getBurntCount();
    }

    function tokenByIndex(uint256 _index) external view virtual returns (uint256) {
        if (_index >= (_owners.length - _getBurntCount())) {
            revert ERC721C__IndexOverflow();
        }
        return _index + _getBurntCountBeforeIndex(_index);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        virtual
        returns (uint256 tokenId)
    {
        if (_index >= balanceOf(_owner)) {
            revert ERC721C__IndexExceedAddressBalance();
        }
        uint256 count;
        uint256 supply = _owners.length;

        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (tokenId; tokenId < supply; tokenId++) {
                if (_owner == ownerOf(tokenId)) {
                    if (count == _index) {
                        return tokenId;
                    } else {
                        count += 1;
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                                 TOKEN APPROVALS
    //////////////////////////////////////////////////////////////*/

    function approve(address _approved, uint256 _tokenId) external virtual {
        if (msg.sender != ownerOf(_tokenId)) {
            revert ERC721C__NotTokenOwner();
        }
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external virtual {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view virtual returns (address) {
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        virtual
        returns (bool)
    {
        return _operatorApprovals[_owner][_operator];
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/ BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address _to, uint256 _amount) internal virtual {
        _safeMint(_to, _amount, "");
    }

    function _safeMint(
        address _to,
        uint256 _amount,
        bytes memory _data
    ) internal virtual {
        if (!_checkOnERC721Received(address(0), _to, _owners.length - 1, _data)) {
            revert ERC721C__NonErc721RReceiver();
        }
        _mint(_to, _amount);
    }

    function _mint(address _to, uint256 _amount) internal virtual {
        if (_amount == 0) {
            revert ERC721C__InvalidMintAmount();
        }

        uint256 _currentIndex = _owners.length;

        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i; i < _amount - 1; i++) {
                _owners.push();
                emit Transfer(address(0), _to, _currentIndex + i);
            }
        }

        // set last index to receiver
        _owners.push(_to);
        emit Transfer(address(0), _to, _currentIndex + (_amount - 1));
    }

    function _burn(uint256 _tokenId) internal virtual tokenExists(_tokenId) {
        address _owner = ownerOf(_tokenId);
        _owners[_tokenId] = address(1);
        delete _tokenApprovals[_tokenId];

        if (_tokenId > 0 && _owners[_tokenId - 1] == address(0)) {
            _owners[_tokenId - 1] = _owner;
        }

        emit Transfer(_owner, address(1), _tokenId);
    }

    function _getBurntCount() internal view virtual returns (uint256 burnCount) {
        uint256 supply = _owners.length;
        for (uint256 i; i < supply; i++) {
            if (_owners[i] == address(1)) {
                burnCount += 1;
            }
        }
    }

    function _getBurntCountBeforeIndex(uint256 _index)
        internal
        view
        virtual
        returns (uint256 burnCount)
    {
        uint256 supply = _owners.length;
        if (_index >= supply) {
            revert ERC721C__IndexOverflow();
        }
        for (uint256 i; i <= _index; i++) {
            if (_owners[i] == address(1)) {
                burnCount += 1;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

pragma solidity ^0.8.7;

error Ownable__NotOwner();
error Ownable__NotNominee();
error Ownable__IncorrectPassword();
error Ownable__InvalidAddress();

abstract contract OwnableExt {
    address private _owner;
    address private _nominee;

    mapping(address => bytes32) private nomineeToHash;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        if (owner() != msg.sender) {
            revert Ownable__NotOwner();
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0));
    }

    // 2 step process to transfer ownership
    // - existing owner calls nominateNewOwner function with nominee address
    // - nominee then accepts the nomination by calling acceptNomination which results in the transfer of ownership
    // Safer way of transferring ownership (in case of transferring to the wrong address directly)
    function nominateNewOwner(address _nomineeAdd) external virtual onlyOwner {
        _nominee = _nomineeAdd;
    }

    function acceptNomination() external virtual {
        if (msg.sender != _nominee) {
            revert Ownable__NotNominee();
        }
        _nominee = address(0);
        _transferOwnership(msg.sender);
    }

    // Similar 2 step process to transfer ownership as above but with the addition of password
    // Choose a password then use hashString function to get the hashedString, include the hashedString together with nominee address to nominate a new owner
    // Nominee would need to include the password to accept the nomination
    function nominateNewOwnerPW(address _nomineeAdd, bytes32 _hashedString)
        external
        virtual
        onlyOwner
    {
        nomineeToHash[_nomineeAdd] = _hashedString;
    }

    function acceptNominationPW(string memory _password) external virtual {
        if (msg.sender != _nominee) {
            revert Ownable__NotNominee();
        }
        if (hashString(_password) != nomineeToHash[msg.sender]) {
            revert Ownable__IncorrectPassword();
        }
        delete nomineeToHash[msg.sender];
        _transferOwnership(msg.sender);
    }

    function hashString(string memory _string) public pure virtual returns (bytes32 hashedString) {
        hashedString = keccak256(abi.encodePacked(_string));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) external virtual onlyOwner {
        if (_newOwner == address(0)) {
            revert Ownable__InvalidAddress();
        }
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address _newOwner) internal virtual {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }
}
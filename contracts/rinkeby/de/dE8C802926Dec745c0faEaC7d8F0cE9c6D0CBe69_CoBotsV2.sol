// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "../interfaces/ICoBotsRenderer.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract CoBots is ERC721A, VRFConsumerBaseV2, Ownable, ReentrancyGuard {
    // Constants
    uint8 public constant MAX_MINT_PER_ADDRESS = 20;
    uint8 public constant MINT_GIVEAWAYS = 30;
    uint8 public constant MINT_FOUNDERS_AND_GIVEAWAYS = 50;
    uint256 public constant RAFFLE_DRAW_DELAY = 1 minutes;
    uint8 public constant COORDINATION_RAFFLE_THRESHOLD = 95; // percentage of MAX_COBOTS
    // These are set only once in constructor but are not constant for testing purposes
    uint256 public MINT_PUBLIC_PRICE;
    uint16 public MAX_COBOTS;
    uint8 public MAIN_RAFFLE_WINNERS_COUNT;
    uint72 public MAIN_RAFFLE_PRIZE;
    uint8 public COORDINATION_RAFFLE_WINNERS_COUNT;
    uint72 public COORDINATION_RAFFLE_PRIZE;
    uint256 public COBOTS_MINT_DURATION;
    uint256 public COBOTS_MINT_RAFFLE_DELAY;
    uint256 public COBOTS_REFUND_DURATION;

    // CoBots states variables
    uint8[] public coBotsSeeds;
    bool[] public coBotsStatusDisabled;
    bool[] public coBotsColors;
    bool[] public coBotsRefunded;
    uint16 public coBotsColorAgreement;

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// Schedule ////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    uint256 public publicSaleStartTimestamp;
    uint256 public mintedOutTimestamp;

    function openPublicSale() external onlyOwner {
        require(publicSaleStartTimestamp == 0, "Public sale already started");
        publicSaleStartTimestamp = block.timestamp;
    }

    function isPublicSaleOpen() public view returns (bool) {
        return
            publicSaleStartTimestamp != 0 &&
            block.timestamp > publicSaleStartTimestamp &&
            block.timestamp < publicSaleStartTimestamp + COBOTS_MINT_DURATION;
    }

    modifier whenPublicSaleOpen() {
        require(isPublicSaleOpen(), "Public sale not open");
        _;
    }

    modifier whenPublicSaleClosed() {
        require(!isPublicSaleOpen(), "Public sale open");
        _;
    }

    function isMintedOut() public view returns (bool) {
        return _currentIndex == MAX_COBOTS;
    }

    modifier whenMintedOut() {
        require(isMintedOut(), "Co-Bots are not minted out");
        _;
    }

    modifier whenNotMintedOut() {
        require(!isMintedOut(), "Co-Bots are minted out");
        _;
    }

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// Marketplaces ////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    address public opensea;
    address public looksrare;
    mapping(address => bool) proxyToApproved;

    /// @notice Set opensea to `opensea_`.
    function setOpensea(address opensea_) external onlyOwner {
        opensea = opensea_;
    }

    /// @notice Set looksrare to `looksrare_`.
    function setLooksrare(address looksrare_) external onlyOwner {
        looksrare = looksrare_;
    }

    /// @notice Approve the communication and interaction with cross-collection interactions.
    function flipProxyState(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    /// @dev Modified for opensea and looksrare pre-approve.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return
            operator == address(ProxyRegistry(opensea).proxies(owner)) ||
            operator == looksrare ||
            proxyToApproved[operator] ||
            super.isApprovedForAll(owner, operator);
    }

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// Token ///////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    address public renderingContractAddress;
    ICoBotsRenderer renderer;

    function setRenderingContractAddress(address _renderingContractAddress)
        public
        onlyOwner
    {
        renderingContractAddress = _renderingContractAddress;
        renderer = ICoBotsRenderer(renderingContractAddress);
    }

    struct Parameters {
        uint16 maxCobots;
        uint72 mintPublicPrice;
        uint8 mainRaffleWinnersCount;
        uint24 timeUnit;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address _rendererAddress,
        address _opensea,
        address _looksrare,
        address vrfCoordinator,
        address link,
        bytes32 keyHash,
        Parameters memory parameters
    ) ERC721A(name_, symbol_) VRFConsumerBaseV2(vrfCoordinator) {
        setRenderingContractAddress(_rendererAddress);
        opensea = _opensea;
        looksrare = _looksrare;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        gasKeyHash = keyHash;
        MAX_COBOTS = parameters.maxCobots;
        MINT_PUBLIC_PRICE = parameters.mintPublicPrice;
        MAIN_RAFFLE_PRIZE =
            (parameters.mintPublicPrice * parameters.maxCobots) /
            20;
        MAIN_RAFFLE_WINNERS_COUNT = parameters.mainRaffleWinnersCount;
        COORDINATION_RAFFLE_WINNERS_COUNT =
            parameters.mainRaffleWinnersCount *
            2;
        COORDINATION_RAFFLE_PRIZE = MAIN_RAFFLE_PRIZE / 10;
        COBOTS_MINT_DURATION = parameters.timeUnit * 7;
        COBOTS_MINT_RAFFLE_DELAY = parameters.timeUnit;
        COBOTS_REFUND_DURATION = parameters.timeUnit * 7;

        coBotsSeeds = new uint8[](parameters.maxCobots);
        coBotsStatusDisabled = new bool[](parameters.maxCobots);
        coBotsColors = new bool[](parameters.maxCobots);
        coBotsRefunded = new bool[](parameters.maxCobots);
        coBotsColorAgreement = parameters.maxCobots / 2; // CoBots are minted 50%/50%
    }

    function _mint(address to, uint256 quantity) internal {
        require(quantity < 32, "Too many Co-Bots to mint in one batch");
        bytes32 seeds = keccak256(
            abi.encodePacked(
                quantity,
                msg.sender,
                msg.value,
                block.timestamp,
                block.difficulty
            )
        );
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _currentIndex + i;
            coBotsSeeds[tokenId] = uint8(seeds[i]);
            coBotsColors[tokenId] = tokenId % 2 == 0;
        }

        _safeMint(to, quantity);
    }

    function mintPublicSale(uint256 quantity)
        external
        payable
        whenPublicSaleOpen
        nonReentrant
    {
        require(
            msg.value == MINT_PUBLIC_PRICE * quantity,
            "Price does not match"
        );
        require(
            _currentIndex + quantity < MAX_COBOTS + 1,
            "There are not enough Co-Bots left to mint that amount"
        );
        require(
            ERC721A.balanceOf(_msgSender()) + quantity <= MAX_MINT_PER_ADDRESS,
            "Co-Bots: the requested quantity exceeds the maximum allowed"
        );

        _mint(_msgSender(), quantity);

        if (isMintedOut()) {
            mintedOutTimestamp = block.timestamp;
        }
    }

    function mintFoundersAndGiveaways(address to, uint256 quantity)
        external
        onlyOwner
    {
        require(
            quantity + _currentIndex <= MINT_FOUNDERS_AND_GIVEAWAYS,
            "Quantity exceeds founders and giveaways allowance"
        );

        _mint(to, quantity);

        if (isMintedOut()) {
            mintedOutTimestamp = block.timestamp;
        }
    }

    function updateCooperativeRaffleStatus() internal {
        if (cooperativeRaffleEnabled) {
            return;
        }
        if (
            ((block.timestamp <
                mintedOutTimestamp + COBOTS_MINT_RAFFLE_DELAY) ||
                (mintedOutTimestamp == 0 &&
                    block.timestamp <
                    publicSaleStartTimestamp +
                        COBOTS_MINT_DURATION +
                        COBOTS_MINT_RAFFLE_DELAY)) &&
            ((coBotsColorAgreement >=
                ((MAX_COBOTS / 100) * COORDINATION_RAFFLE_THRESHOLD)) ||
                (coBotsColorAgreement <=
                    MAX_COBOTS -
                        ((MAX_COBOTS / 100) * COORDINATION_RAFFLE_THRESHOLD)))
        ) {
            cooperativeRaffleEnabled = true;
        }
    }

    function toggleColors(uint256[] calldata tokenIds) external nonReentrant {
        bool commonColor = coBotsColors[tokenIds[0]];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                ERC721A.ownerOf(tokenIds[i]) == _msgSender(),
                "Only owner can toggle color"
            );
            require(
                commonColor == coBotsColors[tokenIds[i]],
                "Toggling colors in two different colors!"
            );
            coBotsColors[tokenIds[i]] = !coBotsColors[tokenIds[i]];
        }
        unchecked {
            coBotsColorAgreement = commonColor
                ? coBotsColorAgreement + uint16(tokenIds.length)
                : coBotsColorAgreement - uint16(tokenIds.length);
        }
        updateCooperativeRaffleStatus();
    }

    function toggleStatus(uint256 tokenId) public nonReentrant {
        require(
            ERC721A.ownerOf(tokenId) == _msgSender(),
            "Only owner can toggle status"
        );

        coBotsStatusDisabled[tokenId] = !coBotsStatusDisabled[tokenId];
    }

    function toggleStatuses(uint256[] calldata tokenIds) public nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            toggleStatus(tokenIds[i]);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");

        if (renderingContractAddress == address(0)) {
            return "";
        }

        return
            renderer.tokenURI(
                _tokenId,
                coBotsSeeds[_tokenId],
                !coBotsStatusDisabled[_tokenId],
                coBotsColors[_tokenId]
            );
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        require(
            drawCount ==
                (
                    cooperativeRaffleEnabled
                        ? MAIN_RAFFLE_WINNERS_COUNT +
                            COORDINATION_RAFFLE_WINNERS_COUNT
                        : MAIN_RAFFLE_WINNERS_COUNT
                ) ||
                (block.timestamp >
                    publicSaleStartTimestamp +
                        COBOTS_MINT_DURATION +
                        COBOTS_REFUND_DURATION),
            "Dev cannot withdraw before the end of the game"
        );
        (bool success, ) = _msgSender().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// Raffle //////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    bytes32 gasKeyHash;

    struct Winner {
        address winner;
        uint16 tokenId;
    }

    uint256 public lastDrawTimestamp;
    uint64 public s_subId;
    mapping(address => uint256) public prizePerAddress;
    Winner[] public winners;
    mapping(uint256 => uint256) public prizePerDraw;
    uint16 public drawCount;
    bool public cooperativeRaffleEnabled;

    function isDrawOpen() public view returns (bool) {
        return
            isMintedOut() &&
            block.timestamp > mintedOutTimestamp + COBOTS_MINT_RAFFLE_DELAY;
    }

    modifier whenDrawOpen() {
        require(isDrawOpen(), "Draw not active");
        _;
    }

    modifier whenRefundAllowed() {
        require(
            (block.timestamp >
                publicSaleStartTimestamp + COBOTS_MINT_DURATION) &&
                (block.timestamp <
                    publicSaleStartTimestamp +
                        COBOTS_MINT_DURATION +
                        COBOTS_REFUND_DURATION),
            "Refund period not open"
        );
        _;
    }

    function claimRefund(uint256[] calldata tokenIds)
        external
        nonReentrant
        whenRefundAllowed
        whenNotMintedOut
    {
        uint256 value;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (tokenId < MINT_FOUNDERS_AND_GIVEAWAYS) {
                continue;
            }
            require(
                ERC721A.ownerOf(tokenId) == _msgSender(),
                "You cannot claim a refund for a token you do not own"
            );
            if (!coBotsRefunded[tokenId]) {
                value += MINT_PUBLIC_PRICE;
                coBotsRefunded[tokenId] = true;
            }
        }
        require(value > 0, "No Co-Bots to refund");
        (bool success, ) = _msgSender().call{value: value}("");
        require(success, "Withdrawal failed");
    }

    function createSubscriptionAndFund(uint96 amount) external onlyOwner {
        if (s_subId == 0) {
            s_subId = COORDINATOR.createSubscription();
            COORDINATOR.addConsumer(s_subId, address(this));
        }
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(s_subId)
        );
    }

    function cancelSubscription() external onlyOwner {
        COORDINATOR.cancelSubscription(s_subId, _msgSender());
        s_subId = 0;
    }

    function draw() external nonReentrant whenDrawOpen returns (uint256) {
        require(
            drawCount <
                (
                    cooperativeRaffleEnabled
                        ? MAIN_RAFFLE_WINNERS_COUNT +
                            COORDINATION_RAFFLE_WINNERS_COUNT
                        : MAIN_RAFFLE_WINNERS_COUNT
                ),
            "Draw limit reached"
        );
        require(
            (lastDrawTimestamp + RAFFLE_DRAW_DELAY <= block.timestamp) ||
                drawCount == 0,
            "Draws take place once per minute"
        );
        lastDrawTimestamp = block.timestamp;
        uint256 currentPrizeMoney = drawCount < MAIN_RAFFLE_WINNERS_COUNT
            ? MAIN_RAFFLE_PRIZE
            : COORDINATION_RAFFLE_PRIZE;
        drawCount++;
        uint256 requestId = COORDINATOR.requestRandomWords(
            gasKeyHash,
            s_subId,
            5, // requestConfirmations
            500_000, // callbackGasLimit
            1 // numWords
        );
        prizePerDraw[requestId] = currentPrizeMoney;
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 selectedToken = randomWords[0];
        address winner = ERC721A.ownerOf(selectedToken % MAX_COBOTS);
        while (
            prizePerAddress[winner] > 0 ||
            (selectedToken % MAX_COBOTS >= MINT_GIVEAWAYS &&
                selectedToken % MAX_COBOTS < MINT_FOUNDERS_AND_GIVEAWAYS)
        ) {
            selectedToken = selectedToken >> 1;
            winner = ERC721A.ownerOf(selectedToken % MAX_COBOTS);
        }
        winners.push(Winner(winner, uint16(selectedToken % MAX_COBOTS)));
        prizePerAddress[winner] = prizePerDraw[requestId];
        (bool success, ) = winner.call{value: prizePerDraw[requestId]}("");
        require(success, "Transfer failed.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**128 - 1 (max value of uint128).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
    }

    // Compiler will pack the following 
    // _currentIndex and _burnCounter into a single 256bit word.
    
    // The tokenId of the next token to be minted.
    uint128 internal _currentIndex;

    // The number of tokens burned.
    uint128 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex times
        unchecked {
            return _currentIndex - _burnCounter;    
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (!ownership.burned) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        revert TokenIndexOutOfBounds();
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        revert();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant: 
                    // There will always be an ownership that has an address and is not burned 
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if _currentIndex + quantity > 3.4e38 (2**128) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
                updatedIndex++;
            }

            _currentIndex = uint128(updatedIndex);
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked { 
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ICoBotsRenderer {
    function SVG_TAG_START() external view returns (string memory);

    function SVG_TAG_END() external view returns (string memory);

    function tokenURI(
        uint256 tokenId,
        uint8 seed,
        bool status,
        bool color
    ) external view returns (string memory);

    function getRandomItems(uint256 tokenId, uint8 seed)
        external
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        );
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

pragma solidity ^0.8.12;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {CollectionEncoded} from "@clemlaflemme.eth/contracts/contracts/lib/renderers/RectEncoder.sol";
import {RendererCommons} from "@clemlaflemme.eth/contracts/contracts/lib/renderers/RendererCommons.sol";
import {RectRenderer} from "@clemlaflemme.eth/contracts/contracts/lib/renderers/RectRenderer.sol";
import {Array} from "@clemlaflemme.eth/contracts/contracts/lib/utils/Array.sol";
import {Integers} from "@clemlaflemme.eth/contracts/contracts/lib/utils/Integers.sol";
import "../interfaces/ICoBotsRendererV2.sol";
import "../interfaces/ICoBotsRenderer.sol";

/*  @title CoBots Renderer V2
    @author Clement Walter
    @dev Update color palette, remove colors and use metta instead of status
*/
contract CoBotsRendererV2 is Ownable, ReentrancyGuard, ICoBotsRendererV2 {
    using Array for string[];
    using Integers for uint256;

    address palettePointer;
    address collectionPointer;
    string[] characteristicNames;
    string[][] traitNames;
    string description;
    ICoBotsRenderer coBotsRenderer;

    event ColorPaletteChanged(address _palette);
    event CollectionChanged(address prevPointer, address newPointer);

    function storePalette(bytes memory palette) public {
        palettePointer = SSTORE2.write(palette);
        emit ColorPaletteChanged(palettePointer);
    }

    function storeCollection(CollectionEncoded memory collection) public {
        address prevPointer = collectionPointer;
        collectionPointer = SSTORE2.write(collection.traits);
        characteristicNames = collection.characteristicNames;
        traitNames = collection.traitNames;
        description = collection.description;
        emit CollectionChanged(prevPointer, collectionPointer);
    }

    constructor(address _coBotsRenderer) {
        coBotsRenderer = ICoBotsRenderer(_coBotsRenderer);
    }

    function getCoBotItems(uint256 tokenId, uint8 seed)
        public
        view
        returns (uint256[10] memory)
    {
        // Characteristics are stored in alphabetical order:
        uint256 eyesIndex;
        uint256 mouthIndex;
        uint256 antennaIndex;
        uint256 feetIndex;
        uint256 statusIndex = seed % 2;
        (eyesIndex, mouthIndex, antennaIndex, feetIndex) = coBotsRenderer
            .getRandomItems(tokenId, seed);

        uint256[10] memory items;
        items[0] = antennaIndex;
        items[1] = 0; // always Black for the Extravagainza
        items[2] = tokenId / 1000;
        items[3] = (tokenId / 100) % 10;
        items[4] = (tokenId / 10) % 10;
        items[5] = tokenId % 10;
        items[6] = eyesIndex;
        items[7] = feetIndex;
        items[8] = mouthIndex;
        items[9] = statusIndex;
        return items;
    }

    function getCoBotBytes(uint256[10] memory items)
        public
        view
        returns (bytes memory)
    {
        // but one needs another order for proper layering:
        return
            bytes.concat(
                RectRenderer.getTraitBytes(collectionPointer, 1, items[1]), // 1. Colour
                RectRenderer.getTraitBytes(collectionPointer, 2, items[2]), // 2. Digit 1
                RectRenderer.getTraitBytes(collectionPointer, 3, items[3]), // 3. Digit 2
                RectRenderer.getTraitBytes(collectionPointer, 4, items[4]), // 4. Digit 3
                RectRenderer.getTraitBytes(collectionPointer, 5, items[5]), // 5. Digit 4
                RectRenderer.getTraitBytes(collectionPointer, 6, items[6]), // 6. Eyes
                RectRenderer.getTraitBytes(collectionPointer, 8, items[8]), // 8. Mouth
                RectRenderer.getTraitBytes(collectionPointer, 0, items[0]), // 0. Antenna
                RectRenderer.getTraitBytes(collectionPointer, 7, items[7]), // 7. Feet
                items[9] == 1
                    ? RectRenderer.getTraitBytes(collectionPointer, 9, 0)
                    : new bytes(4) // 9. Status
            );
    }

    function imageURI(uint256[10] memory items)
        public
        view
        returns (string memory)
    {
        return
            string.concat(
                RendererCommons.DATA_URI,
                coBotsRenderer.SVG_TAG_START(),
                RectRenderer.decodeBytesMemoryToRects(
                    getCoBotBytes(items),
                    RendererCommons.getPalette(palettePointer)
                ),
                coBotsRenderer.SVG_TAG_END()
            );
    }

    function getCoBotAttributes(uint256[10] memory items)
        public
        view
        returns (string memory)
    {
        uint8[5] memory indexes = [6, 8, 0, 7, 9];
        string[] memory attributes = new string[](5);
        for (uint256 i = 0; i < 5; i++) {
            attributes[i] = string.concat(
                '{"trait_type": "',
                characteristicNames[indexes[i]],
                '", "value": "',
                traitNames[indexes[i]][items[indexes[i]]],
                '"}'
            );
        }
        return string.concat("[", attributes.join(","), "]");
    }

    function tokenURI(uint256 tokenId, uint8 seed)
        public
        view
        returns (string memory)
    {
        uint256[10] memory items = getCoBotItems(tokenId, seed);
        return
            string.concat(
                "data:application/json,",
                '{"image": "',
                imageURI(items),
                '"',
                ',"description": "',
                description,
                '"',
                ',"name": "Co-Bot #',
                tokenId.toString(),
                '"',
                ',"attributes": ',
                getCoBotAttributes(items),
                "}"
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Array} from "../utils/Array.sol";

error CoordinatesOutOfRange(uint256 coordinate);

struct Rect {
    uint32 x;
    uint32 y;
    uint32 width;
    uint32 height;
    uint32 fillIndex;
}

struct Trait {
    Rect[] rects;
    string name;
}

struct TraitEncoded {
    bytes rects;
    string name;
}

struct Characteristic {
    Trait[] traits;
    string name;
}

struct CharacteristicEncoded {
    bytes traits;
    string[] names;
    string name;
}

struct Collection {
    Characteristic[] characteristics;
    string description;
}

struct CollectionEncoded {
    bytes traits;
    string[][] traitNames;
    string[] characteristicNames;
    string description;
}

/**  @title RectEncoder
 *
 *   This library can be used (off-chain !) to encode a collection to be deployed and render on-chain images with the
 *   RectRenderer.
 *
 * @author Clement Walter <[email protected]>
 */
contract RectEncoder {
    using Array for string[];
    using Array for bytes[];
    using Array for uint16[];
    using Array for bytes4[];

    /** @dev Use this function to encode a single <rect> as expected by the renderer. Use this off-chain!
     *
     * @param rect The <rect> to encode
     * @return The encoded rectangle as a bytes4
     */
    function encodeRect(Rect memory rect) public pure returns (bytes4) {
        // each coordinates should use only 6 bits and is consequently stored like 00nnnnnn
        if (rect.x > 63) revert CoordinatesOutOfRange(rect.x);
        if (rect.y > 63) revert CoordinatesOutOfRange(rect.y);
        if (rect.width > 63) revert CoordinatesOutOfRange(rect.width);
        if (rect.height > 63) revert CoordinatesOutOfRange(rect.height);
        return
            bytes4(rect.x << 26) |
            bytes4(rect.y << 20) |
            bytes4(rect.width << 14) |
            bytes4(rect.height << 8) |
            bytes4(rect.fillIndex);
    }

    /** @dev Use this function to encode a _trait_, i.e. a list of <rect>s with a name, as expected by the renderer.
     *       Use this off-chain!
     *
     * @param trait The list of <rect>s to encode with a given name; should be shorter than 32 char.
     * @return The encoded list of rectangle
     */
    function encodeTrait(Trait memory trait)
        public
        pure
        returns (TraitEncoded memory)
    {
        bytes4[] memory rects = new bytes4[](trait.rects.length);
        for (uint256 i = 0; i < trait.rects.length; i++) {
            rects[i] = encodeRect(trait.rects[i]);
        }
        return TraitEncoded(rects.join(), trait.name);
    }

    /** @dev Use this function to encode a characteristic, i.e. a list of traits belongings to the same group. Note that
     *       there is no intrinsic difference between a characteristic and a whole collection (all the traits of all the
     *       characteristics) but it's how it's used and expected today so we keep the wording here.
     *       Use this off-chain and push the result using RendererCommon.storeBytes
     *  @param characteristic The list of Trait constituting the characteristic.
     *  @return The encoded characteristic (mainly a bytes memory whose encoding somehow follows solidity memory storage rules.)
     */
    function encodeCharacteristic(Characteristic memory characteristic)
        public
        pure
        returns (CharacteristicEncoded memory)
    {
        bytes[] memory rects = new bytes[](characteristic.traits.length);
        string[] memory names = new string[](characteristic.traits.length);
        uint16[] memory lengths = new uint16[](
            characteristic.traits.length + 1
        );
        uint16 cumSum = 4 +
            2 *
            uint16(characteristic.traits.length % type(uint16).max); // 2 extra bytes for storing start & end for each trait
        for (uint256 i = 0; i < characteristic.traits.length; i++) {
            TraitEncoded memory tmp = encodeTrait(characteristic.traits[i]);
            rects[i] = tmp.rects;
            names[i] = tmp.name;
            lengths[i] = cumSum;
            cumSum += uint16(rects[i].length % type(uint16).max);
        }
        lengths[characteristic.traits.length] = cumSum;
        return (
            CharacteristicEncoded(
                bytes.concat(
                    bytes2(
                        uint16(
                            (characteristic.traits.length + 1) %
                                type(uint16).max
                        )
                    ),
                    lengths.join(),
                    rects.join()
                ),
                names,
                characteristic.name
            )
        );
    }

    /** @dev Use this function to encode a full collection, i.e. a list of characteristics.
     *       Use this off-chain and push the result using RendererCommon.storeBytes
     *
     * @param collection The list of Characteristic constituting the collection. The description is just returned in the
     *        new object and can be used to store the description of the collection.
     * @return The encoded collection (mainly a bytes memory whose encoding somehow follows solidity memory storage rules.)
     */
    function encodeCollection(Collection memory collection)
        public
        pure
        returns (CollectionEncoded memory)
    {
        bytes[] memory traits = new bytes[](collection.characteristics.length);
        string[] memory characteristicNames = new string[](
            collection.characteristics.length
        );
        string[][] memory traitNames = new string[][](
            collection.characteristics.length
        );
        uint16[] memory lengths = new uint16[](
            collection.characteristics.length
        );
        // init characteristic pointer shift with 2 bytes for length + 2 bytes per characteristic
        uint16 cumSum = 2 +
            2 *
            uint16(collection.characteristics.length % type(uint16).max);
        for (uint256 i = 0; i < collection.characteristics.length; i++) {
            CharacteristicEncoded memory tmp = encodeCharacteristic(
                collection.characteristics[i]
            );
            lengths[i] = cumSum;
            traits[i] = tmp.traits;
            traitNames[i] = tmp.names;
            characteristicNames[i] = tmp.name;
            cumSum += uint16(traits[i].length % type(uint16).max);
        }
        return (
            CollectionEncoded(
                bytes.concat(
                    bytes2(
                        uint16(
                            collection.characteristics.length % type(uint16).max
                        )
                    ),
                    lengths.join(),
                    traits.join()
                ),
                traitNames,
                characteristicNames,
                collection.description
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";

import {Integers} from "../utils/Integers.sol";
import {Array} from "../utils/Array.sol";

/**  @title BaseRenderer
 *
 *   This library contains shared functionality and constants for the renderers.
 *
 * @author Clement Walter <[email protected]>
 */
library RendererCommons {
    using Integers for uint256;
    using Integers for uint8;
    using Array for string[];

    string public constant DATA_URI = "data:image/svg+xml,";
    string public constant XMLNS_HEADER =
        "xmlns=%27http://www.w3.org/2000/svg%27";
    string public constant SPACE = "%20";
    string public constant QUOTE = "%27";
    string public constant NUMBER_SIGN = "%23";
    string public constant TAG_START = "%3c";
    string public constant TAG_END = "/%3e";

    event BytesStored(address pointer);

    /**
     * @dev Usually colors are already defined in hex color space so we just concat all the colors. No check is made
     *      and this function only concatenates the input colors.
     * @param palette The list of colors as hex strings, without the leading #.
     * @return The concatenated colors as string. To be used as bytes afterwards.
     */
    function encodePalette(string[] memory palette)
        public
        pure
        returns (string memory)
    {
        return string.concat("0x", palette.join());
    }

    /** @dev Returns one single color reading directly from the storage.
     * @param pointer The pointer to the palette bytes array where each color is R, G, B at storage i, i+1, i+2.
     * @param index The index of the color to retrieve
     * @return The hexstring representation of the color, e.g. "a3120f".
     */
    function getFill(address pointer, uint256 index)
        public
        view
        returns (string memory)
    {
        bytes memory palette = SSTORE2.read(pointer, 3 * index, 3 * index + 3);

        return
            string.concat(
                uint8(palette[0]).toString(16, 2),
                uint8(palette[1]).toString(16, 2),
                uint8(palette[2]).toString(16, 2)
            );
    }

    /** @dev Returns one single color from a pre-loaded whole palette as a bytes array.
     * @param palette A bytes array encoding several RGB colors. Length should be a multiple of 3.
     * @param index The index of the color to retrieve
     * @return The hexstring representation of the color, e.g. "a3120f".
     */
    function getFill(bytes memory palette, uint256 index)
        public
        pure
        returns (string memory)
    {
        return
            string.concat(
                uint8(palette[3 * index]).toString(16, 2),
                uint8(palette[3 * index + 1]).toString(16, 2),
                uint8(palette[3 * index + 2]).toString(16, 2)
            );
    }

    /** @dev Decode the whole palette once for all and returns an array of hexstrings.
     * @param pointer The pointer to the palette bytes array where each color is at storage at i, i+1, i+2.
     * @return An array of hexstring representation of the color, e.g. "a3120f".
     */
    function getPalette(address pointer) public view returns (string[] memory) {
        bytes memory palette = SSTORE2.read(pointer);
        return getPalette(palette);
    }

    function getPalette(bytes memory palette)
        public
        pure
        returns (string[] memory)
    {
        uint256 paletteSize = palette.length / 3;
        string[] memory paletteHex = new string[](paletteSize);
        for (uint256 i = 0; i < paletteSize; i++) {
            paletteHex[i] = getFill(palette, i);
        }
        return paletteHex;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";

import {Integers} from "../utils/Integers.sol";
import {Bytes} from "../utils/Bytes.sol";
import {Array} from "../utils/Array.sol";

error InvalidLength(uint256 length);
error CharacteristicOutOfRange(uint256 characteristic);
error TraitOutOfRange(uint256 trait);

/**  @title RectRenderer
 *
 *   This library can be used to render on-chain images stored as a layering of rectangles.
 *   The returned images is an url safe encoded image uri.
 *
 * @author Clement Walter <[email protected]>
 */
library RectRenderer {
    using Integers for uint8;
    using Integers for uint256;
    using Bytes for bytes;
    using Array for string[];

    string public constant RECT_TAG_START = "%3crect%20x=%27";
    string public constant Y_TAG = "%27%20y=%27";
    string public constant WIDTH_TAG = "%27%20width=%27";
    string public constant HEIGHT_TAG = "%27%20height=%27";
    string public constant FILL_TAG = "%27%20fill=%27%23";
    string public constant RECT_TAG_END = "%27/%3e";

    /** @dev Retrieve the bytes for the given trait from the traits storage.
     *  @param pointer The pointer to the traits stored with SSTORE2.
     *  @param characteristicIndex The index of the characteristic in the collection.
     *  @param traitIndex The index of the trait in the characteristic.
     *  @return The bytes of the trait.
     */
    function getTraitBytes(
        address pointer,
        uint256 characteristicIndex,
        uint256 traitIndex
    ) public view returns (bytes memory) {
        uint16 characteristicsLength = SSTORE2.read(pointer, 0, 2).toUint16();

        if (characteristicsLength - 1 < characteristicIndex)
            revert CharacteristicOutOfRange(characteristicIndex);
        uint16 characteristicStart = SSTORE2
            .read(
                pointer,
                2 + 2 * characteristicIndex,
                2 + 2 * characteristicIndex + 2
            )
            .toUint16();
        uint16 traitsLength = SSTORE2
            .read(pointer, characteristicStart, characteristicStart + 2)
            .toUint16() - 1;
        if (traitsLength - 1 < traitIndex) revert TraitOutOfRange(traitIndex);
        bytes memory _indexes = SSTORE2.read(
            pointer,
            characteristicStart + 2 + 2 * traitIndex,
            characteristicStart + 2 + 2 * traitIndex + 4
        );
        return
            SSTORE2.read(
                pointer,
                characteristicStart + _indexes.toUint16(0),
                characteristicStart + _indexes.toUint16(2)
            );
    }

    function decodeBytes4ToRect(bytes4 rectBytes, string[] memory palette)
        public
        pure
        returns (string memory)
    {
        return decodeBytes4ToRect(rectBytes, palette, 0, 0);
    }

    function decodeBytes4ToRect(
        bytes4 rectBytes,
        string[] memory palette,
        uint256 offsetX,
        uint256 offsetY
    ) public pure returns (string memory) {
        return
            string.concat(
                RECT_TAG_START,
                (uint8(uint32(rectBytes >> 26)) + offsetX).toString(),
                Y_TAG,
                ((uint8(uint32(rectBytes >> 20)) & 0x3f) + offsetY).toString(),
                WIDTH_TAG,
                (uint8(uint32(rectBytes >> 14)) & 0x3f).toString(),
                HEIGHT_TAG,
                (uint8(uint32(rectBytes >> 8)) & 0x3f).toString(),
                FILL_TAG,
                palette[uint8(rectBytes[3])],
                RECT_TAG_END
            );
    }

    function decodeBytesMemoryToRects(
        bytes memory rectsBytes,
        string[] memory palette
    ) public pure returns (string memory) {
        if (rectsBytes.length % 4 != 0) {
            revert InvalidLength(rectsBytes.length);
        }
        uint256 nbRects = rectsBytes.length / 4;
        string[] memory rects = new string[](nbRects);
        for (uint256 i = 0; i < rects.length; i++) {
            rects[i] = decodeBytes4ToRect(
                bytes4(rectsBytes.toUint32(i * 4)),
                palette
            );
        }
        return rects.join();
    }
}

// SPDX-License-Identifier: MIT

/*
 * @title Arrays Utils
 * @author Clement Walter <[email protected]>
 *
 * @notice An attempt at implementing some of the widely used javascript's Array functions in solidity.
 */
pragma solidity ^0.8.12;

error EmptyArray();
error GlueOutOfBounds(uint256 length);

library Array {
    function join(string[] memory a, string memory glue)
        public
        pure
        returns (string memory)
    {
        uint256 inputPointer;
        uint256 gluePointer;

        assembly {
            inputPointer := a
            gluePointer := glue
        }
        return string(_joinReferenceType(inputPointer, gluePointer));
    }

    function join(string[] memory a) public pure returns (string memory) {
        return join(a, "");
    }

    function join(bytes[] memory a, bytes memory glue)
        public
        pure
        returns (bytes memory)
    {
        uint256 inputPointer;
        uint256 gluePointer;

        assembly {
            inputPointer := a
            gluePointer := glue
        }
        return _joinReferenceType(inputPointer, gluePointer);
    }

    function join(bytes[] memory a) public pure returns (bytes memory) {
        return join(a, bytes(""));
    }

    function join(bytes2[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 2, 0);
    }

    /// @dev Join the underlying array of bytes2 to a string.
    function join(uint16[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 2, 256 - 16);
    }

    function join(bytes3[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 3, 0);
    }

    function join(bytes4[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 4, 0);
    }

    function join(bytes8[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 8, 0);
    }

    function join(bytes16[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 16, 0);
    }

    function join(bytes32[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 32, 0);
    }

    function _joinValueType(
        uint256 a,
        uint256 typeLength,
        uint256 shiftLeft
    ) private pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            let inputLength := mload(a)
            let inputData := add(a, 0x20)
            let end := add(inputData, mul(inputLength, 0x20))

            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Initialize the length of the final bytes: length is typeLength x inputLength (array of bytes4)
            mstore(tempBytes, mul(inputLength, typeLength))
            let memoryPointer := add(tempBytes, 0x20)

            // Iterate over all bytes4
            for {
                let pointer := inputData
            } lt(pointer, end) {
                pointer := add(pointer, 0x20)
            } {
                let currentSlot := shl(shiftLeft, mload(pointer))
                mstore(memoryPointer, currentSlot)
                memoryPointer := add(memoryPointer, typeLength)
            }

            mstore(0x40, and(add(memoryPointer, 31), not(31)))
        }
        return tempBytes;
    }

    function _joinReferenceType(uint256 inputPointer, uint256 gluePointer)
        public
        pure
        returns (bytes memory tempBytes)
    {
        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Skip the first 32 bytes where we will store the length of the result
            let memoryPointer := add(tempBytes, 0x20)

            // Load glue
            let glueLength := mload(gluePointer)
            if gt(glueLength, 0x20) {
                revert(gluePointer, 0x20)
            }
            let glue := mload(add(gluePointer, 0x20))

            // Load the length (first 32 bytes)
            let inputLength := mload(inputPointer)
            let inputData := add(inputPointer, 0x20)
            let end := add(inputData, mul(inputLength, 0x20))

            // Initialize the length of the final string
            let stringLength := 0

            // Iterate over all strings (a string is itself an array).
            for {
                let pointer := inputData
            } lt(pointer, end) {
                pointer := add(pointer, 0x20)
            } {
                let currentStringArray := mload(pointer)
                let currentStringLength := mload(currentStringArray)
                stringLength := add(stringLength, currentStringLength)
                let currentStringBytesCount := add(
                    div(currentStringLength, 0x20),
                    gt(mod(currentStringLength, 0x20), 0)
                )

                let currentPointer := add(currentStringArray, 0x20)

                for {
                    let copiedBytesCount := 0
                } lt(copiedBytesCount, currentStringBytesCount) {
                    copiedBytesCount := add(copiedBytesCount, 1)
                } {
                    mstore(
                        add(memoryPointer, mul(copiedBytesCount, 0x20)),
                        mload(currentPointer)
                    )
                    currentPointer := add(currentPointer, 0x20)
                }
                memoryPointer := add(memoryPointer, currentStringLength)
                mstore(memoryPointer, glue)
                memoryPointer := add(memoryPointer, glueLength)
            }

            mstore(
                tempBytes,
                add(stringLength, mul(sub(inputLength, 1), glueLength))
            )
            mstore(0x40, and(add(memoryPointer, 31), not(31)))
        }
        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Integers Library updated from https://github.com/willitscale/solidity-util
 *
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 *
 * @author Clement Walter <[email protected]>
 */
library Integers {
    /**
     * To String
     *
     * Converts an unsigned integer to the string equivalent value, returned as bytes
     * Equivalent to javascript's toString(base)
     *
     * @param _number The unsigned integer to be converted to a string
     * @param _base The base to convert the number to
     * @param  _padding The target length of the string; result will be padded with 0 to reach this length while padding
     *         of 0 means no padding
     * @return bytes The resulting ASCII string value
     */
    function toString(
        uint256 _number,
        uint8 _base,
        uint8 _padding
    ) public pure returns (string memory) {
        uint256 count = 0;
        uint256 b = _number;
        while (b != 0) {
            count++;
            b /= _base;
        }
        if (_number == 0) {
            count++;
        }
        bytes memory res;
        if (_padding == 0) {
            res = new bytes(count);
        } else {
            res = new bytes(_padding);
        }
        for (uint256 i = 0; i < res.length; ++i) {
            b = _number % _base;
            if (b < 10) {
                res[res.length - i - 1] = bytes1(uint8(b + 48)); // 0-9
            } else {
                res[res.length - i - 1] = bytes1(uint8((b % 10) + 65)); // A-F
            }
            _number /= _base;
        }

        for (uint256 i = count; i < _padding; ++i) {
            res[res.length - i - 1] = hex"30"; // 0
        }

        return string(res);
    }

    function toString(uint256 _number) public pure returns (string memory) {
        return toString(_number, 10, 0);
    }

    function toString(uint256 _number, uint8 _base)
        public
        pure
        returns (string memory)
    {
        return toString(_number, _base, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ICoBotsRendererV2 {
    function tokenURI(uint256 tokenId, uint8 seed)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}

// SPDX-License-Identifier: MIT

/*
 * @title Solidity Bytes Arrays Utils
 * @author Clement Walter <[email protected]> from Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library Bytes {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) public pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (address tmp)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");

        assembly {
            tmp := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint8 tmp)
    {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x1), _start))
        }
    }

    function toBytes1(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes1 tmp)
    {
        require(_bytes.length >= _start + 1, "toBytes1_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x1), _start))
        }
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint16 tmp)
    {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x2), _start))
        }
    }

    function toUint16(bytes memory _bytes) public pure returns (uint16 tmp) {
        return toUint16(_bytes, 0);
    }

    function toUint24(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint24 tmp)
    {
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x3), _start))
        }
    }

    function toUint32(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint32 tmp)
    {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x4), _start))
        }
    }

    function toUint40(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint40 tmp)
    {
        require(_bytes.length >= _start + 5, "toUint40_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x5), _start))
        }
    }

    function toBytes5(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes5 tmp)
    {
        require(_bytes.length >= _start + 5, "toBytes5_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x5), _start))
        }
    }

    function toUint48(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint48 tmp)
    {
        require(_bytes.length >= _start + 6, "toUint48_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x6), _start))
        }
    }

    function toBytes6(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes6 tmp)
    {
        require(_bytes.length >= _start + 6, "toBytes6_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x6), _start))
        }
    }

    function toUint56(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint56 tmp)
    {
        require(_bytes.length >= _start + 7, "toUint56_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x7), _start))
        }
    }

    function toByes7(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes7 tmp)
    {
        require(_bytes.length >= _start + 7, "toBytes7_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x7), _start))
        }
    }

    function toUint64(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint64 tmp)
    {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x8), _start))
        }
    }

    function toBytes8(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint64 tmp)
    {
        require(_bytes.length >= _start + 8, "toBytes8_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x8), _start))
        }
    }

    function toUint96(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint96 tmp)
    {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0xc), _start))
        }
    }

    function toBytes12(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes12 tmp)
    {
        require(_bytes.length >= _start + 12, "toBytes12_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0xc), _start))
        }
    }

    function toUint128(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint128 tmp)
    {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x10), _start))
        }
    }

    function toBytes16(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes12 tmp)
    {
        require(_bytes.length >= _start + 16, "toBytes16_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x10), _start))
        }
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint256 tmp)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x20), _start))
        }
    }

    function toBytes32(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes32 tmp)
    {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x20), _start))
        }
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        public
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        public
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "../interfaces/ICoBotsRendererV2.sol";
import "./Schedule.sol";

error BatchLimitExceeded();
error WrongPrice();
error TotalSupplyExceeded();
error AllocationExceeded();
error ToggleMettaCallerNotOwner();
error ChainlinkSubscriptionNotFound();
error TransferFailed();
error MysteryChallengeSenderDoesNotOwnENS();
error MysteryChallengeValueDoesNotMatch();
error FulfillmentAlreadyFulfilled();
error FulfillRequestForNonExistentContest();
error FulfillRequestWithTokenNotOwnedByWinner();
error RedeemTokenNotOwner();
error RedeemTokenAlreadyRedeemed();
error NoGiveawayToTrigger();
error InsufficientFunds();
error WithdrawalFailed();

contract CoBotsV2 is
    ERC721A,
    VRFConsumerBaseV2,
    Ownable,
    ReentrancyGuard,
    Schedule
{
    // Events
    event RendererContractUpdated(address indexed renderer);
    event MettaToggled(uint256 indexed tokenId, bool isMetta);
    event CheckpointDrawn(uint256 indexed requestId, Prize prize);
    event CheckpointFulfilled(
        uint256 indexed requestId,
        Prize prize,
        Winner winner
    );
    event GiveawayFinished();
    event Withdrawal(uint256 amount);

    // Data structures
    struct Prize {
        uint16 checkpoint;
        uint72 amount;
        bool isContest;
    }

    struct MysteryChallenge {
        uint256 ensId;
        uint256 value;
        uint8 prizeIndex;
    }

    struct Parameters {
        uint8 cobotsV1Discount;
        uint16 mintOutFoundersWithdrawalDelay;
        uint16 grandPrizeDelay;
        uint16 maxCobots;
        uint24 contestDuration;
        uint72 mintPublicPrice;
    }

    // Constants
    uint8 public constant MINT_FOUNDERS = 3;
    uint8 public constant MINT_BATCH_LIMIT = 32;
    Parameters public PARAMETERS;
    Prize[] public PRIZES;
    MysteryChallenge private MYSTERY_CHALLENGE;
    IERC721 ENS;
    IERC721Enumerable COBOTS_V1;

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// Token ///////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    address public renderingContractAddress;
    ICoBotsRendererV2 public renderer;
    uint8[] public coBotsSeeds;
    mapping(uint256 => bool) public coBotsV1Redeemed;
    uint256 private _redeemedCount;

    function setRenderingContractAddress(address _renderingContractAddress)
        public
        onlyOwner
    {
        renderingContractAddress = _renderingContractAddress;
        renderer = ICoBotsRendererV2(renderingContractAddress);
        emit RendererContractUpdated(renderingContractAddress);
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address _rendererAddress,
        address vrfCoordinator,
        address link,
        bytes32 keyHash,
        Parameters memory _parameters,
        Prize[] memory _prizes,
        address ens,
        address cobotsV1,
        MysteryChallenge memory _mysteryChallenge
    ) ERC721A(name_, symbol_) VRFConsumerBaseV2(vrfCoordinator) {
        setRenderingContractAddress(_rendererAddress);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        gasKeyHash = keyHash;
        PARAMETERS = _parameters;
        for (uint256 i = 0; i < _prizes.length; i++) {
            PRIZES.push(_prizes[i]);
        }
        ENS = IERC721(ens);
        COBOTS_V1 = IERC721Enumerable(cobotsV1);
        MYSTERY_CHALLENGE = _mysteryChallenge;
    }

    function _mintCoBots(address to, uint256 quantity) internal {
        if (quantity > MINT_BATCH_LIMIT) revert BatchLimitExceeded();
        bytes32 seeds = keccak256(
            abi.encodePacked(
                quantity,
                msg.sender,
                msg.value,
                block.timestamp,
                block.difficulty
            )
        );
        for (uint256 i = 0; i < quantity; i++) {
            coBotsSeeds.push(uint8(seeds[i]) << 1); // insure last digit is 0, used for Metta status
        }

        ERC721A._safeMint(to, quantity);
    }

    /**
     * Mints a batch of Co-Bots to the sender.
     *
     * @dev The tokenIdsV1 parameter can be empty. The call will revert only if the sender pretends to own some
     *      Co-Bots V1 that they actually don't. However it accepts already redeemed token and just ignore them silently.
     *      This is to make it easier for people using etherscan to copy a bunch of token Ids without having to
     *      manually check if they are redeemed or not. However, it is optimal in terms of gas fees to only give
     *      tokenIds if they can actually be redeemed.
     * @param quantity The number of COBOTS to mint.
     * @param tokenIdsV1 A list of V1 Co-Bots token Ids owned by the sender, used to determine the discount.
     */
    function mintPublicSale(uint256 quantity, uint256[] memory tokenIdsV1)
        external
        payable
        whenPublicSaleOpen
        nonReentrant
    {
        if (_currentIndex + quantity > PARAMETERS.maxCobots)
            revert TotalSupplyExceeded();
        uint256 price = PARAMETERS.mintPublicPrice * quantity;

        uint256 redeemed = 0;
        for (uint256 i = 0; i < tokenIdsV1.length; i++) {
            if (COBOTS_V1.ownerOf(tokenIdsV1[i]) != _msgSender())
                revert RedeemTokenNotOwner();
            if (!coBotsV1Redeemed[tokenIdsV1[i]] && redeemed < quantity) {
                coBotsV1Redeemed[tokenIdsV1[i]] = true;
                redeemed++;
                price -=
                    PARAMETERS.mintPublicPrice /
                    PARAMETERS.cobotsV1Discount;
            }
        }
        _redeemedCount += redeemed;
        if (msg.value != price) revert WrongPrice();
        if (quantity + _currentIndex == PARAMETERS.maxCobots) {
            mintedOutTimestamp = block.timestamp;
        }

        _mintCoBots(_msgSender(), quantity);
    }

    function mintFounders(address to, uint256 quantity) external onlyOwner {
        if (quantity + _currentIndex > MINT_FOUNDERS)
            revert AllocationExceeded();

        _mintCoBots(to, quantity);
    }

    /** @notice Return true if the Co-Bot displays metta screen
     *   @param tokenId The Co-Bot token ID
     */
    function isMettaEnabled(uint256 tokenId) external view returns (bool) {
        return coBotsSeeds[tokenId] & 1 == 1;
    }

    function _toggleMetta(uint256 tokenId) internal {
        if (ERC721A.ownerOf(tokenId) != _msgSender())
            revert ToggleMettaCallerNotOwner();

        coBotsSeeds[tokenId] = coBotsSeeds[tokenId] ^ 1;
    }

    function toggleMetta(uint256[] calldata tokenIds) public nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _toggleMetta(tokenIds[i]);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        if (renderingContractAddress == address(0)) {
            return "";
        }

        return renderer.tokenURI(_tokenId, coBotsSeeds[_tokenId]);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    receive() external payable {}

    /** @notice At any point in time, founders can withdraw only up to the required balance to insure that the giveaways
     *          will be paid. We take a conservative approach considering that all the remaining discounted bots will be minted
     *          as soon as possible.
     */
    function withdraw() public onlyOwner {
        // Draw eventual remaining giveaways
        if (_shouldDraw()) {
            draw();
        }

        // Start with the current contract's balance
        uint256 balance = address(this).balance;

        // Correct amount with giveaways that are pending fulfillments, typically previously drawn random fulfillments
        for (uint256 i = 0; i < requestIds.length; i++) {
            if (!fulfillments[requestIds[i]].fulfilled) {
                balance -= fulfillments[requestIds[i]].prize.amount;
            }
        }

        // Use the corrected balance as a base possible withdrawn value
        uint256 value = balance;
        if (value == 0) revert InsufficientFunds();

        // Compute number of remaining discount sales
        uint256 remainingVoucher = COBOTS_V1.totalSupply() - _redeemedCount;
        // Initialize the number of already minted bots for checkpoints
        uint256 previousCheckpoint = _currentIndex;

        // Loop over locked checkpoint to estimate funds and withdrawal capacities
        for (uint256 i = requestIds.length; i < PRIZES.length; i++) {
            // to unlock the next checkpoint, remainingBots bots need to be minted
            uint256 remainingBots = PRIZES[i].checkpoint - previousCheckpoint;

            // They will top up the contract's balance, depending on the number of voucher
            if (remainingVoucher > remainingBots) {
                balance +=
                    remainingBots *
                    (PARAMETERS.mintPublicPrice / PARAMETERS.cobotsV1Discount);
                remainingVoucher -= remainingBots;
            } else {
                balance +=
                    remainingVoucher *
                    (PARAMETERS.mintPublicPrice / PARAMETERS.cobotsV1Discount) +
                    (remainingBots - remainingVoucher) *
                    PARAMETERS.mintPublicPrice;
                remainingVoucher = 0;
            }

            // Then the current prize will be paid
            balance -= PRIZES[i].amount;

            // If at some point in the future it's not possible to pay, then the withdraw tx is reverted
            if (balance < 1) {
                revert InsufficientFunds();
            }

            // The possible withdrawal amount is the minimum between the current balance and the contract's balance
            // after each giveaway.
            if (balance < value) {
                value = balance;
            }
            previousCheckpoint = PRIZES[i].checkpoint;
        }

        (bool success, ) = _msgSender().call{value: value}("");
        if (!success) revert WithdrawalFailed();
        emit Withdrawal(value);
    }

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// Raffle //////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    bytes32 gasKeyHash;
    uint64 public chainlinkSubscriptionId;

    function createSubscriptionAndFund(uint96 amount) external nonReentrant {
        if (chainlinkSubscriptionId == 0) {
            chainlinkSubscriptionId = COORDINATOR.createSubscription();
            COORDINATOR.addConsumer(chainlinkSubscriptionId, address(this));
        }
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(chainlinkSubscriptionId)
        );
    }

    function cancelSubscription() external onlyOwner {
        COORDINATOR.cancelSubscription(chainlinkSubscriptionId, _msgSender());
        chainlinkSubscriptionId = 0;
    }

    struct Winner {
        address winner;
        uint16 tokenId;
    }

    struct Fulfillment {
        Prize prize;
        bool fulfilled;
        Winner winner;
    }

    mapping(uint256 => Fulfillment) public fulfillments;
    uint256[] public requestIds;
    uint256 public drawnAmount;

    /** @notice Use this to retrieve the ordered list of winners with their corresponding prizes and token Id.
     *          Pending fulfillments are included (no winner drawn yet, probably waiting for Chainlink to fulfill).
     */
    function getOrderedFulfillments()
        external
        view
        returns (Fulfillment[] memory)
    {
        Fulfillment[] memory result = new Fulfillment[](requestIds.length);
        for (uint256 i = 0; i < requestIds.length; i++) {
            result[i] = fulfillments[requestIds[i]];
        }
        return result;
    }

    function _shouldDraw() internal view returns (bool) {
        if (requestIds.length == PRIZES.length) {
            return false;
        }
        if (
            (requestIds.length == PRIZES.length - 1) &&
            (block.timestamp < mintedOutTimestamp + PARAMETERS.grandPrizeDelay)
        ) {
            return false;
        }
        if (PRIZES[requestIds.length].checkpoint > _currentIndex) return false;
        return true;
    }

    /**
     * @notice This function can be called at any time by anyone to trigger the unlocked giveaways. It will
     *         revert if there is nothing to unlock to prevent anon from making useless tx. (Usually wallet, e.g.
     *         metamask, warn this before signing).
     *         Giveaways that use Chainlink VRF oracle will be fulfilled automatically by Chainlink. Giveaways that
     *         require founders to unlock will be fulfilled by the founders.
     */
    function draw() public nonReentrant {
        uint256 drawCounts = requestIds.length;
        if (chainlinkSubscriptionId == 0) {
            revert ChainlinkSubscriptionNotFound();
        }
        if (!_shouldDraw()) revert NoGiveawayToTrigger();
        while (PRIZES[drawCounts].checkpoint < _currentIndex + 1) {
            uint256 requestId;
            if (
                (PRIZES[drawCounts].isContest &&
                    block.timestamp <
                    publicSaleStartTimestamp + PARAMETERS.contestDuration) ||
                (drawCounts == MYSTERY_CHALLENGE.prizeIndex)
            ) {
                requestId = _computeRequestId(drawCounts);
            } else {
                requestId = COORDINATOR.requestRandomWords(
                    gasKeyHash,
                    chainlinkSubscriptionId,
                    5, // requestConfirmations
                    500_000, // callbackGasLimit
                    1 // numWords
                );
            }
            drawnAmount += PRIZES[drawCounts].amount;
            fulfillments[requestId] = Fulfillment(
                PRIZES[drawCounts],
                false,
                Winner(address(0), 0)
            );
            emit CheckpointDrawn(requestId, PRIZES[drawCounts]);
            drawCounts++;
            requestIds.push(requestId);
            if (
                (drawCounts == PRIZES.length - 1) &&
                (block.timestamp <
                    mintedOutTimestamp + PARAMETERS.grandPrizeDelay)
            ) {
                return;
            }
            if (drawCounts == PRIZES.length) {
                emit GiveawayFinished();
                return;
            }
        }
    }

    function _computeRequestId(uint256 id) private pure returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(uint8(id % type(uint8).max))));
    }

    function _fulfill(
        uint256 requestId,
        address winnerAddress,
        uint256 selectedToken
    ) internal {
        if (fulfillments[requestId].fulfilled) {
            revert FulfillmentAlreadyFulfilled();
        }
        if (fulfillments[requestId].prize.amount == 0)
            revert FulfillRequestForNonExistentContest();
        if (ERC721A.ownerOf(selectedToken) != winnerAddress) {
            revert FulfillRequestWithTokenNotOwnedByWinner();
        }
        fulfillments[requestId].fulfilled = true;
        Winner memory winner = Winner(winnerAddress, uint16(selectedToken));
        fulfillments[requestId].winner = winner;
        (bool success, ) = winnerAddress.call{
            value: fulfillments[requestId].prize.amount
        }("");
        if (!success) revert TransferFailed();
        emit CheckpointFulfilled(
            requestId,
            fulfillments[requestId].prize,
            winner
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 checkpoint = fulfillments[requestId].prize.checkpoint;
        uint256 selectedToken = randomWords[0] % checkpoint;
        address winner = ERC721A.ownerOf(selectedToken);
        _fulfill(requestId, winner, selectedToken);
    }

    /**
     * @notice This function lets the owner fulfill a giveaway. If the giveaway has not been unlocked, this will
     *         revert.
     * @param giveawayIndex The index of the giveaway to fulfill, 0 based (the first giveaway is index 0).
     * @param winner The selected winner address.
     * @param selectedToken The selected token to be displayed on the website.
     */
    function fulfillContest(
        uint256 giveawayIndex,
        address winner,
        uint256 selectedToken
    ) external nonReentrant onlyOwner {
        uint256 requestId = _computeRequestId(giveawayIndex);
        _fulfill(requestId, winner, selectedToken);
    }

    /**
     * @notice Call this when, you know, you probably know what you're doing here.
     *         revert.
     * @param value Word biggest mysteries are solved with this single value.
     * @param tokenId The selected token to be displayed on the website. This should be owned by the winner.
     */
    function TheAnswer(uint256 value, uint256 tokenId) external nonReentrant {
        if (ENS.ownerOf(MYSTERY_CHALLENGE.ensId) != _msgSender()) {
            revert MysteryChallengeSenderDoesNotOwnENS();
        }
        if (value != MYSTERY_CHALLENGE.value) {
            revert MysteryChallengeValueDoesNotMatch();
        }
        _fulfill(
            _computeRequestId(MYSTERY_CHALLENGE.prizeIndex),
            _msgSender(),
            tokenId
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

error PublicSaleOpen();
error PublicSaleNotOpen();
error TokenMintedOut();
error TokenNotMintedOut();

/** @dev This contract can be used to manage some basic scheduling of a token sale.
 *       To have the isMintedOut() function work, it is required to either update the mintedOutTimestamp
 *       or to override the function (using totalSupply() for instance).
 */
contract Schedule is Ownable {
    uint256 public publicSaleStartTimestamp;
    uint256 public mintedOutTimestamp;

    function openPublicSale() external onlyOwner whenPublicSaleClosed {
        publicSaleStartTimestamp = block.timestamp;
    }

    function isPublicSaleOpen() public view virtual returns (bool) {
        return
            publicSaleStartTimestamp != 0 &&
            block.timestamp > publicSaleStartTimestamp;
    }

    modifier whenPublicSaleOpen() {
        if (!isPublicSaleOpen()) revert PublicSaleNotOpen();
        _;
    }

    modifier whenPublicSaleClosed() {
        if (isPublicSaleOpen()) revert PublicSaleOpen();
        _;
    }

    function isMintedOut() public view virtual returns (bool) {
        return mintedOutTimestamp > 0;
    }

    modifier whenMintedOut() {
        if (!isMintedOut()) revert TokenNotMintedOut();
        _;
    }

    modifier whenNotMintedOut() {
        if (isMintedOut()) revert TokenMintedOut();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import {Integers} from "../lib/Integers.sol";
import "../interfaces/ICoBotsRenderer.sol";

/*  @title CoBots Renderer
    @author Clement Walter
    @dev Encode each traits as a "sum" of `rect`, each rect being stored using 4 bytes
*/
contract CoBotsRenderer is Ownable, ReentrancyGuard, ICoBotsRenderer {
    using Integers for uint8;
    using Strings for uint256;

    // We have a total of 4 * 6 = 24 bits = 3 bytes for coordinates + 1 byte for the color
    // Hence each rect is 4 bytes
    uint8 public constant BITS_PER_COORDINATES = 6;
    uint8 public constant BITS_PER_FILL_INDEX = 8;

    string public constant RECT_TAG_START = "%3crect%20x=%27";
    string public constant Y_TAG = "%27%20y=%27";
    string public constant WIDTH_TAG = "%27%20width=%27";
    string public constant HEIGHT_TAG = "%27%20height=%27";
    string public constant FILL_TAG = "%27%20fill=%27%23";
    string public constant RECT_TAG_END = "%27/%3e";
    string public constant SVG_TAG_START =
        "%3csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20viewBox=%270%200%2045%2045%27%20width=%27450px%27%20height=%27450px%27%3e";
    string public constant SVG_TAG_END =
        "%3cstyle%3erect{shape-rendering:crispEdges}%3c/style%3e%3c/svg%3e";

    address public fillPalette;
    address public traitPalette;
    address public traitPaletteIndexes; // where each trait begins in the traits' palette
    bytes public layerIndexes; // the index of the first item of each layer, uint8/bytes1 for each layer

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////  Rendering mechanics  /////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    /// @dev Colors are concatenated and stored in a single 'bytes' with SSTORE2 to save gas.
    function setFillPalette(bytes calldata _fillPalette) external onlyOwner {
        fillPalette = SSTORE2.write(_fillPalette);
    }

    /// @dev All the rects are concatenated together to save gas.
    ///      The traitPaletteIndexes is used to retrieve the rect from the traitPalette.
    function setTraitPalette(bytes calldata _traitPalette) external onlyOwner {
        traitPalette = SSTORE2.write(_traitPalette);
    }

    /// @dev Since each SSTORE2 slots can contain up to 24kb, indexes need to be uint16, ie. two bytes per index.
    function setTraitPaletteIndexes(bytes calldata _traitPaletteIndexes)
        external
        onlyOwner
    {
        traitPaletteIndexes = SSTORE2.write(_traitPaletteIndexes);
    }

    /// @dev Traits are stored as a plain list while the rendering works with layer and items within each layer.
    ///      Since each layer has a variable number of items, we store the index of the first trait of each layer.
    function setLayerIndexes(bytes calldata _layerIndexes) external onlyOwner {
        layerIndexes = _layerIndexes;
    }

    /// @dev 3 bytes per color because svg does not handle alpha.
    function getFill(uint256 _index) public view returns (string memory) {
        bytes memory palette = SSTORE2.read(fillPalette);
        return
            string.concat(
                uint8(palette[3 * _index]).toString(16, 2),
                uint8(palette[3 * _index + 1]).toString(16, 2),
                uint8(palette[3 * _index + 2]).toString(16, 2)
            );
    }

    /// @dev This function lets map from layerIndex and itemIndex to traitIndex.
    function getTraitIndex(uint256 _layerIndex, uint256 _itemIndex)
        public
        view
        returns (uint256)
    {
        uint8 traitIndex = uint8(layerIndexes[_layerIndex]);
        uint8 nextTraitIndex = uint8(layerIndexes[_layerIndex + 1]);
        if (traitIndex + _itemIndex > nextTraitIndex - 1) {
            return type(uint8).max;
        }

        return _itemIndex + traitIndex;
    }

    /// @dev Retrieve the bytes for the given trait from the traitPalette storage.
    function getTraitBytes(uint256 _index) public view returns (bytes memory) {
        bytes memory _indexes = SSTORE2.read(traitPaletteIndexes);
        uint32 start = uint32(BytesLib.toUint16(_indexes, _index * 2));
        uint32 next = uint32(BytesLib.toUint16(_indexes, _index * 2 + 2));
        bytes memory _traitPalette = SSTORE2.read(traitPalette);
        return BytesLib.slice(_traitPalette, start, next - start);
    }

    function decodeRect(bytes memory rectBytes)
        public
        view
        returns (string memory)
    {
        return decodeRect(rectBytes, 0, 0);
    }

    function decodeRect(
        bytes memory rectBytes,
        uint8 offsetX,
        uint8 offsetY
    ) public view returns (string memory) {
        require(rectBytes.length == 4, "Rect bytes must be 4 bytes long");
        string memory fill = getFill(uint8(rectBytes[3]));
        return
            string.concat(
                RECT_TAG_START,
                (uint8(rectBytes[0] >> 2) + offsetX).toString(),
                Y_TAG,
                (uint8(((rectBytes[0] << 4) | (rectBytes[1] >> 4)) & 0x3f) +
                    offsetY).toString(),
                WIDTH_TAG,
                uint8(((rectBytes[1] << 2) & 0x3f) | (rectBytes[2] >> 6))
                    .toString(),
                HEIGHT_TAG,
                uint8(rectBytes[2] & 0x3f).toString(),
                FILL_TAG,
                fill,
                RECT_TAG_END
            );
    }

    function decode8Rects(bytes32 rectsBytes)
        public
        view
        returns (string memory)
    {
        return
            string.concat(
                decodeRect(
                    bytes.concat(
                        rectsBytes[0],
                        rectsBytes[1],
                        rectsBytes[2],
                        rectsBytes[3]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[4],
                        rectsBytes[5],
                        rectsBytes[6],
                        rectsBytes[7]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[8],
                        rectsBytes[9],
                        rectsBytes[10],
                        rectsBytes[11]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[12],
                        rectsBytes[13],
                        rectsBytes[14],
                        rectsBytes[15]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[16],
                        rectsBytes[17],
                        rectsBytes[18],
                        rectsBytes[19]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[20],
                        rectsBytes[21],
                        rectsBytes[22],
                        rectsBytes[23]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[24],
                        rectsBytes[25],
                        rectsBytes[26],
                        rectsBytes[27]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[28],
                        rectsBytes[29],
                        rectsBytes[30],
                        rectsBytes[31]
                    )
                )
            );
    }

    function decode32Rects(bytes memory rectsBytes)
        public
        view
        returns (string memory)
    {
        return
            string.concat(
                decode8Rects(BytesLib.toBytes32(rectsBytes, 0)),
                decode8Rects(BytesLib.toBytes32(rectsBytes, 32)),
                decode8Rects(BytesLib.toBytes32(rectsBytes, 64)),
                decode8Rects(BytesLib.toBytes32(rectsBytes, 96))
            );
    }

    /// @dev Decode the rect and returns it as a plain string to be used in the svg rect attribute.
    ///      One rect is 4 bytes so 8 rects is a bytes32.
    ///      With 20 bytes32, we have up to 160 rects per trait / co-bots actually if we concat the bytes first.
    ///      This magic number comes from a small data analysis of the traits. We use the fact that an empty
    ///      bytes32 will lead to an empty rect (width and height 0).
    function getTrait(bytes memory traitEncodedBytes)
        public
        view
        returns (string memory)
    {
        // buffer is 20 * 32 bytes = up to 160 rects
        bytes memory buffer = bytes.concat(
            traitEncodedBytes,
            new bytes(640 - traitEncodedBytes.length)
        );
        return
            string.concat(
                SVG_TAG_START,
                decode32Rects(BytesLib.slice(buffer, 0, 128)),
                decode32Rects(BytesLib.slice(buffer, 128, 128)),
                decode32Rects(BytesLib.slice(buffer, 256, 128)),
                decode32Rects(BytesLib.slice(buffer, 384, 128)),
                decode32Rects(BytesLib.slice(buffer, 512, 128)),
                SVG_TAG_END
            );
    }

    function getImageURI(bytes memory traitEncodedBytes)
        public
        view
        returns (string memory)
    {
        return
            string.concat("data:image/svg+xml,", getTrait(traitEncodedBytes));
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////  Co-bots  ////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    function getRandomItems(uint256 tokenId, uint8 seed)
        public
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        )
    {
        uint256 randomBotMemory = uint256(
            keccak256(abi.encodePacked(tokenId, seed))
        );

        // Eyes
        uint256 randomEyes = randomBotMemory % 10_000;
        randomBotMemory >>= 14;
        eyesIndex = randomEyes < 25
            ? 11
            : (randomEyes < 75 ? 10 : randomEyes % 10);

        // Mouth
        uint256 randomMouth = randomBotMemory % 10_000;
        randomBotMemory >>= 14;
        mouthIndex = randomMouth < 50 ? 10 : randomMouth % 10;

        // Antenna
        uint256 randomAntenna = randomBotMemory % 10_000;
        randomBotMemory >>= 14;
        antennaIndex = randomAntenna < 50
            ? 10
            : (randomAntenna < 75 ? 11 : randomAntenna % 10);

        // Feet
        uint256 randomFeet = randomBotMemory % 10_000;
        randomBotMemory >>= 14;
        feetIndex = randomFeet < 50 ? 10 : randomFeet % 10;
    }

    function getToadItems()
        public
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        )
    {
        return (0, 0, 12, 6);
    }

    function getNounishItems()
        public
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        )
    {
        return (0, 0, 13, 0);
    }

    function getWizardItems()
        public
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        )
    {
        return (0, 0, 14, 9);
    }

    function getCoBotItems(
        uint256 tokenId,
        uint8 seed,
        bool status,
        bool color
    ) public pure returns (uint256[10] memory) {
        uint256 eyesIndex;
        uint256 mouthIndex;
        uint256 antennaIndex;
        uint256 feetIndex;
        if (tokenId == 0) {
            (eyesIndex, mouthIndex, antennaIndex, feetIndex) = getToadItems();
        } else if (tokenId == 1) {
            (
                eyesIndex,
                mouthIndex,
                antennaIndex,
                feetIndex
            ) = getNounishItems();
        } else if (tokenId == 2) {
            (eyesIndex, mouthIndex, antennaIndex, feetIndex) = getWizardItems();
        } else {
            (eyesIndex, mouthIndex, antennaIndex, feetIndex) = getRandomItems(
                tokenId,
                seed
            );
        }

        uint256[10] memory items;
        // 0. Colour
        items[0] = color ? 0 : 1;
        // 1. Digit 1
        items[1] = tokenId / 1000;
        // 2. Digit 2
        items[2] = (tokenId / 100) % 10;
        // 3. Digit 3
        items[3] = (tokenId / 10) % 10;
        // 4. Digit 4
        items[4] = tokenId % 10;
        // 5. Eyes
        items[5] = eyesIndex;
        // 6. Mouth
        items[6] = mouthIndex;
        // 7. Antenna
        items[7] = antennaIndex;
        // 8. Status
        items[8] = status ? 1 : 0;
        // 9. Feet
        items[9] = feetIndex;
        return items;
    }

    function getCoBotBytes(uint256[10] memory items)
        public
        view
        returns (bytes memory)
    {
        return
            bytes.concat(
                getTraitBytes(getTraitIndex(0, items[0])),
                getTraitBytes(getTraitIndex(1, items[1])),
                getTraitBytes(getTraitIndex(2, items[2])),
                getTraitBytes(getTraitIndex(3, items[3])),
                getTraitBytes(getTraitIndex(4, items[4])),
                getTraitBytes(getTraitIndex(5, items[5])),
                getTraitBytes(getTraitIndex(6, items[6])),
                getTraitBytes(getTraitIndex(7, items[7])),
                items[8] == 1
                    ? new bytes(4)
                    : getTraitBytes(getTraitIndex(8, items[8])),
                getTraitBytes(getTraitIndex(9, items[9]))
            );
    }

    function getCoBotImageURI(uint256[10] memory items)
        public
        view
        returns (string memory)
    {
        return getImageURI(getCoBotBytes(items));
    }

    function getCoBotAttributes(
        uint256[10] memory items,
        bool status,
        bool color
    ) public pure returns (string memory) {
        string[12] memory eyes = [
            "Classic", // 0
            "Cyclops", // 1
            "Awoken", // 2
            "Flirty", // 3
            "Zen", // 4
            "Sadhappy", // 5
            "Unaligned", // 6
            "Smitten", // 7
            "Optimistic", // 8
            "Hacky", // 9
            "Super", // 50 times
            "Nounish" // 25 times
        ];
        string[11] memory mouths = [
            "Classic", // 0
            "Worried", // 1
            "Knightly", // 2
            "Shy", // 3
            "Happy", // 4
            "Bigsad", // 5
            "Smug", // 6
            "Wowed", // 7
            "Thirsty", // 8
            "Villainous", // 9
            "Shady" // 50 times
        ];
        string[15] memory antennas = [
            "Classic", // 0
            "Serious", // 1
            "Jumpy", // 2
            "Buzzed", // 3
            "Buggy", // 4
            "Punk", // 5
            "Angelic", // 6
            "Impish", // 7
            "Humbled", // 8
            "Western", // 9
            "Royal", // 50 times
            "Hacky", // 25 times
            "!croak", // 1 time
            "Nounish", // 1 time
            "Wizard" // 1 time
        ];
        string[11] memory feet = [
            "Classic", // 0
            "Heavy Duty", // 1
            "Firey", // 2
            "Little Firey", // 3
            "Roller", // 4
            "Little Roller", // 5
            "Energetic", // 6
            "Little Energetic", // 7
            "Hobbled", // 8
            "Ghostly", // 9
            "Pushy" // 50 times
        ];
        return
            string.concat(
                "[",
                items[7] > 11 ? "" : '{"trait_type": "Eyes", "value": "',
                items[7] > 11 ? "" : eyes[items[5]],
                items[7] > 11 ? "" : '"},',
                items[7] > 11 ? "" : '{"trait_type": "Mouth", "value": "',
                items[7] > 11 ? "" : mouths[items[6]],
                items[7] > 11 ? "" : '"},',
                '{"trait_type": "Antenna", "value": "',
                antennas[items[7]],
                '"},',
                '{"trait_type": "Feet", "value": "',
                feet[items[9]],
                '"},',
                '{"trait_type": "Status", "value": "',
                status ? "Online" : "Offline",
                '"},',
                '{"trait_type": "Color", "value": "',
                color ? "Blue" : "Red",
                '"}',
                "]"
            );
    }

    function tokenURI(
        uint256 tokenId,
        uint8 seed,
        bool status,
        bool color
    ) public view returns (string memory) {
        uint256[10] memory items = getCoBotItems(tokenId, seed, status, color);
        return
            string.concat(
                "data:application/json,",
                '{"image_data": "',
                getCoBotImageURI(items),
                '"',
                ',"description": "Co-Bots are cooperation robots | CC0 & 100% On-Chain | co-bots.com."',
                ',"name": "Co-Bot #',
                tokenId.toString(),
                '"',
                ',"attributes": ',
                getCoBotAttributes(items, status, color),
                "}"
            );
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Integers Library updated from https://github.com/willitscale/solidity-util
 *
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 *
 * @author Clement Walter <[email protected]>
 */
library Integers {
    /**
     * To String
     *
     * Converts an unsigned integer to the string equivalent value, returned as bytes
     * Equivalent to javascript's toString(base)
     *
     * @param _number The unsigned integer to be converted to a string
     * @param _base The base to convert the number to
     * @param  _padding The target length of the string; result will be padded with 0 to reach this length while padding
     *         of 0 means no padding
     * @return bytes The resulting ASCII string value
     */
    function toString(
        uint256 _number,
        uint8 _base,
        uint8 _padding
    ) public pure returns (string memory) {
        uint256 count = 0;
        uint256 b = _number;
        while (b != 0) {
            count++;
            b /= _base;
        }
        if (_number == 0) {
            count++;
        }
        bytes memory res;
        if (_padding == 0) {
            res = new bytes(count);
        } else {
            res = new bytes(_padding);
        }
        for (uint256 i = 0; i < count; ++i) {
            b = _number % _base;
            if (b < 10) {
                res[res.length - i - 1] = bytes1(uint8(b + 48)); // 0-9
            } else {
                res[res.length - i - 1] = bytes1(uint8((b % 10) + 65)); // A-F
            }
            _number /= _base;
        }

        for (uint256 i = count; i < _padding; ++i) {
            res[res.length - i - 1] = hex"30"; // 0
        }

        return string(res);
    }

    function toString(uint256 _number) public pure returns (string memory) {
        return toString(_number, 10, 0);
    }

    function toString(uint256 _number, uint8 _base)
        public
        pure
        returns (string memory)
    {
        return toString(_number, _base, 0);
    }

    /**
     * Load 16
     *
     * Converts two bytes to a 16 bit unsigned integer
     *
     * @param _leadingBytes the first byte of the unsigned integer in [256, 65536]
     * @param _endingBytes the second byte of the unsigned integer in [0, 255]
     * @return uint16 The resulting integer value
     */
    function load16(bytes1 _leadingBytes, bytes1 _endingBytes)
        public
        pure
        returns (uint16)
    {
        return
            (uint16(uint8(_leadingBytes)) << 8) + uint16(uint8(_endingBytes));
    }

    /**
     * Load 12
     *
     * Converts three bytes into two uint12 integers
     *
     * @return (uint16, uint16) The two uint16 values up to 2^12 each
     */
    function load12x2(
        bytes1 first,
        bytes1 second,
        bytes1 third
    ) public pure returns (uint16, uint16) {
        return (
            (uint16(uint8(first)) << 4) + (uint16(uint8(second)) >> 4),
            (uint16(uint8(second & hex"0f")) << 8) + uint16(uint8(third))
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/LinkTokenInterface.sol";
import "../interfaces/BlockhashStoreInterface.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/VRFCoordinatorV2Interface.sol";
import "../interfaces/TypeAndVersionInterface.sol";
import "../interfaces/ERC677ReceiverInterface.sol";
import "./VRF.sol";
import "../ConfirmedOwner.sol";
import "../VRFConsumerBaseV2.sol";

contract VRFCoordinatorV2 is
  VRF,
  ConfirmedOwner,
  TypeAndVersionInterface,
  VRFCoordinatorV2Interface,
  ERC677ReceiverInterface
{
  LinkTokenInterface public immutable LINK;
  AggregatorV3Interface public immutable LINK_ETH_FEED;
  BlockhashStoreInterface public immutable BLOCKHASH_STORE;

  // We need to maintain a list of consuming addresses.
  // This bound ensures we are able to loop over them as needed.
  // Should a user require more consumers, they can use multiple subscriptions.
  uint16 public constant MAX_CONSUMERS = 100;
  error TooManyConsumers();
  error InsufficientBalance();
  error InvalidConsumer(uint64 subId, address consumer);
  error InvalidSubscription();
  error OnlyCallableFromLink();
  error InvalidCalldata();
  error MustBeSubOwner(address owner);
  error PendingRequestExists();
  error MustBeRequestedOwner(address proposedOwner);
  error BalanceInvariantViolated(uint256 internalBalance, uint256 externalBalance); // Should never happen
  event FundsRecovered(address to, uint256 amount);
  // We use the subscription struct (1 word)
  // at fulfillment time.
  struct Subscription {
    // There are only 1e9*1e18 = 1e27 juels in existence, so the balance can fit in uint96 (2^96 ~ 7e28)
    uint96 balance; // Common link balance used for all consumer requests.
    uint64 reqCount; // For fee tiers
  }
  // We use the config for the mgmt APIs
  struct SubscriptionConfig {
    address owner; // Owner can fund/withdraw/cancel the sub.
    address requestedOwner; // For safely transferring sub ownership.
    // Maintains the list of keys in s_consumers.
    // We do this for 2 reasons:
    // 1. To be able to clean up all keys from s_consumers when canceling a subscription.
    // 2. To be able to return the list of all consumers in getSubscription.
    // Note that we need the s_consumers map to be able to directly check if a
    // consumer is valid without reading all the consumers from storage.
    address[] consumers;
  }
  // Note a nonce of 0 indicates an the consumer is not assigned to that subscription.
  mapping(address => mapping(uint64 => uint64)) /* consumer */ /* subId */ /* nonce */
    private s_consumers;
  mapping(uint64 => SubscriptionConfig) /* subId */ /* subscriptionConfig */
    private s_subscriptionConfigs;
  mapping(uint64 => Subscription) /* subId */ /* subscription */
    private s_subscriptions;
  // We make the sub count public so that its possible to
  // get all the current subscriptions via getSubscription.
  uint64 private s_currentSubId;
  // s_totalBalance tracks the total link sent to/from
  // this contract through onTokenTransfer, cancelSubscription and oracleWithdraw.
  // A discrepancy with this contract's link balance indicates someone
  // sent tokens using transfer and so we may need to use recoverFunds.
  uint96 private s_totalBalance;
  event SubscriptionCreated(uint64 indexed subId, address owner);
  event SubscriptionFunded(uint64 indexed subId, uint256 oldBalance, uint256 newBalance);
  event SubscriptionConsumerAdded(uint64 indexed subId, address consumer);
  event SubscriptionConsumerRemoved(uint64 indexed subId, address consumer);
  event SubscriptionCanceled(uint64 indexed subId, address to, uint256 amount);
  event SubscriptionOwnerTransferRequested(uint64 indexed subId, address from, address to);
  event SubscriptionOwnerTransferred(uint64 indexed subId, address from, address to);

  // Set this maximum to 200 to give us a 56 block window to fulfill
  // the request before requiring the block hash feeder.
  uint16 public constant MAX_REQUEST_CONFIRMATIONS = 200;
  uint32 public constant MAX_NUM_WORDS = 500;
  // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100)
  // and some arithmetic operations.
  uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;
  error InvalidRequestConfirmations(uint16 have, uint16 min, uint16 max);
  error GasLimitTooBig(uint32 have, uint32 want);
  error NumWordsTooBig(uint32 have, uint32 want);
  error ProvingKeyAlreadyRegistered(bytes32 keyHash);
  error NoSuchProvingKey(bytes32 keyHash);
  error InvalidLinkWeiPrice(int256 linkWei);
  error InsufficientGasForConsumer(uint256 have, uint256 want);
  error NoCorrespondingRequest();
  error IncorrectCommitment();
  error BlockhashNotInStore(uint256 blockNum);
  error PaymentTooLarge();
  error Reentrant();
  struct RequestCommitment {
    uint64 blockNum;
    uint64 subId;
    uint32 callbackGasLimit;
    uint32 numWords;
    address sender;
  }
  mapping(bytes32 => address) /* keyHash */ /* oracle */
    private s_provingKeys;
  bytes32[] private s_provingKeyHashes;
  mapping(address => uint96) /* oracle */ /* LINK balance */
    private s_withdrawableTokens;
  mapping(uint256 => bytes32) /* requestID */ /* commitment */
    private s_requestCommitments;
  event ProvingKeyRegistered(bytes32 keyHash, address indexed oracle);
  event ProvingKeyDeregistered(bytes32 keyHash, address indexed oracle);
  event RandomWordsRequested(
    bytes32 indexed keyHash,
    uint256 requestId,
    uint256 preSeed,
    uint64 indexed subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords,
    address indexed sender
  );
  event RandomWordsFulfilled(uint256 indexed requestId, uint256 outputSeed, uint96 payment, bool success);

  struct Config {
    uint16 minimumRequestConfirmations;
    uint32 maxGasLimit;
    // Reentrancy protection.
    bool reentrancyLock;
    // stalenessSeconds is how long before we consider the feed price to be stale
    // and fallback to fallbackWeiPerUnitLink.
    uint32 stalenessSeconds;
    // Gas to cover oracle payment after we calculate the payment.
    // We make it configurable in case those operations are repriced.
    uint32 gasAfterPaymentCalculation;
  }
  int256 private s_fallbackWeiPerUnitLink;
  Config private s_config;
  FeeConfig private s_feeConfig;
  struct FeeConfig {
    // Flat fee charged per fulfillment in millionths of link
    // So fee range is [0, 2^32/10^6].
    uint32 fulfillmentFlatFeeLinkPPMTier1;
    uint32 fulfillmentFlatFeeLinkPPMTier2;
    uint32 fulfillmentFlatFeeLinkPPMTier3;
    uint32 fulfillmentFlatFeeLinkPPMTier4;
    uint32 fulfillmentFlatFeeLinkPPMTier5;
    uint24 reqsForTier2;
    uint24 reqsForTier3;
    uint24 reqsForTier4;
    uint24 reqsForTier5;
  }
  event ConfigSet(
    uint16 minimumRequestConfirmations,
    uint32 maxGasLimit,
    uint32 stalenessSeconds,
    uint32 gasAfterPaymentCalculation,
    int256 fallbackWeiPerUnitLink,
    FeeConfig feeConfig
  );

  constructor(
    address link,
    address blockhashStore,
    address linkEthFeed
  ) ConfirmedOwner(msg.sender) {
    LINK = LinkTokenInterface(link);
    LINK_ETH_FEED = AggregatorV3Interface(linkEthFeed);
    BLOCKHASH_STORE = BlockhashStoreInterface(blockhashStore);
  }

  /**
   * @notice Registers a proving key to an oracle.
   * @param oracle address of the oracle
   * @param publicProvingKey key that oracle can use to submit vrf fulfillments
   */
  function registerProvingKey(address oracle, uint256[2] calldata publicProvingKey) external onlyOwner {
    bytes32 kh = hashOfKey(publicProvingKey);
    if (s_provingKeys[kh] != address(0)) {
      revert ProvingKeyAlreadyRegistered(kh);
    }
    s_provingKeys[kh] = oracle;
    s_provingKeyHashes.push(kh);
    emit ProvingKeyRegistered(kh, oracle);
  }

  /**
   * @notice Deregisters a proving key to an oracle.
   * @param publicProvingKey key that oracle can use to submit vrf fulfillments
   */
  function deregisterProvingKey(uint256[2] calldata publicProvingKey) external onlyOwner {
    bytes32 kh = hashOfKey(publicProvingKey);
    address oracle = s_provingKeys[kh];
    if (oracle == address(0)) {
      revert NoSuchProvingKey(kh);
    }
    delete s_provingKeys[kh];
    for (uint256 i = 0; i < s_provingKeyHashes.length; i++) {
      if (s_provingKeyHashes[i] == kh) {
        bytes32 last = s_provingKeyHashes[s_provingKeyHashes.length - 1];
        // Copy last element and overwrite kh to be deleted with it
        s_provingKeyHashes[i] = last;
        s_provingKeyHashes.pop();
      }
    }
    emit ProvingKeyDeregistered(kh, oracle);
  }

  /**
   * @notice Returns the proving key hash key associated with this public key
   * @param publicKey the key to return the hash of
   */
  function hashOfKey(uint256[2] memory publicKey) public pure returns (bytes32) {
    return keccak256(abi.encode(publicKey));
  }

  /**
   * @notice Sets the configuration of the vrfv2 coordinator
   * @param minimumRequestConfirmations global min for request confirmations
   * @param maxGasLimit global max for request gas limit
   * @param stalenessSeconds if the eth/link feed is more stale then this, use the fallback price
   * @param gasAfterPaymentCalculation gas used in doing accounting after completing the gas measurement
   * @param fallbackWeiPerUnitLink fallback eth/link price in the case of a stale feed
   * @param feeConfig fee tier configuration
   */
  function setConfig(
    uint16 minimumRequestConfirmations,
    uint32 maxGasLimit,
    uint32 stalenessSeconds,
    uint32 gasAfterPaymentCalculation,
    int256 fallbackWeiPerUnitLink,
    FeeConfig memory feeConfig
  ) external onlyOwner {
    if (minimumRequestConfirmations > MAX_REQUEST_CONFIRMATIONS) {
      revert InvalidRequestConfirmations(
        minimumRequestConfirmations,
        minimumRequestConfirmations,
        MAX_REQUEST_CONFIRMATIONS
      );
    }
    if (fallbackWeiPerUnitLink <= 0) {
      revert InvalidLinkWeiPrice(fallbackWeiPerUnitLink);
    }
    s_config = Config({
      minimumRequestConfirmations: minimumRequestConfirmations,
      maxGasLimit: maxGasLimit,
      stalenessSeconds: stalenessSeconds,
      gasAfterPaymentCalculation: gasAfterPaymentCalculation,
      reentrancyLock: false
    });
    s_feeConfig = feeConfig;
    s_fallbackWeiPerUnitLink = fallbackWeiPerUnitLink;
    emit ConfigSet(
      minimumRequestConfirmations,
      maxGasLimit,
      stalenessSeconds,
      gasAfterPaymentCalculation,
      fallbackWeiPerUnitLink,
      s_feeConfig
    );
  }

  function getConfig()
    external
    view
    returns (
      uint16 minimumRequestConfirmations,
      uint32 maxGasLimit,
      uint32 stalenessSeconds,
      uint32 gasAfterPaymentCalculation
    )
  {
    return (
      s_config.minimumRequestConfirmations,
      s_config.maxGasLimit,
      s_config.stalenessSeconds,
      s_config.gasAfterPaymentCalculation
    );
  }

  function getFeeConfig()
    external
    view
    returns (
      uint32 fulfillmentFlatFeeLinkPPMTier1,
      uint32 fulfillmentFlatFeeLinkPPMTier2,
      uint32 fulfillmentFlatFeeLinkPPMTier3,
      uint32 fulfillmentFlatFeeLinkPPMTier4,
      uint32 fulfillmentFlatFeeLinkPPMTier5,
      uint24 reqsForTier2,
      uint24 reqsForTier3,
      uint24 reqsForTier4,
      uint24 reqsForTier5
    )
  {
    return (
      s_feeConfig.fulfillmentFlatFeeLinkPPMTier1,
      s_feeConfig.fulfillmentFlatFeeLinkPPMTier2,
      s_feeConfig.fulfillmentFlatFeeLinkPPMTier3,
      s_feeConfig.fulfillmentFlatFeeLinkPPMTier4,
      s_feeConfig.fulfillmentFlatFeeLinkPPMTier5,
      s_feeConfig.reqsForTier2,
      s_feeConfig.reqsForTier3,
      s_feeConfig.reqsForTier4,
      s_feeConfig.reqsForTier5
    );
  }

  function getTotalBalance() external view returns (uint256) {
    return s_totalBalance;
  }

  function getFallbackWeiPerUnitLink() external view returns (int256) {
    return s_fallbackWeiPerUnitLink;
  }

  /**
   * @notice Owner cancel subscription, sends remaining link directly to the subscription owner.
   * @param subId subscription id
   * @dev notably can be called even if there are pending requests, outstanding ones may fail onchain
   */
  function ownerCancelSubscription(uint64 subId) external onlyOwner {
    if (s_subscriptionConfigs[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    cancelSubscriptionHelper(subId, s_subscriptionConfigs[subId].owner);
  }

  /**
   * @notice Recover link sent with transfer instead of transferAndCall.
   * @param to address to send link to
   */
  function recoverFunds(address to) external onlyOwner {
    uint256 externalBalance = LINK.balanceOf(address(this));
    uint256 internalBalance = uint256(s_totalBalance);
    if (internalBalance > externalBalance) {
      revert BalanceInvariantViolated(internalBalance, externalBalance);
    }
    if (internalBalance < externalBalance) {
      uint256 amount = externalBalance - internalBalance;
      LINK.transfer(to, amount);
      emit FundsRecovered(to, amount);
    }
    // If the balances are equal, nothing to be done.
  }

  /**
   * @inheritdoc VRFCoordinatorV2Interface
   */
  function getRequestConfig()
    external
    view
    override
    returns (
      uint16,
      uint32,
      bytes32[] memory
    )
  {
    return (s_config.minimumRequestConfirmations, s_config.maxGasLimit, s_provingKeyHashes);
  }

  /**
   * @inheritdoc VRFCoordinatorV2Interface
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 requestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external override nonReentrant returns (uint256) {
    // Input validation using the subscription storage.
    if (s_subscriptionConfigs[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    // Its important to ensure that the consumer is in fact who they say they
    // are, otherwise they could use someone else's subscription balance.
    // A nonce of 0 indicates consumer is not allocated to the sub.
    uint64 currentNonce = s_consumers[msg.sender][subId];
    if (currentNonce == 0) {
      revert InvalidConsumer(subId, msg.sender);
    }
    // Input validation using the config storage word.
    if (
      requestConfirmations < s_config.minimumRequestConfirmations || requestConfirmations > MAX_REQUEST_CONFIRMATIONS
    ) {
      revert InvalidRequestConfirmations(
        requestConfirmations,
        s_config.minimumRequestConfirmations,
        MAX_REQUEST_CONFIRMATIONS
      );
    }
    // No lower bound on the requested gas limit. A user could request 0
    // and they would simply be billed for the proof verification and wouldn't be
    // able to do anything with the random value.
    if (callbackGasLimit > s_config.maxGasLimit) {
      revert GasLimitTooBig(callbackGasLimit, s_config.maxGasLimit);
    }
    if (numWords > MAX_NUM_WORDS) {
      revert NumWordsTooBig(numWords, MAX_NUM_WORDS);
    }
    // Note we do not check whether the keyHash is valid to save gas.
    // The consequence for users is that they can send requests
    // for invalid keyHashes which will simply not be fulfilled.
    uint64 nonce = currentNonce + 1;
    (uint256 requestId, uint256 preSeed) = computeRequestId(keyHash, msg.sender, subId, nonce);

    s_requestCommitments[requestId] = keccak256(
      abi.encode(requestId, block.number, subId, callbackGasLimit, numWords, msg.sender)
    );
    emit RandomWordsRequested(
      keyHash,
      requestId,
      preSeed,
      subId,
      requestConfirmations,
      callbackGasLimit,
      numWords,
      msg.sender
    );
    s_consumers[msg.sender][subId] = nonce;

    return requestId;
  }

  /**
   * @notice Get request commitment
   * @param requestId id of request
   * @dev used to determine if a request is fulfilled or not
   */
  function getCommitment(uint256 requestId) external view returns (bytes32) {
    return s_requestCommitments[requestId];
  }

  function computeRequestId(
    bytes32 keyHash,
    address sender,
    uint64 subId,
    uint64 nonce
  ) private pure returns (uint256, uint256) {
    uint256 preSeed = uint256(keccak256(abi.encode(keyHash, sender, subId, nonce)));
    return (uint256(keccak256(abi.encode(keyHash, preSeed))), preSeed);
  }

  /**
   * @dev calls target address with exactly gasAmount gas and data as calldata
   * or reverts if at least gasAmount gas is not available.
   */
  function callWithExactGas(
    uint256 gasAmount,
    address target,
    bytes memory data
  ) private returns (bool success) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let g := gas()
      // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
      // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
      // We want to ensure that we revert if gasAmount >  63//64*gas available
      // as we do not want to provide them with less, however that check itself costs
      // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
      // to revert if gasAmount >  63//64*gas available.
      if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
        revert(0, 0)
      }
      g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call and return whether we succeeded. ignore return data
      // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }

  function getRandomnessFromProof(Proof memory proof, RequestCommitment memory rc)
    private
    view
    returns (
      bytes32 keyHash,
      uint256 requestId,
      uint256 randomness
    )
  {
    keyHash = hashOfKey(proof.pk);
    // Only registered proving keys are permitted.
    address oracle = s_provingKeys[keyHash];
    if (oracle == address(0)) {
      revert NoSuchProvingKey(keyHash);
    }
    requestId = uint256(keccak256(abi.encode(keyHash, proof.seed)));
    bytes32 commitment = s_requestCommitments[requestId];
    if (commitment == 0) {
      revert NoCorrespondingRequest();
    }
    if (
      commitment != keccak256(abi.encode(requestId, rc.blockNum, rc.subId, rc.callbackGasLimit, rc.numWords, rc.sender))
    ) {
      revert IncorrectCommitment();
    }

    bytes32 blockHash = blockhash(rc.blockNum);
    if (blockHash == bytes32(0)) {
      blockHash = BLOCKHASH_STORE.getBlockhash(rc.blockNum);
      if (blockHash == bytes32(0)) {
        revert BlockhashNotInStore(rc.blockNum);
      }
    }

    // The seed actually used by the VRF machinery, mixing in the blockhash
    uint256 actualSeed = uint256(keccak256(abi.encodePacked(proof.seed, blockHash)));
    randomness = VRF.randomValueFromVRFProof(proof, actualSeed); // Reverts on failure
  }

  /*
   * @notice Compute fee based on the request count
   * @param reqCount number of requests
   * @return feePPM fee in LINK PPM
   */
  function getFeeTier(uint64 reqCount) public view returns (uint32) {
    FeeConfig memory fc = s_feeConfig;
    if (0 <= reqCount && reqCount <= fc.reqsForTier2) {
      return fc.fulfillmentFlatFeeLinkPPMTier1;
    }
    if (fc.reqsForTier2 < reqCount && reqCount <= fc.reqsForTier3) {
      return fc.fulfillmentFlatFeeLinkPPMTier2;
    }
    if (fc.reqsForTier3 < reqCount && reqCount <= fc.reqsForTier4) {
      return fc.fulfillmentFlatFeeLinkPPMTier3;
    }
    if (fc.reqsForTier4 < reqCount && reqCount <= fc.reqsForTier5) {
      return fc.fulfillmentFlatFeeLinkPPMTier4;
    }
    return fc.fulfillmentFlatFeeLinkPPMTier5;
  }

  /*
   * @notice Fulfill a randomness request
   * @param proof contains the proof and randomness
   * @param rc request commitment pre-image, committed to at request time
   * @return payment amount billed to the subscription
   * @dev simulated offchain to determine if sufficient balance is present to fulfill the request
   */
  function fulfillRandomWords(Proof memory proof, RequestCommitment memory rc) external nonReentrant returns (uint96) {
    uint256 startGas = gasleft();
    (bytes32 keyHash, uint256 requestId, uint256 randomness) = getRandomnessFromProof(proof, rc);

    uint256[] memory randomWords = new uint256[](rc.numWords);
    for (uint256 i = 0; i < rc.numWords; i++) {
      randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
    }

    delete s_requestCommitments[requestId];
    VRFConsumerBaseV2 v;
    bytes memory resp = abi.encodeWithSelector(v.rawFulfillRandomWords.selector, requestId, randomWords);
    // Call with explicitly the amount of callback gas requested
    // Important to not let them exhaust the gas budget and avoid oracle payment.
    // Do not allow any non-view/non-pure coordinator functions to be called
    // during the consumers callback code via reentrancyLock.
    // Note that callWithExactGas will revert if we do not have sufficient gas
    // to give the callee their requested amount.
    s_config.reentrancyLock = true;
    bool success = callWithExactGas(rc.callbackGasLimit, rc.sender, resp);
    s_config.reentrancyLock = false;

    // Increment the req count for fee tier selection.
    uint64 reqCount = s_subscriptions[rc.subId].reqCount;
    s_subscriptions[rc.subId].reqCount += 1;

    // We want to charge users exactly for how much gas they use in their callback.
    // The gasAfterPaymentCalculation is meant to cover these additional operations where we
    // decrement the subscription balance and increment the oracles withdrawable balance.
    // We also add the flat link fee to the payment amount.
    // Its specified in millionths of link, if s_config.fulfillmentFlatFeeLinkPPM = 1
    // 1 link / 1e6 = 1e18 juels / 1e6 = 1e12 juels.
    uint96 payment = calculatePaymentAmount(
      startGas,
      s_config.gasAfterPaymentCalculation,
      getFeeTier(reqCount),
      tx.gasprice
    );
    if (s_subscriptions[rc.subId].balance < payment) {
      revert InsufficientBalance();
    }
    s_subscriptions[rc.subId].balance -= payment;
    s_withdrawableTokens[s_provingKeys[keyHash]] += payment;
    // Include payment in the event for tracking costs.
    emit RandomWordsFulfilled(requestId, randomness, payment, success);
    return payment;
  }

  // Get the amount of gas used for fulfillment
  function calculatePaymentAmount(
    uint256 startGas,
    uint256 gasAfterPaymentCalculation,
    uint32 fulfillmentFlatFeeLinkPPM,
    uint256 weiPerUnitGas
  ) internal view returns (uint96) {
    int256 weiPerUnitLink;
    weiPerUnitLink = getFeedData();
    if (weiPerUnitLink <= 0) {
      revert InvalidLinkWeiPrice(weiPerUnitLink);
    }
    // (1e18 juels/link) (wei/gas * gas) / (wei/link) = juels
    uint256 paymentNoFee = (1e18 * weiPerUnitGas * (gasAfterPaymentCalculation + startGas - gasleft())) /
      uint256(weiPerUnitLink);
    uint256 fee = 1e12 * uint256(fulfillmentFlatFeeLinkPPM);
    if (paymentNoFee > (1e27 - fee)) {
      revert PaymentTooLarge(); // Payment + fee cannot be more than all of the link in existence.
    }
    return uint96(paymentNoFee + fee);
  }

  function getFeedData() private view returns (int256) {
    uint32 stalenessSeconds = s_config.stalenessSeconds;
    bool staleFallback = stalenessSeconds > 0;
    uint256 timestamp;
    int256 weiPerUnitLink;
    (, weiPerUnitLink, , timestamp, ) = LINK_ETH_FEED.latestRoundData();
    // solhint-disable-next-line not-rely-on-time
    if (staleFallback && stalenessSeconds < block.timestamp - timestamp) {
      weiPerUnitLink = s_fallbackWeiPerUnitLink;
    }
    return weiPerUnitLink;
  }

  /*
   * @notice Oracle withdraw LINK earned through fulfilling requests
   * @param recipient where to send the funds
   * @param amount amount to withdraw
   */
  function oracleWithdraw(address recipient, uint96 amount) external nonReentrant {
    if (s_withdrawableTokens[msg.sender] < amount) {
      revert InsufficientBalance();
    }
    s_withdrawableTokens[msg.sender] -= amount;
    s_totalBalance -= amount;
    if (!LINK.transfer(recipient, amount)) {
      revert InsufficientBalance();
    }
  }

  function onTokenTransfer(
    address, /* sender */
    uint256 amount,
    bytes calldata data
  ) external override nonReentrant {
    if (msg.sender != address(LINK)) {
      revert OnlyCallableFromLink();
    }
    if (data.length != 32) {
      revert InvalidCalldata();
    }
    uint64 subId = abi.decode(data, (uint64));
    if (s_subscriptionConfigs[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    // We do not check that the msg.sender is the subscription owner,
    // anyone can fund a subscription.
    uint256 oldBalance = s_subscriptions[subId].balance;
    s_subscriptions[subId].balance += uint96(amount);
    s_totalBalance += uint96(amount);
    emit SubscriptionFunded(subId, oldBalance, oldBalance + amount);
  }

  function getCurrentSubId() external view returns (uint64) {
    return s_currentSubId;
  }

  /**
   * @inheritdoc VRFCoordinatorV2Interface
   */
  function getSubscription(uint64 subId)
    external
    view
    override
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    )
  {
    if (s_subscriptionConfigs[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    return (
      s_subscriptions[subId].balance,
      s_subscriptions[subId].reqCount,
      s_subscriptionConfigs[subId].owner,
      s_subscriptionConfigs[subId].consumers
    );
  }

  /**
   * @inheritdoc VRFCoordinatorV2Interface
   */
  function createSubscription() external override nonReentrant returns (uint64) {
    s_currentSubId++;
    uint64 currentSubId = s_currentSubId;
    address[] memory consumers = new address[](0);
    s_subscriptions[currentSubId] = Subscription({balance: 0, reqCount: 0});
    s_subscriptionConfigs[currentSubId] = SubscriptionConfig({
      owner: msg.sender,
      requestedOwner: address(0),
      consumers: consumers
    });

    emit SubscriptionCreated(currentSubId, msg.sender);
    return currentSubId;
  }

  /**
   * @inheritdoc VRFCoordinatorV2Interface
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner)
    external
    override
    onlySubOwner(subId)
    nonReentrant
  {
    // Proposing to address(0) would never be claimable so don't need to check.
    if (s_subscriptionConfigs[subId].requestedOwner != newOwner) {
      s_subscriptionConfigs[subId].requestedOwner = newOwner;
      emit SubscriptionOwnerTransferRequested(subId, msg.sender, newOwner);
    }
  }

  /**
   * @inheritdoc VRFCoordinatorV2Interface
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external override nonReentrant {
    if (s_subscriptionConfigs[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    if (s_subscriptionConfigs[subId].requestedOwner != msg.sender) {
      revert MustBeRequestedOwner(s_subscriptionConfigs[subId].requestedOwner);
    }
    address oldOwner = s_subscriptionConfigs[subId].owner;
    s_subscriptionConfigs[subId].owner = msg.sender;
    s_subscriptionConfigs[subId].requestedOwner = address(0);
    emit SubscriptionOwnerTransferred(subId, oldOwner, msg.sender);
  }

  /**
   * @inheritdoc VRFCoordinatorV2Interface
   */
  function removeConsumer(uint64 subId, address consumer) external override onlySubOwner(subId) nonReentrant {
    if (s_consumers[consumer][subId] == 0) {
      revert InvalidConsumer(subId, consumer);
    }
    // Note bounded by MAX_CONSUMERS
    address[] memory consumers = s_subscriptionConfigs[subId].consumers;
    uint256 lastConsumerIndex = consumers.length - 1;
    for (uint256 i = 0; i < consumers.length; i++) {
      if (consumers[i] == consumer) {
        address last = consumers[lastConsumerIndex];
        // Storage write to preserve last element
        s_subscriptionConfigs[subId].consumers[i] = last;
        // Storage remove last element
        s_subscriptionConfigs[subId].consumers.pop();
        break;
      }
    }
    delete s_consumers[consumer][subId];
    emit SubscriptionConsumerRemoved(subId, consumer);
  }

  /**
   * @inheritdoc VRFCoordinatorV2Interface
   */
  function addConsumer(uint64 subId, address consumer) external override onlySubOwner(subId) nonReentrant {
    // Already maxed, cannot add any more consumers.
    if (s_subscriptionConfigs[subId].consumers.length == MAX_CONSUMERS) {
      revert TooManyConsumers();
    }
    if (s_consumers[consumer][subId] != 0) {
      // Idempotence - do nothing if already added.
      // Ensures uniqueness in s_subscriptions[subId].consumers.
      return;
    }
    // Initialize the nonce to 1, indicating the consumer is allocated.
    s_consumers[consumer][subId] = 1;
    s_subscriptionConfigs[subId].consumers.push(consumer);

    emit SubscriptionConsumerAdded(subId, consumer);
  }

  /**
   * @inheritdoc VRFCoordinatorV2Interface
   */
  function cancelSubscription(uint64 subId, address to) external override onlySubOwner(subId) nonReentrant {
    if (pendingRequestExists(subId)) {
      revert PendingRequestExists();
    }
    cancelSubscriptionHelper(subId, to);
  }

  function cancelSubscriptionHelper(uint64 subId, address to) private nonReentrant {
    SubscriptionConfig memory subConfig = s_subscriptionConfigs[subId];
    Subscription memory sub = s_subscriptions[subId];
    uint96 balance = sub.balance;
    // Note bounded by MAX_CONSUMERS;
    // If no consumers, does nothing.
    for (uint256 i = 0; i < subConfig.consumers.length; i++) {
      delete s_consumers[subConfig.consumers[i]][subId];
    }
    delete s_subscriptionConfigs[subId];
    delete s_subscriptions[subId];
    s_totalBalance -= balance;
    if (!LINK.transfer(to, uint256(balance))) {
      revert InsufficientBalance();
    }
    emit SubscriptionCanceled(subId, to, balance);
  }

  /*
   * @noticeCheck to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId where to send the funds
   * @return exits true if outstanding requests
   * @dev Looping is bounded to MAX_CONSUMERS*(number of keyhashes).
   * @dev Used to disable subscription canceling while outstanding request are present.
   */
  function pendingRequestExists(uint64 subId) public view returns (bool) {
    SubscriptionConfig memory subConfig = s_subscriptionConfigs[subId];
    for (uint256 i = 0; i < subConfig.consumers.length; i++) {
      for (uint256 j = 0; j < s_provingKeyHashes.length; j++) {
        (uint256 reqId, ) = computeRequestId(
          s_provingKeyHashes[j],
          subConfig.consumers[i],
          subId,
          s_consumers[subConfig.consumers[i]][subId]
        );
        if (s_requestCommitments[reqId] != 0) {
          return true;
        }
      }
    }
    return false;
  }

  modifier onlySubOwner(uint64 subId) {
    address owner = s_subscriptionConfigs[subId].owner;
    if (owner == address(0)) {
      revert InvalidSubscription();
    }
    if (msg.sender != owner) {
      revert MustBeSubOwner(owner);
    }
    _;
  }

  modifier nonReentrant() {
    if (s_config.reentrancyLock) {
      revert Reentrant();
    }
    _;
  }

  /**
   * @notice The type and version of this contract
   * @return Type and version string
   */
  function typeAndVersion() external pure virtual override returns (string memory) {
    return "VRFCoordinatorV2 1.0.0";
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface BlockhashStoreInterface {
  function getBlockhash(uint256 number) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ERC677ReceiverInterface {
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
  * @notice Verification of verifiable-random-function (VRF) proofs, following
  * @notice https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
  * @notice See https://eprint.iacr.org/2017/099.pdf for security proofs.

  * @dev Bibliographic references:

  * @dev Goldberg, et al., "Verifiable Random Functions (VRFs)", Internet Draft
  * @dev draft-irtf-cfrg-vrf-05, IETF, Aug 11 2019,
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05

  * @dev Papadopoulos, et al., "Making NSEC5 Practical for DNSSEC", Cryptology
  * @dev ePrint Archive, Report 2017/099, https://eprint.iacr.org/2017/099.pdf
  * ****************************************************************************
  * @dev USAGE

  * @dev The main entry point is randomValueFromVRFProof. See its docstring.
  * ****************************************************************************
  * @dev PURPOSE

  * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
  * @dev to Vera the verifier in such a way that Vera can be sure he's not
  * @dev making his output up to suit himself. Reggie provides Vera a public key
  * @dev to which he knows the secret key. Each time Vera provides a seed to
  * @dev Reggie, he gives back a value which is computed completely
  * @dev deterministically from the seed and the secret key.

  * @dev Reggie provides a proof by which Vera can verify that the output was
  * @dev correctly computed once Reggie tells it to her, but without that proof,
  * @dev the output is computationally indistinguishable to her from a uniform
  * @dev random sample from the output space.

  * @dev The purpose of this contract is to perform that verification.
  * ****************************************************************************
  * @dev DESIGN NOTES

  * @dev The VRF algorithm verified here satisfies the full uniqueness, full
  * @dev collision resistance, and full pseudo-randomness security properties.
  * @dev See "SECURITY PROPERTIES" below, and
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-3

  * @dev An elliptic curve point is generally represented in the solidity code
  * @dev as a uint256[2], corresponding to its affine coordinates in
  * @dev GF(FIELD_SIZE).

  * @dev For the sake of efficiency, this implementation deviates from the spec
  * @dev in some minor ways:

  * @dev - Keccak hash rather than the SHA256 hash recommended in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
  * @dev   Keccak costs much less gas on the EVM, and provides similar security.

  * @dev - Secp256k1 curve instead of the P-256 or ED25519 curves recommended in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
  * @dev   For curve-point multiplication, it's much cheaper to abuse ECRECOVER

  * @dev - hashToCurve recursively hashes until it finds a curve x-ordinate. On
  * @dev   the EVM, this is slightly more efficient than the recommendation in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
  * @dev   step 5, to concatenate with a nonce then hash, and rehash with the
  * @dev   nonce updated until a valid x-ordinate is found.

  * @dev - hashToCurve does not include a cipher version string or the byte 0x1
  * @dev   in the hash message, as recommended in step 5.B of the draft
  * @dev   standard. They are unnecessary here because no variation in the
  * @dev   cipher suite is allowed.

  * @dev - Similarly, the hash input in scalarFromCurvePoints does not include a
  * @dev   commitment to the cipher suite, either, which differs from step 2 of
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
  * @dev   . Also, the hash input is the concatenation of the uncompressed
  * @dev   points, not the compressed points as recommended in step 3.

  * @dev - In the calculation of the challenge value "c", the "u" value (i.e.
  * @dev   the value computed by Reggie as the nonce times the secp256k1
  * @dev   generator point, see steps 5 and 7 of
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
  * @dev   ) is replaced by its ethereum address, i.e. the lower 160 bits of the
  * @dev   keccak hash of the original u. This is because we only verify the
  * @dev   calculation of u up to its address, by abusing ECRECOVER.
  * ****************************************************************************
  * @dev   SECURITY PROPERTIES

  * @dev Here are the security properties for this VRF:

  * @dev Full uniqueness: For any seed and valid VRF public key, there is
  * @dev   exactly one VRF output which can be proved to come from that seed, in
  * @dev   the sense that the proof will pass verifyVRFProof.

  * @dev Full collision resistance: It's cryptographically infeasible to find
  * @dev   two seeds with same VRF output from a fixed, valid VRF key

  * @dev Full pseudorandomness: Absent the proofs that the VRF outputs are
  * @dev   derived from a given seed, the outputs are computationally
  * @dev   indistinguishable from randomness.

  * @dev https://eprint.iacr.org/2017/099.pdf, Appendix B contains the proofs
  * @dev for these properties.

  * @dev For secp256k1, the key validation described in section
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.6
  * @dev is unnecessary, because secp256k1 has cofactor 1, and the
  * @dev representation of the public key used here (affine x- and y-ordinates
  * @dev of the secp256k1 point on the standard y^2=x^3+7 curve) cannot refer to
  * @dev the point at infinity.
  * ****************************************************************************
  * @dev OTHER SECURITY CONSIDERATIONS
  *
  * @dev The seed input to the VRF could in principle force an arbitrary amount
  * @dev of work in hashToCurve, by requiring extra rounds of hashing and
  * @dev checking whether that's yielded the x ordinate of a secp256k1 point.
  * @dev However, under the Random Oracle Model the probability of choosing a
  * @dev point which forces n extra rounds in hashToCurve is 2⁻ⁿ. The base cost
  * @dev for calling hashToCurve is about 25,000 gas, and each round of checking
  * @dev for a valid x ordinate costs about 15,555 gas, so to find a seed for
  * @dev which hashToCurve would cost more than 2,017,000 gas, one would have to
  * @dev try, in expectation, about 2¹²⁸ seeds, which is infeasible for any
  * @dev foreseeable computational resources. (25,000 + 128 * 15,555 < 2,017,000.)

  * @dev Since the gas block limit for the Ethereum main net is 10,000,000 gas,
  * @dev this means it is infeasible for an adversary to prevent correct
  * @dev operation of this contract by choosing an adverse seed.

  * @dev (See TestMeasureHashToCurveGasCost for verification of the gas cost for
  * @dev hashToCurve.)

  * @dev It may be possible to make a secure constant-time hashToCurve function.
  * @dev See notes in hashToCurve docstring.
*/
contract VRF {
  // See https://www.secg.org/sec2-v2.pdf, section 2.4.1, for these constants.
  // Number of points in Secp256k1
  uint256 private constant GROUP_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
  // Prime characteristic of the galois field over which Secp256k1 is defined
  uint256 private constant FIELD_SIZE =
    // solium-disable-next-line indentation
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
  uint256 private constant WORD_LENGTH_BYTES = 0x20;

  // (base^exponent) % FIELD_SIZE
  // Cribbed from https://medium.com/@rbkhmrcr/precompiles-solidity-e5d29bd428c4
  function bigModExp(uint256 base, uint256 exponent) internal view returns (uint256 exponentiation) {
    uint256 callResult;
    uint256[6] memory bigModExpContractInputs;
    bigModExpContractInputs[0] = WORD_LENGTH_BYTES; // Length of base
    bigModExpContractInputs[1] = WORD_LENGTH_BYTES; // Length of exponent
    bigModExpContractInputs[2] = WORD_LENGTH_BYTES; // Length of modulus
    bigModExpContractInputs[3] = base;
    bigModExpContractInputs[4] = exponent;
    bigModExpContractInputs[5] = FIELD_SIZE;
    uint256[1] memory output;
    assembly {
      // solhint-disable-line no-inline-assembly
      callResult := staticcall(
        not(0), // Gas cost: no limit
        0x05, // Bigmodexp contract address
        bigModExpContractInputs,
        0xc0, // Length of input segment: 6*0x20-bytes
        output,
        0x20 // Length of output segment
      )
    }
    if (callResult == 0) {
      revert("bigModExp failure!");
    }
    return output[0];
  }

  // Let q=FIELD_SIZE. q % 4 = 3, ∴ x≡r^2 mod q ⇒ x^SQRT_POWER≡±r mod q.  See
  // https://en.wikipedia.org/wiki/Modular_square_root#Prime_or_prime_power_modulus
  uint256 private constant SQRT_POWER = (FIELD_SIZE + 1) >> 2;

  // Computes a s.t. a^2 = x in the field. Assumes a exists
  function squareRoot(uint256 x) internal view returns (uint256) {
    return bigModExp(x, SQRT_POWER);
  }

  // The value of y^2 given that (x,y) is on secp256k1.
  function ySquared(uint256 x) internal pure returns (uint256) {
    // Curve is y^2=x^3+7. See section 2.4.1 of https://www.secg.org/sec2-v2.pdf
    uint256 xCubed = mulmod(x, mulmod(x, x, FIELD_SIZE), FIELD_SIZE);
    return addmod(xCubed, 7, FIELD_SIZE);
  }

  // True iff p is on secp256k1
  function isOnCurve(uint256[2] memory p) internal pure returns (bool) {
    // Section 2.3.6. in https://www.secg.org/sec1-v2.pdf
    // requires each ordinate to be in [0, ..., FIELD_SIZE-1]
    require(p[0] < FIELD_SIZE, "invalid x-ordinate");
    require(p[1] < FIELD_SIZE, "invalid y-ordinate");
    return ySquared(p[0]) == mulmod(p[1], p[1], FIELD_SIZE);
  }

  // Hash x uniformly into {0, ..., FIELD_SIZE-1}.
  function fieldHash(bytes memory b) internal pure returns (uint256 x_) {
    x_ = uint256(keccak256(b));
    // Rejecting if x >= FIELD_SIZE corresponds to step 2.1 in section 2.3.4 of
    // http://www.secg.org/sec1-v2.pdf , which is part of the definition of
    // string_to_point in the IETF draft
    while (x_ >= FIELD_SIZE) {
      x_ = uint256(keccak256(abi.encodePacked(x_)));
    }
  }

  // Hash b to a random point which hopefully lies on secp256k1. The y ordinate
  // is always even, due to
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
  // step 5.C, which references arbitrary_string_to_point, defined in
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5 as
  // returning the point with given x ordinate, and even y ordinate.
  function newCandidateSecp256k1Point(bytes memory b) internal view returns (uint256[2] memory p) {
    unchecked {
      p[0] = fieldHash(b);
      p[1] = squareRoot(ySquared(p[0]));
      if (p[1] % 2 == 1) {
        // Note that 0 <= p[1] < FIELD_SIZE
        // so this cannot wrap, we use unchecked to save gas.
        p[1] = FIELD_SIZE - p[1];
      }
    }
  }

  // Domain-separation tag for initial hash in hashToCurve. Corresponds to
  // vrf.go/hashToCurveHashPrefix
  uint256 internal constant HASH_TO_CURVE_HASH_PREFIX = 1;

  // Cryptographic hash function onto the curve.
  //
  // Corresponds to algorithm in section 5.4.1.1 of the draft standard. (But see
  // DESIGN NOTES above for slight differences.)
  //
  // TODO(alx): Implement a bounded-computation hash-to-curve, as described in
  // "Construction of Rational Points on Elliptic Curves over Finite Fields"
  // http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.831.5299&rep=rep1&type=pdf
  // and suggested by
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-01#section-5.2.2
  // (Though we can't used exactly that because secp256k1's j-invariant is 0.)
  //
  // This would greatly simplify the analysis in "OTHER SECURITY CONSIDERATIONS"
  // https://www.pivotaltracker.com/story/show/171120900
  function hashToCurve(uint256[2] memory pk, uint256 input) internal view returns (uint256[2] memory rv) {
    rv = newCandidateSecp256k1Point(abi.encodePacked(HASH_TO_CURVE_HASH_PREFIX, pk, input));
    while (!isOnCurve(rv)) {
      rv = newCandidateSecp256k1Point(abi.encodePacked(rv[0]));
    }
  }

  /** *********************************************************************
   * @notice Check that product==scalar*multiplicand
   *
   * @dev Based on Vitalik Buterin's idea in ethresear.ch post cited below.
   *
   * @param multiplicand: secp256k1 point
   * @param scalar: non-zero GF(GROUP_ORDER) scalar
   * @param product: secp256k1 expected to be multiplier * multiplicand
   * @return verifies true iff product==scalar*multiplicand, with cryptographically high probability
   */
  function ecmulVerify(
    uint256[2] memory multiplicand,
    uint256 scalar,
    uint256[2] memory product
  ) internal pure returns (bool verifies) {
    require(scalar != 0, "zero scalar"); // Rules out an ecrecover failure case
    uint256 x = multiplicand[0]; // x ordinate of multiplicand
    uint8 v = multiplicand[1] % 2 == 0 ? 27 : 28; // parity of y ordinate
    // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
    // Point corresponding to address ecrecover(0, v, x, s=scalar*x) is
    // (x⁻¹ mod GROUP_ORDER) * (scalar * x * multiplicand - 0 * g), i.e.
    // scalar*multiplicand. See https://crypto.stackexchange.com/a/18106
    bytes32 scalarTimesX = bytes32(mulmod(scalar, x, GROUP_ORDER));
    address actual = ecrecover(bytes32(0), v, bytes32(x), scalarTimesX);
    // Explicit conversion to address takes bottom 160 bits
    address expected = address(uint160(uint256(keccak256(abi.encodePacked(product)))));
    return (actual == expected);
  }

  // Returns x1/z1-x2/z2=(x1z2-x2z1)/(z1z2) in projective coordinates on P¹(𝔽ₙ)
  function projectiveSub(
    uint256 x1,
    uint256 z1,
    uint256 x2,
    uint256 z2
  ) internal pure returns (uint256 x3, uint256 z3) {
    unchecked {
      uint256 num1 = mulmod(z2, x1, FIELD_SIZE);
      // Note this cannot wrap since x2 is a point in [0, FIELD_SIZE-1]
      // we use unchecked to save gas.
      uint256 num2 = mulmod(FIELD_SIZE - x2, z1, FIELD_SIZE);
      (x3, z3) = (addmod(num1, num2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
    }
  }

  // Returns x1/z1*x2/z2=(x1x2)/(z1z2), in projective coordinates on P¹(𝔽ₙ)
  function projectiveMul(
    uint256 x1,
    uint256 z1,
    uint256 x2,
    uint256 z2
  ) internal pure returns (uint256 x3, uint256 z3) {
    (x3, z3) = (mulmod(x1, x2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
  }

  /** **************************************************************************
        @notice Computes elliptic-curve sum, in projective co-ordinates

        @dev Using projective coordinates avoids costly divisions

        @dev To use this with p and q in affine coordinates, call
        @dev projectiveECAdd(px, py, qx, qy). This will return
        @dev the addition of (px, py, 1) and (qx, qy, 1), in the
        @dev secp256k1 group.

        @dev This can be used to calculate the z which is the inverse to zInv
        @dev in isValidVRFOutput. But consider using a faster
        @dev re-implementation such as ProjectiveECAdd in the golang vrf package.

        @dev This function assumes [px,py,1],[qx,qy,1] are valid projective
             coordinates of secp256k1 points. That is safe in this contract,
             because this method is only used by linearCombination, which checks
             points are on the curve via ecrecover.
        **************************************************************************
        @param px The first affine coordinate of the first summand
        @param py The second affine coordinate of the first summand
        @param qx The first affine coordinate of the second summand
        @param qy The second affine coordinate of the second summand

        (px,py) and (qx,qy) must be distinct, valid secp256k1 points.
        **************************************************************************
        Return values are projective coordinates of [px,py,1]+[qx,qy,1] as points
        on secp256k1, in P²(𝔽ₙ)
        @return sx
        @return sy
        @return sz
    */
  function projectiveECAdd(
    uint256 px,
    uint256 py,
    uint256 qx,
    uint256 qy
  )
    internal
    pure
    returns (
      uint256 sx,
      uint256 sy,
      uint256 sz
    )
  {
    unchecked {
      // See "Group law for E/K : y^2 = x^3 + ax + b", in section 3.1.2, p. 80,
      // "Guide to Elliptic Curve Cryptography" by Hankerson, Menezes and Vanstone
      // We take the equations there for (sx,sy), and homogenize them to
      // projective coordinates. That way, no inverses are required, here, and we
      // only need the one inverse in affineECAdd.

      // We only need the "point addition" equations from Hankerson et al. Can
      // skip the "point doubling" equations because p1 == p2 is cryptographically
      // impossible, and required not to be the case in linearCombination.

      // Add extra "projective coordinate" to the two points
      (uint256 z1, uint256 z2) = (1, 1);

      // (lx, lz) = (qy-py)/(qx-px), i.e., gradient of secant line.
      // Cannot wrap since px and py are in [0, FIELD_SIZE-1]
      uint256 lx = addmod(qy, FIELD_SIZE - py, FIELD_SIZE);
      uint256 lz = addmod(qx, FIELD_SIZE - px, FIELD_SIZE);

      uint256 dx; // Accumulates denominator from sx calculation
      // sx=((qy-py)/(qx-px))^2-px-qx
      (sx, dx) = projectiveMul(lx, lz, lx, lz); // ((qy-py)/(qx-px))^2
      (sx, dx) = projectiveSub(sx, dx, px, z1); // ((qy-py)/(qx-px))^2-px
      (sx, dx) = projectiveSub(sx, dx, qx, z2); // ((qy-py)/(qx-px))^2-px-qx

      uint256 dy; // Accumulates denominator from sy calculation
      // sy=((qy-py)/(qx-px))(px-sx)-py
      (sy, dy) = projectiveSub(px, z1, sx, dx); // px-sx
      (sy, dy) = projectiveMul(sy, dy, lx, lz); // ((qy-py)/(qx-px))(px-sx)
      (sy, dy) = projectiveSub(sy, dy, py, z1); // ((qy-py)/(qx-px))(px-sx)-py

      if (dx != dy) {
        // Cross-multiply to put everything over a common denominator
        sx = mulmod(sx, dy, FIELD_SIZE);
        sy = mulmod(sy, dx, FIELD_SIZE);
        sz = mulmod(dx, dy, FIELD_SIZE);
      } else {
        // Already over a common denominator, use that for z ordinate
        sz = dx;
      }
    }
  }

  // p1+p2, as affine points on secp256k1.
  //
  // invZ must be the inverse of the z returned by projectiveECAdd(p1, p2).
  // It is computed off-chain to save gas.
  //
  // p1 and p2 must be distinct, because projectiveECAdd doesn't handle
  // point doubling.
  function affineECAdd(
    uint256[2] memory p1,
    uint256[2] memory p2,
    uint256 invZ
  ) internal pure returns (uint256[2] memory) {
    uint256 x;
    uint256 y;
    uint256 z;
    (x, y, z) = projectiveECAdd(p1[0], p1[1], p2[0], p2[1]);
    require(mulmod(z, invZ, FIELD_SIZE) == 1, "invZ must be inverse of z");
    // Clear the z ordinate of the projective representation by dividing through
    // by it, to obtain the affine representation
    return [mulmod(x, invZ, FIELD_SIZE), mulmod(y, invZ, FIELD_SIZE)];
  }

  // True iff address(c*p+s*g) == lcWitness, where g is generator. (With
  // cryptographically high probability.)
  function verifyLinearCombinationWithGenerator(
    uint256 c,
    uint256[2] memory p,
    uint256 s,
    address lcWitness
  ) internal pure returns (bool) {
    // Rule out ecrecover failure modes which return address 0.
    unchecked {
      require(lcWitness != address(0), "bad witness");
      uint8 v = (p[1] % 2 == 0) ? 27 : 28; // parity of y-ordinate of p
      // Note this cannot wrap (X - Y % X), but we use unchecked to save
      // gas.
      bytes32 pseudoHash = bytes32(GROUP_ORDER - mulmod(p[0], s, GROUP_ORDER)); // -s*p[0]
      bytes32 pseudoSignature = bytes32(mulmod(c, p[0], GROUP_ORDER)); // c*p[0]
      // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
      // The point corresponding to the address returned by
      // ecrecover(-s*p[0],v,p[0],c*p[0]) is
      // (p[0]⁻¹ mod GROUP_ORDER)*(c*p[0]-(-s)*p[0]*g)=c*p+s*g.
      // See https://crypto.stackexchange.com/a/18106
      // https://bitcoin.stackexchange.com/questions/38351/ecdsa-v-r-s-what-is-v
      address computed = ecrecover(pseudoHash, v, bytes32(p[0]), pseudoSignature);
      return computed == lcWitness;
    }
  }

  // c*p1 + s*p2. Requires cp1Witness=c*p1 and sp2Witness=s*p2. Also
  // requires cp1Witness != sp2Witness (which is fine for this application,
  // since it is cryptographically impossible for them to be equal. In the
  // (cryptographically impossible) case that a prover accidentally derives
  // a proof with equal c*p1 and s*p2, they should retry with a different
  // proof nonce.) Assumes that all points are on secp256k1
  // (which is checked in verifyVRFProof below.)
  function linearCombination(
    uint256 c,
    uint256[2] memory p1,
    uint256[2] memory cp1Witness,
    uint256 s,
    uint256[2] memory p2,
    uint256[2] memory sp2Witness,
    uint256 zInv
  ) internal pure returns (uint256[2] memory) {
    unchecked {
      // Note we are relying on the wrap around here
      require((cp1Witness[0] % FIELD_SIZE) != (sp2Witness[0] % FIELD_SIZE), "points in sum must be distinct");
      require(ecmulVerify(p1, c, cp1Witness), "First mul check failed");
      require(ecmulVerify(p2, s, sp2Witness), "Second mul check failed");
      return affineECAdd(cp1Witness, sp2Witness, zInv);
    }
  }

  // Domain-separation tag for the hash taken in scalarFromCurvePoints.
  // Corresponds to scalarFromCurveHashPrefix in vrf.go
  uint256 internal constant SCALAR_FROM_CURVE_POINTS_HASH_PREFIX = 2;

  // Pseudo-random number from inputs. Matches vrf.go/scalarFromCurvePoints, and
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
  // The draft calls (in step 7, via the definition of string_to_int, in
  // https://datatracker.ietf.org/doc/html/rfc8017#section-4.2 ) for taking the
  // first hash without checking that it corresponds to a number less than the
  // group order, which will lead to a slight bias in the sample.
  //
  // TODO(alx): We could save a bit of gas by following the standard here and
  // using the compressed representation of the points, if we collated the y
  // parities into a single bytes32.
  // https://www.pivotaltracker.com/story/show/171120588
  function scalarFromCurvePoints(
    uint256[2] memory hash,
    uint256[2] memory pk,
    uint256[2] memory gamma,
    address uWitness,
    uint256[2] memory v
  ) internal pure returns (uint256 s) {
    return uint256(keccak256(abi.encodePacked(SCALAR_FROM_CURVE_POINTS_HASH_PREFIX, hash, pk, gamma, v, uWitness)));
  }

  // True if (gamma, c, s) is a correctly constructed randomness proof from pk
  // and seed. zInv must be the inverse of the third ordinate from
  // projectiveECAdd applied to cGammaWitness and sHashWitness. Corresponds to
  // section 5.3 of the IETF draft.
  //
  // TODO(alx): Since I'm only using pk in the ecrecover call, I could only pass
  // the x ordinate, and the parity of the y ordinate in the top bit of uWitness
  // (which I could make a uint256 without using any extra space.) Would save
  // about 2000 gas. https://www.pivotaltracker.com/story/show/170828567
  function verifyVRFProof(
    uint256[2] memory pk,
    uint256[2] memory gamma,
    uint256 c,
    uint256 s,
    uint256 seed,
    address uWitness,
    uint256[2] memory cGammaWitness,
    uint256[2] memory sHashWitness,
    uint256 zInv
  ) internal view {
    unchecked {
      require(isOnCurve(pk), "public key is not on curve");
      require(isOnCurve(gamma), "gamma is not on curve");
      require(isOnCurve(cGammaWitness), "cGammaWitness is not on curve");
      require(isOnCurve(sHashWitness), "sHashWitness is not on curve");
      // Step 5. of IETF draft section 5.3 (pk corresponds to 5.3's Y, and here
      // we use the address of u instead of u itself. Also, here we add the
      // terms instead of taking the difference, and in the proof construction in
      // vrf.GenerateProof, we correspondingly take the difference instead of
      // taking the sum as they do in step 7 of section 5.1.)
      require(verifyLinearCombinationWithGenerator(c, pk, s, uWitness), "addr(c*pk+s*g)!=_uWitness");
      // Step 4. of IETF draft section 5.3 (pk corresponds to Y, seed to alpha_string)
      uint256[2] memory hash = hashToCurve(pk, seed);
      // Step 6. of IETF draft section 5.3, but see note for step 5 about +/- terms
      uint256[2] memory v = linearCombination(c, gamma, cGammaWitness, s, hash, sHashWitness, zInv);
      // Steps 7. and 8. of IETF draft section 5.3
      uint256 derivedC = scalarFromCurvePoints(hash, pk, gamma, uWitness, v);
      require(c == derivedC, "invalid proof");
    }
  }

  // Domain-separation tag for the hash used as the final VRF output.
  // Corresponds to vrfRandomOutputHashPrefix in vrf.go
  uint256 internal constant VRF_RANDOM_OUTPUT_HASH_PREFIX = 3;

  struct Proof {
    uint256[2] pk;
    uint256[2] gamma;
    uint256 c;
    uint256 s;
    uint256 seed;
    address uWitness;
    uint256[2] cGammaWitness;
    uint256[2] sHashWitness;
    uint256 zInv;
  }

  /* ***************************************************************************
     * @notice Returns proof's output, if proof is valid. Otherwise reverts

     * @param proof vrf proof components
     * @param seed  seed used to generate the vrf output
     *
     * Throws if proof is invalid, otherwise:
     * @return output i.e., the random output implied by the proof
     * ***************************************************************************
     */
  function randomValueFromVRFProof(Proof memory proof, uint256 seed) internal view returns (uint256 output) {
    verifyVRFProof(
      proof.pk,
      proof.gamma,
      proof.c,
      proof.s,
      seed,
      proof.uWitness,
      proof.cGammaWitness,
      proof.sHashWitness,
      proof.zInv
    );
    output = uint256(keccak256(abi.encode(VRF_RANDOM_OUTPUT_HASH_PREFIX, proof.gamma)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../dev/VRFCoordinatorV2.sol";

contract VRFCoordinatorV2TestHelper is VRFCoordinatorV2 {
  uint96 s_paymentAmount;
  uint256 s_gasStart;

  constructor(
    address link,
    address blockhashStore,
    address linkEthFeed
  )
    // solhint-disable-next-line no-empty-blocks
    VRFCoordinatorV2(link, blockhashStore, linkEthFeed)
  {
    /* empty */
  }

  function calculatePaymentAmountTest(
    uint256 gasAfterPaymentCalculation,
    uint32 fulfillmentFlatFeeLinkPPM,
    uint256 weiPerUnitGas
  ) external {
    s_paymentAmount = calculatePaymentAmount(
      gasleft(),
      gasAfterPaymentCalculation,
      fulfillmentFlatFeeLinkPPM,
      weiPerUnitGas
    );
  }

  function getPaymentAmount() public view returns (uint96) {
    return s_paymentAmount;
  }

  function getGasStart() public view returns (uint256) {
    return s_gasStart;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {VRFCoordinatorV2TestHelper as Helper} from "@chainlink/contracts/src/v0.8/tests/VRFCoordinatorV2TestHelper.sol";

contract VRFCoordinatorV2TestHelper is Helper {
    receive() external payable {}

    constructor(
        address link,
        address blockhashStore,
        address linkEthFeed
    ) Helper(link, blockhashStore, linkEthFeed) {}
}
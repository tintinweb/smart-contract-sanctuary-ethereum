/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.14;



library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}




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


interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}




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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract MarquisBanquet is Ownable, VRFConsumerBaseV2 {

    using SafeMath for uint256;

    struct KeyInfo {
        bool shuffle;
        uint256 ownerTokenId;
        uint256 changeBlockNumber;
        bytes32 ownerSignature;
    }

    struct Payment {
        bool approved;
        bool paid;
        uint256 amount;
        address to;
        uint256 expirationBlock;
    }

    uint256 private constant INVALID_TOKEN_ID = type(uint256).max;
    uint256 private constant ONE_HOUR_BLOCKS = 300; // ~ an hour

    bool public isRunning;
    uint256 public bountyBalance;
    uint256 private shuffleRequestId;
    uint256 private shuffleStartBlock;

    // Verified Random Function (VRFv2) variables
    bytes32 public keyHash;
    uint256 public subscriptionId;
    VRFCoordinatorV2Interface vrfCoordinatorIface;

    IERC721Enumerable mainContract;

    KeyInfo[4] private keys;

    // Bounty balance and reward variables
    uint256 cleanPaymentsIndex;
    uint256[] private allPaymentIds;
    mapping(address => uint256[]) private userPaymentIds;
    mapping(uint256 => Payment) private payments;

    event RewardPaid(address to, uint256 amount);

    modifier whenRunning() {
        require(isRunning, "not running");
        _;
    }

    modifier whenNotShuffling() {
        require(block.number.sub(shuffleStartBlock) > (ONE_HOUR_BLOCKS * 24), "shuffling");
        _;
    }

    constructor(address _vrfCoordinator, bytes32 _keyHash, uint256 _subscriptionId) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinatorIface = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;

        keys[0].ownerSignature = 0xf892afaa24442adb2ac89ab748bf4690e224a9f20c2a6ce10c067f8cabd8b5d2;
        keys[1].ownerSignature = 0xd6e7a87deffdf73e47a03e5ba13787cb7be05b8c772a6c0f13dade69ba7a6aa4;
        keys[2].ownerSignature = 0x9a2865ea99380dcd0f2d3f2905ecf562920f6b186ccae7187bd5dbd9d56b54c9;
        keys[3].ownerSignature = 0x116bcd8a7089a68db23d0bb8294ccaaf147e20b5b23547b9d7a9522727392476;

        // this is to avoid those cases where token 0 could appear as key-owner, when It is not.
        keys[0].ownerTokenId = INVALID_TOKEN_ID;
        keys[1].ownerTokenId = INVALID_TOKEN_ID;
        keys[2].ownerTokenId = INVALID_TOKEN_ID;
        keys[3].ownerTokenId = INVALID_TOKEN_ID;
    }
    
    /**
     * @dev This method will recieve all sent Eth
     */
    receive() external payable {
        bountyBalance += msg.value;
    }

    function setMainContract(address _mainContractAddress) public onlyOwner {
        mainContract = IERC721Enumerable(_mainContractAddress);
    }

    function start() public onlyOwner {
        require(address(mainContract) != address(0));

        keys[0].changeBlockNumber = block.number;
        keys[1].changeBlockNumber = block.number;
        keys[2].changeBlockNumber = block.number;
        keys[3].changeBlockNumber = block.number;

        isRunning = true;
    }

    function getOwnerSignature(uint256 keyId) public view returns(bytes32) {
        require(keyId < 4, "invalid keyId");
        return keys[keyId].ownerSignature;
    }

    function getKeyOwner(uint256 keyId) public view returns(uint256) {
        require(keyId < 4, "invalid keyId");
        return keys[keyId].ownerTokenId;
    }

    function getKeyInfo(uint256 keyId) public view returns (KeyInfo memory) {
        return keys[keyId];
    }

    /* 
     * 
     */
    function claimKey(uint256 keyId, uint256 tokenId, bytes32 secret) public whenNotShuffling {
        require(keys[keyId].ownerTokenId == INVALID_TOKEN_ID, "key already owned");
        require(mainContract.ownerOf(tokenId) == address(msg.sender), "not tokenId owner");

        bytes32 signture = keccak256(abi.encodePacked(tokenId, secret));
        require(signture == keys[keyId].ownerSignature, "wrong signatue");

        keys[keyId].changeBlockNumber = block.number;
        keys[keyId].ownerTokenId = tokenId;
    }

    function transferKey(uint256 keyId, uint256 toTokenId) public whenNotShuffling {
        require(keyId < 4, "invalid keyId");
        require(mainContract.ownerOf(keys[keyId].ownerTokenId) == address(msg.sender), "key owner error");
        require(mainContract.ownerOf(toTokenId) == address(msg.sender), "toTokenId error");
        require(block.number.sub(keys[keyId].changeBlockNumber) > ONE_HOUR_BLOCKS, "one transfer x hour");
        require(keys[keyId].ownerTokenId != toTokenId, "already own the key");

        keys[keyId].changeBlockNumber = block.number;
        keys[keyId].ownerTokenId = toTokenId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (requestId != shuffleRequestId)
            return;

        uint256 randomWord = randomWords[0];

        for(uint8 keyId = 0; keyId < 4; keyId++) {
            if (keys[keyId].shuffle) {
                keys[keyId].ownerTokenId = randomWord.mod(mainContract.totalSupply());
                randomWord = randomWord >> 16;
                keys[keyId].shuffle = false;
                keys[keyId].changeBlockNumber = block.number;
            }
        }

        payments[requestId].approved = true;
        shuffleStartBlock = 0;
    }

    function _requestShuffle(uint256 _amount, address _to) private {
        require(subscriptionId > 0, "VRF no set up");
        shuffleStartBlock = block.number;

        shuffleRequestId = vrfCoordinatorIface.requestRandomWords(
            keyHash,
            uint64(subscriptionId),
            3,
            200000,
            1
        );

        payments[shuffleRequestId] = Payment({
            approved: false,
            paid: false,
            amount: _amount,
            to: _to,
            expirationBlock: (block.number + (ONE_HOUR_BLOCKS * 24 * 7))
        });
        userPaymentIds[_to].push(shuffleRequestId);
        allPaymentIds.push(shuffleRequestId);
    }

    function shuffle() public whenRunning whenNotShuffling {
        uint128 keysToShuffle = 0;
        uint128 keyId = 0;
        uint256 _rewardAmount;

        for(; keyId < 4; keyId++) {
            keys[keyId].shuffle = (block.number.sub(keys[keyId].changeBlockNumber) > (ONE_HOUR_BLOCKS * 24 * 30));
            if (keys[keyId].shuffle)
                keysToShuffle += 1;
        }

        if (keysToShuffle == 0)
            revert("no keys to shuffle");

        _rewardAmount = bountyBalance.div(100).mul(keysToShuffle); // In this case, 1% of bounty per key, is paid as reward
        bountyBalance -= _rewardAmount;

        _requestShuffle(_rewardAmount, address(msg.sender));
    }

    function claimBounty() public whenRunning whenNotShuffling {
        require(bountyBalance > 0, "no balance to claim");

        uint256 _rewardAmount = bountyBalance;
        bountyBalance = 0;

        for(uint8 keyId = 0; keyId < 4; keyId++) {
            require(mainContract.ownerOf(keys[keyId].ownerTokenId) == address(msg.sender), "not key owner");
            keys[keyId].shuffle = true;
        }

        _requestShuffle(_rewardAmount, address(msg.sender));
    }

    function getUserPayments(address user) public view returns(uint256[] memory) {
        return userPaymentIds[user];
    }

    function getPaymentInfo(uint256 paymentId) public view returns (Payment memory) {
        return payments[paymentId];
    }

    function claimPayment(uint256 paymentId) public {
        require(payments[paymentId].approved && !payments[paymentId].paid, "not approved or already paid");
        require(payments[paymentId].to == address(msg.sender), "payment owner error");
        require(payments[paymentId].expirationBlock >= block.number, "expired payment");

        payments[paymentId].paid = true;

        (bool success, ) = payments[paymentId].to.call{value: payments[paymentId].amount}("");
        require(success, 'transaction error');
    }

    function cleanPayments() public {
        require(cleanPaymentsIndex < allPaymentIds.length);
        require(
            payments[allPaymentIds[cleanPaymentsIndex]].expirationBlock < block.number,
            "no expired payments"
        );

        for(; cleanPaymentsIndex < allPaymentIds.length; cleanPaymentsIndex++) {
            Payment memory _payment = payments[allPaymentIds[cleanPaymentsIndex]];

            if(_payment.paid == true) {
                continue;
            }

            // Is It not expired?
            if(_payment.expirationBlock >= block.number) {
                break;
            }

            // If we are here is because the payment was not paid and It is expired
            bountyBalance += _payment.amount;
        }
    }
}
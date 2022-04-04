// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "VRFConsumerBase.sol";
import "IERC20.sol";
import "Ownable.sol";

/// A `RaffleManager` is a smart contract that allows to create raffles
/// where participants can buy tickets and have their chances of winning
/// the total accumulated amount of the raffle.
/// This contract only allows managing one raffle at a time.
contract RaffleManager is VRFConsumerBase, Ownable {
    /// The amount of tokens that it costs to buy one ticket.
    /// The ERC20 token used to represent this price is specified by `tokenAddress`.
    /// This price works with the number of decimals specified by `tokenDecimals`.
    uint256 public ticketPrice;

    /// The minimum ticket number (e.g. 1)
    uint256 public ticketMinNumber;

    /// The maximum ticket number (e.g. 200)
    uint256 public ticketMaxNumber;

    /// The address of the ERC20 token contract which is used as currency for the raffle.
    address public tokenAddress;

    /// The number of decimals that the ERC20 token specified by `tokenAddress` works with.
    uint8 public tokenDecimals;

    /// The current state of the raffle.
    /// 0 = `closed` -> Default state. There are no ongoing raffles.
    /// 1 = `open` -> There is an ongoing raffle and users can buy tickets.
    /// 2 = `calculatingWinner` -> A raffle has recently finished and the contract is calculating a winner.
    enum RaffleState {
        closed,
        open,
        calculatingWinner
    }
    RaffleState public currentState = RaffleState.closed;

    /// An event that is triggered when this contract requests a random number from Chainlink's VRF.
    event RequestedRandomness(bytes32 requestId);

    /// The amount of LINK required as gas to get a random number from Chainlink's VRF, with 18 decimals.
    uint256 public vrfLinkFee;

    /// A value that identifies unequivocally the Chainlink's VRF node.
    bytes32 public vrfKeyHash;

    /// The last random number that was obtained from Chainlink's VRF.
    uint256 public lastRandomNumber;

    /// The last winner ticket number that was picked.
    uint256 public lastWinnerTicket;

    /// The address that bought the last winner ticket number.
    address public lastWinnerAddress;

    /// Keeps track of how many raffles have been played.
    uint256 rafflesCount;

    /// Maps each ticket number to the address that bought that ticket.
    mapping(uint256 => address) public ticketAddresses;

    /// The list of ticket numbers that have been sold.
    /// They are stored in the order that they were sold.
    uint256[] soldTickets;

    /// Maps addresses to the amount of tokens earned in prizes.
    /// The token is specified by `tokenAddress`.
    /// The number of decimals is specified by `tokenDecimals`.
    mapping(address => uint256) public addressToPrizeAmount;

    constructor(
        address _tokenAddress,
        uint8 _tokenDecimals,
        address _vrfCoordinator,
        uint256 _vrfLinkFee,
        bytes32 _vrfKeyHash,
        address _linkToken
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        tokenAddress = _tokenAddress;
        tokenDecimals = _tokenDecimals;
        vrfLinkFee = _vrfLinkFee;
        vrfKeyHash = _vrfKeyHash;
    }

    /// Buys one ticket for the caller, specified by `_ticketNumber`.
    function buyTicket(uint256 _ticketNumber) public {
        require(currentState == RaffleState.open, "Raffle has not started yet");
        require(
            _ticketNumber >= ticketMinNumber &&
                _ticketNumber <= ticketMaxNumber,
            "Invalid ticket number"
        );
        require(
            ticketAddresses[_ticketNumber] == address(0),
            "Ticket number not available"
        );
        require(
            IERC20(tokenAddress).balanceOf(msg.sender) >= ticketPrice,
            "This address doesn't have enough balance to buy a ticket"
        );
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            ticketPrice
        );
        ticketAddresses[_ticketNumber] = msg.sender;
        soldTickets.push(_ticketNumber);
    }

    /// Returns the current prize for the ongoing raffle.
    /// The prize is calculated by summing the value of all the tickets
    /// that have been sold.
    /// Amount returned is represented in the token specified by `tokenAddress`,
    /// with the number of decimals specified by `tokenDecimals`.
    function getCurrentPrizeAmount() public view returns (uint256) {
        return soldTickets.length * ticketPrice;
    }

    /// Claims the amount won by the caller in closed raffles.
    /// If the caller has won raffles, the total amount won
    /// will get transferred to their address.
    function redeemPrize() public {
        require(
            addressToPrizeAmount[msg.sender] > 0,
            "There is no prize for this address"
        );
        IERC20(tokenAddress).transfer(
            msg.sender,
            addressToPrizeAmount[msg.sender]
        );
    }

    /// Opens a new raffle so participants can start buying tickets.
    function openRaffle(
        uint256 _ticketPrice,
        uint256 _ticketMinNumber,
        uint256 _ticketMaxNumber
    ) public onlyOwner {
        require(
            currentState == RaffleState.closed,
            "There is raffle in progress already. Can't open a new raffle"
        );
        require(_ticketMinNumber >= 0, "_ticketMinNumber cannot be negative");
        require(
            _ticketMinNumber <= _ticketMaxNumber,
            "_ticketMaxNumber must be greater than _ticketMinNumber"
        );
        require(
            _ticketMaxNumber <= type(uint256).max,
            "_ticketMaxNumber is too high"
        );
        require(_ticketPrice > 0, "_ticketPrice cannot be negative");
        require(_ticketPrice <= type(uint256).max, "_ticketPrice is too high");
        ticketPrice = _ticketPrice;
        ticketMinNumber = _ticketMinNumber;
        ticketMaxNumber = _ticketMaxNumber;
        currentState = RaffleState.open;
    }

    /// Closes the current raffle and starts calculating the winner ticket.
    /// Once calculated, the winner ticket will be stored in `_lastWinnerTicket`.
    /// At that point, the address who bought that ticket can claim the funds
    /// of that raffle using the function `redeemPrize`.
    function closeRaffle() public onlyOwner {
        require(
            currentState == RaffleState.open,
            "There isn't any ongoing raffle to close"
        );
        currentState = RaffleState.calculatingWinner;
        startCalculatingWinner();
    }

    /// Starts calculating the winner ticket.
    function startCalculatingWinner() private returns (uint256) {
        // We'll connect to the Chainlink VRF Node
        // using the "Request and Receive" cycle model

        // R&R -> 2 transactions:
        // 1) Request the data from the Chainlink Oracle through a function (requestRandomness)
        // 2) Callback transaction -> Chainlink node returns data to the contract into another function (fulfillRandomness)

        // requestRandomness function is provided by VRFConsumerBase parent class
        bytes32 requestId = requestRandomness(vrfKeyHash, vrfLinkFee);

        // We emit the following event to be able to retrieve the requestId in the tests.
        // Also, events work as logs for the contract.
        emit RequestedRandomness(requestId);
    }

    // We need to override fulfillRandomness from VRFConsumerBase in order to retrieve the random number.
    // This function will be called for us by the VRFCoordinator (that's why it's internal).
    // This function works asynchronously.
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            currentState == RaffleState.calculatingWinner,
            "Raffle is not calculating winners yet"
        );
        require(_randomness > 0, "Random number not found");

        lastRandomNumber = _randomness;

        uint256 winnerTicketIndex = _randomness % soldTickets.length;
        uint256 winnerTicketNumber = soldTickets[winnerTicketIndex];
        lastWinnerTicket = winnerTicketNumber;

        address winnerAddress = ticketAddresses[winnerTicketNumber];
        lastWinnerAddress = winnerAddress;
        require(winnerAddress != address(0), "Cannot find a winner");

        addressToPrizeAmount[winnerAddress] += getCurrentPrizeAmount(); // test +=

        resetRaffle();
    }

    /// Resets state. Private usage only.
    function resetRaffle() private {
        resetTicketAddressesMapping();
        soldTickets = new uint256[](0);
        currentState = RaffleState.closed;
        rafflesCount += 1;
    }

    function resetTicketAddressesMapping() private {
        for (
            uint256 number = ticketMinNumber;
            number <= ticketMaxNumber;
            number++
        ) {
            ticketAddresses[number] = address(0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "LinkTokenInterface.sol";

import "VRFRequestIDBase.sol";

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
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

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
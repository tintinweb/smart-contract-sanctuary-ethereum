// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/VRFV2WrapperInterface.sol";

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
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

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import 'lib/chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol';

contract Roulette is VRFV2WrapperConsumerBase {
    event GameRequest(uint256 gameId);
    event GameResult(uint256 gameId, uint8 result);

    error Unauthorized();
    error InsufficientChainlinkTokens();
    error InvalidGuess();
    error InvalidStakeAmount();
    error InvalidClaim();
    error Locked();

    struct Bet {
        address player;
        uint256 stake;
        uint8 guess;
        uint8 multiplier;
        bool canClaim;
        bool claimed;
    }

    address private constant CHAIN_LINK_CONTRACT = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address private constant VRF_WRAPPER = 0x708701a1DfF4f478de54383E49a627eD4852C816;

    uint256 private constant MINIMUM_LINK = 10e18; // 10 LINK
    uint256 public constant MINIMUM_STAKE = 0.001 ether;
    uint256 public constant MAXIMUM_STAKE = 0.003 ether;

    uint8 private constant RED = 37;
    uint8 private constant BLACK = 38;
    uint8 private constant COLOR_PAYOUT_MULTIPLIER = 2;
    uint8 private constant NUMBER_PAYOUT_MULTIPLIER = 36;

    uint32 private constant CALLBACK_GAS_LIMIT = 100000;
    uint16 private constant REQUEST_CONFIRMATIONS = 2;
    uint32 private constant NUMBER_OF_WORDS = 5;

    address payable private owner;
    bool private lock;

    // gameId => Bet
    mapping(uint256 => Bet) private bets;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    modifier locked() {
        if (lock) {
            revert Locked();
        }
        lock = true;
        _;
        lock = false;
    }

    constructor() payable VRFV2WrapperConsumerBase(CHAIN_LINK_CONTRACT, VRF_WRAPPER) {
        owner = payable(msg.sender);
    }

    /* ---------- EXTERNAL ----------  */

    /**
     * @notice Withdraw contract funds. AKA: RUG
     */
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Withdraw failed');
    }

    /**
     * @notice Create a new game.
     *
     * @param guess uint8 the player guess
     * @return uint256 The game ID
     */
    function newGame(uint8 guess) external payable returns (uint256) {
        _assertItHasLinkTokens();
        _assertIsValidGuess(guess);
        _assertIsValidStake();

        uint256 gameId = requestRandomness(CALLBACK_GAS_LIMIT, REQUEST_CONFIRMATIONS, NUMBER_OF_WORDS);

        Bet memory bet = bets[gameId];
        bet.player = msg.sender;
        bet.guess = guess;
        bet.stake = msg.value;
        bets[gameId] = bet;

        emit GameRequest(gameId);

        return gameId;
    }

    /**
     * @notice Perform winner assessment and update accordingly.
     * @dev Chainlink's VRF wrapper callback function.
     *
     * @param gameId uint256 ID of the request.
     * @param randomWords uint256[] Array of randomly generated words.
     */
    function fulfillRandomWords(uint256 gameId, uint256[] memory randomWords) internal override {
        uint8 random = _getRandom(randomWords[0]);
        Bet memory bet = bets[gameId];

        (bool isWinner, uint8 possiblePayoutMultiplier) = _IsWinner(bet.guess, random);
        bet.canClaim = isWinner;
        bet.multiplier = possiblePayoutMultiplier;

        bets[gameId] = bet;

        emit GameResult(gameId, random);
    }

    /**
     * @notice Send prize funds to winner.
     *
     * @param gameId uint256 ID of the roulette game.
     */
    function claimPrize(uint256 gameId) external locked {
        Bet memory bet = bets[gameId];
        _assertItCanClaim(bet);

        bet.claimed = true;
        bets[gameId] = bet;

        (bool success, ) = payable(msg.sender).call{value: _calculatePayout(bet.stake, bet.multiplier)}('');
        require(success, 'Prize payout failed');
    }

    /* ---------- PUBLIC ---------- */

    /**
     * @notice Assert if a guess is the correct guess
     *
     * @param guess uint8 the player guess
     * @param gameResult uint8 the game generated random number
     * @return (bool, uint8) wether a given guess is correct and its possible payout
     */
    function _IsWinner(uint8 guess, uint8 gameResult) public pure returns (bool, uint8) {
        if (guess >= 0 && guess <= 36) {
            return (guess == gameResult, NUMBER_PAYOUT_MULTIPLIER);
        }

        return (
            gameResult != 0 && (guess == BLACK ? gameResult % 2 == 0 : gameResult % 2 == 1),
            COLOR_PAYOUT_MULTIPLIER
        );
    }

    /**
     * @notice Generate a random number from a VRF in the range 0 - 36
     *
     * @param random uint256 the VRF
     * @return uint8 the random in range
     */
    function _getRandom(uint256 random) public pure returns (uint8) {
        return uint8((random % 37));
    }

    /**
     * @notice Calculate a given payout to a successful guess
     *
     * @param stake uint256 stake amount on bet
     * @param multiplier uint8 stake multiplier
     * @return uint256 the payout amount
     */
    function _calculatePayout(uint256 stake, uint8 multiplier) public pure returns (uint256) {
        return stake * multiplier;
    }

    /* ---------- PRIVATE ---------- */

    /**
     * @notice Retrieve this contract's LINK balance
     *
     * @return uint256 this contract LINK token balance
     */
    function _getLinkTokenBalance() private returns (uint256) {
        (bool success, bytes memory result) = CHAIN_LINK_CONTRACT.call(
            abi.encodeWithSignature('balanceOf(address)', address(this))
        );
        require(success, 'Low level call failed');

        return abi.decode(result, (uint256));
    }

    /**
     * @notice Assert that this contract has sufficient LINK tokens
     * @dev Throws unless this contract LINK token balance is greater than or equal to `MINIMUM_LINK`
     */
    function _assertItHasLinkTokens() private {
        if (_getLinkTokenBalance() >= MINIMUM_LINK) {
            return;
        }

        revert InsufficientChainlinkTokens();
    }

    /**
     * @notice Assert that player guess is valid
     * @dev Throws unless the guess of the player is less than or equal to 38
     *
     * @param guess uint8 the guess of the player
     */
    function _assertIsValidGuess(uint8 guess) private pure {
        if (guess <= 38) {
            return;
        }

        revert InvalidGuess();
    }

    /**
     * @notice Assert that player stake is valid
     * @dev Throws unless player stake is in range between `MINIMUM_STAKE` and `MAXIMUM_STAKE`
     */
    function _assertIsValidStake() private {
        if (msg.value >= MINIMUM_STAKE && msg.value <= MAXIMUM_STAKE) {
            return;
        }

        revert InvalidStakeAmount();
    }

    /**
     * @notice Assert that player can claim prize
     * @dev Throws unless `msg.sender` is the bet player, won the prize and did not claimed yet
     *
     * @param bet Bet the bet data structure
     */
    function _assertItCanClaim(Bet memory bet) private view {
        if (bet.player == msg.sender && bet.canClaim && !bet.claimed) {
            return;
        }

        revert InvalidClaim();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract Roulette is VRFV2WrapperConsumerBase {
    uint256 constant MAX_AMOUNT_ALLOWED_IN_THE_BANK = 2 ether;
    uint128 constant ENTRY_FEES = 0.001 ether;
    uint32 constant CALLBACK_GAS_LIMIT = 1000000;
    uint8 constant NUM_WORDS = 1;
    uint8 constant REQUEST_CONFIRMATIONS = 3;
    address constant LINK_ADDRESS = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant VRF_WRAPPER_ADDRESS = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;
    address immutable owner;
    uint8[] numberRange;
    uint8[] payouts;
    

    // BetTypes:
    //   0: color
    //   1: column
    //   2: dozen
    //   3: eighteen
    //   4: even/odd
    //   5: number

    // BetType - value:
    //   color: 0 for black, 1 for red
    //   column: 0 for left, 1 for middle, 2 for right
    //   dozen: 0 for first, 1 for second, 2 for third
    //   eighteen: 0 for low, 1 for high
    //   even/odd: 0 for even, 1 for odd
    //   number: number

    struct BetStatus {
        uint8 betType;
        uint8 number;
        uint256 fees;
        uint256 randomWord;
        address player;
        bool didWin;
        bool fulfilled;
    }

    mapping(uint256 => BetStatus) public statuses;
    mapping(address => uint256) private winnings;

    event SpinResult(uint256 requestId, bool didWin);
    event RandomNumber(uint256 number);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    constructor() payable VRFV2WrapperConsumerBase(LINK_ADDRESS, VRF_WRAPPER_ADDRESS){
        owner = msg.sender;
        payouts = [2, 3, 3, 2, 2, 36];
        numberRange = [1, 2, 2, 1, 1, 36];
    }

    function bet(
        uint8 _number,
        uint8 _betType
    ) external payable returns (uint256) {
        require(msg.value == ENTRY_FEES , "Entry fees not sent");
        require(_betType <= 5, "Incorrect bet type");
        require(_number <= numberRange[_betType], "Incorrect value");

        uint256 requestId = requestRandomness(
            CALLBACK_GAS_LIMIT ,
            REQUEST_CONFIRMATIONS,
            NUM_WORDS
        );

        statuses[requestId] = BetStatus({
            number: _number,
            betType: _betType,
            fees: VRF_V2_WRAPPER.calculateRequestPrice(CALLBACK_GAS_LIMIT),
            randomWord: 0,
            player: msg.sender,
            didWin: false,
            fulfilled: false
        });

        return requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(statuses[requestId].fees > 0, "Request not found");

        statuses[requestId].fulfilled = true;
        statuses[requestId].randomWord = randomWords[0];
        uint8 number = uint8(randomWords[0] % 37);

        bool won = false;
        if (number == 0) {
            /* bet on 0 */
            won = (statuses[requestId].betType == 5 &&
                statuses[requestId].number == 0);
        } else {
            if (statuses[requestId].betType == 5) {
                /* bet on number */
                won = (statuses[requestId].number == number);
            } else if (statuses[requestId].betType == 4) {
                if (statuses[requestId].number == 0)
                    /* bet on even */
                    won = (number % 2 == 0);
                if (statuses[requestId].number == 1)
                    /* bet on odd */
                    won = (number % 2 == 1);
            } else if (statuses[requestId].betType == 3) {
                if (statuses[requestId].number == 0)
                    /* bet on low 18s */
                    won = (number <= 18);
                if (statuses[requestId].number == 1)
                    /* bet on high 18s */
                    won = (number >= 19);
            } else if (statuses[requestId].betType == 2) {
                if (statuses[requestId].number == 0)
                    /* bet on 1st dozen */
                    won = (number <= 12);
                if (statuses[requestId].number == 1)
                    /* bet on 2nd dozen */
                    won = (number > 12 && number <= 24);
                if (statuses[requestId].number == 2)
                    /* bet on 3rd dozen */
                    won = (number > 24);
            } else if (statuses[requestId].betType == 1) {
                if (statuses[requestId].number == 0)
                    /* bet on left column */
                    won = (number % 3 == 1);
                if (statuses[requestId].number == 1)
                    /* bet on middle column */
                    won = (number % 3 == 2);
                if (statuses[requestId].number == 2)
                    /* bet on right column */
                    won = (number % 3 == 0);
            } else if (statuses[requestId].betType == 0) {
                if (statuses[requestId].number == 0) {
                    /* bet on black */
                    if (number <= 10 || (number >= 20 && number <= 28)) {
                        won = (number % 2 == 0);
                    } else {
                        won = (number % 2 == 1);
                    }
                } else {
                    /* bet on red */
                    if (number <= 10 || (number >= 20 && number <= 28)) {
                        won = (number % 2 == 1);
                    } else {
                        won = (number % 2 == 0);
                    }
                }
            }
        }

        if (won) {
            statuses[requestId].didWin = true;
            winnings[statuses[requestId].player] += ENTRY_FEES * payouts[statuses[requestId].betType];
        }

        emit SpinResult(requestId, statuses[requestId].didWin);
        emit RandomNumber(number);
    }

    function cashOut() external {
        uint256 amount = winnings[msg.sender];
        require(amount > 0, "You have no winnings");
        require(amount <= address(this).balance, "Contract balance don't have enough money. Try again later.");
        winnings[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function safeWithdraw() external onlyOwner {
        require(
            address(this).balance > MAX_AMOUNT_ALLOWED_IN_THE_BANK,
            "Not enough money to save withdraw"
        );

        uint amount = address(this).balance - MAX_AMOUNT_ALLOWED_IN_THE_BANK;
        if (amount > 0) payable(owner).transfer(amount);
    }
    function allWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function getBalances() public view returns (uint, uint) {
        return (address(this).balance, winnings[msg.sender]);
    }
    
    receive() external payable{}
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
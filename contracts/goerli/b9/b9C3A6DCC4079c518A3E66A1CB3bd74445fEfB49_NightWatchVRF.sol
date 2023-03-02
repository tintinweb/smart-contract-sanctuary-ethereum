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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {VRFV2WrapperConsumerBase, LinkTokenInterface} from "chainlink/v0.8/VRFV2WrapperConsumerBase.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {IRandomSeedGenerator} from "./interfaces/IRandomSeedGenerator.sol";

/// @title Random Number Generator for Night Watch project
/// @notice This contract is to ensure distribution is random with Chainlink VRF.
/// @author Yigit Duman <[email protected]>
/// @author Chainlink Team
contract NightWatchVRF is
    VRFV2WrapperConsumerBase,
    Owned,
    IRandomSeedGenerator
{
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Request {
        uint8 state; // 0: not exist 1: requested 2: fulfilled
        uint256[] randomSeeds;
    }

    struct Config {
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        address linkAddress;
        address wrapperAddress;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RequestSent(uint256 requestId, uint32 count);
    event RequestFulfilled(uint256 requestId, uint256[] randomSeeds);

    /*//////////////////////////////////////////////////////////////
                                ERRRORS
    //////////////////////////////////////////////////////////////*/

    error RequestNotFound();
    error RandomnessNeverFulfilled();
    error LinkTransferFailed();

    /*//////////////////////////////////////////////////////////////
                                REQUESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Request ID to Request mapping
    mapping(uint256 => Request) private _requests;

    /// @notice Last request ID
    uint256 public lastRequestId;

    /*//////////////////////////////////////////////////////////////
                                 CONFIG
    //////////////////////////////////////////////////////////////*/

    /// @notice Chainlink configuration
    Config private _config;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the config
    /// @param callbackGasLimit Gas limit for callback
    /// @param requestConfirmations Number of confirmations for request
    /// @param linkAddress Chainlink LINK token address
    /// @param wrapperAddress Chainlink VRF wrapper address
    constructor(
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        address linkAddress,
        address wrapperAddress
    ) VRFV2WrapperConsumerBase(linkAddress, wrapperAddress) Owned(msg.sender) {
        _config = Config({
            callbackGasLimit: callbackGasLimit,
            requestConfirmations: requestConfirmations,
            linkAddress: linkAddress,
            wrapperAddress: wrapperAddress
        });
    }

    /// @notice Set the config
    /// @param callbackGasLimit Gas limit for callback
    /// @param requestConfirmations Number of confirmations for request
    function setConfig(uint32 callbackGasLimit, uint16 requestConfirmations)
        external
        onlyOwner
    {
        _config.callbackGasLimit = callbackGasLimit;
        _config.requestConfirmations = requestConfirmations;
    }

    /// @notice Request random seeds from Chainlink VRF
    /// @param count Number of random seeds to request
    /// @return requestId Request ID
    function requestRandomSeeds(uint32 count)
        external
        onlyOwner
        returns (uint256 requestId)
    {
        // Request randomness and set the request id
        requestId = requestRandomness(
            _config.callbackGasLimit,
            _config.requestConfirmations,
            count
        );

        // Set the request
        _requests[requestId] = Request({
            randomSeeds: new uint256[](0),
            state: 1
        });

        // Set the last request id
        lastRequestId = requestId;

        // Emit RequestSent event
        emit RequestSent(requestId, count);
    }

    /// @notice Get the latest random seed
    function getLatestSeed() external view returns (uint256) {
        // Check if any request is fulfilled
        if (_requests[lastRequestId].state != 2) {
            revert RandomnessNeverFulfilled();
        }

        // Return the latest random seed
        return _requests[lastRequestId].randomSeeds[0];
    }

    /// @notice Withdraw LINK tokens from the contract
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(_config.linkAddress);
        if (!link.transfer(msg.sender, link.balanceOf(address(this)))) {
            revert LinkTransferFailed();
        }
    }

    /// @notice Override of fulfillRandomWords function
    /// @param requestId Request ID
    /// @param randomSeeds Random seeds
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomSeeds)
        internal
        override
    {
        // Check if the request exists
        if (_requests[requestId].state == 0) {
            revert RequestNotFound();
        }

        // Set the request data
        _requests[requestId].randomSeeds = randomSeeds;
        _requests[requestId].state = 2;

        // Emit RequestFulfilled event
        emit RequestFulfilled(requestId, randomSeeds);
    }

    /// @notice Get the request status by request ID
    /// @param requestId Request ID
    function getRequestStatus(uint256 requestId)
        external
        view
        returns (uint8, uint256[] memory)
    {
        return (_requests[requestId].state, _requests[requestId].randomSeeds);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Random seed generator contract interface of Night Watch
/// @author Yigit Duman <[email protected]>
interface IRandomSeedGenerator {
    function getLatestSeed() external view returns (uint256);
}
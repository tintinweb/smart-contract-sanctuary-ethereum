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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IUSDT {
    function approve(address _spender, uint256 _value) external;

    function balanceOf(address who) external view returns (uint256);
    
    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address _owner, address _spender)
        external
        returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./IUSDT.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract RandomNumberGenerator is VRFV2WrapperConsumerBase {

    event RandomNumberRequest(uint256 requestId);
    IUSDT public linkToken;
    address admin;
    address internal linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address internal VRFWrapper = 0x708701a1DfF4f478de54383E49a627eD4852C816;
    bytes32 internal keyHash;
    uint32 internal fee = 1000000;
    uint32 internal numWords = 1;
    uint16 internal requestConfirmations = 3;
    uint256 internal RoundDown = 1e76;
    uint256 internal myRequestId;
    mapping (uint256 => uint256) internal requestIdToFee;
    mapping (uint256 => uint256) internal requestIdToRandomWord;
    mapping (uint256 => bool) internal requestIdToStatus;
    mapping (address => uint256) internal addressToId;

    constructor () VRFV2WrapperConsumerBase(linkAddress, VRFWrapper){
        linkToken = IUSDT(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        admin = msg.sender;
    }

    function getRandomNumber() public returns ( uint256) {
        uint256 requestId = requestRandomness(fee, requestConfirmations, numWords);
        requestIdToFee[requestId] = VRF_V2_WRAPPER.calculateRequestPrice(fee);
        addressToId[msg.sender] = requestId;
        myRequestId = requestId;
        emit RandomNumberRequest(requestId);
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(requestIdToFee[requestId] > 0, "Request not found");
        requestIdToRandomWord[requestId] = randomWords[0];
        requestIdToStatus[requestId] = true;
    }

    function getStatus(uint256 requestId) public view returns(bool){
        return requestIdToStatus[requestId];
    }

    function displayGeneratedRandomWord(uint256 requestId) public view returns(uint256) {
        require(requestIdToFee[requestId] > 0, "Invalid Request ID");
        require(requestIdToStatus[requestId] == true, "Random Number Not gotten YET");
        uint256 result = requestIdToRandomWord[requestId];
        return (result/RoundDown);
        
    }

    function contractBalance() public view returns(uint256){
        return linkToken.balanceOf(address(this));
    }

    function getMyRequestID() public view returns(uint256){
        return addressToId[msg.sender];
    }

    function getLastId() public view returns(uint256){
        return myRequestId;
    }


    function WithdrawLink(uint256 _amount) public {
        require(msg.sender == admin, "Not Admin");
       linkToken.transfer(msg.sender, _amount);
    }

}
   //  keyHash = 0x0476f9a745b61ea5c0ab224d3a6e4c99f0b02fce4da01143a4f70aa80ae76e8a;
       // fee = 0.1 * 10 ** 18;
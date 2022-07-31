/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

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


pragma solidity ^0.8.7;


/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract VRFv2Consumer is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  event recived(uint256 transId);

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  1;

  uint256[] public s_randomWords;
  uint256 public randomN;
  uint256 public s_requestId;
  address s_owner;

  address[] public wallets;

  IERC20 token;

  constructor(uint64 subscriptionId, address token_) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    token = IERC20(token_);
    wallets = [0x0131E7264dAC3789758C440101478A4952770B4F,0x02282AC5B658E08B3267B9E67C322eC983EdB124,0x036a9D919B0670774080B8f84c751A1a29825C36,0x06ea0c9042F29b21DF0EEA74c0043E51332f8Be0,0x0906971E83a2E6595C663A9f1440d28fF1bB80B5,0x0cB6eC1b2FAfD7c3479b3D6141b16981eEe8Cdec,0x0CDbbE3dF28aB1298b8EF4512e857637bcd332F4,0x0eca2924F64d72dB50E625b4d9E158E411CDa148,0x0ef35C01aA6F8c10D638f95f644a37cB06fd2F3c,0x0fC0b924E6bb63582e6bA8F1377bDd865BE46747,0x10142804A82CC1d1059BD80e3590f82F1a64A363,0x115fFA57cc2642593906c5ba8e51A444aF7c4392,0x14EEb690eBDC59a6B1F88442d0cC8bE4e208D301,0x18c1722aD043DbE6597173bCAeC1Cd52cb0E80C0,0x19399e64614d65544c198ef42BDC317C96A07Df4,0x1a70baD3f9e3d9DFACBC23E27b4B46f1dDB0B678,0x1c775FBA74a38D425E604837A59Eddb6737B3934,0x23fb96af0D98458A7ae342d7E4b09cAED4fdfC39,0x2627d8F44F3b13ed851551D88D13B4755c8EbC63,0x267f95C0ff0f3e9c7EC13d04bEaB4842a624376A,0x274339102eFb91b106BCF347876095D8cd951645,0x284A09600840e1F40a86D8a077784CC0fd8a1dBc,0x2a041ff60534D09F25735Bcb85B1cF4F6013ef24,0x2B27115d54230E3BF4494F34754608d1F86f6D55,0x2bC270ad87CE4877cDdA7DB6d2D1E062bC2058E0,0x2dfb48b7D7b191A9eE29c6fF45E32B1962EdDDeE,0x30E66d933961C5f703F63D747e1A95724645FF30,0x3649F75DF4DE348210Af6c7fe410a40bcdd2bA70,0x3786734516d6b6fB9f872Bf5cD7362084930F4FB,0x37aA63f6951284C62Ff62543EF2E5c709E0E7d9d,0x380D340237a02B59A279204C04090643220ee483,0x387B2b95604dbA8aE11950b0FBf392aD00828d9f,0x3Af1320a36203fd8EA045B7f24D5d97b3DA75A6a,0x3B65944248Ea492168EA061c72833FFA754df4cA,0x3c82cf0238f3b5CBf0d8aC644e9Da635c7e78041,0x3C931Ee85A45Ea14bEE716365fe059f0548b2F24,0x3F258B692FDE5Fe42Fcb3Eb9deD50DaD22E2039a,0x42cce1CC483B68Ce2b9E9c0F8AE1dDE7d7CDB098,0x42D1361F59862870859EBd7BFFB1D9D55ceFce31,0x43fbD25E3E63D9d65Ca86c9463dA54B87b682413,0x480Ee476bDCd59F5B255fFE10f81759b49586294,0x488019aF5Fe47552bD6733D7EAe8222E16345D52,0x49aeB7CBA6bBCF2A9cdF43d9984f746BB1a50E0a,0x4AE8eD2068CCFC90CEb82Bf1D4df7F1c034c59E8,0x4cAdBecaA4fef4728f988fA45c80F4E655f2DF73,0x4cc553577f0ED81E203D6b72f5364B7CC96649Fd,0x4d506aB24Ba9A22f9CDF1F07FdcDCF23b9616067,0x4F398881a9042b034Af89DCceb373B60158bf911,0x51048Cf415a998928D60F5e459361ed73a8f673F,0x56E3F0dABbEdaFcad2baA5cE2409282594B06091,0x59f7e526f5b42A91481cC8405f39031123b1bBEA,0x5B467956B452CFC7086825e3b2c404630d04a150,0x5dF944d0b1a981BbfD476092225E4CCB7E19244f,0x604C7A6B1312F8f213399c998c1a256CeCb4c48F,0x6419d0F54BdE63E7351DB7622bE2528B0139510c,0x64a12E36F1e1f8A4B938C430FF9ba31061e3bB29,0x65EA3b960B802744872b8560D25BfB54eC6c4e51,0x67699De717759Ba942428Bd8c98d4e53E33cb4EB,0x6BDf95755fdc3C272Ae6b4b928c6312604F6f5c8,0x6fe0A90596a41EB15Bd616EdDCa51BFB3Db40cBF,0x7023A2358f5Ab1FFC44043E1c4D2A55d4C1cB7A2,0x72dDC71B6e5D2eDe4252eeCef28e376276e8D514,0x743a44555175700ff2E8dc9eC895db23218dDD18,0x75a440407495119842dfFDdeB1d55D49c9Ca18f3,0x778421D25BD21A7147Df71f159682B67Ba9be902,0x79C11eF65cffc35D7FC9c97F50A07DEe21048cda,0x7D7E285821Afac8985873E35b798D9e13B70FF7F,0x7Dd616F85F66535BaBe9e545B5A892600F002803,0x7dE956bd86FA815db86de40b72CDdb20d2174392,0x7e417854696996677ac4169a66743C004Bf9c4a2,0x7F6A392c1FF9447CDe03C976F8eBecBC8E78940F,0x82da2B0bAffDAF967Ad91b6a388B646ff40126C9,0x82da2B0bAffDAF967Ad91b6a388B646ff40126C9,0x873766eaEe715B6AD8cD42f50757b3D83fB94079,0x87e32695CA9cd7075B146973Df34df5476e99350,0x8841264C5F435d667f1950ED954E6095AEef53e9,0x88c70670f8eCDE0d2eD4B3e8A989daDC8d4CE990,0x8A2FBDD2cC26444cF195f4Dd7573C926776F5e7E,0x8A5cBfe826b69e55585cdE0d5D36a0a2e6905a09,0x8B86b12EEd4BF6f724FaEF38657D2CeD96a64065,0x8D6267eaa71e9059D0607D758B2C71c9D7cd905E,0x8DD5cB2E81037C7aC21155484cd24693840d0c37,0x8E0C3d4F6288138d60e36Cc886Dfbb4853B365C5,0x96577ea245C828153E40e5aC9098c98379BA2b57,0x96d13Afc7B2fdd7E0C7A6d9D2867aa76165CdCc0,0x97439CC91Ff9C695206b3c5591476ccdAe644535,0x97543FBD2803a1e90817806235E744dA02699432,0x9bBf94c6f929e49b5FB7226D34b82dc354461F24,0x9C4D6B6F4717EedFe0Df66c332F7bD8afa13B263,0xA0dEeEfb5f83FFBFBaEDE76DB935c80CDA6fE8f8,0xA498a11daa9A80f8BEB588995Ae549F2a889Fc5D,0xa4ac8dd51117808D1511fDcdBFd8262038d91a35,0xa6C4A00c76628Bf847bFdDfE9F7BA5b31fDB1a66,0xA77F76236e9BA7C84beC37832b60c4DE49F6121D,0xa9B30D66AC11F6f1E19cEe2A3D8cDe68D4157386,0xaa73A302eD71c5c7F061E1e5bbBC7b73bE96ecD9,0xaAeb105E609fc8eECb99AcfcF78921870E2321cE,0xAb12189A83Cb97d27669e830519C5854835fC3c2,0xAB12E481E392294a5853c0EA2a48ADb7da2A50c8,0xac7dDcd36FAdFFC392E1b5736a760Fbdb3FDA66C,0xaF1e0D9BEc11Ed3053e12862Cf744967f8E14890,0xb0c509c016a911DB269a9c5C273b1D46a735e4e7,0xb2087C389a721F180bd7488BF397b555C16F9e3C,0xb527eb25c065e68C811a53722a5659214d9A4683,0xb86C4874d2339116Bc5e559c6eC52AEe04a2c036,0xBa0D8e11a03FABC7a6FcEAC0FE6C39c8F079d3C8,0xBCaFff25B7e604CD69bf0289c6B1940D138F3CD4,0xbD593edc060d114d40054e00137DC763C413C5a8,0xbEd561B5a3f02cD08431d6E1fC7Cb5a23e97a2ce,0xbEEabcb3CD655d714372214611bb224624a2588B,0xBF66B4bEfd7747db34a49A32bEDfB20A2152Dd1e,0xBf7AD368842388DeE9C7b74B93c0332311c7FBED,0xbfE9fF199CF1DB378F73EBcF79B6A7A593b3247D,0xc13eA83dC63b77B3509d9e1675d553A2a2ae51a9,0xC17A54b5A8625232006eAF8Ae0C167f0482B6B2e,0xC1B992D52648E205C9ee151C87bA05721B5009DB,0xC23c28777074Ea198142b5d9Fa55c89b531B320c,0xC40B58b7F715d949777C03DafccC54C0d11E38d0,0xC4A1E5edAe83f06E8a6B2588fc60317cc3957523,0xc57064E66cd115406bF7c661074cE703Fc0051Fb,0xC6Bc02e33794cD39ABc5Bb40c1a116AF0ad8a1c9,0xc79a231D0858bd72ECd3108810bda3B4cD3d5BbE,0xcA0eA273053dEF83e8872034f4889731EaA4676D,0xcAdE70F601aF4781C19957090CA460B37f136238,0xCD4864BfC64c4Ea7e55a09d9BC12d20389f23393,0xCDd092e3575D0Dc73EE165dfC06f14f4F055E18D,0xD0206d715aF981A977DE5e48C2d659052C2856A8,0xD036c6D08c32bB333C843a0bB8e85fAbEA7Da83E,0xd282ccb2186465c0EF7C2f6F40062af0b2155e8E,0xD2833571139B9Fd877Bc6994D4bA14335830fAd6,0xd62f81d0232c1B1e7e9C19d7AD76E14e4FA18f29,0xd6928dC64bcF2B5ceA5a67b820961D07381EF75f,0xd7838A508f2aA326C8Bd054fFAacC251c6373432,0xD885D7a02D98853E8D081391fbA4aeB4CFf15F6a,0xd99e59a6FA7db22dA7AA41B3B9c4F63646DB8679,0xdB303ADdc832591bdd19CcF35b6480e6C1561Fec,0xdCCc7729EeaC969B1A898029EAca3b3173F4b53a,0xdd64B3ad2Ef7bc1D49c2813482b343EDf0EA10F5,0xdD8210372f5eF07390E2d28e829F2d49F34663cc,0xE27f98E6742d900d002aAfAC54c668927da14230,0xe2f3FbB69C2A63bD7EC4C1260f59D459aC18534a,0xE339b2735d9Eedf87a2b821Ced46720a3C7A6d85,0xE37E23723A01D23Eff21304bCEeC51de9acee744,0xe37f2B3f585740A5c524b3bbDc9f3232A8E5c058,0xe4077d2E4894464199a6f5fefA260f80e14873DE,0xE4a71858eE7b0859060B813bd7e1D0Be732458e7,0xe65223f0b02f79C1f1d7560D41e61a7b82Ae2634,0xf009dA01a5c9d437Ea96d3C807b06cEC14Ae0013,0xF01FbC3A0D35856acEE3bc2D8a1F48aEe83d9d12,0xf39bBf9EE40A382a69DDe44Fac1E1F7e76392d8b,0xf594bD0a5484faa6a28D63Ef7AeB29189473587B,0xf973aC580EEB14834743569743D20eBd388F9EEf,0xF9A279cA83D8797277472C5fC1552d9c2e8F9893,0xFB9391731ed508717a7b078b08F7C6f9Aaf59F40,0xfBe12D0f97155303C97765c0AEe7f5081AFaaF33,0xFC35D861d98492F39E25264726f63d602C17cBBC,0xfc97c80fAca44E3b6f15807Cc52F2099D9d3012c,0xFd619afc284dc52Be2C4D2B977f9F9751db384Aa];
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() external onlyOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  function fulfillRandomWords(
    uint256 id, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
    randomN = s_randomWords[0] % wallets.length;
    emit recived(id);
  }

  function payTheWiner() public onlyOwner{
    token.transfer(wallets[randomN],1000*10**18);
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}
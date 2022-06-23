/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT
// File: test/contracts/unpacker/interfaces/IERC1155.sol


pragma solidity ^0.8.7;

interface IERC1155
{
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        uint256 id,
        uint256 amount
    ) external;

    function getAuthStatus(address account) external view returns (bool);
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @chainlink/contracts/src/v0.8/VRFRequestIDBase.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: @chainlink/contracts/src/v0.8/VRFConsumerBase.sol


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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
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

// File: test/contracts/unpacker/VRF.sol


pragma solidity ^0.8.7;



contract VRF is VRFConsumerBase
{
    bytes32 internal keyHash;
    uint256 internal fee;

    constructor() 
        VRFConsumerBase
        (
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 	0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }

    // used in unpacker contract
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual override {}

    // help tools ------------------------------------------------------------------------------------
    function expand(uint256 randomValue, uint256 n) internal view returns (uint256[] memory expandedValues) 
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) 
        {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i + block.timestamp))) % (2**256 - 1);
        }
        return expandedValues;
    }
}
// File: test/contracts/unpacker/unpacker.sol


pragma solidity ^0.8.7;




uint32 constant  UINT32_MAX  = 2**32 - 1;
uint8  constant  UINT8_MAX   = 2**8 - 1; 

contract unpacker is VRF, Ownable
{
    modifier isInActive(uint _packId)
    {
        require(!config[_packId].active, "To modify existing config you have to mark config as inactive before");
        _;
    }

    struct packConfig
    {
        bool           active;
        uint8          roll_counter;
        uint256        unlockTime;   
        probability[]  probabilities; // no more then 2^8 - 1
    }

    struct probability 
    {
        uint32      total_odds;
        outcome[]   outcomes;  // no more then 2^8 - 1
    }

    struct outcome
    {
        uint32 odds;
        int256 tokenId; // -1 if there is no reward
    }

    struct request
    {
        uint256 packId;
        address owner;
    }

    mapping(uint256 => packConfig)  private config;
    mapping(bytes32 => request)     private requestRandom;

    // to interact with collection
    IERC1155 public parentNFT;

    constructor(IERC1155 _parentNFT)
    {
        parentNFT = _parentNFT;
    }

    event unboxStarted(address owner, uint256 packId, bytes32 requestId);
    event unboxComplete(address owner, uint256 packId, int256[] rewards);
    event invalidUnbox(address owner, uint256 packId);

    function unbox(uint _packId) public returns(bytes32)
    {
        packConfig memory mr_packConfig = config[_packId];
        address sender = msg.sender;

        require(parentNFT.getAuthStatus(address(this)) == true, "Unpacker contract is not authorized within the collection");
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK in contract to unbox pack");
        require(mr_packConfig.active, "Config for this pack is inactive or has not been initialized");
        require(mr_packConfig.probabilities.length > 0, "Pack probabilities is incomplete");
        require(block.timestamp >= mr_packConfig.unlockTime, "The pack has not unlocked yet");

        parentNFT.safeTransferFrom(sender, address(this), _packId, 1, "0x00");
    
        bytes32 request_id = requestRandomness(keyHash, fee);
        requestRandom[request_id] = request(_packId, sender);

        emit unboxStarted(sender, _packId, request_id);

        return request_id;
    }

    /*
        fulfillRandomness is a callback function of chainlink VRF which receives random value.
        Here we go through our config and check what prizes the owner have to receive.
        Then unpacker contract will mint rewards and clear request table.

        reasons of getting pack back to owner:
            1) while waiting for random config packs were marked as inactive
            2) if unpacker contract does not have custom permission of minting new tokens at parentNFT
            3) if request mapping was not initialized well and owner is equal to zero address
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override 
    { 
        address owner  = requestRandom[requestId].owner;
        uint256 packId = requestRandom[requestId].packId;
        packConfig memory mr_packConfig = config[packId];

        if(mr_packConfig.active == false || parentNFT.getAuthStatus(address(this)) == false || owner == address(0))
        {
            emit invalidUnbox(owner, packId);
            parentNFT.safeTransferFrom(address(this), owner, packId, 1, "0x00");
        }
        else
        {
            uint256 probabilities_size = mr_packConfig.probabilities.length;
            uint256[] memory random_numbers = expand(randomness, probabilities_size);
            int256[] memory rewards = new int256[](probabilities_size);

            for(uint8 i = 0; i < probabilities_size; ++i)
            {
                probability memory mr_probability = config[packId].probabilities[i];
                uint32 summed_odds = 0;
                uint32 random_number  = uint32(random_numbers[i] % mr_probability.total_odds);
                
                for(uint8 j = 0; j < mr_probability.outcomes.length; ++j)
                {
                    summed_odds += mr_probability.outcomes[j].odds;

                    if(summed_odds > random_number)
                    {
                        int256 tokenId = mr_probability.outcomes[j].tokenId;
                        if(tokenId != -1)
                        {
                            parentNFT.mint(owner, uint256(tokenId), 1, "0x00");
                        }
                        rewards[i] = tokenId;
                        break;
                    }
                }
            }
            emit unboxComplete(owner, packId, rewards);

            // burning packs
            parentNFT.burn(packId, 1);
        }

        delete requestRandom[requestId];
    }

    // ------------------- SAFE --------------------

    function withdrawAssets(uint256 _packId, uint256 amount, address withdrawAddr) public onlyOwner
    {
        parentNFT.safeTransferFrom(address(this), withdrawAddr, _packId, amount, "0x00");
    }

    function withdrawTokens(address withdrawAddr, uint256 value)public onlyOwner
    {
        LINK.transfer(withdrawAddr, value);
    }

    function burnPacks(uint256 _packId, uint256 amount)public onlyOwner
    {
        parentNFT.burn(_packId, amount);
    }

    function clearRandomRequest(bytes32 request_id)public onlyOwner
    {
        delete requestRandom[request_id];
    }

    // ---------------------------------------------


    // ------------------- GET ---------------------

    function getConfig(uint256 _packId)public view returns(packConfig memory)
    {
        return config[_packId];
    }

    function getRequest(bytes32 request_id)public view returns(request memory)
    {
        return requestRandom[request_id];
    }

    // ---------------------------------------------


    // ------------------- SETUP -------------------

    /*
        addRolls funcation can be called only by contract.
        Adding rolls to config is available only when pack config is inactive,
        in order to avoid incorrect outcomes for owner.

        Probabilities and outcomes arrays have to consist maxmimum of 255(2^8 - 1) elements.
        Odds and total_odds of outcome have to be less than 4294967295(2^32 - 1).
        The outcomes must be sorted in descending order based on their odds. Each outcome
        must have positive odd.
    */
    function addRolls(
        uint256 _packId,
        uint32 _total_odds,
        uint32[] memory _odds,
        int256[] memory _rewards
        ) public onlyOwner isInActive(_packId)
    {
        require(_odds.length == _rewards.length, "odds length and rewards length must be match");
        require(_odds.length <= UINT8_MAX, "Outcomes count can not be greater then 2^8 - 1");
        require(_odds.length > 0, "A roll must include at least one outcome");
        
        packConfig storage st_packConfig = config[_packId];
        require(st_packConfig.probabilities.length < UINT8_MAX, "Probabilities count can not be greater then 2^8 - 1");

        probability storage st_probability = st_packConfig.probabilities.push();  //config[_packId].probabilities[st_packConfig.roll_counter];

        uint32 last_odds = UINT32_MAX;
        uint32 check_total = 0;

        for(uint8 i = 0; i < _odds.length; ++i)
        {
            require(last_odds >= _odds[i], "The outcomes must be sorted in descending order based on their odds");
            require(_odds[i] > 0, "Each outcome must have positive odds");
            require((check_total + last_odds) <= UINT32_MAX, "Total odds can't be more than 2^32 - 1");

            st_probability.outcomes.push( outcome(_odds[i], _rewards[i]) );
            check_total += _odds[i];
            last_odds = _odds[i];
        }
        require(check_total == _total_odds, "The total odds of the outcomes does not match the provided total odds");

        // updating mapping 
        st_packConfig.roll_counter++;
        st_probability.total_odds = _total_odds;
    }

    function setUnlockTime(uint _packId, uint newUnlockTime)public onlyOwner isInActive(_packId)
    {
        config[_packId].unlockTime = newUnlockTime;
    }

    function revertConfigStatus(uint _packId)public onlyOwner
    {
        config[_packId].active = !config[_packId].active;
    }

    // delete all the pack rolls
    function deleteRolls(uint _packId)public onlyOwner isInActive(_packId)
    {
        packConfig storage st_packConfig = config[_packId];
        require(st_packConfig.roll_counter > 0, "Nothing to delete");

        while(st_packConfig.probabilities.length > 0)
        {
            while(st_packConfig.probabilities[st_packConfig.probabilities.length - 1].outcomes.length > 0)
            {
                st_packConfig.probabilities[st_packConfig.probabilities.length - 1].outcomes.pop();
            }
            st_packConfig.probabilities.pop();
        }
        
        st_packConfig.roll_counter = 0;
    }

    function deleteConfig(uint256 _packId)public onlyOwner
    {
        delete config[_packId];
    }

    // ---------------------------------------------
    
    function onERC1155Received(
        address ,
        address ,
        uint256 ,
        uint256 ,
        bytes calldata 
    ) external virtual returns (bytes4) 
    {
        return this.onERC1155Received.selector;
    }
}
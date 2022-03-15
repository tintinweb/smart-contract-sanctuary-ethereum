/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;


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



   
    /**
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */


    //Rinkeby VRF credentials 
        /**
     * Chainlink VRF Coordinator address: 	0x6168499c0cFfCaCD319c818142124B7A15E857ab
     * LINK token address:                	0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Key Hash: 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc
     */
 
contract Rareround is VRFConsumerBase {
    using SafeMath for uint256;
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;
    mapping(uint256=>uint256) public counter;
    address public OwnerAdmin;

    uint256 public grnc;
    uint256 public rrc;

    modifier adminOnly() {
       require(msg.sender == OwnerAdmin, "Admin accessible only");
        _;
    } 

    mapping(uint256=>address) public User1;
    mapping(uint256=>address) public User2;
    mapping(uint256=>uint256) public ethStaked1;
    mapping(uint256=>uint256) public ethStaked2;
    mapping(uint256=>address[]) public nftStakedAddress1;
    mapping(uint256=>address[]) public nftStakedAddress2;
    mapping(uint256=>uint256[]) public nftStakedIds1;
    mapping(uint256=>uint256[]) public nftStakedIds2;
    mapping(uint256=>uint256[]) public nftCMapIds1;
    mapping(uint256=>uint256[]) public nftCMapIds2;
    mapping(uint256=>uint256) public TotalValue;
    mapping(uint256=>uint256) public idGenerated;
    uint256 public internalCounter = 0;    

    
    struct NFTStruct {
        address NFTAddress;
        uint256 tokenID;

    }

    struct NFTOwnerStruct {
        address depositor;
        uint256 counter;
    }

    struct User{
        address userAddress;
        NFTStruct[] NFT;
        uint256 Ethstaked;
        uint256 totalValue;
    }



    struct Game{
        address user1;
        address user2;
        uint256 game;
        address winner;
        uint256 user1DiceResult;
        uint256 user2DiceResult;
    }

    Game public ActiveGame;
    mapping (uint256 => Game) public gameMapping;
 
    Game[] public gameArray;
    mapping(uint256=>uint256[]) public resultArray;
    mapping (address => uint256) public depositMapping;
    mapping (address => mapping(uint256 => NFTStruct)) public NFTdepositMapping;
    mapping (address => uint256) public NFTdepositCounter;
    mapping (address => mapping(uint256=>NFTOwnerStruct)) public NFTOwnerStructCounter;
    mapping (address => uint256) public NFTCounterUser;
    mapping (address => uint256[]) public GamesPlayed;
    mapping (address => uint256[]) public GamesLost;
    mapping (address => uint256[]) public GamesWon;

    mapping (address => uint256) public OverAllEthStaked;
    mapping (address => uint256) public OverAllEthWon;
    mapping (address => uint256) public OverAllEthLost;

    mapping (address => uint256) public OverAllNFTStaked;
    mapping (address => uint256) public OverAllNFTWon;
    mapping (address => uint256) public OverAllNFTLost;
    
     constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        OwnerAdmin = msg.sender;
    }

    function getGamebyId(uint256 ID) public view returns(Game memory ){
        return gameMapping[ID];
    }

    function getLinkBalance() public view returns (uint256){
        return LINK.balanceOf(address(this));
    }

    function withdrawLink() adminOnly() public {
       LINK.transfer(OwnerAdmin, LINK.balanceOf(address(this)));
    }

    function getresults() public view returns(uint256[]memory ){
        return resultArray[internalCounter];
    }

    function deposit()public payable {
        depositMapping[msg.sender] += msg.value;}

    function getDeposit(address depositor) public view returns(uint256){
        return depositMapping[depositor];
    }



    function withdraw(uint256 amount) public payable {
        require(depositMapping[msg.sender]> amount,"Amount requested is more than balance");
        depositMapping[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function withdrawNFT(address NFTContract, uint256 index, uint256 amount) public {
        require(NFTdepositMapping[msg.sender][index].NFTAddress != address(0),"token does not exist");
        IERC721 token = IERC721(NFTdepositMapping[msg.sender][index].NFTAddress);
        token.transferFrom(address(this),msg.sender,NFTdepositMapping[msg.sender][index].tokenID);
        address owner = NFTOwnerStructCounter[NFTContract][index].depositor;
        uint256 _counter = NFTOwnerStructCounter[NFTContract][index].counter;
        delete NFTdepositMapping[owner][_counter];
        NFTCounterUser[msg.sender]-=1;
        
        if(amount >0 ){
            require(depositMapping[msg.sender]> amount,"Amount requested is more than balance");
    
            depositMapping[msg.sender] -= amount;

            payable(msg.sender).transfer(amount);
        }
 
    
    }
    

    function ProcessGame(User memory user1, User memory user2, uint256 game) public {
        require(user1.Ethstaked <= getDeposit(user1.userAddress),"Insuffecient balance of user 1" );
        require(user2.Ethstaked <= getDeposit(user2.userAddress),"Insuffecient balance of user 2" );
        require(depositMapping[user1.userAddress]>=1000 ,"You must have 0.1 Eth balance available to play this game");
         require(depositMapping[user2.userAddress]>=1000 ,"You must have 0.1 Eth balance available to play this game");
        internalCounter++;
        delete resultArray[internalCounter];
        randomResult = 0;
        counter[internalCounter] = game;
        User1[internalCounter] = user1.userAddress;
        User2[internalCounter] = user2.userAddress;
        ethStaked1[internalCounter] = user1.Ethstaked;
        ethStaked2[internalCounter] = user2.Ethstaked;
        TotalValue[internalCounter] = user1.totalValue + user2.totalValue;
        //ActiveGame[internalCounter] = Game(user1.userAddress,user2.userAddress,game,address(0),0,0);
            
        for (uint256 i = 0; i < user1.NFT.length; i++){
            address contractAddress = user1.NFT[i].NFTAddress;
            uint256 tokenId = user1.NFT[i].tokenID;
            
            nftStakedAddress1[internalCounter].push(contractAddress);
            nftStakedIds1[internalCounter].push(tokenId);
            nftCMapIds1[internalCounter].push(NFTOwnerStructCounter[contractAddress][tokenId].counter);
    
        }

        for (uint256 i = 0; i < user2.NFT.length; i++){
            address contractAddress = user2.NFT[i].NFTAddress;
            uint256 tokenId = user2.NFT[i].tokenID;
            nftStakedAddress2[internalCounter].push(contractAddress);
            nftStakedIds2[internalCounter].push(tokenId);
            nftCMapIds2[internalCounter].push(NFTOwnerStructCounter[contractAddress][tokenId].counter);

        }

       getRandomNumber();
       getRandomNumber();

 

     }

    
     function depositNFT(address NFT, uint256 ID) public  payable {
         IERC721 token = IERC721(NFT);
         token.transferFrom(msg.sender,address(this),ID);
         uint256 ICounter = NFTdepositCounter[msg.sender]+1;
         NFTStruct memory tx1 = NFTStruct(NFT,ID);
         NFTdepositMapping[msg.sender][ICounter] = tx1;
         NFTOwnerStructCounter[NFT][ID] = NFTOwnerStruct(msg.sender,ICounter);
         NFTCounterUser[msg.sender] +=1;
         depositMapping[msg.sender] += msg.value;
     }



    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        grnc++;
        return requestRandomness(keyHash, fee);
    }




    function rewardDistribution(uint256 _winner) public {
    // uint256 ownerValue = TotalValue <= 0.0009 ether ? 0.0009 ether : TotalValue.mul(5).div(100);
    // payable(OwnerAdmin).transfer(ownerValue);
    if(_winner ==0){

        depositMapping[User1[internalCounter]] += ethStaked2[internalCounter];
        depositMapping[User2[internalCounter]] -=ethStaked2[internalCounter];
        GamesWon[User1[internalCounter]].push(counter[internalCounter]);
        GamesLost[User2[internalCounter]].push(counter[internalCounter]);
        OverAllEthWon[User1[internalCounter]] += ethStaked2[internalCounter];
        OverAllEthLost[User2[internalCounter]] += ethStaked2[internalCounter];
   
        for (uint8 i = 0 ; i < nftStakedAddress2[internalCounter].length ; i++){
            NFTdepositCounter[User1[internalCounter]] ++;
            NFTCounterUser[User1[internalCounter]]+=1;
            NFTCounterUser[User2[internalCounter]]-=1;
            NFTdepositMapping[User1[internalCounter]][NFTdepositCounter[User1[internalCounter]]] = NFTStruct(nftStakedAddress2[internalCounter][i],nftStakedIds2[internalCounter][i]);
            delete NFTdepositMapping[User2[internalCounter]][nftCMapIds2[internalCounter][i]];
            OverAllNFTWon[User1[internalCounter]]+=1;
            OverAllNFTLost[User2[internalCounter]]+=1;
           
        }

    }else {

        depositMapping[User2[internalCounter]] += ethStaked1[internalCounter];
        depositMapping[User1[internalCounter]] -=ethStaked1[internalCounter];
        GamesWon[User2[internalCounter]].push(counter[internalCounter]);
        GamesLost[User1[internalCounter]].push(counter[internalCounter]);
        OverAllEthWon[User2[internalCounter]] += ethStaked1[internalCounter];
        OverAllEthLost[User1[internalCounter]] += ethStaked1[internalCounter];
  
        for (uint8 i = 0 ; i < nftStakedAddress1[internalCounter].length ; i++){
            NFTdepositCounter[User2[internalCounter]] ++;
            NFTCounterUser[User1[internalCounter]]+=1;
            NFTCounterUser[User2[internalCounter]]-=1;

            NFTdepositMapping[User2[internalCounter]][NFTdepositCounter[User2[internalCounter]]] = NFTStruct(nftStakedAddress1[internalCounter][i],nftStakedIds1[internalCounter][i]);
            delete NFTdepositMapping[User1[internalCounter]][nftCMapIds1[internalCounter][i]];
            OverAllNFTWon[User2[internalCounter]]+=1;
            OverAllNFTLost[User1[internalCounter]]+=1;
         }
    }
   }

    function getUserDetails(address user)public view returns(
        uint256 ethBalance,
        uint256 NFTbalance,
     
        uint256[] memory gamesWon,
        uint256[] memory gamesLost,
        uint256 gamesPlayedNo,
        uint256 gamesWonNo,
        uint256 gamesLostNo,

        uint256 _overAllEthWon,
        uint256 _overAllEthLost,

        uint256 _overAllNFTWon,
        uint256 _overAllNFTLost
        ){
        ethBalance = depositMapping[user];
        NFTbalance = NFTCounterUser[user];
     
        gamesWon = GamesWon[user];
        gamesLost = GamesLost[user];
     
        gamesWonNo = GamesWon[user].length;
        gamesLostNo = GamesLost[user].length;
        gamesPlayedNo = gamesWonNo+gamesLostNo;
        _overAllEthWon = OverAllEthWon[user];
        _overAllEthLost = OverAllEthLost[user];

        _overAllNFTWon = OverAllNFTWon[user];
        _overAllNFTLost = OverAllNFTLost[user];

     
    }





    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        idGenerated[internalCounter] = uint256(requestId);
        rrc++;
        randomResult = randomness.mod(18).add(1);
        uint256 randToUse = randomResult <3? 3 : randomResult;
        resultArray[internalCounter].push(randToUse);
        uint256 user1DiceResult;
        uint256 user2DiceResult;
        address winner; 
        if(resultArray[internalCounter].length > 1){
            user1DiceResult = resultArray[internalCounter][0];
            user2DiceResult = resultArray[internalCounter][1];
             if(resultArray[internalCounter][0]> resultArray[internalCounter][1]){
                 winner = User1[internalCounter];
       //ActiveGame.winner = User1;
                rewardDistribution(0);
                }
                else{

                    winner = User2[internalCounter];
//    ActiveGame.winner = User2;
                    rewardDistribution(1);
                    }

        }
        Game memory tx1 = Game(User1[internalCounter],User2[internalCounter],counter[internalCounter],winner,user1DiceResult,user2DiceResult);
        gameMapping[counter[internalCounter]] = tx1;
        gameArray.push(tx1);
        //counter[]++;
    }


//    function withdrawLink() external {} //- Implement a withdraw function to avoid locking your LINK in the contract
}
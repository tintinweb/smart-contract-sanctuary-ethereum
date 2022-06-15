/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// File: my/MathX128.sol



pragma solidity ^0.8.0;

library MathX128 {
    uint constant x128=(1<<128)-1;
    
    uint constant oneX128=(1<<128);
    
    function mulX128(uint l, uint r) internal pure returns(uint result) {
        uint l_high=l>>128;
        uint r_high=r>>128;
        uint l_low=(l&x128);
        uint r_low=(r&x128);
        result=((l_high*r_high)<<128) + (l_high*r_low) + (r_high*l_low) + ((l_low*r_low)>>128);
    }
    
    function mulUint(uint l,uint r) internal pure returns(uint result) {
        result=(l*r)>>128;
    }
    
    function toPercentage(uint numberX128,uint decimal) internal pure returns(uint result) {
        numberX128*=100;
        if(decimal>0){
            numberX128*=10**decimal;
        }
        return numberX128>>128;
    }
    
    function toX128(uint percentage,uint decimal) internal pure returns(uint result) {
        uint divisor=100;
        if(decimal>0)
            divisor*=10**decimal;
        return oneX128*percentage/divisor;
    }
}
// File: my/nft/property/INFTPropertyAdmin.sol



pragma solidity ^0.8.0;

interface INFTPropertyAdmin {
    function setUintProperty(uint tokenId,string calldata name,uint value) external;

    function setStringProperty(uint tokenId,string calldata name,string calldata value) external;
}
// File: my/nft/nftAdmin/INFTAdmin.sol



pragma solidity ^0.8.0;


interface INFTAdmin is INFTPropertyAdmin {
    function mintNFT(address to) external returns(uint);
}
// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


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

// File: @openzeppelin/[email protected]/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: my/new_cow/activity/ICowActivity.sol



pragma solidity ^0.8.0;


interface ICowActivity is IERC721 {
    function activityCow(uint _level,address to) external returns(uint tokenId);
    function activityBurn(uint tokenId) external;
    function level(uint tokenId) view external returns(uint);
}
// File: @openzeppelin/[email protected]4.5.0/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

// File: my/wolf/game/ICowGame.sol



pragma solidity ^0.8.0;


interface ICowGame is IERC721Enumerable {
    function cowInfo(uint tokenId) external returns(uint incomeValue,uint feeValue,uint life);
    function stolen(uint tokenId) external view returns(uint);
    function steal(uint tokenId,uint value,address to) external;
    function cowLevel(uint tokenId) external view returns(uint);
    function param() external view returns(address);
    function levelDown(uint tokenId,uint level) external;
    function blood(uint cowId,uint wolfId,uint bloodCC) external returns(bool);
}

// File: @openzeppelin/[email protected]/security/ReentrancyGuard.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: my/wolf/activity/CowMintWolf.sol


pragma solidity ^0.8.0;







contract CowMintWolf is ReentrancyGuard {
    INFTAdmin public wolfAdmin;
    ICowGame public cowGame;
    ICowActivity public cowAddress;
    uint[31] public power=[uint(0),100,120,162,225,310,419,553,713,901,1118,1368,1652,1974,2336,2743,3229,3993,4977,6195,8145,10967,15700,32168,76110,203437,
    729207,1435376,4051806,13525585,50025610];
    uint[31] public lifecycleList=[uint(0),28,33,44,60,82,110,143,181,226,275,331,392,459,531,609,693,826,989,1180,1481,1896,2447,4450,9158,20716,61417,92243,184755,408468,900461];
    uint[] public wolfProbability=[uint(0),0,50,50,0,0];
    uint[] public powerLevel=[uint(0),9999,59999,129999];
    uint[] public successProbability=[uint(0),0,10,50,100];
    uint public startTime;
    uint public durationDays;
    mapping(uint=>mapping(uint=>uint)) public mintCount;
    uint[] mintCountToday=[uint(0),0,10,4,2];

    VRFCoordinatorV2Interface public link;
    mapping(uint=>address) public openRequest;
    mapping(uint=>uint) public openRequestPower;

    event CowMintWolfRequest(uint indexed requestId,address user,uint allPower,uint[] cowIds);
    event WolfCreated(uint indexed requestId,address user,uint tokenId,uint grade,uint kind);
    event CowMintWolfResponse(uint indexed requestId,address user,uint allPower,bool success);

    constructor(INFTAdmin _wolfAdmin,ICowActivity _cowAddress,VRFCoordinatorV2Interface _link,ICowGame _cowGame,uint _startTime,uint _durationDays) {
        cowGame=_cowGame;
        cowAddress=_cowAddress;
        wolfAdmin=_wolfAdmin;
        link=_link;
        startTime=_startTime;
        durationDays=_durationDays;
    }

    function mint(address to,uint[] calldata cowIds) external nonReentrant {
        uint day=(block.timestamp-startTime)/ 1 days;
        require(day<durationDays,"activity end");
        uint allPower=0;
        uint i;
        for(i=0;i<cowIds.length;i++) {
            uint cowId=cowIds[i];
            require(cowAddress.ownerOf(cowId)==msg.sender,"need owner of nft");
            uint level=cowGame.cowLevel(cowId);
            (,,uint life)=cowGame.cowInfo(cowId);
            require(life>=lifecycle(level)*7/10,"cow life too low");
            allPower+=power[level];
        }
        for(i=1;i<4;i++){
            if(allPower<powerLevel[i]){
                break;
            }
        }
        mintCount[day][i]++;
        require(mintCount[day][i]<=mintCountToday[i],"Insufficient mint count today");
        uint requestId=linkRequest(3);
        openRequest[requestId]=to;
        openRequestPower[requestId]=allPower;
        emit CowMintWolfRequest(requestId,to,allPower,cowIds);
        for(i=0;i<cowIds.length;i++) {
            uint cowId=cowIds[i];
            cowAddress.activityBurn(cowId);
        }
    }

    function _open(uint256 requestId,address to,uint allPower,uint randomX128,uint wolfKindRandomX128,uint wolfRandomX128) internal {
        bool success=false;
        uint i;
        for(i=1;i<4;i++){
            if(allPower<powerLevel[i]){
                break;
            }
        }
        if(randomX128>=MathX128.toX128(100-successProbability[i],0)) {
            success=true;
        }
        if(success) {
            uint kind=MathX128.mulX128(wolfKindRandomX128,4)+1;
            uint j;
            for(j=1;j<wolfProbability.length;j++){
                uint wolfProbabilityX128=MathX128.toX128(wolfProbability[j],0);
                if(wolfRandomX128>=wolfProbabilityX128) {
                    wolfRandomX128-=wolfProbabilityX128;
                } else {
                    break;
                }
            }
            uint grade=j;
            require(grade>=1 && grade<=5,"WolfBlindBox: grade error");
            uint tokenId=wolfAdmin.mintNFT(to);
            wolfAdmin.setUintProperty(tokenId,"grade",grade);
            wolfAdmin.setUintProperty(tokenId,"kind",kind);
            emit WolfCreated(requestId,to,tokenId,grade,kind);
        }
        emit CowMintWolfResponse(requestId,to,allPower,success);
    }

    function linkRequest(uint32 num) internal returns(uint s_requestId) {
        s_requestId = link.requestRandomWords(
                0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04,
                4,
                3,
                1000000,
                num
            );
    }

    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal {
        address to=openRequest[requestId];
        uint requestPower=openRequestPower[requestId];
        if(to!=address(0)) {
            _open(requestId,to,requestPower,(randomWords[0]&((uint(1)<<128)-1)),(randomWords[1]&((uint(1)<<128)-1)),(randomWords[2]&((uint(1)<<128)-1)));
            openRequest[requestId]=address(0);
            openRequestPower[requestId]=0;
        }
    }

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) nonReentrant external {
        if (msg.sender != address(link)) {
            revert("need link");
        }
        fulfillRandomWords(requestId, randomWords);
    }

    function lifecycle(uint level) view public returns(uint){
        return lifecycleList[level]*10**18;
    }

}
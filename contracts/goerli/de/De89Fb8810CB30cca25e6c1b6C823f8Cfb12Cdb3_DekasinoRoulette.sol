/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// File: 78_Dekasino/src/Vaults/Interface/IVault.sol


pragma solidity ^0.8.19;

interface IVault {
    function allTimeHigh() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 _underlyingAmount) external;

    function getHighWaterMark() external view returns (uint256 watermark);

    function getShareAmount(uint256 _underlyingAmount) external view returns (uint256);

    function getUnderlyingAmount(uint256 _shareAmount) external view returns (uint256);

    function getUnderlyingBalance() external view returns (uint256);

    function highWaterMark() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function isVaultController(address) external view returns (bool);

    function lockAmounts(uint256) external view returns (uint256);

    function lockBet(uint256 _betId, uint256 _lockAmount) external;

    function maxSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setMaxSupply(uint256 _newSupply) external;

    function setStakingParams(address _newStakingContract, uint256 _newStakingPercent) external;

    function setVaultController(address _controller, bool _status) external;

    function stakingContract() external view returns (address);

    function stakingPercent() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function transferOwnership(address newOwner) external;

    function underlying() external view returns (address);

    function unlockBet(uint256 _betId, uint256 _unlockAmount) external;

    function withdraw(uint256 _shareAmount) external;
}
// File: @api3/airnode-protocol/contracts/rrp/interfaces/IWithdrawalUtilsV0.sol


pragma solidity ^0.8.0;

interface IWithdrawalUtilsV0 {
    event RequestedWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnode,
        address sponsor
    ) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256 withdrawalRequestCount);
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/ITemplateUtilsV0.sol


pragma solidity ^0.8.0;

interface ITemplateUtilsV0 {
    event CreatedTemplate(
        bytes32 indexed templateId,
        address airnode,
        bytes32 endpointId,
        bytes parameters
    );

    function createTemplate(
        address airnode,
        bytes32 endpointId,
        bytes calldata parameters
    ) external returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (
            address[] memory airnodes,
            bytes32[] memory endpointIds,
            bytes[] memory parameters
        );

    function templates(bytes32 templateId)
        external
        view
        returns (
            address airnode,
            bytes32 endpointId,
            bytes memory parameters
        );
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/IAuthorizationUtilsV0.sol


pragma solidity ^0.8.0;

interface IAuthorizationUtilsV0 {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}

// File: @api3/airnode-protocol/contracts/rrp/interfaces/IAirnodeRrpV0.sol


pragma solidity ^0.8.0;




interface IAirnodeRrpV0 is
    IAuthorizationUtilsV0,
    ITemplateUtilsV0,
    IWithdrawalUtilsV0
{
    event SetSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool sponsorshipStatus
    );

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        string errorMessage
    );

    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester)
        external
        view
        returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool isAwaitingFulfillment);
}

// File: @api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol


pragma solidity ^0.8.0;


/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequesterV0 {
    IAirnodeRrpV0 public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrpV0(_airnodeRrp);
        IAirnodeRrpV0(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: 78_Dekasino/DekasinoRoulette.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;






contract DekasinoRoulette is Ownable, RrpRequesterV0 {
    error BetAmount();
    error MinBetFragment();
    error TokenNotSupported();
    error InvalidBet();

    struct Bet {
        bytes32 requestId;
        address player;
        address token;
        uint8[38] betAmounts;
        uint256 totalBet;
        uint8 status;
    }

    struct Token {
        bool isSupported;
        IVault vault;
        uint256 minBet;
        uint256 minPossibleFragment;
        uint256 maxBet;
    }

    /**
     * Goerli TESTNET
     */
    address internal airnode = 0x6238772544f029ecaBfDED4300f13A3c4FE84E1D;
    address internal rrpAddress = 0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd;
    bytes32 internal endpointIdUint256 = 0xfb6d017bb87991b7495f563db3c8cf59ff87b09781947bb1e417006ad7f55a78;
    address internal sponsorWallet;

    mapping(bytes32 => address) private idToUser;
    mapping(bytes32 => uint256) private idToSystemIndex;
    mapping(bytes32 => uint256) private idToUserIndex;

    mapping(uint256 => bool) private validChoice;

    Bet[] public allBets;
    mapping(address => Bet[]) public userBets;
    mapping(address => Token) public tokens;

    event BetPlaced(address indexed user, uint256 betAmount, uint8[38] bets, address token, uint256 timestamp);
    event WheelSpinned(
        address indexed user,
        address token,
        uint256 rolledNumber,
        uint256 totalBet,
        uint256 wonAmount,
        uint256 timestamp
    );

    constructor() RrpRequesterV0(rrpAddress) {
        validChoice[1] = true; //Straight
        validChoice[2] = true; //Split
        validChoice[3] = true; //Street
        validChoice[4] = true; //Corner
        validChoice[5] = true; //0,00,1,2,3
        validChoice[6] = true; //Six line
        validChoice[12] = true; //Dozen/Column
        validChoice[18] = true; //High/Low/Red/Black/Odd/Even
        validChoice[18] = true; //High/Low/Red/Black/Odd/Even
    }

    function placeBet(address _token, uint8[38] memory _betAmounts) external {
        (uint256 total, uint256 highest) = _validateBet(_token, _betAmounts);
        IERC20 token = IERC20(_token);
        
        token.transferFrom(msg.sender, address(this), total);
        uint256 maxPayout = highest * 35;

        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode, endpointIdUint256, address(this), sponsorWallet, address(this), this.fulfillUint256.selector, ""
        );

        tokens[_token].vault.lockBet(uint256(requestId), maxPayout);

        allBets.push(Bet(requestId, msg.sender, _token, _betAmounts, total, 0));
        userBets[msg.sender].push(Bet(requestId, msg.sender, _token, _betAmounts, total, 0));

        idToUser[requestId] = msg.sender;
        idToSystemIndex[requestId] = allBets.length - 1;
        idToUserIndex[requestId] = userBets[msg.sender].length - 1;
        
        emit BetPlaced(msg.sender, total, _betAmounts, _token, block.timestamp);
        
    }

    function fulfillUint256(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp {
        uint256 qrngUint256 = abi.decode(data, (uint256));
        uint256 rolledNumber = qrngUint256 % 38; //0 to 38, 0 = 00, 1 = 0, 2 = 1 ... 37 = 36

        Bet storage system = allBets[idToSystemIndex[requestId]];
        Bet storage user = userBets[system.player][idToUserIndex[requestId]];
        IVault vault = tokens[user.token].vault;
        IERC20 token = IERC20(user.token);

        uint256 wonAmount = user.betAmounts[rolledNumber] * 35;
        uint256 amountToVault = user.totalBet - user.betAmounts[rolledNumber];
        token.transfer(address(vault), amountToVault);
        vault.unlockBet(uint256(requestId), wonAmount);
        wonAmount += user.betAmounts[rolledNumber];

        if (wonAmount > 0) {
            token.transfer(user.player, wonAmount);
            user.status = 1;
            system.status = 1;
        }

        emit WheelSpinned(user.player, user.token, rolledNumber, user.totalBet, wonAmount, block.timestamp);
    }

    function _validateBet(
        address _token,
        uint8[38] memory _betAmounts
    )
        internal
        view
        returns (uint256 totalBet, uint256 highestBet)
    {
        Token memory tkn = tokens[_token];
        if (!tkn.isSupported) revert TokenNotSupported();
        uint256 totalNumbers;
        
        for (uint256 i = 0; i < 38;) {
            if (_betAmounts[i] > 0) {
                if (_betAmounts[i] < tkn.minPossibleFragment) revert MinBetFragment();
                if (_betAmounts[i] > highestBet) highestBet = _betAmounts[i];
                totalNumbers++;
                totalBet += _betAmounts[i];
            }
            unchecked {
                i++;
            }
        }
        
        if (totalBet < tkn.minBet || totalBet > tkn.maxBet) revert BetAmount();
        if (!validChoice[totalNumbers]) revert InvalidBet();
        
    }

    function setToken(
        address _token,
        bool _isSupported,
        IVault _vault,
        uint256 _minBet,
        uint256 _maxBet
    )
        external
        onlyOwner
    {
        Token storage t = tokens[_token];

        t.isSupported = _isSupported;
        t.vault = _vault;
        t.minBet = _minBet;
        t.maxBet = _maxBet;

        t.minPossibleFragment = _minBet / 18;
    }

    function setOracle(address _airnode, address _sponsorWallet, bytes32 _endpointIdUint256) external onlyOwner {
        airnode = _airnode;
        sponsorWallet = _sponsorWallet;
        endpointIdUint256 = _endpointIdUint256;
    }

    function getTotalBetsByUser(address _user) external view returns (uint256) {
      return userBets[_user].length;
    }

    function getTotalBets() external view returns (uint256) {
      return allBets.length;
    }

    function getBetsOfUser(address user, uint256 from, uint256 to) external view returns (Bet[] memory bets) {
        bets = new Bet[](to - from + 1);
        for (uint256 i = from; i <= to; i++) {
            bets[i] = userBets[user][i];
        }
    }

    function getAllBets(uint256 from, uint256 to) external view returns (Bet[] memory bets) {
        bets = new Bet[](to - from + 1);
        for (uint256 i = from; i <= to; i++) {
            bets[i] = allBets[i];
        }
    }
}
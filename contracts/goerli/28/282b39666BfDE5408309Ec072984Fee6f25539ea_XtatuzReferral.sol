// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IXtatuzFactory.sol";
import "../interfaces/IXtatuzProject.sol";
import "../interfaces/IPresaled.sol";
import "../interfaces/IProperty.sol";
import "../interfaces/IXtatuzReroll.sol";
import "../interfaces/IXtatuzRouter.sol";

contract XtatuzReferral is Ownable {
    mapping(uint256 => uint256) private _referralAmount; // Project ID => Amount
    mapping(string => uint[]) public projectIdsByReferral;
    mapping(string => address) public addressByReferral;
    mapping(address => string) public referralByAddress;
    mapping(string => mapping(uint256 => uint256)) public buyerAgentAmount; // referral -> project id -> amount
    mapping(uint256 => mapping (string => uint256)) public referralLevel; // Project ID => referral code => level

    mapping(uint256 => uint256) public levelsPercentage;
    
    address private _operatorAddress;
    address public tokenAddress;

    uint256 public defaultPercentage = 3;

    constructor(address tokenAddress_, uint256[] memory initialPercentage_) {
        _transferOperator(tx.origin);
        require(tokenAddress_ != address(0), "REFERRAL: ADDRESS_ZERO");
        tokenAddress = tokenAddress_;
        setReferralLevels(initialPercentage_);
    }

    event OperatorTransfered(address indexed prevOperator, address indexed newSpv);
    event GenerateReferral(address indexed agentAddress, string referral); // Delete indexed
    event ChangeDefaultPercent(uint256 prevPercent, uint256 newPercent);
    event IncreaseBuyerRef(uint256 indexed projectId, string referral, uint256 referralAmount);
    event SetReferralLevels(uint256[] preLevels, uint256[] newLevels);
    event SetLevel(uint256 projectId, string referral, uint256 level); // Delete indexed

    modifier onlyOperator() {
        _checkOnlyOperator();
        _;
    }

    function generateReferral(address agentAddress_, string memory referral_) public onlyOperator {
        address prevAddress = addressByReferral[referral_];
        require(prevAddress == address(0), "REFERRAL: ALREADY_GENERATE");

        addressByReferral[referral_] = agentAddress_;
        referralByAddress[agentAddress_] = referral_;

        emit GenerateReferral(agentAddress_, referral_);
    }

    function updateReferralAmount(uint256 projectId_, uint256 amount_) public onlyOperator {
        _referralAmount[projectId_] += amount_;
    }

    function getRefferralAmount(uint256 projectId_) public view returns(uint256) {
        return _referralAmount[projectId_];
    }

    function getProjectIdsByReferral(string memory referral_) public view returns(uint[] memory) {
        return projectIdsByReferral[referral_];
    }

    function increaseBuyerRef(uint256 projectId_, string memory referral_, uint256 amount_) public onlyOperator {
        address agentWallet = addressByReferral[referral_];
        require(agentWallet != address(0), "REFERRAL: INVALID_REFERRAL");
        uint256 level = referralLevel[projectId_][referral_];
        uint256 percentage = defaultPercentage;

        if(level != 0) {
            percentage = levelsPercentage[level];
        }

        uint256 referralAmount = (amount_ * percentage) / 100;

        uint256[] memory projectIdList = projectIdsByReferral[referral_];

        bool foundedIndex;
        for (uint256 index = 0; index < projectIdList.length; index++) {
            if (projectIdList[index] == projectId_) {
                foundedIndex = true;
            }
        }
        if (!foundedIndex) {
            projectIdsByReferral[referral_].push(projectId_);
        }

        buyerAgentAmount[referral_][projectId_] += referralAmount;
        updateReferralAmount(projectId_, amount_);
        emit IncreaseBuyerRef(projectId_, referral_, referralAmount);
    }

    function claim(string memory referral_, uint projectId_) public {
        address agent = addressByReferral[referral_];
        address projectAddress = IXtatuzRouter(owner()).getProjectAddressById(projectId_);
        require(projectAddress != address(0), "REFERRAL: INVALID_PROJECT_ID");
        
        IXtatuzProject.Status status = IXtatuzProject(projectAddress).projectStatus();
        require(status == IXtatuzProject.Status.FINISH, "REFERRAL: PROJECT_NOT_FINISH");
        require(msg.sender == agent,"REFERRAL: INVALID_ACCOUNT");

        uint256 amount = buyerAgentAmount[referral_][projectId_];
        buyerAgentAmount[referral_][projectId_] = 0;

        IERC20(tokenAddress).transfer(msg.sender, amount);
    }

    function setDefaultPercentage(uint256 default_) public onlyOperator {
        require(default_ > 0, "REFERRAL: NO_ZERO_PERCENT");
        uint256 prev = defaultPercentage;
        defaultPercentage = default_;
        emit ChangeDefaultPercent(prev, default_);
    }

    function setLevel(uint projectId_, string memory referral_, uint level_) public onlyOperator {
        require(level_ <= 3, "REFERRAL: MAX_LEVEL_IS_3");
        referralLevel[projectId_][referral_] = level_;
        emit SetLevel(projectId_, referral_, level_);
    }

    function setReferralLevels(uint256[] memory percentagePerLevel_) public onlyOperator {
        uint256[] memory prevLevels = new uint256[](3);
        uint256[] memory newLevels = new uint256[](3);
        require(percentagePerLevel_.length == 3, "REFERRAL: 3_LEVELS");
        for(uint256 i = 0; i < percentagePerLevel_.length ; i++){
            prevLevels[i] = levelsPercentage[i + 1];
            levelsPercentage[i + 1] = percentagePerLevel_[i];
            newLevels[i] = levelsPercentage[i + 1];
        }
        emit SetReferralLevels(prevLevels, newLevels);
    }

    function transferOperator(address newOperator_) public onlyOperator {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "REFERRAL: ADDRESS_0");
        address prevOperator = _operatorAddress;
        _operatorAddress = newOperator_;
        emit OperatorTransfered(prevOperator, newOperator_);
    }

    function _checkOnlyOperator() internal view {
        require(msg.sender == _operatorAddress || msg.sender == owner(), "REFERRAL: NOT_OPERATOR");
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IProperty.sol";

interface IXtatuzFactory {
    struct ProjectPrepareData {
        uint256 projectId_;
        address spv_;
        address trustee_;
        uint256 count_;
        uint256 underwriteCount_;
        address tokenAddress_;
        address membershipAddress_;
        string name_;
        string symbol_;
        address routerAddress;
    }

    function createProjectContract(ProjectPrepareData memory projectData) external payable returns (address);

    function getProjectAddress(uint256 projectId_) external view returns (address);

    function getPresaledAddress(uint256 projectId_) external view returns (address);

    function getPropertyAddress(uint256 projectId_) external view returns (address);

    function allProjectAddress() external view returns (address[] memory);

    function allProjectId() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IProperty.sol";

interface IXtatuzProject {
    enum Status {
        AVAILABLE,
        FINISH,
        REFUND,
        UNAVAILABLE
    }

    struct ProjectData {
        uint256 projectId;
        address owner;
        uint256 count;
        uint256 countReserve;
        uint256 underwriteCount;
        uint256 value;
        address[] members;
        uint256 startPresale;
        uint256 endPresale;
        Status status;
        address tokenAddress;
        address propertyAddress;
        address presaledAddress;
    }

    function addProjectMember(address member_, uint256[] memory nftList_) external returns (uint256);

    function finishProject() external;

    function claim(address member_) external;

    function refund(address member_) external;

    function setPresalePeriod(uint256 startPresale_, uint256 endPresale_) external;

    function setUnderwriteCount(uint256 underwriteCount_) external; 

    function getMemberedNFTLists(address member_) external view returns (uint256[] memory);

    function projectStatus() external view returns (Status);

    function minPrice() external returns (uint256);

    function count() external view returns (uint256);

    function countReserve() external view returns (uint256);

    function startPresale() external view returns (uint256);

    function endPresale() external view returns (uint256);

    function tokenAddress() external view returns (address);

    function transferOwnership(address owner) external;

    function transferProjectOwner(address newProjectOwner_) external;

    function transferOperator(address newOperator_) external;

    function transferTrustee(address newTrustee_) external;

    function multiSigMint() external;

    function multiSigBurn() external;

    function getProjectData() external view returns (ProjectData memory);

    function checkCanClaim() external view returns (bool);

    function ownerClaimLeft(uint256[] memory leftNFTList) external;

    function extendEndPresale() external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IPresaled {

    function mint(address to, uint256[] memory tokenIdList_) external;

    function burn(uint256[] memory tokenIdList) external;

    function getPresaledOwner(address owner) external view returns (uint[] memory);

    function getMintedTimestamp(uint tokenId) external view returns (uint);

    function getPresaledPackage(uint tokenId) external view returns (uint);

    function transferOwnership(address owner) external;

    function setBaseURI(string memory baseURI_) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IProperty {
    enum PropertyStatus {
        INCOMPLETE,
        COMPLETE
    }

    function isMintedMaster() external view returns (bool);

    function mintMaster() external;

    function burnMaster() external;

    function getTokenIdList(address member) external view returns (uint256[] memory);

    function mintFragment(address to, uint256[] memory tokenIdList) external;

    function defragment() external;

    function transferOwnership(address owner) external;

    function propertyStatus() external view returns (PropertyStatus);

    function setPropertyStatus(PropertyStatus status) external;

    function setTokenURI(uint256 tokenId_, string memory tokenURI_) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function rerollData(uint256 index) external view returns(string memory);

    function tokenURI(uint256 tokenId_) external returns(string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function operatorBurning(uint256[] memory tokenIdList_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IXtatuzReroll {
    function tokenAddress() external returns(address);

    function reroll(uint256 projectId_, uint256 tokenId_, address member_) external;

    function rerollFee() external returns(uint256);

    function getRerollData(uint256 projectId) external returns(string[] memory);

    function setRerollData(uint256 projectId_, string[] memory rerollData_) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IProperty.sol";

interface IXtatuzRouter {

    enum CollectionType {
        PRESALE,
        PROPERTY
    }

    struct Collection {
        address contractAddress;
        uint256[] tokenIdList;
        CollectionType collectionType;
    }

    function createProject( //
        uint256 count_,
        uint256 underwriteCount_,
        address tokenAddress_,
        string memory name_,
        string memory symbol_,
        uint256 startPresale_,
        uint256 endPresale_
    ) external;

    function addProjectMember( //
        uint256 projectId_,
        uint256[] memory nftList_,
        string memory referral_
    ) external;

    function claim(uint256 projectId_) external;

    function refund(uint256 projectId) external;

    function nftReroll(uint256 projectId_, uint256 tokenId_) external;

    function claimRerollFee(uint256 projectId_) external;

    function isMemberClaimed(address member_, uint256 projectId_) external view returns (bool);

    function referralAddress() external view returns (address);

    function refferalAmount(string memory referral_) external returns(uint256);

    function getProjectAddressById(uint256 projectId) external view returns (address);

    function getMembershipAddress() external view returns (address);

    function getAllCollection() external returns(Collection[] memory);

    function setRerollAddress(address rerollAddress_) external;

    function setReferralAddress(address referralAddress_) external;

    function setPropertyStatus(uint256 projectId_, IProperty.PropertyStatus status) external;

    function _transferSpv(address newSpv_) external;

    function noticeReply(uint256 projectId_) external;

    function noticeToInactiveWallet(uint256 projectId_, address inactiveWallet_) external;

    function pullbackInactive(uint256 projectId_, address inactiveWallet_) external;
}

// SPDX-License-Identifier: MIT
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
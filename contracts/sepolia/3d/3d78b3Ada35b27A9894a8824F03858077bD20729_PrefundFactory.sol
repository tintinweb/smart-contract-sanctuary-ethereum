// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./PrefundCampaign.sol";

/*

██████╗░██████╗░███████╗███████╗██╗░░░██╗███╗░░██╗██████╗
██╔══██╗██╔══██╗██╔════╝██╔════╝██║░░░██║████╗░██║██╔══██╗
██████╔╝██████╔╝█████╗░░█████╗░░██║░░░██║██╔██╗██║██║░░██║
██╔═══╝░██╔══██╗██╔══╝░░██╔══╝░░██║░░░██║██║╚████║██║░░██║
██║░░░░░██║░░██║███████╗██║░░░░░╚██████╔╝██║░╚███║██████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝╚═════╝

 */

// This factory contract allows for the creation of crowdfunding campaigns / money pots.
contract PrefundFactory {

    // --------------------------------------------------------
    // 
    //  State variables
    // 
    // --------------------------------------------------------
    address public owner;
    address public feeCollector;
    address public campaignImplementation;
    uint256 public relativeFee; // 0.5% = 500 (per-mille)
    uint256 public fixedFee;
    uint256 public boostPrice;
    address public NFTContractAddress;
    uint256 public maxBoostsPerAddressPerCampaign;
    uint256 public freeBoostsPerNFTPerCampaign;
    address[] public campaigns;

    // --------------------------------------------------------
    // 
    //  Error declarations
    // 
    // --------------------------------------------------------
    error ZeroAddress();
    error IncorrectAmount(uint256 expected, uint256 provided);
    error NotOwner();
    error InvalidPage();
    error InvalidLimit();
    error PageOutOfRange(uint256 maxPage);
    error TransferFailed();

    // --------------------------------------------------------
    // 
    //  Event declarations
    // 
    // --------------------------------------------------------
    event CampaignCreated(address campaignAddress);
    event OwnerUpdated(address owner);
    event FeeCollectorUpdated(address feeCollector);
    event RelativeFeeUpdated(uint256 relativeFee);
    event FixedFeeUpdated(uint256 fixedFee);
    event BoostPriceUpdated(uint256 boostPrice);
    event NFTContractAddressUpdated(address NFTContractAddress);
    event MaxBoostsPerAddressPerCampaignUpdated(uint256 maxBoostsPerAddressPerCampaign);
    event FreeBoostsPerNFTPerCampaignUpdated(uint256 freeBoostsPerNFTPerCampaign);


    // --------------------------------------------------------
    // 
    //  PrefundFactory constructor
    // 
    // --------------------------------------------------------
    constructor(
        address _feeCollector,
        address _campaignImplementation,
        uint256 _relativeFee,
        uint256 _fixedFee,
        uint256 _boostPrice,
        address _NFTContractAddress,
        uint256 _maxBoostsPerAddressPerCampaign,
        uint256 _freeBoostsPerNFTPerCampaign
    ) {
        if (_feeCollector == address(0)) revert ZeroAddress();
        owner = msg.sender;
        feeCollector = _feeCollector;
        campaignImplementation = _campaignImplementation;
        relativeFee = _relativeFee;
        fixedFee = _fixedFee;
        boostPrice = _boostPrice;
        NFTContractAddress = _NFTContractAddress;
        maxBoostsPerAddressPerCampaign = _maxBoostsPerAddressPerCampaign;
        freeBoostsPerNFTPerCampaign = _freeBoostsPerNFTPerCampaign;
    }


    // --------------------------------------------------------
    // 
    //  Method to create a new crowdfunding campaign
    // 
    // --------------------------------------------------------
    function createCampaign (
        string memory name,
        address recipient,
        uint256 goal, 
        uint256 hardCap, 
        uint256 minContribution, 
        uint256 maxContribution,
        uint256 maxContributionPerAddress,
        uint256 duration, 
        uint256 startDate,
        int256[] memory contributionTierAmounts, 
        string[] memory contributionTierRewards,
        string[] memory contributionTierEstimatedDeliveries,
        bool receivable,
        bool strictMode
    ) external payable returns (address) {

        if (msg.value != 0 && msg.value != fixedFee) revert IncorrectAmount(fixedFee, msg.value);

        // Determine the withdrawal fee for the campaign
        // If the fixedFee in ETH is sent or sender owns an NFT, the fee is 0
        uint256 withdrawalFee = (msg.value == fixedFee || (NFTContractAddress != address(0) && IERC721(NFTContractAddress).balanceOf(msg.sender) > 0)) ? 0 : relativeFee;

        // Create the campaign clone
        address payable clone = payable(Clones.clone(campaignImplementation));

        // Initialize the campaign clone
        PrefundCampaign(clone).initialize(
            msg.sender, // owner address
            recipient,
            address(this), // factory address
            name, 
            goal, 
            hardCap, 
            minContribution, 
            maxContribution,
            maxContributionPerAddress,
            duration, 
            startDate,
            contributionTierAmounts,
            contributionTierRewards,
            contributionTierEstimatedDeliveries,
            withdrawalFee,
            receivable,
            strictMode
        );

        // Add the campaign to the list of all campaigns
        campaigns.push(address(clone));

        // Emit event indicating the creation of the campaign
        emit CampaignCreated(address(clone));

        // Transfer the ETH sent to the feeCollector
        if (msg.value > 0) {
            (bool success, ) = payable(feeCollector).call{value: msg.value}("");
            if (!success) revert TransferFailed();
        }

        // Return the address of the new campaign
        return clone;
    }


    // --------------------------------------------------------
    // 
    //  Below methods are for updating contract parameters, 
    //  and are only callable by the owner of the contract
    // 
    // --------------------------------------------------------
    function transferOwnership(address _owner) external onlyOwner {
        if (_owner == address(0)) revert ZeroAddress();
        owner = _owner;
        emit OwnerUpdated(_owner);
    }

    function updateFeeCollector(address _feeCollector) external onlyOwner {
        if (_feeCollector == address(0)) revert ZeroAddress();
        feeCollector = _feeCollector;
        emit FeeCollectorUpdated(_feeCollector);
    }

    function updateRelativeFee(uint256 _relativeFee) external onlyOwner {
        relativeFee = _relativeFee;
        emit RelativeFeeUpdated(_relativeFee);
    }

    function updateFixedFee(uint256 _fixedFee) external onlyOwner {
        fixedFee = _fixedFee;
        emit FixedFeeUpdated(_fixedFee);
    }

    function updateBoostPrice(uint256 _boostPrice) external onlyOwner {
        boostPrice = _boostPrice;
        emit BoostPriceUpdated(_boostPrice);
    }

    function updateNFTContractAddress(address _NFTContractAddress) external onlyOwner {
        NFTContractAddress = _NFTContractAddress;
        emit NFTContractAddressUpdated(_NFTContractAddress);
    }

    function updateMaxBoostsPerAddressPerCampaign(uint256 _maxBoostsPerAddressPerCampaign) external onlyOwner {
        maxBoostsPerAddressPerCampaign = _maxBoostsPerAddressPerCampaign;
        emit MaxBoostsPerAddressPerCampaignUpdated(_maxBoostsPerAddressPerCampaign);
    }

    function updateFreeBoostsPerNFTPerCampaign(uint256 _freeBoostsPerNFTPerCampaign) external onlyOwner {
        freeBoostsPerNFTPerCampaign = _freeBoostsPerNFTPerCampaign;
        emit FreeBoostsPerNFTPerCampaignUpdated(_freeBoostsPerNFTPerCampaign);
    }


    // --------------------------------------------------------
    // 
    //  Views
    // 
    // --------------------------------------------------------

    // Returns the current configuration
    function getConfig() external view returns (address, address, address, uint256, uint256, uint256, address, uint256, uint256) {
        return (owner, feeCollector, campaignImplementation, relativeFee, fixedFee, boostPrice, NFTContractAddress, maxBoostsPerAddressPerCampaign, freeBoostsPerNFTPerCampaign);
    }

    // Returns the total number of created campaigns
    function nbCampaigns() external view returns (uint256) {
        return campaigns.length;
    }

    // Returns a paginated list of all campaigns in desc order
    function getCampaigns(uint256 page, uint256 limit) public view returns (address[] memory) {
        if (page <= 0) revert InvalidPage();
        if (limit <= 0) revert InvalidLimit();
        if (page > (campaigns.length / limit) + 1) revert PageOutOfRange((campaigns.length / limit) + 1);

        // Compute start and end indices of the slice
        uint256 start = campaigns.length < limit * page ? 0 : campaigns.length - limit * page;
        uint256 end = campaigns.length < limit * (page - 1) ? 0 : campaigns.length - limit * (page - 1);

        // Create new array to hold the result
        uint256 resultLength = end - start;
        address[] memory result = new address[](resultLength);

        // Populate the result array in reverse order
        for (uint256 i = 0; i < resultLength; i++) {
            result[i] = campaigns[end - i - 1];
        }

        return result;
    }


    // --------------------------------------------------------
    // 
    //  Modifiers
    // 
    // --------------------------------------------------------
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPrefundFactory.sol";

contract PrefundCampaign {

    enum Status {
        Inactive,
        Active,
        Expired,
        Canceled,
        Funded
    }

    // If the amount is negative, the contribution tier reward is intended for 
    // the top X contributors where X is the absolute value of the tier amount
    struct ContributionTier {
        int256 amount;
        string reward;
        string estimatedDelivery;
    }


    // --------------------------------------------------------
    // 
    //  State variables
    // 
    // --------------------------------------------------------
    string public name;
    address public owner;
    address public recipient;
    uint256 public goal; // If == 0 -> Money pot
    uint256 public hardCap; // If == 0 -> disabled
    uint256 public minContribution;
    uint256 public maxContribution; // If == 0 -> disabled
    uint256 public maxContributionPerAddress; // If == 0 -> disabled
    uint256 public duration; // In seconds
    uint256 public startDate; // If == 0 -> start now
    uint256 public endDate;
    uint256 public amountFunded;
    uint256 public withdrawalFee; // Ex: 0.5% == 500 (per-mille)
    bool public receivable;
    bool public strictMode;
    bool public withdrawn;
    bool public canceled;
    bool private initialized;

    // Mapping to keep track of contributors and their contributions
    mapping(address => uint256) public contributions;
    // Mapping to keep track of users and their boosts
    mapping(address => uint256) public boosts;

    // An array to store the contribution tiers
    ContributionTier[] public contributionTiers;
    
    // IPrefundFactory interface instance
    IPrefundFactory public factory;


    // --------------------------------------------------------
    // 
    //  Error declarations
    // 
    // --------------------------------------------------------
    error AlreadyInitialized();
    error ZeroAddress();
    error InvalidStringLength();
    error InvalidGoalHardCapRelation();
    error InvalidContributionLimits();
    error InvalidDuration();
    error InvalidContributionTiers();
    error InvalidContributionTierAmount();
    error InvalidContributionTierReward();
    error InvalidContributionTierDelivery();
    error NotReceivable();
    error BelowMinContribution();
    error AboveMaxContribution();
    error AboveMaxPerAddressContribution();
    error InvalidContributionInStrictMode();
    error RefundsNotActive();
    error NoParticipation();
    error TransferFailed();
    error NotEnoughTokensInContract();
    error NotOwner();
    error NotOwnerOrRecipient();
    error NotActive();
    error MaxBoostsPerAddressPerCampaignReached();
    error IncorrectETHSent();
    error GoalNotReached();
    error NoFundsToWithdraw();
    error FeeTransferFailed();

    // --------------------------------------------------------
    // 
    //  Event declarations
    // 
    // --------------------------------------------------------
    event ContributionReceived(address contributor, uint256 amount);
    event Boosted(address booster, uint256 amount, uint256 boostPrice);
    event RefundIssued(address contributor, uint256 amount);
    event Withdrawn(address owner, uint256 amount);
    event OwnerUpdated(address newOwner);
    event CampaignCancelled();


    // --------------------------------------------------------
    // 
    //  Initialization of the clone Campaign contract
    // 
    // --------------------------------------------------------
    function initialize(
        address _owner,
        address _recipient,
        address _factoryAddress,
        string memory _name,
        uint256 _goal, 
        uint256 _hardCap, 
        uint256 _minContribution, 
        uint256 _maxContribution,
        uint256 _maxContributionPerAddress,
        uint256 _duration, 
        uint256 _startDate,
        int256[] memory contributionTierAmounts, 
        string[] memory contributionTierRewards,
        string[] memory contributionTierEstimatedDeliveries,
        uint256 _withdrawalFee,
        bool _receivable,
        bool _strictMode
    ) public {
        // Revert if clone contract already initialized
        if (initialized) revert AlreadyInitialized();
        initialized = true;

        // Check if the inputs are valid
        if (_owner == address(0)) revert ZeroAddress();
        if (_recipient == address(0)) revert ZeroAddress();
        if (_factoryAddress == address(0)) revert ZeroAddress();
        if (bytes(_name).length <= 0 || bytes(_name).length > 50) revert InvalidStringLength();
        if (_hardCap != 0 && _goal > _hardCap) revert InvalidGoalHardCapRelation();
        if (_maxContribution != 0 && _maxContribution < _minContribution) revert InvalidContributionLimits();
        //maxContributionPerAddress must be 0 or greater than minContribution and maxContribution
        if (_maxContributionPerAddress != 0 && (_maxContributionPerAddress < _minContribution || _maxContributionPerAddress < _maxContribution)) revert InvalidContributionLimits();

        if (_goal > 0) {
            // Duration of the campaign should be >= 300 (5min) and <= 5184000 (60 days)
            if (_duration < 5 minutes || _duration > 60 days) revert InvalidDuration();
        } else {
            // Duration of the money pot should be >= 300 (5min) and <= 31536000 (1 year)
            if (_duration < 5 minutes || _duration > 365 days) revert InvalidDuration();
        } 
        
        if (contributionTierAmounts.length > 10) revert InvalidContributionTiers();
        if (contributionTierAmounts.length != contributionTierRewards.length || contributionTierRewards.length != contributionTierEstimatedDeliveries.length) revert InvalidContributionTiers();
        
        // Assign state variables
        name = _name;
        owner = _owner;
        recipient = _recipient;
        goal = _goal;
        hardCap = _hardCap;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
        maxContributionPerAddress = _maxContributionPerAddress;
        duration = _duration;
        withdrawalFee = _withdrawalFee;
        receivable = _receivable;
        factory = IPrefundFactory(_factoryAddress);

        // If startDate == 0 or startDate is lower than the current block.timestamp -> start the campaign
        if (_startDate == 0 || _startDate <= block.timestamp) {
            startDate = block.timestamp;
        } else {
            startDate = _startDate;
        }

        endDate = startDate + duration;

        // Push contribution tiers to the array
        bool tiersHasPositiveAmount = false;

        for (uint256 i = 0; i < contributionTierAmounts.length; i++) {
            if (contributionTierAmounts[i] >= 0 && 
                (contributionTierAmounts[i] < int256(_minContribution) || 
                contributionTierAmounts[i] > (_maxContribution == 0 ? contributionTierAmounts[i] : int256(_maxContribution)) || 
                contributionTierAmounts[i] > (_maxContributionPerAddress == 0 ? contributionTierAmounts[i] : int256(_maxContributionPerAddress)))) 
                revert InvalidContributionTierAmount();
            if (bytes(contributionTierRewards[i]).length <= 0 || bytes(contributionTierRewards[i]).length > 500) revert InvalidContributionTierReward();
            if (bytes(contributionTierEstimatedDeliveries[i]).length <= 0 || bytes(contributionTierEstimatedDeliveries[i]).length > 50) revert InvalidContributionTierDelivery();
            contributionTiers.push(ContributionTier(contributionTierAmounts[i], contributionTierRewards[i], contributionTierEstimatedDeliveries[i]));
            if (contributionTierAmounts[i] >= 0) tiersHasPositiveAmount = true;
        }

        // strictMode can be true only if there is at least one contribution tier with amount >= 0
        if (_strictMode && tiersHasPositiveAmount) strictMode = true;
    }


    // --------------------------------------------------------
    // 
    //  Public methods
    // 
    // --------------------------------------------------------

    // Function for contributors to contribute to the campaign
    function contribute() external payable {
        recordContribution(msg.sender, msg.value);
    }

    // Fallback function to receive contributions
    receive() external payable {
        if (!receivable) revert NotReceivable();
        recordContribution(msg.sender, msg.value);
    }

    // Internal function to record contributions
    function recordContribution (address _contributor, uint256 _amount) internal onlyActive {
        if (_amount < minContribution) revert BelowMinContribution();
        if (maxContribution != 0 && _amount > maxContribution) revert AboveMaxContribution();
        if (maxContributionPerAddress != 0 && contributions[_contributor] + _amount > maxContributionPerAddress) revert AboveMaxPerAddressContribution();

        // If strictMode is enabled, check if the amount sent matches one of the contribution tiers
        if (strictMode) {
            bool amountValid = false;
            for (uint256 i = 0; i < contributionTiers.length; i++) {
                if (contributionTiers[i].amount == int256(_amount)) {
                    amountValid = true;
                    break;
                }
            }
            // Contribution does not match any contribution tiers
            if (!amountValid) revert InvalidContributionInStrictMode();
        }

        // Record contribution
        contributions[_contributor] += _amount;

        // Update amountFunded
        amountFunded += _amount;

        emit ContributionReceived(_contributor, _amount);
    }

    // Function to boost the campaign
    function boost(uint256 _amount) external payable onlyActive {

        if (boosts[msg.sender] + _amount > factory.maxBoostsPerAddressPerCampaign()) revert MaxBoostsPerAddressPerCampaignReached();

        uint256 boostsToPayFor = _amount;
        uint256 freeBoostsLeft = factory.freeBoostsPerNFTPerCampaign() - boosts[msg.sender];

        // Check if the sender has the Prefund NFT and if they haven't used all their free boosts
        if (factory.NFTContractAddress() != address(0) && IERC721(factory.NFTContractAddress()).balanceOf(msg.sender) > 0 && freeBoostsLeft > 0) {
            // If the user has more free boosts left than they want to use now, they don't have to pay anything
            if (freeBoostsLeft >= _amount) {
                if (msg.value != 0) revert IncorrectETHSent();
                boostsToPayFor = 0;
            } else {
                // If the user has some free boosts left but fewer than they want to use now,
                // they only have to pay for the difference
                if (msg.value != factory.boostPrice() * (_amount - freeBoostsLeft)) revert IncorrectETHSent();
                boostsToPayFor -= freeBoostsLeft;
            }
        } else {
            if (msg.value != factory.boostPrice() * _amount) revert IncorrectETHSent();
        }

        // Record boost
        boosts[msg.sender] += _amount;

        // Transfer boost fee
        if (boostsToPayFor > 0) {
            (bool successFee, ) = payable(factory.feeCollector()).call{value: msg.value }("");
            if (!successFee) revert TransferFailed();
        }

        emit Boosted(msg.sender, _amount, factory.boostPrice());
    }

    // Function for contributors to claim a refund if the campaign is expired or cancelled
    function getRefund() external {
        if (status() != Status.Expired && status() != Status.Canceled) revert RefundsNotActive();
        uint256 contributionAmount = contributions[msg.sender];
        if (contributionAmount <= 0) revert NoParticipation();

        // Reset the contribution of the caller
        contributions[msg.sender] = 0;

        // Transfer the contribution back to the contributor
        (bool success, ) = payable(msg.sender).call{value: contributionAmount}("");
        if (!success) revert TransferFailed();

        emit RefundIssued(msg.sender, contributionAmount);
    }


    // --------------------------------------------------------
    // 
    //  OnlyOwner methods
    // 
    // --------------------------------------------------------

    // Function for the owner to cancel the campaign
    function cancel() external onlyOwner {
        canceled = true;
        emit CampaignCancelled();
    }

    // Function to transfer ownership of the campaign to a new owner
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    // Function for the owner to withdraw the funds once the campaign has been funded
    function withdraw() external onlyOwnerOrRecipient {
        if (status() != Status.Funded && (status() != Status.Active || amountFunded < goal)) revert GoalNotReached();
        if (address(this).balance <= 0) revert NoFundsToWithdraw();

        // Mark the funds as withdrawn
        withdrawn = true;

        // Transfer the withdrawal fee to the fee collector
        if (withdrawalFee > 0) {
            uint256 fee = address(this).balance * withdrawalFee / 1000; // Dividing by 1000 because withdrawalFee is per-mille
            (bool successFee, ) = payable(factory.feeCollector()).call{value: fee}("");
            if (!successFee) revert FeeTransferFailed();
        }
       
        // Transfer the rest of the funds to the recipient
        (bool success, ) = payable(recipient).call{value: address(this).balance}("");
        if (!success) revert TransferFailed();

        emit Withdrawn(recipient, address(this).balance);
    }

    // Emergency recovery of ERC20 tokens sent to the contract by accident
    function recoverERC20Tokens(address tokenAddress) external onlyOwnerOrRecipient {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(owner, balance);
        }
    }


    // --------------------------------------------------------
    // 
    //  Viwes
    // 
    // --------------------------------------------------------

    // Function to get the current status of the campaign
    function status() public view returns (Status) {
        if (canceled) {
            return Status.Canceled;
        } else if (withdrawn || (hardCap != 0 && amountFunded >= hardCap) || (block.timestamp >= endDate && amountFunded >= goal)) {
            return Status.Funded;
        } else if (block.timestamp < startDate) {
            return Status.Inactive;
        } else if (block.timestamp >= endDate && amountFunded < goal) {
            return Status.Expired;
        } else {
            return Status.Active;
        }
    }

    // Function to get the configuration of the campaign
    function getConfig () external view returns (string memory, address, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool, bool, bool, bool, ContributionTier[] memory) {
        return (name, owner, recipient, goal, hardCap, minContribution, maxContribution, maxContributionPerAddress, duration, startDate, endDate, amountFunded, withdrawalFee, receivable, strictMode, withdrawn, canceled, contributionTiers); 
    }


    // --------------------------------------------------------
    // 
    //  Modifiers
    // 
    // --------------------------------------------------------
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyOwnerOrRecipient() {
        if (msg.sender != owner && msg.sender != recipient) revert NotOwnerOrRecipient();
        _;
    }

    modifier onlyActive() {
        if (status() != Status.Active) revert NotActive();
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IPrefundFactory {
    
    // State variables
    function owner() external view returns (address);
    function feeCollector() external view returns (address);
    function relativeFee() external view returns (uint256);
    function fixedFee() external view returns (uint256);
    function boostPrice() external view returns (uint256);
    function NFTContractAddress() external view returns (address);
    function maxBoostsPerAddressPerCampaign() external view returns (uint256);
    function freeBoostsPerNFTPerCampaign() external view returns (uint256);
    function campaigns(uint256 index) external view returns (address);

    // Events
    event CampaignCreated(address campaignAddress);
    event OwnerUpdated(address owner);
    event FeeCollectorUpdated(address feeCollector);
    event RelativeFeeUpdated(uint256 relativeFee);
    event FixedFeeUpdated(uint256 fixedFee);
    event BoostPriceUpdated(uint256 boostPrice);
    event NFTContractAddressUpdated(address NFTContractAddress);
    event MaxBoostsPerAddressPerCampaignUpdated(uint256 maxBoostsPerAddressPerCampaign);
    event FreeBoostsPerNFTPerCampaignUpdated(uint256 freeBoostsPerNFTPerCampaign);

    // Methods
    function createCampaign (
        string memory name,
        address recipient,
        uint256 goal, 
        uint256 hardCap, 
        uint256 minContribution, 
        uint256 maxContribution,
        uint256 maxContributionPerAddress,
        uint256 duration, 
        uint256 startDate,
        int256[] memory contributionTierAmounts, 
        string[] memory contributionTierRewards,
        string[] memory contributionTierEstimatedDeliveries,
        bool receivable,
        bool strictMode
    ) external payable returns (address);

    function transferOwnership(address _owner) external;
    function updateFeeCollector(address _feeCollector) external;
    function updateRelativeFee(uint256 _relativeFee) external;
    function updateFixedFee(uint256 _fixedFee) external;
    function updateBoostPrice(uint256 _boostPrice) external;
    function updateNFTContractAddress(address _NFTContractAddress) external;
    function updateFreeBoostsPerNFTPerCampaign(uint256 _freeBoostsPerNFTPerCampaign) external;
    function updateMaxBoostsPerAddressPerCampaign(uint256 _maxBoostsPerAddressPerCampaign) external;

    // Views
    function getConfig() external view returns (address, address, uint256, uint256, uint256, address, uint256, uint256);
    function nbCampaigns() external view returns (uint256);
    function getCampaigns(uint256 page, uint256 limit) external view returns (address[] memory);
}
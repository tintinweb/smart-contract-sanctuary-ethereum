// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IPrefundFactory.sol";

contract PrefundCampaign {
    // Declare Status enum with possible states of a campaign
    enum Status {
        Inactive,
        Active,
        Expired,
        Canceled,
        Funded
    }

    // Structure to represent contribution tier
    struct ContributionTier {
        int256 contributionAmount;
        string contributionReward;
    }


    // --------------------------------------------------------
    // 
    //  State variables
    // 
    // --------------------------------------------------------
    string public name;
    address public owner;
    uint256 public minGoal; // At least 1 wei
    uint256 public maxGoal; // If == 0 -> there is no maxGoal
    uint256 public minContribution; // At least 1 wei
    uint256 public maxContribution; // If == 0 -> there is no maxContribution
    uint256 public duration; // At least 5 * 60s = 300
    uint256 public startDate; // If == 0 -> start immediately
    uint256 public amountFunded;
    uint256 public withdrawalFee; // 0.5% == 500 (per-mille)
    bool public withdrawn = false;
    bool public canceled = false;

    // Mapping to keep track of contributors and their contributions
    mapping(address => uint256) public contributions;
    // Mapping to keep track of users and their boosts
    mapping(address => uint256) public boosts;

    // An array to store the contribution tiers
    ContributionTier[] private contributionTiers;
    
    // IPrefundFactory interface instance
    IPrefundFactory public factory;


    // --------------------------------------------------------
    // 
    //  Event declarations
    // 
    // --------------------------------------------------------
    event ContributionReceived(address contributor, uint256 amount);
    event Boosted(address booster, uint256 amount);
    event RefundIssued(address contributor, uint256 amount);
    event Withdrawn(address owner, uint256 amount);
    event OwnerUpdated(address newOwner);
    event CampaignCancelled();


    // --------------------------------------------------------
    // 
    //  PrefundCampaign constructor
    // 
    // --------------------------------------------------------
    constructor(
        address _owner,
        address _factoryAddress,
        string memory _name,
        uint256 _minGoal, 
        uint256 _maxGoal, 
        uint256 _minContribution, 
        uint256 _maxContribution, 
        uint256 _duration, 
        uint256 _startDate,
        int256[] memory contributionTierAmounts, 
        string[] memory contributionTierRewards,
        uint256 _withdrawalFee
    ) {
        // Check if the inputs are valid
        require(_minContribution > 0, "minContribution should be at least 1 wei");
        require(_maxContribution > 0, "maxContribution should be at least 1 wei");
        require(_maxContribution >= _minContribution, "maxContribution can not be lower than minContribution");
        require(_minGoal > 0, "minGoal should be at least 1 wei");
        require(_maxGoal == 0 || _minGoal <= _maxGoal, "minGoal should be less than or equal to maxGoal");
        require(_duration >= 300, "Duration cannot be less than 5min");
        require(_startDate == 0 || block.timestamp <= _startDate, "You can not set a past date for start");
        require(_owner != address(0), "Owner address cannot be 0");
        require(_factoryAddress != address(0), "Factory address cannot be 0");
        require(contributionTierAmounts.length >= 1 && contributionTierRewards.length >= 1, "At least one tier should be specified");
        require(contributionTierAmounts.length == contributionTierRewards.length, "Mismatched contribution tier arrays");

        // Assign state variables
        name = _name;
        owner = _owner;
        minGoal = _minGoal;
        maxGoal = _maxGoal;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
        duration = _duration;
        withdrawalFee = _withdrawalFee;
        factory = IPrefundFactory(_factoryAddress);

        // If startDate == 0 -> start the campaign
        if (_startDate == 0) {
            startDate = block.timestamp;
        } else {
            startDate = _startDate;
        }

        // Push contribution tiers to the array
        for (uint256 i = 0; i < contributionTierAmounts.length; i++) {
            contributionTiers.push(ContributionTier(contributionTierAmounts[i], contributionTierRewards[i]));
        }
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
        recordContribution(msg.sender, msg.value);
    }

    // Internal function to record contributions
    function recordContribution (address _contributor, uint256 _amount) internal {
        require(_amount >= minContribution, "Contribution is below the minimum limit");
        require(contributions[_contributor] + _amount <= maxContribution, "Contribution is above the maximum limit");

        // Record contribution
        contributions[_contributor] += _amount;

        // Update amountFunded
        amountFunded += _amount;

        emit ContributionReceived(_contributor, _amount);
    }

    // Function to boost the campaign
    function boost(uint256 _amount) external payable {
        require(status() == Status.Active, "You can only boost an active campaign");

        uint256 boostsToPayFor = _amount;
        uint256 freeBoostsLeft = factory.freeBoostsPerNFT() - boosts[msg.sender];

        // Check if the sender has the specific NFT and if they haven't used all their free boosts
        if (factory.NFTContractAddress() != address(0) && IERC721(factory.NFTContractAddress()).balanceOf(msg.sender) > 0 && freeBoostsLeft > 0) {
            // If the user has more free boosts left than they want to use now, they don't have to pay anything
            if (freeBoostsLeft >= _amount) {
                require(msg.value == 0, "No need to send ETH for your boosts");
                boostsToPayFor = 0;
            } else {
                // If the user has some free boosts left but fewer than they want to use now,
                // they only have to pay for the difference
                require(msg.value == factory.boostPrice() * (_amount - freeBoostsLeft), "Incorrect amount of ETH sent");
                boostsToPayFor -= freeBoostsLeft;
            }
        } else {
            require(msg.value == factory.boostPrice() * _amount, "The amount of boosts and ETH sent is incorrect");
        }

        // Record boost
        boosts[msg.sender] += _amount;

        // Transfer boost fee if needed
        if (boostsToPayFor > 0) {
            (bool successFee, ) = payable(factory.feeCollector()).call{value: msg.value }("");
            require(successFee, "Boost fee transfer failed.");
        }

        emit Boosted(msg.sender, _amount);
    }

    // Function for contributors to claim a refund if the campaign is expired or cancelled
    function getRefund() external {
        require(status() == Status.Expired || status() == Status.Canceled, "Refunds are not activated");
        uint256 contributionAmount = contributions[msg.sender];
        require(contributionAmount > 0, "You have not participated");

        // Reset the contribution of the caller
        contributions[msg.sender] = 0;

        // Transfer the contribution back to the contributor
        (bool success, ) = payable(msg.sender).call{value: contributionAmount}("");
        require(success, "Transfer failed.");

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
        require(newOwner != address(0), "Invalid owner address");
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    // Function for the owner to withdraw the funds once the campaign has been funded
    function withdraw() external onlyOwner {
        require(status() == Status.Funded || (status() == Status.Active && amountFunded >= minGoal), "The campaign did not reach the minGoal yet");
        require(address(this).balance > 0, "No funds to withdraw");

        // Mark the funds as withdrawn
        withdrawn = true;

        // Transfer the withdrawal fee to the fee collector
        if (withdrawalFee > 0) {
            uint256 fee = address(this).balance * withdrawalFee / 1000; // Dividing by 1000 because withdrawalFee is per-mille
            (bool successFee, ) = payable(factory.feeCollector()).call{value: fee}("");
            require(successFee, "Fee transfer failed.");
        }
       
        // Transfer the rest of the funds to the owner
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");

        emit Withdrawn(msg.sender, address(this).balance);
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
        } else if (withdrawn || (maxGoal != 0 && amountFunded >= maxGoal) || (block.timestamp >= startDate + duration && amountFunded >= minGoal)) {
            return Status.Funded;
        } else if (block.timestamp < startDate) {
            return Status.Inactive;
        } else if (block.timestamp >= startDate + duration && amountFunded < minGoal) {
            return Status.Expired;
        } else {
            return Status.Active;
        }
    }

    // Function to get the configuration of the campaign
    function getConfig () external view returns (string memory, address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool, bool ) {
        return (name, owner, minGoal, maxGoal, minContribution, maxContribution, duration, startDate, amountFunded, withdrawalFee, withdrawn, canceled ); 
    }


    // --------------------------------------------------------
    // 
    //  Modifiers
    // 
    // --------------------------------------------------------

    // Modifier to restrict access to owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
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

interface IPrefundFactory {
    event CampaignCreated(address campaignAddress);
    event OwnerUpdated(address newOwner);
    event FeeCollectorUpdated(address newFeeCollector);
    event RelativeFeeUpdated(uint256 newRelativeFee);
    event FixedFeeUpdated(uint256 newFixedFee);
    event BoostPriceUpdated(uint256 newBoostPrice);
    event NFTContractAddressUpdated(address newNFTContractAddress);
    event FreeBoostsPerNFTUpdated(uint256 newFreeBoostsPerNFT);

    // Public variables
    function owner() external view returns (address);
    function feeCollector() external view returns (address);
    function relativeFee() external view returns (uint256);
    function fixedFee() external view returns (uint256);
    function boostPrice() external view returns (uint256);
    function NFTContractAddress() external view returns (address);
    function freeBoostsPerNFT() external view returns (uint256);

    // Methods
    function createCampaign(
        string memory name,
        uint256 minGoal,
        uint256 maxGoal,
        uint256 minParticipation,
        uint256 maxParticipation,
        uint256 duration,
        uint256 startDate,
        int256[] memory contributionTierAmounts,
        string[] memory contributionTierRewards
    ) external payable returns (address);

    function transferOwnership(address newOwner) external;

    function updateFeeCollector(address newFeeCollector) external;

    function updateRelativeFee(uint256 newRelativeFee) external;

    function updateFixedFee(uint256 newFixedFee) external;

    function updateBoostPrice(uint256 newBoostPrice) external;

    function updateNFTContractAddress(address newNFTContractAddress) external;

    function updateFreeBoostsPerNFT(uint256 newFreeBoostsPerNFT) external;

    function getConfig()
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint256
        );

    function nbCampaigns() external view returns (uint256);

    function getCampaigns(uint256 page, uint256 limit) external view returns (address[] memory);
}
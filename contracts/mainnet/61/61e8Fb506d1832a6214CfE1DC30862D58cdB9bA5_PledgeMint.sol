/// @notice Pledge Mint v1.2 contract by Culture Cubs
// pledgemint.io
//
// For your ERC721 contract to be compatible, follow the following instructions:
// - declare a variable for the pledgemint contract address:
//   address public pledgeContractAddress;
// - add the following function to allow Pledge Mint to mint NFT for your pledgers:
//   function pledgeMint(address to, uint8 quantity) override
//       external
//       payable {
//       require(pledgeContractAddress == msg.sender, "The caller is not PledgeMint");
//       require(totalSupply() + quantity <= maxCollectionSize, "reached max supply");
//       _mint(to, quantity);
//   }
//
//    * Please ensure you test this method before deploying your contract.
//    * PledgeMint will send the funds collected along with the mint call, minus the fee agreed upon.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./utils/Errors.sol";

interface IERC721Pledge {
    function pledgeMint(address to, uint8 quantity) external payable;
}

contract PledgeMint is Ownable, ReentrancyGuard {
    // Phases allow to have different cohorts of pledgers, with different contracts, prices and limits.
    struct PhaseConfig {
        address admin;
        IERC721Pledge mintContract;
        uint256 mintPrice;
        uint8 maxPerWallet;
        // When locked, the contract on which the mint happens cannot ever be changed again
        bool mintContractLocked;
        // Can only be set to true if mint contract is locked, which is irreversible.
        // Owner of the contract can still trigger refunds - but not access anyone's funds.
        bool pledgesLocked;
        uint16 fee; // int representing the percentage with 2 digits. e.g. 1.75% -> 175
        uint16 cap; // max number of NFTs to sell during this phase
        uint256 startTime;
        uint256 endTime;
    }

    // Mapping from phase Id to array of pledgers
    mapping(uint16 => address[]) public pledgers;
    // Mapping from phase Id to mapping from address to boolean allow value
    mapping(uint16 => mapping(address => bool)) public allowlists;
    // Mapping from phase Id to mapping from address to pladge number
    mapping(uint16 => mapping(address => uint8)) public pledges;

    uint256 public pledgeMintRevenue;

    PhaseConfig[] public phases;

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert Errors.CallerIsContract();
        _;
    }

    modifier onlyAdminOrOwner(uint16 phaseId) {
        if (owner() != _msgSender() && phases[phaseId].admin != _msgSender())
            revert Errors.CallerIsNotOwner();
        _;
    }

    constructor() {}

    function addPhase(
        address admin,
        IERC721Pledge mintContract,
        uint256 mintPrice,
        uint8 maxPerWallet,
        uint16 fee,
        uint16 cap,
        uint startTime,
        uint endTime
    ) external onlyOwner {
        phases.push(
            PhaseConfig(
                admin,
                mintContract,
                mintPrice,
                maxPerWallet,
                false,
                false,
                fee,
                cap,
                startTime,
                endTime
            )
        );
    }

    function allowAddresses(uint16 phaseId, address[] calldata allowlist_)
        external
        onlyAdminOrOwner(phaseId)
    {
        mapping(address => bool) storage _allowlist = allowlists[phaseId];
        for (uint256 i; i < allowlist_.length; ) {
            _allowlist[allowlist_[i]] = true;

            unchecked {
                ++i;
            }
        }
    }

    function pledge(uint16 phaseId, uint8 number)
        external
        payable
        callerIsUser
    {
        PhaseConfig memory phase = phases[phaseId];
        if (block.timestamp < phase.startTime || phase.endTime > 0 && block.timestamp > phase.endTime) revert Errors.PhaseNotActive();
        (uint256 nbPledged, ) = _nbNFTsPledge(phaseId);
        if (phase.cap > 0 && nbPledged + number > phase.cap) revert Errors.OverPhaseCap();
        if (number > phase.maxPerWallet) revert Errors.NFTAmountNotAllowed();
        if (number < 1) revert Errors.AmountNeedsToBeGreaterThanZero();
        if (msg.value != phase.mintPrice * number)
            revert Errors.AmountMismatch();
        if (pledges[phaseId][msg.sender] != 0) revert Errors.AlreadyPledged();
        pledgers[phaseId].push(msg.sender);
        pledges[phaseId][msg.sender] = number;
    }

    function unpledge(uint16 phaseId) external nonReentrant callerIsUser {
        if (phases[phaseId].pledgesLocked == true)
            revert Errors.PledgesAreLocked();

        uint256 nbPledged = pledges[phaseId][msg.sender];
        if (nbPledged < 1) revert Errors.NothingWasPledged();
        pledges[phaseId][msg.sender] = 0;

        (bool success, ) = msg.sender.call{
            value: phases[phaseId].mintPrice * nbPledged
        }("");

        if (!success) revert Errors.UnableToSendValue();
    }

    function lockPhase(uint16 phaseId) external onlyAdminOrOwner(phaseId) {
        if (phases[phaseId].mintContractLocked == false)
            revert Errors.CannotLockPledgeWithoutLockingMint();
        phases[phaseId].pledgesLocked = true;
    }

    function unlockPhase(uint16 phaseId) external onlyAdminOrOwner(phaseId) {
        phases[phaseId].pledgesLocked = false;
    }

    // mint for all participants
    function mintPhase(uint16 phaseId) external onlyAdminOrOwner(phaseId) {
        address[] memory _addresses = pledgers[phaseId];
        _mintPhase(phaseId, _addresses, 0, _addresses.length, false);
    }

    // mint for all participants
    function mintAllPledgesInPhase(uint16 phaseId)
        external
        onlyAdminOrOwner(phaseId)
    {
        address[] memory _addresses = pledgers[phaseId];
        _mintPhase(phaseId, _addresses, 0, _addresses.length, true);
    }

    // mint for all participants, paginated
    function mintPhase(
        uint16 phaseId,
        uint256 startIdx,
        uint256 length
    ) external onlyAdminOrOwner(phaseId) {
        address[] memory _addresses = pledgers[phaseId];
        _mintPhase(phaseId, _addresses, startIdx, length, false);
    }

    // mint for select participants
    // internal function checks eligibility and pledged number.
    function mintPhase(uint16 phaseId, address[] calldata selectPledgers)
        external
        onlyAdminOrOwner(phaseId)
    {
        _mintPhase(phaseId, selectPledgers, 0, selectPledgers.length, false);
    }

    function _mintPhase(
        uint16 phaseId,
        address[] memory addresses,
        uint256 startIdx,
        uint256 count,
        bool allowAllMints
    ) internal {
        PhaseConfig memory _phase = phases[phaseId];
        if (_phase.mintContractLocked == false)
            revert Errors.CannotLaunchMintWithoutLockingContract();
        mapping(address => uint8) storage _pledges = pledges[phaseId];
        mapping(address => bool) storage _allowlist = allowlists[phaseId];
        uint256 phaseRevenue;
        for (uint256 i = startIdx; i < count; ) {
            address addy = addresses[i];
            uint8 quantity = _pledges[addy];

            // Any address not allowed will have to withdraw their pledge manually. We skip them here.
            if ((allowAllMints || _allowlist[addy]) && quantity > 0) {
                _pledges[addy] = 0;
                uint256 totalCost = _phase.mintPrice * quantity;
                uint256 pmRevenue = (totalCost * _phase.fee) / 10000;
                phaseRevenue += pmRevenue;
                _phase.mintContract.pledgeMint{value: totalCost - pmRevenue}(
                    addy,
                    quantity
                );
            }

            unchecked {
                ++i;
            }
        }
        pledgeMintRevenue += phaseRevenue;
    }

    // These stats may decrease in case of refund or mint. They are not itended to archive states.
    function currentPhaseStats(uint16 phaseId)
        public
        view
        returns (
            uint256 nbPledges,
            uint256 nbNFTsPledged,
            uint256 amountPledged,
            uint256 nbAllowedPledges,
            uint256 nbNAllowedFTsPledged,
            uint256 allowedAmountPledged
        )
    {
        PhaseConfig memory _phase = phases[phaseId];
        mapping(address => uint8) storage _pledges = pledges[phaseId];
        mapping(address => bool) storage _allowlist = allowlists[phaseId];
        address[] storage _pledgers = pledgers[phaseId];
        for (uint256 i; i < _pledgers.length; ) {
            address addy = _pledgers[i];
            uint8 quantity = _pledges[addy];
            if (quantity > 0) {
                nbPledges += 1;
                nbNFTsPledged += quantity;
                amountPledged += quantity * _phase.mintPrice;
                if (_allowlist[addy]) {
                    nbAllowedPledges += 1;
                    nbNAllowedFTsPledged += quantity;
                    allowedAmountPledged += quantity * _phase.mintPrice;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function refundPhase(uint16 phaseId)
        external
        onlyAdminOrOwner(phaseId)
        nonReentrant
    {
        _refundPhase(phaseId);
    }

    function refundAll() external onlyOwner nonReentrant {
        for (uint8 i; i < phases.length; ) {
            _refundPhase(i);

            unchecked {
                ++i;
            }
        }
    }

    function refundPhasePledger(uint16 phaseId, address pledger)
        external
        onlyAdminOrOwner(phaseId)
        nonReentrant
    {
        uint256 amount = pledges[phaseId][pledger] * phases[phaseId].mintPrice;
        pledges[phaseId][pledger] = 0;
        (bool success, ) = pledger.call{value: amount}("");
        if (!success) revert Errors.UnableToSendValue();
    }

    function _refundPhase(uint16 phaseId) internal {
        PhaseConfig memory _phase = phases[phaseId];
        address[] storage _addresses = pledgers[phaseId];
        for (uint8 i; i < _addresses.length; ) {
            address addy = _addresses[i];
            uint8 quantity = pledges[phaseId][addy];
            if (quantity > 0) {
                pledges[phaseId][addy] = 0;
                (bool success, ) = addy.call{
                    value: _phase.mintPrice * quantity
                }("");
                if (!success) revert Errors.UnableToSendValue();
            }

            unchecked {
                ++i;
            }
        }
    }

    function _nbNFTsPledge(uint16 phaseId)
        internal
        view
        returns (
            uint256 nbNFTsPledged,
            uint256 nbNAllowedFTsPledged
        )
    {
        mapping(address => uint8) storage _pledges = pledges[phaseId];
        mapping(address => bool) storage _allowlist = allowlists[phaseId];
        address[] storage _pledgers = pledgers[phaseId];
        for (uint256 i; i < _pledgers.length; ) {
            address addy = _pledgers[i];
            uint8 quantity = _pledges[addy];
            if (quantity > 0) {
                nbNFTsPledged += quantity;
                if (_allowlist[addy]) {
                    nbNAllowedFTsPledged += quantity;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function emergencyRefund(
        uint16 phaseId,
        uint256 startIdx,
        uint256 count
    ) external onlyOwner {
        PhaseConfig memory _phase = phases[phaseId];
        for (uint256 i = startIdx; i < count; ) {
            address addy = pledgers[phaseId][i];
            uint8 quantity = pledges[phaseId][addy];

            (bool success, ) = addy.call{value: _phase.mintPrice * quantity}(
                ""
            );
            if (!success) revert Errors.UnableToSendValue();

            unchecked {
                ++i;
            }
        }
    }

    function setMintContract(uint16 phaseId, IERC721Pledge mintContract_)
        external
        onlyAdminOrOwner(phaseId)
    {
        if(phases[phaseId].mintContractLocked == true) revert Errors.ContractCannotBeChanged();
        phases[phaseId].mintContract = mintContract_;
    }

    function setFee(uint16 phaseId, uint16 fee)
        external
        onlyOwner
    {
        phases[phaseId].fee = fee;
    }

    function setStartTime(uint16 phaseId, uint256 startTime)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].startTime = startTime;   
    }

    function setEndTime(uint16 phaseId, uint256 endTime)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].endTime = endTime;   
    }

    function setPrice(uint16 phaseId, uint256 price)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].mintPrice = price;   
    }

    function setCap(uint16 phaseId, uint16 cap)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].cap = cap;   
    }

    function setMaxPerWallet(uint16 phaseId, uint8 maxPerWallet)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].maxPerWallet = maxPerWallet;   
    }

    // there is no unlock function. Once this is locked, funds pledged can only be used to mint on this contract, or refunded.
    function lockMintContract(uint16 phaseId)
        external
        onlyAdminOrOwner(phaseId)
    {
        phases[phaseId].mintContractLocked = true;
    }

    function withdrawRevenue() 
        external
        onlyOwner
    {
        (bool success, ) = msg.sender.call{value: pledgeMintRevenue}("");
        require(success, "Transfer failed.");
        pledgeMintRevenue = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

library Errors {
    // PledgeMint.sol
    error CallerIsContract();
    error CallerIsNotOwner();
    error NFTAmountNotAllowed();
    error PhaseNotActive();
    error OverPhaseCap();
    error AmountNeedsToBeGreaterThanZero();
    error AmountMismatch();
    error AlreadyPledged();
    error PledgesAreLocked();
    error NothingWasPledged();
    error UnableToSendValue();
    error CannotLockPledgeWithoutLockingMint();
    error CannotLaunchMintWithoutLockingContract();
    error ContractCannotBeChanged();
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/IFeeSettings.sol";

/*
    This FeeSettings contract is used to manage fees paid to the tokenize.it platfom
*/
contract FeeSettings is Ownable2Step, ERC165, IFeeSettingsV1 {
    /// @notice Denominator to calculate fees paid in Token.sol. UINT256_MAX means no fees.
    uint256 public tokenFeeDenominator;
    /// @notice Denominator to calculate fees paid in ContinuousFundraising.sol. UINT256_MAX means no fees.
    uint256 public continuousFundraisingFeeDenominator;
    /// @notice Denominator to calculate fees paid in PersonalInvite.sol. UINT256_MAX means no fees.
    uint256 public personalInviteFeeDenominator;
    /// @notice address the fees have to be paid to
    address public feeCollector;
    /// @notice new fee settings that can be activated (after a delay in case of fee increase)
    Fees public proposedFees;

    event SetFeeDenominators(
        uint256 tokenFeeDenominator,
        uint256 continuousFundraisingFeeDenominator,
        uint256 personalInviteFeeDenominator
    );
    event FeeCollectorChanged(address indexed newFeeCollector);
    event ChangeProposed(Fees proposal);

    constructor(Fees memory _fees, address _feeCollector) {
        checkFeeLimits(_fees);
        tokenFeeDenominator = _fees.tokenFeeDenominator;
        continuousFundraisingFeeDenominator = _fees
            .continuousFundraisingFeeDenominator;
        personalInviteFeeDenominator = _fees.personalInviteFeeDenominator;
        require(_feeCollector != address(0), "Fee collector cannot be 0x0");
        feeCollector = _feeCollector;
    }

    function planFeeChange(Fees memory _fees) external onlyOwner {
        checkFeeLimits(_fees);
        // Reducing fees is possible immediately. Increasing fees can only be executed after a minimum of 12 weeks.
        // Beware: reducing fees = increasing the denominator

        // if at least one fee increases, enforce minimum delay
        if (
            _fees.tokenFeeDenominator < tokenFeeDenominator ||
            _fees.continuousFundraisingFeeDenominator <
            continuousFundraisingFeeDenominator ||
            _fees.personalInviteFeeDenominator < personalInviteFeeDenominator
        ) {
            require(
                _fees.time > block.timestamp + 12 weeks,
                "Fee change must be at least 12 weeks in the future"
            );
        }
        proposedFees = _fees;
        emit ChangeProposed(_fees);
    }

    function executeFeeChange() external onlyOwner {
        require(
            block.timestamp >= proposedFees.time,
            "Fee change must be executed after the change time"
        );
        tokenFeeDenominator = proposedFees.tokenFeeDenominator;
        continuousFundraisingFeeDenominator = proposedFees
            .continuousFundraisingFeeDenominator;
        personalInviteFeeDenominator = proposedFees
            .personalInviteFeeDenominator;
        emit SetFeeDenominators(
            tokenFeeDenominator,
            continuousFundraisingFeeDenominator,
            personalInviteFeeDenominator
        );
        delete proposedFees;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "Fee collector cannot be 0x0");
        feeCollector = _feeCollector;
        emit FeeCollectorChanged(_feeCollector);
    }

    function checkFeeLimits(Fees memory _fees) internal pure {
        require(
            _fees.tokenFeeDenominator >= 20,
            "Fee must be equal or less 5% (denominator must be >= 20)"
        );
        require(
            _fees.continuousFundraisingFeeDenominator >= 20,
            "Fee must be equal or less 5% (denominator must be >= 20)"
        );
        require(
            _fees.personalInviteFeeDenominator >= 20,
            "Fee must be equal or less 5% (denominator must be >= 20)"
        );
    }

    /**
    @notice Returns the fee for a given token amount
    @dev will wrongly return 1 if denominator and amount are both uint256 max
     */
    function tokenFee(uint256 _tokenAmount) external view returns (uint256) {
        return _tokenAmount / tokenFeeDenominator;
    }

    /**
    @notice Returns the fee for a given currency amount
    @dev will wrongly return 1 if denominator and amount are both uint256 max
     */
    function continuousFundraisingFee(
        uint256 _currencyAmount
    ) external view returns (uint256) {
        return _currencyAmount / continuousFundraisingFeeDenominator;
    }

    /** 
    @notice Returns the fee for a given currency amount
    @dev will wrongly return 1 if denominator and amount are both uint256 max
     */
    function personalInviteFee(
        uint256 _currencyAmount
    ) external view returns (uint256) {
        return _currencyAmount / personalInviteFeeDenominator;
    }

    /**
     * Specify where the implementation of owner() is located
     */
    function owner()
        public
        view
        override(Ownable, IFeeSettingsV1)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @notice This contract implements the ERC165 interface in order to enable other contracts to query which interfaces this contract implements.
     * @dev See https://eips.ethereum.org/EIPS/eip-165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IFeeSettingsV1) returns (bool) {
        return
            interfaceId == type(IFeeSettingsV1).interfaceId || // we implement IFeeSettingsV1
            ERC165.supportsInterface(interfaceId); // default implementation that enables further querying
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface IFeeSettingsV1 {
    function tokenFee(uint256) external view returns (uint256);

    function continuousFundraisingFee(uint256) external view returns (uint256);

    function personalInviteFee(uint256) external view returns (uint256);

    function feeCollector() external view returns (address);

    function owner() external view returns (address);

    function supportsInterface(bytes4) external view returns (bool); //because we inherit from ERC165
}

struct Fees {
    uint256 tokenFeeDenominator;
    uint256 continuousFundraisingFeeDenominator;
    uint256 personalInviteFeeDenominator;
    uint256 time;
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
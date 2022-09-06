pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IERC4907.sol";
import "./interfaces/IPayment.sol";
import "./payment/NativePayment.sol";
import "./payment/ERC20Payment.sol";

enum RentStatus {
    CREATED,
    ENDED,
    RENT,
    CANCELED
}

struct RentOffer {
    string registryName;
    IERC721 tokenAddress;
    uint256 tokenId;
    address owner;
    uint64 validity;
    bool ownerCreated;
    RentStatus status;
    IPayment paymentOptions;
}

contract Marketplace {
    uint256 internal rentId;
    mapping (uint256 => RentOffer) internal rentOffers;
    IContractRegistry public registry;

    event OwnerCreateRental(address indexed rentTokenAddress, uint256 indexed rentTokenId, uint256 rentId, uint256 deadline);
    event UserAcceptRental(address indexed rentTokenAddress, uint256 indexed rentTokenId);

    event UserOfferRental(address indexed rentTokenAddress, uint256 indexed rentTokenId, uint256 rentId, address user, uint256 deadline);
    event OwnerApprovesRental(address indexed rentTokenAddress, uint256 indexed rentTokenId);

    constructor(IContractRegistry registry_) {
        registry = registry_;
    }

    function getRentOffer(uint256 rentId_) external view returns(RentOffer memory) {
        return rentOffers[rentId_];
    }

    function _assertContractIsValid(address rentTokenAddress_) internal pure {
        require(rentTokenAddress_ != address(0), "Marketplace: Not registered");
        // TODO check supported interfaces
    }

    function _forwardPayment(IPayment paymentOptions_, IContractRegistry.FeeSettings[] memory fees_) internal returns(uint256) {
        if (paymentOptions_.payAddress() == address(0)) {
            return _forwardNative(paymentOptions_.payAmount(), fees_);
        } else {
            return _forwardErc20(IERC20(paymentOptions_.payAddress()), paymentOptions_.payAmount(), fees_);
        }
    }

    function _forwardNative(uint256 paymentAmount_, IContractRegistry.FeeSettings[] memory fees_) internal returns(uint256) {
        require(msg.value == paymentAmount_, "Marketplace: Wrong native amount");
        uint256 feesLen = fees_.length;

        uint256 totalFee = 0;
        for (uint256 i = 0; i < feesLen;) {
            uint256 payAmount = (msg.value * fees_[i].percentage) / 10**18;
            fees_[i].addr.transfer(payAmount);

            unchecked {
                ++i;
                totalFee += payAmount;
            }
        }

        return totalFee;
    }

    function _forwardErc20(IERC20 paymentAddress_, uint256 paymentAmount_, IContractRegistry.FeeSettings[] memory fees_) internal returns(uint256) {
        require(paymentAddress_.allowance(msg.sender, address(this)) >= paymentAmount_, "Marketplace: Missing ERC20 allowance");
        uint256 feesLen = fees_.length;

        uint256 totalFee = 0;
        for (uint256 i = 0; i < feesLen;) {
            uint256 payAmount = (msg.value * fees_[i].percentage) / 10**18;

            require(paymentAddress_.transferFrom(msg.sender, fees_[i].addr, payAmount), "Marketplace: ERC20 transfer failed");
            unchecked {
                ++i;
                totalFee += payAmount;
            }
        }

        return totalFee;
    }

    function _createPaymentInterface(address paymentAddress_, uint256 paymentAmount_, bool rentExtensionAllowed_) internal returns(IPayment) {
        if (paymentAddress_ == address(0)) {
            return new NativePayment(paymentAmount_, rentExtensionAllowed_);
        } else {
            return new ERC20Payment(paymentAddress_, paymentAmount_, rentExtensionAllowed_);
        }
    }

    // *** The first case, OWNER creates rental offer ***
    function ownerCreatesRental(string memory registryTokenName_, uint256 rentTokenId_, uint64 validityTime_, uint256 rentFor_, address paymentAddress_, uint256 paymentAmount_, bool rentExtensionAllowed_) external returns(uint256) {
        IERC721 rentTokenAddress_ = IERC721(registry.getContract(registryTokenName_));
        _assertContractIsValid(address(rentTokenAddress_));
        require(rentTokenAddress_.ownerOf(rentTokenId_) == msg.sender, "Marketplace: USER is not the OWNER");
        uint64 validity = uint64(block.timestamp + validityTime_);

        rentOffers[++rentId] = RentOffer ({
            registryName: registryTokenName_,
            tokenAddress: rentTokenAddress_,
            tokenId: rentTokenId_,
            owner: msg.sender,
            validity: validity,
            ownerCreated: true,
            status: RentStatus.CREATED,
            paymentOptions: _createPaymentInterface(paymentAddress_, paymentAmount_, rentExtensionAllowed_)
        });

        // TODO we shouldn't block token?
        rentTokenAddress_.transferFrom(msg.sender, address(this), rentTokenId_);
        emit OwnerCreateRental(address(rentTokenAddress_), rentTokenId_, rentId, validity);
        return rentId;
    }

    function userAcceptsAvailableRental(uint256 rentId_) external {
        RentOffer memory offer = rentOffers[rentId_];
        require(offer.status == RentStatus.CREATED, "Marketplace: Wrong order status");
        require(block.timestamp <= offer.validity, "Marketplace: Deadline passed");

        offer.status = RentStatus.RENT;

        IERC4907(address(offer.tokenAddress)).setUser(offer.tokenId, msg.sender, offer.validity);
        IContractRegistry.FeeSettings[] memory fees = registry.getFeeFromAddress(IERC4907(address(offer.tokenAddress)));
        uint256 fee = _forwardPayment(offer.paymentOptions, fees);

        rentOffers[rentId_] = offer;
        emit UserAcceptRental(address(offer.tokenAddress), offer.tokenId);
    }

    function ownerFinishesRental(uint256 rentId_) external {
        RentOffer memory offer = rentOffers[rentId_];
        require(offer.status == RentStatus.RENT, "Marketplace: Wrong order status");
        require(offer.tokenAddress.ownerOf(offer.tokenId) == msg.sender, "Marketplace: USER is not the OWNER");

        offer.status = RentStatus.ENDED;
        IERC4907(address(offer.tokenAddress)).setUser(offer.tokenId, msg.sender, offer.validity);

        rentOffers[rentId_] = offer;
    }

    function ownerRemovesRentalOffer(uint256 rentId_) external {
        require(rentId_ < rentId, "Marketplace: Order does not exist");
        RentOffer memory offer = rentOffers[rentId_];
        require(msg.sender == offer.owner && offer.ownerCreated, "Marketplace: User is not an owner");

        offer.status = RentStatus.CANCELED;
        offer.tokenAddress.transferFrom(address(this), offer.owner, offer.tokenId);

        rentOffers[rentId_] = offer;
    }

    // *** The second case, when OWNER haven't created rental yet, but USER can offer renting of particular token. ***
    function userOffersRental(string memory registryTokenName_, uint256 rentTokenId_, uint64 validityTime_, address paymentAddress_, uint256 paymentAmount_, bool rentExtensionAllowed_) external returns(uint256) {
        IERC721 rentTokenAddress_ = IERC721(registry.getContract(registryTokenName_));
        _assertContractIsValid(address(rentTokenAddress_));
        ++rentId;
        uint64 validity = uint64(block.timestamp + validityTime_);

        rentOffers[rentId] = RentOffer ({
            registryName: registryTokenName_,
            tokenAddress: rentTokenAddress_,
            tokenId: rentTokenId_,
            owner: rentTokenAddress_.ownerOf(rentTokenId_),
            validity: validity,
            ownerCreated: false,
            status: RentStatus.CREATED,
            paymentOptions: _createPaymentInterface(paymentAddress_, paymentAmount_, rentExtensionAllowed_)
        });

        emit UserOfferRental(address(rentTokenAddress_), rentTokenId_, rentId, msg.sender, validity);
        return rentId;
    }

    function ownerAcceptUserRentalOffer(uint256 rentId_) external {

    }
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IERC4907.sol";

interface IContractRegistry {
    // Logged when new record is created.
    event NewRecord(string indexed nodeName, address owner, address contractAddr);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(string indexed nodeName, address owner);

    // Logged when the resolver for a node changes.
    event NewAddress(string indexed nodeName, address contractAddr);

    struct FeeSettings {
        uint256 percentage; // it is base 10**18 variable
        address payable addr;
    }

    function setContract(string memory nodeName_, address contractAddr_) external;

    function setOwner(string memory nodeName_, address owner_) external;

    function getOwner(string memory nodeName_) external view returns (address);

    function getContract(string memory nodeName_) external view returns (address);

    function getFeeFromAddress(IERC4907 wrapperAddress_) external view returns(FeeSettings[] memory);

    function getFeeFromName(string memory partnerName_) external view returns(FeeSettings[] memory);

    function recordExists(string memory nodeName_) external view returns (bool);

    function registerRentContract(
        string memory partnerName_,
        string memory nodeName_,
        address owner_,
        IERC4907 contractAddr_,
        IERC721 originalNftAddr_
    ) external;

    function registerAndDeployWrapper(
        string memory partnerName_,
        string memory nodeName_,
        address owner_,
        IERC721 originalNftAddr_,
        string memory name_,
        string memory symbol_
    ) external;

    function originalNftAddr(IERC4907 wrapper_) external view returns(IERC721); // wrapper -> original
    function wrapperNftAddr(IERC721 original_) external view returns(IERC4907); // original -> wrapper
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC4907 {
  // Logged when the user of a token assigns a new user or updates expires
  /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
  /// The zero address for user indicates that there is no user address
  event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

  /// @notice set the user and expires of a NFT
  /// @dev The zero address indicates there is no user
  /// Throws if `tokenId` is not valid NFT
  /// @param user  The new user of the NFT
  /// @param expires  UNIX timestamp, The new user could use the NFT before expires
  function setUser(
    uint256 tokenId,
    address user,
    uint64 expires
  ) external;

  /// @notice Get the user address of an NFT
  /// @dev The zero address indicates that there is no user or the user is expired
  /// @param tokenId The NFT to get the user address for
  /// @return The user address for this NFT
  function userOf(uint256 tokenId) external view returns (address);

  /// @notice Get the user expires of an NFT
  /// @dev The zero value indicates that there is no user
  /// @param tokenId The NFT to get the user expires for
  /// @return The user expires for this NFT
  function userExpires(uint256 tokenId) external view returns (uint256);
}

pragma solidity ^0.8.0;

interface IPayment {
    function payAmount() external returns(uint256);
    function payAddress() external returns(address);
    function rentExtension() external returns(bool);
}

pragma solidity ^0.8.0;

import "./Payment.sol";

contract NativePayment is Payment {
    constructor (uint256 payAmount_, bool rentExtensionAllowed_)
    Payment(address(0), payAmount_, rentExtensionAllowed_)
    {}
}

pragma solidity ^0.8.0;

import "./Payment.sol";

contract ERC20Payment is Payment {
    constructor (address payAddress_, uint256 payAmount_, bool rentExtensionAllowed_)
    Payment(payAddress_, payAmount_, rentExtensionAllowed_)
    {}
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPayment.sol";

contract Payment is IPayment, Ownable {
    uint256 public override payAmount;
    address public override payAddress;
    bool public override rentExtension;

    constructor (address payAddress_, uint256 payAmount_, bool rentExtensionAllowed_) {
        payAddress = payAddress_;
        payAmount = payAmount_;
        rentExtension = rentExtensionAllowed_;
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
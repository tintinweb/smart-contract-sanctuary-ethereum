// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Base.sol";

contract PublicFoundry is BaseFoundry {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../zone/Interface.sol";

import "./appraiser/Interface.sol";
import "./validator/Interface.sol";
import "./guard/Interface.sol";
import "./Interface.sol";

contract BaseFoundry is FoundryInterface {
  using SafeMath for uint256;

  uint256 public constant MAX_ITEMS = 256;

  struct Validator {
    FoundryValidatorInterface instance;
    uint256 id;
  }

  struct Guard {
    FoundryGuardInterface instance;
    uint256 id;
  }

  struct Appraiser {
    FoundryAppraiserInterface instance;
    uint256 id;
  }

  struct Issuance {
    ZoneInterface zone;
    bytes32 parent;
    bool enabled;
    Guard guard;
    Appraiser appraiser;
    address beneficiary;
  }

  Issuance[] public issuances;
  mapping(uint256 => Validator[]) public validators;
  mapping(uint256 => mapping(FoundryValidatorInterface => mapping(uint256 => uint256)))
    public validatorLookup;

  modifier onlyOwnerOfParent(uint256 issuanceId) {
    Issuance memory issuance = issuances[issuanceId];
    require(_isParentOwner(issuance.zone, issuance.parent), "Not the owner.");
    _;
  }

  function _isParentOwner(ZoneInterface zone, bytes32 parent)
    internal
    view
    returns (bool)
  {
    return IERC721(address(zone)).ownerOf(uint256(parent)) == msg.sender;
  }

  function _createIssuance(ZoneInterface zone, bytes32 parent)
    internal
    returns (uint256)
  {
    require(_isParentOwner(zone, parent), "Not the owner.");

    issuances.push(
      Issuance(
        zone,
        parent,
        false,
        Guard(FoundryGuardInterface(address(0)), 0),
        Appraiser(FoundryAppraiserInterface(address(0)), 0),
        address(0)
      )
    );

    uint256 id = issuances.length.sub(1);
    emit IssuanceCreated(id, zone, parent);
    return id;
  }

  function createIssuance(ZoneInterface zone)
    public
    override
    returns (uint256)
  {
    return _createIssuance(zone, zone.getOrigin());
  }

  function createSubIssuance(ZoneInterface zone, bytes32 parent)
    public
    returns (uint256)
  {
    return _createIssuance(zone, parent);
  }

  function enable(uint256 issuanceId)
    public
    override
    onlyOwnerOfParent(issuanceId)
  {
    Issuance storage issuance = issuances[issuanceId];
    issuance.enabled = true;
    emit Enabled(issuanceId);
  }

  function disable(uint256 issuanceId)
    public
    override
    onlyOwnerOfParent(issuanceId)
  {
    Issuance storage issuance = issuances[issuanceId];
    issuance.enabled = false;
    emit Disabled(issuanceId);
  }

  // New function to set the beneficiary
  function setBeneficiary(uint256 issuanceId, address newBeneficiary)
    public
    onlyOwnerOfParent(issuanceId)
  {
    issuances[issuanceId].beneficiary = newBeneficiary;
    emit BeneficiarySet(issuanceId, newBeneficiary);
  }

  function addValidator(
    uint256 issuanceId,
    FoundryValidatorInterface instance,
    uint256 id
  ) public override onlyOwnerOfParent(issuanceId) {
    require(
      validators[issuanceId].length < MAX_ITEMS,
      "Max validators reached."
    );
    validators[issuanceId].push(Validator(instance, id));
    validatorLookup[issuanceId][instance][id] = validators[issuanceId]
      .length
      .sub(1);
    emit ValidatorAdded(issuanceId, instance, id);
  }

  function removeValidator(
    uint256 issuanceId,
    FoundryValidatorInterface instance,
    uint256 id
  ) public override onlyOwnerOfParent(issuanceId) {
    uint256 validatorIndex = validatorLookup[issuanceId][instance][id];
    require(
      validatorIndex < validators[issuanceId].length,
      "Validator does not exist."
    );

    uint256 lastValidatorIndex = validators[issuanceId].length.sub(1);

    // Swap the validator to remove with the last validator in the array
    Validator storage validatorToRemove = validators[issuanceId][
      validatorIndex
    ];
    Validator storage lastValidator = validators[issuanceId][
      lastValidatorIndex
    ];

    validators[issuanceId][validatorIndex] = lastValidator;
    validators[issuanceId][lastValidatorIndex] = validatorToRemove;

    // Update the index of the last validator
    validatorLookup[issuanceId][lastValidator.instance][
      lastValidator.id
    ] = validatorIndex;

    // Remove the last validator from the array
    validators[issuanceId].pop();

    // Remove the validator from the index mapping
    delete validatorLookup[issuanceId][instance][id];

    emit ValidatorRemoved(issuanceId, instance, id);
  }

  function listValidators(uint256 issuanceId)
    public
    view
    returns (Validator[] memory)
  {
    return validators[issuanceId];
  }

  function validate(uint256 issuanceId, string memory label)
    public
    view
    override
    returns (bool)
  {
    Validator[] storage validatorArray = validators[issuanceId];
    for (uint256 i = 0; i < validatorArray.length; i++) {
      if (!validatorArray[i].instance.validate(validatorArray[i].id, label)) {
        return false;
      }
    }
    return true;
  }

  function setGuard(
    uint256 issuanceId,
    FoundryGuardInterface instance,
    uint256 id
  ) public override onlyOwnerOfParent(issuanceId) {
    Issuance storage issuance = issuances[issuanceId];
    issuance.guard = Guard(instance, id);
    emit GuardSet(issuanceId, instance, id);
  }

  function removeGuard(uint256 issuanceId)
    public
    override
    onlyOwnerOfParent(issuanceId)
  {
    Issuance storage issuance = issuances[issuanceId];
    issuance.guard = Guard(FoundryGuardInterface(address(0)), 0);
    emit GuardRemoved(issuanceId);
  }

  function authorize(
    uint256 id,
    address wallet,
    string calldata label,
    bytes calldata credentials
  ) external view override returns (bool) {
    require(id < issuances.length, "Issuance does not exist.");
    Issuance storage issuance = issuances[id];

    if (validate(id, label)) {
      // If a guard is set, check its authorization, otherwise just return true.
      if (issuance.guard.id != 0) {
        return
          issuance.guard.instance.authorize(
            issuance.guard.id,
            wallet,
            label,
            credentials
          );
      }
      return true;
    }
    return false;
  }

  function setAppraiser(
    uint256 issuanceId,
    FoundryAppraiserInterface instance,
    uint256 id
  ) public override onlyOwnerOfParent(issuanceId) {
    Issuance storage issuance = issuances[issuanceId];
    issuance.appraiser = Appraiser(instance, id);
    emit AppraiserSet(issuanceId, instance, id);
  }

  function removeAppraiser(uint256 issuanceId)
    public
    override
    onlyOwnerOfParent(issuanceId)
  {
    Issuance storage issuance = issuances[issuanceId];
    issuance.appraiser = Appraiser(FoundryAppraiserInterface(address(0)), 0);
    emit AppraiserRemoved(issuanceId);
  }

  function appraise(uint256 issuanceId, string memory label)
    public
    view
    returns (uint256, IERC20)
  {
    require(issuanceId < issuances.length, "Issuance does not exist.");
    Issuance storage issuance = issuances[issuanceId];

    // Default return values for when there's no Appraiser set
    uint256 amount = 0;
    IERC20 token = IERC20(address(0));

    if (issuance.appraiser.instance != FoundryAppraiserInterface(address(0))) {
      (amount, token) = issuance.appraiser.instance.appraise(
        issuance.appraiser.id,
        label
      );
    }

    return (amount, token);
  }

  function register(
    address to,
    uint256 issuanceId,
    string memory label,
    bytes memory credentials
  ) public payable override returns (bytes32 namehash) {
    require(issuanceId < issuances.length, "Issuance does not exist.");
    Issuance storage issuance = issuances[issuanceId];
    require(issuances[issuanceId].enabled, "Issuance is not enabled.");

    // check authorization
    require(
      this.authorize(issuanceId, to, label, credentials),
      "Authorization failed."
    );

    // get price and token
    (uint256 price, IERC20 token) = this.appraise(issuanceId, label);

    // Determine the recipient of the tokens
    address recipient = issuance.beneficiary != address(0)
      ? issuance.beneficiary
      : issuance.zone.owner();

    // check the user's balance and allowance then transfer the tokens or native ETH
    if (token == IERC20(address(0))) {
      require(msg.value >= price, "Insufficient balance.");
      (bool success, ) = recipient.call{value: price}("");
      require(success, "Transfer failed.");
    } else {
      require(token.balanceOf(msg.sender) >= price, "Insufficient balance.");
      require(
        token.allowance(msg.sender, address(this)) >= price,
        "Insufficient allowance."
      );
      require(
        token.transferFrom(msg.sender, recipient, price),
        "Transfer failed."
      );
    }

    // register label
    namehash = issuance.zone.register(to, issuance.parent, label);

    // Emit the event
    emit Registered(issuanceId, to, namehash);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ZoneInterface {
  event ZoneCreated(bytes32 indexed origin, string name, string symbol);
  event ResourceRegistered(bytes32 indexed parent, string label);

  function getOrigin() external view returns (bytes32);

  function owner() external view returns (address);

  function exists(bytes32 namehash) external view returns (bool);

  function register(
    address to,
    bytes32 parent,
    string memory label
  ) external returns (bytes32 namehash);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface FoundryAppraiserInterface {
  function appraise(uint256 id, string memory label)
    external
    view
    returns (uint256, IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface FoundryValidatorInterface {
  function validate(uint256 id, string calldata label)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface FoundryGuardInterface {
  function authorize(
    uint256 id,
    address wallet,
    string calldata label,
    bytes calldata credentials
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../zone/Interface.sol";

import "./appraiser/Interface.sol";
import "./validator/Interface.sol";
import "./guard/Interface.sol";

interface FoundryInterface {
  event IssuanceCreated(uint256 id, ZoneInterface zone, bytes32 parent);
  event Enabled(uint256 issuanceId);
  event Disabled(uint256 issuanceId);
  event BeneficiarySet(uint256 indexed issuanceId, address newBeneficiary);

  event ValidatorAdded(
    uint256 indexed issuanceId,
    FoundryValidatorInterface indexed validatorContract,
    uint256 validatorId
  );
  event ValidatorRemoved(
    uint256 indexed issuanceId,
    FoundryValidatorInterface indexed instance,
    uint256 id
  );

  event GuardSet(
    uint256 issuanceId,
    FoundryGuardInterface instance,
    uint256 id
  );
  event GuardRemoved(uint256 issuanceId);

  event AppraiserSet(
    uint256 indexed issuanceId,
    FoundryAppraiserInterface appraiserContract,
    uint256 appriaserId
  );
  event AppraiserRemoved(uint256 indexed issuanceId);

  event Registered(uint256 issuanceId, address indexed to, bytes32 namehash);

  function createIssuance(ZoneInterface zone) external returns (uint256);

  function enable(uint256 issuanceId) external;

  function disable(uint256 issuanceId) external;

  function addValidator(
    uint256 issuanceId,
    FoundryValidatorInterface instance,
    uint256 id
  ) external;

  function removeValidator(
    uint256 issuanceId,
    FoundryValidatorInterface instance,
    uint256 id
  ) external;

  function validate(uint256 issuanceId, string calldata label)
    external
    view
    returns (bool);

  function setGuard(
    uint256 issuanceId,
    FoundryGuardInterface instance,
    uint256 id
  ) external;

  function removeGuard(uint256 issuanceId) external;

  function authorize(
    uint256 id,
    address wallet,
    string calldata label,
    bytes calldata credentials
  ) external view returns (bool);

  function setAppraiser(
    uint256 issuanceId,
    FoundryAppraiserInterface instance,
    uint256 id
  ) external;

  function removeAppraiser(uint256 issuanceId) external;

  function register(
    address to,
    uint256 issuanceId,
    string memory label,
    bytes memory credentials
  ) external payable returns (bytes32 namehash);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}
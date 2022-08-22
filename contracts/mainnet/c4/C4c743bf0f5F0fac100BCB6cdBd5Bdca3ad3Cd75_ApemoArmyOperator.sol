//SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IApemoArmy.sol";
import "./utils/Operatorable.sol";
import "./helpers/DateHelper.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * Apemo Army Avatar Operator Contract V1
 * Provided by Satoshiverse LLC
 */
contract ApemoArmyOperator is Operatorable, ReentrancyGuard {
    IApemoArmy public apemoArmyContract;

    // Payable Address for the Initial Sale
    address payable public svEthAddr =
        payable(0x981268bF660454e24DBEa9020D57C2504a538C57);

    enum AllowLists {
        APELIST,
        CREWMEN_LIST,
        TREVOR_JONES,
        HACKATAO,
        PUBLIC_SALE_LIST
    }
    //Allow List Merkle roots
    mapping(AllowLists => bytes32) public allowListMerkleRoots;

    //Merkle Tree Root for the free claim list
    bytes32 public freeClaimMerkleRoot;

    //Current phase of the drop
    uint256 currentPhase = 0;

    uint16 mintIndex = 1;

    uint16 public apemoArmySold = 0;
    uint256 public trevorTexturesSold = 0;
    uint256 public hackataoTexturesSold = 0;

    uint256 MAX_SUPPLY = 10000;
    uint256 MAX_SUPPLY_SALES = 5000;
    uint256 MAX_SUPPLY_SPECIAL_TEXTURES = 100;

    uint256 publicSalePrice = .1 ether;

    bool public claimState = true;
    bool public purchaseState = true;

    //We can have a address => bool mapping or address => uint8 mapping
    mapping(address => uint8) public claimedAmount;
    mapping(address => bool) public claimedAddresses;

    //Allowlist purchases cannot exceed per-user allotment, which can never exceed 2.
    mapping(AllowLists => mapping(address => uint8)) public allowListPurchases;

    //Functions

    // Set Initial Addresses and Variables Upon Deployment
    constructor(address _operator, address _apemoArmyContract) {
        apemoArmyContract = IApemoArmy(_apemoArmyContract);
        addOperator(_operator);
    }

    // Change the Payment Adddress if Necessary
    function setPaymentAddress(address _svEthAddr) external onlyOwner {
        svEthAddr = payable(_svEthAddr);
    }

    // Sets the merkle root corresponding to the free Claim List
    // Snapshot will be taken on August 23rd, 2022 1:00 PM PST.
    function setFreeClaimMerkleRoot(bytes32 _freeClaimMerkleRoot)
        external
        onlyOperator
    {
        freeClaimMerkleRoot = _freeClaimMerkleRoot;
    }

    //Sets the merkle roots for the allow lists
    function setAllowListMerkleRoot(AllowLists allowList, bytes32 merkleRoot)
        external
        onlyOperator
    {
        allowListMerkleRoots[allowList] = merkleRoot;
    }

    // Operator can toggle the claim mechanism as On / Off
    function toggleClaim() external onlyOperator {
        claimState = !claimState;
    }

    // Operator can toggle the purchasing mechanism as On / Off for the Sale of Apemo Army
    function togglePurchase() external onlyOperator {
        purchaseState = !purchaseState;
    }

    // Claim Apemo Army if you have the allotment. Must be in phase = 4
    //function claim(uint8 claimCount, bytes32[] calldata merkleProof, uint8 phaseOrAllowList)
    function claim(
        uint256 claimCount,
        uint256 allotment,
        bytes32[] calldata merkleProof
    ) external nonReentrant {
        require(claimState, "Claim is disabled");
        require(currentPhase == 4, "Claim period has not yet begun.");
        require(
            !claimedAddresses[msg.sender],
            "You have already claimed your full allotment."
        );

        require(
            claimCount + claimedAmount[msg.sender] <= allotment,
            "Claiming this many would exceed your allotment."
        );
        require(
            MerkleProof.verify(
                merkleProof,
                freeClaimMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, allotment))
            ),
            "Sender address is not on the free claim list"
        );

        if (claimedAmount[msg.sender] + claimCount == allotment) {
            claimedAddresses[msg.sender] = true;
            claimedAmount[msg.sender] = (uint8)(
                claimedAmount[msg.sender] + claimCount
            );
        } else {
            claimedAmount[msg.sender] = (uint8)(
                claimedAmount[msg.sender] + claimCount
            );
        }

        uint256 i = 0;
        uint256 tokenId;

        while (i < claimCount) {
            tokenId = mintIndex;
            mintIndex++;
            apemoArmyContract.operatorMint(msg.sender, tokenId);
            i++;
        }
    }

    // Purchase Apemo Army avatars without discount. Max 10 per transaction.
    function purchase(uint256 count) external payable nonReentrant {
        require(purchaseState, "Purchase is disabled");
        require(count <= 10, "Can only purchase up to 10 per transaction");
        require(
            currentPhase == 3,
            "Public sale has not begun yet or has already ended"
        );
        require(msg.value >= count * publicSalePrice, "Not enough ether");

        require(
            apemoArmySold + count <= MAX_SUPPLY_SALES,
            "No Apemo Army avatars left for public sale"
        );

        uint256 tokenId;
        for (uint256 i = 0; i < count; i++) {
            tokenId = mintIndex;
            mintIndex++;
            apemoArmySold++;
            apemoArmyContract.operatorMint(msg.sender, tokenId);
        }

        (bool sent, ) = svEthAddr.call{value: count * publicSalePrice}("");
        require(sent, "Failed to send Ether");

        if (msg.value > count * publicSalePrice) {
            (sent, ) = payable(msg.sender).call{
                value: msg.value - count * publicSalePrice
            }("");
            require(sent, "Failed to send change back to user");
        }
    }

    //Purchase Apemo Army avatars using your spot in one of the allowlists
    function allowListPurchase(
        uint256 count,
        uint256 allotment,
        AllowLists list,
        bytes32[] calldata merkleProof
    ) external payable nonReentrant {
        require(purchaseState, "Purchase is disabled");
        require(
            allowListPurchases[list][msg.sender] + count <= allotment,
            "Purchasing would exceed allotment."
        );
        require(currentPhase >= 1, "Allowlist sale has not begun yet");
        require(currentPhase < 3, "Allowlist sale has already ended");
        if (list == AllowLists.PUBLIC_SALE_LIST) {
            require(
                currentPhase == 2,
                "Public Allowlist sales cannot be performed at this time"
            );
        } else if (list == AllowLists.TREVOR_JONES) {
            require(
                trevorTexturesSold + count <= MAX_SUPPLY_SPECIAL_TEXTURES,
                "Bitcoin Angel Clothing textures are sold out"
            );
            trevorTexturesSold += count;
        }
        else if (list == AllowLists.HACKATAO) {
            require(
                hackataoTexturesSold + count <= MAX_SUPPLY_SPECIAL_TEXTURES,
                "Hackatao Clothing textures are sold out"
            );
            hackataoTexturesSold += count;
        }

        require(count <= allotment, "Cannot mint more than allotment.");
        uint256 price = publicSalePrice;
        if (list == AllowLists.APELIST) {
            price = (price) / 2;
        } else if (
            list == AllowLists.CREWMEN_LIST ||
            list == AllowLists.TREVOR_JONES ||
            list == AllowLists.HACKATAO
        ) {
            price = (price * 8) / 10;
        }
        require(msg.value >= count * price, "Not enough ether");
        require(
            apemoArmySold + count <= MAX_SUPPLY_SALES,
            "No Apemo Army avatars left for public sale"
        );
        require(
            MerkleProof.verify(
                merkleProof,
                allowListMerkleRoots[list],
                keccak256(abi.encodePacked(msg.sender, allotment))
            ),
            "Sender address is not in that allowlist"
        );

        allowListPurchases[list][msg.sender] += uint8(count);

        uint256 tokenId;
        for (uint256 i = 0; i < count; i++) {
            tokenId = mintIndex;
            mintIndex++;
            apemoArmySold++;
            apemoArmyContract.operatorMint(msg.sender, tokenId);
        }

        (bool sent, ) = svEthAddr.call{value: count * price}("");
        require(sent, "Failed to send Ether");

        if (msg.value > count * price) {
            (sent, ) = payable(msg.sender).call{
                value: msg.value - count * price
            }("");
            require(sent, "Failed to send change back to user");
        }
    }

    // Operator can batch mint and transfer remaining Apemo Army avatars to a secure address
    function safeBatchMintAndTransfer(address holder, uint16 batchSize)
        external
        onlyOperator
    {
        require(
            mintIndex + batchSize <= MAX_SUPPLY + 1,
            "No Apemo Army avatars left for public sale"
        );

        for (uint256 i = mintIndex; i < mintIndex + batchSize; i++) {
            apemoArmyContract.operatorMint(holder, i);
        }

        mintIndex = uint16(mintIndex + batchSize);
    }

    // Owner can decrease the total supply not ever exceeding 10,000 Apemo Army avatars
    function setMaxLimit(uint256 maxLimit) external onlyOwner {
        require(maxLimit < 10001, "Max supply can never exceed 10000");
        MAX_SUPPLY = maxLimit;
    }

    //Sets current phase of the drop
    function setPhase(uint8 _currentPhase) external onlyOperator {
        require(
            _currentPhase <= 5 && _currentPhase >= 0,
            "Phase must be between 0 and 5"
        );
        currentPhase = _currentPhase;
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

//SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.0;

// Interface for the ApemoArmy token
interface IApemoArmy {

  function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

  function operatorMint(address to, uint256 tokenId) external;
}

//SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Operatorable is Ownable, AccessControl {
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  /**
    * @dev Restricted to members of the `operator` role.
    */
  modifier onlyOperator() {
    require(hasRole(OPERATOR_ROLE, msg.sender), "Operatorable: CALLER_NO_OPERATOR_ROLE");
    _;
  }

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(OPERATOR_ROLE, msg.sender);
  }

  /**
    * @dev Add an `_account` to the `operator` role.
    */
  function addOperator(address _account) public onlyOwner {
    grantRole(OPERATOR_ROLE, _account);
  }

  /**
    * @dev Remove an `_account` from the `operator` role.
    */
  function removeOperator(address _account) public onlyOwner {
    revokeRole(OPERATOR_ROLE, _account);
  }

  /**
    * @dev Check if an _account is operator.
    */
  function isOperator(address _account) public view returns (bool) {
    return hasRole(OPERATOR_ROLE, _account);
  }
}

//SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.0;

library DateHelper {
  // function min(uint a, uint b) internal pure returns (uint) {
  //   return a < b ? a : b;
  // }

  function getPhase(uint256 _activeDateTime, uint256 _interval) internal view returns (uint256) {
    unchecked {
      uint256 passedTimeInHours = (block.timestamp - _activeDateTime) / _interval;
      if( passedTimeInHours < 24) {
        return 1;
      } else if( passedTimeInHours < 48 ) {
        return 2;
      } else if( passedTimeInHours < 72 ) {
        return 3;
      } else if( passedTimeInHours < 96 ) {
        return 4;
      } else if( passedTimeInHours < 120 ) {
        return 5;
      } else if( passedTimeInHours < 144 ) {
        return 6;
      } else if( passedTimeInHours < 168 ) {
        return 7;
      } else {
        return 8;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// SPDX-License-Identifier: MIT
/*
Exorians Proxy smart contract:
This smart contract controls all the Cryochamber sale phases as well as the Exorians
reveal.

Legal Overview:

*/

pragma solidity ^0.8.4;

import "./lib/ICryochambers.sol";
import "./lib/IExorians.sol";
import "./lib/IMintpasses.sol";
import "./lib/Structs.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Proxy is AccessControl, Ownable, ReentrancyGuard, Structs {

    IMintpasses public mintpasses;
    ICryochambers public cryochambers;
    IExorians public exorians;
    uint public revealTime;
    uint public adminRevealTime;  // When admin can reveal for users
    uint public timestamp;  // seteable timestamp for debugging;

    Phase[] public salePhases;
    mapping(uint256 => bool) public mintpassUsedIds;
    bool public debug = false;

    event Minted(uint256 quantity, uint256[] tokenIds, uint256 price, address indexed newOwner);
    event Revealed(
        uint256 indexed burnedCryochamberId, uint256 indexed exorianId, address indexed owner
    );

    /// @notice Constructor
    /// @param _mintpassAddress CM21 Mintpass contract address
    /// @param _cryochambersAddress Cryochambers contract address
    /// @param _exoriansAddress Exorians contract address
    /// @param _revealTime When Cryochamber owners can reveal
    /// @param _adminRevealTime When admin can reveal "unrevealed" cryochambers
    /// @param _debug Debug mode (seteable timestamp)
    constructor(
        address _mintpassAddress,
        address _cryochambersAddress,
        address _exoriansAddress,
        uint _revealTime,
        uint _adminRevealTime,
        bool _debug
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        mintpasses = IMintpasses(_mintpassAddress);
        cryochambers = ICryochambers(_cryochambersAddress);
        exorians = IExorians(_exoriansAddress);
        debug = _debug;
        revealTime = _revealTime;
        adminRevealTime = _adminRevealTime;
        // Add empty sale phase (index 0) to determine invalid phase
        salePhases.push();
    }

    /// @notice Add a new sale phase
    /// @param _name Phase name
    /// @param _startTime Start time (epoch seconds)
    /// @param _endTime End time (epoch seconds)
    /// @param _startPrice Start Price in ETH
    /// @param _endPrice End (floor) Price in ETH (0 for fixed price)
    /// @param _maxTokenId Max Cryochamber token ID to sell in this phase (0 if no checking)
    /// @param _intervalMinutes Interval for price decrease in minutes (0 for no decrease)
    /// @param _priceDecrease Price decrease value in ETH (0 for no decrease)
    /// @param _requireMintPass Phase requires mint pass?
    /// @param _maxPerWallet Max tokens per wallet allowed in this phase
    function addSalePhase(
        string memory _name,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _maxTokenId,
        uint8 _intervalMinutes,
        uint256 _priceDecrease,
        bool _requireMintPass,
        uint8 _maxPerWallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_endTime > _startTime, "Invalid time range");
        require(_startPrice > 0, "Invalid start price");
        Phase memory _phase = Phase(
            _name,
            _startTime,
            _endTime,
            _startPrice,
            _endPrice,
            _maxTokenId,
            _intervalMinutes,
            _priceDecrease,
            _requireMintPass,
            _maxPerWallet
        );
        salePhases.push(_phase);
    }

    /// @notice Edit a sale phase
    /// @param _index Sale phase index (>0)
    /// @param _name Phase name
    /// @param _startTime Start time (epoch seconds)
    /// @param _endTime End time (epoch seconds)
    /// @param _startPrice Start Price in ETH
    /// @param _endPrice End (floor) Price in ETH (0 for fixed price)
    /// @param _maxTokenId Max Cryochamber token ID to sell in this phase (0 if no checking)
    /// @param _intervalMinutes Interval for price decrease in minutes (0 for no decrease)
    /// @param _priceDecrease Price decrease value in ETH (0 for no decrease)
    /// @param _requireMintPass Phase requires mint pass?
    /// @param _maxPerWallet Max tokens per wallet allowed in this phase
    function editSalePhase(
        uint8 _index,
        string memory _name,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _maxTokenId,
        uint8 _intervalMinutes,
        uint256 _priceDecrease,
        bool _requireMintPass,
        uint8 _maxPerWallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_index > 0, "Invalid index");
        require(_endTime > _startTime, "Invalid time range");
        require(_startPrice > 0, "Invalid start price");
        Phase memory _phase = Phase(
            _name,
            _startTime,
            _endTime,
            _startPrice,
            _endPrice,
            _maxTokenId,
            _intervalMinutes,
            _priceDecrease,
            _requireMintPass,
            _maxPerWallet
        );
        salePhases[_index] = _phase;
    }

    /// @notice Find out which sale phase is going on right now. Remember that phases start with 1
    ///   phase 0 means not at any sale phase
    function getActiveSalePhase(uint256 _now) public view returns (Phase memory) {
        uint8 _currentPhase = 0;
        // go through all phases
        for (uint8 i = 1; i < salePhases.length; i++) {
            Phase memory _phase = salePhases[i];
            if (_now >= _phase.startTime && _now <= _phase.endTime) {
                _currentPhase = i;
            }
        }

        require(_currentPhase > 0, "Cryochamber minting is not available at the moment");

        return salePhases[_currentPhase];
    }

    /// @notice Calculate price based on current phase
    function getPrice(uint256 _now) public view returns (uint256) {
        uint256 _timeNow = block.timestamp;
        if (debug) _timeNow = _now;
        Phase memory _phase = getActiveSalePhase(_timeNow);
        uint256 _price = _phase.startPrice;

        if (_phase.intervalMinutes > 0 && _phase.priceDecrease > 0 && _phase.endPrice > 0) {
            uint256 calculatePriceDecrease = (
            ((_timeNow - _phase.startTime) / 60) / _phase.intervalMinutes
            ) * _phase.priceDecrease;

            if (calculatePriceDecrease >= _price) {
                _price = _phase.endPrice;
            } else {
                _price = _price - calculatePriceDecrease;
            }
        }

        return _price;
    }


    /// @notice Mint Cryochamber
    /// @param _cm21TokenId Mintpass token id
    /// @param _quantity Quantity
    function mint(uint256 _cm21TokenId, uint256 _quantity) public payable nonReentrant {
        require(_quantity > 0, "Minimum Cryochambers to mint is 1");
        uint256 _timeNow = block.timestamp;
        if (debug) _timeNow = timestamp;
        Phase memory _phase = getActiveSalePhase(_timeNow);

        // Phase requirements
        if (_phase.maxTokenId > 0) {
            require(
                cryochambers.lastTokenId() + _quantity <= _phase.maxTokenId,
                "Max tokens reached for this phase"
            );
        }

        if (_phase.requireMintPass) {
            require(
                mintpasses.balanceOf(msg.sender, _cm21TokenId) > 0,
                "Sender does not own a CM21 Mint Pass (required to get a Cryochamber in this phase)"
            );
            require(
                mintpassUsedIds[_cm21TokenId] == false,
                "The provided CM21 Mint Pass was already used to redeem"
            );
            // Mark mintpass token ID as used:
            mintpassUsedIds[_cm21TokenId] = true;
        }

        if (_phase.maxPerWallet > 0) {
            uint256 _walletCount = cryochambers.walletCount(msg.sender);
            require(
                _walletCount + _quantity <= _phase.maxPerWallet,
                "Max Cryochambers per wallet exceeded"
            );
        }

        // Calculate price
        uint256 _price = getPrice(_timeNow);
        require(msg.value == _price, "ETH sent does not match current Cryochamber price");

        // Mint
        uint256[] memory _mintedIds = cryochambers.mint(msg.sender, _quantity);

        // Send event
        emit Minted(_quantity, _mintedIds, _price, msg.sender);
    }

    /// @notice Reveal Exorian from Cryochamber
    /// @param _cryochamberTokenId Cryochamber token id
    function reveal(uint256 _cryochamberTokenId) public nonReentrant {
        uint256 _timeNow = block.timestamp;
        if (debug) _timeNow = timestamp;
        // Check that reveal is enabled
        require(_timeNow >= revealTime, "It's not reveal time just yet!");
        // Check that sender owns cryochamber
        require(
            cryochambers.balanceOf(msg.sender, _cryochamberTokenId) == 1,
            "Sender does not own a Cryochamber"
        );
        // burn cryochamber
        cryochambers.burn(msg.sender, _cryochamberTokenId, 1);
        // Mint exorian
        uint256 _mintedExorianId = exorians.mint(msg.sender);
        emit Revealed(_cryochamberTokenId, _mintedExorianId, msg.sender);
    }

    /// @notice Reveals Exorian from Cryochamber for a user
    ///     Cryochamber owners have a specific time period  to reveal (e.g. 1 year)
    ///     If they can't/don't reveal, admin will be able to do so after time period
    /// @param _cryochamberTokenId Cryochamber token id
    /// @param _owner Owner address
    function adminReveal(
        uint256 _cryochamberTokenId, address _owner
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _timeNow = block.timestamp;
        if (debug) _timeNow = timestamp;
        // Check that reveal is enabled
        require(_timeNow >= adminRevealTime, "It's not admin reveal time yet");
        // Check that _owner owns cryochamber
        require(
            cryochambers.balanceOf(_owner, _cryochamberTokenId) == 1,
            "Address provided does not own a Cryochamber"
        );
        // burn cryochamber
        cryochambers.burn(_owner, _cryochamberTokenId, 1);
        // Mint exorian
        uint256 _mintedExorianId = exorians.mint(_owner);
        emit Revealed(_cryochamberTokenId, _mintedExorianId, _owner);
    }

    /// @notice Set timestamp only for debugging
    /// @param _timestamp Epoch time in seconds
    function setNow(uint _timestamp) public onlyOwner {
        timestamp = _timestamp;
    }

    /// @notice Edit reveal time
    /// @param _newRevealTime Epoch time in seconds
    function setRevealTime(uint _newRevealTime) public onlyOwner {
        revealTime = _newRevealTime;
    }

    /// @notice Withdraw funds
    /// @param _wallet Address to withdraw funds to
    /// @param _amount ETH amount to withdraw
    function withdrawFunds(address payable _wallet, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(this).balance >= _amount, "Cannot withdraw more than balance");
        _wallet.transfer(_amount);
    }

    /// @notice Interface override
    function supportsInterface(bytes4 _interfaceId) public view virtual override(AccessControl) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Structs {

    // Sale phase
    struct Phase {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        uint256 endPrice;
        uint256 maxTokenId;
        uint8 intervalMinutes;
        uint256 priceDecrease;
        bool requireMintPass;
        uint8 maxPerWallet;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMintpasses {
    function balanceOf(address, uint256) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IExorians {
    function mint(address) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICryochambers {
    function lastTokenId() external returns (uint256);
    function walletCount(address) external returns (uint256);
    function mint(address, uint256) external returns (uint256[] memory);
    function balanceOf(address, uint256) external returns (uint256);
    function burn(address, uint256, uint256) external;
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
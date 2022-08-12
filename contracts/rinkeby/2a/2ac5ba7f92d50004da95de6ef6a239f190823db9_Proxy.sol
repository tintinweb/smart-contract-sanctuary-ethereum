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
import "openzepplin/access/AccessControl.sol";
import "openzepplin/security/ReentrancyGuard.sol";
import "openzepplin/utils/cryptography/MerkleProof.sol";


contract Proxy is AccessControl, ReentrancyGuard, Structs {

    IMintpasses public mintpasses;
    ICryochambers public cryochambers;
    IExorians public exorians;
    uint public revealTime;
    uint public timestamp;  // seteable timestamp for debugging;

    Phase[] public salePhases;
    mapping(uint256 => bool) public mintpassUsedIds;
    bool public debug = false;

    event Minted(
        uint256 quantity, uint256[] tokenIds, uint256[] mintpassIds, uint256 price, address indexed newOwner
    );
    event Revealed(
        uint256 indexed burnedCryochamberId, uint256 indexed exorianId, address indexed owner
    );

    /// @notice Constructor
    /// @param _mintpassAddress CM21 Mintpass contract address
    /// @param _cryochambersAddress Cryochambers contract address
    /// @param _exoriansAddress Exorians contract address
    /// @param _revealTime When Cryochamber owners can reveal
    /// @param _debug Debug mode (seteable timestamp)
    constructor(
        address _mintpassAddress,
        address _cryochambersAddress,
        address _exoriansAddress,
        uint _revealTime,
        bool _debug
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        mintpasses = IMintpasses(_mintpassAddress);
        cryochambers = ICryochambers(_cryochambersAddress);
        exorians = IExorians(_exoriansAddress);
        debug = _debug;
        revealTime = _revealTime;
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
        uint8 _maxPerWallet,
        bytes32 _merkleRoot
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
            _maxPerWallet,
            _merkleRoot
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
        uint8 _maxPerWallet,
        bytes32 _merkleRoot
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
            _maxPerWallet,
            _merkleRoot
        );
        salePhases[_index] = _phase;
    }

    /// @notice Find out which sale phase is going on right now. Remember that phases start with 1
    ///   phase 0 means not at any sale phase
    /// @param _now Epoch timestamp in seconds
    function getActiveSalePhase(uint256 _now) public view returns (Phase memory) {
        uint8 _currentPhase = 0;
        // go through all phases
        for (uint8 i = 1; i < salePhases.length; i++) {
            Phase memory _phase = salePhases[i];
            if (_now >= _phase.startTime && _now < _phase.endTime) {
                _currentPhase = i;
            }
        }

        require(_currentPhase > 0, "Cryochamber minting is not available at the moment");

        return salePhases[_currentPhase];
    }

    /// @notice Calculate price based on current phase
    /// @param _now Epoch timestamp in seconds ONLY FOR DEBUGGING (send 0 in prod, it will ignore)
    function getPrice(uint256 _now) public view returns (uint256) {
        uint256 _timeNow = block.timestamp;
        if (debug) _timeNow = _now;
        Phase memory _phase = getActiveSalePhase(_timeNow);
        uint256 _price = _phase.startPrice;

        if (_phase.intervalMinutes > 0 && _phase.priceDecrease > 0 && _phase.endPrice > 0) {
            uint256 _computedPriceDecrease = (
            ((_timeNow - _phase.startTime) / 60) / _phase.intervalMinutes
            ) * _phase.priceDecrease;
            if (
                (_computedPriceDecrease > _price) ||
                ((_price - _computedPriceDecrease) < _phase.endPrice)
            ) {
                _price = _phase.endPrice;
            } else {
                _price = _price - _computedPriceDecrease;
            }
        }

        return _price;
    }

    /// @notice Mint Cryochamber
    /// @param _cm21tokenIds Mintpass token IDs to redeem. If no mintpass required, send 0 in the array
    ///     per cryochamber desired. E.g. if phase is 1 or 3, and 2 Cryochambers are needed to 
    ///     mint, send [0, 0]
    /// @param _merkleProof Proof to be send in case the phase is about whitelist, to send it null send []
    function mint(uint256[] memory _cm21tokenIds, bytes32[] calldata _merkleProof) public payable nonReentrant {
        uint256 _quantity = _cm21tokenIds.length;
        require(_quantity > 0, "Minimum 1 Cryochamber to mint");
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
            // Private sale. Can mint as many cryochambers as mintpasses they hold
            for (uint256 i = 0; i < _quantity; i++) {
                uint256 _tokenId = _cm21tokenIds[i];
                require(
                    mintpasses.balanceOf(msg.sender, _tokenId) > 0,
                    "Sender does not own a CM21 Mint Pass (required to get a Cryochamber in this phase)"
                );
                require(
                    mintpassUsedIds[_tokenId] == false,
                    "The provided CM21 Mint Pass token ID was already used"
                );
                // Mark mintpass token ID as used:
                mintpassUsedIds[_tokenId] = true;
            }
        } else {
            // Open Sales (Dutch auction & Public sale), capped per wallet OR up to 5 at the same time
            if (_phase.maxPerWallet > 0) {
                uint256 _walletCount = cryochambers.walletCount(msg.sender);
                require(
                    _walletCount + _quantity <= _phase.maxPerWallet,
                    "Max Cryochambers per wallet exceeded"
                );
            } else {
                // It's limitless per wallet, let's cap it per transaction
                require(_quantity <= 5, "Max Cryochambers to mint per transaction is 5");
            }
        }

        if (_phase.merkleRoot != 0) {
            require(walletIsWhitelisted(_merkleProof, msg.sender, _phase.merkleRoot), "Sender is not in whitelist");
        }

        // Calculate price
        // It will accept higher prices just in case the signature comes right before
        // the price decrease cutoff time
        uint256 _price = getPrice(_timeNow) * _quantity;
        require(msg.value >= _price, "ETH sent is less than Cryochamber(s) value");

        // Mint
        uint256[] memory _mintedIds = cryochambers.mint(msg.sender, _quantity);

        // Send event
        emit Minted(_quantity, _mintedIds, _cm21tokenIds, _price, msg.sender);
    }

    /// @notice Reveal Exorian from Cryochamber
    /// @param _cryochamberTokenId Cryochamber token id
    function reveal(uint256 _cryochamberTokenId) public nonReentrant {
        uint256 _timeNow = block.timestamp;
        if (debug) _timeNow = timestamp;
        // Check that reveal is enabled
        require(_timeNow >= revealTime, "It is not reveal time just yet!");
        // Check that sender owns cryochamber
        require(
            cryochambers.balanceOf(msg.sender, _cryochamberTokenId) == 1,
            "Sender does not own the Cryochamber"
        );
        // burn cryochamber
        cryochambers.burn(msg.sender, _cryochamberTokenId);
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
        uint _adminRevealTime = revealTime + (86400 * 365);
        require(_timeNow >= _adminRevealTime, "It is not admin reveal time yet");
        // Check that _owner owns cryochamber
        require(
            cryochambers.balanceOf(_owner, _cryochamberTokenId) == 1,
            "Address provided does not own a Cryochamber"
        );
        // burn cryochamber
        cryochambers.burn(_owner, _cryochamberTokenId);
        // Mint exorian
        uint256 _mintedExorianId = exorians.mint(_owner);
        emit Revealed(_cryochamberTokenId, _mintedExorianId, _owner);
    }

    /// @notice Set timestamp only for debugging
    /// @param _timestamp Epoch time in seconds
    function setNow(uint _timestamp) public onlyRole(DEFAULT_ADMIN_ROLE) {
        timestamp = _timestamp;
    }

    /// @notice Edit reveal time
    /// @param _newRevealTime Epoch time in seconds
    function setRevealTime(uint _newRevealTime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revealTime = _newRevealTime;
    }

    /// @notice Set Cryochamber contract address
    /// @param _address Cryochamber contract address
    function setCryochambersAddress(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        cryochambers = ICryochambers(_address);
    }

    /// @notice Set Exorian contract address
    /// @param _address Exorians contract address
    function setExoriansAddress(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        exorians = IExorians(_address);
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

    /// @notice Checks if address is on whitelist
    /// @param _merkleProof Computed Merkle proof
    /// @param _wallet Wallet address
    /// @param _merkleRoot Merkle root set on phase
    function walletIsWhitelisted(
        bytes32[] calldata _merkleProof, address _wallet, bytes32 _merkleRoot
    ) public pure returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_wallet));
        return MerkleProof.verify(_merkleProof, _merkleRoot, _leaf);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICryochambers {
    function lastTokenId() external returns (uint256);
    function walletCount(address) external returns (uint256);
    function mint(address, uint256) external returns (uint256[] memory);
    function balanceOf(address, uint256) external returns (uint256);
    function burn(address, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IExorians {
    function mint(address) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMintpasses {
    function balanceOf(address, uint256) external returns (uint256);
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
        bytes32 merkleRoot;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
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
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
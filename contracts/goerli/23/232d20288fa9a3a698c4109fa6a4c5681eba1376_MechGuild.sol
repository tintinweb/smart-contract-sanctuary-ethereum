//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IERC1155Upgradeable.sol";

contract MechGuild is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Guild {
        address master;
        address[] members;
        address[] pendingMembers;
        bool isPrivate;
    }

    struct GuildHall {
        uint256 materials;
        uint256 level;
        uint256 completedTime;
    }

    struct User {
        uint256 guildId;
        uint256 lastOutOfGuild;
        uint256 contributionPoint;
    }

    struct EIP712Signature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    bytes32 public constant CREATE_GUILD_WITH_SIG_TYPEHASH =
        keccak256(
            "CreateGuildWithSig(bool isPrivate,uint256 nonce,uint256 deadline)"
        );
    bytes32 public constant JOIN_GUILD_WITH_SIG_TYPEHASH =
        keccak256(
            "JoinGuildWithSig(uint256 guildId,uint256 nonce,uint256 deadline)"
        );

    //settings
    uint256 public guildCount;
    uint256 public penaltyTime;

    uint256 public createMaterialFee;
    address public materialContract;
    uint256 public materialID;

    uint256 public createTokenFee;
    address public tokenContract;
    address public fundingWallet;

    address private signer;

    mapping(uint256 => Guild) public guilds;
    mapping(address => User) public users;
    mapping(address => uint256) public pendingRequests;
    mapping(uint256 => mapping(address => uint256)) public guildContribution;

    uint256 public maxGuildHallLevel;
    mapping(uint256 => GuildHall) public guildHalls;
    mapping(uint256 => uint256[]) public guildHallSettings;

    mapping(address => uint256) public createGuildSigNonces;
    mapping(address => uint256) public joinGuildSigNonces;

    // Events
    event GuildCreated(
        uint256 guildId,
        address guildMaster,
        uint256 sigNonce,
        bool isPrivate
    );

    event GuildMasterChanged(
        uint256 guildId,
        address oldMaster,
        address newMaster
    );

    event RequestToJoin(uint256 guildId, address memberAddress);

    event RequestCanceled(uint256 guildId, address memberAddress);

    event Joined(uint256 guildId, address memberAddress);

    event OutOfGuild(uint256 guildId, address memberAddress);

    event GuildHallContributed(
        uint256 guildId,
        address member,
        uint256 amountMaterial
    );

    event GuildHallUpgraded(
        uint256 guildId,
        uint256 level,
        uint256 compeletedTime
    );

    event GuildAccessChanged(uint256 guildId, bool isPrivate);

    /*
     * Initializer
     */
    function __MechaGuild_init(
        address _materialContract,
        uint256 _materialId,
        address _tokenContract,
        address _fundingWallet,
        address _signer
    ) public initializer {
        __Ownable_init();

        materialContract = _materialContract;
        materialID = _materialId;

        tokenContract = _tokenContract;
        fundingWallet = _fundingWallet;

        signer = _signer;

        penaltyTime = 2 days;
        guildCount = 0;
        createTokenFee = 100 * 1e18;
        createMaterialFee = 50;

        maxGuildHallLevel = 6;
        // guild guildHall setting [max_member, upgrade_time, material_cost]
        guildHallSettings[1] = [15, 0 hours, 50];
        guildHallSettings[2] = [18, 1 hours, 200];
        guildHallSettings[3] = [21, 2 hours, 300];
        guildHallSettings[4] = [24, 3 hours, 500];
        guildHallSettings[5] = [27, 5 hours, 800];
        guildHallSettings[6] = [30, 8 hours, 1300];
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setFundingWallet(address _fundingWallet) external onlyOwner {
        fundingWallet = _fundingWallet;
    }

    function setCreateFee(uint256 _tokenFee, uint256 _materialFee)
        external
        onlyOwner
    {
        createTokenFee = _tokenFee;
        createMaterialFee = _materialFee;
    }

    function setPenaltyTime(uint256 _penaltyTime) external onlyOwner {
        penaltyTime = _penaltyTime;
    }

    function setGuildHallLevelSetting(
        uint256 _level,
        uint256 _maxMember,
        uint256 _upgradeTime,
        uint256 _cost
    ) external onlyOwner {
        if (_level > 1) {
            require(
                _maxMember > guildHallSettings[_level - 1][0],
                "Invalid max member"
            );
        }

        if (_level < maxGuildHallLevel) {
            require(
                _maxMember < guildHallSettings[_level + 1][0],
                "Invalid max member"
            );
        }

        guildHallSettings[_level] = [_maxMember, _upgradeTime, _cost];
    }

    function increaseMaxGuildHallLevel(
        uint256 _maxMember,
        uint256 _upgradeTime,
        uint256 _cost
    ) external onlyOwner {
        uint256[] memory current = guildHallSettings[maxGuildHallLevel];
        require(_maxMember > current[0], "Invalid max member");

        maxGuildHallLevel += 1;
        guildHallSettings[maxGuildHallLevel] = [
            _maxMember,
            _upgradeTime,
            _cost
        ];
    }

    function createGuildWithSig(bool _isPrivate, EIP712Signature memory _sig)
        external
    {
        require(users[msg.sender].guildId == 0, "Already joined other guild");
        require(
            users[msg.sender].lastOutOfGuild + penaltyTime <= block.timestamp,
            "Penalty time is not over"
        );

        require(
            _sig.deadline == 0 || _sig.deadline >= block.timestamp,
            "Signature expired"
        );
        require(
            pendingRequests[msg.sender] == 0,
            "Already have pending request"
        );

        bytes32 domainSeparator = _calculateDomainSeparator();
        uint256 nonce = createGuildSigNonces[msg.sender];
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        CREATE_GUILD_WITH_SIG_TYPEHASH,
                        _isPrivate,
                        createGuildSigNonces[msg.sender]++,
                        _sig.deadline
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, _sig.v, _sig.r, _sig.s);
        require(recoveredAddress == signer, "Invalid signature");

        // Burn guild materials as requirement
        IERC1155Upgradeable material = IERC1155Upgradeable(materialContract);
        material.burn(msg.sender, materialID, createMaterialFee);

        // Transfer fee to funding wallet as requirement
        IERC20Upgradeable token = IERC20Upgradeable(tokenContract);
        token.safeTransferFrom(msg.sender, fundingWallet, createTokenFee);

        // Create guild infomation
        guildCount++;
        guilds[guildCount].isPrivate = _isPrivate;
        guilds[guildCount].master = msg.sender;
        guilds[guildCount].members.push(msg.sender);

        users[msg.sender].guildId = guildCount;

        guildHalls[guildCount].level = 1;

        emit GuildCreated(guildCount, msg.sender, nonce, _isPrivate);
    }

    function joinGuildWithSig(uint256 _guildId, EIP712Signature memory _sig)
        external
    {
        require(
            _sig.deadline == 0 || _sig.deadline >= block.timestamp,
            "Signature expired"
        );
        bytes32 domainSeparator = _calculateDomainSeparator();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        JOIN_GUILD_WITH_SIG_TYPEHASH,
                        _guildId,
                        joinGuildSigNonces[msg.sender]++,
                        _sig.deadline
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, _sig.v, _sig.r, _sig.s);

        require(recoveredAddress == signer, "Invalid signature");
        require(_guildId > 0 && _guildId <= guildCount, "Invalid Guild ID");
        require(users[msg.sender].guildId == 0, "Already joined other guild");
        require(
            pendingRequests[msg.sender] == 0,
            "Already have pending request"
        );
        require(
            users[msg.sender].lastOutOfGuild + penaltyTime <= block.timestamp,
            "Penalty time is not over"
        );

        if (guilds[_guildId].isPrivate) {
            guilds[_guildId].pendingMembers.push(msg.sender);
            pendingRequests[msg.sender] = _guildId;
            emit RequestToJoin(_guildId, msg.sender);
        } else {
            _joinGuild(msg.sender, _guildId);
        }
    }

    function promoteNewMaster(address _newMaster) external {
        uint256 guildId = users[msg.sender].guildId;
        require(guildId > 0, "Not joined any guild");
        require(guilds[guildId].master == msg.sender, "Not guild master");

        require(guildId == users[_newMaster].guildId, "Invalid new master");
        guilds[guildId].master = _newMaster;

        emit GuildMasterChanged(guildId, msg.sender, _newMaster);
    }

    function acceptJoinRequest(address[] memory _members) external {
        uint256 guildId = users[msg.sender].guildId;
        require(guildId > 0, "Not joining any guild yet");
        require(guilds[guildId].master == msg.sender, "Not guild master");

        // Check guild guildHall settings
        uint256[] memory currentHallSetting = _getCurrentHallSetting(guildId);
        uint256 maxMemberSetting = currentHallSetting[0];
        require(
            maxMemberSetting >=
                (guilds[guildId].members.length + _members.length),
            "The maximum number of members has been exceeded"
        );

        // Accept pending members
        for (uint256 i = 0; i < _members.length; i++) {
            _acceptPendingMember(_members[i], guildId);
        }
    }

    function denyJoinRequest(address[] memory _members) external {
        uint256 guildId = users[msg.sender].guildId;
        require(guildId > 0, "Not joining any guild yet");
        require(guilds[guildId].master == msg.sender, "Not guild master");

        // Deny pending members
        for (uint256 i = 0; i < _members.length; i++) {
            _cancelPendingMember(_members[i], guildId);
        }
    }

    function kickMember(address _member) external {
        uint256 guildId = users[_member].guildId;
        require(guildId > 0, "Not joining any guild yet");

        require(guildId == users[msg.sender].guildId, "Not in the same guild");
        require(guilds[guildId].master == msg.sender, "Not guild master");
        require(_member != msg.sender, "Invalid member address");

        _outOfGuild(_member, guildId, false);
    }

    function changeAccessType(bool _isPrivate) external {
        uint256 guildId = users[msg.sender].guildId;
        require(guildId > 0, "Not joining any guild yet");
        Guild storage currentGuild = guilds[guildId];
        require(currentGuild.master == msg.sender, "Not guild master");
        require(
            currentGuild.pendingMembers.length == 0,
            "Either accept or deny all pending requests"
        );

        currentGuild.isPrivate = _isPrivate;
        emit GuildAccessChanged(guildId, _isPrivate);
    }

    function outOfGuild() external {
        uint256 guildId = users[msg.sender].guildId;
        require(guildId > 0, "Not joining any guild yet");
        require(
            guilds[guildId].master != msg.sender,
            "Guild Master cannot leave the guild"
        );
        _outOfGuild(msg.sender, guildId, true);
    }

    function cancelJoinRequest() external {
        require(pendingRequests[msg.sender] > 0, "No pending request");

        _cancelPendingMember(msg.sender, pendingRequests[msg.sender]);
    }

    function contributeGuildBase(uint256 _amount) external {
        uint256 guildId = users[msg.sender].guildId;
        require(guildId > 0, "Not joining any guild yet");

        IERC1155Upgradeable material = IERC1155Upgradeable(materialContract);
        material.burn(msg.sender, materialID, _amount);

        guildHalls[guildId].materials += _amount;
        users[msg.sender].contributionPoint += _amount * 10;
        guildContribution[guildId][msg.sender] += _amount;
        emit GuildHallContributed(guildId, msg.sender, _amount);

        GuildHall storage currentHall = guildHalls[guildId];
        if (currentHall.completedTime >= block.timestamp) {
            return;
        }

        if (currentHall.level >= maxGuildHallLevel) {
            return;
        }
        uint256[] memory nextLevelSetting = guildHallSettings[
            currentHall.level + 1
        ];
        if (currentHall.materials < nextLevelSetting[2]) {
            return;
        }

        currentHall.level++;
        currentHall.completedTime = block.timestamp + nextLevelSetting[1];
        currentHall.materials -= nextLevelSetting[2];

        emit GuildHallUpgraded(
            guildId,
            currentHall.level,
            currentHall.completedTime
        );
    }

    function upgradeBuilding() external {
        uint256 guildId = users[msg.sender].guildId;
        require(guildId > 0, "Not joining any guild yet");

        GuildHall storage currentHall = guildHalls[guildId];
        require(
            currentHall.completedTime < block.timestamp,
            "Time to upgrade is not over yet"
        );
        require(currentHall.level < maxGuildHallLevel, "Maximum level reached");
        uint256[] memory nextLevelSetting = guildHallSettings[
            currentHall.level + 1
        ];
        require(
            currentHall.materials >= nextLevelSetting[2],
            "Insufficient materials"
        );
        currentHall.level++;
        currentHall.completedTime = block.timestamp + nextLevelSetting[1];
        currentHall.materials -= nextLevelSetting[2];
        emit GuildHallUpgraded(
            guildId,
            currentHall.level,
            currentHall.completedTime
        );
    }

    function getMemberOfGuild(uint256 guildId)
        external
        view
        returns (address[] memory)
    {
        return guilds[guildId].members;
    }

    function getPendingMemberOfGuild(uint256 guildId)
        external
        view
        returns (address[] memory)
    {
        return guilds[guildId].pendingMembers;
    }

    function getCurrentBuildingLevel(uint256 guildId)
        public
        view
        returns (uint256)
    {
        if (guildHalls[guildId].completedTime > block.timestamp) {
            return guildHalls[guildId].level - 1;
        }
        return guildHalls[guildId].level;
    }

    function _getCurrentHallSetting(uint256 guildId)
        internal
        view
        returns (uint256[] memory)
    {
        return guildHallSettings[getCurrentBuildingLevel(guildId)];
    }

    function _joinGuild(address member, uint256 guildId) internal {
        require(users[member].guildId == 0, "Already joined other guild");
        uint256[] memory currentHallSettings = _getCurrentHallSetting(guildId);
        uint256 maxMemberSetting = currentHallSettings[0];
        require(
            maxMemberSetting > guilds[guildId].members.length,
            "The maximum number of members has been exceeded"
        );

        guilds[guildId].members.push(member);
        users[member].guildId = guildId;
        users[member].lastOutOfGuild = block.timestamp;
        emit Joined(guildId, member);
    }

    function _acceptPendingMember(address pendingMember, uint256 guildId)
        internal
    {
        address[] memory pendingMembers = guilds[guildId].pendingMembers;
        require(pendingMembers.length > 0, "Invalid pending member");
        require(
            users[pendingMember].guildId == 0,
            "Already joined other guild"
        );

        address[] memory newPendingMembers = new address[](
            pendingMembers.length - 1
        );
        uint256 k = 0;

        for (uint256 i = 0; i < pendingMembers.length; i++) {
            if (pendingMembers[i] != pendingMember) {
                require(k < pendingMembers.length - 1, "Not pending member");
                newPendingMembers[k] = pendingMembers[i];
                k++;
            }
        }

        guilds[guildId].pendingMembers = newPendingMembers;
        delete pendingRequests[pendingMember];
        _joinGuild(pendingMember, guildId);
    }

    function _cancelPendingMember(address pendingMember, uint256 guildId)
        internal
    {
        address[] memory pendingMembers = guilds[guildId].pendingMembers;
        require(pendingMembers.length > 0, "Invalid pending member");

        address[] memory newPendingMembers = new address[](
            pendingMembers.length - 1
        );
        uint256 k = 0;

        for (uint256 i = 0; i < pendingMembers.length; i++) {
            if (pendingMembers[i] != pendingMember) {
                require(k < pendingMembers.length - 1, "Not pending member");
                newPendingMembers[k] = pendingMembers[i];
                k++;
            }
        }

        guilds[guildId].pendingMembers = newPendingMembers;
        delete pendingRequests[pendingMember];
    }

    function _outOfGuild(
        address member,
        uint256 guildId,
        bool isPenalty
    ) internal {
        require(users[member].guildId == guildId, "Invalid member");
        address[] memory members = guilds[guildId].members;
        require(members.length > 1, "Invalid member");

        address[] memory newMembers = new address[](members.length - 1);
        uint256 k = 0;

        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] != member) {
                require(k < members.length - 1, "Not member");
                newMembers[k] = members[i];
                k++;
            }
        }
        guilds[guildId].members = newMembers;
        users[member].guildId = 0;
        guildContribution[guildId][member] = 0;
        if (isPenalty) {
            users[member].lastOutOfGuild = block.timestamp;
        }

        emit OutOfGuild(guildId, member);
    }

    /**
     * @notice Calculates EIP712 DOMAIN_SEPARATOR based on the current contract.
     */
    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,address verifyingContract)"
                    ),
                    keccak256(bytes("MechaGuild")),
                    keccak256(bytes("1")),
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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
interface IERC165Upgradeable {
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
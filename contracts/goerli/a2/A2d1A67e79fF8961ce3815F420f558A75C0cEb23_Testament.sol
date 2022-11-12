// Version de solidity del Smart Contract
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

// Smart Contract Information
// Name: Testament

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol";

// Smart Contract - Testament
contract Testament is Ownable, Pausable {

    // Relation of assets with wallets
    mapping(bytes32 => mapping(address => uint256)) public assetsPercents;

    // true if user will donate its organs
    bool public isDonor;

    // Url of the video to be seen by the heirs
    string public videoUrl;
    string public videoPassword;

    // Death certificate id
    string public deathCertificateId;

    // Notary can update a death certificate and execute the testament
    address public notary;

    bool public isExecuted;

    event Executed();

    event Deceased(
        string deathCertificateId
    );

    event UpdatedVideo(
        string videoUrl,
        string oldVideoUrl
    );

    event UpdatedNotary(
        address notaryAddress,
        address oldNotaryAddress
    );

    event UpdatedIsDonor(
        bool isDonor
    );

    event UpdatedAsset(
        string assetId,
        address heir,
        uint256 newPercent,
        uint256 oldPercent
    );

    function getAssetPercent(string calldata assetId, address heir) public view returns (uint256) {
        return assetsPercents[secureHash(assetId)][heir];
    }

    function registerAsset(string calldata assetId, address heir, uint256 percent) public onlyOwner whenNotPaused {
        require(!isExecuted);
        requireValidString(assetId, 'Invalid asset id');

        bytes32 secureAssetId = secureHash(assetId);

        uint256 oldPercent = assetsPercents[secureAssetId][heir];

        require(oldPercent != percent, 'Percent already set for the heir asset');

        assetsPercents[secureAssetId][heir] = percent;

        emit UpdatedAsset(assetId, heir, percent, oldPercent);
    }

    function setIsDonor(bool _isDonor) public onlyOwner whenNotPaused {
        checkIsNotDeath();
        checkIsNotExecuted();
        require(isDonor != _isDonor, 'Donor value is already set');

        isDonor = _isDonor;

        emit UpdatedIsDonor(isDonor);
    }

    function setVideoUrl(string calldata _videoUrl, string calldata _videoPassword) public onlyOwner whenNotPaused {
        checkIsNotDeath();
        checkIsNotExecuted();
        require(hash(videoUrl) != hash(_videoUrl) && hash(videoPassword) != hash(_videoPassword), 'Url already stored, try a different video url');

        string memory oldVideoUrl = videoUrl;

        videoUrl = _videoUrl;
        videoPassword = _videoPassword;

        emit UpdatedVideo(videoUrl, oldVideoUrl);
    }

    function setNotary(address _notary) public onlyOwner whenNotPaused {
        checkIsNotDeath();
        checkIsNotExecuted();
        require(notary != _notary, 'Notary already stored, try a different notary address');

        address oldNotary = notary;

        notary = _notary;

        emit UpdatedNotary(notary, oldNotary);
    }

    function executeTestament() public whenNotPaused {
        require(msg.sender == notary, 'Not enough permissions to execute the testament');
        checkIsDeath('Death certificate required');
        checkIsNotExecuted();

        isExecuted = true;

        emit Executed();
    }

    function setDeathCertificate(string calldata _deathCertificateId) public whenNotPaused {
        require(msg.sender == notary, 'Not enough permissions to add a death certificate');
        checkIsNotExecuted();
        checkIsDeath('Owner is already death');
        requireValidString(_deathCertificateId, 'Invalid death certificate');

        deathCertificateId = _deathCertificateId;

        // Owner deceased
        renounceOwnership();

        emit Deceased(deathCertificateId);
    }

    function requireValidString(string memory str, string memory errorMessage) private pure {
        require(bytes(str).length > 0, errorMessage);
    }

    function hash(string memory _text) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_text));
    }

    function secureHash(string memory _text) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256(abi.encodePacked(_text))));
    }

    function checkIsNotDeath() private view {
        require(bytes(deathCertificateId).length == 0, 'Testament owner is already death');
    }

    function checkIsDeath(string memory errorMessage) private view {
        requireValidString(deathCertificateId, errorMessage);
    }

    function checkIsNotExecuted() private view {
        require(!isExecuted, 'Testament already executed');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
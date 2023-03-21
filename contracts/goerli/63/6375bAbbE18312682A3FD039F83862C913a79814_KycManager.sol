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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IKycManager {
    enum KycType {
        NON_KYC,
        US_KYC,
        GENERAL_KYC
    }

    struct User {
        KycType kycType;
        bool isBanned;
    }

    function onlyNotBanned(address investor) external view;

    function onlyKyc(address investor) external view;

    function isBanned(address investor) external view returns (bool);

    function isKyc(address investor) external view returns (bool);

    function isUSKyc(address investor) external view returns (bool);

    function isNonUSKyc(address investor) external view returns (bool);

    function isStrict() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IKycManager.sol";

contract KycManager is IKycManager, Ownable {
    event GrantKyc(address investor, KycType kycType);
    event RevokeKyc(address investor, KycType kycType);
    event Banned(address investor);
    event UnBanned(address investor);
    event SetStrict(bool status);

    mapping(address => User) userList;
    bool strictOn;

    /*//////////////////////////////////////////////////////////////
                    OPERATIONS CALLED BY OWNER
    //////////////////////////////////////////////////////////////*/

    function grantKyc(address investor, KycType kycType) external onlyOwner {
        require(
            KycType.US_KYC == kycType || KycType.GENERAL_KYC == kycType,
            "invalid kyc type"
        );

        User storage user = userList[investor];
        user.kycType = kycType;
        emit GrantKyc(investor, kycType);
    }

    function revokeKyc(address investor) external onlyOwner {
        User storage user = userList[investor];
        emit RevokeKyc(investor, user.kycType);

        user.kycType = KycType.NON_KYC;
    }

    function banned(address investor) external onlyOwner {
        User storage user = userList[investor];
        user.isBanned = true;
        emit Banned(investor);
    }

    function unBanned(address investor) external onlyOwner {
        User storage user = userList[investor];
        user.isBanned = false;
        emit UnBanned(investor);
    }

    function setStrict(bool status) external onlyOwner {
        strictOn = status;
        emit SetStrict(status);
    }

    /*//////////////////////////////////////////////////////////////
                            USED BY INTERFACE
    //////////////////////////////////////////////////////////////*/
    function getUserInfo(
        address investor
    ) external view returns (User memory user) {
        user = userList[investor];
    }

    function onlyNotBanned(address investor) external view {
        require(!userList[investor].isBanned, "user is banned");
    }

    function onlyKyc(address investor) external view {
        require(
            KycType.NON_KYC != userList[investor].kycType,
            "not a kyc user"
        );
    }

    function isBanned(address investor) external view returns (bool) {
        return userList[investor].isBanned;
    }

    function isKyc(address investor) external view returns (bool) {
        return KycType.NON_KYC != userList[investor].kycType;
    }

    function isUSKyc(address investor) external view returns (bool) {
        return KycType.US_KYC == userList[investor].kycType;
    }

    function isNonUSKyc(address investor) external view returns (bool) {
        return KycType.GENERAL_KYC == userList[investor].kycType;
    }

    function isStrict() external view returns (bool) {
        return strictOn;
    }
}
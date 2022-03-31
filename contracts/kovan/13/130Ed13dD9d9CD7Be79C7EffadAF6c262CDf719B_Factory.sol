//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMissionFactory.sol";
import "../interfaces/ISubjectFactory.sol";
import "../interfaces/IScholarshipFactory.sol";
import "../interfaces/ITuitionFactory.sol";
import "../interfaces/IFactory.sol";

contract Factory is Ownable, IFactory {
    mapping(Object => address) public object;

    constructor(
        address mission,
        address subject,
        address scholarship,
        address tuition
    ) {
        object[Object.Mission] = mission;
        object[Object.Subject] = subject;
        object[Object.Scholarship] = scholarship;
        object[Object.Tuition] = tuition;
    }

    function setObject(
        address mission,
        address subject,
        address scholarship,
        address tuition
    ) external override {
        require(
            mission != address(0) &&
                subject != address(0) &&
                scholarship != address(0) &&
                tuition != address(0)
        );
        object[Object.Mission] = mission;
        object[Object.Subject] = subject;
        object[Object.Scholarship] = scholarship;
        object[Object.Tuition] = tuition;
    }

    function getObject(Object _object) external view returns (address) {
        return object[_object];
    }

    function createNewMission(address accessControll, address rewardDistributor)
        external
        override
        returns (address)
    {
        return
            IMissionFactory(object[Object.Mission]).createNewMission(
                accessControll,
                rewardDistributor
            );
    }

    function createNewSubject(address accessControll)
        external
        override
        returns (address)
    {
        return
            ISubjectFactory(object[Object.Subject]).createNewMission(
                accessControll
            );
    }

    function createNewScholarship(
        address accessControll,
        address rewardDistributor
    ) external override returns (address) {
        return
            IScholarshipFactory(object[Object.Scholarship])
                .createNewScholarship(accessControll, rewardDistributor);
    }

    function createNewTuition(address accessControll, address rewardDistributor)
        external
        override
        returns (address)
    {
        return
            ITuitionFactory(object[Object.Tuition]).createNewTuition(
                accessControll,
                rewardDistributor
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITuitionFactory {
    function createNewTuition(
        address _accessControll,
        address _rewardDistributor
    ) external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISubjectFactory {
    function createNewMission(address _accessControll)
        external
        returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IScholarshipFactory {
    function createNewScholarship(
        address _accessControll,
        address _rewardDistributor
    ) external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMissionFactory {
    function createNewMission(
        address _accessControll,
        address _rewardDistributor
    ) external returns (address);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IFactory {
    enum Object {
        Mission,
        Subject,
        Scholarship,
        Tuition
    }

    function setObject(
        address mission,
        address subject,
        address scholarship,
        address tuition
    ) external;

    function getObject(Object _object) external view returns (address);

    function createNewMission(address accessControll, address rewardDistributor)
        external
        returns (address);

    function createNewSubject(address accessControll)
        external
        returns (address);

    function createNewScholarship(
        address accessControll,
        address rewardDistributor
    ) external returns (address);

    function createNewTuition(address accessControll, address rewardDistributor)
        external
        returns (address);
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
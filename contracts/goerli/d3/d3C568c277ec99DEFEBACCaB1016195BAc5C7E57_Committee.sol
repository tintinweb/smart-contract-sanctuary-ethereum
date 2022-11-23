// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/ICollectionManager.sol";
import "../commons/OwnableInitializable.sol";



contract Committee is OwnableInitializable {

    mapping(address => bool) public members;

    event MemberSet(address indexed _member, bool _value);

    /**
    * @notice Create the contract
    * @param _owner - owner of the contract
    * @param _members - members to be added at contract creation
    */
    constructor(address _owner, address[] memory _members) {
        // EIP712 init
        // Ownable init
        _initOwnable();
        transferOwnership(_owner);

        for (uint256 i = 0; i < _members.length; i++) {
            _setMember(_members[i], true);
        }
    }

    /**
    * @notice Set members
    * @param _members - members to be added
    * @param _values - whether the members should be added or removed
    */
    function setMembers(address[] calldata _members, bool[] calldata _values) external onlyOwner {
        require(_members.length == _values.length, "Committee#setMembers: LENGTH_MISMATCH");

        for (uint256 i = 0; i < _members.length; i++) {
            _setMember(_members[i], _values[i]);
        }
    }

    /**
    * @notice Set members
    * @param _member - member to be added
    * @param _value - whether the member should be added or removed
    */
    function _setMember(address _member, bool _value) internal {
        members[_member] = _value;

        emit MemberSet(_member, _value);
    }

    /**
    * @notice Manage collection
    * @param _collectionManager - collection manager
    * @param _forwarder - forwarder contract owner of the collection
    * @param _collection - collection to be managed
    * @param _data - array of calls
    */
    function manageCollection(ICollectionManager _collectionManager, address _forwarder, address _collection, bytes[] memory _data) external {
       require(members[_msgSender()], "Committee#manageCollection: UNAUTHORIZED_SENDER");

        for (uint256 i = 0; i < _data.length; i++) {
            _collectionManager.manageCollection(_forwarder, _collection, _data[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface ICollectionManager {
   function manageCollection(address _forwarder, address _collection, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ContextMixin.sol";

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
abstract contract OwnableInitializable is ContextMixin {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initOwnable () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


abstract contract ContextMixin {
    function _msgSender()
        internal
        view
        virtual
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}
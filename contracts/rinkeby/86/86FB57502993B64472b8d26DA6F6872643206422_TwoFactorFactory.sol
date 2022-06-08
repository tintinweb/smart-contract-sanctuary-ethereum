// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./Ownable.sol";

contract CloneFactory {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

interface ITwoFactor {
    function init(address _sender, address _backupWallet, bytes32 _encryptedPassword) external;
}

contract TwoFactorFactory is CloneFactory, Ownable {
    
    address public firstChildAddress;
    bool private isCreationEnabled = true;
    mapping(address => address) public eoaToVaultMap;
    event TwoFactorCreated(address newTwoFactor);
 
    constructor(address _firstChildAddress) {
        require(_firstChildAddress!= address(0), "Address can not be zero");
        firstChildAddress = _firstChildAddress;
    }
    
    function createTwoFactor(address _backupWallet, bytes32 _encryptedPassword) external {
        require(isCreationEnabled == true, "Creating TwoFactor vaults has been disabled for now");
        require(
            eoaToVaultMap[msg.sender] == address(0),
            "Vault already exists for user"
        );
        address clone = createClone(firstChildAddress);
        ITwoFactor(clone).init(msg.sender, _backupWallet, _encryptedPassword);
        eoaToVaultMap[msg.sender] = clone;
        emit TwoFactorCreated(clone);
    }

    function pauseTwoFactorProduction() external onlyOwner{
        require(isCreationEnabled == true, "TwoFactor production is already paused");
        isCreationEnabled = false;
    }

    function resumeTwoFactorProduction() external onlyOwner{
        require(isCreationEnabled == false, "TwoFactor production already going on");
        isCreationEnabled = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/utils/Context.sol";
/** 
 * @dev This contract module is inspired from 
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 * OpenZepplin Ownable contract. The code is forked from Ownable except 
 * 2 functions i.e. renounce and transfer ownership. In our usecase, we do not require users 
 * to transfer or renounce ownership as it is always aligned with the original user.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
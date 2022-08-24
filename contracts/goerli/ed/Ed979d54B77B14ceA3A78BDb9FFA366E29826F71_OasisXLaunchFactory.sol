// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Minimal proxy library
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title OasisX NFT Launch Factory
 * @notice NFT Lauch Factory contract
 * @author OasisX Protocol | cryptoware.eth
 **/

/// @dev an interface to interact with the NFT721 base contract
interface IOasisXNFT721 {
    function initialize(
        bytes memory data,
        address owner_,
        uint256 protocolFee_,
        address protocolAddress_
    ) external;
}

/// @dev an interface to interact with the NFT1155 base contract
interface IOasisXNFT1155 {
    function initialize(
        bytes memory data,
        address owner_,
        uint256 protocolFee_,
        address protocolAddress_
    ) external;
}

interface IOasisXEntry {
    function getMaxId() external returns (uint8);

    function balanceOf(address account, uint256 id) external returns (uint256);

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

}

contract OasisXLaunchFactory is Ownable, ReentrancyGuard {
    /// @notice cheaply clone contract functionality in an immutable way
    using Clones for address;

    /// @notice Base ERC721 address
    address public NFT721Base;

    /// @notice Base ERC1155 address
    address public NFT1155Base;

    /// @notice Address of protocol fee wallet;
    address payable public protocolAddress;

    address public OasisXNFTEntryAddress;

    /// @notice Access fee to charge per clone type
    mapping(uint256 => uint256) public accessFee;

    /// @notice protocol fees from every drop
    uint256 public protocolFee;

    /// @notice Payable clone
    bool public payableEntry;

    /// @notice 721 contracts mapped by owner address
    mapping(address => address[]) public clones721;

    /// @notice 1155 contracts mapped by owner address
    mapping(address => address[]) public clones1155;

    /// @notice Cloning events definition
    event New721Clone
    (
        address indexed _newClone,
        address indexed _owner
    );

    event New1155Clone
    (
        address indexed _newClone,
        address indexed _owner
    );

    event cloneAccessChanged();

    event AccessFeeChanged
    (
        uint256[] indexed cloneTypes,
        uint256[] indexed amount
    );

    event ProtocolFeeChanged
    (
        uint256 indexed protocolFee
    );

    event ProtocolAddressChanged
    (
        address indexed protocol
    );

    event Implementation721Changed
    (
        address indexed Base721
    );

    event Implementation1155Changed
    (
        address indexed Base1155
    );

   event OasisXNFTEntryAddressChanged(address indexed newAddress);

    receive() external payable {
        revert("OasisXNFT721: Please use Mint or Admin calls");
    }

    fallback() external payable {
        revert("OasisXNFT721: Please use Mint or Admin calls");
    }

    /**
     * @notice constructor
     * @param BaseNFT721 address of the Base 721 contract to be cloned
     * @param BaseNFT1155 address of the Base 1155 contract to be cloned
     * @param protocolFee_ fee for the protocol
     * @param _protocolAddress protocol address to collect mint fees
     * @param _OasisXEntry 1155Entry address to access the clone factory

     **/
    constructor(
        address BaseNFT721,
        address BaseNFT1155,
        uint256 protocolFee_,
        address _protocolAddress,
        address _OasisXEntry
    ) {
        require
        (
            BaseNFT721 != address(0),
            "OasisXLaunchFactory: BaseNFT721 address cannot be 0"
        );
        require
        (
   
            BaseNFT1155 != address(0) ,
            "OasisXLaunchFactory: BaseNFT1155 address cannot be 0"
        );
        require
        (

            _protocolAddress != address(0) ,
            "OasisXLaunchFactory: _protocolAddress address cannot be 0"
        );
        require
        (

            _OasisXEntry != address(0),
            "OasisXLaunchFactory: _OasisXEntry address cannot be 0"
        );
        NFT721Base = BaseNFT721;
        NFT1155Base = BaseNFT1155;
        protocolFee = protocolFee_;
        protocolAddress = payable(_protocolAddress);
        OasisXNFTEntryAddress = _OasisXEntry;
    }

    /**
     * @notice initializing the cloned contract
     * @param data Represent the 1155Proxy params encoded
     **/
    function create1155(bytes memory data) external payable nonReentrant {
        require(
            holderAndBurnOrPayable(0, msg.value),
            "OasisXNFT1155 : Not OasisX nft holder or Eth sent mismatch"
        );

        address identicalChild = NFT1155Base.clone();

        clones1155[msg.sender].push(identicalChild);

        IOasisXNFT1155(identicalChild).initialize(
            data,
            msg.sender,
            protocolFee,
            protocolAddress
        );

        emit New1155Clone(identicalChild, msg.sender);
    }

    /**
     * @notice initializing the cloned contract
     * @param data Represent the 721Proxy params encoded
     **/
    function create721(bytes memory data) external payable nonReentrant {
        require(
            holderAndBurnOrPayable(1, msg.value),
            "OasisXNFT721 : Not OasisX nft holder or Eth sent mismatch"
        );

        address identicalChild = NFT721Base.clone();

        clones721[msg.sender].push(identicalChild);

        IOasisXNFT721(identicalChild).initialize(
            data,
            msg.sender,
            protocolFee,
            protocolAddress
        );

        emit New721Clone(identicalChild, msg.sender);
    }

    /**
     * @notice Change clone from OasisXNFTEntry to payable and vis verca
     **/
    function changeCloneAccess() external onlyOwner {
        payableEntry = !payableEntry;
        emit cloneAccessChanged();
    }

    /**
     * @notice assert msg.value equal accessFee or msg.sender hold OasisXNFTEntry and burn
     * @param cloneType type of clone
     * @param amount amount of new access fee
     */
    function holderAndBurnOrPayable(uint256 cloneType, uint256 amount)
        internal
        returns (bool)
    {
        if (payableEntry && amount > 0) {
            if (amount == accessFee[cloneType]) {
                (bool success, ) = protocolAddress.call{
                    value: amount,
                    gas: 2800
                }("");
                return success;
            }
            return false;
        } else if (!payableEntry && amount == 0) {
            uint8 maxEntries = IOasisXEntry(OasisXNFTEntryAddress).getMaxId();

            for (uint256 i = cloneType; i <= maxEntries; i++) {
                if (
                    IOasisXEntry(OasisXNFTEntryAddress).balanceOf(
                        msg.sender,
                        i
                    ) >
                    0 &&
                    cloneType == 0
                ) {
                    return true;
                } else if (
                    IOasisXEntry(OasisXNFTEntryAddress).balanceOf(
                        msg.sender,
                        i
                    ) >
                    0 &&
                    cloneType == 1
                ) {
                    if (i == 1) {
                        
                        IOasisXEntry(OasisXNFTEntryAddress).burn(
                            msg.sender,
                            1,
                            1
                        );
                        return true;
                    } else {
                        return true;
                    }
                }
            }
            return false;
        }
        return false;
    }

    /**
     * @notice change launchpad access fee if payable option
     * @param cloneType clone type wether 721 or 1155
     * @param amount protocol fee
     */
    function changeAccessFee(
        uint256[] memory cloneType,
        uint256[] memory amount
    ) external onlyOwner {
        require(
            cloneType.length == amount.length,
            "OasisXLaunchFactory: New access fee cannot be the same"
        );

        for (uint256 i = 0; i < cloneType.length; i++) {
            accessFee[cloneType[i]] = amount[i];
        }
        emit AccessFeeChanged(cloneType, amount);
    }

    /**
     * @notice Owner can change protocol fee
     * @param amount amount of new protocol fee
     */
    function changeProtocolFee(uint256 amount) external onlyOwner {
        require(
            amount != protocolFee,
            "OasisXLaunchFactory: New Protocol fee cannot be the same"
        );
        protocolFee = amount;
        emit ProtocolFeeChanged(amount);
    }

    /**
     * @notice Owner can change protocol address
     * @param addr address of new protocol
     */
    function changeProtocolAddress(address addr) external onlyOwner {
        require(
            addr != address(0),
            "OasisXLaunchFactory: New Protocol cannot be address 0"
        );
        require(
            addr != protocolAddress,
            "OasisXLaunchFactory: New Protocol cannot be address 0"
        );
        protocolAddress = payable(addr);
        emit ProtocolAddressChanged(addr);
    }

    /**
     * @notice Change 721 Base Contract
     * @param new_add address of new 721 Base contract
     */
    function change721Implementation(address new_add) external onlyOwner {
        require(
            new_add != address(0),
            "OasisXLaunchFactory: New 721 Base cannot be address 0"
        );
        require(
            new_add != NFT721Base,
            "OasisXLaunchFactory: New 721 Base address is the same"
        );
        NFT721Base = new_add;
        emit Implementation721Changed(new_add);
    }

    /**
     * @notice Change 1155 Base Contract
     * @param new_add address of new 1155 Base Contract
     */
    function change1155Implementation(address new_add) external onlyOwner {
        require(
            new_add != address(0),
            "OasisXLaunchFactory: New 1155 Base cannot be address 0"
        );
        require(
            new_add != NFT1155Base,
            "OasisXLaunchFactory: New 1155 Base address cannot be the same"
        );
        NFT1155Base = new_add;
        emit Implementation1155Changed(new_add);
    }

    function changeOasisXNFTEntryAddress(address new_add) external onlyOwner {
        require
        (
            new_add != address(0),
            "OasisXLaunchFactory: Address cannot be 0"
        );

        require
        (
            new_add != OasisXNFTEntryAddress,
            "OasisXLaunchFactory: Address cannot be same as previous"
        );

        OasisXNFTEntryAddress = new_add;
        emit OasisXNFTEntryAddressChanged(new_add);
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
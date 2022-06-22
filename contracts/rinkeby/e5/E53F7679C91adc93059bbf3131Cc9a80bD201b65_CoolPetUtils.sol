// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

interface ICoolPets {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract CoolPetUtils is Ownable {
    // Addresses
    address public _coolPetContractAddress;

    constructor(address coolPetContractAddress) {
        _coolPetContractAddress = coolPetContractAddress;
    }

    /// @notice Helper function to convert uint to string
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /// @notice Helper function to check if an account owns any pets from a selection
    /// @param account Address of account to check against
    /// @param start TokenId to start checking from
    /// @param count Total number of tokens to check from the `start`
    /// @return string String of ids the `account` owns
    function getWalletOfOwnerForSelection(
        address account,
        uint256 start,
        uint256 count
    ) external view returns (string memory) {
        string memory output;

        ICoolPets iface = ICoolPets(_coolPetContractAddress);

        for (uint256 i = start; i < (start + count); i++) {
            try iface.ownerOf(i) returns (address owner) {
                if (owner == account) {
                    output = string(abi.encodePacked(output, uint2str(i), ','));
                }
            } catch {
                // do nothing
            }
        }
        return output;
    }

    /// @notice Helper function to check if submitted cat ids have claimed pets
    /// @dev This function only supports cat ids up to 9998. There are no cats beyond that point
    /// @param catIds Array of cat ids
    /// @return string String of cats ids that have claimed pets
    function getClaimedPetsFromCatIds(uint256[] memory catIds)
        external
        view
        returns (string memory)
    {
        string memory output;

        for (uint256 i; i < catIds.length; i++) {
            if (catIds[i] < 9999) {
                try ICoolPets(_coolPetContractAddress).ownerOf(catIds[i]) {
                    output = string(abi.encodePacked(output, uint2str(catIds[i]), ','));
                } catch {
                    // do nothing
                }
            }
        }
        return output;
    }

    function setCoolPetsContractAddress(address coolPetsContractAddress) external onlyOwner {
        require(coolPetsContractAddress != address(0), 'PU 100 - Invalid address');
        _coolPetContractAddress = coolPetsContractAddress;
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
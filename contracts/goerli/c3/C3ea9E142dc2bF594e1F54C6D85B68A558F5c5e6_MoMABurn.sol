// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FFV2 {
    struct FF2Artwork {
        string title;
        string artistName;
        string fingerprint;
        uint256 editionSize;
    }

    mapping(uint256 => FF2Artwork) public artworks;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {}
}

contract FFV33 {
    struct FF3Artwork {
        string title;
        string artistName;
        string fingerprint;
        uint256 editionSize;
        uint256 AEAmount;
        uint256 PPAmount;
    }
    mapping(uint256 => FF3Artwork) public artworks;

    function mintArtworkEdition(uint256 _artworkID, address _owner) public {}
}

contract MoMABurn is Ownable {
    using SafeMath for uint256;
    address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public burnContractAddress; // Address of token need to burn
    address public tier1ContractAddress; // Address of new token for Tier 1
    address public tier2ContractAddress; // Address of new token for Tier 2
    address public tier3ContractAddress; // Address of new token for Tier 3

    uint256 private burnArtworkID; // Artwork ID will be burned
    uint256 private tier1ArtworkID; // Artwork ID of Tier 1
    uint256 private tier2ArtworkID; // Artwork ID of Tier 2
    uint256 private tier3ArtworkID; // Artwork ID of Tier 3

    bool public isBurnEnabled;

    constructor() {
        isBurnEnabled = false;
    }

    /// @notice setBurnAndMintParams use for update burn and mint contract addresses and artwork IDs
    /// @param _burnContractAddress - new burn contract address
    /// @param _tier1Address - new burn contract address for tier 1
    /// @param _tier2Address - new burn contract address for tier 2
    /// @param _tier3Address - new burn contract address for tier 3
    /// @param _burnArtworkID - artwork ID will be burned
    /// @param _tier1ArtworkID - new artwork ID for tier 1
    /// @param _tier2ArtworkID - new artwork ID for tier 2
    /// @param _tier3ArtworkID - new artwork ID for tier 3
    function setBurnAndMintParams(
        address _burnContractAddress,
        address _tier1Address,
        address _tier2Address,
        address _tier3Address,
        uint256 _burnArtworkID,
        uint256 _tier1ArtworkID,
        uint256 _tier2ArtworkID,
        uint256 _tier3ArtworkID
    ) public onlyOwner {
        require(
            _burnContractAddress != address(0) &&
                _tier1Address != address(0) &&
                _tier2Address != address(0) &&
                _tier3Address != address(0),
            "Invalid contract address"
        );
        (, , string memory burnFingerprint, uint256 burnEditionSize) = FFV2(
            _burnContractAddress
        ).artworks(_burnArtworkID);
        (
            ,
            ,
            string memory tier1Fingerprint,
            uint256 tier1EditionSize,
            ,

        ) = FFV33(_tier1Address).artworks(_tier1ArtworkID);
        (
            ,
            ,
            string memory tier2Fingerprint,
            uint256 tier2EditionSize,
            ,

        ) = FFV33(_tier2Address).artworks(_tier2ArtworkID);
        (
            ,
            ,
            string memory tier3Fingerprint,
            uint256 tier3EditionSize,
            ,

        ) = FFV33(_tier3Address).artworks(_tier3ArtworkID);

        require(
            burnEditionSize > 0 &&
                bytes(burnFingerprint).length != 0 &&
                tier1EditionSize > 0 &&
                bytes(tier1Fingerprint).length != 0 &&
                tier2EditionSize > 0 &&
                bytes(tier2Fingerprint).length != 0 &&
                tier3EditionSize > 0 &&
                bytes(tier3Fingerprint).length != 0,
            "Invalid minting parameters"
        );

        burnContractAddress = _burnContractAddress;
        tier1ContractAddress = _tier1Address;
        tier2ContractAddress = _tier2Address;
        tier3ContractAddress = _tier3Address;
        burnArtworkID = _burnArtworkID;
        tier1ArtworkID = _tier1ArtworkID;
        tier2ArtworkID = _tier2ArtworkID;
        tier3ArtworkID = _tier3ArtworkID;
    }

    /// @notice setBurnEnabled use for update burn enable status
    /// @param _isBurnEnabled - the condition is true or false
    function setBurnEnabled(bool _isBurnEnabled) public onlyOwner {
        isBurnEnabled = _isBurnEnabled;
    }

    /// @notice burnAndMint use for burn old editions and mint new edition
    /// @param _burnedEditions - array of edition IDs to burn
    function burnAndMint(uint256[] memory _burnedEditions) external {
        require(isBurnEnabled, "Burn and mint status is not enabled");

        require(
            _burnedEditions.length == 3 ||
                _burnedEditions.length == 6 ||
                _burnedEditions.length == 9,
            "Invalid number of burning editions"
        );

        (, , , uint256 burnEditionSize) = FFV2(burnContractAddress).artworks(
            burnArtworkID
        );

        for (uint256 i = 0; i < _burnedEditions.length; i++) {
            // Check duplicate with others
            for (uint256 j = i + 1; j < _burnedEditions.length; j++) {
                if (_burnedEditions[i] == _burnedEditions[j]) {
                    revert("Invalid burning editions");
                }
            }

            require(
                burnEditionSize > 0 &&
                    _burnedEditions[i] >= burnArtworkID &&
                    _burnedEditions[i] <= burnArtworkID + burnEditionSize,
                "Edition ID is not support for burning"
            );

            FFV2(burnContractAddress).safeTransferFrom(
                _msgSender(),
                DEAD_ADDRESS,
                _burnedEditions[i]
            );
        }

        address mintContractAddr = tier1ContractAddress;
        uint256 artworkID = tier1ArtworkID;

        if (_burnedEditions.length == 6) {
            mintContractAddr = tier2ContractAddress;
            artworkID = tier2ArtworkID;
        }

        if (_burnedEditions.length == 9) {
            mintContractAddr = tier3ContractAddress;
            artworkID = tier3ArtworkID;
        }

        FFV33(mintContractAddr).mintArtworkEdition(artworkID, _msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
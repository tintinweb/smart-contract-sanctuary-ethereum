// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IHI-PLANET-UTIL.sol";

contract HIPLANET_UTIL is IHI_PLANET_UTIL, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    uint256 internal ether001 = 10**16;
    uint8 constant PUBLIC_INDEX = 0;
    uint8 constant PRESALE_INDEX = 1;
    uint8 constant OG_INDEX = 2;

    MarketConfig public marketConfig;
    Config public config =
        Config({
            revealed: false,
            maxSupply: 3333,
            baseExtension: ".json",
            baseURI: "",
            hiddenURI: "ipfs://QmcXG9QgbBocXuXHA3HukSDGF9aAEi88niNMspwvqRmaNp",
            maxMintAmountPerTx: 10,
            paused: false
        });

    MintPolicy public publicPolicy;
    MintPolicy public presalePolicy;
    MintPolicy public ogsalePolicy;

    function initPolicy() internal {
        publicPolicy.price = ether001.div(10);
        publicPolicy.startTime = 0;
        publicPolicy.endTime = 0;
        publicPolicy.name = "publicM";
        publicPolicy.index = 0;
        publicPolicy.paused = true;

        presalePolicy.price = ether001.div(10);
        presalePolicy.startTime = 0;
        presalePolicy.endTime = 0;
        presalePolicy.name = "presaleM";
        presalePolicy.index = 1;
        presalePolicy.paused = true;
        presalePolicy.maxMintAmountLimit = 5;

        ogsalePolicy.price = 0;
        ogsalePolicy.startTime = 0;
        ogsalePolicy.endTime = 0;
        ogsalePolicy.name = "ogsaleM";
        ogsalePolicy.index = 2;
        ogsalePolicy.paused = true;
        ogsalePolicy.maxMintAmountLimit = 1;
    }

    address internal owner;

    constructor() {
        initPolicy();
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "HI-PLANET: Only owner can call this function"
        );
        _;
    }

    function publicSaleBulkMintDiscount(uint8 _mintAmount, uint256 _price)
        public
        pure
        returns (uint256)
    {
        // if user minted 10 tokens, discount is 20%
        if (_mintAmount == 10) return _price.mul(8).div(10);
        // if user minted more than 5 tokens, discount is 10%
        if (_mintAmount > 4) return _price.mul(9).div(10);
        return _price;
    }

    // 이거는 필수
    function togglePause() public onlyOwner {
        config.paused = !config.paused;
    }

    function togglePresale() public onlyOwner {
        presalePolicy.paused = !presalePolicy.paused;
    }

    function toggleOgsale() public onlyOwner {
        ogsalePolicy.paused = !ogsalePolicy.paused;
    }

    function togglePublicSale() public onlyOwner {
        publicPolicy.paused = !publicPolicy.paused;
    }

    function toggleReveal() public onlyOwner {
        config.revealed = !config.revealed;
    }

    function toggleMarketActicated() public onlyOwner {
        marketConfig.activated = !marketConfig.activated;
    }

    function setPublicsalePolicy(
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        bool _paused
    ) public onlyOwner returns (bool) {
        publicPolicy.price = _price;
        publicPolicy.startTime = _startTime;
        publicPolicy.endTime = _endTime;
        publicPolicy.paused = _paused;
        return true;
    }

    function setPresalePolicy(
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        bool _paused,
        uint8 _maxMintAmountLimit
    ) public onlyOwner returns (bool) {
        presalePolicy.price = _price;
        presalePolicy.startTime = _startTime;
        presalePolicy.endTime = _endTime;
        presalePolicy.paused = _paused;
        presalePolicy.maxMintAmountLimit = _maxMintAmountLimit;
        return true;
    }

    function setOgsalePolicy(
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        bool _paused,
        uint8 _maxMintAmountLimit
    ) public onlyOwner returns (bool) {
        ogsalePolicy.price = _price;
        ogsalePolicy.startTime = _startTime;
        ogsalePolicy.endTime = _endTime;
        ogsalePolicy.paused = _paused;
        ogsalePolicy.maxMintAmountLimit = _maxMintAmountLimit;
        return true;
    }

    function setMaxMintAmountPerTx(uint8 _maxMintAmountPerTx) public onlyOwner {
        config.maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxSupply(uint16 _maxSupply) public onlyOwner {
        config.maxSupply = _maxSupply;
    }

    function setWlMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        presalePolicy.merkleRoot = _merkleRoot;
    }

    function setOgMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        ogsalePolicy.merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        config.baseURI = _tokenBaseURI;
    }

    function setMintTime(
        uint8 _policyIndex,
        uint256 _mintStart,
        uint256 _mintEnd
    ) public onlyOwner {
        require(_policyIndex < 3, "HMI: Invalid index");
        // PUBLIC_INDEX || 0
        // PRESALE_INDEX || 1
        // OG_INDEX || 2
        unchecked {
            if (_policyIndex == PUBLIC_INDEX) {
                publicPolicy.startTime = _mintStart;
                publicPolicy.endTime = _mintEnd;
                return;
            } else if (_policyIndex == PRESALE_INDEX) {
                presalePolicy.startTime = _mintStart;
                presalePolicy.endTime = _mintEnd;
                return;
            } else if (_policyIndex == OG_INDEX) {
                ogsalePolicy.startTime = _mintStart;
                ogsalePolicy.endTime = _mintEnd;
                return;
            }
        }
    }

    function setMarketActivatedTime(uint256 _activatedTime) public onlyOwner {
        marketConfig.activatedTime = _activatedTime;
    }

    function getCurBlock() public view returns (uint256) {
        return block.timestamp;
    }

    function getMintTimeDiff(uint8 _policyIndex)
        public
        view
        returns (uint256, uint256)
    {
        require(_policyIndex < 3, "HMI: Invalid index");
        uint256 startGap = 0;
        uint256 endGap = 0;
        bool success;
        uint256 _now = block.timestamp;

        if (_policyIndex == PUBLIC_INDEX) {
            (success, startGap) = (publicPolicy.startTime).trySub(_now);
            (success, endGap) = (publicPolicy.endTime).trySub(_now);
        } else if (_policyIndex == PRESALE_INDEX) {
            (success, startGap) = (presalePolicy.startTime).trySub(_now);
            (success, endGap) = (presalePolicy.endTime).trySub(_now);
        } else if (_policyIndex == OG_INDEX) {
            (success, startGap) = (ogsalePolicy.startTime).trySub(_now);
            (success, endGap) = (ogsalePolicy.endTime).trySub(_now);
        }

        return (startGap, endGap);
    }

    function getSecMarketDiff() external view returns (uint256) {
        (bool _bool, uint256 _gap) = (marketConfig.activatedTime).trySub(
            block.timestamp
        );
        _bool;
        return _gap;
    }

    function getTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _tokenURI,
                    "/",
                    _tokenId.toString(),
                    config.baseExtension
                )
            );
    }

    function getConfig() external view returns (Config memory) {
        return config;
    }

    function getPublicPolicy() external view returns (MintPolicy memory) {
        return publicPolicy;
    }

    function getPresalePolicy() external view returns (MintPolicy memory) {
        return presalePolicy;
    }

    function getOgsalePolicy() external view returns (MintPolicy memory) {
        return ogsalePolicy;
    }

    function getMarketConfig() external view returns (MarketConfig memory) {
        return marketConfig;
    }

    function getAddress() external view returns (address) {
        return address(this);
    }

    function getMaxSupply() external view returns (uint16) {
        return config.maxSupply;
    }

    function paused() external view returns (bool) {
        return config.paused;
    }

    function publicM() external view returns (bool) {
        return publicPolicy.paused;
    }

    function presaleM() external view returns (bool) {
        return presalePolicy.paused;
    }

    function ogsaleM() external view returns (bool) {
        return ogsalePolicy.paused;
    }

    function price() external view returns (uint256) {
        return publicPolicy.price;
    }

    function wlPrice() external view returns (uint256) {
        return presalePolicy.price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IHI-PLANET.sol";

/**
 * @dev Interface of HI-PLANET.
 */
interface IHI_PLANET_UTIL is IHIPLANET {
    /// @notice fnuction which calculate the total nft price by the mint amoint
    function publicSaleBulkMintDiscount(uint8 _mintAmount, uint256 _price)
        external
        pure
        returns (uint256);

    /// @notice fnuction which set max mint amount per tx
    function setMaxMintAmountPerTx(uint8 _maxMintAmountPerTx) external;

    /// @notice fnuction which set maxSupply
    function setMaxSupply(uint16 _maxSupply) external;

    /// @notice fnuction which toggle the paused state of the NFT contract
    function togglePause() external;

    /// @notice fnuction which set the presale paused state of the NFT contract
    function togglePresale() external;

    /// @notice fnuction which set the ogsale paused state of the NFT contract
    function toggleOgsale() external;

    /// @notice fnuction which set the publicsale start time of the NFT contract
    function togglePublicSale() external;

    /// @notice fnuction which toggle the state of token uri revealed
    function toggleReveal() external;

    /// @notice fnuction which set the wl merkle root of the NFT contract
    function setWlMerkleRoot(bytes32 _merkleRoot) external;

    /// @notice fnuction which set the og merkle root of the NFT contract
    function setOgMerkleRoot(bytes32 _merkleRoot) external;

    /// @notice fnuction which set base token uri of the NFT contract
    function setBaseURI(string memory _tokenBaseURI) external;

    /**
     *  @notice fnuction which set mint begin time and end time of the NFT contract
     *  in publicPolicy, presalePolicy, ogsalePolicy
     */
    function setMintTime(
        uint8 _policyIndex,
        uint256 _mintStart,
        uint256 _mintEnd
    ) external;

    /// @notice fnuction which toggle opensea or magic eden market activation
    function toggleMarketActicated() external;

    /// @notice fnuction which set opensea or magic eden market activation time
    function setMarketActivatedTime(uint256 _activatedTime) external;

    /// @notice fnuction which get current block number
    function getCurBlock() external view returns (uint256);

    /**
     *  @notice fnuction which get difference between
     *  current block number and the block number of the activated time
     */
    function getMintTimeDiff(uint8 _policyIndex)
        external
        view
        returns (uint256, uint256);

    /** @notice fnuction which get difference between current block number
     *   and the block number of the secondary market(opensea or magic eden) activated time
     */
    function getSecMarketDiff() external view returns (uint256);

    /**
     * @notice used in NFT contract for getting complete uri of the token
     * by combining base uri and token id
     */
    function getTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        view
        returns (string memory);

    function getConfig() external view returns (Config memory);

    function getPublicPolicy() external view returns (MintPolicy memory);

    function getPresalePolicy() external view returns (MintPolicy memory);

    function getOgsalePolicy() external view returns (MintPolicy memory);

    function getMarketConfig() external view returns (MarketConfig memory);

    function getAddress() external view returns (address);
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
pragma solidity ^0.8.15;

/**
 * @dev Interface of HI-PLANET.
 */
interface IHIPLANET {
    struct MintPolicy {
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        string name;
        uint8 index;
        bool paused;
        bytes32 merkleRoot;
        uint8 maxMintAmountLimit;
    }
    // mapping(address => uint256) claimed;

    struct Config {
        bool revealed;
        uint16 maxSupply;
        string baseExtension;
        string baseURI;
        string hiddenURI;
        uint8 maxMintAmountPerTx;
        bool paused;
    }
    struct MarketConfig {
        bool activated;
        uint256 activatedTime;
    }
}
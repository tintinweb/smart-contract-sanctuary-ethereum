pragma solidity ^0.5.0;

import './libs/0.5.x/SafeMath.sol';
import './interfaces/0.5.x/IGenArt721CoreV2.sol';

contract GenArt721Minter_DoodleLabs_Whitelist {
    using SafeMath for uint256;

    event AddMinterWhitelist(address minterAddress);
    event RemoveMinterWhitelist(address minterAddress);
    event SetMerkleRoot(uint256 indexed projectId, bytes32 indexed merkleRoot);

    IGenArt721CoreV2 genArtCoreContract;
    mapping(address => bool) public minterWhitelist;
    mapping(uint256 => mapping(address => uint256)) public whitelist;
    mapping(uint256 => bytes32) private _merkleRoot;

    modifier onlyWhitelisted() {
        require(genArtCoreContract.isWhitelisted(msg.sender), 'can only be set by admin');
        _;
    }

    modifier onlyMintWhitelisted() {
        require(minterWhitelist[msg.sender], 'only callable by minter');
        _;
    }

    constructor(address _genArtCore, address _minterAddress) public {
        genArtCoreContract = IGenArt721CoreV2(_genArtCore);
        minterWhitelist[_minterAddress] = true;
    }

    function getMerkleRoot(uint256 projectId) external view returns (bytes32 merkleRoot) {
        return _merkleRoot[projectId];
    }

    function setMerkleRoot(uint256 projectId, bytes32 merkleRoot) public onlyWhitelisted {
        _merkleRoot[projectId] = merkleRoot;
        emit SetMerkleRoot(projectId, merkleRoot);
    }

    function addMinterWhitelist(address _minterAddress) public onlyWhitelisted {
        minterWhitelist[_minterAddress] = true;
        emit AddMinterWhitelist(_minterAddress);
    }

    function removeMinterWhitelist(address _minterAddress) public onlyWhitelisted {
        minterWhitelist[_minterAddress] = false;
        emit RemoveMinterWhitelist(_minterAddress);
    }

    function getWhitelisted(uint256 projectId, address user)
        external
        view
        returns (uint256 amount)
    {
        return whitelist[projectId][user];
    }

    function increaseAmount(
        uint256 projectId,
        address to,
        uint256 quantity
    ) public onlyMintWhitelisted {
        whitelist[projectId][to] = whitelist[projectId][to].add(quantity);
    }
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.4.0/contracts/math/SafeMath.sol
pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

interface IGenArt721CoreV2 {
    function isWhitelisted(address sender) external view returns (bool);

    function admin() external view returns (address);

    function projectIdToCurrencySymbol(uint256 _projectId) external view returns (string memory);

    function projectIdToCurrencyAddress(uint256 _projectId) external view returns (address);

    function projectIdToArtistAddress(uint256 _projectId) external view returns (address payable);

    function projectIdToPricePerTokenInWei(uint256 _projectId) external view returns (uint256);

    function projectIdToAdditionalPayee(uint256 _projectId) external view returns (address payable);

    function projectIdToAdditionalPayeePercentage(uint256 _projectId)
        external
        view
        returns (uint256);

    function projectTokenInfo(uint256 _projectId)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            bool,
            address,
            uint256,
            string memory,
            address
        );

    function renderProviderAddress() external view returns (address payable);

    function renderProviderPercentage() external view returns (uint256);

    function mint(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenIdToProjectId(uint256 tokenId) external view returns (uint256);
}
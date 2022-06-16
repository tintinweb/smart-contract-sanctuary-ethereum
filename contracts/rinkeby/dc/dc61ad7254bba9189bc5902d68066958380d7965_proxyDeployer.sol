/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

interface ITyeNFTTemplate {
    function createCollection(
        string memory _name,
        string memory _symbol,
        address _Address
    ) external returns (address);
}

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract proxyDeployer is Owned {
    using SafeMath for uint256;
    event DeployedAddress(address indexed deployesAddress);
    struct CollectionDetails {
        address collectionAddress;
        string name;
        string symbol;
        uint256 startDate;
        uint256 endDate;
        uint256 price;
        uint256 whiteprice;
        uint256 totalQTY;
        uint256 maxNFT;
        uint256 maxWhiteNFT;
        string Currency;
        address tokenAddress;
        address feeCollectorAddress;
    }
    address[] collectionAddressList; // All Collection Address
    mapping(address => CollectionDetails) private collectionsList; //Stored Collection Details
    address deployedAddress; // NFT Template Address

    function setdeployerAddress(address _deployerAddress) public onlyOwner {
        deployedAddress = _deployerAddress;
    }

    function deployerFunction(
        string[] memory otherdatas,
        uint256[] calldata data,
        address[] memory _Address
    ) public onlyOwner {
        address _collectionAddress = ITyeNFTTemplate(deployedAddress)
            .createCollection(otherdatas[0], otherdatas[1], _Address[0]); // otherdatas[1] - name, otherdatas[2] - symbol, _Address[0] - Collection OwnerAddress(FeeCollector)
        CollectionDetails memory _CollectionDetails;
        _CollectionDetails.collectionAddress = _collectionAddress; // New Collection Address
        _CollectionDetails.name = otherdatas[0]; //name
        _CollectionDetails.symbol = otherdatas[1]; //Symbol
        _CollectionDetails.Currency = otherdatas[2]; //Coin ot Token
        _CollectionDetails.startDate = block.timestamp.add(data[0].mul(1 days));
        _CollectionDetails.endDate = block.timestamp.add(data[1].mul(1 days));
        _CollectionDetails.price = data[2]; // Stantard NFT Price
        _CollectionDetails.whiteprice = data[3]; // WhiteList address NFT Price
        _CollectionDetails.totalQTY = data[4]; // NFT Total Supply
        _CollectionDetails.maxNFT = data[5]; //How many NFT mint per Address
        _CollectionDetails.maxWhiteNFT = data[6]; //How many NFT mint per WhiteList Address
        _CollectionDetails.feeCollectorAddress = _Address[0]; // Fee Collector Address
        _CollectionDetails.tokenAddress = _Address[1]; // ERC20 Token Address
        collectionsList[_collectionAddress] = _CollectionDetails;
        collectionAddressList.push(_collectionAddress);
        emit DeployedAddress(_collectionAddress);
    }

    function getTemplateAddress() public view returns (address) {
        return deployedAddress;
    }

    function getAllCollectionAddress() public view returns (address[] memory) {
        return collectionAddressList;
    }

    function getCollectionDetails(address _collectionAddress)
        public
        view
        returns (CollectionDetails memory)
    {
        return collectionsList[_collectionAddress];
    }

    function editCollections(
        address _collectionAddress,
        uint256[] calldata editdata,
        address[] memory _Address
    ) public onlyOwner {
        collectionsList[_collectionAddress].startDate = editdata[0];
        collectionsList[_collectionAddress].endDate = editdata[1];
        collectionsList[_collectionAddress].price = editdata[2];
        collectionsList[_collectionAddress].whiteprice = editdata[3];
        collectionsList[_collectionAddress].totalQTY = editdata[4];
        collectionsList[_collectionAddress].maxNFT = editdata[5];
        collectionsList[_collectionAddress].maxWhiteNFT = editdata[6];
        collectionsList[_collectionAddress].feeCollectorAddress = _Address[0];
        collectionsList[_collectionAddress].tokenAddress = _Address[1];
    }
}
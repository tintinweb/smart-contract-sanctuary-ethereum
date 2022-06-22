// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTService.sol";
import "./interfaces/INRService.sol";

contract NRService is NFTService, INRService {
    address public immutable override nftCert;

    // Keep track of allocated energy for a ticket
    mapping(uint256 => ConsumedRecord[]) private _allocations;

    // Hardcoded energy consumption per region per credit
    EnergyRequest[] public energyRequests;

    constructor (address _nfticket, address _nftCert, uint256 _pricePerCredit) NFTService(_nfticket, _pricePerCredit) {
        nftCert = _nftCert;
    }

    function _postMint(address recipient, string calldata tokenURI, uint256 credits, uint256 newTicketId)
        internal
        override
    {
        // Allocate energy from NFTCert contract
        ConsumedRecord[] memory consumedRecords = INFTCert(nftCert).consumeEnergy(energyRequests);

        for (uint256 i = 0; i < consumedRecords.length; i++) {
            _allocations[newTicketId].push(consumedRecords[i]);
        }
    }

    function setEnergyRequests(EnergyRequest[] calldata _energyRequests)
        external
        override
        onlyOwner
    {
        delete energyRequests;

        for (uint256 i = 0; i < _energyRequests.length; i++) {
            energyRequests.push(_energyRequests[i]);
        }
    }

    function viewAllocations(uint256 ticketId)
        external
        override
        view
        returns (ConsumedRecord[] memory)
    {
        return _allocations[ticketId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/TransferHelper.sol";
import "./libs/SafeMath.sol";
import "./interfaces/INFTicket.sol";
import "./interfaces/INFTService.sol";

abstract contract NFTService is Ownable, INFTService {
    using SafeMath for uint256;

    address public immutable override nfticket;

    // Keep track of remaining credits for a ticket
    mapping(uint256 => uint256) internal _remainCredits;

    // Price per credit for a ticket in Wei
    uint256 public override pricePerCredit;

    constructor(address _nfticket, uint256 _pricePerCredit) {
        nfticket = _nfticket;
        pricePerCredit = _pricePerCredit;
    }

    function buyNFTicket(address recipient, string calldata tokenURI, uint256 credits)
        external
        override
        payable
        returns (uint256)
    {
        uint256 totalPrice = pricePerCredit.mul(credits);

        require(msg.value == totalPrice, "Price incorrect");

        _preMint(recipient, tokenURI, credits);

        uint256 newTicketId = INFTicket(nfticket).mintNFTicket(recipient, tokenURI);

        _postMint(recipient, tokenURI, credits, newTicketId);

        _remainCredits[newTicketId] = credits;

        TransferHelper.safeTransferNative(owner(), totalPrice);

        emit TicketBought(newTicketId, msg.sender, recipient, tokenURI, credits);

        return newTicketId;
    }

    function _preMint(address recipient, string calldata tokenURI, uint256 credits) internal virtual { }

    function _postMint(address recipient, string calldata tokenURI, uint256 credits, uint256 newTicketId) internal virtual { }

    function updatePricePerCredit(uint256 _pricePerCredit)
        external
        override
        onlyOwner
    {
        pricePerCredit = _pricePerCredit;
    }

    function viewCredits(uint256 ticketId)
        external
        override
        view
        returns (uint256)
    {
        return _remainCredits[ticketId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/INFTCert.sol";

/**
 * Interface of NFTicket
 */
interface INRService {
  function nftCert() external view returns (address);
  function viewAllocations(uint256 ticketId) external view returns (ConsumedRecord[] memory);

  function setEnergyRequests(EnergyRequest[] calldata _energyRequests) external;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: NATIVE_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Interface of NFTicket
 */
interface INFTicket {

    function mintNFTicket(address recipient, string calldata tokenURI) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Interface of NFTService
 */
interface INFTService {
  event TicketBought(uint256 indexed newTicketId, address buyer, address recipient, string tokenURI, uint256 credits);

  function pricePerCredit() external view returns (uint256);
  function nfticket() external view returns (address);
  
  function buyNFTicket(address recipient, string calldata tokenURI, uint256 credits) external payable returns (uint256);
  function updatePricePerCredit(uint256) external;
  function viewCredits(uint256 ticketId) external view returns (uint256);
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
pragma solidity ^0.8.0;

// Owner: Agent
interface INFTCert {
    function registerCerts(EnergyCertInput[] calldata certInputs) external;
    function consumeEnergy(EnergyRequest[] calldata energyReqs
    ) external returns (ConsumedRecord[] memory);
}

struct ConsumedRecord {
    uint certId;
    string energyType;
    string location;
    uint amount;
}

struct EnergyCertInput {
    string certNum;
    string issuer;
    string URI;
    string vcURI;
    string energyType;
    string location;
    uint amount;
}

struct EnergyRequest {
    string location;
    string energyType;
    uint consumeAmount;
}
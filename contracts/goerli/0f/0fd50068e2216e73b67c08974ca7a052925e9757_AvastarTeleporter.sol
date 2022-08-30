/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// File: contracts/AvastarTypes.sol

pragma solidity 0.5.14;

/**
 * @title Avastar Data Types
 * @author Cliff Hall
 */
contract AvastarTypes {

    enum Generation {
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    }

    enum Series {
        PROMO,
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    }

    enum Wave {
        PRIME,
        REPLICANT
    }

    enum Gene {
        SKIN_TONE,
        HAIR_COLOR,
        EYE_COLOR,
        BG_COLOR,
        BACKDROP,
        EARS,
        FACE,
        NOSE,
        MOUTH,
        FACIAL_FEATURE,
        EYES,
        HAIR_STYLE
    }

    enum Gender {
        ANY,
        MALE,
        FEMALE
    }

    enum Rarity {
        COMMON,
        UNCOMMON,
        RARE,
        EPIC,
        LEGENDARY
    }

    struct Trait {
        uint256 id;
        Generation generation;
        Gender gender;
        Gene gene;
        Rarity rarity;
        uint8 variation;
        Series[] series;
        string name;
        string svg;

    }

    struct Prime {
        uint256 id;
        uint256 serial;
        uint256 traits;
        bool[12] replicated;
        Generation generation;
        Series series;
        Gender gender;
        uint8 ranking;
    }

    struct Replicant {
        uint256 id;
        uint256 serial;
        uint256 traits;
        Generation generation;
        Gender gender;
        uint8 ranking;
    }

    struct Avastar {
        uint256 id;
        uint256 serial;
        uint256 traits;
        Generation generation;
        Wave wave;
    }

    struct Attribution {
        Generation generation;
        string artist;
        string infoURI;
    }

}

// File: contracts/AvastarBase.sol

pragma solidity 0.5.14;

/**
 * @title Avastar Base
 * @author Cliff Hall
 * @notice Utilities used by descendant contracts
 */
contract AvastarBase {

    /**
     * @notice Convert a `uint` value to a `string`
     * via OraclizeAPI - MIT licence
     * https://github.com/provable-things/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol#L896
     * @param _i the `uint` value to be converted
     * @return result the `string` representation of the given `uint` value
     */
    function uintToStr(uint _i)
    internal pure
    returns (string memory result) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        result = string(bstr);
    }

    /**
     * @notice Concatenate two strings
     * @param _a the first string
     * @param _b the second string
     * @return result the concatenation of `_a` and `_b`
     */
    function strConcat(string memory _a, string memory _b)
    internal pure
    returns(string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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
        require(c >= a, "SafeMath: addition overflow");

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/AccessControl.sol

pragma solidity 0.5.14;



/**
 * @title Access Control
 * @author Cliff Hall
 * @notice Role-based access control and contract upgrade functionality.
 */
contract AccessControl {

    using SafeMath for uint256;
    using SafeMath for uint16;
    using Roles for Roles.Role;

    Roles.Role private admins;
    Roles.Role private minters;
    Roles.Role private owners;

    /**
     * @notice Sets `msg.sender` as system admin by default.
     * Starts paused. System admin must unpause, and add other roles after deployment.
     */
    constructor() public {
        admins.add(msg.sender);
    }

    /**
     * @notice Emitted when contract is paused by system administrator.
     */
    event ContractPaused();

    /**
     * @notice Emitted when contract is unpaused by system administrator.
     */
    event ContractUnpaused();

    /**
     * @notice Emitted when contract is upgraded by system administrator.
     * @param newContract address of the new version of the contract.
     */
    event ContractUpgrade(address newContract);


    bool public paused = true;
    bool public upgraded = false;
    address public newContractAddress;

    /**
     * @notice Modifier to scope access to minters
     */
    modifier onlyMinter() {
        require(minters.has(msg.sender));
        _;
    }

    /**
     * @notice Modifier to scope access to owners
     */
    modifier onlyOwner() {
        require(owners.has(msg.sender));
        _;
    }

    /**
     * @notice Modifier to scope access to system administrators
     */
    modifier onlySysAdmin() {
        require(admins.has(msg.sender));
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract not upgraded.
     */
    modifier whenNotUpgraded() {
        require(!upgraded);
        _;
    }

    /**
     * @notice Called by a system administrator to  mark the smart contract as upgraded,
     * in case there is a serious breaking bug. This method stores the new contract
     * address and emits an event to that effect. Clients of the contract should
     * update to the new contract address upon receiving this event. This contract will
     * remain paused indefinitely after such an upgrade.
     * @param _newAddress address of new contract
     */
    function upgradeContract(address _newAddress) external onlySysAdmin whenPaused whenNotUpgraded {
        require(_newAddress != address(0));
        upgraded = true;
        newContractAddress = _newAddress;
        emit ContractUpgrade(_newAddress);
    }

    /**
     * @notice Called by a system administrator to add a minter.
     * Reverts if `_minterAddress` already has minter role
     * @param _minterAddress approved minter
     */
    function addMinter(address _minterAddress) external onlySysAdmin {
        minters.add(_minterAddress);
        require(minters.has(_minterAddress));
    }

    /**
     * @notice Called by a system administrator to add an owner.
     * Reverts if `_ownerAddress` already has owner role
     * @param _ownerAddress approved owner
     * @return added boolean indicating whether the role was granted
     */
    function addOwner(address _ownerAddress) external onlySysAdmin {
        owners.add(_ownerAddress);
        require(owners.has(_ownerAddress));
    }

    /**
     * @notice Called by a system administrator to add another system admin.
     * Reverts if `_sysAdminAddress` already has sysAdmin role
     * @param _sysAdminAddress approved owner
     */
    function addSysAdmin(address _sysAdminAddress) external onlySysAdmin {
        admins.add(_sysAdminAddress);
        require(admins.has(_sysAdminAddress));
    }

    /**
     * @notice Called by an owner to remove all roles from an address.
     * Reverts if address had no roles to be removed.
     * @param _address address having its roles stripped
     */
    function stripRoles(address _address) external onlyOwner {
        require(msg.sender != _address);
        bool stripped = false;
        if (admins.has(_address)) {
            admins.remove(_address);
            stripped = true;
        }
        if (minters.has(_address)) {
            minters.remove(_address);
            stripped = true;
        }
        if (owners.has(_address)) {
            owners.remove(_address);
            stripped = true;
        }
        require(stripped == true);
    }

    /**
     * @notice Called by a system administrator to pause, triggers stopped state
     */
    function pause() external onlySysAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @notice Called by a system administrator to un-pause, returns to normal state
     */
    function unpause() external onlySysAdmin whenPaused whenNotUpgraded {
        paused = false;
        emit ContractUnpaused();
    }

}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/drafts/Counters.sol

pragma solidity ^0.5.0;


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: @openzeppelin/contracts/introspection/ERC165.sol

pragma solidity ^0.5.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol

pragma solidity ^0.5.0;








/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This function is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol

pragma solidity ^0.5.0;





/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {ERC721-_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Metadata.sol

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721Metadata.sol

pragma solidity ^0.5.0;





contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/ERC721Full.sol

pragma solidity ^0.5.0;




/**
 * @title Full ERC721 Token
 * @dev This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology.
 *
 * See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

// File: contracts/AvastarState.sol

pragma solidity 0.5.14;





/**
 * @title Avastar State
 * @author Cliff Hall
 * @notice This contract maintains the state variables for the Avastar Teleporter.
 */
contract AvastarState is AvastarBase, AvastarTypes, AccessControl, ERC721Full {

    /**
     * @notice Calls ERC721Full constructor with token name and symbol.
     */
    constructor() public ERC721Full(TOKEN_NAME, TOKEN_SYMBOL) {}

    string public constant TOKEN_NAME = "Avastar";
    string public constant TOKEN_SYMBOL = "AVASTAR";

    /**
     * @notice All Avastars across all Waves and Generations
     */
    Avastar[] internal avastars;

    /**
     * @notice List of all Traits across all Generations
     */
    Trait[] internal traits;

    /**
     * @notice  Retrieve Primes by Generation
     * Prime[] primes = primesByGeneration[uint8(_generation)]
     */
    mapping(uint8 => Prime[]) internal primesByGeneration;

    /**
     * @notice Retrieve Replicants by Generation
     * Replicant[] replicants = replicantsByGeneration[uint8(_generation)]
     */
    mapping(uint8 => Replicant[]) internal replicantsByGeneration;

    /**
     * @notice Retrieve Artist Attribution by Generation
     * Attribution attribution = attributionByGeneration[Generation(_generation)]
     */
    mapping(uint8 => Attribution) public attributionByGeneration;

    /**
     * @notice Retrieve the approved Trait handler for a given Avastar Prime by Token ID
     */
    mapping(uint256 => address) internal traitHandlerByPrimeTokenId;

    /**
     * @notice Is a given Trait Hash used within a given Generation
     * bool used = isHashUsedByGeneration[uint8(_generation)][uint256(_traits)]
     * This mapping ensures that within a Generation, a given Trait Hash is unique and can only be used once
     */
    mapping(uint8 => mapping(uint256 => bool)) public isHashUsedByGeneration;

    /**
     * @notice Retrieve Token ID for a given Trait Hash within a given Generation
     * uint256 tokenId = tokenIdByGenerationAndHash[uint8(_generation)][uint256(_traits)]
     * Since Token IDs start at 0 and empty mappings for uint256 return 0, check isHashUsedByGeneration first
     */
    mapping(uint8 => mapping(uint256 => uint256)) public tokenIdByGenerationAndHash;

    /**
     * @notice Retrieve count of Primes and Promos by Generation and Series
     * uint16 count = primeCountByGenAndSeries[uint8(_generation)][uint8(_series)]
     */
    mapping(uint8 =>  mapping(uint8 => uint16)) public primeCountByGenAndSeries;

    /**
     * @notice Retrieve count of Replicants by Generation
     * uint16 count = replicantCountByGeneration[uint8(_generation)]
     */
    mapping(uint8 => uint16) public replicantCountByGeneration;

    /**
     * @notice Retrieve the Token ID for an Avastar by a given Generation, Wave, and Serial
     * uint256 tokenId = tokenIdByGenerationWaveAndSerial[uint8(_generation)][uint256(_wave)][uint256(_serial)]
     */
    mapping(uint8 => mapping(uint8 => mapping(uint256 => uint256))) public tokenIdByGenerationWaveAndSerial;

    /**
     * @notice Retrieve the Trait ID for a Trait from a given Generation by Gene and Variation
     * uint256 traitId = traitIdByGenerationGeneAndVariation[uint8(_generation)][uint8(_gene)][uint8(_variation)]
     */
    mapping(uint8 => mapping(uint8 => mapping(uint8 => uint256))) public traitIdByGenerationGeneAndVariation;

}

// File: contracts/TraitFactory.sol

pragma solidity 0.5.14;


/**
 * @title Avastar Trait Factory
 * @author Cliff Hall
 */
contract TraitFactory is AvastarState {

    /**
     * @notice Event emitted when a new Trait is created.
     * @param id the Trait ID
     * @param generation the generation of the trait
     * @param gene the gene that the trait is a variation of
     * @param rarity the rarity level of this trait
     * @param variation variation of the gene the trait represents
     * @param name the name of the trait
     */
    event NewTrait(uint256 id, Generation generation, Gene gene, Rarity rarity, uint8 variation, string name);

    /**
     * @notice Event emitted when artist attribution is set for a generation.
     * @param generation the generation that attribution was set for
     * @param artist the artist who created the artwork for the generation
     * @param infoURI the artist's website / portfolio URI
     */
    event AttributionSet(Generation generation, string artist, string infoURI);

    /**
     * @notice Event emitted when a Trait's art is created.
     * @param id the Trait ID
     */
    event TraitArtExtended(uint256 id);

    /**
     * @notice Modifier to ensure no trait modification after a generation's
     * Avastar production has begun.
     * @param _generation the generation to check production status of
     */
    modifier onlyBeforeProd(Generation _generation) {
        require(primesByGeneration[uint8(_generation)].length == 0 && replicantsByGeneration[uint8(_generation)].length == 0);
        _;
    }

    /**
     * @notice Get Trait ID by Generation, Gene, and Variation.
     * @param _generation the generation the trait belongs to
     * @param _gene gene the trait belongs to
     * @param _variation the variation of the gene
     * @return traitId the ID of the specified trait
     */
    function getTraitIdByGenerationGeneAndVariation(
        Generation _generation,
        Gene _gene,
        uint8 _variation
    )
    external view
    returns (uint256 traitId)
    {
        return traitIdByGenerationGeneAndVariation[uint8(_generation)][uint8(_gene)][_variation];
    }

    /**
     * @notice Retrieve a Trait's info by ID.
     * @param _traitId the ID of the Trait to retrieve
     * @return id the ID of the trait
     * @return generation generation of the trait
     * @return series list of series the trait may appear in
     * @return gender gender(s) the trait is valid for
     * @return gene gene the trait belongs to
     * @return variation variation of the gene the trait represents
     * @return rarity the rarity level of this trait
     * @return name name of the trait
     */
    function getTraitInfoById(uint256 _traitId)
    external view
    returns (
        uint256 id,
        Generation generation,
        Series[] memory series,
        Gender gender,
        Gene gene,
        Rarity rarity,
        uint8 variation,
        string memory name
    ) {
        require(_traitId < traits.length);
        Trait memory trait = traits[_traitId];
        return (
            trait.id,
            trait.generation,
            trait.series,
            trait.gender,
            trait.gene,
            trait.rarity,
            trait.variation,
            trait.name
        );
    }

    /**
     * @notice Retrieve a Trait's name by ID.
     * @param _traitId the ID of the Trait to retrieve
     * @return name name of the trait
     */
    function getTraitNameById(uint256 _traitId)
    external view
    returns (string memory name) {
        require(_traitId < traits.length);
        name = traits[_traitId].name;
    }

    /**
     * @notice Retrieve a Trait's art by ID.
     * Only invokable by a system administrator.
     * @param _traitId the ID of the Trait to retrieve
     * @return art the svg layer representation of the trait
     */
    function getTraitArtById(uint256 _traitId)
    external view onlySysAdmin
    returns (string memory art) {
        require(_traitId < traits.length);
        Trait memory trait = traits[_traitId];
        art = trait.svg;
    }

    /**
     * @notice Get the artist Attribution info for a given Generation, combined into a single string.
     * @param _generation the generation to retrieve artist attribution for
     * @return attrib a single string with the artist and artist info URI
     */
    function getAttributionByGeneration(Generation _generation)
    external view
    returns (
        string memory attribution
    ){
        Attribution memory attrib = attributionByGeneration[uint8(_generation)];
        require(bytes(attrib.artist).length > 0);
        attribution = strConcat(attribution, attrib.artist);
        attribution = strConcat(attribution, ' (');
        attribution = strConcat(attribution, attrib.infoURI);
        attribution = strConcat(attribution, ')');
    }

    /**
     * @notice Set the artist Attribution for a given Generation
     * @param _generation the generation to set artist attribution for
     * @param _artist the artist who created the art for the generation
     * @param _infoURI the URI for the artist's website / portfolio
     */
    function setAttribution(
        Generation _generation,
        string calldata _artist,
        string calldata _infoURI
    )
    external onlySysAdmin onlyBeforeProd(_generation)
    {
        require(bytes(_artist).length > 0 && bytes(_infoURI).length > 0);
        attributionByGeneration[uint8(_generation)] = Attribution(_generation, _artist, _infoURI);
        emit AttributionSet(_generation, _artist, _infoURI);
    }

    /**
     * @notice Create a Trait
     * @param _generation the generation the trait belongs to
     * @param _series list of series the trait may appear in
     * @param _gender gender the trait is valid for
     * @param _gene gene the trait belongs to
     * @param _rarity the rarity level of this trait
     * @param _variation the variation of the gene the trait belongs to
     * @param _name the name of the trait
     * @param _svg svg layer representation of the trait
     * @return traitId the token ID of the newly created trait
     */
    function createTrait(
        Generation _generation,
        Series[] calldata _series,
        Gender _gender,
        Gene _gene,
        Rarity _rarity,
        uint8 _variation,
        string calldata _name,
        string calldata _svg
    )
    external onlySysAdmin whenNotPaused onlyBeforeProd(_generation)
    returns (uint256 traitId)
    {
        require(_series.length > 0);
        require(bytes(_name).length > 0);
        require(bytes(_svg).length > 0);

        // Get Trait ID
        traitId = traits.length;

        // Create and store trait
        traits.push(
            Trait(traitId, _generation, _gender, _gene, _rarity, _variation,  _series, _name, _svg)
        );

        // Create generation/gene/variation to traitId mapping required by assembleArtwork
        traitIdByGenerationGeneAndVariation[uint8(_generation)][uint8(_gene)][uint8(_variation)] = traitId;

        // Send the NewTrait event
        emit NewTrait(traitId, _generation, _gene, _rarity, _variation, _name);

        // Return the new Trait ID
        return traitId;
    }

    /**
     * @notice Extend a Trait's art.
     * Only invokable by a system administrator.
     * If successful, emits a `TraitArtExtended` event with the resultant artwork.
     * @param _traitId the ID of the Trait to retrieve
     * @param _svg the svg content to be concatenated to the existing svg property
     */
    function extendTraitArt(uint256 _traitId, string calldata _svg)
    external onlySysAdmin whenNotPaused onlyBeforeProd(traits[_traitId].generation)
    {
        require(_traitId < traits.length);
        string memory art = strConcat(traits[_traitId].svg, _svg);
        traits[_traitId].svg = art;
        emit TraitArtExtended(_traitId);
    }

    /**
     * @notice Assemble the artwork for a given Trait hash with art from the given Generation
     * @param _generation the generation the Avastar belongs to
     * @param _traitHash the Avastar's trait hash
     * @return svg the fully rendered SVG for the Avastar
     */
    function assembleArtwork(Generation _generation, uint256 _traitHash)
    internal view
    returns (string memory svg)
    {
        require(_traitHash > 0);
        string memory accumulator = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" height="1000px" width="1000px" viewBox="0 0 1000 1000">';
        uint256 slotConst = 256;
        uint256 slotMask = 255;
        uint256 bitMask;
        uint256 slottedValue;
        uint256 slotMultiplier;
        uint256 variation;
        uint256 traitId;
        Trait memory trait;

        // Iterate trait hash by Gene and assemble SVG sandwich
        for (uint8 slot = 0; slot <= uint8(Gene.HAIR_STYLE); slot++){
            slotMultiplier = uint256(slotConst**slot);  // Create slot multiplier
            bitMask = slotMask * slotMultiplier;        // Create bit mask for slot
            slottedValue = _traitHash & bitMask;        // Extract slotted value from hash
            if (slottedValue > 0) {
                variation = (slot > 0)                  // Extract variation from slotted value
                    ? slottedValue / slotMultiplier
                    : slottedValue;
                if (variation > 0) {
                    traitId = traitIdByGenerationGeneAndVariation[uint8(_generation)][slot][uint8(variation)];
                    trait = traits[traitId];
                    accumulator = strConcat(accumulator, trait.svg);
                }
            }
        }

        return strConcat(accumulator, '</svg>');
    }

}

// File: contracts/AvastarFactory.sol

pragma solidity 0.5.14;


/**
 * @title Avastar Token Factory
 * @author Cliff Hall
 */
contract AvastarFactory is TraitFactory {

    /**
     * @notice Mint an Avastar.
     * Only invokable by descendant contracts when contract is not paused.
     * Adds new `Avastar` to `avastars` array.
     * Doesn't emit an event, the calling method does (`NewPrime` or `NewReplicant`).
     * Sets `isHashUsedByGeneration` mapping to true for `avastar.generation` and `avastar.traits`.
     * Sets `tokenIdByGenerationAndHash` mapping to `avastar.id` for `avastar.generation` and `avastar.traits`.
     * Sets `tokenIdByGenerationWaveAndSerial` mapping to `avastar.id` for `avastar.generation`, `avastar.wave`, and `avastar.serial`.
     * @param _owner the address of the new Avastar's owner
     * @param _serial the new Avastar's Prime or Replicant serial number
     * @param _traits the new Avastar's trait hash
     * @param _generation the new Avastar's generation
     * @param _wave the new Avastar's wave (Prime/Replicant)
     * @return tokenId the newly minted Prime's token ID
     */
    function mintAvastar(
        address _owner,
        uint256 _serial,
        uint256 _traits,
        Generation _generation,
        Wave _wave
    )
    internal whenNotPaused
    returns (uint256 tokenId)
    {
        // Mapped Token Id for given generation and serial should always be 0 (uninitialized)
        require(tokenIdByGenerationWaveAndSerial[uint8(_generation)][uint8(_wave)][_serial] == 0);

        // Serial should always be the current length of the primes or replicants array for the given generation
        if (_wave == Wave.PRIME){
            require(_serial == primesByGeneration[uint8(_generation)].length);
        } else {
            require(_serial == replicantsByGeneration[uint8(_generation)].length);
        }

        // Get Token ID
        tokenId = avastars.length;

        // Create and store Avastar token
        Avastar memory avastar = Avastar(tokenId, _serial, _traits, _generation, _wave);

        // Store the avastar
        avastars.push(avastar);

        // Indicate use of Trait Hash within given generation
        isHashUsedByGeneration[uint8(avastar.generation)][avastar.traits] = true;

        // Store token ID by Generation and Trait Hash
        tokenIdByGenerationAndHash[uint8(avastar.generation)][avastar.traits] = avastar.id;

        // Create generation/wave/serial to tokenId mapping
        tokenIdByGenerationWaveAndSerial[uint8(avastar.generation)][uint8(avastar.wave)][avastar.serial] = avastar.id;

        // Mint the token
        super._mint(_owner, tokenId);
    }

    /**
     * @notice Get an Avastar's Wave by token ID.
     * @param _tokenId the token id of the given Avastar
     * @return wave the Avastar's wave (Prime/Replicant)
     */
    function getAvastarWaveByTokenId(uint256 _tokenId)
    external view
    returns (Wave wave)
    {
        require(_tokenId < avastars.length);
        wave = avastars[_tokenId].wave;
    }

    /**
     * @notice Render the Avastar Prime or Replicant from the original on-chain art.
     * @param _tokenId the token ID of the Prime or Replicant
     * @return svg the fully rendered SVG representation of the Avastar
     */
    function renderAvastar(uint256 _tokenId)
    external view
    returns (string memory svg)
    {
        require(_tokenId < avastars.length);
        Avastar memory avastar = avastars[_tokenId];
        uint256 traits = (avastar.wave == Wave.PRIME)
        ? primesByGeneration[uint8(avastar.generation)][avastar.serial].traits
        : replicantsByGeneration[uint8(avastar.generation)][avastar.serial].traits;
        svg = assembleArtwork(avastar.generation, traits);
    }
}

// File: contracts/PrimeFactory.sol

pragma solidity 0.5.14;


/**
 * @title Avastar Prime Factory
 * @author Cliff Hall
 */
contract PrimeFactory is AvastarFactory {

    /**
     * @notice Maximum number of primes that can be minted in
     * any given series for any generation.
     */
    uint16 public constant MAX_PRIMES_PER_SERIES = 5000;
    uint16 public constant MAX_PROMO_PRIMES_PER_GENERATION = 200;

    /**
     * @notice Event emitted upon the creation of an Avastar Prime
     * @param id the token ID of the newly minted Prime
     * @param serial the serial of the Prime
     * @param generation the generation of the Prime
     * @param series the series of the Prime
     * @param gender the gender of the Prime
     * @param traits the trait hash of the Prime
     */
    event NewPrime(uint256 id, uint256 serial, Generation generation, Series series, Gender gender, uint256 traits);

    /**
     * @notice Get the Avastar Prime metadata associated with a given Generation and Serial.
     * Does not include the trait replication flags.
     * @param _generation the Generation of the Prime
     * @param _serial the Serial of the Prime
     * @return tokenId the Prime's token ID
     * @return serial the Prime's serial
     * @return traits the Prime's trait hash
     * @return replicated the Prime's trait replication indicators
     * @return generation the Prime's generation
     * @return series the Prime's series
     * @return gender the Prime's gender
     * @return ranking the Prime's ranking
     */
    function getPrimeByGenerationAndSerial(Generation _generation, uint256 _serial)
    external view
    returns (
        uint256 tokenId,
        uint256 serial,
        uint256 traits,
        Generation generation,
        Series series,
        Gender gender,
        uint8 ranking
    ) {
        require(_serial < primesByGeneration[uint8(_generation)].length);
        Prime memory prime = primesByGeneration[uint8(_generation)][_serial];
        return (
            prime.id,
            prime.serial,
            prime.traits,
            prime.generation,
            prime.series,
            prime.gender,
            prime.ranking
        );
    }

    /**
     * @notice Get the Avastar Prime associated with a given Token ID.
     * Does not include the trait replication flags.
     * @param _tokenId the Token ID of the specified Prime
     * @return tokenId the Prime's token ID
     * @return serial the Prime's serial
     * @return traits the Prime's trait hash
     * @return generation the Prime's generation
     * @return series the Prime's series
     * @return gender the Prime's gender
     * @return ranking the Prime's ranking
     */
    function getPrimeByTokenId(uint256 _tokenId)
    external view
    returns (
        uint256 tokenId,
        uint256 serial,
        uint256 traits,
        Generation generation,
        Series series,
        Gender gender,
        uint8 ranking
    ) {
        require(_tokenId < avastars.length);
        Avastar memory avastar = avastars[_tokenId];
        require(avastar.wave ==  Wave.PRIME);
        Prime memory prime = primesByGeneration[uint8(avastar.generation)][avastar.serial];
        return (
            prime.id,
            prime.serial,
            prime.traits,
            prime.generation,
            prime.series,
            prime.gender,
            prime.ranking
        );
    }

    /**
     * @notice Get an Avastar Prime's replication flags by token ID.
     * @param _tokenId the token ID of the specified Prime
     * @return tokenId the Prime's token ID
     * @return replicated the Prime's trait replication flags
     */
    function getPrimeReplicationByTokenId(uint256 _tokenId)
    external view
    returns (
        uint256 tokenId,
        bool[12] memory replicated
    ) {
        require(_tokenId < avastars.length);
        Avastar memory avastar = avastars[_tokenId];
        require(avastar.wave ==  Wave.PRIME);
        Prime memory prime = primesByGeneration[uint8(avastar.generation)][avastar.serial];
        return (
            prime.id,
            prime.replicated
        );
    }

    /**
     * @notice Mint an Avastar Prime
     * Only invokable by minter role, when contract is not paused.
     * If successful, emits a `NewPrime` event.
     * @param _owner the address of the new Avastar's owner
     * @param _traits the new Prime's trait hash
     * @param _generation the new Prime's generation
     * @return _series the new Prime's series
     * @param _gender the new Prime's gender
     * @param _ranking the new Prime's rarity ranking
     * @return tokenId the newly minted Prime's token ID
     * @return serial the newly minted Prime's serial
     */
    function mintPrime(
        address _owner,
        uint256 _traits,
        Generation _generation,
        Series _series,
        Gender _gender,
        uint8 _ranking
    )
    external onlyMinter whenNotPaused
    returns (uint256 tokenId, uint256 serial)
    {
        require(_owner != address(0));
        require(_traits != 0);
        require(isHashUsedByGeneration[uint8(_generation)][_traits] == false);
        require(_ranking > 0 && _ranking <= 100);
        uint16 count = primeCountByGenAndSeries[uint8(_generation)][uint8(_series)];
        if (_series != Series.PROMO) {
            require(count < MAX_PRIMES_PER_SERIES);
        } else {
            require(count < MAX_PROMO_PRIMES_PER_GENERATION);
        }

        // Get Prime Serial and mint Avastar, getting tokenId
        serial = primesByGeneration[uint8(_generation)].length;
        tokenId = mintAvastar(_owner, serial, _traits, _generation, Wave.PRIME);

        // Create and store Prime struct
        bool[12] memory replicated;
        primesByGeneration[uint8(_generation)].push(
            Prime(tokenId, serial, _traits, replicated, _generation, _series, _gender, _ranking)
        );

        // Increment count for given Generation/Series
        primeCountByGenAndSeries[uint8(_generation)][uint8(_series)]++;

        // Send the NewPrime event
        emit NewPrime(tokenId, serial, _generation, _series, _gender, _traits);

        // Return the tokenId, serial
        return (tokenId, serial);
    }

}

// File: contracts/ReplicantFactory.sol

pragma solidity 0.5.14;


/**
 * @title Avastar Replicant Factory
 * @author Cliff Hall
 */
contract ReplicantFactory is PrimeFactory {

    /**
     * @notice Maximum number of Replicants that can be minted
     * in any given generation.
     */
    uint16 public constant MAX_REPLICANTS_PER_GENERATION = 25200;

    /**
     * @notice Event emitted upon the creation of an Avastar Replicant
     * @param id the token ID of the newly minted Replicant
     * @param serial the serial of the Replicant
     * @param generation the generation of the Replicant
     * @param gender the gender of the Replicant
     * @param traits the trait hash of the Replicant
     */
    event NewReplicant(uint256 id, uint256 serial, Generation generation, Gender gender, uint256 traits);

    /**
     * @notice Get the Avastar Replicant metadata associated with a given Generation and Serial
     * @param _generation the generation of the specified Replicant
     * @param _serial the serial of the specified Replicant
     * @return tokenId the Replicant's token ID
     * @return serial the Replicant's serial
     * @return traits the Replicant's trait hash
     * @return generation the Replicant's generation
     * @return gender the Replicant's gender
     * @return ranking the Replicant's ranking
     */
    function getReplicantByGenerationAndSerial(Generation _generation, uint256 _serial)
    external view
    returns (
        uint256 tokenId,
        uint256 serial,
        uint256 traits,
        Generation generation,
        Gender gender,
        uint8 ranking
    ) {
        require(_serial < replicantsByGeneration[uint8(_generation)].length);
        Replicant memory replicant = replicantsByGeneration[uint8(_generation)][_serial];
        return (
            replicant.id,
            replicant.serial,
            replicant.traits,
            replicant.generation,
            replicant.gender,
            replicant.ranking
        );
    }

    /**
     * @notice Get the Avastar Replicant associated with a given Token ID
     * @param _tokenId the token ID of the specified Replicant
     * @return tokenId the Replicant's token ID
     * @return serial the Replicant's serial
     * @return traits the Replicant's trait hash
     * @return generation the Replicant's generation
     * @return gender the Replicant's gender
     * @return ranking the Replicant's ranking
     */
    function getReplicantByTokenId(uint256 _tokenId)
    external view
    returns (
        uint256 tokenId,
        uint256 serial,
        uint256 traits,
        Generation generation,
        Gender gender,
        uint8 ranking
    ) {
        require(_tokenId < avastars.length);
        Avastar memory avastar = avastars[_tokenId];
        require(avastar.wave ==  Wave.REPLICANT);
        Replicant memory replicant = replicantsByGeneration[uint8(avastar.generation)][avastar.serial];
        return (
            replicant.id,
            replicant.serial,
            replicant.traits,
            replicant.generation,
            replicant.gender,
            replicant.ranking
        );
    }

    /**
     * @notice Mint an Avastar Replicant.
     * Only invokable by minter role, when contract is not paused.
     * If successful, emits a `NewReplicant` event.
     * @param _owner the address of the new Avastar's owner
     * @param _traits the new Replicant's trait hash
     * @param _generation the new Replicant's generation
     * @param _gender the new Replicant's gender
     * @param _ranking the new Replicant's rarity ranking
     * @return tokenId the newly minted Replicant's token ID
     * @return serial the newly minted Replicant's serial
     */
    function mintReplicant(
        address _owner,
        uint256 _traits,
        Generation _generation,
        Gender _gender,
        uint8 _ranking
    )
    external onlyMinter whenNotPaused
    returns (uint256 tokenId, uint256 serial)
    {
        require(_traits != 0);
        require(isHashUsedByGeneration[uint8(_generation)][_traits] == false);
        require(_ranking > 0 && _ranking <= 100);
        require(replicantCountByGeneration[uint8(_generation)] < MAX_REPLICANTS_PER_GENERATION);

        // Get Replicant Serial and mint Avastar, getting tokenId
        serial = replicantsByGeneration[uint8(_generation)].length;
        tokenId = mintAvastar(_owner, serial, _traits, _generation, Wave.REPLICANT);

        // Create and store Replicant struct
        replicantsByGeneration[uint8(_generation)].push(
            Replicant(tokenId, serial, _traits, _generation, _gender, _ranking)
        );

        // Increment count for given Generation
        replicantCountByGeneration[uint8(_generation)]++;

        // Send the NewReplicant event
        emit NewReplicant(tokenId, serial, _generation, _gender, _traits);

        // Return the tokenId, serial
        return (tokenId, serial);
    }

}

// File: contracts/IAvastarMetadata.sol

pragma solidity 0.5.14;

/**
 * @title Identification interface for Avastar Metadata generator contract
 * @author Cliff Hall
 * @notice Used by `AvastarTeleporter` contract to validate the address of the contract.
 */
interface IAvastarMetadata {

    /**
     * @notice Acknowledge contract is `AvastarMetadata`
     * @return always true
     */
    function isAvastarMetadata() external pure returns (bool);

    /**
     * @notice Get token URI for a given Avastar Token ID.
     * @param _tokenId the Token ID of a previously minted Avastar Prime or Replicant
     * @return uri the Avastar's off-chain JSON metadata URI
     */
    function tokenURI(uint _tokenId)
    external view
    returns (string memory uri);
}

// File: contracts/AvastarTeleporter.sol

pragma solidity 0.5.14;



/**
 * @title AvastarTeleporter
 * @author Cliff Hall
 * @notice Management of Avastar Primes, Replicants, and Traits
 */
contract AvastarTeleporter is ReplicantFactory {

    /**
     * @notice Event emitted when a handler is approved to manage Trait replication.
     * @param handler the address being approved to Trait replication
     * @param primeIds the array of Avastar Prime tokenIds the handler can use
     */
    event TraitAccessApproved(address indexed handler, uint256[] primeIds);

    /**
     * @notice Event emitted when a handler replicates Traits.
     * @param handler the address marking the Traits as used
     * @param primeId the token id of the Prime supplying the Traits
     * @param used the array of flags representing the Primes resulting Trait usage
     */
    event TraitsUsed(address indexed handler, uint256 primeId, bool[12] used);

    /**
     * @notice Event emitted when AvastarMetadata contract address is set
     * @param contractAddress the address of the new AvastarMetadata contract
     */
    event MetadataContractAddressSet(address contractAddress);

    /**
     * @notice Address of the AvastarMetadata contract
     */
    address private metadataContractAddress;

    /**
     * @notice Acknowledge contract is `AvastarTeleporter`
     * @return always true
     */
    function isAvastarTeleporter() external pure returns (bool) {return true;}

    /**
     * @notice Set the address of the `AvastarMetadata` contract.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * If successful, emits an `MetadataContractAddressSet` event.
     * @param _address address of AvastarTeleporter contract
     */
    function setMetadataContractAddress(address _address)
    external onlySysAdmin whenPaused whenNotUpgraded
    {
        // Cast the candidate contract to the IAvastarMetadata interface
        IAvastarMetadata candidateContract = IAvastarMetadata(_address);

        // Verify that we have the appropriate address
        require(candidateContract.isAvastarMetadata());

        // Set the contract address
        metadataContractAddress = _address;

        // Emit the event
        emit MetadataContractAddressSet(_address);
    }

    /**
     * @notice Get the current address of the `AvastarMetadata` contract.
     * return contractAddress the address of the `AvastarMetadata` contract
     */
    function getMetadataContractAddress()
    external view
    returns (address contractAddress) {
        return metadataContractAddress;
    }

    /**
     * @notice Get token URI for a given Avastar Token ID.
     * Reverts if given token id is not a valid Avastar Token ID.
     * @param _tokenId the Token ID of a previously minted Avastar Prime or Replicant
     * @return uri the Avastar's off-chain JSON metadata URI
     */
    function tokenURI(uint _tokenId)
    external view
    returns (string memory uri)
    {
        require(_tokenId < avastars.length);
        return IAvastarMetadata(metadataContractAddress).tokenURI(_tokenId);
    }

    /**
     * @notice Approve a handler to manage Trait replication for a set of Avastar Primes.
     * Accepts up to 256 primes for approval per call.
     * Reverts if caller is not owner of all Primes specified.
     * Reverts if no Primes are specified.
     * Reverts if given handler already has approval for all Primes specified.
     * If successful, emits a `TraitAccessApproved` event.
     * @param _handler the address approved for Trait access
     * @param _primeIds the token ids for which to approve the handler
     */
    function approveTraitAccess(address _handler, uint256[] calldata _primeIds)
    external
    {
        require(_primeIds.length > 0 && _primeIds.length <= 256);
        uint256 primeId;
        bool approvedAtLeast1 = false;
        for (uint8 i = 0; i < _primeIds.length; i++) {
            primeId = _primeIds[i];
            require(primeId < avastars.length);
            require(msg.sender == super.ownerOf(primeId), "Must be token owner");
            if (traitHandlerByPrimeTokenId[primeId] != _handler) {
                traitHandlerByPrimeTokenId[primeId] = _handler;
                approvedAtLeast1 = true;
            }
        }
        require(approvedAtLeast1, "No unhandled primes specified");

        // Emit the event
        emit TraitAccessApproved(_handler, _primeIds);
    }

    /**
     * @notice Mark some or all of an Avastar Prime's traits used.
     * Caller must be the token owner OR the approved handler.
     * Caller must send all 12 flags with those to be used set to true, the rest to false.
     * The position of each flag in the `_traitFlags` array corresponds to a Gene, of which Traits are variations.
     * The flag order is: [ SKIN_TONE, HAIR_COLOR, EYE_COLOR, BG_COLOR, BACKDROP, EARS, FACE, NOSE, MOUTH, FACIAL_FEATURE, EYES, HAIR_STYLE ].
     * Reverts if no usable traits are indicated.
     * If successful, emits a `TraitsUsed` event.
     * @param _primeId the token id for the Prime whose Traits are to be used
     * @param _traitFlags an array of no more than 12 booleans representing the Traits to be used
     */
    function useTraits(uint256 _primeId, bool[12] calldata _traitFlags)
    external
    {
        // Make certain token id is valid
        require(_primeId < avastars.length);

        // Make certain caller is token owner OR approved handler
        require(msg.sender == super.ownerOf(_primeId) || msg.sender == traitHandlerByPrimeTokenId[_primeId],
        "Must be token owner or approved handler" );

        // Get the Avastar and make sure it's a Prime
        Avastar memory avastar = avastars[_primeId];
        require(avastar.wave == Wave.PRIME);

        // Get the Prime
        Prime storage prime = primesByGeneration[uint8(avastar.generation)][avastar.serial];

        // Set the flags.
        bool usedAtLeast1;
        for (uint8 i = 0; i < 12; i++) {
            if (_traitFlags.length > i ) {
                if ( !prime.replicated[i] && _traitFlags[i] ) {
                    prime.replicated[i] = true;
                    usedAtLeast1 = true;
                }
            } else {
                break;
            }
        }

        // Revert if no flags changed
        require(usedAtLeast1, "No reusable traits specified");

        // Clear trait handler
        traitHandlerByPrimeTokenId[_primeId] = address(0);

        // Emit the TraitsUsed event
        emit TraitsUsed(msg.sender, _primeId, prime.replicated);
    }

}
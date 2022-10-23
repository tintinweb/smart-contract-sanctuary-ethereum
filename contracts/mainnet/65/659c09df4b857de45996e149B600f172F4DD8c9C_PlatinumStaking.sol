/*  2022 Platinum Primates Staking Contract 10232022             		
                                                          .                     
                                                                                
                                                               .                
                                       ,%%%@@@@@@#     ##@@@@@#                 
                                      @@@@@,,,,,@@@@&*@@@,,,&@@@                
                        %%%%         ,@@@@%@@@@@%@@@@@@%%@@@%%@@      
                      @&    &@       ,@@@@     @@@@@@@@    @@@@@ 
                    &&&,*..*,,@@     ,@@@@     @@/@@@@     @@@@  
                    @@&,*@&&* @@        @@@@@@@@@@@@@,,,,, @@@@        
                      ,@&%%/%@&&          #@@@@@@@&&/,///// @@@#                
                                       ,&@@@&@@@@@@@@&&&&,@@@@@@@               
                   %%%%                @&&&@@@@@@@@@@@@@@&*@@@@@@##             
                 @@@@@                 @@& @&&&@@&  *@@@@,@&*, * @@    
               %%@@@@@                 *&&*&@@@@@@@@@%%%%#%%@@@%,@@  
              @@@@@@@@@                **@&,***@&@@@&@@@&@@&&*&@@@            
                 @@@@@@@@%%               /@@@@&%%%%%%%%%%%%%%@@@// @%        
              .,., @@@@@@@@@@@              *,*&&&&&&&&&@@&@&&&*    @@  
            ........,,@@@@@@@@@@%%                               %%@@@          
         ,,....&&&&&,..  @@@@@@@@@@@@@@@                       @@@@@@        
       ......#&&&&&&&&##.....,,,,@@@@@@@@@@%%%%        %%%%%@@@@@,,,.#          
     .......&&&&&&&&&&&&&&@&&&&&&.....         @@@  @@         ,.%&&&&@@  
   .......&&&&&&&&&&&&&&&&&&&&&&&&&&&&#########...,,..######## ..**&&&&@%     
    ....,&&&&&&&&&&&&&&@ ..&&&&&&  && &&  &       && & && & &&@ ...&&&&&@       
   ......&&&&&&&&&&&&&&&@  .&&&&& ,## & ,, & &&  &   &   &#&  @ ....&&&&&@ */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721A {
    error ApprovalCallerNotOwnerNorApproved();

    error ApprovalQueryForNonexistentToken();

    error BalanceQueryForZeroAddress();

    error MintToZeroAddress();

    error MintZeroQuantity();

    error OwnerQueryForNonexistentToken();

    error TransferCallerNotOwnerNorApproved();

    error TransferFromIncorrectOwner();

    error TransferToNonERC721ReceiverImplementer();

    error TransferToZeroAddress();

    error URIQueryForNonexistentToken();

    error MintERC2309QuantityExceedsLimit();

    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }

    function totalSupply() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function approve(address to, uint256 tokenId) external payable;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed from,
        address indexed to
    );
}

interface IERC721AQueryable is IERC721A {
    error InvalidQueryRange();

    function explicitOwnershipsOf(uint256[] memory tokenIds)
        external
        view
        returns (TokenOwnership[] memory);

    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);
}

interface IERC721Metadata is IERC721A {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function mint(address to, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IAccessControl {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = valueIndex;
            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            if (prod1 == 0) {
                return prod0 / denominator;
            }

            require(denominator > prod1);

            uint256 remainder;
            assembly {
                remainder := mulmod(x, y, denominator)

                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            uint256 twos = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, twos)

                prod0 := div(prod0, twos)

                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

            uint256 inverse = (3 * denominator) ^ 2;

            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            result = prod0 * inverse;
            return result;
        }
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 result = 1 << (log2(a) >> 1);

        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    function sqrt(uint256 a, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    function log2(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    function log10(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    function log256(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

contract PlatinumStaking is Ownable, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant TP_STAKER_ROLE = keccak256("TP_STAKER_ROLE");

    IERC721AQueryable public NFT;
    IERC20 public token;

    uint256 public REWARD_AMOUNT = 10;
    uint256 public WITHDRAWAL_FEE_PLTNM = 0;

    uint256 public LOCK_TIME = 0 days;
    uint256 public REWARD_INTERVAL = 1 days;

    uint256 private COMPUTED_REWARD_AMOUNT = REWARD_AMOUNT * 10**18;
    uint256 private COMPUTED_WITHDRAWAL_FEEL_PLTNM =
        WITHDRAWAL_FEE_PLTNM * 10**18;
    uint256 private MAX_INT = 2**256 - 1;

    mapping(address => EnumerableSet.UintSet) stakedNFTs;
    mapping(uint256 => uint256) timestampOfNFTs;
    mapping(address => uint256) rewards;
    mapping(uint256 => address) ownerOfToken;
    uint256 public TotalShares;

    bool locked;
    modifier lock() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    constructor(address _NFT, address _token) {
        token = IERC20(_token);
        NFT = IERC721AQueryable(_NFT);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TP_STAKER_ROLE, msg.sender);
    }

    function setTokenAddress(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setNFTAddress(address _NFT) external onlyOwner {
        NFT = IERC721AQueryable(_NFT);
    }

    function setLockTime(uint256 _locktime) external onlyOwner {
        LOCK_TIME = _locktime;
    }

    function setWithdrawalFeePltnm(uint256 _withdrawalFeePLTNM)
        external
        onlyOwner
    {
        WITHDRAWAL_FEE_PLTNM = _withdrawalFeePLTNM;
    }

    function setRewardAmount(uint256 _rewardAmount) external onlyOwner {
        REWARD_AMOUNT = _rewardAmount;
    }

    function setRewardInterval(uint256 _rewardInterval) external onlyOwner {
        REWARD_INTERVAL = _rewardInterval;
    }

    function DepositAll() external {
        require(tx.origin == msg.sender, "Contract can't access this function");
        require(
            (NFT.tokensOfOwner(msg.sender)).length > 0,
            "No tokens available."
        );

        uint256[] memory tokensOfOwner = NFT.tokensOfOwner(msg.sender);

        if (tokensOfOwner.length > 0) {
            for (uint256 i = 0; i < tokensOfOwner.length; i++) {
                Deposit(tokensOfOwner[i]);
            }
        }
    }

    function Deposit(uint256 tokenID) public {
        require(tx.origin == msg.sender, "Contract can't access this function");
        NFT.transferFrom(msg.sender, address(this), tokenID);
        stakedNFTs[msg.sender].add(tokenID);
        timestampOfNFTs[tokenID] = block.timestamp;
        ownerOfToken[tokenID] = msg.sender;
        TotalShares += 1;
    }

    function DepositSpecific(uint256[] memory _tokenIDs) public {
        require(
            (NFT.tokensOfOwner(msg.sender)).length > 0,
            "No tokens available."
        );
        if (_tokenIDs.length > 0) {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                Deposit(_tokenIDs[i]);
            }
        }
    }

    function DepositFrom(address _tokenSrc, uint256 _tokenID)
        public
        onlyRole(TP_STAKER_ROLE)
    {
        NFT.transferFrom(_tokenSrc, address(this), _tokenID);
        stakedNFTs[_tokenSrc].add(_tokenID);
        timestampOfNFTs[_tokenID] = block.timestamp;
        ownerOfToken[_tokenID] = _tokenSrc;
        TotalShares += 1;
    }

    function DepositSpecificFrom(address _tokenSrc, uint256[] memory _tokenIDs)
        public
        onlyRole(TP_STAKER_ROLE)
    {
        require(
            (NFT.tokensOfOwner(_tokenSrc)).length > 0,
            "No tokens available."
        );
        if (_tokenIDs.length > 0) {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                DepositFrom(_tokenSrc, _tokenIDs[i]);
            }
        }
    }

    function DepositAllFrom(address _tokenSrc) public onlyRole(TP_STAKER_ROLE) {
        require(
            (NFT.tokensOfOwner(_tokenSrc)).length > 0,
            "No tokens available."
        );
        uint256[] memory tokensOfOwner = NFT.tokensOfOwner(_tokenSrc);

        if (tokensOfOwner.length > 0) {
            for (uint256 i = 0; i < tokensOfOwner.length; i++) {
                DepositFrom(_tokenSrc, tokensOfOwner[i]);
            }
        }
    }

    function WithdrawSpecific(uint256[] memory _tokenIDs) public {
        require(
            stakedNFTs[msg.sender].length() > 0,
            "You do not have any staked NFTs"
        );
        require(
            token.balanceOf(msg.sender) >=
                (COMPUTED_WITHDRAWAL_FEEL_PLTNM * _tokenIDs.length),
            "You do not have enough $PLTNM to withdraw your Primates"
        );

        if (_tokenIDs.length > 0) {
            for (uint256 i = 0; i < _tokenIDs.length; i++) {
                WithdrawNFT(_tokenIDs[i]);
            }
        }
    }

    function WithdrawAll() external {
        require(
            token.balanceOf(msg.sender) >=
                (COMPUTED_WITHDRAWAL_FEEL_PLTNM *
                    stakedNFTs[msg.sender].length()),
            "You do not have enough $PLTNM to withdraw your Primates"
        );
        require(tx.origin == msg.sender, "Contract can't access this function");
        while (stakedNFTs[msg.sender].length() > 0) {
            uint256 ID = stakedNFTs[msg.sender].length() - 1;
            WithdrawNFT(stakedNFTs[msg.sender].at(ID));
        }
    }

    function WithdrawNFT(uint256 tokenId) public lock {
        require(
            token.balanceOf(msg.sender) >= COMPUTED_WITHDRAWAL_FEEL_PLTNM,
            "You do not have enough $PLTNM to withdraw your Primates"
        );

        require(tx.origin == msg.sender, "Contract can't access this function");
        require(
            stakedNFTs[msg.sender].contains(tokenId),
            "NFT not staked by Account"
        );
        require(
            block.timestamp - timestampOfNFTs[tokenId] > LOCK_TIME,
            "NFT can't be unstaked now."
        );

        stakedNFTs[msg.sender].remove(tokenId);
        timestampOfNFTs[tokenId] = 0;
        ownerOfToken[tokenId] = address(0);
        TotalShares -= 1;
        NFT.transferFrom(address(this), msg.sender, tokenId);

        if (COMPUTED_WITHDRAWAL_FEEL_PLTNM > 0) {
            token.transferFrom(
                msg.sender,
                address(this),
                COMPUTED_WITHDRAWAL_FEEL_PLTNM
            );
        }
    }

    function getLengthOfStakedNFTs(address _addr)
        external
        view
        returns (uint256)
    {
        return stakedNFTs[_addr].length();
    }

    function getWithdrawalCostEstimate(address _address)
        external
        view
        returns (uint256)
    {
        return COMPUTED_WITHDRAWAL_FEEL_PLTNM * stakedNFTs[_address].length();
    }

    function getOwnerOfStakedNFT(uint256 _tokenId)
        external
        view
        returns (address)
    {
        return ownerOfToken[_tokenId];
    }

    function getStakedNFTByIndex(address _addr, uint256 id)
        external
        view
        returns (uint256)
    {
        uint256 length = stakedNFTs[_addr].length();
        require(length > id, "");

        return stakedNFTs[_addr].at(id);
    }

    function WithdrawDividents() external lock {
        _withdrawDividents(msg.sender);
    }

    function _mintPlatinum(address recipient, uint256 amount) private {
        token.mint(recipient, amount);
    }

    function _withdrawDividents(address recipient) private {
        require(tx.origin == msg.sender, "Contract can't access this function");
        uint256 amount = getDividents(recipient);

        uint256 length = stakedNFTs[recipient].length();
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = stakedNFTs[recipient].at(i);
            timestampOfNFTs[tokenId] = block.timestamp;
        }

        if (amount == 0) return;
        _mintPlatinum(recipient, amount);
    }

    function getStakedLengthOfTimeForToken(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return block.timestamp - timestampOfNFTs[_tokenId];
    }



    function getComulativeRewardRate(address recipient)
        public
        view
        returns (uint256 dividents)
    {
        
        uint256 length = stakedNFTs[recipient].length();
        dividents = COMPUTED_REWARD_AMOUNT * length;


        if (length == 2) {
            dividents = dividents + ((dividents * 20) / 100);
        } else if (length >= 3 && length < 5) {
            dividents = dividents + ((dividents * 25) / 100);
        } else if (length >= 5 && length < 10) {
            dividents = dividents + ((dividents * 35) / 100);
        } else if (length >= 10) {
            dividents = dividents + ((dividents * 45) / 100);
        }

    }

    function getDividents(address recipient)
        public
        view
        returns (uint256 dividents)
    {
        dividents = 0;
        uint256 length = stakedNFTs[recipient].length();

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = stakedNFTs[recipient].at(i);
            if (timestampOfNFTs[tokenId] > 0) {
                uint256 diff = block.timestamp - timestampOfNFTs[tokenId];

                dividents += (diff * COMPUTED_REWARD_AMOUNT) / REWARD_INTERVAL;
            }
        }

        if (length == 2) {
            dividents = dividents + ((dividents * 20) / 100);
        } else if (length >= 3 && length < 5) {
            dividents = dividents + ((dividents * 25) / 100);
        } else if (length >= 5 && length < 10) {
            dividents = dividents + ((dividents * 35) / 100);
        } else if (length >= 10) {
            dividents = dividents + ((dividents * 45) / 100);
        }
    }
}
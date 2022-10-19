// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./NFCUpgradeable.sol";
import "./internal-upgradeable/RentableNFTUpgradeable.sol";
import "./internal-upgradeable/FundForwarderUpgradeable.sol";
import "./interfaces-upgradeable/IRentableNFCUpgradeable.sol";
import "./internal-upgradeable/IWithdrawableUpgradeable.sol";

contract RentableNFCUpgradeable is
    NFCUpgradeable,
    RentableNFTUpgradeable,
    IRentableNFCUpgradeable,
    FundForwarderUpgradeable
{
    using Bytes32Address for address;
    using Bytes32Address for uint256;
    using Bytes32Address for bytes32;
    using SafeCastUpgradeable for uint256;

    uint256 public limit;
    bytes32 private _treasury;

    function init(
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_,
        uint256 limit_,
        ITreasuryUpgradeable treasury_
    ) external initializer {
        __NFC_init(
            name_,
            symbol_,
            baseURI_,
            18,
            ///@dev value is equal to keccak256("RentableNFCUpgradeable")
            0x8f0d2d8abbd7c54281bae66528ef94d45e2883ff8bcc0f44d38a570078d4694d
        );
        __FundForwarder_init(treasury_);
        bytes32 treasury;
        assembly {
            treasury := treasury_
        }
        _treasury = treasury;
        _setLimit(limit_);
    }

    function setTreasury(ITreasuryUpgradeable treasury_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        bytes32 treasury;
        assembly {
            treasury := treasury_
        }
        _treasury = treasury;
    }

    function redeem(
        address to_,
        address user_,
        uint256 type_,
        IERC20Upgradeable reward_,
        uint256 amount_
    ) external onlyRole(OPERATOR_ROLE) {
        _checkLock(user_);
        uint256 id;
        if (_ownerOf[id].fromFirst20Bytes() == address(0)) {
            unchecked {
                _mint(to_, id = (++_tokenIdTracker << 8) | (type_ & ~uint8(0)));
            }
        }
        _setUser(id, user_);
        address treasury;
        assembly {
            treasury := sload(_treasury.slot)
        }
        (bool ok, ) = treasury.call(
            abi.encodeWithSelector(
                IWithdrawableUpgradeable.withdraw.selector,
                reward_,
                user_,
                amount_
            )
        );
        if (!ok) revert Rentable__PaymentFailed();

        emit Redeemed(id, user_, reward_, amount_);
    }

    function deposit(
        address user_,
        uint256 tokenId_,
        uint256 deadline_,
        bytes calldata signature_
    ) external payable override onlyRole(OPERATOR_ROLE) {
        _checkLock(user_);
        _deposit(user_, tokenId_, deadline_, signature_);

        _setUser(tokenId_, user_);
    }

    function setLimit(uint256 limit_)
        external
        override
        onlyRole(OPERATOR_ROLE)
    {
        emit LimitSet(limit, limit_);
        _setLimit(limit_);
    }

    function setUser(uint256 tokenId, address user)
        external
        override
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
        ownerOf(tokenId);
        _checkLock(user);
        _setUser(tokenId, user);
    }

    function userOf(uint256 tokenId)
        external
        view
        override
        returns (address user)
    {
        ownerOf(tokenId);
        user = _userInfos[tokenId].fromLast160Bits();
    }

    function limitOf(uint256 tokenId) external view override returns (uint256) {
        return _userInfos[tokenId] & ~uint96(0);
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        override(ERC721Upgradeable, NFCUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }

    function _setUser(uint256 tokenId_, address user_) internal {
        uint256 userInfo = _userInfos[tokenId_];
        if (userInfo.fromLast160Bits() == user_)
            revert RentableNFC__AlreadySet();
        uint256 _limit = userInfo & ~uint96(0);
        unchecked {
            if (_limit++ > limit) revert RentableNFC__LimitExceeded();
        }

        emit UserUpdated(tokenId_, user_);

        _userInfos[tokenId_] = user_.fillFirst96Bits() | _limit;
    }

    function _setLimit(uint256 limit_) internal {
        limit = limit_;
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    )
        internal
        override(ERC721Upgradeable, ERC721PresetMinterPauserAutoIdUpgradeable)
    {
        super._beforeTokenTransfer(from_, to_, tokenId_);
        uint256 userInfo = _userInfos[tokenId_];
        if (userInfo.fromLast160Bits() != address(0)) revert RentableNFC__NotValidTransfer();
        if (from_ != to_ && userInfo & ~uint96(0) == limit) {
            delete _userInfos[tokenId_];

            emit UserUpdated(tokenId_, address(0));
        }

    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ITreasuryUpgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRentableNFCUpgradeable {
    error RentableNFC__Rented();
    error RentableNFC__Expired();
    error RentableNFC__AlreadySet();
    error RentableNFC__Unauthorized();
    error RentableNFC__LimitExceeded();
    error RentableNFC__NotValidTransfer();

    event Redeemed(
        uint256 id,
        address user,
        IERC20Upgradeable reward,
        uint256 amount
    );

    event LimitSet(uint256 indexed from, uint256 indexed to);

    function setLimit(uint256 limit_) external;

    function setUser(uint256 tokenId, address user) external;

    function deposit(
        address user_,
        uint256 tokenId_,
        uint256 deadline_,
        bytes calldata signature_
    ) external payable;

    function limitOf(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";

import "oz-custom/contracts/internal-upgradeable/SignableUpgradeable.sol";

import "./internal-upgradeable/LockableUpgradeable.sol";
import "./internal-upgradeable/TransferableUpgradeable.sol";
import "./internal-upgradeable/FundForwarderUpgradeable.sol";

import "oz-custom/contracts/oz-upgradeable/utils/math/MathUpgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/utils/math/SafeCastUpgradeable.sol";

import "./interfaces-upgradeable/INFCUpgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

import "oz-custom/contracts/libraries/SSTORE2.sol";
import "oz-custom/contracts/libraries/StringLib.sol";

contract NFCUpgradeable is
    INFCUpgradeable,
    UUPSUpgradeable,
    LockableUpgradeable,
    SignableUpgradeable,
    TransferableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721PresetMinterPauserAutoIdUpgradeable
{
    using SSTORE2 for bytes;
    using SSTORE2 for bytes32;
    using StringLib for uint256;
    using Bytes32Address for uint256;
    using Bytes32Address for address;
    using MathUpgradeable for uint256;
    using SafeCastUpgradeable for uint256;

    ///@dev value is equal to keccak256("UPGRADER_ROLE")
    bytes32 public constant UPGRADER_ROLE =
        0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;

    ///@dev value is equal to keccak256("OPERATOR_ROLE")
    bytes32 public constant OPERATOR_ROLE =
        0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;

    uint256 public decimals;
    bytes32 public version;
    bytes32 private _business;
    bytes32 private _treasury;

    uint256 private _defaultFeeTokenInfo;
    //mapping(uint256 => RoyaltyInfo) private _typeRoyalty;
    mapping(uint256 => RoyaltyInfoV2) private _typeRoyaltyV2;

    bytes32 private _baseTokenURIPtr;

    function setBaseTokenURI(string calldata tokenURI_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        _baseTokenURIPtr = bytes(tokenURI_).write();
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setTypeFee(
        IERC20Upgradeable feeToken_,
        uint256 type_,
        uint256 price_,
        address[] calldata takers_,
        uint256[] calldata takerPercents_
    ) external override onlyRole(OPERATOR_ROLE) {
        uint256 nTaker;
        unchecked {
            nTaker = takerPercents_.length % 32;
        }
        uint256 percentMask;
        for (uint256 i; i < nTaker; ) {
            percentMask |= takerPercents_[i] << (i << 3);
            unchecked {
                ++i;
            }
        }

        RoyaltyInfoV2 memory royaltyInfo;
        royaltyInfo.feeData =
            address(feeToken_).fillFirst96Bits() |
            price_.toUint96();
        royaltyInfo.takersPtr = abi.encode(takers_).write();
        royaltyInfo.takerPercents = (percentMask << 8) | nTaker;
        _typeRoyaltyV2[type_] = royaltyInfo;
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external override {
        _setRoleAdmin(role, adminRole);
    }

    function mint(address to_, uint256 type_)
        external
        override
        onlyRole(MINTER_ROLE)
        returns (uint256 id)
    {
        unchecked {
            _mint(to_, id = (++_tokenIdTracker << 8) | (type_ & ~uint8(0)));
        }
    }

    function setBlockUser(address account_, bool status_)
        external
        override
        onlyRole(PAUSER_ROLE)
    {
        _setBlockUser(account_, status_);
    }

    function royaltyInfoOf(uint256 type_)
        public
        view
        override
        returns (
            address token,
            uint256 price,
            uint256 nTakers,
            address[] memory takers,
            uint256[] memory takerPercents
        )
    {
        RoyaltyInfoV2 memory royaltyInfo = _typeRoyaltyV2[type_];
        takers = abi.decode(royaltyInfo.takersPtr.read(), (address[]));
        uint256 feeData = royaltyInfo.feeData;
        price = royaltyInfo.feeData & ~uint96(0);
        token = feeData.fromLast160Bits();
        uint256 _takerPercents = royaltyInfo.takerPercents;
        nTakers = _takerPercents & 0xff;
        uint256 percentMask = _takerPercents >> 8;
        takerPercents = new uint256[](nTakers);
        for (uint256 i; i < nTakers; ) {
            takerPercents[i] = (percentMask >> (i << 3)) & 0xff;
            unchecked {
                ++i;
            }
        }
    }

    function typeOf(uint256 tokenId_) public view override returns (uint256) {
        ownerOf(tokenId_);
        return tokenId_ & ~uint8(0);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        ownerOf(tokenId);
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            type(IERC165Upgradeable).interfaceId == interfaceId_ ||
            super.supportsInterface(interfaceId_);
    }

    function __NFC_init(
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_,
        uint256 decimals_,
        bytes32 version_
    ) internal onlyInitializing {
        __ReentrancyGuard_init();
        __EIP712_init(name_, "1");
        __ERC721PresetMinterPauserAutoId_init(name_, symbol_, baseURI_);

        address sender = _msgSender();
        _grantRole(OPERATOR_ROLE, sender);
        _grantRole(UPGRADER_ROLE, sender);

        version = version_;
        decimals = decimals_ & ~uint8(0);
    }

    function _deposit(
        address user_,
        uint256 tokenId_,
        uint256 deadline_,
        bytes calldata signature_
    ) internal virtual {
        (
            address token,
            uint256 price,
            uint256 nTakers,
            address[] memory takers,
            uint256[] memory takerPercents
        ) = royaltyInfoOf(typeOf(tokenId_));
        price *= 10**decimals;
        if (signature_.length == 65) {
            if (block.timestamp > deadline_) revert NFC__Expired();
            (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature_);
            IERC20PermitUpgradeable(token).permit(
                user_,
                address(this),
                price, // convert to wei
                deadline_,
                v,
                r,
                s
            );
        }
        emit Deposited(tokenId_, user_, price);
        price *= 100; // convert percentage to 1e4
        for (uint256 i; i < nTakers; ) {
            _safeTransferFrom(
                token,
                user_,
                takers[i],
                price.mulDiv(
                    takerPercents[i],
                    1e4,
                    MathUpgradeable.Rounding.Zero
                )
            );
            unchecked {
                ++i;
            }
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function _baseURI() internal view override returns (string memory) {
        return string(_baseTokenURIPtr.read());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "oz-custom/contracts/oz-upgradeable/utils/ContextUpgradeable.sol";

import "../interfaces-upgradeable/ITreasuryUpgradeable.sol";

error FundForwarder__ForwardError();

abstract contract FundForwarderUpgradeable is ContextUpgradeable {
    bytes32 private _treasury;

    function __FundForwarder_init(ITreasuryUpgradeable treasury_)
        internal
        onlyInitializing
    {
        __FundForwarder_init_unchained(treasury_);
    }

    function __FundForwarder_init_unchained(ITreasuryUpgradeable treasury_)
        internal
    {
        assembly {
            sstore(_treasury.slot, treasury_)
        }
    }

    receive() external payable virtual {
        address treasury;
        assembly {
            treasury := sload(_treasury.slot)
        }
        (bool success, ) = payable(treasury).call{value: msg.value}("");
        if (!success) revert FundForwarder__ForwardError();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "./IRentableNFTUpgradeable.sol";

import "oz-custom/contracts/oz-upgradeable/utils/math/SafeCastUpgradeable.sol";

abstract contract RentableNFTUpgradeable is
    ERC721Upgradeable,
    IRentableNFTUpgradeable
{
    using SafeCastUpgradeable for uint256;

    struct UserInfo {
        address user;
        uint96 expires;
    }

    mapping(uint256 => UserInfo) private _users;
    mapping(uint256 => uint256) internal _userInfos;

    function __RentableNFT_init() internal onlyInitializing {}

    function __RentableNFT_init_unchained() internal onlyInitializing {}

    function userOf(uint256 tokenId)
        external
        view
        virtual
        override
        returns (address user)
    {
        ownerOf(tokenId);
        uint256 value = _userInfos[tokenId];
        assembly {
            user := value
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IWithdrawableUpgradeable {
    event Withdrawn(
        address indexed token,
        address indexed to,
        uint256 indexed value
    );
    event Received(address indexed sender, uint256 indexed value);

    function withdraw(
        address from_,
        address to_,
        uint256 amount_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ITreasuryUpgradeable {
    error Treasury__PaymentNotSupported();

    function paymentTokens() external view returns (address[] memory);

    function setPaymentTokens(address[] calldata tokens_) external;

    function pause() external;

    function unpause() external;

    function acceptedPayment(address token_) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    error ERC20__Expired();
    error ERC20__StringTooLong();
    error ERC20__InvalidSignature();
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "oz-custom/contracts/oz-upgradeable/proxy/utils/Initializable.sol";

import "oz-custom/contracts/oz-upgradeable/utils/structs/BitMapsUpgradeable.sol";

import "./ILockableUpgradeable.sol";

import "oz-custom/contracts/libraries/Bytes32Address.sol";

abstract contract LockableUpgradeable is Initializable, ILockableUpgradeable {
    using Bytes32Address for address;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    BitMapsUpgradeable.BitMap private _blockedUsers;

    modifier onlyUnlocked(
        address sender_,
        address from_,
        address to_
    ) {
        _onlyUnlocked(sender_, from_, to_);
        _;
    }

    function __Lockable_init() internal onlyInitializing {}

    function __Lockable_init_unchained() internal onlyInitializing {}

    function setBlockUser(address account_, bool status_)
        external
        virtual
        override;

    function isBlocked(address account_) external view override returns (bool) {
        return _blockedUsers.get(account_.fillLast96Bits());
    }

    function _setBlockUser(address account_, bool status_) internal {
        _blockedUsers.setTo(account_.fillLast96Bits(), status_);
    }

    function _checkLock(address account_) internal view {
        if (_blockedUsers.get(account_.fillLast96Bits()))
            revert Lockable__UserIsLocked();
    }

    function _onlyUnlocked(
        address sender_,
        address from_,
        address to_
    ) internal view {
        _checkLock(sender_);
        _checkLock(from_);
        _checkLock(to_);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/proxy/utils/Initializable.sol";

error Transferable__TransferFailed();
error Transferable__InvalidArguments();

abstract contract TransferableUpgradeable is Initializable {
    function __Transferable_init() internal onlyInitializing {}

    function __Transferable_init_unchained() internal onlyInitializing {}

    function _safeTransferFrom(
        address token_,
        address from_,
        address to_,
        uint256 value_
    ) internal virtual {
        if (value_ == 0 || to_ == address(0))
            revert Transferable__InvalidArguments();
        bool success;
        if (token_ == address(0)) success = __nativeTransfer(to_, value_);
        else {
            assembly {
                let freeMemoryPointer := mload(0x40)

                mstore(
                    freeMemoryPointer,
                    0x23b872dd00000000000000000000000000000000000000000000000000000000
                )
                mstore(add(freeMemoryPointer, 4), from_)
                mstore(add(freeMemoryPointer, 36), to_)
                mstore(add(freeMemoryPointer, 68), value_)

                success := and(
                    or(
                        and(eq(mload(0), 1), gt(returndatasize(), 31)),
                        iszero(returndatasize())
                    ),
                    call(gas(), token_, 0, freeMemoryPointer, 100, 0, 32)
                )
            }
        }

        if (!success) revert Transferable__TransferFailed();
    }

    function _safeTransfer(
        address token_,
        address to_,
        uint256 value_
    ) internal virtual {
        if (value_ == 0 || to_ == address(0))
            revert Transferable__InvalidArguments();

        bool success;
        if (token_ == address(0)) success = __nativeTransfer(to_, value_);
        else {
            assembly {
                // Get a pointer to some free memory.
                let freeMemoryPointer := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(
                    freeMemoryPointer,
                    0xa9059cbb00000000000000000000000000000000000000000000000000000000
                )
                mstore(add(freeMemoryPointer, 4), to_) // Append the "to" argument.
                mstore(add(freeMemoryPointer, 36), value_) // Append the "amount" argument.

                success := and(
                    or(
                        and(eq(mload(0), 1), gt(returndatasize(), 31)),
                        iszero(returndatasize())
                    ),
                    call(gas(), token_, 0, freeMemoryPointer, 68, 0, 32)
                )
            }
        }

        if (!success) revert Transferable__TransferFailed();
    }

    function _safeNativeTransfer(address to_, uint256 amount_)
        internal
        virtual
    {
        if (!__nativeTransfer(to_, amount_))
            revert Transferable__TransferFailed();
    }

    function __nativeTransfer(address to_, uint256 amount_)
        private
        returns (bool success)
    {
        assembly {
            success := call(gas(), to_, amount_, 0, 0, 0, 0)
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface INFCUpgradeable {
    error NFC__Expired();
    error NFC__Unexisted();
    error NFC__Unauthorized();
    error NFC__NonZeroAddress();
    error NFC__LengthMismatch();

    struct RoyaltyInfoV2 {
        uint256 feeData;
        uint256 takerPercents;
        bytes32 takersPtr;
    }
    struct RoyaltyInfo {
        uint256 feeData;
        uint256 takerPercents;
        bytes32[] takers;
    }

    event Deposited(
        uint256 indexed tokenId,
        address indexed from,
        uint256 indexed priceFee
    );

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function setTypeFee(
        IERC20Upgradeable feeToken_,
        uint256 type_,
        uint256 price_,
        address[] calldata takers_,
        uint256[] calldata takerPercents_
    ) external;

    function royaltyInfoOf(uint256 type_)
        external
        view
        returns (
            address token,
            uint256 price,
            uint256 length,
            address[] memory takers,
            uint256[] memory takerPercents
        );

    function typeOf(uint256 tokenId_) external view returns (uint256);

    function mint(address to_, uint256 type_) external returns (uint256 id);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../oz-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

import "./interfaces/ISignableUpgradeable.sol";

import "../libraries/Bytes32Address.sol";

abstract contract SignableUpgradeable is
    EIP712Upgradeable,
    ISignableUpgradeable
{
    using Bytes32Address for address;
    using ECDSAUpgradeable for bytes32;

    mapping(bytes32 => uint256) internal _nonces;

    function __Signable_init() internal onlyInitializing {}

    function __Signable_init_unchained() internal onlyInitializing {}

    function nonces(address sender_)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _nonce(sender_);
    }

    function _verify(
        address sender_,
        address verifier_,
        bytes32 structHash_,
        bytes calldata signature_
    ) internal view virtual {
        _checkVerifier(
            sender_,
            verifier_,
            _hashTypedDataV4(structHash_),
            signature_
        );
    }

    function _verify(
        address sender_,
        address verifier_,
        bytes32 structHash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view virtual {
        _checkVerifier(
            sender_,
            verifier_,
            _hashTypedDataV4(structHash_),
            v,
            r,
            s
        );
    }

    function _checkVerifier(
        address sender_,
        address verifier_,
        bytes32 digest_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view virtual {
        if (digest_.recover(v, r, s) != verifier_)
            revert Signable__InvalidSignature(sender_);
    }

    function _checkVerifier(
        address sender_,
        address verifier_,
        bytes32 digest_,
        bytes calldata signature_
    ) internal view virtual {
        if (digest_.recover(signature_) != verifier_)
            revert Signable__InvalidSignature(sender_);
    }

    function _useNonce(address sender_) internal virtual returns (uint256) {
        unchecked {
            return _nonces[sender_.fillLast12Bytes()]++;
        }
    }

    function _nonce(address sender_) internal view virtual returns (uint256) {
        return _nonces[sender_.fillLast12Bytes()];
    }

    function _splitSignature(bytes calldata signature_)
        internal
        pure
        virtual
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            r := calldataload(signature_.offset)
            s := calldataload(add(signature_.offset, 0x20))
            v := byte(0, calldataload(add(signature_.offset, 0x40)))
        }
    }

    function DOMAIN_SEPARATOR()
        external
        view
        virtual
        override
        returns (bytes32)
    {
        return _domainSeparatorV4();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

error ReentrancyGuard__Locked();

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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
    uint256 private _locked;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _locked = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        if (_locked != 1) revert ReentrancyGuard__Locked();

        _locked = 2;

        _;

        _locked = 1;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library StringLib {
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

error UUPSUpgradeable__OnlyCall();
error UUPSUpgradeable__OnlyDelegateCall();
error UUPSUpgradeable__OnlyActiveProxy();

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is
    Initializable,
    IERC1822ProxiableUpgradeable,
    ERC1967UpgradeUpgradeable
{
    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        if (address(this) == __self) revert UUPSUpgradeable__OnlyDelegateCall();
        if (_getImplementation() != __self)
            revert UUPSUpgradeable__OnlyActiveProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        if (address(this) != __self) revert UUPSUpgradeable__OnlyCall();
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        virtual
        onlyProxy
    {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    error SSTORE2_DEPLOYMENT_FAILED();
    error SSTORE2_READ_OUT_OF_BOUNDS();

    // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.
    uint256 internal constant DATA_OFFSET = 1;

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (bytes32 ptr) {
        // Note: The assembly block below does not expand the memory.
        address pointer;
        assembly {
            let originalDataLength := mload(data)

            // Add 1 to data size since we are prefixing it with a STOP opcode.
            let dataSize := add(originalDataLength, 1)

            /**
             * ------------------------------------------------------------------------------------+
             *   Opcode  | Opcode + Arguments  | Description       | Stack View                    |
             * ------------------------------------------------------------------------------------|
             *   0x61    | 0x61XXXX            | PUSH2 codeSize    | codeSize                      |
             *   0x80    | 0x80                | DUP1              | codeSize codeSize             |
             *   0x60    | 0x600A              | PUSH1 10          | 10 codeSize codeSize          |
             *   0x3D    | 0x3D                | RETURNDATASIZE    | 0 10 codeSize codeSize        |
             *   0x39    | 0x39                | CODECOPY          | codeSize                      |
             *   0x3D    | 0x3D                | RETURNDATASZIE    | 0 codeSize                    |
             *   0xF3    | 0xF3                | RETURN            |                               |
             *   0x00    | 0x00                | STOP              |                               |
             * ------------------------------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called. Also PUSH2 is
             * used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                data,
                or(
                    0x61000080600a3d393df300,
                    shl(64, dataSize) // shift `dataSize` so that it lines up with the 0000 after PUSH2
                )
            )

            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 21), add(dataSize, 10))

            // Restore original length of the variable size `data`
            mstore(data, originalDataLength)
        }

        if (pointer == address(0)) {
            revert SSTORE2_DEPLOYMENT_FAILED();
        }
        assembly {
            ptr := pointer
        }
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(bytes32 ptr) internal view returns (bytes memory) {
        address pointer;
        assembly {
            pointer := ptr
        }
        return
            readBytecode(
                pointer,
                DATA_OFFSET,
                pointer.code.length - DATA_OFFSET
            );
    }

    function read(address pointer, uint256 start)
        internal
        view
        returns (bytes memory)
    {
        start += DATA_OFFSET;
        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        if (pointer.code.length < end) {
            revert SSTORE2_READ_OUT_OF_BOUNDS();
        }

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 63 (32 + 31) to size and running the result through the logic
            // above ensures the memory pointer remains word-aligned, following
            // the Solidity convention.
            mstore(0x40, add(data, and(add(size, 63), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

error Math__Overflow();

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) revert Math__Overflow();

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
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

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
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

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

error SafeCast__Overflow();

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    // function toUint248(uint256 value) internal pure returns (uint248) {
    //     require(
    //         value <= type(uint248).max,
    //         "SafeCast: value doesn't fit in 248 bits"
    //     );
    //     return uint248(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint240 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint240).
    //  *
    //  * Counterpart to Solidity's `uint240` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 240 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint240(uint256 value) internal pure returns (uint240) {
    //     require(
    //         value <= type(uint240).max,
    //         "SafeCast: value doesn't fit in 240 bits"
    //     );
    //     return uint240(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint232 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint232).
    //  *
    //  * Counterpart to Solidity's `uint232` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 232 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint232(uint256 value) internal pure returns (uint232) {
    //     require(
    //         value <= type(uint232).max,
    //         "SafeCast: value doesn't fit in 232 bits"
    //     );
    //     return uint232(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint224 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint224).
    //  *
    //  * Counterpart to Solidity's `uint224` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 224 bits
    //  *
    //  * _Available since v4.2._
    //  */
    // function toUint224(uint256 value) internal pure returns (uint224) {
    //     require(
    //         value <= type(uint224).max,
    //         "SafeCast: value doesn't fit in 224 bits"
    //     );
    //     return uint224(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint216 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint216).
    //  *
    //  * Counterpart to Solidity's `uint216` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 216 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint216(uint256 value) internal pure returns (uint216) {
    //     require(
    //         value <= type(uint216).max,
    //         "SafeCast: value doesn't fit in 216 bits"
    //     );
    //     return uint216(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint208 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint208).
    //  *
    //  * Counterpart to Solidity's `uint208` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 208 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint208(uint256 value) internal pure returns (uint208) {
    //     require(
    //         value <= type(uint208).max,
    //         "SafeCast: value doesn't fit in 208 bits"
    //     );
    //     return uint208(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint200 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint200).
    //  *
    //  * Counterpart to Solidity's `uint200` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 200 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint200(uint256 value) internal pure returns (uint200) {
    //     require(
    //         value <= type(uint200).max,
    //         "SafeCast: value doesn't fit in 200 bits"
    //     );
    //     return uint200(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint192 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint192).
    //  *
    //  * Counterpart to Solidity's `uint192` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 192 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint192(uint256 value) internal pure returns (uint192) {
    //     require(
    //         value <= type(uint192).max,
    //         "SafeCast: value doesn't fit in 192 bits"
    //     );
    //     return uint192(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint184 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint184).
    //  *
    //  * Counterpart to Solidity's `uint184` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 184 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint184(uint256 value) internal pure returns (uint184) {
    //     require(
    //         value <= type(uint184).max,
    //         "SafeCast: value doesn't fit in 184 bits"
    //     );
    //     return uint184(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint176 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint176).
    //  *
    //  * Counterpart to Solidity's `uint176` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 176 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint176(uint256 value) internal pure returns (uint176) {
    //     require(
    //         value <= type(uint176).max,
    //         "SafeCast: value doesn't fit in 176 bits"
    //     );
    //     return uint176(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint168 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint168).
    //  *
    //  * Counterpart to Solidity's `uint168` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 168 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint168(uint256 value) internal pure returns (uint168) {
    //     require(
    //         value <= type(uint168).max,
    //         "SafeCast: value doesn't fit in 168 bits"
    //     );
    //     return uint168(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint160 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint160).
    //  *
    //  * Counterpart to Solidity's `uint160` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 160 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint160(uint256 value) internal pure returns (uint160) {
    //     require(
    //         value <= type(uint160).max,
    //         "SafeCast: value doesn't fit in 160 bits"
    //     );
    //     return uint160(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint152 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint152).
    //  *
    //  * Counterpart to Solidity's `uint152` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 152 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint152(uint256 value) internal pure returns (uint152) {
    //     require(
    //         value <= type(uint152).max,
    //         "SafeCast: value doesn't fit in 152 bits"
    //     );
    //     return uint152(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint144 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint144).
    //  *
    //  * Counterpart to Solidity's `uint144` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 144 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint144(uint256 value) internal pure returns (uint144) {
    //     require(
    //         value <= type(uint144).max,
    //         "SafeCast: value doesn't fit in 144 bits"
    //     );
    //     return uint144(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint136 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint136).
    //  *
    //  * Counterpart to Solidity's `uint136` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 136 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint136(uint256 value) internal pure returns (uint136) {
    //     require(
    //         value <= type(uint136).max,
    //         "SafeCast: value doesn't fit in 136 bits"
    //     );
    //     return uint136(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint128 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint128).
    //  *
    //  * Counterpart to Solidity's `uint128` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 128 bits
    //  *
    //  * _Available since v2.5._
    //  */
    // function toUint128(uint256 value) internal pure returns (uint128) {
    //     require(
    //         value <= type(uint128).max,
    //         "SafeCast: value doesn't fit in 128 bits"
    //     );
    //     return uint128(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint120 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint120).
    //  *
    //  * Counterpart to Solidity's `uint120` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 120 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint120(uint256 value) internal pure returns (uint120) {
    //     require(
    //         value <= type(uint120).max,
    //         "SafeCast: value doesn't fit in 120 bits"
    //     );
    //     return uint120(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint112 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint112).
    //  *
    //  * Counterpart to Solidity's `uint112` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 112 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint112(uint256 value) internal pure returns (uint112) {
    //     require(
    //         value <= type(uint112).max,
    //         "SafeCast: value doesn't fit in 112 bits"
    //     );
    //     return uint112(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint104 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint104).
    //  *
    //  * Counterpart to Solidity's `uint104` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 104 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint104(uint256 value) internal pure returns (uint104) {
    //     require(
    //         value <= type(uint104).max,
    //         "SafeCast: value doesn't fit in 104 bits"
    //     );
    //     return uint104(value);
    // }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        //require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        if (value > ~uint96(0)) revert SafeCast__Overflow();
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    // function toUint88(uint256 value) internal pure returns (uint88) {
    //     require(
    //         value <= type(uint88).max,
    //         "SafeCast: value doesn't fit in 88 bits"
    //     );
    //     return uint88(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint80 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint80).
    //  *
    //  * Counterpart to Solidity's `uint80` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 80 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint80(uint256 value) internal pure returns (uint80) {
    //     require(
    //         value <= type(uint80).max,
    //         "SafeCast: value doesn't fit in 80 bits"
    //     );
    //     return uint80(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint72 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint72).
    //  *
    //  * Counterpart to Solidity's `uint72` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 72 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint72(uint256 value) internal pure returns (uint72) {
    //     require(
    //         value <= type(uint72).max,
    //         "SafeCast: value doesn't fit in 72 bits"
    //     );
    //     return uint72(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint64 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint64).
    //  *
    //  * Counterpart to Solidity's `uint64` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 64 bits
    //  *
    //  * _Available since v2.5._
    //  */
    // function toUint64(uint256 value) internal pure returns (uint64) {
    //     require(
    //         value <= type(uint64).max,
    //         "SafeCast: value doesn't fit in 64 bits"
    //     );
    //     return uint64(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint56 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint56).
    //  *
    //  * Counterpart to Solidity's `uint56` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 56 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint56(uint256 value) internal pure returns (uint56) {
    //     require(
    //         value <= type(uint56).max,
    //         "SafeCast: value doesn't fit in 56 bits"
    //     );
    //     return uint56(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint48 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint48).
    //  *
    //  * Counterpart to Solidity's `uint48` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 48 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint48(uint256 value) internal pure returns (uint48) {
    //     require(
    //         value <= type(uint48).max,
    //         "SafeCast: value doesn't fit in 48 bits"
    //     );
    //     return uint48(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint40 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint40).
    //  *
    //  * Counterpart to Solidity's `uint40` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 40 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint40(uint256 value) internal pure returns (uint40) {
    //     require(
    //         value <= type(uint40).max,
    //         "SafeCast: value doesn't fit in 40 bits"
    //     );
    //     return uint40(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint32 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint32).
    //  *
    //  * Counterpart to Solidity's `uint32` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 32 bits
    //  *
    //  * _Available since v2.5._
    //  */
    // function toUint32(uint256 value) internal pure returns (uint32) {
    //     require(
    //         value <= type(uint32).max,
    //         "SafeCast: value doesn't fit in 32 bits"
    //     );
    //     return uint32(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint24 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint24).
    //  *
    //  * Counterpart to Solidity's `uint24` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 24 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toUint24(uint256 value) internal pure returns (uint24) {
    //     require(
    //         value <= type(uint24).max,
    //         "SafeCast: value doesn't fit in 24 bits"
    //     );
    //     return uint24(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint16 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint16).
    //  *
    //  * Counterpart to Solidity's `uint16` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 16 bits
    //  *
    //  * _Available since v2.5._
    //  */
    // function toUint16(uint256 value) internal pure returns (uint16) {
    //     require(
    //         value <= type(uint16).max,
    //         "SafeCast: value doesn't fit in 16 bits"
    //     );
    //     return uint16(value);
    // }

    // /**
    //  * @dev Returns the downcasted uint8 from uint256, reverting on
    //  * overflow (when the input is greater than largest uint8).
    //  *
    //  * Counterpart to Solidity's `uint8` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 8 bits
    //  *
    //  * _Available since v2.5._
    //  */
    // function toUint8(uint256 value) internal pure returns (uint8) {
    //     require(
    //         value <= type(uint8).max,
    //         "SafeCast: value doesn't fit in 8 bits"
    //     );
    //     return uint8(value);
    // }

    // /**
    //  * @dev Converts a signed int256 into an unsigned uint256.
    //  *
    //  * Requirements:
    //  *
    //  * - input must be greater than or equal to 0.
    //  *
    //  * _Available since v3.0._
    //  */
    // function toUint256(int256 value) internal pure returns (uint256) {
    //     require(value >= 0, "SafeCast: value must be positive");
    //     return uint256(value);
    // }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    // function toInt248(int256 value) internal pure returns (int248) {
    //     require(
    //         value >= type(int248).min && value <= type(int248).max,
    //         "SafeCast: value doesn't fit in 248 bits"
    //     );
    //     return int248(value);
    // }

    // /**
    //  * @dev Returns the downcasted int240 from int256, reverting on
    //  * overflow (when the input is less than smallest int240 or
    //  * greater than largest int240).
    //  *
    //  * Counterpart to Solidity's `int240` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 240 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt240(int256 value) internal pure returns (int240) {
    //     require(
    //         value >= type(int240).min && value <= type(int240).max,
    //         "SafeCast: value doesn't fit in 240 bits"
    //     );
    //     return int240(value);
    // }

    // /**
    //  * @dev Returns the downcasted int232 from int256, reverting on
    //  * overflow (when the input is less than smallest int232 or
    //  * greater than largest int232).
    //  *
    //  * Counterpart to Solidity's `int232` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 232 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt232(int256 value) internal pure returns (int232) {
    //     require(
    //         value >= type(int232).min && value <= type(int232).max,
    //         "SafeCast: value doesn't fit in 232 bits"
    //     );
    //     return int232(value);
    // }

    // /**
    //  * @dev Returns the downcasted int224 from int256, reverting on
    //  * overflow (when the input is less than smallest int224 or
    //  * greater than largest int224).
    //  *
    //  * Counterpart to Solidity's `int224` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 224 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt224(int256 value) internal pure returns (int224) {
    //     require(
    //         value >= type(int224).min && value <= type(int224).max,
    //         "SafeCast: value doesn't fit in 224 bits"
    //     );
    //     return int224(value);
    // }

    // /**
    //  * @dev Returns the downcasted int216 from int256, reverting on
    //  * overflow (when the input is less than smallest int216 or
    //  * greater than largest int216).
    //  *
    //  * Counterpart to Solidity's `int216` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 216 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt216(int256 value) internal pure returns (int216) {
    //     require(
    //         value >= type(int216).min && value <= type(int216).max,
    //         "SafeCast: value doesn't fit in 216 bits"
    //     );
    //     return int216(value);
    // }

    // /**
    //  * @dev Returns the downcasted int208 from int256, reverting on
    //  * overflow (when the input is less than smallest int208 or
    //  * greater than largest int208).
    //  *
    //  * Counterpart to Solidity's `int208` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 208 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt208(int256 value) internal pure returns (int208) {
    //     require(
    //         value >= type(int208).min && value <= type(int208).max,
    //         "SafeCast: value doesn't fit in 208 bits"
    //     );
    //     return int208(value);
    // }

    // /**
    //  * @dev Returns the downcasted int200 from int256, reverting on
    //  * overflow (when the input is less than smallest int200 or
    //  * greater than largest int200).
    //  *
    //  * Counterpart to Solidity's `int200` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 200 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt200(int256 value) internal pure returns (int200) {
    //     require(
    //         value >= type(int200).min && value <= type(int200).max,
    //         "SafeCast: value doesn't fit in 200 bits"
    //     );
    //     return int200(value);
    // }

    // /**
    //  * @dev Returns the downcasted int192 from int256, reverting on
    //  * overflow (when the input is less than smallest int192 or
    //  * greater than largest int192).
    //  *
    //  * Counterpart to Solidity's `int192` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 192 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt192(int256 value) internal pure returns (int192) {
    //     require(
    //         value >= type(int192).min && value <= type(int192).max,
    //         "SafeCast: value doesn't fit in 192 bits"
    //     );
    //     return int192(value);
    // }

    // /**
    //  * @dev Returns the downcasted int184 from int256, reverting on
    //  * overflow (when the input is less than smallest int184 or
    //  * greater than largest int184).
    //  *
    //  * Counterpart to Solidity's `int184` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 184 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt184(int256 value) internal pure returns (int184) {
    //     require(
    //         value >= type(int184).min && value <= type(int184).max,
    //         "SafeCast: value doesn't fit in 184 bits"
    //     );
    //     return int184(value);
    // }

    // /**
    //  * @dev Returns the downcasted int176 from int256, reverting on
    //  * overflow (when the input is less than smallest int176 or
    //  * greater than largest int176).
    //  *
    //  * Counterpart to Solidity's `int176` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 176 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt176(int256 value) internal pure returns (int176) {
    //     require(
    //         value >= type(int176).min && value <= type(int176).max,
    //         "SafeCast: value doesn't fit in 176 bits"
    //     );
    //     return int176(value);
    // }

    // /**
    //  * @dev Returns the downcasted int168 from int256, reverting on
    //  * overflow (when the input is less than smallest int168 or
    //  * greater than largest int168).
    //  *
    //  * Counterpart to Solidity's `int168` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 168 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt168(int256 value) internal pure returns (int168) {
    //     require(
    //         value >= type(int168).min && value <= type(int168).max,
    //         "SafeCast: value doesn't fit in 168 bits"
    //     );
    //     return int168(value);
    // }

    // /**
    //  * @dev Returns the downcasted int160 from int256, reverting on
    //  * overflow (when the input is less than smallest int160 or
    //  * greater than largest int160).
    //  *
    //  * Counterpart to Solidity's `int160` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 160 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt160(int256 value) internal pure returns (int160) {
    //     require(
    //         value >= type(int160).min && value <= type(int160).max,
    //         "SafeCast: value doesn't fit in 160 bits"
    //     );
    //     return int160(value);
    // }

    // /**
    //  * @dev Returns the downcasted int152 from int256, reverting on
    //  * overflow (when the input is less than smallest int152 or
    //  * greater than largest int152).
    //  *
    //  * Counterpart to Solidity's `int152` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 152 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt152(int256 value) internal pure returns (int152) {
    //     require(
    //         value >= type(int152).min && value <= type(int152).max,
    //         "SafeCast: value doesn't fit in 152 bits"
    //     );
    //     return int152(value);
    // }

    // /**
    //  * @dev Returns the downcasted int144 from int256, reverting on
    //  * overflow (when the input is less than smallest int144 or
    //  * greater than largest int144).
    //  *
    //  * Counterpart to Solidity's `int144` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 144 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt144(int256 value) internal pure returns (int144) {
    //     require(
    //         value >= type(int144).min && value <= type(int144).max,
    //         "SafeCast: value doesn't fit in 144 bits"
    //     );
    //     return int144(value);
    // }

    // /**
    //  * @dev Returns the downcasted int136 from int256, reverting on
    //  * overflow (when the input is less than smallest int136 or
    //  * greater than largest int136).
    //  *
    //  * Counterpart to Solidity's `int136` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 136 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt136(int256 value) internal pure returns (int136) {
    //     require(
    //         value >= type(int136).min && value <= type(int136).max,
    //         "SafeCast: value doesn't fit in 136 bits"
    //     );
    //     return int136(value);
    // }

    // /**
    //  * @dev Returns the downcasted int128 from int256, reverting on
    //  * overflow (when the input is less than smallest int128 or
    //  * greater than largest int128).
    //  *
    //  * Counterpart to Solidity's `int128` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 128 bits
    //  *
    //  * _Available since v3.1._
    //  */
    // function toInt128(int256 value) internal pure returns (int128) {
    //     require(
    //         value >= type(int128).min && value <= type(int128).max,
    //         "SafeCast: value doesn't fit in 128 bits"
    //     );
    //     return int128(value);
    // }

    // /**
    //  * @dev Returns the downcasted int120 from int256, reverting on
    //  * overflow (when the input is less than smallest int120 or
    //  * greater than largest int120).
    //  *
    //  * Counterpart to Solidity's `int120` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 120 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt120(int256 value) internal pure returns (int120) {
    //     require(
    //         value >= type(int120).min && value <= type(int120).max,
    //         "SafeCast: value doesn't fit in 120 bits"
    //     );
    //     return int120(value);
    // }

    // /**
    //  * @dev Returns the downcasted int112 from int256, reverting on
    //  * overflow (when the input is less than smallest int112 or
    //  * greater than largest int112).
    //  *
    //  * Counterpart to Solidity's `int112` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 112 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt112(int256 value) internal pure returns (int112) {
    //     require(
    //         value >= type(int112).min && value <= type(int112).max,
    //         "SafeCast: value doesn't fit in 112 bits"
    //     );
    //     return int112(value);
    // }

    // /**
    //  * @dev Returns the downcasted int104 from int256, reverting on
    //  * overflow (when the input is less than smallest int104 or
    //  * greater than largest int104).
    //  *
    //  * Counterpart to Solidity's `int104` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 104 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt104(int256 value) internal pure returns (int104) {
    //     require(
    //         value >= type(int104).min && value <= type(int104).max,
    //         "SafeCast: value doesn't fit in 104 bits"
    //     );
    //     return int104(value);
    // }

    // /**
    //  * @dev Returns the downcasted int96 from int256, reverting on
    //  * overflow (when the input is less than smallest int96 or
    //  * greater than largest int96).
    //  *
    //  * Counterpart to Solidity's `int96` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 96 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt96(int256 value) internal pure returns (int96) {
    //     require(
    //         value >= type(int96).min && value <= type(int96).max,
    //         "SafeCast: value doesn't fit in 96 bits"
    //     );
    //     return int96(value);
    // }

    // /**
    //  * @dev Returns the downcasted int88 from int256, reverting on
    //  * overflow (when the input is less than smallest int88 or
    //  * greater than largest int88).
    //  *
    //  * Counterpart to Solidity's `int88` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 88 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt88(int256 value) internal pure returns (int88) {
    //     require(
    //         value >= type(int88).min && value <= type(int88).max,
    //         "SafeCast: value doesn't fit in 88 bits"
    //     );
    //     return int88(value);
    // }

    // /**
    //  * @dev Returns the downcasted int80 from int256, reverting on
    //  * overflow (when the input is less than smallest int80 or
    //  * greater than largest int80).
    //  *
    //  * Counterpart to Solidity's `int80` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 80 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt80(int256 value) internal pure returns (int80) {
    //     require(
    //         value >= type(int80).min && value <= type(int80).max,
    //         "SafeCast: value doesn't fit in 80 bits"
    //     );
    //     return int80(value);
    // }

    // /**
    //  * @dev Returns the downcasted int72 from int256, reverting on
    //  * overflow (when the input is less than smallest int72 or
    //  * greater than largest int72).
    //  *
    //  * Counterpart to Solidity's `int72` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 72 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt72(int256 value) internal pure returns (int72) {
    //     require(
    //         value >= type(int72).min && value <= type(int72).max,
    //         "SafeCast: value doesn't fit in 72 bits"
    //     );
    //     return int72(value);
    // }

    // /**
    //  * @dev Returns the downcasted int64 from int256, reverting on
    //  * overflow (when the input is less than smallest int64 or
    //  * greater than largest int64).
    //  *
    //  * Counterpart to Solidity's `int64` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 64 bits
    //  *
    //  * _Available since v3.1._
    //  */
    // function toInt64(int256 value) internal pure returns (int64) {
    //     require(
    //         value >= type(int64).min && value <= type(int64).max,
    //         "SafeCast: value doesn't fit in 64 bits"
    //     );
    //     return int64(value);
    // }

    // /**
    //  * @dev Returns the downcasted int56 from int256, reverting on
    //  * overflow (when the input is less than smallest int56 or
    //  * greater than largest int56).
    //  *
    //  * Counterpart to Solidity's `int56` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 56 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt56(int256 value) internal pure returns (int56) {
    //     require(
    //         value >= type(int56).min && value <= type(int56).max,
    //         "SafeCast: value doesn't fit in 56 bits"
    //     );
    //     return int56(value);
    // }

    // /**
    //  * @dev Returns the downcasted int48 from int256, reverting on
    //  * overflow (when the input is less than smallest int48 or
    //  * greater than largest int48).
    //  *
    //  * Counterpart to Solidity's `int48` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 48 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt48(int256 value) internal pure returns (int48) {
    //     require(
    //         value >= type(int48).min && value <= type(int48).max,
    //         "SafeCast: value doesn't fit in 48 bits"
    //     );
    //     return int48(value);
    // }

    // /**
    //  * @dev Returns the downcasted int40 from int256, reverting on
    //  * overflow (when the input is less than smallest int40 or
    //  * greater than largest int40).
    //  *
    //  * Counterpart to Solidity's `int40` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 40 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt40(int256 value) internal pure returns (int40) {
    //     require(
    //         value >= type(int40).min && value <= type(int40).max,
    //         "SafeCast: value doesn't fit in 40 bits"
    //     );
    //     return int40(value);
    // }

    // /**
    //  * @dev Returns the downcasted int32 from int256, reverting on
    //  * overflow (when the input is less than smallest int32 or
    //  * greater than largest int32).
    //  *
    //  * Counterpart to Solidity's `int32` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 32 bits
    //  *
    //  * _Available since v3.1._
    //  */
    // function toInt32(int256 value) internal pure returns (int32) {
    //     require(
    //         value >= type(int32).min && value <= type(int32).max,
    //         "SafeCast: value doesn't fit in 32 bits"
    //     );
    //     return int32(value);
    // }

    // /**
    //  * @dev Returns the downcasted int24 from int256, reverting on
    //  * overflow (when the input is less than smallest int24 or
    //  * greater than largest int24).
    //  *
    //  * Counterpart to Solidity's `int24` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 24 bits
    //  *
    //  * _Available since v4.7._
    //  */
    // function toInt24(int256 value) internal pure returns (int24) {
    //     require(
    //         value >= type(int24).min && value <= type(int24).max,
    //         "SafeCast: value doesn't fit in 24 bits"
    //     );
    //     return int24(value);
    // }

    // /**
    //  * @dev Returns the downcasted int16 from int256, reverting on
    //  * overflow (when the input is less than smallest int16 or
    //  * greater than largest int16).
    //  *
    //  * Counterpart to Solidity's `int16` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 16 bits
    //  *
    //  * _Available since v3.1._
    //  */
    // function toInt16(int256 value) internal pure returns (int16) {
    //     require(
    //         value >= type(int16).min && value <= type(int16).max,
    //         "SafeCast: value doesn't fit in 16 bits"
    //     );
    //     return int16(value);
    // }

    // /**
    //  * @dev Returns the downcasted int8 from int256, reverting on
    //  * overflow (when the input is less than smallest int8 or
    //  * greater than largest int8).
    //  *
    //  * Counterpart to Solidity's `int8` operator.
    //  *
    //  * Requirements:
    //  *
    //  * - input must fit into 8 bits
    //  *
    //  * _Available since v3.1._
    //  */
    // function toInt8(int256 value) internal pure returns (int8) {
    //     require(
    //         value >= type(int8).min && value <= type(int8).max,
    //         "SafeCast: value doesn't fit in 8 bits"
    //     );
    //     return int8(value);
    // }

    // /**
    //  * @dev Converts an unsigned uint256 into a signed int256.
    //  *
    //  * Requirements:
    //  *
    //  * - input must be less than or equal to maxInt256.
    //  *
    //  * _Available since v3.0._
    //  */
    // function toInt256(uint256 value) internal pure returns (int256) {
    //     // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
    //     require(
    //         value <= uint256(type(int256).max),
    //         "SafeCast: value doesn't fit in an int256"
    //     );
    //     return int256(value);
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../extensions/ERC721BurnableUpgradeable.sol";
import "../extensions/ERC721PausableUpgradeable.sol";
import "../extensions/ERC721EnumerableUpgradeable.sol";
import "../../../access/AccessControlEnumerableUpgradeable.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
abstract contract ERC721PresetMinterPauserAutoIdUpgradeable is
    AccessControlEnumerableUpgradeable,
    ERC721PausableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable
{
    ///@dev value is equal to keccak256("MINTER_ROLE")
    bytes32 public constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    ///@dev value is equal to keccak256("PAUSER_ROLE")
    bytes32 public constant PAUSER_ROLE =
        0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;

    uint256 internal _tokenIdTracker;

    string private _baseTokenURI;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */

    function __ERC721PresetMinterPauserAutoId_init(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) internal onlyInitializing {
        __ERC721_init_unchained(name, symbol);
        __Pausable_init_unchained();
        __ERC721PresetMinterPauserAutoId_init_unchained(
            name,
            symbol,
            baseTokenURI
        );
    }

    function __ERC721PresetMinterPauserAutoId_init_unchained(
        string memory,
        string memory,
        string memory baseTokenURI
    ) internal onlyInitializing {
        _baseTokenURI = baseTokenURI;

        address sender = _msgSender();
        _grantRole(MINTER_ROLE, sender);
        _grantRole(PAUSER_ROLE, sender);
        _grantRole(DEFAULT_ADMIN_ROLE, sender);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    // function mint(address to) public virtual {
    //     _checkRole(MINTER_ROLE, _msgSender());

    //     // We cannot just use balanceOf to create the new tokenId because tokens
    //     // can be burned (destroyed), so we need a separate counter.
    //     unchecked {
    //         _mint(to, _tokenIdTracker++);
    //     }
    // }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        _checkRole(PAUSER_ROLE, _msgSender());
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        _checkRole(PAUSER_ROLE, _msgSender());
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721PausableUpgradeable
        )
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlEnumerableUpgradeable,
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    error ERC20Permit__Expired();

    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ILockableUpgradeable {
    error Lockable__UserIsLocked();

    function setBlockUser(address account_, bool status_) external;

    function isBlocked(address account_) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Bytes32Address {
    function fromFirst20Bytes(bytes32 bytesValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := bytesValue
        }
    }

    function fillLast12Bytes(address addressValue)
        internal
        pure
        returns (bytes32 value)
    {
        assembly {
            value := addressValue
        }
    }

    function fromFirst160Bits(uint256 uintValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := uintValue
        }
    }

    function fillLast96Bits(address addressValue)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := addressValue
        }
    }

    function fromLast160Bits(uint256 uintValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := shr(0x60, uintValue)
        }
    }

    function fillFirst96Bits(address addressValue)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := shl(0x60, addressValue)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

//import "../../utils/AddressUpgradeable.sol";
error Initializable__Initializing();
error Initializable__NotInitializing();
error Initializable__AlreadyInitialized();

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint256 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    uint256 private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint256 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _initializing != 2;
        uint256 initialized = _initialized;
        if (
            !((isTopLevelCall && initialized == 0) ||
                (initialized == 1 && address(this).code.length == 0))
        ) revert Initializable__AlreadyInitialized();

        _initialized = 1;
        if (isTopLevelCall) _initializing = 2;
        _;
        if (isTopLevelCall) {
            _initializing = 1;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint256 version) {
        if (_initializing != 1 || _initialized >= version)
            revert Initializable__AlreadyInitialized();
        _initialized = version & ~uint8(0);
        _initializing = 2;
        _;
        _initializing = 1;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        if (_initializing != 2) revert Initializable__NotInitializing();
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        if (_initializing != 1) revert Initializable__Initializing();
        if (_initialized < ~uint8(0)) {
            _initialized = ~uint8(0);
            emit Initialized(~uint8(0));
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMapsUpgradeable {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index)
        internal
        view
        returns (bool)
    {
        return bitmap._data[index >> 8] & (1 << (index & 0xff)) != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) set(bitmap, index);
        else unset(bitmap, index);
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        bitmap._data[index >> 8] |= 1 << (index & 0xff);
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        bitmap._data[index >> 8] &= ~(1 << (index & 0xff));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ISignableUpgradeable {
    error Signable__InvalidSignature(address sender);

    function nonces(address sender_) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    ///@dev value is equal to keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 private constant _TYPE_HASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version)
        internal
        onlyInitializing
    {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version)
        internal
        onlyInitializing
    {
        _HASHED_NAME = keccak256(bytes(name));
        _HASHED_VERSION = keccak256(bytes(version));
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            _buildDomainSeparator(
                _TYPE_HASH,
                _EIP712NameHash(),
                _EIP712VersionHash()
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view virtual returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

//import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)
            // Directly load `s` from the calldata.
            let s := calldataload(add(signature.offset, 0x20))

            switch signature.length
            case 64 {
                // Here, `s` is actually `vs` that needs to be recovered into `v` and `s`.
                // Compute `v` and store it in the scratch space.
                mstore(0x20, add(shr(255, s), 27))
                // prettier-ignore
                s := and(s, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            }
            case 65 {
                // Compute `v` and store it in the scratch space.
                mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40))))
            }

            // If `s` in lower half order, such that the signature is not malleable.
            // prettier-ignore
            if iszero(gt(s, 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0)) {
                mstore(0x00, hash)
                calldatacopy(0x40, signature.offset, 0x20) // Directly copy `r` over.
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                result := mload(sub(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address result) {
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)
            mstore(0x20, v)
            // If `s` in lower half order, such that the signature is not malleable.
            // prettier-ignore
            if iszero(gt(s, 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0)) {
                mstore(0x00, hash)
                mstore(0x40, r)
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                result := mload(sub(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32 result)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        assembly {
            // Store into scratch space for keccak256.
            mstore(0x20, hash)
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32")
            // 0x40 - 0x04 = 0x3c
            result := keccak256(0x04, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32 result)
    {
        assembly {
            // We need at most 128 bytes for Ethereum signed message header.
            // The max length of the ASCII reprenstation of a uint256 is 78 bytes.
            // The length of "\x19Ethereum Signed Message:\n" is 26 bytes.
            // The next multiple of 32 above 78 + 26 is 128.

            // Instead of allocating, we temporarily copy the 128 bytes before the
            // start of `s` data to some variables.
            let m3 := mload(sub(s, 0x60))
            let m2 := mload(sub(s, 0x40))
            let m1 := mload(sub(s, 0x20))
            // The length of `s` is in bytes.
            let sLength := mload(s)

            let ptr := add(s, 0x20)

            // `end` marks the end of the memory which we will compute the keccak256 of.
            let end := add(ptr, sLength)

            // Convert the length of the bytes to ASCII decimal representation
            // and store it into the memory.
            for {
                let temp := sLength
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                temp := div(temp, 10)
            } {
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            // Move the pointer 32 bytes lower to make room for the string.
            // `start` marks the start of the memory which we will compute the keccak256 of.
            let start := sub(ptr, 32)
            // Copy the header over to the memory.
            mstore(
                start,
                "\x00\x00\x00\x00\x00\x00\x19Ethereum Signed Message:\n"
            )
            start := add(start, 6)

            // Compute the keccak256 of the memory.
            result := keccak256(start, sub(end, start))

            // Restore the previous memory.
            mstore(s, sLength)
            mstore(sub(s, 0x20), m1)
            mstore(sub(s, 0x40), m2)
            mstore(sub(s, 0x60), m3)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32 result)
    {
        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(
                memPtr,
                0x1901000000000000000000000000000000000000000000000000000000000000
            ) // EIP191 header
            mstore(add(memPtr, 2), domainSeparator) // EIP712 domain hash
            mstore(add(memPtr, 34), structHash) // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

error ERC1967UpgradeUpgradeable__NonZeroAddress();
error ERC1967UpgradeUpgradeable__ExecutionFailed();
error ERC1967UpgradeUpgradeable__TargetIsNotContract();
error ERC1967UpgradeUpgradeable__ImplementationIsNotUUPS();
error ERC1967UpgradeUpgradeable__UnsupportedProxiableUUID();
error ERC1967UpgradeUpgradeable__DelegateCallToNonContract();
error ERC1967UpgradeUpgradeable__ImplementationIsNotContract();

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {}

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (!_isContract(newImplementation))
            revert ERC1967UpgradeUpgradeable__ImplementationIsNotContract();
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try
                IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()
            returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT)
                    revert ERC1967UpgradeUpgradeable__UnsupportedProxiableUUID();
            } catch {
                revert ERC1967UpgradeUpgradeable__ImplementationIsNotUUPS();
            }

            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0))
            revert ERC1967UpgradeUpgradeable__NonZeroAddress();
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (!_isContract(newBeacon))
            revert ERC1967UpgradeUpgradeable__TargetIsNotContract();
        if (!_isContract(IBeaconUpgradeable(newBeacon).implementation()))
            revert ERC1967UpgradeUpgradeable__ImplementationIsNotContract();
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(
                IBeaconUpgradeable(newBeacon).implementation(),
                data
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data)
        private
        returns (bytes memory)
    {
        if (!_isContract(target))
            revert ERC1967UpgradeUpgradeable__DelegateCallToNonContract();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata);
    }

    function _isContract(address addr_) internal view returns (bool) {
        return addr_.code.length != 0;
    }

    function _verifyCallResult(bool success, bytes memory returndata)
        internal
        pure
        returns (bytes memory)
    {
        if (success) return returndata;
        else {
            // Look for revert reason and bubble it up if present
            if (returndata.length != 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, returndata), mload(returndata))
                }
            } else revert ERC1967UpgradeUpgradeable__ExecutionFailed();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot)
        internal
        pure
        returns (BooleanSlot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot)
        internal
        pure
        returns (Bytes32Slot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot)
        internal
        pure
        returns (Uint256Slot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.10;

import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../utils/structs/BitMapsUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";

import "../../../libraries/Bytes32Address.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721Upgradeable is
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using Bytes32Address for address;
    using Bytes32Address for bytes32;
    using Bytes32Address for uint256;

    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;
    string public symbol;

    function _baseURI() internal view virtual returns (string memory);

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => bytes32) internal _ownerOf;
    mapping(bytes32 => uint256) internal _balanceOf;

    function ownerOf(uint256 id)
        public
        view
        virtual
        override
        returns (address owner)
    {
        if ((owner = _ownerOf[id].fromFirst20Bytes()) == address(0))
            revert ERC721__NotMinted();
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert ERC721__NonZeroAddress();

        return _balanceOf[owner.fillLast12Bytes()];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => bytes32) internal _getApproved;

    mapping(bytes32 => BitMapsUpgradeable.BitMap) internal _isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        if (bytes(name_).length > 32 || bytes(symbol_).length > 32)
            revert ERC721__StringTooLong();
        name = name_;
        symbol = symbol_;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual override {
        address owner = _ownerOf[id].fromFirst20Bytes();
        address sender = _msgSender();
        if (
            sender != owner &&
            !_isApprovedForAll[owner.fillLast12Bytes()].get(
                sender.fillLast96Bits()
            )
        ) revert ERC721__Unauthorized();

        _getApproved[id] = spender.fillLast12Bytes();

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        address sender = _msgSender();
        _isApprovedForAll[sender.fillLast12Bytes()].setTo(
            operator.fillLast96Bits(),
            approved
        );

        emit ApprovalForAll(sender, operator, approved);
    }

    function getApproved(uint256 tokenId)
        external
        view
        override
        returns (address operator)
    {
        return _getApproved[tokenId].fromFirst20Bytes();
    }

    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return
            _isApprovedForAll[owner.fillLast12Bytes()].get(
                operator.fillFirst96Bits()
            );
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            _isApprovedForAll[owner.fillLast12Bytes()].get(
                spender.fillLast96Bits()
            ) ||
            _getApproved[tokenId] == spender.fillLast12Bytes());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        if (from != _ownerOf[id].fromFirst20Bytes()) revert ERC721__WrongFrom();
        if (to == address(0)) revert ERC721__InvalidRecipient();
        _beforeTokenTransfer(from, to, id);

        address sender = _msgSender();
        bytes32 _from = from.fillLast12Bytes();
        if (
            sender != from &&
            !_isApprovedForAll[_from].get(sender.fillLast96Bits()) &&
            sender.fillLast12Bytes() != _getApproved[id]
        ) revert ERC721__Unauthorized();

        bytes32 _to = to.fillLast12Bytes();
        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            --_balanceOf[_from];

            ++_balanceOf[_to];
        }

        _ownerOf[id] = _to;

        delete _getApproved[id];

        emit Transfer(from, to, id);

        _afterTokenTransfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiverUpgradeable(to).onERC721Received(
                _msgSender(),
                from,
                id,
                ""
            ) !=
            ERC721TokenReceiverUpgradeable.onERC721Received.selector
        ) revert ERC721__UnsafeRecipient();
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (from != _ownerOf[tokenId].fromFirst20Bytes())
            revert ERC721__WrongFrom();
        if (to == address(0)) revert ERC721__InvalidRecipient();
        _beforeTokenTransfer(from, to, tokenId);

        bytes32 _to = to.fillLast12Bytes();

        unchecked {
            --_balanceOf[from.fillLast12Bytes()];
            ++_balanceOf[_to];
        }
        _ownerOf[tokenId] = _to;

        delete _getApproved[tokenId];

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual override {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiverUpgradeable(to).onERC721Received(
                _msgSender(),
                from,
                id,
                data
            ) !=
            ERC721TokenReceiverUpgradeable.onERC721Received.selector
        ) revert ERC721__UnsafeRecipient();
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert ERC721__InvalidRecipient();
        if (_ownerOf[id] != 0) revert ERC721__AlreadyMinted();

        _beforeTokenTransfer(address(0), to, id);
        bytes32 _to = to.fillLast12Bytes();
        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[_to]++;
        }
        _ownerOf[id] = _to;

        emit Transfer(address(0), to, id);

        _afterTokenTransfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id].fromFirst20Bytes();

        if (owner == address(0)) revert ERC721__NotMinted();

        _beforeTokenTransfer(owner, address(0), id);

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner.fillLast12Bytes()]--;
        }

        delete _ownerOf[id];

        delete _getApproved[id];

        emit Transfer(owner, address(0), id);

        _afterTokenTransfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiverUpgradeable(to).onERC721Received(
                _msgSender(),
                address(0),
                id,
                ""
            ) !=
            ERC721TokenReceiverUpgradeable.onERC721Received.selector
        ) revert ERC721__UnsafeRecipient();
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiverUpgradeable(to).onERC721Received(
                _msgSender(),
                address(0),
                id,
                data
            ) !=
            ERC721TokenReceiverUpgradeable.onERC721Received.selector
        ) revert ERC721__UnsafeRecipient();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiverUpgradeable {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiverUpgradeable.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../../libraries/EnumerableSet256.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is
    IAccessControlEnumerableUpgradeable,
    AccessControlUpgradeable
{
    function __AccessControlEnumerable_init() internal onlyInitializing {}

    function __AccessControlEnumerable_init_unchained()
        internal
        onlyInitializing
    {}

    using EnumerableSet256 for EnumerableSet256.AddressSet;

    mapping(bytes32 => EnumerableSet256.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId ==
            type(IAccessControlEnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getAllRoleMembers(bytes32 role_)
        public
        view
        virtual
        override
        returns (address[] memory)
    {
        return _roleMembers[role_].values();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        virtual
        override
        returns (address)
    {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.10;

import "../ERC721Upgradeable.sol";

error ERC721Burnable__OnlyOwnerOrApproved();

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */

abstract contract ERC721BurnableUpgradeable is ERC721Upgradeable {
    function __ERC721Burnable_init() internal onlyInitializing {}

    function __ERC721Burnable_init_unchained() internal onlyInitializing {}

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert ERC721Burnable__OnlyOwnerOrApproved();
        _burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721PausableUpgradeable is
    ERC721Upgradeable,
    PausableUpgradeable
{
    function __ERC721Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC721Pausable_init_unchained() internal onlyInitializing {}

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        _requireNotPaused();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is
    ERC721Upgradeable,
    IERC721EnumerableUpgradeable
{
    using Bytes32Address for address;
    // Mapping from owner to list of owned token IDs
    mapping(bytes32 => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    function __ERC721Enumerable_init() internal onlyInitializing {}

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (index >= balanceOf(owner)) revert ERC721Enumerable__OutOfBounds();
        return _ownedTokens[owner.fillLast12Bytes()][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (index != totalSupply()) revert ERC721Enumerable__OutOfBounds();
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) _addTokenToAllTokensEnumeration(tokenId);
        else if (from != to) _removeTokenFromOwnerEnumeration(from, tokenId);

        if (to == address(0)) _removeTokenFromAllTokensEnumeration(tokenId);
        else if (to != from) _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to.fillLast12Bytes()][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
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
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        bytes32 _from = from.fillLast12Bytes();
        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[_from][lastTokenIndex];

            _ownedTokens[_from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[_from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {}

    function __ERC165_init_unchained() internal onlyInitializing {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    error ERC721__NotMinted();
    error ERC721__WrongFrom();
    error ERC721__Unauthorized();
    error ERC721__StringTooLong();
    error ERC721__AlreadyMinted();
    error ERC721__NonZeroAddress();
    error ERC721__UnsafeRecipient();
    error ERC721__InvalidRecipient();
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getAllRoleMembers(bytes32 role_)
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";

import "../../libraries/BitMap256.sol";
import "../../libraries/Bytes32Address.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is
    ContextUpgradeable,
    IAccessControlUpgradeable,
    ERC165Upgradeable
{
    using Bytes32Address for address;
    using BitMap256 for BitMap256.BitMap;

    function __AccessControl_init() internal onlyInitializing {}

    function __AccessControl_init_unchained() internal onlyInitializing {}

    mapping(bytes32 => bytes32) private _adminRoles;
    mapping(bytes32 => BitMap256.BitMap) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _hasRole(uint256(role), account.fillLast12Bytes());
    }

    function _hasRole(uint256 role, bytes32 bytes32Addr)
        internal
        view
        virtual
        returns (bool)
    {
        return _roles[bytes32Addr].unsafeGet(role);
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account))
            revert AccessControl__RoleMissing(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _adminRoles[role];
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        if (account != _msgSender()) revert AccessControl__Unauthorized();
        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _adminRoles[role] = adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (_grantRole(uint256(role), account.fillLast12Bytes()))
            emit RoleGranted(role, account, _msgSender());
    }

    function _grantRole(uint256 role, bytes32 account)
        internal
        virtual
        returns (bool)
    {
        if (!_hasRole(role, account)) {
            _roles[account].unsafeSet(role);
            return true;
        }
        return false;
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (_revokeRole(uint256(role), account.fillLast12Bytes())) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function _revokeRole(uint256 role, bytes32 account)
        internal
        virtual
        returns (bool)
    {
        if (_hasRole(role, account)) {
            _roles[account].unsafeUnset(role);
            return true;
        }
        return false;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.17;

import "./Array.sol";
import "./BitMap256.sol";

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet256 {
    using Array for uint256[256];
    using BitMap256 for uint256;
    using BitMap256 for BitMap256.BitMap;
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        uint256 length;
        // Storage of set values
        uint256[256] _values;
        BitMap256.BitMap _indexes;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, uint256 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values[value.index()] = value;
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            //set._indexes[value] = set._values.length;
            ++set.length;
            return true;
        } else return false;
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, uint256 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._values[value.index()] == value ? value.index() : 0;

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            //uint256 toDeleteIndex;
            // uint256 lastIndex;
            // unchecked {
            //     //toDeleteIndex = valueIndex - 1;
            //     lastIndex = --set.length;
            // }

            set._values[valueIndex] = 0;

            // if (valueIndex != lastIndex) {
            //     uint256 lastValue = set._values[lastIndex];

            //     // Move the last value to the index where the value to delete is
            //     set._values[valueIndex] = lastValue;
            //     // Update the index for the moved value
            //     //set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            // }

            // Delete the slot where the moved value was stored
            //set._values.pop();

            // Delete the index for the deleted slot
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, uint256 value)
        private
        view
        returns (bool)
    {
        //return set._indexes[value] != 0;
        return set._values[value.index()] == value;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (uint256)
    {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (uint256[] memory) {
        uint256[256] memory val = set._values;
        return val.trimZero(set.length);
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        uint256 val;
        assembly {
            val := value
        }
        return _add(set._inner, val);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        uint256 val;
        assembly {
            val := value
        }
        return _remove(set._inner, val);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        uint256 val;
        assembly {
            val := value
        }
        return _contains(set._inner, val);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        uint256 val = _at(set._inner, index);
        bytes32 val_;
        assembly {
            val_ := val
        }
        return val_;
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory res)
    {
        uint256[] memory val = _values(set._inner);
        res = new bytes32[](val.length);
        assembly {
            res := val
        }
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        uint256 store;
        assembly {
            store := value
        }
        return _add(set._inner, store);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        uint256 store;
        assembly {
            store := value
        }
        return _remove(set._inner, store);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        uint256 store;
        assembly {
            store := value
        }
        return _contains(set._inner, store);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address addr)
    {
        uint256 value = _at(set._inner, index);
        assembly {
            addr := value
        }
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        uint256[] memory store = _values(set._inner);
        address[] memory result = new address[](store.length);

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        return _values(set._inner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    error AccessControl__Unauthorized();
    error AccessControl__RoleMissing(bytes32 role, address account);
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;

    function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///@dev can store up to 256 slots
library BitMap256 {
    struct BitMap {
        uint256 data;
    }

    function index(uint256 value_) internal pure returns (uint256) {
        return value_ & 0xff;
    }

    function indexHash(uint256 value) internal pure returns (uint256 idx) {
        assembly {
            mstore(0x00, value)
            idx := keccak256(0x00, 32)
        }
    }

    function unsafeGet(BitMap storage bitmap_, uint256 value_)
        internal
        view
        returns (bool isSet)
    {
        assembly {
            isSet := and(sload(bitmap_.slot), shl(and(value_, 0xff), 1))
        }
    }

    function unsafeGet(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (bool isSet)
    {
        assembly {
            isSet := and(bitmap_, shl(and(value_, 0xff), 1))
        }
    }

    function get(BitMap storage bitmap_, uint256 value_)
        internal
        view
        returns (bool isSet)
    {
        assembly {
            mstore(0x00, value_)
            isSet := and(
                sload(bitmap_.slot),
                shl(and(keccak256(0x00, 32), 0xff), 1)
            )
        }
    }

    function get(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (bool isSet)
    {
        assembly {
            mstore(0x00, value_)
            isSet := and(bitmap_, shl(and(keccak256(0x00, 32), 0xff), 1))
        }
    }

    function setData(BitMap storage bitmap_, uint256 value) internal {
        assembly {
            sstore(bitmap_.slot, value)
        }
    }

    function setTo(
        BitMap storage bitmap_,
        uint256 value_,
        bool status_
    ) internal {
        if (status_) set(bitmap_, value_);
        else unset(bitmap_, value_);
    }

    function unsafeSet(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            sstore(
                bitmap_.slot,
                or(sload(bitmap_.slot), shl(and(value_, 0xff), 1))
            )
        }
    }

    function unsafeSet(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (uint256 bitmap)
    {
        assembly {
            bitmap := or(bitmap_, shl(and(value_, 0xff), 1))
        }
    }

    function set(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            mstore(0x00, value_)
            sstore(
                bitmap_.slot,
                or(sload(bitmap_.slot), shl(and(keccak256(0x00, 32), 0xff), 1))
            )
        }
    }

    function set(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (uint256 bitmap)
    {
        assembly {
            mstore(0x00, value_)
            bitmap := or(bitmap_, shl(and(keccak256(0x00, 32), 0xff), 1))
        }
    }

    function unsafeUnset(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            sstore(
                bitmap_.slot,
                and(sload(bitmap_.slot), not(shl(and(value_, 0xff), 1)))
            )
        }
    }

    function unsafeUnset(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (uint256 bitmap)
    {
        assembly {
            bitmap := and(bitmap_, not(shl(and(value_, 0xff), 1)))
        }
    }

    function unset(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            mstore(0x00, value_)
            sstore(
                bitmap_.slot,
                and(
                    sload(bitmap_.slot),
                    not(shl(and(keccak256(0x00, 32), 0xff), 1))
                )
            )
        }
    }

    function unset(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (uint256 bitmap)
    {
        assembly {
            mstore(0x00, value_)
            bitmap := and(bitmap_, not(shl(and(keccak256(0x00, 32), 0xff), 1)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BitMap256.sol";

library Array {
    using BitMap256 for uint256;

    // 100 record ~= 60k gas
    function buildSet(uint256[] memory arr_)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 length = arr_.length;
        {
            uint256 val;
            uint256 bitmap;
            for (uint256 i; i < length; ) {
                unchecked {
                    val = arr_[i];
                    while (length > i && bitmap.get(val)) val = arr_[--length];
                    bitmap = bitmap.set(arr_[i] = val);
                    ++i;
                }
            }
        }
        assembly {
            mstore(arr_, length)
        }
        return arr_;
    }

    function trimZero(uint256[] memory arr_)
        internal
        pure
        returns (uint256[] memory res)
    {
        res = arr_;
        uint256 length = res.length;
        uint256 counter;
        for (uint256 i; i < length; ) {
            unchecked {
                if (arr_[i] != 0) res[counter++] = arr_[i];
                ++i;
            }
        }
        assembly {
            mstore(res, counter)
        }
    }

    function trimZero(uint256[256] memory arr_, uint256 size_)
        internal
        pure
        returns (uint256[] memory res)
    {
        res = new uint256[](size_);
        uint256 length = arr_.length;
        uint256 counter;
        for (uint256 i; i < length; ) {
            unchecked {
                if (arr_[i] != 0) res[counter++] = arr_[i];
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";

error Pausable__Paused();
error Pausable__NotPaused();

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    uint256 private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = 1;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool isPaused) {
        assembly {
            isPaused := eq(2, sload(_paused.slot))
        }
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) revert Pausable__Paused();
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) revert Pausable__NotPaused();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = 2;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = 1;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    error ERC721Enumerable__OutOfBounds();

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IRentableNFTUpgradeable {
    error Rentable__PaymentFailed();
    error Rentable__NotValidTransfer();
    error Rentable__OnlyOwnerOrApproved();
    // Logged when the user of a NFT is changed or expires is changed
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UserUpdated(uint256 indexed tokenId, address indexed user);

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns (address);
}
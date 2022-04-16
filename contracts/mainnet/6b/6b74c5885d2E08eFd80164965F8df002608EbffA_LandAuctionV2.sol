// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/ILockShiboshi.sol";
import "./interfaces/ILockLeash.sol";
import "./interfaces/ILandRegistry.sol";
import "./interfaces/ILandAuction.sol";

import "./LandAuction.sol";

contract LandAuctionV2 is ILandAuction, AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    uint32 constant clearLow = 0xffff0000;
    uint32 constant clearHigh = 0x0000ffff;
    uint32 constant factor = 0x10000;

    /*
        xLow, yHigh gets mapped to 1,1
        transform: x + 97, 100 - y

        y_mapped = 100 - y
        x_mapped = 97 + x
    */

    int16 public constant xLow = -96;
    int16 public constant yLow = -99;
    int16 public constant xHigh = 96;
    int16 public constant yHigh = 99;

    enum Stage {
        Default,
        Inactive,
        PrivateSale,
        PublicSale
    }

    struct Bid {
        uint256 amount;
        address bidder;
    }

    LandAuction public auctionV1;
    ILandRegistry public landRegistry;
    ILockLeash public lockLeash;
    ILockShiboshi public lockShiboshi;
    bool public multiMintEnabled;

    address public signerAddress;
    Stage public currentStage;

    mapping(int16 => mapping(int16 => Bid)) public getCurrentBid;
    mapping(address => uint256) private _winningsBidsOf;

    mapping(address => uint32[]) private _mintedBy;
    mapping(address => uint32[]) private _allBidsOf;
    mapping(address => mapping(uint32 => uint8)) private _statusOfBidsOf;

    event StageSet(uint256 stage);
    event SignerSet(address signer);
    event multiMintToggled(bool newValue);
    event LandBought(
        address indexed user,
        uint32 indexed encXY,
        int16 x,
        int16 y,
        uint256 price,
        uint256 time,
        Stage saleStage
    );

    constructor(
        LandAuction _auctionV1,
        ILandRegistry _landRegistry,
        ILockLeash _lockLeash,
        ILockShiboshi _lockShiboshi
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        auctionV1 = _auctionV1;
        landRegistry = _landRegistry;
        lockLeash = _lockLeash;
        lockShiboshi = _lockShiboshi;

        signerAddress = msg.sender;
    }

    modifier onlyValid(int16 x, int16 y) {
        require(xLow <= x && x <= xHigh, "ERR_X_OUT_OF_RANGE");
        require(yLow <= y && y <= yHigh, "ERR_Y_OUT_OF_RANGE");
        _;
    }

    modifier onlyStage(Stage s) {
        require(currentStage == s, "ERR_THIS_STAGE_NOT_LIVE_YET");
        _;
    }

    function weightToCapacity(uint256 weightLeash, uint256 weightShiboshi)
        public
        pure
        returns (uint256)
    {
        uint256[10] memory QRangeLeash = [
            uint256(9),
            uint256(30),
            uint256(60),
            uint256(100),
            uint256(130),
            uint256(180),
            uint256(220),
            uint256(300),
            uint256(370),
            uint256(419)
        ];
        uint256[10] memory QRangeShiboshi = [
            uint256(45),
            uint256(89),
            uint256(150),
            uint256(250),
            uint256(350),
            uint256(480),
            uint256(600),
            uint256(700),
            uint256(800),
            uint256(850)
        ];
        uint256[10] memory buckets = [
            uint256(1),
            uint256(5),
            uint256(10),
            uint256(20),
            uint256(50),
            uint256(80),
            uint256(100),
            uint256(140),
            uint256(180),
            uint256(200)
        ];
        uint256 capacity;

        if (weightLeash > 0) {
            for (uint256 i = 9; i >= 0; i = _uncheckedDec(i)) {
                if (weightLeash > QRangeLeash[i] * 1e18) {
                    capacity += buckets[i];
                    break;
                }
            }
        }

        if (weightShiboshi > 0) {
            for (uint256 i = 9; i >= 0; i = _uncheckedDec(i)) {
                if (weightShiboshi > QRangeShiboshi[i]) {
                    capacity += buckets[i];
                    break;
                }
            }
        }

        return capacity;
    }

    function getOutbidPrice(uint256 bidPrice) public pure returns (uint256) {
        // 5% more than the current price
        return (bidPrice * 21) / 20;
    }

    function winningsBidsOf(address user) public view returns (uint256) {
        return _winningsBidsOf[user] + auctionV1.winningsBidsOf(user);
    }

    function availableCapacityOf(address user) public view returns (uint256) {
        uint256 weightLeash = lockLeash.weightOf(user);
        uint256 weightShiboshi = lockShiboshi.weightOf(user);

        return
            weightToCapacity(weightLeash, weightShiboshi) -
            winningsBidsOf(user);
    }

    function getReservePrice(int16 x, int16 y) public view returns (uint256) {
        return auctionV1.getReservePrice(x, y);
    }

    function getPriceOf(int16 x, int16 y) public view returns (uint256) {
        Bid storage currentBid = getCurrentBid[x][y];
        if (currentBid.amount == 0) {
            // no bids on this contract
            return auctionV1.getPriceOf(x, y);
        } else {
            // attempt to outbid a bid placed here
            return getOutbidPrice(currentBid.amount);
        }
    }

    function priceOfCategory(int8 category) external view returns (uint256) {
        return auctionV1.priceOfCategory(category);
    }

    function getCategory(int16 x, int16 y) public view returns (int8) {
        return auctionV1.getCategory(x, y);
    }

    function isShiboshiZone(int16 x, int16 y) public pure returns (bool) {
        /*
            (12,99) to (48, 65)
            (49, 99) to (77, 78)
            (76, 77) to (77, 50)
            (65, 50) to (75, 50)
        */

        if (x >= 12 && x <= 48 && y <= 99 && y >= 65) {
            return true;
        }
        if (x >= 49 && x <= 77 && y <= 99 && y >= 78) {
            return true;
        }
        if (x >= 76 && x <= 77 && y <= 77 && y >= 50) {
            return true;
        }
        if (x >= 65 && x <= 75 && y == 50) {
            return true;
        }
        return false;
    }

    // List of currently winning bids of this user
    function bidInfoOf(address user)
        external
        view
        returns (int16[] memory, int16[] memory)
    {
        (int16[] memory xsV1, int16[] memory ysV1) = auctionV1.bidInfoOf(user);
        uint256 lengthV1 = xsV1.length;

        uint256 bidCount = _winningsBidsOf[user];
        int16[] memory xs = new int16[](bidCount + lengthV1);
        int16[] memory ys = new int16[](bidCount + lengthV1);

        for (uint256 i = 0; i < lengthV1; i = _uncheckedInc(i)) {
            xs[i] = xsV1[i];
            ys[i] = ysV1[i];
        }

        uint256 ptr = lengthV1;
        uint32[] storage allBids = _allBidsOf[user];
        uint256 length = allBids.length;

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            if (_statusOfBidsOf[user][allBids[i]] == 1) {
                (int16 x, int16 y) = _decodeXY(allBids[i]);
                xs[ptr] = x;
                ys[ptr] = y;
                ptr = _uncheckedInc(ptr);
            }
        }

        return (xs, ys);
    }

    // List of all bids, ever done by this user
    function allBidInfoOf(address user)
        external
        view
        returns (int16[] memory, int16[] memory)
    {
        (int16[] memory xsV1, int16[] memory ysV1) = auctionV1.allBidInfoOf(
            user
        );
        uint256 lengthV1 = xsV1.length;

        uint32[] storage allBids = _allBidsOf[user];
        uint256 bidCount = allBids.length;
        int16[] memory xs = new int16[](bidCount + lengthV1);
        int16[] memory ys = new int16[](bidCount + lengthV1);

        for (uint256 i = 0; i < lengthV1; i = _uncheckedInc(i)) {
            xs[i] = xsV1[i];
            ys[i] = ysV1[i];
        }

        for (
            uint256 i = lengthV1;
            i < lengthV1 + bidCount;
            i = _uncheckedInc(i)
        ) {
            (int16 x, int16 y) = _decodeXY(allBids[i - lengthV1]);
            xs[i] = x;
            ys[i] = y;
        }

        return (xs, ys);
    }

    function mintedBy(address user) external
        view
        returns (int16[] memory, int16[] memory) {

            uint32[] storage allMints = _mintedBy[user];
            uint256 mintCount = allMints.length;
            int16[] memory xs = new int16[](mintCount);
            int16[] memory ys = new int16[](mintCount);

            for (uint256 i = 0; i < mintCount; i = _uncheckedInc(i)) {
                (int16 x, int16 y) = _decodeXY(allMints[i]);
                xs[i] = x;
                ys[i] = y;
            }

            return (xs, ys);
        }


    function setStage(uint256 stage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (stage >= 2) {
            require(
                uint256(auctionV1.currentStage()) == 0,
                "ERR_AUCTION_V1_IS_NOT_DISABLED"
            );
        }
        currentStage = Stage(stage);
        emit StageSet(stage);
    }

    function setSignerAddress(address signer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(signer != address(0), "ERR_CANNOT_BE_ZERO_ADDRESS");
        signerAddress = signer;
        emit SignerSet(signer);
    }

    function setLandRegistry(address _landRegistry)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        landRegistry = ILandRegistry(_landRegistry);
    }

    function setLockLeash(address _lockLeash)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lockLeash = ILockLeash(_lockLeash);
    }

    function setLockShiboshi(address _lockShiboshi)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lockShiboshi = ILockShiboshi(_lockShiboshi);
    }

    function setAuctionV1(LandAuction _auctionV1)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        auctionV1 = _auctionV1;
    }

    function setMultiMint(bool desiredValue)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(multiMintEnabled != desiredValue, "ERR_ALREADY_DESIRED_VALUE");
        multiMintEnabled = desiredValue;

        emit multiMintToggled(desiredValue);
    }

    function withdraw(address to, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payable(to).transfer(amount);
    }

    function mintWinningBid(int16[] calldata xs, int16[] calldata ys) external {
        require(
            currentStage == Stage.PublicSale ||
                currentStage == Stage.PrivateSale,
            "ERR_MUST_WAIT_FOR_BIDDING_TO_END"
        );

        uint256 length = xs.length;
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];
            require(xLow <= x && x <= xHigh, "ERR_X_OUT_OF_RANGE");
            require(yLow <= y && y <= yHigh, "ERR_Y_OUT_OF_RANGE");

            (, address user) = auctionV1.getCurrentBid(x, y);
            require(user != address(0), "ERR_NO_BID_FOUND");
            landRegistry.mint(user, x, y);
            _mintedBy[user].push(_encodeXY(x, y));
        }
    }

    function mintPrivate(int16 x, int16 y)
        external
        payable
        onlyStage(Stage.PrivateSale)
        nonReentrant
    {
        require(availableCapacityOf(msg.sender) != 0, "ERR_NO_BIDS_REMAINING");
        require(!isShiboshiZone(x, y), "ERR_NO_MINT_IN_SHIBOSHI_ZONE");
        _mintPublicOrPrivate(msg.sender, x, y, msg.value);
        emit LandBought(
            msg.sender,
            _encodeXY(x, y),
            x,
            y,
            msg.value,
            block.timestamp,
            Stage.PrivateSale
        );
    }

    function mintPrivateMulti(
        int16[] calldata xs,
        int16[] calldata ys,
        uint256[] calldata prices
    ) external payable onlyStage(Stage.PrivateSale) nonReentrant {
        require(multiMintEnabled, "ERR_MULTI_BID_DISABLED");

        uint256 length = xs.length;
        require(length != 0, "ERR_NO_INPUT");
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");
        require(length == prices.length, "ERR_INPUT_LENGTH_MISMATCH");

        address user = msg.sender;
        require(
            availableCapacityOf(user) >= length,
            "ERR_INSUFFICIENT_BIDS_REMAINING"
        );

        uint256 total;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            total += prices[i];
        }
        require(msg.value == total, "ERR_INSUFFICIENT_AMOUNT_SENT");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];
            require(!isShiboshiZone(x, y), "ERR_NO_MINT_IN_SHIBOSHI_ZONE");
            _mintPublicOrPrivate(user, x, y, prices[i]);
            emit LandBought(
                user,
                _encodeXY(x, y),
                x,
                y,
                prices[i],
                block.timestamp,
                Stage.PrivateSale
            );
        }
    }

    function mintPrivateShiboshiZone(
        int16 x,
        int16 y,
        bytes calldata signature
    ) external payable onlyStage(Stage.PrivateSale) nonReentrant {
        require(
            _verifySigner(_hashMessage(msg.sender), signature),
            "ERR_SIGNATURE_INVALID"
        );
        require(isShiboshiZone(x, y), "ERR_NOT_IN_SHIBOSHI_ZONE");
        _mintPublicOrPrivate(msg.sender, x, y, msg.value);
        emit LandBought(
            msg.sender,
            _encodeXY(x, y),
            x,
            y,
            msg.value,
            block.timestamp,
            Stage.PrivateSale
        );
    }

    function mintPrivateShiboshiZoneMulti(
        int16[] calldata xs,
        int16[] calldata ys,
        uint256[] calldata prices,
        bytes calldata signature
    ) external payable onlyStage(Stage.PrivateSale) nonReentrant {
        require(multiMintEnabled, "ERR_MULTI_BID_DISABLED");

        address user = msg.sender;
        require(
            _verifySigner(_hashMessage(user), signature),
            "ERR_SIGNATURE_INVALID"
        );

        uint256 length = xs.length;
        require(length != 0, "ERR_NO_INPUT");
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");
        require(length == prices.length, "ERR_INPUT_LENGTH_MISMATCH");

        uint256 total;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            total += prices[i];
        }
        require(msg.value == total, "ERR_INSUFFICIENT_AMOUNT_SENT");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];
            require(isShiboshiZone(x, y), "ERR_NOT_IN_SHIBOSHI_ZONE");
            _mintPublicOrPrivate(user, x, y, prices[i]);
            emit LandBought(
                user,
                _encodeXY(x, y),
                x,
                y,
                prices[i],
                block.timestamp,
                Stage.PrivateSale
            );
        }
    }

    function mintPublic(int16 x, int16 y)
        external
        payable
        onlyStage(Stage.PublicSale)
        nonReentrant
    {
        _mintPublicOrPrivate(msg.sender, x, y, msg.value);
        emit LandBought(
            msg.sender,
            _encodeXY(x, y),
            x,
            y,
            msg.value,
            block.timestamp,
            Stage.PublicSale
        );
    }

    function mintPublicMulti(
        int16[] calldata xs,
        int16[] calldata ys,
        uint256[] calldata prices
    ) external payable onlyStage(Stage.PublicSale) nonReentrant {
        require(multiMintEnabled, "ERR_MULTI_BID_DISABLED");

        uint256 length = xs.length;
        require(length != 0, "ERR_NO_INPUT");
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");
        require(length == prices.length, "ERR_INPUT_LENGTH_MISMATCH");

        uint256 total;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            total += prices[i];
        }
        require(msg.value == total, "ERR_INSUFFICIENT_AMOUNT_SENT");

        address user = msg.sender;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];
            _mintPublicOrPrivate(user, x, y, prices[i]);
            emit LandBought(
                user,
                _encodeXY(x, y),
                x,
                y,
                prices[i],
                block.timestamp,
                Stage.PublicSale
            );
        }
    }

    // transform: +97, +100
    function _transformXY(int16 x, int16 y)
        internal
        pure
        onlyValid(x, y)
        returns (uint16, uint16)
    {
        return (uint16(x + 97), uint16(100 - y));
    }

    function _mintPublicOrPrivate(
        address user,
        int16 x,
        int16 y,
        uint256 price
    ) internal onlyValid(x, y) {
        Bid storage currentBid = getCurrentBid[x][y];
        require(currentBid.amount == 0, "ERR_NOT_UP_FOR_SALE");
        require(price == getReservePrice(x, y), "ERR_INSUFFICIENT_AMOUNT_SENT");

        currentBid.bidder = user;
        currentBid.amount = price;
        _winningsBidsOf[user] += 1;

        uint32 encXY = _encodeXY(x, y);
        _allBidsOf[user].push(encXY);
        _statusOfBidsOf[user][encXY] = 1;

        landRegistry.mint(user, x, y);
    }

    function _hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender));
    }

    function _verifySigner(bytes32 messageHash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            signerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    function _uncheckedInc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    function _uncheckedDec(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i - 1;
        }
    }

    function _encodeXY(int16 x, int16 y) internal pure returns (uint32) {
        return
            ((uint32(uint16(x)) * factor) & clearLow) |
            (uint32(uint16(y)) & clearHigh);
    }

    function _decodeXY(uint32 value) internal pure returns (int16 x, int16 y) {
        x = _expandNegative16BitCast((value & clearLow) >> 16);
        y = _expandNegative16BitCast(value & clearHigh);
    }

    function _expandNegative16BitCast(uint32 value)
        internal
        pure
        returns (int16)
    {
        if (value & (1 << 15) != 0) {
            return int16(int32(value | clearLow));
        }
        return int16(int32(value));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
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
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function allowance(address owner, address spender) external view returns (uint256);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
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
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILockShiboshi {
    function lockInfoOf(address user)
        external
        view
        returns (
            uint256[] memory ids,
            uint256 startTime,
            uint256 numDays,
            address ogUser
        );

    function weightOf(address user) external view returns (uint256);

    function extraShiboshiNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256);

    function extraDaysNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256);

    function isWinner(address user) external view returns (bool);

    function unlockAt(address user) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILockLeash {
    function lockInfoOf(address user)
        external
        view
        returns (
            uint256 amount,
            uint256 startTime,
            uint256 numDays,
            address ogUser
        );

    function weightOf(address user) external view returns (uint256);

    function extraLeashNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256);

    function extraDaysNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256);

    function isWinner(address user) external view returns (bool);

    function unlockAt(address user) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILandRegistry {
    function mint(
        address user,
        int16 x,
        int16 y
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILandAuction {
    function winningsBidsOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/ILockShiboshi.sol";
import "./interfaces/ILockLeash.sol";
import "./interfaces/ILandRegistry.sol";
import "./interfaces/ILandAuction.sol";

contract LandAuction is ILandAuction, AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    bytes32 public constant GRID_SETTER_ROLE = keccak256("GRID_SETTER_ROLE");

    uint32 constant clearLow = 0xffff0000;
    uint32 constant clearHigh = 0x0000ffff;
    uint32 constant factor = 0x10000;

    uint16 public constant N = 194; // xHigh + 97 + 1
    uint16 public constant M = 200; // yHigh + 100 + 1

    /*
        xLow, yHigh gets mapped to 1,1
        transform: x + 97, 100 - y

        y_mapped = 100 - y
        x_mapped = 97 + x
    */

    int16 public constant xLow = -96;
    int16 public constant yLow = -99;
    int16 public constant xHigh = 96;
    int16 public constant yHigh = 99;

    enum Stage {
        Default,
        Bidding,
        PrivateSale,
        PublicSale
    }

    struct Bid {
        uint256 amount;
        address bidder;
    }

    address public immutable weth;
    ILandRegistry public landRegistry;
    ILockLeash public lockLeash;
    ILockShiboshi public lockShiboshi;
    bool public multiBidEnabled;

    address public signerAddress;
    Stage public currentStage;

    int8[N + 10][M + 10] private _categoryBIT;

    mapping(int16 => mapping(int16 => Bid)) public getCurrentBid;
    mapping(int8 => uint256) public priceOfCategory;
    mapping(address => uint256) public winningsBidsOf;

    mapping(address => uint32[]) private _allBidsOf;
    mapping(address => mapping(uint32 => uint8)) private _statusOfBidsOf;

    event CategoryPriceSet(int8 category, uint256 price);
    event StageSet(uint256 stage);
    event SignerSet(address signer);
    event multiBidToggled(bool newValue);
    event BidCreated(
        address indexed user,
        uint32 indexed encXY,
        int16 x,
        int16 y,
        uint256 price,
        uint256 time
    );
    event LandBought(
        address indexed user,
        uint32 indexed encXY,
        int16 x,
        int16 y,
        uint256 price,
        Stage saleStage
    );

    constructor(
        address _weth,
        ILandRegistry _landRegistry,
        ILockLeash _lockLeash,
        ILockShiboshi _lockShiboshi
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GRID_SETTER_ROLE, msg.sender);

        weth = _weth;
        landRegistry = _landRegistry;
        lockLeash = _lockLeash;
        lockShiboshi = _lockShiboshi;

        signerAddress = msg.sender;
    }

    modifier onlyValid(int16 x, int16 y) {
        require(xLow <= x && x <= xHigh, "ERR_X_OUT_OF_RANGE");
        require(yLow <= y && y <= yHigh, "ERR_Y_OUT_OF_RANGE");
        _;
    }

    modifier onlyStage(Stage s) {
        require(currentStage == s, "ERR_THIS_STAGE_NOT_LIVE_YET");
        _;
    }

    function weightToCapacity(uint256 weightLeash, uint256 weightShiboshi)
        public
        pure
        returns (uint256)
    {
        uint256[10] memory QRangeLeash = [
            uint256(9),
            uint256(30),
            uint256(60),
            uint256(100),
            uint256(130),
            uint256(180),
            uint256(220),
            uint256(300),
            uint256(370),
            uint256(419)
        ];
        uint256[10] memory QRangeShiboshi = [
            uint256(45),
            uint256(89),
            uint256(150),
            uint256(250),
            uint256(350),
            uint256(480),
            uint256(600),
            uint256(700),
            uint256(800),
            uint256(850)
        ];
        uint256[10] memory buckets = [
            uint256(1),
            uint256(5),
            uint256(10),
            uint256(20),
            uint256(50),
            uint256(80),
            uint256(100),
            uint256(140),
            uint256(180),
            uint256(200)
        ];
        uint256 capacity;

        if (weightLeash > 0) {
            for (uint256 i = 9; i >= 0; i = _uncheckedDec(i)) {
                if (weightLeash > QRangeLeash[i] * 1e18) {
                    capacity += buckets[i];
                    break;
                }
            }
        }

        if (weightShiboshi > 0) {
            for (uint256 i = 9; i >= 0; i = _uncheckedDec(i)) {
                if (weightShiboshi > QRangeShiboshi[i]) {
                    capacity += buckets[i];
                    break;
                }
            }
        }

        return capacity;
    }

    function getOutbidPrice(uint256 bidPrice) public pure returns (uint256) {
        // 5% more than the current price
        return (bidPrice * 21) / 20;
    }

    function availableCapacityOf(address user) public view returns (uint256) {
        uint256 weightLeash = lockLeash.weightOf(user);
        uint256 weightShiboshi = lockShiboshi.weightOf(user);

        return
            weightToCapacity(weightLeash, weightShiboshi) -
            winningsBidsOf[user];
    }

    function getReservePrice(int16 x, int16 y) public view returns (uint256) {
        uint256 price = priceOfCategory[getCategory(x, y)];
        require(price != 0, "ERR_NOT_UP_FOR_SALE");
        return price;
    }

    function getPriceOf(int16 x, int16 y) public view returns (uint256) {
        Bid storage currentBid = getCurrentBid[x][y];
        if (currentBid.amount == 0) {
            return getReservePrice(x, y);
        } else {
            // attempt to outbid
            return getOutbidPrice(currentBid.amount);
        }
    }

    function getCategory(int16 x, int16 y) public view returns (int8) {
        (uint16 x_mapped, uint16 y_mapped) = _transformXY(x, y);

        int8 category;
        for (uint16 i = x_mapped; i > 0; i = _subLowbit(i)) {
            for (uint16 j = y_mapped; j > 0; j = _subLowbit(j)) {
                unchecked {
                    category += _categoryBIT[i][j];
                }
            }
        }
        return category;
    }

    function isShiboshiZone(int16 x, int16 y) public pure returns (bool) {
        /*
            (12,99) to (48, 65)
            (49, 99) to (77, 78)
            (76, 77) to (77, 50)
            (65, 50) to (75, 50)
        */

        if (x >= 12 && x <= 48 && y <= 99 && y >= 65) {
            return true;
        }
        if (x >= 49 && x <= 77 && y <= 99 && y >= 78) {
            return true;
        }
        if (x >= 76 && x <= 77 && y <= 77 && y >= 50) {
            return true;
        }
        if (x >= 65 && x <= 75 && y == 50) {
            return true;
        }
        return false;
    }

    // List of currently winning bids of this user
    function bidInfoOf(address user)
        external
        view
        returns (int16[] memory, int16[] memory)
    {
        uint256 bidCount = winningsBidsOf[user];
        int16[] memory xs = new int16[](bidCount);
        int16[] memory ys = new int16[](bidCount);

        uint256 ptr;
        uint32[] storage allBids = _allBidsOf[user];
        uint256 length = allBids.length;

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            if (_statusOfBidsOf[user][allBids[i]] == 1) {
                (int16 x, int16 y) = _decodeXY(allBids[i]);
                xs[ptr] = x;
                ys[ptr] = y;
                ptr = _uncheckedInc(ptr);
            }
        }

        return (xs, ys);
    }

    // List of all bids, ever done by this user
    function allBidInfoOf(address user)
        external
        view
        returns (int16[] memory, int16[] memory)
    {
        uint32[] storage allBids = _allBidsOf[user];
        uint256 bidCount = allBids.length;
        int16[] memory xs = new int16[](bidCount);
        int16[] memory ys = new int16[](bidCount);

        for (uint256 i = 0; i < bidCount; i = _uncheckedInc(i)) {
            (int16 x, int16 y) = _decodeXY(allBids[i]);
            xs[i] = x;
            ys[i] = y;
        }

        return (xs, ys);
    }

    function setGridVal(
        int16 x1,
        int16 y1,
        int16 x2,
        int16 y2,
        int8 val
    ) external onlyRole(GRID_SETTER_ROLE) {
        (uint16 x1_mapped, uint16 y1_mapped) = _transformXY(x1, y1);
        (uint16 x2_mapped, uint16 y2_mapped) = _transformXY(x2, y2);

        _updateGrid(x2_mapped + 1, y2_mapped + 1, val);
        _updateGrid(x1_mapped, y1_mapped, val);
        _updateGrid(x1_mapped, y2_mapped + 1, -val);
        _updateGrid(x2_mapped + 1, y1_mapped, -val);
    }

    function setPriceOfCategory(int8 category, uint256 price)
        external
        onlyRole(GRID_SETTER_ROLE)
    {
        priceOfCategory[category] = price;

        emit CategoryPriceSet(category, price);
    }

    function setStage(uint256 stage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        currentStage = Stage(stage);
        emit StageSet(stage);
    }

    function setSignerAddress(address signer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(signer != address(0), "ERR_CANNOT_BE_ZERO_ADDRESS");
        signerAddress = signer;
        emit SignerSet(signer);
    }

    function setLandRegistry(address _landRegistry)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        landRegistry = ILandRegistry(_landRegistry);
    }

    function setLockLeash(address _lockLeash)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lockLeash = ILockLeash(_lockLeash);
    }

    function setLockShiboshi(address _lockShiboshi)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lockShiboshi = ILockShiboshi(_lockShiboshi);
    }

    function setMultiBid(bool desiredValue)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(multiBidEnabled != desiredValue, "ERR_ALREADY_DESIRED_VALUE");
        multiBidEnabled = desiredValue;

        emit multiBidToggled(desiredValue);
    }

    function withdraw(address to, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payable(to).transfer(amount);
    }

    function bidOne(int16 x, int16 y)
        external
        payable
        onlyStage(Stage.Bidding)
        nonReentrant
    {
        address user = msg.sender;
        require(availableCapacityOf(user) != 0, "ERR_NO_BIDS_REMAINING");
        require(!isShiboshiZone(x, y), "ERR_NO_MINT_IN_SHIBOSHI_ZONE");
        _bid(user, x, y, msg.value);
    }

    function bidShiboshiZoneOne(
        int16 x,
        int16 y,
        bytes calldata signature
    ) external payable onlyStage(Stage.Bidding) nonReentrant {
        address user = msg.sender;
        require(
            _verifySigner(_hashMessage(user), signature),
            "ERR_SIGNATURE_INVALID"
        );
        require(isShiboshiZone(x, y), "ERR_NOT_IN_SHIBOSHI_ZONE");
        _bid(user, x, y, msg.value);
    }

    function bidMulti(
        int16[] calldata xs,
        int16[] calldata ys,
        uint256[] calldata prices
    ) external payable onlyStage(Stage.Bidding) nonReentrant {
        require(multiBidEnabled, "ERR_MULTI_BID_DISABLED");

        address user = msg.sender;

        uint256 length = xs.length;
        require(length != 0, "ERR_NO_INPUT");
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");
        require(length == prices.length, "ERR_INPUT_LENGTH_MISMATCH");

        uint256 total;
        require(
            availableCapacityOf(user) >= length,
            "ERR_INSUFFICIENT_BIDS_REMAINING"
        );

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            total += prices[i];
        }
        require(msg.value == total, "ERR_INSUFFICIENT_AMOUNT_SENT");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];
            require(!isShiboshiZone(x, y), "ERR_NO_MINT_IN_SHIBOSHI_ZONE");
            _bid(user, x, y, prices[i]);
        }
    }

    function bidShiboshiZoneMulti(
        int16[] calldata xs,
        int16[] calldata ys,
        uint256[] calldata prices,
        bytes calldata signature
    ) external payable onlyStage(Stage.Bidding) nonReentrant {
        require(multiBidEnabled, "ERR_MULTI_BID_DISABLED");

        address user = msg.sender;
        require(
            _verifySigner(_hashMessage(user), signature),
            "ERR_SIGNATURE_INVALID"
        );

        uint256 length = xs.length;
        require(length != 0, "ERR_NO_INPUT");
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");
        require(length == prices.length, "ERR_INPUT_LENGTH_MISMATCH");

        uint256 total;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            total += prices[i];
        }
        require(msg.value == total, "ERR_INSUFFICIENT_AMOUNT_SENT");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];
            require(isShiboshiZone(x, y), "ERR_NOT_IN_SHIBOSHI_ZONE");
            _bid(user, x, y, prices[i]);
        }
    }

    function mintWinningBid(int16[] calldata xs, int16[] calldata ys) external {
        require(
            currentStage == Stage.PublicSale ||
                currentStage == Stage.PrivateSale,
            "ERR_MUST_WAIT_FOR_BIDDING_TO_END"
        );

        uint256 length = xs.length;
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];
            require(xLow <= x && x <= xHigh, "ERR_X_OUT_OF_RANGE");
            require(yLow <= y && y <= yHigh, "ERR_Y_OUT_OF_RANGE");

            address user = getCurrentBid[x][y].bidder;
            require(user != address(0), "ERR_NO_BID_FOUND");
            landRegistry.mint(user, x, y);
        }
    }

    function mintPrivate(int16 x, int16 y)
        external
        payable
        onlyStage(Stage.PrivateSale)
        nonReentrant
    {
        require(availableCapacityOf(msg.sender) != 0, "ERR_NO_BIDS_REMAINING");
        require(!isShiboshiZone(x, y), "ERR_NO_MINT_IN_SHIBOSHI_ZONE");
        _mintPublicOrPrivate(msg.sender, x, y);
        emit LandBought(
            msg.sender,
            _encodeXY(x, y),
            x,
            y,
            msg.value,
            Stage.PrivateSale
        );
    }

    function mintPrivateShiboshiZone(
        int16 x,
        int16 y,
        bytes calldata signature
    ) external payable onlyStage(Stage.PrivateSale) nonReentrant {
        require(
            _verifySigner(_hashMessage(msg.sender), signature),
            "ERR_SIGNATURE_INVALID"
        );
        require(isShiboshiZone(x, y), "ERR_NOT_IN_SHIBOSHI_ZONE");
        _mintPublicOrPrivate(msg.sender, x, y);
        emit LandBought(
            msg.sender,
            _encodeXY(x, y),
            x,
            y,
            msg.value,
            Stage.PrivateSale
        );
    }

    function mintPublic(int16 x, int16 y)
        external
        payable
        onlyStage(Stage.PublicSale)
        nonReentrant
    {
        _mintPublicOrPrivate(msg.sender, x, y);
        emit LandBought(
            msg.sender,
            _encodeXY(x, y),
            x,
            y,
            msg.value,
            Stage.PublicSale
        );
    }

    // transform: +97, +100
    function _transformXY(int16 x, int16 y)
        internal
        pure
        onlyValid(x, y)
        returns (uint16, uint16)
    {
        return (uint16(x + 97), uint16(100 - y));
    }

    function _bid(
        address user,
        int16 x,
        int16 y,
        uint256 price
    ) internal onlyValid(x, y) {
        uint32 encXY = _encodeXY(x, y);
        Bid storage currentBid = getCurrentBid[x][y];
        if (currentBid.amount == 0) {
            // first bid on this land
            require(
                price >= getReservePrice(x, y),
                "ERR_INSUFFICIENT_AMOUNT_SENT"
            );
        } else {
            // attempt to outbid
            require(user != currentBid.bidder, "ERR_CANNOT_OUTBID_YOURSELF");
            require(
                price >= getOutbidPrice(currentBid.amount),
                "ERR_INSUFFICIENT_AMOUNT_SENT"
            );
            _safeTransferETHWithFallback(currentBid.bidder, currentBid.amount);
            winningsBidsOf[currentBid.bidder] -= 1;
            _statusOfBidsOf[currentBid.bidder][encXY] = 2;
        }

        currentBid.bidder = user;
        currentBid.amount = price;
        winningsBidsOf[user] += 1;

        if (_statusOfBidsOf[user][encXY] == 0) {
            // user has never bid on this land earlier
            _allBidsOf[user].push(encXY);
        }
        _statusOfBidsOf[user][encXY] = 1;

        emit BidCreated(user, encXY, x, y, price, block.timestamp);
    }

    function _mintPublicOrPrivate(
        address user,
        int16 x,
        int16 y
    ) internal onlyValid(x, y) {
        Bid storage currentBid = getCurrentBid[x][y];
        require(currentBid.amount == 0, "ERR_NOT_UP_FOR_SALE");
        require(
            msg.value == getReservePrice(x, y),
            "ERR_INSUFFICIENT_AMOUNT_SENT"
        );

        currentBid.bidder = user;
        currentBid.amount = msg.value;
        winningsBidsOf[user] += 1;

        uint32 encXY = _encodeXY(x, y);
        _allBidsOf[user].push(encXY);
        _statusOfBidsOf[user][encXY] = 1;

        landRegistry.mint(user, x, y);
    }

    function _hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender));
    }

    function _verifySigner(bytes32 messageHash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            signerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{value: amount}();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }

    function _uncheckedInc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    function _uncheckedDec(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i - 1;
        }
    }

    function _encodeXY(int16 x, int16 y) internal pure returns (uint32) {
        return
            ((uint32(uint16(x)) * factor) & clearLow) |
            (uint32(uint16(y)) & clearHigh);
    }

    function _decodeXY(uint32 value) internal pure returns (int16 x, int16 y) {
        x = _expandNegative16BitCast((value & clearLow) >> 16);
        y = _expandNegative16BitCast(value & clearHigh);
    }

    function _expandNegative16BitCast(uint32 value)
        internal
        pure
        returns (int16)
    {
        if (value & (1 << 15) != 0) {
            return int16(int32(value | clearLow));
        }
        return int16(int32(value));
    }

    // Functions for BIT

    function _updateGrid(
        uint16 x,
        uint16 y,
        int8 val
    ) internal {
        for (uint16 i = x; i <= N; i = _addLowbit(i)) {
            for (uint16 j = y; j <= M; j = _addLowbit(j)) {
                unchecked {
                    _categoryBIT[i][j] += val;
                }
            }
        }
    }

    function _addLowbit(uint16 i) internal pure returns (uint16) {
        unchecked {
            return i + uint16(int16(i) & (-int16(i)));
        }
    }

    function _subLowbit(uint16 i) internal pure returns (uint16) {
        unchecked {
            return i - uint16(int16(i) & (-int16(i)));
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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